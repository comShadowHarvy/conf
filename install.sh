#!/bin/bash
# =============================================================================
# Enhanced Cross-Platform Package Installer
# A smart script for installing packages across different Linux distributions,
# macOS, and language-specific package managers.
# =============================================================================

# Configuration and command-line argument parsing
PACKAGE=""
VERBOSE=0
SAFE_MODE=0
UNINSTALL=0
FORCE=0
installed=0
LOG_FILE="$HOME/.install_history.log"

# Show help message
show_help() {
  echo "Usage: $0 <package> [options]"
  echo "Options:"
  echo "  --verbose    Show detailed output during installation"
  echo "  --safe       Ask for confirmation before executing sudo commands"
  echo "  --uninstall  Remove the specified package"
  echo "  --force      Skip dependency checks and verification"
  echo "  --help       Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 neovim"
  echo "  $0 yazi --verbose"
  echo "  $0 ripgrep --safe"
  echo "  $0 node --uninstall"
  exit 0
}

# Process command-line arguments
process_args() {
  # Check if package name is provided
  if [ -z "$1" ] || [[ "$1" == --* ]]; then
    show_help
  fi

  PACKAGE="$1"
  shift

  # Process options
  while [ $# -gt 0 ]; do
    case "$1" in
      --verbose)
        VERBOSE=1
        ;;
      --safe)
        SAFE_MODE=1
        echo "Running in safe mode. Will ask for confirmation before each sudo operation."
        ;;
      --uninstall)
        UNINSTALL=1
        echo "Running in uninstall mode."
        ;;
      --force)
        FORCE=1
        echo "Running in force mode. Skipping dependency checks and verification."
        ;;
      --help)
        show_help
        ;;
      *)
        echo "Unknown option: $1"
        show_help
        ;;
    esac
    shift
  done
}

# Function to log messages if verbose is enabled
log() {
  if [ $VERBOSE -eq 1 ]; then
    echo "[LOG] $1"
  fi
}

# Function to log error messages
error() {
  echo "[ERROR] $1" >&2
}

# Function to map package names for different package managers
map_package_name() {
  local pkg="$1"
  local manager="$2"
  
  case "$pkg:$manager" in
    # Editors and IDEs
    "neovim:apt-get") echo "neovim" ;;
    "neovim:pacman") echo "neovim" ;;
    "neovim:brew") echo "neovim" ;;
    "vim:apt-get") echo "vim" ;;
    "emacs:apt-get") echo "emacs" ;;
    "vscode:apt-get") echo "code" ;;
    "vscode:brew") echo "visual-studio-code" ;;
    
    # File managers
    "yazi:cargo") echo "yazi-fm" ;;
    "yazi:pacman") echo "yazi" ;;
    "yazi:apt-get") echo "yazi" ;;
    
    # Terminal utilities
    "ripgrep:apt-get") echo "ripgrep" ;;
    "ripgrep:brew") echo "ripgrep" ;;
    "ripgrep:cargo") echo "ripgrep" ;;
    "rg:apt-get") echo "ripgrep" ;;
    "rg:pacman") echo "ripgrep" ;;
    "fd:apt-get") echo "fd-find" ;;
    "fd:pacman") echo "fd" ;;
    "fzf:brew") echo "fzf" ;;
    "fzf:apt-get") echo "fzf" ;;
    "bat:apt-get") echo "bat" ;;
    "bat:pacman") echo "bat" ;;
    
    # Programming languages
    "node:apt-get") echo "nodejs" ;;
    "nodejs:apt-get") echo "nodejs" ;;
    "python:apt-get") echo "python3" ;;
    "python:pacman") echo "python" ;;
    "rust:apt-get") echo "rustc" ;;
    "rust:pacman") echo "rust" ;;
    "go:apt-get") echo "golang" ;;
    "golang:apt-get") echo "golang" ;;
    
    # Shell enhancements
    "zsh:apt-get") echo "zsh" ;;
    "ohmyzsh:curl") echo "ohmyzsh" ;;
    "ohmyposh:apt-get") echo "oh-my-posh" ;;
    
    # Default to the original name
    *) echo "$pkg" ;;
  esac
}

