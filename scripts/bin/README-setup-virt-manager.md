# setup-virt-manager.sh

Set up virt-manager for virtual machine management on CachyOS/Arch Linux.

## Usage

```bash
./setup-virt-manager.sh
```

## What It Does

### 1. Installs Virtualization Software
- **qemu** - System emulator and virtualizer
- **virt-manager** - GUI for managing VMs
- **libvirt** - Virtualization API
- **dnsmasq** - DNS/DHCP server for VM networking
- **ebtables** - Ethernet bridge filtering
- **iptables-nft** - Packet filtering for VM networking

### 2. Enables libvirtd Service
- Starts libvirtd daemon
- Enables automatic startup on boot

### 3. Adds User to libvirt Group
- Grants permission to manage VMs without sudo
- Uses your current username automatically

## Post-Installation

**IMPORTANT:** Log out and log back in for group changes to take effect.

After logging back in, you can:
- Launch virt-manager from your application menu
- Create and manage virtual machines
- No sudo required for VM operations

## Verify Installation

```bash
# Check if libvirtd is running
systemctl status libvirtd

# Check your groups (should include 'libvirt')
groups

# Launch virt-manager
virt-manager
```

## Requirements

- Arch Linux or CachyOS
- Internet connection
- CPU with virtualization support (Intel VT-x or AMD-V)

## Enable CPU Virtualization

If VMs don't work, enable virtualization in BIOS:
- Reboot into BIOS/UEFI settings
- Look for: Intel VT-x, AMD-V, or Virtualization Technology
- Enable it and save

Check if enabled:
```bash
# For Intel
grep -E 'vmx' /proc/cpuinfo

# For AMD
grep -E 'svm' /proc/cpuinfo
```

## Creating Your First VM

1. Launch virt-manager
2. Click "Create a new virtual machine"
3. Select ISO or network install
4. Follow the wizard

## Common VM Use Cases

- Testing Android APKs in Android-x86
- Running Windows for testing
- Linux development environments
- Safe environment for testing modified software

## Troubleshooting

**"Failed to connect to socket"**
- Make sure libvirtd is running: `sudo systemctl start libvirtd`
- Log out and log back in

**"Permission denied"**
- Check you're in libvirt group: `groups`
- Log out and log back in if you just ran the script

**VMs are very slow**
- Enable virtualization in BIOS
- Check: `lscpu | grep Virtualization`

**Network doesn't work in VM**
- Check dnsmasq is running: `systemctl status dnsmasq`
- Ensure firewall allows VM traffic

**Permission denied when running script**
- Make executable: `chmod +x setup-virt-manager.sh`

## Removing virt-manager

If you want to uninstall:
```bash
sudo pacman -Rns qemu virt-manager libvirt dnsmasq ebtables iptables-nft
sudo gpasswd -d $USER libvirt
```
