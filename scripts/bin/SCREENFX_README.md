# ScreenFX - Terminal Animation System

A cyberpunk-themed terminal animation system that displays your `screen.txt` with various animated effects when you open a new terminal session.

## Features

- **4 Animation Styles**: Static, Typewriter, Loader, and Glitch effects
- **Cyberpunk Color Theming**: Bright colors that match your Shadow Harvey aesthetic
- **Configurable**: Easily customize speed, style, and enable/disable
- **Smart Detection**: Automatically disabled in SSH sessions and subshells
- **Compatible**: Works with both Bash and Zsh
- **Oh My Posh Integration**: Plays nicely with your existing prompt setup

## Quick Start

The system is already integrated into your shell configurations and will run automatically when you open a new terminal.

### Test it manually:
```bash
# Source the script
source ~/bin/screenfx.sh

# Run with specific style
SCREENFX_STYLE=glitch screenfx::show ~/screen.txt

# Test all styles
~/bin/screenfx.sh --self-test
```

## Configuration

Control the animation with environment variables:

```bash
# Basic controls
export SCREENFX=1                    # Enable (1) or disable (0)
export SCREENFX_STYLE="random"       # random, static, typewriter, loader, glitch
export SCREENFX_SPEED="normal"       # fast, normal, slow

# Advanced
export SCREENFX_FORCE=1              # Force in SSH sessions
export SCREENFX_DEBUG=1              # Enable debug output
```

## Animation Styles

1. **static** - Instant colorized display
2. **typewriter** - Character-by-character typing effect
3. **loader** - Progress bar with gradual reveal
4. **glitch** - Matrix-style interference effects with stabilization

## File Structure

- **Script**: `~/bin/screenfx.sh` (synced with your repo)
- **Screen File**: `~/screen.txt` (your Shadow Harvey transmission)
- **Integration**: Added to both `~/.bashrc` and `~/.zshrc`

## Customization Examples

```bash
# Always use glitch effect at fast speed
export SCREENFX_STYLE="glitch"
export SCREENFX_SPEED="fast"

# Disable completely
export SCREENFX=0

# Different file
screenfx::show ~/my_custom_screen.txt
```

## Troubleshooting

### Animation not showing:
1. Check: `echo $SCREENFX` (should be 1)
2. Verify: `ls ~/screen.txt` (file exists)
3. Test: `source ~/bin/screenfx.sh && SCREENFX_STYLE=static screenfx::show ~/screen.txt`

### Colors not working:
- Check terminal: `tput colors` (should be 256)
- Test colors: `echo -e "\033[1;91mTest\033[0m"`

### Performance issues:
```bash
export SCREENFX_SPEED="fast"
# or disable:
export SCREENFX=0
```

## Repository Integration

This script is located in `~/bin/` so it syncs with your repository. Any changes you make will be tracked in git.

## Uninstall

1. Remove from shell configs:
   ```bash
   # Remove these lines from ~/.bashrc and ~/.zshrc:
   # ── Shadow-Harvey intro ──────────────────────────────
   # [[ -o interactive ]] && {
   #   source ~/bin/screenfx.sh
   #   screenfx::show "$HOME/screen.txt"
   # }
   ```

2. Delete script: `rm ~/bin/screenfx.sh ~/bin/SCREENFX_README.md`

---

*Enjoy your cyberpunk terminal! 🚀*