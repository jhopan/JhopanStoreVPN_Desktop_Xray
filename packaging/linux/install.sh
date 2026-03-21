#!/usr/bin/env bash
set -euo pipefail

APP_NAME="JhopanStoreVPN"
APP_ID="jhopanstorevpn"
INSTALL_DIR="/opt/${APP_ID}"
BIN_LINK="/usr/local/bin/${APP_ID}"
DESKTOP_FILE="/usr/share/applications/${APP_ID}.desktop"

SRC_BIN="${1:-./dist/linux/JhopanStoreVPN}"
SRC_XRAY="${2:-./dist/linux/xray}"
SRC_ASSETS="${3:-./dist/linux/assets}"

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo ./packaging/linux/install.sh"
  exit 1
fi

if [[ ! -f "$SRC_BIN" ]]; then
  echo "App binary not found: $SRC_BIN"
  exit 1
fi

mkdir -p "$INSTALL_DIR"
install -m 0755 "$SRC_BIN" "$INSTALL_DIR/JhopanStoreVPN"

if [[ -f "$SRC_XRAY" ]]; then
  install -m 0755 "$SRC_XRAY" "$INSTALL_DIR/xray"
fi

if [[ -d "$SRC_ASSETS" ]]; then
  rm -rf "$INSTALL_DIR/assets"
  cp -R "$SRC_ASSETS" "$INSTALL_DIR/assets"
fi

ln -sf "$INSTALL_DIR/JhopanStoreVPN" "$BIN_LINK"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=${APP_NAME}
Comment=Desktop VPN client
Exec=${INSTALL_DIR}/JhopanStoreVPN
Terminal=false
Type=Application
Categories=Network;Utility;
StartupNotify=true
EOF

chmod 0644 "$DESKTOP_FILE"
update-desktop-database /usr/share/applications >/dev/null 2>&1 || true

echo "Installed ${APP_NAME} to ${INSTALL_DIR}"
