#!/usr/bin/env bash
# =============================================================================
# Stow Manager - Automated dotfiles management with GNU Stow
# =============================================================================
# Author: Shadow Harvey
# Description: Enhanced stow automation with conflict resolution, rollback, 
#              package dependencies, and interactive management
# =============================================================================

set -euo pipefail

# Script metadata
SCRIPT_NAME="stow-manager"
SCRIPT_VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
CONFIG_FILE="${SCRIPT_DIR}/stow-config.yaml"
STOW_DIR="${SCRIPT_DIR}"
TARGET_DIR="${HOME}"
LOG_DIR="${SCRIPT_DIR}/logs"
BACKUP_DIR="${HOME}/.stow-backups"

# Colors for output
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    PURPLE=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    WHITE=$(tput setaf 7)
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
else
    RED="" GREEN="" YELLOW="" BLUE="" PURPLE="" CYAN="" WHITE="" BOLD="" RESET=""
fi

# Global variables
VERBOSE=false
DRY_RUN=false
FORCE=false
INTERACTIVE=true
LOG_FILE=""
TRANSACTION_ID=""

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Console output with colors
    case "$level" in
        DEBUG)   [[ "$VERBOSE" == "true" ]] && echo -e "${BLUE}[DEBUG]${RESET} $message" >&2 ;;
        INFO)    echo -e "${CYAN}[INFO]${RESET} $message" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${RESET} $message" ;;
        WARNING) echo -e "${YELLOW}[WARNING]${RESET} $message" >&2 ;;
        ERROR)   echo -e "${RED}[ERROR]${RESET} $message" >&2 ;;
        STEP)    echo -e "${PURPLE}[STEP]${RESET} $message" ;;
    esac
    
    # File logging (if log file is set)
    if [[ -n "$LOG_FILE" ]]; then
        printf '{"timestamp":"%s","level":"%s","message":"%s","transaction":"%s"}\n' \
               "$timestamp" "$level" "$message" "$TRANSACTION_ID" >> "$LOG_FILE"
    fi
}

# Utility functions
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {
    if ! command_exists "$1"; then
        log ERROR "Required command '$1' not found"
        log ERROR "Please install it and try again"
        exit 1
    fi
}

# Initialize directories
init_directories() {
    mkdir -p "$LOG_DIR" "$BACKUP_DIR"
    
    # Set up log file for this session
    TRANSACTION_ID=$(date +%Y%m%d_%H%M%S)_$$
    LOG_FILE="${LOG_DIR}/stow-${TRANSACTION_ID}.log"
    
    log DEBUG "Initialized directories and logging"
    log DEBUG "Log file: $LOG_FILE"
}

# YAML configuration parser using yq or python fallback
parse_config() {
    local key="$1"
    local default="${2:-}"
    
    if command_exists yq; then
        yq eval "$key" "$CONFIG_FILE" 2>/dev/null || echo "$default"
    elif command_exists python3; then
        python3 -c "
import yaml, sys, json
try:
    with open('$CONFIG_FILE') as f:
        data = yaml.safe_load(f)
    
    keys = '$key'.strip('.').split('.')
    result = data
    for k in keys:
        if isinstance(result, dict) and k in result:
            result = result[k]
        else:
            result = None
            break
    
    if result is not None:
        print(json.dumps(result) if isinstance(result, (dict, list)) else str(result))
    else:
        print('$default')
except Exception:
    print('$default')
" 2>/dev/null
    else
        log WARNING "Neither yq nor python3 available for config parsing"
        echo "$default"
    fi
}

