#!/usr/bin/env bash
# zsh_maintain.sh - System health check and updates

echo "🛠️  Starting System Maintenance..."

# 1. Check for updates (Arch/Omarchy/Bazzite)
if command -v yay &> /dev/null; then
    echo "📦 Updating AUR packages..."
    yay -Syu
elif command -v pacman &> /dev/null; then
    echo "📦 Updating Pacman packages..."
    sudo pacman -Syu
fi

# 2. Check for missing tools defined in your old zshrc
TOOLS=("fzf" "zoxide" "eza" "bat" "ripgrep" "fd" "neovim" "fastfetch")
for tool in "${TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo "⚠️  Missing tool: $tool. Installing..."
        # Add installation logic here (or just warn)
        if command -v pacman &> /dev/null; then sudo pacman -S "$tool"; fi
    fi
done

# 3. Update Git Repos
echo "octocat: Checking trusted git directories..."
TRUSTED_DIRS=("$HOME/git" "$HOME/projects")
for dir in "${TRUSTED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        find "$dir" -maxdepth 2 -name ".git" -type d | while read gitdir; do
            repo_dir=$(dirname "$gitdir")
            echo "   Pulling $repo_dir..."
            git -C "$repo_dir" pull -q
        done
    fi
done

echo "✅ Maintenance complete."
