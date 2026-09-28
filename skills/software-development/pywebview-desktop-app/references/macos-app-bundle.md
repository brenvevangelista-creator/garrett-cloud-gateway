# macOS .app Bundle for pywebview Apps

Hand-rolled `.app` bundle with compiled C launcher, custom icon, entitlements, and ad-hoc codesigning.

## Bundle Structure

```
App.app/
  Contents/
    Info.plist              # Required: bundle metadata
    MacOS/
      app_binary            # Compiled Mach-O C binary
    Resources/
      App.icns              # App icon (optional but expected)
```

## C Launcher

Gatekeeper rejects `.app` bundles whose `CFBundleExecutable` is a shell script. Use a compiled C binary that `execv()`s Python:

```c
#include <unistd.h>
int main() {
    char *python = "./venv/bin/python3";  // relative to bundle MacOS/ or use absolute
    char *args[] = {python, "shell.py", NULL};
    execv(python, args);
    return 1;
}
```

Compile: `cc -o app_binary launcher.c` (produces Mach-O arm64 on Apple Silicon).

The path is relative to the working directory at launch, which is the bundle's MacOS/ directory for .app bundles launched via `open`.

## Info.plist Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>app_binary</string>
  <key>CFBundleIdentifier</key><string>com.example.app</string>
  <key>CFBundleName</key><string>App</string>
  <key>CFBundleDisplayName</key><string>App</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>App</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSMicrophoneUsageDescription</key><string>App needs microphone access.</string>
</dict>
</plist>
```

## Entitlements

For mic access + IPC:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.device.audio-input</key><true/>
  <key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
  <array><string>com.apple.coreservices.launchservicesd</string></array>
</dict>
</plist>
```

## Icon Generation (PIL → iconset → icns)

1. Generate 1024×1024 base image with PIL
2. Create `.iconset` directory with all required sizes:
   - `icon_16x16.png` (16px), `icon_16x16@2x.png` (32px)
   - `icon_32x32.png` (32px), `icon_32x32@2x.png` (64px)
   - `icon_128x128.png` (128px), `icon_128x128@2x.png` (256px)
   - `icon_256x256.png` (256px), `icon_256x256@2x.png` (512px)
   - `icon_512x512.png` (512px), `icon_512x512@2x.png` (1024px)
3. Convert: `iconutil -c icns App.iconset -o App.icns`

## Build + Sign Script

```bash
# Compile launcher
cc -o App.app/Contents/MacOS/app_binary launcher.c

# Copy icon
mkdir -p App.app/Contents/Resources
cp App.icns App.app/Contents/Resources/

# Code sign (ad-hoc)
codesign --force --sign - --identifier com.example.app \
  --entitlements App.entitlements App.app

# Verify
codesign -dvvv App.app 2>&1 | grep -E '(Identifier|Entitlements|Signed)'

# Clear quarantine for local use
xattr -cr App.app

# Test launch
open App.app
sleep 3
ps aux | grep app_binary | grep -v grep
```

## Adding to Dock

After copying to `/Applications`, add programmatically:

```bash
cp -R App.app /Applications/App.app
xattr -cr /Applications/App.app

# Add to Dock
defaults write com.apple.dock persistent-apps -array-add \
  '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/App.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
killall Dock  # required to reload dock layout
```

## Decision Table

| Build Type | Main Executable | Signing | Distribution |
|---|---|---|---|
| Dev (`python shell.py`) | N/A | None | Direct run |
| Local .app | C binary | Ad-hoc (`--sign -`) | `xattr -cr` + right-click→Open |
| TestFlight/Notarized | C binary | Developer ID | `notarytool submit` |

**Shell-script launcher alternative**: A `#!/bin/bash` launcher in `Contents/MacOS/` works when invoked directly (`./App.app/Contents/MacOS/oracle`) but `open App.app` may not surface the process or window. Use the C binary for reliable Dock/`open` launch behavior.

**C launcher + framework Python**: The C `execv` wrapper fixes Gatekeeper but may still fail if the venv Python lacks macOS GUI application context. If the compiled launcher starts the process but pywebview creates 0 windows, the venv Python is likely a non-framework build (e.g., Homebrew symlink to `/usr/local/bin/python3`). Fix: either rebuild the venv with framework Python, or have the C launcher exec into the framework Python.app binary directly (`/Library/Frameworks/Python.framework/Versions/3.10/Resources/Python.app/Contents/MacOS/Python`) with `PYTHONPATH` set to include the venv's `site-packages`.

**Debugging silent launch failures**: Temporarily replace the launcher with a log-capturing version:
```bash
#!/bin/bash
exec > /tmp/app_debug.log 2>&1
echo "=== Launch $(date) ==="
echo "HOME=$HOME"
PROJ="$HOME/projects/yourproject"
echo "PROJ=$PROJ"
ls -la "$PROJ/venv/bin/python3" || echo "PYTHON NOT FOUND"
cd "$PROJ" || { echo "CD FAILED"; exit 1; }
exec "$PROJ/venv/bin/python3" "shell.py"
```
Check `/tmp/app_debug.log` after 8 seconds to see where execution stopped.
