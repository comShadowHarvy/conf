#!/usr/bin/env bash
#=============================================================================
# install-compression-tools.sh
#
# Installs all compression and decompression utilities needed for:
#   - extract (extract-all.sh)
#   - zipp (multi-format smart compressor)
#
# Supports: Arch / Omarchy / Manjaro (pacman), Debian / Ubuntu (apt),
#           Fedora / RHEL (dnf), openSUSE (zypper), Alpine (apk), macOS (brew)
#=============================================================================

set -euo pipefail

# ------------------------------------------------------------------
#  Color / UI helpers
# ------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

msg()    { printf "${GREEN}[+]${NC} %s\n" "$*"; }
info()   { printf "${BLUE}[*]${NC} %s\n" "$*"; }
warn()   { printf "${YELLOW}[!]${NC} %s\n" "$*"; }
err()    { printf "${RED}[x]${NC} %s\n" "$*" >&2; }
header() { printf "\n${BOLD}${CYAN}%s${NC}\n" "$*"; }

# ------------------------------------------------------------------
#  Helper: Check if binary exists in PATH
# ------------------------------------------------------------------
has() { command -v "$1" >/dev/null 2>&1; }

# ------------------------------------------------------------------
#  Parse Arguments
# ------------------------------------------------------------------
DRY_RUN=false
CHECK_ONLY=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -c, --check     Check installed tools and status without making changes
  -d, --dry-run   Show which packages would be installed
  -h, --help      Display this help message

Supported utilities installed:
  • Common:       file, tar, gzip, bzip2, xz, unzip, zip
  • Fast/Modern:  pigz (parallel gzip), zstd / unzstd
  • High-Ratio:   7z / 7zz (7-zip), unrar, arj, lzip, lzop
  • Linux Pkg:    dpkg-deb (deb), rpm2cpio + cpio (rpm)
  • Progress:     pv (pipe viewer)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--check)
      CHECK_ONLY=true
      shift
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# ------------------------------------------------------------------
#  Detect Package Manager & OS
# ------------------------------------------------------------------
detect_pkg_mgr() {
  if has pacman; then
    echo "pacman"
  elif has apt-get; then
    echo "apt"
  elif has dnf; then
    echo "dnf"
  elif has zypper; then
    echo "zypper"
  elif has apk; then
    echo "apk"
  elif has brew; then
    echo "brew"
  else
    echo "unknown"
  fi
}

PKG_MGR=$(detect_pkg_mgr)

# ------------------------------------------------------------------
#  Tool & Package Inventory
# ------------------------------------------------------------------
# Format: "binary_name:package_for_pacman:package_for_apt:package_for_dnf:package_for_zypper:package_for_apk:package_for_brew"
TOOL_DEFINITIONS=(
  "file:file:file:file:file:file:file"
  "tar:tar:tar:tar:tar:tar:tar"
  "gzip:gzip:gzip:gzip:gzip:gzip:gzip"
  "pigz:pigz:pigz:pigz:pigz:pigz:pigz"
  "bzip2:bzip2:bzip2:bzip2:bzip2:bzip2:bzip2"
  "bunzip2:bzip2:bzip2:bzip2:bzip2:bzip2:bzip2"
  "xz:xz:xz-utils:xz:xz:xz:xz"
  "unzip:unzip:unzip:unzip:unzip:unzip:unzip"
  "zip:zip:zip:zip:zip:zip:zip"
  "7z:7zip:p7zip-full:p7zip:7zip:7zip:p7zip"
  "unrar:unrar:unrar-free:unrar:unrar:unrar:unrar"
  "arj:arj:arj:arj:arj:arj:arj"
  "lzip:lzip:lzip:lzip:lzip:lzip:lzip"
  "lzop:lzop:lzop:lzop:lzop:lzop:lzop"
  "zstd:zstd:zstd:zstd:zstd:zstd:zstd"
  "unzstd:zstd:zstd:zstd:zstd:zstd:zstd"
  "dpkg-deb:dpkg:dpkg:dpkg:dpkg:dpkg:"
  "rpm2cpio:rpmextract:rpm2cpio:rpm:rpm:rpm2cpio:"
  "cpio:cpio:cpio:cpio:cpio:cpio:cpio"
  "pv:pv:pv:pv:pv:pv:pv"
)

# ------------------------------------------------------------------
#  Audit Installed Tools
# ------------------------------------------------------------------
header "=== Compression & Decompression Tools Status ==="

missing_tools=()
needed_pkgs=()

