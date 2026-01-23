# Enhanced dial - The Permissions Facilitator v3.0

A delightfully enhanced device permissions helper that maintains all the personality and charm of the original while adding powerful new features.

## 🎭 What Makes dial Special

dial is not just another permissions script - it's an **entertainment experience** that solves a real problem. Choose from 5 distinct personalities:

- **👨‍🔬 Wizard**: Mystical and wise, speaks of artifacts and rituals
- **🤖 GLaDOS**: Sarcastic AI from Portal, treats you like a test subject  
- **🏰 DM**: D&D dungeon master, frames everything as guild membership
- **😤 Sassy**: Impatient but helpful, gets straight to the point
- **😏 Sarcastic**: Dry wit and barely contained frustration

## 🚀 Enhanced Features (v3.0)

### ✨ **Smart Device Discovery**
- Auto-discovers devices by category (serial, video, audio, USB, storage)
- Suggests alternatives when specified device isn't found
- Shows device ownership and group information

### 🔍 **Status & Information**
- Check current group memberships (`-c, --check`)
- List all available devices (`-l, --list`) 
- Scan for devices (`-s, --scan`)
- Verbose logging for debugging (`-v, --verbose`)

### 🛡️ **Safety Features**
- Dry-run mode shows what would happen (`-n, --dry-run`)
- Checks if user already has access (no unnecessary changes)
- Operation logging for audit trails
- Enhanced error handling with helpful suggestions

### 📱 **Modern CLI**
- Long and short options (`--help` and `-h`)
- Backward compatible with original usage
- Colored output with personality-specific messages
- Progressive enhancement (graceful degradation without colors)

## 📖 Usage Examples

### Quick Start (Legacy Compatible)
```bash
# Original usage still works perfectly
dial                    # Random personality, default device
```

### New Enhanced Usage
```bash
# Check what groups you're already in
dial -c
dial --check

# List all available devices  
dial -l
dial --list

# Scan for devices interactively
dial -s
dial --scan

# Dry run to see what would happen
dial -n -d /dev/ttyUSB0
dial --dry-run --device /dev/video0

# Verbose output for debugging
dial -v -p wizard -d /dev/ttyACM0

# Specific personality and device
dial -p glados -d /dev/video1
```

### Device Categories

The enhanced dial automatically categorizes devices:

- **Serial**: `/dev/ttyACM*`, `/dev/ttyUSB*`, `/dev/ttyS*` → `dialout`/`uucp` groups
- **Video**: `/dev/video*`, `/dev/dri/card*` → `video` group  
- **Audio**: `/dev/snd/*`, `/dev/audio*` → `audio` group
- **USB**: `/dev/bus/usb/*/*` → Various groups
- **Storage**: `/dev/sd*`, `/dev/nvme*` → `disk` group

## 🎯 Smart Error Handling

When dial can't find your device, it doesn't just fail - it helps:

```
Device '/dev/ttyACM0' not found. Did you forget to plug it in?

Available devices that might work:

  serial devices:
    /dev/ttyS0 (owner: root, group: uucp)
    /dev/ttyUSB0 (owner: root, group: dialout)
    ...

Usage examples:
  dial -d /dev/ttyUSB0    # Specific device  
  dial -s                 # Scan and choose
```

## 📊 Operation Logging

All operations are logged to `~/.local/share/dial/history.log`:

```
[2025-09-09 23:45:12] dry_run: device=/dev/ttyS0, group=uucp, status=simulated
[2025-09-09 23:46:33] check: device=/dev/video0, group=video, status=already_member
[2025-09-09 23:47:45] add_to_group: device=/dev/ttyUSB0, group=dialout, status=success
```

## 🎪 Personality Examples

### GLaDOS Mode
```
====================================================================
Aperture Science Permissions Facilitator
Mandated Acknowledgment: Conceived by ShadowHarvy  
====================================================================

Oh, look. Another test subject... I mean, *user*... requires access adjustments.

-> Right. Let's analyze your... *quaint*... security configuration for device '/dev/video0'.
   Device '/dev/video0' detected. Minimal compliance noted.
-> Executing primitive command to determine group ownership...
   Analysis complete. The group with access privileges is: 'video'.

Interesting. You're already in group 'video'. Did you forget, or are you just testing me?

No action required. The system is already perfectly configured. Unlike your judgment.
```

### Wizard Mode with Dry Run
```
====================================================================
The Oracle of Device Access
A spell by: ShadowHarvy
====================================================================

[DRY RUN MODE] - No actual changes will be made
The Oracle peers into possible futures without disturbing the present...

-> Let us consult the system's arcane energies for device '/dev/ttyS0'...
   The artifact '/dev/ttyS0' has been detected.
-> Scrying for the guardian group of the artifact...
   The guardian group is revealed to be 'uucp'.

[DRY RUN] Would add user 'me' to group 'uucp'

*** The Oracle has spoken. Go now, and create wonders. ***
```

## 🔧 Command Reference

```bash
dial [options]

Options:
  -p <persona>   Choose personality: wizard, glados, dm, sassy, sarcastic
  -d <device>    Specify device file (e.g., /dev/ttyACM0)  
  -s, --scan     Interactive device scanning and selection
  -c, --check    Show current group memberships and exit
  -l, --list     List all available devices and exit  
  -n, --dry-run  Show what would happen without making changes
  -v, --verbose  Enable verbose output for debugging
  -h, --help     Show this help message and exit
```

## 📁 Files Created

- `~/.local/share/dial/history.log` - Operation history
- `~/.config/dial/` - Future configuration directory

## 🔄 Migration from Original

The enhanced dial is **100% backward compatible**:

```bash
# These work exactly as before
dial                           # Default behavior unchanged
dial -p wizard                 # Same personality system
dial -d /dev/ttyUSB0          # Same device specification
dial -h                       # Same help (now enhanced)

# Plus all the new features
dial -c                       # NEW: Check groups  
dial -l                       # NEW: List devices
dial -n -d /dev/video0        # NEW: Dry run mode
dial --verbose --scan         # NEW: Enhanced discovery
```

## 🌟 What's Enhanced

| Feature | Original | Enhanced |
|---------|----------|----------|
| **Device Support** | Single device only | Multiple with auto-discovery |
| **Error Handling** | Basic "not found" | Suggestions + alternatives |
| **Status Checking** | None | Group membership + device info |
| **Safety** | Direct execution | Dry-run + validation |
| **CLI** | Basic getopts | Modern arg parsing + long options |
| **Logging** | None | Full operation history |
| **Discovery** | Manual only | Smart categorized scanning |

## 💡 Pro Tips

1. **Use `-c` first** to see what groups you're already in
2. **Use `-l` to explore** available devices on your system  
3. **Use `-n` to test** before making changes
4. **Use `-v` to debug** when something goes wrong
5. **Use `-s` to discover** devices you didn't know existed

---

*The enhanced dial maintains the whimsical personality-driven experience while adding the professional features you need for serious development work.*
