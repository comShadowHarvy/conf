#!/usr/bin/env bash

# Steam Artwork Sync Script
# Backup and restore Steam custom artwork between Steam Deck and Desktop
# License: MIT
# Author: Generated for Steam Deck <-> Desktop artwork synchronization

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "${0}")"
readonly VERSION="1.0.0"

# Steam path detection
readonly DEFAULT_DECK_STEAM_PATH="$HOME/.steam/root"
readonly DEFAULT_DESKTOP_STEAM_PATH="$HOME/.local/share/Steam"

# Artwork file patterns
readonly ARTWORK_PATTERNS=(
    "*.jpg"
    "*.png" 
    "*.webp"
    "*.jpeg"
)

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Global variables
OPERATION=""
SOURCE_STEAM_PATH=""
DEST_STEAM_PATH=""
BACKUP_DIR=""
DRY_RUN=false
VERBOSE=false
FORCE=false
CUSTOM_ONLY=false

# Cleanup on exit
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo -e "${RED}Script exited with error (code: $exit_code)${NC}" >&2
    fi
}

trap cleanup EXIT

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

# Usage information
usage() {
    cat << EOF
Steam Artwork Sync v${VERSION}

SYNOPSIS
    ${SCRIPT_NAME} <command> [options]

DESCRIPTION
    Backup and restore Steam custom artwork between Steam Deck and Desktop.
    
    Steam stores custom artwork in two locations:
    • appcache/librarycache/ - Downloaded and custom artwork files
    • userdata/*/config/grid/ - User-uploaded custom artwork (if exists)

COMMANDS
    backup      Create backup of Steam artwork
    restore     Restore Steam artwork from backup
    info        Show Steam installation paths and artwork statistics

OPTIONS
    -s, --source PATH       Source Steam installation path
    -d, --dest PATH         Destination Steam installation path  
    -o, --output DIR        Backup directory (for backup command)
    -i, --input DIR         Backup directory (for restore command)
    -n, --dry-run          Show what would be done without executing
    -c, --custom-only      Backup/restore only user-uploaded custom artwork
    -v, --verbose          Enable verbose output
    -f, --force            Skip confirmation prompts
    -h, --help             Show this help message

EXAMPLES
    # Backup from Steam Deck (mounted at /mnt/deck)
    ${SCRIPT_NAME} backup -s /mnt/deck/.steam/root -o ~/deck-artwork-backup

    # Restore to desktop Steam
    ${SCRIPT_NAME} restore -i ~/deck-artwork-backup -d ~/.local/share/Steam

    # Auto-detect paths and backup
    ${SCRIPT_NAME} backup

    # Show artwork info for current installation
    ${SCRIPT_NAME} info
    
    # Backup only custom user-uploaded artwork
    ${SCRIPT_NAME} backup --custom-only -o ~/custom-artwork-only

NOTES
    • Steam should be closed before running restore operations
    • Default paths are auto-detected based on common installations
    • Backup includes both cached artwork and custom uploads
    • Use --dry-run to preview operations before executing

EOF
}

# Check if Steam is running
check_steam_running() {
    if pgrep -x "steam" > /dev/null; then
        log_warning "Steam is currently running!"
        if [[ "$FORCE" != true ]]; then
            echo -n "Do you want to continue? This may cause issues. (y/N): "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                log_error "Aborted by user"
                exit 1
            fi
        fi
    fi
}

# Detect Steam installation path
detect_steam_path() {
    local paths=(
        "$HOME/.local/share/Steam"
        "$HOME/.steam/root"
        "$HOME/.var/app/com.valvesoftware.Steam/home/.local/share/Steam"
    )
    
    for path in "${paths[@]}"; do
        if [[ -d "$path/appcache" && -d "$path/userdata" ]]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# Get Steam user ID from userdata directory
get_steam_userid() {
    local steam_path="$1"
    local userdata_path="$steam_path/userdata"
    
    if [[ ! -d "$userdata_path" ]]; then
        log_error "No userdata directory found at $userdata_path"
        return 1
    fi
    
    # Find the first numeric directory in userdata
    local userid
    local userid_path
    userid_path=$(find "$userdata_path" -mindepth 1 -maxdepth 1 -type d -name '[0-9]*' | head -1)
    
    if [[ -n "$userid_path" ]]; then
        userid=$(basename "$userid_path")
    fi
    
    if [[ -z "$userid" ]]; then
        log_error "No Steam user ID found in $userdata_path"
        return 1
    fi
    
    echo "$userid"
}

# Count artwork files
count_artwork_files() {
    local path="$1"
    local count=0
    
    if [[ -d "$path" ]]; then
        for pattern in "${ARTWORK_PATTERNS[@]}"; do
            count=$((count + $(find "$path" -name "$pattern" -type f 2>/dev/null | wc -l)))
        done
    fi
    
    echo "$count"
}

# Get directory size in human readable format
get_dir_size() {
    local path="$1"
    if [[ -d "$path" ]]; then
        du -sh "$path" 2>/dev/null | cut -f1 || echo "0B"
    else
        echo "0B"
    fi
}

# Show Steam artwork information
show_info() {
    log_info "Steam Artwork Information"
    echo
    
    # Try to detect Steam path
    local steam_path
    if steam_path=$(detect_steam_path); then
        log_info "Detected Steam installation: $steam_path"
        
        local userid
        if userid=$(get_steam_userid "$steam_path"); then
            log_info "Steam User ID: $userid"
            
            # Show artwork statistics
            local librarycache_path="$steam_path/appcache/librarycache"
            local grid_path="$steam_path/userdata/$userid/config/grid"
            
            local cache_count cache_size grid_count grid_size
            cache_count=$(count_artwork_files "$librarycache_path")
            cache_size=$(get_dir_size "$librarycache_path")
            grid_count=$(count_artwork_files "$grid_path")
            grid_size=$(get_dir_size "$grid_path")
            
            echo
            log_info "Downloaded/Cached Artwork:"
            echo "  Path: $librarycache_path"
            echo "  Files: $cache_count"
            echo "  Size: $cache_size"
            
            echo
            log_info "Custom User-Uploaded Artwork:"
            echo "  Path: $grid_path"
            echo "  Files: $grid_count"
            echo "  Size: $grid_size"
            
            echo
            log_info "Total artwork files: $((cache_count + grid_count))"
            if [[ $grid_count -gt 0 ]]; then
                log_info "Custom artwork detected! Use --custom-only to sync only custom artwork"
            fi
            
        else
            log_error "Could not determine Steam user ID"
            exit 1
        fi
    else
        log_error "No Steam installation detected"
        echo "Please specify Steam path manually with -s option"
        exit 1
    fi
}

# Create backup
create_backup() {
    local source_path="$SOURCE_STEAM_PATH"
    local backup_dir="$BACKUP_DIR"
    
    log_info "Creating backup from: $source_path"
    log_info "Backup destination: $backup_dir"
    
    # Verify source path exists
    if [[ ! -d "$source_path" ]]; then
        log_error "Source Steam path does not exist: $source_path"
        exit 1
    fi
    
    # Get Steam user ID
    local userid
    if ! userid=$(get_steam_userid "$source_path"); then
        exit 1
    fi
    
    log_verbose "Using Steam User ID: $userid"
    
    # Define source paths
    local source_cache="$source_path/appcache/librarycache"
    local source_grid="$source_path/userdata/$userid/config/grid"
    
    # Check if source directories exist and have content
    local cache_count grid_count
    if [[ "$CUSTOM_ONLY" == true ]]; then
        cache_count=0  # Skip library cache in custom-only mode
        grid_count=$(count_artwork_files "$source_grid")
        log_info "Custom-only mode: focusing on user-uploaded artwork only"
    else
        cache_count=$(count_artwork_files "$source_cache")
        grid_count=$(count_artwork_files "$source_grid")
    fi
    
    if [[ $cache_count -eq 0 && $grid_count -eq 0 ]]; then
        if [[ "$CUSTOM_ONLY" == true ]]; then
            log_error "No custom artwork files found in source Steam installation"
        else
            log_error "No artwork files found in source Steam installation"
        fi
        exit 1
    fi
    
    log_info "Found $cache_count library cache files, $grid_count custom grid files"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would create backup directory: $backup_dir"
        log_info "[DRY RUN] Would copy $cache_count files from library cache"
        log_info "[DRY RUN] Would copy $grid_count files from grid"
        return 0
    fi
    
    # Create backup directory structure
    mkdir -p "$backup_dir"/{librarycache,grid}
    
    # Backup library cache (skip in custom-only mode)
    if [[ $cache_count -gt 0 && "$CUSTOM_ONLY" != true ]]; then
        log_info "Backing up library cache artwork..."
        rsync -av --progress \
            --include="*/" \
            $(printf -- "--include=%s " "${ARTWORK_PATTERNS[@]}") \
            --exclude="*" \
            "$source_cache/" "$backup_dir/librarycache/"
    fi
    
    # Backup grid files if they exist
    if [[ -d "$source_grid" && $grid_count -gt 0 ]]; then
        log_info "Backing up custom grid artwork..."
        rsync -av --progress \
            $(printf -- "--include=%s " "${ARTWORK_PATTERNS[@]}") \
            --exclude="*" \
            "$source_grid/" "$backup_dir/grid/"
    fi
    
    # Create manifest file
    local manifest_file="$backup_dir/manifest.json"
    log_info "Creating backup manifest..."
    
    cat > "$manifest_file" << EOF
{
    "created": "$(date -Iseconds)",
    "source_path": "$source_path", 
    "steam_userid": "$userid",
    "script_version": "$VERSION",
    "custom_only": $CUSTOM_ONLY,
    "stats": {
        "librarycache_files": $cache_count,
        "grid_files": $grid_count,
        "backup_size": "$(get_dir_size "$backup_dir")"
    }
}
EOF
    
    log_success "Backup completed successfully!"
    log_info "Backup location: $backup_dir"
    log_info "Total files backed up: $((cache_count + grid_count))"
    log_info "Backup size: $(get_dir_size "$backup_dir")"
}

