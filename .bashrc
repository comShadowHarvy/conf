#####################################################################
# ~/.bashrc - Integrated Configuration
#
# This file combines customizations from your old bashrc with a
# Bash-adapted version of your Zsh/Zim setup.
#####################################################################

# Exit if not running interactively.
[[ $- != *i* ]] && return

# --------------------------------------------------
# Colors Testing Function
# --------------------------------------------------
colors() {
    local fgc bgc vals seq0

    printf "Color escapes are %s\n" '\e[${value};...;${value}m'
    printf "Values 30..37 are \e[33mforeground colors\e[m\n"
    printf "Values 40..47 are \e[43mbackground colors\e[m\n"
    printf "Value  1 gives a  \e[1mbold-faced look\e[m\n\n"

    for fgc in {30..37}; do
        for bgc in {40..47}; do
            # Optionally adjust to display defaults
            fgc=${fgc#37}  # white (if needed)
            bgc=${bgc#40}  # black (if needed)

            vals="${fgc:+$fgc;}${bgc}"
            vals=${vals%%;}
            seq0="${vals:+\e[${vals}m}"
            printf "  %-9s" "${seq0:-(default)}"
            printf " ${seq0}TEXT\e[m"
            printf " \e[${vals:+${vals+$vals;}}1mBOLD\e[m"
        done
        echo; echo
    done
}

# --------------------------------------------------
# Bash Completion
# --------------------------------------------------
if [ -r /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
fi

# --------------------------------------------------
# Terminal Title (for X-based terminals)
# --------------------------------------------------
case ${TERM} in
    xterm*|rxvt*|Eterm*|aterm|kterm|gnome*|interix|konsole*)
        PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\007"'
        ;;
    screen*)
        PROMPT_COMMAND='echo -ne "\033_${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\033\\"'
        ;;
esac

# --------------------------------------------------
# Git Updates & Directory Listing
# --------------------------------------------------
check_git_updates_and_ls() {
    ls --color=auto  # List directory contents with color

    # If in a Git repository, check for updates.
    if [ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1; then
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
# Override the default cd command to run the Git check after directory change.
cd() {
    builtin cd "$@" && check_git_updates_and_ls
}

# --------------------------------------------------
# Zoxide Installation
# --------------------------------------------------
if ! command -v zoxide > /dev/null 2>&1; then
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# --------------------------------------------------
# History Management
# --------------------------------------------------
export HISTFILE="$HOME/.bash_history"
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend
# Append history on each command; also reload history so sessions share commands.
export PROMPT_COMMAND="history -a; history -c; history -r; ${PROMPT_COMMAND}"

# --------------------------------------------------
# Keybindings (Emacs-style with prefix history search)
# --------------------------------------------------
bind -e
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# --------------------------------------------------
# Aliases & Custom Configurations
# --------------------------------------------------
# Source additional aliases or API keys if the files exist.
if [ -f "$HOME/.aliases" ]; then
    source "$HOME/.aliases"
fi
if [ -f "$HOME/.api_keys" ]; then
    source "$HOME/.api_keys"
fi

# --------------------------------------------------
# Local Binaries in PATH
# --------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"

# --------------------------------------------------
# Oh My Posh Theme Setup for Bash
# --------------------------------------------------
if ! command -v oh-my-posh > /dev/null 2>&1; then
  echo "Oh My Posh is not installed. Installing..."
  curl -s https://ohmyposh.dev/install.sh | bash -s
fi

THEME_FILE="$HOME/.poshthemes/devious-diamonds.omp.yaml"
THEME_URL="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/devious-diamonds.omp.yaml"

mkdir -p "$HOME/.poshthemes"

if [ ! -f "$THEME_FILE" ]; then
  echo "Devious Diamonds theme not found. Downloading..."
  curl -fsSL "$THEME_URL" -o "$THEME_FILE"
  chmod u+rw "$THEME_FILE"
  echo "Theme downloaded to $THEME_FILE"
fi

# Initialize Oh My Posh for Bash.
eval "$(oh-my-posh init bash --config "$THEME_FILE")"

# --------------------------------------------------
# Fabric Bootstrap (Optional)
# --------------------------------------------------
if [ -f "$HOME/.config/fabric/fabric-bootstrap.inc" ]; then
  echo "Loading Fabric Bootstrap..."
  source "$HOME/.config/fabric/fabric-bootstrap.inc"
else
  echo "Fabric Bootstrap not found. Skipping."
fi

# --------------------------------------------------
# Homebrew Integration (Linuxbrew)
# --------------------------------------------------
if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if command -v brew &>/dev/null; then
    if [ -f "$(brew --prefix)/etc/bash_completion" ]; then
        source "$(brew --prefix)/etc/bash_completion"
    fi
fi

# --------------------------------------------------
# Additional Shell Options from Old bashrc
# --------------------------------------------------
# Adjust terminal window size after each command.
shopt -s checkwinsize
# Ensure aliases are expanded.
shopt -s expand_aliases

# Allow local root processes to access the X server.
xhost +local:root > /dev/null 2>&1

# (Optional) Source Fabric bootstrap if placed in another location.
if [ -f "$HOME/.config/fabric/fabric-bootstrap.inc" ]; then
  source "$HOME/.config/fabric/fabric-bootstrap.inc"
fi

# --------------------------------------------------
# Colorful Prompt Setup (similar to your old bashrc)
# --------------------------------------------------
use_color=true
safe_term=${TERM//[^[:alnum:]]/?}
match_lhs=""

if [ -f "$HOME/.dir_colors" ]; then
    match_lhs="$match_lhs$(<"$HOME/.dir_colors")"
fi
if [ -f /etc/DIR_COLORS ]; then
    match_lhs="$match_lhs$(</etc/DIR_COLORS)"
fi
if [ -z "$match_lhs" ] && command -v dircolors >/dev/null; then
    match_lhs=$(dircolors --print-database)
fi
if [[ $'\n'$match_lhs == *$'\n'"TERM ${safe_term}"* ]]; then
    use_color=true
fi

if $use_color; then
    if [ "$EUID" -eq 0 ]; then
        PS1='\[\033[01;31m\][\h\[\033[01;36m\] \W\[\033[01;31m\]]\$\[\033[00m\] '
    else
        PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] '
    fi
    alias ls='ls --color=auto'
    alias grep='grep --colour=auto'
    alias egrep='egrep --colour=auto'
    alias fgrep='fgrep --colour=auto'
else
    if [ "$EUID" -eq 0 ]; then
        PS1='\u@\h \W \$ '
    else
        PS1='\u@\h \w \$ '
    fi
fi

unset use_color safe_term match_lhs

# --------------------------------------------------
# Final Message
# --------------------------------------------------
echo "Bash configuration loaded successfully."
