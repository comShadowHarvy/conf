# dialtest - Device Permissions Helper v2.1

Device Permissions Helper v2.1 with automated functionality and user-friendly interface.

## 🚀 Features

- **Primary Function**: Legacy device permissions tool with personalities
- **User-Friendly**: Clear error messages and validation
- **Cross-Platform**: Works on Linux systems
- **Multiple Personalities**: Choose from wizard, GLaDOS, DM, sassy, or sarcastic modes

## 🎭 Personalities

This application supports multiple personalities for a more engaging experience:

- **🧙‍♂️ Wizard**: Mystical and wise, speaks of artifacts and rituals
- **🤖 GLaDOS**: Sarcastic AI from Portal, treats you like a test subject
- **🏰 DM**: D&D dungeon master, frames everything as adventures
- **😤 Sassy**: Impatient but helpful, gets straight to the point
- **😏 Sarcastic**: Dry wit and barely contained frustration

Choose a personality with \`-p <persona>\` or let the system choose randomly.

## 📖 Usage

### Basic Usage

```bash
./dialtest -p wizard -d /dev/ttyACM0
```

### Command Options

See the application's built-in help for detailed options:
```bash
dialtest -h
```

## 📋 Requirements

### System Requirements
- **OS**: Linux (tested on Arch-based distributions)
- **Shell**: Bash 4.0+ (for shell scripts)

### Dependencies
- Standard Unix utilities

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
cp dialtest ~/.local/bin/
chmod +x ~/.local/bin/dialtest
```

### System-wide Install
```bash
# Copy to system bin (requires sudo)
sudo cp dialtest /usr/local/bin/
sudo chmod +x /usr/local/bin/dialtest
```

## 📚 Examples

### Example 1: Basic Usage
```bash
./dialtest -p wizard -d /dev/ttyACM0
```

### Example 2: With Personality
```bash
dialtest -p wizard [arguments]
```

## 🚨 Common Issues

### Issue 1: Permission Denied
**Problem**: `Permission denied` when running
**Solution**: 
```bash
chmod +x dialtest
```

### Issue 2: Dependencies Missing
**Problem**: Required tools not found
**Solution**: Install the required dependencies using your package manager

## 🔍 Troubleshooting

Run with verbose output if available:
```bash
dialtest -v [arguments]  # If supported
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
