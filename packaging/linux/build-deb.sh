#!/usr/bin/env bash
set -euo pipefail

APP_NAME="JhopanStoreVPN"
APP_ID="jhopanstorevpn"
VERSION="${1:-1.0.0}"
ARCH="${2:-amd64}"

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DIST_DIR="$ROOT_DIR/dist/linux"
OUT_DIR="$ROOT_DIR/dist/installer/linux"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

SRC_BIN="$DIST_DIR/JhopanStoreVPN"
SRC_XRAY="$DIST_DIR/xray"
SRC_ASSETS="$DIST_DIR/assets"

if [[ ! -f "$SRC_BIN" ]]; then
  echo "Missing binary: $SRC_BIN"
  exit 1
fi

if ! command -v dpkg-deb >/dev/null 2>&1; then
  echo "dpkg-deb is required. Install Debian packaging tools first."
  exit 1
fi

PKG_DIR="$WORK_DIR/${APP_ID}_${VERSION}_${ARCH}"
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/opt/$APP_ID"
mkdir -p "$PKG_DIR/usr/bin"
mkdir -p "$PKG_DIR/usr/share/applications"

install -m 0755 "$SRC_BIN" "$PKG_DIR/opt/$APP_ID/JhopanStoreVPN"

if [[ -f "$SRC_XRAY" ]]; then
  install -m 0755 "$SRC_XRAY" "$PKG_DIR/opt/$APP_ID/xray"
fi

if [[ -d "$SRC_ASSETS" ]]; then
  cp -R "$SRC_ASSETS" "$PKG_DIR/opt/$APP_ID/assets"
fi

cat > "$PKG_DIR/usr/bin/$APP_ID" <<'EOF'
#!/usr/bin/env bash
exec /opt/jhopanstorevpn/JhopanStoreVPN "$@"
EOF
chmod 0755 "$PKG_DIR/usr/bin/$APP_ID"

cat > "$PKG_DIR/usr/share/applications/$APP_ID.desktop" <<EOF
[Desktop Entry]
Name=$APP_NAME
Comment=Desktop VPN client
Exec=/opt/$APP_ID/JhopanStoreVPN
Terminal=false
Type=Application
Categories=Network;Utility;
StartupNotify=true
EOF
chmod 0644 "$PKG_DIR/usr/share/applications/$APP_ID.desktop"

cat > "$PKG_DIR/DEBIAN/control" <<EOF
Package: $APP_ID
Version: $VERSION
Section: net
Priority: optional
Architecture: $ARCH
Maintainer: JhopanStore <support@jhopanstore.local>
Description: JhopanStoreVPN desktop client
EOF

cat > "$PKG_DIR/DEBIAN/postinst" <<'EOF'
#!/usr/bin/env bash
set -e
update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
exit 0
EOF
chmod 0755 "$PKG_DIR/DEBIAN/postinst"

cat > "$PKG_DIR/DEBIAN/postrm" <<'EOF'
#!/usr/bin/env bash
set -e
update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
exit 0
EOF
chmod 0755 "$PKG_DIR/DEBIAN/postrm"

mkdir -p "$OUT_DIR"
OUT_FILE="$OUT_DIR/${APP_ID}_${VERSION}_${ARCH}.deb"
dpkg-deb --build "$PKG_DIR" "$OUT_FILE"

echo "Built DEB: $OUT_FILE"
echo "Install via double-click in file manager (GUI Software Center) or: sudo apt install ./$(basename "$OUT_FILE")"