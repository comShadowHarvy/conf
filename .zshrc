# =====================================================
# Zsh Configuration with ZimFW and Custom Enhancements
# =====================================================

# -----------------
# ZimFW Configuration
# -----------------

# Set ZimFW installation path
ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim

# Download ZimFW if missing
if [[ ! -f ${ZIM_HOME}/zimfw.zsh ]]; then
  curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# Initialize ZimFW and install missing modules
source ${ZIM_HOME}/zimfw.zsh init

# -----------------
# Git Updates and Directory Listing
# -----------------

# Function to check for Git updates and display directory contents
function check_git_updates_and_ls() {
    ls --color=auto  # List directory contents with color

    # Check for Git updates if the directory is a Git repository
    if [ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Checking for updates in $(basename $(pwd))..."
        git fetch > /dev/null 2>&1
        UPSTREAM=${1:-'@{u}'}
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse "$UPSTREAM")
        BASE=$(git merge-base @ "$UPSTREAM")

        if [ "$LOCAL" = "$REMOTE" ]; then
            echo "✔ Repository is up to date."
        elif [ "$LOCAL" = "$BASE" ]; then
            echo "⇩ Updates are available. Run 'git pull'."
        elif [ "$REMOTE" = "$BASE" ]; then
            echo "⇧ Local changes haven't been pushed. Run 'git push'."
        else
            echo "⚠ Repository has diverged."
        fi
    fi
}

# Hook to run `check_git_updates_and_ls` whenever the directory changes
autoload -U add-zsh-hook
add-zsh-hook chpwd check_git_updates_and_ls

# -----------------
# Zoxide Installation
# -----------------

# Install Zoxide if not already installed
if ! command -v zoxide > /dev/null 2>&1; then
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# -----------------
# History Management
# -----------------

# Configure Zsh history
HISTFILE=${HOME}/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt share_history          # Share history across all sessions
setopt hist_ignore_all_dups   # Avoid duplicate entries in history

# -----------------
# Keybindings
# -----------------

# Set Emacs keybindings for Zsh
bindkey -e
# Bind arrow keys for history substring search
bindkey "${terminfo[kcuu1]}" history-substring-search-up
bindkey "${terminfo[kcud1]}" history-substring-search-down

# -----------------
# Aliases and Custom Configurations
# -----------------

# Source custom aliases and API keys if they exist
[ -f ~/.aliases ] && source ~/.aliases
[ -f ~/.api_keys ] && source ~/.api_keys

# -----------------
# Paths
# -----------------

# Add local binaries to PATH
export PATH="$HOME/.local/bin:$PATH"

# -----------------
# Oh My Posh Theme
# -----------------

# Check if oh-my-posh is installed
if ! command -v oh-my-posh > /dev/null 2>&1; then
  echo "Oh My Posh is not installed. Installing..."
  curl -s https://ohmyposh.dev/install.sh | bash -s
fi

# Path to the theme file
THEME_FILE="$HOME/.poshthemes/devious-diamonds.omp.yaml"

# URL to download the theme
THEME_URL="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/devious-diamonds.omp.yaml"

# Ensure ~/.poshthemes directory exists
mkdir -p ~/.poshthemes

# Download the theme if missing
if [[ ! -f "$THEME_FILE" ]]; then
  echo "Devious Diamonds theme not found. Downloading..."
  curl -fsSL "$THEME_URL" -o "$THEME_FILE"
  chmod u+rw "$THEME_FILE"
  echo "Theme downloaded to $THEME_FILE"
fi

# Initialize Oh My Posh with the Devious Diamonds theme
eval "$(oh-my-posh init zsh --config $THEME_FILE)"

# -----------------
# Fabric Bootstrap (Optional)
# -----------------

# Load Fabric bootstrap if available
if [[ -f "$HOME/.config/fabric/fabric-bootstrap.inc" ]]; then
  echo "Loading Fabric Bootstrap..."
  source "$HOME/.config/fabric/fabric-bootstrap.inc"
else
  echo "Fabric Bootstrap not found. Skipping."
fi

# -----------------
# Cleanup & Final Notes
# -----------------

echo "Zsh configuration loaded successfully."
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
if type brew &>/dev/null; then
FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

autoload -Uz compinit
compinit
fi
