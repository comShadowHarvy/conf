#!/bin/bash

echo "Starting setup..."

# Define key ID and keyserver
keyID="3056513887B78AEB"
keyServer="keyserver.ubuntu.com"
echo "Defined key variables."

# Define package URLs
keyringPackageUrl="https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst"
mirrorlistPackageUrl="https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst"
echo "Package URLs defined."

# Update system and install necessary packages
echo "Updating system and installing necessary packages..."
sudo pacman -Sy --noconfirm base-devel git wget curl

# Receive the key
echo "Receiving key..."
sudo pacman-key --recv-key $keyID --keyserver $keyServer

# Locally sign the key
echo "Signing key..."
sudo pacman-key --lsign-key $keyID

# Install the chaotic keyring package
echo "Installing the Chaotic AUR keyring package..."
sudo pacman -U $keyringPackageUrl --noconfirm

# Install the chaotic mirrorlist package
echo "Installing the Chaotic AUR mirrorlist package..."
sudo pacman -U $mirrorlistPackageUrl --noconfirm

# Append Chaotic AUR repo to pacman.conf
echo "Configuring pacman to use the Chaotic AUR..."
echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf > /dev/null

# Disable signature verification in pacman.conf
echo "Disabling signature verification in pacman.conf..."
sudo sed -i 's/^SigLevel    = Required DatabaseOptional$/SigLevel = Never/' /etc/pacman.conf

# Download the BlackArch strap.sh script
echo "Downloading the BlackArch strap.sh script..."
wget https://blackarch.org/strap.sh
echo "Making strap.sh executable..."
chmod +x strap.sh

# Execute the strap.sh script with superuser privileges
echo "Running strap.sh..."
sudo ./strap.sh

# Install paru from AUR
echo "Cloning the paru repository..."
git clone https://aur.archlinux.org/paru.git
cd paru
echo "Building and installing paru..."
makepkg -si --noconfirm
cd ..
rm -rf paru

# Install Metasploit
echo "Installing Metasploit..."
sudo pacman -S metasploit --noconfirm

# Refresh the package databases and update the system packages
echo "Refreshing package databases and updating system packages..."
sudo pacman -Syu --noconfirm

# Install Pacui from AUR
echo "Installing Pacui from AUR..."
paru -S pacui --noconfirm

# Install Snapd
echo "Installing Snapd and enabling the service..."
sudo pacman -S snapd --noconfirm
sudo systemctl enable --now snapd.socket

# Install Flatpak
echo "Installing Flatpak..."
sudo pacman -S flatpak --noconfirm

# Install AppImageLauncher
echo "Installing AppImageLauncher from AUR..."
paru -S appimagelauncher --noconfirm

# Install Docker
echo "Installing Docker..."
sudo pacman -S docker --noconfirm
echo "Enabling and starting Docker service..."
sudo systemctl enable --now docker.service

echo "Setup complete. All selected packages have been installed and configured."

