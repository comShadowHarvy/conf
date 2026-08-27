# proton - Standalone Proton Runner & Priority Launcher

A smart, standalone launcher to execute Windows games and applications with Valve's Proton outside of Steam, automatically prioritizing the latest and best Proton versions available on your system.

## 🚀 Features

- **Automatic Priority Selection**: Chooses the best Proton runner automatically based on availability:
  1. **Proton-CachyOS (Latest)**
  2. **Proton-GE / GE-Proton (Latest)**
  3. **Proton Experimental (Latest)**
  4. **Other Proton Runners (Latest)** (e.g. DW-Proton, Proton 9, 8, etc.)
- **Multi-Location Discovery**: Scans Steam compatibility tools directories, Steam library `steamapps/common`, Heroic, Lutris, Bottles, Flatpak, and system paths.
- **Intelligent Path & Argument Parsing**: Supports standard execution, quoted paths, and multi-word unquoted paths (e.g., `proton /path/to/my game/game.exe --arg`).
- **Custom Prefix Management**: Uses a clean default prefix (`~/.local/share/proton/prefixes/default`) or customizable per-game prefixes with `--prefix` or `WINEPREFIX`.
- **Informative CLI**: Includes `--list` to view all discovered versions, `--version` to inspect the default, `--dry-run` to preview commands, and `--type` to force specific builds.

## 📖 Usage

### Basic Usage

```bash
# Run any Windows executable with auto-detected Proton
proton /path/to/game.exe

# Run with arguments
proton /path/to/game.exe --fullscreen --dx11

# Run with unquoted spaces in path
proton /home/me/Games/Epic Game/game.exe
```

### Windows Built-in Utilities

```bash
# Wine configuration GUI
proton winecfg

# Registry editor
proton regedit

# Windows command prompt
proton cmd.exe
```

### Command Options

```bash
proton [OPTIONS] <path_to_exe> [arguments...]
proton [OPTIONS] path to exe [arguments...]

Options:
  -l, --list             List all detected Proton versions and show the active default
  -p, --prefix <DIR>     Specify custom Wine/Proton prefix directory
                         (Default: ~/.local/share/proton/prefixes/default)
  -t, --type <TYPE>       Force a specific Proton tier:
                         cachyos | ge | experimental | other
  --proton <PATH>         Explicitly specify a Proton tool directory
  -d, --dry-run           Show command line, environment, and Proton path without running
  -v, --verb <VERB>       Set Proton verb (default: waitforexitandrun, options: run, runinprefix)
  -g, --gameid <ID>       Set custom Steam Game / App ID (default: 0)
  -h, --help              Show help message and exit
  -V, --version           Show currently selected Proton runner version
```

## 🎯 Selection Priority Hierarchy

When launching without `--type` or `--proton` flags, the script searches all installed runners and selects:

1. **Tier 1: Proton-CachyOS (Latest)**
   - Prioritizes CachyOS Proton builds (e.g., `Proton-CachyOS Latest-x86_64_v3`, `proton-cachyos-slr`).
2. **Tier 2: Proton-GE (Latest)**
   - Selects GloriousEggroll Proton builds (e.g., `Proton-GE Latest`, `GE-Proton11-5`).
3. **Tier 3: Proton Experimental (Latest)**
   - Selects Valve's `Proton - Experimental`.
4. **Tier 4: Other Compatibility Tools**
   - Selects any other installed Proton build (e.g., `DW-Proton Latest`, `Proton 9.0`, `Proton 8.0`).

## 📋 Environment Variables

| Variable | Description | Default |
|---|---|---|
| `STEAM_COMPAT_DATA_PATH` | Proton compatibility data / Wine prefix directory | `~/.local/share/proton/prefixes/default` |
| `PROTON_PREFIX` | Alias for prefix directory | Same as above |
| `WINEPREFIX` | Alias for prefix directory | Same as above |
| `PROTON_PATH` / `PROTONPATH` | Override Proton directory | Auto-detected |
| `PROTON_VERB` | Proton execution verb (`waitforexitandrun`, `run`) | `waitforexitandrun` |
| `STEAM_COMPAT_APP_ID` | Steam App ID | `0` |
| `PROTON_ENABLE_NVAPI` | Enable DLSS / NVAPI support | System default |
| `PROTON_ENABLE_WAYLAND` | Enable Wine Wayland driver | System default |
| `DXVK_ASYNC` | Enable DXVK async pipeline | System default |

## 📚 Examples

### Example 1: View Installed Versions
```bash
proton --list
```

### Example 2: Force Proton-GE
```bash
proton --type ge /path/to/game.exe
```

### Example 3: Dedicated Prefix for a Game
```bash
proton --prefix ~/.local/share/proton/prefixes/cyberpunk /games/Cyberpunk2077/bin/x64/Cyberpunk2077.exe
```

### Example 4: Dry Run Preview
```bash
proton --dry-run /path/to/game.exe --option
```

## 🛠️ Requirements

- **OS**: Linux (Arch / CachyOS / Fedora / Ubuntu / SteamOS)
- **Python**: 3.8+
- **Proton**: At least one Proton tool installed (via Steam, ProtonPlus, or system package manager)
