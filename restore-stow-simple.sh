#!/usr/bin/env bash
# =============================================================================
# Simple Stow Configuration Restore Script
# =============================================================================
# Author: Shadow Harvey  
# Description: Simple script to restore all stow configurations with one command
# Usage: ./restore-stow-simple.sh [options]
# =============================================================================

set -euo pipefail

# Script metadata
SCRIPT_NAME="restore-stow-simple"
SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
STOW_DIR="$SCRIPT_DIR"
TARGET_DIR="$HOME"

# Colors for output
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    PURPLE=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
else
    RED="" GREEN="" YELLOW="" BLUE="" PURPLE="" CYAN="" BOLD="" RESET=""
fi

# Package groups based on your config
declare -A GROUPS
GROUPS=()
GROUPS[essential]="bash git shared scripts"
GROUPS[minimal]="bash git shared"
GROUPS[development]="nvim tmux vscode"
GROUPS[desktop]="hyprland waybar"
GROUPS[full]="bash git shared scripts nvim tmux vscode hyprland waybar"
GROUPS[all]="bash git shared scripts nvim tmux vscode hyprland waybar analysis secrets"

# Options
DRY_RUN=false
FORCE=false
GROUP="full"
INTERACTIVE=true
BACKUP=true

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        INFO)    echo -e "${CYAN}[INFO]${RESET} $message" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${RESET} $message" ;;
        WARNING) echo -e "${YELLOW}[WARNING]${RESET} $message" ;;
        ERROR)   echo -e "${RED}[ERROR]${RESET} $message" >&2 ;;
        STEP)    echo -e "${PURPLE}[STEP]${RESET} $message" ;;
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
    find "$STOW_DIR" -maxdepth 1 -type d ! -name ".*" ! -name logs ! -name backups ! -name bin \
        -exec basename {} \; | sort
}

# Check if package exists
package_exists() {
    local package="$1"
    [[ -d "$STOW_DIR/$package" ]]
}

# Check if package is stowed
is_stowed() {
    local package="$1"
    
    if ! package_exists "$package"; then
        return 1
    fi
    
    # Check for stow-managed symlinks
    while IFS= read -r -d '' file; do
        local relative_path="${file#$STOW_DIR/$package/}"
        local target_file="$TARGET_DIR/$relative_path"
        
        if [[ -L "$target_file" ]]; then
            local link_target=$(readlink "$target_file")
            if [[ "$link_target" == *"$package/$relative_path" ]]; then
                return 0  # Found at least one valid stow symlink
            fi
        fi
    done < <(find "$STOW_DIR/$package" -type f -print0 2>/dev/null || true)
    
    return 1
}

# Show package status
show_status() {
    log STEP "Package Status"
    echo
    
    local packages=($(get_packages))
    local stowed_count=0
    local total_count=${#packages[@]}
    
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
    echo "Total packages: $total_count"
    echo "Stowed packages: $stowed_count"
    echo "Available groups: ${!GROUPS[*]}"
}

# Backup existing configurations
create_backup() {
    if [[ "$BACKUP" == "false" ]]; then
        log INFO "Skipping backup (--no-backup specified)"
        return
    fi
    
    log STEP "Creating backup of existing configurations"
    
    local backup_dir="$HOME/.stow-restore-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # List of common config files that might conflict
    local files_to_backup=(
        ".bashrc" ".bash_profile" ".bash_logout"
        ".zshrc" ".antigenrc" 
        ".gitconfig"
        ".aliases"
        ".config/nvim"
        ".config/tmux" ".tmux.conf"
        ".config/hypr"
        ".config/waybar"
        ".wgetrc"
    )
    
    local backed_up=0
    for file in "${files_to_backup[@]}"; do
        local source_file="$HOME/$file"
        local dest_file="$backup_dir/$file"
        
        if [[ -e "$source_file" && ! -L "$source_file" ]]; then
            log INFO "Backing up: $file"
            mkdir -p "$(dirname "$dest_file")"
            cp -r "$source_file" "$dest_file"
            backed_up=$((backed_up + 1))
        fi
    done
    
    if [[ $backed_up -gt 0 ]]; then
        log SUCCESS "Backed up $backed_up files to: $backup_dir"
        echo "BACKUP_DIR=\"$backup_dir\"" > "$STOW_DIR/.last_backup"
    else
        log INFO "No files needed backing up"
        rmdir "$backup_dir" 2>/dev/null || true
    fi
}

# Stow a single package
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
    
    local stow_args=(-t "$TARGET_DIR" -d "$STOW_DIR")
    [[ "$DRY_RUN" == "true" ]] && stow_args+=(-n)
    
    if stow "${stow_args[@]}" "$package" 2>/dev/null; then
        log SUCCESS "Successfully stowed '$package'"
        return 0
    else
        # Handle conflicts
        log WARNING "Conflict detected for package '$package'"
        
        if [[ "$FORCE" == "true" ]]; then
            log INFO "Forcing stow (removing conflicts)"
            stow "${stow_args[@]}" -R "$package" 2>/dev/null || {
                log ERROR "Failed to force stow '$package'"
                return 1
            }
            log SUCCESS "Force stowed '$package'"
            return 0
        else
            log ERROR "Failed to stow '$package' (use --force to override conflicts)"
            return 1
        fi
    fi
}

