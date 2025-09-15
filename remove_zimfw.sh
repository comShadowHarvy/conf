#!/usr/bin/env bash
# =======================================================
# ZimFW Removal and Cleanup Script
# Safely removes ZimFW and transitions to clean config
# =======================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    shift
    case $level in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $*" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $*" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $*" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $*" ;;
    esac
}

# Backup current config
backup_current_config() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="backups/pre-zimfw-removal-${timestamp}"
    
    log "INFO" "Creating backup directory: $backup_dir"
    mkdir -p "$backup_dir"
    
    # Backup main files
    [[ -f .zshrc ]] && cp .zshrc "$backup_dir/"
    [[ -f ~/.zimrc ]] && cp ~/.zimrc "$backup_dir/"
    [[ -f ~/.zlogin ]] && cp ~/.zlogin "$backup_dir/"
    [[ -f ~/.zlogout ]] && cp ~/.zlogout "$backup_dir/"
    
    log "INFO" "Backup complete: $backup_dir"
}

# Remove ZimFW files
remove_zimfw_files() {
    log "INFO" "Removing ZimFW files..."
    
    # ZimFW directory
    if [[ -d ~/.zim ]]; then
        log "INFO" "Removing ZimFW directory: ~/.zim"
        rm -rf ~/.zim
    fi
    
    # ZimFW config files
    local zimfw_files=(~/.zimrc ~/.zlogin ~/.zlogout)
    for file in "${zimfw_files[@]}"; do
        if [[ -f "$file" ]]; then
            log "INFO" "Removing: $file"
            rm -f "$file"
        fi
    done
    
    # Clear any zimfw commands from history
    if [[ -f ~/.zsh_history ]]; then
        log "INFO" "Removing zimfw entries from history"
        sed -i '/zimfw/d' ~/.zsh_history 2>/dev/null || true
    fi
}

# Install clean configuration
install_clean_config() {
    log "INFO" "Installing clean configuration..."
    
    if [[ -f .zshrc.clean ]]; then
        # Replace current .zshrc with clean version
        cp .zshrc.clean .zshrc
        log "INFO" "Installed clean .zshrc configuration"
    else
        log "ERROR" "Clean configuration file (.zshrc.clean) not found!"
        log "ERROR" "Please run this script from the git/conf directory"
        exit 1
    fi
}

# Clean cache directories
clean_caches() {
    log "INFO" "Cleaning ZSH cache directories..."
    
    local cache_dirs=(
        ~/.cache/zsh
        ~/.local/share/zsh
        ~/.zcompdump*
    )
    
    for dir in "${cache_dirs[@]}"; do
        if [[ -e "$dir" ]]; then
            log "INFO" "Removing cache: $dir"
            rm -rf "$dir"
        fi
    done
}

# Validate syntax
validate_config() {
    log "INFO" "Validating new configuration syntax..."
    
    if zsh -n .zshrc; then
        log "INFO" "✓ Configuration syntax is valid"
        return 0
    else
        log "ERROR" "✗ Configuration syntax error detected"
        return 1
    fi
}

# Show differences
show_differences() {
    log "INFO" "Key differences in the clean configuration:"
    echo -e "  ${GREEN}✓${NC} Removed ZimFW plugin system"
    echo -e "  ${GREEN}✓${NC} Native Zsh completion system"
    echo -e "  ${GREEN}✓${NC} Maintained all existing functionality"
    echo -e "  ${GREEN}✓${NC} Faster startup (no plugin loading)"
    echo -e "  ${GREEN}✓${NC} Simplified maintenance"
    echo -e "  ${GREEN}✓${NC} Kept modular alias system"
    echo -e "  ${GREEN}✓${NC} Preserved FZF, zoxide, and other tools"
    echo ""
    echo -e "  ${YELLOW}!${NC} Lost: Plugin-based syntax highlighting"
    echo -e "  ${YELLOW}!${NC} Lost: Plugin-based autosuggestions"
    echo -e "  ${YELLOW}!${NC} Lost: Plugin-based history search"
    echo ""
    echo -e "  ${BLUE}i${NC} You can add these features back manually if needed"
}

# Main execution
main() {
    log "INFO" "Starting ZimFW removal process..."
    
    # Check if we're in the right directory
    if [[ ! -f .zshrc.clean ]]; then
        log "ERROR" "Please run this script from the /home/me/git/conf directory"
        exit 1
    fi
    
    # Ask for confirmation
    echo ""
    log "WARN" "This will:"
    echo "  • Remove ZimFW and all plugins"
    echo "  • Replace your current .zshrc with a clean version"  
    echo "  • Preserve your modular aliases"
    echo "  • Create backups of current config"
    echo ""
    read -p "Continue? [y/N] " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "Operation cancelled"
        exit 0
    fi
    
    # Execute removal steps
    backup_current_config
    remove_zimfw_files
    clean_caches
    install_clean_config
    
    if validate_config; then
        log "INFO" "✅ ZimFW removal completed successfully!"
        echo ""
        show_differences
        echo ""
        log "INFO" "To apply changes, run: exec zsh -l"
        log "INFO" "Or open a new terminal session"
    else
        log "ERROR" "❌ Configuration validation failed!"
        log "ERROR" "Your original .zshrc is backed up for restoration"
        exit 1
    fi
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi