#!/usr/bin/env bash
# restore_everything.sh - Master Restore System
# Comprehensive restore of Docker images, Flatpak apps, credentials, and Git repos
#
# USAGE:
#   ./restore_everything.sh [options] [backup_directory]
#
# OPTIONS:
#   -d, --dir <path>      Restore from specific backup directory
#   --docker              Restore Docker images only
#   --flatpak             Restore Flatpak apps only  
#   --credentials         Restore credentials only (SSH, GPG, GitHub CLI, Git)
#   --git-repos           Restore Git repositories only (requires gitdow)
#   --skip-docker         Skip Docker images restore
#   --skip-flatpak        Skip Flatpak apps restore
#   --skip-credentials    Skip credentials restore
#   --skip-git-repos      Skip Git repositories restore
#   --add-ssh-keys        Automatically add SSH keys to agent after restore (default)
#   --no-ssh-agent        Don't automatically add SSH keys to agent
#   -p, --persona <name>  Choose personality: wise_old, dm, glados, flirty, linuxdev, sassy, sarcastic
#   --no-theatrics        Skip loading animation and fancy text
#   --dry-run             Show what would be restored without doing it
#   --all                 Restore everything (default behavior)
#   -h, --help            Show this help
#
# If no backup directory is specified, uses ~/complete-backups/latest/

set -euo pipefail

# Colors
if [ -t 1 ]; then
  C_RESET='\033[0m' C_BOLD='\033[1m' C_RED='\033[0;31m' C_GREEN='\033[0;32m'
  C_YELLOW='\033[0;33m' C_BLUE='\033[0;34m' C_PURPLE='\033[0;35m' C_CYAN='\033[0;36m'
else
  C_RESET='' C_BOLD='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_PURPLE='' C_CYAN=''
fi

# Persona text store
declare -A TEXT
SKIP_THEATRICS=0
PERSONA_CHOSEN=""

# Default options
BACKUP_DIR=""
RESTORE_DOCKER=1
RESTORE_FLATPAK=1
RESTORE_CREDENTIALS=1
RESTORE_GIT_REPOS=1
ADD_SSH_KEYS=1
NO_SSH_AGENT=0
DRY_RUN=0
SELECTIVE_MODE=0

# Persona setup for restore
setup_persona() {
  local choice="${1:-}"
  local personas=("wise_old" "dm" "glados" "flirty" "linuxdev" "sassy" "sarcastic")
  if [ -z "$choice" ]; then
    choice=${personas[$((RANDOM % ${#personas[@]}))]}
  fi
  PERSONA_CHOSEN="$choice"

  # Wise Old One
  declare -A WISE=(
    [title]="The Old One's Restoration Rite"
    [intro_start]="Awakening the threads of memory from the archive"
    [intro_online]="The ancient knowledge stirs... ready to flow"
    [intro_scan]="Reading the essence of what was preserved"
    [commence]="Let us restore what once was"
  )
  # Dungeon Master
  declare -A DM=(
    [title]="The Great Restoration Campaign"
    [intro_start]="Rolling for party readiness... success!"
    [intro_online]="Your backup tome has been unsealed"
    [intro_scan]="Identifying treasures within the vault"
    [commence]="The restoration quest begins!"
  )
  # GLaDOS
  declare -A GLADOS=(
    [title]="Aperture Science Subject Recovery Protocol"
    [intro_start]="Initiating test subject reconstruction sequence"
    [intro_online]="Surprisingly, your backup didn't corrupt itself"
    [intro_scan]="Analyzing your inferior file organization"
    [commence]="Restoring your... 'important' files"
  )
  # Flirty (PG)
  declare -A FLIRTY=(
    [title]="The Sweet Little Restoration"
    [intro_start]="Getting cozy with your backup files"
    [intro_online]="Everything's looking so good in there"
    [intro_scan]="Mmm, nice file structure you have"
    [commence]="Time to bring back all your favorites"
  )
  # Linux Developer
  declare -A LDEV=(
    [title]="DevOps: System State Recovery"
    [intro_start]="Initializing recovery pipeline"
    [intro_online]="Backup integrity validated, proceeding"
    [intro_scan]="Parsing manifest and dependency graph"
    [commence]="Executing restore workflow"
  )
  # Sassy
  declare -A SASSY=(
    [title]="The 'Fine, I'll Fix It' Restore"
    [intro_start]="Ugh, starting your little restore thing"
    [intro_online]="There, it's working. You're welcome"
    [intro_scan]="Looking at the mess you made"
    [commence]="Cleaning up after you... again"
  )
  # Sarcastic
  declare -A SAR=(
    [title]="The Miraculous Data Resurrection"
    [intro_start]="Booting the absolutely foolproof restore system"
    [intro_online]="Shockingly, your backup actually exists"
    [intro_scan]="Cataloging your digital life choices"
    [commence]="Restoring your presumably crucial files"
  )

  case "$choice" in
    wise_old) for k in "${!WISE[@]}"; do TEXT[$k]="${WISE[$k]}"; done ;;
    dm)       for k in "${!DM[@]}"; do TEXT[$k]="${DM[$k]}"; done ;;
    glados)   for k in "${!GLADOS[@]}"; do TEXT[$k]="${GLADOS[$k]}"; done ;;
    flirty)   for k in "${!FLIRTY[@]}"; do TEXT[$k]="${FLIRTY[$k]}"; done ;;
    linuxdev) for k in "${!LDEV[@]}"; do TEXT[$k]="${LDEV[$k]}"; done ;;
    sassy)    for k in "${!SASSY[@]}"; do TEXT[$k]="${SASSY[$k]}"; done ;;
    sarcastic)for k in "${!SAR[@]}"; do TEXT[$k]="${SAR[$k]}"; done ;;
    *)        for k in "${!LDEV[@]}"; do TEXT[$k]="${LDEV[$k]}"; done ;;
  esac
}

