#!/usr/bin/env zsh
# =====================================================
# Optimized Zsh Configuration with ZimFW
# Organized for performance and functionality
# =====================================================

# --- Performance Tracking (Uncomment to Debug) ---
# zmodload zsh/zprof
# ZSHRC_START_TIME=${EPOCHREALTIME} # Use Zsh's high-resolution timer

# --- Core Zsh Options (Set Early) ---
# Exit on error, treat unset variables as errors (be careful with prompts/completions), exit on pipe failures
# Consider removing 'u' if it causes issues with plugins/themes: setopt NO_UNSET
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
setopt AUTO_CD                        # If command is a path to a directory, cd into it.
setopt AUTO_PUSHD                     # Automatically push directories onto the stack.
setopt PUSHD_IGNORE_DUPS              # Don't push directories onto the stack if they are already there.
setopt PUSHD_SILENT                   # Do not print the directory stack after pushd or popd.
setopt PUSHD_TO_HOME                  # Have pushd with no arguments act like `pushd $HOME`.
setopt EXTENDED_GLOB                  # Use extended globbing syntax.
setopt GLOB_DOTS                      # Include hidden files in globbing results.
setopt NO_BEEP                        # No annoying beeps.
setopt INTERACTIVE_COMMENTS           # Allow comments in interactive shell.
setopt COMPLETE_IN_WORD               # Complete from both ends of a word.
setopt ALWAYS_TO_END                  # Move cursor to the end of a completed word.
setopt CORRECT                        # Auto-correct commands
# setopt MULTIOS                      # Allow multiple redirections (can sometimes be surprising)

# History configuration
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
# Ignore common commands and duplicates
#export HISTORY_IGNORE="(ls|cd|pwd|exit|sudo reboot|history|cd -|cd ..| *|&:)" # Ignore duplicates and commands starting with space
# Zsh-native way to ignore patterns. The `|` acts as an OR.
# The `&` is for duplicates (already handled by HIST_IGNORE_ALL_DUPS)
# The leading space is handled by HIST_IGNORE_SPACE
HIST_IGNORE_PATTERNS="ls|cd|pwd|exit|sudo reboot|history|cd -|cd ..|exa*|lsd*"

# --- Environment Variables & Paths ---
# Use ZDOTDIR if set, otherwise default to $HOME
export ZDOTDIR="${ZDOTDIR:-$HOME}"
export EDITOR="nvim"
export VISUAL="nvim" # Or 'neovide', 'gvim' etc.

# XDG Base Directory Specification (use defaults if not set)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$ZDOTDIR/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$ZDOTDIR/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$ZDOTDIR/.cache}"

# Ensure base directories exist
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"

# Path configuration (using Zsh's typeset -U for uniqueness)
typeset -U path # Ensures path entries are unique
# Prepend user bin directories
path=(
  "$HOME/app"                   # Custom applications
  "$HOME/.local/bin"            # Standard user binary location
  "$HOME/bin"                   # Legacy user binary location
  "$XDG_DATA_HOME/../bin"       # Potential location from install scripts (resolves to ~/.local/bin)
  $path                         # Include existing system path
)
# Source environment variables from a specific file if it exists
[[ -f "$XDG_DATA_HOME/../bin/env" ]] && source "$XDG_DATA_HOME/../bin/env"

# FZF configuration
export FZF_DEFAULT_OPTS="--layout=reverse --exact --border=bold --border=rounded --margin=3% --color=dark"
# Use fd if available for FZF
if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# --- Configuration Options ---
# User configuration - easy to customize
INSTALL_MISSING_TOOLS=true      # Auto-install missing tools (interactively)
SHOW_POKEMON=true               # Show Pokémon on startup (can impact startup time)
SHOW_WELCOME_MESSAGE=true       # Show welcome message
USE_OHMYPOSH=true               # Use Oh My Posh prompt
AUTO_CHECK_UPDATES=true         # Auto-check for Git updates on cd (only in trusted dirs)

