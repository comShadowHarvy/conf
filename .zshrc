#!/usr/bin/env zsh
# =====================================================
# Optimized Zsh Configuration with ZimFW
# Organized for performance and functionality
# =====================================================

# -----------------
# Performance Tracking (uncomment to debug startup time)
# -----------------
# zmodload zsh/zprof  # Start profiling
# ZSHRC_START_TIME=$(date +%s.%N)

# -----------------
# Configuration Options
# -----------------
# Set these options to control what gets installed and loaded
INSTALL_MISSING_TOOLS=true     # Auto-install missing tools
SHOW_POKEMON=true              # Show Pokémon on startup
SHOW_WELCOME_MESSAGE=true      # Show welcome message
USE_OHMYPOSH=true              # Use Oh My Posh prompt
AUTO_CHECK_UPDATES=true       # Auto-check for updates on startup

# Define trusted Git directories for auto-updates
TRUSTED_GIT_DIRS=("$HOME/git" "$HOME/projects" "$HOME/work" "$HOME/personal" "$HOME/dev")


# Define which plugins to enable (true) or disable (false)
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
# Helper Functions
# -----------------

# Log a message with a timestamp
log_message() {
  local level=$1
  local message=$2
  local color=""
  local reset="\033[0m"
  
  case $level in
    "INFO")    color="\033[0;32m" ;;  # Green
    "WARNING") color="\033[0;33m" ;;  # Yellow
    "ERROR")   color="\033[0;31m" ;;  # Red
    *)         color="\033[0;37m" ;;  # White
  esac
  
  echo -e "${color}[$(date +%H:%M:%S)] [$level] $message${reset}"
}

# Install a tool if it's missing (with confirmation)
install_if_missing() {
  local cmd=$1
  local package=${2:-$1}
  local message=${3:-"$package not found. Would you like to install it? [y/N]"}
  
  if [[ "$INSTALL_MISSING_TOOLS" == "true" ]] && ! (( ${+commands[$cmd]} )); then
    echo -n "$message "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      log_message "INFO" "Installing $package..."
      
      # Try using our custom install script
      if [[ -f "$HOME/install.sh" ]]; then
        bash "$HOME/install.sh" $package
      # Fallback to package managers if install.sh didn't work or doesn't exist
      elif ! (( ${+commands[$cmd]} )); then
        if (( ${+commands[brew]} )); then
          brew install $package
        elif (( ${+commands[apt-get]} )); then
          sudo apt-get update && sudo apt-get install -y $package
        elif (( ${+commands[pacman]} )); then
          sudo pacman -S --noconfirm $package
        elif (( ${+commands[dnf]} )); then
          sudo dnf install -y $package
        fi
      fi
    fi
  fi
}

# Safely source a file if it exists
safe_source() {
  [[ -f "$1" ]] && source "$1"
}

# Download a file safely
safe_download() {
  local url=$1
  local destination=$2
  local message=${3:-"Downloading $url to $destination"}
  
  if [[ ! -f "$destination" ]]; then
    log_message "INFO" "$message"
    mkdir -p "$(dirname "$destination")"
    curl -fsSL "$url" -o "$destination" || {
      log_message "ERROR" "Failed to download $url"
      return 1
    }
  fi
}

# Better path management
path_prepend() {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    PATH="$1:$PATH"
  fi
}

path_append() {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    PATH="$PATH:$1"
  fi
}

# Detect virtual environments
function virtualenv_info {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "($(basename $VIRTUAL_ENV)) "
  fi
}

# Cache detection of package managers
_detect_package_manager() {
  local cache_file="$HOME/.package_manager_cache"
  
  # Use cached result if less than 24 hours old
  if [[ -f "$cache_file" && $(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) )) -lt 86400 ]]; then
    cat "$cache_file"
    return
  fi
  
  # Detect package manager and cache result
  local manager=""
  if (( ${+commands[apt-get]} )); then
    manager="apt-get"
  elif (( ${+commands[pacman]} )); then
    manager="pacman"
  elif (( ${+commands[dnf]} )); then
    manager="dnf"
  elif (( ${+commands[yum]} )); then
    manager="yum"
  elif (( ${+commands[zypper]} )); then
    manager="zypper"
  elif (( ${+commands[brew]} )); then
    manager="brew"
  elif (( ${+commands[apk]} )); then
    manager="apk"
  fi
  
  echo "$manager" > "$cache_file"
  echo "$manager"
}

# -----------------
# Paths
# -----------------

