# eee - Universal Archive Extractor

A comprehensive archive extraction utility that handles virtually any compressed format and automatically creates organized extraction directories.

## 🚀 Features

- **Universal Format Support**: Handles ZIP, TAR, 7Z, RAR, DEB, RPM, ISO, and many compression formats
- **Automatic Format Detection**: Uses file magic and extension heuristics to determine format
- **Clean Extraction**: Creates `<basename>_extracted` directories for organized output
- **Batch Processing**: Process multiple archives in a single command
- **Error Tolerance**: Continues processing remaining archives even if one fails
- **Tool Detection**: Automatically detects and uses available extraction tools

## 📖 Usage

### Basic Usage

```bash
# Extract single archive
./eee archive.zip

# Extract multiple archives
./eee file1.tar.gz file2.7z file3.rar

# Extract all archives in directory
./eee *.zip
```

### Command Options

```bash
eee <archive1> [<archive2> ...]

Arguments:
  archive1, archive2...  One or more archive files to extract
```

## 🗂️ Supported Formats

### Archive Formats
- **ZIP** → `unzip`
- **TAR** variants → `tar`
  - `.tar` → `tar -xf`
  - `.tar.gz/.tgz` → `tar -xzf`
  - `.tar.bz2/.tbz2` → `tar -xjf`
  - `.tar.xz/.txz` → `tar -xJf`
  - `.tar.zst/.tzst` → `tar --use-compress-program=unzstd`
- **7Z** → `7z`
- **RAR** → `unrar`
- **ARJ** → `arj`

### Package Formats
- **DEB** → `dpkg-deb`
- **RPM** → `rpm2cpio | cpio`

### Compression Formats
- **GZ** → `gunzip`
- **BZ2** → `bunzip2`
- **XZ** → `unxz`
- **ZST** → `unzstd`
- **LZ** → `lunzip`
- **LZO** → `lzop`
- **LZMA** → `unlzma`

### Special Formats
- **ISO** → Mount notification (requires root)

## 📋 Requirements

### System Requirements
- **OS**: Linux, macOS, or Windows with Bash
- **Shell**: Bash 4.0+
- **Tools**: Various extraction utilities (see dependencies)

### Dependencies

The script automatically detects and uses available tools:

```bash
# Core utilities (usually pre-installed)
- file          # Format detection
- tar           # TAR archives
- unzip         # ZIP archives

# Additional tools (install as needed)
- 7z            # 7-Zip archives
- unrar         # RAR archives
- arj           # ARJ archives
- dpkg-deb      # Debian packages
- rpm2cpio      # RPM packages
- cpio          # RPM extraction
- gunzip        # Gzip decompression
- bunzip2       # Bzip2 decompression
- unxz          # XZ decompression
- unzstd        # Zstd decompression
- lunzip        # Lzip decompression
- lzop          # LZO decompression
- unlzma        # LZMA decompression
```

### Installation Commands
```bash
# Debian/Ubuntu
sudo apt install unzip p7zip-full unrar-free arj rpm2cpio cpio \
                  gzip bzip2 xz-utils zstd lzip lzop lzma

# Arch Linux
sudo pacman -S unzip p7zip unrar arj rpm-tools gzip bzip2 xz zstd lzip lzop

# macOS
brew install p7zip unrar arj rpm2cpio zstd lzip
```

## 🛠️ Installation

### Quick Install
```bash
# Copy to local bin directory
cp eee ~/.local/bin/
chmod +x ~/.local/bin/eee
```

### System-wide Install
```bash
# Copy to system bin (requires sudo)
sudo cp eee /usr/local/bin/
sudo chmod +x /usr/local/bin/eee
```

## ⚙️ Configuration

### Extraction Behavior
- **Output Directory**: `<archive_basename>_extracted`
- **Overwrite Protection**: Skips extraction if output directory exists
- **Format Detection**: Uses `file` command and extension fallback

### Customization
Edit the script to modify behavior:
```bash
# Change output directory pattern
local dest="${src%.*}_extracted"      # Current: filename_extracted
local dest="${src}_extracted"         # Alternative: filename.ext_extracted

# Modify detection priority
# Edit detect_format() function to prioritize certain formats
```

## 📚 Examples

### Example 1: Single Archive
```bash
./eee document.zip
```
Output:
```
=== Extracting: document.zip  (zip)  →  document_extracted ===
[Extraction process output...]
```
Creates: `document_extracted/` directory with contents

### Example 2: Multiple Archives
```bash
./eee backup.tar.gz photos.7z software.deb
```
Creates three directories:
- `backup_extracted/`
- `photos_extracted/`
- `software_extracted/`

### Example 3: Batch Processing
```bash
./eee *.tar.gz
```
Extracts all `.tar.gz` files in the current directory.

### Example 4: Mixed Formats
```bash
./eee archive.zip backup.tar.xz installer.deb firmware.bin
```
Processes all supported formats, skips unsupported ones with a warning.

## 🚨 Common Issues

### Issue 1: Tool Not Found
**Problem**: `command not found: unrar`
**Solution**: Install the required extraction tool:
```bash
# Arch Linux
sudo pacman -S unrar

# Ubuntu/Debian
sudo apt install unrar-free
```

### Issue 2: Directory Already Exists
**Problem**: `Destination directory already exists – skipping`
**Solution**: 
```bash
# Remove or rename existing directory
rm -rf archive_extracted/
# OR rename it
mv archive_extracted/ archive_extracted_old/
```

### Issue 3: Unknown Format
**Problem**: Archive format not recognized
**Solution**: Check file type manually:
```bash
file suspicious_archive
# May need to add support for new format in script
```

## 🔍 Troubleshooting

### Format Detection Issues
```bash
# Check file type detection
file archive.unknown

# Check if file has proper extension
mv archive.unknown archive.zip  # If it's actually a ZIP
```

### Permission Problems
```bash
# Ensure archive is readable
ls -la archive.zip

# Check available disk space
df -h .
```

### Extraction Failures
```bash
# Test archive integrity
unzip -t archive.zip        # For ZIP files
7z t archive.7z              # For 7Z files
tar -tf archive.tar.gz       # For TAR files
```

## 🧰 Format Detection Logic

The script uses a two-stage detection process:

1. **Magic Number Detection**: Uses `file` command to analyze file headers
2. **Extension Fallback**: If magic detection fails, uses file extension

```bash
# Example magic number detection
file archive.bin
# Output: "ZIP archive data, at least v1.0 to extract"
# Result: Detected as ZIP format
```

## ⚡ Performance Notes

- **Large Archives**: 7Z and TAR.XZ may be slow but provide better compression
- **Batch Processing**: Processing many small archives is faster than few large ones
- **Network Storage**: Extraction to network drives may be significantly slower
- **SSD vs HDD**: SSD significantly improves extraction speed for small files

## 🤝 Contributing

This script is part of a personal toolkit. If you find bugs or have suggestions:

1. Test with various archive formats and edge cases
2. Consider adding support for new compression formats
3. Ensure error handling doesn't break batch processing

## 📄 License

Created by **OpenAI ChatGPT** and adapted by **ShadowHarvy**

This script is provided as-is for educational and personal use.

## 🔗 Related Tools

- [7-Zip](https://www.7-zip.org/) - Universal archive utility
- [WinRAR](https://www.win-rar.com/) - RAR archive utility
- [The Unarchiver](https://theunarchiver.com/) - macOS archive utility
- [PeaZip](https://peazip.github.io/) - Cross-platform archive manager

---

*Part of the ShadowHarvy toolkit - Extract everything, organize nothing*
