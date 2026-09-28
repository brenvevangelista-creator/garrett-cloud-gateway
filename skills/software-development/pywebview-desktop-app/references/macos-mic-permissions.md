# macOS Microphone Permissions in pywebview (WKWebView)

Two-layer gate: WebKit delegate + OS TCC. Both must pass.

## Layer 1: WKWebView Delegate Hook

`navigator.mediaDevices.getUserMedia({audio:true})` triggers WebKit's `requestMediaCapturePermission` delegate. pywebview does NOT implement this — monkey-patch `BrowserDelegate` before `create_window()`.

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

Selector MUST be bytes, not str. Add a guard flag (`cls._oracle_media_patched = True`) to avoid double-patching.

## Layer 2: OS TCC (Info.plist)

macOS checks the main bundle's `Info.plist` for `NSMicrophoneUsageDescription`. Running under Python.app means Python.app's Info.plist is the target.

```bash
PLIST="/Library/Frameworks/Python.framework/Versions/3.10/Resources/Python.app/Contents/Info.plist"
cp "$PLIST" "${PLIST}.oracle-backup"
/usr/libexec/PlistBuddy -c "Add :NSMicrophoneUsageDescription string 'Oracle needs microphone access for voice commands.'" "$PLIST"
tccutil reset Microphone
```

This modifies the system Python.app — survives until Python is reinstalled. Backup first.

## Layer 3: Proper .app Bundle (Preferred)

A hand-rolled `.app` bundle with its own `Info.plist` avoids modifying Python.app entirely. See `references/macos-app-bundle.md` for the full build process.

## Decision Table

| Build Type | Approach | Info.plist | TCC Reset |
|---|---|---|---|
| Dev (python shell.py) | Patch Python.app | System Python.app | Yes, after plist edit |
| Local .app bundle | Own Info.plist | In bundle | Only if bundle ID changes |
| Distributed .app | Own Info.plist + Developer ID | In bundle | N/A (user grants) |
