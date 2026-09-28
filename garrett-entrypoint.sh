#!/bin/sh
# Garrett cloud entrypoint — bypasses s6-overlay's hard PID-1 requirement.
#
# Render's Docker runtime does not exec the image entrypoint as PID 1 (like
# Fly Machines / `docker run --init`), so s6-overlay's /init aborts with
# "s6-overlay-suexec: fatal: can only run as pid 1" and the container exits
# 128 before any Hermes code runs. See hermes-agent issue #36208.
#
# Instead of s6 supervision, run the stage2 bootstrap + memory seed directly,
# then the gateway in foreground. NO_SUPERVISE is set at the service so
# `hermes gateway run` uses pre-s6 foreground semantics.
set -e
export HERMES_HOME="${HERMES_HOME:-/opt/data}"
export PATH="/command:/package/admin/s6/command:${PATH}"
/opt/hermes/docker/stage2-hook.sh
/opt/hermes/seed-memories.sh
exec /opt/hermes/docker/main-wrapper.sh gateway run
