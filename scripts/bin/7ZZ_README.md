# 7zz - 7-Zip Compression Wrapper

7-Zip Compression Wrapper with automated functionality and user-friendly interface.

## 🚀 Features

- **Primary Function**: Ultra-compression wrapper for 7z with progress tracking
- **User-Friendly**: Clear error messages and validation
- **Cross-Platform**: Works on Linux systems




## 📖 Usage

### Basic Usage

```bash
./7zz file_or_directory
```

### Command Options

See the application's built-in help for detailed options:
```bash
7zz -h
```

## 📋 Requirements

### System Requirements
- **OS**: Linux (tested on Arch-based distributions)
- **Shell**: Bash 4.0+ (for shell scripts)

### Dependencies
- 7z command from p7zip

### Installation Commands
```bash
# Install dependencies (example for Arch Linux)
# Adjust package names for your distribution
sudo pacman -S [required-packages]
```

## 🛠️ Installation

### Quick Install
```bash
# Copy to local bin directory
cp 7zz ~/.local/bin/
chmod +x ~/.local/bin/7zz
```

### System-wide Install
```bash
# Copy to system bin (requires sudo)
sudo cp 7zz /usr/local/bin/
sudo chmod +x /usr/local/bin/7zz
```

## 📚 Examples

### Example 1: Basic Usage
```bash
./7zz file_or_directory
```



## 🚨 Common Issues

### Issue 1: Permission Denied
**Problem**: `Permission denied` when running
**Solution**: 
```bash
chmod +x 7zz
```

### Issue 2: Dependencies Missing
**Problem**: Required tools not found
**Solution**: Install the required dependencies using your package manager

## 🔍 Troubleshooting

Run with verbose output if available:
```bash
7zz -v [arguments]  # If supported
```

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
