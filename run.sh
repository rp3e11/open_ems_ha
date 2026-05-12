#!/bin/sh
# OpenEMS Edge add-on entrypoint.
#
# Responsibilities:
#   1. Ensure persistent dirs exist under /data (HA add-on volume).
#   2. Drop any user-supplied bundles from /share/openems-bundles into the
#      Felix bundle directory before launch.
#   3. Hand off (via exec) to OpenEMS's own launcher so Java becomes PID 1
#      and receives SIGTERM cleanly when Supervisor stops the add-on.
set -eu

echo "[openems-addon] preparing persistent storage under /data"
mkdir -p /data/config /data/data

# Optional: let users drop extra Felix bundles into /share/openems-bundles
# (mapped read-write via config.yaml). Copy them in on every boot so
# upgrades pick up new versions automatically.
BUNDLE_SRC="/share/openems-bundles"
BUNDLE_DST="/opt/openems/bundles"
if [ -d "$BUNDLE_SRC" ] && [ -d "$BUNDLE_DST" ]; then
    echo "[openems-addon] syncing custom bundles from $BUNDLE_SRC"
    cp -f "$BUNDLE_SRC"/*.jar "$BUNDLE_DST"/ 2>/dev/null || true
fi

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
        echo "[openems-addon] launching $candidate"
        exec "$candidate" "$@"
    fi
done

# Fallback: launch the edge jar directly. Works for older images that
# ship openems-edge.jar at the canonical path documented in the
# OpenEMS Getting Started guide (java -jar openems-edge.jar).
if [ -f /opt/openems/openems-edge.jar ]; then
    echo "[openems-addon] launching openems-edge.jar via java"
    cd /opt/openems
    exec java \
        -Dfelix.cm.dir=/var/opt/openems/config \
        -jar openems-edge.jar
fi

echo "[openems-addon] ERROR: could not find OpenEMS launcher. Image layout:"
ls -la /opt/openems 2>/dev/null || echo "  /opt/openems does not exist"
exit 1