# Trusted Git directories (prevent auto-updates in untrusted locations)
# Use $HOME explicitly for clarity, ensure paths exist or handle gracefully if needed
TRUSTED_GIT_DIRS=(
  "$HOME/git"
  "$HOME/projects"
  "$HOME/work"
  "$HOME/personal"
  "$HOME/dev"
)

# Plugin configuration (used by ZimFW and potentially OMZ)
# Using an associative array for clarity
typeset -A zplugins
zplugins=(
  [git]=true                    # Enable Git plugin features
  [zoxide]=true                 # Enable zoxide (intelligent cd)
  [syntax-highlighting]=true    # Enable zsh-syntax-highlighting
  [autosuggestions]=true        # Enable zsh-autosuggestions
  [history-substring-search]=true # Enable history substring search
  [archlinux]=true              # Enable Arch Linux specific aliases/functions (if applicable)
)

# --- Helper Functions ---

# Log functions - only loaded when needed
_log_message() {
  local level=$1 message=$2 color
  case $level in
    "INFO")    color="32" ;; # Green
    "WARNING") color="33" ;; # Yellow
    "ERROR")   color="31" ;; # Red
    *)         color="37" ;; # White
  esac
  # Use Zsh's %D{%T} for time format
  print -P "%F{$color}[%D{%T}] [$level] $message%f"
}

# Safer sourcing
_safe_source() { [[ -f "$1" ]] && source "$1" }

# Safe download helper (requires curl or wget)
_safe_download() {
  local url=$1 destination=$2 message=${3:-"Downloading $url"} cmd
  if [[ ! -f "$destination" ]]; then
    _log_message "INFO" "$message"
    mkdir -p "$(dirname "$destination")"
    if (( $+commands[curl] )); then
      curl -fLso "$destination" "$url" || { _log_message "ERROR" "curl failed to download $url"; return 1; }
    elif (( $+commands[wget] )); then
      wget -qO "$destination" "$url" || { _log_message "ERROR" "wget failed to download $url"; return 1; }
    else
      _log_message "ERROR" "Cannot download: curl or wget not found."
      return 1
    fi
  fi
  return 0
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

  # Try custom install script first (if it exists and is executable)
  local custom_installer="$HOME/development/conf/install.sh" # Use full path
  if [[ -x "$custom_installer" ]]; then
      _log_message "INFO" "Using custom installer: $custom_installer"
      if "$custom_installer" "$package"; then
          if (( $+commands[$cmd] )); then
              _log_message "INFO" "$package installed successfully via custom script."
              return 0
          else
              _log_message "WARNING" "Custom install script ran but command '$cmd' still not found."
          fi
      else
          _log_message "WARNING" "Custom install script failed for $package."
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
#____________________________________________________________________________________________
# REFACTOR: Defer slow startup visuals to run *after* the first prompt is drawn.
# This makes the shell feel instantaneous.
_run_deferred_startup_visuals() {
    # STEP 1: Immediately unregister this function so it only runs ONCE per session.
    # This is the key to the "run only once" trick.
    unset -f _run_deferred_startup_visuals
    add-zsh-hook -d precmd _run_deferred_startup_visuals

    # STEP 2: Place your original logic for showing visuals here.
    # This will now print *above* your first ready-to-use prompt.
    if [[ "$SHOW_POKEMON" == "true" ]]; then
        # Check dependencies first
        if (( $+commands[pokemon-colorscripts] )) && (( $+commands[fastfetch] )); then
            # Run your preferred combined command. Using the pipe version as an example.
            pokemon-colorscripts --no-title -r | fastfetch --pipe

        elif (( $+commands[pokemon-colorscripts] )); then
            # Fallback to just pokemon if fastfetch is missing
            pokemon-colorscripts --no-title -r

        elif (( $+commands[fastfetch] )); then
            # Fallback to just fastfetch if pokemon is missing
            fastfetch
        fi
    elif (( $+commands[fastfetch] )); then
        # If pokemon is disabled, just show fastfetch
        fastfetch
    elif (( $+commands[neofetch] )); then
        # Fallback to neofetch if fastfetch is missing
        neofetch
    fi

    # STEP 3 (Optional but Recommended): Redraw the prompt.
    # When the async command finishes, this ensures the prompt is neatly positioned underneath.
    zle && zle .redisplay
}
#_____________________________________________________________________________________________
# --- Completion System ---
# Initialize completions; use cache if available and less than 24 hours old
autoload -Uz compinit
local compinit_cache_file="$XDG_CACHE_HOME/zsh/zcompdump"
if [[ -f "$compinit_cache_file" ]] && (( $(date +%s) - $(stat -c %Y "$compinit_cache_file" 2>/dev/null || stat -f %m "$compinit_cache_file" 2>/dev/null || echo 0) < 86400 )); then
  compinit -i -C -d "$compinit_cache_file"
else
  # Regenerate cache file
  compinit -i -d "$compinit_cache_file"
fi
# Basic completion styling
zstyle ':completion:*' menu select
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS} # Use LS_COLORS for completion highlighting
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case-insensitive matching
zstyle ':completion:*' group-name '' # Group completions by type
zstyle ':completion:*:descriptions' format '%F{yellow}%B--- %d%b%f' # Format descriptions
zstyle ':completion:*' verbose yes # Provide detailed completion messages

