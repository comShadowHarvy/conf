# Steam Deck SSH Setup

A simple script to install and configure SSH server on Steam Deck for remote access.

## What it does

This script automatically:
- Installs OpenSSH server using pacman
- Enables and starts the SSH service
- Helps you set a password for the `deck` user
- Shows your Steam Deck's IP address
- Optionally configures firewall rules
- Provides connection information

## Requirements

- Steam Deck running SteamOS
- Admin/sudo access
- Internet connection for package installation

## Installation & Usage

1. **Download the script** to your Steam Deck:
   ```bash
   # If you have git:
   git clone [your-repo-url]
   
   # Or copy the setup_steamdeck_ssh.sh file manually
   ```

2. **Make it executable**:
   ```bash
   chmod +x setup_steamdeck_ssh.sh
   ```

3. **Run the script**:
   ```bash
   ./setup_steamdeck_ssh.sh
   ```

4. **Follow the prompts**:
   - Enter your sudo password when prompted
   - Set a password for the `deck` user when asked
   - Optionally allow SSH through firewall

## After Setup

Once the script completes, you'll see output like:
```
=== Quick Connect Info ===
Your Steam Deck IP: 192.168.1.100
Connect with: ssh deck@192.168.1.100
```

## Connecting from other devices

### From Windows:
```cmd
ssh deck@YOUR_STEAMDECK_IP
```

### From Mac/Linux:
```bash
ssh deck@YOUR_STEAMDECK_IP
```

### Using hostname (if available):
```bash
ssh deck@steamdeck
```

## Security Notes

- The script enables password authentication by default
- Consider setting up SSH keys for better security
- You can disable password auth in `/etc/ssh/sshd_config` if using keys
- Restart SSH after config changes: `sudo systemctl restart sshd`

## Troubleshooting

### SSH service not starting
```bash
sudo systemctl status sshd
sudo journalctl -u sshd
```

### Can't connect from other devices
1. Check if SSH is running: `sudo systemctl status sshd`
2. Verify Steam Deck's IP: `ip addr show`
3. Test local connection: `ssh deck@localhost`
4. Check firewall: `sudo ufw status`

### Forgot Steam Deck password
Reset it with: `sudo passwd deck`

## What gets installed

- `openssh` package (SSH server)
- Service enabled to start on boot
- Default SSH configuration (port 22, password auth enabled)

## Uninstalling

To remove SSH server:
```bash
sudo systemctl stop sshd
sudo systemctl disable sshd
sudo pacman -R openssh
```

## Files modified

- SSH service files in `/etc/systemd/system/`
- SSH configuration in `/etc/ssh/sshd_config` (default settings)
- Password for `deck` user

---

**Note**: This script is designed specifically for Steam Deck's SteamOS (Arch-based). It may work on other Arch Linux systems but is optimized for Steam Deck use cases.