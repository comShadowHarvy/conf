# Centralized Backup System

## Overview

The backup system has been updated to support centralized backup storage. All backup components (Docker images, Flatpak apps, credentials, and Git repositories) now get stored in a single timestamped directory for easy restoration.

## New Directory Structure

**Before (Legacy):**
```
~/docker-backups/images/20250925-120000/
~/flatpak-backups/20250925-120000/
~/secure-backups/20250925-120000/
~/complete-backups/20250925-120000/
  ├── docker-images/20250925-120001/
  ├── flatpak-apps/20250925-120002/
  └── credentials/20250925-120003/
```

**After (Centralized):**
```
~/complete-backups/20250925-120000/
├── docker-images/
│   ├── images.digests.txt
│   ├── images.tags.txt
│   ├── images.json
│   └── README.txt
├── flatpak-apps/
│   ├── apps.tsv
│   ├── remotes.tsv
│   ├── apps.details.txt
│   └── README.txt
├── credentials/
│   ├── credentials.tar.gpg
│   ├── collected/
│   └── README.txt
├── git_repositories_backup.txt
└── BACKUP_SUMMARY.txt
```

## Usage

### Backup Everything (New Centralized Mode)
```bash
./backup_everything.sh
# Creates ~/complete-backups/YYYYmmdd-HHMMSS/ with all components
```

### Restore Everything
```bash
./restore_everything.sh
# Automatically uses ~/complete-backups/latest/

# Or specify a specific backup:
./restore_everything.sh ~/complete-backups/20250925-120000/
```

### Individual Component Backups (Still Supported)
```bash
# Standalone mode (legacy behavior)
./backup_docker_images.sh --dir ~/my-docker-backup
./backup_flatpak_apps.sh --dir ~/my-flatpak-backup
./backup_credentials.sh --outdir ~/my-creds-backup

# Centralized mode (new)
./backup_docker_images.sh --dest ~/my-centralized-backup
./backup_flatpak_apps.sh --dest ~/my-centralized-backup
./backup_credentials.sh --dest ~/my-centralized-backup
```

## Backward Compatibility

- All existing standalone scripts work exactly as before when used individually
- The restore script automatically detects both legacy and centralized directory structures
- Legacy backups can still be restored using the new restore script

## Benefits

1. **Single Location**: All backup files are in one directory
2. **Easy Restoration**: One command restores everything
3. **No Timestamp Conflicts**: Single timestamp for the entire backup
4. **Cleaner Organization**: Flat structure within each component directory
5. **Backward Compatible**: Existing backups and workflows continue to work

## Migration

No migration is required. The new system works alongside existing backups:

- New backups use the centralized structure
- Old backups continue to work with the restore scripts
- Individual scripts maintain their original behavior when used standalone