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

if ! command -v rpmbuild >/dev/null 2>&1; then
  echo "rpmbuild is required. Install rpm tooling first."
  exit 1
fi

RPM_ARCH="x86_64"
if [[ "$ARCH" == "arm64" ]]; then
  RPM_ARCH="aarch64"
fi

RPMROOT="$WORK_DIR/rpmbuild"
PKG_ROOT="$WORK_DIR/${APP_ID}-${VERSION}"
mkdir -p "$RPMROOT"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p "$PKG_ROOT/opt/$APP_ID" "$PKG_ROOT/usr/bin" "$PKG_ROOT/usr/share/applications"

install -m 0755 "$SRC_BIN" "$PKG_ROOT/opt/$APP_ID/JhopanStoreVPN"
if [[ -f "$SRC_XRAY" ]]; then
  install -m 0755 "$SRC_XRAY" "$PKG_ROOT/opt/$APP_ID/xray"
fi
if [[ -d "$SRC_ASSETS" ]]; then
  cp -R "$SRC_ASSETS" "$PKG_ROOT/opt/$APP_ID/assets"
fi

cat > "$PKG_ROOT/usr/bin/$APP_ID" <<'EOF'
#!/usr/bin/env bash
exec /opt/jhopanstorevpn/JhopanStoreVPN "$@"
EOF
chmod 0755 "$PKG_ROOT/usr/bin/$APP_ID"

cat > "$PKG_ROOT/usr/share/applications/$APP_ID.desktop" <<EOF
[Desktop Entry]
Name=$APP_NAME
Comment=Desktop VPN client
Exec=/opt/$APP_ID/JhopanStoreVPN
Terminal=false
Type=Application
Categories=Network;Utility;
StartupNotify=true
EOF
chmod 0644 "$PKG_ROOT/usr/share/applications/$APP_ID.desktop"

TARBALL="$RPMROOT/SOURCES/${APP_ID}-${VERSION}.tar.gz"
tar -C "$WORK_DIR" -czf "$TARBALL" "${APP_ID}-${VERSION}"

cat > "$RPMROOT/SPECS/${APP_ID}.spec" <<EOF
Name:           ${APP_ID}
Version:        ${VERSION}
Release:        1%{?dist}
Summary:        ${APP_NAME} desktop client
License:        Proprietary
URL:            https://github.com/jhopan/JhopanStoreVPN_Desktop_Xray
BuildArch:      ${RPM_ARCH}
Source0:        ${APP_ID}-${VERSION}.tar.gz

%description
${APP_NAME} desktop VPN client package.

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}
cp -a opt %{buildroot}/
cp -a usr %{buildroot}/

%files
/opt/${APP_ID}
/usr/bin/${APP_ID}
/usr/share/applications/${APP_ID}.desktop

%post
update-desktop-database /usr/share/applications >/dev/null 2>&1 || true

%postun
update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
EOF

rpmbuild --define "_topdir $RPMROOT" -bb "$RPMROOT/SPECS/${APP_ID}.spec"

mkdir -p "$OUT_DIR"
RPM_FILE=$(find "$RPMROOT/RPMS" -type f -name "*.rpm" | head -n1)
if [[ -z "$RPM_FILE" ]]; then
  echo "RPM build failed: no output file found"
  exit 1
fi
OUT_FILE="$OUT_DIR/${APP_ID}_${VERSION}_${ARCH}.rpm"
cp "$RPM_FILE" "$OUT_FILE"

echo "Built RPM: $OUT_FILE"
