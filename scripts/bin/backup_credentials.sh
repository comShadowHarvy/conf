#!/usr/bin/env bash
# backup_credentials.sh
# Safely back up developer credentials and auth material.
# Supported items (all optional, discovered automatically):
# - SSH: ~/.ssh (keys, config, known_hosts) with strict filtering
# - GPG: exported public/secret keys + ownertrust (ASCII armored)
# - GitHub CLI: ~/.config/gh/hosts.yml and config.yml
# - Git: ~/.gitconfig, ~/.git-credentials (if present)
# - System Keyring: ~/.local/share/keyrings (GNOME Keyring, etc.; highly sensitive)
# - Docker/Podman: ~/.docker/config.json, ~/.config/containers/auth.json
# - AWS: ~/.aws/ (credentials, config, etc.)
# - Kubernetes: ~/.kube/config
# - Package Managers: npm (~/.npmrc), PyPI (~/.pypirc), Cargo (~/.cargo/credentials*)
# - Misc: ~/.netrc
# - VS Code settings: ~/.config/Code/User (settings.json, keybindings.json, snippets)
#
# OUTPUT: A timestamped directory under ~/secure-backups/YYYYmmdd-HHMMSS containing
#         files and a consolidated credentials.tar(.gpg) archive
#
# ENCRYPTION:
#   --encrypt-symmetric           Encrypt archive with a passphrase (GPG symmetric)
#   --encrypt-recipient <USERID>  Encrypt to a GPG recipient (your key ID/email)
#   --no-encrypt                  Do not encrypt (NOT RECOMMENDED)
#
# USAGE:
#   ./backup_credentials.sh [--encrypt-symmetric | --encrypt-recipient <id> | --no-encrypt]
#                           [--include-vscode] [--outdir <dir>] [--dest <dir>] [--dry-run]
#
# --outdir: Creates $DIR/YYYYmmdd-HHMMSS/ (original standalone mode)
# --dest: Creates $DEST/credentials/ (centralized mode - no timestamp subdirectory)
#
# SECURITY WARNINGS:
# - Handle the resulting archive as HIGHLY SENSITIVE (contains private keys).
# - Store offline or on an encrypted volume. Do NOT commit anywhere.
# - Prefer encryption options; plain tar is for temporary/air-gapped use only.
# - Keyring backups are machine-specific and may not restore cleanly on different systems.

set -euo pipefail
shopt -s nullglob
umask 077  # Ensure no world-readable files/directories are created

ENCRYPT_MODE="symmetric"   # default to symmetric encryption
RECIPIENT=""
INCLUDE_VSCODE=0
OUT_ROOT="$HOME/secure-backups"
CENTRALIZED_MODE=0
DEST_DIR=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --encrypt-symmetric) ENCRYPT_MODE="symmetric"; shift ;;
    --encrypt-recipient) ENCRYPT_MODE="recipient"; RECIPIENT="${2:-}"; shift 2 ;;
    --no-encrypt)        ENCRYPT_MODE="none"; shift ;;
    --include-vscode)    INCLUDE_VSCODE=1; shift ;;
    --outdir)            OUT_ROOT="${2:-}"; shift 2 ;;
    --dest)              DEST_DIR="${2:-}"; CENTRALIZED_MODE=1; shift 2 ;;
    --dry-run)           DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '1,120p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Set output directory based on mode
if [[ $CENTRALIZED_MODE -eq 1 ]]; then
  OUT_DIR="$DEST_DIR/credentials"
  TS="centralized-$(date +%Y%m%d-%H%M%S)"
else
  TS=$(date +%Y%m%d-%H%M%S)
  OUT_DIR="$OUT_ROOT/$TS"
fi
ARCHIVE_NAME="credentials.tar"
ARCHIVE_PATH="$OUT_DIR/$ARCHIVE_NAME"

mkdir -p "$OUT_DIR"

echo "[info] Backup destination: $OUT_DIR"

# Gather lists
WORK_DIR="$OUT_DIR/collected"
mkdir -p "$WORK_DIR"

# 1) SSH (filter out sockets and agent files)
if [[ -d "$HOME/.ssh" ]]; then
  echo "[info] Collecting SSH material (~/.ssh)"
  mkdir -p "$WORK_DIR/ssh"
  # Keys: id_* plus any .pub, config, known_hosts, and custom keys (*.pem, *.key) if present
  # Exclude control sockets and random files
  rsync -a --chmod=Du=rwx,Dgo=,Fu=rw,Fgo= \
    --include='id_*' --include='*.pub' --include='config' --include='known_hosts' \
    --include='*.pem' --include='*.key' \
    --exclude='*/' --prune-empty-dirs "$HOME/.ssh/" "$WORK_DIR/ssh/" || true
fi

