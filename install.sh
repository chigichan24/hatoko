#!/bin/bash
set -euo pipefail

INSTALL_DIR="/Library/Input Methods"
APP_NAME="Hatoko.app"
BUNDLE_ID="com.chigichan24.inputmethod.Hatoko"

echo "=== Hatoko IME Installer ==="

# 1. Generate Xcode project
echo "[1/5] Generating Xcode project..."
mint run xcodegen generate

# 2. Build
echo "[2/5] Building..."
xcodebuild -project Hatoko.xcodeproj \
  -scheme Hatoko \
  -configuration Debug \
  build \
  | grep -E "^(Build |Compile|Link|Sign|error:)" || true

BUILD_DIR=$(xcodebuild -project Hatoko.xcodeproj \
  -scheme Hatoko \
  -configuration Debug \
  -showBuildSettings 2>/dev/null \
  | grep " BUILD_DIR " \
  | awk '{print $3}')

APP_PATH="${BUILD_DIR}/Debug/${APP_NAME}"

if [ ! -d "$APP_PATH" ]; then
  echo "ERROR: Build product not found at $APP_PATH"
  exit 1
fi

# 3. Kill existing process and clean up
echo "[3/5] Cleaning up..."
killall Hatoko 2>/dev/null || true
sleep 0.5

# Unregister from TIS before removing
swift -e '
import Carbon
import Foundation
let sources = TISCreateInputSourceList(nil, true)?.takeRetainedValue() as? [TISInputSource] ?? []
for source in sources {
    guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { continue }
    let id = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
    if id.hasPrefix("com.chigichan24.inputmethod.Hatoko") {
        TISDisableInputSource(source)
    }
}
' 2>/dev/null || true

# 4. Remove old and copy fresh
echo "[4/5] Installing..."
sudo rm -rf "${INSTALL_DIR}/${APP_NAME}"
sudo cp -R "$APP_PATH" "$INSTALL_DIR/"

# Re-register with LaunchServices
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f "${INSTALL_DIR}/${APP_NAME}"

# Launch
open "${INSTALL_DIR}/${APP_NAME}"
sleep 2

# 5. Register and enable input source
echo "[5/5] Registering input source..."
swift -e '
import Carbon
import Foundation

let appURL = URL(fileURLWithPath: "/Library/Input Methods/Hatoko.app") as CFURL
TISRegisterInputSource(appURL)

let sources = TISCreateInputSourceList(nil, true)?.takeRetainedValue() as? [TISInputSource] ?? []
var found = false
for source in sources {
    guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { continue }
    let id = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
    if id.hasPrefix("com.chigichan24.inputmethod.Hatoko") {
        found = true
        TISEnableInputSource(source)
        print("  Enabled: \(id)")
    }
}
if !found { print("  WARNING: Input source not found. Logout/login may be needed.") }
'

echo ""
echo "=== Done! ==="
echo "If Hatoko appears in the menu bar input source, select it."
echo "If not, logout and login once, then it should appear."