# Restore from backup  
restore_backup() {
    local dest_path="$DEST_STEAM_PATH"
    local backup_dir="$BACKUP_DIR"
    
    log_info "Restoring to: $dest_path"
    log_info "From backup: $backup_dir"
    
    # Verify backup directory and manifest
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup directory does not exist: $backup_dir"
        exit 1
    fi
    
    local manifest_file="$backup_dir/manifest.json"
    if [[ ! -f "$manifest_file" ]]; then
        log_error "Backup manifest not found: $manifest_file"
        exit 1
    fi
    
    # Verify destination Steam path
    if [[ ! -d "$dest_path" ]]; then
        log_error "Destination Steam path does not exist: $dest_path"
        exit 1
    fi
    
    # Get destination Steam user ID
    local userid
    if ! userid=$(get_steam_userid "$dest_path"); then
        exit 1
    fi
    
    log_verbose "Using destination Steam User ID: $userid"
    
    # Define destination paths
    local dest_cache="$dest_path/appcache/librarycache"
    local dest_grid="$dest_path/userdata/$userid/config/grid"
    
    # Count files in backup
    local backup_cache_count backup_grid_count
    if [[ "$CUSTOM_ONLY" == true ]]; then
        backup_cache_count=0  # Skip library cache in custom-only mode
        backup_grid_count=$(count_artwork_files "$backup_dir/grid")
        log_info "Custom-only mode: restoring only user-uploaded artwork"
    else
        backup_cache_count=$(count_artwork_files "$backup_dir/librarycache")
        backup_grid_count=$(count_artwork_files "$backup_dir/grid")
    fi
    
    log_info "Backup contains $backup_cache_count library cache files, $backup_grid_count custom grid files"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would restore $backup_cache_count files to library cache"
        log_info "[DRY RUN] Would restore $backup_grid_count files to grid"
        return 0
    fi
    
    # Check if Steam is running
    check_steam_running
    
    # Create destination directories if they don't exist
    mkdir -p "$dest_cache"
    mkdir -p "$dest_grid"
    
    # Restore library cache (skip in custom-only mode)
    if [[ $backup_cache_count -gt 0 && "$CUSTOM_ONLY" != true ]]; then
        log_info "Restoring library cache artwork..."
        rsync -av --progress "$backup_dir/librarycache/" "$dest_cache/"
    fi
    
    # Restore grid files
    if [[ $backup_grid_count -gt 0 ]]; then
        log_info "Restoring custom grid artwork..."
        rsync -av --progress "$backup_dir/grid/" "$dest_grid/"
    fi
    
    # Fix permissions
    log_info "Fixing file permissions..."
    find "$dest_cache" "$dest_grid" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find "$dest_cache" "$dest_grid" -type d -exec chmod 755 {} \; 2>/dev/null || true
    
    log_success "Restore completed successfully!"
    log_info "Total files restored: $((backup_cache_count + backup_grid_count))"
    log_info "Restart Steam to see the restored artwork"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            backup|restore|info)
                if [[ -n "$OPERATION" ]]; then
                    log_error "Multiple operations specified"
                    exit 1
                fi
                OPERATION="$1"
                shift
                ;;
            -s|--source)
                SOURCE_STEAM_PATH="$2"
                shift 2
                ;;
            -d|--dest)
                DEST_STEAM_PATH="$2"
                shift 2
                ;;
            -o|--output)
                BACKUP_DIR="$2"
                shift 2
                ;;
            -i|--input)
                BACKUP_DIR="$2"
                shift 2
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -c|--custom-only)
                CUSTOM_ONLY=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Validate operation
    if [[ -z "$OPERATION" ]]; then
        log_error "No operation specified"
        echo "Use -h or --help for usage information"
        exit 1
    fi
}

