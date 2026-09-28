---
name: pywebview-desktop-app
description: Use when building native desktop apps with pywebview.
---

# pywebview Desktop App

Build native desktop apps that wrap a local web server using pywebview. Tier-by-tier approach — each tier must be verified before the next starts.

## Prerequisites

- Python 3.10+ with `pywebview` installed in a project venv
- A running local web server (FastAPI/uvicorn, Express, etc.) on a fixed port
- macOS: Xcode command line tools for `codesign` (Tier 5)

## Tier Sequence

### Tier 1 — Bare Window

Create `shell.py` with a single `webview.create_window()` pointing at the server URL.

```python
import webview
window = webview.create_window("App Title", url=SERVER_URL, width=1280, height=900, min_size=(800, 600))
webview.start(debug=False)
```

Verify: window appears, title bar correct, traffic lights visible, zero browser chrome, content renders.

### Tier 2 — Mic Permissions (macOS)

WKWebView silently denies `getUserMedia` unless two conditions are met:

1. **Delegate hook** — monkey-patch `BrowserDelegate` before window creation to grant at the WebKit level
2. **Info.plist** — add `NSMicrophoneUsageDescription` to the Python.app bundle's Info.plist for the OS-level TCC prompt

```python
import objc
from WebKit import WKPermissionDecisionGrant
from webview.platforms.cocoa import BrowserView

cls = BrowserView.BrowserDelegate
def requestMediaCapturePermission_(self, _wv, _origin, _frame, _type, handler):
    handler(WKPermissionDecisionGrant)

selector = b'webView:requestMediaCapturePermissionForOrigin:initiatedByFrame:type:decisionHandler:'
objc.classAddMethod(cls, selector, requestMediaCapturePermission_)
```

Then patch Info.plist:
```bash
PLIST="/Library/Frameworks/Python.framework/Versions/3.10/Resources/Python.app/Contents/Info.plist"
cp "$PLIST" "${PLIST}.oracle-backup"
/usr/libexec/PlistBuddy -c "Add :NSMicrophoneUsageDescription string 'App needs microphone access.'" "$PLIST"
tccutil reset Microphone  # reset TCC so prompt appears again
```

Verify: create a test page that calls `navigator.mediaDevices.getUserMedia({audio:true})` and reports success/failure. Must show GRANTED + live stream.

See `references/macos-mic-permissions.md` for the full chain explanation.

See `references/macos-app-bundle.md` for the .app bundle build (Tier 5+).

### Tier 3 — External Links

Route external URLs to the system browser. Two mechanisms needed:

**1. `target="_blank"` / `window.open()`** — set before `create_window()`:
```python
import webview
webview.settings['OPEN_EXTERNAL_LINKS_IN_BROWSER'] = True
```

**2. Same-window external links** — `OPEN_EXTERNAL_LINKS_IN_BROWSER` does NOT catch plain `<a href>` or `window.location` changes. Patch the delegate's navigation policy method:
```python
import objc, webbrowser
from webview.platforms.cocoa import BrowserView
from WebKit import WKNavigationActionPolicyAllow, WKNavigationActionPolicyCancel

ALLOWED_HOSTS = {"127.0.0.1", "localhost"}

def _decide_policy(self, _sel, _wv, action, handler):
    host = action.request().URL().host() or ""
    if host in ALLOWED_HOSTS:
        handler(WKNavigationActionPolicyAllow)
    else:
        handler(WKNavigationActionPolicyCancel)
        webbrowser.open(action.request().URL().absoluteString())

selector = b'webView:decidePolicyForNavigationAction:decisionHandler:'
objc.classAddMethod(BrowserView.BrowserDelegate, selector, _decide_policy)
```

Call both patches before `webview.start()`. The `request_sent` event cannot block navigation — it fires after the policy decision.

### Tier 4 — Splash + Server Wake

Show a branded splash page while the server starts. Pattern:

1. Probe `http://127.0.0.1:PORT` — if up, load server URL directly (fast path)
2. If down → load splash HTML as `file://` URL, start server subprocess, poll in background thread
3. On success → `window.load_url(SERVER_URL)` to navigate
4. On timeout (60s) → splash shows retry link
5. On window close → terminate server subprocess if we started it

Key pitfall: the server subprocess needs the RIGHT Python. If the app venv only has pywebview, the server needs its own venv with FastAPI/uvicorn. Use the server's venv Python, not `sys.executable`.