# Stow multiple packages
stow_packages() {
    local packages=("$@")
    local failed=0
    
    for package in "${packages[@]}"; do
        stow_package "$package" || ((failed++))
    done
    
    return $failed
}

# Get packages from group
get_group_packages() {
    local group="$1"
    
    if [[ -n "${GROUPS[$group]:-}" ]]; then
        echo ${GROUPS[$group]}
    else
        log ERROR "Unknown group: $group"
        log INFO "Available groups: ${!GROUPS[*]}"
        return 1
    fi
}

# Main restore function
restore_configs() {
    log STEP "Restoring stow configurations"
    
    local packages=()
    
    # Determine packages to stow
    if [[ -n "${GROUPS[$GROUP]:-}" ]]; then
        # It's a group
        log INFO "Restoring group '$GROUP'"
        IFS=' ' read -ra packages <<< "${GROUPS[$GROUP]}"
    else
        # Treat as individual packages
        IFS=',' read -ra packages <<< "$GROUP"
    fi
    
    log INFO "Packages to stow: ${packages[*]}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "DRY RUN - Would stow the following packages:"
        for pkg in "${packages[@]}"; do
            if package_exists "$pkg"; then
                echo "  • $pkg $(is_stowed "$pkg" && echo "(already stowed)" || echo "(not stowed)")"
            else
                echo "  • $pkg ${RED}(MISSING)${RESET}"
            fi
        done
        return 0
    fi
    
    local failed=$(stow_packages "${packages[@]}")
    
    if [[ $failed -eq 0 ]]; then
        log SUCCESS "Successfully restored all packages!"
        return 0
    else
        log ERROR "$failed packages failed to restore"
        return 1
    fi
}

# Show post-installation notes
show_post_install_notes() {
    cat << EOF

${BOLD}${GREEN}🎉 Stow Configuration Restore Complete!${RESET}

${BOLD}📋 Next Steps:${RESET}
  • Source your shell configuration:
    ${YELLOW}source ~/.bashrc${RESET}  (for bash)
    ${YELLOW}source ~/.zshrc${RESET}   (for zsh)

  • If using tmux, restart or source config:
    ${YELLOW}tmux source-file ~/.tmux.conf${RESET}

  • For Neovim users, first launch may install plugins:
    ${YELLOW}nvim${RESET}

${BOLD}📁 Useful Commands:${RESET}
  • Check status:         ${YELLOW}$SCRIPT_NAME --status${RESET}
  • Unstow a package:     ${YELLOW}stow -D <package>${RESET}
  • Restow a package:     ${YELLOW}stow -R <package>${RESET}

EOF

    if [[ -f "$STOW_DIR/.last_backup" ]]; then
        source "$STOW_DIR/.last_backup"
        if [[ -n "${BACKUP_DIR:-}" && -d "$BACKUP_DIR" ]]; then
            echo -e "${BOLD}💾 Backup Information:${RESET}"
            echo -e "  Your original configurations are backed up at:"
            echo -e "  ${CYAN}$BACKUP_DIR${RESET}"
            echo
        fi
    fi
}

