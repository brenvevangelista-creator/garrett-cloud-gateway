---
name: garrett-assistant
description: "Use when maintaining the Garrett voice assistant app."
---

# Garrett Assistant (jarvis-os-v2)

Bren's local Gemini Live voice assistant at `~/projects/jarvis-os-v2`. PyQt6 GUI
("G.A.R.R.E.T.T — MARK XXXIX"), always-on via launchd. Bren is non-technical:
perform every change yourself with tools and verify it live before reporting —
never hand him a step list, and never report an edit as done before executing it.

## Code map

| What | Where |
|---|---|
| Persona / system prompt | `core/prompt.txt` — THIS defines his name and identity |
| Spoken greeting | `main.py` `_announce_startup` (~line 888) |
| Tool declarations | `TOOL_DECLARATIONS` in `main.py` (~line 369) |
| Tool dispatch | `_execute_tool` in `main.py` (~line 1555); approval-gated `mutating` set ~1736 |
| Live model auto-pick | `core/live_model.py` (prefers `*native-audio*`) |
| OAuth/secret storage | `core/secret_store.py` (macOS keychain) |
| Long-term memory | `memory/long_term.json` (seed via `memory_manager.record_owner_name`) |
| Tools | `actions/<name>.py`, entry fn `(parameters, response, player, session_memory) -> str` |
| Launcher | `~/.local/bin/garrett` — must export `JARVIS_CLI=1` (guard in `main.py` refuses otherwise) |
| Logs | `.logs/garrett.log` (stdout), `.logs/garrett-error.log` (stderr) |

## Working rules

- **There is no config/env knob for the assistant's name.** Renaming means
  patching `core/prompt.txt` + the greeting string, then sweeping display labels
  (`perl -pi -e 's/\bJarvis\b/Garrett/g'` etc., sparing env vars like
  `JARVIS_CLI` and identifiers like `jarvis_ui_control`). Verify the actual
  mechanism in code before promising any config change.
- **Never use broad sed for renaming.** A blanket `sed 's/JARVIS/Garrett/g'` breaks internal module paths and env var checks (`JARVIS_CLI` → `Garrett_CLI`, breaking the launcher). Use Python-based targeted `re.sub` to change only user-visible strings: window titles, `[GARRETT]` log prefixes, startup banner, voice greeting, persona name, `print()` messages. Leave all `from core.` imports, `JARVIS_CLI` env var, `JARVIS_ACTIONS_PATH`, and API model names untouched. After renaming, always verify syntax with `ast.parse` on both main.py and ui.py, then clear `__pycache__` before restarting.
- **Always-on service**: `~/Library/LaunchAgents/com.bren.garrett.plist`
  (KeepAlive, auto-start at login). Manage: `launchctl kickstart -k
  gui/$(id -u)/com.bren.garrett`. After every code change, restart it, then
  verify exactly ONE instance (`pgrep -f "jarvis-os-v2.*main.py" | wc -l` → 1)
  and a fresh `Connected.` in the log — two instances fight over the mic.
- **Never hold the GUI app in a foreground terminal call** — the tool timeout
  kills the window and the user watches it die. Use launchd or `background=true`.
- **VAD cut-offs**: default `START_SENSITIVITY_HIGH`/`END_SENSITIVITY_HIGH` +
  200 ms silence makes ambient noise cancel his speech mid-sentence (Live API
  does not retry a cancelled turn). Tuned defaults are LOW/LOW + 1000 ms,
  overridable via `GARRETT_VAD_SILENCE_MS`. Tune this first when he "stops and
  never continues".
- **Clap gate**: boot waits for two claps; env toggles `JARVIS_SKIP_CLAP_GATE` /
  `JARVIS_ENABLE_CLAP_GATE`; the gate auto-disables on incompatible AUHAL setups.
