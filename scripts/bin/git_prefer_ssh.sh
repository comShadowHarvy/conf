#!/usr/bin/env bash
# git_prefer_ssh.sh
# Configure Git and GitHub CLI to prefer SSH over HTTPS for all operations.
#
# What this script does:
# 1. Configures Git to automatically rewrite HTTPS GitHub URLs to SSH
# 2. Configures GitHub CLI (gh) to use SSH protocol
# 3. Optionally scans and converts existing repos from HTTPS to SSH
# 4. Verifies SSH authentication with GitHub
#
# USAGE:
#   ./git_prefer_ssh.sh [--convert-existing] [--scan-depth N] [--dry-run]
#
# OPTIONS:
#   --convert-existing    Scan for and convert existing HTTPS repos to SSH
#   --scan-depth N        Search depth for finding repos (default: 3)
#   --dry-run             Show what would be done without making changes
#   -h, --help            Show this help message

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
RESET='\033[0m'

DRY_RUN=0
CONVERT_EXISTING=0
SCAN_DEPTH=3

# Display title screen
show_title() {
  clear
  echo -e "${CYAN}"
  echo "╔═══════════════════════════════════════════════════════════════════════╗"
  echo "║                                                                       ║"
  echo -e "║  ${BOLD}${MAGENTA}   ██████╗ ██╗████████╗    ███████╗███████╗██╗  ██╗${CYAN}                ║"
  echo -e "║  ${BOLD}${MAGENTA}  ██╔════╝ ██║╚══██╔══╝    ██╔════╝██╔════╝██║  ██║${CYAN}                ║"
  echo -e "║  ${BOLD}${MAGENTA}  ██║  ███╗██║   ██║       ███████╗███████╗███████║${CYAN}                ║"
  echo -e "║  ${BOLD}${MAGENTA}  ██║   ██║██║   ██║       ╚════██║╚════██║██╔══██║${CYAN}                ║"
  echo -e "║  ${BOLD}${MAGENTA}  ╚██████╔╝██║   ██║       ███████║███████║██║  ██║${CYAN}                ║"
  echo -e "║  ${BOLD}${MAGENTA}   ╚═════╝ ╚═╝   ╚═╝       ╚══════╝╚══════╝╚═╝  ╚═╝${CYAN}                ║"
  echo "║                                                                       ║"
  echo -e "║              ${YELLOW}${BOLD}SSH Configuration & Automation Tool${CYAN}                    ║"
  echo "║                                                                       ║"
  echo -e "║                     ${GREEN}Configure Git to Prefer SSH${CYAN}                       ║"
  echo -e "║                   ${GREEN}Over HTTPS for All Operations${CYAN}                      ║"
  echo "║                                                                       ║"
  echo -e "║  ${WHITE}Author:${RESET} ${BLUE}${BOLD}ShadowHarvy${CYAN}                                                 ║"
  echo -e "║  ${WHITE}Version:${RESET} ${GREEN}1.0.0${CYAN}                                                       ║"
  echo "║                                                                       ║"
  echo "╚═══════════════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --convert-existing) CONVERT_EXISTING=1; shift ;;
    --scan-depth)       SCAN_DEPTH="${2:-3}"; shift 2 ;;
    --dry-run)          DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# //; s/^#//'
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Show title screen
show_title

echo -e "${CYAN}${BOLD}=== Git SSH Preference Configuration ===${RESET}"
echo

# Check if Git is installed
if ! command -v git >/dev/null 2>&1; then
  echo -e "${RED}[error] Git is not installed${RESET}" >&2
  exit 1
fi

# Check if SSH key exists
if [[ ! -f "$HOME/.ssh/id_ed25519" && ! -f "$HOME/.ssh/id_rsa" ]]; then
  echo -e "${YELLOW}[warn] No SSH key found in ~/.ssh/${RESET}"
  echo -e "${YELLOW}[warn] You may need to generate one with: ssh-keygen -t ed25519 -C \"your_email@example.com\"${RESET}"
  echo -e "${YELLOW}[warn] And add it to GitHub: https://github.com/settings/keys${RESET}"
  echo
fi

# 1. Configure Git to rewrite HTTPS to SSH
echo -e "${BLUE}[1/4] Configuring Git to prefer SSH over HTTPS...${RESET}"

if [[ $DRY_RUN -eq 1 ]]; then
  echo -e "${YELLOW}[dry-run] Would set: git config --global url.\"git@github.com:\".insteadOf \"https://github.com/\"${RESET}"
else
  git config --global url."git@github.com:".insteadOf "https://github.com/"
  echo -e "  ${GREEN}✓${RESET} Git will now automatically use SSH for all GitHub URLs"
fi

# Check current setting
CURRENT_REWRITE=$(git config --global --get url."git@github.com:".insteadOf 2>/dev/null || echo "")
if [[ -n "$CURRENT_REWRITE" ]]; then
  echo -e "  ${CYAN}Current setting:${RESET} $CURRENT_REWRITE → git@github.com:"
fi

echo

# 2. Configure GitHub CLI
echo -e "${BLUE}[2/4] Configuring GitHub CLI (gh) to use SSH...${RESET}"

