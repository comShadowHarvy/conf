#!/usr/bin/env bash
# setup_git_ssh_signing.sh
# Configure Git user profile and SSH commit signing for GitHub/GitLab.
#
# Author: ShadowHarvy
# Version: 1.0.0
#
# What this script does:
# 1. Sets Git user.name and user.email
# 2. Configures Git to use SSH as the signing format (gpg.format ssh)
# 3. Discovers/links your public SSH key (user.signingkey ~/.ssh/id_ed25519.pub)
# 4. Enables automatic commit signing (commit.gpgsign true)
# 5. Configures allowed_signers for local signature verification
# 6. Displays the public key and provides GitHub configuration guidance
#
# USAGE:
#   ./setup_git_ssh_signing.sh [OPTIONS]
#
# OPTIONS:
#   -n, --name NAME       Git user name (e.g. "Your Name")
#   -e, --email EMAIL     Git user email (e.g. "you@example.com")
#   -k, --key PATH        Path to public SSH key (e.g. ~/.ssh/id_ed25519.pub)
#   --no-sign             Do not enable automatic commit signing (commit.gpgsign)
#   --no-trust            Skip setting up ~/.config/git/allowed_signers
#   --dry-run             Preview changes without applying them
#   -y, --yes             Accept defaults non-interactively where possible
#   -h, --help            Show this help message

set -euo pipefail

# ANSI Color Definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
RESET='\033[0m'

# Default values
ARG_NAME=""
ARG_EMAIL=""
ARG_KEY=""
AUTO_SIGN=1
SETUP_TRUST=1
DRY_RUN=0
NON_INTERACTIVE=0

# Display banner
show_title() {
  clear 2>/dev/null || true
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
  echo -e "║              ${YELLOW}${BOLD}Git Profile & SSH Signing Setup Tool${CYAN}                    ║"
  echo "║                                                                       ║"
  echo -e "║                ${GREEN}Configure Git Identity & Sign Commits${CYAN}                  ║"
  echo -e "║                  ${GREEN}Using Your Modern SSH Key Pair${CYAN}                     ║"
  echo "║                                                                       ║"
  echo -e "║  ${WHITE}Author:${RESET} ${BLUE}${BOLD}ShadowHarvy${CYAN}                                                 ║"
  echo -e "║  ${WHITE}Version:${RESET} ${GREEN}1.0.0${CYAN}                                                       ║"
  echo "║                                                                       ║"
  echo "╚═══════════════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo
}

# Print help message
show_help() {
  echo -e "${BOLD}Usage:${RESET} $0 [OPTIONS]"
  echo
  echo -e "${BOLD}Options:${RESET}"
  echo "  -n, --name NAME       Git user name (e.g. \"Jane Doe\")"
  echo "  -e, --email EMAIL     Git user email (e.g. \"jane@example.com\")"
  echo "  -k, --key PATH        Path to public SSH key (e.g. ~/.ssh/id_ed25519.pub)"
  echo "      --no-sign         Do not enable automatic commit signing (commit.gpgsign false)"
  echo "      --no-trust        Skip local verification setup (allowed_signers)"
  echo "      --dry-run         Print what would be executed without applying changes"
  echo "  -y, --yes             Accept defaults non-interactively where possible"
  echo "  -h, --help            Show this help message"
  echo
  echo -e "${BOLD}Examples:${RESET}"
  echo "  $0                                      # Interactive wizard"
  echo "  $0 -n \"ShadowHarvy\" -e \"me@example.com\" # Provide details via flags"
  echo "  $0 --dry-run                            # Preview git config changes"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--name)
      ARG_NAME="${2:-}"
      shift 2
      ;;
    -e|--email)
      ARG_EMAIL="${2:-}"
      shift 2
      ;;
    -k|--key)
      ARG_KEY="${2:-}"
      shift 2
      ;;
    --no-sign)
      AUTO_SIGN=0
      shift
      ;;
    --no-trust)
      SETUP_TRUST=0
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -y|--yes)
      NON_INTERACTIVE=1
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo -e "${RED}[error] Unknown option: $1${RESET}" >&2
      show_help
      exit 1
      ;;
  esac
