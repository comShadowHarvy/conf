#!/usr/bin/env bash
# =============================================================================
# Simple Stow Configuration Restore Script
# =============================================================================
# Author: Shadow Harvey  
# Description: Simple script to restore all stow configurations with one command
# Usage: ./restore-stow.sh [options]
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$SCRIPT_DIR"
TARGET_DIR="$HOME"

# Colors
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
    RED=$(tput setaf 1 2>/dev/null || echo "")
    GREEN=$(tput setaf 2 2>/dev/null || echo "")
    YELLOW=$(tput setaf 3 2>/dev/null || echo "")
    BLUE=$(tput setaf 4 2>/dev/null || echo "")
    PURPLE=$(tput setaf 5 2>/dev/null || echo "")
    CYAN=$(tput setaf 6 2>/dev/null || echo "")
    BOLD=$(tput bold 2>/dev/null || echo "")
    RESET=$(tput sgr0 2>/dev/null || echo "")
else
    RED="" GREEN="" YELLOW="" BLUE="" PURPLE="" CYAN="" BOLD="" RESET=""
fi

# Options with defaults
DRY_RUN=false
FORCE=false
INTERACTIVE=true
BACKUP=true
SELECTED_PACKAGES=""

# Package groups - hardcoded from your config
get_group_packages() {
    local group="$1"
    case "$group" in
        essential) echo "bash git shared scripts" ;;
        minimal) echo "bash git shared" ;;
        development) echo "nvim tmux vscode" ;;
        desktop) echo "hyprland waybar" ;;
        full) echo "bash git shared scripts nvim tmux vscode hyprland waybar" ;;
        all) echo "bash git shared scripts nvim tmux vscode hyprland waybar analysis secrets" ;;
        *) echo ""; return 1 ;;
    esac
}

# Logging
log() {
    local level="$1"; shift
    case "$level" in
        INFO) echo -e "${CYAN}[INFO]${RESET} $*" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${RESET} $*" ;;
        WARNING) echo -e "${YELLOW}[WARNING]${RESET} $*" ;;
        ERROR) echo -e "${RED}[ERROR]${RESET} $*" >&2 ;;
        STEP) echo -e "${PURPLE}[STEP]${RESET} $*" ;;
    esac
}

# Check if stow is installed
check_stow() {
    if ! command -v stow >/dev/null 2>&1; then
        log ERROR "GNU Stow is not installed"
        echo ""
        log INFO "Install stow with:"
        echo "  • Arch Linux: sudo pacman -S stow"
        echo "  • Ubuntu/Debian: sudo apt install stow"
        echo "  • macOS: brew install stow"
        exit 1
    fi
}

# Get available packages
get_packages() {
    find "$STOW_DIR" -maxdepth 1 -type d ! -name ".*" ! -name logs ! -name backups ! -name bin ! -name "$(basename "$STOW_DIR")" \
        -exec basename {} \; | sort
}

# Check if package exists
package_exists() {
    [[ -d "$STOW_DIR/$1" ]]
}

# Check if package is stowed (simplified check)
is_stowed() {
    local package="$1"
    [[ -d "$STOW_DIR/$package" ]] || return 1
    
    # Check if any file from the package is symlinked
    find "$STOW_DIR/$package" -type f 2>/dev/null | while read -r file; do
        local rel_path="${file#$STOW_DIR/$package/}"
        local target="$TARGET_DIR/$rel_path"
        if [[ -L "$target" ]]; then
            local link_target=$(readlink "$target")
            if [[ "$link_target" == *"$package/$rel_path" ]]; then
                echo "stowed"
                return 0
            fi
        fi
    done | grep -q "stowed"
}

# Show package status
show_status() {
    log STEP "Package Status"
    echo
    
    local packages=($(get_packages))
    local stowed_count=0
    
    printf "%-15s %s\n" "PACKAGE" "STATUS"
    printf "%-15s %s\n" "-------" "------"
    
    for pkg in "${packages[@]}"; do
        if is_stowed "$pkg"; then
            echo -e "$(printf "%-15s" "$pkg") ${GREEN}STOWED${RESET}"
            ((stowed_count++))
        else
            echo -e "$(printf "%-15s" "$pkg") ${YELLOW}NOT STOWED${RESET}"
        fi
    done
    
    echo
    echo "Total packages: ${#packages[@]}"
    echo "Stowed packages: $stowed_count"
    echo "Available groups: essential minimal development desktop full all"
}

