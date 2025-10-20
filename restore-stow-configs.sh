#!/usr/bin/env bash
# =============================================================================
# Stow Configuration Restore Script
# =============================================================================
# Author: Shadow Harvey  
# Description: Simple script to restore all stow configurations with one command
# Usage: ./restore-stow-configs.sh [options]
# =============================================================================

set -euo pipefail

# Script metadata
SCRIPT_NAME="restore-stow-configs"
SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
STOW_MANAGER="${SCRIPT_DIR}/stow-manager.sh"
CONFIG_FILE="${SCRIPT_DIR}/stow-config.yaml"

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

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for stow
    if ! command -v stow >/dev/null 2>&1; then
        missing_deps+=("stow")
    fi
    
    # Check for stow manager
    if [[ ! -x "$STOW_MANAGER" ]]; then
        missing_deps+=("stow-manager.sh (not found or not executable)")
    fi
    
    # Check for config file
    if [[ ! -f "$CONFIG_FILE" ]]; then
        missing_deps+=("stow-config.yaml")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log ERROR "Missing dependencies:"
        printf '  • %s\n' "${missing_deps[@]}"
        
        if [[ " ${missing_deps[*]} " =~ " stow " ]]; then
            echo ""
            log INFO "Install stow with:"
            echo "  • Arch Linux: sudo pacman -S stow"
            echo "  • Ubuntu/Debian: sudo apt install stow"
            echo "  • macOS: brew install stow"
        fi
        
        exit 1
    fi
}

# Show system status
show_system_info() {
    log STEP "System Information"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Stow directory:    $SCRIPT_DIR"
    echo "Target directory:  $HOME"
    echo "Config file:       $CONFIG_FILE"
    echo "Stow manager:      $STOW_MANAGER"
    echo "Group to restore:  $GROUP"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
}

# Show current package status
show_current_status() {
    log STEP "Current Package Status"
    
    if [[ -x "$STOW_MANAGER" ]]; then
        "$STOW_MANAGER" status
    else
        log WARNING "Cannot show detailed status (stow-manager.sh not available)"
        
        # Fallback: simple status check
        echo "Available packages in $SCRIPT_DIR:"
        find "$SCRIPT_DIR" -maxdepth 1 -type d ! -name ".*" ! -name logs ! -name backups \
            -exec basename {} \; | sort | sed 's/^/  • /'
    fi
    
    echo
}

# Backup existing configurations
create_backup() {
    if [[ "$BACKUP" == "false" ]]; then
        log INFO "Skipping backup (--no-backup specified)"
        return
    fi
    
    log STEP "Creating backup of existing configurations"
    
    local backup_dir="${HOME}/.stow-restore-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Get list of files that would be overwritten
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
        echo "BACKUP_DIR=\"$backup_dir\"" > "${SCRIPT_DIR}/.last_backup"
    else
        log INFO "No files needed backing up"
        rmdir "$backup_dir" 2>/dev/null || true
    fi
}

# Restore configurations using stow manager
restore_configs() {
    log STEP "Restoring stow configurations"
    
    local stow_args=()
    
    # Add global options
    [[ "$DRY_RUN" == "true" ]] && stow_args+=(--dry-run)
    [[ "$FORCE" == "true" ]] && stow_args+=(--force)
    [[ "$INTERACTIVE" == "false" ]] && stow_args+=(--no-interactive)
    
    # Determine what to stow
    local command_args=()
    case "$GROUP" in
        all|full)
            # Use the full group defined in config
            command_args+=(group full)
            ;;
        essential|minimal|development|desktop)
            # Use predefined groups
            command_args+=(group "$GROUP")
            ;;
        *)
            # Treat as individual package names
            command_args+=(stow "$GROUP")
            ;;
    esac
    
    # Execute stow manager
    log INFO "Executing: $STOW_MANAGER ${stow_args[*]} ${command_args[*]}"
    
    if "$STOW_MANAGER" "${stow_args[@]}" "${command_args[@]}"; then
        log SUCCESS "Successfully restored stow configurations!"
        return 0
    else
        log ERROR "Failed to restore some configurations"
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
    ${YELLOW}tmux source ~/.config/tmux/tmux.conf${RESET}

  • For Neovim users, first launch may install plugins:
    ${YELLOW}nvim${RESET}

${BOLD}📁 Useful Commands:${RESET}
  • Check package status: ${YELLOW}./stow-manager.sh status${RESET}
  • Unstow a package:     ${YELLOW}./stow-manager.sh unstow <package>${RESET}
  • Restow a package:     ${YELLOW}./stow-manager.sh restow <package>${RESET}

EOF

    if [[ -f "${SCRIPT_DIR}/.last_backup" ]]; then
        source "${SCRIPT_DIR}/.last_backup"
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
${BOLD}${PURPLE}🏠 Stow Configuration Restore Script v${SCRIPT_VERSION}${RESET}

${BOLD}USAGE:${RESET}
    $SCRIPT_NAME [options] [group/packages]

${BOLD}OPTIONS:${RESET}
    -n, --dry-run           Show what would be done without executing
    -f, --force             Force operations, skip confirmations
    -g, --group GROUP       Restore specific group [full|essential|minimal|development|desktop]
    -p, --packages LIST     Restore specific packages (comma-separated)
    --no-backup            Skip creating backup of existing configs
    --no-interactive       Run in non-interactive mode
    -s, --status           Show current package status and exit
    -h, --help             Show this help message

${BOLD}GROUPS:${RESET}
    ${CYAN}full${RESET}        All packages (default)
    ${CYAN}essential${RESET}   Core shell and git configuration
    ${CYAN}minimal${RESET}     Minimal setup (bash, git, shared)
    ${CYAN}development${RESET} Development tools (nvim, tmux, vscode)
    ${CYAN}desktop${RESET}     GUI/Desktop environment (hyprland, waybar)

${BOLD}EXAMPLES:${RESET}
    # Restore all configurations
    $SCRIPT_NAME

    # Dry run to see what would happen
    $SCRIPT_NAME --dry-run

    # Restore only essential packages
    $SCRIPT_NAME --group essential

    # Restore specific packages
    $SCRIPT_NAME --packages bash,git,nvim

    # Force restore without prompts
    $SCRIPT_NAME --force --no-interactive

    # Check current status
    $SCRIPT_NAME --status

${BOLD}FILES:${RESET}
    Config:     $CONFIG_FILE
    Manager:    $STOW_MANAGER

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
                INTERACTIVE=false
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
                show_current_status
                exit 0
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                log ERROR "Unknown option: $1"
                echo ""
                show_usage
                exit 1
                ;;
            *)
                # Treat remaining arguments as package names
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
    echo -e "${BOLD}${PURPLE}🏠 Stow Configuration Restore${RESET}"
    echo -e "${BLUE}Restoring your dotfiles with GNU Stow${RESET}"
    echo
    
    # Check dependencies
    check_dependencies
    
    # Show system information
    show_system_info
    
    # Show current status unless in non-interactive mode
    if [[ "$INTERACTIVE" == "true" && "$DRY_RUN" == "false" ]]; then
        show_current_status
        
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
        # Show post-installation notes
        show_post_install_notes
        log SUCCESS "All done! Your stow configurations have been restored."
    else
        log ERROR "Restore completed with some errors. Check the output above."
        exit 1
    fi
}

# Handle Ctrl+C gracefully
trap 'echo; log ERROR "Restore interrupted by user"; exit 1' INT TERM

# Run main function
main "$@"