```python
HERMES_VENV = os.path.expanduser("~/.hermes/hermes-agent/venv/bin/python3")
PYTHON = HERMES_VENV if os.path.isfile(HERMES_VENV) else sys.executable
UVICORN_CMD = [PYTHON, "-m", "uvicorn", "server.server:app", "--host", "127.0.0.1", "--port", "3333"]
```

### Tier 5 — macOS .app Bundle + Signing

Hand-roll `.app` bundle directory structure with a compiled C launcher, codesign with entitlements. Full recipe in `references/macos-app-bundle.md`.

Directory structure:
```
Oracle.app/
  Contents/
    Info.plist          # CFBundleExecutable=oracle, bundle ID, icon ref
    MacOS/
      oracle            # Compiled Mach-O C binary (NOT a shell script)
    Resources/
      Oracle.icns       # App icon
```

**Critical: use a compiled C binary as `CFBundleExecutable`, not a shell script.** Gatekeeper rejects `.app` bundles whose main executable is a shell script — `open Oracle.app` launches nothing. The C launcher calls `execv()` on the Python venv + shell.py.

```c
// oracle_launcher.c — compile: cc -o oracle oracle_launcher.c
#include <unistd.h>
int main() {
    char *python = "./venv/bin/python3";
    char *args[] = {python, "shell.py", NULL};
    execv(python, args);
    return 1;
}
```

Entitlements plist (audio input for mic):
```xml
<key>com.apple.security.device.audio-input</key>
<true/>
```

Codesign:
```bash
mkdir -p Oracle.app/Contents/MacOS Oracle.app/Contents/Resources
cp oracle Oracle.app/Contents/MacOS/oracle
cp Oracle.icns Oracle.app/Contents/Resources/
codesign --force --sign - --identifier com.brenevangelista.oracle \
  --entitlements Oracle.entitlements Oracle.app
spctl --assess --type execute Oracle.app  # expect 'rejected' for ad-hoc
xattr -cr Oracle.app  # clear quarantine for local use
```

### Tier 6 — Polish

Icon, window state persistence, server health monitoring, Supabase persistence.

**Icon generation** (PIL → iconset → .icns):
```python
from PIL import Image, ImageDraw, ImageFont
img = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)
# draw your icon...
img.save('icon_1024x1024.png')
```
```bash
mkdir -p Oracle.iconset
# Generate all sizes (16,32,64,128,256,512,1024 + @2x variants)
# icon_16x16.png → icon_16x16.png, icon_32x32.png → icon_16x16@2x.png, etc.
iconutil -c icns Oracle.iconset -o Oracle.icns
```

**Window state persistence** — save/restore window position and size:
```python
import json, os
STATE_FILE = os.path.expanduser("~/.config/<appname>/window-state.json")
def save_state(window):
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    json.dump({"x": window.x, "y": window.y, "width": window.width, "height": window.height}, open(STATE_FILE, "w"))
def restore_state(window):
    if os.path.exists(STATE_FILE):
        s = json.load(open(STATE_FILE))
        window.move(s["x"], s["y"])
        window.resize(s["width"], s["height"])
```

**Server health monitoring** — background thread pings server every 10s, shows reconnect overlay on consecutive failures, auto-restarts if server died.

**Supabase persistence** — REST API client (no dependency needed) for conversation history, memory entries, and knowledge base. Tables created via migration, accessed via `requests` or `urllib`.

## Pitfalls

