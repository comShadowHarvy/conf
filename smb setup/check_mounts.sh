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