# 2) GPG Exports (prefer exporting rather than copying ~/.gnupg wholesale)
if command -v gpg >/dev/null 2>&1; then
  echo "[info] Exporting GPG public/secret keys and ownertrust"
  mkdir -p "$WORK_DIR/gpg"
  # Public keys
  gpg --export --armor > "$WORK_DIR/gpg/public_keys.asc" || true
  # Secret keys (you will be prompted for key passphrase(s) if applicable)
  gpg --export-secret-keys --armor > "$WORK_DIR/gpg/secret_keys.asc" || true
  # Ownertrust (so trust levels can be restored)
  gpg --export-ownertrust > "$WORK_DIR/gpg/ownertrust.txt" || true
fi

# 3) GitHub CLI auth (hosts.yml and config.yml)
if [[ -d "$HOME/.config/gh" ]]; then
  GH_HAS_FILES=0
  [[ -f "$HOME/.config/gh/hosts.yml" ]] && GH_HAS_FILES=1
  [[ -f "$HOME/.config/gh/config.yml" ]] && GH_HAS_FILES=1
  
  if [[ $GH_HAS_FILES -eq 1 ]]; then
    echo "[info] Backing up GitHub CLI configuration (~/.config/gh/)"
    mkdir -p "$WORK_DIR/gh"
    
    if [[ -f "$HOME/.config/gh/hosts.yml" ]]; then
      cp -f "$HOME/.config/gh/hosts.yml" "$WORK_DIR/gh/" || true
    fi
    
    if [[ -f "$HOME/.config/gh/config.yml" ]]; then
      cp -f "$HOME/.config/gh/config.yml" "$WORK_DIR/gh/" || true
    fi
  fi
fi

# 4) Git configs/credentials
if [[ -f "$HOME/.gitconfig" ]]; then
  echo "[info] Backing up ~/.gitconfig"
  cp -f "$HOME/.gitconfig" "$WORK_DIR/" || true
fi
if [[ -f "$HOME/.git-credentials" ]]; then
  echo "[info] Backing up ~/.git-credentials (PLAINTEXT TOKENS)"
  cp -f "$HOME/.git-credentials" "$WORK_DIR/" || true
fi

# 5) System Keyring (GNOME Keyring, KWallet, etc.)
if [[ -d "$HOME/.local/share/keyrings" ]]; then
  echo "[info] Backing up system keyring (~/.local/share/keyrings)"
  echo "[warn] Keyring data is machine/user specific and may not restore on different systems"
  mkdir -p "$WORK_DIR/keyrings"
  rsync -aH "$HOME/.local/share/keyrings/" "$WORK_DIR/keyrings/" || true
fi

# 6) Docker/Podman registry auth
if [[ -f "$HOME/.docker/config.json" ]]; then
  echo "[info] Backing up Docker registry auth (~/.docker/config.json)"
  mkdir -p "$WORK_DIR/docker"
  cp -f "$HOME/.docker/config.json" "$WORK_DIR/docker/" || true
fi
if [[ -f "$HOME/.config/containers/auth.json" ]]; then
  echo "[info] Backing up Podman registry auth (~/.config/containers/auth.json)"
  mkdir -p "$WORK_DIR/containers"
  cp -f "$HOME/.config/containers/auth.json" "$WORK_DIR/containers/" || true
fi

# 7) AWS credentials and config
if [[ -d "$HOME/.aws" ]]; then
  echo "[info] Backing up AWS credentials (~/.aws)"
  mkdir -p "$WORK_DIR/aws"
  rsync -a "$HOME/.aws/" "$WORK_DIR/aws/" || true
fi

# 8) Kubernetes config
if [[ -f "$HOME/.kube/config" ]]; then
  echo "[info] Backing up Kubernetes config (~/.kube/config)"
  mkdir -p "$WORK_DIR/kube"
  cp -f "$HOME/.kube/config" "$WORK_DIR/kube/" || true
fi

# 9) Package manager credentials
# npm
if [[ -f "$HOME/.npmrc" ]]; then
  echo "[info] Backing up npm config (~/.npmrc)"
  mkdir -p "$WORK_DIR/package-managers"
  cp -f "$HOME/.npmrc" "$WORK_DIR/package-managers/" || true
fi
if [[ -f "$HOME/.config/npm/npmrc" ]]; then
  echo "[info] Backing up npm config (~/.config/npm/npmrc)"
  mkdir -p "$WORK_DIR/package-managers/npm"
  cp -f "$HOME/.config/npm/npmrc" "$WORK_DIR/package-managers/npm/" || true
fi

# PyPI
if [[ -f "$HOME/.pypirc" ]]; then
  echo "[info] Backing up PyPI config (~/.pypirc)"
  mkdir -p "$WORK_DIR/package-managers"
  cp -f "$HOME/.pypirc" "$WORK_DIR/package-managers/" || true
fi