# Function to try a command and mark success if it runs successfully
try_install() {
  local manager="$1"
  local cmd="$2"
  local pkg=$(map_package_name "$PACKAGE" "$manager")
  
  echo "Trying: $cmd $pkg"
  
  # Check for safe mode with sudo
  if [[ "$cmd" == sudo* ]] && [ $SAFE_MODE -eq 1 ]; then
    echo "About to run with sudo: $cmd $pkg"
    read -p "Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Operation cancelled by user"
      return 1
    fi
  fi
  
  # Execute the command
  local output=""
  local exit_code=0
  
  if [ $VERBOSE -eq 1 ]; then
    $cmd "$pkg"
    exit_code=$?
  else
    output=$($cmd "$pkg" 2>&1)
    exit_code=$?
  fi
  
  # Handle the result
  if [ $exit_code -eq 0 ]; then
    installed=1
    # Log successful installation
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installed $pkg using $manager" >> "$LOG_FILE"
    return 0
  else
    log "Failed to install with $manager: $output"
    return 1
  fi
}

# Function to try uninstallation
try_uninstall() {
  local manager="$1"
  local pkg=$(map_package_name "$PACKAGE" "$manager")
  local cmd=""
  
  case "$manager" in
    "pacman") cmd="sudo pacman -R" ;;
    "yay") cmd="yay -R" ;;
    "apt-get") cmd="sudo apt-get remove -y" ;;
    "dnf") cmd="sudo dnf remove -y" ;;
    "zypper") cmd="sudo zypper remove -y" ;;
    "apk") cmd="sudo apk del" ;;
    "brew") cmd="brew uninstall" ;;
    "cargo") cmd="cargo uninstall" ;;
    "pip") cmd="pip uninstall -y" ;;
    "npm") cmd="npm uninstall -g" ;;
    "gem") cmd="gem uninstall" ;;
    *) 
      echo "Uninstall not supported for $manager"
      return 1 
      ;;
  esac
  
  echo "Trying to uninstall $pkg using $cmd..."
  
  # Check for safe mode with sudo
  if [[ "$cmd" == sudo* ]] && [ $SAFE_MODE -eq 1 ]; then
    echo "About to run with sudo: $cmd $pkg"
    read -p "Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Operation cancelled by user"
      return 1
    fi
  fi
  
  if [ $VERBOSE -eq 1 ]; then
    $cmd "$pkg"
    exit_code=$?
  else
    output=$($cmd "$pkg" 2>&1)
    exit_code=$?
  fi
  
  if [ $exit_code -eq 0 ]; then
    installed=1
    # Log successful uninstallation
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Uninstalled $pkg using $manager" >> "$LOG_FILE"
    return 0
  else
    log "Failed to uninstall with $manager: $output"
    return 1
  fi
}

# Detect available package managers
detect_package_managers() {
  declare -a managers
  
  # Desktop/server package managers
  [ -x "$(command -v pacman)" ] && managers+=("pacman")
  [ -x "$(command -v yay)" ] && managers+=("yay")
  [ -x "$(command -v apt-get)" ] && managers+=("apt-get")
  [ -x "$(command -v dnf)" ] && managers+=("dnf")
  [ -x "$(command -v zypper)" ] && managers+=("zypper")
  [ -x "$(command -v apk)" ] && managers+=("apk")
  
  # Language-specific package managers
  [ -x "$(command -v pip)" ] && managers+=("pip")
  [ -x "$(command -v npm)" ] && managers+=("npm")
  [ -x "$(command -v cargo)" ] && managers+=("cargo")
  [ -x "$(command -v gem)" ] && managers+=("gem")
  
  # macOS package managers
  [ -x "$(command -v brew)" ] && managers+=("brew")
  [ -x "$(command -v port)" ] && managers+=("port")
  
  # Special installations
  [ -x "$(command -v curl)" ] && managers+=("curl")
  
  echo "${managers[@]}"
}

