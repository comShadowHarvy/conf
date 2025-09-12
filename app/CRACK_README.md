# crack - WPA/WPA2 WiFi Password Cracker

An automated script for cracking WPA/WPA2 WiFi passwords using Hashcat with customizable wordlist directories.

## 🚀 Features

- **Automated Hashcat Workflow**: Converts cap files to hc22000 format and runs dictionary attacks
- **Multiple Wordlist Support**: Uses all available wordlist directories in a single session
- **Default Wordlist Discovery**: Automatically finds wordlists in common locations
- **Progress Logging**: Saves cracked passwords to a persistent log file
- **Error Handling**: Validates inputs and provides helpful error messages

## 📖 Usage

### Basic Usage

```bash
# Use default wordlists
./crack capture_file.cap

# Use specific wordlist file or directory
./crack capture_file.cap /path/to/wordlist.txt
./crack capture_file.cap /path/to/wordlist/directory/
```

### Command Options

```bash
crack <capture_file.cap> [wordlist_file_or_dir]

Arguments:
  capture_file.cap      WiFi packet capture file from airodump-ng
  wordlist_file_or_dir  Optional: specific wordlist file or directory
                       If not provided, uses default wordlist directories
```

## 🎯 Default Wordlist Directories

The script automatically searches these locations for wordlists:
- `~/git/wordlists/wordlists/passwords` - Personal wordlist collection
- `/usr/share/seclists/Passwords` - SecLists password collection

If multiple directories exist, all are used simultaneously in the attack.

## 📋 Requirements

### System Requirements
- **OS**: Linux (tested on Arch-based distributions)
- **RAM**: At least 4GB recommended for large wordlists
- **GPU**: NVIDIA or AMD GPU recommended for faster cracking

### Dependencies
- `hashcat` - Password recovery tool
- `hcxtools` (specifically `hcxpcapngtool`) - Packet capture conversion tools

### Installation Commands
```bash
# Arch Linux
sudo pacman -S hashcat hcxtools

# Debian/Ubuntu
sudo apt install hashcat hcxtools

# Install wordlists (optional)
# SecLists
sudo apt install seclists
# OR download manually
git clone https://github.com/danielmiessler/SecLists.git ~/git/wordlists/
```

## 🛠️ Installation

### Quick Install
```bash
# Copy to local bin directory
cp crack ~/.local/bin/
chmod +x ~/.local/bin/crack
```

### System-wide Install
```bash
# Copy to system bin (requires sudo)
sudo cp crack /usr/local/bin/
sudo chmod +x /usr/local/bin/crack
```

## ⚙️ Configuration

### Cracked Passwords Log
- **Location**: `~/cracked.log`
- **Format**: `ESSID:Password` (one per line)
- **Automatic**: All successful cracks are logged here

### Wordlist Configuration
Edit the script to modify default wordlist directories:
```bash
DEFAULT_WORDLIST_DIRS=(
  "~/git/wordlists/wordlists/passwords"
  "/usr/share/seclists/Passwords"
  "/path/to/your/wordlists"  # Add custom directories
)
```

## 📚 Examples

### Example 1: Basic Attack with Default Wordlists
```bash
./crack handshake.cap
```
Output:
```
[*] No wordlist specified. Locating all default wordlist directories...
[+] Adding directory to session: /home/user/git/wordlists/wordlists/passwords
[+] Adding directory to session: /usr/share/seclists/Passwords
[*] Converting handshake.cap to handshake.hc22000...
[+] Conversion successful.
[*] Starting Hashcat attack. Cracked keys will be saved to /home/user/cracked.log
```

### Example 2: Specific Wordlist File
```bash
./crack handshake.cap /usr/share/wordlists/rockyou.txt
```

### Example 3: Custom Wordlist Directory
```bash
./crack handshake.cap ~/my-wordlists/
```

## 🚨 Common Issues

### Issue 1: No Valid Handshake
**Problem**: `Conversion failed. The capture file might not contain a valid handshake`
**Solution**: 
1. Ensure you captured a complete 4-way handshake
2. Use `aircrack-ng` to verify: `aircrack-ng -w /dev/null capture.cap`
3. Recapture the handshake if necessary

### Issue 2: Hashcat Not Found
**Problem**: `hashcat is not installed or not in your PATH`
**Solution**: Install hashcat and ensure it's in PATH:
```bash
sudo pacman -S hashcat  # Arch
sudo apt install hashcat  # Ubuntu/Debian
which hashcat  # Verify installation
```

### Issue 3: No Wordlists Found
**Problem**: `None of the default wordlist directories were found`
**Solution**: Download wordlists:
```bash
# Install SecLists
sudo apt install seclists
# OR clone popular wordlists
git clone https://github.com/danielmiessler/SecLists.git ~/wordlists/
```

## 🔍 Troubleshooting

### Monitor Hashcat Progress
During the attack, use these Hashcat hotkeys:
- Press `s` - Show status
- Press `p` - Pause/resume
- Press `q` - Quit attack

### Check Cracked Passwords
```bash
# View all cracked passwords
cat ~/cracked.log

# Search for specific network
grep "MyNetwork" ~/cracked.log
```

### Hashcat Performance Tuning
```bash
# Check Hashcat devices
hashcat -I

# Force specific device (example)
hashcat -d 1 -m 22000 -a 0 handshake.hc22000 wordlist.txt

# Optimize workload (example)
hashcat -w 3 -m 22000 -a 0 handshake.hc22000 wordlist.txt
```

## ⚖️ Legal and Ethical Notice

**IMPORTANT**: This tool is for educational and authorized testing purposes only.

- ✅ **Legal Uses**: Testing your own networks, authorized penetration testing, learning
- ❌ **Illegal Uses**: Attacking networks you don't own, unauthorized access

Always ensure you have explicit permission before testing any wireless network.

## 🛡️ WiFi Security Recommendations

To protect against this type of attack:
1. **Use WPA3**: Upgrade to WPA3 if supported
2. **Strong Passwords**: Use long, complex passwords (20+ characters)
3. **Regular Updates**: Keep router firmware updated
4. **Monitor Access**: Regularly check connected devices

## 🤝 Contributing

This script is part of a personal toolkit. If you find bugs or have suggestions:

1. Test changes with your own networks only
2. Ensure compliance with local laws
3. Consider the ethical implications of any modifications

## 📄 License

Created by **ShadowHarvy**

This script is provided as-is for educational and authorized testing purposes only.

## 🔗 Related Tools

- [Hashcat](https://hashcat.net/hashcat/) - Advanced password recovery
- [Aircrack-ng](https://www.aircrack-ng.org/) - WiFi security auditing tools
- [SecLists](https://github.com/danielmiessler/SecLists) - Security wordlists collection
- [Hcxtools](https://github.com/ZerBea/hcxtools) - WiFi packet analysis tools

---

*Part of the ShadowHarvy toolkit - Keeping your WiFi security in check*
