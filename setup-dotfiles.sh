#!/usr/bin/env bash
# =============================================================================
# Stow Dotfiles Setup Script
# =============================================================================
# This script sets up the dotfiles repository on a fresh system
# Usage: curl -fsSL <raw-url>/setup-dotfiles.sh | bash
# Or:    ./setup-dotfiles.sh [options]

set -euo pipefail

# Configuration
REPO_URL="https://github.com/yourusername/dotfiles.git"  # UPDATE THIS!
INSTALL_DIR="$HOME/conf"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${PURPLE}[STEP]${NC} $1"; }

# Help function
show_help() {
    cat << EOF
${PURPLE}🏠 Stow Dotfiles Setup Script${NC}

${BLUE}DESCRIPTION:${NC}
    Sets up your dotfiles repository with GNU Stow on a fresh system.
    Automatically detects your package manager and installs dependencies.

${BLUE}USAGE:${NC}
    $0 [OPTIONS]

    # Quick install (recommended):
    curl -fsSL <raw-github-url>/setup-dotfiles.sh | bash

${BLUE}OPTIONS:${NC}
    -h, --help          Show this help message
    -u, --url URL       Git repository URL
    -d, --dir DIR       Installation directory (default: $INSTALL_DIR)
    -c, --core-only     Install only core packages (bash, zsh, git, scripts, shared)
    -s, --skip-deps     Skip dependency installation
    -f, --force         Force installation (overwrite existing)
    -b, --backup-only   Only backup existing files, don't install
    --ssh               Use SSH for git clone (requires SSH keys)
    --dry-run           Show what would be done without executing

${BLUE}EXAMPLES:${NC}
    $0                                    # Full installation with defaults
    $0 --core-only                        # Install only essential packages  
    $0 --url git@github.com:user/dots.git --ssh  # Use your SSH repo
    $0 --force                            # Force overwrite existing setup

${BLUE}PACKAGES:${NC}
    ${GREEN}Core (essential):${NC}
    • bash     - Enhanced bash configuration
    • zsh      - Optimized zsh with modules  
    • git      - Git configuration and aliases
    • scripts  - Custom utility scripts (updateall, mkscript, etc.)
    • shared   - Alias system (modular + legacy)

    ${YELLOW}Optional (GUI/tools):${NC}
    • tmux     - Terminal multiplexer config
    • nvim     - Neovim configuration (LazyVim)
    • hyprland - Hyprland window manager
    • waybar   - Status bar configuration  
    • vscode   - VS Code settings
    • wget     - Download utility config
    • secrets  - API keys and tokens

EOF
}

# Parse command line arguments
CORE_ONLY=false
SKIP_DEPS=false
FORCE=false
DRY_RUN=false
BACKUP_ONLY=false
USE_SSH=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -u|--url)
            REPO_URL="$2"
            shift 2
            ;;
        -d|--dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -c|--core-only)
            CORE_ONLY=true
            shift
            ;;
        -s|--skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -b|--backup-only)
            BACKUP_ONLY=true
            shift
            ;;
        --ssh)
            USE_SSH=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Dry run function
execute() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: $*"
    else
        "$@"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS and package manager
detect_system() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos:brew"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch:pacman"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian:apt"
    elif [[ -f /etc/redhat-release ]]; then
        echo "redhat:dnf"
    elif [[ -f /etc/SUSE-brand ]]; then
        echo "suse:zypper"
    else
        echo "unknown:unknown"
    fi
}

# Install dependencies
install_dependencies() {
    [[ "$SKIP_DEPS" == "true" ]] && return 0
    
    log_step "Installing dependencies..."
    local system_info=$(detect_system)
    local os=${system_info%:*}
    local pm=${system_info#*:}
    
    log_info "Detected system: $os with package manager: $pm"
    
    case $pm in
        pacman)
            execute sudo pacman -Sy --needed git stow make
            ;;
        apt)
            execute sudo apt update
            execute sudo apt install -y git stow make
            ;;
        dnf)
            execute sudo dnf install -y git stow make
            ;;
        brew)
            execute brew install git stow make
            ;;
        zypper)
            execute sudo zypper install -y git stow make
            ;;
        *)
            log_error "Unknown package manager: $pm"
            log_error "Please install manually: git, stow, make"
            exit 1
            ;;
    esac
    
    log_success "Dependencies installed successfully"
}

