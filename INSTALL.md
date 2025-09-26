# 🚀 Fresh OS Installation Guide

This guide shows you how to set up your Stow-managed dotfiles on a brand new system.

## 🎯 Quick Install (Recommended)

**1. One-liner install:**
```bash
# Replace with your actual repository URL!
bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/dotfiles/main/setup-dotfiles.sh)
```

**2. Alternative - clone and run:**
```bash
git clone https://github.com/yourusername/dotfiles.git ~/conf
cd ~/conf
./setup-dotfiles.sh
```

## 📋 What The Script Does

1. **🔍 Detects your system** (Arch, Ubuntu, Fedora, macOS, etc.)
2. **📦 Installs dependencies** (`git`, `stow`, `make`)
3. **💾 Backs up existing dotfiles** (to `~/dotfiles_backup_YYYYMMDD_HHMMSS/`)
4. **📥 Clones your repository** (to `~/conf/`)
5. **🔗 Creates symlinks** using Stow
6. **✅ Verifies installation**
7. **🎉 Shows next steps**

## 🛠️ Installation Options

### Core Only (Essential packages)
```bash
./setup-dotfiles.sh --core-only
```
Installs: `bash`, `zsh`, `git`, `scripts`, `shared` (aliases)

### Full Installation  
```bash
./setup-dotfiles.sh
```
Installs all available packages including GUI configs

### Custom Repository
```bash
./setup-dotfiles.sh --url git@github.com:yourusername/dotfiles.git --ssh
```

### Force Overwrite
```bash
./setup-dotfiles.sh --force
```

### Dry Run (Preview)
```bash
./setup-dotfiles.sh --dry-run
```

## 🔧 Manual Installation Steps

If you prefer to install manually:

### 1. Install Dependencies

**Arch Linux:**
```bash
sudo pacman -Sy git stow make
```

**Ubuntu/Debian:**
```bash
sudo apt update && sudo apt install git stow make
```

**Fedora:**
```bash
sudo dnf install git stow make
```

**macOS:**
```bash
brew install git stow make
```

### 2. Clone Repository
```bash
git clone https://github.com/yourusername/dotfiles.git ~/conf
cd ~/conf
```

### 3. Backup Existing Files
```bash
mkdir -p ~/dotfiles_backup_$(date +%Y%m%d)
mv ~/.bashrc ~/.zshrc ~/.gitconfig ~/dotfiles_backup_$(date +%Y%m%d)/ 2>/dev/null || true
```

### 4. Install Packages
```bash
# Core packages
make stow-core

# Or all packages  
make stow-all

# Or individual packages
make stow PACKAGE=nvim
```

### 5. Verify
```bash
make status
```

## 🎯 First-Time Setup Checklist

After installation, do these steps:

- [ ] **Restart your shell** or run `source ~/.bashrc` / `source ~/.zshrc`
- [ ] **Test core functionality**: `updateall`, `mkscript`, git commands
- [ ] **Check aliases work**: `alias | head -10`
- [ ] **Verify scripts**: `which updateall` should show `~/bin/updateall`
- [ ] **Configure Git** if needed:
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "you@example.com"  
  ```
- [ ] **Set up SSH keys** for GitHub/GitLab if using SSH
- [ ] **Install additional tools** your configs reference

## 📁 Repository Structure

Your dotfiles will be organized like this:
```
~/conf/
├── bash/           # Bash configuration
├── zsh/            # Zsh configuration  
├── git/            # Git configuration
├── scripts/        # Custom utility scripts → ~/bin/
├── shared/         # Shared aliases → ~/.aliases, ~/.aliases.d/
├── nvim/           # Neovim config → ~/.config/nvim/
├── tmux/           # Tmux config → ~/.config/tmux/
├── hyprland/       # Window manager
├── waybar/         # Status bar
├── secrets/        # API keys → ~/.api_keys
└── archive/        # Backup files
```

## 🔄 Managing Your Setup

**View Status:**
```bash
cd ~/conf && make status
```

**Add New Package:**
```bash
make stow PACKAGE=packagename
```

**Remove Package:**
```bash
make unstow PACKAGE=packagename
```

**Update Repository:**
```bash
cd ~/conf
git pull
make restow-all  # Re-apply all packages
```

## 🆘 Troubleshooting

### "Stow conflicts" Error
```bash
# Remove conflicting files first
rm ~/.bashrc ~/.zshrc ~/.gitconfig
cd ~/conf && make stow-core
```

### "Package not found" Error
Check available packages:
```bash
cd ~/conf && ls -d */ | tr -d '/'
```

### Scripts Not in PATH
```bash
# Check if ~/bin exists and is linked
ls -la ~/bin
# Restart shell or source config
source ~/.bashrc  # or ~/.zshrc
```

### Permission Issues
```bash
# Make scripts executable
chmod +x ~/conf/scripts/bin/*
# Or use the Makefile
cd ~/conf && make restow-all
```

## 🎉 You're All Set!

Your dotfiles are now:
- ✅ **Organized** with Stow packages
- ✅ **Version controlled** with Git
- ✅ **Portable** across systems
- ✅ **Easy to manage** with Make commands

**Welcome to your reproducible development environment!** 🏠✨

## 📚 Learn More

- [GNU Stow Documentation](https://www.gnu.org/software/stow/)
- [Repository README](./README.md) - Detailed usage guide
- [Makefile Commands](./Makefile) - All available operations

---
**Pro Tip**: Bookmark this guide for future installations! 📖