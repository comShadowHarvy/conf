#!/usr/bin/env bash
# restore_docker_images.sh
# Restore Docker images from a saved list by pulling them.
# Usage:
#   restore_docker_images.sh [-f path_to_list] [--prefer-digests]
#   If -f is omitted, tries: ~/docker-backups/images/latest/images.digests.txt then images.tags.txt
# List format:
#   - tags file   : repository:tag
#   - digests file: repository@sha256:<digest>

set -euo pipefail

PREFER_DIGESTS=0
LIST_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--file)
      LIST_FILE="${2-}"
      shift 2
      ;;
    --prefer-digests)
      PREFER_DIGESTS=1
      shift
      ;;
    -h|--help)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# Check docker availability
if ! command -v docker >/dev/null 2>&1; then
  printf "Error: docker CLI not found in PATH.\n" >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  printf "Error: Docker daemon is not running or not accessible.\n" >&2
  exit 1
fi

if [[ -z "$LIST_FILE" ]]; then
  BASE="$HOME/docker-backups/images/latest"
  if [[ $PREFER_DIGESTS -eq 1 && -f "$BASE/images.digests.txt" ]]; then
    LIST_FILE="$BASE/images.digests.txt"
  elif [[ -f "$BASE/images.digests.txt" ]]; then
    LIST_FILE="$BASE/images.digests.txt"
  elif [[ -f "$BASE/images.tags.txt" ]]; then
    LIST_FILE="$BASE/images.tags.txt"
  else
    echo "Error: Could not find a default list file. Use -f to specify one." >&2
    exit 1
  fi
fi

if [[ ! -f "$LIST_FILE" ]]; then
  echo "Error: List file not found: $LIST_FILE" >&2
  exit 1
fi

echo "Restoring Docker images from: $LIST_FILE"
FAIL=0
TOTAL=0
OK=0

# Read non-empty, non-comment lines
while IFS= read -r line; do
  line_trimmed="${line%%#*}"           # strip trailing comments
  line_trimmed="${line_trimmed%%[$'\r\n']*}"
  line_trimmed="${line_trimmed##+([[:space:]])}"
  if [[ -z "$line_trimmed" ]]; then
    continue
  fi
  ((TOTAL++))
  echo "-> Pulling $line_trimmed"
  if docker pull "$line_trimmed"; then
    ((OK++))
  else
    ((FAIL++))
    echo "!! Failed: $line_trimmed" >&2
  fi
done < "$LIST_FILE"

echo "" 
echo "Restore complete: $OK succeeded, $FAIL failed, out of $TOTAL entries."
if [[ $FAIL -gt 0 ]]; then
  echo "Some images failed to pull. If they are private, login first, e.g.:"
  echo "  docker login registry.example.com"
  exit 1
fi

