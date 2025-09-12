#!/usr/bin/env bash
# backup_credentials.sh
# Safely back up developer credentials and auth material.
# Supported items (all optional, discovered automatically):
# - SSH: ~/.ssh (keys, config, known_hosts) with strict filtering
# - GPG: exported public/secret keys + ownertrust (ASCII armored)
# - GitHub CLI: ~/.config/gh/hosts.yml
# - Git: ~/.gitconfig, ~/.git-credentials (if present)
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
#                           [--include-vscode] [--outdir <dir>] [--dry-run]
#
# SECURITY WARNINGS:
# - Handle the resulting archive as HIGHLY SENSITIVE (contains private keys).
# - Store offline or on an encrypted volume. Do NOT commit anywhere.
# - Prefer encryption options; plain tar is for temporary/air-gapped use only.

set -euo pipefail
shopt -s nullglob

ENCRYPT_MODE="symmetric"   # default to symmetric encryption
RECIPIENT=""
INCLUDE_VSCODE=0
OUT_ROOT="$HOME/secure-backups"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --encrypt-symmetric) ENCRYPT_MODE="symmetric"; shift ;;
    --encrypt-recipient) ENCRYPT_MODE="recipient"; RECIPIENT="${2:-}"; shift 2 ;;
    --no-encrypt)        ENCRYPT_MODE="none"; shift ;;
    --include-vscode)    INCLUDE_VSCODE=1; shift ;;
    --outdir)            OUT_ROOT="${2:-}"; shift 2 ;;
    --dry-run)           DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '1,120p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

TS=$(date +%Y%m%d-%H%M%S)
OUT_DIR="$OUT_ROOT/$TS"
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

# 3) GitHub CLI auth
if [[ -f "$HOME/.config/gh/hosts.yml" ]]; then
  echo "[info] Backing up GitHub CLI tokens (~/.config/gh/hosts.yml)"
  mkdir -p "$WORK_DIR/gh"
  cp -f "$HOME/.config/gh/hosts.yml" "$WORK_DIR/gh/" || true
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

# 5) VS Code settings (OPTIONAL, no login tokens)
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

# Create latest symlink
ln -sfn "$OUT_DIR" "$OUT_ROOT/latest" || true

echo "[done] Credentials backup complete: $OUT_DIR"
echo "[info] Latest backup symlink: $OUT_ROOT/latest"

