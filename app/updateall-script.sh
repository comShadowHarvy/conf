#!/usr/bin/env bash
# updateall - Universal system update utility

echo "🔄 Starting system update..."

# Determine Linux distribution
if [ -f /etc/os-release ]; then
    distro=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
else
    distro="unknown"
fi

# Update system packages based on distribution
echo "📦 Updating system packages for $distro..."
case "$distro" in
    alpine)
        sudo apk update && sudo apk upgrade
        ;;
    debian|ubuntu)
        sudo apt update && sudo apt upgrade -y
        ;;
    fedora|rhel|centos)
        if command -v dnf >/dev/null 2>&1; then
            sudo dnf upgrade --refresh -y
        else
            sudo yum update -y
        fi
        ;;
    arch|manjaro|endeavouros)
        sudo pacman -Syu
        ;;
    *)
        # Default to pacman if distribution couldn't be identified
        if command -v pacman >/dev/null 2>&1; then
            sudo pacman -Syu
        else
            echo "⚠️ Unknown distribution. No system update performed."
        fi
        ;;
esac

# Update flatpak if available
if command -v flatpak >/dev/null 2>&1; then
    echo "📦 Updating Flatpak packages..."
    flatpak update -y
fi

# Update snap if available
if command -v snap >/dev/null 2>&1; then
    echo "📦 Updating Snap packages..."
    sudo snap refresh
fi

# Update Homebrew if available
if command -v brew >/dev/null 2>&1; then
    echo "📦 Updating Homebrew packages..."
    brew update && brew upgrade
fi

# Update ZimFW if available
if command -v zimfw >/dev/null 2>&1; then
    echo "🛠️ Updating ZimFW..."
    zimfw update
fi

# Update Oh My Posh if available
if command -v oh-my-posh >/dev/null 2>&1; then
    echo "🛠️ Updating Oh My Posh..."
    sudo oh-my-posh update
fi

echo "🎉 System update complete!"
