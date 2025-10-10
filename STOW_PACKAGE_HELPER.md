# Stow Package Configuration Helper

Easy tool to add new packages to your stow configuration without manually editing YAML files.

## 🚀 Quick Start

```bash
# List all packages and their configuration status
./stow-add-package.sh list

# Scan for unconfigured packages
./stow-add-package.sh scan

# Quick add a package with defaults
./stow-add-package.sh quick my-package

# Interactive configuration (recommended for important packages)
./stow-add-package.sh add my-package

# Configure all unconfigured packages at once
./stow-add-package.sh bulk
```

## 📋 Commands

### `list` - Show Package Status
Lists all existing package directories and shows which ones are configured vs unconfigured.

**Example:**
```bash
./stow-add-package.sh list
```

### `scan` - Find Unconfigured Packages  
Quickly identify package directories that exist but aren't in your stow configuration.

**Example:**
```bash
./stow-add-package.sh scan
```

### `quick <package> [category] [priority]` - Quick Add
Adds a package with sensible defaults. Perfect for simple packages that don't need special configuration.

**Parameters:**
- `package` - Package name (must exist as directory)
- `category` - optional, defaults to "optional" (core|development|desktop|optional) 
- `priority` - optional, defaults to 5 (1-10, 1=highest)

**Examples:**
```bash
# Quick add with all defaults
./stow-add-package.sh quick my-package

# Quick add as development package with priority 3
./stow-add-package.sh quick my-dev-tools development 3
```

### `add <package>` - Interactive Configuration
Full interactive configuration with prompts for all options. Best for important packages that need specific settings.

**What it configures:**
- Priority (1-10, where 1 = highest priority)
- Category (core/development/desktop/optional)
- Description
- Dependencies (other packages required)
- Conflicting files
- Backup policy (ask/skip/backup/force)
- Enabled status
- Pre/post stow hooks

**Example:**
```bash
./stow-add-package.sh add my-important-package
```

### `bulk` - Configure All Unconfigured
Handles all unconfigured packages at once with your choice of:
- **Interactive** - Full configuration for each package
- **Quick** - Apply same defaults to all packages
- **Skip** - Do nothing

**Example:**
```bash
./stow-add-package.sh bulk
```

## ⚡ Convenience Script

Use the shorter `stow-pkg` command (located in `bin/stow-pkg`):

```bash
# These are equivalent:
./stow-add-package.sh list
bin/stow-pkg list

# If bin/ is in your PATH:
stow-pkg quick my-package
```

## 🛠️ Features

- **Interactive Prompts** - User-friendly prompts with defaults and validation
- **Smart YAML Insertion** - Maintains priority order and proper formatting  
- **Automatic Backups** - Creates timestamped backups before modifying config
- **Comprehensive Options** - Supports all stow-config.yaml features
- **Error Handling** - Validates package directories exist and aren't duplicated
- **Colorful Output** - Clear visual feedback with colors and symbols

## 📁 Package Categories

- **core** - Essential system configuration (bash, zsh, git)
- **development** - Development tools (nvim, tmux, vscode)  
- **desktop** - GUI/Desktop environment (hyprland, waybar)
- **optional** - Additional utilities and personal configs

## 🎯 Priority Levels

- **1-2** - Critical system packages (shells, git)
- **3-4** - Important utilities (scripts, shared configs)
- **5-6** - Development tools (editors, multiplexers)
- **7-8** - Desktop packages (window managers, bars)
- **9-10** - Optional/personal packages

## 🔧 Configuration Options

### Dependencies
List other packages this one requires:
```
Dependencies:
• shared
• git
```

### Conflicts  
Files that might conflict during stowing:
```
Conflicts:
• .bashrc
• .config/nvim
```

### Backup Policies
- **ask** - Prompt before overwriting (default)
- **skip** - Don't overwrite existing files
- **backup** - Backup existing files before overwriting
- **force** - Overwrite without prompting

### Hooks
Commands to run before/after stowing:
- **pre_stow** - Run before stowing (e.g., backup configs)
- **post_stow** - Run after stowing (e.g., reload configs, set permissions)

## 📝 Example Interactive Session

```
━━━ Configuring Package: my-nvim ━━━

Priority (1=highest, 10=lowest) (1-10) [5]: 3
Category
  1) core
  2) development (default)
  3) desktop  
  4) optional
Choice [development]: 2

Description [Custom configuration package]: My Neovim configuration with plugins

Enabled by default [Y/n]: y

Backup policy
  1) ask (default)
  2) skip
  3) backup
  4) force
Choice [ask]: 3

[INFO] Dependencies (other packages this one requires):
Dependencies
Enter items one per line. Press Enter on empty line to finish.
  • shared
  • 

[INFO] Conflicting files (files that might conflict during stowing):
Example: .bashrc, .config/nvim, etc.
Conflicts  
Enter items one per line. Press Enter on empty line to finish.
  • .config/nvim
  • 

Pre-stow hook command (optional): 
Post-stow hook command (optional): echo 'Neovim config updated!'

━━━ Configuration Summary ━━━
Package:      my-nvim
Priority:     3
Category:     development  
Description:  My Neovim configuration with plugins
Enabled:      true
Backup Policy: backup
Dependencies: ["shared"]
Conflicts:    [".config/nvim"]
Post-stow:    echo 'Neovim config updated!'

Add this package to configuration [Y/n]: y
[SUCCESS] Package 'my-nvim' added to configuration
```

## 🗃️ File Structure

```
conf/
├── stow-add-package.sh    # Main script
├── bin/stow-pkg          # Convenience wrapper  
├── stow-config.yaml      # Your stow configuration
└── stow-config.yaml.backup.* # Automatic backups
```

## 💡 Tips

1. **Use `scan` first** to see what needs configuring
2. **Use `quick` for simple packages** to save time
3. **Use `add` for important packages** that need specific settings  
4. **Use `bulk` with quick mode** to configure many packages at once
5. **Check `list` after changes** to verify everything is configured
6. **Backups are created automatically** - you can always restore if needed

## 🔍 Troubleshooting

**Package directory doesn't exist:**
```
[ERROR] Package directory doesn't exist: /path/to/package  
[INFO] Create the directory first, then add configuration
```
→ Create the package directory first with `mkdir package-name`

**Package already configured:**
```
[WARNING] Package 'my-package' is already configured
```
→ Use your existing stow-manager.sh to modify existing packages

**YAML syntax errors:**
The script automatically validates YAML and creates backups, so you can always restore the previous working configuration if something goes wrong.