#!/usr/bin/env bash
set -euo pipefail

# Restow all packages in this repo
REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$REPO_DIR"

TARGET_DIR=${1:-$HOME}

packages=(bash zsh git tmux nvim hyprland waybar vscode wget secrets scripts shared)

echo "Unstowing all packages from $TARGET_DIR..."
for p in "${packages[@]}"; do
  if [ -d "$p" ]; then
    stow -t "$TARGET_DIR" -D "$p" >/dev/null 2>&1 || true
  fi
done

echo "Stowing all packages to $TARGET_DIR..."
for p in "${packages[@]}"; do
  if [ -d "$p" ]; then
    echo "- $p"
    stow -t "$TARGET_DIR" "$p"
  fi
done

echo "Done."
