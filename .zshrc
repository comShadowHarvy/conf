# Use powerline
USE_POWERLINE=true
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
if [ -f "/home/me/.config/fabric/fabric-bootstrap.inc" ]; then . "/home/me/.config/fabric/fabric-bootstrap.inc"; fi