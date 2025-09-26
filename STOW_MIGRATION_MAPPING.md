# Stow Migration Mapping

## Current State Analysis

### Files in `/home/me/conf` (to be organized into packages)

| Current Path | Target Package | Target Path | Notes |
|-------------|----------------|-------------|-------|
| `.bashrc` | `bash` | `bash/.bashrc` | Main bash configuration |
| `.bash_profile` | `bash` | `bash/.bash_profile` | Bash login profile |
| `.bash_logout` | `bash` | `bash/.bash_logout` | Bash logout script |
| `.zshrc` | `zsh` | `zsh/.zshrc` | Main zsh configuration |
| `.gitconfig` | `git` | `git/.gitconfig` | Git user configuration |
| `.wgetrc` | `wget` | `wget/.wgetrc` | Wget configuration |
| `.api_keys` | `secrets` | `secrets/.api_keys` | API keys (consider security) |
| `.antigenrc` | `zsh` | `zsh/.antigenrc` | Antigen (zsh plugin manager) config |
| `antigen.zsh` | `zsh` | `zsh/.local/share/antigen/antigen.zsh` | Antigen script |

### Config Directories to be Packaged

| Current Path | Target Package | Target Path | Notes |
|-------------|----------------|-------------|-------|
| `.config/nvim.old/*` | `nvim` | `nvim/.config/nvim/` | Neovim configuration |
| `.config/waybar.old/*` | `waybar` | `waybar/.config/waybar/` | Waybar configuration |
| `.config/hypr.bac/*` | `hyprland` | `hyprland/.config/hypr/` | Hyprland WM config |
| `.tmux/*` | `tmux` | `tmux/.config/tmux/` | Tmux configuration |
| `.vscode/settings.json` | `vscode` | `vscode/.vscode/settings.json` | VS Code settings |

### Application Scripts and Utilities

| Current Path | Target Package | Target Path | Notes |
|-------------|----------------|-------------|-------|
| `app/*` | `scripts` | `scripts/bin/` | Custom utility scripts |
| `aliases.d/*` | `bash,zsh` | `bash/.aliases.d/` and `zsh/.aliases.d/` | Modular aliases |
| `.aliases*` | Multiple | Split between bash/zsh | Legacy alias files |

### Backup/Duplicate Files to Handle

| File Pattern | Action | Notes |
|-------------|---------|-------|
| `*.bak`, `*.orig` | Archive or delete | Keep only if significantly different |
| `*-20250915*` | Archive or delete | Dated backups |
| `.zshrc.clean` | Compare and delete | Likely redundant |
| `old/*` | Archive | Move to `archive/old/` |

## Proposed Stow Package Structure

```
/home/me/conf/
├── bash/
│   ├── .bashrc
│   ├── .bash_profile
│   ├── .bash_logout
│   └── .aliases.d/          # symlinked to shared aliases
├── zsh/
│   ├── .zshrc
│   ├── .antigenrc
│   ├── .aliases.d/          # symlinked to shared aliases
│   └── .local/share/antigen/antigen.zsh
├── git/
│   └── .gitconfig
├── tmux/
│   └── .config/tmux/
├── nvim/
│   └── .config/nvim/
├── hyprland/
│   └── .config/hypr/
├── waybar/
│   └── .config/waybar/
├── vscode/
│   └── .vscode/settings.json
├── wget/
│   └── .wgetrc
├── secrets/
│   └── .api_keys
├── scripts/
│   └── bin/                 # All app/ scripts go here
├── shared/
│   └── .aliases.d/          # Shared between bash/zsh
└── archive/
    ├── old/
    └── backups/
```

## Migration Strategy

1. **Packages to create first**: `bash`, `zsh`, `git`, `tmux`, `nvim`
2. **Secondary packages**: `hyprland`, `waybar`, `vscode`, `wget`, `secrets`, `scripts`
3. **Shared components**: `aliases.d` will be symlinked from both bash and zsh packages

## Files in $HOME that will be replaced

- `.bashrc` (will become symlink to `conf/bash/.bashrc`)
- `.zshrc` (will become symlink to `conf/zsh/.zshrc`)
- `.bash_profile` (will become symlink to `conf/bash/.bash_profile`)

## Safety Notes

- Current `.tmux.conf` is already a symlink: `lrwxrwxrwx -> /home/me/.config/tmux/.tmux.config`
- Need to check if current home configs are newer than conf/ versions
- Make full backup before stowing