print_header() { printf "\n${C_BOLD}${C_PURPLE}---=== %s ===---${C_RESET}\n" "$1"; }

# Enhanced loading animations (same as backup script)
spinner_dots() {
  local msg="$1" duration="$2"
  local spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local end_time=$(($(date +%s) + duration))
  while [ $(date +%s) -lt $end_time ]; do
    for frame in "${spinner[@]}"; do
      printf "\r ${C_CYAN}${frame} %s${C_RESET}" "$msg"
      sleep 0.08
      [ $(date +%s) -ge $end_time ] && break
    done
  done
}

reverse_progress_bar() {
  local msg="$1" duration="$2"
  local width=40
  printf " ${C_YELLOW}%s${C_RESET}\n" "$msg"
  for ((i=width; i>=0; i--)); do
    printf "\r ${C_BLUE}["
    for ((j=0; j<i; j++)); do printf "░"; done
    for ((j=i; j<width; j++)); do printf "▓"; done
    printf "]${C_RESET} %d%%" $((100-i*100/width))
    sleep $(echo "scale=3; $duration / $width" | bc -l 2>/dev/null || echo "0.05")
  done
  printf "\n"
}

restore_wave_animation() {
  local msg="$1"
  local waves=('█' '▇' '▆' '▅' '▄' '▃' '▂' '▁' '▂' '▃' '▄' '▅' '▆' '▇')
  printf " ${C_GREEN}%s ${C_PURPLE}" "$msg"
  for i in {1..35}; do
    printf "%s" "${waves[i % ${#waves[@]}]}"
    sleep 0.04
  done
  printf "${C_RESET}\n"
}

data_flow_animation() {
  local msg="$1"
  printf " ${C_CYAN}%s ${C_RESET}" "$msg"
  local flow=('>>>' '-->>' '--->' '----' '<---' '<<--' '<<<-' '<<<<')
  for i in {1..25}; do
    printf "\r ${C_CYAN}%s ${C_BLUE}%s${C_RESET}" "$msg" "${flow[i % ${#flow[@]}]}"
    sleep 0.1
  done
  printf "\r ${C_CYAN}%s ${C_GREEN}DONE${C_RESET}\n" "$msg"
}

