#!/usr/bin/env bash
# backup_docker_desktop_mcp.sh
# Save Docker Desktop MCP (Model Context Protocol) configuration and setup
# Usage: backup_docker_desktop_mcp.sh [--dir /path/to/backup-root] [--dest /path/to/centralized-backup]
# 
# --dir: Creates $DIR/YYYYmmdd-HHMMSS/ (original standalone mode)
# --dest: Creates $DEST/docker-desktop-mcp/ (centralized mode - no timestamp subdirectory)
#
# Creates: mcp_config/, catalog.json, registry.yaml, config.yaml, tools.yaml, README.txt

set -euo pipefail

# Default to standalone mode
BACKUP_ROOT="$HOME/docker-mcp-backups"
CENTRALIZED_MODE=0
DEST_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      BACKUP_ROOT="${2:-}"
      shift 2
      ;;
    --dest)
      DEST_DIR="${2:-}"
      CENTRALIZED_MODE=1
      shift 2
      ;;
    -h|--help)
      sed -n '1,10p' "$0"; exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2; exit 1
      ;;
  esac
done

# Set output directory based on mode
TS=$(date +%Y%m%d-%H%M%S)
if [[ $CENTRALIZED_MODE -eq 1 ]]; then
  OUT_DIR="$DEST_DIR/docker-desktop-mcp"
else
  OUT_DIR="$BACKUP_ROOT/$TS"
fi

# Check if Docker Desktop MCP directory exists
MCP_DIR="$HOME/.docker/mcp"
if [[ ! -d "$MCP_DIR" ]]; then
  printf "Warning: Docker Desktop MCP directory not found at %s\n" "$MCP_DIR" >&2
  printf "This might indicate Docker Desktop MCP is not set up or uses a different location.\n" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

printf "Backing up Docker Desktop MCP configuration...\n"
printf "Source: %s\n" "$MCP_DIR"
printf "Destination: %s\n" "$OUT_DIR"

# Copy the entire MCP directory structure
printf "Copying MCP configuration files...\n"
if command -v rsync >/dev/null 2>&1; then
  # Use rsync for better progress and handling
  rsync -av "$MCP_DIR/" "$OUT_DIR/mcp_config/" --exclude="*.log" --exclude="*.tmp"
else
  # Fallback to cp
  cp -r "$MCP_DIR" "$OUT_DIR/mcp_config"
fi

# Also backup the main docker config.json and daemon.json if they exist
printf "Checking for Docker configuration files...\n"
DOCKER_CONFIG_DIR="$HOME/.docker"
for config_file in "config.json" "daemon.json"; do
  if [[ -f "$DOCKER_CONFIG_DIR/$config_file" ]]; then
    printf "Backing up %s...\n" "$config_file"
    cp "$DOCKER_CONFIG_DIR/$config_file" "$OUT_DIR/"
  fi
done

# Create a summary of what was backed up
printf "Creating backup summary...\n"
{
  echo "Docker Desktop MCP Backup - $TS"
  echo ""
  echo "Source Directory: $MCP_DIR"
  echo "Host: $(hostname)"
  echo "User: $USER"
  echo "Created: $(date)"
  echo ""
  echo "Files and Directories Backed Up:"
  if [[ -d "$OUT_DIR/mcp_config" ]]; then
    echo "✓ MCP Configuration Directory (mcp_config/)"
    find "$OUT_DIR/mcp_config" -type f | sed 's|'"$OUT_DIR"'/mcp_config/|  - |' | head -20
    local file_count
    file_count=$(find "$OUT_DIR/mcp_config" -type f | wc -l)
    if [[ $file_count -gt 20 ]]; then
      echo "  ... and $((file_count - 20)) more files"
    fi
  fi
  
  for config_file in "config.json" "daemon.json"; do
    if [[ -f "$OUT_DIR/$config_file" ]]; then
      echo "✓ Docker $config_file"
    fi
  done
  
  echo ""
  echo "Restore Instructions:"
  echo "1. Ensure Docker Desktop is installed and stopped"
  echo "2. Copy mcp_config/ contents to ~/.docker/mcp/"
  echo "3. Copy any config.json/daemon.json files to ~/.docker/"
  echo "4. Restart Docker Desktop"
  echo "5. Verify MCP setup in Docker Desktop settings"
  echo ""
  echo "Automated restore:"
  echo "  ./restore_docker_desktop_mcp.sh -d \"$OUT_DIR\""
  
} > "$OUT_DIR/README.txt"

# Convenience symlink to latest snapshot (standalone mode only)
if [[ $CENTRALIZED_MODE -eq 0 ]]; then
  mkdir -p "$BACKUP_ROOT"
  ln -sfn "$OUT_DIR" "$BACKUP_ROOT/latest"
fi

printf "✅ Docker Desktop MCP backup completed\n"
printf "Location: %s\n" "$OUT_DIR"
printf "Files backed up:\n"
printf "  - MCP configuration directory\n"
if [[ -f "$OUT_DIR/config.json" ]]; then
  printf "  - config.json\n"
fi
if [[ -f "$OUT_DIR/daemon.json" ]]; then
  printf "  - daemon.json\n"
fi
printf "  - README.txt (with restore instructions)\n"