# Add local binaries to PATH
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"
export ZSH="$HOME/.oh-my-zsh"

# -----------------
# Core Zsh Options
# -----------------

# Configure Zsh history
HISTFILE="$HOME/.zsh_history"
[[ ! -f "$HISTFILE" ]] && touch "$HISTFILE"
HISTSIZE=100000
SAVEHIST=100000
setopt hist_expire_dups_first   # Delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_all_dups     # Don't record duplicated commands
setopt hist_ignore_space        # Don't record commands starting with space
setopt hist_reduce_blanks       # Remove superfluous blanks from history
setopt hist_verify              # Show command with history expansion before running it
setopt inc_append_history       # Add commands to HISTFILE immediately
setopt share_history            # Share history between all sessions

# Completion and expansion options
setopt auto_cd                  # cd by typing directory name
setopt auto_pushd               # Push the current directory visited on the stack
setopt pushd_ignore_dups        # Do not store duplicates in the stack
setopt pushdminus               # Swap the meaning of + and - for pushd
setopt extended_glob            # Use extended globbing
setopt glob_dots                # Include hidden files in globbing

# Input and output options
setopt no_beep                  # Disable beeping
setopt interactive_comments     # Allow comments in interactive shells
setopt multios                  # Allow multiple redirections
setopt correct                  # Command correction
setopt complete_in_word         # Complete from both ends of a word

# -----------------
# Completion Configuration
# -----------------