type_out() {
  local msg="$1" color="${2:-$C_GREEN}"
  printf " ${color}"
  for ((i=0; i<${#msg}; i++)); do
    printf "%c" "${msg:$i:1}"
    sleep 0.03
  done
  printf "${C_RESET}\n"
}

initial_loader() {
  [ "$SKIP_THEATRICS" -eq 1 ] && return 0
  
  # Clear screen and move cursor up
  printf "\033[2J\033[H"
  
  # Stage 1: Initial startup with spinning
  spinner_dots "${TEXT[intro_start]}" 2
  printf "\r ${C_GREEN}✓ %s${C_RESET}\n" "${TEXT[intro_online]}"
  sleep 0.3
  
  # Stage 2: Backup analysis with reverse progress bar
  reverse_progress_bar "${TEXT[intro_scan]}" 1.5
  
  # Stage 3: Data flow animation
  data_flow_animation "Preparing restoration sequence"
  
  # Stage 4: Final preparation with restore wave
  restore_wave_animation "Loading restoration protocols"
  
  # Stage 5: Ready message with typewriter effect
  type_out "Restoration system online. Ready to proceed..." "$C_BOLD$C_GREEN"
  sleep 0.5
  
  # Personality-specific ready messages
  case "$PERSONA_CHOSEN" in
    glados) type_out "Please remain calm during the restoration process..." "$C_YELLOW" ;;
    dm) type_out "Your backup scroll has been decoded successfully!" "$C_PURPLE" ;;
    wise_old) type_out "The memories of old shall flow anew..." "$C_CYAN" ;;
    sassy) type_out "Alright, let's fix whatever you broke..." "$C_RED" ;;
    sarcastic) type_out "Time to restore your 'irreplaceable' files..." "$C_YELLOW" ;;
    linuxdev) type_out "Restoration pipeline initialized. Standing by..." "$C_BLUE" ;;
    flirty) type_out "Ready to bring back all your favorite things..." "$C_PURPLE" ;;
    *) type_out "Restoration sequence ready." "$C_GREEN" ;;
  esac
  
  printf "\n"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dir)           BACKUP_DIR="${2:-}"; shift 2 ;;
    --docker)           SELECTIVE_MODE=1; RESTORE_DOCKER=1; RESTORE_FLATPAK=0; RESTORE_CREDENTIALS=0; RESTORE_GIT_REPOS=0; shift ;;
    --flatpak)          SELECTIVE_MODE=1; RESTORE_DOCKER=0; RESTORE_FLATPAK=1; RESTORE_CREDENTIALS=0; RESTORE_GIT_REPOS=0; shift ;;
    --credentials)      SELECTIVE_MODE=1; RESTORE_DOCKER=0; RESTORE_FLATPAK=0; RESTORE_CREDENTIALS=1; RESTORE_GIT_REPOS=0; shift ;;
    --git-repos)        SELECTIVE_MODE=1; RESTORE_DOCKER=0; RESTORE_FLATPAK=0; RESTORE_CREDENTIALS=0; RESTORE_GIT_REPOS=1; shift ;;
    --skip-docker)      RESTORE_DOCKER=0; shift ;;
    --skip-flatpak)     RESTORE_FLATPAK=0; shift ;;
    --skip-credentials) RESTORE_CREDENTIALS=0; shift ;;
    --skip-git-repos)   RESTORE_GIT_REPOS=0; shift ;;
    --add-ssh-keys)     ADD_SSH_KEYS=1; shift ;;
    --no-ssh-agent)     NO_SSH_AGENT=1; ADD_SSH_KEYS=0; shift ;;
    -p|--persona)       PERSONA_CHOSEN="${2:-}"; shift 2 ;;
    --no-theatrics)     SKIP_THEATRICS=1; shift ;;
    --dry-run)          DRY_RUN=1; shift ;;
    --all)              RESTORE_DOCKER=1; RESTORE_FLATPAK=1; RESTORE_CREDENTIALS=1; RESTORE_GIT_REPOS=1; shift ;;
    -h|--help)
      sed -n '1,25p' "$0"; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) 
      if [[ -z "$BACKUP_DIR" ]]; then
        BACKUP_DIR="$1"
      else
        echo "Multiple backup directories specified" >&2; exit 1
      fi
      shift ;;
  esac