done

show_title

# 0. Check Git installation & version
if ! command -v git >/dev/null 2>&1; then
  echo -e "${RED}[error] Git is not installed or not in PATH.${RESET}" >&2
  exit 1
fi

GIT_VER=$(git --version | awk '{print $3}')
echo -e "${BLUE}[i] Detected Git version: ${BOLD}$GIT_VER${RESET}"

# SSH signing format requires Git 2.34.0+
MAJOR_VER=$(echo "$GIT_VER" | cut -d. -f1)
MINOR_VER=$(echo "$GIT_VER" | cut -d. -f2)
if [[ "$MAJOR_VER" -lt 2 ]] || { [[ "$MAJOR_VER" -eq 2 ]] && [[ "$MINOR_VER" -lt 34 ]]; }; then
  echo -e "${RED}[error] Git version $GIT_VER does not support SSH signing (requires Git 2.34+).${RESET}" >&2
  exit 1
fi
echo

# -------------------------------------------------------------
# STEP 1: Name and Email
# -------------------------------------------------------------
echo -e "${CYAN}${BOLD}▶ Step 1: User Identity (Name and Email)${RESET}"
echo -e "${WHITE}Git commits are stamped with your user name and email address.${RESET}"
echo

CURRENT_NAME=$(git config --global user.name 2>/dev/null || echo "")
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

# Resolve Name
if [[ -n "$ARG_NAME" ]]; then
  GIT_NAME="$ARG_NAME"
elif [[ $NON_INTERACTIVE -eq 1 && -n "$CURRENT_NAME" ]]; then
  GIT_NAME="$CURRENT_NAME"
else
  DEFAULT_NAME="${CURRENT_NAME:-$USER}"
  while true; do
    read -r -p "$(echo -e "${YELLOW}Enter your Git display name [${BOLD}$DEFAULT_NAME${RESET}${YELLOW}]: ${RESET}")" INPUT_NAME
    GIT_NAME="${INPUT_NAME:-$DEFAULT_NAME}"
    if [[ -n "$GIT_NAME" ]]; then
      break
    fi
    echo -e "${RED}Name cannot be empty. Please enter your name.${RESET}"
  done
fi

# Resolve Email
if [[ -n "$ARG_EMAIL" ]]; then
  GIT_EMAIL="$ARG_EMAIL"
elif [[ $NON_INTERACTIVE -eq 1 && -n "$CURRENT_EMAIL" ]]; then
  GIT_EMAIL="$CURRENT_EMAIL"
