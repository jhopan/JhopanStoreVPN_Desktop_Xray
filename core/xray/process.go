package xray

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sync"
	"syscall"
	"time"
)

// Process manages the Xray-core subprocess lifecycle.
type Process struct {
	mu      sync.Mutex
	cmd     *exec.Cmd
	running bool
	onCrash func() // callback when xray crashes unexpectedly
}

// NewProcess creates a new Xray process manager.
func NewProcess(onCrash func()) *Process {
	return &Process{onCrash: onCrash}
}

// IsRunning returns whether xray is currently running.
func (p *Process) IsRunning() bool {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.running
}

// Start launches xray with the given config JSON bytes.
// It writes config to a temp file and runs xray-core.
func (p *Process) Start(configJSON []byte) error {
	p.mu.Lock()
	defer p.mu.Unlock()

	if p.running {
		return fmt.Errorf("xray is already running")
	}

	// Write config to temp file
	configDir, err := os.MkdirTemp("", "jhovpn")
	if err != nil {
		return fmt.Errorf("failed to create temp dir: %w", err)
	}
	configPath := filepath.Join(configDir, "config.json")
	if err := os.WriteFile(configPath, configJSON, 0644); err != nil {
		os.RemoveAll(configDir)
		return fmt.Errorf("failed to write config: %w", err)
	}

	// Find xray binary
	xrayBin := findXrayBinary()
	if xrayBin == "" {
		os.RemoveAll(configDir)
		return fmt.Errorf("xray binary not found. Place xray binary next to the application")
	}

	logFile, _ := os.OpenFile("xray_error.log", os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0644)
	p.cmd = exec.Command(xrayBin, "run", "-c", configPath)
	setProcAttr(p.cmd)
	// loglevel is "none" in config but we want to know if it crashes
	p.cmd.Stdout = logFile
	p.cmd.Stderr = logFile

	if err := p.cmd.Start(); err != nil {
		os.RemoveAll(configDir)
		return fmt.Errorf("failed to start xray: %w", err)
	}

	p.running = true

	// Monitor process in background; cleans up configDir when xray exits
	go func() {
		p.cmd.Wait() //nolint:errcheck
		p.mu.Lock()
		wasRunning := p.running
		p.running = false
		p.mu.Unlock()

		// Clean up temp config
		os.RemoveAll(configDir)

		// Invoke callback for any unexpected exit — clean or non-clean
		if wasRunning && p.onCrash != nil {
			p.onCrash()
		}
	}()

	return nil
}

// Stop gracefully stops the xray process with timeout before force killing.
func (p *Process) Stop() error {
	p.mu.Lock()
	if !p.running || p.cmd == nil || p.cmd.Process == nil {
		p.running = false
		p.mu.Unlock()
		return nil
	}
	p.running = false
	cmd := p.cmd
	p.mu.Unlock()

	// Try graceful shutdown first: send SIGTERM (or Interrupt on Windows)
	// This allows Xray to cleanup TUN adapter and flush buffers
	gracefulTimeout := time.Duration(3) * time.Second
	log.Printf("[Xray] Graceful shutdown requested (timeout: %v)", gracefulTimeout)
	
	// Send signal (SIGTERM on Unix/WIndows actually sends CTRL_BREAK)
	var sig os.Signal = syscall.SIGTERM
	if runtime.GOOS == "windows" {
		sig = os.Interrupt // Windows: Ctrl+C equivalent
	}
	
	if err := cmd.Process.Signal(sig); err != nil {
		log.Printf("[Xray] Graceful signal failed: %v, forcing kill", err)
		return cmd.Process.Kill()
	}
	
	// Wait for graceful exit with timeout
	done := make(chan error, 1)
	go func() {
		done <- cmd.Wait()
	}()
	
	select {
	case <-time.After(gracefulTimeout):
		// Timeout - force kill
		log.Printf("[Xray] Graceful shutdown timeout, force killing")
		if err := cmd.Process.Kill(); err != nil {
			log.Printf("[Xray] Force kill failed: %v", err)
			return err
		}
		// Wait for killed process to fully exit
		<-done
		return nil
	case err := <-done:
		// Process exited (either gracefully or from signal)
		if err != nil {
			log.Printf("[Xray] Process exit error: %v", err)
		}
		return nil
	}
}

// findXrayBinary looks for xray binary next to the executable, in PATH, or in current dir.
func findXrayBinary() string {
	names := []string{"xray"}
	if runtime.GOOS == "windows" {
		names = []string{"xray.exe"}
	}

	// Check next to executable
	if exePath, err := os.Executable(); err == nil {
		dir := filepath.Dir(exePath)
		for _, name := range names {
			p := filepath.Join(dir, name)
			if _, err := os.Stat(p); err == nil {
				return p
			}
		}
	}

	// Check current working directory
	if cwd, err := os.Getwd(); err == nil {
		for _, name := range names {
			p := filepath.Join(cwd, name)
			if _, err := os.Stat(p); err == nil {
				return p
			}
		}
	}

	// Check PATH
	for _, name := range names {
		if p, err := exec.LookPath(name); err == nil {
			return p
		}
	}

	return ""
}

// HasBinary reports whether xray executable can be found.
func HasBinary() bool {
	return findXrayBinary() != ""
}

