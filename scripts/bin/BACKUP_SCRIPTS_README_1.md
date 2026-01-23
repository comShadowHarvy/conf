# 🛡️ Backup & Restore Scripts

A comprehensive suite of backup and restore scripts for Linux systems, featuring automated backups of Docker images, Flatpak applications, credentials, and Git repositories.

## 📁 Script Overview

### Backup Scripts
- **`backup_everything.sh`** - Master backup orchestrator with theatrical personalities
- **`backup_docker_images.sh`** - Docker container image backup
- **`backup_flatpak_apps.sh`** - Flatpak applications and remotes backup
- **`backup_credentials.sh`** - SSH keys, GPG keys, Git credentials, and GitHub CLI tokens
- **`app/gitback`** - Git repositories synchronization and backup

### Restore Scripts
- **`restore_everything.sh`** - Master restore orchestrator
- **`restore_docker_images.sh`** - Docker image restoration
- **`restore_flatpak_apps.sh`** - Flatpak applications restoration
- **`restore_credentials.sh`** - Credentials restoration

## 🚀 Quick Start

### Full System Backup
```bash
# Complete backup with personality (default behavior)
./backup_everything.sh

# Quick backup without animations
./backup_everything.sh --no-theatrics

# Flat file structure (all files in one directory)
./backup_everything.sh --flat

# Dry run to see what would be backed up
./backup_everything.sh --dry-run
```

### Individual Component Backups
```bash
# Backup only specific components
./backup_everything.sh --docker --flatpak
./backup_everything.sh --credentials --git-repos
./backup_everything.sh --docker --no-theatrics
```

## 🎭 Backup Personalities

The main backup script features fun personalities that add character to your backups:

- **`wise_old`** - Ancient wisdom and mystical vibes
- **`dm`** - Dungeon Master RPG style
- **`glados`** - Portal's GLaDOS sarcastic AI
- **`flirty`** - Charming and playful (PG-rated)
- **`linuxdev`** - Professional developer style
- **`sassy`** - Attitude with a side of snark
- **`sarcastic`** - Dry humor and wit

```bash
# Choose a specific personality
./backup_everything.sh -p glados
./backup_everything.sh --persona dm

# Skip the theatrics for automation
./backup_everything.sh --no-theatrics
```

## 📋 Detailed Usage

### Master Backup Script (`backup_everything.sh`)

```bash
Usage: ./backup_everything.sh [options]

Component Options:
  --docker              Include Docker images backup
  --flatpak             Include Flatpak apps backup  
  --credentials         Include credentials backup (SSH, GPG, GitHub CLI, Git)
  --git-repos           Include Git repositories backup/sync
  --vscode              Include VS Code settings (with credentials)
  --all                 Backup everything (default behavior)

Security Options:
  --encrypt-symmetric   Encrypt credential archives with passphrase (default)
  --encrypt-recipient   Encrypt credential archives to GPG recipient
  --no-encrypt-creds    Don't encrypt credentials (NOT recommended)

Output Options:
  --outdir <path>       Custom output directory (default: ~/complete-backups)
  --flat                Put all backup files directly in main folder
  --dry-run             Show what would be backed up without doing it

Interface Options:
  -p, --persona <name>  Choose personality (see list above)
  --no-theatrics        Skip loading animation and fancy text
  -h, --help            Show help message
```

### Output Structure

#### Default Structure (Organized)
```
complete-backups/20250910-185921/
├── BACKUP_SUMMARY.txt                     # Backup report and restore instructions
├── docker-images/20250910-185921/         # Docker backup files
│   ├── images.digests.txt                 # Preferred for exact restoration
│   ├── images.tags.txt                    # Fallback restoration method
│   ├── images.json                        # Raw Docker metadata
│   └── README.txt                         # Docker restore instructions
├── flatpak-apps/20250910-185921/          # Flatpak backup files
│   ├── apps.tsv                          # Installed applications list
│   ├── remotes.tsv                       # Configured remotes
│   ├── apps.details.txt                  # Human-readable details
│   └── README.txt                        # Flatpak restore instructions
├── credentials/20250910-185921/           # Encrypted credentials
│   ├── credentials.tar.gpg               # Encrypted credential archive
│   └── MANIFEST.txt                      # Contents manifest
└── git_repositories_backup.txt           # Git repositories list
```

#### Flat Structure (--flat option)
```
complete-backups/20250910-185921/
├── BACKUP_SUMMARY.txt                     # Backup report
├── docker_images.digests.txt              # Docker images (by digest)
├── docker_images.tags.txt                 # Docker images (by tag)
├── docker_images.json                     # Docker raw metadata
├── flatpak_apps.tsv                       # Flatpak applications
├── flatpak_remotes.tsv                    # Flatpak remotes
├── flatpak_apps.details.txt               # Flatpak details
├── credentials.tar.gpg                    # Encrypted credentials
├── credentials_MANIFEST.txt               # Credential contents list
├── git_repositories_backup.txt            # Git repositories
├── docker-images_README.txt               # Docker restore guide
└── flatpak-apps_README.txt                # Flatpak restore guide
```

