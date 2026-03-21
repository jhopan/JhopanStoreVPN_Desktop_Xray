#!/usr/bin/env bash
set -euo pipefail

APP_NAME="JhopanStoreVPN"
APP_BUNDLE="/Applications/${APP_NAME}.app"
BIN_LINK="/usr/local/bin/jhopanstorevpn"

rm -f "$BIN_LINK"
rm -rf "$APP_BUNDLE"

echo "Uninstalled ${APP_NAME}"