# Get list of available packages
get_available_packages() {
    local packages=()
    
    if [[ -f "$CONFIG_FILE" ]]; then
        # Get from config
        local package_list=$(parse_config ".packages | keys" "[]")
        if [[ "$package_list" != "[]" ]]; then
            packages=($(echo "$package_list" | tr -d '[],' | tr -s ' '))
        fi
    fi
    
    # Fallback: scan directories
    if [[ ${#packages[@]} -eq 0 ]]; then
        while IFS= read -r -d '' dir; do
            local pkg_name=$(basename "$dir")
            [[ "$pkg_name" != "." && "$pkg_name" != ".git" && "$pkg_name" != "logs" ]] && packages+=("$pkg_name")
        done < <(find "$STOW_DIR" -maxdepth 1 -type d -print0 2>/dev/null)
    fi
    
    printf '%s\n' "${packages[@]}" | sort
}

# Get package metadata
get_package_meta() {
    local package="$1"
    local field="$2"
    local default="${3:-}"
    
    parse_config ".packages.$package.$field" "$default"
}

# Get package group members
get_group_packages() {
    local group="$1"
    parse_config ".groups.$group" "[]" | tr -d '[],' | tr -s ' '
}

# Check if package exists
package_exists() {
    local package="$1"
    [[ -d "${STOW_DIR}/${package}" ]]
}

# Check package dependencies
check_dependencies() {
    local package="$1"
    local deps_json=$(get_package_meta "$package" "dependencies" "[]")
    
    if [[ "$deps_json" != "[]" ]]; then
        local deps=($(echo "$deps_json" | tr -d '[],' | tr -s ' '))
        for dep in "${deps[@]}"; do
            if ! package_exists "$dep"; then
                log ERROR "Package '$package' requires '$dep' but it doesn't exist"
                return 1
            fi
            
            if ! is_stowed "$dep"; then
                log WARNING "Package '$package' requires '$dep' but it's not stowed"
                log INFO "Consider stowing '$dep' first"
            fi
        done
    fi
    
    return 0
}

# Check if package is enabled
is_enabled() {
    local package="$1"
    local enabled=$(get_package_meta "$package" "enabled" "true")
    [[ "$enabled" == "true" ]]
}

# Check if package is already stowed
is_stowed() {
    local package="$1"
    
    if ! package_exists "$package"; then
        return 1
    fi
    
    # Check for stow-managed symlinks
    local stow_path="${STOW_DIR}/${package}"
    find "$stow_path" -type f -print0 2>/dev/null | while IFS= read -r -d '' file; do
        local relative_path="${file#$stow_path/}"
        local target_file="${TARGET_DIR}/${relative_path}"
        
        if [[ -L "$target_file" ]]; then
            local link_target=$(readlink "$target_file")
            if [[ "$link_target" == *"$package/$relative_path" ]]; then
                exit 0  # Found at least one valid stow symlink
            fi
        fi
    done
    
    return $?
}

# Detect conflicts before stowing
detect_conflicts() {
    local package="$1"
    local conflicts=()
    
    if ! package_exists "$package"; then
        log ERROR "Package '$package' doesn't exist"
        return 1
    fi
    
    # Use stow's dry-run to detect conflicts
    if ! stow -t "$TARGET_DIR" -d "$STOW_DIR" -n "$package" 2>/dev/null; then
        # Get detailed conflict information
        while IFS= read -r line; do
            if [[ "$line" == *"already exists"* ]]; then
                local file=$(echo "$line" | sed -n 's/.*: \(.*\) already exists.*/\1/p')
                [[ -n "$file" ]] && conflicts+=("$file")
            fi
        done < <(stow -t "$TARGET_DIR" -d "$STOW_DIR" -n "$package" 2>&1 || true)
    fi
    
    if [[ ${#conflicts[@]} -gt 0 ]]; then
        log WARNING "Conflicts detected for package '$package':"
        for conflict in "${conflicts[@]}"; do
            log WARNING "  - $conflict"
        done
        return 1
    fi
    
    return 0
}

# Create backup of conflicting files
backup_conflicts() {
    local package="$1"
    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local package_backup_dir="${BACKUP_DIR}/${backup_timestamp}/${package}"
    
    mkdir -p "$package_backup_dir"
    
    # Get conflict list from stow dry-run
    local conflicts=()
    while IFS= read -r line; do
        if [[ "$line" == *"already exists"* ]]; then
            local file=$(echo "$line" | sed -n 's/.*: \(.*\) already exists.*/\1/p')
            [[ -n "$file" ]] && conflicts+=("$file")
        fi
    done < <(stow -t "$TARGET_DIR" -d "$STOW_DIR" -n "$package" 2>&1 || true)
    
    local backed_up=false
    for conflict in "${conflicts[@]}"; do
        if [[ -e "$conflict" && ! -L "$conflict" ]]; then
            log INFO "Backing up: $conflict"
            mkdir -p "$(dirname "${package_backup_dir}/${conflict#$TARGET_DIR/}")"
            cp -r "$conflict" "${package_backup_dir}/${conflict#$TARGET_DIR/}"
            backed_up=true
        fi
    done
    
    if [[ "$backed_up" == "true" ]]; then
        log SUCCESS "Backup created: $package_backup_dir"
        echo "$package_backup_dir"  # Return backup path
    fi
}

# Resolve conflicts based on policy
resolve_conflicts() {
    local package="$1"
    local policy=$(get_package_meta "$package" "backup_policy" "$(parse_config '.global.conflict_policy' 'ask')")
    
    if ! detect_conflicts "$package"; then
        case "$policy" in
            skip)
                log WARNING "Skipping '$package' due to conflicts (policy: skip)"
                return 1
                ;;
            force)
                log WARNING "Forcing installation of '$package' (policy: force)"
                # Remove conflicting files
                while IFS= read -r line; do
                    if [[ "$line" == *"already exists"* ]]; then
                        local file=$(echo "$line" | sed -n 's/.*: \(.*\) already exists.*/\1/p')
                        if [[ -n "$file" && -e "$file" && ! -L "$file" ]]; then
                            log WARNING "Removing conflicting file: $file"
                            [[ "$DRY_RUN" == "false" ]] && rm -rf "$file"
                        fi
                    fi
                done < <(stow -t "$TARGET_DIR" -d "$STOW_DIR" -n "$package" 2>&1 || true)
                ;;
            backup)
                log INFO "Backing up conflicting files for '$package'"
                if [[ "$DRY_RUN" == "false" ]]; then
                    local backup_path=$(backup_conflicts "$package")
                    [[ -n "$backup_path" ]] && log INFO "Backup created at: $backup_path"
                fi
                
                # Remove original files after backup
                while IFS= read -r line; do
                    if [[ "$line" == *"already exists"* ]]; then
                        local file=$(echo "$line" | sed -n 's/.*: \(.*\) already exists.*/\1/p')
                        if [[ -n "$file" && -e "$file" && ! -L "$file" ]]; then
                            [[ "$DRY_RUN" == "false" ]] && rm -rf "$file"
                        fi
                    fi
                done < <(stow -t "$TARGET_DIR" -d "$STOW_DIR" -n "$package" 2>&1 || true)
                ;;
            ask)
                if [[ "$INTERACTIVE" == "true" && "$DRY_RUN" == "false" ]]; then
                    echo
                    log WARNING "Conflicts found for '$package'. What would you like to do?"
                    echo "  1) Skip this package"
                    echo "  2) Backup conflicting files and continue"
                    echo "  3) Force overwrite (dangerous)"
                    echo "  4) Quit"
                    read -p "Choice [1-4]: " -n 1 -r choice
                    echo
                    
                    case "$choice" in
                        1) log INFO "Skipping '$package'"; return 1 ;;
                        2) resolve_conflicts "$package" "backup"; return $? ;;
                        3) resolve_conflicts "$package" "force"; return $? ;;
                        4) log INFO "Aborted by user"; exit 1 ;;
                        *) log ERROR "Invalid choice"; return 1 ;;
                    esac
                else
                    log ERROR "Conflicts found and running non-interactively. Use --force or configure backup_policy."
                    return 1
                fi
                ;;
            *)
                log ERROR "Unknown conflict policy: $policy"
                return 1
                ;;
        esac
    fi
    
    return 0
}