# Backup existing configurations
create_backup() {
    [[ "$BACKUP" == "true" ]] || return 0
    
    log STEP "Creating backup of existing configurations"
    
    local backup_dir="$HOME/.stow-restore-backup-$(date +%Y%m%d-%H%M%S)"
    local files_to_backup=(
        ".bashrc" ".bash_profile" ".bash_logout"
        ".zshrc" ".gitconfig" ".aliases"
        ".config/nvim" ".config/tmux" ".tmux.conf"
        ".config/hypr" ".config/waybar" ".wgetrc"
    )
    
    local backed_up=0
    for file in "${files_to_backup[@]}"; do
        [[ -e "$HOME/$file" && ! -L "$HOME/$file" ]] || continue
        
        if [[ $backed_up -eq 0 ]]; then
            mkdir -p "$backup_dir" || { log ERROR "Failed to create backup directory"; return 1; }
        fi
        
        log INFO "Backing up: $file"
        if mkdir -p "$(dirname "$backup_dir/$file")" && cp -r "$HOME/$file" "$backup_dir/$file" 2>/dev/null; then
            ((backed_up++))
        else
            log WARNING "Failed to backup $file, skipping"
        fi
    done
    
    if [[ $backed_up -gt 0 ]]; then
        log SUCCESS "Backed up $backed_up files to: $backup_dir"
        printf 'BACKUP_DIR="%s"\n' "$backup_dir" > "$STOW_DIR/.last_backup"
    else
        log INFO "No files needed backing up"
    fi
}

# Stow a package
stow_package() {
    local package="$1"
    
    if ! package_exists "$package"; then
        log ERROR "Package '$package' doesn't exist"
        return 1
    fi
    
    if is_stowed "$package"; then
        log INFO "Package '$package' is already stowed"
        return 0
    fi
    
    log INFO "Stowing package: $package"
    
    local cmd=(stow -t "$TARGET_DIR" -d "$STOW_DIR")
    [[ "$DRY_RUN" == "true" ]] && cmd+=(-n)
    
    if "${cmd[@]}" "$package" 2>/dev/null; then
        log SUCCESS "Successfully stowed '$package'"
    elif [[ "$FORCE" == "true" ]]; then
        log WARNING "Conflicts detected, force stowing '$package'"
        # Use --adopt to handle conflicts by adopting existing files
        if "${cmd[@]}" --adopt "$package" 2>/dev/null; then
            log SUCCESS "Force stowed '$package' (adopted existing files)"
        else
            log ERROR "Failed to force stow '$package'"
            return 1
        fi
    else
        log ERROR "Failed to stow '$package' (use --force to override conflicts)"
        return 1
    fi
}

# Main restore function
restore_configs() {
    log STEP "Restoring stow configurations"
    
    local packages=()
    
    if [[ -n "$SELECTED_PACKAGES" ]]; then
        # Check if it's a group
        local group_packages=$(get_group_packages "$SELECTED_PACKAGES" 2>/dev/null || true)
        if [[ -n "$group_packages" ]]; then
            log INFO "Restoring group '$SELECTED_PACKAGES'"
            read -ra packages <<< "$group_packages"
        else
            # Treat as comma-separated packages
            IFS=',' read -ra packages <<< "$SELECTED_PACKAGES"
        fi
    else
        # Default to full group
        read -ra packages <<< "$(get_group_packages "full")"
    fi
    
    log INFO "Packages to stow: ${packages[*]}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "DRY RUN - Would stow:"
        for pkg in "${packages[@]}"; do
            if package_exists "$pkg"; then
                local status=$(is_stowed "$pkg" && echo "(already stowed)" || echo "(not stowed)")
                echo "  • $pkg $status"
            else
                echo "  • $pkg ${RED}(MISSING)${RESET}"
            fi
        done
        return 0
    fi
    
    local failed=0
    for package in "${packages[@]}"; do
        stow_package "$package" || ((failed++))
    done
    
    if [[ $failed -eq 0 ]]; then
        log SUCCESS "Successfully restored all packages!"
    else
        log ERROR "$failed packages failed to restore"
        return 1
    fi
}

