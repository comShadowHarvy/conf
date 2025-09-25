#!/usr/bin/env bash
# restore_docker_desktop_mcp.sh
# Restore Docker Desktop MCP (Model Context Protocol) configuration and setup
# Usage: restore_docker_desktop_mcp.sh [options]
#
# OPTIONS:
#   -d, --dir <path>      Restore from specific backup directory
#   -f, --file <archive>  Restore from archive file (if available)
#   --dry-run             Show what would be restored without doing it
#   --backup              Backup existing MCP config before restore
#   --force               Overwrite existing files without confirmation
#   -h, --help            Show this help
#
# The script expects either:
#   - A directory containing mcp_config/ subdirectory and optional config files
#   - Direct path to Docker Desktop MCP backup directory

set -euo pipefail

# Default options
BACKUP_DIR=""
ARCHIVE_FILE=""
DRY_RUN=0
BACKUP_EXISTING=1
FORCE_OVERWRITE=0

print_usage() {
  sed -n '1,20p' "$0"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dir)
      BACKUP_DIR="${2:-}"
      shift 2
      ;;
    -f|--file)
      ARCHIVE_FILE="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --backup)
      BACKUP_EXISTING=1
      shift
      ;;
    --no-backup)
      BACKUP_EXISTING=0
      shift
      ;;
    --force)
      FORCE_OVERWRITE=1
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      print_usage >&2
      exit 1
      ;;
  esac
done

# Validate arguments
if [[ -z "$BACKUP_DIR" && -z "$ARCHIVE_FILE" ]]; then
  echo "Error: Must specify either --dir or --file" >&2
  print_usage >&2
  exit 1
fi

if [[ -n "$ARCHIVE_FILE" ]]; then
  echo "Error: Archive file restore not yet implemented. Use --dir instead." >&2
  exit 1
fi

if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "Error: Backup directory not found: $BACKUP_DIR" >&2
  exit 1
fi

# Target directories
DOCKER_DIR="$HOME/.docker"
MCP_DIR="$DOCKER_DIR/mcp"

printf "Docker Desktop MCP Configuration Restore\n"
printf "=========================================\n"
printf "Source: %s\n" "$BACKUP_DIR"
printf "Target: %s\n" "$MCP_DIR"
printf "Mode: %s\n" "$([ $DRY_RUN -eq 1 ] && echo "DRY RUN" || echo "LIVE RESTORE")"
printf "\n"

# Check what's available in the backup
BACKUP_MCP_CONFIG="$BACKUP_DIR/mcp_config"
BACKUP_DOCKER_CONFIG="$BACKUP_DIR/config.json"
BACKUP_DOCKER_DAEMON="$BACKUP_DIR/daemon.json"

if [[ ! -d "$BACKUP_MCP_CONFIG" ]]; then
  echo "Error: MCP config directory not found in backup: $BACKUP_MCP_CONFIG" >&2
  echo "Expected directory structure: backup_dir/mcp_config/" >&2
  exit 1
fi

printf "Found backup components:\n"
if [[ -d "$BACKUP_MCP_CONFIG" ]]; then
  local mcp_file_count
  mcp_file_count=$(find "$BACKUP_MCP_CONFIG" -type f | wc -l)
  printf "  ✓ MCP configuration directory (%d files)\n" "$mcp_file_count"
fi
if [[ -f "$BACKUP_DOCKER_CONFIG" ]]; then
  printf "  ✓ Docker config.json\n"
fi
if [[ -f "$BACKUP_DOCKER_DAEMON" ]]; then
  printf "  ✓ Docker daemon.json\n"
fi
printf "\n"

# Backup existing configuration if requested
if [[ $BACKUP_EXISTING -eq 1 && -d "$MCP_DIR" ]]; then
  BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  EXISTING_BACKUP_DIR="$HOME/.docker/mcp-backup-$BACKUP_TIMESTAMP"
  
  printf "Backing up existing MCP configuration...\n"
  if [[ $DRY_RUN -eq 1 ]]; then
    printf "[dry-run] Would backup existing MCP config to: %s\n" "$EXISTING_BACKUP_DIR"
  else
    mkdir -p "$EXISTING_BACKUP_DIR"
    if command -v rsync >/dev/null 2>&1; then
      rsync -av "$MCP_DIR/" "$EXISTING_BACKUP_DIR/"
    else
      cp -r "$MCP_DIR" "$EXISTING_BACKUP_DIR"
    fi
    printf "  ✓ Existing config backed up to: %s\n" "$EXISTING_BACKUP_DIR"
  fi
  printf "\n"
