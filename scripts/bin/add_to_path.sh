#!/usr/bin/env bash
# ==============================================================================
# Shell PATH Configurator (add_to_path.sh)
#
# Detects the active shell (fish, bash, zsh, etc.) and adds a target directory
# (defaults to ~/git/conf/scripts/bin) to PATH so scripts can be run directly
# as installed executable commands.
#
# For Fish:
#   - Command mode: runs 'fish_add_path -U <dir>' (universal variable, instant)
#   - File mode: updates ~/.config/fish/config.fish
# For Bash / Zsh:
#   - File mode: updates ~/.bashrc or ~/.zshrc
#   - Session: exports PATH directly if sourced, or prints command/eval snippet
# ==============================================================================

set -e

# --- Color Definitions ---
if [ -t 1 ]; then
  BOLD="\033[1m"
  DIM="\033[2m"
  GREEN="\033[0;32m"
  BLUE="\033[0;34m"
  CYAN="\033[0;36m"
  YELLOW="\033[1;33m"
  MAGENTA="\033[0;35m"
  RED="\033[0;31m"
  RESET="\033[0m"
else
  BOLD=""
  DIM=""
  GREEN=""
  BLUE=""
  CYAN=""
  YELLOW=""
  MAGENTA=""
  RED=""
  RESET=""
fi

# --- Default Settings ---
TARGET_INPUT=""
TARGET_DIR=""
RESOLVE_NOTE=""
OVERRIDE_SHELL=""
FISH_METHOD="both" # Options: command, file, both
DRY_RUN=false
FIX_PERMS=false
CONFIGURE_ALL=false
EVAL_MODE=false

# --- Sourcing Detection ---
IS_SOURCED=false
if [ -n "$ZSH_VERSION" ]; then
  case "$ZSH_EVAL_CONTEXT" in *:file) IS_SOURCED=true ;; esac
elif [ -n "$BASH_VERSION" ]; then
  if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    IS_SOURCED=true
  fi
fi

# --- Helper Functions ---
print_banner() {
  echo -e "${BOLD}${CYAN}======================================================${RESET}"
  echo -e "${BOLD}${CYAN}   🚀 Shell PATH Configurator & Command Installer    ${RESET}"
  echo -e "${BOLD}${CYAN}======================================================${RESET}"
}

usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS] [DIRECTORY]

Detects the active shell and adds a folder to PATH so scripts inside
can be run directly as installed commands.

Arguments:
  [DIRECTORY]                 Target directory to add to PATH
                              (Default: ~/git/conf/scripts/bin)

Options:
  -s, --shell <name>          Override detected shell: fish, bash, zsh, all
  -a, --all                   Configure PATH across all installed shells (fish, bash, zsh)
  -m, --fish-method <method>  Fish configuration method:
                                command : Universal variable via 'fish_add_path -U' (instant)
                                file    : Append to ~/.config/fish/config.fish
                                both    : Apply live command AND config file (default)
  -x, --fix-perms             Ensure scripts in target folder have execute (+x) permissions
  -n, --dry-run               Preview changes without modifying any files or environment
  -e, --eval                  Output only the shell export statement for eval: eval "\$($0 --eval)"
  -h, --help                  Show this help message

Examples:
  $(basename "$0")                          # Detect shell and add ~/git/conf/scripts/bin
  $(basename "$0") ~/my-scripts             # Add a custom directory
  $(basename "$0") --shell fish             # Specifically configure Fish shell
  $(basename "$0") --all                    # Configure Fish, Bash, and Zsh all at once
  $(basename "$0") --dry-run                # Preview what would be added
  source $(basename "$0")                   # (in bash/zsh) update current session immediately
EOF
}

# --- Parse Arguments ---
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      if [ "$IS_SOURCED" = true ]; then return 0 2>/dev/null || true; else exit 0; fi
      ;;
    -s|--shell)
      OVERRIDE_SHELL="$2"
      shift 2
      ;;
    -a|--all)
      CONFIGURE_ALL=true
      shift
      ;;
    -m|--fish-method)
      FISH_METHOD="$2"
      shift 2
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -x|--fix-perms)
      FIX_PERMS=true
      shift
      ;;
    -e|--eval)
      EVAL_MODE=true
      shift
      ;;
    -*)
      echo -e "${RED}Error: Unknown option '$1'${RESET}" >&2
      usage >&2
      if [ "$IS_SOURCED" = true ]; then return 1 2>/dev/null || true; else exit 1; fi
      ;;
    *)
      if [ -z "$TARGET_INPUT" ]; then
        TARGET_INPUT="$1"
      else
        echo -e "${RED}Error: Unexpected argument '$1'${RESET}" >&2
        if [ "$IS_SOURCED" = true ]; then return 1 2>/dev/null || true; else exit 1; fi
      fi
      shift
      ;;
  esac
