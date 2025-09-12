# gitback - The Grand Repo Wrangler & Backupinator 9001

A personality-driven repository backup and synchronization tool that discovers, updates, and catalogs all Git repositories in configured directories with theatrical flair.

## 🚀 Features

- **Automated Repository Discovery**: Scans configured directories for Git repositories
- **Intelligent Updates**: Pulls latest changes while avoiding conflicts with dirty repos
- **Backup Catalog**: Maintains a detailed backup file with repository URLs and metadata
- **Multiple Personalities**: Choose from wizard, GLaDOS, or dungeon master themes
- **Progress Tracking**: Detailed reporting of successful updates, new repos, and issues
- **Safety First**: Skips repositories with uncommitted changes to prevent conflicts

## 🎭 Personalities

This application supports multiple personalities for a more engaging experience:

- **🧙‍♂️ Wizard**: Mystical repository management with arcane terminology
- **🤖 GLaDOS**: Sarcastic AI treats your repos like test subjects
- **🏰 DM**: D&D dungeon master frames everything as epic adventures

Choose a personality with `-p <persona>` or let the system choose randomly.

## 📖 Usage

### Basic Usage

```bash
# Run with random personality
./gitback

# Choose specific personality
./gitback -p wizard
./gitback -p glados
./gitback -p dm
```

### Command Options

```bash
gitback [OPTIONS]

Options:
  -p <persona>  Choose a personality: wizard, glados, dm
                If omitted, a random one is chosen
  -h            Show this help message and exit
```

## 📋 Requirements

### System Requirements
- **OS**: Linux, macOS, or Windows with Bash
- **Shell**: Bash 4.0+
- **Git**: Git must be installed and configured

### Dependencies
- `git` - Version control system
- `lsblk` - Block device listing (Linux only)
- Standard Unix utilities: `find`, `grep`, `awk`, `basename`

### Installation Commands
```bash
# Debian/Ubuntu
sudo apt install git

# Arch Linux
sudo pacman -S git

# macOS
brew install git
```

## 🛠️ Installation

### Quick Install
```bash
# Copy to local bin directory
cp gitback ~/.local/bin/
chmod +x ~/.local/bin/gitback
```

### System-wide Install
```bash
# Copy to system bin (requires sudo)
sudo cp gitback /usr/local/bin/
sudo chmod +x /usr/local/bin/gitback
```

## ⚙️ Configuration

### Search Directories
Edit the script to configure which directories to search for repositories:

```bash
SEARCH_DIRS=(
  "$HOME/git"
  "$HOME/development"
  "$HOME/projects"    # Add custom directories
)
```

### Backup Configuration
- **Backup Directory**: `$HOME/backup`
- **Backup File**: `$HOME/backup/repo_backup.txt`
- **Format**: Plain text with repository paths and URLs

### Timing Configuration
```bash
INTER_REPO_DELAY=0.2    # Seconds between repository operations
SKIP_THEATRICS=0        # Set to 1 to skip loading animations
```

## 📚 Examples

### Example 1: First Run with Wizard Personality
```bash
./gitback -p wizard
```
Output:
```
No persona specified. The fates have chosen: wizard
Powering up the Repo Wrangler... ONLINE!
Scanning known dimensions for git traces...
Consulting the sacred backup scroll's history...

Found Repo #1: 'my-project'
Remote 'origin' URL: https://github.com/user/my-project.git
New inscription for the scroll: 'my-project'.
```

### Example 2: GLaDOS Mode with Repository Updates
```bash
./gitback -p glados
```
Output:
```
Aperture Science Collaborative Work Monitoring System
Test Subject #1 located: 'test-repo'
Central repository link established: git@github.com:user/test-repo.git
Attempting mandatory synchronization...
✔ Synchronization complete. All your work now belongs to us.
```

### Example 3: Random Personality
```bash
./gitback
```
The system will randomly select wizard, GLaDOS, or dungeon master personality.

## 📊 Backup File Format

The backup file (`~/backup/repo_backup.txt`) contains:
```
# Wrangling Report (Run: 2025-01-09 15:30:12)
# 
# Summary:
# - Total repositories found: 5
# - Repositories with updates: 2
# - Repositories newly added: 1
# 
/home/user/git/project1 | https://github.com/user/project1.git
/home/user/git/project2 | git@gitlab.com:user/project2.git
/home/user/development/tools | https://github.com/user/tools.git
```

## 🚨 Common Issues

### Issue 1: No Repositories Found
**Problem**: "Found no git repositories in directory"
**Solution**: 
1. Verify the search directories contain Git repositories
2. Check that repositories have `.git` directories
3. Ensure proper read permissions on directories

### Issue 2: Git Pull Fails
**Problem**: "git pull failed. Check manually!"
**Solution**: 
```bash
# Navigate to the repository and check status
cd /path/to/repository
git status
git pull --verbose
```

### Issue 3: Uncommitted Changes Warning
**Problem**: "Repo has uncommitted changes. Skipping pull"
**Solution**: 
```bash
# Either commit changes or stash them
git add .
git commit -m "Work in progress"
# OR
git stash
```

## 🔍 Troubleshooting

### Enable Verbose Output
The script provides detailed output by default. To skip theatrical elements:
```bash
# Edit the script and set:
SKIP_THEATRICS=1
```

### Manual Repository Check
```bash
# Check repository status manually
cd /path/to/repo
git status
git remote -v
git log --oneline -5
```

### Backup File Issues
```bash
# Check backup file permissions
ls -la ~/backup/repo_backup.txt

# Manually create backup directory if needed
mkdir -p ~/backup
```

## 🔄 Update Workflow

The script follows this workflow for each repository:

1. **Discovery**: Find all Git repositories in search directories
2. **URL Extraction**: Get remote 'origin' URL
3. **Backup Check**: Compare against existing backup file
4. **Status Check**: Verify no uncommitted changes exist
5. **Update**: Run `git fetch` and `git pull` if safe
6. **Logging**: Record results and update backup file

## 📈 Statistics Tracking

Each run tracks and reports:
- **Total Repositories**: Number of Git repos found
- **New Repositories**: Repos not in previous backup
- **Updated Repositories**: Repos that received new commits
- **Skipped Repositories**: Repos with uncommitted changes
- **Failed Operations**: Repos where updates failed

## 🤝 Contributing

This script is part of a personal toolkit. If you find bugs or have suggestions:

1. Test changes with non-critical repositories first
2. Ensure Git operations are safe and don't cause data loss
3. Consider the entertainment value of personality modes

## 📄 License

Created by **ShadowHarvy**

This script is provided as-is for educational and personal use.

## 🔗 Related Tools

- [Git](https://git-scm.com/) - Version control system
- [gitdow](./gitdow) - Repository cloning companion tool
- [GitHub CLI](https://cli.github.com/) - GitHub command-line interface
- [GitLab CLI](https://gitlab.com/gitlab-org/cli) - GitLab command-line interface

---

*Part of the ShadowHarvy toolkit - Because managing repos manually is for peasants*
