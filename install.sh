#!/bin/bash
set -euo pipefail

INSTALL_DIR="/Library/Input Methods"
APP_NAME="Hatoko.app"

echo "=== Hatoko IME Installer ==="

# 1. Generate Xcode project
echo "[1/4] Generating Xcode project..."
mint run xcodegen generate

# 2. Build
echo "[2/4] Building..."
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
echo "[3/4] Installing..."
killall Hatoko 2>/dev/null || true
sleep 0.5

# 4. Copy to Input Methods
sudo cp -R "$APP_PATH" "$INSTALL_DIR/"
echo "  Copied to ${INSTALL_DIR}/${APP_NAME}"

# 5. Launch
echo "[4/4] Launching..."
open "${INSTALL_DIR}/${APP_NAME}"

echo ""
echo "=== Done! ==="
echo "Next steps:"
echo "  1. Open System Settings → Keyboard → Input Sources"
echo "  2. Click '+' and add 'Hatoko'"
echo "  3. Select Hatoko from the menu bar input source"
echo "  4. Try typing in any text field"