done

# --- Shell Detection Function ---
detect_shell() {
  if [ -n "$OVERRIDE_SHELL" ]; then
    echo "$OVERRIDE_SHELL|explicit --shell argument"
    return 0
  fi

  if [ "$IS_SOURCED" = true ]; then
    if [ -n "$ZSH_VERSION" ]; then
      echo "zsh|sourced inside interactive zsh"
      return 0
    elif [ -n "$BASH_VERSION" ]; then
      echo "bash|sourced inside interactive bash"
      return 0
    fi
  fi

  # Check parent process hierarchy
  local current_pid=$$
  while [ "$current_pid" -gt 1 ] 2>/dev/null; do
    local parent_pid
    parent_pid=$(ps -p "$current_pid" -o ppid= 2>/dev/null | tr -d ' ')
    [ -z "$parent_pid" ] && break
    local comm
    comm=$(ps -p "$parent_pid" -o comm= 2>/dev/null | tr -d ' ')
    case "$comm" in
      fish|zsh|bash|ksh|tcsh|csh)
        echo "$comm|process tree (parent PID $parent_pid)"
        return 0
        ;;
    esac
    current_pid="$parent_pid"
  done

  # Fallback to $SHELL environment variable
  if [ -n "$SHELL" ]; then
    local base="${SHELL##*/}"
    case "$base" in
      fish|zsh|bash|ksh|tcsh|csh)
        echo "$base|login shell (\$SHELL: $SHELL)"
        return 0
        ;;
    esac
  fi

  echo "bash|fallback default"
}

# --- Directory Resolution Function ---
resolve_target_dir() {
  local input="$1"
  local resolved=""

  if [ -z "$input" ]; then
    # Default is ~/git/conf/scripts/bin (or ~/git/conf/scripts/bit if specifically created)
    if [ -d "$HOME/git/conf/scripts/bit" ]; then
      resolved="$HOME/git/conf/scripts/bit"
      RESOLVE_NOTE="Default target selected: ~/git/conf/scripts/bit"
    elif [ -d "$HOME/git/conf/scripts/bin" ]; then
      resolved="$HOME/git/conf/scripts/bin"
      RESOLVE_NOTE="Default target selected: ~/git/conf/scripts/bin"
    else
      resolved="$HOME/git/conf/scripts/bin"
      RESOLVE_NOTE="Default target ~/git/conf/scripts/bin does not exist yet"
    fi
  else
    # Tilde expansion
    case "$input" in
      "~"*) input="${HOME}${input#\~}" ;;
    esac

    # If user passed path with 'scripts/bit' but 'bit' does not exist while 'bin' does
    if [[ "$input" =~ /scripts/bit/?$ ]] && [ ! -d "$input" ]; then
      local candidate="${input%/bit*}/bin"
      if [ -d "$candidate" ]; then
        RESOLVE_NOTE="Folder '$input' not found; auto-corrected to existing '$candidate'"
        resolved="$candidate"
      else
        resolved="$input"
      fi
    else
      resolved="$input"
    fi
  fi

  if [ -d "$resolved" ]; then
    resolved="$(cd "$resolved" 2>/dev/null && pwd -P)"
  else
    resolved="$(realpath -m "$resolved" 2>/dev/null || echo "$resolved")"
  fi

  TARGET_DIR="$resolved"
}

# --- Execute Directory Resolution ---
resolve_target_dir "$TARGET_INPUT"

# If eval mode requested, just print eval string and exit
if [ "$EVAL_MODE" = true ]; then
  echo "export PATH=\"$TARGET_DIR:\$PATH\""
  if [ "$IS_SOURCED" = true ]; then return 0 2>/dev/null || true; else exit 0; fi
fi

# Detect shell
SHELL_DETECTION_RAW=$(detect_shell)
DETECTED_SHELL="${SHELL_DETECTION_RAW%%|*}"
SHELL_DETECT_METHOD="${SHELL_DETECTION_RAW##*|}"

