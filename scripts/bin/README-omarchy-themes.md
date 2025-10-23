# Omarchy Theme Installer

A bash script that automatically scrapes [omarchythemes.com](https://omarchythemes.com) and installs community themes for Omarchy using `omarchy-theme-install`.

## What It Does

1. **Scrapes** the Omarchy themes website to discover all available themes
2. **Extracts** GitHub repository URLs from each theme's detail page
3. **Installs** themes using the `omarchy-theme-install` command
4. **Reports** progress and provides detailed logs

## Requirements

- **Omarchy** with `omarchy-theme-install` command
- Standard Unix tools: `curl`, `grep`, `sed`, `awk`, `sort`, `uniq`, `tr`
- Optional: `fzf` for enhanced interactive selection

## Installation

The script is located at `~/bin/omarchy-install-themes.sh`.

Make sure `~/bin` is in your PATH:
```bash
export PATH="$HOME/bin:$PATH"
```

## Usage

### List all available themes
```bash
omarchy-install-themes.sh --list
```

### Install all themes
```bash
omarchy-install-themes.sh --all
```

### Install specific themes
```bash
omarchy-install-themes.sh --only catppuccin,dracula,nord
```

### Interactive selection
```bash
omarchy-install-themes.sh --interactive
```

### Dry-run (test without installing)
```bash
omarchy-install-themes.sh --all --dry-run
```

## Options

- `-a, --all` - Install all discovered themes
- `-i, --interactive` - Choose themes interactively (default)
- `-o, --only SLUGS` - Install comma-separated list of theme slugs
- `-l, --list` - List discovered themes and exit
- `-n, --dry-run` - Show what would be done without installing
- `-d, --delay SEC` - Delay between requests (default: 0.3s)
- `--strict-github` - Only accept root GitHub repo links
- `-h, --help` - Show help message

## Examples

### Install all themes with slower rate limiting
```bash
DELAY=0.6 omarchy-install-themes.sh --all
```

### Install specific themes with dry-run
```bash
omarchy-install-themes.sh --only dracula,gruvbox,nord --dry-run
```

### Use custom log location
```bash
LOG_FILE=~/omarchy-themes.log omarchy-install-themes.sh --all
```

## Environment Variables

- `OMARCHY_INSTALLER` - Path to omarchy-theme-install (default: `~/.local/share/omarchy/bin/omarchy-theme-install`)
- `BASE_URL` - Themes website URL (default: `https://omarchythemes.com`)
- `DELAY` - Delay between requests in seconds (default: `0.3`)
- `USER_AGENT` - HTTP User-Agent string
- `LOG_FILE` - Log file path (default: `/tmp/omarchy-theme-install-TIMESTAMP.log`)
- `STRICT_GITHUB` - Set to `1` to only accept root repo links

## Features

- ✅ **Progress tracking** - Shows `[X/Y]` for each theme
- ✅ **Error handling** - Continues on failures, reports at end
- ✅ **Detailed logging** - Timestamped logs in `/tmp`
- ✅ **Rate limiting** - Configurable delay between requests
- ✅ **Interactive mode** - Uses `fzf` if available, falls back to numbered menu
- ✅ **Dry-run support** - Test without actually installing

## Expected Results

When running `--all`, the script will:
- Successfully install **~70+ community themes** with GitHub repositories
- Skip **~13 official themes** (catppuccin, gruvbox, nord, etc.) - these don't need installation as they're built-in
- Report **~7 private/unavailable repos** that require authentication

## Log Files

All operations are logged to timestamped files in `/tmp/`:
```bash
/tmp/omarchy-theme-install-YYYYMMDD-HHMMSS.log
```

View the last run's log:
```bash
ls -lt /tmp/omarchy-theme-install-*.log | head -1 | awk '{print $NF}' | xargs cat
```

## Troubleshooting

### No themes discovered
- Check your internet connection
- Verify the website is accessible: `curl -I https://omarchythemes.com`
- Try with custom BASE_URL if site structure changed

### Theme has no GitHub link
- Official themes (DHH/Omarchy maintained) don't have separate repos
- These are expected "failures" - they're already built into Omarchy

### Installation failed
- Check the log file for detailed error messages
- Some repos may be private or removed
- Try installing individually with: `omarchy-theme-install <GitHub_URL>`

### Rate limiting
- Increase delay if you're getting connection errors: `--delay 1.0`
- The default 0.3s delay is respectful to the server

## Notes

- The script is polite to the omarchythemes.com server with configurable delays
- Failed installations don't stop the process - all themes are attempted
- Log files persist in `/tmp` for debugging

## Author

Created with assistance from AI for managing Omarchy themes efficiently.

## License

Free to use and modify.
