# =====================================================
# Zsh Configuration with ZimFW and Custom Enhancements
# =====================================================

# -----------------
# Paths
# -----------------

# Add local binaries to PATH
export PATH="$HOME/.local/bin:$PATH"
# If you come from bash you might have to change your $PATH.
# export PATH="$HOME/bin:/usr/local/bin:$PATH"

export ZSH="$HOME/.oh-my-zsh"

# -----------------
# ZimFW Configuration
# -----------------

# Set ZimFW installation path
ZIM_HOME=${ZDOTDIR:-$HOME}/.zim

# Download ZimFW if missing
if [[ ! -f "${ZIM_HOME}/zimfw.zsh" ]]; then
  curl -fsSL --create-dirs -o "${ZIM_HOME}/zimfw.zsh" \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# Initialize ZimFW and install missing modules
source "${ZIM_HOME}/zimfw.zsh" init

# -----------------
# Git Updates and Directory Listing
# -----------------

# Function to check for Git updates and display directory contents
check_git_updates_and_ls() {
    ls --color=auto  # List directory contents with color

    # Check for Git updates if in a Git repository
    if [ -d ".git" ] || git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Checking for updates in $(basename "$(pwd)")..."
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

# Hook to run check_git_updates_and_ls whenever the directory changes
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
HISTFILE="$HOME/.zsh_history"
[ ! -f "$HISTFILE" ] && touch "$HISTFILE"  # create the history file if it doesn't exist
HISTSIZE=100000
SAVEHIST=100000
setopt share_history          # Share history across all sessions
setopt hist_ignore_all_dups   # Avoid duplicate history entries

# -----------------
# Keybindings
# -----------------

# Use Emacs keybindings
bindkey -e
# Bind arrow keys for history substring search
bindkey "${terminfo[kcuu1]}" history-substring-search-up
bindkey "${terminfo[kcud1]}" history-substring-search-down

# -----------------
# Aliases and Custom Configurations
# -----------------

# Source custom aliases and API keys if they exist
[ -f "$HOME/.aliases" ] && source "$HOME/.aliases"
[ -f "$HOME/.api_keys" ] && source "$HOME/.api_keys"

# Uncomment to change your theme
# ZSH_THEME="funky"

plugins=(
    git
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Load oh-my-zsh
source "$ZSH/oh-my-zsh.sh"

# -----------------
# Pokémon Colorscripts Installation
# -----------------

# If Pokémon Colorscripts is not installed, clone and install it.
if ! command -v pokemon-colorscripts > /dev/null 2>&1; then
  echo "Pokémon Colorscripts not found. Installing..."
  git clone --depth 1 https://gitlab.com/phoneybadger/pokemon-colorscripts.git &&
  cd pokemon-colorscripts &&
  sudo ./install.sh &&
  cd ..
fi

# Display Pokémon Colorscripts if installed
if command -v pokemon-colorscripts > /dev/null 2>&1; then
  pokemon-colorscripts --no-title -s -r
fi

# -----------------
# Oh My Posh Theme
# -----------------

# Install oh-my-posh if not already installed
if ! command -v oh-my-posh > /dev/null 2>&1; then
  echo "Oh My Posh is not installed. Installing..."
  curl -s https://ohmyposh.dev/install.sh | bash -s
fi

# Define theme file and URL
THEME_FILE="$HOME/.poshthemes/devious-diamonds.omp.yaml"
THEME_URL="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/devious-diamonds.omp.yaml"

# Ensure the theme directory exists
mkdir -p "$HOME/.poshthemes"

# Download the theme if missing
if [[ ! -f "$THEME_FILE" ]]; then
  echo "Devious Diamonds theme not found. Downloading..."
  curl -fsSL "$THEME_URL" -o "$THEME_FILE"
  chmod u+rw "$THEME_FILE"
  echo "Theme downloaded to $THEME_FILE"
fi

# Initialize Oh My Posh with the Devious Diamonds theme
eval "$(oh-my-posh init zsh --config "$THEME_FILE")"

# -----------------
# Fabric Bootstrap (Optional)
# -----------------

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

# Homebrew detection and initialization
if ! command -v brew &>/dev/null && [ ! -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif command -v brew &>/dev/null; then
    eval "$(brew shellenv)"
fi

# Install ripgrep if missing
if ! command -v rg &>/dev/null; then
    echo "ripgrep not found. Installing via Homebrew..."
    brew install ripgrep
fi

# Install node if missing
if ! command -v node &>/dev/null; then
    echo "node not found. Installing via Homebrew..."
    brew install node
fi

# If fastfetch is installed, run the combined Pokémon Colorscripts and fastfetch command
if command -v fastfetch > /dev/null 2>&1 && command -v pokemon-colorscripts > /dev/null 2>&1; then
    pokemon-colorscripts --no-title -s -r | fastfetch -c "$HOME/.config/fastfetch/config-pokemon.jsonc" \
      --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
fi

# Check if luarocks is installed; if not, install it along with luasocket
if ! command -v luarocks &>/dev/null; then
  echo "luarocks not found. Installing luarocks and luasocket..."

  # Download luarocks
  wget -O /tmp/luarocks-3.11.1.tar.gz https://luarocks.org/releases/luarocks-3.11.1.tar.gz

  # Extract and change to the directory
  tar zxpf /tmp/luarocks-3.11.1.tar.gz -C /tmp
  cd /tmp/luarocks-3.11.1

  # Configure, compile, and install luarocks
  ./configure && make && sudo make install

  # Install the luasocket module via luarocks
  sudo luarocks install luasocket

  echo "Installation complete."
else
  echo "luarocks is already installed."
fi
declare -a fonts=(
    BitstreamVeraSansMono
    CodeNewRoman
    DroidSansMono
    FiraCode
    FiraMono
    Go-Mono
    Hack
    Hermit
    JetBrainsMono
    Meslo
    Noto
    Overpass
    ProggyClean
    RobotoMono
    SourceCodePro
    SpaceMono
    Ubuntu
    UbuntuMono
)

version='2.1.0'
fonts_dir="${HOME}/.local/share/fonts"

if [[ ! -d "$fonts_dir" ]]; then
    echo "Creating fonts directory: $fonts_dir"
    mkdir -p "$fonts_dir"

    for font in "${fonts[@]}"; do
        zip_file="${font}.zip"
        download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/${zip_file}"
        echo "Downloading $download_url"

        if wget -q "$download_url"; then
            echo "Download successful."
            if unzip -q "$zip_file" -d "$fonts_dir"; then
                echo "Unzip successful."
                rm "$zip_file"
            else
                echo "Unzip failed for $zip_file"
            fi
        else
            echo "Download failed for $download_url"
        fi
    done

    find "$fonts_dir" -name '*Windows Compatible*' -delete

    fc-cache -fv
else
    echo "Fonts directory already exists: $fonts_dir. Skipping download and installation."
fi
