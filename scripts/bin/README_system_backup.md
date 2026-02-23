# System Backup & Restore (`system_backup.sh`)

A unified, secure tool for backing up and restoring your system's critical working state, including:
1. **Secure Credentials** (SSH, GPG, AWS, config files, package managers, etc.)
2. **Git Repositories** (A manifest of your cloned repos and their remotes)
3. **Flatpak Apps** (A manifest of installed flatpaks and configured remotes)

By default, everything is heavily compressed using `xz -9e` and encrypted securely via GPG.

---

## 1. Backing Up

The `backup` subcommand collects all tracked materials into a temporary space, bundles them into a master `.tar.xz` archive, securely encrypts it, and places the final artifact in the output directory.

### Basic Usage
```bash
./system_backup.sh backup
```
- Prompts for a passphrase to symmetrically encrypt the `credentials.tar.xz.gpg` archive.
- Outputs the final encrypted file to `~/secure-backups/system-backup-YYYYMMDD-HHMMSS.tar.xz.gpg`.

### Advanced Backup Options
- `--encrypt-recipient <USERID>`: Encrypts the archive asymmetrically to a specific GPG key/email instead of a passphrase.
- `--no-encrypt`: **(NOT RECOMMENDED)** Outputs a plaintext `.tar.xz` archive.
- `--include-vscode`: Backs up your `~/.config/Code/User` settings and snippets.
- `--outdir <dir>`: Change the destination folder (default is `~/secure-backups`).
- `--dry-run`: See what would be archived and where, without actually doing it.

---

## 2. Restoring

The `restore` subcommand reads the archive, extracts it to a temporary space, and carefully restores the contents to their proper places. It validates SSH permissions and prompts to add keys back into your SSH agent.

### Basic Usage
```bash
# Restore from a specific archive file
./system_backup.sh restore -f ~/secure-backups/system-backup-20231024-120000.tar.xz.gpg

# Restore from a previously extracted folder
./system_backup.sh restore -d ~/my-extracted-backup/collected
```

### Granular Skips
By default, `restore` attempts to restore everything it finds in the backup. You can skip entire domains:
- `--skip-credentials`: Ignore all SSH, GPG, AWS, tool configs, etc.
- `--skip-gits`: Do not attempt to `git clone` the repositories back into `~/git`.
- `--skip-flatpaks`: Do not attempt to add Flatpak remotes or install Flatpak apps.

You can also skip specific types of credentials if you only need partial restores:
- `--skip-ssh`
- `--skip-gpg`
- `--skip-git-config`
- `--skip-github`
- `--skip-vscode`
- `--skip-docker`
- `--skip-aws`
- `--skip-kube`
- `--skip-keyring`
- `--skip-gemini`
- `--skip-package-managers`
- `--skip-ani-cli`
- `--skip-viu-media`
- `--skip-komikku`

### Other Restore Options
- `--no-ssh-agent`: Prevents the script from automatically attempting to add restored SSH keys to your `ssh-agent`.
- `--dry-run`: Prints out exactly what files would perfectly restore to what locations, without touching the live system.

---

## 3. What Gets Backed Up?

### Credentials Module
- **SSH**: `~/.ssh` (keys, config, known_hosts - strict filtering)
- **GPG**: Exported public keys, secret keys, and ownertrust values.
- **GitHub CLI**: `~/.config/gh`
- **Git Configs**: `~/.gitconfig` and `~/.git-credentials`
- **System Keyrings**: `~/.local/share/keyrings` 
- **Docker/Podman**: Login registries
- **AWS & Kubernetes**: Profiles and kubeconfigs
- **Package Managers**: npm, PyPI, Cargo
- **Custom Configs**: `~/.netrc`, `~/.gemini`, `ani-cli`, `viu-media`, `komikku`

### Gits Module
Iterates through every folder inside `/home/mw/git`. If it is a valid git repository, it extracts the directory name and the `origin` remote URL, saving this list to be cloned during restoration.

### Flatpaks Module
Records a TSV of configured remotes (`flatpak remotes`) and installed flatpaks (`flatpak list --app`), noting if they were user or system installations, so they can be re-installed cleanly.
