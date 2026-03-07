if status is-interactive
    # Starship custom prompt
    starship init fish | source

    # Direnv + Zoxide
    command -v direnv &>/dev/null && direnv hook fish | source
    command -v zoxide &>/dev/null && zoxide init fish --cmd cd | source

    # Better ls
    alias ls='eza --icons --group-directories-first -1'

    # Abbrs
    abbr lg lazygit
    abbr gd 'git diff'
    abbr ga 'git add .'
    abbr gc 'git commit -am'
    abbr gl 'git log'
    abbr gs 'git status'
    abbr gst 'git stash'
    abbr gsp 'git stash pop'
    abbr gp 'git push'
    abbr gpl 'git pull'
    abbr gsw 'git switch'
    abbr gsm 'git switch main'
    abbr gb 'git branch'
    abbr gbd 'git branch -d'
    abbr gco 'git checkout'
    abbr gsh 'git show'

    abbr l ls
    abbr ll 'ls -l'
    abbr la 'ls -a'
    abbr lla 'ls -la'

    abbr -a y yazi

    # Custom colours
    cat ~/.local/state/caelestia/sequences.txt 2>/dev/null

    # For jumping between prompts in foot terminal
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end
end

# Paths to your tackle
set tacklebox_path ~/.tackle ~/.tacklebox
# Path Configuration
fish_add_path $HOME/bin
fish_add_path $HOME/.local/bin
fish_add_path $XDG_DATA_HOME/../bin
fish_add_path $HOME/.lmstudio/bin
# Theme
#set tacklebox_theme entropy

# Which modules would you like to load? (modules can be found in ~/.tackle/modules/*)
# Custom modules may be added to ~/.tacklebox/modules/
# Example format: set tacklebox_modules virtualfish virtualhooks

# Which plugins would you like to enable? (plugins can be found in ~/.tackle/plugins/*)
# Custom plugins may be added to ~/.tacklebox/plugins/
# Example format: set tacklebox_plugins python extract

# Load Tacklebox configuration
. ~/.tacklebox/tacklebox.fish
