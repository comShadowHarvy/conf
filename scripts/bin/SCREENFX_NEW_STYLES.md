# ScreenFX - New Loading Screen Styles Guide

## 🎬 Available Animation Styles

Your `screenfx.sh` script now includes **21 different loading screen styles**:

### Original Styles
1. **`static`** - Simple colored output without animation
2. **`typewriter`** - Character-by-character typing effect
3. **`loader`** - Progress bar with content reveal
4. **`glitch`** - Digital interference and signal stabilization

### New Styles Added
5. **`matrix`** - The Matrix-style falling green characters with Japanese katakana
6. **`waves`** - Ocean wave-like animation with flowing data
7. **`bounce`** - Kinetic bouncing ball with content entrance effects
8. **`scan`** - Scanner line effect revealing content progressively
9. **`fade`** - Materialization effect from gray to full color
10. **`reveal`** - Hidden message decryption with block reveal
11. **`cascade`** - Waterfall-like data flow effect
12. **`hologram`** - Holographic projection with flicker effects

### Latest Styles Added (9 more!)
13. **`neon`** - Cyberpunk neon glow effect with intensity buildup
14. **`terminal`** - Retro terminal boot sequence with line numbers
15. **`hack`** - Realistic hacking simulation with progress bars
16. **`decrypt`** - Cryptographic decryption with key testing
17. **`spiral`** - Dimensional vortex with spiral data extraction
18. **`plasma`** - Ionized particle stream with plasma field
19. **`lightning`** - Electrical storm with lightning bolt effects
20. **`explode`** - Countdown explosion with data reassembly
21. **`radar`** - Military radar sweep with target acquisition

## 🎮 How to Use

### Environment Variables
- `SCREENFX_STYLE` - Choose specific style or "random"
- `SCREENFX_SPEED` - Set to "fast", "normal", or "slow"
- `SCREENFX_FORCE` - Set to "1" to force animations in SSH sessions

### Examples

```bash
# Use a specific style
SCREENFX_STYLE=matrix screenfx::show "$HOME/screen.txt"

# Use random style with fast speed
SCREENFX_STYLE=random SCREENFX_SPEED=fast screenfx::show

# Force hologram style even in SSH
SCREENFX_STYLE=hologram SCREENFX_FORCE=1 screenfx::show

# Test all styles quickly
./screenfx.sh --self-test
```

### Modify Your Bashrc
To change the default loading screen style, edit your `~/.bashrc` and modify the Shadow-Harvey intro section:

```bash
# ── Shadow-Harvey intro ──────────────────────────────
if [[ $- == *i* ]]; then               # only interactive shells
  source ~/bin/screenfx.sh
  # Set your preferred style here
  export SCREENFX_STYLE="matrix"        # or waves, hologram, cascade, etc.
  export SCREENFX_SPEED="normal"        # fast, normal, slow
  screenfx::show "$HOME/screen.txt"
fi
```

## 🌟 Style Descriptions

**Matrix** - Full cyberpunk experience with falling Japanese characters, neural link establishment, and character-by-character reveal with matrix overlay.

**Waves** - Sine wave mathematics create flowing ocean-like patterns, with content displayed in wave-timed intervals using blue/cyan color schemes.

**Bounce** - Animated bouncing ball followed by content that "bounces" in from the side with kinetic energy effects.

**Scan** - Red scanning line moves down the screen progressively revealing each line with highlighting effects.

**Fade** - Three-stage materialization from gray to white to full color, simulating emergence from void.

**Reveal** - Content appears as blocks initially, then reveals character-by-character like decrypting a hidden message.

**Cascade** - Waterfall-like effect where characters appear in diagonal waves across the screen with cyan highlights.

**Hologram** - Realistic holographic projection with flickering, distortion, and stabilization effects using cyan tinting.

**Neon** - Multi-pass neon glow effect that builds intensity from dim magenta to bright white peak, simulating cyberpunk neon signs.

**Terminal** - Classic retro terminal experience with boot sequence messages, status indicators, and numbered line output.

**Hack** - Complete hacking simulation with vulnerability scanning, exploit progress bars, and scrambled-to-clear text reveals.

**Decrypt** - Cryptographic warfare with multiple encryption algorithm testing, hex keys, and encrypted-to-plaintext transformation.

**Spiral** - Dimensional vortex generator with rotating spiral patterns and center-out data extraction order.

**Plasma** - High-energy plasma field with ionized particle streams using mathematical wave patterns and multi-color gradients.

**Lightning** - Electrical storm simulation with multiple lightning strikes, screen flashes, and electrical flicker effects on content.

**Explode** - Dramatic countdown explosion with expanding blast radius, debris scatter, and data fragment reassembly.

**Radar** - Military radar system with rotating sweep line, concentric circles, target blips, and contact detection alerts.

## 🎨 Customization

Each style uses the existing color scheme and can be modified in the `screenfx.sh` file. All animations respect:
- Terminal size detection
- Color capability checking  
- Speed configuration
- SSH session detection
- Cursor hiding/showing
- Proper color reset

Your original content coloring patterns (status bars, binary sequences, progress bars, etc.) are preserved across all animation styles.