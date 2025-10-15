# Steam Artwork Sync

A comprehensive script to backup and restore Steam custom artwork between Steam Deck and Desktop installations.

## Overview

Steam doesn't sync custom artwork between devices, which means beautiful game artwork you've set up on your Steam Deck won't appear on your desktop Steam installation. This script solves that problem by allowing you to backup artwork from one Steam installation and restore it to another.

## Features

- ✅ **Full artwork backup/restore** - Handles all Steam artwork types (capsules, heroes, logos, icons)
- ✅ **Auto-detection** - Automatically finds Steam installations on common paths
- ✅ **Safe operations** - Dry-run mode, Steam process detection, permission fixing
- ✅ **Cross-platform** - Works between Steam Deck (SteamOS) and Linux desktop
- ✅ **Comprehensive logging** - Colored output with progress indicators
- ✅ **Manifest tracking** - JSON manifest for backup verification
- ✅ **Flexible paths** - Support for custom Steam installation paths

## Steam Artwork Types Supported

| Type | Description | Files |
|------|-------------|--------|
| **Capsule** | Vertical poster art (600x900) | `library_600x900.jpg` |
| **Wide Capsule** | Horizontal banner (460x215) | `header.jpg` |  
| **Hero** | Large background image (1920x620) | `library_hero.jpg` |
| **Logo** | Game logo overlay | `logo.png` |
| **Icon** | Small icon for UI elements | Various hash names |

## Custom vs Default Artwork

**Default/Downloaded Artwork** (`appcache/librarycache/`):
- Artwork downloaded by Steam from official sources
- Game store images, community-uploaded images
- Automatically cached when you browse the Steam store
- Usually takes up several GB of space

**Custom User-Uploaded Artwork** (`userdata/*/config/grid/`):
- Artwork you manually uploaded via Steam's "Set Custom Artwork" feature
- Your personal artwork selections that override defaults
- Only exists if you've manually customized game artwork
- Usually much smaller in size

**Use `--custom-only` when you want to:**
- Transfer only your personal artwork choices
- Keep backups small and focused
- Avoid transferring Steam's large artwork cache
- Sync only artwork you've personally selected

## Installation

1. Download the script:
```bash
wget -O steam-artwork-sync.sh [script-url]
# OR copy the script to your desired location
```

2. Make it executable:
```bash
chmod +x steam-artwork-sync.sh
```

3. Optionally, move to a system path:
```bash
sudo mv steam-artwork-sync.sh /usr/local/bin/
```

## Dependencies

- `bash` (version 4.0+)
- `rsync` - For efficient file synchronization
- `find` - For file discovery (standard on all Linux)
- `du` - For size calculations (standard on all Linux)

## Usage

### Basic Commands

```bash
# Show artwork information for current Steam installation
./steam-artwork-sync.sh info

# Create backup with auto-detected paths
./steam-artwork-sync.sh backup

# Restore from backup with auto-detected destination
./steam-artwork-sync.sh restore -i ~/deck-artwork-backup-20241015-120000
```

### Advanced Usage

```bash
# Backup from specific Steam Deck path
./steam-artwork-sync.sh backup -s /mnt/steamdeck/.steam/root -o ~/my-deck-backup

# Restore to specific desktop Steam path  
./steam-artwork-sync.sh restore -i ~/my-deck-backup -d ~/.local/share/Steam

# Backup only custom user-uploaded artwork (not Steam's downloaded artwork)
./steam-artwork-sync.sh backup --custom-only -o ~/custom-artwork-only

# Dry run to see what would happen
./steam-artwork-sync.sh backup --dry-run -v

# Force operation without prompts
./steam-artwork-sync.sh restore -i ~/backup -f
```

## Common Scenarios

### Steam Deck → Desktop Linux

1. **On Steam Deck**: Access desktop mode or use SSH
```bash
# Create backup on Steam Deck
./steam-artwork-sync.sh backup -o ~/deck-artwork-backup
```

2. **Transfer backup**: Copy to your desktop via USB, SSH, cloud storage, etc.

3. **On Desktop**: Restore the artwork  
```bash
# Restore to desktop Steam
./steam-artwork-sync.sh restore -i ~/deck-artwork-backup
```

### Via SSH/Network

```bash
# Backup directly over SSH (from desktop)
./steam-artwork-sync.sh backup -s deck@steamdeck:~/.steam/root -o ~/deck-backup

# Or mount Steam Deck filesystem and backup
sshfs deck@steamdeck:/ /mnt/steamdeck
./steam-artwork-sync.sh backup -s /mnt/steamdeck/home/deck/.steam/root
```