done

# Default to latest backup if none specified
if [[ -z "$BACKUP_DIR" ]]; then
  LATEST_BACKUP="$HOME/complete-backups/latest"
  if [[ -L "$LATEST_BACKUP" && -d "$LATEST_BACKUP" ]]; then
    BACKUP_DIR="$LATEST_BACKUP"
    echo "[info] Using latest backup: $BACKUP_DIR"
  else
    echo "[error] No backup directory specified and no latest backup found." >&2
    echo "Usage: $0 [options] [backup_directory]" >&2
    exit 1
  fi
fi

if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "[error] Backup directory not found: $BACKUP_DIR" >&2
  exit 1
fi

# Persona init + loader
setup_persona "$PERSONA_CHOSEN"
print_header "${TEXT[title]}"
initial_loader

# Read backup summary if available
SUMMARY_FILE="$BACKUP_DIR/BACKUP_SUMMARY.txt"
if [[ -f "$SUMMARY_FILE" ]]; then
  echo "========================================"
  echo "📖 BACKUP INFORMATION"
  echo "========================================"
  head -10 "$SUMMARY_FILE" | grep -E "(COMPLETE SYSTEM BACKUP|Host:|User:|Timestamp:|COMPONENTS INCLUDED|✓)"
  echo ""
fi

print_header "${TEXT[commence]}"
echo "Source: $BACKUP_DIR"
echo ""

FAILED_COMPONENTS=()
SUCCESS_COUNT=0
TOTAL_COMPONENTS=$((RESTORE_DOCKER + RESTORE_FLATPAK + RESTORE_CREDENTIALS + RESTORE_GIT_REPOS))

# 1. Docker Images Restore
if [[ $RESTORE_DOCKER -eq 1 ]]; then
  echo "🐳 [1/4] Restoring Docker images..."
  
  # Try centralized layout first, then legacy layout
  DOCKER_IMAGES_FILE="$BACKUP_DIR/docker-images/images.digests.txt"
  if [[ ! -f "$DOCKER_IMAGES_FILE" ]]; then
    DOCKER_IMAGES_FILE="$BACKUP_DIR/docker-images/images.tags.txt"
  fi
  if [[ ! -f "$DOCKER_IMAGES_FILE" ]]; then
    # Fall back to legacy nested directory structure
    DOCKER_IMAGES_FILE=$(find "$BACKUP_DIR/docker-images" -name "images.digests.txt" 2>/dev/null | head -1)
    if [[ -z "$DOCKER_IMAGES_FILE" ]]; then
      DOCKER_IMAGES_FILE=$(find "$BACKUP_DIR/docker-images" -name "images.tags.txt" 2>/dev/null | head -1)
    fi
  fi
  
  if [[ -n "$DOCKER_IMAGES_FILE" && -f "$DOCKER_IMAGES_FILE" ]]; then
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "[dry-run] Would restore Docker images from: $DOCKER_IMAGES_FILE"
      else
        if ~/restore_docker_images.sh -f "$DOCKER_IMAGES_FILE"; then
          echo "✅ Docker images restore completed"
          ((SUCCESS_COUNT++))
        else
          echo "❌ Docker images restore failed"
          FAILED_COMPONENTS+=("Docker")
        fi
      fi
    else
      echo "⚠️  Docker not available, skipping..."
      FAILED_COMPONENTS+=("Docker (not available)")
    fi
  else
    echo "⚠️  No Docker images backup found, skipping..."
    FAILED_COMPONENTS+=("Docker (no backup found)")
  fi
  echo ""
fi

