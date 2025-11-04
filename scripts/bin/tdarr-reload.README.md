# Tdarr Network Share Reloader

**Author:** ShadowHarvy  
**Version:** 1.0  
**Purpose:** Automatically stops Tdarr, remounts network shares, and restarts Tdarr with a beautiful loading screen

---

## Features

✨ **Beautiful ASCII Title Screen** - Eye-catching branded interface  
🎨 **Color-Coded Status Messages** - Clear visual feedback  
⏳ **Animated Loading Bar** - 12-second countdown with progress visualization  
🔄 **Automatic Remounting** - Handles network share remounting seamlessly  
✅ **Verification System** - Checks all expected directories are accessible  
🐳 **Docker Integration** - Manages Tdarr container lifecycle automatically  

---

## Installation

The script is already installed at:
```
~/bin/tdarr-reload
```

Make it executable (if not already):
```bash
chmod +x ~/bin/tdarr-reload
```

Add `~/bin` to your PATH (if not already in your `.bashrc` or `.zshrc`):
```bash
export PATH="$HOME/bin:$PATH"
```

---

## Usage

### Basic Usage
Simply run the script:
```bash
tdarr-reload
```

Or with full path:
```bash
~/bin/tdarr-reload
```

### What It Does

1. **Displays Title Screen** - Shows the Tdarr Reload banner
2. **Stops Tdarr** - Gracefully stops the `tdarr-node` Docker container
3. **Remounts Shares** - Executes the SMB mounting script at `~/betterstrap/smb.sh`
4. **Waits 12 Seconds** - Shows animated loading bar while shares stabilize
5. **Verifies Shares** - Checks that all expected directories are accessible:
   - downloads
   - emulatorjs
   - incomplete
   - jellyfin
   - metube
   - minecraftbe
   - ollama
   - qBittorrent
   - storage
   - taildrop
   - trans
   - USB1
   - USB2
6. **Restarts Tdarr** - Starts the `tdarr-node` container with fresh mounts
7. **Success Screen** - Displays completion status

---

## Configuration

Edit the script to customize these variables:

```bash
TDARR_CONTAINER="tdarr-node"              # Docker container name
SMB_SCRIPT="$HOME/betterstrap/smb.sh"     # Path to SMB mount script
SHARE_PATH="/share"                        # Share mount point
WAIT_TIME=12                               # Seconds to wait after remounting
```

---

## Requirements

- **Docker** - For managing Tdarr container
- **sudo access** - For remounting network shares
- **SMB script** - Located at `~/betterstrap/smb.sh`
- **Bash 4.0+** - For array support
- **Terminal with color support** - For best visual experience

---

## Troubleshooting

### Script fails to find SMB script
**Error:** `SMB script not found at ~/betterstrap/smb.sh`  
**Solution:** Update the `SMB_SCRIPT` variable to point to your actual mount script location

### Container won't start
**Error:** `Failed to start Tdarr container`  
**Solution:** 
- Check Docker is running: `systemctl status docker`
- Check container exists: `docker ps -a | grep tdarr`
- Check logs: `docker logs tdarr-node`

### Missing directories
**Warning:** `Missing directories: [list]`  
**Solution:** 
- Verify network shares are properly configured
- Check `/etc/fstab` entries
- Ensure SMB credentials are correct
- Check network connectivity to NAS/share host

### Permission denied
**Error:** When running the script  
**Solution:** 
- Make executable: `chmod +x ~/bin/tdarr-reload`
- Ensure sudo access for mounting: `sudo -v`

---

## Exit Codes

- `0` - Success
- `1` - Error (SMB script not found, container failed to start, etc.)

---

## Visual Preview

When you run the script, you'll see:

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
        ████████╗██████╗  █████╗ ██████╗ ██████╗     ██████╗ ...
        ╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██╔══██╗    ██╔══██╗...
           ██║   ██║  ██║███████║██████╔╝██████╔╝    ██████╔╝...
           ...
║                                                                              ║
                        Network Share Reloader v1.0
                              by ShadowHarvy
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

[INFO] Stopping Tdarr container...
[✓] Tdarr container stopped successfully

[INFO] Remounting network shares...
[✓] Network shares remounted

Waiting for shares to stabilize...
[████████████████████████████████████░░░░░░░░░░░] 75%
```

---

## Advanced Usage

### Run as a Cron Job
To automatically reload shares daily at 3 AM:
```bash
crontab -e
# Add this line:
0 3 * * * /home/me/bin/tdarr-reload >> /home/me/tdarr-reload.log 2>&1
```

### Create an Alias
Add to your `.bashrc` or `.zshrc`:
```bash
alias treload='tdarr-reload'
```

### Run with Notification
If you have `notify-send` installed:
```bash
tdarr-reload && notify-send "Tdarr Reload" "Completed successfully!"
```

---

## License

Free to use and modify. Attribution to ShadowHarvy appreciated!

---

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review Docker and SMB logs
3. Verify network connectivity
4. Check file permissions

---

## Changelog

### v1.0 (2025-11-02)
- Initial release
- ASCII art title screen
- Color-coded status messages
- Animated loading bar
- Share verification
- Docker container management
- Full error handling

---

**Enjoy your automated Tdarr reloads! 🎬**
