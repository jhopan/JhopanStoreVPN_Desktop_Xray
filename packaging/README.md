# Packaging and Installer Guide

This folder contains installer assets for Windows, Linux, and macOS.

## Windows (Inno Setup -> Setup.exe)

### Prerequisites

- Inno Setup installed
- ISCC available in PATH
- Build output available in dist/windows/

### Build setup.exe

1. Build app binary first.
2. Run:

```powershell
./packaging/windows/make-installer.ps1
```

Result:

- dist/installer/windows/JhopanStoreVPN-Setup.exe

Installer behavior:

- Installs to Program Files
- Creates Start Menu shortcut
- Optional desktop shortcut
- Registers App Paths for discoverability from Windows search / Win+R
- Generates uninstaller entry (Control Panel / Installed Apps)

## Linux (Double-click .deb installer)

### Build GUI-installable package

Run on Linux machine:

```bash
chmod +x ./packaging/linux/build-deb.sh
./packaging/linux/build-deb.sh 1.0.0 amd64
```

Result:

- dist/installer/linux/jhopanstorevpn_1.0.0_amd64.deb

Install behavior:

- User can double-click the .deb in file manager / Software Center
- Installs app to /opt/jhopanstorevpn
- Adds launcher to app menu/search via .desktop entry
- Adds command jhopanstorevpn in PATH via /usr/bin wrapper

Manual script installer (fallback) is still available:

```bash
sudo ./packaging/linux/install.sh
```

Uninstall fallback:

```bash
sudo ./packaging/linux/uninstall.sh
```

## macOS (DMG drag-and-drop to Applications)

### Build DMG

Run on macOS machine:

```bash
chmod +x ./packaging/macos/build-dmg.sh
./packaging/macos/build-dmg.sh 1.0.0
```

Result:

- dist/installer/macos/JhopanStoreVPN-1.0.0.dmg

Install behavior:

- User opens DMG
- Drag JhopanStoreVPN.app into Applications
- App then appears in Launchpad/Spotlight like standard macOS apps

Direct install script (fallback) is still available:

```bash
./packaging/macos/install.sh
```

Uninstall fallback:

```bash
./packaging/macos/uninstall.sh
```
