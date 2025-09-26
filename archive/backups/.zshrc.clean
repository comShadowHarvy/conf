#!/usr/bin/env zsh
# =====================================================
# Clean Optimized Zsh Configuration (No Plugin Framework)
# Lightweight, fast, and focused on essentials
# Based on comprehensive WARP development standards
# =====================================================

# --- Performance Tracking (Uncomment to Debug) ---
# zmodload zsh/zprof
# ZSHRC_START_TIME=${EPOCHREALTIME} # Use Zsh's high-resolution timer

# --- Core Environment Setup (Set Early) ---
export ZDOTDIR="${ZDOTDIR:-$HOME}"

# XDG Base Directory Specification (use defaults if not set)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$ZDOTDIR/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$ZDOTDIR/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$ZDOTDIR/.cache}"

# Ensure base directories exist
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"

# --- Core Zsh Options (Set Early) ---
# History configuration
setopt BANG_HIST                      # Treat '!' specially during history expansion
setopt EXTENDED_HISTORY               # Write the history file in the ':start:elapsed;command' format.
setopt INC_APPEND_HISTORY             # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY                  # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST         # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS               # Don't record an entry that was just recorded.
setopt HIST_IGNORE_ALL_DUPS           # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS              # Don't display duplicate entries when searching.
setopt HIST_IGNORE_SPACE              # Don't record entries starting with a space.
setopt HIST_SAVE_NO_DUPS              # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS             # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY                    # Don't execute history expansion commands immediately.

# Directory navigation
setopt AUTO_CD                        # If command is a path to a directory, cd into it.
setopt AUTO_PUSHD                     # Automatically push directories onto the stack.
setopt PUSHD_IGNORE_DUPS              # Don't push directories onto the stack if they are already there.
setopt PUSHD_SILENT                   # Do not print the directory stack after pushd or popd.
setopt PUSHD_TO_HOME                  # Have pushd with no arguments act like `pushd $HOME`.

# Globbing and completion
setopt EXTENDED_GLOB                  # Use extended globbing syntax.
setopt GLOB_DOTS                      # Include hidden files in globbing results.
setopt NO_BEEP                        # No annoying beeps.
setopt INTERACTIVE_COMMENTS           # Allow comments in interactive shell.
setopt COMPLETE_IN_WORD               # Complete from both ends of a word.
setopt ALWAYS_TO_END                  # Move cursor to the end of a completed word.
setopt CORRECT                        # Auto-correct commands

# History settings
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
HIST_IGNORE_PATTERNS="ls|cd|pwd|exit|sudo reboot|history|cd -|cd ..|eza*|lsd*"

# --- Editor Configuration ---
export EDITOR="nvim"
export VISUAL="nvim"

# --- Path Configuration (using Zsh's typeset -U for uniqueness) ---
typeset -U path # Ensures path entries are unique

# Build path array with proper precedence
path=(
  "$HOME/app"                   # Custom applications
  "$HOME/.local/bin"            # Standard user binary location
  "$HOME/bin"                   # Legacy user binary location
  "$XDG_DATA_HOME/../bin"       # Potential location from install scripts
  $path                         # Include existing system path
)

# Add repo app directory to path if it exists and contains executables
[[ -d "./app" && -x "./app/updateall" ]] && path=("./app" $path)

# Source environment variables from specific file if it exists
[[ -f "$XDG_DATA_HOME/../bin/env" ]] && source "$XDG_DATA_HOME/../bin/env"

# --- Configuration Options & Runtime Toggles ---
# User configuration - easy to customize
INSTALL_MISSING_TOOLS=${INSTALL_MISSING_TOOLS:-true}      # Auto-install missing tools (interactively)
SHOW_POKEMON=${SHOW_POKEMON:-true}                        # Show Pokémon on startup (can impact startup time)
SHOW_WELCOME_MESSAGE=${SHOW_WELCOME_MESSAGE:-true}        # Show welcome message
USE_OHMYPOSH=${USE_OHMYPOSH:-true}                        # Use Oh My Posh prompt
AUTO_CHECK_UPDATES=${AUTO_CHECK_UPDATES:-true}            # Auto-check for Git updates on cd (only in trusted dirs)

# Trusted Git directories (prevent auto-updates in untrusted locations)
TRUSTED_GIT_DIRS=(
  "$HOME/git"
  "$HOME/projects"
  "$HOME/work"
  "$HOME/personal" 
  "$HOME/dev"
)

