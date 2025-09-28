# img2iso - Image to ISO Converter

Convert .img, .img.bz2, and .img.xz disk image files to .iso format with progress feedback and size statistics.

## 🚀 Features

- **Primary Function**: Converts IMG and compressed IMG.BZ2/IMG.XZ files to ISO format
- **Batch Processing**: Handle multiple files in a single command
- **Smart Decompression**: Automatically handles .img.bz2 and .img.xz files
- **Size Reporting**: Shows original and converted file sizes
- **Safe Operations**: Prompts before overwriting existing files
- **Progress Tracking**: Clear feedback during conversion process
- **Error Handling**: Comprehensive error checking and cleanup

## 📖 Usage

### Basic Usage

```bash
./img2iso <image_file1> [image_file2] ...
```

### Command Options

```bash
img2iso -h    # Show help message
img2iso --help    # Show help message
```

## 📋 Requirements

### System Requirements
- **OS**: Linux (tested on Arch-based distributions)
- **Shell**: Bash 4.0+ 

### Dependencies
- bzip2 (for .img.bz2 decompression)
- bunzip2 (for .img.bz2 decompression)
- xz (for .img.xz decompression)
- unxz (for .img.xz decompression)
- cp (for file copying)
- stat (for file size reporting)
- file (for file type detection)

### Installation Commands
```bash
# Install dependencies (example for Arch Linux)
sudo pacman -S bzip2 xz coreutils file
```

## 🛠️ Installation

### Quick Install
```bash
# Copy to local bin directory
cp img2iso ~/.local/bin/
chmod +x ~/.local/bin/img2iso
```

### System-wide Install
```bash
# Copy to system bin (requires sudo)
sudo cp img2iso /usr/local/bin/
sudo chmod +x /usr/local/bin/img2iso
```

## 📚 Examples

### Example 1: Convert single .img file
```bash
./img2iso diskimage.img
```
Creates `diskimage.iso` in the same directory.

### Example 2: Convert compressed .img.bz2 file
```bash
./img2iso compressed_image.img.bz2
```
Decompresses and converts to `compressed_image.iso`.

### Example 3: Convert .img.xz file
```bash
./img2iso xz_compressed.img.xz
```
Decompresses and converts to `xz_compressed.iso`.

### Example 4: Batch conversion
```bash
./img2iso image1.img image2.img.bz2 image3.img.xz
```
Converts multiple files at once with progress tracking.

### Example 4: Show help
```bash
./img2iso -h
```

## 🔍 Supported File Formats

### Input Formats
- **`.img`** - Raw disk image files (direct copy to .iso)
- **`.img.bz2`** - Bzip2 compressed disk image files (decompress then copy to .iso)
- **`.img.xz`** - XZ compressed disk image files (decompress then copy to .iso)

### Output Format
- **`.iso`** - ISO 9660 disk image format

## 🚨 Common Issues

### Issue 1: Permission Denied
**Problem**: `Permission denied` when running
**Solution**: 
```bash
chmod +x img2iso
```

### Issue 2: Dependencies Missing
**Problem**: Required tools not found
**Solution**: Install the required dependencies:
```bash
# Arch Linux
sudo pacman -S bzip2 coreutils file

# Ubuntu/Debian
sudo apt install bzip2 xz-utils coreutils file

# RHEL/CentOS/Fedora
sudo yum install bzip2 xz coreutils file
```

### Issue 3: File Already Exists
**Problem**: Output .iso file already exists
**Solution**: The script will prompt you to overwrite. Choose 'y' to overwrite or 'N' to skip.

### Issue 4: Insufficient Disk Space
**Problem**: Not enough space for conversion
**Solution**: Free up disk space or move files to a location with more space.

## 🔍 Troubleshooting

### Check File Status
```bash
# Verify input file exists and is readable
ls -la your_image_file.img
file your_image_file.img
```

### Manual Decompression Test
```bash
# Test .img.bz2 decompression manually
bunzip2 -t your_image.img.bz2

# Test .img.xz decompression manually
unxz -t your_image.img.xz
```

### Check Available Space
```bash
# Check disk space
df -h .
```

## 💡 Technical Notes

- IMG and ISO files are essentially the same format for disk images
- The conversion is primarily a file copy operation with extension change
- For .img.bz2 and .img.xz files, decompression occurs in a temporary directory
- Temporary files are automatically cleaned up on script exit
- File size statistics help verify successful conversion

## 🤝 Contributing

This script is part of a personal toolkit. If you find bugs or have suggestions:

1. Check the source code for inline comments
2. Test your changes thoroughly  
3. Consider the impact on existing workflows

## 📄 License

Created by **ShadowHarvy**

This script is provided as-is for educational and personal use.

---

*Part of the ShadowHarvy toolkit - Automating the boring stuff since forever*