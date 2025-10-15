#!/bin/bash

# Steam Deck SSH Setup Script
# This script installs and configures SSH server on Steam Deck

set -e

echo "=== Steam Deck SSH Setup ==="

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Error: Don't run this script as root"
    exit 1
fi

# Install SSH server using pacman
echo "Installing OpenSSH server..."
sudo pacman -S --needed openssh

# Enable and start SSH service
echo "Enabling SSH service..."
sudo systemctl enable sshd
sudo systemctl start sshd

# Check if SSH is running
echo "Checking SSH service status..."
sudo systemctl status sshd --no-pager

# Set password for deck user if not already set
echo ""
echo "Setting up password for deck user..."
echo "You'll need to set a password to connect via SSH:"
sudo passwd deck

# Show current SSH configuration
echo ""
echo "Current SSH server configuration:"
echo "- SSH is running on port 22"
echo "- Password authentication is enabled by default"

# Get IP address
IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')
echo ""
echo "=== Connection Information ==="
echo "Your Steam Deck's IP address: $IP"
echo "To connect from another device, use:"
echo "  ssh deck@$IP"
echo ""
echo "Optional: To connect via hostname (if available):"
echo "  ssh deck@steamdeck"
echo ""

# Optional: Configure firewall
echo "=== Firewall Configuration ==="
if command -v ufw >/dev/null 2>&1; then
    echo "UFW firewall detected. Do you want to allow SSH through firewall? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        sudo ufw allow ssh
        echo "SSH allowed through firewall"
    fi
else
    echo "No UFW firewall detected - SSH should work without additional configuration"
fi

echo ""
echo "=== Setup Complete ==="
echo "SSH server is now installed and running on your Steam Deck!"
echo "You can now connect from other devices using the connection info above."
echo ""
echo "Security tips:"
echo "- Consider using SSH keys instead of passwords for better security"
echo "- You can disable password authentication in /etc/ssh/sshd_config if using keys"
echo "- Run 'sudo systemctl restart sshd' after making config changes"
echo ""
echo "=== Quick Connect Info ==="
echo "Your Steam Deck IP: $IP"
echo "Connect with: ssh deck@$IP"
