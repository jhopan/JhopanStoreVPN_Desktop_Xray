package assets

import (
	"os"
	"path/filepath"

	"fyne.io/fyne/v2"
)

// IconData is the application icon - uses icon.png only.
var IconData fyne.Resource

func init() {
	// Single source: icon.png
	if res := loadAssetFile("icon.png"); res != nil {
		IconData = res
		return
	}

	// Fallback only if icon.png not found
	IconData = &fyne.StaticResource{
		StaticName: "icon.png",
		StaticContent: []byte{
			0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
			0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
			0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x10,
			0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x91, 0x68,
			0x36, 0x00, 0x00, 0x00, 0x1f, 0x49, 0x44, 0x41,
			0x54, 0x78, 0x9c, 0x62, 0x60, 0x60, 0xa0, 0x04,
			0x30, 0x32, 0x32, 0x32, 0x30, 0x30, 0x30, 0x30,
			0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
			0x00, 0x00, 0x00, 0x31, 0x00, 0x01, 0xed, 0xd0,
			0x7d, 0x2f, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
			0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
		},
	}
}

// TrayIconData returns the tray icon - uses icon.png.
func TrayIconData() fyne.Resource {
	if res := loadAssetFile("icon.png"); res != nil {
		return res
	}
	return IconData
}

// loadAssetFile tries to load a file from common asset locations.
func loadAssetFile(name string) *fyne.StaticResource {
	paths := []string{}
	if exePath, err := os.Executable(); err == nil {
		dir := filepath.Dir(exePath)
		paths = append(paths, filepath.Join(dir, "assets", name))
		paths = append(paths, filepath.Join(dir, name))
	}
	if cwd, err := os.Getwd(); err == nil {
		paths = append(paths, filepath.Join(cwd, "assets", name))
		paths = append(paths, filepath.Join(cwd, name))
	}
	for _, p := range paths {
		data, err := os.ReadFile(p)
		if err == nil {
			return &fyne.StaticResource{StaticName: name, StaticContent: data}
		}
	}
	return nil
}

// LoadIcon returns the app icon resource.
func LoadIcon() fyne.Resource {
	return IconData
}