# Validate and set default arguments
validate_args() {
    case "$OPERATION" in
        backup)
            # Set source path
            if [[ -z "$SOURCE_STEAM_PATH" ]]; then
                if SOURCE_STEAM_PATH=$(detect_steam_path); then
                    log_info "Auto-detected source Steam path: $SOURCE_STEAM_PATH"
                else
                    log_error "Could not auto-detect Steam path. Please specify with -s option"
                    exit 1
                fi
            fi
            
            # Set backup directory
            if [[ -z "$BACKUP_DIR" ]]; then
                BACKUP_DIR="$HOME/steam-artwork-backup-$(date +%Y%m%d-%H%M%S)"
                log_info "Using default backup directory: $BACKUP_DIR"
            fi
            ;;
            
        restore)
            # Set destination path
            if [[ -z "$DEST_STEAM_PATH" ]]; then
                if DEST_STEAM_PATH=$(detect_steam_path); then
                    log_info "Auto-detected destination Steam path: $DEST_STEAM_PATH"
                else
                    log_error "Could not auto-detect Steam path. Please specify with -d option"
                    exit 1
                fi
            fi
            
            # Backup directory is required for restore
            if [[ -z "$BACKUP_DIR" ]]; then
                log_error "Backup directory required for restore operation. Use -i option"
                exit 1
            fi
            ;;
            
        info)
            # No additional validation needed for info
            ;;
    esac
}

# Main function
main() {
    echo "Steam Artwork Sync v${VERSION}"
    echo
    
    parse_args "$@"
    validate_args
    
    case "$OPERATION" in
        backup)
            create_backup
            ;;
        restore)
            restore_backup
            ;;
        info)
            show_info
            ;;
    esac
}

# Run main function
main "$@"