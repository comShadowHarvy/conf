#!/usr/bin/env bash
# backup_everything.sh - Master Backup System
# Comprehensive backup of Docker images, Flatpak apps, credentials, and Git repos
# 
# USAGE:
#   ./backup_everything.sh [options]
#
# OPTIONS:
#   --docker              Include Docker images backup
#   --flatpak             Include Flatpak apps backup  
#   --credentials         Include credentials backup (SSH, GPG, GitHub CLI, Git)
#   --git-repos           Include Git repositories backup/sync
#   --vscode              Include VS Code settings (with credentials)
#   --encrypt-symmetric   Encrypt credential archives with passphrase (recommended)
#   --encrypt-recipient   Encrypt credential archives to GPG recipient
#   --no-encrypt-creds    Don't encrypt credentials (NOT recommended)
#   --outdir <path>       Custom output directory (default: ~/complete-backups)
#   --flat                Put all backup files directly in main folder (no subdirectories)
#   -p, --persona <name>  Choose personality: wise_old, dm, glados, flirty, linuxdev, sassy, sarcastic
#   --no-theatrics        Skip loading animation and fancy text
#   --dry-run             Show what would be backed up without doing it
#   --all                 Backup everything (default behavior)
#   -h, --help            Show this help
#
# OUTPUT: Creates ~/complete-backups/YYYYmmdd-HHMMSS/ with subdirectories for each backup type

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
INCLUDE_DOCKER=0
INCLUDE_FLATPAK=0  
INCLUDE_CREDENTIALS=0
INCLUDE_GIT_REPOS=0
INCLUDE_VSCODE=0
ENCRYPT_MODE="symmetric"
ENCRYPT_RECIPIENT=""
OUT_ROOT="$HOME/complete-backups"
FLAT_OUTPUT=0
DRY_RUN=0

