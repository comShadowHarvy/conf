#!/bin/bash

set -e

echo "=== Master Setup: Delayed Mount + SMB + Mount Check ==="

echo ">>> Creating mount script..."
cat > /usr/local/bin/delayed-mount.sh <<'EOF'
#!/bin/bash

sleep 30

mount -L "Backup Plus" /mnt/usb
mount -L "My Passport" /mnt/usb2
mount -L "rom" /mnt/rom

systemctl restart smbd
EOF

chmod +x /usr/local/bin/delayed-mount.sh

echo ">>> Creating systemd service..."
cat > /etc/systemd/system/delayed-mount.service <<'EOF'
[Unit]
Description=Delayed Mount of USB Drives
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/delayed-mount.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable delayed-mount.service

echo ">>> Creating mount points..."
mkdir -p /mnt/usb /mnt/usb2 /mnt/rom

echo ">>> Setting up SMB shares..."

SMB_SHARES='
[USB-Share]
   path = /mnt/usb
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0777
   directory mask = 0777
   force user = root
   force group = root

[USB-Share-2]
   path = /mnt/usb2
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0777
   directory mask = 0777
   force user = root
   force group = root

[ROM-Share]
   path = /mnt/rom
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0777
   directory mask = 0777
   force user = root
   force group = root
'

if ! grep -q "\[USB-Share\]" /etc/samba/smb.conf; then
  echo "$SMB_SHARES" >> /etc/samba/smb.conf
  echo "Added SMB shares to smb.conf"
else
  echo "SMB shares already exist in smb.conf"
fi

testparm -s > /dev/null 2>&1
systemctl enable smbd
systemctl restart smbd

echo ">>> Creating mount check script..."
cat > /usr/local/bin/check_mounts.sh <<'EOF'
#!/bin/bash

MOUNTS=(
  "/mnt/usb:Backup Plus"
  "/mnt/usb2:My Passport"
  "/mnt/rom:rom"
)

LOG_FILE="/var/log/mount-check.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_and_remount() {
  local mount_point="$1"
  local label="$2"
  
  if ! mountpoint -q "$mount_point" 2>/dev/null; then
    log "WARNING: $mount_point is not mounted, attempting to mount..."
    mount -L "$label" "$mount_point" 2>>"$LOG_FILE"
    if mountpoint -q "$mount_point"; then
      log "SUCCESS: Remounted $mount_point"
    else
      log "ERROR: Failed to mount $mount_point"
      return 1
    fi
  fi
  
  if touch "$mount_point/.write_test" 2>/dev/null; then
    rm -f "$mount_point/.write_test"
    log "OK: $mount_point is writable"
    return 0
  else
    log "WARNING: $mount_point is not writable, attempting to remount..."
    umount "$mount_point" 2>>"$LOG_FILE" || umount -l "$mount_point" 2>>"$LOG_FILE"
    sleep 2
    mount -L "$label" "$mount_point" 2>>"$LOG_FILE"
    
    if touch "$mount_point/.write_test" 2>/dev/null; then
      rm -f "$mount_point/.write_test"
      log "SUCCESS: Remounted $mount_point and now writable"
      return 0
    else
      log "ERROR: Failed to remount $mount_point as writable"
      return 1
    fi
  fi
}

log "=== Starting mount check ==="

failed=0
for entry in "${MOUNTS[@]}"; do
  mount_point="${entry%%:*}"
  label="${entry##*:}"
  check_and_remount "$mount_point" "$label" || ((failed++))
done

if [ $failed -eq 0 ]; then
  log "=== All mounts OK ==="
else
  log "=== $failed mount(s) failed ==="
fi
EOF

chmod +x /usr/local/bin/check_mounts.sh

echo ">>> Setting up cron job..."
CRON_JOB="*/5 * * * * /usr/local/bin/check_mounts.sh"
(crontab -l 2>/dev/null | grep -v "check_mounts.sh"; echo "$CRON_JOB") | crontab -

echo "=== Setup Complete ==="
echo ""
echo "Summary:"
echo "  - Delayed mount service enabled (runs at boot after 30s delay)"
echo "  - SMB shares configured (USB-Share, USB-Share-2, ROM-Share)"
echo "  - Mount check cron job added (runs every 5 minutes)"
echo "  - Check logs at /var/log/mount-check.log"
