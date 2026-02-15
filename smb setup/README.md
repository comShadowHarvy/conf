# USB Drive Setup Scripts

Scripts to set up delayed mounting, SMB shares, and mount health monitoring.

## Usage

Deploy and run on the server:

```bash
scp master_setup.sh root@192.168.1.47:/tmp/
ssh root@192.168.1.47 "bash /tmp/master_setup.sh"
```

Or run individual scripts:

```bash
# Delayed mount only
scp setup_delayed_mount.sh root@192.168.1.47:/tmp/
ssh root@192.168.1.47 "bash /tmp/setup_delayed_mount.sh"

# SMB shares only
scp setup_smb_shares.sh root@192.168.1.47:/tmp/
ssh root@192.168.1.47 "bash /tmp/setup_smb_shares.sh"

# Mount check cron only
scp check_mounts.sh setup_mount_check_cron.sh root@192.168.1.47:/tmp/
ssh root@192.168.1.47 "bash /tmp/setup_mount_check_cron.sh"
```

## What Each Script Does

### master_setup.sh
Runs everything: delayed mount + SMB shares + mount check cron.

### setup_delayed_mount.sh
- Creates `/usr/local/bin/delayed-mount.sh`
- Enables systemd service to run at boot
- Waits 30s after boot, then mounts:
  - `Backup Plus` → `/mnt/usb`
  - `My Passport` → `/mnt/usb2`
  - `rom` → `/mnt/rom`
- Restarts Samba after mounting

### setup_smb_shares.sh
Adds these shares to `/etc/samba/smb.conf`:
- `USB-Share` → `/mnt/usb`
- `USB-Share-2` → `/mnt/usb2`
- `ROM-Share` → `/mnt/rom`

All shares are:
- Writable by guest
- Browsable
- Full permissions (0777)

### check_mounts.sh
Checks mount points every 5 minutes (via cron):
- Verifies mounts are actually mounted
- Tests write access
- If not writable: unmounts and remounts
- Logs to `/var/log/mount-check.log`

## Files Created

| Path | Description |
|------|-------------|
| `/usr/local/bin/delayed-mount.sh` | Mount script |
| `/usr/local/bin/check_mounts.sh` | Health check script |
| `/etc/systemd/system/delayed-mount.service` | Systemd service |
| `/var/log/mount-check.log` | Mount check logs |

## Cron Job

```
*/5 * * * * /usr/local/bin/check_mounts.sh
```

Runs every 5 minutes to verify mounts are writable.
