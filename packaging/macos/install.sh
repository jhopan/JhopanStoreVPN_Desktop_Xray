#!/usr/bin/env bash
set -euo pipefail

APP_NAME="JhopanStoreVPN"
APP_ID="com.jhopanstore.vpn"
APP_BUNDLE="/Applications/${APP_NAME}.app"
BIN_LINK="/usr/local/bin/jhopanstorevpn"

SRC_BIN="${1:-./dist/macos/JhopanStoreVPN}"
SRC_XRAY="${2:-./dist/macos/xray}"
SRC_ASSETS="${3:-./dist/macos/assets}"

if [[ ! -f "$SRC_BIN" ]]; then
  echo "App binary not found: $SRC_BIN"
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

CONTENTS_DIR="$TMP_DIR/${APP_NAME}.app/Contents"
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
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${APP_ID}</string>
  <key>CFBundleVersion</key>
  <string>1.0.0</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleExecutable</key>
  <string>JhopanStoreVPN</string>
  <key>LSMinimumSystemVersion</key>
  <string>11.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

rm -rf "$APP_BUNDLE"
mv "$TMP_DIR/${APP_NAME}.app" "$APP_BUNDLE"

mkdir -p /usr/local/bin
ln -sf "$APP_BUNDLE/Contents/MacOS/JhopanStoreVPN" "$BIN_LINK"

touch "$APP_BUNDLE"
/usr/bin/mdimport "$APP_BUNDLE" >/dev/null 2>&1 || true

echo "Installed ${APP_NAME} to ${APP_BUNDLE}"
