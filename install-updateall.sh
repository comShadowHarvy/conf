#!/bin/bash
# Installer for updateall script

# Text styling
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
RESET="\033[0m"

echo -e "${BOLD}${BLUE}=== Installing updateall command ===${RESET}"
echo

# Create bin directory if it doesn't exist
if [ ! -d "$HOME/bin" ]; then
    echo -e "${YELLOW}Creating ~/bin directory...${RESET}"
    mkdir -p "$HOME/bin"
    echo -e "${GREEN}Created ~/bin directory${RESET}"
fi

# Create the updateall script
echo -e "${YELLOW}Creating updateall command...${RESET}"
cat > "$HOME/bin/updateall" << 'EOL'
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
EOL

# Make the script executable
chmod +x "$HOME/bin/updateall"
echo -e "${GREEN}Created updateall command${RESET}"

# Check if ~/bin is already in PATH
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo -e "${YELLOW}Adding ~/bin to your PATH...${RESET}"
    
    # Add to .zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.zshrc"; then
            echo '' >> "$HOME/.zshrc"
            echo '# Add ~/bin to PATH for custom scripts' >> "$HOME/.zshrc"
            echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"
            echo -e "${GREEN}Added ~/bin to PATH in .zshrc${RESET}"
        else
            echo -e "${BLUE}~/bin already in PATH in .zshrc${RESET}"
        fi
    fi
    
    # Also add to .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.bashrc"; then
            echo '' >> "$HOME/.bashrc"
            echo '# Add ~/bin to PATH for custom scripts' >> "$HOME/.bashrc"
            echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
            echo -e "${GREEN}Added ~/bin to PATH in .bashrc${RESET}"
        else
            echo -e "${BLUE}~/bin already in PATH in .bashrc${RESET}"
        fi
    fi
    
    # Update current PATH for this session
    export PATH="$HOME/bin:$PATH"
else
    echo -e "${BLUE}~/bin is already in your PATH${RESET}"
fi

# Create symlink in /usr/local/bin for system-wide access (if possible)
if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
    echo -e "${YELLOW}Creating system-wide symlink...${RESET}"
    ln -sf "$HOME/bin/updateall" "/usr/local/bin/updateall"
    echo -e "${GREEN}Created system-wide symlink${RESET}"
elif command -v sudo >/dev/null 2>&1; then
    echo -e "${YELLOW}Creating system-wide symlink (requires sudo)...${RESET}"
    sudo ln -sf "$HOME/bin/updateall" "/usr/local/bin/updateall" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Created system-wide symlink${RESET}"
    else
        echo -e "${BLUE}No permission to create system-wide symlink (not critical)${RESET}"
    fi
fi

echo
echo -e "${BOLD}${GREEN}✅ Installation complete!${RESET}"
echo
echo -e "You can now run the ${BOLD}updateall${RESET} command from anywhere."
echo -e "If it doesn't work immediately, try:"
echo -e "  - Opening a new terminal"
echo -e "  - Running: ${BOLD}source ~/.zshrc${RESET}"
echo -e "  - Running: ${BOLD}export PATH=\"\$HOME/bin:\$PATH\"${RESET}"
echo

# Try to run the command immediately
if command -v updateall >/dev/null 2>&1; then
    echo -e "${GREEN}The command is now available in your current session!${RESET}"
    echo -e "Run it by typing: ${BOLD}updateall${RESET}"
else
    echo -e "${YELLOW}Note: You may need to restart your terminal or source your shell config.${RESET}"
fi