# --- FZF Configuration ---
export FZF_DEFAULT_OPTS="--layout=reverse --exact --border=rounded --margin=3% --color=dark --height 60% --multi"

# Use fd/rg if available for FZF with intelligent fallbacks
if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude .cache'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules'
elif (( $+commands[rg] )); then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*" --glob "!node_modules/*"'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# FZF keybindings (if fzf is installed)
if (( $+commands[fzf] )); then
  # Load FZF keybindings if available
  if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
  elif [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh
  fi
fi

# --- Helper Functions ---

# Enhanced logging with proper error handling
_log_message() {
  local level=$1 message=$2 color
  case $level in
    "INFO")    color="32" ;; # Green
    "WARNING") color="33" ;; # Yellow
    "ERROR")   color="31" ;; # Red
    "DEBUG")   color="36" ;; # Cyan
    *)         color="37" ;; # White
  esac
  print -P "%F{$color}[%D{%T}] [$level] $message%f"
}

# Safer sourcing with debug info
_safe_source() {
  [[ -f "$1" ]] && { source "$1"; return 0; } || { [[ -n "$DEBUG_ZSHRC" ]] && _log_message "DEBUG" "File not found: $1"; return 1; }
}

# Enhanced error handling
_error_exit() {
  _log_message "ERROR" "$1"
  return ${2:-1}
}

# Robust cache validation helper (24-hour expiry)
_is_cache_valid() {
  local cache_file="$1"
  [[ -f "$cache_file" ]] && (( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0) < 86400 ))
}

# Safe download helper with progress and retries
_safe_download() {
  local url="$1" destination="$2" message="${3:-"Downloading $url"}"
  [[ -f "$destination" ]] && return 0
  
  _log_message "INFO" "$message"
  mkdir -p "$(dirname "$destination")"
  
  local cmd
  if (( $+commands[curl] )); then
    cmd="curl -fLs --connect-timeout 10 --max-time 30"
  elif (( $+commands[wget] )); then
    cmd="wget -qO-"
  else
    _error_exit "Cannot download: curl or wget not found."
    return 1
  fi
  
  $cmd "$url" > "$destination" || { _error_exit "Failed to download $url"; return 1; }
}

# Package manager detection (cached)
_detect_package_manager() {
  local cache_file="$XDG_CACHE_HOME/zsh/package_manager"
  # Check cache validity (1 day)
  if [[ -f "$cache_file" ]] && (( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0) < 86400 )); then
    cat "$cache_file"
    return 0
  fi

  # Detect system package manager
  local manager=""
  # Order matters: prefer specific managers if multiple exist (e.g., yay over pacman)
  for pm in yay apt-get pacman dnf yum zypper brew apk; do
    (( $+commands[$pm] )) && { manager="$pm"; break; }
  done

  mkdir -p "$(dirname "$cache_file")"
  print -r -- "$manager" > "$cache_file"
  print -r -- "$manager"
}

# Simplified installation helper (interactive)
_install_if_missing() {
  local cmd=$1 package=${2:-$1} message=${3:-"$package not found. Install? [y/N]"} pm install_cmd update_cmd
  # Skip if command exists or auto-install disabled
  (( $+commands[$cmd] )) && return 0
  [[ "$INSTALL_MISSING_TOOLS" != "true" ]] && return 1

  # Ask for confirmation
  print -n "$message "
  read -r response
  [[ ! "$response" =~ ^[Yy]$ ]] && return 1

  _log_message "INFO" "Attempting to install $package..."

  # Try custom install script first (proper path resolution)
  if [[ -x "./install.sh" ]]; then
      _log_message "INFO" "Using local installer: ./install.sh"
      if ./install.sh "$package"; then
          (( $+commands[$cmd] )) && { _log_message "INFO" "$package installed successfully via local script."; return 0; }
          _log_message "WARNING" "Install script ran but command '$cmd' still not found."
      else
          _log_message "WARNING" "Local install script failed for $package."
      fi
  fi

  # Fall back to system package manager
  pm=$(_detect_package_manager)
  case "$pm" in
    apt-get) update_cmd="sudo apt-get update"; install_cmd="sudo apt-get install -y" ;;
    pacman|yay) install_cmd="sudo $pm -S --noconfirm" ;; # yay might prompt anyway
    dnf) install_cmd="sudo dnf install -y" ;;
    yum) install_cmd="sudo yum install -y" ;;
    zypper) install_cmd="sudo zypper install -y" ;;
    brew) install_cmd="brew install" ;;
    apk) update_cmd="sudo apk update"; install_cmd="sudo apk add" ;;
    *) _log_message "ERROR" "Unsupported package manager: $pm. Cannot install $package."; return 1 ;;
  esac

  # Run update command if defined (e.g., for apt, apk)
  if [[ -n "$update_cmd" ]]; then
      _log_message "INFO" "Running package list update ($pm)..."
      eval "$update_cmd" || { _log_message "ERROR" "Package list update failed."; return 1; }
  fi

  # Run install command
  _log_message "INFO" "Using $pm to install $package..."
  if eval "$install_cmd $package"; then
      if (( $+commands[$cmd] )); then
          _log_message "INFO" "$package installed successfully via $pm."
          return 0
      else
          _log_message "ERROR" "Installation via $pm seemed successful, but command '$cmd' is still not found."
          return 1
      fi
  else
      _log_message "ERROR" "Installation via $pm failed for $package."
      return 1
  fi
}

# Defer slow startup visuals to run *after* the first prompt is drawn
# This makes the shell feel instantaneous
_run_deferred_startup_visuals() {
    # Immediately unregister this function so it only runs ONCE per session
    unset -f _run_deferred_startup_visuals
    add-zsh-hook -d precmd _run_deferred_startup_visuals

    # Show system info based on available tools and configuration
    if [[ "$SHOW_POKEMON" == "true" ]]; then
        if (( $+commands[pokemon-colorscripts] )) && (( $+commands[fastfetch] )); then
            # Run pokemon piped to fastfetch with custom config
            pokemon-colorscripts --no-title -s -r | \
            fastfetch -c "$HOME/.config/fastfetch/config-pokemon.jsonc" \
                      --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
        elif (( $+commands[pokemon-colorscripts] )); then
            # Just pokemon with appropriate size
            if [[ -n "$TMUX" ]]; then
                pokemon-colorscripts --no-title -r
            else
                pokemon-colorscripts --no-title -r -b
            fi
        elif (( $+commands[fastfetch] )); then
            # Just fastfetch with appropriate sizing
            if [[ -n "$TMUX" ]]; then
                fastfetch --logo-width 15
            else
                fastfetch --logo-width 20
            fi
        fi
    elif (( $+commands[fastfetch] )); then
        # Use a compact fastfetch config for speed
        if [[ -n "$TMUX" ]]; then
            fastfetch --logo none
        else
            fastfetch --logo-width 15
        fi
    elif (( $+commands[neofetch] )); then
        # Use a faster neofetch config
        neofetch --disable packages --disable resolution --color_blocks off
    fi

    # Redraw the prompt to ensure it's neatly positioned
    zle && zle .redisplay
}

# --- Completion System (Native Zsh) ---
autoload -Uz compinit
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR"
local compinit_cache_file="$ZSH_CACHE_DIR/zcompdump"

if _is_cache_valid "$compinit_cache_file"; then
  compinit -i -C -d "$compinit_cache_file"
else
  compinit -i -d "$compinit_cache_file"
fi

# Enhanced completion styling
zstyle ':completion:*' menu select
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}%B--- %d%b%f'
zstyle ':completion:*' verbose yes
zstyle ':completion:*:warnings' format '%F{red}%BNo matches found%b%f'

# --- Shell Enhancements ---

# Function to set terminal title (matches DT's format)
_set_term_title() {
  print -Pn "\\e]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\\~}\\a"
}
# Register function to run before each prompt and upon directory change
autoload -Uz add-zsh-hook
add-zsh-hook precmd _set_term_title
add-zsh-hook chpwd _set_term_title # Update title on cd

# Optimized Git update checker - only run when needed
_check_git_updates() {
  # Skip check if disabled or not in a git repo
  [[ "$AUTO_CHECK_UPDATES" != "true" ]] && return
  # Use Zsh's built-in check for .git directory for speed
  [[ ! -d .git ]] && [[ ! -f .git ]] && return

  # Verify trusted directory status efficiently
  local is_trusted=0 current_dir="$PWD"
  for dir in "${TRUSTED_GIT_DIRS[@]}"; do
    # Ensure dir ends with / for prefix matching unless it's just $HOME
    [[ "$dir" != "$HOME" ]] && dir="${dir%/}/"
    # Check if current path starts with the trusted directory path
    [[ "$current_dir/" == "$dir"* ]] && { is_trusted=1; break; }
  done
  [[ $is_trusted -eq 0 ]] && return

  # Perform check asynchronously in the background to avoid blocking prompt
  {
    # Fetch updates quietly
    git fetch --quiet &>/dev/null
    local exit_code=$?
    if (( exit_code != 0 )); then
        # Optionally notify about fetch failure
        # print -P "%F{red}⚠ Git fetch failed in $current_dir: $PWD%f"
        return
    fi

    # Compare local and remote states
    local UPSTREAM='@{u}' LOCAL REMOTE BASE status_msg color
    LOCAL=$(git rev-parse @ 2>/dev/null)
    REMOTE=$(git rev-parse "$UPSTREAM" 2>/dev/null)

    # Only proceed if both LOCAL and REMOTE are valid commit hashes
    if [[ -n "$LOCAL" && -n "$REMOTE" ]]; then
      BASE=$(git merge-base @ "$UPSTREAM" 2>/dev/null)
      if [[ "$LOCAL" = "$REMOTE" ]]; then
        status_msg="✔ Up to date." color="green"
      elif [[ "$LOCAL" = "$BASE" ]]; then
        status_msg="⇩ Updates available (git pull)." color="blue"
      elif [[ "$REMOTE" = "$BASE" ]]; then
        status_msg="⇧ Unpushed changes (git push)." color="yellow"
      else
        status_msg="⚠ Diverged." color="red"
      fi
      # Print status message (consider adding repo name)
      print -P "%F{$color}Git status ($(basename "$current_dir")): $status_msg%f"
    fi
  } &! # Run in background, disown immediately

}

# Improved directory change hook - combines ls and git check
_enhanced_chpwd() {
  # Use exa instead of ls if available, otherwise ls
  if (( $+commands[eza] )); then
    eza --color=always --icons --group-directories-first # Customize exa flags as needed
  elif (( $+commands[lsd] )); then
    lsd --color=always --icon=auto # Customize lsd flags as needed
  else
    ls --color=auto # Standard ls
  fi
  _check_git_updates
}
add-zsh-hook chpwd _enhanced_chpwd

# Debug function for Git checking
debug_git_check() {
  print "Current dir: $PWD"
  print "Is Git repo: $(( [[ -d .git ]] || [[ -f .git ]] )) && echo Yes || echo No"
  print "AUTO_CHECK_UPDATES: $AUTO_CHECK_UPDATES"
  print "Trusted dirs: ${TRUSTED_GIT_DIRS[*]}"

  local is_trusted=0 current_dir="$PWD"
  for dir in "${TRUSTED_GIT_DIRS[@]}"; do
    [[ "$dir" != "$HOME" ]] && dir="${dir%/}/"
    [[ "$current_dir/" == "$dir"* ]] && { is_trusted=1; break; }
  done
  print "Is trusted: $(( is_trusted )) && echo Yes || echo No"
}
alias debug-git="debug_git_check"

# --- Lazy Loading Functions ---
# Define functions that load the actual tool only when first called

# Lazy load nvm
nvm() {
  unset -f nvm # Remove this lazy-load function
  export NVM_DIR="$HOME/.nvm" # Standard NVM directory
  # Source nvm.sh safely
  _safe_source "$NVM_DIR/nvm.sh"
  # Source bash_completion safely
  _safe_source "$NVM_DIR/bash_completion"
  # Call the real nvm command
  nvm "$@"
}

# Lazy load conda
conda() {
  unset -f conda # Remove this lazy-load function
  # Attempt to find conda executable (adjust path if needed)
  local conda_exe
  conda_exe=$(command -v conda 2>/dev/null) || conda_exe="$HOME/miniconda3/bin/conda" || conda_exe="$HOME/anaconda3/bin/conda"

  if [[ -x "$conda_exe" ]]; then
    # Initialize conda for Zsh
    eval "$("$conda_exe" 'shell.zsh' 'hook' 2>/dev/null)"
    # Call the real conda command
    conda "$@"
  else
    _log_message "ERROR" "Conda executable not found."
    return 1
  fi
}

# Lazy load Homebrew
brew() {
  unset -f brew # Remove this lazy-load function
  local brew_prefix brew_exe
  # Standard Homebrew locations
  local potential_prefixes=(
      "/home/linuxbrew/.linuxbrew" # Linuxbrew standard
      "$HOME/.linuxbrew"           # Linuxbrew user install
      "/opt/homebrew"              # macOS ARM64
      "/usr/local"                 # macOS Intel / legacy Linuxbrew
  )
  for prefix in "${potential_prefixes[@]}"; do
      if [[ -x "${prefix}/bin/brew" ]]; then
          brew_prefix="$prefix"
          brew_exe="${prefix}/bin/brew"
          break
      fi
  done

  if [[ -n "$brew_exe" ]]; then
      # Set up environment variables for Homebrew
      eval "$("$brew_exe" shellenv)"
      # Call the real brew command
      brew "$@"
  elif [[ "$INSTALL_MISSING_TOOLS" == "true" ]]; then
      _log_message "INFO" "Homebrew not found."
      print -n "Install Homebrew? [y/N] "
      read -r response
      if [[ "$response" =~ ^[Yy]$ ]]; then
          _log_message "INFO" "Installing Homebrew..."
          # Ensure curl and bash are available
          if ! (( $+commands[curl] )) || ! (( $+commands[bash] )); then
              _log_message "ERROR" "Cannot install Homebrew: curl and bash are required."
              return 1
          fi
          # Run the official installer
          /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
          # Try calling brew again after installation (it might require a new shell, though)
          brew "$@"
      else
          return 1
      fi
  else
      _log_message "ERROR" "Homebrew not found and auto-install is disabled."
      return 1
  fi
}

# --- Tool Configurations ---

# Zoxide (intelligent cd) - load if command exists
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh --cmd cd)" # Use --cmd cd to alias cd directly
  # Optional: alias j='z' for explicit jump if needed
fi

# --- Keybindings ---
bindkey -e # Use Emacs keybindings

# Other useful bindings
bindkey '^[[1;5C' forward-word          # Ctrl+Right
bindkey '^[[1;5D' backward-word         # Ctrl+Left
bindkey '^[[3~' delete-char             # Delete key
bindkey '^H' backward-kill-word         # Ctrl+Backspace (might vary by terminal)
bindkey '^[[Z' reverse-menu-complete   # Shift+Tab (might vary by terminal)
bindkey '^[.' insert-last-word          # Alt+.
bindkey '^[k' kill-line                 # Alt+k (might conflict)
bindkey '^[b' backward-word             # Alt+b
bindkey '^[f' forward-word              # Alt+f

# --- Modular Alias System ---

# Performance-optimized modular alias loader
_alias_module_loaded=()
_alias_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
_alias_cmd_cache="$_alias_cache_dir/aliases_cmd_cache"
mkdir -p "$_alias_cache_dir"

# Load alias module with performance caching
load_alias_module() {
  local mod="$1" file="$HOME/git/conf/aliases.d/$mod.aliases"
  local module_id="LOADED_ALIAS_MODULE_${mod//-/_}"
  
  # Skip if already loaded
  [[ -v $module_id ]] && return 0
  
  # Check if file exists and is readable
  [[ -r "$file" ]] || return 1
  
  # Source the module
  if source "$file" 2>/dev/null; then
    _alias_module_loaded+=("$mod")
    typeset -g "$module_id"=1
    return 0
  else
    _log_message "WARNING" "Failed to load alias module: $mod"
    return 1
  fi
}

# Check if command exists with 24-hour caching
_cached_command_exists() {
  local cmd="$1" cache_key="cmd_$cmd"
  local cache_file="$_alias_cmd_cache"
  
  # Create cache if it doesn't exist
  [[ -f "$cache_file" ]] || touch "$cache_file"
  
  # Check if cache is older than 24 hours
  if [[ $(find "$cache_file" -mtime +1 2>/dev/null) ]]; then
    # Cache is stale, clear it
    > "$cache_file"
  fi
  
  # Check cache first
  if grep -q "^$cache_key:" "$cache_file" 2>/dev/null; then
    local cached_result=$(grep "^$cache_key:" "$cache_file" | cut -d: -f2)
    [[ "$cached_result" == "1" ]] && return 0 || return 1
  fi
  
  # Not in cache, check command and cache result
  local result=0
  (( ${+commands[$cmd]} )) || result=1
  
  # Update cache (remove old entry if exists, add new)
  grep -v "^$cache_key:" "$cache_file" > "$cache_file.tmp" 2>/dev/null || touch "$cache_file.tmp"
  echo "$cache_key:$((1-result))" >> "$cache_file.tmp"
  mv "$cache_file.tmp" "$cache_file"
  
  return $result
}

# Lazy alias loader - runs once after first prompt
_lazy_alias_loader() {
  # Remove this hook after first run
  add-zsh-hook -d precmd _lazy_alias_loader
  
  # Load conditional modules based on available commands and env vars
  [[ "$DISABLE_YAZI_ALIASES" != "true" ]] && _cached_command_exists "yazi" && load_alias_module "15-yazi"
  [[ "$DISABLE_PACKAGE_ALIASES" != "true" ]] && { _cached_command_exists "pacman" || _cached_command_exists "brew"; } && load_alias_module "30-package"
  [[ "$DISABLE_MEDIA_ALIASES" != "true" ]] && { _cached_command_exists "yt-dlp" || _cached_command_exists "youtube-dl"; } && load_alias_module "40-media"
  [[ "$DISABLE_GIT_ALIASES" != "true" ]] && _cached_command_exists "git" && load_alias_module "50-git"
  [[ "$DISABLE_TMUX_ALIASES" != "true" ]] && _cached_command_exists "tmux" && load_alias_module "55-tmux"
  [[ "$DISABLE_AI_ALIASES" != "true" ]] && _cached_command_exists "ollama" && load_alias_module "65-ai"
  [[ "$DISABLE_DEV_ALIASES" != "true" ]] && _cached_command_exists "nvim" && load_alias_module "85-development"
  
  # Always load these (they have internal tool detection)
  load_alias_module "60-apps"      # Shell apps and custom commands
  load_alias_module "70-productivity"  # Productivity functions
  load_alias_module "75-modern"    # Modern CLI tools with fallbacks
  load_alias_module "80-performance" # CachyOS performance optimizations
  load_alias_module "90-operations" # File operations and analysis
  load_alias_module "95-aur-safe"   # AUR-safe aliases
}

# Load core modules immediately (essential for basic shell operation)
load_alias_module "00-core"     # Navigation, basic functions
load_alias_module "10-files"    # File management, directory listing
load_alias_module "20-system"   # System management, monitoring

# Register lazy loader for conditional modules
add-zsh-hook precmd _lazy_alias_loader

# --- Load Custom Configurations ---
# Source local files if they exist
_safe_source "$ZDOTDIR/.api_keys" # Be careful with sensitive data! Consider env vars or dedicated tools.
_safe_source "$ZDOTDIR/.zshrc.local" # For user-specific overrides

# Legacy .aliases support for backward compatibility
if [[ -f "$ZDOTDIR/.aliases" ]] && [[ "$USE_LEGACY_ALIASES" == "true" ]]; then
  _log_message "INFO" "Loading legacy .aliases file (consider migrating to modular system)"
  _safe_source "$ZDOTDIR/.aliases"
fi

# --- Oh My Posh (Prompt) ---
if [[ "$USE_OHMYPOSH" == "true" ]]; then
  if _install_if_missing "oh-my-posh"; then
    # Use XDG config directory for themes
    OMP_THEME_DIR="$XDG_CONFIG_HOME/oh-my-posh/themes"
    OMP_THEME_FILE="$OMP_THEME_DIR/devious-diamonds.omp.yaml" # Adjust theme name if needed
    OMP_THEME_URL="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/devious-diamonds.omp.yaml"

    # Ensure theme is available (download if missing)
    mkdir -p "$OMP_THEME_DIR"
    if _safe_download "$OMP_THEME_URL" "$OMP_THEME_FILE" "Downloading Oh My Posh theme..."; then
      # Initialize Oh My Posh
      eval "$(oh-my-posh init zsh --config "$OMP_THEME_FILE")"
    else
      _log_message "WARNING" "Failed to download Oh My Posh theme. Using default prompt."
    fi
  else
    _log_message "WARNING" "Oh My Posh not available. Using default prompt."
  fi
fi

# --- Feature Functions & Aliases ---

# Font installation function (run once)
_install_fonts() {
  local fonts_dir="$XDG_DATA_HOME/fonts"
  local fonts_lock_file="$XDG_CACHE_HOME/zsh/fonts_installed"

  # Check if already run or if nerd fonts are already available
  if [[ -f "$fonts_lock_file" ]]; then
    return 0
  fi
  
  # Check if nerd fonts are already installed system-wide or user-wide
  if fc-list 2>/dev/null | grep -qi "nerd.*font"; then
    # Fonts are available, create lock file to prevent future prompts
    mkdir -p "$(dirname "$fonts_lock_file")"
    touch "$fonts_lock_file"
    return 0
  fi

  print -n "Set up Nerd Fonts? (Requires wget/curl and unzip) [y/N] "
  read -r response
  [[ ! "$response" =~ ^[Yy]$ ]] && return 1

  # Check dependencies
  if ! (( $+commands[unzip] )) || ! ((( $+commands[wget] )) || (( $+commands[curl] ))); then
      _log_message "ERROR" "Cannot install fonts: wget/curl and unzip are required."
      return 1
  fi

  _log_message "INFO" "Setting up Nerd Fonts in $fonts_dir..."
  mkdir -p "$fonts_dir"

  local fonts=(BitstreamVeraSansMono CodeNewRoman FiraCode Hack JetBrainsMono SourceCodePro UbuntuMono)
  local version='3.2.1' # Use a recent Nerd Fonts version
  local total=${#fonts[@]} current=0 success_count=0

  for font in "${fonts[@]}"; do
    current=$((current + 1))
    _log_message "INFO" "Installing font ($current/$total): $font"
    local zip_file="/tmp/${font}.zip"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/${font}.zip"

    if _safe_download "$download_url" "$zip_file"; then
      unzip -qo "$zip_file" -d "$fonts_dir" # -q quiet, -o overwrite
      local unzip_status=$?
      rm -f "$zip_file" # Clean up zip file regardless of unzip status
      if (( unzip_status == 0 )); then
          success_count=$((success_count + 1))
      else
          _log_message "WARNING" "Failed to unzip $font.zip"
      fi
    fi
  done

  # Clean up Windows Compatible fonts if they exist
  find "$fonts_dir" -name '*Windows Compatible*' -type f -delete 2>/dev/null

  # Update font cache if fc-cache exists
  if (( $+commands[fc-cache] )); then
    _log_message "INFO" "Updating font cache..."
    fc-cache -f -v # Force update, verbose output
  fi

  if (( success_count > 0 )); then
      # Create lock file on success
      mkdir -p "$(dirname "$fonts_lock_file")"
      touch "$fonts_lock_file"
      _log_message "INFO" "Nerd Fonts installation complete ($success_count fonts installed/updated)."
  else
      _log_message "ERROR" "Nerd Fonts installation failed."
      return 1
  fi
}

# Development tools installer
_install_dev_tools() {
  _log_message "INFO" "Checking essential development tools..."
  local tools=("ripgrep:rg" "neovim:nvim" "yazi:yazi" "node:node" "python3:python" "go:go" "rustc:rustc")
  for tool in "${tools[@]}"; do
    local pkg=${tool%%:*} cmd=${tool#*:}
    _install_if_missing "$cmd" "$pkg" "$pkg ($cmd) not found. Install? [y/N]"
  done

  _log_message "INFO" "Development tools check complete."
}

# Aliases for installation functions
alias install-dev-tools='_install_dev_tools'
alias install-fonts='_install_fonts'
alias install-brew='brew' # Just use the lazy-loaded brew function

# Alias for Python virtual environment (make path dynamic if possible)
# Consider using tools like direnv, pyenv, or poetry for better env management
PYTHON_ENV_PATH="/home/me/python_packages_env/bin/activate"
if [[ -f "$PYTHON_ENV_PATH" ]]; then
    alias activate-python-env="source $PYTHON_ENV_PATH"
else
    # Define a placeholder or warning if the path doesn't exist
    activate-python-env() {
        print -P "%F{red}Error: Python environment not found at $PYTHON_ENV_PATH%f"
        return 1
    }
fi

# --- Deferred Loading & Startup Tasks ---

# Load Fabric Bootstrap if available (ensure path is correct)
_safe_source "$XDG_CONFIG_HOME/fabric/fabric-bootstrap.inc"

# Offer to install fonts once if enabled and not already done
if [[ "$INSTALL_MISSING_TOOLS" == "true" ]]; then
    _install_fonts # Function now checks lock file internally
fi

# --- Terminal Startup Visuals (Run Last Before Prompt) ---

# Register deferred startup visuals to run after first prompt
if [[ "$SHOW_POKEMON" == "true" ]] || (( $+commands[fastfetch] )); then
    add-zsh-hook precmd _run_deferred_startup_visuals
fi

# Welcome message (only if enabled)
if [[ "$SHOW_WELCOME_MESSAGE" == "true" ]]; then
  # Cache system info for 24 hours to avoid repeated calls
  local cache_file="$XDG_CACHE_HOME/zsh/system_info"
  local cache_dir="$(dirname "$cache_file")"
  local os kernel distro
  
  # Ensure cache directory exists
  [[ ! -d "$cache_dir" ]] && mkdir -p "$cache_dir"
  
  # Use cached data if available and less than 24 hours old
  if [[ -f "$cache_file" ]] && (( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0) < 86400 )); then
    source "$cache_file"
  else
    # Get fresh system information
    os=$(uname -s)
    kernel=$(uname -r)
    # Try os-release first, fallback for macOS/others
    if [[ -f /etc/os-release ]]; then
      distro=$(source /etc/os-release && print -r -- "$PRETTY_NAME")
    elif [[ "$os" == "Darwin" ]]; then
      distro=$(sw_vers -productName)
    else
      distro="Unknown"
    fi
    
    # Cache the information
    echo "os='$os'" > "$cache_file"
    echo "kernel='$kernel'" >> "$cache_file"
    echo "distro='$distro'" >> "$cache_file"
  fi

  # Get username and last login time efficiently
  local username="${USER:-$(whoami)}"
  local last_login="$(date)"

  # Display welcome message with unicode icons and colors
  print # Empty line
  print -P "%F{cyan}🚀 Welcome, %B$username%b, to your optimized Zsh environment!%f"
  print -P "%F{blue}🖥️  $distro ($kernel)%f"
  print -P "%F{green}🔄 Last login: $last_login%f"
  print -P "%F{yellow}💡 Type 'updateall' to update system%f"
  print -P "%F{yellow}💡 Type 'install-dev-tools' to install missing tools%f"
  print # Empty line
fi

# Run initial directory listing (after welcome message)
# Use a separate function to avoid triggering git check on startup
if (( $+commands[eza] )); then
    eza --color=always --icons --group-directories-first
elif (( $+commands[lsd] )); then
    lsd --color=always --icon=auto
else
    ls --color=auto
fi

# --- Tmux Integration ---

# Set up tmux config directory and files if they don't exist
_setup_tmux_config() {
    local tmux_config_dir="$XDG_CONFIG_HOME/tmux"
    local tmux_conf="$tmux_config_dir/tmux.conf"
    local tmux_conf_local="$tmux_config_dir/tmux.conf.local"
    local home_tmux_conf="$HOME/.tmux.conf"
    local home_tmux_conf_local="$HOME/.tmux.conf.local"

    # Only proceed if the config directory doesn't exist or is empty
    if [[ ! -d "$tmux_config_dir" ]] || [[ -z "$(ls -A "$tmux_config_dir")" ]]; then
        _log_message "INFO" "Setting up tmux configuration in $tmux_config_dir..."
        mkdir -p "$tmux_config_dir"

        # Check dependencies
        if ! (( $+commands[curl] )) && ! (( $+commands[wget] )); then
            _log_message "ERROR" "Cannot download tmux config: curl or wget required."
            return 1
        fi

        # Download Oh My Tmux config files
        _safe_download "https://raw.githubusercontent.com/gpakosz/.tmux/master/.tmux.conf" "$tmux_conf" "Downloading .tmux.conf"
        _safe_download "https://raw.githubusercontent.com/gpakosz/.tmux/master/.tmux.conf.local" "$tmux_conf_local" "Downloading .tmux.conf.local"

        # Create symlinks in $HOME pointing to the XDG location
        ln -sf "$tmux_conf" "$home_tmux_conf"
        ln -sf "$tmux_conf_local" "$home_tmux_conf_local"

        _log_message "INFO" "Tmux configuration set up successfully!"
    fi

    # Ensure symlinks exist even if dir was already there
    [[ -f "$tmux_conf" ]] && [[ ! -L "$home_tmux_conf" ]] && ln -sf "$tmux_conf" "$home_tmux_conf"
    [[ -f "$tmux_conf_local" ]] && [[ ! -L "$home_tmux_conf_local" ]] && ln -sf "$tmux_conf_local" "$home_tmux_conf_local"
}
_setup_tmux_config

# --- Debug and Development Aliases ---
alias debug-git="debug_git_check; print 'Trusted dirs:'; printf ' - %s\\n' \"${TRUSTED_GIT_DIRS[@]}\""
alias debug-zshrc="DEBUG_ZSHRC=1 exec zsh -l"
alias reload-zsh="exec zsh -l"

# Performance profiling helpers
alias profile-zsh="sed -i 's/# zmodload zsh\\/zprof/zmodload zsh\\/zprof/' .zshrc && exec zsh -l"
alias unprofile-zsh="sed -i 's/zmodload zsh\\/zprof/# zmodload zsh\\/zprof/' .zshrc"

# --- Performance Tracking End ---
# ZSHRC_END_TIME=${EPOCHREALTIME}
# ZSHRC_ELAPSED=$(($ZSHRC_END_TIME - $ZSHRC_START_TIME))
# _log_message "INFO" "Zsh initialized in $ZSHRC_ELAPSED seconds"
# zprof # Print profiling info