## 🔄 Restoration

### Full System Restore
```bash
# Restore everything from latest backup (SSH keys auto-activated)
./restore_everything.sh

# Restore from specific backup
./restore_everything.sh --backup-dir /path/to/backup/20250910-185921

# Restore without automatically adding SSH keys to agent
./restore_everything.sh --no-ssh-agent

# Dry run restoration
./restore_everything.sh --dry-run
```

### Individual Component Restoration
```bash
# Restore Docker images
./restore_docker_images.sh -f /path/to/images.digests.txt

# Restore Flatpak apps
./restore_flatpak_apps.sh -f /path/to/apps.tsv -r /path/to/remotes.tsv

# Restore credentials (SSH keys automatically activated)
./restore_credentials.sh -f /path/to/credentials.tar.gpg

# Restore credentials without SSH activation
./restore_credentials.sh -f /path/to/credentials.tar.gpg --no-ssh-agent

# Restore from flat structure
./restore_docker_images.sh -f docker_images.digests.txt
./restore_flatpak_apps.sh -f flatpak_apps.tsv -r flatpak_remotes.tsv
```

## 🔧 Individual Script Usage

### Docker Images (`backup_docker_images.sh`)
```bash
# Default backup location
./backup_docker_images.sh

# Custom backup directory
./backup_docker_images.sh --dir /path/to/backup/location

# Output files:
# - images.tags.txt     (repository:tag format)
# - images.digests.txt  (repository@sha256:digest format - preferred)
# - images.json         (raw metadata)
# - README.txt          (restore instructions)
```

### Flatpak Applications (`backup_flatpak_apps.sh`)
```bash
# Default backup location
./backup_flatpak_apps.sh

# Custom backup directory
./backup_flatpak_apps.sh --dir /path/to/backup/location

# Output files:
# - remotes.tsv         (configured Flatpak remotes)
# - apps.tsv            (installed applications list)
# - apps.details.txt    (human-readable application details)
# - README.txt          (restore instructions)
```

### Credentials (`backup_credentials.sh`)
```bash
# Encrypted with symmetric passphrase (recommended)
./backup_credentials.sh --encrypt-symmetric

# Encrypted to specific GPG recipient
./backup_credentials.sh --encrypt-recipient user@example.com

# Unencrypted (NOT recommended - use only for testing)
./backup_credentials.sh --no-encrypt

# Include VS Code settings
./backup_credentials.sh --include-vscode

# Custom output directory
./backup_credentials.sh --outdir /path/to/backup/location

# Backed up credentials include:
# - SSH keys (~/.ssh)
# - GPG keys (public/private + ownertrust)
# - Git configuration (~/.gitconfig, ~/.git-credentials)
# - GitHub CLI tokens (~/.config/gh/hosts.yml)
# - VS Code settings (optional)
```

## 🔐 Security Features

### Credential Encryption
- **Default**: Symmetric GPG encryption with passphrase
- **Advanced**: Encrypt to specific GPG recipient
- **Testing only**: Unencrypted option (not recommended for production)

### What Gets Backed Up
- **SSH Keys**: Private/public keys, known_hosts, authorized_keys
- **GPG Keys**: Public/private keyring + ownertrust database
- **Git Credentials**: Global config and stored credentials
- **GitHub CLI**: Authentication tokens and configuration
- **VS Code**: Settings and extensions (optional)

### SSH Key Auto-Activation
- **Default**: SSH keys are automatically added to the SSH agent after restore
- **Manual control**: Use `--no-ssh-agent` to skip automatic activation
- **Smart detection**: Starts SSH agent if not running, handles passphrases gracefully
- **Verification**: Shows which keys were successfully added to the agent

## 🕐 Automation

### Cron Job Examples
```bash
# Daily backup at 2 AM (quiet, flat structure)
0 2 * * * /home/me/backup_everything.sh --no-theatrics --flat >/dev/null 2>&1

# Weekly full backup with logs
0 3 * * 0 /home/me/backup_everything.sh --no-theatrics > /var/log/backup.log 2>&1

# Hourly git sync only
0 * * * * /home/me/app/gitback >/dev/null 2>&1
```

### Systemd Timer (Alternative to Cron)
```bash
# Create systemd service and timer files for automated backups
# See systemd documentation for detailed setup
```

## 🛠️ Dependencies

### Required
- **bash** (4.0+)
- **coreutils** (basic Unix tools)
- **findutils** (find command)

### Optional (for respective components)
- **docker** - For Docker image backups
- **flatpak** - For Flatpak application backups
- **gpg** - For credential encryption
- **git** - For Git repository management
- **bc** - For progress bar calculations (fallback available)