for item in "${TOOL_DEFINITIONS[@]}"; do
  IFS=":" read -r bin pkg_pacman pkg_apt pkg_dnf pkg_zypper pkg_apk pkg_brew <<< "$item"

  # Pick package name for current package manager
  case "$PKG_MGR" in
    pacman) target_pkg="$pkg_pacman" ;;
    apt)    target_pkg="$pkg_apt" ;;
    dnf)    target_pkg="$pkg_dnf" ;;
    zypper) target_pkg="$pkg_zypper" ;;
    apk)    target_pkg="$pkg_apk" ;;
    brew)   target_pkg="$pkg_brew" ;;
    *)      target_pkg="" ;;
  esac

  # Special check for 7z / 7zz
  if [[ "$bin" == "7z" ]]; then
    if has 7z || has 7zz || has 7za; then
      printf "  ${GREEN}✓${NC} %-12s (found %s)\n" "7z" "$(command -v 7z 2>/dev/null || command -v 7zz 2>/dev/null || command -v 7za)"
      continue
    fi
  elif has "$bin"; then
    printf "  ${GREEN}✓${NC} %-12s (found %s)\n" "$bin" "$(command -v "$bin")"
    continue
  fi

  printf "  ${RED}✗${NC} %-12s ${YELLOW}[MISSING]${NC} (Package: %s)\n" "$bin" "${target_pkg:-N/A}"
  missing_tools+=("$bin")
  if [[ -n "$target_pkg" ]]; then
    # Add uniquely
    if [[ ! " ${needed_pkgs[*]} " =~ " ${target_pkg} " ]]; then
      needed_pkgs+=("$target_pkg")
    fi
  fi
done

echo ""

if [[ ${#missing_tools[@]} -eq 0 ]]; then
  msg "All compression and extraction tools are installed and ready!"
  exit 0
fi

info "Missing tools: ${missing_tools[*]}"
info "Target packages to install: ${needed_pkgs[*]}"

if [[ "$CHECK_ONLY" == true ]]; then
  exit 0
fi

if [[ "$PKG_MGR" == "unknown" ]]; then
  err "Could not detect a supported package manager (pacman, apt, dnf, zypper, apk, brew)."
  err "Please install the missing tools manually: ${missing_tools[*]}"
  exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
  info "[Dry-Run] Package manager: $PKG_MGR"
  info "[Dry-Run] Would install: ${needed_pkgs[*]}"
  exit 0
fi

# ------------------------------------------------------------------
#  Run Installation
# ------------------------------------------------------------------
header "=== Installing Missing Packages via $PKG_MGR ==="

SUDO=""
if [[ $EUID -ne 0 ]] && [[ "$PKG_MGR" != "brew" ]]; then
  if has sudo; then
    SUDO="sudo"
  else
    err "'sudo' command not found and not running as root. Please run as root."
    exit 1
  fi
fi

case "$PKG_MGR" in
  pacman)
    info "Running: $SUDO pacman -S --needed --noconfirm ${needed_pkgs[*]}"
    $SUDO pacman -S --needed --noconfirm "${needed_pkgs[@]}"
    ;;
  apt)
    info "Updating package lists..."
    $SUDO apt-get update -y
    info "Running: $SUDO apt-get install -y ${needed_pkgs[*]}"
    $SUDO apt-get install -y "${needed_pkgs[@]}"
    ;;
  dnf)
    info "Running: $SUDO dnf install -y ${needed_pkgs[*]}"
    $SUDO dnf install -y "${needed_pkgs[@]}"
    ;;
  zypper)
    info "Running: $SUDO zypper --non-interactive install ${needed_pkgs[*]}"
    $SUDO zypper --non-interactive install "${needed_pkgs[@]}"
    ;;
  apk)
    info "Running: $SUDO apk add ${needed_pkgs[*]}"
    $SUDO apk add "${needed_pkgs[@]}"
    ;;
  brew)
    info "Running: brew install ${needed_pkgs[*]}"
    brew install "${needed_pkgs[@]}"
    ;;
esac

# ------------------------------------------------------------------
#  Post-Install Verification
# ------------------------------------------------------------------
header "=== Verification ==="
still_missing=()
for bin in "${missing_tools[@]}"; do
  if [[ "$bin" == "7z" ]]; then
    if has 7z || has 7zz || has 7za; then
      printf "  ${GREEN}✓${NC} %-12s is now installed!\n" "7z"
      continue
    fi
  elif has "$bin"; then
    printf "  ${GREEN}✓${NC} %-12s is now installed!\n" "$bin"
    continue
  fi
  printf "  ${RED}✗${NC} %-12s is still missing\n" "$bin"
  still_missing+=("$bin")
done

echo ""
if [[ ${#still_missing[@]} -eq 0 ]]; then
  msg "🎉 All required compression and decompression tools are now installed successfully!"
else
  warn "Some tools could not be installed automatically: ${still_missing[*]}"
  warn "You may need to enable additional repositories (e.g. AUR, non-free, EPEL)."
fi
