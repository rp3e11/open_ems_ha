#!/bin/sh
# OpenEMS Edge add-on entrypoint.
#
# Responsibilities:
#   1. Ensure persistent dirs exist under /data (HA add-on volume).
#   2. Drop any user-supplied bundles from /data/bundles into the
#      Felix bundle directory before launch.
#   3. Hand off (via exec) to OpenEMS's own launcher, dropping to a
#      non-root user if possible.
set -eu

echo "[openems-addon] preparing persistent storage under /data"
mkdir -p /data/config /data/data /data/bundles

# Sync custom Felix bundles from /data/bundles into the runtime bundle
# directory. Clean the destination of previously-synced custom bundles
# first so that removals and renames in /data/bundles take effect.
BUNDLE_SRC="/data/bundles"
BUNDLE_DST="/opt/openems/bundles"
BUNDLE_MANIFEST="/data/.custom_bundles"
if [ -d "$BUNDLE_SRC" ] && [ -d "$BUNDLE_DST" ]; then
    # Remove previously synced custom bundles
    if [ -f "$BUNDLE_MANIFEST" ]; then
        while IFS= read -r old_jar; do
            if [ -f "$BUNDLE_DST/$old_jar" ]; then
                echo "[openems-addon] removing stale bundle: $old_jar"
                rm -f "$BUNDLE_DST/$old_jar"
            fi
        done < "$BUNDLE_MANIFEST"
    fi
    # Copy current bundles and record manifest
    : > "$BUNDLE_MANIFEST"
    for jar in "$BUNDLE_SRC"/*.jar; do
        [ -f "$jar" ] || continue
        echo "[openems-addon] copying custom bundle: $(basename "$jar")"
        cp -f "$jar" "$BUNDLE_DST"/
        basename "$jar" >> "$BUNDLE_MANIFEST"
    done
fi

# Create a non-root user for running OpenEMS if one doesn't exist yet.
# Log what we find so failures are diagnosable.
RUN_USER=""
if id openems >/dev/null 2>&1; then
    RUN_USER="openems"
    echo "[openems-addon] found existing 'openems' user"
elif command -v useradd >/dev/null 2>&1; then
    echo "[openems-addon] creating 'openems' user (Debian-style)"
    groupadd -f -g 1005 openems 2>&1 || true
    if useradd -u 1005 -g 1005 -d /opt/openems -s /bin/sh -M -N openems 2>&1; then
        RUN_USER="openems"
    else
        echo "[openems-addon] WARNING: useradd failed, will run as root"
    fi
elif command -v adduser >/dev/null 2>&1; then
    echo "[openems-addon] creating 'openems' user (Alpine-style)"
    addgroup -g 1005 openems 2>/dev/null || true
    if adduser -u 1005 -G openems -D -h /opt/openems -s /bin/sh openems 2>&1; then
        RUN_USER="openems"
    else
        echo "[openems-addon] WARNING: adduser failed, will run as root"
    fi
else
    echo "[openems-addon] WARNING: no useradd/adduser found, will run as root"
fi

# Set ownership if we have a non-root user
if [ -n "$RUN_USER" ]; then
    if [ ! -f /data/.ownership_set ]; then
        echo "[openems-addon] first boot: setting directory ownership"
        chown -R "$RUN_USER" /data /opt/openems 2>/dev/null || true
        touch /data/.ownership_set
    else
        chown "$RUN_USER" /data /data/config /data/data 2>/dev/null || true
    fi
fi

export HOME=/opt/openems

# Felix HTTP port. The add-on exposes 8765 on the host network (avoiding
# the common 8080 conflict with other HA add-ons). We inject it via
# JAVA_TOOL_OPTIONS so the JVM picks it up regardless of which upstream
# launcher script runs.
HTTP_PORT=8765
JVM_PROPS="-Dorg.osgi.service.http.port=${HTTP_PORT}"

# Helper: exec a command, dropping privileges if possible.
# Writes argv to a temp script to preserve argument boundaries
# instead of flattening through $* in a shell string.
run_exec() {
    if [ -n "$RUN_USER" ]; then
        echo "[openems-addon] launching as $RUN_USER: $1 (HTTP port ${HTTP_PORT})"
        LAUNCH_SCRIPT=$(mktemp /tmp/openems-launch.XXXXXX)
        {
            printf '#!/bin/sh\n'
            # env vars don't pass through `su -c`; set them inside the
            # wrapper so the JVM picks them up after the privilege drop.
            printf 'export JAVA_TOOL_OPTIONS=%s\n' "'${JVM_PROPS}'"
            printf 'exec'
            for arg in "$@"; do
                printf " '%s'" "$(printf '%s' "$arg" | sed "s/'/'\\\\''/g")"
            done
            printf '\n'
        } > "$LAUNCH_SCRIPT"
        # mktemp creates with mode 0600; widen so RUN_USER can read+exec.
        chmod 755 "$LAUNCH_SCRIPT"
        exec su -s /bin/sh "$RUN_USER" -c "exec $LAUNCH_SCRIPT"
    else
        echo "[openems-addon] launching as root: $1 (HTTP port ${HTTP_PORT})"
        export JAVA_TOOL_OPTIONS="${JVM_PROPS}"
        exec "$@"
    fi
}

# Locate OpenEMS's own launcher. The upstream image's exact path has shifted
# between releases, so probe a few likely locations and exec the first match.
# If none match, dump diagnostics and exit so the failure is loud.
for candidate in \
    /opt/openems/openems-edge \
    /opt/openems/bin/openems-edge \
    /opt/openems/start.sh \
    /opt/openems/docker-entrypoint.sh \
; do
    if [ -x "$candidate" ]; then
        run_exec "$candidate" "$@"
    fi
done

# Fallback: launch the edge jar directly.
if [ -f /opt/openems/openems-edge.jar ]; then
    cd /opt/openems
    run_exec java -Dfelix.cm.dir=/var/opt/openems/config -jar openems-edge.jar "$@"
fi

echo "[openems-addon] ERROR: could not find OpenEMS launcher. Image layout:"
ls -la /opt/openems 2>/dev/null || echo "  /opt/openems does not exist"
exit 1
