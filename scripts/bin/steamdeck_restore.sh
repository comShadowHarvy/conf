#!/bin/bash

# Steam Deck Restore Script
# Restores custom game icons and AnimationChanger files from backup

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

prompt() {
    echo -e "${BLUE}[PROMPT]${NC} $1"
}

# List available backups
list_backups() {
    local backup_dir="${1:-$HOME/steamdeck_backups}"
    
    if [[ ! -d "$backup_dir" ]]; then
        error "Backup directory not found: $backup_dir"
    fi
    
    local backups=($(find "$backup_dir" -maxdepth 1 -name "steamdeck_backup_*.tar.gz" -type f | sort -r))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        error "No backups found in: $backup_dir"
    fi
    
    echo "Available backups:"
    echo "===================="
    for i in "${!backups[@]}"; do
        local backup="${backups[$i]}"
        local size=$(du -h "$backup" | cut -f1)
        local date=$(stat -c %y "$backup" 2>/dev/null | cut -d'.' -f1 || stat -f "%Sm" "$backup")
        echo "$((i+1)). $(basename "$backup") - $size - $date"
    done
    echo ""
    
    echo "${backups[@]}"
}

# Extract backup
extract_backup() {
    local backup_file="$1"
    local extract_dir="$2"
    
    log "Extracting backup: $(basename "$backup_file")"
    mkdir -p "$extract_dir"
    tar -xzf "$backup_file" -C "$extract_dir"
    
    # Find the actual backup folder
    local backup_folder=$(find "$extract_dir" -maxdepth 1 -type d -name "backup_*" | head -1)
    echo "$backup_folder"
}

# Restore Steam icons
restore_steam_icons() {
    local backup_path="$1"
    
    log "Restoring Steam custom icons..."
    
    local steam_userdata="$HOME/.local/share/Steam/userdata"
    local icons_backup="$backup_path/steam_icons"
    
    if [[ ! -d "$icons_backup" ]]; then
        warn "No Steam icons found in backup"
        return
    fi
    
    if [[ ! -d "$steam_userdata" ]]; then
        warn "Steam userdata directory not found: $steam_userdata"
        warn "Please ensure Steam is installed and has been run at least once"
        return
    fi
    
    for user_backup in "$icons_backup"/userdata_*/; do
        if [[ ! -d "$user_backup" ]]; then
            continue
        fi
        
        local user_id=$(basename "$user_backup" | sed 's/userdata_//')
        local user_dir="$steam_userdata/$user_id"
        
        if [[ ! -d "$user_dir" ]]; then
            warn "User directory not found for user $user_id, skipping"
            continue
        fi
        
        # Restore grid images
        if [[ -d "$user_backup/grid" ]]; then
            mkdir -p "$user_dir/config"
            cp -r "$user_backup/grid" "$user_dir/config/" 2>/dev/null || true
            local icon_count=$(find "$user_backup/grid" -type f | wc -l)
            log "  ✓ Restored $icon_count custom icons for user $user_id"
        fi
        
        # Restore shortcuts.vdf
        if [[ -f "$user_backup/shortcuts.vdf" ]]; then
            mkdir -p "$user_dir/config"
            cp "$user_backup/shortcuts.vdf" "$user_dir/config/" 2>/dev/null || true
            log "  ✓ Restored shortcuts.vdf for user $user_id"
        fi
    done
}