# Execute package hooks
run_hooks() {
    local package="$1"
    local hook_type="$2"  # pre_stow, post_stow, pre_unstow, post_unstow
    
    local hook_cmd=$(get_package_meta "$package" "hooks.$hook_type" "")
    
    if [[ -n "$hook_cmd" ]]; then
        log INFO "Running $hook_type hook for '$package': $hook_cmd"
        if [[ "$DRY_RUN" == "false" ]]; then
            if ! eval "$hook_cmd"; then
                log WARNING "Hook '$hook_type' failed for package '$package'"
                return 1
            fi
        else
            log INFO "DRY RUN: Would run: $hook_cmd"
        fi
    fi
    
    return 0
}

# Stow a single package
stow_package() {
    local package="$1"
    
    if ! package_exists "$package"; then
        log ERROR "Package '$package' doesn't exist"
        return 1
    fi
    
    if ! is_enabled "$package"; then
        log WARNING "Package '$package' is disabled, skipping"
        return 1
    fi
    
    if is_stowed "$package"; then
        log INFO "Package '$package' is already stowed"
        return 0
    fi
    
    log STEP "Stowing package: $package"
    
    # Check dependencies
    if ! check_dependencies "$package"; then
        return 1
    fi
    
    # Run pre-stow hooks
    run_hooks "$package" "pre_stow"
    
    # Handle conflicts
    if ! resolve_conflicts "$package"; then
        log ERROR "Failed to resolve conflicts for '$package'"
        return 1
    fi
    
    # Perform the stow operation
    log INFO "Stowing '$package'..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "DRY RUN: Would stow '$package'"
        stow -t "$TARGET_DIR" -d "$STOW_DIR" -n "$package"
    else
        if stow -t "$TARGET_DIR" -d "$STOW_DIR" "$package"; then
            log SUCCESS "Successfully stowed '$package'"
            
            # Run post-stow hooks
            run_hooks "$package" "post_stow"
        else
            log ERROR "Failed to stow '$package'"
            return 1
        fi
    fi
    
    return 0
}

