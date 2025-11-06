# Git SSH - SSH Configuration & Automation Tool

<div align="center">

```
   ██████╗ ██╗████████╗    ███████╗███████╗██╗  ██╗
  ██╔════╝ ██║╚══██╔══╝    ██╔════╝██╔════╝██║  ██║
  ██║  ███╗██║   ██║       ███████╗███████╗███████║
  ██║   ██║██║   ██║       ╚════██║╚════██║██╔══██║
  ╚██████╔╝██║   ██║       ███████║███████║██║  ██║
   ╚═════╝ ╚═╝   ╚═╝       ╚══════╝╚══════╝╚═╝  ╚═╝
```

**Configure Git to Prefer SSH Over HTTPS for All Operations**

**Author:** ShadowHarvy  
**Version:** 1.0.0  
**License:** MIT

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Why SSH?](#-why-ssh)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Usage](#-usage)
- [Options](#-options)
- [Examples](#-examples)
- [How It Works](#-how-it-works)
- [Troubleshooting](#-troubleshooting)
- [FAQ](#-faq)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 Overview

**Git SSH** is a comprehensive automation tool that configures your Git environment to prefer SSH over HTTPS for all GitHub operations. Say goodbye to username/password prompts and hello to seamless, secure authentication using SSH keys!

This tool:
- ✅ Automatically rewrites HTTPS GitHub URLs to SSH
- ✅ Configures GitHub CLI (gh) to use SSH protocol
- ✅ Verifies your SSH authentication with GitHub
- ✅ Optionally converts existing repositories from HTTPS to SSH
- ✅ Works with both standalone and automated workflows

---

## ✨ Features

### 🔐 Security First
- **SSH Key Authentication** - More secure than password-based authentication
- **No Plain-Text Credentials** - SSH keys are never transmitted in plain text
- **No Token Management** - No need to manage or rotate personal access tokens

### 🚀 Automation
- **One-Command Setup** - Configure your entire Git environment with a single command
- **Bulk Repository Conversion** - Automatically find and convert all HTTPS repos
- **Dry-Run Mode** - Preview changes before applying them
- **Colorful Output** - Easy-to-read, color-coded status messages

### 🔧 Flexibility
- **Customizable Search Depth** - Control how deep to search for repositories
- **Selective Conversion** - Choose whether to convert existing repos
- **Non-Destructive** - Never overwrites or deletes data

### 📊 Verification
- **SSH Connection Testing** - Verifies your SSH key is working with GitHub
- **Status Reporting** - Shows current configuration and authentication status
- **Summary Output** - Clear summary of all changes made

---

## 🤔 Why SSH?

### SSH vs HTTPS

| Feature | SSH | HTTPS |
|---------|-----|-------|
| **Authentication** | Public key cryptography | Username + Password/Token |
| **Security** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Convenience** | No password prompts | Prompted for credentials |
| **Speed** | Slightly faster | Slightly slower |
| **Firewalls** | May be blocked (port 22) | Rarely blocked (port 443) |
| **Setup Complexity** | Moderate | Easy |

### Benefits of SSH

1. **No Password Prompts** - Set it up once, never type your password again
2. **More Secure** - Private keys are never sent over the network
3. **Better for Automation** - Scripts and CI/CD can authenticate without secrets
4. **Faster Operations** - SSH connections can be reused and multiplexed
5. **Industry Standard** - Used by most professional development teams

---

## ✅ Prerequisites

### Required
- **Git** - Version 2.0 or higher
- **SSH** - OpenSSH client (usually pre-installed on Linux/macOS)
- **SSH Key** - Must be generated and added to your GitHub account

### Optional
- **GitHub CLI (gh)** - For enhanced GitHub integration
  ```bash
  # Arch Linux
  sudo pacman -S github-cli
  
  # Ubuntu/Debian
  sudo apt install gh
  
  # macOS
  brew install gh
  ```

### Setting Up SSH Keys

If you don't have an SSH key yet:

```bash
# Generate a new SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Start the SSH agent
eval "$(ssh-agent -s)"

# Add your SSH key to the agent
ssh-add ~/.ssh/id_ed25519

# Copy your public key
cat ~/.ssh/id_ed25519.pub
```

Then add the public key to GitHub:
1. Go to https://github.com/settings/keys
2. Click "New SSH key"
3. Paste your public key
4. Click "Add SSH key"

---

## 📥 Installation

### Method 1: Direct Download

```bash
# Download the script
curl -o ~/bin/git_prefer_ssh.sh https://raw.githubusercontent.com/YOUR_REPO/git_prefer_ssh.sh

# Make it executable
chmod +x ~/bin/git_prefer_ssh.sh
```

### Method 2: Clone Repository

```bash
# Clone the repository
git clone https://github.com/YOUR_REPO/git-ssh-tools.git

# Copy to your bin directory
cp git-ssh-tools/git_prefer_ssh.sh ~/bin/

# Make it executable
chmod +x ~/bin/git_prefer_ssh.sh
```

### Method 3: Manual Installation

1. Copy the script to `~/bin/git_prefer_ssh.sh`
2. Make it executable: `chmod +x ~/bin/git_prefer_ssh.sh`
3. Ensure `~/bin` is in your PATH

---

## 🚀 Usage

### Basic Syntax

```bash
git_prefer_ssh.sh [OPTIONS]
```

### Quick Start

```bash
# Configure Git to prefer SSH (recommended for first run)
~/bin/git_prefer_ssh.sh

# Configure AND convert all existing repos
~/bin/git_prefer_ssh.sh --convert-existing

# Preview what would be changed (safe to run)
~/bin/git_prefer_ssh.sh --convert-existing --dry-run
```

---

## ⚙️ Options

### `--convert-existing`
Scans your home directory for Git repositories using HTTPS and converts them to SSH.

**Default:** Disabled  
**Example:** `git_prefer_ssh.sh --convert-existing`

### `--scan-depth N`
Controls how deep to search for Git repositories.

**Default:** 3  
**Range:** 1-10 (recommended)  
**Example:** `git_prefer_ssh.sh --convert-existing --scan-depth 5`

**Depth Guide:**
- `1` - Only `~/repo/` 
- `2` - Also `~/projects/repo/`
- `3` - Also `~/code/projects/repo/` (default)
- `5` - Deep directory structures

### `--dry-run`
Shows what changes would be made without actually applying them.

**Example:** `git_prefer_ssh.sh --convert-existing --dry-run`

### `-h, --help`
Displays help information and exits.

**Example:** `git_prefer_ssh.sh --help`

---

## 📚 Examples

### Example 1: First-Time Setup

```bash
# Just configure Git and GitHub CLI (recommended)
~/bin/git_prefer_ssh.sh
```

**Output:**
```
╔═══════════════════════════════════════════════════════════════════════╗
║                         GIT SSH                                       ║
║              SSH Configuration & Automation Tool                      ║
╚═══════════════════════════════════════════════════════════════════════╝

=== Git SSH Preference Configuration ===

[1/4] Configuring Git to prefer SSH over HTTPS...
  ✓ Git will now automatically use SSH for all GitHub URLs

[2/4] Configuring GitHub CLI (gh) to use SSH...
  ✓ GitHub CLI will now use SSH for git operations

[3/4] Verifying SSH authentication with GitHub...
  ✓ SSH authentication successful as: ShadowHarvy

[4/4] Scanning for existing repositories...
  Skipped (use --convert-existing to enable)

=== Configuration Complete ===

Summary:
  • Git will now automatically use SSH for GitHub URLs
  • GitHub CLI configured to use SSH (if installed)
  • All future clones will use SSH by default
```

### Example 2: Convert Existing Repos

```bash
# Convert all existing HTTPS repos to SSH
~/bin/git_prefer_ssh.sh --convert-existing
```

**Output:**
```
[4/4] Scanning for existing repositories...
  Searching for repositories (depth: 3)...

  Repository: /home/user/projects/my-app
    Current:  https://github.com/user/my-app.git
    New:      git@github.com:user/my-app.git
    ✓ Converted to SSH

  Repository: /home/user/code/another-repo
    Current:  https://github.com/user/another-repo.git
    New:      git@github.com:user/another-repo.git
    ✓ Converted to SSH

  Converted 2 of 2 repositories

=== Configuration Complete ===

Summary:
  • Git configured to prefer SSH for GitHub
  • GitHub CLI configured to use SSH
  • Converted 2 existing repos to SSH

All future Git operations with GitHub will use SSH!
```

### Example 3: Preview Changes (Dry Run)

```bash
# See what would be changed without making changes
~/bin/git_prefer_ssh.sh --convert-existing --dry-run
```

**Output:**
```
[1/4] Configuring Git to prefer SSH over HTTPS...
[dry-run] Would set: git config --global url."git@github.com:".insteadOf "https://github.com/"

[2/4] Configuring GitHub CLI (gh) to use SSH...
[dry-run] Would set: gh config set git_protocol ssh

[3/4] Verifying SSH authentication with GitHub...
  ✓ SSH authentication successful as: ShadowHarvy

[4/4] Scanning for existing repositories...
  Searching for repositories (depth: 3)...

  Repository: /home/user/projects/my-app
    Current:  https://github.com/user/my-app.git
    New:      git@github.com:user/my-app.git
    [dry-run] Would convert to SSH

  Found 1 repositories that would be converted
```

### Example 4: Deep Search

```bash
# Search deeper directory structures
~/bin/git_prefer_ssh.sh --convert-existing --scan-depth 5
```

---

## 🔍 How It Works

### Step 1: Git URL Rewriting

The script configures Git to automatically rewrite HTTPS URLs to SSH:

```bash
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

**Effect:**
- `git clone https://github.com/user/repo.git` → Uses `git@github.com:user/repo.git`
- `git push` to HTTPS remote → Uses SSH automatically
- Works transparently with all Git commands

### Step 2: GitHub CLI Configuration

If GitHub CLI is installed, configures it to use SSH:

```bash
gh config set git_protocol ssh
```

**Effect:**
- `gh repo clone user/repo` → Uses SSH
- `gh pr create` → Uses SSH for push operations

### Step 3: SSH Verification

Tests your SSH connection to GitHub:

```bash
ssh -T git@github.com
```

**Success:** `Hi username! You've successfully authenticated...`

### Step 4: Repository Conversion (Optional)

Scans for repositories and converts their remote URLs:

```bash
# Find repos using HTTPS
find $HOME -name ".git" -type d

# Convert each one
git remote set-url origin git@github.com:user/repo.git
```

---

## 🔧 Troubleshooting

### SSH Authentication Failed

**Problem:** `✗ SSH authentication failed`

**Solution:**
1. Verify your SSH key exists:
   ```bash
   ls -la ~/.ssh/id_*
   ```

2. Test SSH connection manually:
   ```bash
   ssh -T git@github.com
   ```

3. Add your SSH key to GitHub:
   - Copy key: `cat ~/.ssh/id_ed25519.pub`
   - Add at: https://github.com/settings/keys

4. Check SSH agent:
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

### Permission Denied (publickey)

**Problem:** `Permission denied (publickey)`

**Solution:**
1. Verify SSH key is added to agent:
   ```bash
   ssh-add -l
   ```

2. Check SSH config (`~/.ssh/config`):
   ```
   Host github.com
     HostName github.com
     User git
     IdentityFile ~/.ssh/id_ed25519
   ```

3. Verify key permissions:
   ```bash
   chmod 600 ~/.ssh/id_ed25519
   chmod 644 ~/.ssh/id_ed25519.pub
   ```

### GitHub CLI Not Found

**Problem:** `⚠ GitHub CLI (gh) not found - skipping`

**Solution:** This is not an error - GitHub CLI is optional.

To install:
```bash
# Arch Linux
sudo pacman -S github-cli

# Ubuntu/Debian
sudo apt install gh

# macOS
brew install gh
```

### No Repositories Found

**Problem:** `No repositories using HTTPS found`

**Reasons:**
1. All repos already use SSH (good!)
2. Search depth too shallow
3. Repos are outside home directory

**Solution:**
- Increase search depth: `--scan-depth 5`
- Manually check: `git remote -v` in each repo

### Repository Conversion Failed

**Problem:** `✗ Failed to convert`

**Reasons:**
1. Repository has no remote named "origin"
2. Repository has unusual remote configuration
3. Permission issues

**Solution:**
1. Check current remote:
   ```bash
   cd /path/to/repo
   git remote -v
   ```

2. Manually convert:
   ```bash
   git remote set-url origin git@github.com:user/repo.git
   ```

---

## ❓ FAQ

### Q: Will this affect non-GitHub repositories?

**A:** No. The script only rewrites URLs for `github.com`. GitLab, Bitbucket, and self-hosted Git servers are unaffected.

To support other platforms, add similar rules:
```bash
git config --global url."git@gitlab.com:".insteadOf "https://gitlab.com/"
```

### Q: Can I undo these changes?

**A:** Yes! Remove the configuration:

```bash
# Remove Git URL rewriting
git config --global --unset url."git@github.com:".insteadOf

# Reset GitHub CLI to HTTPS
gh config set git_protocol https

# Manually convert repos back to HTTPS
git remote set-url origin https://github.com/user/repo.git
```

### Q: What if I use HTTPS for some repos and SSH for others?

**A:** The global configuration will always prefer SSH. To use HTTPS for specific repos:

```bash
cd /path/to/specific/repo
git config --local url."https://github.com/".insteadOf "git@github.com:"
```

### Q: Does this work with private repositories?

**A:** Yes! As long as your SSH key is added to your GitHub account with appropriate permissions.

### Q: Will this work in CI/CD environments?

**A:** Yes, but you'll need to:
1. Add SSH keys to your CI/CD environment
2. Configure SSH agent in your pipeline
3. Add GitHub to known_hosts

Example for GitHub Actions:
```yaml
- uses: webfactory/ssh-agent@v0.5.4
  with:
    ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
```

### Q: What about organizations with 2FA/SAML?

**A:** SSH keys bypass 2FA/SAML at the Git protocol level. You'll still need 2FA for web login, but Git operations work seamlessly.

### Q: Can I use this on Windows?

**A:** Yes, but with modifications:
- Use Git Bash or WSL
- Adjust path separators
- SSH key locations may differ

### Q: How do I verify it's working?

**A:** Try cloning a repo with an HTTPS URL:

```bash
git clone https://github.com/user/repo.git
```

Check the remote:
```bash
cd repo
git remote -v
# Should show: git@github.com:user/repo.git
```

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### Reporting Bugs
1. Check if the issue already exists
2. Include your OS and Git version
3. Provide error messages and steps to reproduce

### Feature Requests
1. Describe the feature and use case
2. Explain why it would be useful
3. Provide examples if possible

### Pull Requests
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Code Style
- Use 2-space indentation
- Follow existing naming conventions
- Add comments for complex logic
- Use color constants for output

---

## 📄 License

This project is licensed under the MIT License.

```
MIT License

Copyright (c) 2025 ShadowHarvy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

- **Git** - For being awesome version control
- **GitHub** - For excellent SSH key management
- **OpenSSH** - For secure, reliable authentication
- **The Open Source Community** - For inspiration and support

---

## 📞 Support

- **Issues:** Report bugs or request features on GitHub
- **Discussions:** Ask questions in GitHub Discussions
- **Email:** Contact the author for private inquiries

---

<div align="center">

**Made with ❤️ by ShadowHarvy**

If this tool helped you, consider giving it a ⭐!

[Report Bug](https://github.com/YOUR_REPO/issues) · [Request Feature](https://github.com/YOUR_REPO/issues) · [Documentation](https://github.com/YOUR_REPO/wiki)

</div>
