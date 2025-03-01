#!/usr/bin/env zsh
# =====================================================
# Optimized Zsh Configuration with ZimFW
# Organized for performance and functionality
# =====================================================

# Performance tracking - uncomment to debug startup time
# zmodload zsh/zprof
# ZSHRC_START_TIME=$(date +%s.%N)

# -----------------
# Configuration Options
# -----------------
# User configuration - easy to customize
INSTALL_MISSING_TOOLS=true     # Auto-install missing tools
SHOW_POKEMON=true              # Show Pokémon on startup
SHOW_WELCOME_MESSAGE=true      # Show welcome message
USE_OHMYPOSH=true              # Use Oh My Posh prompt
AUTO_CHECK_UPDATES=true        # Auto-check for updates on startup

# Trusted Git directories (prevent auto-updates in untrusted locations)
TRUSTED_GIT_DIRS=("$HOME/git" "$HOME/projects" "$HOME/work" "$HOME/personal" "$HOME/dev")

# Plugin configuration
declare -A plugins
plugins=(
  [git]=true
  [zoxide]=true
  [syntax-highlighting]=true
  [autosuggestions]=true
  [history-substring-search]=true
  [archlinux]=true
)

# -----------------
# Paths (Set early, minimal)
# -----------------
typeset -U path
path=("$HOME/.local/bin" "$HOME/bin" $path)
export ZSH="$HOME/.oh-my-zsh"

# -----------------
# Core Zsh Options (Critical for Startup)
# -----------------

# History configuration
HISTFILE="$HOME/.zsh_history"
[[ ! -f "$HISTFILE" ]] && touch "$HISTFILE"
HISTSIZE=100000
SAVEHIST=100000

# Optimize zsh options (set all at once to avoid multiple hash operations)
setopt hist_expire_dups_first hist_ignore_all_dups hist_ignore_space 
setopt hist_reduce_blanks hist_verify inc_append_history share_history
setopt auto_cd auto_pushd pushd_ignore_dups pushdminus extended_glob
setopt glob_dots no_beep interactive_comments multios correct complete_in_word

# -----------------
# Helper Functions
# -----------------

# Log functions - only loaded when needed
log_message() {
  local level=$1
  local message=$2
  local colors=("32" "33" "31" "37")  # Green, Yellow, Red, White
  local idx=0
  
  case $level in
    "INFO")    idx=0 ;;
    "WARNING") idx=1 ;;
    "ERROR")   idx=2 ;;
    *)         idx=3 ;;
  esac
  
  echo -e "\033[0;${colors[$idx]}m[$(date +%H:%M:%S)] [$level] $message\033[0m"
}

# Safer sourcing
safe_source() { [[ -f "$1" ]] && source "$1"; }

# Better path management
path_prepend() { [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"; }
path_append() { [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]] && PATH="$PATH:$1"; }

# Safe download helper
safe_download() {
  local url=$1 destination=$2 message=${3:-"Downloading $url"}
  
  if [[ ! -f "$destination" ]]; then
    log_message "INFO" "$message"
    mkdir -p "$(dirname "$destination")"
    curl -fsSL "$url" -o "$destination" || log_message "ERROR" "Failed to download $url"
  fi
}

# Package manager detection (cached)
_detect_package_manager() {
  local cache_file="$HOME/.package_manager_cache"
  
  # Use cached result if fresh (less than 24 hours old)
  if [[ -f "$cache_file" ]] && (( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) < 86400 )); then
    cat "$cache_file"
    return
  fi
  
  # Detect system package manager
  local manager=""
  for pm in apt-get pacman dnf yum zypper brew apk; do
    (( ${+commands[$pm]} )) && { manager="$pm"; break; }
  done
  
  echo "$manager" > "$cache_file"
  echo "$manager"
}

# Simplified installation helper
install_if_missing() {
  local cmd=$1 package=${2:-$1} message=${3:-"$package not found. Install? [y/N]"}
  
  # Skip if tool exists or auto-install disabled
  (( ${+commands[$cmd]} )) && return 0
  [[ "$INSTALL_MISSING_TOOLS" != "true" ]] && return 1
  
  # Ask for confirmation
  echo -n "$message "
  read -r response
  [[ ! "$response" =~ ^[Yy]$ ]] && return 1
  
  log_message "INFO" "Installing $package..."
  
  # Try custom install script first
  if [[ -f "$HOME/install.sh" ]]; then
    bash "$HOME/install.sh" $package
    (( ${+commands[$cmd]} )) && return 0
  fi
  
  # Fall back to system package manager
  if (( ${+commands[brew]} )); then
    brew install $package
  elif (( ${+commands[apt-get]} )); then
    sudo apt-get update && sudo apt-get install -y $package
  elif (( ${+commands[pacman]} )); then
    sudo pacman -S --noconfirm $package
  elif (( ${+commands[dnf]} )); then
    sudo dnf install -y $package
  fi
}

