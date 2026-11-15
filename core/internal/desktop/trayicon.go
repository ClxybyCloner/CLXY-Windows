package desktop

import (
	"embed"
	"runtime"
)

// AppIconICO is the transparent CLXY C/X mark in the sizes Windows uses:
// the executable's resources (tools/winres).
//
//go:embed appicon.ico
var AppIconICO []byte

// trayFiles are the transparent CLXY C/X tray icons by state. Windows takes
// the .ico files (several sizes), the other systems the 32 px .png files.
//
//go:embed tray
var trayFiles embed.FS

// Tray icon names.
const (
	iconRunning       = "running"
	iconRunningAsleep = "running-asleep" // running without a connection to Mozilla
	iconSet           = "set"            // running while Windows uses the proxy
	iconSetAsleep     = "set-asleep"
	iconWaiting       = "waiting"
	iconError         = "error"
	iconOff           = "off"
)

// trayIcon is the named tray icon in this system's format.
func trayIcon(name string) []byte {
	ext := ".png"
	if runtime.GOOS == "windows" {
		ext = ".ico"
	}
	data, _ := trayFiles.ReadFile("tray/" + name + ext)
	return data
}