# Backup existing dotfiles
backup_existing_files() {
    log_step "Backing up existing dotfiles..."
    
    # Files that might conflict with Stow
    local files_to_backup=(
        ".bashrc" ".bash_profile" ".bash_logout"
        ".zshrc" ".antigenrc" 
        ".gitconfig" ".wgetrc" ".api_keys" ".aliases"
        ".config/nvim" ".config/tmux" ".config/hypr" ".config/waybar"
        ".vscode/settings.json"
    )
    
    local backed_up=false
    execute mkdir -p "$BACKUP_DIR"
    
    for file in "${files_to_backup[@]}"; do
        local full_path="$HOME/$file"
        if [[ -e "$full_path" ]] && [[ ! -L "$full_path" ]]; then
            log_info "Backing up $file"
            execute mkdir -p "$BACKUP_DIR/$(dirname "$file")"
            execute cp -r "$full_path" "$BACKUP_DIR/$file" 2>/dev/null || true
            backed_up=true
        fi
    done
    
    if [[ "$backed_up" == "true" ]]; then
        log_success "Backup created at $BACKUP_DIR"
        echo "  📁 Location: $BACKUP_DIR"
    else
        log_info "No existing dotfiles found to backup"
        execute rmdir "$BACKUP_DIR" 2>/dev/null || true
    fi
    
    [[ "$BACKUP_ONLY" == "true" ]] && exit 0
}

