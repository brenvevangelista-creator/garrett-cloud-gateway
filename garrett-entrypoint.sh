#!/bin/sh
# DIAGNOSTIC entrypoint — determine what Render actually executes and where it fails.
# No `set -e`: capture every step's exit code explicitly.
echo "===GARRETT-ENTRYPOINT-RAN==="
echo "PID=$$ UID=$(id -u) GID=$(id -g)"
echo "HERMES_HOME=${HERMES_HOME:-unset}"
echo "PATH=$PATH"
echo "--- /opt/hermes ---"
ls -la /opt/hermes/ 2>&1 | head -30
echo "--- /opt/data ---"
ls -la /opt/data/ 2>&1 | head -30
echo "===STAGE2==="
/opt/hermes/docker/stage2-hook.sh 2>&1
echo "===STAGE2-EXIT=$?==="
echo "===SEED==="
/opt/hermes/seed-memories.sh 2>&1
echo "===SEED-EXIT=$?==="
echo "===GATEWAY==="
/opt/hermes/docker/main-wrapper.sh gateway run 2>&1
echo "===GATEWAY-EXIT=$?==="
echo "===DONE==="