# Unstow a single package
unstow_package() {
    local package="$1"
    
    if ! package_exists "$package"; then
        log ERROR "Package '$package' doesn't exist"
        return 1
    fi
    
    if ! is_stowed "$package"; then
        log INFO "Package '$package' is not stowed"
        return 0
    fi
    
    log STEP "Unstowing package: $package"
    
    # Run pre-unstow hooks
    run_hooks "$package" "pre_unstow"
    
    # Perform the unstow operation
    log INFO "Unstowing '$package'..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "DRY RUN: Would unstow '$package'"
        stow -t "$TARGET_DIR" -d "$STOW_DIR" -n -D "$package"
    else
        if stow -t "$TARGET_DIR" -d "$STOW_DIR" -D "$package"; then
            log SUCCESS "Successfully unstowed '$package'"
            
            # Run post-unstow hooks
            run_hooks "$package" "post_unstow"
        else
            log ERROR "Failed to unstow '$package'"
            return 1
        fi
    fi
    
    return 0
}

# Restow a single package
restow_package() {
    local package="$1"
    
    log STEP "Restowing package: $package"
    unstow_package "$package" && stow_package "$package"
}

# Interactive package selection with fzf
select_packages_interactive() {
    local mode="$1"  # stow, unstow, or restow
    local preselected=("${@:2}")
    
    if ! command_exists fzf; then
        log WARNING "fzf not available, falling back to manual selection"
        return 1
    fi
    
    local available_packages=($(get_available_packages))
    local package_info=""
    
    # Build package information for fzf preview
    for pkg in "${available_packages[@]}"; do
        local desc=$(get_package_meta "$pkg" "description" "No description")
        local category=$(get_package_meta "$pkg" "category" "unknown")
        local priority=$(get_package_meta "$pkg" "priority" "5")
        local stowed_status
        
        if is_stowed "$pkg"; then
            stowed_status="${GREEN}[STOWED]${RESET}"
        else
            stowed_status="${RED}[NOT STOWED]${RESET}"
        fi
        
        local enabled_status
        if is_enabled "$pkg"; then
            enabled_status="${GREEN}✓${RESET}"
        else
            enabled_status="${RED}✗${RESET}"
        fi
        
        package_info+="\n$pkg\t$stowed_status $enabled_status [$category:$priority] $desc"
    done
    
    local prompt
    case "$mode" in
        stow)   prompt="Select packages to STOW" ;;
        unstow) prompt="Select packages to UNSTOW" ;;
        restow) prompt="Select packages to RESTOW" ;;
        *) prompt="Select packages" ;;
    esac
    
    # Use fzf to select packages
    local selected=($(echo -e "$package_info" | column -t -s $'\t' | \
                     fzf --multi \
                         --header="$prompt (Tab for multi-select, Enter to confirm)" \
                         --preview='echo "Package: {1}\nFiles:" && find "'"$STOW_DIR"'"/{1} -type f 2>/dev/null | head -10' \
                         --preview-window=right:40% \
                         --bind='ctrl-a:select-all,ctrl-d:deselect-all' | \
                     awk '{print $1}'))
    
    printf '%s\n' "${selected[@]}"
}