# Initialize the completion system
autoload -Uz compinit
# Optimize completion init - compinit is slow so only run it if needed
_comp_files=(${ZDOTDIR:-$HOME}/.zcompdump(Nm-20))
if (( $#_comp_files )); then
  compinit -C
else
  compinit
fi
unset _comp_files

# Set completion options
zstyle ':completion:*' menu select                            # Use menu selection for completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'     # Case insensitive matching
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS} # Colored completion
zstyle ':completion:*' group-name ''                          # Group completions by category
zstyle ':completion:*:descriptions' format '%F{yellow}%B--- %d%b%f' # Format for group titles
zstyle ':completion:*' verbose yes                            # Verbose completion info
zstyle ':completion:*' rehash true                            # Automatically rehash for new executables

# -----------------
# ZimFW Configuration
# -----------------

# Set ZimFW installation path
ZIM_HOME=${ZDOTDIR:-$HOME}/.zim

# Download ZimFW if missing
if [[ ! -f "${ZIM_HOME}/zimfw.zsh" ]]; then
  log_message "INFO" "ZimFW not found. Installing..."
  safe_download "https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh" "${ZIM_HOME}/zimfw.zsh"
fi

# Initialize ZimFW
if [[ -f "${ZIM_HOME}/zimfw.zsh" ]]; then
  source "${ZIM_HOME}/zimfw.zsh" init -q
fi

# -----------------
# Shell Enhancements
# -----------------

# Function to check for Git updates and display directory contents
check_git_updates_and_ls() {
    # Always show directory contents first
    ls --color=auto
    
    # Only show updates if AUTO_CHECK_UPDATES is enabled
    if [[ "$AUTO_CHECK_UPDATES" != "true" ]]; then
        return
    fi

    # Check if this is a Git repository
    if [[ -d ".git" ]] || git rev-parse --git-dir > /dev/null 2>&1; then
        # Verify if this is a trusted directory
        local current_dir=$(pwd)
        local is_trusted=0
        
        for dir in "${TRUSTED_GIT_DIRS[@]}"; do
            if [[ "$current_dir" == "$dir"* ]]; then
                is_trusted=1
                break
            fi
        done
        
        # Only proceed with auto-updates in trusted directories
        if [[ $is_trusted -eq 1 ]]; then
            echo "Checking for updates in $(basename "$(pwd)")..."
            git fetch > /dev/null 2>&1
            UPSTREAM=${1:-'@{u}'}
            LOCAL=$(git rev-parse @ 2>/dev/null)
            REMOTE=$(git rev-parse "$UPSTREAM" 2>/dev/null)
            BASE=$(git merge-base @ "$UPSTREAM" 2>/dev/null)

            if [[ "$LOCAL" = "$REMOTE" ]]; then
                echo "✔ Repository is up to date."
            elif [[ "$LOCAL" = "$BASE" ]]; then
                echo "⇩ Updates are available. Run 'git pull'."
            elif [[ "$REMOTE" = "$BASE" ]]; then
                echo "⇧ Local changes haven't been pushed. Run 'git push'."
            else
                echo "⚠ Repository has diverged."
            fi
        fi
    fi
}

# Hook to run check_git_updates_and_ls whenever the directory changes
autoload -U add-zsh-hook
add-zsh-hook chpwd check_git_updates_and_ls
# Debug function
debug_git_check() {
  echo "Current dir: $(pwd)"
  echo "Is Git repo: $(if [[ -d ".git" ]] || git rev-parse --git-dir > /dev/null 2>&1; then echo "Yes"; else echo "No"; fi)"
  echo "AUTO_CHECK_UPDATES: $AUTO_CHECK_UPDATES"
  echo "Trusted dirs: ${TRUSTED_GIT_DIRS[*]}"
  
  # Check if current directory is trusted
  local current_dir=$(pwd)
  local is_trusted=0
  for dir in "${TRUSTED_GIT_DIRS[@]}"; do
    if [[ "$current_dir" == "$dir"* ]]; then
      is_trusted=1
      break
    fi
  done
  echo "Is trusted: $(if [[ $is_trusted -eq 1 ]]; then echo "Yes"; else echo "No"; fi)"
}
alias debug-git="debug_git_check"

# -----------------
# Tool Installation & Configuration
# -----------------

# Install and configure Zoxide for intelligent directory navigation
if ${plugins[zoxide]:-true}; then
  install_if_missing "zoxide" "zoxide" "zoxide (intelligent cd) not found. Would you like to install it? [y/N]"
  if (( ${+commands[zoxide]} )); then
    eval "$(zoxide init zsh)"
    alias cd="z"  # Use zoxide's 'z' command instead of 'cd'
  fi
fi

# -----------------
# Lazy Loading Functions
# -----------------

# Lazy load nvm
nvm() {
  unset -f nvm
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm "$@"
}

# Lazy load conda
conda() {
  unset -f conda
  local conda_path="$HOME/miniconda3/bin/conda"
  if [ -f "$conda_path" ]; then
    __conda_setup="$('$conda_path' 'shell.zsh' 'hook' 2> /dev/null)"
    eval "$__conda_setup"
    unset __conda_setup
  fi
  conda "$@"
}

# -----------------
# Keybindings
# -----------------

# Use Emacs keybindings
bindkey -e

# Bind arrow keys for history substring search if the module is loaded
if [[ -n "$terminfo[kcuu1]" && -n "$terminfo[kcud1]" ]]; then
  bindkey "$terminfo[kcuu1]" history-substring-search-up
  bindkey "$terminfo[kcud1]" history-substring-search-down
fi

# Additional useful keybindings
bindkey '^[[1;5C' forward-word                 # Ctrl+Right - forward one word
bindkey '^[[1;5D' backward-word                # Ctrl+Left - backward one word
bindkey '^[[3~' delete-char                    # Delete key
bindkey '^H' backward-kill-word                # Ctrl+Backspace - delete previous word
bindkey '^[[Z' reverse-menu-complete           # Shift+Tab - go backward in completion menu
bindkey '^[.' insert-last-word                 # Alt+. - insert last word from previous command
bindkey '^[k' kill-line                        # Alt+k - kill line from cursor to end
bindkey '^[b' backward-word                    # Alt+b - move back a word
bindkey '^[f' forward-word                     # Alt+f - move forward a word

# -----------------
# Aliases and Custom Configurations
# -----------------

# Source custom aliases and API keys if they exist
safe_source "$HOME/.aliases"
safe_source "$HOME/.api_keys"

# Load user-specific customizations if they exist
safe_source "$HOME/.zshrc.local"

# Load oh-my-zsh if available
if [[ -d "$ZSH" ]]; then
  # Define plugins to use based on our plugins associative array
  typeset -a ohmyzsh_plugins=()
  
  ${plugins[git]:-true} && ohmyzsh_plugins+=("git")
  ${plugins[archlinux]:-true} && ohmyzsh_plugins+=("archlinux")
  ${plugins[autosuggestions]:-true} && ohmyzsh_plugins+=("zsh-autosuggestions")
  ${plugins[syntax-highlighting]:-true} && ohmyzsh_plugins+=("zsh-syntax-highlighting")
  
  # Set the plugins array for oh-my-zsh
  plugins=("${ohmyzsh_plugins[@]}")
  
  # Only load oh-my-zsh.sh if it exists
  safe_source "$ZSH/oh-my-zsh.sh"
fi

# -----------------
# Visual Enhancements
# -----------------

# Install and configure Pokémon Colorscripts if enabled
if [[ "$SHOW_POKEMON" == "true" ]]; then
  if ! (( ${+commands[pokemon-colorscripts]} )) && [[ "$INSTALL_MISSING_TOOLS" == "true" ]]; then
    log_message "INFO" "Would you like to install Pokémon Colorscripts? [y/N]"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      log_message "INFO" "Installing Pokémon Colorscripts..."
      (
        git clone --depth 1 https://gitlab.com/phoneybadger/pokemon-colorscripts.git /tmp/pokemon-colorscripts &&
        cd /tmp/pokemon-colorscripts &&
        sudo ./install.sh &&
        rm -rf /tmp/pokemon-colorscripts
      ) &>/dev/null
    fi
  fi

  # Display Pokémon Colorscripts if installed
  if (( ${+commands[pokemon-colorscripts]} )); then
    pokemon-colorscripts --no-title -s -r
  fi
fi

# -----------------
# Oh My Posh Theme
# -----------------

if [[ "$USE_OHMYPOSH" == "true" ]]; then
  # Install oh-my-posh if not already installed
  install_if_missing "oh-my-posh" "oh-my-posh" "Oh My Posh not found. Would you like to install it? [y/N]"

  # Define theme file and URL
  THEME_FILE="$HOME/.poshthemes/devious-diamonds.omp.yaml"
  THEME_URL="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/devious-diamonds.omp.yaml"

  # Ensure the theme directory exists
  mkdir -p "$HOME/.poshthemes"

  # Download the theme if missing
  safe_download "$THEME_URL" "$THEME_FILE" "Downloading Oh My Posh theme..."
  chmod u+rw "$THEME_FILE" 2>/dev/null

  # Initialize Oh My Posh with the theme
  if (( ${+commands[oh-my-posh]} )); then
    eval "$(oh-my-posh init zsh --config "$THEME_FILE")"
  else
    log_message "WARNING" "Oh My Posh not available. Using default prompt."
  fi
fi

# -----------------
# Fabric Bootstrap (Optional)
# -----------------

if [[ -f "$HOME/.config/fabric/fabric-bootstrap.inc" ]]; then
  log_message "INFO" "Loading Fabric Bootstrap..."
  source "$HOME/.config/fabric/fabric-bootstrap.inc"
fi

# -----------------
# Package Managers
# -----------------

# Homebrew detection and initialization (lazy-loaded)
brew() {
  unset -f brew
  
  # Check if homebrew is installed in one of the standard locations
  if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    eval "$($HOME/.linuxbrew/bin/brew shellenv)"
  elif [[ -x "/opt/homebrew/bin/brew" ]]; then  # macOS ARM64
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then     # macOS Intel
    eval "$(/usr/local/bin/brew shellenv)"
  elif [[ "$INSTALL_MISSING_TOOLS" == "true" ]]; then
    log_message "INFO" "Homebrew not found. Would you like to install it? [y/N]"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      log_message "INFO" "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      
      # Try to find brew again after installation
      if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
        eval "$($HOME/.linuxbrew/bin/brew shellenv)"
      elif [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    else
      # Create stub function to avoid infinite recursion
      function brew() {
        echo "Homebrew is not installed. Run 'install_brew' to install it."
      }
      return 1
    fi
  fi
  
  # Execute brew command with passed arguments
  brew "$@"
}

# Function to install Homebrew
install_brew() {
  log_message "INFO" "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Initialize Homebrew based on platform
  if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    eval "$($HOME/.linuxbrew/bin/brew shellenv)"
  elif [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  
  # Redefine the brew function to directly use the command
  unset -f brew
}

# -----------------
# Core Development Tools
# -----------------

# Install essential development tools with confirmation
install_dev_tools() {
  echo "Installing essential development tools..."
  
  local tools=("ripgrep" "neovim" "yazi" "node")
  local installers=("rg" "nvim" "yazi" "node")
  
  for i in {1..${#tools[@]}}; do
    install_if_missing "${installers[$i-1]}" "${tools[$i-1]}" "${tools[$i-1]} not found. Would you like to install it? [y/N]"
  done
  
  # Install luarocks and luasocket if needed
  if [[ "$INSTALL_MISSING_TOOLS" == "true" ]] && ! (( ${+commands[luarocks]} )); then
    log_message "INFO" "Would you like to install luarocks and luasocket? [y/N]"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      log_message "INFO" "Installing luarocks and luasocket..."
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
  
  echo "Development tools installation complete!"
}

# Add an alias to install dev tools on demand
alias install-dev-tools="install_dev_tools"

# -----------------
# Font Installation (Only runs once after initial setup)
# -----------------

# Define fonts to install
declare -a fonts=(
    BitstreamVeraSansMono
    CodeNewRoman
    FiraCode
    Hack
    JetBrainsMono
    SourceCodePro
    UbuntuMono
)

# Check if fonts need to be installed
fonts_dir="${HOME}/.local/share/fonts"
fonts_lock="${HOME}/.fonts_installed"

# Function to install fonts
install_fonts() {
  log_message "INFO" "Would you like to set up Nerd Fonts? [y/N]"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    log_message "INFO" "Setting up Nerd Fonts..."
    
    # Create fonts directory if it doesn't exist
    mkdir -p "$fonts_dir"
    
    # Set version
    version='2.1.0'
    
    # Progress counter
    total=${#fonts[@]}
    current=0
    
    # Install each font
    for font in "${fonts[@]}"; do
      current=$((current + 1))
      log_message "INFO" "Installing font ($current/$total): $font"
      
      zip_file="/tmp/${font}.zip"
      download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/${font}.zip"
      
      # Download and install the font
      if wget -q "$download_url" -O "$zip_file"; then
        unzip -q "$zip_file" -d "$fonts_dir" && rm "$zip_file"
      fi
    done
    
    # Remove Windows compatible fonts
    find "$fonts_dir" -name '*Windows Compatible*' -delete
    
    # Update font cache
    fc-cache -f
    
    # Create lock file to prevent reinstallation
    touch "$fonts_lock"
    
    log_message "INFO" "Nerd Fonts installation complete."
  fi
}

# Only offer to install fonts once and if tools auto-install is enabled
if [[ ! -f "$fonts_lock" && "$INSTALL_MISSING_TOOLS" == "true" ]]; then
  install_fonts
fi

# Add an alias to manually install fonts later if skipped
alias install-fonts="install_fonts"

# -----------------
# Fancy Terminal Integration
# -----------------

# If fastfetch and Pokémon Colorscripts are installed, run the combined command
if (( ${+commands[fastfetch]} )) && (( ${+commands[pokemon-colorscripts]} )) && [[ "$SHOW_POKEMON" == "true" ]]; then
  FASTFETCH_CONFIG="$HOME/.config/fastfetch/config-pokemon.jsonc"
  
  # Create config directory if it doesn't exist
  if [[ ! -f "$FASTFETCH_CONFIG" ]]; then
    mkdir -p "$(dirname "$FASTFETCH_CONFIG")"
    cat > "$FASTFETCH_CONFIG" <<EOL
{
  "display": {
    "separator": " ",
    "colorScheme": "dark"
  },
  "modules": [
    "title",
    "os",
    "kernel",
    "uptime",
    "packages",
    "shell",
    "memory",
    "cpu",
    "gpu"
  ]
}
EOL
  fi
  
  # Run the combined command
  pokemon-colorscripts --no-title -s -r | fastfetch -c "$FASTFETCH_CONFIG" \
    --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
fi

# -----------------
# Welcome Message
# -----------------

if [[ "$SHOW_WELCOME_MESSAGE" == "true" ]]; then
  # Get system information
  OS=$(uname -s)
  KERNEL=$(uname -r)
  if [[ -f /etc/os-release ]]; then
    DISTRO=$(grep "PRETTY_NAME" /etc/os-release | cut -d= -f2 | tr -d '"')
  else
    DISTRO="Unknown Linux Distribution"
  fi
  
  # Display a welcome message
  echo ""
  echo "🚀 Welcome to your optimized Zsh environment!"
  echo "🖥️  $DISTRO ($OS $KERNEL)"
  echo "🔄 Last login: $(date)"
  echo "💡 Type 'updateall' to update all packages and tools"
  echo "💡 Type 'install-dev-tools' to install development tools"
  echo ""
fi

# -----------------
# Finalization
# -----------------

# Run initial ls command to show current directory
ls --color=auto

# Uncomment to show startup time
# ZSHRC_END_TIME=$(date +%s.%N)
# ZSHRC_ELAPSED=$(echo "$ZSHRC_END_TIME - $ZSHRC_START_TIME" | bc)
# log_message "INFO" "Zsh initialized in $ZSHRC_ELAPSED seconds"
# zprof  # End profiling