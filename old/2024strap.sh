#!/bin/bash

# Function to display a fake loading bar
loading_bar() {
    bar="##################################################"
    bar_length=${#bar}
    percentage=0

    echo -n "["
    while [ $percentage -lt 100 ]; do
        n=$(($percentage * $bar_length / 100))
        printf "%s" "${bar:0:n}"
        printf "%s" ">"
        printf "%*s" $(($bar_length - $n - 1)) ""
        echo -n "] $percentage% "
        sleep 0.05
        percentage=$((percentage + 1))
        echo -ne "\r"
    done
    echo "[${bar}] 100%"
}

echo "Starting setup..."
loading_bar

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Define key ID and keyserver
keyID="3056513887B78AEB"
keyServer="keyserver.ubuntu.com"
echo "Defined key variables."
loading_bar

# Define package URLs
keyringPackageUrl="https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst"
mirrorlistPackageUrl="https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst"
echo "Package URLs defined."
loading_bar

# Define temporary directory
tempDir=$(mktemp -d)
logFile="$tempDir/setup.log"
paclockUrl="https://raw.githubusercontent.com/comShadowHarvy/conf/main/paclock.sh"
zshrcUrl="https://raw.githubusercontent.com/comShadowHarvy/conf/main/.zshrc"
aliasesUrl="https://raw.githubusercontent.com/comShadowHarvy/conf/main/.aliases"
antigenrcUrl="https://raw.githubusercontent.com/comShadowHarvy/conf/main/.antigenrc"
zsh1Url="https://raw.githubusercontent.com/comShadowHarvy/conf/main/.zsh1"

# Function to log and run commands
run_command() {
    echo "Running: $1"
    echo "Running: $1" >> "$logFile"
    eval "$1" >> "$logFile" 2>&1
    if [ $? -ne 0 ]; then
        echo "Error: Command failed - $1"
        exit 1
    fi
}

# Detect the operating system
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect the operating system."
    exit 1
fi

# Function to update system and install packages based on the OS
install_packages() {
    case "$OS" in
        arch)
            run_command "sudo pacman -Sy --noconfirm base-devel git wget curl zsh"
            ;;
        debian|ubuntu)
            run_command "sudo apt update -y && sudo apt install -y build-essential git wget curl gnupg python3-pip zsh"
            ;;
        rhel|centos|fedora)
            run_command "sudo dnf install -y @development-tools git wget curl gnupg python3-pip zsh"
            ;;
        *)
            echo "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
}

# Function to install and configure Chaotic AUR (only for Arch Linux)
install_chaotic_aur() {
    if [ "$OS" == "arch" ]; then
        run_command "sudo pacman-key --recv-key $keyID --keyserver $keyServer"
        run_command "sudo pacman-key --lsign-key $keyID"
        run_command "sudo pacman -U $keyringPackageUrl --noconfirm"
        run_command "sudo pacman -U $mirrorlistPackageUrl --noconfirm"
        if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
            echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf > /dev/null
            sudo sed -i 's/^SigLevel    = Required DatabaseOptional$/SigLevel = Never/' /etc/pacman.conf
        else
            echo "Chaotic AUR is already configured in pacman.conf"
        fi
    fi
}

# Function to install BlackArch (only for Arch Linux)
install_blackarch() {
    if [ "$OS" == "arch" ]; then
        if ! command -v blackarch &> /dev/null; then
            run_command "wget https://blackarch.org/strap.sh -O $tempDir/strap.sh"
            run_command "chmod +x $tempDir/strap.sh"
            run_command "sudo $tempDir/strap.sh"
        else
            echo "BlackArch is already installed"
        fi
    fi
}

# Function to install paru (only for Arch Linux)
install_paru() {
    if [ "$OS" == "arch" ]; then
        if ! command -v paru &> /dev/null; then
            run_command "git clone https://aur.archlinux.org/paru.git $tempDir/paru"
            cd $tempDir/paru
            run_command "makepkg -si --noconfirm"
            cd ..
            rm -rf $tempDir/paru
        else
            echo "paru is already installed"
        fi
    fi
}