# -----------------
# Completion System (Optimized)
# -----------------

# Fast initialization of completion system
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh-24) ]]; then
  compinit -C
else
  compinit
fi

# Set completion styles (condensed)
zstyle ':completion:*' menu select matcher-list 'm:{a-zA-Z}={A-Za-z}' group-name ''
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:descriptions' format '%F{yellow}%B--- %d%b%f'
zstyle ':completion:*' verbose yes rehash true

# -----------------
# ZimFW Configuration
# -----------------

# Load ZimFW (fast, lightweight plugin manager)
ZIM_HOME=${ZDOTDIR:-$HOME}/.zim
[[ ! -f "${ZIM_HOME}/zimfw.zsh" ]] && safe_download \
  "https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh" \
  "${ZIM_HOME}/zimfw.zsh" "Installing ZimFW..."

[[ -f "${ZIM_HOME}/zimfw.zsh" ]] && source "${ZIM_HOME}/zimfw.zsh" init -q

# -----------------
# Shell Enhancements
# -----------------

# Optimized Git update checker - only run when needed
check_git_updates() {
  # Skip check if disabled or not a git repo
  [[ "$AUTO_CHECK_UPDATES" != "true" ]] && return
  git rev-parse --git-dir &>/dev/null || return
  
  # Verify trusted directory status
  local is_trusted=0
  local current_dir=$(pwd)
  for dir in "${TRUSTED_GIT_DIRS[@]}"; do
    [[ "$current_dir" == "$dir"* ]] && { is_trusted=1; break; }
  done
  [[ $is_trusted -eq 0 ]] && return
  
  # Check for updates
  echo "Checking for updates in $(basename "$(pwd)")..."
  git fetch &>/dev/null
  
  # Compare local and remote states
  local UPSTREAM=${1:-'@{u}'} LOCAL REMOTE BASE
  LOCAL=$(git rev-parse @ 2>/dev/null)
  REMOTE=$(git rev-parse "$UPSTREAM" 2>/dev/null)
  BASE=$(git merge-base @ "$UPSTREAM" 2>/dev/null)
  
  # Display status in a user-friendly way
  if [[ "$LOCAL" = "$REMOTE" ]]; then
    echo "✔ Repository is up to date."
  elif [[ "$LOCAL" = "$BASE" ]]; then
    echo "⇩ Updates are available. Run 'git pull'."
  elif [[ "$REMOTE" = "$BASE" ]]; then
    echo "⇧ Local changes haven't been pushed. Run 'git push'."
  else
    echo "⚠ Repository has diverged."
  fi
}

# Improved directory change hook - combines ls and git check
enhanced_chpwd() {
  ls --color=auto
  check_git_updates
}
autoload -U add-zsh-hook
add-zsh-hook chpwd enhanced_chpwd

# Debug function for Git checking
debug_git_check() {
  echo "Current dir: $(pwd)"
  echo "Is Git repo: $(git rev-parse --git-dir &>/dev/null && echo "Yes" || echo "No")"
  echo "AUTO_CHECK_UPDATES: $AUTO_CHECK_UPDATES"
  echo "Trusted dirs: ${TRUSTED_GIT_DIRS[*]}"
  
  local is_trusted=0 current_dir=$(pwd)
  for dir in "${TRUSTED_GIT_DIRS[@]}"; do
    [[ "$current_dir" == "$dir"* ]] && { is_trusted=1; break; }
  done
  echo "Is trusted: $([ $is_trusted -eq 1 ] && echo "Yes" || echo "No")"
}
alias debug-git="debug_git_check"

# -----------------
# Lazy Loading Functions
# -----------------

# Lazy load nvm (only when needed)
nvm() {
  unset -f nvm
  export NVM_DIR="$HOME/.nvm"
  safe_source "$NVM_DIR/nvm.sh"
  nvm "$@"
}

# Lazy load conda (only when needed)
conda() {
  unset -f conda
  local conda_path="$HOME/miniconda3/bin/conda"
  if [ -f "$conda_path" ]; then
    eval "$("$conda_path" 'shell.zsh' 'hook' 2>/dev/null)"
  fi
  conda "$@"
}

# Lazy load Homebrew
brew() {
  unset -f brew
  
  # Check standard Homebrew locations
  local brew_paths=(
    "/home/linuxbrew/.linuxbrew/bin/brew"
    "$HOME/.linuxbrew/bin/brew"
    "/opt/homebrew/bin/brew"  # macOS ARM64
    "/usr/local/bin/brew"     # macOS Intel
  )
  
  # Initialize first found Homebrew
  for brew_path in "${brew_paths[@]}"; do
    if [[ -x "$brew_path" ]]; then
      eval "$("$brew_path" shellenv)"
      brew "$@"
      return
    fi
  done
  
  # Offer to install if not found
  if [[ "$INSTALL_MISSING_TOOLS" == "true" ]]; then
    log_message "INFO" "Homebrew not found. Install? [y/N]"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      log_message "INFO" "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      
      # Try again after installation
      brew "$@"
      return
    fi
  fi
  
  # Fallback if not installed
  echo "Homebrew is not installed. Run 'install_brew' to install it."
}

