# Custom Scripts in ~/bin/

This directory contains custom scripts for X11 and network monitoring.

## Scripts Available

### 1. run-etherape
**Purpose**: Run etherape (network packet visualization tool) with proper sudo privileges and GUI access.

**Usage**:
```bash
run-etherape          # Start etherape normally
run-etherape -i eth0  # Monitor specific interface
run-etherape --help   # Show etherape help
```

**What it does**:
- Checks if etherape is installed
- Verifies graphical environment is available
- Runs etherape with sudo privileges while preserving GUI access
- Passes any command line arguments to etherape

**Requirements**: etherape must be installed (`sudo pacman -S etherape`)

### 2. install-x11
**Purpose**: Install complete X11 environment on Arch Linux.

**Usage**:
```bash
install-x11
```

**What it installs**:
- Xorg server (`xorg-server`)
- X11 utilities (`xorg-apps`, `xorg-xinit`)
- X11 client libraries (libx11, libxext, etc.)
- Tests the installation

**Features**:
- Colored output for easy reading
- Error checking at each step
- Installation verification
- Helpful suggestions for additional components

## PATH Configuration

These scripts are in `~/bin/` which should be in your PATH. If not, add this to your `~/.bashrc`:

```bash
export PATH="$HOME/bin:$PATH"
```

## Troubleshooting

### run-etherape issues:
- **"etherape is not installed"**: Run `sudo pacman -S etherape`
- **"No graphical display detected"**: Make sure you're in a GUI session
- **Permission denied**: The script will prompt for your sudo password

### install-x11 issues:
- **"This script is designed for Arch Linux"**: Only works on Arch Linux
- **"Don't run this script as root"**: Run as regular user, not with sudo

## Example Workflows

1. **First time setup**:
   ```bash
   install-x11        # Install X11
   sudo pacman -S etherape  # Install etherape
   run-etherape       # Start monitoring
   ```

2. **Regular use**:
   ```bash
   run-etherape -i wlan0  # Monitor WiFi interface
   ```

## Notes

- Both scripts include comprehensive error checking
- The etherape script preserves your GUI environment when using sudo
- The X11 installer only installs what's necessary for basic functionality
- Scripts are designed to be user-friendly with clear error messages
