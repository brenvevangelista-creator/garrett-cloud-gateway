#!/bin/sh
# First-boot seed of Garrett's memories into the persistent volume.
# Plain sh (no with-contenv shebang — s6/execline isn't available on Render).
set -eu

HERMES_HOME="${HERMES_HOME:-/opt/data}"
SEED_DIR="/opt/hermes/garrett-memories"

[ -d "$SEED_DIR" ] || exit 0

for src in "$SEED_DIR"/*; do
    [ -e "$src" ] || continue
    name="$(basename "$src")"
    dest="$HERMES_HOME/memories/$name"
    # Never clobber a memory the cloud instance has already written.
    if [ ! -e "$dest" ]; then
        cp "$src" "$dest"
        chown hermes:hermes "$dest" 2>/dev/null || true
    fi
done