# -----------------
# Tool Configurations
# -----------------

# Zoxide (intelligent cd) - load when plugin enabled
if ${plugins[zoxide]:-true} && install_if_missing "zoxide"; then
  eval "$(zoxide init zsh)"
  alias cd="z"
fi

# -----------------
# Keybindings
# -----------------

# Use Emacs keybindings
bindkey -e

# History substring search (if available)
if [[ -n "$terminfo[kcuu1]" && -n "$terminfo[kcud1]" ]]; then
  bindkey "$terminfo[kcuu1]" history-substring-search-up
  bindkey "$terminfo[kcud1]" history-substring-search-down
fi

# Additional useful keybindings (set all at once)
bindkey '^[[1;5C' forward-word                 # Ctrl+Right
bindkey '^[[1;5D' backward-word                # Ctrl+Left
bindkey '^[[3~' delete-char                    # Delete
bindkey '^H' backward-kill-word                # Ctrl+Backspace
bindkey '^[[Z' reverse-menu-complete           # Shift+Tab
bindkey '^[.' insert-last-word                 # Alt+.
bindkey '^[k' kill-line                        # Alt+k
bindkey '^[b' backward-word                    # Alt+b
bindkey '^[f' forward-word                     # Alt+f

# -----------------
# Load Configurations
# -----------------

# Source custom configurations
safe_source "$HOME/.aliases"
safe_source "$HOME/.api_keys"
safe_source "$HOME/.zshrc.local"

# Load oh-my-zsh efficiently
if [[ -d "$ZSH" ]]; then
  # Map our plugin configuration to oh-my-zsh format
  typeset -a ohmyzsh_plugins=()
  ${plugins[git]:-true} && ohmyzsh_plugins+=("git")
  ${plugins[archlinux]:-true} && ohmyzsh_plugins+=("archlinux")
  ${plugins[autosuggestions]:-true} && ohmyzsh_plugins+=("zsh-autosuggestions")
  ${plugins[syntax-highlighting]:-true} && ohmyzsh_plugins+=("zsh-syntax-highlighting")
  
  plugins=("${ohmyzsh_plugins[@]}")
  safe_source "$ZSH/oh-my-zsh.sh"
fi

# -----------------
# Visual Enhancements (Deferred)
# -----------------

# Pokemon colorscripts (install only if enabled)
if [[ "$SHOW_POKEMON" == "true" ]]; then
  if ! (( ${+commands[pokemon-colorscripts]} )) && [[ "$INSTALL_MISSING_TOOLS" == "true" ]]; then
    log_message "INFO" "Install Pokémon Colorscripts? [y/N]"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      (
        git clone --depth 1 https://gitlab.com/phoneybadger/pokemon-colorscripts.git /tmp/pokemon-colorscripts &&
        cd /tmp/pokemon-colorscripts &&
        sudo ./install.sh &&
        rm -rf /tmp/pokemon-colorscripts
      ) &>/dev/null
    fi
  fi

  # Display Pokemon if installed
  (( ${+commands[pokemon-colorscripts]} )) && pokemon-colorscripts --no-title -s -r
fi

# -----------------
# Oh My Posh (Prompt)
# -----------------

if [[ "$USE_OHMYPOSH" == "true" ]]; then
  if install_if_missing "oh-my-posh" "oh-my-posh" "Oh My Posh not found. Install? [y/N]"; then
    # Set up theme
    THEME_FILE="$HOME/.poshthemes/devious-diamonds.omp.yaml"
    THEME_URL="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/devious-diamonds.omp.yaml"
    
    # Ensure theme is available
    mkdir -p "$HOME/.poshthemes"
    safe_download "$THEME_URL" "$THEME_FILE" "Downloading Oh My Posh theme..."
    chmod u+rw "$THEME_FILE" 2>/dev/null
    
    # Initialize Oh My Posh
    eval "$(oh-my-posh init zsh --config "$THEME_FILE")"
  else
    log_message "WARNING" "Oh My Posh not available. Using default prompt."
  fi
fi

# -----------------
# Feature Functions
# -----------------

# Font installation function (run once)
fonts_dir="${HOME}/.local/share/fonts"
fonts_lock="${HOME}/.fonts_installed"

