#!/bin/bash

# Check if package name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <package>"
  exit 1
fi

PACKAGE="$1"
installed=0

# Function to try a command and mark success if it runs successfully
try_install() {
  echo "Trying: $1 $PACKAGE"
  $1 "$PACKAGE" && installed=1 && return 0
  return 1
}

# Attempt installation using available package managers in order
if command -v pacman >/dev/null 2>&1; then
  try_install "sudo pacman -S --noconfirm"
  [ $installed -eq 1 ] && exit 0
fi

if command -v yay >/dev/null 2>&1; then
  try_install "yay -S --noconfirm"
  [ $installed -eq 1 ] && exit 0
fi

if command -v apt-get >/dev/null 2>&1; then
  try_install "sudo apt-get install -y"
  [ $installed -eq 1 ] && exit 0
fi

if command -v apk >/dev/null 2>&1; then
  try_install "sudo apk add"
  [ $installed -eq 1 ] && exit 0
fi

if command -v dpkg >/dev/null 2>&1; then
  echo "dpkg is found but dpkg doesn't resolve dependencies automatically. Skipping."
fi

if command -v brew >/dev/null 2>&1; then
  try_install "brew install"
  [ $installed -eq 1 ] && exit 0
fi

echo "No supported package manager found or installation failed."
exit 1
