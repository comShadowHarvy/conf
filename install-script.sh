#!/usr/bin/env bash
#
# Utility Installer Script
# Installs mkscript and updateall to make them available system-wide
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print a colored message
print_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Print a success message
success() {
    print_message "${GREEN}" "✅ $1"
}

# Print an error message
error() {
    print_message "${RED}" "❌ $1"
    return 1
}

# Print a warning message
warning() {
    print_message "${YELLOW}" "⚠️ $1"
}

# Print an info message
info() {
    print_message "${BLUE}" "ℹ️ $1"
}

# Check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Install a script to a location in PATH
install_script() {
    local script_source="$1"
    local script_name="$2"
    local install_dir="$3"
    
    # Check if source script exists
    if [[ ! -f "$script_source" ]]; then
        error "Source script not found: $script_source"
        return 1
    fi
    
    # Copy the script to destination
    cp "$script_source" "$install_dir/$script_name" || {
        error "Failed to copy $script_source to $install_dir/$script_name"
        return 1
    }
    
    # Make it executable
    chmod +x "$install_dir/$script_name" || {
        error "Failed to make $install_dir/$script_name executable"
        return 1
    }
    
    success "Installed $script_name to $install_dir"
}

# Main installation function
main() {
    info "Starting utility installation..."
    
    # Define installation directory
    local install_dir="$HOME/.local/bin"
    
    # Create install directory if it doesn't exist
    if [[ ! -d "$install_dir" ]]; then
        info "Creating installation directory: $install_dir"
        mkdir -p "$install_dir" || error "Failed to create directory: $install_dir"
    fi
    
    # Check if installation directory is in PATH
    if ! echo "$PATH" | grep -q "$install_dir"; then
        warning "$install_dir is not in your PATH"
        info "Add the following to your ~/.bashrc or ~/.zshrc:"
        echo "export PATH=\"\$PATH:$install_dir\""
    fi
    
    # Install mkscript
    local mkscript_source="./mkscript-app.sh"
    if [[ -f "$mkscript_source" ]]; then
        install_script "$mkscript_source" "mkscript" "$install_dir"
    else
        warning "mkscript-app.sh not found in current directory."
        info "Please provide the correct path to mkscript-app.sh:"
        read -r mkscript_source
        if [[ -f "$mkscript_source" ]]; then
            install_script "$mkscript_source" "mkscript" "$install_dir"
        else
            error "Could not find mkscript-app.sh"
        fi
    fi
    
    # Install updateall
    local updateall_source="./updateall-script.sh"
    if [[ -f "$updateall_source" ]]; then
        install_script "$updateall_source" "updateall" "$install_dir"
    else
        warning "updateall-script.sh not found in current directory."
        info "Please provide the correct path to updateall-script.sh:"
        read -r updateall_source
        if [[ -f "$updateall_source" ]]; then
            install_script "$updateall_source" "updateall" "$install_dir"
        else
            error "Could not find updateall-script.sh"
        fi
    fi
    
    # Installation complete
    if command_exists mkscript && command_exists updateall; then
        success "Both utilities installed successfully!"
        info "You can now run 'mkscript' and 'updateall' from anywhere."
    elif command_exists mkscript; then
        success "mkscript installed successfully!"
        warning "updateall installation failed."
    elif command_exists updateall; then
        success "updateall installed successfully!"
        warning "mkscript installation failed."
    else
        warning "Installation completed with issues."
        info "Make sure $install_dir is in your PATH and restart your terminal."
    fi
}

# Run the installation
main
