#!/usr/bin/env bash
# restore_credentials.sh  
# Restore credentials from backup created by backup_credentials.sh
# USAGE:
#   ./restore_credentials.sh -f <archive_path> [--dry-run] [--skip-ssh] [--skip-gpg]
#   ./restore_credentials.sh -d <backup_directory> [options]
#
# OPTIONS:
#   -f, --file <path>     Restore from specific archive (.tar or .tar.gpg)
#   -d, --dir <path>      Restore from backup directory (uses collected/ subdir)
#   --dry-run             Show what would be restored without making changes
#   --skip-ssh            Don't restore SSH keys/config
#   --skip-gpg            Don't import GPG keys
#   --skip-git            Don't restore git configs
#   --skip-github         Don't restore GitHub CLI tokens
#   --skip-vscode         Don't restore VS Code settings
#   --add-ssh-keys        Automatically add SSH keys to agent after restore
#   --no-ssh-agent        Don't automatically add SSH keys to agent
#
# SECURITY WARNINGS:
# - This restores private keys and tokens to your home directory.
# - Ensure the source archive is trusted and from your own backup.
# - SSH keys will be restored with proper restrictive permissions (600/700).

set -euo pipefail
shopt -s nullglob

ARCHIVE_FILE=""
BACKUP_DIR=""
DRY_RUN=0
SKIP_SSH=0
SKIP_GPG=0
SKIP_GIT=0
SKIP_GITHUB=0
SKIP_VSCODE=0
ADD_SSH_KEYS=1
NO_SSH_AGENT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--file)        ARCHIVE_FILE="${2:-}"; shift 2 ;;
    -d|--dir)         BACKUP_DIR="${2:-}"; shift 2 ;;
    --dry-run)        DRY_RUN=1; shift ;;
    --skip-ssh)       SKIP_SSH=1; shift ;;
    --skip-gpg)       SKIP_GPG=1; shift ;;
    --skip-git)       SKIP_GIT=1; shift ;;
    --skip-github)    SKIP_GITHUB=1; shift ;;
    --skip-vscode)    SKIP_VSCODE=1; shift ;;
    --add-ssh-keys)   ADD_SSH_KEYS=1; shift ;;
    --no-ssh-agent)   NO_SSH_AGENT=1; ADD_SSH_KEYS=0; shift ;;
    -h|--help)
      sed -n '1,30p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -n "$ARCHIVE_FILE" && -n "$BACKUP_DIR" ]]; then
  echo "[error] Specify either --file or --dir, not both." >&2
  exit 1
fi

if [[ -z "$ARCHIVE_FILE" && -z "$BACKUP_DIR" ]]; then
  # Default: try to find latest backup
  LATEST_BACKUP="$HOME/secure-backups/latest"
  if [[ -L "$LATEST_BACKUP" && -d "$LATEST_BACKUP" ]]; then
    BACKUP_DIR="$LATEST_BACKUP"
    echo "[info] Using latest backup: $BACKUP_DIR"
  else
    echo "[error] No archive specified and no latest backup found." >&2
    echo "Use: --file <archive.tar.gpg> or --dir <backup_directory>" >&2
    exit 1
  fi
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

# Extract or copy source material to work directory
if [[ -n "$ARCHIVE_FILE" ]]; then
  if [[ ! -f "$ARCHIVE_FILE" ]]; then
    echo "[error] Archive not found: $ARCHIVE_FILE" >&2
    exit 1
  fi
  
  echo "[info] Extracting archive: $ARCHIVE_FILE"
  
  if [[ "$ARCHIVE_FILE" == *.gpg ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] Would decrypt and extract: $ARCHIVE_FILE"
    else
      gpg --decrypt "$ARCHIVE_FILE" | tar -xf - -C "$WORK_DIR"
    fi
  else
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] Would extract: $ARCHIVE_FILE"  
    else
      tar -xf "$ARCHIVE_FILE" -C "$WORK_DIR"
    fi
  fi
  
elif [[ -n "$BACKUP_DIR" ]]; then
  COLLECTED_DIR="$BACKUP_DIR/collected"
  if [[ ! -d "$COLLECTED_DIR" ]]; then
    echo "[error] Collected directory not found: $COLLECTED_DIR" >&2
    exit 1
  fi
  echo "[info] Using backup directory: $COLLECTED_DIR"
  if [[ $DRY_RUN -eq 0 ]]; then
    rsync -a "$COLLECTED_DIR/" "$WORK_DIR/"
  fi
fi

# Function to activate SSH keys in agent
activate_ssh_keys() {
  if [[ $ADD_SSH_KEYS -eq 0 || $NO_SSH_AGENT -eq 1 || $DRY_RUN -eq 1 ]]; then
    return 0
  fi
  
  # Check if SSH agent is available
  if ! command -v ssh-add >/dev/null 2>&1; then
    echo "[warn] ssh-add not found, skipping SSH key activation"
    return 0
  fi
  
  # Check if SSH agent is running or start it
  if [[ -z "$SSH_AUTH_SOCK" ]]; then
    echo "[info] Starting SSH agent..."
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      echo "[warn] Failed to start SSH agent, skipping key activation"
      return 0
    fi
  fi
  
  echo "[info] Adding SSH keys to agent..."
  
  # Find and add private SSH keys
  local added_count=0
  for key_file in "$HOME/.ssh"/id_*; do
    # Skip if it's a public key (.pub) or doesn't exist
    [[ -f "$key_file" && "$key_file" != *.pub ]] || continue
    
    # Try to add the key
    if ssh-add "$key_file" 2>/dev/null; then
      echo "[info] Added SSH key: $(basename "$key_file")"
      ((added_count++))
    else
      echo "[warn] Failed to add SSH key: $(basename "$key_file") (may require passphrase)"
    fi
  done
  
  if [[ $added_count -gt 0 ]]; then
    echo "[info] Successfully added $added_count SSH key(s) to agent"
    
    # List loaded keys
    echo "[info] Currently loaded SSH keys:"
    ssh-add -l 2>/dev/null || echo "  (No keys or agent not available)"
  else
    echo "[warn] No SSH keys were added to the agent"
  fi
}

