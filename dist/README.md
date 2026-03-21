# JhopanStoreVPN - Distribution

Lightweight VLESS VPN client built with Go + Fyne + Xray-core.

## Windows (Ready to Use)

Folder: `dist/windows/`

### Build/Package (Windows):

```powershell
powershell -ExecutionPolicy Bypass -File .\dist\windows\build.ps1
```

Script di atas otomatis menyiapkan:

- `JhopanStoreVPN.exe`
- `xray.exe` (download otomatis jika belum ada)
- `wintun.dll`
- aset runtime di folder `assets/`

```
windows/
├── JhopanStoreVPN.exe    # Main application
├── xray.exe              # Xray-core engine
└── assets/
    └── icon.png          # App and tray icon
```

**How to run:** Double-click `JhopanStoreVPN.exe`

---

## Linux

Folder: `dist/linux/`

### Build on Linux:

```bash
# Install dependencies (Ubuntu/Debian)
sudo apt install -y golang gcc pkg-config libgl1-mesa-dev xorg-dev

# Clone/copy project, then:
cd JhoVPN
chmod +x dist/linux/build.sh
./dist/linux/build.sh
```

### Download Xray-core:

```bash
wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip Xray-linux-64.zip xray -d dist/linux/
chmod +x dist/linux/xray
```

### Run:

```bash
cd dist/linux
./JhopanStoreVPN
```

---

## macOS

Folder: `dist/macos/`

### Build on macOS:

```bash
# Install Xcode CLI tools + Go
xcode-select --install
brew install go

# Clone/copy project, then:
cd JhoVPN
chmod +x dist/macos/build.sh
./dist/macos/build.sh
```

### Download Xray-core:

```bash
# Intel Mac:
wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-macos-64.zip
# Apple Silicon (M1/M2/M3):
wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-macos-arm64-v8a.zip

unzip Xray-macos-*.zip xray -d dist/macos/
chmod +x dist/macos/xray
```

### Run:

```bash
cd dist/macos
./JhopanStoreVPN
```

---

## Notes

- Fyne (GUI framework) requires CGo, so each platform must be built natively or with the correct cross-compiler toolchain.
- Windows build is included ready-to-use since it was built on Windows.
- Linux and macOS include build scripts — run them on the target OS.
- Xray-core binary must be downloaded separately for each platform from: https://github.com/XTLS/Xray-core/releases
