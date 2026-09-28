#!/bin/sh
# Garrett cloud entrypoint for Render.
#
# Render runs dockerCommand directly as PID 1, bypassing the image
# ENTRYPOINT and s6-overlay /init (which aborts "can only run as pid 1").
# So s6 tools aren't on PATH — we ship a s6-setuidgid shim at
# /opt/hermes/bin and run the normal stage2 bootstrap + memory seed +
# gateway in the foreground, no s6 supervision.
set -e
export HERMES_HOME="${HERMES_HOME:-/opt/data}"
export HOME=/opt/data
/opt/hermes/docker/stage2-hook.sh
/opt/hermes/seed-memories.sh
exec /opt/hermes/docker/main-wrapper.sh gateway run