# --- ZimFW (Plugin Manager) ---
ZIM_HOME="$XDG_DATA_HOME/zim"
# Download zimfw.zsh if missing
if [[ ! -f "$ZIM_HOME/zimfw.zsh" ]]; then
  # Ensure curl or wget is available
  if ! (( $+commands[curl] )) && ! (( $+commands[wget] )); then
    _log_message "ERROR" "Cannot install ZimFW: curl or wget is required."
  else
    _safe_download \
      "https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh" \
      "$ZIM_HOME/zimfw.zsh" "Downloading ZimFW..."
  fi
fi
# Initialize ZimFW if the file exists
[[ -f "$ZIM_HOME/.zimrc" ]] && source "$ZIM_HOME/zimrc"

# --- Configure Zim Modules (Plugins/Themes) ---
# Define modules to be managed by ZimFW based on our zplugins array
zmodules=()
(( ${zplugins[git]} )) && zmodules+=("git")
(( ${zplugins[syntax-highlighting]} )) && zmodules+=("zsh-users/zsh-syntax-highlighting")
(( ${zplugins[autosuggestions]} )) && zmodules+=("zsh-users/zsh-autosuggestions")
(( ${zplugins[history-substring-search]} )) && zmodules+=("zsh-users/zsh-history-substring-search")
(( ${zplugins[archlinux]} )) && zmodules+=("archlinux") # Assuming this is a Zim module

# Add other desired Zim modules here, e.g., themes, completions
# zmodules+=("prompt") # Example: Add prompt module if needed

