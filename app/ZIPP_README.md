# Enhanced zipp - Multi-Format Compression Utility

A powerful, enhanced compression utility that supports multiple formats while maintaining full backward compatibility with the original bash version.

## 🚀 What's New

The enhanced `zipp` has been completely rewritten in Python and now includes:

### ✨ **Multiple Compression Formats**
- **ZIP** - Standard zip compression (original default)
- **TAR.GZ** - Gzip compression with parallel `pigz` support
- **TAR.XZ** - High-ratio XZ compression
- **7Z** - 7-Zip format (if `7z` command available)

### 🎯 **Smart Features**
- **Auto-format detection** from file extensions
- **Exclude patterns** with glob support (`.git/**`, `__pycache__/**`)
- **Configuration files** for default settings
- **Parallel compression** using `pigz` for tar.gz
- **Archive validation** after creation
- **Timestamp preservation** across all formats

### 🛠️ **Enhanced CLI**
- **Backward compatible** - existing `zipp file.txt` still works
- **Multiple sources** - `zipp file1.txt dir1/ file2.doc`
- **Compression levels** - `-l 0` (fastest) to `-l 9` (best)
- **Threading control** - `-j 8` for 8 threads
- **Verbose/quiet modes** - `-v` or `-q`

## 📖 Usage Examples

### Basic Usage (Backward Compatible)
```bash
# Original usage still works - creates file.txt.zip
zipp file.txt

# Directory compression - creates myproject.zip
zipp myproject/
```

### Multi-Format Support
```bash
# Create tar.gz archive with auto-detection
zipp -f tar.gz myproject/

# Create tar.xz with maximum compression
zipp -f tar.xz -l 9 docs/

# Create 7z archive (if 7z available)
zipp -f 7z -l 6 source_code/

# Auto-detect from output filename
zipp -o backup.tar.gz mydata/
```

### Exclude Patterns
```bash
# Exclude common development files
zipp -x ".git/**" -x "__pycache__/**" -x "*.pyc" project/

# Multiple exclude patterns
zipp --exclude "*.log" --exclude "node_modules/**" --exclude ".env" webapp/
```

### Advanced Options
```bash
# Fast compression with 8 threads
zipp -f tar.gz -l 1 -j 8 large_dataset/

# Quiet mode for scripts
zipp -q -f zip project/

# Verbose debugging
zipp -v -f tar.xz documents/

# Custom output name
zipp -o "backup-$(date +%Y%m%d).tar.gz" important_files/
```

## ⚙️ Configuration Files

Create a config file to set your preferred defaults:

```bash
# Generate sample config
zipp --create-config ~/.config/zipp/config.ini
```

Sample configuration:
```ini
[DEFAULT]
format = tar.gz
level = 6
preserve_timestamps = true
threads = 0
excludes = .git/** __pycache__/** *.pyc .DS_Store Thumbs.db node_modules/**
```

Config locations (in order of precedence):
1. `--config /path/to/config.ini`
2. `~/.config/zipp/config.ini`
3. `~/.zipp.ini`
4. `./.zipp.ini`

## 🏃‍♂️ Performance Tips

### Parallel Compression
- Install `pigz` for faster gzip compression: `sudo pacman -S pigz`
- Use `-j N` to control thread count
- TAR.GZ automatically uses `pigz` if available

### Format Selection by Use Case
- **ZIP**: Best compatibility, moderate compression
- **TAR.GZ**: Good balance, faster with `pigz`
- **TAR.XZ**: Highest compression ratio, slower
- **7Z**: Excellent compression, requires 7z package

### Compression Levels
- **Level 0**: Fastest, minimal compression
- **Level 1-3**: Fast compression, good for large files
- **Level 6**: Default balance (recommended)
- **Level 9**: Maximum compression, slower

## 🔧 Command Reference

```bash
zipp [-h] [-o OUTPUT] [-f FORMAT] [-l LEVEL] [-x EXCLUDE] [-j THREADS] 
     [-q] [-v] [--no-progress] [--no-timestamps] [--config CONFIG] 
     [--create-config PATH] [sources ...]

Options:
  -o, --output OUTPUT       Output archive name (auto-generated if not specified)
  -f, --format FORMAT       Compression format: auto, zip, tar.gz, tar.xz, 7z
  -l, --level LEVEL         Compression level 0-9 (0=fastest, 9=best)
  -x, --exclude PATTERN     Exclude files matching pattern (repeatable)
  -j, --threads THREADS     Number of threads for parallel compression
  -q, --quiet               Suppress non-essential output
  -v, --verbose             Enable verbose output
  --no-progress             Disable progress indicators
  --no-timestamps           Do not preserve timestamps
  --config CONFIG           Use specific configuration file
  --create-config PATH      Create sample configuration file
```

## 🔄 Migration from Original

The enhanced `zipp` is fully backward compatible:

```bash
# This still works exactly as before
zipp myfile.txt
# → Creates myfile.txt.zip with maximum compression (level 9)

# But now you have many more options
zipp -f tar.gz -l 6 -x ".git/**" myproject/
# → Creates myproject.tar.gz with default compression, excluding .git
```

## 🛡️ Safety Features

- **Overwrite protection**: Won't overwrite source files
- **Archive validation**: Tests created archives for integrity  
- **Interrupt handling**: Cleans up incomplete archives on Ctrl+C
- **Error recovery**: Detailed error messages and suggestions

## 📊 Output

The enhanced version provides detailed statistics:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Compression Summary for 'myproject/':
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Original Size   : 45.2MB (47,458,392 bytes)
Compressed Size : 12.3MB (12,891,456 bytes)
Space Saved     : 32.9MB (34,566,936 bytes)
Compression Ratio: 72.84%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🔧 Dependencies

**Required**:
- Python 3.6+
- Standard Unix tools (`tar`, `zip`, `unzip`)

**Optional** (auto-detected):
- `pigz` - Parallel gzip compression
- `7z` - 7-Zip format support  
- `pv` - Progress indicators

## 📁 Files

- `zipp` - Enhanced Python version
- `zipp.original` - Original bash backup
- `~/.config/zipp/config.ini` - Configuration file

---

*Enhanced zipp maintains the simplicity of the original while adding professional-grade features for power users.*
