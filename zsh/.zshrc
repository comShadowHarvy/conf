#!/usr/bin/env zsh
# =====================================================
# ShadowHarvy's Optimized Zsh Configuration
# Lightweight, fast, and focused on essentials
# =====================================================

# --- 1. Core Speed Optimizations ---
# Compile completions in the background to speed up startup
if [[ -n "$ZSH_DEBUGRC" ]]; then zmodload zsh/zprof; fi

# --- 2. Environment Variables ---
export ZDOTDIR="${ZDOTDIR:-$HOME}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$ZDOTDIR/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$ZDOTDIR/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$ZDOTDIR/.cache}"
export EDITOR="nvim"
export VISUAL="nvim"

# Path Configuration (Unique entries only)
typeset -U path
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$XDG_DATA_HOME/../bin"
  "$HOME/.lmstudio/bin"
  $path
)

# --- 3. Shell Options ---
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY          # Append to history file
setopt SHARE_HISTORY           # Share history between sessions
setopt HIST_IGNORE_DUPS        # Ignore duplicates
setopt HIST_IGNORE_SPACE       # Ignore commands starting with space
setopt HIST_REDUCE_BLANKS      # Remove extra spaces
setopt AUTO_CD                 # cd by typing directory name
setopt ALWAYS_TO_END           # Move cursor to end of completed word
setopt NO_BEEP                 # Silence is golden

# --- 4. Completion System ---
autoload -Uz compinit add-zsh-hook
# Check cache once a day to speed up startup
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit;
else
  compinit -C;
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- 5. Plugins (Lazy Loaded) ---
# FZF
if (( $+commands[fzf] )); then
  source <(fzf --zsh)
  (( $+commands[fd] )) && export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
fi

# Zoxide
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh --cmd cd)"
fi

# --- 6. Oh My Posh Configuration (Auto-Fixing) ---
if (( $+commands[oh-my-posh] )); then
  THEME_URL="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/devious-diamonds.omp.yaml"
  THEME_CONFIG="$XDG_CONFIG_HOME/oh-my-posh/themes/devious-diamonds.omp.yaml"

  # If theme file is missing, download it silently
  if [[ ! -f "$THEME_CONFIG" ]]; then
      mkdir -p "$(dirname "$THEME_CONFIG")"
      curl -sSL "$THEME_URL" -o "$THEME_CONFIG"
  fi

  # Initialize
  if [[ -f "$THEME_CONFIG" ]]; then
      eval "$(oh-my-posh init zsh --config "$THEME_CONFIG")"
  else
      # Fallback to default if download failed
      eval "$(oh-my-posh init zsh)"
  fi
else
  # Fallback if oh-my-posh is completely missing
  autoload -Uz promptinit && promptinit && prompt adam1
fi

# --- 7. Git Status Checker (Unrestricted) ---
# Checks for updates on ALL git repos when you cd into them
_check_git_updates() {
  # 1. Fast check: Are we in a git repo?
  [[ ! -d .git ]] && [[ ! -f .git ]] && return

  # 2. Async background fetch (Runs in subshell &!)
  {
    git fetch --quiet &>/dev/null
    local exit_code=$?
    
    if (( exit_code == 0 )); then
        local UPSTREAM='@{u}' LOCAL REMOTE BASE status_msg color
        LOCAL=$(git rev-parse @ 2>/dev/null)
        REMOTE=$(git rev-parse "$UPSTREAM" 2>/dev/null)

        if [[ -n "$LOCAL" && -n "$REMOTE" ]]; then
            BASE=$(git merge-base @ "$UPSTREAM" 2>/dev/null)
            if [[ "$LOCAL" = "$REMOTE" ]]; then
                status_msg="✔ Up to date."
                color="green"
            elif [[ "$LOCAL" = "$BASE" ]]; then
                status_msg="⇩ Updates available (git pull)."
                color="blue"
            elif [[ "$REMOTE" = "$BASE" ]]; then
                status_msg="⇧ Unpushed changes (git push)."
                color="yellow"
            else
                status_msg="⚠ Diverged."
                color="red"
            fi
            # Print the status message to the terminal
            print -P "%F{$color}Git status: $status_msg%f"
        fi
    fi
  } &! 
}

# Run the git check whenever directory changes
add-zsh-hook chpwd _check_git_updates
# Run it once on startup for the current folder
_check_git_updates

# --- 8. Startup Banner (Reordered) ---
# Helper function to handle the complex ScreenFX randomization
function _run_screenfx() {
    source ~/bin/screenfx.sh
    
    # 1. Pick random style (exclude 'static')
    local -a _styles=("${(@)SCREENFX_STYLES:#static}")
    if [[ ${#_styles[@]} -gt 0 ]]; then
        local -i _idx=$(( (RANDOM % ${#_styles[@]}) + 1 ))
        export SCREENFX_STYLE="${_styles[_idx]}"
    fi
    
    # 2. Pick random screen file from your config repo
    local -a _screen_files=("$HOME/git/conf"/screen*.txt)
    
    if [[ ${#_screen_files[@]} -gt 0 ]]; then
        # Zsh arrays are 1-indexed
        local -i _screen_idx=$(( (RANDOM % ${#_screen_files[@]}) + 1 ))
        screenfx::show "${_screen_files[_screen_idx]}"
    fi
}

function _show_banner() {
    # 1. ScreenFX (Random Splash) - Now First
    [[ -f ~/bin/screenfx.sh ]] && _run_screenfx
    
    # 2. System Info (Pokemon/Fastfetch)
    if (( $+commands[pokemon-colorscripts] )) && (( $+commands[fastfetch] )); then
        # Pipe pokemon into fastfetch
        pokemon-colorscripts --no-title -s -r | \
        fastfetch -c "$HOME/.config/fastfetch/config-pokemon.jsonc" --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
    elif (( $+commands[fastfetch] )); then
        fastfetch
    else
        print -P "%F{cyan}🚀 Welcome back, ShadowHarvy.%f"
    fi

    # 3. Holiday Dashboard
    if (( $+commands[uv] )) && [[ -f ~/bin/holiday_dashboard.py ]]; then
        echo "" # Spacer
        uv run ~/bin/holiday_dashboard.py
    fi
}
[[ -o interactive ]] && _show_banner

# --- 9. Aliases ---
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias grep='rg'
alias cat='bat'
alias updateall='~/bin/zsh_maintain.sh'

# Source separated alias files if they exist
for alias_file in "$HOME/.aliases.d"/*.aliases; do
  [[ -f "$alias_file" ]] && source "$alias_file"
done

# --- 10. Keybindings ---
bindkey -e
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# --- 11. Local Overrides ---
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

. "$HOME/.local/share/../bin/env"
