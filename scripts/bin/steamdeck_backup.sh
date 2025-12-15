#!/bin/bash

# Steam Deck Backup Script
# Backs up custom game icons and AnimationChanger files

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-$HOME/steamdeck_backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory
create_backup_dir() {
    log "Creating backup directory: $BACKUP_PATH"
    mkdir -p "$BACKUP_PATH"
}

# Backup Steam custom icons (grid images)
backup_steam_icons() {
    log "Backing up Steam custom icons..."
    
    local steam_userdata="$HOME/.local/share/Steam/userdata"
    
    if [[ -d "$steam_userdata" ]]; then
        for user_dir in "$steam_userdata"/*/; do
            if [[ -d "${user_dir}config/grid" ]]; then
                local user_id=$(basename "$user_dir")
                local dest_dir="$BACKUP_PATH/steam_icons/userdata_${user_id}"
                
                mkdir -p "$dest_dir"
                cp -r "${user_dir}config/grid" "$dest_dir/" 2>/dev/null || true
                
                local icon_count=$(find "$dest_dir" -type f | wc -l)
                if [[ $icon_count -gt 0 ]]; then
                    log "  ✓ Backed up $icon_count custom icons for user $user_id"
                fi
            fi
        done
        
        # Also backup shortcuts.vdf which contains non-Steam game info
        for user_dir in "$steam_userdata"/*/; do
            if [[ -f "${user_dir}config/shortcuts.vdf" ]]; then
                local user_id=$(basename "$user_dir")
                local dest_dir="$BACKUP_PATH/steam_icons/userdata_${user_id}"
                
                mkdir -p "$dest_dir"
                cp "${user_dir}config/shortcuts.vdf" "$dest_dir/" 2>/dev/null || true
                log "  ✓ Backed up shortcuts.vdf for user $user_id"
            fi
        done
    else
        warn "Steam userdata directory not found: $steam_userdata"
    fi
}

# Backup AnimationChanger files
backup_animationchanger() {
    log "Backing up AnimationChanger files..."
    
    local anim_paths=(
        "$HOME/homebrew/plugins/AnimationChanger"
        "$HOME/.local/share/AnimationChanger"
        "$HOME/.config/AnimationChanger"
    )
    
    local found=false
    
    for path in "${anim_paths[@]}"; do
        if [[ -d "$path" ]]; then
            local dest_name=$(basename "$path")
            cp -r "$path" "$BACKUP_PATH/animationchanger_${dest_name}" 2>/dev/null || true
            log "  ✓ Backed up AnimationChanger from: $path"
            found=true
        fi
    done
    
    if [[ "$found" == "false" ]]; then
        warn "AnimationChanger directory not found in common locations"
        warn "Checked: ${anim_paths[*]}"
    fi
}

# Backup Decky Loader plugins (if present)
backup_decky_plugins() {
    log "Backing up Decky Loader content..."
    
    local decky_path="$HOME/homebrew"
    
    if [[ -d "$decky_path" ]]; then
        # Backup all plugins (downloaded content)
        if [[ -d "${decky_path}/plugins" ]]; then
            cp -r "${decky_path}/plugins" "$BACKUP_PATH/decky_plugins" 2>/dev/null || true
            local plugin_count=$(ls -1 "${decky_path}/plugins" 2>/dev/null | wc -l)
            log "  ✓ Backed up $plugin_count Decky plugins"
        fi
        
        # Backup plugin settings
        if [[ -d "${decky_path}/settings" ]]; then
            cp -r "${decky_path}/settings" "$BACKUP_PATH/decky_settings" 2>/dev/null || true
            log "  ✓ Backed up Decky plugin settings"
        fi
        
        # Backup themes if present
        if [[ -d "${decky_path}/themes" ]]; then
            cp -r "${decky_path}/themes" "$BACKUP_PATH/decky_themes" 2>/dev/null || true
            local theme_count=$(ls -1 "${decky_path}/themes" 2>/dev/null | wc -l)
            log "  ✓ Backed up $theme_count Decky themes"
        fi
        
        # Backup logs (useful for troubleshooting)
        if [[ -d "${decky_path}/logs" ]]; then
            cp -r "${decky_path}/logs" "$BACKUP_PATH/decky_logs" 2>/dev/null || true
            log "  ✓ Backed up Decky logs"
        fi
        
        # Create a detailed inventory
        if [[ -d "${decky_path}/plugins" ]]; then
            {
                echo "Decky Loader Plugins Inventory"
                echo "================================"
                echo "Date: $(date)"
                echo ""
                for plugin_dir in "${decky_path}/plugins"/*/; do
                    if [[ -d "$plugin_dir" ]]; then
                        local plugin_name=$(basename "$plugin_dir")
                        local plugin_size=$(du -sh "$plugin_dir" 2>/dev/null | cut -f1)
                        echo "Plugin: $plugin_name"
                        echo "  Size: $plugin_size"
                        
                        # Check for package.json or plugin.json
                        if [[ -f "${plugin_dir}package.json" ]]; then
                            local version=$(grep -oP '"version"\s*:\s*"\K[^"]+' "${plugin_dir}package.json" 2>/dev/null || echo "unknown")
                            echo "  Version: $version"
                        elif [[ -f "${plugin_dir}plugin.json" ]]; then
                            local version=$(grep -oP '"version"\s*:\s*"\K[^"]+' "${plugin_dir}plugin.json" 2>/dev/null || echo "unknown")
                            echo "  Version: $version"
                        fi
                        echo ""
                    fi
                done
            } > "$BACKUP_PATH/decky_inventory.txt" 2>/dev/null || true
            log "  ✓ Created Decky inventory"
        fi
    else
        warn "Decky Loader not found at: $decky_path"
    fi
}

# Create backup manifest
create_manifest() {
    log "Creating backup manifest..."
    
    cat > "$BACKUP_PATH/MANIFEST.txt" <<EOF
Steam Deck Backup
=================
Date: $(date)
Hostname: $(hostname)
User: $(whoami)

Backup Contents:
EOF
    
    find "$BACKUP_PATH" -type f -o -type d | sed "s|$BACKUP_PATH/||" | sort >> "$BACKUP_PATH/MANIFEST.txt"
    
    log "  ✓ Manifest created"
}

# Compress backup
compress_backup() {
    log "Compressing backup..."
    
    local archive_name="steamdeck_backup_$TIMESTAMP.tar.gz"
    tar -czf "$BACKUP_DIR/$archive_name" -C "$BACKUP_DIR" "backup_$TIMESTAMP"
    
    local size=$(du -h "$BACKUP_DIR/$archive_name" | cut -f1)
    log "  ✓ Backup compressed: $archive_name ($size)"
    
    # Remove uncompressed backup
    rm -rf "$BACKUP_PATH"
    
    echo ""
    log "Backup complete: $BACKUP_DIR/$archive_name"
}

# Main execution
main() {
    echo "========================================"
    echo "  Steam Deck Configuration Backup"
    echo "========================================"
    echo ""
    
    create_backup_dir
    backup_steam_icons
    backup_animationchanger
    backup_decky_plugins
    create_manifest
    compress_backup
    
    echo ""
    log "All done! 🎮"
}

# Run main function
main
