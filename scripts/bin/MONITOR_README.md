# monitor - Real-time Kernel Message Monitor

A sophisticated kernel message monitoring tool that displays dmesg output in real-time with intelligent color coding, clean formatting, and smart duplicate filtering.

## 🚀 Features

- **Real-time monitoring** - Uses modern `dmesg --follow` when available
- **Intelligent color coding** - Messages colored by severity and content type
- **Smart filtering** - Automatically filters duplicate messages using timestamps
- **Clean output** - Professional formatting with color-coded sections
- **Fallback support** - Uses polling method on older systems
- **Input validation** - Validates line count and provides helpful warnings
- **Graceful cleanup** - Proper signal handling and cursor restoration
- **Dependency checking** - Automatically verifies required tools are available

## 🎨 Color Legend

The monitor script uses intelligent color coding to help you quickly identify different types of kernel messages:

- **🔴 CRITICAL/ALERT** - System critical errors, panics, BUGs, segfaults
- **🟥 ERROR** - Error conditions, failed operations, cannot statements
- **🟡 WARNING** - Warning conditions and alerts
- **🟨 NOTICE** - Normal but significant events
- **🟢 INFO** - Informational messages
- **🔵 DEBUG** - Debug-level messages
- **🟣 USB/DEVICE** - Hardware device events (USB, hubs, devices)
- **🔷 NETWORK** - Network-related events (eth, wlan, tcp, ip)
- **🟦 SYSTEM** - Service start/stop, enable/disable events
- **💙 THERMAL** - Temperature, thermal, CPU-related messages
- **⚪ OTHER** - General kernel messages
- **🔘 TIMESTAMPS** - Message timestamps in muted gray

## 📖 Usage

### Basic Usage
```bash
monitor              # Show last 20 lines (default)
monitor 50           # Show last 50 lines  
monitor --help       # Show help information
```

### Command Options
```bash
monitor [number_of_lines]

Arguments:
  number_of_lines    Number of lines to display (default: 20)

Options:
  -h, --help         Show help message with color legend

Controls:
  Ctrl+C             Stop monitoring and exit
```

## 📋 Requirements

### System Requirements
- Linux system with kernel message support
- Bash 4.0 or higher
- Terminal with ANSI color support (most modern terminals)

### Dependencies
- `dmesg` - Kernel message display utility
- `sudo` - Elevated privileges for kernel access  
- `tail` - Text processing utility
- `awk` - Advanced text processing
- `tput` - Terminal control (optional, for cursor management)
- `watch` - Command watching utility (fallback only)

### Installation Commands
On Arch Linux:
```bash
# Core dependencies (usually pre-installed)
sudo pacman -S coreutils gawk sudo util-linux

# Optional for fallback mode
sudo pacman -S procps-ng
```

On Ubuntu/Debian:
```bash
# Core dependencies (usually pre-installed)  
sudo apt update
sudo apt install coreutils gawk sudo util-linux

# Optional for fallback mode
sudo apt install procps
```

## 🛠️ Installation

### Quick Install
Copy the script to your personal bin directory:
```bash
cp monitor ~/bin/
chmod +x ~/bin/monitor
```

### System-wide Install
Install for all users:
```bash
sudo cp monitor /usr/local/bin/
sudo chmod +x /usr/local/bin/monitor
```

## 📚 Examples

### Example 1: Basic monitoring with color coding
Monitor kernel messages with default settings:
```bash
monitor
```
Shows last 20 kernel messages with intelligent color coding, then monitors for new ones in real-time.

### Example 2: Extended history for troubleshooting
Monitor with more historical context:
```bash
monitor 100
```
Shows last 100 kernel messages before starting real-time monitoring - useful for debugging issues.

### Example 3: USB device troubleshooting
Monitor for USB device events:
```bash
# In one terminal, start monitoring
monitor

# In another terminal, plug/unplug USB device
# Watch for purple-colored USB-related kernel messages
```
USB/device messages appear in purple/magenta for easy identification.