else
  DEFAULT_EMAIL="${CURRENT_EMAIL:-}"
  while true; do
    if [[ -n "$DEFAULT_EMAIL" ]]; then
      read -r -p "$(echo -e "${YELLOW}Enter your Git email [${BOLD}$DEFAULT_EMAIL${RESET}${YELLOW}]: ${RESET}")" INPUT_EMAIL
      GIT_EMAIL="${INPUT_EMAIL:-$DEFAULT_EMAIL}"
    else
      read -r -p "$(echo -e "${YELLOW}Enter your Git email (must match your GitHub email): ${RESET}")" INPUT_EMAIL
      GIT_EMAIL="${INPUT_EMAIL:-}"
    fi

    if [[ -n "$GIT_EMAIL" && "$GIT_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
      break
    elif [[ -n "$GIT_EMAIL" ]]; then
      echo -e "${YELLOW}Warning: '${GIT_EMAIL}' does not look like a standard email format, but proceeding.${RESET}"
      break
    else
      echo -e "${RED}Email cannot be empty. Please enter your email address.${RESET}"
    fi
  done
fi

echo -e "  ${GREEN}✓${RESET} Name  : ${BOLD}$GIT_NAME${RESET}"
echo -e "  ${GREEN}✓${RESET} Email : ${BOLD}$GIT_EMAIL${RESET}"
echo

# -------------------------------------------------------------
# STEP 2 & 3: SSH Key Discovery & Selection
# -------------------------------------------------------------
echo -e "${CYAN}${BOLD}▶ Step 2: SSH Signing Key Selection${RESET}"
echo -e "${WHITE}Discovering available public SSH keys in ~/.ssh...${RESET}"
echo

# Helper function to expand tilde
expand_path() {
  local p="$1"
  if [[ "$p" == ~* ]]; then
    echo "${p/#\~/$HOME}"
  else
    echo "$p"
  fi
}

KEY_PATH=""

if [[ -n "$ARG_KEY" ]]; then
  RESOLVED_ARG_KEY=$(expand_path "$ARG_KEY")
  if [[ -f "$RESOLVED_ARG_KEY" ]]; then
    KEY_PATH="$RESOLVED_ARG_KEY"
  else
    echo -e "${RED}[error] Specified key file not found: $ARG_KEY${RESET}" >&2
    exit 1
  fi
else
  # Discover potential public keys in ~/.ssh
  MAPFILE_KEYS=()
  if [[ -d "$HOME/.ssh" ]]; then
    # Preferred order: Ed25519 first, then RSA, then others
    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
      MAPFILE_KEYS+=("$HOME/.ssh/id_ed25519.pub")
    fi
    if [[ -f "$HOME/.ssh/id_rsa.pub" ]]; then
      MAPFILE_KEYS+=("$HOME/.ssh/id_rsa.pub")
    fi
    if [[ -f "$HOME/.ssh/id_ecdsa.pub" ]]; then
      MAPFILE_KEYS+=("$HOME/.ssh/id_ecdsa.pub")
    fi

    # Any other .pub files not already listed
    while IFS= read -r pubfile; do
      if [[ -f "$pubfile" ]]; then
        already_in=0
        for existing in "${MAPFILE_KEYS[@]}"; do
          if [[ "$existing" == "$pubfile" ]]; then
            already_in=1
            break
          fi
        done
        if [[ $already_in -eq 0 ]]; then
          MAPFILE_KEYS+=("$pubfile")
        fi
      fi
    done < <(find "$HOME/.ssh" -maxdepth 1 -name "*.pub" ! -name "*.backup*" 2>/dev/null || true)
  fi

  if [[ ${#MAPFILE_KEYS[@]} -eq 0 ]]; then
    echo -e "${YELLOW}[!] No SSH public keys found in ~/.ssh/${RESET}"
    if [[ $NON_INTERACTIVE -eq 1 ]]; then
      GEN_KEY="y"
    else
      read -r -p "$(echo -e "${YELLOW}Would you like to generate a new modern Ed25519 SSH key now? [Y/n]: ${RESET}")" GEN_CHOICE
      GEN_KEY="${GEN_CHOICE:-y}"
    fi

    if [[ "$GEN_KEY" =~ ^[Yy]$ ]]; then
      mkdir -p "$HOME/.ssh"
      chmod 700 "$HOME/.ssh"
      NEW_KEY_PATH="$HOME/.ssh/id_ed25519"
      echo -e "${CYAN}Generating new Ed25519 key at $NEW_KEY_PATH...${RESET}"
      if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "${YELLOW}[dry-run] Would execute: ssh-keygen -t ed25519 -C \"$GIT_EMAIL\" -f \"$NEW_KEY_PATH\"${RESET}"
        KEY_PATH="${NEW_KEY_PATH}.pub"
      else
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$NEW_KEY_PATH"
        KEY_PATH="${NEW_KEY_PATH}.pub"
        echo -e "  ${GREEN}✓${RESET} Key generated: $KEY_PATH"
      fi
    else
      echo -e "${YELLOW}Please enter the full path to your public SSH key:${RESET}"
      read -r -p "Key path: " MANUAL_KEY
      KEY_PATH=$(expand_path "$MANUAL_KEY")
      if [[ ! -f "$KEY_PATH" ]]; then
        echo -e "${RED}[error] File does not exist: $KEY_PATH${RESET}" >&2
        exit 1
      fi
    fi
  elif [[ ${#MAPFILE_KEYS[@]} -eq 1 && $NON_INTERACTIVE -eq 1 ]]; then
    KEY_PATH="${MAPFILE_KEYS[0]}"
  else
    echo -e "${WHITE}Available SSH Public Keys:${RESET}"
    idx=1
    for k in "${MAPFILE_KEYS[@]}"; do
      key_type="Unknown"
      if [[ "$k" == *"ed25519"* ]]; then
        key_type="Ed25519 (Recommended)"
      elif [[ "$k" == *"rsa"* ]]; then
        key_type="RSA"
      elif [[ "$k" == *"ecdsa"* ]]; then
        key_type="ECDSA"
      fi
      echo -e "  ${BOLD}${CYAN}[$idx]${RESET} $k ${MAGENTA}($key_type)${RESET}"
      ((idx++))
    done
    echo -e "  ${BOLD}${CYAN}[$idx]${RESET} Specify custom path"
    custom_idx=$idx
    ((idx++))
    echo -e "  ${BOLD}${CYAN}[$idx]${RESET} Generate a new Ed25519 key"
    gen_idx=$idx

    echo
    while true; do
      read -r -p "$(echo -e "${YELLOW}Select a key [1-${#MAPFILE_KEYS[@]}, default: 1]: ${RESET}")" CHOICE
      CHOICE="${CHOICE:-1}"
      if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#MAPFILE_KEYS[@]}" ]; then
        KEY_PATH="${MAPFILE_KEYS[$((CHOICE - 1))]}"
        break
      elif [[ "$CHOICE" == "$custom_idx" ]]; then
        read -r -p "$(echo -e "${YELLOW}Enter path to your public key (.pub): ${RESET}")" CUSTOM_P
        KEY_PATH=$(expand_path "$CUSTOM_P")
        if [[ -f "$KEY_PATH" ]]; then
          break
        else
          echo -e "${RED}File does not exist: $KEY_PATH${RESET}"
        fi
      elif [[ "$CHOICE" == "$gen_idx" ]]; then
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        NEW_KEY_PATH="$HOME/.ssh/id_ed25519"
        if [[ -f "$NEW_KEY_PATH" ]]; then
          NEW_KEY_PATH="$HOME/.ssh/id_ed25519_signing_$(date +%s)"
        fi
        echo -e "${CYAN}Generating new Ed25519 key at $NEW_KEY_PATH...${RESET}"
        if [[ $DRY_RUN -eq 1 ]]; then
          echo -e "${YELLOW}[dry-run] Would execute: ssh-keygen -t ed25519 -C \"$GIT_EMAIL\" -f \"$NEW_KEY_PATH\"${RESET}"
          KEY_PATH="${NEW_KEY_PATH}.pub"
        else
          ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$NEW_KEY_PATH"
          KEY_PATH="${NEW_KEY_PATH}.pub"
          echo -e "  ${GREEN}✓${RESET} Key generated: $KEY_PATH"
        fi
        break
      else
        echo -e "${RED}Invalid selection. Please choose an option between 1 and $gen_idx.${RESET}"
      fi
    done
  fi
fi

# Ensure key is a public key
if [[ "$KEY_PATH" != *".pub" ]] && [[ -f "${KEY_PATH}.pub" ]]; then
  echo -e "${YELLOW}[note] Switching to public key counterpart: ${KEY_PATH}.pub${RESET}"
  KEY_PATH="${KEY_PATH}.pub"
fi

echo -e "  ${GREEN}✓${RESET} Selected Signing Key: ${BOLD}$KEY_PATH${RESET}"
echo

# -------------------------------------------------------------
# STEP 4: Signing options
# -------------------------------------------------------------
echo -e "${CYAN}${BOLD}▶ Step 3: Automatic Commit Signing Options${RESET}"

if [[ $NON_INTERACTIVE -eq 0 && -z "${ARG_NAME:-}" ]]; then
  read -r -p "$(echo -e "${YELLOW}Automatically sign all future commits (commit.gpgsign true)? [Y/n]: ${RESET}")" SIGN_INPUT
  SIGN_INPUT="${SIGN_INPUT:-y}"
  if [[ "$SIGN_INPUT" =~ ^[Yy]$ ]]; then
    AUTO_SIGN=1
  else
    AUTO_SIGN=0
  fi

  read -r -p "$(echo -e "${YELLOW}Configure local signature verification trust (~/.config/git/allowed_signers)? [Y/n]: ${RESET}")" TRUST_INPUT
  TRUST_INPUT="${TRUST_INPUT:-y}"
  if [[ "$TRUST_INPUT" =~ ^[Yy]$ ]]; then
    SETUP_TRUST=1
  else
    SETUP_TRUST=0
  fi
fi

echo -e "  ${GREEN}✓${RESET} Automatic commit signing : $( [[ $AUTO_SIGN -eq 1 ]] && echo -e "${BOLD}${GREEN}Enabled${RESET}" || echo -e "${YELLOW}Disabled${RESET}" )"
echo -e "  ${GREEN}✓${RESET} Local verification trust : $( [[ $SETUP_TRUST -eq 1 ]] && echo -e "${BOLD}${GREEN}Enabled${RESET}" || echo -e "${YELLOW}Disabled${RESET}" )"
echo

# -------------------------------------------------------------
# APPLY CONFIGURATIONS
# -------------------------------------------------------------
echo -e "${CYAN}${BOLD}▶ Step 4: Applying Git Global Configuration${RESET}"
echo

apply_git_config() {
  local key="$1"
  local val="$2"
  if [[ $DRY_RUN -eq 1 ]]; then
    echo -e "  ${YELLOW}[dry-run] git config --global $key \"$val\"${RESET}"
  else
    git config --global "$key" "$val"
    echo -e "  ${GREEN}✓${RESET} Configured ${BOLD}$key${RESET} = $val"
  fi
}

# 1. Set user.name & user.email
apply_git_config "user.name" "$GIT_NAME"
apply_git_config "user.email" "$GIT_EMAIL"

# 2. Set gpg.format ssh
apply_git_config "gpg.format" "ssh"

# 3. Set user.signingkey
apply_git_config "user.signingkey" "$KEY_PATH"

# 4. Set commit.gpgsign
if [[ $AUTO_SIGN -eq 1 ]]; then
  apply_git_config "commit.gpgsign" "true"
else
  apply_git_config "commit.gpgsign" "false"
fi

# 5. Set up allowed_signers for local trust (gpg.ssh.allowedSignersFile)
if [[ $SETUP_TRUST -eq 1 && -f "$KEY_PATH" ]]; then
  ALLOWED_FILE="$HOME/.config/git/allowed_signers"
  PUB_CONTENT=$(cat "$KEY_PATH" 2>/dev/null || echo "")

  if [[ -n "$PUB_CONTENT" ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      echo -e "  ${YELLOW}[dry-run] Add entry to $ALLOWED_FILE:${RESET}"
      echo -e "    $GIT_EMAIL $PUB_CONTENT"
      echo -e "  ${YELLOW}[dry-run] git config --global gpg.ssh.allowedSignersFile \"$ALLOWED_FILE\"${RESET}"
    else
      mkdir -p "$(dirname "$ALLOWED_FILE")"
      touch "$ALLOWED_FILE"

      # Check if this exact key is already present in allowed_signers
      KEY_DATA=$(awk '{print $2}' "$KEY_PATH" 2>/dev/null || echo "")
      if [[ -n "$KEY_DATA" ]] && grep -Fq "$KEY_DATA" "$ALLOWED_FILE" 2>/dev/null; then
        echo -e "  ${BLUE}[i]${RESET} Key already exists in $ALLOWED_FILE"
      else
        echo "$GIT_EMAIL $PUB_CONTENT" >> "$ALLOWED_FILE"
        echo -e "  ${GREEN}✓${RESET} Added identity to ${BOLD}$ALLOWED_FILE${RESET}"
      fi

      git config --global gpg.ssh.allowedSignersFile "$ALLOWED_FILE"
      echo -e "  ${GREEN}✓${RESET} Configured ${BOLD}gpg.ssh.allowedSignersFile${RESET} = $ALLOWED_FILE"
    fi
  fi
fi

echo

# -------------------------------------------------------------
# STEP 5: Verification & Current Settings
# -------------------------------------------------------------
echo -e "${CYAN}${BOLD}▶ Step 5: Verification & Status Summary${RESET}"
echo

if [[ $DRY_RUN -eq 0 ]]; then
  echo -e "${WHITE}Active Git Signing Configuration:${RESET}"
  git config --global --get-regexp '^(user\.(name|email|signingkey)|gpg\.(format|ssh)|commit\.gpgsign)' 2>/dev/null | while read -r line; do
    echo -e "  ${GREEN}•${RESET} ${CYAN}${line%% *}${RESET} = ${line#* }"
  done
  echo
fi

# Check GitHub SSH authentication status
echo -e "${WHITE}Checking GitHub SSH connection status...${RESET}"
SSH_TEST_OUTPUT=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 || true)

if echo "$SSH_TEST_OUTPUT" | grep -q "successfully authenticated"; then
  GH_USER=$(echo "$SSH_TEST_OUTPUT" | grep -oP "Hi \K[^!]+" || echo "user")
  echo -e "  ${GREEN}✓${RESET} SSH connection to GitHub succeeded (Authenticated as ${BOLD}${GREEN}$GH_USER${RESET})"
else
  echo -e "  ${YELLOW}⚠${RESET} GitHub SSH not yet authenticated or key not registered with GitHub."
fi
echo

# -------------------------------------------------------------
# STEP 6: Public Key & GitHub Instructions
# -------------------------------------------------------------
if [[ -f "$KEY_PATH" ]]; then
  PUB_KEY_DATA=$(cat "$KEY_PATH")

  echo -e "╔═══════════════════════════════════════════════════════════════════════╗"
  echo -e "║                 ${YELLOW}${BOLD}YOUR PUBLIC SSH KEY (FOR GITHUB)${CYAN}                    ║"
  echo -e "╚═══════════════════════════════════════════════════════════════════════╝"
  echo -e "${GREEN}${BOLD}$PUB_KEY_DATA${RESET}"
  echo

  # Clipboard integration
  COPIED=0
  if command -v wl-copy >/dev/null 2>&1; then
    wl-copy < "$KEY_PATH" 2>/dev/null && COPIED=1
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard < "$KEY_PATH" 2>/dev/null && COPIED=1
  elif command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "$KEY_PATH" 2>/dev/null && COPIED=1
  fi

  if [[ $COPIED -eq 1 ]]; then
    echo -e "  ${GREEN}✨ Public key automatically copied to your clipboard!${RESET}"
    echo
  fi

  echo -e "${CYAN}${BOLD}Action Required on GitHub:${RESET}"
  echo -e "  1. Open: ${BLUE}${BOLD}https://github.com/settings/keys${RESET}"
  echo -e "  2. Click ${BOLD}'New SSH key'${RESET}"
  echo -e "  3. In Title, enter a name (e.g. ${CYAN}\"$(hostname) Signing Key\"${RESET})"
  echo -e "  4. In Key type, select: ${MAGENTA}${BOLD}Signing Key${RESET}  ${YELLOW}← IMPORTANT for Verified badge!${RESET}"
  echo -e "  5. Paste your key and click ${BOLD}'Add SSH key'${RESET}"
  echo
  echo -e "  ${BLUE}Note:${RESET} If you also want to push/pull repositories via this same key,"
  echo -e "  add it a second time with Key type set to ${BOLD}Authentication Key${RESET}."
  echo
fi

echo -e "${CYAN}${BOLD}Testing Your Signed Commits:${RESET}"
echo -e "  In any git repository, make a commit:"
echo -e "    ${WHITE}$ git commit -m \"Test signed commit\"${RESET}"
echo -e "  Then verify your signature with:"
echo -e "    ${WHITE}$ git log -1 --show-signature${RESET}"
echo
echo -e "${GREEN}${BOLD}✔ Git SSH signing setup complete!${RESET}"
echo