# Resolve dependencies for packages
resolve_dependencies() {
  local pkg="$1"
  local manager="$2"
  
  # Skip if in force mode
  if [ $FORCE -eq 1 ]; then
    return 0
  fi
  
  case "$pkg:$manager" in
    "neovim:apt-get")
      echo "Checking dependencies for neovim..."
      try_install "$manager" "sudo apt-get install -y" "software-properties-common"
      ;;
    "yazi:cargo")
      echo "Checking dependencies for yazi..."
      for dep in gcc make pkg-config; do
        if ! command -v $dep >/dev/null 2>&1; then
          echo "Installing dependency: $dep"
          if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get install -y $dep
          elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm $dep
          # Add more package managers as needed
          fi
        fi
      done
      ;;
    "node:apt-get"|"nodejs:apt-get")
      echo "Checking dependencies for nodejs..."
      try_install "$manager" "sudo apt-get install -y" "curl"
      ;;
  esac
}

# Verify that installation was successful
verify_installation() {
  local pkg="$1"
  local binary="${2:-$1}"
  
  # Skip if in force mode
  if [ $FORCE -eq 1 ]; then
    return 0
  fi
  
  # Map common packages to their binaries
  case "$pkg" in
    "neovim") binary="nvim" ;;
    "ripgrep") binary="rg" ;;
    "fd-find") binary="fdfind" ;;
    "nodejs") binary="node" ;;
    "yazi-fm") binary="yazi" ;;
  esac
  
  if command -v "$binary" >/dev/null 2>&1; then
    echo "✅ Verified: $binary is now available"
    if [ $VERBOSE -eq 1 ]; then
      echo "Version information:"
      $binary --version 2>/dev/null || echo "No version information available"
    fi
    return 0
  else
    echo "⚠️ Warning: $binary was not found in PATH after installation"
    return 1
  fi
}

# Handle special cases for certain packages
handle_special_cases() {
  case "$PACKAGE" in
    "yazi")
      # For Yazi, try cargo installation as fallback
      if command -v cargo >/dev/null 2>&1; then
        echo "Trying cargo installation for Yazi..."
        cargo install --locked yazi-fm && installed=1 && return 0
      fi
      ;;
    "ohmyzsh")
      # For Oh My Zsh, use the official installation method
      echo "Installing Oh My Zsh..."
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && installed=1 && return 0
      ;;
    "nvm")
      # For Node Version Manager
      echo "Installing NVM..."
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && installed=1 && return 0
      ;;
    "rust")
      # For Rust, use rustup
      echo "Installing Rust using rustup..."
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && installed=1 && return 0
      ;;
  esac
  return 1
}

# Handle uninstallation for special cases
handle_special_uninstall() {
  case "$PACKAGE" in
    "ohmyzsh")
      echo "Uninstalling Oh My Zsh..."
      if [ -f "$HOME/.oh-my-zsh/tools/uninstall.sh" ]; then
        sh "$HOME/.oh-my-zsh/tools/uninstall.sh" && installed=1 && return 0
      fi
      ;;
    "nvm")
      echo "To uninstall NVM, please remove the NVM directory (usually ~/.nvm) and the NVM initialization lines from your profile."
      echo "You may want to use: rm -rf ~/.nvm"
      installed=1 && return 0
      ;;
    "rust")
      echo "Uninstalling Rust using rustup..."
      if command -v rustup >/dev/null 2>&1; then
        rustup self uninstall -y && installed=1 && return 0
      fi
      ;;
  esac
  return 1
}

