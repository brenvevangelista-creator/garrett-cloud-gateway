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

# --- Memories: no auto-seed exists, so ship them + a first-boot hook --------
COPY memories/ /opt/hermes/garrett-memories/
COPY seed-memories.sh /opt/hermes/seed-memories.sh
RUN chmod +x /opt/hermes/seed-memories.sh
RUN printf '#!/command/with-contenv sh\nexec /opt/hermes/seed-memories.sh\n' \
        > /etc/cont-init.d/20-garrett-seed-memories \
    && chmod +x /etc/cont-init.d/20-garrett-seed-memories