# Load Zim modules if the array is not empty
if (( ${#zmodules[@]} > 0 )); then
  zimfw install # Install/update modules if needed
  zimfw load    # Load the modules
fi

# --- Shell Enhancements ---

# Function to set terminal title (matches DT's format)
_set_term_title() {
  print -Pn "\e]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\a"
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
  if (( $+commands[exa] )); then
    exa --color=always --icons --group-directories-first # Customize exa flags as needed
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

# Zoxide (intelligent cd) - load if plugin enabled and command exists
if (( ${zplugins[zoxide]} )) && _install_if_missing "zoxide"; then
  eval "$(zoxide init zsh --cmd cd)" # Use --cmd cd to alias cd directly
  # Optional: alias j='z' for explicit jump if needed
fi

# --- Keybindings ---
bindkey -e # Use Emacs keybindings

# History substring search bindings (if module loaded and terminfo available)
if (( ${+widgets[history-substring-search-up]} && ${+terminfo[kcuu1]} )); then
  bindkey "$terminfo[kcuu1]" history-substring-search-up   # Up arrow
fi
if (( ${+widgets[history-substring-search-down]} && ${+terminfo[kcud1]} )); then
  bindkey "$terminfo[kcud1]" history-substring-search-down # Down arrow
fi

# FZF keybindings (if fzf is installed)
if (( $+commands[fzf] )); then
  bindkey '^T' fzf-file-widget           # Ctrl+T - Find file
  bindkey '^R' fzf-history-widget       # Ctrl+R - Find history
  bindkey '^[[C' fzf-completion          # Alt+C - Find directory (Note: Alt+C might conflict)
  # Ensure fzf-tab plugin isn't overriding if you prefer standard fzf bindings
fi

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

# --- Load Custom Configurations ---
# Source local files if they exist
_safe_source "$ZDOTDIR/.aliases"
_safe_source "$ZDOTDIR/.api_keys" # Be careful with sensitive data! Consider env vars or dedicated tools.
_safe_source "$ZDOTDIR/.zshrc.local" # For user-specific overrides

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

  # Check if already run
  [[ -f "$fonts_lock_file" ]] && return 0

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

# Run fastfetch or similar (optional, can slow startup)
# Consider running this *after* the first prompt appears using a hook if speed is critical
if [[ "$SHOW_POKEMON" == "true" ]]; then
    # Check dependencies first
    if (( $+commands[pokemon-colorscripts] )) && (( $+commands[fastfetch] )); then
        FASTFETCH_CONFIG="$XDG_CONFIG_HOME/fastfetch/config-pokemon.jsonc"
        # Create default config if missing
        if [[ ! -f "$FASTFETCH_CONFIG" ]]; then
            mkdir -p "$(dirname "$FASTFETCH_CONFIG")"
            # Basic fastfetch config example
            print -r -- '{
              "display": { "separator": " ", "colorScheme": "dark" },
              "modules": ["title", "os", "kernel", "uptime", "packages", "shell", "memory", "cpu", "gpu"]
            }' > "$FASTFETCH_CONFIG"
        fi
        # Run combined command (might be slow)
        # pokemon-colorscripts --no-title -s -r | fastfetch -c "$FASTFETCH_CONFIG" --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
        # Alternative: Run fastfetch only, maybe with a different logo source
        fastfetch --logo-width 15 # Simpler fastfetch call
    elif (( $+commands[pokemon-colorscripts] )); then
        # Fallback to just pokemon if fastfetch is missing
        pokemon-colorscripts --no-title -s -r
    elif (( $+commands[fastfetch] )); then
        # Fallback to just fastfetch if pokemon is missing
        fastfetch
    fi
elif (( $+commands[fastfetch] )); then
    # Show fastfetch even if pokemon is disabled
    fastfetch
fi


# Welcome message (only if enabled)
if [[ "$SHOW_WELCOME_MESSAGE" == "true" ]]; then
  # Get system information efficiently
  local os kernel distro
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

  print # Empty line
  print -P "%F{cyan}🚀 Welcome to your optimized Zsh environment!%f"
  print -P "%F{blue}🖥️  $distro ($os $kernel)%f"
  print -P "%F{green}🔄 Last login: $(date)%f" # date is relatively fast
  print -P "%F{yellow}💡 Type 'updateall' to update system (if installed)%f"
  print -P "%F{yellow}💡 Type 'install-dev-tools' to check/install tools%f"
  print # Empty line
fi

# Run initial ls/exa command (after welcome message)
_enhanced_chpwd # Call the chpwd hook manually once at startup

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

# Auto-launch tmux (make this the VERY LAST command if used)
# Check if tmux exists, we are in an interactive shell, not already in tmux/screen, and TMUX var is not set
if (( $+commands[tmux] )) && [[ -o INTERACTIVE ]] && [[ -z "$TMUX" ]] && [[ "$TERM" != screen* ]] && [[ "$TERM" != tmux* ]]; then
  # exec replaces the current shell process with tmux
  exec tmux
fi

# --- Performance Tracking End (Uncomment to Debug) ---
# ZSHRC_END_TIME=${EPOCHREALTIME}
# ZSHRC_ELAPSED=$(($ZSHRC_END_TIME - $ZSHRC_START_TIME))
# _log_message "INFO" "Zsh initialized in $ZSHRC_ELAPSED seconds"
# zprof # Print profiling info