# Function to safely restore file with backup
safe_restore() {
  local src="$1"
  local dest="$2" 
  local perms="${3:-}"
  
  if [[ ! -f "$src" ]]; then
    return 0
  fi
  
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] Would restore: $src -> $dest"
    return 0
  fi
  
  # Backup existing file if present
  if [[ -f "$dest" ]]; then
    echo "[info] Backing up existing: $dest -> $dest.backup-$(date +%s)"
    mv "$dest" "$dest.backup-$(date +%s)"
  fi
  
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  
  if [[ -n "$perms" ]]; then
    chmod "$perms" "$dest"
  fi
  
  echo "[info] Restored: $dest"
}

# 1) SSH Keys and Config
if [[ $SKIP_SSH -eq 0 && -d "$WORK_DIR/ssh" ]]; then
  echo "[info] Restoring SSH keys and configuration"
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  
  for f in "$WORK_DIR/ssh"/*; do
    [[ -f "$f" ]] || continue
    filename=$(basename "$f")
    
    # Determine appropriate permissions
    perms="600"
    if [[ "$filename" == *.pub ]]; then
      perms="644"
    elif [[ "$filename" == "config" ]]; then
      perms="600"
    elif [[ "$filename" == "known_hosts" ]]; then  
      perms="644"
    fi
    
    safe_restore "$f" "$HOME/.ssh/$filename" "$perms"
  done
  
  # Activate SSH keys if requested
  activate_ssh_keys
fi

# 2) GPG Keys
if [[ $SKIP_GPG -eq 0 && -d "$WORK_DIR/gpg" ]]; then
  echo "[info] Importing GPG keys"
  
  if [[ -f "$WORK_DIR/gpg/public_keys.asc" ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] Would import GPG public keys"
    else
      gpg --import "$WORK_DIR/gpg/public_keys.asc"
      echo "[info] Imported GPG public keys"
    fi
  fi
  
  if [[ -f "$WORK_DIR/gpg/secret_keys.asc" ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] Would import GPG secret keys" 
    else
      gpg --import "$WORK_DIR/gpg/secret_keys.asc"
      echo "[info] Imported GPG secret keys"
    fi
  fi
  
  if [[ -f "$WORK_DIR/gpg/ownertrust.txt" ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] Would restore GPG ownertrust"
    else
      gpg --import-ownertrust "$WORK_DIR/gpg/ownertrust.txt"
      echo "[info] Restored GPG ownertrust"
    fi
  fi
fi

# 3) Git Configuration
if [[ $SKIP_GIT -eq 0 ]]; then
  if [[ -f "$WORK_DIR/.gitconfig" ]]; then
    safe_restore "$WORK_DIR/.gitconfig" "$HOME/.gitconfig" "644"
  fi
  
  if [[ -f "$WORK_DIR/.git-credentials" ]]; then
    safe_restore "$WORK_DIR/.git-credentials" "$HOME/.git-credentials" "600"
  fi
fi

# 4) GitHub CLI
if [[ $SKIP_GITHUB -eq 0 && -f "$WORK_DIR/gh/hosts.yml" ]]; then
  safe_restore "$WORK_DIR/gh/hosts.yml" "$HOME/.config/gh/hosts.yml" "600"
fi

# 5) VS Code Settings
if [[ $SKIP_VSCODE -eq 0 && -d "$WORK_DIR/vscode" ]]; then
  echo "[info] Restoring VS Code settings"
  
  for f in "$WORK_DIR/vscode/User"/*.json; do
    [[ -f "$f" ]] || continue
    filename=$(basename "$f")
    safe_restore "$f" "$HOME/.config/Code/User/$filename" "644"
  done
  
  if [[ -d "$WORK_DIR/vscode/User/snippets" ]]; then
    mkdir -p "$HOME/.config/Code/User/snippets"
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] Would restore VS Code snippets"
    else
      rsync -a "$WORK_DIR/vscode/User/snippets/" "$HOME/.config/Code/User/snippets/"
      echo "[info] Restored VS Code snippets"  
    fi
  fi
fi

if [[ $DRY_RUN -eq 0 ]]; then
  echo "[done] Credential restore completed"
  echo "[info] You may need to:"
  if [[ $ADD_SSH_KEYS -eq 0 || $NO_SSH_AGENT -eq 1 ]]; then
    echo "  - Add SSH keys to agent: ssh-add ~/.ssh/id_*"
  fi
  echo "  - Test GitHub CLI: gh auth status"  
  echo "  - Verify GPG keys: gpg --list-keys"
  echo "  - Test SSH connection: ssh -T git@github.com"
else
  echo "[dry-run] Credential restore simulation completed"
  if [[ $ADD_SSH_KEYS -eq 1 && $NO_SSH_AGENT -eq 0 ]]; then
    echo "[dry-run] Would automatically add SSH keys to agent"
  fi
fi
