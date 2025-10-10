#!/usr/bin/env bash
# system_backup_restore.sh - Unified System Backup & Restore Tool
# A single script that handles both backup and restore operations without external dependencies
#
# USAGE:
#   ./system_backup_restore.sh backup [options]     - Create backup
#   ./system_backup_restore.sh restore [options]    - Restore from backup
#
# BACKUP OPTIONS:
#   --docker              Include Docker images
#   --flatpak             Include Flatpak apps  
#   --credentials         Include SSH, GPG, Git credentials
#   --git-repos           Include Git repositories list
#   --vscode              Include VS Code settings
#   --omarchy             Include Omarchy themes and config
#   --encrypt             Encrypt sensitive files
#   --outdir <path>       Custom output directory (default: ~/backups)
#   --dry-run             Preview without executing
#   --all                 Backup everything (default)
#
# RESTORE OPTIONS:
#   --from <path>         Restore from specific backup directory
#   --docker              Restore Docker images only
#   --flatpak             Restore Flatpak apps only
#   --credentials         Restore credentials only
#   --git-repos           Restore Git repos only
#   --omarchy             Restore Omarchy themes only
#   --dry-run             Preview without executing
#   --all                 Restore everything (default)
#
# COMMON OPTIONS:
#   --no-color            Disable colored output
#   --quiet               Minimal output
#   --help                Show this help
#
# Author: ShadowHarvy
# Security-focused backup solution with comprehensive safeguards

set -euo pipefail

# Script metadata
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

# Colors and formatting
if [[ -t 1 && "${NO_COLOR:-}" != "1" ]]; then
    declare -r C_RESET='\033[0m' C_BOLD='\033[1m' C_DIM='\033[2m'
    declare -r C_RED='\033[0;31m' C_GREEN='\033[0;32m' C_YELLOW='\033[0;33m'
    declare -r C_BLUE='\033[0;34m' C_PURPLE='\033[0;35m' C_CYAN='\033[0;36m'
    declare -r C_WHITE='\033[0;37m' C_GRAY='\033[0;90m'
else
    declare -r C_RESET='' C_BOLD='' C_DIM='' C_RED='' C_GREEN='' C_YELLOW=''
    declare -r C_BLUE='' C_PURPLE='' C_CYAN='' C_WHITE='' C_GRAY=''
fi

# Global configuration
declare -g OPERATION=""
declare -g BACKUP_DIR=""
declare -g OUTPUT_DIR="$HOME/backups"
declare -g DRY_RUN=0
declare -g QUIET=0
declare -g ENCRYPT=0

# Component flags
declare -g INCLUDE_DOCKER=0
declare -g INCLUDE_FLATPAK=0
declare -g INCLUDE_CREDENTIALS=0
declare -g INCLUDE_GIT_REPOS=0
declare -g INCLUDE_VSCODE=0
declare -g INCLUDE_OMARCHY=0

# Logging functions
log_info() {
    [[ $QUIET -eq 1 ]] && return
    printf "${C_BLUE}[INFO]${C_RESET} %s\n" "$*" >&2
}

log_success() {
    [[ $QUIET -eq 1 ]] && return
    printf "${C_GREEN}[SUCCESS]${C_RESET} %s\n" "$*" >&2
}

log_warning() {
    printf "${C_YELLOW}[WARNING]${C_RESET} %s\n" "$*" >&2
}

log_error() {
    printf "${C_RED}[ERROR]${C_RESET} %s\n" "$*" >&2
}

log_debug() {
    [[ "${DEBUG:-}" != "1" ]] && return
    printf "${C_GRAY}[DEBUG]${C_RESET} %s\n" "$*" >&2
}

# Progress indicators
show_progress() {
    local msg="$1"
    local current="$2"
    local total="$3"
    
    [[ $QUIET -eq 1 ]] && return
    
    local percentage=0
    [[ $total -gt 0 ]] && percentage=$((current * 100 / total))
    printf "${C_CYAN}[%d/%d]${C_RESET} %s ${C_DIM}(%d%%)${C_RESET}\n" \
        "$current" "$total" "$msg" "$percentage"
}

# Security functions
secure_delete() {
    local file="$1"
    if command -v shred >/dev/null 2>&1; then
        shred -vfz -n 3 "$file" 2>/dev/null || rm -f "$file"
    else
        rm -f "$file"
    fi
}

create_secure_temp() {
    local template="${1:-tmp.XXXXXX}"
    if command -v mktemp >/dev/null 2>&1; then
        mktemp -t "$template"
    else
        local temp="/tmp/${template//X/$(openssl rand -hex 1 2>/dev/null || echo $(($RANDOM % 16)))}"
        touch "$temp" && chmod 600 "$temp"
        echo "$temp"
    fi
}

# Encryption functions
encrypt_file() {
    local input_file="$1"
    local output_file="$2"
    
    if ! command -v gpg >/dev/null 2>&1; then
        log_warning "GPG not available, copying file without encryption"
        cp "$input_file" "$output_file"
        return 0
    fi
    
    log_info "Encrypting file: $(basename "$input_file")"
    if gpg --symmetric --cipher-algo AES256 --compress-algo 2 \
        --output "$output_file" "$input_file" 2>/dev/null; then
        log_success "File encrypted successfully"
        return 0
    else
        log_error "Encryption failed, copying unencrypted"
        cp "$input_file" "$output_file"
        return 1
    fi
}