# Status display
show_status() {
    local format="${1:-table}"  # table, json, simple
    
    log STEP "Package Status Report"
    echo
    
    local available_packages=($(get_available_packages))
    
    case "$format" in
        json)
            echo "{"
            echo '  "packages": ['
            local first=true
            for pkg in "${available_packages[@]}"; do
                [[ "$first" == "false" ]] && echo ","
                first=false
                
                local desc=$(get_package_meta "$pkg" "description" "")
                local category=$(get_package_meta "$pkg" "category" "unknown")
                local priority=$(get_package_meta "$pkg" "priority" "5")
                local enabled=$(is_enabled "$pkg" && echo "true" || echo "false")
                local stowed=$(is_stowed "$pkg" && echo "true" || echo "false")
                
                printf '    {"name":"%s","description":"%s","category":"%s","priority":%s,"enabled":%s,"stowed":%s}' \
                       "$pkg" "$desc" "$category" "$priority" "$enabled" "$stowed"
            done
            echo
            echo "  ],"
            echo '  "summary": {'
            echo '    "total": '${#available_packages[@]}','
            echo '    "stowed": '$(printf '%s\n' "${available_packages[@]}" | xargs -I {} sh -c 'cd "'"$SCRIPT_DIR"'" && "'"$0"'" is-stowed {} && echo {}' | wc -l)','
            echo '    "enabled": '$(printf '%s\n' "${available_packages[@]}" | xargs -I {} sh -c 'cd "'"$SCRIPT_DIR"'" && "'"$0"'" is-enabled {} && echo {}' | wc -l)
            echo "  }"
            echo "}"
            ;;
        simple)
            for pkg in "${available_packages[@]}"; do
                local status
                if is_stowed "$pkg"; then
                    status="${GREEN}STOWED${RESET}"
                else
                    status="${RED}NOT STOWED${RESET}"
                fi
                
                if ! is_enabled "$pkg"; then
                    status="$status ${YELLOW}(DISABLED)${RESET}"
                fi
                
                printf "%-15s %s\n" "$pkg" "$status"
            done
            ;;
        table|*)
            echo "📦 PACKAGE STATUS"
            echo "================"
            printf "%-15s %-10s %-8s %-12s %s\n" "PACKAGE" "STATUS" "ENABLED" "CATEGORY" "DESCRIPTION"
            printf "%-15s %-10s %-8s %-12s %s\n" "-------" "------" "-------" "--------" "-----------"
            
            for pkg in "${available_packages[@]}"; do
                local desc=$(get_package_meta "$pkg" "description" "")
                local category=$(get_package_meta "$pkg" "category" "unknown")
                
                local status
                if is_stowed "$pkg"; then
                    status="${GREEN}STOWED${RESET}"
                else
                    status="${RED}NOT STOWED${RESET}"
                fi
                
                local enabled
                if is_enabled "$pkg"; then
                    enabled="${GREEN}YES${RESET}"
                else
                    enabled="${RED}NO${RESET}"
                fi
                
                printf "%-15s %-18s %-15s %-12s %s\n" "$pkg" "$status" "$enabled" "$category" "$desc"
            done
            
            echo
            echo "📊 SUMMARY"
            echo "=========="
            echo "Total packages:   ${#available_packages[@]}"
            echo "Stowed packages:  $(printf '%s\n' "${available_packages[@]}" | xargs -I {} sh -c 'cd "'"$SCRIPT_DIR"'" && "'"$0"'" is-stowed {} && echo {}' | wc -l)"
            echo "Enabled packages: $(printf '%s\n' "${available_packages[@]}" | xargs -I {} sh -c 'cd "'"$SCRIPT_DIR"'" && "'"$0"'" is-enabled {} && echo {}' | wc -l)"
            ;;
    esac
}