# Show usage information
show_usage() {
    cat << EOF
${BOLD}${PURPLE}🏠 Simple Stow Configuration Restore Script v${SCRIPT_VERSION}${RESET}

${BOLD}USAGE:${RESET}
    $SCRIPT_NAME [options] [group/packages]

${BOLD}OPTIONS:${RESET}
    -n, --dry-run           Show what would be done without executing
    -f, --force             Force operations, remove conflicts
    -g, --group GROUP       Restore specific group
    -p, --packages LIST     Restore specific packages (comma-separated)
    --no-backup            Skip creating backup of existing configs
    --no-interactive       Run in non-interactive mode
    -s, --status           Show current package status and exit
    -h, --help             Show this help message

${BOLD}AVAILABLE GROUPS:${RESET}
EOF
    
    for group in "${!GROUPS[@]}"; do
        echo "    ${CYAN}$group${RESET}: ${GROUPS[$group]}"
    done
    
    cat << EOF

${BOLD}EXAMPLES:${RESET}
    # Restore all configurations (default)
    $SCRIPT_NAME

    # Dry run to see what would happen
    $SCRIPT_NAME --dry-run

    # Restore only essential packages
    $SCRIPT_NAME --group essential

    # Restore specific packages
    $SCRIPT_NAME --packages bash,git,nvim

    # Force restore, removing conflicts
    $SCRIPT_NAME --force

    # Check current status
    $SCRIPT_NAME --status

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -g|--group)
                GROUP="$2"
                shift 2
                ;;
            -p|--packages)
                GROUP="$2"
                shift 2
                ;;
            --no-backup)
                BACKUP=false
                shift
                ;;
            --no-interactive)
                INTERACTIVE=false
                shift
                ;;
            -s|--status)
                check_stow
                show_status
                exit 0
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                log ERROR "Unknown option: $1"
                echo ""
                show_usage
                exit 1
                ;;
            *)
                GROUP="$1"
                shift
                ;;
        esac
    done
}

# Main function
main() {
    # Parse arguments
    parse_arguments "$@"
    
    # Header
    echo
    echo -e "${BOLD}${PURPLE}🏠 Simple Stow Configuration Restore${RESET}"
    echo -e "${BLUE}Restoring your dotfiles with GNU Stow${RESET}"
    echo
    
    # Check dependencies
    check_stow
    
    # Show system information
    echo -e "${PURPLE}[STEP]${RESET} System Information"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Stow directory:    $STOW_DIR"
    echo "Target directory:  $TARGET_DIR"
    echo "Group to restore:  $GROUP"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    
    # Show current status unless in non-interactive mode
    if [[ "$INTERACTIVE" == "true" && "$DRY_RUN" == "false" ]]; then
        show_status
        
        # Confirmation prompt
        echo -e "${YELLOW}This will stow configurations from group/packages: ${BOLD}$GROUP${RESET}${YELLOW}"
        if [[ "$BACKUP" == "true" ]]; then
            echo -e "Existing configurations will be backed up first.${RESET}"
        else
            echo -e "No backup will be created.${RESET}"
        fi
        echo
        
        read -p "Continue? [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            log INFO "Restore cancelled by user"
            exit 0
        fi
        echo
    fi
    
    # Create backup if requested
    create_backup
    
    # Restore configurations
    if restore_configs; then
        show_post_install_notes
        log SUCCESS "All done! Your stow configurations have been restored."
    else
        log ERROR "Restore completed with some errors. Check the output above."
        exit 1
    fi
}

# Handle Ctrl+C gracefully
trap 'echo; log ERROR "Restore interrupted by user"; exit 1' INT TERM

# Run main function if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi