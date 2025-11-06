# Combined Omarchy Theme Installer (Temporary)

A bash script that automatically fetches and installs Omarchy themes from **two sources**:
1. **omarchythemes.com** - The official community themes gallery
2. **learn.omacom.io** - The Omarchy manual's extra themes page

The script intelligently deduplicates themes and provides flexible installation options.

---

## What It Does

1. **Fetches** themes from both omarchythemes.com (via scraping) and learn.omacom.io (direct GitHub URLs)
2. **Normalizes** GitHub repository URLs to catch duplicates across sources
3. **Deduplicates** based on normalized repo URLs (e.g., `github.com/user/repo` and `github.com/user/repo.git` are treated as the same)
4. **Combines** unique themes from both sources into a single list
5. **Installs** selected themes using the `omarchy-theme-install` command
6. **Reports** detailed progress with colored output and comprehensive logs

---

## Why This Script Exists

This is a **temporary/combined installer** created to bridge multiple theme sources:
- The original `omarchy-install-themes.sh` only scrapes omarchythemes.com
- The learn.omacom.io page provides a curated list of additional themes
- This script combines both sources to ensure you don't miss any themes

**Note:** This may become obsolete if the theme sources are consolidated in the future.

---

## Requirements

### Required
- **Omarchy** with `omarchy-theme-install` command installed
  - Default location: `~/.local/share/omarchy/bin/omarchy-theme-install`
- Standard Unix tools: `curl`, `grep`, `sed`, `awk`, `sort`, `uniq`, `tr`
- Bash 4.0+

### Optional
- **fzf** - For enhanced interactive theme selection (highly recommended)
  - Install: `sudo pacman -S fzf` (Arch) or `brew install fzf` (macOS)

---

## Installation

The script is located at:
```
~/git/conf/scripts/bin/omarchy-install-all-themes-combined.sh
```

Make sure it's executable (already done):
```bash
chmod +x ~/git/conf/scripts/bin/omarchy-install-all-themes-combined.sh
```

Add the scripts directory to your PATH if not already:
```bash
export PATH="$HOME/git/conf/scripts/bin:$PATH"
```

---

## Usage

### Quick Start

Run without arguments to get an interactive prompt:
```bash
omarchy-install-all-themes-combined.sh
```

You'll be asked to choose:
1. Install all themes automatically
2. Interactive selection (choose specific themes)
3. List themes only

### Command-Line Options

#### List all available themes
```bash
omarchy-install-all-themes-combined.sh --list
```

Shows all unique themes found from both sources with their GitHub URLs and source.

#### Install all themes automatically
```bash
omarchy-install-all-themes-combined.sh --all
```

Fetches and installs every unique theme from both sources.

#### Interactive selection
```bash
omarchy-install-all-themes-combined.sh --interactive
```

- With `fzf`: Multi-select interface (TAB to select, ENTER to confirm)
- Without `fzf`: Numbered list with range support (e.g., `1,2,5-7`)

#### Install specific themes
```bash
omarchy-install-all-themes-combined.sh --only dracula,catppuccin,nord
```

Install only the specified theme slugs (comma-separated, case-insensitive).

#### Dry-run (test without installing)
```bash
omarchy-install-all-themes-combined.sh --all --dry-run
```

Shows what would be installed without actually running the installer.

---

## Options Reference

| Option | Description |
|--------|-------------|
| `-a, --all` | Install all discovered themes |
| `-i, --interactive` | Choose themes interactively (fzf or numbered menu) |
| `-o, --only SLUGS` | Install comma-separated list of theme slugs |
| `-l, --list` | List all discovered themes and exit |
| `-n, --dry-run` | Show what would be done without installing |
| `-d, --delay SEC` | Delay between requests in seconds (default: 0.5) |
| `--strict-github` | Only accept root GitHub repo links (filter out extra paths) |
| `-h, --help` | Show help message |

---

## Environment Variables

Override defaults by setting these before running:

| Variable | Default | Description |
|----------|---------|-------------|
| `OMARCHY_INSTALLER` | `~/.local/share/omarchy/bin/omarchy-theme-install` | Path to theme installer |
| `BASE_URL` | `https://omarchythemes.com` | Base URL for omarchythemes.com |
| `LEARN_URL` | `https://learn.omacom.io/2/the-omarchy-manual/90/extra-themes` | Learn page URL |
| `DELAY` | `0.5` | Delay between HTTP requests (seconds) |
| `USER_AGENT` | `OmarchyCombinedInstaller/1.0 ...` | HTTP User-Agent string |
| `LOG_FILE` | `/tmp/omarchy-theme-install-TIMESTAMP.log` | Log file path |
| `STRICT_GITHUB` | `0` | Set to `1` to only accept root repo links |

---

## Examples

### Install all themes with slower rate limiting
```bash
DELAY=1.0 omarchy-install-all-themes-combined.sh --all
```

