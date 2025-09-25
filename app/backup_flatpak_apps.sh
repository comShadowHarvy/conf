#!/usr/bin/env bash
# backup_flatpak_apps.sh
# Save a timestamped list of installed Flatpak apps and configured remotes.
# Usage: backup_flatpak_apps.sh [--dir /path/to/backup-root] [--dest /path/to/centralized-backup]
# 
# --dir: Creates $DIR/YYYYmmdd-HHMMSS/ (original standalone mode)
# --dest: Creates $DEST/flatpak-apps/ (centralized mode - no timestamp subdirectory)
#
# Creates: remotes.tsv, apps.tsv, apps.details.txt, README.txt

set -euo pipefail

# Default to standalone mode
BACKUP_ROOT="$HOME/flatpak-backups"
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
if [[ $CENTRALIZED_MODE -eq 1 ]]; then
  OUT_DIR="$DEST_DIR/flatpak-apps"
else
  TS=$(date +%Y%m%d-%H%M%S)
  OUT_DIR="$BACKUP_ROOT/$TS"
fi

# Check flatpak availability
if ! command -v flatpak >/dev/null 2>&1; then
  printf "Error: flatpak CLI not found in PATH.\n" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

# Save remotes (TSV with header)
echo -e "name\turl" > "$OUT_DIR/remotes.tsv"
flatpak remotes -d | tail -n +2 | while read -r name title url rest; do
  [[ -n "$name" && -n "$url" ]] && echo -e "$name\t$url" >> "$OUT_DIR/remotes.tsv"
done

# Save apps (TSV with header)
# Columns: application, arch, branch, origin, installation
{
  echo -e "application\tarch\tbranch\torigin\tinstallation"
  flatpak list --app --columns=application,arch,branch,origin,installation
} > "$OUT_DIR/apps.tsv"

# Save detailed listing as reference (human-readable)
flatpak list --app --show-details > "$OUT_DIR/apps.details.txt"

# Snapshot README
cat > "$OUT_DIR/README.txt" <<EOF
Flatpak Snapshot - $TS

Files:
- remotes.tsv        : Flatpak remotes (name, url)
- apps.tsv           : Installed apps (application, arch, branch, origin, installation)
- apps.details.txt   : Human-readable details from 'flatpak list --show-details'

Restore with the companion script:
  restore_flatpak_apps.sh           # Uses latest snapshot by default
  restore_flatpak_apps.sh -f "$OUT_DIR/apps.tsv" -r "$OUT_DIR/remotes.tsv"

Notes:
- This backs up the list of apps and remotes, not app data.
- User vs system installation is preserved when restoring.
- Specific commits are not pinned; the restore will install the current commit of the saved branch.
EOF

# Convenience symlink to latest snapshot (standalone mode only)
if [[ $CENTRALIZED_MODE -eq 0 ]]; then
  ln -sfn "$OUT_DIR" "$BACKUP_ROOT/latest"
fi

printf "Saved Flatpak snapshot to: %s\n" "$OUT_DIR"
printf "Files created:\n  - %s\n  - %s\n  - %s\n" \
  "$OUT_DIR/remotes.tsv" "$OUT_DIR/apps.tsv" "$OUT_DIR/apps.details.txt"

