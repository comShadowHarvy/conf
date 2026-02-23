#!/usr/bin/env bash
# system_backup.sh
# Unified script to backup and restore system state, combining:
# - Secure Credentials (SSH, GPG, AWS, Keys, configs)
# - Git Repositories (list of paths and remotes)
# - Flatpak Apps (remotes and installed application lists)
show_title() {
  local title="$1"
  cat <<'EOF'
===================================================
   ____            _        _                 _
  / ___| _   _ ___| |_ __ _| | ___   __ _  __| |
  \\___ \\| | | / __| __/ _` | |/ _ \\ / _` |/ _` |
   ___) | |_| \\__ \\ || (_| | | (_) | (_| | (_| |
  |____/ \\__,_|___/\\__\\,_,_|_|\\___/ \\__,_|\\__,_|

  $title
  Author: ShadowHarvy
===================================================
EOF
}
fake_load() {
  local msg="$1"
  echo -n "[${msg}]"
  for i in {1..5}; do
    sleep 0.3
    echo -n "."
  done
  echo " done"
}

# USAGE:
#   system_backup.sh backup [options]
#   system_backup.sh restore [options]
#
# COMPRESSION: Archives are maximally compressed with `xz -9e`.
# ENCRYPTION: Backup archives can optionally be symmetrically or asymmetrically GPG encrypted.

set -euo pipefail
shopt -s nullglob
umask 077  # Ensure no world-readable files/directories are created

# === GLOBALS ===
COMMAND="${1:-}"
if [[ -n "$COMMAND" ]]; then shift; fi

# Backup Globals
ENCRYPT_MODE="symmetric"
RECIPIENT=""
INCLUDE_VSCODE=0
OUT_ROOT="$HOME/secure-backups"
DRY_RUN=0

# Restore Globals
ARCHIVE_FILE=""
BACKUP_DIR=""
SKIP_CREDENTIALS=0
SKIP_GITS=0
SKIP_FLATPAKS=0
# Granular credential skips
SKIP_SSH=0
SKIP_GPG=0
SKIP_GIT_CONFIG=0
SKIP_GITHUB=0
SKIP_VSCODE=0
SKIP_DOCKER=0
SKIP_AWS=0
SKIP_KUBE=0
SKIP_KEYRING=0
SKIP_GEMINI=0
SKIP_PACKAGE_MANAGERS=0
SKIP_ANI_CLI=0
SKIP_VIU_MEDIA=0
SKIP_KOMIKKU=0
ADD_SSH_KEYS=1
NO_SSH_AGENT=0

print_help() {
  cat << 'EOF'
system_backup.sh - Unified System Backup & Restore Tool

USAGE:
  system_backup.sh backup [OPTIONS]
  system_backup.sh restore [OPTIONS]

BACKUP OPTIONS:
  --encrypt-symmetric           Encrypt archive with a passphrase (GPG symmetric) [Default]
  --encrypt-recipient <USERID>  Encrypt to a GPG recipient (your key ID/email)
  --no-encrypt                  Do not encrypt (NOT RECOMMENDED for credentials)
  --include-vscode              Include VS Code settings and snippets
  --outdir <dir>                Destination directory for backups (Default: ~/secure-backups)
  --dry-run                     Simulate the backup process

RESTORE OPTIONS:
  -f, --file <path>             Restore from specific archive (.tar.xz or .tar.xz.gpg)
  -d, --dir <path>              Restore from extracted backup directory (the 'collected/' folder)
  --dry-run                     Show what would be restored without making changes
  
  --skip-credentials            Skip restoring ALL credentials
  --skip-gits                   Skip cloning back Git repositories
  --skip-flatpaks               Skip restoring Flatpak remotes and apps
  
  (Granular Credential Skips):
  --skip-ssh, --skip-gpg, --skip-git-config, --skip-github, --skip-vscode,
  --skip-docker, --skip-aws, --skip-kube, --skip-keyring, --skip-gemini,
  --skip-package-managers, --skip-ani-cli, --skip-viu-media, --skip-komikku
  
  --no-ssh-agent                Don't automatically add SSH keys to agent after restore

EOF
  exit 0
}

if [[ -z "$COMMAND" || "$COMMAND" == "-h" || "$COMMAND" == "--help" ]]; then
  print_help
fi

# ==========================================
#                 BACKUP
# ==========================================
do_backup() {
  show_title "System Backup"
  fake_load "Collecting credentials"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --encrypt-symmetric) ENCRYPT_MODE="symmetric"; shift ;;
      --encrypt-recipient) ENCRYPT_MODE="recipient"; RECIPIENT="${2:-}"; shift 2 ;;
      --no-encrypt)        ENCRYPT_MODE="none"; shift ;;
      --include-vscode)    INCLUDE_VSCODE=1; shift ;;
      --outdir)            OUT_ROOT="${2:-}"; shift 2 ;;
      --dry-run)           DRY_RUN=1; shift ;;
      *) echo "[error] Unknown option: $1" >&2; exit 1 ;;
    esac
  done

  TS=$(date +%Y%m%d-%H%M%S)
  ARCHIVE_NAME="system-backup-${TS}.tar.xz"
  ARCHIVE_PATH="$OUT_ROOT/$ARCHIVE_NAME"
  
  mkdir -p "$OUT_ROOT"
  
  # Temporary collection directory
  WORK_DIR=$(mktemp -d "/tmp/system_backup.XXXXXX")
  trap 'rm -rf "$WORK_DIR"' EXIT
  
  CRED_DIR="$WORK_DIR/credentials"
  FLAT_DIR="$WORK_DIR/flatpaks"
  mkdir -p "$CRED_DIR" "$FLAT_DIR"

  echo "========================================="
  echo "          COLLECTING CREDENTIALS         "
  echo "========================================="
  fake_load "Backing up credentials"
  
  # 1) SSH
  if [[ -d "$HOME/.ssh" ]]; then
    echo "[info] Collecting SSH material (~/.ssh)"
    mkdir -p "$CRED_DIR/ssh"
    rsync -a --chmod=Du=rwx,Dgo=,Fu=rw,Fgo= \
      --include='id_*' --include='*.pub' --include='config' --include='known_hosts' \
      --include='*.pem' --include='*.key' \
      --exclude='*/' --prune-empty-dirs "$HOME/.ssh/" "$CRED_DIR/ssh/" || true
  fi

  # 2) GPG
  if command -v gpg >/dev/null 2>&1; then
    echo "[info] Exporting GPG public/secret keys and ownertrust"
    mkdir -p "$CRED_DIR/gpg"
    gpg --export --armor > "$CRED_DIR/gpg/public_keys.asc" || true
    gpg --export-secret-keys --armor > "$CRED_DIR/gpg/secret_keys.asc" || true
    gpg --export-ownertrust > "$CRED_DIR/gpg/ownertrust.txt" || true
  fi

  # 3) GitHub CLI
  if [[ -d "$HOME/.config/gh" ]]; then
    echo "[info] Backing up GitHub CLI configuration (~/.config/gh/)"
    mkdir -p "$CRED_DIR/gh"
    [[ -f "$HOME/.config/gh/hosts.yml" ]] && cp -f "$HOME/.config/gh/hosts.yml" "$CRED_DIR/gh/" || true
    [[ -f "$HOME/.config/gh/config.yml" ]] && cp -f "$HOME/.config/gh/config.yml" "$CRED_DIR/gh/" || true
  fi

  # 4) Git Configs
  if [[ -f "$HOME/.gitconfig" ]]; then
    echo "[info] Backing up ~/.gitconfig"
    cp -f "$HOME/.gitconfig" "$CRED_DIR/" || true
  fi
  if [[ -f "$HOME/.git-credentials" ]]; then
    echo "[info] Backing up ~/.git-credentials"
    cp -f "$HOME/.git-credentials" "$CRED_DIR/" || true
  fi

  # 5) System Keyring
  if [[ -d "$HOME/.local/share/keyrings" ]]; then
    echo "[info] Backing up system keyring (~/.local/share/keyrings)"
    mkdir -p "$CRED_DIR/keyrings"
    rsync -aH "$HOME/.local/share/keyrings/" "$CRED_DIR/keyrings/" || true
  fi

  # 6) Docker/Podman
  if [[ -f "$HOME/.docker/config.json" ]]; then
    echo "[info] Backing up Docker registry auth"
    mkdir -p "$CRED_DIR/docker"
    cp -f "$HOME/.docker/config.json" "$CRED_DIR/docker/" || true
  fi
  if [[ -f "$HOME/.config/containers/auth.json" ]]; then
    echo "[info] Backing up Podman registry auth"
    mkdir -p "$CRED_DIR/containers"
    cp -f "$HOME/.config/containers/auth.json" "$CRED_DIR/containers/" || true
  fi

  # 7) AWS
  if [[ -d "$HOME/.aws" ]]; then
    echo "[info] Backing up AWS credentials"
    mkdir -p "$CRED_DIR/aws"
    rsync -a "$HOME/.aws/" "$CRED_DIR/aws/" || true
  fi

  # 8) Kubernetes
  if [[ -f "$HOME/.kube/config" ]]; then
    echo "[info] Backing up Kubernetes config"
    mkdir -p "$CRED_DIR/kube"
    cp -f "$HOME/.kube/config" "$CRED_DIR/kube/" || true
  fi

  # 9) Package Managers
  mkdir -p "$CRED_DIR/package-managers"
  [[ -f "$HOME/.npmrc" ]] && cp -f "$HOME/.npmrc" "$CRED_DIR/package-managers/" || true
  if [[ -f "$HOME/.config/npm/npmrc" ]]; then
    mkdir -p "$CRED_DIR/package-managers/npm"
    cp -f "$HOME/.config/npm/npmrc" "$CRED_DIR/package-managers/npm/" || true
  fi
  [[ -f "$HOME/.pypirc" ]] && cp -f "$HOME/.pypirc" "$CRED_DIR/package-managers/" || true
  if [[ -f "$HOME/.cargo/credentials" || -f "$HOME/.cargo/credentials.toml" ]]; then
    mkdir -p "$CRED_DIR/package-managers/cargo"
    [[ -f "$HOME/.cargo/credentials" ]] && cp -f "$HOME/.cargo/credentials" "$CRED_DIR/package-managers/cargo/" || true
    [[ -f "$HOME/.cargo/credentials.toml" ]] && cp -f "$HOME/.cargo/credentials.toml" "$CRED_DIR/package-managers/cargo/" || true
  fi

  # 10) .netrc
  [[ -f "$HOME/.netrc" ]] && cp -f "$HOME/.netrc" "$CRED_DIR/" || true

  # 11) VS Code
  if [[ $INCLUDE_VSCODE -eq 1 ]]; then
    VSC_USER_DIR="$HOME/.config/Code/User"
    if [[ -d "$VSC_USER_DIR" ]]; then
      echo "[info] Backing up VS Code user settings"
      mkdir -p "$CRED_DIR/vscode/User"
      [[ -f "$VSC_USER_DIR/settings.json" ]] && cp -f "$VSC_USER_DIR/settings.json" "$CRED_DIR/vscode/User/" || true
      [[ -f "$VSC_USER_DIR/keybindings.json" ]] && cp -f "$VSC_USER_DIR/keybindings.json" "$CRED_DIR/vscode/User/" || true
      if [[ -d "$VSC_USER_DIR/snippets" ]]; then
        mkdir -p "$CRED_DIR/vscode/User/snippets"
        rsync -a "$VSC_USER_DIR/snippets/" "$CRED_DIR/vscode/User/snippets/" || true
      fi
    fi
  fi

  # 12) Gemini CLI
  if [[ -d "$HOME/.gemini" ]]; then
    echo "[info] Backing up Gemini CLI config"
    mkdir -p "$CRED_DIR/gemini"
    rsync -a "$HOME/.gemini/" "$CRED_DIR/gemini/" || true
  fi

  # 13) ani-cli
  if [[ -d "$HOME/.local/state/ani-cli" ]]; then
    mkdir -p "$CRED_DIR/ani-cli/state"
    rsync -a "$HOME/.local/state/ani-cli/" "$CRED_DIR/ani-cli/state/" || true
  fi
  if [[ -d "$HOME/.config/ani-cli" ]]; then
    mkdir -p "$CRED_DIR/ani-cli/config"
    rsync -a "$HOME/.config/ani-cli/" "$CRED_DIR/ani-cli/config/" || true
  fi

  # 14) viu-media
  [[ -d "$HOME/.config/viu" ]] && rsync -a "$HOME/.config/viu/" "$CRED_DIR/viu/" || true
  [[ -d "$HOME/.config/viu-media" ]] && rsync -a "$HOME/.config/viu-media/" "$CRED_DIR/viu-media/" || true

  # 15) Komikku
  if [[ -d "$HOME/.config/komikku" ]]; then
    mkdir -p "$CRED_DIR/komikku/config"
    rsync -a "$HOME/.config/komikku/" "$CRED_DIR/komikku/config/" || true
  fi
  for db in "$HOME/.local/share/komikku/"*.db; do
    mkdir -p "$CRED_DIR/komikku/data"
    cp -f "$db" "$CRED_DIR/komikku/data/" || true
  done

  echo "========================================="
  echo "         COLLECTING GIT PROJECTS         "
  echo "========================================="
  fake_load "Backing up git repositories"
  GIT_ROOT="$HOME/git"
  GIT_BACKUP_FILE="$WORK_DIR/git_backup_list.txt"
  > "$GIT_BACKUP_FILE"
  
  if [[ -d "$GIT_ROOT" ]]; then
    for repo_dir in "$GIT_ROOT"/*; do
      if [ -d "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
        dir_name=$(basename "$repo_dir")
        if remote_url=$(git -C "$repo_dir" remote get-url origin 2>/dev/null); then
          echo "$dir_name $remote_url" >> "$GIT_BACKUP_FILE"
          echo "[info] Backed up git link: $dir_name -> $remote_url"
        else
          echo "[warn] No remote origin found for $dir_name"
        fi
      fi
    done
  else
    echo "[warn] Git root directory $GIT_ROOT not found."
  fi

  echo "========================================="
  echo "          COLLECTING FLATPAKS            "
  echo "========================================="
  fake_load "Backing up flatpaks"
  if command -v flatpak >/dev/null 2>&1; then
    echo "[info] Saving Flatpak remotes"
    echo -e "name\turl" > "$FLAT_DIR/remotes.tsv"
    flatpak remotes -d | tail -n +2 | while read -r name title url rest; do
      [[ -n "$name" && -n "$url" ]] && echo -e "$name\t$url" >> "$FLAT_DIR/remotes.tsv"
    done
    
    echo "[info] Saving Flatpak apps"
    {
      echo -e "application\tarch\tbranch\torigin\tinstallation"
      flatpak list --app --columns=application,arch,branch,origin,installation
    } > "$FLAT_DIR/apps.tsv"
    
    flatpak list --app --show-details > "$FLAT_DIR/apps.details.txt"
  else
    echo "[warn] flatpak CLI not found. Skipping."
  fi

  echo "========================================="
  echo "         CREATING MASTER ARCHIVE         "
  echo "========================================="
  fake_load "Compressing archive"
  
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] Would create maximum compressed archive: $ARCHIVE_PATH"
  else
    echo "[info] Compressing with xz -9e... This may take a moment."
    # Use max compression
    export XZ_OPT="-9e"
    (cd "$WORK_DIR" && tar -cJf "$ARCHIVE_PATH" .)
    echo "[info] Created archive: $ARCHIVE_PATH"
  fi

  case "$ENCRYPT_MODE" in
    symmetric)
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "[dry-run] Would GPG-symmetric encrypt: $ARCHIVE_PATH.gpg"
      else
        echo "[info] Encrypting archive symmetrically."
        gpg --symmetric --cipher-algo AES256 "$ARCHIVE_PATH"
        shred -u "$ARCHIVE_PATH" || true
        ARCHIVE_PATH+=".gpg"
        echo "[info] Final encrypted backup: $ARCHIVE_PATH"
      fi
      ;;
    recipient)
      if [[ -z "$RECIPIENT" ]]; then
        echo "[error] --encrypt-recipient requires a user ID." >&2; exit 1
      fi
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "[dry-run] Would GPG-encrypt to recipient '$RECIPIENT': $ARCHIVE_PATH.gpg"
      else
        echo "[info] Encrypting archive to recipient: $RECIPIENT"
        gpg --encrypt --recipient "$RECIPIENT" "$ARCHIVE_PATH"
        shred -u "$ARCHIVE_PATH" || true
        ARCHIVE_PATH+=".gpg"
        echo "[info] Final encrypted backup: $ARCHIVE_PATH"
      fi
      ;;
    none)
      echo "[warn] PRODUCED UNENCRYPTED ARCHIVE. Handle with extreme care: $ARCHIVE_PATH"
      ;;
  esac

  echo "[done] Backup phase completed successfully."
}

# ==========================================
#                 RESTORE
# ==========================================
do_restore() {
  show_title "System Restore"
  fake_load "Preparing restore"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--file)               ARCHIVE_FILE="${2:-}"; shift 2 ;;
      -d|--dir)                BACKUP_DIR="${2:-}"; shift 2 ;;
      --dry-run)               DRY_RUN=1; shift ;;
      --skip-credentials)      SKIP_CREDENTIALS=1; shift ;;
      --skip-gits)             SKIP_GITS=1; shift ;;
      --skip-flatpaks)         SKIP_FLATPAKS=1; shift ;;
      --skip-ssh)              SKIP_SSH=1; shift ;;
      --skip-gpg)              SKIP_GPG=1; shift ;;
      --skip-git-config)       SKIP_GIT_CONFIG=1; shift ;;
      --skip-github)           SKIP_GITHUB=1; shift ;;
      --skip-vscode)           SKIP_VSCODE=1; shift ;;
      --skip-docker)           SKIP_DOCKER=1; shift ;;
      --skip-aws)              SKIP_AWS=1; shift ;;
      --skip-kube)             SKIP_KUBE=1; shift ;;
      --skip-keyring)          SKIP_KEYRING=1; shift ;;
      --skip-gemini)           SKIP_GEMINI=1; shift ;;
      --skip-package-managers) SKIP_PACKAGE_MANAGERS=1; shift ;;
      --skip-ani-cli)          SKIP_ANI_CLI=1; shift ;;
      --skip-viu-media)        SKIP_VIU_MEDIA=1; shift ;;
      --skip-komikku)          SKIP_KOMIKKU=1; shift ;;
      --add-ssh-keys)          ADD_SSH_KEYS=1; shift ;;
      --no-ssh-agent)          NO_SSH_AGENT=1; ADD_SSH_KEYS=0; shift ;;
      *) echo "[error] Unknown option: $1" >&2; exit 1 ;;
    esac
  done

  if [[ -n "$ARCHIVE_FILE" && -n "$BACKUP_DIR" ]]; then
    echo "[error] Specify either --file or --dir, not both." >&2; exit 1
  fi
  if [[ -z "$ARCHIVE_FILE" && -z "$BACKUP_DIR" ]]; then
    echo "[error] Must specify backup source with -f <file> or -d <dir>." >&2; exit 1
  fi

  WORK_DIR=$(mktemp -d "/tmp/system_restore.XXXXXX")
  trap 'rm -rf "$WORK_DIR"' EXIT

  # Validate and extract
  if [[ -n "$ARCHIVE_FILE" ]]; then
    if [[ ! -f "$ARCHIVE_FILE" ]]; then
      echo "[error] Archive not found: $ARCHIVE_FILE" >&2; exit 1
    fi
    echo "[info] Extracting archive: $ARCHIVE_FILE"
    if [[ "$ARCHIVE_FILE" == *.gpg ]]; then
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "[dry-run] Would decrypt and extract: $ARCHIVE_FILE"
      else
        gpg --decrypt "$ARCHIVE_FILE" | tar -xJf - -C "$WORK_DIR"
      fi
    else
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "[dry-run] Would extract: $ARCHIVE_FILE"  
      else
        tar -xJf "$ARCHIVE_FILE" -C "$WORK_DIR"
      fi
    fi
  elif [[ -n "$BACKUP_DIR" ]]; then
    if [[ ! -d "$BACKUP_DIR" ]]; then
      echo "[error] Backup directory not found: $BACKUP_DIR" >&2; exit 1
    fi
    echo "[info] Copying from backup directory: $BACKUP_DIR"
    if [[ $DRY_RUN -eq 0 ]]; then
      rsync -a "$BACKUP_DIR/" "$WORK_DIR/"
    fi
  fi

  # Helper functions
  safe_restore() {
    local src="$1"
    local dest="$2" 
    local perms="${3:-}"
    [[ ! -f "$src" ]] && return 0
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] Would restore: $src -> $dest"
      return 0
    fi
    if [[ -f "$dest" ]]; then
      mv "$dest" "$dest.backup-$(date +%s)"
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    [[ -n "$perms" ]] && chmod "$perms" "$dest"
    echo "[info] Restored: $dest"
  }

  activate_ssh_keys() {
    [[ $ADD_SSH_KEYS -eq 0 || $NO_SSH_AGENT -eq 1 || $DRY_RUN -eq 1 ]] && return 0
    if ! command -v ssh-add >/dev/null 2>&1; then return 0; fi
    if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
      eval "$(ssh-agent -s)" >/dev/null 2>&1 || return 0
    fi
    echo "[info] Adding SSH keys to agent..."
    for key_file in "$HOME/.ssh"/id_*; do
      [[ -f "$key_file" && "$key_file" != *.pub ]] || continue
      ssh-add "$key_file" 2>/dev/null && echo "[info] Added $(basename "$key_file")" || true
    done
  }

  # --- A) RESTORE CREDENTIALS ---
  if [[ $SKIP_CREDENTIALS -eq 0 && -d "$WORK_DIR/credentials" ]]; then
    echo "========================================="
    echo "          RESTORING CREDENTIALS          "
    echo "========================================="
    fake_load "Restoring credentials"
    C_DIR="$WORK_DIR/credentials"

    if [[ $SKIP_SSH -eq 0 && -d "$C_DIR/ssh" ]]; then
      mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
      for f in "$C_DIR/ssh"/*; do
        [[ -f "$f" ]] || continue
        fn=$(basename "$f")
        perms="600"
        [[ "$fn" == *.pub || "$fn" == "known_hosts" ]] && perms="644"
        safe_restore "$f" "$HOME/.ssh/$fn" "$perms"
      done
      activate_ssh_keys
    fi

    if [[ $SKIP_GPG -eq 0 && -d "$C_DIR/gpg" ]]; then
      [[ -f "$C_DIR/gpg/public_keys.asc" && $DRY_RUN -eq 0 ]] && gpg --import "$C_DIR/gpg/public_keys.asc"
      [[ -f "$C_DIR/gpg/secret_keys.asc" && $DRY_RUN -eq 0 ]] && gpg --import "$C_DIR/gpg/secret_keys.asc"
      [[ -f "$C_DIR/gpg/ownertrust.txt" && $DRY_RUN -eq 0 ]] && gpg --import-ownertrust "$C_DIR/gpg/ownertrust.txt"
    fi

    if [[ $SKIP_GIT_CONFIG -eq 0 ]]; then
      safe_restore "$C_DIR/.gitconfig" "$HOME/.gitconfig" "644"
      safe_restore "$C_DIR/.git-credentials" "$HOME/.git-credentials" "600"
    fi

    if [[ $SKIP_GITHUB -eq 0 && -d "$C_DIR/gh" ]]; then
      mkdir -p "$HOME/.config/gh" && chmod 700 "$HOME/.config/gh"
      safe_restore "$C_DIR/gh/hosts.yml" "$HOME/.config/gh/hosts.yml" "600"
      safe_restore "$C_DIR/gh/config.yml" "$HOME/.config/gh/config.yml" "600"
    fi

    if [[ $SKIP_KEYRING -eq 0 && -d "$C_DIR/keyrings" ]]; then
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "[dry-run] Would restore system keyring to ~/.local/share/keyrings"
      else
        mkdir -p "$HOME/.local/share/keyrings"
        rsync -aH "$C_DIR/keyrings/" "$HOME/.local/share/keyrings/"
      fi
    fi

    if [[ $SKIP_DOCKER -eq 0 ]]; then
      safe_restore "$C_DIR/docker/config.json" "$HOME/.docker/config.json" "600"
      safe_restore "$C_DIR/containers/auth.json" "$HOME/.config/containers/auth.json" "600"
    fi

    if [[ $SKIP_AWS -eq 0 && -d "$C_DIR/aws" ]]; then
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "[dry-run] Would restore AWS credentials"
      else
        mkdir -p "$HOME/.aws" && chmod 700 "$HOME/.aws"
        rsync -a "$C_DIR/aws/" "$HOME/.aws/"
        [[ -f "$HOME/.aws/credentials" ]] && chmod 600 "$HOME/.aws/credentials"
        [[ -f "$HOME/.aws/config" ]] && chmod 644 "$HOME/.aws/config"
      fi
    fi

    if [[ $SKIP_KUBE -eq 0 ]]; then
      safe_restore "$C_DIR/kube/config" "$HOME/.kube/config" "600"
    fi

    if [[ $SKIP_PACKAGE_MANAGERS -eq 0 ]]; then
      safe_restore "$C_DIR/package-managers/.npmrc" "$HOME/.npmrc" "600"
      safe_restore "$C_DIR/package-managers/npm/npmrc" "$HOME/.config/npm/npmrc" "600"
      safe_restore "$C_DIR/package-managers/.pypirc" "$HOME/.pypirc" "600"
      safe_restore "$C_DIR/package-managers/cargo/credentials" "$HOME/.cargo/credentials" "600"
      safe_restore "$C_DIR/package-managers/cargo/credentials.toml" "$HOME/.cargo/credentials.toml" "600"
    fi

    safe_restore "$C_DIR/.netrc" "$HOME/.netrc" "600"

    if [[ $SKIP_VSCODE -eq 0 && -d "$C_DIR/vscode/User" ]]; then
      for f in "$C_DIR/vscode/User"/*.json; do
        [[ -f "$f" ]] || continue
        safe_restore "$f" "$HOME/.config/Code/User/$(basename "$f")" "644"
      done
      if [[ -d "$C_DIR/vscode/User/snippets" && $DRY_RUN -eq 0 ]]; then
        mkdir -p "$HOME/.config/Code/User/snippets"
        rsync -a "$C_DIR/vscode/User/snippets/" "$HOME/.config/Code/User/snippets/"
      fi
    fi

    if [[ $SKIP_GEMINI -eq 0 && -d "$C_DIR/gemini" ]]; then
      if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$HOME/.gemini" && chmod 700 "$HOME/.gemini"
        rsync -a "$C_DIR/gemini/" "$HOME/.gemini/"
        find "$HOME/.gemini" -type f -exec chmod 600 {} \; || true
        find "$HOME/.gemini" -type d -exec chmod 700 {} \; || true
      fi
    fi

    if [[ $SKIP_ANI_CLI -eq 0 && -d "$C_DIR/ani-cli" ]]; then
      if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$HOME/.local/state/ani-cli" "$HOME/.config/ani-cli"
        [[ -d "$C_DIR/ani-cli/state" ]] && rsync -a "$C_DIR/ani-cli/state/" "$HOME/.local/state/ani-cli/"
        [[ -d "$C_DIR/ani-cli/config" ]] && rsync -a "$C_DIR/ani-cli/config/" "$HOME/.config/ani-cli/"
      fi
    fi

    if [[ $SKIP_VIU_MEDIA -eq 0 ]]; then
      if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$HOME/.config/viu" "$HOME/.config/viu-media"
        [[ -d "$C_DIR/viu" ]] && rsync -a "$C_DIR/viu/" "$HOME/.config/viu/"
        [[ -d "$C_DIR/viu-media" ]] && rsync -a "$C_DIR/viu-media/" "$HOME/.config/viu-media/"
      fi
    fi

    if [[ $SKIP_KOMIKKU -eq 0 && -d "$C_DIR/komikku" ]]; then
      if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$HOME/.config/komikku" "$HOME/.local/share/komikku"
        [[ -d "$C_DIR/komikku/config" ]] && rsync -a "$C_DIR/komikku/config/" "$HOME/.config/komikku/"
        [[ -d "$C_DIR/komikku/data" ]] && cp -f "$C_DIR/komikku/data/"*.db "$HOME/.local/share/komikku/" 2>/dev/null || true
      fi
    fi
  
    echo "[done] Credentials restore completed."
  fi

  # --- B) RESTORE GITS ---
  if [[ $SKIP_GITS -eq 0 && -f "$WORK_DIR/git_backup_list.txt" ]]; then
    echo "========================================="
    echo "             RESTORING GITS              "
    echo "========================================="
    fake_load "Restoring git repositories"
    GIT_ROOT="$HOME/git"
    mkdir -p "$GIT_ROOT"
    
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] Would clone the repositories listed in git_backup_list.txt"
    else
      while read -r line; do
        [ -z "$line" ] && continue
        dir_name=$(echo "$line" | awk '{print $1}')
        remote_url=$(echo "$line" | awk '{print $2}')
        target_dir="$GIT_ROOT/$dir_name"
        
        if [[ -d "$target_dir" ]]; then
          echo "[info] Skipping existing repo: $dir_name"
        else
          echo "[info] Cloning $dir_name from $remote_url..."
          git clone "$remote_url" "$target_dir" || echo "[warn] Failed to clone $dir_name"
        fi
      done < "$WORK_DIR/git_backup_list.txt"
    fi
    echo "[done] Git restore completed."
  fi

  # --- C) RESTORE FLATPAKS ---
  if [[ $SKIP_FLATPAKS -eq 0 && -d "$WORK_DIR/flatpaks" ]]; then
    echo "========================================="
    echo "           RESTORING FLATPAKS            "
    echo "========================================="
    fake_load "Restoring flatpaks"
    if ! command -v flatpak >/dev/null 2>&1; then
      echo "[error] flatpak CLI not found. Can't restore flatpaks."
    else
      APPS_FILE="$WORK_DIR/flatpaks/apps.tsv"
      REMOTES_FILE="$WORK_DIR/flatpaks/remotes.tsv"
  
      if [[ -f "$REMOTES_FILE" && $DRY_RUN -eq 0 ]]; then
        tail -n +2 "$REMOTES_FILE" | while IFS=$'\t' read -r name url; do
          [[ -z "$name" || -z "$url" ]] && continue
          if flatpak remotes --columns=name | awk 'NR>1 {print $1}' | grep -qx "$name"; then
            echo "[info] Remote exists: $name"
          else
            echo "[info] Adding remote: $name ($url)"
            flatpak remote-add --gpg-verify "$name" "$url"
          fi
        done
      elif [[ $DRY_RUN -eq 1 ]]; then
        echo "[dry-run] Would add missing flatpak remotes."
      fi
  
      if [[ -f "$APPS_FILE" && $DRY_RUN -eq 0 ]]; then
        TOTAL=0; OK=0; FAIL=0
        while IFS=$'\t' read -r application arch branch origin installation; do
          if [[ "$application" == "application" || -z "$application" ]]; then continue; fi
          ((TOTAL++))
          INSTALL_OPT="--user"
          [[ "$installation" == "system" ]] && INSTALL_OPT="--system"
          REF="$application//${branch:-stable}"
          
          echo "-> Installing ($installation) $application (origin=$origin, branch=${branch:-stable})"
          if flatpak install -y $INSTALL_OPT "$origin" "$REF" >/dev/null; then
            ((OK++))
          else
            ((FAIL++))
            echo "[warn] Failed: $application ($origin $REF)"
          fi
        done < "$APPS_FILE"
        echo "[info] Restore apps complete: $OK succeeded, $FAIL failed, out of $TOTAL entries."
      elif [[ $DRY_RUN -eq 1 ]]; then
        echo "[dry-run] Would install flatpak apps from list."
      fi
    fi
  fi

  echo "========================================="
  echo "[done] Entire restore phase completed successfully."
}

# Run subcommand
if [[ "$COMMAND" == "backup" ]]; then
  do_backup "$@"
elif [[ "$COMMAND" == "restore" ]]; then
  do_restore "$@"
else
  echo "[error] Unknown command: $COMMAND" >&2
  print_help
fi
