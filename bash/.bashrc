# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# --- Path Configuration (from zshrc) ---
# Add custom bin directories to PATH
export PATH="$HOME/bin:$HOME/.local/bin:$XDG_DATA_HOME/../bin:$PATH"

# Source environment variables from bin/env if it exists
[[ -f "$HOME/.local/share/../bin/env" ]] && source "$HOME/.local/share/../bin/env"
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# --- Editor Configuration ---
export EDITOR="nvim"
export VISUAL="nvim"

# --- XDG Base Directory Specification ---
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# --- Python Virtual Environment Alias ---
PYTHON_ENV_PATH="/home/me/python_packages_env/bin/activate"
if [[ -f "$PYTHON_ENV_PATH" ]]; then
    alias activate-python-env="source $PYTHON_ENV_PATH"
fi

# --- Utility Aliases ---
alias reload-bash="exec bash -l"

# --- Load Modular Aliases (if using Stow structure) ---
if [[ -d "$HOME/.aliases.d" ]]; then
    for alias_file in "$HOME/.aliases.d/"*.aliases; do
        [[ -f "$alias_file" ]] && source "$alias_file"
    done
fi