install_fonts() {
  log_message "INFO" "Set up Nerd Fonts? [y/N]"
  read -r response
  [[ ! "$response" =~ ^[Yy]$ ]] && return
  
  log_message "INFO" "Setting up Nerd Fonts..."
  mkdir -p "$fonts_dir"
  
  # Define font list and version
  local fonts=(BitstreamVeraSansMono CodeNewRoman FiraCode Hack JetBrainsMono SourceCodePro UbuntuMono)
  local version='2.1.0'
  
  # Install each font
  local total=${#fonts[@]} current=0
  for font in "${fonts[@]}"; do
    current=$((current + 1))
    log_message "INFO" "Installing font ($current/$total): $font"
    
    local zip_file="/tmp/${font}.zip"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/${font}.zip"
    
    if wget -q "$download_url" -O "$zip_file"; then
      unzip -q "$zip_file" -d "$fonts_dir" && rm "$zip_file"
    fi
  done
  
  # Clean up and update
  find "$fonts_dir" -name '*Windows Compatible*' -delete
  fc-cache -f
  touch "$fonts_lock"
  log_message "INFO" "Nerd Fonts installation complete."
}

# Development tools installer
install_dev_tools() {
  log_message "INFO" "Installing essential development tools..."
  
  # Install core tools
  local tools=("ripgrep:rg" "neovim:nvim" "yazi:yazi" "node:node")
  for tool in "${tools[@]}"; do
    local pkg=${tool%%:*}
    local cmd=${tool#*:}
    install_if_missing "$cmd" "$pkg" "$pkg not found. Install? [y/N]"
  done
  
  # Install luarocks and luasocket
  if [[ "$INSTALL_MISSING_TOOLS" == "true" ]] && ! (( ${+commands[luarocks]} )); then
    log_message "INFO" "Install luarocks and luasocket? [y/N]"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      (
        wget -q -O /tmp/luarocks.tar.gz https://luarocks.org/releases/luarocks-3.11.1.tar.gz &&
        tar zxpf /tmp/luarocks.tar.gz -C /tmp &&
        cd /tmp/luarocks-3.11.1 &&
        ./configure && make && sudo make install &&
        sudo luarocks install luasocket &&
        rm -rf /tmp/luarocks*
      ) &>/dev/null
    fi
  fi
  
  log_message "INFO" "Development tools installation complete!"
}

# Set up install functions and aliases
alias install-dev-tools="install_dev_tools"
alias install-fonts="install_fonts"
alias install-brew="/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""

# -----------------
# Deferred Loading
# -----------------

# Load Fabric Bootstrap if available
[[ -f "$HOME/.config/fabric/fabric-bootstrap.inc" ]] && source "$HOME/.config/fabric/fabric-bootstrap.inc"

# Only offer to install fonts once
[[ ! -f "$fonts_lock" && "$INSTALL_MISSING_TOOLS" == "true" ]] && install_fonts

# -----------------
# Terminal Startup
# -----------------

# Run fastfetch with Pokemon if available
if (( ${+commands[fastfetch]} )) && (( ${+commands[pokemon-colorscripts]} )) && [[ "$SHOW_POKEMON" == "true" ]]; then
  FASTFETCH_CONFIG="$HOME/.config/fastfetch/config-pokemon.jsonc"
  
  # Create config if missing
  if [[ ! -f "$FASTFETCH_CONFIG" ]]; then
    mkdir -p "$(dirname "$FASTFETCH_CONFIG")"
    cat > "$FASTFETCH_CONFIG" <<EOL
{
  "display": { "separator": " ", "colorScheme": "dark" },
  "modules": ["title", "os", "kernel", "uptime", "packages", "shell", "memory", "cpu", "gpu"]
}
EOL
  fi
  
  # Run combined command
  pokemon-colorscripts --no-title -s -r | fastfetch -c "$FASTFETCH_CONFIG" --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
fi

# Welcome message (only if enabled)
if [[ "$SHOW_WELCOME_MESSAGE" == "true" ]]; then
  # Get system information more efficiently
  OS=$(uname -s)
  KERNEL=$(uname -r)
  DISTRO=$(grep -oP '(?<=PRETTY_NAME=")[^"]+' /etc/os-release 2>/dev/null || echo "Unknown")
  
  echo ""
  echo "🚀 Welcome to your optimized Zsh environment!"
  echo "🖥️  $DISTRO ($OS $KERNEL)"
  echo "🔄 Last login: $(date)"
  echo "💡 Type 'updateall' to update all packages and tools"
  echo "💡 Type 'install-dev-tools' to install development tools"
  echo ""
fi

# Run initial ls command
ls --color=auto

# Uncomment to show startup time
# ZSHRC_END_TIME=$(date +%s.%N)
# ZSHRC_ELAPSED=$(echo "$ZSHRC_END_TIME - $ZSHRC_START_TIME" | bc)
# log_message "INFO" "Zsh initialized in $ZSHRC_ELAPSED seconds"
# zprof  # End profiling