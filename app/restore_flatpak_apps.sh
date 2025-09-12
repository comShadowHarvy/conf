#!/usr/bin/env bash
# restore_flatpak_apps.sh
# Restore Flatpak remotes and apps from saved TSV lists.
# Usage:
#   restore_flatpak_apps.sh [-f apps.tsv] [-r remotes.tsv]
#   If not provided, defaults to ~/flatpak-backups/latest/{apps.tsv,remotes.tsv}
# Behavior:
#   - Adds missing remotes (name+url), with gpg-verify flag if present
#   - Installs apps for each row: installation (user/system), origin, application, branch, arch
#   - Non-interactive install

set -euo pipefail

APPS_FILE=""
REMOTES_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--file)
      APPS_FILE="${2-}"; shift 2;;
    -r|--remotes)
      REMOTES_FILE="${2-}"; shift 2;;
    -h|--help)
      sed -n '2,20p' "$0"; exit 0;;
    *) echo "Unknown argument: $1" >&2; exit 1;;
  esac
done

# Check flatpak availability
if ! command -v flatpak >/dev/null 2>&1; then
  printf "Error: flatpak CLI not found in PATH.\n" >&2
  exit 1
fi

BASE="$HOME/flatpak-backups/latest"
APPS_FILE=${APPS_FILE:-"$BASE/apps.tsv"}
REMOTES_FILE=${REMOTES_FILE:-"$BASE/remotes.tsv"}

if [[ ! -f "$APPS_FILE" ]]; then
  echo "Error: Apps file not found: $APPS_FILE" >&2
  exit 1
fi
if [[ ! -f "$REMOTES_FILE" ]]; then
  echo "Warning: Remotes file not found: $REMOTES_FILE (will try to use existing remotes)" >&2
fi

# Add remotes if missing
if [[ -f "$REMOTES_FILE" ]]; then
  echo "Restoring remotes from: $REMOTES_FILE"
  tail -n +2 "$REMOTES_FILE" | while IFS=$'\t' read -r name url; do
    [[ -z "$name" || -z "$url" ]] && continue
    if flatpak remotes --columns=name | awk 'NR>1 {print $1}' | grep -qx "$name"; then
      echo "- Remote exists: $name"
    else
      echo "- Adding remote: $name ($url)"
      flatpak remote-add --gpg-verify "$name" "$url"
    fi
  done
fi

# Restore apps
echo "Restoring apps from: $APPS_FILE"
TOTAL=0
OK=0
FAIL=0

# Header: application\tarch\tbranch\torigin\tinstallation
while IFS=$'\t' read -r application arch branch origin installation; do
  # skip header and empty lines
  if [[ "$application" == "application" || -z "$application" ]]; then
    continue
  fi
  ((TOTAL++))

  # Determine target installation
  INSTALL_OPT="--user"
  if [[ "$installation" == "system" ]]; then
    INSTALL_OPT="--system"
  fi

  # Build install ref: app/id//branch (arch auto if not specified)
  REF="$application//${branch:-stable}"

  echo "-> Installing ($installation) $application (origin=$origin, branch=${branch:-stable})"
  if flatpak install -y $INSTALL_OPT "$origin" "$REF" >/dev/null; then
    ((OK++))
  else
    ((FAIL++))
    echo "!! Failed: $application ($origin $REF)" >&2
  fi

done < "$APPS_FILE"

echo ""
echo "Restore complete: $OK succeeded, $FAIL failed, out of $TOTAL entries."
if [[ $FAIL -gt 0 ]]; then
  echo "Some apps failed to install. Check remotes, network or try manually."
  exit 1
fi

