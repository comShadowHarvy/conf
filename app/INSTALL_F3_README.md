# install_f3 - F3 Tool Installer

F3 Tool Installer with automated functionality and user-friendly interface.

## 🚀 Features

- **Primary Function**: Builds and installs F3 from source with dependencies
- **User-Friendly**: Clear error messages and validation
- **Cross-Platform**: Works on Linux systems




## 📖 Usage

### Basic Usage

```bash
./install_f3
```

### Command Options

See the application's built-in help for detailed options:
```bash
install_f3 -h
```

## 📋 Requirements

### System Requirements
- **OS**: Linux (tested on Arch-based distributions)
- **Shell**: Bash 4.0+ (for shell scripts)

### Dependencies
- git, make, build tools

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
cp install_f3 ~/.local/bin/
chmod +x ~/.local/bin/install_f3
```

### System-wide Install
```bash
# Copy to system bin (requires sudo)
sudo cp install_f3 /usr/local/bin/
sudo chmod +x /usr/local/bin/install_f3
```

## 📚 Examples

### Example 1: Basic Usage
```bash
./install_f3
```



## 🚨 Common Issues

### Issue 1: Permission Denied
**Problem**: `Permission denied` when running
**Solution**: 
```bash
chmod +x install_f3
```

### Issue 2: Dependencies Missing
**Problem**: Required tools not found
**Solution**: Install the required dependencies using your package manager

## 🔍 Troubleshooting

Run with verbose output if available:
```bash
install_f3 -v [arguments]  # If supported
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
