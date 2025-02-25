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
AUTO_CHECK_UPDATES=false       # Auto-check for updates on startup

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

# Install a tool if it's missing
install_if_missing() {
  local cmd=$1
  local package=${2:-$1}
  local message=${3:-"$package not found. Installing..."}
  
  if [[ "$INSTALL_MISSING_TOOLS" == "true" ]] && ! command -v $cmd &>/dev/null; then
    log_message "INFO" "$message"
    
    # Try using our custom install script
    if [[ -f "$HOME/install.sh" ]]; then
      bash "$HOME/install.sh" $package
    # Fallback to package managers if install.sh didn't work or doesn't exist
    elif ! command -v $cmd &>/dev/null; then
      if command -v brew &>/dev/null; then
        brew install $package
      elif command -v apt-get &>/dev/null; then
        sudo apt-get update && sudo apt-get install -y $package
      elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm $package
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y $package
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

# -----------------
# Paths
# -----------------

# Add local binaries to PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export ZSH="$HOME/.oh-my-zsh"

# -----------------
# Core Zsh Options
# -----------------

# Configure Zsh history
HISTFILE="$HOME/.zsh_history"
[[ ! -f "$HISTFILE" ]] && touch "$HISTFILE"
HISTSIZE=100000
SAVEHIST=100000
setopt share_history          # Share history across all sessions
setopt hist_ignore_all_dups   # Avoid duplicate history entries
setopt hist_ignore_space      # Don't record commands starting with space
setopt hist_reduce_blanks     # Remove superfluous blanks
setopt extended_history       # Record timestamp of command

# Completion and expansion options
setopt auto_cd                # cd by typing directory name
setopt auto_pushd             # Push the current directory visited on the stack
setopt pushd_ignore_dups      # Do not store duplicates in the stack
setopt extended_glob          # Use extended globbing

# Input and output options
setopt no_beep                # Disable beeping
setopt interactive_comments   # Allow comments in interactive shells

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
    # Only show updates if AUTO_CHECK_UPDATES is enabled
    if [[ "$AUTO_CHECK_UPDATES" != "true" ]]; then
        ls --color=auto
        return
    fi

    ls --color=auto  # List directory contents with color

    # Check for Git updates if in a Git repository
    if [[ -d ".git" ]] || git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Checking for updates in $(basename "$(pwd)")..."
        git fetch > /dev/null 2>&1
        UPSTREAM=${1:-'@{u}'}
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse "$UPSTREAM")
        BASE=$(git merge-base @ "$UPSTREAM")

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
}

# Hook to run check_git_updates_and_ls whenever the directory changes
autoload -U add-zsh-hook
add-zsh-hook chpwd check_git_updates_and_ls

# -----------------
# Tool Installation & Configuration
# -----------------

# Install and configure Zoxide for intelligent directory navigation
install_if_missing "zoxide" "zoxide" "Installing zoxide for smart directory navigation..."
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  alias cd="z"  # Use zoxide's 'z' command instead of 'cd'
fi

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

# -----------------
# Aliases and Custom Configurations
# -----------------

# Source custom aliases and API keys if they exist
safe_source "$HOME/.aliases"
safe_source "$HOME/.api_keys"

# Load oh-my-zsh if available
if [[ -d "$ZSH" ]]; then
  # Define plugins to use
  plugins=(
    git
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
  )
  
  # Only load oh-my-zsh.sh if it exists
  safe_source "$ZSH/oh-my-zsh.sh"
fi

# -----------------
# Visual Enhancements
# -----------------

# Install and configure Pokémon Colorscripts if enabled
if [[ "$SHOW_POKEMON" == "true" ]]; then
  if ! command -v pokemon-colorscripts &>/dev/null && [[ "$INSTALL_MISSING_TOOLS" == "true" ]]; then
    log_message "INFO" "Installing Pokémon Colorscripts..."
    (
      git clone --depth 1 https://gitlab.com/phoneybadger/pokemon-colorscripts.git /tmp/pokemon-colorscripts &&
      cd /tmp/pokemon-colorscripts &&
      sudo ./install.sh &&
      rm -rf /tmp/pokemon-colorscripts
    ) &>/dev/null
  fi

  # Display Pokémon Colorscripts if installed
  if command -v pokemon-colorscripts &>/dev/null; then
    pokemon-colorscripts --no-title -s -r
  fi
fi

# -----------------
# Oh My Posh Theme
# -----------------

if [[ "$USE_OHMYPOSH" == "true" ]]; then
  # Install oh-my-posh if not already installed
  install_if_missing "oh-my-posh" "oh-my-posh" "Oh My Posh not found. Installing..."

  # Define theme file and URL
  THEME_FILE="$HOME/.poshthemes/devious-diamonds.omp.yaml"
  THEME_URL="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/devious-diamonds.omp.yaml"

  # Ensure the theme directory exists
  mkdir -p "$HOME/.poshthemes"

  # Download the theme if missing
  safe_download "$THEME_URL" "$THEME_FILE" "Downloading Oh My Posh theme..."
  chmod u+rw "$THEME_FILE" 2>/dev/null

  # Initialize Oh My Posh with the theme
  if command -v oh-my-posh &>/dev/null; then
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

# Homebrew detection and initialization
if ! command -v brew &>/dev/null; then
  if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ "$INSTALL_MISSING_TOOLS" == "true" ]]; then
    log_message "INFO" "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
      eval "$($HOME/.linuxbrew/bin/brew shellenv)"
    fi
  fi
fi

# -----------------
# Core Development Tools
# -----------------

# Install essential development tools
install_if_missing "rg" "ripgrep" "Installing ripgrep for better searching..."
install_if_missing "node" "node" "Installing node.js..."
install_if_missing "nvim" "neovim" "Installing Neovim..."
install_if_missing "yazi" "yazi" "Installing Yazi file manager..."

# Install luarocks and luasocket if needed
if [[ "$INSTALL_MISSING_TOOLS" == "true" ]] && ! command -v luarocks &>/dev/null; then
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

if [[ ! -f "$fonts_lock" && "$INSTALL_MISSING_TOOLS" == "true" ]]; then
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

# -----------------
# Fancy Terminal Integration
# -----------------

# If fastfetch and Pokémon Colorscripts are installed, run the combined command
if command -v fastfetch &>/dev/null && command -v pokemon-colorscripts &>/dev/null && [[ "$SHOW_POKEMON" == "true" ]]; then
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