# Clone or update repository  
setup_repository() {
    log_step "Setting up dotfiles repository..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        if [[ "$FORCE" != "true" ]]; then
            log_error "Directory $INSTALL_DIR already exists"
            log_error "Use --force to overwrite or remove it manually"
            exit 1
        else
            log_warning "Removing existing $INSTALL_DIR"
            execute rm -rf "$INSTALL_DIR"
        fi
    fi
    
    # Convert to SSH if requested
    if [[ "$USE_SSH" == "true" ]] && [[ "$REPO_URL" =~ https://github.com/ ]]; then
        REPO_URL=$(echo "$REPO_URL" | sed 's|https://github.com/|git@github.com:|' | sed 's|\.git$|.git|')
        log_info "Using SSH URL: $REPO_URL"
    fi
    
    log_info "Cloning from $REPO_URL"
    execute git clone "$REPO_URL" "$INSTALL_DIR"
    log_success "Repository cloned successfully"
}

# Remove conflicting files before stowing
remove_conflicts() {
    log_step "Removing conflicting files..."
    
    local conflicts=(
        "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.bash_logout"
        "$HOME/.zshrc" "$HOME/.antigenrc" 
        "$HOME/.gitconfig" "$HOME/.wgetrc" "$HOME/.api_keys" "$HOME/.aliases"
    )
    
    for file in "${conflicts[@]}"; do
        if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
            log_info "Removing conflicting file: $file"
            execute rm "$file"
        fi
    done
    
    # Remove conflicting directories
    local conflict_dirs=(
        "$HOME/.config/nvim" "$HOME/.config/tmux"
    )
    
    for dir in "${conflict_dirs[@]}"; do
        if [[ -d "$dir" ]] && [[ ! -L "$dir" ]]; then
            log_info "Removing conflicting directory: $dir"
            execute rm -rf "$dir"
        fi
    done
}

# Stow packages
stow_packages() {
    log_step "Installing dotfiles with Stow..."
    
    execute cd "$INSTALL_DIR"
    
    local core_packages=(bash zsh git scripts shared)
    local optional_packages=(tmux nvim hyprland waybar vscode wget secrets)
    
    if [[ "$CORE_ONLY" == "true" ]]; then
        log_info "Installing core packages only"
        packages=("${core_packages[@]}")
    else
        log_info "Installing all available packages"
        packages=("${core_packages[@]}")
        # Only add optional packages that exist
        for pkg in "${optional_packages[@]}"; do
            [[ -d "$pkg" ]] && packages+=("$pkg")
        done
    fi
    
    log_info "Packages to install: ${packages[*]}"
    
    for package in "${packages[@]}"; do
        if [[ -d "$package" ]]; then
            log_info "Installing $package..."
            if execute stow -t "$HOME" "$package" 2>/dev/null; then
                log_success "✓ $package installed"
            else
                log_warning "⚠ $package had conflicts, trying to resolve..."
                # Try to resolve conflicts automatically
                execute stow -t "$HOME" --adopt "$package" 2>/dev/null || true
                execute git checkout HEAD -- "$package" 2>/dev/null || true
                execute stow -t "$HOME" "$package"
                log_success "✓ $package installed (conflicts resolved)"
            fi
        else
            log_warning "Package $package not found, skipping"
        fi
    done
}

# Verify installation
verify_installation() {
    log_step "Verifying installation..."
    
    local verification_passed=true
    
    # Check essential symlinks
    local expected_links=(
        "$HOME/.bashrc:conf/bash/.bashrc"
        "$HOME/.zshrc:conf/zsh/.zshrc" 
        "$HOME/.gitconfig:conf/git/.gitconfig"
        "$HOME/.aliases:conf/shared/.aliases"
    )
    
    echo "  🔗 Checking symlinks:"
    for link_pair in "${expected_links[@]}"; do
        local link=${link_pair%:*}
        local expected=${link_pair#*:}
        
        if [[ -L "$link" ]]; then
            local actual=$(readlink "$link")
            if [[ "$actual" == "$expected" ]]; then
                echo "    ✅ $(basename "$link") → $actual"
            else
                echo "    ❌ $(basename "$link") → $actual (expected $expected)"
                verification_passed=false
            fi
        else
            echo "    ❌ $(basename "$link") is not a symlink"
            verification_passed=false
        fi
    done
    
    # Check if directory exists and is a git repo
    echo "  📁 Repository status:"
    if [[ -d "$INSTALL_DIR/.git" ]]; then
        local branch=$(cd "$INSTALL_DIR" && git branch --show-current 2>/dev/null || echo "unknown")
        local commit=$(cd "$INSTALL_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        echo "    ✅ Git repository (branch: $branch, commit: $commit)"
    else
        echo "    ❌ Not a git repository"
        verification_passed=false
    fi
    
    if [[ "$verification_passed" == "true" ]]; then
        log_success "Installation verification passed!"
        return 0
    else
        log_error "Installation verification failed!"
        return 1
    fi
}

# Post-installation setup
post_install_setup() {
    log_step "Post-installation setup..."
    
    # Make sure scripts are executable
    if [[ -d "$INSTALL_DIR/scripts/bin" ]]; then
        execute chmod +x "$INSTALL_DIR"/scripts/bin/*
        log_info "Made scripts executable"
    fi
    
    # Source new shell config if possible
    if [[ -n "${BASH_VERSION:-}" ]]; then
        if [[ -f "$HOME/.bashrc" ]]; then
            log_info "Sourcing new bash configuration..."
            execute source "$HOME/.bashrc" || log_warning "Failed to source .bashrc"
        fi
    fi
}

# Show completion message
show_completion() {
    echo
    echo "🎉${GREEN} Installation Complete! ${NC}🎉"
    echo "=================================="
    
    cat << EOF

${BLUE}📍 What was installed:${NC}
• Dotfiles repository: ${INSTALL_DIR}
• Configuration symlinks in your home directory
• Custom scripts available at ~/bin/

${BLUE}🔄 Next Steps:${NC}
1. ${YELLOW}Restart your shell${NC} or open a new terminal
2. Run: ${YELLOW}source ~/.bashrc${NC} (for bash)
3. Run: ${YELLOW}source ~/.zshrc${NC} (for zsh)  
4. Check everything works: ${YELLOW}make status${NC}

${BLUE}🛠️  Management Commands:${NC}
• View status:     ${YELLOW}cd ~/conf && make status${NC}
• Add package:     ${YELLOW}make stow PACKAGE=nvim${NC}
• Remove package:  ${YELLOW}make unstow PACKAGE=nvim${NC} 
• Get help:        ${YELLOW}make help${NC}

${BLUE}📦 Available Scripts:${NC}
$(if [[ -d "$INSTALL_DIR/scripts/bin" ]]; then
    ls "$INSTALL_DIR/scripts/bin" 2>/dev/null | head -5 | sed 's/^/• /'
    echo "• ... and $(ls "$INSTALL_DIR/scripts/bin" 2>/dev/null | wc -l) total scripts"
fi)

${BLUE}🗂️  Backup Location:${NC}
$(if [[ -d "$BACKUP_DIR" ]]; then echo "$BACKUP_DIR"; else echo "No backup was needed"; fi)

${GREEN}Your dotfiles are now managed with GNU Stow!${NC}
Learn more: https://www.gnu.org/software/stow/

EOF
}

# Main installation function
main() {
    echo
    echo "🏠 ${PURPLE}Stow Dotfiles Setup${NC}"
    echo "===================="
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "🧪 DRY RUN MODE - No changes will be made"
    fi
    
    # Show configuration
    echo
    echo "${BLUE}Configuration:${NC}"
    echo "  Repository:   $REPO_URL"
    echo "  Install Dir:  $INSTALL_DIR"
    echo "  Backup Dir:   $BACKUP_DIR"
    echo "  Mode:         $(if [[ "$CORE_ONLY" == "true" ]]; then echo "Core packages only"; else echo "All packages"; fi)"
    echo
    
    # Confirm installation unless forced or dry run
    if [[ "$DRY_RUN" != "true" ]] && [[ "$FORCE" != "true" ]] && [[ "$BACKUP_ONLY" != "true" ]]; then
        read -p "Continue with installation? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled by user"
            exit 0
        fi
    fi
    
    # Run installation steps
    install_dependencies
    backup_existing_files
    setup_repository
    remove_conflicts
    stow_packages
    post_install_setup
    
    if ! verify_installation; then
        log_error "Installation completed with errors. Check the output above."
        exit 1
    fi
    
    show_completion
    log_success "🎉 Stow dotfiles setup completed successfully!"
}

# Handle interrupts gracefully
trap 'log_error "Setup interrupted by user"; exit 1' INT TERM

# Run main function
main "$@"