# Show usage
show_usage() {
    cat << 'EOF'
🏠 Simple Stow Configuration Restore Script

USAGE:
    restore-stow.sh [options] [group/packages]

OPTIONS:
    -n, --dry-run           Show what would be done without executing
    -f, --force             Force operations, remove conflicts  
    -g, --group GROUP       Restore specific group
    -p, --packages LIST     Restore specific packages (comma-separated)
    --no-backup            Skip creating backup of existing configs
    --no-interactive       Run in non-interactive mode
    -s, --status           Show current package status and exit
    -h, --help             Show this help message

GROUPS:
    essential    Core shell and git configuration (bash git shared scripts)
    minimal      Minimal setup (bash git shared)
    development  Development tools (nvim tmux vscode)
    desktop      GUI/Desktop environment (hyprland waybar)
    full         Full configuration (default)
    all          Everything including optional packages

EXAMPLES:
    # Restore full configuration (default)
    restore-stow.sh

    # Dry run to see what would happen  
    restore-stow.sh --dry-run

    # Restore only essential packages
    restore-stow.sh --group essential

    # Restore specific packages
    restore-stow.sh --packages bash,git,nvim

    # Force restore, removing conflicts
    restore-stow.sh --force

    # Check current status
    restore-stow.sh --status

EOF
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--dry-run) DRY_RUN=true; shift ;;
            -f|--force) FORCE=true; shift ;;
            -g|--group) SELECTED_PACKAGES="$2"; shift 2 ;;
            -p|--packages) SELECTED_PACKAGES="$2"; shift 2 ;;
            --no-backup) BACKUP=false; shift ;;
            --no-interactive) INTERACTIVE=false; shift ;;
            -s|--status) show_status; exit 0 ;;
            -h|--help) show_usage; exit 0 ;;
            -*) log ERROR "Unknown option: $1"; echo; show_usage; exit 1 ;;
            *) SELECTED_PACKAGES="$1"; shift ;;
        esac
    done
}

# Main function
main() {
    parse_args "$@"
    
    echo
    echo -e "${BOLD}${PURPLE}🏠 Simple Stow Configuration Restore${RESET}"
    echo -e "${BLUE}Restoring your dotfiles with GNU Stow${RESET}"
    echo
    
    check_stow
    
    log STEP "System Information"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Stow directory:    $STOW_DIR"
    echo "Target directory:  $TARGET_DIR"
    echo "Selected packages: ${SELECTED_PACKAGES:-full (default)}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    
    if [[ "$INTERACTIVE" == "true" && "$DRY_RUN" == "false" ]]; then
        show_status
        
        echo -e "${YELLOW}This will stow configurations: ${BOLD}${SELECTED_PACKAGES:-full}${RESET}${YELLOW}"
        [[ "$BACKUP" == "true" ]] && echo -e "Existing configurations will be backed up first.${RESET}" || echo -e "No backup will be created.${RESET}"
        echo
        
        read -p "Continue? [Y/n]: " -n 1 -r
        echo
        [[ $REPLY =~ ^[Nn]$ ]] && { log INFO "Cancelled by user"; exit 0; }
        echo
    fi
    
    create_backup
    
    if restore_configs; then
        echo
        log SUCCESS "🎉 Stow configuration restore complete!"
        echo
        echo -e "${BOLD}📋 Next Steps:${RESET}"
        echo "  • Source shell config: ${YELLOW}source ~/.bashrc${RESET} or ${YELLOW}source ~/.zshrc${RESET}"
        echo "  • For tmux: ${YELLOW}tmux source-file ~/.tmux.conf${RESET}"
        echo "  • For Neovim: Launch ${YELLOW}nvim${RESET} to install plugins"
        
        if [[ -f "$STOW_DIR/.last_backup" ]]; then
            source "$STOW_DIR/.last_backup"
            [[ -d "${BACKUP_DIR:-}" ]] && echo -e "  • Backup created at: ${CYAN}$BACKUP_DIR${RESET}"
        fi
        echo
    else
        exit 1
    fi
}

# Handle interrupts
trap 'echo; log ERROR "Interrupted by user"; exit 1' INT TERM

# Run if executed directly
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"