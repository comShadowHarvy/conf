#!/bin/bash

# Setup Virt-Manager on CachyOS/Arch Linux

set -e  # Exit on error

echo "Installing virt-manager and dependencies..."
sudo pacman -Syu qemu virt-manager libvirt dnsmasq ebtables iptables-nft

echo "Enabling libvirtd service..."
sudo systemctl enable --now libvirtd

echo "Adding user to libvirt group..."
sudo usermod -aG libvirt $USER

echo "Setup complete!"
echo "Note: You may need to log out and log back in for group changes to take effect."
