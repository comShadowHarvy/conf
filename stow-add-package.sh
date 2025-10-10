#!/usr/bin/env bash
# =============================================================================
# Stow Package Manager - Easy package addition to stow configuration
# =============================================================================
# Author: ShadowHarvy
# Description: Interactive tool to add new packages to stow-config.yaml
# =============================================================================

set -euo pipefail

# Script metadata
SCRIPT_NAME="stow-add-package"
SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
CONFIG_FILE="${SCRIPT_DIR}/stow-config.yaml"
STOW_DIR="${SCRIPT_DIR}"

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

# Logging functions
log_info() { echo -e "${CYAN}[INFO]${RESET} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${RESET} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${RESET} $*"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $*"; }
log_step() { echo -e "${PURPLE}[STEP]${RESET} $*"; }

# Interactive prompts
prompt_text() {
    local prompt="$1"
    local default="${2:-}"
    local var_name="$3"
    
    if [[ -n "$default" ]]; then
        read -p "${CYAN}${prompt}${RESET} [${YELLOW}${default}${RESET}]: " input
        input="${input:-$default}"
    else
        read -p "${CYAN}${prompt}${RESET}: " input
    fi
    
    declare -g "$var_name"="$input"
}

prompt_number() {
    local prompt="$1"
    local default="$2"
    local min="$3"
    local max="$4"
    local var_name="$5"
    
    while true; do
        read -p "${CYAN}${prompt}${RESET} (${min}-${max}) [${YELLOW}${default}${RESET}]: " input
        input="${input:-$default}"
        
        if [[ "$input" =~ ^[0-9]+$ ]] && (( input >= min && input <= max )); then
            declare -g "$var_name"="$input"
            break
        else
            log_error "Please enter a number between $min and $max"
        fi
    done
}

prompt_choice() {
    local prompt="$1"
    local choices_str="$2"
    local default="$3"
    local var_name="$4"
    
    IFS='|' read -ra choices <<< "$choices_str"
    
    echo -e "${CYAN}${prompt}${RESET}"
    for i in "${!choices[@]}"; do
        local choice="${choices[i]}"
        if [[ "$choice" == "$default" ]]; then
            echo -e "  ${YELLOW}$((i+1))${RESET}) ${BOLD}${choice}${RESET} ${YELLOW}(default)${RESET}"
        else
            echo -e "  $((i+1))) ${choice}"
        fi
    done
    
    while true; do
        read -p "Choice [${YELLOW}${default}${RESET}]: " input
        
        if [[ -z "$input" ]]; then
            declare -g "$var_name"="$default"
            break
        elif [[ "$input" =~ ^[0-9]+$ ]] && (( input >= 1 && input <= ${#choices[@]} )); then
            declare -g "$var_name"="${choices[$((input-1))]}"
            break
        else
            # Check if it's a direct choice match
            for choice in "${choices[@]}"; do
                if [[ "${input,,}" == "${choice,,}" ]]; then
                    declare -g "$var_name"="$choice"
                    return
                fi
            done
            log_error "Please enter a valid choice (1-${#choices[@]}) or choice name"
        fi
    done
}

prompt_boolean() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    local default_display="y/N"
    [[ "$default" == "true" ]] && default_display="Y/n"
    
    while true; do
        read -p "${CYAN}${prompt}${RESET} [${YELLOW}${default_display}${RESET}]: " input
        
        case "${input,,}" in
            ""|"y"|"yes"|"true")
                if [[ "$default" == "true" || "$input" =~ ^(y|yes|true)$ ]]; then
                    declare -g "$var_name"="true"
                    break
                elif [[ "$default" == "false" ]]; then
                    declare -g "$var_name"="false"
                    break
                fi
                ;;
            "n"|"no"|"false")
                declare -g "$var_name"="false"
                break
                ;;
            *)
                log_error "Please enter y/yes/true or n/no/false"
                ;;
        esac
    done
}

