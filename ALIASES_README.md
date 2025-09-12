# Enhanced Shell Aliases & Functions

## Overview
This enhanced `.aliases` file provides a comprehensive collection of modern shell utilities, CachyOS-specific optimizations, and productivity enhancements. Compatible with both Bash and Zsh.

## 🆕 New Features Added

### CachyOS & Performance Optimizations
```bash
# CPU Performance Management
cpufreq           # Show current CPU frequency information
cpugov            # Show current CPU governor
cpuperf           # Set CPU to performance mode
cpusave           # Set CPU to power saving mode

# System Optimization
drop-caches       # Clear system memory caches
trim-ssd          # Trim all mounted SSDs
rebuild-initramfs # Rebuild initramfs for kernel changes

# CachyOS Specific (if running CachyOS)
kernel-list       # List available kernels
cachy-version     # Show CachyOS version
cachy-kernel      # Check if using CachyOS kernel
```

### Enhanced Package Management
```bash
# Unified AUR Management (paru/yay)
aurinstall <pkg>  # Install AUR package
aurupdate         # Update AUR packages only
aursync           # Full system update including AUR
aursearch <term>  # Search AUR packages
aurinfo <pkg>     # Show AUR package information
aurclean          # Clean AUR package cache

# Enhanced Pacman Shortcuts
paclog           # Watch pacman log in real-time
pacql <pkg>      # List files in package
pacqdt           # List orphaned packages
pacdeps <pkg>    # Show package dependency tree
pacfiles <file>  # Find which package provides file
```

### Modern Development Environment
```bash
# Project Management
projectinit <name> [template]  # Initialize new project (python/node/basic)
c                             # Open current directory in VS Code

# Enhanced Git Workflow
git-tree         # Beautiful git log tree view
git-files        # Show only changed file names
git-stats        # Show contributor statistics
git-today        # Show today's commits by you
git-week         # Show this week's commits

# Version Managers
node-version     # Show Node.js and npm versions
py-version       # Show Python and pip versions
venv-create      # Create and activate Python virtual environment
venv-activate    # Activate existing virtual environment
```

### System Monitoring & Maintenance
```bash
# Comprehensive System Update
full-update      # Complete system update with cleanup
                 # - Updates system packages (paru/pacman)
                 # - Updates Flatpak applications
                 # - Cleans package cache
                 # - Removes orphaned packages
                 # - Trims SSDs

# System Health Monitoring
syshealth        # Quick system health check
                 # - Disk usage
                 # - Memory usage
                 # - Load average
                 # - Failed services
                 # - Temperature readings
                 # - System status

watch-system [interval]  # Live system monitoring dashboard
```

### Advanced File Operations
```bash
# Enhanced File Analysis
fileinfo <file>  # Comprehensive file information
                 # - File type and size
                 # - Modification date
                 # - Permissions
                 # - Line/word/character count

# Smart Search
search <pattern> [path] [--type=ext]  # Intelligent content search
                                      # Uses ripgrep if available
                                      # Supports file type filtering
```

### Productivity Enhancements
```bash
# Session Management
save-session [name]    # Save current directory and history
load-session [name]    # Restore saved session
list-sessions          # List all saved sessions

# Quick Utilities
serve-here [port]      # Serve current directory via HTTP
open-url <url>         # Open URL in default browser
clip                   # Copy stdin to clipboard (cross-platform)
alias-suggest          # Show most used commands for aliasing
```

### Modern Tool Integration
```bash
# Modern Alternatives (if installed)
diff → delta          # Better diff with syntax highlighting
help → tldr           # Simplified man pages
benchmark → hyperfine # Command benchmarking

# Enhanced Docker Management
docker-clean          # Complete Docker cleanup
docker-stats          # Non-streaming container stats
docker-top           # Clean container status table
```

## 🔧 Enhanced Existing Features

### Package Management
- **Smarter AUR handling**: Unified commands work with both paru and yay
- **Better package maintenance**: Enhanced orphan removal and cache cleaning
- **Real-time monitoring**: Live pacman log viewing

### File Management
- **Modern tool detection**: Automatically uses eza/lsd over ls when available
- **Better fallbacks**: Graceful degradation when modern tools aren't installed
- **Progress indicators**: rsync-based copying with progress bars

### Network Operations
- **Enhanced sharing**: Better HTTP server with IP address display
- **Improved testing**: More comprehensive connectivity tests
- **Modern tools**: Support for dog (DNS), gping (ping), httpie (HTTP client)

### Git Workflow
- **Visual improvements**: Better log formatting and tree views
- **Statistics**: Contributor analysis and commit tracking
- **Smart operations**: Robust pull with stashing and rebasing

## 📚 Function Categories

### Navigation & File Management
- `mkcd`, `up`, `cdf` - Enhanced directory navigation
- `extract`, `extract-all` - Universal archive extraction
- `backup`, `archive` - File backup and archival
- `biggest`, `dirsummary` - Disk usage analysis

### Development Tools
- `gcc` (git clone + cd), `quickgit`, `gitupdate` - Git workflow
- `projectinit` - Project scaffolding with templates
- Language-specific helpers for Python, Node.js, Docker

### System Administration
- `sysinfo`, `sys-full`, `syshealth` - System information
- `orphan`, `full-update` - Package maintenance
- `killport`, `killname` - Process management
- `watchdir`, `watch-system` - Monitoring

### Productivity Utilities
- `note`, `todo`, `todo-done` - Quick note-taking
- `genpass`, `randstr` - Password/string generation
- `qr` - QR code generation
- `save-session`, `load-session` - Session management

## 🎨 Modern Enhancements

### Performance Optimizations
- Lazy loading of commands and aliases
- Intelligent fallbacks for missing tools
- Cached package manager detection
- Minimal overhead for unused features

### User Experience
- Unicode icons and emojis for better readability
- Color-coded output where appropriate
- Progress indicators for long-running operations
- Consistent error handling and user feedback

### Cross-Platform Compatibility
- Wayland and X11 clipboard support
- macOS and Linux compatibility where possible
- Graceful handling of missing dependencies

## 🚀 Usage Examples

```bash
# Set up a new Python project
projectinit my-app python

# Comprehensive system maintenance
full-update

# Quick system health check
syshealth

# Smart file search
search "function" . --type=py

# Save current work session
save-session work-project

# Serve current directory for file sharing
serve-here 8080

# Get detailed file information
fileinfo important-document.pdf

# Monitor system in real-time
watch-system 1
```

## 🔄 Compatibility

### Shell Compatibility
- ✅ Bash 4.0+
- ✅ Zsh 5.0+
- ✅ POSIX-compliant functions

### OS Compatibility
- ✅ CachyOS Linux (optimized)
- ✅ Arch Linux
- ✅ Other Linux distributions
- ⚠️  macOS (limited package management features)

### Dependencies
Most functions work with standard tools, with enhanced features when modern alternatives are available:
- **Required**: bash/zsh, coreutils, git
- **Enhanced with**: eza/lsd, bat, ripgrep, fd, fzf, zoxide
- **Optional**: docker, nodejs, python3, sensors, flatpak

---

**Total Functions**: 50+ utility functions  
**Total Aliases**: 100+ shortcuts  
**Performance**: Optimized for fast startup and minimal overhead  
**Maintenance**: Auto-updating package management with cleanup