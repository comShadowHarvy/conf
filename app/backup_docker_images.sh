#!/usr/bin/env bash
# backup_docker_images.sh
# Save a timestamped list of currently installed Docker images (tags and digests)
# Usage: backup_docker_images.sh [--dir /path/to/backup-root]
# Creates: $BACKUP_ROOT/images/YYYYmmdd-HHMMSS/{images.tags.txt, images.digests.txt, images.json, README.txt}

set -euo pipefail

BACKUP_ROOT="$HOME/docker-backups/images"
if [[ ${1-} == "--dir" && -n ${2-} ]]; then
  BACKUP_ROOT="$2"
  shift 2
fi

# Check docker availability
if ! command -v docker >/dev/null 2>&1; then
  printf "Error: docker CLI not found in PATH.\n" >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  printf "Error: Docker daemon is not running or not accessible.\n" >&2
  exit 1
fi

TS=$(date +%Y%m%d-%H%M%S)
OUT_DIR="$BACKUP_ROOT/$TS"
mkdir -p "$OUT_DIR"

# Save images (repository:tag), excluding dangling <none>
# Note: images with no tag (<none>) cannot be pulled by tag; they are excluded from tags list.
docker images --format '{{.Repository}}:{{.Tag}}' \
  | grep -v '^<none>:' \
  | grep -v '^:' \
  | sort -u > "$OUT_DIR/images.tags.txt"

# Save images by content digest (repository@digest), more reproducible
# Exclude entries with missing digest
# Some images may show <none>@<none>; filter those out
(docker images --digests --format '{{.Repository}}@{{.Digest}}' \
   | grep -v '^<none>@' \
   | grep -v '@<none>$' \
   | grep -E '@sha256:' \
   | sort -u) > "$OUT_DIR/images.digests.txt"

# Save raw JSON metadata (one JSON object per line)
docker images --format json > "$OUT_DIR/images.json"

# Write a simple README for this snapshot
cat > "$OUT_DIR/README.txt" <<EOF
Docker Images Snapshot - $TS

Files:
- images.tags.txt    : List of repository:tag (excludes dangling <none> tags)
- images.digests.txt : List of repository@sha256:digest (preferred for exact restore)
- images.json        : Raw metadata (one JSON object per line)

Restore order of preference:
1) Use images.digests.txt for exact image content
2) Fallback to images.tags.txt which pulls latest for each tag

To restore using the companion script:
  restore_docker_images.sh -f "$OUT_DIR/images.digests.txt"
  # or
  restore_docker_images.sh -f "$OUT_DIR/images.tags.txt"
EOF

# Convenience symlink to latest snapshot
mkdir -p "$BACKUP_ROOT"
ln -sfn "$OUT_DIR" "$BACKUP_ROOT/latest"

printf "Saved Docker images list to: %s\n" "$OUT_DIR"
printf "Files created:\n"
printf "  - %s\n" "$OUT_DIR/images.tags.txt" "$OUT_DIR/images.digests.txt" "$OUT_DIR/images.json"