# Function to install specific packages
install_specific_packages() {
    case "$OS" in
        arch)
            if ! pacman -Qi metasploit &> /dev/null; then
                run_command "sudo pacman -S metasploit --noconfirm"
            else
                echo "metasploit is already installed"
            fi
            run_command "sudo pacman -Syu --noconfirm"
            if ! pacman -Qi pacui &> /dev/null; then
                run_command "paru -S pacui --noconfirm"
            else
                echo "pacui is already installed"
            fi
            if ! pacman -Qi snapd &> /dev/null; then
                run_command "sudo pacman -S snapd --noconfirm"
                run_command "sudo systemctl enable --now snapd.socket"
            else
                echo "snapd is already installed"
            fi
            if ! pacman -Qi flatpak &> /dev/null; then
                run_command "sudo pacman -S flatpak --noconfirm"
            else
                echo "flatpak is already installed"
            fi
            if ! pacman -Qi appimagelauncher &> /dev/null; then
                run_command "paru -S appimagelauncher --noconfirm"
            else
                echo "appimagelauncher is already installed"
            fi
            if ! pacman -Qi docker &> /dev/null; then
                run_command "sudo pacman -S docker --noconfirm"
                run_command "sudo systemctl enable --now docker.service"
            else
                echo "docker is already installed"
            fi
            if ! pacman -Qi python-pip &> /dev/null; then
                run_command "sudo pacman -S python-pip --noconfirm"
            else
                echo "pip3 is already installed"
            fi
            if ! command -v pipx &> /dev/null; then
                run_command "pip3 install --user pipx"
                run_command "pipx ensurepath"
            else
                echo "pipx is already installed"
            fi
            ;;
        debian|ubuntu)
            if ! dpkg -l | grep -q metasploit-framework; then
                run_command "sudo apt install -y metasploit-framework"
            else
                echo "metasploit-framework is already installed"
            fi
            run_command "sudo apt upgrade -y"
            if ! dpkg -l | grep -q snapd; then
                run_command "sudo apt install -y snapd"
                run_command "sudo systemctl enable --now snapd.socket"
            else
                echo "snapd is already installed"
            fi
            if ! dpkg -l | grep -q flatpak; then
                run_command "sudo apt install -y flatpak"
            else
                echo "flatpak is already installed"
            fi
            if ! dpkg -l | grep -q docker.io; then
                run_command "sudo apt install -y docker.io"
                run_command "sudo systemctl enable --now docker.service"
            else
                echo "docker.io is already installed"
            fi
            if ! dpkg -l | grep -q python3-pip; then
                run_command "sudo apt install -y python3-pip"
            else
                echo "pip3 is already installed"
            fi
            if ! command -v pipx &> /dev/null; then
                run_command "pip3 install --user pipx"
                run_command "pipx ensurepath"
            else
                echo "pipx is already installed"
            fi
            ;;
        rhel|centos|fedora)
            if ! rpm -q metasploit-framework &> /dev/null; then
                run_command "sudo dnf install -y metasploit-framework"
            else
                echo "metasploit-framework is already installed"
            fi
            run_command "sudo dnf upgrade -y"
            if ! rpm -q epel-release &> /dev/null; then
                run_command "sudo dnf install -y epel-release"
            else
                echo "epel-release is already installed"
            fi
            if ! rpm -q snapd &> /dev/null; then
                run_command "sudo dnf install -y snapd"
                run_command "sudo systemctl enable --now snapd.socket"
            else
                echo "snapd is already installed"
            fi
            if ! rpm -q flatpak &> /dev/null; then
                run_command "sudo dnf install -y flatpak"
            else
                echo "flatpak is already installed"
            fi
            if ! rpm -q docker &> /dev/null; then
                run_command "sudo dnf install -y docker"
                run_command "sudo systemctl enable --now docker.service"
            else
                echo "docker is already installed"
            fi
            if ! rpm -q python3-pip &> /dev/null; then
                run_command "sudo dnf install -y python3-pip"
            else
                echo "pip3 is already installed"
            fi
            if ! command -v pipx &> /dev/null; then
                run_command "pip3 install --user pipx"
                run_command "pipx ensurepath"
            else
                echo "pipx is already installed"
            fi
            ;;
        *)
            echo "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
}

# Function to install Antigen and set zsh as default shell
install_antigen_zsh() {
    if [ ! -d "$HOME/.antigen" ]; then
        run_command "git clone https://github.com/zsh-users/antigen.git $HOME/.antigen"
    else
        echo "Antigen is already installed"
    fi
    if [ "$SHELL" != "/bin/zsh" ]; then
        run_command "chsh -s /bin/zsh"
    else
        echo "zsh is already the default shell"
    fi
}

# Function to download configuration files
download_configs() {
    run_command "wget $zshrcUrl -O $HOME/.zshrc"
    run_command "wget $aliasesUrl -O $HOME/.aliases"
    run_command "wget $antigenrcUrl -O $HOME/.antigenrc"
    run_command "wget $zsh1Url -O $HOME/.zsh1"
}

# Function to download paclock.sh (only for Arch Linux)
download_paclock_script() {
    if [ "$OS" == "arch" ]; then
        run_command "wget $paclockUrl -O /usr/local/bin/paclock.sh"
        run_command "chmod +x /usr/local/bin/paclock.sh"
    fi
}

# Main installation process
install_packages
loading_bar
install_chaotic_aur
loading_bar
install_blackarch
loading_bar
install_paru
loading_bar
install_specific_packages
loading_bar
download_paclock_script
loading_bar
install_antigen_zsh
loading_bar
download_configs
loading_bar

echo "Setup complete. All selected packages have been installed and configured."
echo "Log file is located at $logFile"

# Clean up temporary directory
rm -rf $tempDir
