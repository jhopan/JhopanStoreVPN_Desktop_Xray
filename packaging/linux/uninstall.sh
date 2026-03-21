#!/usr/bin/env bash
set -euo pipefail

APP_ID="jhopanstorevpn"
INSTALL_DIR="/opt/${APP_ID}"
BIN_LINK="/usr/local/bin/${APP_ID}"
DESKTOP_FILE="/usr/share/applications/${APP_ID}.desktop"

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo ./packaging/linux/uninstall.sh"
  exit 1
fi

rm -f "$BIN_LINK"
rm -f "$DESKTOP_FILE"
rm -rf "$INSTALL_DIR"
update-desktop-database /usr/share/applications >/dev/null 2>&1 || true

echo "Uninstalled ${APP_ID}"