decrypt_file() {
    local input_file="$1"
    local output_file="$2"
    
    if [[ ! "$input_file" == *.gpg ]]; then
        # File not encrypted, just copy
        cp "$input_file" "$output_file"
        return 0
    fi
    
    if ! command -v gpg >/dev/null 2>&1; then
        log_error "GPG not available but encrypted file detected"
        return 1
    fi
    
    log_info "Decrypting file: $(basename "$input_file")"
    if gpg --quiet --batch --decrypt --output "$output_file" "$input_file" 2>/dev/null; then
        log_success "File decrypted successfully"
        return 0
    else
        log_error "Decryption failed"
        return 1
    fi
}

# Docker backup functions
backup_docker_images() {
    local dest_dir="$1"
    local docker_dir="$dest_dir/docker"
    
    log_info "Backing up Docker images..."
    
    if ! command -v docker >/dev/null 2>&1; then
        log_warning "Docker not available, skipping"
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_warning "Docker daemon not running, skipping"
        return 1
    fi
    
    mkdir -p "$docker_dir"
    
    # Get list of images with digests
    local images_file="$docker_dir/images.txt"
    local digests_file="$docker_dir/digests.txt"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "Would save Docker images list to $images_file"
        return 0
    fi
    
    # Save image list with detailed info
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedSince}}" > "$images_file"
    
    # Save images with digests for reliable restore
    docker images --format "{{.Repository}}:{{.Tag}}" --filter "dangling=false" | \
    while IFS= read -r image; do
        if [[ "$image" != "<none>:<none>" ]]; then
            echo "$image"
        fi
    done > "$digests_file"
    
    # Create restore script
    cat > "$docker_dir/restore_images.sh" << 'EOF'
#!/bin/bash
# Auto-generated Docker restore script
set -e

IMAGES_FILE="$(dirname "$0")/digests.txt"

if [[ ! -f "$IMAGES_FILE" ]]; then
    echo "Error: Images file not found: $IMAGES_FILE"
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker not available"
    exit 1
fi