# Main installation function
install_package() {
  # Get available package managers
  IFS=' ' read -r -a managers <<< "$(detect_package_managers)"
  
  if [ ${#managers[@]} -eq 0 ]; then
    error "No supported package managers found on your system."
    exit 1
  fi
  
  log "Available package managers: ${managers[*]}"
  
  # Try system package managers first
  for manager in "${managers[@]}"; do
    case "$manager" in
      # System package managers
      "pacman")
        try_install "$manager" "sudo pacman -S --noconfirm"
        [ $installed -eq 1 ] && verify_installation "$PACKAGE" && echo "✅ Successfully installed $PACKAGE using pacman" && return 0
        ;;
      "yay")
        try_install "$manager" "yay -S --noconfirm"
        [ $installed -eq 1 ] && verify_installation "$PACKAGE" && echo "✅ Successfully installed $PACKAGE using yay" && return 0
        ;;
      "apt-get")
        # Update package lists first
        log "Updating apt package lists..."
        if [ $SAFE_MODE -eq 1 ]; then
          echo "About to run: sudo apt-get update"
          read -p "Continue? [y/N] " -n 1 -r
          echo
          if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo apt-get update >/dev/null 2>&1
          fi
        else
          sudo apt-get update >/dev/null 2>&1
        fi
        
        # Resolve dependencies
        resolve_dependencies "$PACKAGE" "$manager"
        
        # Install package
        try_install "$manager" "sudo apt-get install -y"
        [ $installed -eq 1 ] && verify_installation "$PACKAGE" && echo "✅ Successfully installed $PACKAGE using apt-get" && return 0
        ;;
      "dnf")
        try_install "$manager" "sudo dnf install -y"
        [ $installed -eq 1 ] && verify_installation "$PACKAGE" && echo "✅ Successfully installed $PACKAGE using dnf" && return 0
        ;;
      "zypper")
        try_install "$manager" "sudo zypper install -y"
        [ $installed -eq 1 ] && verify_installation "$PACKAGE" && echo "✅ Successfully installed $PACKAGE using zypper" && return 0
        ;;
      "apk")
        try_install "$manager" "sudo apk add"
        [ $installed -eq 1 ] && verify_installation "$PACKAGE" && echo "✅ Successfully installed $PACKAGE using apk" && return 0
        ;;
      "brew")
        try_install "$manager" "brew install"
        [ $installed -eq 1 ] && verify_installation "$PACKAGE" && echo "✅ Successfully installed $PACKAGE using brew" && return 0
        ;;
      "port")
        try_install "$manager" "sudo port install"
        [ $installed -eq 1 ] && verify_installation "$PACKAGE" && echo "✅ Successfully installed $PACKAGE using MacPorts" && return 0
        ;;
        
      # Language-specific package managers
      "pip")
        # Only use pip for Python packages
        case "$PACKAGE" in
          python-*|py-*|pip-*)
            try_install "$manager" "pip install --user"
            [ $installed -eq 1 ] && echo "✅ Successfully installed $PACKAGE using pip" && return 0
            ;;
        esac
        ;;
      "npm")
        # Only use npm for JavaScript packages
        case "$PACKAGE" in
          node-*|npm-*|js-*)
            try_install "$manager" "npm install -g"
            [ $installed -eq 1 ] && echo "✅ Successfully installed $PACKAGE using npm" && return 0
            ;;
        esac
        ;;
      "cargo")
        # For Rust packages
        case "$PACKAGE" in
          "yazi"|"yazi-fm"|"ripgrep"|"rg"|"fd"|"bat"|"cargo-*"|"rust-*")
            try_install "$manager" "cargo install --locked"
            [ $installed -eq 1 ] && verify_installation "$PACKAGE" && echo "✅ Successfully installed $PACKAGE using cargo" && return 0
            ;;
        esac
        ;;
    esac
  done
  
  # Try handling special cases as a last resort
  handle_special_cases
  [ $installed -eq 1 ] && echo "✅ Successfully installed $PACKAGE using special handling" && return 0
  
  echo "❌ No supported package manager found or installation failed for $PACKAGE."
  echo "You may need to install it manually or check the package name."
  return 1
}

# Main uninstallation function
uninstall_package() {
  # Try special uninstall handlers first
  handle_special_uninstall
  [ $installed -eq 1 ] && echo "✅ Successfully uninstalled $PACKAGE" && return 0

  # Get available package managers
  IFS=' ' read -r -a managers <<< "$(detect_package_managers)"
  
  for manager in "${managers[@]}"; do
    try_uninstall "$manager"
    [ $installed -eq 1 ] && echo "✅ Successfully uninstalled $PACKAGE using $manager" && return 0
  done
  
  echo "❌ Failed to uninstall $PACKAGE or package not found."
  return 1
}

# Main execution
process_args "$@"

if [ $UNINSTALL -eq 1 ]; then
  uninstall_package
else
  install_package
fi

exit $?