#!/bin/sh
# Build and smoke-test the OpenEMS Edge add-on container.
#
# Usage: ./test.sh
#
# Requires either Docker or Podman. Builds the image, starts it with
# a temporary /data volume, and verifies the entrypoint completes its
# setup steps and launches OpenEMS.
set -eu

# Pick container runtime
if command -v docker >/dev/null 2>&1; then
    RT=docker
elif command -v podman >/dev/null 2>&1; then
    RT=podman
else
    echo "ERROR: neither docker nor podman found" >&2
    exit 1
fi
echo "Using container runtime: $RT"

IMAGE="openems-edge-test"
CONTAINER="openems-edge-test-run"
PASS=0
FAIL=0

cleanup() {
    echo ""
    echo "=== Cleanup ==="
    $RT rm -f "$CONTAINER" >/dev/null 2>&1 || true
    $RT rmi -f "$IMAGE" >/dev/null 2>&1 || true
}
trap cleanup EXIT

assert() {
    desc="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    desc="$1"
    haystack="$2"
    needle="$3"
    if echo "$haystack" | grep -q "$needle"; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected: $needle)"
        FAIL=$((FAIL + 1))
    fi
}

# -------------------------------------------------------
echo "=== Building image ==="
$RT build -t "$IMAGE" openems_edge/
echo ""

# -------------------------------------------------------
echo "=== Test: container starts and runs setup ==="

# Start container in background, give it time to boot
$RT run -d --name "$CONTAINER" \
    --tmpfs /data \
    "$IMAGE"

echo "Waiting for container to boot (30s)..."
sleep 30

LOGS=$($RT logs "$CONTAINER" 2>&1)

# Check setup steps in logs
assert_contains "persistent storage prepared" "$LOGS" "preparing persistent storage"
assert_contains "user creation attempted" "$LOGS" "openems"
assert_contains "launcher found" "$LOGS" "launching"

# -------------------------------------------------------
echo ""
echo "=== Test: persistent directories created ==="

assert "data/config exists" $RT exec "$CONTAINER" test -d /data/config
assert "data/data exists" $RT exec "$CONTAINER" test -d /data/data
assert "data/bundles exists" $RT exec "$CONTAINER" test -d /data/bundles

# -------------------------------------------------------
echo ""
echo "=== Test: symlinks point to /data ==="

config_link=$($RT exec "$CONTAINER" readlink /var/opt/openems/config 2>/dev/null || echo "MISSING")
data_link=$($RT exec "$CONTAINER" readlink /var/opt/openems/data 2>/dev/null || echo "MISSING")

assert_contains "config symlink -> /data/config" "$config_link" "/data/config"
assert_contains "data symlink -> /data/data" "$data_link" "/data/data"

# -------------------------------------------------------
echo ""
echo "=== Test: OpenEMS process is running ==="

assert "java process running" $RT exec "$CONTAINER" sh -c "ps aux 2>/dev/null | grep -q '[j]ava' || pgrep -x java"

# -------------------------------------------------------
echo ""
echo "=== Test: container is healthy ==="

STATE=$($RT inspect --format '{{.State.Status}}' "$CONTAINER" 2>/dev/null || echo "unknown")
assert_contains "container status is running" "$STATE" "running"

# -------------------------------------------------------
echo ""
echo "=== Test: bundle sync manifest created ==="

assert "bundle manifest exists" $RT exec "$CONTAINER" test -f /data/.custom_bundles

# -------------------------------------------------------
echo ""
echo "=== Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "=== Container logs ==="
    echo "$LOGS"
    exit 1
fi
