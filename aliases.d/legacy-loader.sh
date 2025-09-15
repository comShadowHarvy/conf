#!/usr/bin/env bash
# ------------------------------------------------------------------
# Legacy Compatibility Loader
# Loads all alias modules for scripts that expect a single .aliases file
# ------------------------------------------------------------------

# Get the directory where this script is located
ALIASES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all alias modules in order
for module_file in "$ALIASES_DIR"/*.aliases; do
  [[ -r "$module_file" ]] && source "$module_file" 2>/dev/null || {
    echo "Warning: Failed to load $(basename "$module_file")" >&2
  }
done

# Legacy compatibility marker
LEGACY_ALIASES_LOADED=1

return 0