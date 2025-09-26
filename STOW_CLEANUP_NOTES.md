# Stow Migration Cleanup Notes

## Backup Files Archived

The following backup and duplicate files were moved to `archive/backups/` during the Stow migration:

### Alias Files
- `.aliases.20250915_124902.bak` (2208 lines) - Backup from Sept 15
- `.aliases.bak-2025-09-15` (1689 lines) - Different backup from same day  
- `.aliases.orig` (948 lines) - Original smaller version
- `.aliases.orig-20250912` (863 lines) - Original from Sept 12

### Zsh Configuration Files
- `.zshrc.20250915_124902.bak` - Backup from Sept 15
- `.zshrc.bakk` - Manual backup
- `.zshrc.clean` - Clean version attempt  
- `.zshrc.orig` - Original version
- `.zshrc.orig-20250912` - Original from Sept 12

## Files Moved to archive/old/

Legacy configuration files moved from `old/` directory:
- `.wget-hsts` - wget history
- `.Xclients` - X11 client configuration
- `.xinitrc` - X11 initialization
- `.zcompdump` - Zsh completion dump
- `.zdata` - Zsh data
- `.zsh1` - Old zsh config
- `.zshrc.bac` - Another zsh backup
- `.zshrc.bac1` - Yet another zsh backup

## Rationale

1. **Preserved History**: All backup files were preserved in the archive rather than deleted to maintain configuration history.

2. **Size Differences**: The different file sizes indicate meaningful evolution of configurations over time.

3. **Git History**: The original file movements are preserved in git history, so the archive serves as an additional safety net.

4. **Easy Recovery**: If any current configuration causes issues, archived versions can be easily restored.

## Current Active Files

After cleanup, the main configuration files are organized in Stow packages:
- `bash/.bashrc` - Current bash configuration
- `zsh/.zshrc` - Current zsh configuration  
- `shared/.aliases.d/` - Modular aliases shared between shells
- `.aliases` - Legacy monolithic aliases (still in repo root, may need to integrate with shared system)

## Future Cleanup Recommendations

1. **Integrate .aliases**: Consider migrating the remaining `.aliases` file content into the modular `shared/.aliases.d/` system.

2. **Periodic Archive Cleanup**: Review archived files after 6 months of successful Stow operation.

3. **Documentation**: Keep this file updated as more cleanup decisions are made.