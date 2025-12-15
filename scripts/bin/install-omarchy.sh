#!/bin/bash
# Omarchy Installation Script
# Installs Omarchy - Organization hierarchy tool
#### curl -fsSL https://omarchy.org/install | bash
set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   log_error "Don't run this script as root. It will ask for sudo when needed."
   exit 1
fi

log_info "Starting installation of Omarchy..."

# Run the official Omarchy installer
log_info "Downloading and running Omarchy installer..."
eval "$(curl -fsSL https://raw.githubusercontent.com/basecamp/omarchy/refs/heads/master/boot.sh)"

# Verify installation
if command -v omarchy &> /dev/null; then
    log_success "Omarchy installed successfully!"
    
    # Get version
    OMARCHY_VERSION=$(omarchy --version 2>/dev/null || echo "installed")
    log_info "Version: $OMARCHY_VERSION"
else
    log_error "Omarchy installation failed or command not found in PATH"
    exit 1
fi

# Print summary
echo ""
log_success "============================================"
log_success "Installation Complete!"
log_success "============================================"
echo ""
log_info "Omarchy is now installed on your system."
echo ""
log_info "Next steps:"
echo "  1. Try running: ${GREEN}omarchy${NC}"
echo "  2. For help: ${GREEN}omarchy --help${NC}"
echo ""
log_success "Enjoy using Omarchy! 🚀"
