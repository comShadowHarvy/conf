#!/usr/bin/env bash
# ============================================================================
# Drive Formatter Tool
# ============================================================================

set -e

# formatting options
FORMATS=("ext4" "fat32" "exfat" "btrfs" "xfs" "f2fs")

echo "=========================================="
echo "      CONNECTED STORAGE DEVICES"
echo "=========================================="
# List disk devices with model, size, and transport info
lsblk -d -p -o NAME,MODEL,SIZE,TYPE,FSTYPE,TRAN | grep -v "loop"
echo "=========================================="

echo ""
read -r -p "Enter the device path to format (e.g., /dev/sdb): " DEVICE

if [[ ! -b "$DEVICE" ]]; then
    echo "Error: Device '$DEVICE' not found or is not a block device."
    exit 1
fi

# Basic safety check: don't let them easily format the root partition/disk if possible to detect simple mismatch
# (Comprehensive protection is hard, but we can warn if it's mounted as /)
if lsblk "$DEVICE" | grep -q " /"; then
    echo "CRITICAL WARNING: This device appears to contain your ROOT filesystem (/)."
    echo "Operation ABORTED for safety."
    exit 1
fi

echo ""
echo "Select File System:"
select FS in "${FORMATS[@]}"; do
    if [[ -n "$FS" ]]; then
        break
    else
        echo "Invalid selection. Try again."
    fi
done

echo ""
echo "WARNING: YOU ARE ABOUT TO FORMAT $DEVICE AS $FS."
echo "ALL DATA ON $DEVICE WILL BE PERMANENTLY LOST."
read -r -p "Type 'YES' to continue: " CONFIRM

if [[ "$CONFIRM" != "YES" ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo "Formatting $DEVICE as $FS..."

case "$FS" in
    "ext4")
        CMD="mkfs.ext4 -F"
        ;;
    "fat32")
        CMD="mkfs.fat -F 32 -I"
        ;;
    "exfat")
        CMD="mkfs.exfat"
        ;;
    "btrfs")
        CMD="mkfs.btrfs -f"
        ;;
    "xfs")
        CMD="mkfs.xfs -f"
        ;;
    "f2fs")
        CMD="mkfs.f2fs -f"
        ;;
    *)
        echo "Unknown filesystem."
        exit 1
        ;;
esac

# Execute with sudo
sudo $CMD "$DEVICE"

echo ""
echo "Format complete. New listing:"
lsblk -d -p -o NAME,FSTYPE,SIZE,UUID "$DEVICE"
