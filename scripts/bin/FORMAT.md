# Script Format and Coding Standards

This document defines the standard format and conventions for all scripts in the ShadowHarvy toolkit to ensure consistency, maintainability, and professionalism.

## 📋 Table of Contents

1. [File Structure](#file-structure)
2. [Header Format](#header-format)
3. [Color Scheme](#color-scheme)
4. [Functions](#functions)
5. [Error Handling](#error-handling)
6. [User Interface](#user-interface)
7. [Dependencies](#dependencies)
8. [Documentation](#documentation)
9. [Examples](#examples)

---

## 📁 File Structure

### Script Organization
```bash
#!/bin/bash

# SCRIPT: script_name - Brief description
# DESCRIPTION: Detailed description of what the script does
# AUTHOR: ShadowHarvy
# CREATED: YYYY-MM-DD

# --- Set Colors for Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Global Variables ---
# Define any global variables here

# --- Cleanup Function ---
cleanup() {
    # Cleanup logic here
}

# --- Set trap for cleanup ---
trap cleanup EXIT

# --- Core Functions ---
# All helper functions here

# --- Main Function ---
main() {
    # Main script logic
}

# --- Execute Main Function ---
main "$@"
```

### File Permissions
- All scripts must be executable: `chmod +x script_name`
- Use `#!/bin/bash` shebang (consistent across toolkit)

---

## 📝 Header Format

### Required Header Block
```bash
#!/bin/bash

# SCRIPT: script_name - Brief one-line description
# DESCRIPTION: Detailed multi-line description explaining purpose,
#              functionality, and any important usage notes
# AUTHOR: ShadowHarvy
# CREATED: YYYY-MM-DD
```

### Header Guidelines
- **SCRIPT**: Use lowercase script name + brief description
- **DESCRIPTION**: Can span multiple lines for complex scripts
- **AUTHOR**: Always "ShadowHarvy"
- **CREATED**: Use ISO date format (YYYY-MM-DD)

---

## 🎨 Color Scheme

### Standard Color Variables
```bash
# --- Set Colors for Output ---
RED='\033[0;31m'      # Error messages, warnings
GREEN='\033[0;32m'    # Success messages, confirmations
YELLOW='\033[0;33m'   # Warnings, prompts, usage info
BLUE='\033[0;34m'     # Information, progress updates
NC='\033[0m'          # No Color - reset to default
```

### Color Usage Guidelines
- **RED**: Errors, critical warnings, failure messages
- **GREEN**: Success messages, completion confirmations
- **YELLOW**: Usage information, warnings, user prompts
- **BLUE**: Progress updates, informational messages
- **NC**: Always reset color after colored output

### Color Usage Examples
```bash
echo -e "${RED}Error: File not found${NC}"
echo -e "${GREEN}Successfully completed operation${NC}"
echo -e "${YELLOW}Warning: This will overwrite existing files${NC}"
echo -e "${BLUE}Processing file 1 of 10...${NC}"
```

---

## 🔧 Functions

### Required Functions

#### Usage Function
```bash
usage() {
    echo -e "${YELLOW}Usage: $0 [options] <arguments>${NC}"
    echo ""
    echo "Brief description of the script's purpose."
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo "  -v, --verbose Enable verbose output"
    echo ""
    echo "Examples:"
    echo "  $0 example_argument"
    echo "  $0 -v file.txt"
}
```

#### Dependency Check Function
```bash
check_dependencies() {
    local missing_deps=()
    local required_commands=("command1" "command2" "command3")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "${RED}  - $dep${NC}"
        done
        echo -e "${YELLOW}Please install missing dependencies and try again.${NC}"
        exit 1
    fi
}
```

#### Cleanup Function
```bash
cleanup() {
    # Remove temporary files
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        echo -e "${BLUE}Cleaning up temporary files...${NC}"
        rm -rf "$TEMP_DIR"
    fi
    
    # Kill background processes if any
    # Reset any system changes
}

# Always set cleanup trap
trap cleanup EXIT
```

### Function Guidelines
- Use descriptive function names with underscores: `process_file()`, `validate_input()`
- Include local variable declarations: `local variable_name="value"`
- Return meaningful exit codes: `return 0` for success, `return 1` for errors
- Add brief comments explaining complex logic

---

## 🚨 Error Handling

### Standard Error Patterns
```bash
# Check if file exists
if [ ! -f "$filename" ]; then
    echo -e "${RED}Error: File '$filename' does not exist${NC}"
    return 1
fi

# Check command success
if ! command_here; then
    echo -e "${RED}Error: Command failed${NC}"
    exit 1
fi

# Validate user input
if [[ ! "$input" =~ ^[a-zA-Z0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid input format${NC}"
    usage
    exit 1
fi
```

### Error Handling Guidelines
- Always check return codes for critical operations
- Provide clear, descriptive error messages
- Include the context of what failed
- Use appropriate exit codes (0 = success, 1 = general error)
- Clean up resources before exiting on errors

---

## 👤 User Interface

### Progress Indicators
```bash
echo -e "${BLUE}=== Script Name ===${NC}"
echo -e "${BLUE}Processing $# file(s)...${NC}"

# For loops with progress
for ((i=1; i<=${#files[@]}; i++)); do
    echo -e "${YELLOW}[$i/${#files[@]}] Processing: ${files[$i-1]}${NC}"
    # Processing logic here
done
```

### User Prompts
```bash
# Yes/No confirmation
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Operation cancelled${NC}"
    exit 0
fi

# Input validation
while true; do
    read -p "Enter device name: " DEVICE
    if validate_device "$DEVICE"; then
        break
    else
        echo -e "${RED}Invalid device. Please try again.${NC}"
    fi
done
```

### Summary Reports
```bash
# Final summary
echo -e "${BLUE}=== Operation Summary ===${NC}"
echo -e "${BLUE}Files processed: $PROCESSED_COUNT${NC}"
echo -e "${GREEN}Successfully completed: $SUCCESS_COUNT${NC}"

if [ $SUCCESS_COUNT -lt $PROCESSED_COUNT ]; then
    local failed_count=$((PROCESSED_COUNT - SUCCESS_COUNT))
    echo -e "${RED}Failed operations: $failed_count${NC}"
    exit 1
else
    echo -e "${GREEN}All operations completed successfully!${NC}"
    exit 0
fi
```

---

## 📦 Dependencies

### Dependency Management
```bash
check_dependencies() {
    local missing_deps=()
    local required_commands=("curl" "jq" "git")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "${RED}  - $dep${NC}"
        done
        echo -e "${YELLOW}Install with: sudo pacman -S ${missing_deps[*]}${NC}"
        exit 1
    fi
}
```

### Common Dependencies
- **Core tools**: `bash`, `coreutils` (cp, mv, rm, etc.)
- **Text processing**: `sed`, `awk`, `grep`
- **Network**: `curl`, `wget`
- **Archive**: `tar`, `gzip`, `bzip2`, `7z`
- **System**: `systemd`, `sudo`

---

## 📚 Documentation

### README Template Structure
```markdown
# script_name - Brief Description

Detailed description of the script's purpose and functionality.

## 🚀 Features
- List key features
- Highlight unique capabilities

## 📖 Usage
### Basic Usage
### Command Options

## 📋 Requirements
### System Requirements
### Dependencies
### Installation Commands

## 🛠️ Installation
### Quick Install
### System-wide Install

## 📚 Examples
### Example 1: Basic usage
### Example 2: Advanced usage

## 🚨 Common Issues
### Issue 1: Problem and Solution

## 🔍 Troubleshooting

## 🤝 Contributing

## 📄 License
Created by **ShadowHarvy**
```

### Inline Documentation
- Use `#` for single-line comments
- Use `# ---` for section separators
- Comment complex logic and non-obvious operations
- Include examples in comments for complex functions

---

## 📋 Examples

### Minimal Script Template
```bash
#!/bin/bash

# SCRIPT: example - Example script following format standards
# DESCRIPTION: This script demonstrates the standard format
# AUTHOR: ShadowHarvy
# CREATED: 2025-09-28

# --- Set Colors for Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Usage Function ---
usage() {
    echo -e "${YELLOW}Usage: $0 [options] <argument>${NC}"
    echo ""
    echo "Example script demonstrating format standards."
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 example_argument"
}

# --- Main Function ---
main() {
    # Check for help flag
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        exit 0
    fi
    
    # Check arguments
    if [ $# -eq 0 ]; then
        echo -e "${RED}Error: No arguments provided${NC}"
        usage
        exit 1
    fi
    
    echo -e "${BLUE}=== Example Script ===${NC}"
    echo -e "${GREEN}Processing: $1${NC}"
    
    # Main logic here
    
    echo -e "${GREEN}Script completed successfully!${NC}"
}

# --- Execute Main Function ---
main "$@"
```

---

## ✅ Checklist

Before considering a script complete, verify:

### Code Quality
- [ ] Follows header format
- [ ] Uses standard color scheme
- [ ] Includes proper error handling
- [ ] Has cleanup function with trap
- [ ] Implements dependency checking
- [ ] Follows naming conventions

### User Experience
- [ ] Has usage/help function
- [ ] Provides clear error messages
- [ ] Shows progress for long operations
- [ ] Includes confirmation prompts for destructive operations
- [ ] Displays summary information

### Documentation
- [ ] Has corresponding README.md
- [ ] Includes usage examples
- [ ] Documents all dependencies
- [ ] Explains installation process
- [ ] Provides troubleshooting guide

### Testing
- [ ] Handles missing arguments gracefully
- [ ] Validates user input
- [ ] Cleans up on exit
- [ ] Works with edge cases
- [ ] Provides meaningful exit codes

---

## 🔄 Version History

- **2025-09-28**: Initial format specification created
- Document covers all established patterns from existing toolkit
- Based on analysis of format, 7zz, arip, and img2iso scripts

---

*This format guide ensures consistency across the ShadowHarvy toolkit and maintains professional standards for all scripts.*