# Show help
show_help() {
    cat << EOF
${BOLD}${PURPLE}🏠 Stow Manager v${SCRIPT_VERSION}${RESET}
${BLUE}Automated dotfiles management with GNU Stow${RESET}

${BOLD}USAGE:${RESET}
    $SCRIPT_NAME <command> [options] [packages...]

${BOLD}COMMANDS:${RESET}
    ${CYAN}stow${RESET}     [packages...]     Stow specified packages (or interactive select)
    ${CYAN}unstow${RESET}   [packages...]     Unstow specified packages
    ${CYAN}restow${RESET}   [packages...]     Restow (unstow + stow) specified packages
    ${CYAN}status${RESET}   [format]          Show status of all packages [table|json|simple]
    ${CYAN}list${RESET}                       List all available packages
    ${CYAN}groups${RESET}                     List package groups
    ${CYAN}group${RESET}    <group>           Stow all packages in a group
    ${CYAN}scan${RESET}                       Scan for changes and suggest updates
    ${CYAN}check${RESET}    [packages...]     Check for conflicts without stowing
    ${CYAN}rollback${RESET} [transaction]     Rollback to previous state
    ${CYAN}clean${RESET}                      Clean up broken symlinks and old backups
    ${CYAN}validate${RESET}                   Validate configuration file
    ${CYAN}help${RESET}                       Show this help message

${BOLD}PACKAGE QUERIES:${RESET}
    ${CYAN}is-stowed${RESET}   <package>      Check if package is stowed (exit code)
    ${CYAN}is-enabled${RESET}  <package>      Check if package is enabled (exit code)
    ${CYAN}info${RESET}        <package>      Show package information

${BOLD}OPTIONS:${RESET}
    -v, --verbose              Enable verbose output
    -n, --dry-run             Show what would be done without executing
    -f, --force               Skip confirmations and force operations
    -q, --quiet               Suppress non-essential output
    -i, --interactive         Use interactive mode (default: true)
    -c, --config <file>       Use alternative config file
    -h, --help                Show this help

${BOLD}EXAMPLES:${RESET}
    ${YELLOW}# Interactive stowing${RESET}
    $SCRIPT_NAME stow

    ${YELLOW}# Stow specific packages${RESET}
    $SCRIPT_NAME stow bash zsh git

    ${YELLOW}# Stow a package group${RESET}
    $SCRIPT_NAME group essential

    ${YELLOW}# Check status with JSON output${RESET}
    $SCRIPT_NAME status json

    ${YELLOW}# Dry run to see what would happen${RESET}
    $SCRIPT_NAME --dry-run stow nvim

    ${YELLOW}# Check for conflicts${RESET}
    $SCRIPT_NAME check bash zsh

${BOLD}PACKAGE GROUPS:${RESET}
$(parse_config '.groups | keys' | tr -d '[],' | tr ' ' '\n' | sed 's/^/    • /')

${BOLD}CONFIG FILE:${RESET}
    $CONFIG_FILE

${BOLD}LOG DIRECTORY:${RESET}
    $LOG_DIR

EOF
}

