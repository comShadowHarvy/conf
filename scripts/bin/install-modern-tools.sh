#!/bin/bash
# Modern CLI Tools Installation Script for Arch Linux
# Installs: broot, zellij, hexyl, just, hyperfine, atuin, ouch, gping, bandwhich, starship, fzf, fd, bat, eza

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

log_info "Starting installation of modern CLI tools..."

# Update package database
log_info "Updating package database..."
sudo pacman -Sy

# List of packages to install
PACKAGES=(
    broot      # Interactive directory tree
    zellij     # Terminal workspace
    hexyl      # Hex viewer
    just       # Command runner
    hyperfine  # Benchmarking tool
    atuin      # Shell history
    ouch       # Compression tool
    gping      # Graphical ping
    bandwhich  # Bandwidth monitor
    starship   # Shell prompt
    fzf        # Fuzzy finder
    fd         # Modern find
    bat        # Cat with syntax highlighting
    eza        # Modern ls
    ripgrep    # Fast grep (useful with fzf)
)

# Install packages
log_info "Installing packages: ${PACKAGES[*]}"
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

log_success "All packages installed successfully!"

# Configure tools
log_info "Configuring tools..."

# --- Atuin Configuration ---
if command -v atuin &> /dev/null; then
    log_info "Configuring atuin (shell history)..."
    
    # Initialize atuin if not already done
    if [[ ! -f "$HOME/.local/share/atuin/history.db" ]]; then
        log_info "Importing existing shell history..."
        atuin import auto || log_warn "Could not import history (might be first run)"
    fi
    
    # Add atuin to bashrc if not already present
    if ! grep -q "atuin init bash" "$HOME/.bashrc"; then
        log_info "Adding atuin to .bashrc..."
        echo '' >> "$HOME/.bashrc"
        echo '# Atuin - Shell history' >> "$HOME/.bashrc"
        echo 'eval "$(atuin init bash)"' >> "$HOME/.bashrc"
    else
        log_info "Atuin already configured in .bashrc"
    fi
    
    log_success "Atuin configured!"
fi

# --- Starship Configuration ---
if command -v starship &> /dev/null; then
    log_info "Configuring starship (prompt)..."
    
    # Add starship to bashrc if not already present
    if ! grep -q "starship init bash" "$HOME/.bashrc"; then
        log_info "Adding starship to .bashrc..."
        echo '' >> "$HOME/.bashrc"
        echo '# Starship - Custom prompt' >> "$HOME/.bashrc"
        echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
    else
        log_info "Starship already configured in .bashrc"
    fi
    
    # Create default config if it doesn't exist
    if [[ ! -f "$HOME/.config/starship.toml" ]]; then
        log_info "Creating starship config..."
        mkdir -p "$HOME/.config"
        starship preset nerd-font-symbols -o "$HOME/.config/starship.toml"
    fi
    
    log_success "Starship configured!"
fi

# --- FZF Configuration ---
if command -v fzf &> /dev/null; then
    log_info "Configuring fzf (fuzzy finder)..."
    
    # Add fzf to bashrc if not already present
    if ! grep -q "fzf --bash" "$HOME/.bashrc"; then
        log_info "Adding fzf keybindings to .bashrc..."
        echo '' >> "$HOME/.bashrc"
        echo '# FZF - Fuzzy finder keybindings' >> "$HOME/.bashrc"
        echo 'eval "$(fzf --bash)"' >> "$HOME/.bashrc"
    else
        log_info "FZF already configured in .bashrc"
    fi
    
    # Set FZF default options with fd
    if ! grep -q "FZF_DEFAULT_COMMAND" "$HOME/.bashrc"; then
        log_info "Setting FZF default options..."
        echo '' >> "$HOME/.bashrc"
        echo '# FZF - Use fd instead of find' >> "$HOME/.bashrc"
        echo 'export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"' >> "$HOME/.bashrc"
        echo 'export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"' >> "$HOME/.bashrc"
        echo 'export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"' >> "$HOME/.bashrc"
    fi
    
    log_success "FZF configured!"
fi

# --- Zellij Configuration ---
if command -v zellij &> /dev/null; then
    log_info "Configuring zellij (terminal workspace)..."
    
    if [[ ! -f "$HOME/.config/zellij/config.kdl" ]]; then
        log_info "Creating default zellij config..."
        mkdir -p "$HOME/.config/zellij"
        zellij setup --dump-config > "$HOME/.config/zellij/config.kdl"
    else
        log_info "Zellij config already exists"
    fi
    
    log_success "Zellij configured!"
fi

# --- Broot Configuration ---
if command -v broot &> /dev/null; then
    log_info "Configuring broot (directory navigator)..."
    
    # Broot needs to install shell integration
    if [[ ! -f "$HOME/.config/broot/launcher/bash/br" ]]; then
        log_info "Installing broot shell integration..."
        broot --install || log_warn "Could not auto-install broot (try running 'broot' manually)"
    else
        log_info "Broot already configured"
    fi
    
    log_success "Broot configured!"
fi

# Print summary
echo ""
log_success "============================================"
log_success "Installation Complete!"
log_success "============================================"
echo ""
log_info "Installed tools:"
echo "  • broot     - Interactive directory tree (alias: br, tree)"
echo "  • zellij    - Terminal workspace (alias: zj)"
echo "  • hexyl     - Hex viewer (alias: hex)"
echo "  • just      - Command runner (alias: j, jl)"
echo "  • hyperfine - Benchmarking (alias: bench)"
echo "  • atuin     - Shell history (alias: hist)"
echo "  • ouch      - Compression (alias: compress, extract)"
echo "  • gping     - Graphical ping (alias: ping)"
echo "  • bandwhich - Bandwidth monitor (alias: bw)"
echo "  • starship  - Custom prompt"
echo "  • fzf       - Fuzzy finder (Ctrl+R, Ctrl+T)"
echo "  • fd        - Modern find"
echo "  • bat       - Cat with highlighting"
echo "  • eza       - Modern ls"
echo "  • ripgrep   - Fast grep (rg)"
echo ""
log_info "Next steps:"
echo "  1. Reload your shell: ${GREEN}source ~/.bashrc${NC}"
echo "  2. Your aliases are in: ${GREEN}~/.aliases.d/modern-tools.aliases${NC}"
echo "  3. Try: ${GREEN}ff${NC} (find files), ${GREEN}fcd${NC} (cd with fzf), ${GREEN}hist${NC} (search history)"
echo "  4. (Optional) Register for atuin sync: ${GREEN}atuin register${NC}"
echo "  5. (Optional) Customize starship: ${GREEN}nvim ~/.config/starship.toml${NC}"
echo ""
log_success "Happy hacking! 🚀"
