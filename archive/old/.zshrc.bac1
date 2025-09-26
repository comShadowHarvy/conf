# -----------------
# ZimFW Configuration
# -----------------

ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim

# Download zimfw plugin manager if missing
if [[ ! -f ${ZIM_HOME}/zimfw.zsh ]]; then
  curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# Initialize ZimFW and install missing modules
source ${ZIM_HOME}/zimfw.zsh init

# -----------------
# History Management
# -----------------

HISTFILE=${HOME}/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt share_history hist_ignore_all_dups

# -----------------
# Keybindings
# -----------------

bindkey -e  # Emacs keybindings
bindkey "${terminfo[kcuu1]}" history-substring-search-up
bindkey "${terminfo[kcud1]}" history-substring-search-down

# -----------------
# Aliases and Custom Configurations
# -----------------

# Load personal aliases and functions
[ -f ~/.aliases ] && source ~/.aliases
[ -f ~/.api_keys ] && source ~/.api_keys

# -----------------
# Paths
# -----------------

export PATH="$HOME/.local/bin:$PATH"

# -----------------
# Oh My Posh Theme
# -----------------

#eval "$(oh-my-posh init zsh --config ~/.poshthemes/devious-diamonds.omp.yaml)"


# ========================
# Oh My Posh Configuration
# ========================
# Path to the theme file
THEME_FILE="$HOME/.poshthemes/devious-diamonds.omp.yaml"

# URL to download the theme
THEME_URL="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/devious-diamonds.omp.yaml"

# Ensure the ~/.poshthemes directory exists
mkdir -p ~/.poshthemes

# Check if the theme file exists; if not, download it
if [[ ! -f "$THEME_FILE" ]]; then
  echo "Devious Diamonds theme not found. Downloading..."
  curl -fsSL "$THEME_URL" -o "$THEME_FILE"
  chmod u+rw "$THEME_FILE"
  echo "Theme downloaded to $THEME_FILE"
fi

# Load Oh My Posh with the Devious Diamonds theme
eval "$(oh-my-posh init zsh --config $THEME_FILE)"



# -----------------
# Fabric Bootstrap (Optional)
# -----------------

# Check if Fabric bootstrap is present before sourcing
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