# 2. Flatpak Apps Restore
if [[ $RESTORE_FLATPAK -eq 1 ]]; then
  echo "📦 [2/4] Restoring Flatpak applications..."
  
  # Try centralized layout first, then legacy layout
  FLATPAK_APPS_FILE="$BACKUP_DIR/flatpak-apps/apps.tsv"
  FLATPAK_REMOTES_FILE="$BACKUP_DIR/flatpak-apps/remotes.tsv"
  if [[ ! -f "$FLATPAK_APPS_FILE" ]]; then
    # Fall back to legacy nested directory structure
    FLATPAK_APPS_FILE=$(find "$BACKUP_DIR/flatpak-apps" -name "apps.tsv" 2>/dev/null | head -1)
    FLATPAK_REMOTES_FILE=$(find "$BACKUP_DIR/flatpak-apps" -name "remotes.tsv" 2>/dev/null | head -1)
  fi
  
  if [[ -n "$FLATPAK_APPS_FILE" && -f "$FLATPAK_APPS_FILE" ]]; then
    if command -v flatpak >/dev/null 2>&1; then
      RESTORE_CMD="~/restore_flatpak_apps.sh -f $FLATPAK_APPS_FILE"
      if [[ -n "$FLATPAK_REMOTES_FILE" && -f "$FLATPAK_REMOTES_FILE" ]]; then
        RESTORE_CMD="$RESTORE_CMD -r $FLATPAK_REMOTES_FILE"
      fi
      
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "[dry-run] Would restore Flatpak apps with: $RESTORE_CMD"
      else
        if eval "$RESTORE_CMD"; then
          echo "✅ Flatpak apps restore completed"
          ((SUCCESS_COUNT++))
        else
          echo "❌ Flatpak apps restore failed"
          FAILED_COMPONENTS+=("Flatpak")
        fi
      fi
    else
      echo "⚠️  Flatpak not available, skipping..."
      FAILED_COMPONENTS+=("Flatpak (not available)")
    fi
  else
    echo "⚠️  No Flatpak apps backup found, skipping..."
    FAILED_COMPONENTS+=("Flatpak (no backup found)")
  fi
  echo ""
fi

# 3. Credentials Restore
if [[ $RESTORE_CREDENTIALS -eq 1 ]]; then
  echo "🔐 [3/4] Restoring credentials..."
  
  # Try centralized layout first, then legacy layout
  CREDS_ARCHIVE="$BACKUP_DIR/credentials/credentials.tar.gpg"
  if [[ ! -f "$CREDS_ARCHIVE" ]]; then
    CREDS_ARCHIVE="$BACKUP_DIR/credentials/credentials.tar"
  fi
  if [[ ! -f "$CREDS_ARCHIVE" ]]; then
    # Fall back to legacy nested directory structure
    CREDS_ARCHIVE=$(find "$BACKUP_DIR/credentials" -name "credentials.tar.gpg" -o -name "credentials.tar" 2>/dev/null | head -1)
  fi
  
  if [[ -n "$CREDS_ARCHIVE" && -f "$CREDS_ARCHIVE" ]]; then
    CREDS_CMD="~/restore_credentials.sh"
    [[ $DRY_RUN -eq 1 ]] && CREDS_CMD="$CREDS_CMD --dry-run"
    [[ $NO_SSH_AGENT -eq 1 ]] && CREDS_CMD="$CREDS_CMD --no-ssh-agent"
    [[ $ADD_SSH_KEYS -eq 1 ]] && CREDS_CMD="$CREDS_CMD --add-ssh-keys"
    CREDS_CMD="$CREDS_CMD -f $CREDS_ARCHIVE"
    
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] Would restore credentials from: $CREDS_ARCHIVE"
      eval "$CREDS_CMD"
    else
      if eval "$CREDS_CMD"; then
        echo "✅ Credentials restore completed"
        ((SUCCESS_COUNT++))
      else
        echo "❌ Credentials restore failed"
        FAILED_COMPONENTS+=("Credentials")
      fi
    fi
  else
    # Try to find backup directory instead - centralized layout first
    CREDS_DIR="$BACKUP_DIR/credentials/collected"
    if [[ ! -d "$CREDS_DIR" ]]; then
      # Fall back to legacy nested directory structure
      CREDS_DIR=$(find "$BACKUP_DIR/credentials" -maxdepth 2 -name "collected" -type d 2>/dev/null | head -1)
    fi
    if [[ -n "$CREDS_DIR" ]]; then
      CREDS_BACKUP_DIR=$(dirname "$CREDS_DIR")
      CREDS_CMD="~/restore_credentials.sh"
      [[ $DRY_RUN -eq 1 ]] && CREDS_CMD="$CREDS_CMD --dry-run"
      [[ $NO_SSH_AGENT -eq 1 ]] && CREDS_CMD="$CREDS_CMD --no-ssh-agent"
      [[ $ADD_SSH_KEYS -eq 1 ]] && CREDS_CMD="$CREDS_CMD --add-ssh-keys"
      CREDS_CMD="$CREDS_CMD -d $CREDS_BACKUP_DIR"
      
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "[dry-run] Would restore credentials from directory: $CREDS_BACKUP_DIR"
        eval "$CREDS_CMD"
      else
        if eval "$CREDS_CMD"; then
          echo "✅ Credentials restore completed"
          ((SUCCESS_COUNT++))
        else
          echo "❌ Credentials restore failed"
          FAILED_COMPONENTS+=("Credentials")
        fi
      fi
    else
      echo "⚠️  No credentials backup found, skipping..."
      FAILED_COMPONENTS+=("Credentials (no backup found)")
    fi
  fi
  echo ""
