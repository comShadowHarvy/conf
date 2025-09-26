# 🏠 Dotfiles - Stow Managed Configuration

[![Stow](https://img.shields.io/badge/managed%20with-GNU%20Stow-blue.svg)](https://www.gnu.org/software/stow/)
[![Tests](https://img.shields.io/badge/tests-passing-green.svg)](#test-results)
[![Platform](https://img.shields.io/badge/platform-Arch%20Linux-blue.svg)](https://archlinux.org/)

This repository contains my personal dotfiles, organized as [GNU Stow](https://www.gnu.org/software/stow/) packages for easy management and deployment across systems.

## 📁 Repository Structure

```
/home/me/conf/
├── bash/              # Bash shell configuration
│   ├── .bashrc
│   ├── .bash_profile  
│   └── .bash_logout
├── zsh/               # Zsh shell configuration
│   ├── .zshrc
│   ├── .antigenrc
│   └── .local/share/antigen/antigen.zsh
├── git/               # Git configuration
│   └── .gitconfig
├── tmux/              # Tmux configuration
│   └── .config/tmux/
├── nvim/              # Neovim configuration
│   └── .config/nvim/
├── hyprland/          # Hyprland window manager
│   └── .config/hypr/
├── waybar/            # Waybar status bar
│   └── .config/waybar/
├── vscode/            # Visual Studio Code settings
│   └── .vscode/
├── wget/              # Wget configuration
│   └── .wgetrc
├── secrets/           # API keys and secrets
│   └── .api_keys
├── scripts/           # Custom scripts (not yet populated)
│   └── bin/
├── shared/            # Shared configuration files
│   ├── .aliases       # Legacy monolithic aliases
│   └── .aliases.d/    # Modular aliases system
├── archive/           # Backup and legacy files
│   ├── backups/       # Backup files from migration
│   └── old/           # Legacy configuration files
├── bin/               # Repository management scripts
│   └── restow.sh      # Restow all packages
├── Makefile           # Automation for stow operations
└── docs/              # Documentation
    ├── TEST_REPORT.md
    ├── STOW_MIGRATION_MAPPING.md
    └── STOW_CLEANUP_NOTES.md
```

## 🚀 Quick Start

### Prerequisites

```bash
# Install GNU Stow
sudo pacman -S stow  # Arch Linux
# sudo apt install stow   # Ubuntu/Debian
# brew install stow       # macOS
```

### Installation

```bash
# Clone the repository
git clone <your-repo-url> ~/conf
cd ~/conf

# Stow core packages
make stow-core

# Or stow all available packages
make stow-all

# Or stow individual packages
make stow PACKAGE=nvim
```

## 🎯 Package Management

### Available Packages

| Package | Status | Description |
|---------|---------|-------------|
| `bash` | ✅ Active | Bash shell configuration with custom functions |
| `zsh` | ✅ Active | Zsh configuration with antigen plugin manager |
| `git` | ✅ Active | Git user configuration and aliases |
| `tmux` | ✅ Active | Tmux terminal multiplexer configuration |
| `nvim` | ✅ Active | Neovim configuration with LazyVim |
| `wget` | ✅ Active | Wget download utility configuration |
| `secrets` | ✅ Active | API keys and authentication tokens |
| `hyprland` | 📦 Ready | Hyprland window manager configuration |
| `waybar` | 📦 Ready | Waybar status bar configuration |
| `vscode` | 📦 Ready | VS Code settings and extensions |
| `scripts` | 📦 Ready | Custom utility scripts |
| `shared` | 📦 Ready | Shared aliases and common configuration |

### Stow Operations

```bash
# Check what would be stowed (dry run)
make check

# Stow specific package
make stow PACKAGE=bash

# Unstow specific package  
make unstow PACKAGE=bash

# Stow all packages
make stow-all

# Unstow all packages
make unstow-all

# Re-stow everything (useful after repo moves)
make restow-all

# Show current symlink status
make status

# Clean broken symlinks
make clean
```

### Direct Stow Commands

```bash
# From the repo directory
cd ~/conf

# Stow a package
stow -t $HOME bash

# Unstow a package
stow -t $HOME -D bash

# Dry run (simulation mode)
stow --no -t $HOME bash
```

## 🛠️ Adding New Packages

1. **Create package directory**:
   ```bash
   mkdir -p new-package/.config/new-app
   ```

2. **Move configuration files**:
   ```bash
   # Maintain the same directory structure as $HOME
   git mv ~/.config/new-app/* new-package/.config/new-app/
   ```

3. **Update Makefile**:
   ```makefile
   PACKAGES := bash zsh git tmux nvim new-package
   ```

4. **Test the package**:
   ```bash
   make check  # Verify no conflicts
   make stow PACKAGE=new-package
   ```

5. **Commit changes**:
   ```bash
   git add new-package/
   git commit -m "Add new-package Stow configuration"
   ```

## 🔧 Configuration Features

### Bash Configuration
- Custom aliases and functions
- Enhanced history management
- Oh My Posh theme integration
- Color testing utilities
- Git status checking on directory change

### Zsh Configuration  
- Clean, optimized configuration
- FZF integration with fd/ripgrep
- Extended globbing and completion
- Performance optimizations
- Modular alias system

### Git Configuration
- User identity and email
- Custom aliases for common operations
- Enhanced diff and merge tools

### Neovim Configuration
- LazyVim-based setup
- Modern Lua configuration
- Plugin management with lazy.nvim
- Custom keymaps and options

## 📋 Maintenance

### Backup Strategy
- Original files are backed up during installation
- Archive directory preserves historical configurations
- Git history tracks all changes
- Tagged releases for easy rollback

### Regular Maintenance
```bash
# Update repository
git pull origin main

# Re-stow after updates
./bin/restow.sh

# Validate everything still works
make check
```

### Rollback Process
```bash
# Unstow everything
make unstow-all

# Restore from backup
cp -r ~/dotfiles_pre_stow_backup_YYYYMMDD/* ~/

# Or checkout previous state
git checkout v-stow-migration
```

## 🧪 Test Results

Latest test results are available in [`TEST_REPORT.md`](TEST_REPORT.md).

**Status**: ✅ All core packages tested and functional  
**Last Updated**: 2025-09-26  
**Test Coverage**: Symlink validation, configuration loading, application compatibility

## 📖 Documentation

- [`STOW_MIGRATION_MAPPING.md`](STOW_MIGRATION_MAPPING.md) - Migration planning and package mapping
- [`STOW_CLEANUP_NOTES.md`](STOW_CLEANUP_NOTES.md) - Cleanup decisions and archived files
- [`TEST_REPORT.md`](TEST_REPORT.md) - Detailed validation test results

## 🤝 Contributing

This is a personal dotfiles repository, but feel free to:

1. **Fork** for your own use
2. **Suggest improvements** via issues
3. **Share configurations** that might be useful

### Development Workflow
```bash
# Make changes to package files
vim bash/.bashrc

# Test changes
make unstow PACKAGE=bash
make stow PACKAGE=bash

# Commit when satisfied
git add bash/
git commit -m "Update bash configuration"
```

## ⚡ Performance Notes

- Stow operations are lightweight (just symlinks)
- No performance impact on shell startup
- Configurations are optimized for speed
- Modular design allows selective loading

## 🔐 Security Considerations

- **Secrets package** contains sensitive API keys
- Repository should be private if it includes secrets
- Consider using environment variables for sensitive data
- `.gitignore` configured to exclude sensitive files

## 📄 License

This repository contains personal configuration files. Feel free to use any configurations that are helpful, but please customize them for your own needs.

---

**Repository**: Personal Dotfiles  
**Maintainer**: [Your Name]  
**Last Updated**: 2025-09-26  
**Stow Version**: GNU Stow (latest)