#!/usr/bin/env bash
# =============================================================================
# Restore All Stows - Quick restore script
# =============================================================================
# Description: Restores all dotfiles by stowing packages in correct order
# Usage: ./restore-all.sh [--full|--essential|--media|--all]
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_MANAGER="${SCRIPT_DIR}/stow-manager.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Default to essential packages
MODE="${1:-essential}"

# Parse arguments
case "$MODE" in
    --full|full)
        echo -e "${BLUE}Restoring all packages (full)${RESET}"
        PACKAGES=("bash" "shared" "zsh" "git" "scripts" "nvim" "tmux" "vscode" "hyprland" "waybar" "wget" "yt-x" "yt-dlp")
        ;;
    --essential|essential)
        echo -e "${BLUE}Restoring essential packages${RESET}"
        PACKAGES=("bash" "shared" "zsh" "git" "scripts")
        ;;
    --media|media)
        echo -e "${BLUE}Restoring media packages${RESET}"
        PACKAGES=("yt-x" "yt-dlp")
        ;;
    --development|development)
        echo -e "${BLUE}Restoring development packages${RESET}"
        PACKAGES=("nvim" "tmux" "vscode")
        ;;
    --desktop|desktop)
        echo -e "${BLUE}Restoring desktop packages${RESET}"
        PACKAGES=("hyprland" "waybar")
        ;;
    --all|all)
        echo -e "${BLUE}Restoring ALL packages${RESET}"
        PACKAGES=("bash" "shared" "zsh" "git" "scripts" "nvim" "tmux" "vscode" "hyprland" "waybar" "wget" "yt-x" "yt-dlp")
        ;;
    --help|-h)
        cat << EOF
${BLUE}Usage: $0 [option]${RESET}

${BLUE}Options:${RESET}
  --essential    Restore core packages (bash, zsh, git, shared, scripts) [default]
  --full         Restore all packages including dev and desktop
  --media        Restore media packages (yt-x, yt-dlp)
  --development  Restore development packages (nvim, tmux, vscode)
  --desktop      Restore desktop packages (hyprland, waybar)
  --all          Restore everything (same as --full)
  --help         Show this help message

${BLUE}Examples:${RESET}
  $0                    # Restore essential packages
  $0 --full            # Restore all packages
  $0 --media           # Restore only media tools
EOF
        exit 0
        ;;
    *)
        echo -e "${RED}Unknown option: $MODE${RESET}"
        echo "Use '$0 --help' for usage information"
        exit 1
        ;;
esac

# Check if stow-manager exists
if [[ ! -f "$STOW_MANAGER" ]]; then
    echo -e "${RED}Error: stow-manager.sh not found at $STOW_MANAGER${RESET}"
    exit 1
fi

# Backup conflicting files
echo -e "${YELLOW}Checking for conflicts...${RESET}"
CONFLICTS_FOUND=false

for package in "${PACKAGES[@]}"; do
    if "$STOW_MANAGER" check "$package" 2>/dev/null; then
        : # No conflicts
    else
        CONFLICTS_FOUND=true
    fi
done

if [[ "$CONFLICTS_FOUND" == "true" ]]; then
    echo -e "${YELLOW}Some conflicts detected. Removing conflicting files...${RESET}"
    rm -f ~/.bashrc ~/.bash_profile ~/.bash_logout ~/.zshrc ~/.aliases ~/.gitconfig
    echo -e "${GREEN}Cleaned up conflicts${RESET}"
fi

# Stow packages
echo -e "${BLUE}Stowing packages...${RESET}"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

for package in "${PACKAGES[@]}"; do
    if "$STOW_MANAGER" stow "$package" 2>/dev/null; then
        echo -e "${GREEN}✓${RESET} $package"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}✗${RESET} $package"
        ((FAIL_COUNT++))
    fi
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}Restored: $SUCCESS_COUNT${RESET}"
if [[ $FAIL_COUNT -gt 0 ]]; then
    echo -e "${RED}Failed: $FAIL_COUNT${RESET}"
fi
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

if [[ $FAIL_COUNT -eq 0 ]]; then
    echo -e "${GREEN}All packages restored successfully!${RESET}"
    exit 0
else
    echo -e "${YELLOW}Some packages failed. Check conflicts and try again.${RESET}"
    exit 1
fi
