#!/bin/bash

# Quick README generator for remaining apps
# Based on the template and existing analysis

# Apps that already have READMEs (skip these)
EXISTING_READMES=("dial" "zipp" "arip" "crack" "gitback" "eee")

# App data: name|short_description|main_features|usage_example|dependencies
APP_DATA=(
  "2048|2048 Puzzle Game|Classic sliding puzzle game in terminal|./2048|ncurses library"
  "7zz|7-Zip Compression Wrapper|Ultra-compression wrapper for 7z with progress tracking|./7zz file_or_directory|7z command from p7zip"
  "dialtest|Device Permissions Helper v2.1|Legacy device permissions tool with personalities|./dialtest -p wizard -d /dev/ttyACM0|Standard Unix utilities"
  "flipp|Flipper Zero CLI Connector|Connects to Flipper Zero serial CLI interface|./flipp|screen or minicom"
  "format|Interactive Disk Formatter|Safe disk formatting with confirmation and checks|sudo ./format|parted, filesystem tools"
  "gitdow|Repository Cloning Tool|Clones repositories from backup manifest with personalities|./gitdow -p glados|git, standard Unix utilities"
  "install|Package Installer from Lists|Installs packages from YAML/TXT files using yay|./install packages.yaml|yay, yamllint, yq"
  "install_f3|F3 Tool Installer|Builds and installs F3 from source with dependencies|./install_f3|git, make, build tools"
  "mkscript|Script Creation Utility|Creates executable scripts with editor launch and personalities|./mkscript -p sassy script_name|nvim or configured editor"
  "ripdvd|Simple DVD Ripper|Basic DVD ISO to MP4 conversion|./ripdvd input.iso output.mp4|ffmpeg"
  "ripdvdnew|Enhanced DVD Ripper|Improved DVD ISO to MP4 conversion with validation|./ripdvdnew input.iso output.mp4|ffmpeg"
  "stay|Minimal Do-Nothing Script|Placeholder script that does nothing|./stay|None (just exits)"
  "stormb|Terminal Storm Animation|Animated rainfall/storm effect with clouds and lightning|./stormb|Bash 4.0+, terminal colors"
  "storm.py|Advanced Storm Simulator|Sophisticated terminal weather animation with physics|python3 storm.py|Python 3.6+"
  "testusb|F3 USB Drive Tester|USB/storage device testing with personalities and F3 integration|./testusb -p dm|f3write, f3read, f3probe"
  "updateall|Universal System Updater|Updates all package managers and tools on the system|./updateall|pacman/apt/dnf, flatpak"
)

# Function to create README from template
create_readme() {
    local app_name="$1"
    local short_desc="$2"
    local features="$3"
    local usage="$4"
    local deps="$5"
    
    # Check if README already exists
    for existing in "${EXISTING_READMES[@]}"; do
        if [[ "$existing" == "$app_name" ]]; then
            echo "Skipping $app_name - README already exists"
            return
        fi
    done
    
    # Check if app has personalities
    local has_personalities=""
    if /home/me/app/"$app_name" -h 2>/dev/null | grep -q "persona\|personality"; then
        has_personalities="yes"
    fi
    
    local filename="/home/me/app/${app_name^^}_README.md"
    
    echo "Creating README for $app_name..."
    
    cat > "$filename" << EOF
# $app_name - $short_desc

$short_desc with automated functionality and user-friendly interface.

## 🚀 Features

- **Primary Function**: $features
- **User-Friendly**: Clear error messages and validation
- **Cross-Platform**: Works on Linux systems
$([ "$has_personalities" = "yes" ] && echo "- **Multiple Personalities**: Choose from wizard, GLaDOS, DM, sassy, or sarcastic modes")

$(if [ "$has_personalities" = "yes" ]; then
cat << 'PERSONALITIES'
## 🎭 Personalities

This application supports multiple personalities for a more engaging experience:

- **🧙‍♂️ Wizard**: Mystical and wise, speaks of artifacts and rituals
- **🤖 GLaDOS**: Sarcastic AI from Portal, treats you like a test subject
- **🏰 DM**: D&D dungeon master, frames everything as adventures
- **😤 Sassy**: Impatient but helpful, gets straight to the point
- **😏 Sarcastic**: Dry wit and barely contained frustration

Choose a personality with \`-p <persona>\` or let the system choose randomly.

PERSONALITIES
fi)

## 📖 Usage

### Basic Usage

\`\`\`bash
$usage
\`\`\`

### Command Options

See the application's built-in help for detailed options:
\`\`\`bash
$app_name -h
\`\`\`

## 📋 Requirements

### System Requirements
- **OS**: Linux (tested on Arch-based distributions)
- **Shell**: Bash 4.0+ (for shell scripts)

### Dependencies
- $deps

### Installation Commands
\`\`\`bash
# Install dependencies (example for Arch Linux)
# Adjust package names for your distribution
sudo pacman -S [required-packages]
\`\`\`

## 🛠️ Installation

### Quick Install
\`\`\`bash
# Copy to local bin directory
cp $app_name ~/.local/bin/
chmod +x ~/.local/bin/$app_name
\`\`\`

### System-wide Install
\`\`\`bash
# Copy to system bin (requires sudo)
sudo cp $app_name /usr/local/bin/
sudo chmod +x /usr/local/bin/$app_name
\`\`\`

## 📚 Examples

### Example 1: Basic Usage
\`\`\`bash
$usage
\`\`\`

$([ "$has_personalities" = "yes" ] && echo "### Example 2: With Personality
\`\`\`bash
$app_name -p wizard [arguments]
\`\`\`")

## 🚨 Common Issues

### Issue 1: Permission Denied
**Problem**: \`Permission denied\` when running
**Solution**: 
\`\`\`bash
chmod +x $app_name
\`\`\`

### Issue 2: Dependencies Missing
**Problem**: Required tools not found
**Solution**: Install the required dependencies using your package manager

## 🔍 Troubleshooting

Run with verbose output if available:
\`\`\`bash
$app_name -v [arguments]  # If supported
\`\`\`

## 🤝 Contributing

This script is part of a personal toolkit. If you find bugs or have suggestions:

1. Check the source code for inline comments
2. Test your changes thoroughly
3. Consider the impact on existing workflows

## 📄 License

Created by **ShadowHarvy**

This script is provided as-is for educational and personal use.

---

*Part of the ShadowHarvy toolkit - Automating the boring stuff since forever*
EOF

    echo "Created $filename"
}

# Process each app
for app_data in "${APP_DATA[@]}"; do
    IFS='|' read -r name short features usage deps <<< "$app_data"
    create_readme "$name" "$short" "$features" "$usage" "$deps"
done

echo
echo "README generation complete!"
echo "Created READMEs for apps that didn't already have them."
echo
echo "Summary of all READMEs in /home/me/app:"
ls -la /home/me/app/*README.md
