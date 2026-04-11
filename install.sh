#!/bin/bash
set -euo pipefail

INSTALL_DIR="/Library/Input Methods"
APP_NAME="Hatoko.app"
BUNDLE_ID="com.chigichan24.inputmethod.Hatoko"

echo "=== Hatoko IME Installer ==="

# Parse arguments
APP_SOURCE=""
IS_CLEAN=false

for arg in "$@"; do
  case "$arg" in
    --clean)
      IS_CLEAN=true
      ;;
    *)
      APP_SOURCE="$arg"
      ;;
  esac
done

# Detect update vs fresh install
IS_UPDATE=false
if [ -d "${INSTALL_DIR}/${APP_NAME}" ]; then
  IS_UPDATE=true
fi

if [ "$IS_CLEAN" = true ]; then
  IS_UPDATE=false
  echo "(Clean install mode)"
fi

if [ -n "$APP_SOURCE" ]; then
  # Pre-built .app provided
  echo "[1/5] Using pre-built app: $APP_SOURCE"
  echo "[2/5] Skipping build..."
  APP_PATH="$APP_SOURCE"

  if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: App not found at $APP_PATH"
    exit 1
  fi
else
  # Build from source
  echo "[1/5] Generating Xcode project..."
  mint run xcodegen generate
  ./scripts/inject_package_traits.sh

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
fi

# 3. Kill existing process
echo "[3/5] Cleaning up..."
killall Hatoko 2>/dev/null || true
for i in $(seq 1 10); do
  pgrep -x Hatoko >/dev/null 2>&1 || break
  sleep 0.5
done

# On clean install, disable existing TIS sources before removing
if [ "$IS_UPDATE" = false ]; then
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
fi

# 4. Install
echo "[4/5] Installing..."
if [ "$IS_UPDATE" = true ]; then
  # Update: overwrite in place to preserve TIS registration
  sudo rsync -a --delete "${APP_PATH}/" "${INSTALL_DIR}/${APP_NAME}/"
else
  # Fresh install: clean copy
  sudo rm -rf "${INSTALL_DIR}/${APP_NAME}"
  sudo cp -R "$APP_PATH" "$INSTALL_DIR/"
fi

# Re-register with LaunchServices
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f "${INSTALL_DIR}/${APP_NAME}"

# Launch
open "${INSTALL_DIR}/${APP_NAME}"
sleep 2

# 5. Register input source (fresh install only)
echo "[5/5] Registering input source..."
if [ "$IS_UPDATE" = false ]; then
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
else
  echo "  Skipped (update mode - TIS registration preserved)"
fi

echo ""
echo "=== Done! ==="
if [ "$IS_UPDATE" = true ]; then
  echo "Updated in place. Hatoko should be available immediately."
  echo "If not working, try switching away from Hatoko and back."
else
  echo "First install complete."
  echo "If Hatoko appears in the menu bar input source, select it."
  echo "If not, logout and login once, then it should appear."
fi