fi

# 4. Git Repositories Restore
if [[ $RESTORE_GIT_REPOS -eq 1 ]]; then
  echo "🔄 [4/4] Restoring Git repositories..."
  
  GIT_BACKUP_FILE="$BACKUP_DIR/git_repositories_backup.txt"
  
  if [[ -f "$GIT_BACKUP_FILE" ]]; then
    if [[ -x ~/app/gitdow ]]; then
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "[dry-run] Would restore Git repositories using: ~/app/gitdow"
        echo "[dry-run] Backup file found: $GIT_BACKUP_FILE"
      else
        echo "ℹ️  Git repositories backup found: $GIT_BACKUP_FILE"
        echo "🔧 To restore repositories, run: ~/app/gitdow"
        echo "   (This will clone/update repos listed in ~/backup/repo_backup.txt)"
        
        # Copy backup file to expected location
        mkdir -p ~/backup
        cp "$GIT_BACKUP_FILE" ~/backup/repo_backup.txt
        
        echo "✅ Git repositories backup file copied to ~/backup/repo_backup.txt"
        echo "   Run ~/app/gitdow to clone repositories"
        ((SUCCESS_COUNT++))
      fi
    else
      echo "⚠️  gitdow script not found at ~/app/gitdow"
      echo "   Git repositories backup available at: $GIT_BACKUP_FILE"
      FAILED_COMPONENTS+=("Git repositories (gitdow not found)")
    fi
  else
    echo "⚠️  No Git repositories backup found, skipping..."
    FAILED_COMPONENTS+=("Git repositories (no backup found)")
  fi
  echo ""
fi

echo "========================================"
echo "🎉 COMPLETE SYSTEM RESTORE FINISHED"
echo "========================================"
echo "Results: $SUCCESS_COUNT/$TOTAL_COMPONENTS components restored successfully"

if [[ ${#FAILED_COMPONENTS[@]} -gt 0 ]]; then
  echo ""
  echo "⚠️  Failed/Skipped components: ${FAILED_COMPONENTS[*]}"
  echo "Check the output above for specific details"
fi

echo ""
if [[ $SUCCESS_COUNT -eq $TOTAL_COMPONENTS ]]; then
  echo "✅ All selected components restored successfully!"
else
  echo "⚠️  Some components failed or were skipped - see details above"
fi

echo ""
echo "📋 POST-RESTORE CHECKLIST:"
if [[ $NO_SSH_AGENT -eq 1 || $ADD_SSH_KEYS -eq 0 ]]; then
  echo "  • SSH: Run 'ssh-add ~/.ssh/id_*' to add keys to agent"
else
  echo "  • SSH: Keys automatically added to agent ✓"
fi
echo "  • GitHub CLI: Run 'gh auth status' to verify authentication"
echo "  • Git repos: Run '~/app/gitdow' if not automatically restored"
echo "  • Docker: Run 'docker images' to verify restored images"
echo "  • Flatpak: Run 'flatpak list' to verify restored apps"
