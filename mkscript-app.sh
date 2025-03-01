#!/usr/bin/env bash
#
# mkscript - Standalone script creator utility
# Creates new shell scripts with proper structure and permissions
#

set -euo pipefail

VERSION="1.0.0"

# Display help information
show_help() {
    cat << EOF
mkscript - Shell script generator utility v${VERSION}

USAGE:
    mkscript [OPTIONS] <script_name>

OPTIONS:
    -h, --help      Show this help message and exit
    -t, --template  Select template type (basic, advanced)
    -e, --editor    Specify editor to use (defaults to \$EDITOR or auto-detect)
    -n, --no-edit   Create script without opening in editor
    -f, --force     Overwrite existing file if it exists
    -v, --version   Show version information

EXAMPLES:
    mkscript myscript            # Creates myscript.sh with basic template
    mkscript -t advanced backup  # Creates backup.sh with advanced template
    mkscript -e vim process.sh   # Creates and opens with vim

TEMPLATES:
    basic     - Minimal script with error handling
    advanced  - Full-featured script with argument parsing, logging, etc.

NOTES:
    - If no extension is provided, .sh will be added automatically
    - Scripts are automatically made executable with chmod +x
EOF
    exit 0
}

# Display version information
show_version() {
    echo "mkscript version ${VERSION}"
    exit 0
}

# Create a basic template
create_basic_template() {
    local file=$1
    cat > "$file" << 'EOF'
#!/usr/bin/env bash

# Created: $(date)
# Description: 

# Exit on error, undefined vars, and pipe failures
set -euo pipefail

echo "Hello, World!"
EOF
}

# Create an advanced template
create_advanced_template() {
    local file=$1
    cat > "$file" << 'EOF'
#!/usr/bin/env bash

# Created: $(date)
# Description: 

# Exit on error, undefined vars, and pipe failures
set -euo pipefail

# Script variables
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Print usage information
usage() {
    cat << HELP
Usage: $SCRIPT_NAME [OPTIONS] <arguments>

Options:
  -h, --help      Show this help message and exit
  -v, --verbose   Enable verbose output

Arguments:
  arg1            Description of arg1

Example:
  $SCRIPT_NAME arg1
HELP
}

# Parse command line arguments
parse_args() {
    VERBOSE=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            *)
                ARG1="$1"
                shift
                ;;
        esac
    done
    
    # Validate arguments
    if [[ -z "${ARG1:-}" ]]; then
        echo "Error: Missing required argument"
        usage
        exit 1
    fi
}

# Log message with timestamp
log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
}

# Print debug messages if verbose mode is enabled
debug() {
    $VERBOSE && log "DEBUG" "$@" || true
}

# Print info messages
info() {
    log "INFO" "$@"
}

# Print error messages
error() {
    log "ERROR" "$@" >&2
}

# Cleanup function called on exit
cleanup() {
    # Add cleanup code here
    debug "Cleaning up..."
}

# Main script execution
main() {
    # Register cleanup function
    trap cleanup EXIT
    
    # Parse command line arguments
    parse_args "$@"
    
    # Script logic
    info "Starting script execution"
    debug "Argument: $ARG1"
    
    # Your code here
    
    info "Script execution completed"
}

# Call main function
main "$@"
EOF
}

# Get preferred editor
get_editor() {
    if [[ -n "${EDITOR_OVERRIDE:-}" ]]; then
        echo "$EDITOR_OVERRIDE"
        return
    fi

    if [[ -n "${EDITOR:-}" ]]; then
        echo "$EDITOR"
        return
    fi

    # Try to detect available editors
    for editor in nvim vim nano code subl gedit; do
        if command -v "$editor" &>/dev/null; then
            echo "$editor"
            return
        fi
    done

    # No editor found
    echo ""
}

# Main script execution
main() {
    # Default values
    local TEMPLATE="basic"
    local EDITOR_OVERRIDE=""
    local OPEN_EDITOR=true
    local FORCE=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                ;;
            -v|--version)
                show_version
                ;;
            -t|--template)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --template requires an argument"
                    exit 1
                fi
                TEMPLATE="$2"
                shift 2
                ;;
            -e|--editor)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --editor requires an argument"
                    exit 1
                fi
                EDITOR_OVERRIDE="$2"
                shift 2
                ;;
            -n|--no-edit)
                OPEN_EDITOR=false
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -*)
                echo "Error: Unknown option: $1"
                echo "Try 'mkscript --help' for more information."
                exit 1
                ;;
            *)
                # First non-option argument is the script name
                SCRIPT_NAME="$1"
                shift
                break
                ;;
        esac
    done
    
    # Check if script name was provided
    if [[ -z "${SCRIPT_NAME:-}" ]]; then
        echo "Error: No script name provided"
        echo "Try 'mkscript --help' for more information."
        exit 1
    fi
    
    # Add .sh extension if not provided
    if [[ "$SCRIPT_NAME" != *.* ]]; then
        SCRIPT_NAME="${SCRIPT_NAME}.sh"
    fi
    
    # Check if file already exists
    if [[ -f "$SCRIPT_NAME" && "$FORCE" != true ]]; then
        echo "Error: File '$SCRIPT_NAME' already exists."
        echo "Use --force to overwrite."
        exit 1
    fi
    
    # Create the script with the selected template
    case "$TEMPLATE" in
        basic)
            create_basic_template "$SCRIPT_NAME"
            ;;
        advanced)
            create_advanced_template "$SCRIPT_NAME"
            ;;
        *)
            echo "Error: Unknown template: $TEMPLATE"
            echo "Available templates: basic, advanced"
            exit 1
            ;;
    esac
    
    # Make the script executable
    chmod +x "$SCRIPT_NAME"
    
    echo "Created script: $SCRIPT_NAME"
    
    # Open in editor if requested
    if [[ "$OPEN_EDITOR" == true ]]; then
        EDITOR=$(get_editor)
        if [[ -n "$EDITOR" ]]; then
            echo "Opening with $EDITOR..."
            "$EDITOR" "$SCRIPT_NAME"
        else
            echo "No editor found. Script is ready for editing."
        fi
    fi
}

# Run the main function with all arguments
main "$@"