if command -v gh >/dev/null 2>&1; then
  if [[ $DRY_RUN -eq 1 ]]; then
    echo -e "${YELLOW}[dry-run] Would set: gh config set git_protocol ssh${RESET}"
  else
    gh config set git_protocol ssh
    echo -e "  ${GREEN}✓${RESET} GitHub CLI will now use SSH for git operations"
  fi
  
  # Show current gh auth status
  echo -e "  ${CYAN}GitHub CLI status:${RESET}"
  gh auth status 2>&1 | sed 's/^/    /' || echo "    (Not authenticated)"
else
  echo -e "  ${YELLOW}⚠${RESET} GitHub CLI (gh) not found - skipping"
  echo -e "    ${WHITE}Install with:${RESET} sudo pacman -S github-cli"
fi

echo

# 3. Verify SSH authentication
echo -e "${BLUE}[3/4] Verifying SSH authentication with GitHub...${RESET}"

if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  USERNAME=$(ssh -T git@github.com 2>&1 | grep -oP "Hi \K[^!]+")
  echo -e "  ${GREEN}✓${RESET} SSH authentication successful as: ${BOLD}${GREEN}$USERNAME${RESET}"
else
  echo -e "  ${RED}✗${RESET} SSH authentication failed"
  echo -e "    ${YELLOW}Make sure your SSH key is added to GitHub:${RESET} https://github.com/settings/keys"
  echo -e "    ${WHITE}Test with:${RESET} ssh -T git@github.com"
fi

echo

# 4. Convert existing repos (optional)
echo -e "${BLUE}[4/4] Scanning for existing repositories...${RESET}"

if [[ $CONVERT_EXISTING -eq 0 ]]; then
  echo -e "  ${YELLOW}Skipped${RESET} (use ${CYAN}--convert-existing${RESET} to enable)"
  echo
  echo -e "${GREEN}${BOLD}=== Configuration Complete ===${RESET}"
  echo
  echo -e "${CYAN}Summary:${RESET}"
  echo -e "  ${GREEN}•${RESET} Git will now automatically use SSH for GitHub URLs"
  echo -e "  ${GREEN}•${RESET} GitHub CLI configured to use SSH (if installed)"
  echo -e "  ${GREEN}•${RESET} All future clones will use SSH by default"
  echo
  echo -e "${WHITE}To convert existing HTTPS repos to SSH, run:${RESET}"
  echo -e "  ${CYAN}$0 --convert-existing${RESET}"
  exit 0
fi

# Find and convert repos
echo -e "  ${CYAN}Searching for repositories (depth: $SCAN_DEPTH)...${RESET}"
REPOS_FOUND=0
REPOS_CONVERTED=0

while IFS='|' read -r repo url; do
  ((REPOS_FOUND++))
  
  # Convert HTTPS URL to SSH
  SSH_URL=$(echo "$url" | sed 's|https://github.com/|git@github.com:|')
  
  echo
  echo -e "  ${MAGENTA}Repository:${RESET} $repo"
  echo -e "    ${YELLOW}Current:${RESET}  $url"
  echo -e "    ${CYAN}New:${RESET}      $SSH_URL"
  
  if [[ $DRY_RUN -eq 1 ]]; then
    echo -e "    ${YELLOW}[dry-run] Would convert to SSH${RESET}"
  else
    if git -C "$repo" remote set-url origin "$SSH_URL" 2>/dev/null; then
      echo -e "    ${GREEN}✓${RESET} Converted to SSH"
      ((REPOS_CONVERTED++))
    else
      echo -e "    ${RED}✗${RESET} Failed to convert"
    fi
  fi
done < <(find "$HOME" -maxdepth "$SCAN_DEPTH" -name ".git" -type d 2>/dev/null | while read gitdir; do
  repo=$(dirname "$gitdir")
  url=$(git -C "$repo" remote get-url origin 2>/dev/null || echo "")
  if [[ "$url" == https://github.com/* ]]; then
    echo "$repo|$url"
  fi
done)

echo
if [[ $REPOS_FOUND -eq 0 ]]; then
  echo -e "  ${YELLOW}No repositories using HTTPS found${RESET}"
else
  if [[ $DRY_RUN -eq 0 ]]; then
    echo -e "  ${GREEN}Converted $REPOS_CONVERTED of $REPOS_FOUND repositories${RESET}"
  else
    echo -e "  ${YELLOW}Found $REPOS_FOUND repositories that would be converted${RESET}"
  fi
fi

echo
echo -e "${GREEN}${BOLD}=== Configuration Complete ===${RESET}"
echo
echo -e "${CYAN}Summary:${RESET}"
echo -e "  ${GREEN}•${RESET} Git configured to prefer SSH for GitHub"
echo -e "  ${GREEN}•${RESET} GitHub CLI configured to use SSH"
if [[ $REPOS_CONVERTED -gt 0 ]]; then
  echo -e "  ${GREEN}•${RESET} Converted ${BOLD}$REPOS_CONVERTED${RESET} existing repos to SSH"
fi
echo
echo -e "${BOLD}${GREEN}All future Git operations with GitHub will use SSH!${RESET}"
echo