# Handle --all
if [ "$CONFIGURE_ALL" = true ]; then
  SHELLS_TO_CONFIGURE=()
  command -v fish >/dev/null 2>&1 && SHELLS_TO_CONFIGURE+=("fish")
  command -v bash >/dev/null 2>&1 && SHELLS_TO_CONFIGURE+=("bash")
  command -v zsh >/dev/null 2>&1 && SHELLS_TO_CONFIGURE+=("zsh")
  if [ ${#SHELLS_TO_CONFIGURE[@]} -eq 0 ]; then
    SHELLS_TO_CONFIGURE=("$DETECTED_SHELL")
  fi
else
  SHELLS_TO_CONFIGURE=("$DETECTED_SHELL")
fi

# --- Directory Inspection ---
DIR_EXISTS=false
TOTAL_FILES=0
EXEC_FILES=0
SAMPLE_SCRIPTS=()

if [ -d "$TARGET_DIR" ]; then
  DIR_EXISTS=true
  TOTAL_FILES=$(find "$TARGET_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l)
  EXEC_FILES=$(find "$TARGET_DIR" -maxdepth 1 -type f -executable 2>/dev/null | wc -l)
  
  # Sample executable names for display (excluding documentation / non-code assets)
  while IFS= read -r f; do
    [ -n "$f" ] && SAMPLE_SCRIPTS+=("$(basename "$f")")
    [ ${#SAMPLE_SCRIPTS[@]} -ge 8 ] && break
  done < <(find "$TARGET_DIR" -maxdepth 1 -type f -executable \
    ! -name "*.md" ! -name "*.txt" ! -name "*.html" ! -name "*.json" \
    ! -name "*.yaml" ! -name "*.yml" ! -name "*.example" ! -name "*.hc22000" \
    ! -name "*.orig*" -printf "%f\n" 2>/dev/null | sort)
fi

# Fix permissions if requested
if [ "$FIX_PERMS" = true ] && [ "$DIR_EXISTS" = true ]; then
  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[Dry-Run] Would make script files in '$TARGET_DIR' executable (chmod +x)${RESET}"
  else
    # Make .sh, .py, and files without extension executable if they have shebangs or are scripts
    find "$TARGET_DIR" -maxdepth 1 -type f \( -name "*.sh" -o -name "*.py" -o ! -name "*.*" \) \
      ! -name "*.md" ! -name "*.txt" ! -name "*.json" ! -name "*.yaml" \
      -exec chmod +x {} + 2>/dev/null || true
    TOTAL_FILES=$(find "$TARGET_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l)
    EXEC_FILES=$(find "$TARGET_DIR" -maxdepth 1 -type f -executable 2>/dev/null | wc -l)
  fi
fi

# --- Display Overview ---
print_banner
echo -e "${BOLD}Target Folder:${RESET}    ${GREEN}$TARGET_DIR${RESET}"
if [ -n "$RESOLVE_NOTE" ]; then
  echo -e "${DIM}               ℹ $RESOLVE_NOTE${RESET}"
fi

if [ "$DIR_EXISTS" = true ]; then
  echo -e "${BOLD}Folder Status:${RESET}    ${GREEN}Found ($TOTAL_FILES files, $EXEC_FILES executable scripts)${RESET}"
  if [ ${#SAMPLE_SCRIPTS[@]} -gt 0 ]; then
    echo -e "${BOLD}Sample Scripts:${RESET}   ${CYAN}${SAMPLE_SCRIPTS[*]} ...${RESET}"
  fi
else
  echo -e "${BOLD}Folder Status:${RESET}    ${YELLOW}⚠️ Directory does not exist yet (will still be added to PATH)${RESET}"
fi

echo -e "${BOLD}Detected Shell:${RESET}   ${MAGENTA}$DETECTED_SHELL${RESET} ${DIM}($SHELL_DETECT_METHOD)${RESET}"
if [ "$CONFIGURE_ALL" = true ]; then
  echo -e "${BOLD}Configuring:${RESET}      ${BLUE}All installed shells (${SHELLS_TO_CONFIGURE[*]})${RESET}"
fi
if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}${BOLD}Mode:${RESET}             ${YELLOW}DRY-RUN (no files or environment variables modified)${RESET}"
fi
echo -e "${BOLD}${CYAN}------------------------------------------------------${RESET}"

# --- Shell Configuration Implementations ---

configure_fish() {
  local target="$1"
  local fish_cfg="$HOME/.config/fish/config.fish"
  echo -e "\n${BOLD}${MAGENTA}🐟 Configuring Fish Shell:${RESET}"

  # 1. Command execution via fish_add_path -U (Universal variable)
  if [ "$FISH_METHOD" = "command" ] || [ "$FISH_METHOD" = "both" ]; then
    echo -e "  ${BOLD}[Method 1: Interactive / Live Command]${RESET}"
    if command -v fish >/dev/null 2>&1; then
      # Check if already in fish path
      local already_in_fish=false
      if fish -c "contains '$target' \$PATH; or contains '$target' \$fish_user_paths" >/dev/null 2>&1; then
        already_in_fish=true
      fi

      if [ "$already_in_fish" = true ]; then
        echo -e "    ${BLUE}ℹ Already present in Fish universal PATH (\$fish_user_paths)${RESET}"
      else
        if [ "$DRY_RUN" = true ]; then
          echo -e "    ${YELLOW}[Dry-Run] Would run: fish -c \"fish_add_path -U '$target'\"${RESET}"
        else
          fish -c "fish_add_path -U '$target'"
          echo -e "    ${GREEN}✔ Executed: fish_add_path -U '$target'${RESET}"
          echo -e "    ${DIM}  Universal variable set. Active IMMEDIATELY in all Fish sessions!${RESET}"
        fi
      fi
    else
      echo -e "    ${YELLOW}⚠️ 'fish' binary not found in current PATH to execute live command.${RESET}"
    fi
  fi

  # 2. File persistence in config.fish
  if [ "$FISH_METHOD" = "file" ] || [ "$FISH_METHOD" = "both" ]; then
    echo -e "  ${BOLD}[Method 2: Persistent Configuration File]${RESET}"
    local cfg_dir="$(dirname "$fish_cfg")"
    
    if [ "$DRY_RUN" = false ] && [ ! -d "$cfg_dir" ]; then
      mkdir -p "$cfg_dir"
    fi

    local entry="fish_add_path $target"
    if [ -f "$fish_cfg" ] && grep -Fq "$target" "$fish_cfg"; then
      echo -e "    ${BLUE}ℹ Entry already exists in $fish_cfg${RESET}"
    else
      if [ "$DRY_RUN" = true ]; then
        echo -e "    ${YELLOW}[Dry-Run] Would append '$entry' to $fish_cfg${RESET}"
      else
        echo "" >> "$fish_cfg"
        echo "# Custom scripts path added by add_to_path.sh on $(date +'%Y-%m-%d %H:%M')" >> "$fish_cfg"
        echo "$entry" >> "$fish_cfg"
        echo -e "    ${GREEN}✔ Appended to $fish_cfg:${RESET} ${CYAN}$entry${RESET}"
      fi
    fi
  fi
}

configure_bash() {
  local target="$1"
  local bashrc="$HOME/.bashrc"
  echo -e "\n${BOLD}${MAGENTA}🐚 Configuring Bash Shell:${RESET}"

  # 1. File Persistence
  echo -e "  ${BOLD}[Configuration File: ~/.bashrc]${RESET}"
  local export_line="export PATH=\"$target:\$PATH\""
  
  if [ -f "$bashrc" ] && grep -Fq "$target" "$bashrc"; then
    echo -e "    ${BLUE}ℹ Entry already exists in $bashrc${RESET}"
  else
    if [ "$DRY_RUN" = true ]; then
      echo -e "    ${YELLOW}[Dry-Run] Would append '$export_line' to $bashrc${RESET}"
    else
      echo "" >> "$bashrc"
      echo "# Custom scripts path added by add_to_path.sh on $(date +'%Y-%m-%d %H:%M')" >> "$bashrc"
      echo "$export_line" >> "$bashrc"
      echo -e "    ${GREEN}✔ Appended to $bashrc:${RESET} ${CYAN}$export_line${RESET}"
    fi
  fi

  # 2. Current Session Handling
  if [ "$IS_SOURCED" = true ] && [ "$DETECTED_SHELL" = "bash" ]; then
    export PATH="$target:$PATH"
    echo -e "    ${GREEN}✔ Current interactive Bash session updated immediately!${RESET}"
  else
    echo -e "  ${BOLD}[Active Session Command]${RESET}"
    echo -e "    Run now in current terminal: ${BOLD}${CYAN}$export_line${RESET}"
    echo -e "    Or reload:                   ${BOLD}${CYAN}source ~/.bashrc${RESET}"
  fi
}

configure_zsh() {
  local target="$1"
  local zshrc="$HOME/.zshrc"
  echo -e "\n${BOLD}${MAGENTA}⚡ Configuring Zsh Shell:${RESET}"

  # 1. File Persistence
  echo -e "  ${BOLD}[Configuration File: ~/.zshrc]${RESET}"
  local export_line="export PATH=\"$target:\$PATH\""

  if [ -f "$zshrc" ] && grep -Fq "$target" "$zshrc"; then
    echo -e "    ${BLUE}ℹ Entry already exists in $zshrc${RESET}"
  else
    if [ "$DRY_RUN" = true ]; then
      echo -e "    ${YELLOW}[Dry-Run] Would append '$export_line' to $zshrc${RESET}"
    else
      echo "" >> "$zshrc"
      echo "# Custom scripts path added by add_to_path.sh on $(date +'%Y-%m-%d %H:%M')" >> "$zshrc"
      echo "$export_line" >> "$zshrc"
      echo -e "    ${GREEN}✔ Appended to $zshrc:${RESET} ${CYAN}$export_line${RESET}"
    fi
  fi

  # 2. Current Session Handling
  if [ "$IS_SOURCED" = true ] && [ "$DETECTED_SHELL" = "zsh" ]; then
    export PATH="$target:$PATH"
    echo -e "    ${GREEN}✔ Current interactive Zsh session updated immediately!${RESET}"
  else
    echo -e "  ${BOLD}[Active Session Command]${RESET}"
    echo -e "    Run now in current terminal: ${BOLD}${CYAN}$export_line${RESET}"
    echo -e "    Or reload:                   ${BOLD}${CYAN}source ~/.zshrc${RESET}"
  fi
}

configure_generic() {
  local sh_name="$1"
  local target="$2"
  local profile="$HOME/.profile"
  echo -e "\n${BOLD}${MAGENTA}🔹 Configuring $sh_name Shell:${RESET}"

  local export_line="export PATH=\"$target:\$PATH\""
  if [ -f "$profile" ] && grep -Fq "$target" "$profile"; then
    echo -e "    ${BLUE}ℹ Entry already exists in $profile${RESET}"
  else
    if [ "$DRY_RUN" = true ]; then
      echo -e "    ${YELLOW}[Dry-Run] Would append '$export_line' to $profile${RESET}"
    else
      echo "" >> "$profile"
      echo "# Custom scripts path added by add_to_path.sh on $(date +'%Y-%m-%d %H:%M')" >> "$profile"
      echo "$export_line" >> "$profile"
      echo -e "    ${GREEN}✔ Appended to $profile:${RESET} ${CYAN}$export_line${RESET}"
    fi
  fi
}

# --- Execute Configuration for Identified Shells ---
for sh_target in "${SHELLS_TO_CONFIGURE[@]}"; do
  case "$sh_target" in
    fish) configure_fish "$TARGET_DIR" ;;
    bash) configure_bash "$TARGET_DIR" ;;
    zsh)  configure_zsh "$TARGET_DIR" ;;
    *)    configure_generic "$sh_target" "$TARGET_DIR" ;;
  esac
done

# --- Verification & Summary ---
echo -e "\n${BOLD}${CYAN}======================================================${RESET}"
echo -e "${BOLD}${GREEN}✅ Configuration Complete!${RESET}"

if [ "$DIR_EXISTS" = true ] && [ "$EXEC_FILES" -gt 0 ] && [ "$DRY_RUN" = false ]; then
  # Try to verify resolution using sample script
  SAMPLE_CMD="${SAMPLE_SCRIPTS[0]:-}"
  if [ -n "$SAMPLE_CMD" ]; then
    echo -e "\n${BOLD}Quick Test:${RESET}"
    if [ "$DETECTED_SHELL" = "fish" ] && command -v fish >/dev/null 2>&1; then
      RESOLVED_TEST=$(fish -c "which $SAMPLE_CMD 2>/dev/null" || true)
      if [ -n "$RESOLVED_TEST" ]; then
        echo -e "  Fish test: ${GREEN}✔ '$SAMPLE_CMD' -> $RESOLVED_TEST${RESET}"
      else
        echo -e "  Fish test: '${SAMPLE_CMD}' will be available upon terminal refresh."
      fi
    elif [ "$DETECTED_SHELL" = "bash" ]; then
      echo -e "  To use in your current terminal now, run:"
      echo -e "    ${BOLD}${CYAN}export PATH=\"$TARGET_DIR:\$PATH\"${RESET}"
    elif [ "$DETECTED_SHELL" = "zsh" ]; then
      echo -e "  To use in your current terminal now, run:"
      echo -e "    ${BOLD}${CYAN}export PATH=\"$TARGET_DIR:\$PATH\"${RESET}"
    fi
  fi
fi

echo -e "\n${DIM}All scripts inside ${TARGET_DIR} can now be run like standard commands!${RESET}"
echo -e "${BOLD}${CYAN}======================================================${RESET}"

if [ "$IS_SOURCED" = true ]; then
  return 0 2>/dev/null || true
else
  exit 0
fi