### List themes and save to file
```bash
omarchy-install-all-themes-combined.sh --list > available-themes.txt
```

### Install specific themes with dry-run
```bash
omarchy-install-all-themes-combined.sh --only dracula,gruvbox,nord --dry-run
```

### Use custom log location
```bash
LOG_FILE=~/omarchy-combined.log omarchy-install-all-themes-combined.sh --all
```

### Interactive mode with custom installer path
```bash
OMARCHY_INSTALLER=/usr/local/bin/omarchy-theme-install \
  omarchy-install-all-themes-combined.sh --interactive
```

---

## Features

### ✅ Dual-Source Fetching
- Scrapes omarchythemes.com for theme pages and extracts GitHub URLs
- Directly parses learn.omacom.io for GitHub repository links
- Gracefully handles failures from either source

### ✅ Intelligent Deduplication
- Normalizes GitHub URLs (lowercase, removes `.git`, trailing slashes)
- Tracks unique repositories by `owner/repo` pattern
- Handles slug collisions by appending `-2`, `-3`, etc.

### ✅ Interactive Selection
- **With fzf**: Beautiful multi-select interface
- **Without fzf**: Numbered list with range support (`1,2,5-7`)
- Shows theme slug, GitHub URL, and source

### ✅ Progress Tracking
- Shows `[X/Y]` progress for each theme
- Colored output (blue=info, green=success, yellow=warning, red=error)
- Real-time feedback during installation

### ✅ Robust Error Handling
- Continues on individual theme failures
- Reports all failures at the end
- Never aborts the entire run

### ✅ Detailed Logging
- Timestamped logs in `/tmp/`
- Full command output captured
- Easy debugging of failures

### ✅ Rate Limiting
- Configurable delay between HTTP requests
- Respectful to server resources
- Adjustable via `--delay` or `DELAY` env var

### ✅ Dry-Run Support
- Test before installing
- Shows exactly what would happen
- Safe for experimentation

---

## Expected Results

When running with `--all`, you can expect:

- **~75+ themes** from learn.omacom.io (direct GitHub links)
- **~70+ themes** from omarchythemes.com (scraped from theme pages)
- **~100-120 unique themes** after deduplication (overlap varies)
- **Some failures** are normal:
  - Private repos requiring authentication (~5-10)
  - Official themes already built into Omarchy (~10-15)
  - Removed or renamed repositories (~2-5)

Example output:
```
[INFO] Found 73 themes from omarchythemes.com
[INFO] Found 76 themes from learn.omacom.io
[INFO] Total unique themes after deduplication: 118
[INFO] Successful installations: 95
[INFO] Failed installations: 23
```

---

## Log Files

All operations are logged to timestamped files:
```
/tmp/omarchy-theme-install-YYYYMMDD-HHMMSS.log
```

### View the last run's log
```bash
ls -t /tmp/omarchy-theme-install-*.log | head -1 | xargs cat
```

### View last 50 lines of latest log
```bash
ls -t /tmp/omarchy-theme-install-*.log | head -1 | xargs tail -50
```

### Search for failures in latest log
```bash
ls -t /tmp/omarchy-theme-install-*.log | head -1 | xargs grep -i "error\|failed"
```

---

## Troubleshooting

### No themes discovered from either source
**Symptoms:**
```
[ERROR] No themes discovered from either source.
```

**Solutions:**
1. Check your internet connection
2. Verify the websites are accessible:
   ```bash
   curl -I https://omarchythemes.com
   curl -I https://learn.omacom.io/2/the-omarchy-manual/90/extra-themes
   ```
3. Check if the sites have changed structure (URLs may need updating)

---

### Themes found but none match my --only slugs
**Symptoms:**
```
[WARN] No matching themes found for: my-theme
```

**Solutions:**
1. Run `--list` to see available slug names
2. Check spelling and case (matching is case-insensitive but needs exact slug)
3. Use `grep` to find themes:
   ```bash
   omarchy-install-all-themes-combined.sh --list | grep -i "dracula"
   ```

---

### Theme installation failed
**Symptoms:**
```
[ERROR] [theme-slug] Installation failed (see log: /tmp/...)
```

**Solutions:**
1. Check the log file for detailed error messages:
   ```bash
   cat /tmp/omarchy-theme-install-*.log
   ```
2. Common causes:
   - **Private repo**: Repository requires GitHub authentication
   - **Removed repo**: Repository no longer exists on GitHub
   - **Already installed**: Theme is already installed (usually not an error)
   - **Permission denied**: Check `omarchy-theme-install` permissions

3. Try installing manually:
   ```bash
   ~/.local/share/omarchy/bin/omarchy-theme-install https://github.com/owner/repo
   ```

---

### No GitHub link found for theme
**Symptoms:**
```
[WARN] [theme-slug] No GitHub repository link found on theme page
```

**Causes:**
- Official themes maintained by Omarchy don't have separate repos
- These themes are built into Omarchy by default
- This is expected and not an error

