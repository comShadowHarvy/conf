# Stow Configuration Restore Script

A simple script to restore all your stow configurations with one command.

## Quick Start

```bash
# Restore all configurations (recommended)
./restore-stow.sh

# Check what would be restored first (dry run)
./restore-stow.sh --dry-run

# Check current status
./restore-stow.sh --status
```

## Usage

```bash
./restore-stow.sh [options] [group/packages]
```

### Options

- `-n, --dry-run` - Show what would be done without executing
- `-f, --force` - Force operations, remove conflicts
- `-g, --group GROUP` - Restore specific group
- `-p, --packages LIST` - Restore specific packages (comma-separated)
- `--no-backup` - Skip creating backup of existing configs
- `--no-interactive` - Run in non-interactive mode
- `-s, --status` - Show current package status and exit
- `-h, --help` - Show help message

### Groups

- **essential** - Core shell and git configuration (bash git shared scripts)
- **minimal** - Minimal setup (bash git shared)
- **development** - Development tools (nvim tmux vscode)
- **desktop** - GUI/Desktop environment (hyprland waybar)
- **full** - Full configuration (default)
- **all** - Everything including optional packages

## Examples

```bash
# Restore full configuration (default)
./restore-stow.sh

# Dry run to see what would happen
./restore-stow.sh --dry-run

# Restore only essential packages
./restore-stow.sh --group essential

# Restore specific packages
./restore-stow.sh --packages bash,git,nvim

# Force restore, removing conflicts
./restore-stow.sh --force

# Check current status
./restore-stow.sh --status
```

## What It Does

1. **Checks dependencies** - Ensures GNU Stow is installed
2. **Creates backups** - Backs up existing config files (unless `--no-backup`)
3. **Stows packages** - Uses GNU Stow to symlink your configurations
4. **Provides feedback** - Shows what was done and next steps

## Safety Features

- Creates backups of existing files before overwriting
- Dry-run mode to preview changes
- Interactive confirmation (unless `--no-interactive`)
- Graceful error handling

## After Restoration

After running the script, you may need to:

- Source your shell configuration: `source ~/.bashrc` or `source ~/.zshrc`
- For tmux: `tmux source-file ~/.tmux.conf`
- For Neovim: Launch `nvim` to install plugins

## Files

- **Main script**: `restore-stow.sh`
- **Wrapper**: `bin/restore-stow` (can be added to PATH)
- **Configuration**: `stow-config.yaml`
- **Backups**: Saved to `~/.stow-restore-backup-TIMESTAMP`

## Troubleshooting

### Conflicts

If you get conflicts, use `--force` to overwrite existing files:

```bash
./restore-stow.sh --force
```

### Missing packages

Check available packages:

```bash
./restore-stow.sh --status
```

### Stow not installed

Install GNU Stow:

```bash
# Arch Linux
sudo pacman -S stow

# Ubuntu/Debian  
sudo apt install stow

# macOS
brew install stow
```

## Manual Stow Commands

You can also use stow directly:

```bash
# Stow a package
stow -d /home/me/git/conf -t /home/me bash

# Unstow a package
stow -d /home/me/git/conf -t /home/me -D bash

# Restow a package (unstow + stow)
stow -d /home/me/git/conf -t /home/me -R bash
```