# Restore AnimationChanger
restore_animationchanger() {
    local backup_path="$1"
    
    log "Restoring AnimationChanger files..."
    
    local restored=false
    
    # Restore to homebrew/plugins/AnimationChanger if it exists or can be created
    for anim_backup in "$backup_path"/animationchanger_*/; do
        if [[ ! -d "$anim_backup" ]]; then
            continue
        fi
        
        local backup_name=$(basename "$anim_backup")
        
        # Try to restore to original location based on backup name
        if [[ "$backup_name" == "animationchanger_AnimationChanger" ]]; then
            # This was from homebrew/plugins/AnimationChanger
            local restore_path="$HOME/homebrew/plugins/AnimationChanger"
            mkdir -p "$(dirname "$restore_path")"
            cp -r "$anim_backup" "$restore_path" 2>/dev/null || true
            log "  ✓ Restored AnimationChanger to: $restore_path"
            restored=true
        else
            # Generic restore location
            local restore_path="$HOME/.local/share/AnimationChanger"
            mkdir -p "$(dirname "$restore_path")"
            cp -r "$anim_backup" "$restore_path" 2>/dev/null || true
            log "  ✓ Restored AnimationChanger to: $restore_path"
            restored=true
        fi
    done
    
    if [[ "$restored" == "false" ]]; then
        warn "No AnimationChanger files found in backup"
    fi
}

# Restore Decky Loader content
restore_decky_content() {
    local backup_path="$1"
    
    log "Restoring Decky Loader content..."
    
    local decky_path="$HOME/homebrew"
    
    if [[ ! -d "$decky_path" ]]; then
        warn "Decky Loader not found at: $decky_path"
        warn "Please install Decky Loader before restoring content"
        return
    fi
    
    local restored_items=0
    
    # Restore plugins
    if [[ -d "$backup_path/decky_plugins" ]]; then
        cp -r "$backup_path/decky_plugins" "$decky_path/plugins" 2>/dev/null || true
        local plugin_count=$(ls -1 "$backup_path/decky_plugins" 2>/dev/null | wc -l)
        log "  ✓ Restored $plugin_count Decky plugins"
        ((restored_items++))
    fi
    
    # Restore settings
    if [[ -d "$backup_path/decky_settings" ]]; then
        cp -r "$backup_path/decky_settings" "$decky_path/settings" 2>/dev/null || true
        log "  ✓ Restored Decky plugin settings"
        ((restored_items++))
    fi
    
    # Restore themes
    if [[ -d "$backup_path/decky_themes" ]]; then
        cp -r "$backup_path/decky_themes" "$decky_path/themes" 2>/dev/null || true
        local theme_count=$(ls -1 "$backup_path/decky_themes" 2>/dev/null | wc -l)
        log "  ✓ Restored $theme_count Decky themes"
        ((restored_items++))
    fi
    
    # Show inventory if available
    if [[ -f "$backup_path/decky_inventory.txt" ]]; then
        echo ""
        log "Decky Loader Inventory:"
        cat "$backup_path/decky_inventory.txt" | head -30 | sed 's/^/    /'
        echo ""
    fi
    
    if [[ $restored_items -eq 0 ]]; then
        warn "No Decky Loader content found in backup"
    fi
}

# Main execution
main() {
    local backup_dir="${1:-$HOME/steamdeck_backups}"
    
    echo "========================================"
    echo "  Steam Deck Configuration Restore"
    echo "========================================"
    echo ""
    
    # List and select backup
    local backups_output=$(list_backups "$backup_dir")
    local backups=($(echo "$backups_output" | tail -1))
    
    read -p "Select backup number to restore (1-${#backups[@]}): " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#backups[@]}" ]]; then
        error "Invalid selection"
    fi
    
    local selected_backup="${backups[$((selection-1))]}"
    
    echo ""
    log "Selected: $(basename "$selected_backup")"
    echo ""
    
    read -p "Proceed with restore? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Restore cancelled"
        exit 0
    fi
    
    echo ""
    
    # Extract backup
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    local backup_folder=$(extract_backup "$selected_backup" "$temp_dir")
    
    # Restore components
    restore_steam_icons "$backup_folder"
    restore_animationchanger "$backup_folder"
    restore_decky_content "$backup_folder"
    
    echo ""
    log "Restore complete! 🎮"
    log "You may need to restart Steam or your Steam Deck for changes to take effect."
}

# Run with optional backup directory argument
main "$@"