# Persona setup
setup_persona() {
  local choice="${1:-}"
  local personas=("wise_old" "dm" "glados" "flirty" "linuxdev" "sassy" "sarcastic")
  if [ -z "$choice" ]; then
    choice=${personas[$((RANDOM % ${#personas[@]}))]}
  fi
  PERSONA_CHOSEN="$choice"

  # Wise Old One
  declare -A WISE=(
    [title]="The Old One's Archive Rite"
    [intro_start]="Invoking the winds of time to prepare the archive"
    [intro_online]="The sigils align... the rite may begin"
    [intro_scan]="Peering into the threads of your system's fate"
    [commence]="Let us bind your knowledge to memory"
  )
  # Dungeon Master
  declare -A DM=(
    [title]="The Grand Party Backup Quest"
    [intro_start]="Rolling initiative for backup sequence"
    [intro_online]="Your party is ready. The path is clear"
    [intro_scan]="Surveying the dungeon of directories"
    [commence]="The quest begins!"
  )
  # GLaDOS
  declare -A GLADOS=(
    [title]="Aperture Science Archival Compliance Test"
    [intro_start]="Initiating mandatory compliance procedures"
    [intro_online]="Testing apparatus online. Try not to panic"
    [intro_scan]="Evaluating your questionable configuration choices"
    [commence]="Proceeding with 'backup' (your word, not mine)"
  )
  # Flirty (PG)
  declare -A FLIRTY=(
    [title]="The Charming Little Backup"
    [intro_start]="Warming up... making everything neat for you"
    [intro_online]="All set—let's make this backup gorgeous"
    [intro_scan]="Taking a quick look around—looking good"
    [commence]="Okay, let's capture your best side"
  )
  # Linux Developer
  declare -A LDEV=(
    [title]="Linux Dev Ops: Full Snapshot"
    [intro_start]="Spinning up pipelines and sanity checks"
    [intro_online]="CI green, preflight passed"
    [intro_scan]="Enumerating targets and env state"
    [commence]="Executing backup plan"
  )
  # Sassy
  declare -A SASSY=(
    [title]="The 'Fine, I'll Do It' Backup"
    [intro_start]="Sigh... starting the thing"
    [intro_online]="There. Happy? It's online"
    [intro_scan]="Scanning your chaos—yikes"
    [commence]="Let's just get this over with"
  )
  # Sarcastic
  declare -A SAR=(
    [title]="The Totally Necessary Backup"
    [intro_start]="Booting spectacularly fragile process"
    [intro_online]="Miraculously, it's working"
    [intro_scan]="Checking for disasters... found several"
    [commence]="Archiving your questionable life choices"
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

# Function to flatten backup directory structure
flatten_backup_files() {
  local backup_dir="$1"
  [[ $FLAT_OUTPUT -eq 0 ]] && return 0  # Skip if flat output not requested
  [[ $DRY_RUN -eq 1 ]] && return 0      # Skip in dry run mode
  
  echo "📁 Flattening backup directory structure..."
  
  # Process each component subdirectory
  for component_dir in "$backup_dir"/*; do
    [[ -d "$component_dir" ]] || continue
    
    local component_name=$(basename "$component_dir")
    
    # Skip files and known non-component directories
    [[ "$component_name" == "BACKUP_SUMMARY.txt" ]] && continue
    
    # Find the timestamped subdirectory inside the component directory
    local timestamped_dir=$(find "$component_dir" -maxdepth 1 -type d -name "20*" | head -1)
    if [[ -n "$timestamped_dir" && -d "$timestamped_dir" ]]; then
      echo "  Moving files from $component_name/$(basename "$timestamped_dir")/ to main directory..."
      
      # Move all files from timestamped dir to main backup dir, with component prefix
      for file in "$timestamped_dir"/*; do
        [[ -f "$file" ]] || continue
        local filename=$(basename "$file")
        local new_name="${component_name}_${filename}"
        
        # Special handling for common file types to avoid redundant prefixes
        case "$filename" in
          images.*) new_name="docker_${filename}" ;;
          apps.*|remotes.*) new_name="flatpak_${filename}" ;;
          credentials.*) new_name="${filename}" ;;
          *.txt|*.tsv|*.json) new_name="${component_name}_${filename}" ;;
          *) new_name="${component_name}_${filename}" ;;
        esac
        
        mv "$file" "$backup_dir/$new_name"
      done
      
      # Remove the now-empty timestamped directory
      rmdir "$timestamped_dir" 2>/dev/null || true
      
      # Remove any symlinks in the component directory (like 'latest' symlink)
      find "$component_dir" -type l -delete 2>/dev/null || true
      
      # Remove the now-empty component directory
      rmdir "$component_dir" 2>/dev/null || true
    fi
  done
  
  echo "✅ Directory structure flattened"
}

# Enhanced loading animations
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

matrix_rain() {
  local msg="$1"
  local chars=('0' '1' '0' '1' '█' '▓' '▒' '░')
  printf "\n ${C_GREEN}"
  for i in {1..25}; do
    printf "%s" "${chars[$((RANDOM % ${#chars[@]}))]}"
    sleep 0.05
  done
  printf "${C_RESET}\n ${C_GREEN}▶ %s${C_RESET}\n" "$msg"
}

progress_bar() {
  local msg="$1" duration="$2"
  local width=40
  printf " ${C_YELLOW}%s${C_RESET}\n" "$msg"
  printf " ${C_BLUE}["
  for ((i=0; i<=width; i++)); do
    printf "▓"
    printf "${C_RESET}%*s${C_BLUE}]${C_RESET} %d%%\r" $((width-i)) "" $((i*100/width))
    sleep $(echo "scale=3; $duration / $width" | bc -l 2>/dev/null || echo "0.05")
    printf " ${C_BLUE}["
  done
  printf "\n"
}

wave_animation() {
  local msg="$1"
  local waves=('▁' '▂' '▃' '▄' '▅' '▆' '▇' '█' '▇' '▆' '▅' '▄' '▃' '▂')
  printf " ${C_PURPLE}%s ${C_CYAN}" "$msg"
  for i in {1..35}; do
    printf "%s" "${waves[i % ${#waves[@]}]}"
    sleep 0.04
  done
  printf "${C_RESET}\n"
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
  
  # Stage 1: Initial startup with spinning
  spinner_dots "${TEXT[intro_start]}" 2
  printf "\r ${C_GREEN}✓ %s${C_RESET}\n" "${TEXT[intro_online]}"
  sleep 0.3
  
  # Stage 2: System analysis with progress bar
  progress_bar "${TEXT[intro_scan]}" 1.5
  
  # Stage 3: Final preparation with wave animation
  wave_animation "Preparing system components"
  
  # Stage 4: Ready message with typewriter effect
  type_out "System ready. Initiating backup sequence..." "$C_BOLD$C_GREEN"
  sleep 0.5
  
  # Matrix-style transition
  case "$PERSONA_CHOSEN" in
    glados) type_out "All test subjects accounted for..." "$C_YELLOW" ;;
    dm) type_out "Rolling for backup success... Natural 20!" "$C_PURPLE" ;;
    wise_old) type_out "The ancient protocols awaken..." "$C_CYAN" ;;
    sassy) type_out "Ugh, fine, let's do this thing..." "$C_RED" ;;
    sarcastic) type_out "Oh great, another 'important' backup..." "$C_YELLOW" ;;
    linuxdev) type_out "All systems nominal. Proceeding..." "$C_BLUE" ;;
    *) type_out "Backup initialization complete." "$C_GREEN" ;;
  esac
  
  printf "\n"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --docker)           INCLUDE_DOCKER=1; shift ;;
    --flatpak)          INCLUDE_FLATPAK=1; shift ;;
    --credentials)      INCLUDE_CREDENTIALS=1; shift ;;
    --git-repos)        INCLUDE_GIT_REPOS=1; shift ;;
    --vscode)           INCLUDE_VSCODE=1; shift ;;
    --encrypt-symmetric) ENCRYPT_MODE="symmetric"; shift ;;
    --encrypt-recipient) ENCRYPT_MODE="recipient"; ENCRYPT_RECIPIENT="${2:-}"; shift 2 ;;
    --no-encrypt-creds) ENCRYPT_MODE="none"; shift ;;
    --outdir)           OUT_ROOT="${2:-}"; shift 2 ;;
    --flat)             FLAT_OUTPUT=1; shift ;;
    -p|--persona)       PERSONA_CHOSEN="${2:-}"; shift 2 ;;
    --no-theatrics)     SKIP_THEATRICS=1; shift ;;
    --dry-run)          DRY_RUN=1; shift ;;
    --all)              INCLUDE_DOCKER=1; INCLUDE_FLATPAK=1; INCLUDE_CREDENTIALS=1; INCLUDE_GIT_REPOS=1; shift ;;
    -h|--help)
      sed -n '1,30p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# If no specific components selected, backup everything
if [[ $INCLUDE_DOCKER -eq 0 && $INCLUDE_FLATPAK -eq 0 && $INCLUDE_CREDENTIALS -eq 0 && $INCLUDE_GIT_REPOS -eq 0 ]]; then
  echo "[info] No specific components selected, backing up everything..."
  INCLUDE_DOCKER=1
  INCLUDE_FLATPAK=1  
  INCLUDE_CREDENTIALS=1
  INCLUDE_GIT_REPOS=1
fi

TS=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$OUT_ROOT/$TS"

# Persona init + loader
setup_persona "$PERSONA_CHOSEN"
print_header "${TEXT[title]}"
initial_loader
print_header "${TEXT[commence]}"

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[DRY RUN] Would create backup directory: $BACKUP_DIR"
else
  mkdir -p "$BACKUP_DIR"
  echo "[info] Created backup directory: $BACKUP_DIR"
fi

# Summary of what will be backed up
if [[ $DRY_RUN -eq 1 ]]; then
  echo "[DRY RUN] Would create backup summary: $BACKUP_DIR/BACKUP_SUMMARY.txt"
else
  {
    echo "COMPLETE SYSTEM BACKUP - $TS"
    echo "Host: $(hostname)"
    echo "User: $USER"
    echo "Timestamp: $(date)"
    echo ""
    echo "COMPONENTS INCLUDED:"
    [ $INCLUDE_DOCKER -eq 1 ] && echo "✓ Docker images"
    [ $INCLUDE_FLATPAK -eq 1 ] && echo "✓ Flatpak applications"
    [ $INCLUDE_CREDENTIALS -eq 1 ] && echo "✓ Credentials (SSH, GPG, GitHub CLI, Git)"
    [ $INCLUDE_GIT_REPOS -eq 1 ] && echo "✓ Git repositories backup/sync"
    [ $INCLUDE_VSCODE -eq 1 ] && echo "✓ VS Code settings"
    echo ""
    echo "BACKUP LOCATION: $BACKUP_DIR"
  } > "$BACKUP_DIR/BACKUP_SUMMARY.txt" || echo "[warn] Failed to create summary file"
fi

echo "========================================"
echo "🔄 COMPLETE SYSTEM BACKUP STARTING"
echo "========================================"
echo "Timestamp: $TS"
echo "Location: $BACKUP_DIR"
echo ""

FAILED_COMPONENTS=()
SUCCESS_COUNT=0

# Calculate total steps
TOTAL_STEPS=$((INCLUDE_DOCKER + INCLUDE_FLATPAK + INCLUDE_CREDENTIALS + INCLUDE_GIT_REPOS))
CURRENT_STEP=0

# 1. Docker Images Backup
if [[ $INCLUDE_DOCKER -eq 1 ]]; then
  CURRENT_STEP=$((CURRENT_STEP + 1))
  echo "🐳 [$CURRENT_STEP/$TOTAL_STEPS] Backing up Docker images..."
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] Would backup Docker images to: $BACKUP_DIR/docker-images/"
    else
      if ~/git/conf/app/backup_docker_images.sh --dest "$BACKUP_DIR"; then
        echo "✅ Docker images backup completed"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
      else
        echo "❌ Docker images backup failed"
        FAILED_COMPONENTS+=("Docker")
      fi
    fi
  else
    echo "⚠️  Docker not available, skipping..."
    FAILED_COMPONENTS+=("Docker (not available)")
  fi
  echo ""
fi

# 2. Flatpak Apps Backup  
if [[ $INCLUDE_FLATPAK -eq 1 ]]; then
  CURRENT_STEP=$((CURRENT_STEP + 1))
  echo "📦 [$CURRENT_STEP/$TOTAL_STEPS] Backing up Flatpak applications..."
  if command -v flatpak >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] Would backup Flatpak apps to: $BACKUP_DIR/flatpak-apps/"
      SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
      if ~/git/conf/app/backup_flatpak_apps.sh --dest "$BACKUP_DIR"; then
        echo "✅ Flatpak apps backup completed"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
      else
        echo "❌ Flatpak apps backup failed"
        FAILED_COMPONENTS+=("Flatpak")
      fi
    fi
  else
    echo "⚠️  Flatpak not available, skipping..."
    FAILED_COMPONENTS+=("Flatpak (not available)")
  fi
  echo ""
fi

# 3. Credentials Backup
if [[ $INCLUDE_CREDENTIALS -eq 1 ]]; then
  CURRENT_STEP=$((CURRENT_STEP + 1))
  echo "🔐 [$CURRENT_STEP/$TOTAL_STEPS] Backing up credentials (SSH, GPG, GitHub CLI, Git)..."
  # Build credentials backup command
  CREDS_CMD="~/git/conf/app/backup_credentials.sh --dest $BACKUP_DIR"
  
  case "$ENCRYPT_MODE" in
    symmetric) CREDS_CMD="$CREDS_CMD --encrypt-symmetric" ;;
    recipient) 
      if [[ -n "$ENCRYPT_RECIPIENT" ]]; then
        CREDS_CMD="$CREDS_CMD --encrypt-recipient $ENCRYPT_RECIPIENT"
      else
        echo "❌ Error: --encrypt-recipient specified but no recipient provided"
        FAILED_COMPONENTS+=("Credentials (no recipient)")
        CREDS_CMD=""
      fi
      ;;
    none) CREDS_CMD="$CREDS_CMD --no-encrypt" ;;
  esac
  
  if [[ $INCLUDE_VSCODE -eq 1 ]]; then
    CREDS_CMD="$CREDS_CMD --include-vscode"
  fi
  
  if [[ $DRY_RUN -eq 1 ]]; then
    CREDS_CMD="$CREDS_CMD --dry-run"
  fi
  
  if [[ -n "$CREDS_CMD" ]]; then
    if eval "$CREDS_CMD"; then
      echo "✅ Credentials backup completed"
      SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
      echo "❌ Credentials backup failed"
      FAILED_COMPONENTS+=("Credentials")
    fi
  fi
  echo ""
fi

# 4. Git Repositories Backup/Sync
if [[ $INCLUDE_GIT_REPOS -eq 1 ]]; then
  CURRENT_STEP=$((CURRENT_STEP + 1))
  echo "🔄 [$CURRENT_STEP/$TOTAL_STEPS] Backing up and syncing Git repositories..."
  
  if [[ -x ~/app/gitback ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] Would run Git repositories backup/sync"
    else
      # Run gitback to update all repos and create backup
      if ~/app/gitback; then
        # Copy the generated backup to our backup directory
        REPO_BACKUP_SOURCE="$HOME/backup/repo_backup.txt"
        if [[ -f "$REPO_BACKUP_SOURCE" ]]; then
          cp "$REPO_BACKUP_SOURCE" "$BACKUP_DIR/git_repositories_backup.txt"
        fi
        echo "✅ Git repositories backup completed"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
      else
        echo "❌ Git repositories backup failed"
        FAILED_COMPONENTS+=("Git repositories")
      fi
    fi
  else
    echo "⚠️  gitback script not found at ~/app/gitback, skipping..."
    FAILED_COMPONENTS+=("Git repositories (gitback not found)")
  fi
  echo ""
fi

# Flatten directory structure if requested
flatten_backup_files "$BACKUP_DIR"

# Create summary report
TOTAL_COMPONENTS=$((INCLUDE_DOCKER + INCLUDE_FLATPAK + INCLUDE_CREDENTIALS + INCLUDE_GIT_REPOS))

if [[ $DRY_RUN -eq 0 ]]; then
  {
    echo ""
    echo "BACKUP RESULTS:"
    echo "✅ Successful: $SUCCESS_COUNT/$TOTAL_COMPONENTS"
    [ ${#FAILED_COMPONENTS[@]} -gt 0 ] && echo "❌ Failed: ${FAILED_COMPONENTS[*]}"
    echo ""
    echo "RESTORE INSTRUCTIONS:"
    echo "- All components: ./restore_everything.sh [backup_directory]"
    echo "- Docker images: ./restore_docker_images.sh -f docker-images/images.digests.txt"
    echo "- Flatpak apps: ./restore_flatpak_apps.sh -f flatpak-apps/apps.tsv -r flatpak-apps/remotes.tsv"
    echo "- Credentials: ./restore_credentials.sh -f credentials/credentials.tar.gpg"
    echo "- Git repos: Use gitdow with git_repositories_backup.txt"
    echo ""
    echo "CREATED: $(date)"
  } >> "$BACKUP_DIR/BACKUP_SUMMARY.txt" || echo "[warn] Failed to append to summary file"
fi

# Create convenience symlinks
if [[ $DRY_RUN -eq 0 ]]; then
  ln -sfn "$BACKUP_DIR" "$OUT_ROOT/latest"
fi

echo "========================================"
echo "🎉 COMPLETE SYSTEM BACKUP FINISHED"
echo "========================================"
echo "Results: $SUCCESS_COUNT/$TOTAL_COMPONENTS components backed up successfully"
echo "Location: $BACKUP_DIR"
echo "Latest symlink: $OUT_ROOT/latest"

if [[ ${#FAILED_COMPONENTS[@]} -gt 0 ]]; then
  echo ""
  echo "⚠️  Failed components: ${FAILED_COMPONENTS[*]}"
  echo "Check the output above for specific error details"
  exit 1
fi

echo ""
echo "✅ All backups completed successfully!"
echo "📖 See BACKUP_SUMMARY.txt for restore instructions"