---

### Getting rate limited or connection errors
**Symptoms:**
- Frequent "fetch failed" warnings
- Timeouts during scraping

**Solutions:**
1. Increase the delay between requests:
   ```bash
   DELAY=1.5 omarchy-install-all-themes-combined.sh --all
   ```

2. Reduce concurrent operations (already sequential in this script)

3. Check your network connection for instability

---

### Script exits with "Too many invalid attempts"
**Symptoms:**
```
[ERROR] Too many invalid attempts. Exiting.
```

**Cause:**
- Invalid choice entered 3 times at the mode prompt

**Solution:**
- Use command-line flags instead:
  ```bash
  omarchy-install-all-themes-combined.sh --all        # or
  omarchy-install-all-themes-combined.sh --interactive
  ```

---

### fzf not found, falling back to numbered menu
**Not an error**, but if you want fzf:
```bash
# Arch Linux
sudo pacman -S fzf

# macOS
brew install fzf

# Ubuntu/Debian
sudo apt install fzf
```

---

## How Deduplication Works

### Normalization Process

1. **Lowercase** the entire URL
2. **Remove** `www.` prefix
3. **Remove** `.git` suffix
4. **Remove** trailing slashes
5. **Extract** only `owner/repo` (first two path segments)
6. **Reconstruct** as `https://github.com/owner/repo`

### Examples

These URLs are all treated as the same theme:
```
https://github.com/User/Repo
https://github.com/user/repo
https://github.com/user/repo.git
https://github.com/user/repo/
https://GitHub.com/USER/REPO.git/
```

All become:
```
https://github.com/user/repo
```

### Slug Generation

Slugs are created as `owner-repo`:
- `https://github.com/catlee/omarchy-dracula-theme` → `catlee-omarchy-dracula-theme`
- `https://github.com/bjarneo/omarchy-ash-theme` → `bjarneo-omarchy-ash-theme`

---

## Comparison with Original Script

| Feature | Original (`omarchy-install-themes.sh`) | Combined (this script) |
|---------|---------------------------------------|------------------------|
| Sources | omarchythemes.com only | omarchythemes.com + learn.omacom.io |
| Deduplication | By theme slug | By normalized GitHub URL |
| Default delay | 0.3s | 0.5s (configurable) |
| Interactive prompt | Only if no flags | Same, with 3-choice menu |
| Theme count | ~70 | ~100-120 (after dedup) |
| Purpose | Stable, single-source | Temporary, comprehensive |

---

## Technical Details

### Script Flow

1. **Prerequisite Check**
   - Verify required commands exist
   - Check `omarchy-theme-install` is executable

2. **Argument Parsing**
   - Parse command-line flags
   - Set mode, options, environment overrides

3. **Fetch from omarchythemes.com**
   - Discover theme page links
   - Scrape each page for GitHub URL
   - Track as source: "omarchythemes.com"

4. **Fetch from learn.omacom.io**
   - Download page HTML
   - Extract all GitHub URLs via regex
   - Track as source: "learn.omacom.io"

5. **Combine and Deduplicate**
   - Normalize all GitHub URLs
   - Remove duplicates by normalized URL
   - Generate unique slugs (append `-2`, `-3` for collisions)

6. **Mode Resolution**
   - If no mode flag: prompt user
   - Execute chosen mode (list/all/only/interactive)

7. **Installation Loop**
   - For each selected theme:
     - Log progress `[X/Y]`
     - Run `omarchy-theme-install URL`
     - Track success/failure
     - Sleep `DELAY` seconds

8. **Summary Report**
   - Count successes and failures
   - List failed themes
   - Show log file location

---

## Notes and Warnings

### ⚠️ Temporary Script
This script is meant as a temporary solution to combine multiple theme sources. It may be superseded by:
- Official Omarchy theme discovery features
- Consolidated theme repositories
- Built-in theme management tools

### 💡 Rate Limiting
The script is configured to be respectful to servers:
- Default 0.5s delay between requests
- Retry logic with backoff
- Reasonable timeouts (10s connect, 30s max)

### 🔒 Private Repositories
Some themes may be private or require authentication:
- The script will report these as failures
- You can manually install them with GitHub credentials
- Use `gh auth login` for GitHub CLI authentication

### 🎨 Theme Quality
Not all themes are equally maintained:
- Some may be outdated or incompatible
- Some may conflict with each other
- Test themes before committing to daily use

### 📝 Logging
Logs contain:
- Full curl output
- Installation command results
- Timestamps for debugging
- Logs persist in `/tmp/` (may be cleared on reboot)

---

## Author

Created as a temporary solution to combine Omarchy theme sources from multiple locations.

---

## License

Free to use and modify. No warranty provided.

---

## See Also

- Original script: `omarchy-install-themes.sh`
- Original README: `README-omarchy-themes.md`
- Omarchy themes: https://omarchythemes.com
- Omarchy manual: https://learn.omacom.io