- **`objc.classAddMethod` requires bytes for selector** — pass `b'webView:...'` not `'webView:...'`. A `str` raises `TypeError: a bytes-like object is required`.
- **`BrowserDelegate` class path varies by pywebview version** — verify the actual class name with `dir(BrowserView)` before patching. The mic delegate monkey-patch targets `BrowserView.BrowserDelegate`, but attribute names change across versions. Always guard: `if not hasattr(BrowserView, 'BrowserDelegate'): print("WARNING: BrowserDelegate not found, mic patch skipped")`.
- **`window.events.navigating` and `window.events.started` do NOT exist** — pywebview's EventContainer has neither. Available events: `before_load`, `before_show`, `closed`, `closing`, `initialized`, `loaded`, `maximized`, `minimized`, `moved`, `request_sent`, `resized`, `response_received`, `restored`, `shown`. Use `shown` for first-window-display hooks (splash → wake server), `loaded` for DOM-ready, `before_load` for URL interception, `response_received` for post-navigation hooks.
- **Python venv mismatch** — the desktop app venv (pywebview) and the server venv (FastAPI/uvicorn) are often different. The server subprocess must use the server's Python, not the app's.
- **TCC prompt won't appear without Info.plist** — the WKWebView delegate hook grants at WebKit level, but macOS TCC checks `NSMicrophoneUsageDescription` in the main bundle's Info.plist. Without it, mic is silently denied.
- **`tccutil reset Microphone`** — required after modifying Info.plist so macOS re-shows the permission prompt. Resets ALL apps' mic permissions.
- **Server subprocess becomes zombie** — if the wrong Python is used (missing deps), the process dies silently. Check `ps aux | grep PID` after starting.
- **Gatekeeper rejects shell script executables in .app bundles** — `open Oracle.app` launches nothing if `CFBundleExecutable` points to a `.sh` file. Must be a compiled Mach-O binary (C `execv` wrapper).
- **Compiled C launcher alone may not give pywebview WindowServer access** — a Mach-O binary fixes Gatekeeper rejection, but pywebview's Cocoa backend also needs the Python process to have macOS GUI application context. If the venv Python is a symlink to `/usr/local/bin/python3` (Homebrew/system), it may lack the framework event loop. Check with `readlink -f venv/bin/python3`. If it resolves to `/Library/Frameworks/Python.framework/.../Python.app/Contents/MacOS/Python`, it has framework support; if it resolves to `/usr/local/bin/python3`, it may not. When window creation fails silently (process starts, 0 windows), try launching via `open -a Python.app shell.py` using the framework Python directly, or switch the venv's Python to the framework build.
- **`Path(__file__).resolve().parent.parent` may not reach project root** — when source files live in a subdirectory (e.g., `src/brain.py`), two `.parent` calls resolve to the subdirectory, not the project root. Count the nesting depth and add `.parent` calls accordingly, or anchor on a known marker file (`ROOT = next(p for p in Path(__file__).resolve().parents if (p / 'pyproject.toml').exists())`).
- **`osascript` with `with administrator privileges` creates unkillable zombies** — the `authtrampoline` process (PPID=1) survives `kill -9` until reboot. These phantom processes can occupy ports and appear as running Python instances. Avoid using `with administrator privileges` in osascript for GUI app testing; if stuck, only a reboot clears them.
- **Debug .app launch failures with log redirection** — when `open App.app` starts a process but nothing appears, replace the launcher temporarily with a script that does `exec > /tmp/app_debug.log 2>&1` then `echo` env vars (HOME, PROJ, python path, CWD) before the final `exec python3 shell.py`. This reveals whether the script runs at all, whether paths resolve, and where it stops. Check the log after `sleep 8`.
- **codesign `Info.plist=not bound` error** — caused by unsigned subcomponents (e.g., a leftover `.sh` script) inside the bundle. Remove all non-binary subcomponents and sign the whole bundle in one pass.
- **`xattr -cr` required before `open`** — Gatekeeper quarantines unsigned/downloaded .apps. Clear with `xattr -cr Oracle.app` before launching.
- **`webview.settings` dict must be set before `create_window()`** — setting `OPEN_EXTERNAL_LINKS_IN_BROWSER` after window creation has no effect.
- **`OPEN_EXTERNAL_LINKS_IN_BROWSER` only handles `target="_blank"`** — same-window external navigation (plain `<a href>` without target, or `window.location.href = ...`) still loads inside the webview. To intercept those, monkey-patch `webView_decidePolicyForNavigationAction_decisionHandler_` on `BrowserView.BrowserDelegate`: check `request.URL().host()` against allowed hosts, call `decisionHandler(WKNavigationActionPolicyCancel)` + `open_in_browser()` for external, `decisionHandler(WKNavigationActionPolicyAllow)` for local. Use `objc.classAddMethod` to add the override.
- **`request_sent` event cannot block navigation** — pywebview fires `request_sent` from inside `decidePolicyForNavigationAction`, then re-issues the request with an `X-Handled` header. The handler runs but the original navigation proceeds regardless. To actually cancel navigation, patch the delegate method directly (see previous pitfall).

## User Preferences

- **Tier-by-tier, never collapse tiers** — verify each before moving on
- **"up to you"** on unspecified details means use sensible defaults without asking
- Bundle ID default: `com.brenevangelista.<appname>`
- Ad-hoc code signing (`--force --sign -`) is acceptable for local builds
