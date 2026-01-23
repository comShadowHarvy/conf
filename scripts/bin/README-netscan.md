# NetScan - Network Discovery and Port Scanning Tool

Advanced network scanning utility combining nmap and arp-scan capabilities for comprehensive network reconnaissance.

## 🚀 Features

- **Interactive Menu System** - Easy-to-use interface for all scanning operations
- **Multiple Scan Types** - Quick, full, ARP, and custom scanning options
- **Network Interface Detection** - Automatic discovery and selection of network interfaces
- **Progress Indicators** - Real-time feedback during scanning operations
- **Summary Reports** - Detailed statistics and results analysis
- **Output Logging** - Save scan results to files for later analysis
- **Color-Coded Output** - Enhanced readability with color-coded messages
- **Flexible Input Options** - Both interactive and command-line modes

## 📖 Usage

### Interactive Mode (Recommended)
```bash
netscan
```

### Command Line Mode
```bash
# Quick scan with specific interface and range
netscan -i wlan0 -r 192.168.1.0/24

# Save output to file
netscan -o scan_results.txt

# Full command line specification
netscan -i wlan0 -r 192.168.1.0/24 -o network_scan.txt
```

### Command Options

- `-h, --help`     - Show help message and usage examples
- `-i, --interface IFACE` - Specify network interface (e.g., wlan0, eth0)
- `-r, --range RANGE`     - Specify target range in CIDR notation (e.g., 192.168.1.0/24)
- `-o, --output FILE`     - Save output to specified file

## 📋 Requirements

### System Requirements
- **Operating System**: Linux (tested on Arch Linux)
- **Shell**: Bash 4.0 or higher
- **Privileges**: Some scans require root access (sudo)

### Dependencies
- **nmap** - Network exploration and security auditing
- **arp-scan** - ARP packet scanning tool
- **ip** - Show and manipulate routing, network devices (iproute2)
- **python3** - For network range calculations

### Installation Commands

#### Arch Linux
```bash
sudo pacman -S nmap arp-scan iproute2 python
```

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install nmap arp-scan iproute2 python3
```

#### CentOS/RHEL/Fedora
```bash
sudo yum install nmap arp-scan iproute python3
```

## 🛠️ Installation

### Quick Install
1. Download the script to your personal bin directory:
   ```bash
   curl -o ~/bin/netscan https://raw.githubusercontent.com/user/repo/main/netscan
   chmod +x ~/bin/netscan
   ```

2. Ensure `~/bin` is in your PATH:
   ```bash
   echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

### System-wide Install
```bash
sudo cp netscan /usr/local/bin/
sudo chmod +x /usr/local/bin/netscan
```

## 📚 Examples

### Example 1: Basic Interactive Usage
```bash
$ netscan
=== NetScan - Network Discovery Tool ===

Select scan type:
1) Quick scan (host discovery + common ports)
2) Full scan (comprehensive with service detection)  
3) ARP scan (local network discovery)
4) Custom scan (user-defined parameters)
5) List network interfaces
6) Exit

Choose an option (1-6): 1

Select network interface:
1) wlan0
2) docker0
Choose interface (1-2): 1

Enter target range [default: 192.168.1.0/24]: 

=== Quick Network Scan ===
Target: 192.168.1.0/24
...
```

### Example 2: Command Line Usage
```bash
# Quick network discovery
netscan -i wlan0 -r 192.168.1.0/24

# Full comprehensive scan (requires sudo)
sudo netscan -i eth0 -r 10.0.0.0/24 -o full_scan.txt

# ARP scan for local network
netscan -i wlan0 -o arp_results.txt
```

### Example 3: Custom Scan with Specific Parameters
```bash
$ netscan
# Select option 4 for custom scan
# Enter custom parameters: -sS -sV -p 22,80,443,8080
```

## 🔧 Scan Types

### 1. Quick Scan
- **Purpose**: Fast network overview
- **Method**: Host discovery + common port scan (1-1024)
- **Time**: 1-5 minutes for typical networks
- **Requires Root**: Yes (for SYN scan)

### 2. Full Scan  
- **Purpose**: Comprehensive network analysis
- **Method**: All ports + OS detection + service versions
- **Time**: 30+ minutes for large networks
- **Requires Root**: Yes

### 3. ARP Scan
- **Purpose**: Local network device discovery
- **Method**: ARP table scanning
- **Time**: <1 minute
- **Requires Root**: No

### 4. Custom Scan
- **Purpose**: User-defined parameters
- **Method**: Custom nmap options
- **Time**: Varies by parameters
- **Requires Root**: Depends on scan type

## 🚨 Common Issues

### Issue 1: "Missing required dependencies"
**Problem**: Required tools not installed
**Solution**: 
```bash
# Arch Linux
sudo pacman -S nmap arp-scan

# Ubuntu/Debian  
sudo apt install nmap arp-scan
```

### Issue 2: "Permission denied" or "QUITTING!" errors
**Problem**: Insufficient privileges for certain scan types
**Solution**: Run with sudo privileges
```bash
sudo netscan
```

### Issue 3: "No network interfaces found"
**Problem**: Network interfaces not detected
**Solution**: Check network configuration
```bash
ip addr show
# Verify interfaces are up and have IP addresses
```

### Issue 4: Python network range calculation fails
**Problem**: Missing python3 or ipaddress module
**Solution**: Install Python 3.3+ (ipaddress module is built-in)

## 🔍 Troubleshooting

### Debug Network Interface Detection
```bash
ip -o -4 addr show  # List all IPv4 interfaces
```

### Verify Dependencies
```bash
which nmap arp-scan ip python3
```

### Check Permissions
```bash
# Test if nmap works with current privileges
nmap -sn 127.0.0.1

# Test if arp-scan works
arp-scan --interface=lo --localnet 2>/dev/null || echo "Requires interface"
```

### Manual Testing
```bash
# Test basic nmap functionality
nmap -sn 192.168.1.1

# Test arp-scan functionality  
arp-scan --interface=wlan0 --localnet
```

## 🎯 Tips for Effective Usage

1. **Start with ARP scan** for quick local network discovery
2. **Use Quick scan** for most penetration testing needs  
3. **Reserve Full scan** for detailed analysis of specific targets
4. **Save outputs** to files for documentation and comparison
5. **Run as root** when possible for complete functionality
6. **Be mindful of network policies** - always scan authorized networks only

## 🤝 Contributing

This tool is part of the ShadowHarvy toolkit and follows established formatting standards. 

For issues or improvements:
1. Test thoroughly on different network environments
2. Follow the FORMAT.md coding standards
3. Ensure compatibility with common Linux distributions
4. Add appropriate error handling and user feedback

## 📄 License

Created by **ShadowHarvy** as part of the network security toolkit.

---

**⚠️ Disclaimer**: This tool is intended for authorized network testing and educational purposes only. Users are responsible for complying with applicable laws and regulations. Always obtain proper authorization before scanning networks you do not own.

**🛡️ Security Note**: Network scanning may trigger security alerts on monitored networks. Use responsibly and only on networks you own or have explicit permission to test.