# Use powerline
#USE_POWERLINE=true
# Has weird character width
# Example:
#    is not a diamond
HAS_WIDECHARS=false
# Source manjaro-zsh-configuration
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
fi
# Use manjaro zsh prompt
if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
  source /usr/share/zsh/manjaro-zsh-prompt
fi


[ -f ~/.api_keys ] && source ~/.api_keys
[ -f ~/.aliases ] && source ~/.aliases
[ -f ~/.zsh1 ] && source ~/.zsh1
[ -f ~/antigen.zsh ] && source ~/antigen.zsh
export PATH="$HOME/.local/bin:$PATH"
eval "$(oh-my-posh init zsh --config ~/.poshthemes/devious-diamonds.omp.yaml)"
if [ -f "/home/me/.config/fabric/fabric-bootstrap.inc" ]; then . "/home/me/.config/fabric/fabric-bootstrap.inc"; fi
echo "source ${HOME}/.zgenom/zgenom.zsh" >> ~/.zshrc
### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk
source /home/me/.zgenom/zgenom.zsh
