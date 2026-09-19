# Git SSH Signing - Profile & SSH Commit Signing Setup Tool

<div align="center">

```
   ██████╗ ██╗████████╗    ███████╗███████╗██╗  ██╗
  ██╔════╝ ██║╚══██╔══╝    ██╔════╝██╔════╝██║  ██║
  ██║  ███╗██║   ██║       ███████╗███████╗███████║
  ██║   ██║██║   ██║       ╚════██║╚════██║██╔══██║
  ╚██████╔╝██║   ██║       ███████║███████║██║  ██║
   ╚═════╝ ╚═╝   ╚═╝       ╚══════╝╚══════╝╚═╝  ╚═╝
```

**Interactive Setup for Git Identity & SSH Key Commit Signing for GitHub / GitLab**

**Author:** ShadowHarvy  
**Version:** 1.0.0  
**License:** MIT

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Why Sign Git Commits with SSH?](#-why-sign-git-commits-with-ssh)
- [What the Script Does](#-what-the-script-does)
- [Usage](#-usage)
  - [Interactive Mode (Recommended)](#interactive-mode-recommended)
  - [Command-Line Flags](#command-line-flags)
- [Step-by-Step GitHub Setup](#-step-by-step-github-setup)
- [Verifying Signed Commits](#-verifying-signed-commits)
- [Troubleshooting & FAQ](#-troubleshooting--faq)

---

## 🌟 Overview

`setup_git_ssh_signing.sh` configures your global Git profile with your display name and email address, associates Git directly with your SSH public key, and enables automatic cryptographically signed commits using the modern SSH format (introduced in Git 2.34+).

Gone are the days of dealing with complex GPG keyrings and GPG expiration issues—you can now use your standard SSH key (such as `~/.ssh/id_ed25519.pub`) for both authentication and commit verification.

---

## 🔐 Why Sign Git Commits with SSH?

1. **Verified Badge on GitHub**: Displays the green **"Verified"** badge next to all your commits, proving authorship.
2. **Impersonation Prevention**: Anyone can configure `user.name` and `user.email` to match yours; cryptographic signatures prove the commit was created by the owner of the private key.
3. **No Extra GPG Tooling**: You don't need `gpg-agent`, `pinentry`, or separate GPG keys. Git signs commits natively with your existing OpenSSH key pair.

---

## ⚙️ What the Script Does

The script executes the standard 4-step Git SSH configuration workflow:

1. **Identity Configuration**:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```
2. **Set SSH Signing Format**:
   ```bash
   git config --global gpg.format ssh
   ```
3. **Link SSH Public Key**:
   ```bash
   git config --global user.signingkey ~/.ssh/id_ed25519.pub
   ```
4. **Enable Automatic Commit Signing**:
   ```bash
   git config --global commit.gpgsign true
   ```
5. **Local Verification Trust (`allowed_signers`)**:
   Adds your public key to `~/.config/git/allowed_signers` and sets:
   ```bash
   git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
   ```
   *(This ensures `git log --show-signature` displays your commits as trusted locally).*
6. **Clipboard Integration**: Automatically copies your public key to the system clipboard using `wl-copy`, `xclip`, or `pbcopy`.

---

## 🚀 Usage

### Interactive Mode (Recommended)

Simply run the script with no arguments:

```bash
./scripts/bin/setup_git_ssh_signing.sh
# or from root:
./setup_git_ssh_signing.sh
```

You will be guided through:
1. Confirming or typing your Git display name.
2. Confirming or typing your Git email.
3. Selecting an existing SSH public key (or generating a new Ed25519 key on the fly).
4. Enabling automatic signing and local verification trust.

### Command-Line Flags

```bash
./scripts/bin/setup_git_ssh_signing.sh [OPTIONS]
```

| Flag | Description |
| :--- | :--- |
| `-n, --name NAME` | Git user display name |
| `-e, --email EMAIL` | Git email address (matching your GitHub account) |
| `-k, --key PATH` | Path to public SSH key (e.g. `~/.ssh/id_ed25519.pub`) |
| `--no-sign` | Do not enable automatic commit signing (`commit.gpgsign false`) |
| `--no-trust` | Skip configuring `~/.config/git/allowed_signers` |
| `--dry-run` | Preview all commands without modifying Git config |
| `-y, --yes` | Run non-interactively, accepting detected defaults |
| `-h, --help` | Display help screen |

#### Examples

```bash
# Preview what would be configured
./scripts/bin/setup_git_ssh_signing.sh --dry-run

# Run non-interactively with specific name and email
./scripts/bin/setup_git_ssh_signing.sh -n "ShadowHarvy" -e "jimbob343@gmail.com" -y
```

---

## 🌐 Step-by-Step GitHub Setup

To display the green **"Verified"** badge on GitHub:

1. Copy your public key:
   - The script automatically copies it to your clipboard if `wl-copy` or `xclip` is installed.
   - Or view it manually: `cat ~/.ssh/id_ed25519.pub`
2. Open your GitHub account settings:
   👉 **[https://github.com/settings/keys](https://github.com/settings/keys)**
3. Click the green button **"New SSH key"**.
4. Fill out the fields:
   - **Title**: E.g. `Arch Laptop Signing Key`
   - **Key type**: Select **`Signing Key`** *(Critical: do not leave as Authentication Key if you want commit signing)*.
   - **Key**: Paste the content of your `.pub` file.
5. Click **"Add SSH key"**.

> **Note:** If you also want to use this same SSH key to clone, push, and pull repositories (`git@github.com:...`), add the key a second time with **Key type** set to **`Authentication Key`**.

---

## 🧪 Verifying Signed Commits

In any Git repository, create a test commit:

```bash
git commit -m "Test signed commit"
```

Then check the cryptographic signature:

```bash
git log -1 --show-signature
```

Expected output:
```text
commit 1a2b3c4d5e... (HEAD -> main)
Good "git" signature for you@example.com with ED25519 key SHA256:...
Author: Your Name <you@example.com>
Date:   ...
```

Push the commit to GitHub, and you will see the **Verified** badge next to your commit!

---

## ❓ Troubleshooting & FAQ

### 1. `git log --show-signature` says "signature untrusted"
Git needs to know who is allowed to sign commits locally. The script automatically configures this by creating `~/.config/git/allowed_signers` with:
```text
you@example.com ssh-ed25519 AAAAC3NzaC1... you@example.com
```
and setting:
```bash
git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
```

### 2. GitHub shows "Unverified" commit badge
- Ensure the email in `git config --global user.email` matches a verified email in your GitHub account ([Settings > Emails](https://github.com/settings/emails)).
- Ensure the key was added as a **Signing Key** under [GitHub SSH and GPG keys](https://github.com/settings/keys).

### 3. Error: `error: gpg.format=ssh requires git 2.34+`
Ensure your Git version is 2.34.0 or higher:
```bash
git --version
```
Update Git via your system package manager if necessary (`sudo pacman -S git`).