### Example 4: Network issue diagnosis
Monitor network-related kernel events:
```bash
monitor 50
```
Network messages (ethernet, wifi, tcp, etc.) appear in cyan for quick spotting.

### Example 5: System startup analysis
Review boot messages and monitor ongoing activity:
```bash
monitor 200
```
Critical errors show in bright red, warnings in yellow - perfect for boot analysis.

## 🚨 Common Issues

### Issue 1: Permission denied
**Problem**: `dmesg: read kernel buffer failed: Operation not permitted`

**Solution**: 
- Script automatically uses sudo for kernel access
- Ensure your user account has sudo privileges
- You may be prompted for password on first run

### Issue 2: No color output
**Problem**: Output appears without colors

**Solution**:
- Ensure terminal supports ANSI colors (most modern terminals do)
- Try different terminal emulator (xterm, gnome-terminal, etc.)
- Colors automatically work in most environments
- Check if terminal has color support: `echo $COLORTERM`

### Issue 3: Colors don't match message content
**Problem**: Colors seem wrong for some messages

**Solution**:
- Color coding is based on content analysis and keywords
- Some messages may not match expected patterns
- This is normal - the system makes best guesses based on content
- Critical errors will always be highlighted in red

### Issue 4: High line count performance
**Problem**: Slow performance with many lines

**Solution**:
- Script warns when using >1000 lines
- Color processing adds minimal overhead
- Consider using smaller line counts for better performance
- Modern systems handle coloring efficiently

## 🔍 Troubleshooting

### Color Testing
Test color support in your terminal:
```bash
# Quick color test
echo -e "\033[31mRed\033[0m \033[32mGreen\033[0m \033[33mYellow\033[0m"

# Check color environment
echo $TERM
echo $COLORTERM
```

### Debug Mode
Add debug output by modifying the script:
```bash
# Add at top of script after colors
DEBUG=true
```

### Check Dependencies
Verify all required tools are available:
```bash
# Check core dependencies
which dmesg sudo tail awk

# Check optional dependencies  
which tput watch
```

### Manual Testing
Test kernel message access and coloring:
```bash
# Test basic dmesg access with colors
sudo dmesg | tail -20

# Test follow feature (modern systems)
sudo dmesg --follow
```

## 🎯 Advanced Usage

### Integration with System Monitoring
Use with other monitoring tools:
```bash
# Terminal multiplexer setup with colors
tmux new-session -d 'monitor 50'
tmux split-window -h 'htop'
tmux attach
```

### Log Analysis with Colors
Combine with other log analysis:
```bash
# Save colored output to file (preserving colors)
monitor | tee kernel_monitor.log

# View colored logs later
less -R kernel_monitor.log
```

### Custom Color Schemes
The script uses these color categories that can be customized:
- `BRIGHT_RED` - Critical/Alert messages
- `RED` - Error messages  
- `BRIGHT_YELLOW` - Warnings
- `YELLOW` - Notices
- `GREEN` - Info messages
- `BLUE` - Debug messages
- `PURPLE` - USB/Device events
- `CYAN` - Network events
- `BRIGHT_GREEN` - Service status
- `BRIGHT_BLUE` - System/thermal
- `WHITE` - General messages
- `GRAY` - Timestamps

## 🤝 Contributing

Improvements and bug fixes welcome! The script follows the ShadowHarvy toolkit format standards.

### Code Style
- Follow existing color scheme and formatting
- Include comprehensive error handling
- Add appropriate comments for complex logic
- Test color output on multiple terminal types

### Testing Checklist
- [ ] Works with and without `dmesg --follow` support
- [ ] Handles Ctrl+C interruption gracefully
- [ ] Validates input parameters correctly
- [ ] Colors display properly in various terminals
- [ ] Shows appropriate error messages
- [ ] Cleans up background processes on exit
- [ ] Color coding works for different message types

## 📄 License

Created by **ShadowHarvy** as part of the system administration toolkit.

Part of the ShadowHarvy script collection - professional tools for Linux system administration and monitoring with intelligent visual enhancements.
