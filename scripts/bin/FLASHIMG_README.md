# flashimg - Safe Disk Image Flasher

Flash disk images to storage devices with interactive drive selection and comprehensive safety checks.

## 🚀 Features

- **Primary Function**: Flash .img, .img.bz2, .img.xz, and .iso files to storage devices
- **Interactive Drive Selection**: Shows available devices and lets you choose safely
- **Multiple Format Support**: Handles compressed and raw image formats automatically
- **Safety Checks**: Multiple confirmations and warnings before destructive operations
- **Progress Tracking**: Real-time progress display during flashing
- **Auto Unmounting**: Automatically unmounts mounted partitions before flashing
- **Smart Validation**: Prevents flashing to partitions instead of devices

## 📖 Usage

### Basic Usage

```bash
./flashimg <image_file>
```

### Command Options

```bash
flashimg -h    # Show help message
flashimg --help    # Show help message
```

## 📋 Requirements

### System Requirements
- **OS**: Linux (tested on Arch-based distributions)
- **Shell**: Bash 4.0+ 
- **Privileges**: Regular user with sudo access (do NOT run as root)

### Dependencies
- dd (for disk writing)
- lsblk (for listing block devices)
- bzcat (for .img.bz2 decompression)
- xzcat (for .img.xz decompression)
- cat (for raw file handling)
- sudo (for privileged operations)

### Installation Commands
```bash
# Install dependencies (example for Arch Linux)
sudo pacman -S bzip2 xz coreutils util-linux sudo

# Ubuntu/Debian
sudo apt install bzip2 xz-utils coreutils util-linux sudo

# RHEL/CentOS/Fedora
sudo yum install bzip2 xz coreutils util-linux sudo
```

## 🛠️ Installation

### Quick Install
```bash
# Copy to local bin directory
cp flashimg ~/.local/bin/
chmod +x ~/.local/bin/flashimg
```

### System-wide Install
```bash
# Copy to system bin (requires sudo)
sudo cp flashimg /usr/local/bin/
sudo chmod +x /usr/local/bin/flashimg
```

## 📚 Examples

### Example 1: Flash Steam Deck recovery image
```bash
./flashimg steamdeck-recovery-4.img.bz2
```
The script will:
- Show available storage devices
- Ask you to select target device (e.g., sdb)
- Confirm the operation with multiple warnings
- Decompress and flash with progress display

### Example 2: Flash Raspberry Pi OS
```bash
./flashimg raspios-lite.img.xz
```
Handles XZ-compressed images automatically.

### Example 3: Flash Ubuntu ISO
```bash
./flashimg ubuntu-22.04-desktop-amd64.iso
```
Works with ISO files for creating bootable USB drives.

### Example 4: Flash raw IMG file
```bash
./flashimg custom-system.img
```
Direct flashing of raw disk images.

## 🔍 Supported File Formats

### Input Formats
- **`.img`** - Raw disk image files (direct flash)
- **`.img.bz2`** - Bzip2 compressed disk image files (decompress while flashing)
- **`.img.xz`** - XZ compressed disk image files (decompress while flashing)
- **`.iso`** - ISO 9660 disk image files (direct flash)

### Automatic Decompression
- **Bzip2**: Uses `bzcat` to decompress on-the-fly
- **XZ**: Uses `xzcat` to decompress on-the-fly
- **No intermediate files**: Streams directly to target device

## 🛡️ Safety Features

### Multiple Safety Checks
1. **File Validation**: Verifies image file exists and has valid extension
2. **Device Validation**: Ensures target is a device, not a partition
3. **Mount Detection**: Shows mounted partitions and warnings
4. **Multiple Confirmations**: Requires explicit confirmation before flashing
5. **Root Check**: Prevents running as root (uses sudo when needed)

### Interactive Workflow
```bash
1. Show available storage devices with mount status
2. Ask user to select target device by name
3. Display device information and mounted partitions
4. Warn about mounted partitions (if any)
5. Show final warning with device details
6. Require typing 'FLASH' to proceed
7. Unmount partitions automatically
8. Execute flash operation with progress
```

### Warning System
- **RED**: Critical warnings and errors
- **YELLOW**: Important notices and device info  
- **BLUE**: Progress and informational messages
- **GREEN**: Success confirmations

## 🚨 Common Issues

### Issue 1: Permission Denied
**Problem**: `Permission denied` when running
**Solution**: 
```bash
chmod +x flashimg
```

### Issue 2: Dependencies Missing
**Problem**: Required tools not found
**Solution**: Install the required dependencies:
```bash
# Arch Linux
sudo pacman -S bzip2 xz coreutils util-linux

# Ubuntu/Debian  
sudo apt install bzip2 xz-utils coreutils util-linux

# RHEL/CentOS/Fedora
sudo yum install bzip2 xz coreutils util-linux
```

### Issue 3: Running as Root
**Problem**: Script refuses to run as root
**Solution**: Run as regular user - the script will use sudo when needed:
```bash
# Wrong
sudo ./flashimg image.img

# Correct  
./flashimg image.img
```

### Issue 4: Device Busy/Mounted
**Problem**: Target device has mounted partitions
**Solution**: The script will:
- Show you which partitions are mounted
- Ask for confirmation to proceed
- Automatically unmount partitions before flashing

### Issue 5: Selecting Wrong Device
**Problem**: Accidentally selecting system drive
**Solution**: The script shows device info and requires:
- Typing exact device name (sdb, nvme0n1, etc.)
- Reviewing device information display
- Typing 'FLASH' in all caps to confirm

## 🔍 Troubleshooting

### Check Available Devices
```bash
# Manually list storage devices
lsblk -d -o NAME,SIZE,MODEL,VENDOR,TRAN
```

### Verify Image File
```bash
# Check if compressed file is valid
bzcat yourfile.img.bz2 | head -c 512 > /dev/null  # Test bz2
xzcat yourfile.img.xz | head -c 512 > /dev/null   # Test xz
```

### Manual Unmounting
```bash
# If script can't unmount, do it manually
sudo umount /dev/sdb1 /dev/sdb2  # etc.
```

### Check Device Status
```bash
# Check if device is busy
lsof /dev/sdb*
fuser -m /dev/sdb*
```

## 💡 Technical Notes

- **Block Size**: Uses 128M blocks for optimal performance
- **Sync Writes**: Uses `oflag=sync` for data integrity
- **Progress Display**: Shows real-time progress via dd status=progress
- **Streaming**: Compressed files are decompressed directly to device (no temp files)
- **Partition Detection**: Smart logic to prevent writing to partitions
- **Clean Unmounting**: Properly unmounts before writing

## ⚠️ Important Warnings

1. **DESTRUCTIVE OPERATION**: This completely erases target device
2. **No Undo**: Once started, the operation cannot be undone
3. **Select Carefully**: Double-check device selection - wrong choice = data loss
4. **External Drives Only**: Never flash your system drive
5. **Backup Important Data**: Ensure you have backups of important data

## 🤝 Contributing

This script is part of a personal toolkit. If you find bugs or have suggestions:

1. Check the source code for inline comments
2. Test your changes thoroughly
3. Consider the impact on existing workflows
4. Test with non-critical devices only

## 📄 License

Created by **ShadowHarvy**

This script is provided as-is for educational and personal use.

---

*Part of the ShadowHarvy toolkit - Automating the boring stuff since forever*