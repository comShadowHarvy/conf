# 🎬 Complete ScreenFX Styles Collection - All 21 Animation Modes

## 🚀 Your Enhanced Loading Screen Arsenal

Your `screenfx.sh` script now has **21 unique loading screen animations**! Here's the complete collection:

### 🏠 Original Core Styles (1-4)
1. **`static`** - Clean, instant colorized display
2. **`typewriter`** - Classic character-by-character typing
3. **`loader`** - Progress bar with synchronized content reveal
4. **`glitch`** - Digital interference with signal stabilization

### ⚡ First Expansion Pack (5-12)
5. **`matrix`** - The Matrix rain with Japanese katakana
6. **`waves`** - Mathematical sine wave ocean flow
7. **`bounce`** - Kinetic physics with bouncing animations  
8. **`scan`** - Progressive red scanning line reveal
9. **`fade`** - Three-stage materialization from void
10. **`reveal`** - Encrypted blocks to plaintext decryption
11. **`cascade`** - Waterfall data flow with diagonal waves
12. **`hologram`** - Flickering projection with stabilization

### 🔥 Latest Mega Pack (13-21)
13. **`neon`** - Cyberpunk neon signs with intensity buildup
14. **`terminal`** - Retro terminal boot with status messages
15. **`hack`** - Full hacking simulation with exploits
16. **`decrypt`** - Multi-algorithm cryptographic warfare
17. **`spiral`** - Dimensional vortex with center-out extraction
18. **`plasma`** - High-energy ionized particle streams
19. **`lightning`** - Electrical storm with multiple strikes
20. **`explode`** - Countdown detonation with reassembly
21. **`radar`** - Military radar sweep with target acquisition

## ⚙️ Usage Examples

### Set a Specific Style in Your `.bashrc`
```bash
# ── Shadow-Harvey intro ──────────────────────────────
if [[ $- == *i* ]]; then
  source ~/bin/screenfx.sh
  export SCREENFX_STYLE="explode"     # Pick your favorite!
  export SCREENFX_SPEED="normal"      # fast, normal, slow
  screenfx::show "$HOME/screen.txt"
fi
```

### Try Different Styles Quickly
```bash
# Test specific styles
SCREENFX_STYLE=lightning screenfx::show "$HOME/screen.txt"
SCREENFX_STYLE=plasma SCREENFX_SPEED=fast screenfx::show
SCREENFX_STYLE=radar screenfx::show

# Let random pick for you
SCREENFX_STYLE=random screenfx::show

# Test all styles at once
./screenfx.sh --self-test
```

### Override for Special Sessions
```bash
# Force dramatic styles even in SSH
SCREENFX_STYLE=explode SCREENFX_FORCE=1 screenfx::show

# Quick and quiet
SCREENFX_STYLE=static SCREENFX_SPEED=fast screenfx::show
```

## 🎯 Style Categories by Mood

### 🔥 **High Energy** (dramatic, intense)
- `explode` - Countdown explosion
- `lightning` - Electrical storm 
- `hack` - Cyber warfare
- `plasma` - Energy fields

### 🌊 **Flowing** (smooth, organic)
- `waves` - Ocean mathematics
- `cascade` - Waterfall data
- `spiral` - Vortex extraction
- `fade` - Gradual materialization

### 🤖 **Cyberpunk** (futuristic, tech)
- `matrix` - The classic
- `hologram` - Projection effects
- `neon` - Glowing signs
- `terminal` - Retro computing

### 🔍 **Technical** (analytical, precise)
- `scan` - Progressive analysis  
- `radar` - Target acquisition
- `decrypt` - Code breaking
- `reveal` - Data uncovering

### 🎮 **Classic** (reliable, clean)
- `static` - Instant display
- `typewriter` - Character typing
- `loader` - Progress tracking
- `glitch` - Digital artifacts

### ⚡ **Kinetic** (movement, physics)
- `bounce` - Physics simulation
- `spiral` - Rotational dynamics

## 🎨 Technical Features

All 21 styles support:
- **3 Speed Settings**: fast, normal, slow
- **Color Management**: Full cyberpunk palette
- **Terminal Detection**: Automatic size adjustment  
- **SSH Compatibility**: Disable/force modes
- **Content Preservation**: Your existing color patterns
- **Cursor Management**: Professional hide/show
- **Random Selection**: Different style each session
- **Unicode Support**: Full character set including symbols

## 📊 Performance & Compatibility

- **Tested on**: Arch Linux, Bash 5.3.3
- **Dependencies**: Standard terminal utilities (tput, bc for advanced math)
- **Memory**: Lightweight, minimal resource usage  
- **Speed**: Optimized animations with configurable timing
- **Fallbacks**: Graceful degradation on limited terminals

## 🎭 Animation Showcase

Each style creates a unique experience:

- **Matrix**: Green katakana rain → Neural link → Character reveal
- **Lightning**: Storm warnings → Multiple strikes → Electrical flickers  
- **Explode**: 3-2-1 countdown → Expanding blast → Fragment reassembly
- **Plasma**: Field generation → Particle streams → Energy materialization
- **Radar**: System online → Rotating sweep → Target identification
- **Hack**: Vulnerability scan → Progress bars → Data decryption
- **Neon**: Dim glow → Intensity buildup → Peak brightness
- **Spiral**: Vortex generation → Rotation patterns → Dimensional extraction

---

**Your terminal has never been more exciting!** 🎆

With 21 different loading animations, every new shell session becomes an experience. Whether you want the classic Matrix rain, explosive countdowns, electrical storms, or smooth ocean waves - there's a perfect animation for every mood and moment.

*Embrace the cyberpunk aesthetic and make your terminal the envy of every developer! 🚀*