# Main command dispatcher
main() {
    # Initialize
    init_directories
    require_command stow
    
    # Parse global options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                INTERACTIVE=false
                shift
                ;;
            -q|--quiet)
                # Redirect INFO and DEBUG to /dev/null in quiet mode
                exec 3>&1 1>/dev/null
                shift
                ;;
            --no-interactive)
                INTERACTIVE=false
                shift
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                log ERROR "Unknown option: $1"
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Require at least one command
    if [[ $# -eq 0 ]]; then
        show_help
        exit 1
    fi
    
    local command="$1"
    shift
    
    # Execute command
    case "$command" in
        stow)
            if [[ $# -eq 0 ]] && [[ "$INTERACTIVE" == "true" ]]; then
                # Interactive mode
                local selected_packages=($(select_packages_interactive "stow"))
                if [[ ${#selected_packages[@]} -eq 0 ]]; then
                    log INFO "No packages selected"
                    exit 0
                fi
                set -- "${selected_packages[@]}"
            fi
            
            [[ $# -eq 0 ]] && { log ERROR "No packages specified"; exit 1; }
            
            local failed=0
            for package in "$@"; do
                stow_package "$package" || ((failed++))
            done
            
            if [[ $failed -gt 0 ]]; then
                log ERROR "$failed package(s) failed to stow"
                exit 1
            fi
            ;;
        
        unstow)
            if [[ $# -eq 0 ]] && [[ "$INTERACTIVE" == "true" ]]; then
                local selected_packages=($(select_packages_interactive "unstow"))
                if [[ ${#selected_packages[@]} -eq 0 ]]; then
                    log INFO "No packages selected"
                    exit 0
                fi
                set -- "${selected_packages[@]}"
            fi
            
            [[ $# -eq 0 ]] && { log ERROR "No packages specified"; exit 1; }
            
            local failed=0
            for package in "$@"; do
                unstow_package "$package" || ((failed++))
            done
            
            if [[ $failed -gt 0 ]]; then
                log ERROR "$failed package(s) failed to unstow"
                exit 1
            fi
            ;;
        
        restow)
            if [[ $# -eq 0 ]] && [[ "$INTERACTIVE" == "true" ]]; then
                local selected_packages=($(select_packages_interactive "restow"))
                if [[ ${#selected_packages[@]} -eq 0 ]]; then
                    log INFO "No packages selected"
                    exit 0
                fi
                set -- "${selected_packages[@]}"
            fi
            
            [[ $# -eq 0 ]] && { log ERROR "No packages specified"; exit 1; }
            
            local failed=0
            for package in "$@"; do
                restow_package "$package" || ((failed++))
            done
            
            if [[ $failed -gt 0 ]]; then
                log ERROR "$failed package(s) failed to restow"
                exit 1
            fi
            ;;
        
        status)
            local format="${1:-table}"
            show_status "$format"
            ;;
        
        list)
            log INFO "Available packages:"
            get_available_packages | sed 's/^/  • /'
            ;;
        
        groups)
            log INFO "Available groups:"
            parse_config '.groups | keys' | tr -d '[],' | tr ' ' '\n' | sed 's/^/  • /'
            ;;
        
        group)
            [[ $# -eq 0 ]] && { log ERROR "No group specified"; exit 1; }
            local group="$1"
            local packages=($(get_group_packages "$group"))
            
            if [[ ${#packages[@]} -eq 0 ]]; then
                log ERROR "Group '$group' not found or empty"
                exit 1
            fi
            
            log INFO "Stowing group '$group': ${packages[*]}"
            
            local failed=0
            for package in "${packages[@]}"; do
                stow_package "$package" || ((failed++))
            done
            
            if [[ $failed -gt 0 ]]; then
                log ERROR "$failed package(s) from group '$group' failed to stow"
                exit 1
            fi
            ;;
        
        is-stowed)
            [[ $# -eq 0 ]] && { log ERROR "No package specified"; exit 1; }
            is_stowed "$1"
            ;;
        
        is-enabled)
            [[ $# -eq 0 ]] && { log ERROR "No package specified"; exit 1; }
            is_enabled "$1"
            ;;
        
        info)
            [[ $# -eq 0 ]] && { log ERROR "No package specified"; exit 1; }
            local package="$1"
            
            if ! package_exists "$package"; then
                log ERROR "Package '$package' doesn't exist"
                exit 1
            fi
            
            echo "${BOLD}📦 Package: $package${RESET}"
            echo "Description: $(get_package_meta "$package" "description" "No description")"
            echo "Category:    $(get_package_meta "$package" "category" "unknown")"
            echo "Priority:    $(get_package_meta "$package" "priority" "5")"
            echo "Enabled:     $(is_enabled "$package" && echo "Yes" || echo "No")"
            echo "Stowed:      $(is_stowed "$package" && echo "Yes" || echo "No")"
            
            local deps=$(get_package_meta "$package" "dependencies" "[]")
            if [[ "$deps" != "[]" ]]; then
                echo "Dependencies: $(echo "$deps" | tr -d '[],' | tr ' ' ', ')"
            fi
            
            local conflicts=$(get_package_meta "$package" "conflicts" "[]")
            if [[ "$conflicts" != "[]" ]]; then
                echo "Conflicts:   $(echo "$conflicts" | tr -d '[],' | tr ' ' ', ')"
            fi
            
            echo "Backup Policy: $(get_package_meta "$package" "backup_policy" "ask")"
            
            if [[ -d "${STOW_DIR}/${package}" ]]; then
                echo "Files:"
                find "${STOW_DIR}/${package}" -type f | sed 's/^/  • /' | head -10
                local file_count=$(find "${STOW_DIR}/${package}" -type f | wc -l)
                if [[ $file_count -gt 10 ]]; then
                    echo "  ... and $((file_count - 10)) more files"
                fi
            fi
            ;;
        
        check)
            [[ $# -eq 0 ]] && { log ERROR "No packages specified"; exit 1; }
            
            local conflicts_found=false
            for package in "$@"; do
                if ! detect_conflicts "$package"; then
                    conflicts_found=true
                fi
            done
            
            if [[ "$conflicts_found" == "true" ]]; then
                log ERROR "Conflicts detected. Run with --force or resolve manually."
                exit 1
            else
                log SUCCESS "No conflicts detected"
            fi
            ;;
        
        validate)
            if [[ ! -f "$CONFIG_FILE" ]]; then
                log ERROR "Config file not found: $CONFIG_FILE"
                exit 1
            fi
            
            log INFO "Validating configuration..."
            
            # Basic YAML syntax check
            if command_exists yq; then
                if ! yq eval '.' "$CONFIG_FILE" >/dev/null 2>&1; then
                    log ERROR "Invalid YAML syntax in config file"
                    exit 1
                fi
            elif command_exists python3; then
                if ! python3 -c "import yaml; yaml.safe_load(open('$CONFIG_FILE'))" 2>/dev/null; then
                    log ERROR "Invalid YAML syntax in config file"
                    exit 1
                fi
            else
                log WARNING "Cannot validate YAML syntax (no yq or python3)"
            fi
            
            # Check that defined packages exist
            local config_packages=($(parse_config '.packages | keys' | tr -d '[],' | tr ' ' '\n'))
            for pkg in "${config_packages[@]}"; do
                if ! package_exists "$pkg"; then
                    log WARNING "Package '$pkg' defined in config but directory doesn't exist"
                fi
            done
            
            # Check that existing packages are in config
            local available_packages=($(get_available_packages))
            for pkg in "${available_packages[@]}"; do
                if ! printf '%s\n' "${config_packages[@]}" | grep -q "^$pkg$"; then
                    log WARNING "Package '$pkg' exists but not defined in config"
                fi
            done
            
            log SUCCESS "Configuration validation complete"
            ;;
        
        clean)
            log STEP "Cleaning up..."
            
            # Find and remove broken symlinks in target directory
            local broken_links=$(find "$TARGET_DIR" -maxdepth 2 -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l)
            if [[ $broken_links -gt 0 ]]; then
                log INFO "Found $broken_links broken symlinks"
                if [[ "$DRY_RUN" == "false" ]]; then
                    find "$TARGET_DIR" -maxdepth 2 -type l ! -exec test -e {} \; -delete 2>/dev/null
                    log SUCCESS "Removed broken symlinks"
                else
                    log INFO "DRY RUN: Would remove $broken_links broken symlinks"
                fi
            else
                log INFO "No broken symlinks found"
            fi
            
            # Clean up old backups (keep only max_backups)
            local max_backups=$(parse_config '.global.max_backups' '10')
            local backup_dirs=($(find "$BACKUP_DIR" -maxdepth 1 -type d -name '[0-9]*' | sort -r))
            
            if [[ ${#backup_dirs[@]} -gt $max_backups ]]; then
                local to_remove=("${backup_dirs[@]:$max_backups}")
                log INFO "Found ${#backup_dirs[@]} backup directories, keeping newest $max_backups"
                
                for backup_dir in "${to_remove[@]}"; do
                    log INFO "Removing old backup: $(basename "$backup_dir")"
                    [[ "$DRY_RUN" == "false" ]] && rm -rf "$backup_dir"
                done
            else
                log INFO "Backup directory is within limits (${#backup_dirs[@]}/$max_backups)"
            fi
            ;;
        
        rollback)
            log ERROR "Rollback functionality not yet implemented"
            exit 1
            ;;
        
        scan)
            log ERROR "Scan functionality not yet implemented"
            exit 1
            ;;
        
        help|--help)
            show_help
            ;;
        
        *)
            log ERROR "Unknown command: $command"
            echo "Run '$SCRIPT_NAME help' for usage information"
            exit 1
            ;;
    esac
    
    log SUCCESS "Operation completed successfully"
}

# Handle interrupts gracefully
trap 'log ERROR "Operation interrupted by user"; exit 1' INT TERM

# Run main function
main "$@"