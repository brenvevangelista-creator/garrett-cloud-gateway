# Garrett Cloud Gateway — derived Hermes image for Render
#
# Seeds my brain (config, SOUL, memories, skills) into the official
# Hermes image so the first boot on a fresh /opt/data volume produces a
# fully-configured Garrett instance. Secrets (Nous auth, Telegram token)
# are NOT baked in — they arrive via Render env vars at runtime.

FROM nousresearch/hermes-agent:v2026.9.24

# --- Config: override the image's first-boot seed source --------------------
# stage2-hook.sh copies /opt/hermes/cli-config.yaml.example -> config.yaml
# on first boot only. Swapping this file means the cloud instance comes up
# with model.provider=nous + deepseek-v4-pro + telegram.enabled from boot 1.
COPY config.yaml /opt/hermes/cli-config.yaml.example

# --- SOUL: override the default persona seed --------------------------------
# stage2-hook.sh copies /opt/hermes/docker/SOUL.md -> SOUL.md on first boot.
COPY SOUL.md /opt/hermes/docker/SOUL.md

# --- Skills: merge my full skill set into the bundled skills tree -----------
# skills_sync.py copies bundled skills from /opt/hermes/skills/ into
# $HERMES_HOME/skills/ on boot. Adding my custom skills here means they are
# seeded too. .dockerignore excludes the manifest/cache dotfiles.
COPY skills/ /opt/hermes/skills/

# --- Memories: no auto-seed exists, so ship them + a seed script ------------
COPY memories/ /opt/hermes/garrett-memories/
COPY seed-memories.sh /opt/hermes/seed-memories.sh
RUN chmod +x /opt/hermes/seed-memories.sh

# --- s6-setuidgid shim: Render skips s6-overlay /init, so s6-setuidgid is
# not on PATH. stage2-hook.sh and main-wrapper.sh both call it to drop to
# the hermes user; this shim emulates it with setpriv/runuser/su.
COPY s6-setuidgid /opt/hermes/bin/s6-setuidgid
RUN chmod +x /opt/hermes/bin/s6-setuidgid

# --- Entrypoint: bypass s6-overlay (requires PID 1; Render doesn't give it) -
# Render's Docker runtime does not exec the image entrypoint as PID 1, so
# s6-overlay's /init aborts ("can only run as pid 1", exit 128 — hermes-agent
# issue #36208). Run the stage2 bootstrap + memory seed + gateway in
# foreground directly instead of under s6 supervision.
COPY garrett-entrypoint.sh /opt/hermes/garrett-entrypoint.sh
RUN chmod +x /opt/hermes/garrett-entrypoint.sh
ENTRYPOINT ["/opt/hermes/garrett-entrypoint.sh"]
CMD ["gateway", "run"]