# Cargo/Rust
if [[ -f "$HOME/.cargo/credentials" ]]; then
  echo "[info] Backing up Cargo credentials (~/.cargo/credentials)"
  mkdir -p "$WORK_DIR/package-managers/cargo"
  cp -f "$HOME/.cargo/credentials" "$WORK_DIR/package-managers/cargo/" || true
fi
if [[ -f "$HOME/.cargo/credentials.toml" ]]; then
  echo "[info] Backing up Cargo credentials (~/.cargo/credentials.toml)"
  mkdir -p "$WORK_DIR/package-managers/cargo"
  cp -f "$HOME/.cargo/credentials.toml" "$WORK_DIR/package-managers/cargo/" || true
fi

# 10) .netrc
if [[ -f "$HOME/.netrc" ]]; then
  echo "[info] Backing up .netrc (~/.netrc)"
  cp -f "$HOME/.netrc" "$WORK_DIR/" || true
fi

# 11) VS Code settings (OPTIONAL, no login tokens)
if [[ $INCLUDE_VSCODE -eq 1 ]]; then
  VSC_USER_DIR="$HOME/.config/Code/User"
  if [[ -d "$VSC_USER_DIR" ]]; then
    echo "[info] Backing up VS Code user settings/snippets"
    mkdir -p "$WORK_DIR/vscode/User"
    for f in settings.json keybindings.json; do
      [[ -f "$VSC_USER_DIR/$f" ]] && cp -f "$VSC_USER_DIR/$f" "$WORK_DIR/vscode/User/" || true
    done
    if [[ -d "$VSC_USER_DIR/snippets" ]]; then
      mkdir -p "$WORK_DIR/vscode/User/snippets"
      rsync -a "$VSC_USER_DIR/snippets/" "$WORK_DIR/vscode/User/snippets/" || true
    fi
  fi
fi

# Summary manifest
{
  echo "Backup timestamp: $TS"
  echo "Host: $(hostname)"
  echo "User: $USER"
  echo "Collected paths:"
  find "$WORK_DIR" -type f | sed "s#^$WORK_DIR/##" || true
} > "$OUT_DIR/MANIFEST.txt"

# Create tar
if [[ $DRY_RUN -eq 1 ]]; then
  echo "[dry-run] Would create archive: $ARCHIVE_PATH"
else
  echo "[info] Creating archive: $ARCHIVE_PATH"
  (cd "$WORK_DIR" && tar -cf "$ARCHIVE_PATH" .)
fi

# Encrypt if requested
case "$ENCRYPT_MODE" in
  symmetric)
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] Would GPG-symmetric encrypt: $ARCHIVE_PATH.gpg"
    else
      echo "[info] Encrypting archive symmetrically (you will be prompted for a passphrase)"
      gpg --symmetric --cipher-algo AES256 "$ARCHIVE_PATH"
      shred -u "$ARCHIVE_PATH" || true
      ARCHIVE_PATH+=".gpg"
    fi
    ;;
  recipient)
    if [[ -z "$RECIPIENT" ]]; then
      echo "[error] --encrypt-recipient requires a recipient (key ID/email)." >&2
      exit 1
    fi
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] Would GPG-encrypt to recipient '$RECIPIENT': $ARCHIVE_PATH.gpg"
    else
      echo "[info] Encrypting archive to recipient: $RECIPIENT"
      gpg --encrypt --recipient "$RECIPIENT" "$ARCHIVE_PATH"
      shred -u "$ARCHIVE_PATH" || true
      ARCHIVE_PATH+=".gpg"
    fi
    ;;
  none)
    echo "[warn] Producing UNENCRYPTED archive. Handle with EXTREME CARE: $ARCHIVE_PATH"
    ;;
esac

# Permissions tightening on collected materials
chmod -R go-rwx "$OUT_DIR" || true

cat > "$OUT_DIR/README.txt" <<EOF
SECURE CREDENTIALS BACKUP ($TS)

This directory contains a highly sensitive backup of your credentials.

CONTENTS:
- MANIFEST.txt: summary of collected files
- collected/: raw gathered materials (SSH, GPG exports, etc.)
- $ARCHIVE_NAME$( [[ "$ENCRYPT_MODE" != "none" ]] && echo ".gpg" ): consolidated archive (prefer this file)

RESTORE:
  ./restore_credentials.sh -f "$ARCHIVE_PATH"  # decrypts if .gpg

SECURITY:
- Store offline (USB) or on an encrypted volume.
- Do not upload to cloud without strong encryption.
- Consider removing collected/ after verifying the encrypted archive.
EOF

# Create latest symlink (standalone mode only)
if [[ $CENTRALIZED_MODE -eq 0 ]]; then
  ln -sfn "$OUT_DIR" "$OUT_ROOT/latest" || true
fi

echo "[done] Credentials backup complete: $OUT_DIR"
echo "[info] Latest backup symlink: $OUT_ROOT/latest"

