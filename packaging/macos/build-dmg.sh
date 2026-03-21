#!/usr/bin/env bash
set -euo pipefail

APP_NAME="JhopanStoreVPN"
APP_ID="com.jhopanstore.vpn"
VERSION="${1:-1.0.0}"

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DIST_DIR="$ROOT_DIR/dist/macos"
OUT_DIR="$ROOT_DIR/dist/installer/macos"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

SRC_BIN="$DIST_DIR/JhopanStoreVPN"
SRC_XRAY="$DIST_DIR/xray"
SRC_ASSETS="$DIST_DIR/assets"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script must run on macOS."
  exit 1
fi

if [[ ! -f "$SRC_BIN" ]]; then
  echo "Missing binary: $SRC_BIN"
  exit 1
fi

if ! command -v hdiutil >/dev/null 2>&1; then
  echo "hdiutil is required on macOS."
  exit 1
fi

STAGE_DIR="$WORK_DIR/stage"
APP_BUNDLE="$STAGE_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$MACOS_DIR" "$RES_DIR"

install -m 0755 "$SRC_BIN" "$RES_DIR/JhopanStoreVPN.bin"
if [[ -f "$SRC_XRAY" ]]; then
  install -m 0755 "$SRC_XRAY" "$RES_DIR/xray"
fi
if [[ -d "$SRC_ASSETS" ]]; then
  cp -R "$SRC_ASSETS" "$RES_DIR/assets"
fi

cat > "$MACOS_DIR/JhopanStoreVPN" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_DIR/Resources"
exec "$APP_DIR/Resources/JhopanStoreVPN.bin" "$@"
EOF
chmod 0755 "$MACOS_DIR/JhopanStoreVPN"

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$APP_ID</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleExecutable</key>
  <string>JhopanStoreVPN</string>
  <key>LSMinimumSystemVersion</key>
  <string>11.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

ln -s /Applications "$STAGE_DIR/Applications"

mkdir -p "$OUT_DIR"
DMG_PATH="$OUT_DIR/${APP_NAME}-${VERSION}.dmg"

hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE_DIR" -ov -format UDZO "$DMG_PATH"

echo "Built DMG: $DMG_PATH"
echo "Open DMG and drag ${APP_NAME}.app into Applications."