fi

# Check for conflicts
CONFLICTS=()
if [[ -d "$MCP_DIR" && $FORCE_OVERWRITE -eq 0 ]]; then
  CONFLICTS+=("MCP directory exists: $MCP_DIR")
fi
if [[ -f "$DOCKER_DIR/config.json" && -f "$BACKUP_DOCKER_CONFIG" && $FORCE_OVERWRITE -eq 0 ]]; then
  CONFLICTS+=("Docker config.json exists")
fi
if [[ -f "$DOCKER_DIR/daemon.json" && -f "$BACKUP_DOCKER_DAEMON" && $FORCE_OVERWRITE -eq 0 ]]; then
  CONFLICTS+=("Docker daemon.json exists")
fi

if [[ ${#CONFLICTS[@]} -gt 0 && $DRY_RUN -eq 0 ]]; then
  printf "⚠️  Conflicts detected:\n"
  for conflict in "${CONFLICTS[@]}"; do
    printf "  - %s\n" "$conflict"
  done
  printf "\n"
  
  if [[ $FORCE_OVERWRITE -eq 0 ]]; then
    printf "Use --force to overwrite existing files, or --backup to backup them first.\n"
    printf "Current backup setting: %s\n" "$([ $BACKUP_EXISTING -eq 1 ] && echo "enabled" || echo "disabled")"
    read -p "Continue anyway? [y/N]: " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Restore cancelled."
      exit 0
    fi
  fi
fi

# Restore MCP configuration
printf "Restoring MCP configuration...\n"
if [[ $DRY_RUN -eq 1 ]]; then
  printf "[dry-run] Would create directory: %s\n" "$MCP_DIR"
  printf "[dry-run] Would copy MCP config files from: %s\n" "$BACKUP_MCP_CONFIG"
else
  mkdir -p "$DOCKER_DIR"
  
  # Remove existing MCP directory if it exists
  if [[ -d "$MCP_DIR" ]]; then
    printf "  Removing existing MCP directory...\n"
    rm -rf "$MCP_DIR"
  fi
  
  # Copy MCP configuration
  printf "  Copying MCP configuration files...\n"
  if command -v rsync >/dev/null 2>&1; then
    rsync -av "$BACKUP_MCP_CONFIG/" "$MCP_DIR/"
  else
    cp -r "$BACKUP_MCP_CONFIG" "$MCP_DIR"
  fi
  
  printf "  ✓ MCP configuration restored\n"
fi

# Restore Docker configuration files
if [[ -f "$BACKUP_DOCKER_CONFIG" ]]; then
  printf "Restoring Docker config.json...\n"
  if [[ $DRY_RUN -eq 1 ]]; then
    printf "[dry-run] Would copy: %s -> %s/config.json\n" "$BACKUP_DOCKER_CONFIG" "$DOCKER_DIR"
  else
    cp "$BACKUP_DOCKER_CONFIG" "$DOCKER_DIR/config.json"
    printf "  ✓ config.json restored\n"
  fi
fi

if [[ -f "$BACKUP_DOCKER_DAEMON" ]]; then
  printf "Restoring Docker daemon.json...\n"
  if [[ $DRY_RUN -eq 1 ]]; then
    printf "[dry-run] Would copy: %s -> %s/daemon.json\n" "$BACKUP_DOCKER_DAEMON" "$DOCKER_DIR"
  else
    cp "$BACKUP_DOCKER_DAEMON" "$DOCKER_DIR/daemon.json"
    printf "  ✓ daemon.json restored\n"
  fi
fi

printf "\n"
printf "========================================\n"
printf "✅ Docker Desktop MCP Restore Complete\n" 
printf "========================================\n"

if [[ $DRY_RUN -eq 0 ]]; then
  printf "Restored to: %s\n" "$MCP_DIR"
  
  printf "\nNext steps:\n"
  printf "1. Restart Docker Desktop to apply configuration changes\n"
  printf "2. Verify MCP setup in Docker Desktop settings\n"
  printf "3. Test MCP functionality with your preferred tools\n"
  
  if [[ $BACKUP_EXISTING -eq 1 && -d "$EXISTING_BACKUP_DIR" ]]; then
    printf "4. Remove backup if restoration successful: rm -rf %s\n" "$EXISTING_BACKUP_DIR"
  fi
  
  printf "\nRestore completed successfully! 🎉\n"
else
  printf "[DRY RUN] No changes were made.\n"
fi