### Installation Check
```bash
# Check if all tools are available
command -v docker && echo "✓ Docker available"
command -v flatpak && echo "✓ Flatpak available"
command -v gpg && echo "✓ GPG available"
command -v git && echo "✓ Git available"
```

## 📊 Backup Reports

Each backup creates a `BACKUP_SUMMARY.txt` file containing:

```
COMPLETE SYSTEM BACKUP - 20250910-185921
Host: your-hostname
User: username
Timestamp: Wed Sep 10 18:59:21 EDT 2025

COMPONENTS INCLUDED:
✓ Docker images
✓ Flatpak applications
✓ Credentials (SSH, GPG, GitHub CLI, Git)
✓ Git repositories backup/sync

BACKUP LOCATION: /home/me/complete-backups/20250910-185921

BACKUP RESULTS:
✅ Successful: 4/4

RESTORE INSTRUCTIONS:
- Docker images: ./restore_docker_images.sh -f docker-images/*/images.digests.txt
- Flatpak apps: ./restore_flatpak_apps.sh -f flatpak-apps/*/apps.tsv -r flatpak-apps/*/remotes.tsv
- Credentials: ./restore_credentials.sh -f credentials/*/credentials.tar.gpg
- Git repos: Use gitdow with git_repositories_backup.txt

CREATED: Wed Sep 10 18:59:21 EDT 2025
```

## 🚨 Troubleshooting

### Common Issues

#### Exit Code 1
- **Cause**: One or more components failed to backup
- **Solution**: Check the output for specific error messages
- **Example**: Docker daemon not running, missing GPG keys, permission issues

#### Permission Denied
```bash
# Make scripts executable
chmod +x backup_*.sh restore_*.sh

# Check ownership
ls -la backup_*.sh
```

#### Missing Dependencies
```bash
# Install missing tools (Arch Linux / CachyOS)
sudo pacman -S docker flatpak gnupg git

# Enable and start Docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER  # Logout/login required
```

#### GPG Issues
```bash
# Check GPG setup
gpg --list-secret-keys
gpg --list-keys

# Generate key if none exist
gpg --full-generate-key
```

### Debug Mode
```bash
# Run with bash debug output
bash -x ./backup_everything.sh --no-theatrics

# Verbose output with dry run
./backup_everything.sh --dry-run --no-theatrics
```

## 💡 Tips & Best Practices

### Backup Strategy
1. **Regular automated backups** - Set up cron jobs or systemd timers
2. **Test your restores** - Regularly verify backups can be restored
3. **Multiple backup locations** - Store backups on different devices/cloud
4. **Version rotation** - Keep multiple backup versions, clean up old ones

### Security Best Practices
1. **Always encrypt credentials** - Never use `--no-encrypt` in production
2. **Strong passphrases** - Use long, complex passphrases for encryption
3. **Secure storage** - Store backups on encrypted drives or secure cloud storage
4. **Access control** - Limit who can access backup files and scripts

### Performance Tips
1. **Use `--flat` for large backups** - Easier to manage single directory
2. **Skip theatrics in automation** - Use `--no-theatrics` for cron jobs
3. **Component-specific backups** - Backup only what you need for faster execution
4. **SSD storage** - Store backups on fast storage for better performance

### Maintenance
```bash
# Clean up old backups (keep last 30 days)
find ~/complete-backups -type d -name "20*" -mtime +30 -exec rm -rf {} \;

# Check backup sizes
du -sh ~/complete-backups/*/

# Verify latest backup integrity
./backup_everything.sh --dry-run
```

## 📝 Changelog

### Recent Improvements
- ✅ Fixed exit code 1 issues with arithmetic expansions
- ✅ Added dynamic step counting based on enabled components
- ✅ Implemented `--flat` option for simplified directory structure
- ✅ Enhanced error handling and debugging output
- ✅ Improved backup summary generation
- ✅ Better support for dry-run testing

## 🤝 Contributing

These scripts are personal tools but improvements are welcome:

1. **Bug Reports**: Test thoroughly and provide detailed error output
2. **Feature Requests**: Consider impact on existing functionality
3. **Security**: Always consider security implications of changes
4. **Testing**: Test on different systems and configurations

## 📄 License

Personal use scripts - use at your own risk. No warranty provided.

## ⚡ Quick Reference Card

```bash
# Full backup with personality
./backup_everything.sh

# Automation-friendly backup
./backup_everything.sh --no-theatrics --flat

# Test what would happen
./backup_everything.sh --dry-run

# Specific components only
./backup_everything.sh --docker --flatpak --no-theatrics

# Custom location
./backup_everything.sh --outdir /mnt/external/backups

# Choose personality
./backup_everything.sh -p glados

# Restore everything from latest (SSH keys auto-activated)
./restore_everything.sh

# Restore without SSH activation
./restore_everything.sh --no-ssh-agent

# Restore from specific backup
./restore_everything.sh --backup-dir /path/to/backup
```

---

**Happy Backing Up!** 🎉 Remember: The best backup is the one you actually use and test regularly.
