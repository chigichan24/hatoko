#!/bin/bash
set -euo pipefail

INSTALL_DIR="/Library/Input Methods"
APP_NAME="Hatoko.app"

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

# 3. Kill existing process
echo "[3/5] Installing..."
killall Hatoko 2>/dev/null || true
sleep 0.5

# 4. Remove old and copy fresh
sudo rm -rf "${INSTALL_DIR}/${APP_NAME}"
sudo cp -R "$APP_PATH" "$INSTALL_DIR/"
echo "  Copied to ${INSTALL_DIR}/${APP_NAME}"

# 5. Launch
echo "[4/5] Launching..."
open "${INSTALL_DIR}/${APP_NAME}"
sleep 2

# 6. Register and enable input source
echo "[5/5] Registering input source..."
swift -e '
import Carbon
import Foundation

let appURL = URL(fileURLWithPath: "/Library/Input Methods/Hatoko.app") as CFURL
let regStatus = TISRegisterInputSource(appURL)
if regStatus != 0 && regStatus != -1 {
    print("WARNING: TISRegisterInputSource returned \(regStatus)")
}

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
if !found {
    print("ERROR: Input source not found after registration")
}
'

echo ""
echo "=== Done! ==="
echo "Select Hatoko from the menu bar input source to start using it."