### Multiple Backups

```bash
# Timestamped backups
./steam-artwork-sync.sh backup -o ~/backups/deck-$(date +%Y%m%d)

# Keep multiple device backups
./steam-artwork-sync.sh backup -s /path/to/steam1 -o ~/backups/gaming-pc
./steam-artwork-sync.sh backup -s /path/to/steam2 -o ~/backups/steam-deck
```

## Directory Structure

### Steam Installation Paths
- **Steam Deck**: `~/.steam/root/`
- **Desktop Linux**: `~/.local/share/Steam/`
- **Flatpak Steam**: `~/.var/app/com.valvesoftware.Steam/home/.local/share/Steam/`

### Artwork Storage Locations
```
Steam/
├── appcache/librarycache/          # Downloaded artwork cache
│   ├── [APPID]/
│   │   ├── library_600x900.jpg    # Capsule art
│   │   ├── header.jpg              # Wide capsule
│   │   ├── library_hero.jpg        # Hero image
│   │   ├── logo.png                # Logo
│   │   └── [hash].jpg              # Icon variants
└── userdata/[USERID]/config/grid/  # Custom uploaded artwork
    ├── [APPID]_hero.jpg
    ├── [APPID]_logo.png
    └── [APPID].jpg
```

### Backup Structure
```
backup-directory/
├── manifest.json              # Backup metadata
├── librarycache/              # Cached artwork files
│   └── [APPID]/...
└── grid/                      # Custom artwork files  
    └── [custom files]...
```

## Command Reference

### Commands
| Command | Description |
|---------|-------------|
| `backup` | Create backup of Steam artwork |
| `restore` | Restore Steam artwork from backup |
| `info` | Show Steam paths and artwork statistics |

### Options
| Option | Description |
|--------|-------------|
| `-s, --source PATH` | Source Steam installation path |
| `-d, --dest PATH` | Destination Steam installation path |
| `-o, --output DIR` | Backup directory (for backup) |
| `-i, --input DIR` | Backup directory (for restore) |
| `-n, --dry-run` | Preview operations without executing |
| `-c, --custom-only` | Backup/restore only user-uploaded custom artwork |
| `-v, --verbose` | Enable verbose output |
| `-f, --force` | Skip confirmation prompts |
| `-h, --help` | Show help message |

## Safety Features

- **Steam Process Detection**: Warns if Steam is running during restore
- **Dry Run Mode**: Preview operations with `--dry-run`
- **Backup Validation**: Checks for valid manifest and directories
- **Permission Fixing**: Ensures correct file permissions after restore  
- **Path Validation**: Verifies source/destination paths exist
- **User Confirmation**: Prompts before potentially destructive operations

## Troubleshooting

### Common Issues

**"No Steam user ID found"**
- Steam userdata directory is missing or empty
- Run Steam at least once to create user profile
- Check Steam installation path is correct

**"No artwork files found"**  
- Source Steam installation has no custom artwork
- Verify correct Steam path with `-s` option
- Check if artwork exists with `info` command

**"Permission denied"**
- Ensure script is executable: `chmod +x steam-artwork-sync.sh`
- Check read/write permissions on Steam directories
- May need to run with sudo for system Steam installations

**"Steam is running" warning**
- Close Steam before running restore operations
- Use `--force` to bypass warning (not recommended)
- Use `pkill steam` to force close Steam

### Debugging

```bash
# Enable verbose output
./steam-artwork-sync.sh backup -v

# Use dry run to debug issues
./steam-artwork-sync.sh restore -i ~/backup --dry-run -v

# Check Steam paths manually  
./steam-artwork-sync.sh info
```

## Best Practices

1. **Always backup first** - Create backups before making changes
2. **Use dry-run** - Test operations with `--dry-run` before executing
3. **Close Steam** - Always close Steam before restoring artwork
4. **Verify backups** - Check backup directories contain expected files
5. **Keep multiple backups** - Don't overwrite previous backups
6. **Test restore** - Verify artwork appears correctly in Steam after restore

## License

This script is released under the MIT License. Feel free to modify and distribute.

## Contributing

Issues and improvements welcome! This script handles the most common Steam artwork scenarios, but Steam's artwork system has many edge cases.

## Version History

- **v1.0.0** - Initial release with backup, restore, and info commands