- **Gemini REST model names go stale per key** ("no longer available to new
  users" 404, e.g. `gemini-2.5-flash`). List what the key actually has
  (`curl "https://generativelanguage.googleapis.com/v1beta/models?key=$GEMINI_API_KEY"`
  — read the key from `.env`, never print it) and sweep hardcoded names in
  `actions/`. As of last check: REST `gemini-3.6-flash`, fallback
  `gemini-3.1-flash-lite`; Live auto-picks `gemini-2.5-flash-native-audio-latest`.
- **Keys**: live in `.env` (chmod 600). To update, rewrite the
  `GEMINI_API_KEY=` line — appending a duplicate causes confusing state. A key
  pasted in chat is exposed: advise rotation.

## Adding a tool (5 touch points)

1. `actions/<name>.py` — entry function returning a user-facing string;
   reuse the OAuth pattern from `actions/google_workspace.py` or
   `actions/email_control.py` (keyring creds, client-secret auto-discovery in
   Downloads/`config/`, `connect` action with approval gate).
2. Lazy import in `main.py`: `<name> = _lazy_action("actions.<name>", "<name>")`.
3. `TOOL_DECLARATIONS` entry — description must teach the model the actions and
   safety gates (confirm before create/delete/send; never guess IDs).
4. `_execute_tool` branch; inherit a dropped-in `credentials_path` from
   `ui.current_dropped_file_path` for connect flows.
5. Add to the `mutating` set + a usage-rules paragraph in `core/prompt.txt`.

Then `py_compile`, unit-call the tool's `status` action, restart the service,
and check the log.

## PyQt6 CPU optimization (critical)

Garrett's orb UI is a PyQt6 canvas with multiple animation canvases
(HudCanvas, AIActivityCanvas, CompactModeWidget). Without throttling it burns
100%+ CPU and makes the Mac unusable.

### Diagnosing CPU

`sample <pid> 5` (macOS) — shows where CPU time goes. Expect `paintAndFlush` and
`drawEllipse` if the orb is over-rendering. `ps aux | grep main.py | awk '{print $3}'`
for quick % check.

### Idle-aware timer pattern

Every canvas `_step` method must switch between fast (active) and slow (idle)
timers. The pattern:

```python
def _step(self):
    is_active = self.state in ("listening", "speaking", "thinking")
    target_ms = self._active_frame_ms if is_active else 500
    if self._tmr.interval() != target_ms:
        self._tmr.setInterval(target_ms)
    # ... render ...
```

Store `_active_frame_ms` in `set_graphics_quality()` (reads from the profile's
`frame_ms`). Default to `_active_frame_ms = 50` in `__init__` — if `_step` runs
before `set_graphics_quality`, it crashes on missing attribute.

### Graphics quality profiles

`ui_settings.json` in project root: `{"graphics_quality": "low"}`. Profiles
are dicts in `ui.py` with `frame_ms` (50=low/20FPS, 33=medium/30FPS,
16=high/60FPS), `scanline_step`, `antialias`, `node_count`. Always start with
`low` for voice-only use.

### Geometry constants

Class-level constants in each canvas control draw-call density:
`_NODE_COUNT`, `_SHELL_NODES`, `_WAVE_COLS`, `_WAVE_ROWS`, `_RING_COUNT`,
`_LATTICE_RINGS`, `_LATTICE_ARCS`. Reducing these 60-70% has minimal visual
impact but cuts per-frame work proportionally.

**PITFALL**: When reducing `_RING_COUNT`, verify every list initialized with
that count. `_ring_angles` is built with `range(self._RING_COUNT)` but
`_orbital_rings` is a hardcoded list of dicts. If you reduce one without the
other, you get `IndexError: list index out of range` on startup — and the
crash is silent (no PID, no logs, LaunchAgent service shows registered but
dead). Use `len(self._orbital_rings)` instead of `_RING_COUNT` for ring-dependent
lists, or reduce `_orbital_rings` to match.

### Typing animation timer

Default `self._tmr.start(6)` at ~line 4384 = 166 FPS for a typing cursor.
Change to `self._tmr.start(30)` minimum. This alone dropped CPU from 112% to
~50% in testing.

### After editing ui.py

1. `python3 -c "import ast; ast.parse(open('ui.py').read()); print('OK')"`
   — syntax check (does NOT catch runtime errors like missing attributes)
2. `find . -name '*.pyc' -delete` — **always** delete stale bytecode. PyQt6
   imports `.pyc` first; an old compiled file silently overrides your edits.
3. Restart: `launchctl kickstart -k gui/$(id -u)/com.bren.garrett`
4. Wait 10-15s, then check PID exists and CPU is < 15%

### Silent crash debugging

If `launchctl list | grep garrett` shows the service but `pgrep -f main.py`
returns nothing and both log files are empty: run Garrett manually in
foreground to capture the traceback:

```bash
JARVIS_CLI=1 PYTHONUNBUFFERED=1 ~/projects/jarvis-os-v2/venv/bin/python \
  ~/projects/jarvis-os-v2/main.py 2>&1 | head -50
```

The `head -50` catches the crash before the GUI blocks the terminal.

## Tool management

Gemini Live sessions process every TOOL_DECLARATION on every turn. Too many
tools cause lag, disconnections, and "Interface closed" loops (the PyQt6
mainloop exiting because the session drops).

**Current state**: 11 tools — the voice-essential set plus `brain_read` for
vault access. `actions/browser_control.py` exists on disk but is NOT in
TOOL_DECLARATIONS or dispatch.

When adding/removing tools, touch exactly these 5 places (same as "Adding a
tool" above): action file, lazy import, TOOL_DECLARATIONS, dispatch branch,
prompt.txt. Then delete `.pyc` and restart.

**PITFALL**: `session_resumption` in the Live config can crash with
`SessionResumptionConfig.__init__() got an unexpected keyword argument
'transmitted_tokens_limit'`. Comment it out (`# session_resumption omitted —`
`# default disables resumption`) instead of setting `session_resumption=None`.

**PITFALL**: The `.logs/garrett-error.log` may be empty even when the process
crashes silently. Add `PYTHONUNBUFFERED=1` to the launcher script to flush
stderr. Without it, LaunchAgent captures nothing.

## After editing prompt.txt or tools

Same as ui.py edits: syntax check main.py, delete `.pyc`, restart, verify
single PID and CPU < 15%, check logs for `Connected.` and `Mic started`.

## Existing Google surface

`email_control` (Gmail) and `google_workspace` (Drive/Calendar/Sheets, one
OAuth). Both need a Desktop-app OAuth client JSON from Google Cloud with the
relevant APIs enabled; Bren drags it into the window and says "connect
Google/Gmail using this file". Creds live in the keychain, never in files.
PowerPoint decks are native (`create_presentation`).