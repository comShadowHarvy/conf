#!/usr/bin/env bash
# =======================================================
# Configuration Restoration Script  
# Restore previous configuration from backup
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

# List available backups
list_backups() {
    log "INFO" "Available backups:"
    if [[ -d backups ]]; then
        local count=0
        for backup in backups/*/; do
            if [[ -d "$backup" ]]; then
                count=$((count + 1))
                local backup_name=$(basename "$backup")
                local files=$(find "$backup" -maxdepth 1 -type f | wc -l)
                echo "  $count) $backup_name ($files files)"
            fi
        done
        
        if [[ $count -eq 0 ]]; then
            log "WARN" "No backups found in backups/ directory"
            return 1
        fi
        return 0
    else
        log "WARN" "No backups directory found"
        return 1
    fi
}

# Select backup to restore
select_backup() {
    local backup_dirs=(backups/*/)
    backup_dirs=("${backup_dirs[@]%/}")  # Remove trailing slashes
    
    if [[ ${#backup_dirs[@]} -eq 0 ]]; then
        log "ERROR" "No backups available"
        return 1
    fi
    
    echo ""
    log "INFO" "Select backup to restore:"
    local i=1
    for backup in "${backup_dirs[@]}"; do
        if [[ -d "$backup" ]]; then
            local backup_name=$(basename "$backup")
            echo "  $i) $backup_name"
            i=$((i + 1))
        fi
    done
    
    echo ""
    read -p "Enter backup number [1-$((i-1))] or 'q' to quit: " selection
    
    if [[ "$selection" == "q" ]]; then
        log "INFO" "Operation cancelled"
        exit 0
    fi
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le $((i-1)) ]]; then
        SELECTED_BACKUP="${backup_dirs[$((selection-1))]}"
        log "INFO" "Selected: $(basename "$SELECTED_BACKUP")"
    else
        log "ERROR" "Invalid selection"
        return 1
    fi
}

# Restore from selected backup
restore_backup() {
    local backup_dir="$1"
    
    log "INFO" "Restoring from: $(basename "$backup_dir")"
    
    # Show what will be restored
    echo ""
    log "INFO" "Files to restore:"
    for file in "$backup_dir"/*; do
        if [[ -f "$file" ]]; then
            local filename=$(basename "$file")
            local target_path
            
            case "$filename" in
                ".zshrc") target_path=".zshrc" ;;
                ".zimrc") target_path="~/.zimrc" ;;
                ".zlogin") target_path="~/.zlogin" ;;
                ".zlogout") target_path="~/.zlogout" ;;
                *) target_path="$filename" ;;
            esac
            
            echo "  • $filename → $target_path"
        fi
    done
    
    echo ""
    read -p "Continue with restoration? [y/N] " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "Restoration cancelled"
        return 1
    fi
    
    # Create current backup before restoration
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local current_backup="backups/pre-restore-${timestamp}"
    mkdir -p "$current_backup"
    
    [[ -f .zshrc ]] && cp .zshrc "$current_backup/"
    log "INFO" "Current config backed up to: $current_backup"
    
    # Restore files
    for file in "$backup_dir"/*; do
        if [[ -f "$file" ]]; then
            local filename=$(basename "$file")
            
            case "$filename" in
                ".zshrc")
                    cp "$file" .zshrc
                    log "INFO" "Restored: .zshrc"
                    ;;
                ".zimrc")
                    cp "$file" ~/.zimrc
                    log "INFO" "Restored: ~/.zimrc"
                    ;;
                ".zlogin")
                    cp "$file" ~/.zlogin
                    log "INFO" "Restored: ~/.zlogin"
                    ;;
                ".zlogout")
                    cp "$file" ~/.zlogout
                    log "INFO" "Restored: ~/.zlogout"
                    ;;
            esac
        fi
    done
}

# Validate restored configuration
validate_restored_config() {
    log "INFO" "Validating restored configuration..."
    
    if zsh -n .zshrc; then
        log "INFO" "✓ Configuration syntax is valid"
        return 0
    else
        log "ERROR" "✗ Configuration syntax error detected"
        return 1
    fi
}

# Main execution
main() {
    log "INFO" "Configuration Restoration Tool"
    echo ""
    
    # Check if we're in the right directory
    if [[ ! -f .zshrc ]] || [[ ! -f .aliases ]]; then
        log "ERROR" "Please run this script from the /home/me/git/conf directory"
        exit 1
    fi
    
    # List and select backup
    if ! list_backups; then
        exit 1
    fi
    
    if ! select_backup; then
        exit 1
    fi
    
    # Restore configuration
    if restore_backup "$SELECTED_BACKUP"; then
        if validate_restored_config; then
            log "INFO" "✅ Configuration restored successfully!"
            echo ""
            log "INFO" "To apply changes, run: exec zsh -l"
            log "INFO" "Or open a new terminal session"
        else
            log "ERROR" "❌ Restored configuration has syntax errors!"
            log "WARN" "You may need to fix the configuration manually"
        fi
    fi
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi