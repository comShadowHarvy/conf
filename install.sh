#!/bin/bash

# Check if package name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <package> [--verbose]"
  echo "Example: $0 neovim"
  echo "Example: $0 yazi --verbose"
  exit 1
fi

PACKAGE="$1"
VERBOSE=0
installed=0

# Check for verbose flag
if [ "$2" = "--verbose" ]; then
  VERBOSE=1
fi

# Function to log messages if verbose is enabled
log() {
  if [ $VERBOSE -eq 1 ]; then
    echo "$1"
  fi
}

# Function to map package names for different package managers
map_package_name() {
  local pkg="$1"
  local manager="$2"
  
  case "$pkg:$manager" in
    "neovim:apt-get") echo "neovim" ;;
    "neovim:pacman") echo "neovim" ;;
    "neovim:brew") echo "neovim" ;;
    "yazi:cargo") echo "yazi" ;;
    # Add more mappings as needed
    *) echo "$pkg" ;;  # Default to the original name
  esac
}

# Function to try a command and mark success if it runs successfully
try_install() {
  local manager="$1"
  local cmd="$2"
  local pkg=$(map_package_name "$PACKAGE" "$manager")
  
  echo "Trying: $cmd $pkg"
  if [ $VERBOSE -eq 1 ]; then
    $cmd "$pkg" && installed=1 && return 0
  else
    $cmd "$pkg" >/dev/null 2>&1 && installed=1 && return 0
  fi
  return 1
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
  esac
  return 1
}

# Attempt installation using available package managers in order
if command -v pacman >/dev/null 2>&1; then
  try_install "pacman" "sudo pacman -S --noconfirm"
  [ $installed -eq 1 ] && echo "✅ Successfully installed $PACKAGE using pacman" && exit 0
fi

if command -v yay >/dev/null 2>&1; then
  try_install "yay" "yay -S --noconfirm"
  [ $installed -eq 1 ] && echo "✅ Successfully installed $PACKAGE using yay" && exit 0
fi

if command -v apt-get >/dev/null 2>&1; then
  # Update package lists first
  log "Updating apt package lists..."
  sudo apt-get update >/dev/null 2>&1
  try_install "apt-get" "sudo apt-get install -y"
  [ $installed -eq 1 ] && echo "✅ Successfully installed $PACKAGE using apt-get" && exit 0
fi

if command -v dnf >/dev/null 2>&1; then
  try_install "dnf" "sudo dnf install -y"
  [ $installed -eq 1 ] && echo "✅ Successfully installed $PACKAGE using dnf" && exit 0
fi

if command -v zypper >/dev/null 2>&1; then
  try_install "zypper" "sudo zypper install -y"
  [ $installed -eq 1 ] && echo "✅ Successfully installed $PACKAGE using zypper" && exit 0
fi

if command -v apk >/dev/null 2>&1; then
  try_install "apk" "sudo apk add"
  [ $installed -eq 1 ] && echo "✅ Successfully installed $PACKAGE using apk" && exit 0
fi

if command -v brew >/dev/null 2>&1; then
  try_install "brew" "brew install"
  [ $installed -eq 1 ] && echo "✅ Successfully installed $PACKAGE using brew" && exit 0
fi

# Try cargo for Rust packages
if command -v cargo >/dev/null 2>&1; then
  case "$PACKAGE" in
    "yazi"|"yazi-fm")
      try_install "cargo" "cargo install --locked"
      [ $installed -eq 1 ] && echo "✅ Successfully installed $PACKAGE using cargo" && exit 0
      ;;
  esac
fi

# Try handling special cases as a last resort
handle_special_cases
[ $installed -eq 1 ] && echo "✅ Successfully installed $PACKAGE using special handling" && exit 0

echo "❌ No supported package manager found or installation failed for $PACKAGE."
echo "You may need to install it manually or check the package name."
exit 1