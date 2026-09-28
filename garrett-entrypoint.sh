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

# Clear any stale OAuth auth.json. A single-use Nous refresh token that was
# rotated elsewhere puts the provider into a terminal "refresh-token reuse"
# quarantine (relogin_required stamped into auth.json), which blocks even the
# NOUS_API_KEY fallback. The cloud instance authenticates with NOUS_API_KEY,
# so a leftover auth.json is never legitimate here.
rm -f "$HERMES_HOME/auth.json"

/opt/hermes/docker/stage2-hook.sh

# Persist NOUS_API_KEY into the profile's .env. The model provider resolves
# credentials through the secret scope (built from $HERMES_HOME/.env, no
# os.environ fallback), and the privilege-drop into the hermes user may reset
# the process environment anyway.
if [ -n "${NOUS_API_KEY:-}" ] && [ -f "$HERMES_HOME/.env" ]; then
    sed -i '/^NOUS_API_KEY=/d' "$HERMES_HOME/.env" 2>/dev/null || true
    printf 'NOUS_API_KEY=%s\n' "$NOUS_API_KEY" >> "$HERMES_HOME/.env"
fi

/opt/hermes/seed-memories.sh
exec /opt/hermes/docker/main-wrapper.sh gateway run
