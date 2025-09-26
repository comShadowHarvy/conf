#!/usr/bin/env bash
#=============================================================
#  arch‑install-all.sh   –   Installs every tool needed for the
#                            “extract‑all.sh” helper on Arch Linux
#
#  Usage:
#      ./arch-install-all.sh          # run as regular user → sudo will be used
#      sudo ./arch-install-all.sh     # or run as root
#
#  Packages installed:
#    file, tar, gzip, bzip2, xz, unzip, p7zip, unrar,
#    arj, lzip, lzop, zstd, dpkg, rpm2cpio, cpio
#=============================================================

set -euo pipefail

# ------------------------------------------------------------------
#  Helper: print a message to stdout (colourised)
# ------------------------------------------------------------------
msg() { printf '\e[1;32m%s\e[0m\n' "$*"; }
warn() { printf '\e[1;33m%s\e[0m\n' "$*"; }
err() { printf '\e[1;31m%s\e[0m\n' "$*" >&2; }

# ------------------------------------------------------------------
#  1. Gather the list of packages that are missing
# ------------------------------------------------------------------
missing_pkgs=()
for pkg in file tar gzip bzip2 xz unzip p7zip unrar arj lzip lzop zstd dpkg rpm2cpio cpio; do
  if ! pacman -Qi "$pkg" &>/dev/null; then
    missing_pkgs+=("$pkg")
  fi
done

# ------------------------------------------------------------------
#  2. Nothing missing → quit
# ------------------------------------------------------------------
if [[ ${#missing_pkgs[@]} -eq 0 ]]; then
  msg "All required tools are already installed."
  exit 0
fi

# ------------------------------------------------------------------
#  3. Install the missing packages
# ------------------------------------------------------------------
msg "Installing the following packages: ${missing_pkgs[*]}"

# If the script was launched as a normal user, we want to run pacman with sudo.
cmd=(pacman -S --needed --noconfirm "${missing_pkgs[@]}")
if [[ $EUID -ne 0 ]]; then
  cmd=(sudo "${cmd[@]}")
fi

# Run the command and keep any failures on the stack
if "${cmd[@]}"; then
  msg "✅  Installation succeeded."
else
  err "❌  Installation failed – check the output above for details."
  exit 1
fi

# ------------------------------------------------------------------
#  4. Post‑install sanity check
# ------------------------------------------------------------------
for pkg in "${missing_pkgs[@]}"; do
  if ! pacman -Qi "$pkg" &>/dev/null; then
    warn "Package $pkg was not installed successfully.  Please check pacman logs."
  fi
done

msg "All tools are now available for use."