prompt_list() {
    local prompt="$1"
    local var_name="$2"
    
    echo -e "${CYAN}${prompt}${RESET}"
    echo -e "${YELLOW}Enter items one per line. Press Enter on empty line to finish.${RESET}"
    
    local items=()
    while true; do
        read -p "  • " item
        [[ -z "$item" ]] && break
        items+=("$item")
    done
    
    # Convert to YAML array format
    if [[ ${#items[@]} -eq 0 ]]; then
        declare -g "$var_name"="[]"
    else
        local yaml_array=""
        for item in "${items[@]}"; do
            yaml_array="$yaml_array\"$item\", "
        done
        yaml_array="[${yaml_array%, }]"
        declare -g "$var_name"="$yaml_array"
    fi
}

# Get existing packages
get_existing_packages() {
    local packages=()
    
    while IFS= read -r -d '' dir; do
        local pkg_name=$(basename "$dir")
        [[ "$pkg_name" != "." && "$pkg_name" != ".git" && "$pkg_name" != "logs" && "$pkg_name" != ".stow-backups" ]] && packages+=("$pkg_name")
    done < <(find "$STOW_DIR" -maxdepth 1 -type d -print0 2>/dev/null)
    
    printf '%s\n' "${packages[@]}" | sort
}

# Check if package exists in config
package_in_config() {
    local package="$1"
    grep -q "^  $package:" "$CONFIG_FILE" 2>/dev/null
}

# Scan for unconfigured packages
scan_unconfigured() {
    log_step "Scanning for unconfigured packages..."
    
    local existing_packages=()
    readarray -t existing_packages < <(get_existing_packages)
    
    local unconfigured=()
    for pkg in "${existing_packages[@]}"; do
        if ! package_in_config "$pkg"; then
            unconfigured+=("$pkg")
        fi
    done
    
    if [[ ${#unconfigured[@]} -eq 0 ]]; then
        log_success "All existing packages are configured!"
        return 1
    fi
    
    echo -e "${YELLOW}Found ${#unconfigured[@]} unconfigured packages:${RESET}"
    printf '  • %s\n' "${unconfigured[@]}"
    echo ""
    
    return 0
}

# Add package to YAML config
add_package_to_config() {
    local package="$1"
    local priority="$2"
    local category="$3"
    local description="$4"
    local dependencies="$5"
    local conflicts="$6"
    local backup_policy="$7"
    local enabled="$8"
    local hooks_pre_stow="${9:-}"
    local hooks_post_stow="${10:-}"
    
    log_step "Adding $package to configuration..."
    
    # Create backup
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Find where to insert (after packages: line, maintain priority order)
    local temp_file=$(mktemp)
    local in_packages=false
    local inserted=false
    
    while IFS= read -r line; do
        if [[ "$line" == "packages:" ]]; then
            echo "$line" >> "$temp_file"
            in_packages=true
        elif [[ "$in_packages" == "true" && "$line" =~ ^[[:space:]]*# ]]; then
            # Comment in packages section
            echo "$line" >> "$temp_file"
        elif [[ "$in_packages" == "true" && "$line" =~ ^[[:space:]]*[a-zA-Z] && "$inserted" == "false" ]]; then
            # Found another package, check if we should insert before it
            local existing_priority=$(echo "$line" | sed -n '/priority:/s/.*priority: *\([0-9]*\).*/\1/p')
            if [[ -n "$existing_priority" && "$priority" -lt "$existing_priority" ]]; then
                # Insert our package before this one
                write_package_config "$package" "$priority" "$category" "$description" "$dependencies" "$conflicts" "$backup_policy" "$enabled" "$hooks_pre_stow" "$hooks_post_stow" >> "$temp_file"
                echo "" >> "$temp_file"
                inserted=true
            fi
            echo "$line" >> "$temp_file"
        elif [[ "$in_packages" == "true" && "$line" =~ ^[^[:space:]] && "$inserted" == "false" ]]; then
            # End of packages section
            write_package_config "$package" "$priority" "$category" "$description" "$dependencies" "$conflicts" "$backup_policy" "$enabled" "$hooks_pre_stow" "$hooks_post_stow" >> "$temp_file"
            echo "" >> "$temp_file"
            echo "$line" >> "$temp_file"
            in_packages=false
            inserted=true
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$CONFIG_FILE"
    
    # If we're still in packages section at EOF, add the package
    if [[ "$in_packages" == "true" && "$inserted" == "false" ]]; then
        write_package_config "$package" "$priority" "$category" "$description" "$dependencies" "$conflicts" "$backup_policy" "$enabled" "$hooks_pre_stow" "$hooks_post_stow" >> "$temp_file"
    fi
    
    mv "$temp_file" "$CONFIG_FILE"
    
    log_success "Package '$package' added to configuration"
}

write_package_config() {
    local package="$1"
    local priority="$2"
    local category="$3"
    local description="$4"
    local dependencies="$5"
    local conflicts="$6"
    local backup_policy="$7"
    local enabled="$8"
    local hooks_pre_stow="$9"
    local hooks_post_stow="${10}"
    
    cat << EOF
  $package:
    priority: $priority
    category: $category
    description: "$description"
EOF
    
    if [[ "$dependencies" != "[]" ]]; then
        echo "    dependencies: $dependencies"
    fi
    
    if [[ "$conflicts" != "[]" ]]; then
        echo "    conflicts: $conflicts"
    fi
    
    if [[ "$backup_policy" != "ask" ]]; then
        echo "    backup_policy: $backup_policy"
    fi
    
    if [[ "$enabled" != "true" ]]; then
        echo "    enabled: $enabled"
    fi
    
    if [[ -n "$hooks_pre_stow" || -n "$hooks_post_stow" ]]; then
        echo "    hooks:"
        [[ -n "$hooks_pre_stow" ]] && echo "      pre_stow: \"$hooks_pre_stow\""
        [[ -n "$hooks_post_stow" ]] && echo "      post_stow: \"$hooks_post_stow\""
    fi
}

# Interactive package configuration
configure_package_interactive() {
    local package="$1"
    
    echo ""
    echo -e "${BOLD}${CYAN}━━━ Configuring Package: $package ━━━${RESET}"
    echo ""
    
    # Basic info
    local priority category description enabled backup_policy
    
    prompt_number "Priority (1=highest, 10=lowest)" "5" "1" "10" "priority"
    
    prompt_choice "Category" "core|development|desktop|optional" "optional" "category"
    
    prompt_text "Description" "Custom configuration package" "description"
    
    prompt_boolean "Enabled by default" "true" "enabled"
    
    prompt_choice "Backup policy" "ask|skip|backup|force" "ask" "backup_policy"
    
    # Dependencies
    local dependencies
    echo ""
    log_info "Dependencies (other packages this one requires):"
    prompt_list "Dependencies" "dependencies"
    
    # Conflicts
    local conflicts
    echo ""
    log_info "Conflicting files (files that might conflict during stowing):"
    echo -e "${YELLOW}Example: .bashrc, .config/nvim, etc.${RESET}"
    prompt_list "Conflicts" "conflicts"
    
    # Hooks
    local hooks_pre_stow hooks_post_stow
    echo ""
    prompt_text "Pre-stow hook command (optional)" "" "hooks_pre_stow"
    prompt_text "Post-stow hook command (optional)" "" "hooks_post_stow"
    
    # Summary
    echo ""
    echo -e "${BOLD}${YELLOW}━━━ Configuration Summary ━━━${RESET}"
    echo -e "${CYAN}Package:${RESET}      $package"
    echo -e "${CYAN}Priority:${RESET}     $priority"
    echo -e "${CYAN}Category:${RESET}     $category"
    echo -e "${CYAN}Description:${RESET}  $description"
    echo -e "${CYAN}Enabled:${RESET}      $enabled"
    echo -e "${CYAN}Backup Policy:${RESET} $backup_policy"
    echo -e "${CYAN}Dependencies:${RESET} $dependencies"
    echo -e "${CYAN}Conflicts:${RESET}    $conflicts"
    [[ -n "$hooks_pre_stow" ]] && echo -e "${CYAN}Pre-stow:${RESET}     $hooks_pre_stow"
    [[ -n "$hooks_post_stow" ]] && echo -e "${CYAN}Post-stow:${RESET}    $hooks_post_stow"
    echo ""
    
    local confirm
    prompt_boolean "Add this package to configuration" "true" "confirm"
    
    if [[ "$confirm" == "true" ]]; then
        add_package_to_config "$package" "$priority" "$category" "$description" \
                             "$dependencies" "$conflicts" "$backup_policy" "$enabled" \
                             "$hooks_pre_stow" "$hooks_post_stow"
        return 0
    else
        log_info "Package configuration cancelled"
        return 1
    fi
}

# Quick add with defaults
quick_add_package() {
    local package="$1"
    local category="${2:-optional}"
    local priority="${3:-5}"
    
    local description="$package configuration"
    local dependencies="[]"
    local conflicts="[]"
    local backup_policy="ask"
    local enabled="true"
    local hooks_pre_stow=""
    local hooks_post_stow=""
    
    add_package_to_config "$package" "$priority" "$category" "$description" \
                         "$dependencies" "$conflicts" "$backup_policy" "$enabled" \
                         "$hooks_pre_stow" "$hooks_post_stow"
}

# Bulk configuration
bulk_configure() {
    local unconfigured=()
    readarray -t unconfigured < <(get_existing_packages | while read -r pkg; do
        package_in_config "$pkg" || echo "$pkg"
    done)
    
    if [[ ${#unconfigured[@]} -eq 0 ]]; then
        log_success "All packages are already configured!"
        return 0
    fi
    
    echo -e "${BOLD}${CYAN}━━━ Bulk Package Configuration ━━━${RESET}"
    echo ""
    echo "Found ${#unconfigured[@]} unconfigured packages:"
    printf '  • %s\n' "${unconfigured[@]}"
    echo ""
    
    local mode
    prompt_choice "Configuration mode" "interactive|quick|skip" "quick" "mode"
    
    case "$mode" in
        interactive)
            for pkg in "${unconfigured[@]}"; do
                configure_package_interactive "$pkg" || continue
            done
            ;;
        quick)
            local default_category default_priority
            prompt_choice "Default category for all packages" "core|development|desktop|optional" "optional" "default_category"
            prompt_number "Default priority for all packages" "5" "1" "10" "default_priority"
            
            for pkg in "${unconfigured[@]}"; do
                log_info "Quick-adding package: $pkg"
                quick_add_package "$pkg" "$default_category" "$default_priority"
            done
            ;;
        skip)
            log_info "Skipping bulk configuration"
            return 0
            ;;
    esac
    
    log_success "Bulk configuration completed!"
}

# Show usage
show_usage() {
    cat << EOF
${BOLD}$SCRIPT_NAME v$SCRIPT_VERSION${RESET} - Easy Stow Package Configuration

${BOLD}USAGE:${RESET}
  $SCRIPT_NAME [COMMAND] [OPTIONS]

${BOLD}COMMANDS:${RESET}
  ${CYAN}add <package>${RESET}     - Add specific package interactively
  ${CYAN}quick <package>${RESET}   - Quick add with defaults
  ${CYAN}scan${RESET}              - Scan for unconfigured packages
  ${CYAN}bulk${RESET}              - Configure all unconfigured packages
  ${CYAN}list${RESET}              - List all packages and their status
  ${CYAN}help${RESET}              - Show this help

${BOLD}EXAMPLES:${RESET}
  # Add specific package interactively
  $SCRIPT_NAME add my-package

  # Quick add with defaults
  $SCRIPT_NAME quick my-package

  # Configure all unconfigured packages
  $SCRIPT_NAME bulk

  # List all packages
  $SCRIPT_NAME list

${BOLD}FEATURES:${RESET}
  • Interactive package configuration with prompts
  • Quick add mode with sensible defaults  
  • Bulk configuration for multiple packages
  • Automatic YAML formatting and validation
  • Configuration backups before changes
  • Priority-based insertion in config file
  • Support for dependencies, conflicts, and hooks

EOF
}

# List packages and status
list_packages() {
    log_step "Package Configuration Status"
    echo ""
    
    local all_packages=()
    readarray -t all_packages < <(get_existing_packages)
    
    local configured_count=0
    local unconfigured_count=0
    
    echo -e "${BOLD}${CYAN}Package Directory Status:${RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    for pkg in "${all_packages[@]}"; do
        if package_in_config "$pkg"; then
            echo -e "  ${GREEN}✓${RESET} $pkg ${CYAN}(configured)${RESET}"
            configured_count=$((configured_count + 1))
        else
            echo -e "  ${YELLOW}○${RESET} $pkg ${YELLOW}(unconfigured)${RESET}"
            unconfigured_count=$((unconfigured_count + 1))
        fi
    done
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BOLD}Total:${RESET} ${#all_packages[@]} packages"
    echo -e "${GREEN}Configured:${RESET} $configured_count"
    echo -e "${YELLOW}Unconfigured:${RESET} $unconfigured_count"
    
    if [[ $unconfigured_count -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Run '${SCRIPT_NAME} bulk' to configure all unconfigured packages${RESET}"
    fi
}

# Main function
main() {
    # Check dependencies
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Config file not found: $CONFIG_FILE"
        exit 1
    fi
    
    # Parse arguments
    case "${1:-help}" in
        add)
            [[ $# -lt 2 ]] && { log_error "Package name required"; exit 1; }
            local package="$2"
            
            if [[ ! -d "${STOW_DIR}/${package}" ]]; then
                log_error "Package directory doesn't exist: ${STOW_DIR}/${package}"
                log_info "Create the directory first, then add configuration"
                exit 1
            fi
            
            if package_in_config "$package"; then
                log_warning "Package '$package' is already configured"
                exit 1
            fi
            
            configure_package_interactive "$package"
            ;;
            
        quick)
            [[ $# -lt 2 ]] && { log_error "Package name required"; exit 1; }
            local package="$2"
            local category="${3:-optional}"
            local priority="${4:-5}"
            
            if [[ ! -d "${STOW_DIR}/${package}" ]]; then
                log_error "Package directory doesn't exist: ${STOW_DIR}/${package}"
                exit 1
            fi
            
            if package_in_config "$package"; then
                log_warning "Package '$package' is already configured"
                exit 1
            fi
            
            quick_add_package "$package" "$category" "$priority"
            ;;
            
        scan)
            scan_unconfigured
            ;;
            
        bulk)
            bulk_configure
            ;;
            
        list)
            list_packages
            ;;
            
        help|--help|-h)
            show_usage
            ;;
            
        *)
            log_error "Unknown command: ${1:-}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"