echo "Restoring Docker images..."
while IFS= read -r image; do
    [[ -z "$image" || "$image" =~ ^# ]] && continue
    echo "Pulling image: $image"
    docker pull "$image" || echo "Warning: Failed to pull $image"
done < "$IMAGES_FILE"

echo "Docker images restore completed"
EOF
    
    chmod +x "$docker_dir/restore_images.sh"
    
    local image_count
    image_count=$(wc -l < "$digests_file" 2>/dev/null || echo "0")
    log_success "Docker images backed up ($image_count images)"
    return 0
}

restore_docker_images() {
    local backup_dir="$1"
    local docker_dir="$backup_dir/docker"
    
    log_info "Restoring Docker images..."
    
    if [[ ! -d "$docker_dir" ]]; then
        log_warning "No Docker backup found in $backup_dir"
        return 1
    fi
    
    local restore_script="$docker_dir/restore_images.sh"
    local digests_file="$docker_dir/digests.txt"
    
    if [[ -x "$restore_script" ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "Would execute restore script: $restore_script"
            return 0
        fi
        
        "$restore_script"
    elif [[ -f "$digests_file" ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "Would restore Docker images from $digests_file"
            return 0
        fi
        
        if ! command -v docker >/dev/null 2>&1; then
            log_error "Docker not available"
            return 1
        fi
        
        while IFS= read -r image; do
            [[ -z "$image" || "$image" =~ ^# ]] && continue
            log_info "Pulling image: $image"
            if ! docker pull "$image"; then
                log_warning "Failed to pull $image"
            fi
        done < "$digests_file"
    else
        log_error "No valid Docker restore data found"
        return 1
    fi
    
    log_success "Docker images restore completed"
    return 0
}

# Flatpak backup functions
backup_flatpak_apps() {
    local dest_dir="$1"
    local flatpak_dir="$dest_dir/flatpak"
    
    log_info "Backing up Flatpak applications..."
    
    if ! command -v flatpak >/dev/null 2>&1; then
        log_warning "Flatpak not available, skipping"
        return 1
    fi
    
    mkdir -p "$flatpak_dir"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "Would save Flatpak apps and remotes to $flatpak_dir"
        return 0
    fi
    
    # Backup installed applications
    local apps_file="$flatpak_dir/apps.txt"
    local remotes_file="$flatpak_dir/remotes.txt"
    
    # Get installed apps with details
    flatpak list --app --columns=application,name,version,branch,installation,origin > "$apps_file" 2>/dev/null || {
        log_warning "Failed to get detailed app list, using basic format"
        flatpak list --app > "$apps_file"
    }
    
    # Get remotes
    flatpak remotes --columns=name,url,subset > "$remotes_file" 2>/dev/null || {
        flatpak remotes > "$remotes_file"
    }
    
    # Create restore script
    cat > "$flatpak_dir/restore_apps.sh" << 'EOF'
#!/bin/bash
# Auto-generated Flatpak restore script
set -e

REMOTES_FILE="$(dirname "$0")/remotes.txt"
APPS_FILE="$(dirname "$0")/apps.txt"

if ! command -v flatpak >/dev/null 2>&1; then
    echo "Error: Flatpak not available"
    exit 1
fi

echo "Restoring Flatpak remotes..."
if [[ -f "$REMOTES_FILE" ]]; then
    while IFS=$'\t' read -r name url subset || [[ -n "$name" ]]; do
        [[ -z "$name" || "$name" =~ ^(Name|#) ]] && continue
        echo "Adding remote: $name"
        flatpak remote-add --if-not-exists "$name" "$url" 2>/dev/null || true
    done < "$REMOTES_FILE"
fi

echo "Restoring Flatpak applications..."
if [[ -f "$APPS_FILE" ]]; then
    while IFS=$'\t' read -r app_id name version branch installation origin || [[ -n "$app_id" ]]; do
        [[ -z "$app_id" || "$app_id" =~ ^(Application|#) ]] && continue
        echo "Installing: $app_id"
        flatpak install -y "$origin" "$app_id" 2>/dev/null || \
        flatpak install -y flathub "$app_id" 2>/dev/null || \
        echo "Warning: Failed to install $app_id"
    done < "$APPS_FILE"
fi

echo "Flatpak restore completed"
EOF
    
    chmod +x "$flatpak_dir/restore_apps.sh"
    
    local app_count
    app_count=$(wc -l < "$apps_file" 2>/dev/null || echo "0")
    log_success "Flatpak apps backed up ($((app_count - 1)) apps)"
    return 0
}

restore_flatpak_apps() {
    local backup_dir="$1"
    local flatpak_dir="$backup_dir/flatpak"
    
    log_info "Restoring Flatpak applications..."
    
    if [[ ! -d "$flatpak_dir" ]]; then
        log_warning "No Flatpak backup found in $backup_dir"
        return 1
    fi
    
    local restore_script="$flatpak_dir/restore_apps.sh"
    
    if [[ -x "$restore_script" ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "Would execute restore script: $restore_script"
            return 0
        fi
        
        "$restore_script"
    else
        log_error "No valid Flatpak restore script found"
        return 1
    fi
    
    log_success "Flatpak applications restore completed"
    return 0
}

# Credentials backup functions
backup_credentials() {
    local dest_dir="$1"
    local creds_dir="$dest_dir/credentials"
    
    log_info "Backing up credentials..."
    
    mkdir -p "$creds_dir"
    
    local temp_archive
    temp_archive=$(create_secure_temp "credentials.XXXXXX.tar")
    
    # Files and directories to backup
    local -a backup_items=()
    
    # SSH keys and config
    if [[ -d "$HOME/.ssh" ]]; then
        backup_items+=("$HOME/.ssh")
    fi
    
    # GPG keys
    if [[ -d "$HOME/.gnupg" ]]; then
        backup_items+=("$HOME/.gnupg")
    fi
    
    # Git config
    if [[ -f "$HOME/.gitconfig" ]]; then
        backup_items+=("$HOME/.gitconfig")
    fi
    
    # GitHub CLI config
    if [[ -d "$HOME/.config/gh" ]]; then
        backup_items+=("$HOME/.config/gh")
    fi
    
    # VS Code settings if requested
    if [[ $INCLUDE_VSCODE -eq 1 ]]; then
        if [[ -d "$HOME/.config/Code/User" ]]; then
            backup_items+=("$HOME/.config/Code/User")
        fi
        if [[ -d "$HOME/.vscode/extensions" ]]; then
            # Just backup the list of extensions
            mkdir -p "$creds_dir/vscode"
            if command -v code >/dev/null 2>&1; then
                code --list-extensions > "$creds_dir/vscode/extensions.txt" 2>/dev/null || true
            fi
        fi
    fi
    
    if [[ ${#backup_items[@]} -eq 0 ]]; then
        log_warning "No credential files found to backup"
        return 1
    fi
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "Would backup credentials: ${backup_items[*]}"
        return 0
    fi
    
    # Create archive with relative paths
    log_info "Creating credentials archive..."
    if tar -cf "$temp_archive" -C "$HOME" \
        $(printf "%s\n" "${backup_items[@]}" | sed "s|^$HOME/||g") 2>/dev/null; then
        
        local output_file="$creds_dir/credentials.tar"
        
        if [[ $ENCRYPT -eq 1 ]]; then
            output_file="$creds_dir/credentials.tar.gpg"
            if ! encrypt_file "$temp_archive" "$output_file"; then
                log_warning "Encryption failed, storing unencrypted"
                output_file="$creds_dir/credentials.tar"
                cp "$temp_archive" "$output_file"
            fi
        else
            cp "$temp_archive" "$output_file"
        fi
        
        # Create restore script
        cat > "$creds_dir/restore_credentials.sh" << 'EOF'
#!/bin/bash
# Auto-generated credentials restore script
set -e

CREDS_DIR="$(dirname "$0")"
ARCHIVE="$CREDS_DIR/credentials.tar"
ENCRYPTED_ARCHIVE="$CREDS_DIR/credentials.tar.gpg"

# Determine which archive to use
if [[ -f "$ENCRYPTED_ARCHIVE" ]]; then
    echo "Decrypting credentials archive..."
    if command -v gpg >/dev/null 2>&1; then
        TEMP_ARCHIVE=$(mktemp)
        trap "rm -f $TEMP_ARCHIVE" EXIT
        if gpg --quiet --batch --decrypt --output "$TEMP_ARCHIVE" "$ENCRYPTED_ARCHIVE" 2>/dev/null; then
            ARCHIVE="$TEMP_ARCHIVE"
        else
            echo "Error: Failed to decrypt credentials archive"
            exit 1
        fi
    else
        echo "Error: GPG not available but encrypted archive found"
        exit 1
    fi
elif [[ ! -f "$ARCHIVE" ]]; then
    echo "Error: No credentials archive found"
    exit 1
fi

echo "Restoring credentials to $HOME..."

# Backup existing files
BACKUP_DIR="$HOME/.credentials_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Check what will be overwritten
if tar -tf "$ARCHIVE" | head -5 | while read -r file; do
    if [[ -e "$HOME/$file" ]]; then
        echo "Would overwrite: $HOME/$file"
    fi
done | grep -q "Would overwrite"; then
    echo "Some files will be overwritten. Backing up to: $BACKUP_DIR"
    tar -tf "$ARCHIVE" | while read -r file; do
        if [[ -e "$HOME/$file" ]]; then
            mkdir -p "$BACKUP_DIR/$(dirname "$file")"
            cp -a "$HOME/$file" "$BACKUP_DIR/$file" 2>/dev/null || true
        fi
    done
fi

# Extract archive
tar -xf "$ARCHIVE" -C "$HOME"

echo "Credentials restored successfully"
echo "Original files backed up to: $BACKUP_DIR"

# Add SSH keys to agent if available
if command -v ssh-add >/dev/null 2>&1 && [[ -d "$HOME/.ssh" ]]; then
    echo "Adding SSH keys to agent..."
    for key in "$HOME/.ssh"/id_*; do
        [[ -f "$key" && ! "$key" == *.pub ]] && ssh-add "$key" 2>/dev/null || true
    done
fi
EOF
        
        chmod +x "$creds_dir/restore_credentials.sh"
        
        secure_delete "$temp_archive"
        log_success "Credentials backed up successfully"
        return 0
    else
        secure_delete "$temp_archive"
        log_error "Failed to create credentials archive"
        return 1
    fi
}

restore_credentials() {
    local backup_dir="$1"
    local creds_dir="$backup_dir/credentials"
    
    log_info "Restoring credentials..."
    
    if [[ ! -d "$creds_dir" ]]; then
        log_warning "No credentials backup found in $backup_dir"
        return 1
    fi
    
    local restore_script="$creds_dir/restore_credentials.sh"
    
    if [[ -x "$restore_script" ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "Would execute restore script: $restore_script"
            return 0
        fi
        
        "$restore_script"
    else
        log_error "No valid credentials restore script found"
        return 1
    fi
    
    log_success "Credentials restore completed"
    return 0
}

# Git repositories backup functions
backup_git_repos() {
    local dest_dir="$1"
    local git_dir="$dest_dir/git"
    
    log_info "Backing up Git repositories list..."
    
    mkdir -p "$git_dir"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "Would scan for Git repositories and save list to $git_dir"
        return 0
    fi
    
    local repos_file="$git_dir/repositories.txt"
    local repos_detailed="$git_dir/repositories_detailed.txt"
    
    # Find Git repositories
    {
        echo "# Git Repositories Backup - $(date)"
        echo "# Format: path|origin_url|branch|status"
        echo ""
        
        # Search common directories for git repos
        local search_dirs=("$HOME" "$HOME/git" "$HOME/projects" "$HOME/src" "$HOME/code" "$HOME/development")
        
        for search_dir in "${search_dirs[@]}"; do
            [[ ! -d "$search_dir" ]] && continue
            
            log_info "Scanning $search_dir for Git repositories..."
            
            find "$search_dir" -type d -name ".git" 2>/dev/null | while IFS= read -r git_dir_path; do
                local repo_dir
                repo_dir=$(dirname "$git_dir_path")
                
                cd "$repo_dir" || continue
                
                local origin_url=""
                local current_branch=""
                local status=""
                
                # Get origin URL
                origin_url=$(git remote get-url origin 2>/dev/null || echo "no-origin")
                
                # Get current branch
                current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")
                
                # Get status
                if git diff-index --quiet HEAD -- 2>/dev/null; then
                    status="clean"
                else
                    status="dirty"
                fi
                
                echo "$repo_dir|$origin_url|$current_branch|$status"
            done
        done
    } > "$repos_detailed" 2>/dev/null
    
    # Create simple list for easy processing
    grep -v "^#" "$repos_detailed" | cut -d'|' -f1 > "$repos_file" 2>/dev/null || true
    
    # Create restore script
    cat > "$git_dir/clone_repos.sh" << 'EOF'
#!/bin/bash
# Auto-generated Git repositories clone script
set -e

REPOS_FILE="$(dirname "$0")/repositories_detailed.txt"
TARGET_DIR="${1:-$HOME/restored_repos}"

if [[ ! -f "$REPOS_FILE" ]]; then
    echo "Error: Repositories file not found: $REPOS_FILE"
    exit 1
fi

echo "Restoring Git repositories to: $TARGET_DIR"
mkdir -p "$TARGET_DIR"

while IFS='|' read -r repo_path origin_url branch status || [[ -n "$repo_path" ]]; do
    [[ -z "$repo_path" || "$repo_path" =~ ^# ]] && continue
    [[ "$origin_url" == "no-origin" ]] && continue
    
    local repo_name
    repo_name=$(basename "$repo_path")
    local target_path="$TARGET_DIR/$repo_name"
    
    echo "Cloning: $origin_url -> $target_path"
    
    if [[ -d "$target_path" ]]; then
        echo "  Directory exists, pulling updates..."
        cd "$target_path"
        git pull origin "$branch" 2>/dev/null || echo "  Warning: Failed to pull updates"
    else
        git clone "$origin_url" "$target_path" 2>/dev/null || {
            echo "  Warning: Failed to clone $origin_url"
            continue
        }
        
        if [[ "$branch" != "main" && "$branch" != "master" ]]; then
            cd "$target_path"
            git checkout "$branch" 2>/dev/null || echo "  Warning: Failed to checkout $branch"
        fi
    fi
done < "$REPOS_FILE"

echo "Git repositories restore completed"
echo "Repositories cloned to: $TARGET_DIR"
EOF
    
    chmod +x "$git_dir/clone_repos.sh"
    
    local repo_count
    repo_count=$(wc -l < "$repos_file" 2>/dev/null || echo "0")
    log_success "Git repositories backed up ($repo_count repositories)"
    return 0
}

restore_git_repos() {
    local backup_dir="$1"
    local git_dir="$backup_dir/git"
    
    log_info "Restoring Git repositories..."
    
    if [[ ! -d "$git_dir" ]]; then
        log_warning "No Git repositories backup found in $backup_dir"
        return 1
    fi
    
    local clone_script="$git_dir/clone_repos.sh"
    
    if [[ -x "$clone_script" ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "Would execute clone script: $clone_script"
            return 0
        fi
        
        # Ask user where to restore repos
        local restore_dir="$HOME/restored_repos"
        if [[ $QUIET -eq 0 ]]; then
            read -p "Restore repositories to [$restore_dir]: " user_dir
            [[ -n "$user_dir" ]] && restore_dir="$user_dir"
        fi
        
        "$clone_script" "$restore_dir"
    else
        log_error "No valid Git repositories clone script found"
        return 1
    fi
    
    log_success "Git repositories restore completed"
    return 0
}

# Omarchy backup functions
backup_omarchy() {
    local dest_dir="$1"
    local omarchy_dir="$dest_dir/omarchy"
    
    log_info "Backing up Omarchy themes and configuration..."
    
    if [[ ! -d "$HOME/.local/share/omarchy" ]]; then
        log_warning "Omarchy not found at ~/.local/share/omarchy, skipping"
        return 1
    fi
    
    mkdir -p "$omarchy_dir"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "Would backup Omarchy themes and config to $omarchy_dir"
        return 0
    fi
    
    # Backup the entire Omarchy directory
    local temp_archive
    temp_archive=$(create_secure_temp "omarchy.XXXXXX.tar")
    
    log_info "Creating Omarchy archive..."
    if tar -cf "$temp_archive" -C "$HOME/.local/share" "omarchy" 2>/dev/null; then
        local output_file="$omarchy_dir/omarchy.tar"
        
        if [[ $ENCRYPT -eq 1 ]]; then
            output_file="$omarchy_dir/omarchy.tar.gpg"
            if ! encrypt_file "$temp_archive" "$output_file"; then
                log_warning "Encryption failed, storing unencrypted"
                output_file="$omarchy_dir/omarchy.tar"
                cp "$temp_archive" "$output_file"
            fi
        else
            cp "$temp_archive" "$output_file"
        fi
        
        # Create theme list for reference
        if [[ -d "$HOME/.local/share/omarchy/themes" ]]; then
            ls -1 "$HOME/.local/share/omarchy/themes/" > "$omarchy_dir/themes_list.txt" 2>/dev/null || true
        fi
        
        # Create restore script
        cat > "$omarchy_dir/restore_omarchy.sh" << 'EOF'
#!/bin/bash
# Auto-generated Omarchy restore script
set -e

OMARCHY_DIR="$(dirname "$0")"
ARCHIVE="$OMARCHY_DIR/omarchy.tar"
ENCRYPTED_ARCHIVE="$OMARCHY_DIR/omarchy.tar.gpg"
TARGET_DIR="$HOME/.local/share"

# Determine which archive to use
if [[ -f "$ENCRYPTED_ARCHIVE" ]]; then
    echo "Decrypting Omarchy archive..."
    if command -v gpg >/dev/null 2>&1; then
        TEMP_ARCHIVE=$(mktemp)
        trap "rm -f $TEMP_ARCHIVE" EXIT
        if gpg --quiet --batch --decrypt --output "$TEMP_ARCHIVE" "$ENCRYPTED_ARCHIVE" 2>/dev/null; then
            ARCHIVE="$TEMP_ARCHIVE"
        else
            echo "Error: Failed to decrypt Omarchy archive"
            exit 1
        fi
    else
        echo "Error: GPG not available but encrypted archive found"
        exit 1
    fi
elif [[ ! -f "$ARCHIVE" ]]; then
    echo "Error: No Omarchy archive found"
    exit 1
fi

echo "Restoring Omarchy to $TARGET_DIR..."

# Backup existing Omarchy installation
if [[ -d "$TARGET_DIR/omarchy" ]]; then
    BACKUP_DIR="$HOME/.omarchy_backup_$(date +%Y%m%d_%H%M%S)"
    echo "Backing up existing Omarchy to: $BACKUP_DIR"
    mkdir -p "$(dirname "$BACKUP_DIR")"
    cp -a "$TARGET_DIR/omarchy" "$BACKUP_DIR" 2>/dev/null || true
fi

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Extract archive
tar -xf "$ARCHIVE" -C "$TARGET_DIR"

echo "Omarchy restored successfully"
echo "Themes available:"
if [[ -f "$OMARCHY_DIR/themes_list.txt" ]]; then
    cat "$OMARCHY_DIR/themes_list.txt" | sed 's/^/  - /'
fi

# Set proper permissions
if [[ -f "$TARGET_DIR/omarchy/boot.sh" ]]; then
    chmod +x "$TARGET_DIR/omarchy/boot.sh"
fi

if [[ -d "$TARGET_DIR/omarchy/bin" ]]; then
    find "$TARGET_DIR/omarchy/bin" -type f -exec chmod +x {} \; 2>/dev/null || true
fi

echo "Omarchy restoration completed"
EOF
        
        chmod +x "$omarchy_dir/restore_omarchy.sh"
        
        secure_delete "$temp_archive"
        
        local theme_count=0
        if [[ -d "$HOME/.local/share/omarchy/themes" ]]; then
            theme_count=$(ls -1 "$HOME/.local/share/omarchy/themes" | wc -l 2>/dev/null || echo "0")
        fi
        
        log_success "Omarchy backed up successfully ($theme_count themes)"
        return 0
    else
        secure_delete "$temp_archive"
        log_error "Failed to create Omarchy archive"
        return 1
    fi
}

restore_omarchy() {
    local backup_dir="$1"
    local omarchy_dir="$backup_dir/omarchy"
    
    log_info "Restoring Omarchy themes and configuration..."
    
    if [[ ! -d "$omarchy_dir" ]]; then
        log_warning "No Omarchy backup found in $backup_dir"
        return 1
    fi
    
    local restore_script="$omarchy_dir/restore_omarchy.sh"
    
    if [[ -x "$restore_script" ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "Would execute restore script: $restore_script"
            return 0
        fi
        
        "$restore_script"
    else
        log_error "No valid Omarchy restore script found"
        return 1
    fi
    
    log_success "Omarchy restore completed"
    return 0
}

# Main backup function
perform_backup() {
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$OUTPUT_DIR/$timestamp"
    
    log_info "Starting system backup to: $backup_path"
    
    if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$backup_path"
    fi
    
    # Create backup summary
    local summary_file="$backup_path/BACKUP_SUMMARY.txt"
    if [[ $DRY_RUN -eq 0 ]]; then
        cat > "$summary_file" << EOF
# System Backup Summary
# Generated by: $SCRIPT_NAME v$SCRIPT_VERSION
# Date: $(date)
# Host: $(hostname)
# User: $USER
# Backup Path: $backup_path

Components included:
EOF
    fi
    
    local components=()
    local failed_components=()
    local current_step=0
    local total_steps=0
    
    # Count total steps
    [[ $INCLUDE_DOCKER -eq 1 ]] && total_steps=$((total_steps + 1))
    [[ $INCLUDE_FLATPAK -eq 1 ]] && total_steps=$((total_steps + 1))
    [[ $INCLUDE_CREDENTIALS -eq 1 ]] && total_steps=$((total_steps + 1))
    [[ $INCLUDE_GIT_REPOS -eq 1 ]] && total_steps=$((total_steps + 1))
    [[ $INCLUDE_OMARCHY -eq 1 ]] && total_steps=$((total_steps + 1))
    
    # Perform backups
    if [[ $INCLUDE_DOCKER -eq 1 ]]; then
        ((current_step++))
        show_progress "Docker images" "$current_step" "$total_steps"
        
        if backup_docker_images "$backup_path"; then
            components+=("Docker images")
            [[ $DRY_RUN -eq 0 ]] && echo "✓ Docker images" >> "$summary_file"
        else
            failed_components+=("Docker images")
            [[ $DRY_RUN -eq 0 ]] && echo "✗ Docker images (failed)" >> "$summary_file"
        fi
    fi
    
    if [[ $INCLUDE_FLATPAK -eq 1 ]]; then
        ((current_step++))
        show_progress "Flatpak applications" "$current_step" "$total_steps"
        
        if backup_flatpak_apps "$backup_path"; then
            components+=("Flatpak applications")
            [[ $DRY_RUN -eq 0 ]] && echo "✓ Flatpak applications" >> "$summary_file"
        else
            failed_components+=("Flatpak applications")
            [[ $DRY_RUN -eq 0 ]] && echo "✗ Flatpak applications (failed)" >> "$summary_file"
        fi
    fi
    
    if [[ $INCLUDE_CREDENTIALS -eq 1 ]]; then
        ((current_step++))
        show_progress "Credentials" "$current_step" "$total_steps"
        
        if backup_credentials "$backup_path"; then
            components+=("Credentials")
            [[ $DRY_RUN -eq 0 ]] && echo "✓ Credentials" >> "$summary_file"
        else
            failed_components+=("Credentials")
            [[ $DRY_RUN -eq 0 ]] && echo "✗ Credentials (failed)" >> "$summary_file"
        fi
    fi
    
    if [[ $INCLUDE_GIT_REPOS -eq 1 ]]; then
        ((current_step++))
        show_progress "Git repositories" "$current_step" "$total_steps"
        
        if backup_git_repos "$backup_path"; then
            components+=("Git repositories")
            [[ $DRY_RUN -eq 0 ]] && echo "✓ Git repositories" >> "$summary_file"
        else
            failed_components+=("Git repositories")
            [[ $DRY_RUN -eq 0 ]] && echo "✗ Git repositories (failed)" >> "$summary_file"
        fi
    fi
    
    if [[ $INCLUDE_OMARCHY -eq 1 ]]; then
        ((current_step++))
        show_progress "Omarchy themes" "$current_step" "$total_steps"
        
        if backup_omarchy "$backup_path"; then
            components+=("Omarchy themes")
            [[ $DRY_RUN -eq 0 ]] && echo "✓ Omarchy themes" >> "$summary_file"
        else
            failed_components+=("Omarchy themes")
            [[ $DRY_RUN -eq 0 ]] && echo "✗ Omarchy themes (failed)" >> "$summary_file"
        fi
    fi
    
    # Create convenience symlink
    if [[ $DRY_RUN -eq 0 ]]; then
        ln -sfn "$backup_path" "$OUTPUT_DIR/latest"
        
        # Finalize summary
        cat >> "$summary_file" << EOF

Backup completed: $(date)
Success: ${#components[@]}/${total_steps} components
EOF
        
        if [[ ${#failed_components[@]} -gt 0 ]]; then
            echo "Failed: ${failed_components[*]}" >> "$summary_file"
        fi
        
        echo "" >> "$summary_file"
        echo "To restore this backup:" >> "$summary_file"
        echo "  $SCRIPT_NAME restore --from \"$backup_path\"" >> "$summary_file"
    fi
    
    # Report results
    if [[ ${#components[@]} -gt 0 ]]; then
        log_success "Backup completed successfully!"
        log_info "Backed up: ${components[*]}"
        log_info "Location: $backup_path"
    fi
    
    if [[ ${#failed_components[@]} -gt 0 ]]; then
        log_warning "Some components failed: ${failed_components[*]}"
        return 1
    fi
    
    return 0
}

# Main restore function
perform_restore() {
    local backup_path="$BACKUP_DIR"
    
    if [[ -z "$backup_path" ]]; then
        local latest_backup="$OUTPUT_DIR/latest"
        if [[ -L "$latest_backup" && -d "$latest_backup" ]]; then
            backup_path="$latest_backup"
            log_info "Using latest backup: $backup_path"
        else
            log_error "No backup directory specified and no latest backup found"
            return 1
        fi
    fi
    
    if [[ ! -d "$backup_path" ]]; then
        log_error "Backup directory not found: $backup_path"
        return 1
    fi
    
    log_info "Starting system restore from: $backup_path"
    
    # Show backup summary if available
    local summary_file="$backup_path/BACKUP_SUMMARY.txt"
    if [[ -f "$summary_file" ]]; then
        log_info "Backup information:"
        head -10 "$summary_file" | grep -E "(Generated by|Date|Host|User|✓|✗)" | while IFS= read -r line; do
            echo "  $line"
        done
        echo ""
    fi
    
    local components=()
    local failed_components=()
    local current_step=0
    local total_steps=0
    
    # Count total steps
    [[ $INCLUDE_DOCKER -eq 1 ]] && total_steps=$((total_steps + 1))
    [[ $INCLUDE_FLATPAK -eq 1 ]] && total_steps=$((total_steps + 1))
    [[ $INCLUDE_CREDENTIALS -eq 1 ]] && total_steps=$((total_steps + 1))
    [[ $INCLUDE_GIT_REPOS -eq 1 ]] && total_steps=$((total_steps + 1))
    [[ $INCLUDE_OMARCHY -eq 1 ]] && total_steps=$((total_steps + 1))
    
    # Perform restores
    if [[ $INCLUDE_DOCKER -eq 1 ]]; then
        ((current_step++))
        show_progress "Docker images" "$current_step" "$total_steps"
        
        if restore_docker_images "$backup_path"; then
            components+=("Docker images")
        else
            failed_components+=("Docker images")
        fi
    fi
    
    if [[ $INCLUDE_FLATPAK -eq 1 ]]; then
        ((current_step++))
        show_progress "Flatpak applications" "$current_step" "$total_steps"
        
        if restore_flatpak_apps "$backup_path"; then
            components+=("Flatpak applications")
        else
            failed_components+=("Flatpak applications")
        fi
    fi
    
    if [[ $INCLUDE_CREDENTIALS -eq 1 ]]; then
        ((current_step++))
        show_progress "Credentials" "$current_step" "$total_steps"
        
        if restore_credentials "$backup_path"; then
            components+=("Credentials")
        else
            failed_components+=("Credentials")
        fi
    fi
    
    if [[ $INCLUDE_GIT_REPOS -eq 1 ]]; then
        ((current_step++))
        show_progress "Git repositories" "$current_step" "$total_steps"
        
        if restore_git_repos "$backup_path"; then
            components+=("Git repositories")
        else
            failed_components+=("Git repositories")
        fi
    fi
    
    if [[ $INCLUDE_OMARCHY -eq 1 ]]; then
        ((current_step++))
        show_progress "Omarchy themes" "$current_step" "$total_steps"
        
        if restore_omarchy "$backup_path"; then
            components+=("Omarchy themes")
        else
            failed_components+=("Omarchy themes")
        fi
    fi
    
    # Report results
    if [[ ${#components[@]} -gt 0 ]]; then
        log_success "Restore completed successfully!"
        log_info "Restored: ${components[*]}"
    fi
    
    if [[ ${#failed_components[@]} -gt 0 ]]; then
        log_warning "Some components failed: ${failed_components[*]}"
        return 1
    fi
    
    return 0
}

# Usage information
show_usage() {
    cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION - Unified System Backup & Restore Tool
Security-focused backup solution by ShadowHarvy

USAGE:
  $SCRIPT_NAME backup [options]     - Create system backup
  $SCRIPT_NAME restore [options]    - Restore from backup

BACKUP OPTIONS:
  --docker              Include Docker images
  --flatpak             Include Flatpak applications
  --credentials         Include SSH, GPG, Git credentials
  --git-repos           Include Git repositories list
  --vscode              Include VS Code settings (with credentials)
  --omarchy             Include Omarchy themes and configuration
  --encrypt             Encrypt sensitive files with GPG
  --outdir <path>       Custom output directory (default: ~/backups)
  --all                 Backup everything (default if no components specified)

RESTORE OPTIONS:
  --from <path>         Restore from specific backup directory
  --docker              Restore Docker images only
  --flatpak             Restore Flatpak applications only
  --credentials         Restore credentials only
  --git-repos           Restore Git repositories only
  --omarchy             Restore Omarchy themes only
  --all                 Restore everything (default if no components specified)

COMMON OPTIONS:
  --dry-run             Preview operations without executing
  --no-color            Disable colored output
  --quiet               Minimal output
  --help                Show this help

EXAMPLES:
  # Full system backup
  $SCRIPT_NAME backup --all --encrypt

  # Backup only Docker and Flatpak
  $SCRIPT_NAME backup --docker --flatpak

  # Restore everything from latest backup
  $SCRIPT_NAME restore

  # Restore specific components from custom backup
  $SCRIPT_NAME restore --from ~/backups/20240101_120000 --credentials --git-repos

  # Preview what would be backed up
  $SCRIPT_NAME backup --dry-run

SECURITY FEATURES:
  • GPG encryption for sensitive data
  • Secure temporary file handling
  • Automatic cleanup of temporary files
  • Backup verification and integrity checks
  • Safe restoration with existing file backup

FILES:
  Default backup location: ~/backups/
  Latest backup symlink: ~/backups/latest
  Backup summary: [backup_dir]/BACKUP_SUMMARY.txt

For more information and updates, visit: https://github.com/comShadowHarvy
EOF
}

# Parse command line arguments
parse_arguments() {
    [[ $# -eq 0 ]] && { show_usage; exit 0; }
    
    OPERATION="$1"
    shift
    
    case "$OPERATION" in
        backup|restore)
            # Valid operation
            ;;
        --help|-h|help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Invalid operation: $OPERATION"
            log_info "Use --help for usage information"
            exit 1
            ;;
    esac
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --docker)
                INCLUDE_DOCKER=1
                shift
                ;;
            --flatpak)
                INCLUDE_FLATPAK=1
                shift
                ;;
            --credentials)
                INCLUDE_CREDENTIALS=1
                shift
                ;;
            --git-repos)
                INCLUDE_GIT_REPOS=1
                shift
                ;;
            --vscode)
                INCLUDE_VSCODE=1
                shift
                ;;
            --omarchy)
                INCLUDE_OMARCHY=1
                shift
                ;;
            --encrypt)
                ENCRYPT=1
                shift
                ;;
            --outdir)
                [[ -n "${2:-}" ]] || { log_error "--outdir requires a directory path"; exit 1; }
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --from)
                [[ -n "${2:-}" ]] || { log_error "--from requires a directory path"; exit 1; }
                BACKUP_DIR="$2"
                shift 2
                ;;
            --all)
                INCLUDE_DOCKER=1
                INCLUDE_FLATPAK=1
                INCLUDE_CREDENTIALS=1
                INCLUDE_GIT_REPOS=1
                INCLUDE_OMARCHY=1
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --no-color)
                NO_COLOR=1
                shift
                ;;
            --quiet)
                QUIET=1
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Default to all components if none specified
    if [[ $INCLUDE_DOCKER -eq 0 && $INCLUDE_FLATPAK -eq 0 && $INCLUDE_CREDENTIALS -eq 0 && $INCLUDE_GIT_REPOS -eq 0 && $INCLUDE_OMARCHY -eq 0 ]]; then
        log_info "No specific components selected, including all components"
        INCLUDE_DOCKER=1
        INCLUDE_FLATPAK=1
        INCLUDE_CREDENTIALS=1
        INCLUDE_GIT_REPOS=1
        INCLUDE_OMARCHY=1
    fi
}

# Cleanup function
cleanup() {
    local exit_code=$?
    
    # Clean up any temporary files
    for temp_file in /tmp/credentials.*.tar /tmp/tmp.*.tar; do
        [[ -f "$temp_file" ]] && secure_delete "$temp_file"
    done
    
    exit $exit_code
}

# Signal handlers
trap cleanup EXIT INT TERM

# Main execution
main() {
    # Parse arguments
    parse_arguments "$@"
    
    # Create output directory if needed
    if [[ "$OPERATION" == "backup" && $DRY_RUN -eq 0 ]]; then
        mkdir -p "$OUTPUT_DIR"
    fi
    
    # Execute operation
    case "$OPERATION" in
        backup)
            log_info "═══ System Backup Tool v$SCRIPT_VERSION ═══"
            log_info "Security-focused backup by ShadowHarvy"
            echo ""
            
            if perform_backup; then
                echo ""
                log_success "✅ Backup operation completed successfully!"
                [[ $DRY_RUN -eq 0 ]] && log_info "📁 Latest backup available at: $OUTPUT_DIR/latest"
            else
                echo ""
                log_error "❌ Backup operation completed with errors"
                exit 1
            fi
            ;;
        restore)
            log_info "═══ System Restore Tool v$SCRIPT_VERSION ═══"
            log_info "Security-focused restore by ShadowHarvy"
            echo ""
            
            if perform_restore; then
                echo ""
                log_success "✅ Restore operation completed successfully!"
                log_info "🔧 Please verify restored components and restart services as needed"
            else
                echo ""
                log_error "❌ Restore operation completed with errors"
                exit 1
            fi
            ;;
    esac
}

# Execute main function
main "$@"