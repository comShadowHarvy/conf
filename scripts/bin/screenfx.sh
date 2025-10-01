#!/bin/bash
# =====================================================
# ScreenFX - Terminal Animation Driver
# For displaying screen.txt with cyberpunk effects
# =====================================================

# Configuration defaults
SCREENFX=${SCREENFX:-1}                           # 1=enabled, 0=disabled
SCREENFX_STYLE=${SCREENFX_STYLE:-"random"}        # random, static, typewriter, loader, glitch
SCREENFX_SPEED=${SCREENFX_SPEED:-"normal"}        # fast, normal, slow
SCREENFX_FORCE=${SCREENFX_FORCE:-0}               # Force in SSH sessions
SCREENFX_MODE=${SCREENFX_MODE:-"startup"}         # startup, prompt
SCREENFX_STYLES=(static typewriter loader glitch) # Available styles

# Color definitions (cyberpunk theme)
declare -A COLORS
COLORS[reset]='\033[0m'
COLORS[red]='\033[1;31m'
COLORS[green]='\033[1;32m'
COLORS[yellow]='\033[1;33m'
COLORS[blue]='\033[1;34m'
COLORS[magenta]='\033[1;35m'
COLORS[cyan]='\033[1;36m'
COLORS[white]='\033[1;37m'
COLORS[gray]='\033[1;90m'
COLORS[bright_red]='\033[1;91m'
COLORS[bright_green]='\033[1;92m'
COLORS[bright_yellow]='\033[1;93m'
COLORS[bright_blue]='\033[1;94m'
COLORS[bright_magenta]='\033[1;95m'
COLORS[bright_cyan]='\033[1;96m'
COLORS[bright_white]='\033[1;97m'

# Speed mappings
declare -A SPEEDS
SPEEDS[fast]=0.01
SPEEDS[normal]=0.03
SPEEDS[slow]=0.06

# Self-test mode (must be after function definitions)
_run_self_test() {
    echo "ScreenFX Self-Test:"
    echo "- tput colors: $(tput colors 2>/dev/null || echo "N/A")"
    echo "- Terminal: $TERM"
    echo "- Available styles: ${SCREENFX_STYLES[*]}"
    echo "Running quick test of each style..."
    echo "Testing..." > /tmp/screenfx_test.txt
    for style in "${SCREENFX_STYLES[@]}"; do
        echo "Testing $style:"
        SCREENFX_STYLE=$style SCREENFX_SPEED=fast screenfx::show /tmp/screenfx_test.txt
        echo
    done
    rm -f /tmp/screenfx_test.txt
    exit 0
}

# Utility functions
screenfx::log() {
    [[ -n "$SCREENFX_DEBUG" ]] && echo "[SCREENFX] $*" >&2
}

screenfx::get_terminal_size() {
    local cols rows
    if command -v tput &>/dev/null; then
        cols=$(tput cols 2>/dev/null || echo 80)
        rows=$(tput lines 2>/dev/null || echo 24)
    else
        cols=80
        rows=24
    fi
    echo "$cols $rows"
}

screenfx::hide_cursor() {
    command -v tput &>/dev/null && tput civis 2>/dev/null
}

screenfx::show_cursor() {
    command -v tput &>/dev/null && tput cnorm 2>/dev/null
}

screenfx::clear_screen() {
    command -v tput &>/dev/null && tput clear 2>/dev/null || clear
}

screenfx::get_sleep_time() {
    local speed="${SCREENFX_SPEED:-normal}"
    echo "${SPEEDS[$speed]:-${SPEEDS[normal]}}"
}

# Colorize text based on content patterns
screenfx::colorize_line() {
    local line="$1"
    local colored_line="$line"
    
    # Header status bar (bright cyan)
    if [[ "$line" == *"STATUS"*"HOST"*"KERNEL"*"UPTIME"* ]]; then
        colored_line="${COLORS[bright_cyan]}${line}${COLORS[reset]}"
    
    # Binary sequences (bright green)
    elif [[ "$line" == *"01010"* ]]; then
        colored_line="${COLORS[bright_green]}${line}${COLORS[reset]}"
    
    # Progress bar (bright yellow)
    elif [[ "$line" == *"#########"* ]]; then
        colored_line="${COLORS[bright_yellow]}${line}${COLORS[reset]}"
        colored_line="${colored_line/100%/${COLORS[bright_green]}100%${COLORS[reset]}}"
    
    # Shadow Harvey title (bright red)
    elif [[ "$line" == *"S H A D O W H A R V Y"* ]]; then
        colored_line="${COLORS[bright_red]}${line}${COLORS[reset]}"
    
    # Stealth mode (bright magenta)
    elif [[ "$line" == *"STEALTH_MODE"* ]]; then
        colored_line="${line/STEALTH_MODE/${COLORS[bright_magenta]}STEALTH_MODE${COLORS[reset]}}"
        colored_line="${colored_line/ENGAGED/${COLORS[bright_green]}ENGAGED${COLORS[reset]}}"
    
    # End transmission (gray)
    elif [[ "$line" == *"END_OF_TRANSMISSION"* ]]; then
        colored_line="${COLORS[gray]}${line}${COLORS[reset]}"
    
    # ASCII art and borders (cyan) - check for common characters
    elif [[ "$line" == *"|"* ]] || [[ "$line" == *"\\"* ]] || [[ "$line" == *"/"* ]] || [[ "$line" == *"["* ]] || [[ "$line" == *"]"* ]]; then
        colored_line="${COLORS[cyan]}${line}${COLORS[reset]}"
    
    # Default (keep original)
    else
        colored_line="$line"
    fi
    
    echo -e "$colored_line"
}

# Animation styles
screenfx::static() {
    local file="$1"
    local line
    
    screenfx::hide_cursor
    while IFS= read -r line; do
        screenfx::colorize_line "$line"
    done < "$file"
    screenfx::show_cursor
}

screenfx::typewriter() {
    local file="$1"
    local sleep_time
    sleep_time=$(screenfx::get_sleep_time)
    local line
    
    screenfx::hide_cursor
    while IFS= read -r line; do
        # Print the line character by character (without colors for smoother effect)
        for ((i=0; i<${#line}; i++)); do
            printf "%s" "${line:$i:1}"
            sleep "$sleep_time"
        done
        echo
    done < "$file"
    screenfx::show_cursor
}

screenfx::loader() {
    local file="$1"
    local sleep_time
    sleep_time=$(screenfx::get_sleep_time)
    local -a lines
    local total_lines=0
    
    # Read all lines into array
    while IFS= read -r line; do
        lines[total_lines]="$line"
        ((total_lines++))
    done < "$file"
    
    screenfx::hide_cursor
    
    # Show loading header
    echo -e "${COLORS[bright_cyan]}[INITIALIZING SHADOW HARVEY TERMINAL...]${COLORS[reset]}"
    echo -e "${COLORS[cyan]}Loading transmission data...${COLORS[reset]}"
    echo
    
    # Show progress and lines simultaneously
    for ((i=0; i<total_lines; i++)); do
        local progress=$((i * 100 / total_lines))
        local bar_length=50
        local filled=$((progress * bar_length / 100))
        local empty=$((bar_length - filled))
        
        # Update progress bar
        printf "\r${COLORS[yellow]}Progress: ["
        printf "%*s" $filled | tr ' ' '='
        printf "%*s" $empty
        printf "] %d%%${COLORS[reset]}" $progress
        
        sleep "$sleep_time"
        
        # Show the line after a brief pause
        if [[ $((i % 3)) -eq 0 ]]; then
            echo
            screenfx::colorize_line "${lines[i]}"
        fi
    done
    
    # Clear progress bar and show remaining lines
    echo -e "\r${COLORS[bright_green]}Progress: [$(printf "%*s" $bar_length | tr ' ' '=')] 100% COMPLETE${COLORS[reset]}"
    echo
    
    for ((i=0; i<total_lines; i++)); do
        screenfx::colorize_line "${lines[i]}"
    done
    
    screenfx::show_cursor
}

screenfx::glitch() {
    local file="$1"
    local sleep_time
    sleep_time=$(screenfx::get_sleep_time)
    local line
    
    screenfx::hide_cursor
    
    # Show glitch effect header
    echo -e "${COLORS[bright_magenta]}[SIGNAL INTERFERENCE DETECTED]${COLORS[reset]}"
    echo -e "${COLORS[red]}[ATTEMPTING TO STABILIZE...]${COLORS[reset]}"
    
    # Generate some glitch lines
    for ((i=0; i<5; i++)); do
        local glitch_line=""
        for ((j=0; j<60; j++)); do
            if [[ $((RANDOM % 2)) -eq 0 ]]; then
                glitch_line+="1"
            else
                glitch_line+="0"
            fi
        done
        echo -e "${COLORS[bright_magenta]}${glitch_line}${COLORS[reset]}"
        sleep 0.1
    done
    
    sleep 0.5
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_green]}[SIGNAL STABILIZED]${COLORS[reset]}"
    echo -e "${COLORS[cyan]}[DISPLAYING TRANSMISSION...]${COLORS[reset]}"
    echo
    
    # Show actual content with occasional glitches
    local line_count=0
    while IFS= read -r line; do
        if [[ $((RANDOM % 10)) -eq 0 ]] && [[ $line_count -gt 5 ]]; then
            # Random glitch
            local glitch=""
            for ((k=0; k<${#line}; k++)); do
                if [[ $((RANDOM % 5)) -eq 0 ]]; then
                    glitch+="${COLORS[bright_magenta]}█${COLORS[reset]}"
                else
                    glitch+="${line:$k:1}"
                fi
            done
            echo -e "$glitch"
            sleep 0.05
            # Show correct line
            printf "\r\033[K"  # Clear line
            screenfx::colorize_line "$line"
        else
            screenfx::colorize_line "$line"
        fi
        sleep "$sleep_time"
        ((line_count++))
    done < "$file"
    
    screenfx::show_cursor
}

# Main function
screenfx::show() {
    local file="${1:-$HOME/screen.txt}"
    
    # Check if enabled
    [[ "$SCREENFX" != "1" ]] && return 0
    
    screenfx::log "Starting screenfx::show with file: $file"
    
    # Check SSH session (disable by default)
    if [[ -n "$SSH_CONNECTION" ]] && [[ "$SCREENFX_FORCE" != "1" ]]; then
        screenfx::log "Skipping animation in SSH session (set SCREENFX_FORCE=1 to override)"
        return 0
    fi
    
    # Check if file exists
    if [[ ! -f "$file" ]]; then
        screenfx::log "File not found: $file"
        return 1
    fi
    
    # Choose style
    local style="$SCREENFX_STYLE"
    if [[ "$style" == "random" ]]; then
        local num_styles=${#SCREENFX_STYLES[@]}
        local random_index=$((RANDOM % num_styles))
        style="${SCREENFX_STYLES[$random_index]}"
    fi
    
    screenfx::log "Using style: $style"
    
    # Execute the chosen style
    case "$style" in
        static)
            screenfx::static "$file"
            ;;
        typewriter)
            screenfx::typewriter "$file"
            ;;
        loader)
            screenfx::loader "$file"
            ;;
        glitch)
            screenfx::glitch "$file"
            ;;
        *)
            screenfx::log "Unknown style: $style, using static"
            screenfx::static "$file"
            ;;
    esac
    
    # Add some space after animation
    echo
}

# Handle self-test mode after functions are defined
if [[ "$1" == "--self-test" ]]; then
    _run_self_test
fi

# Functions are automatically available when sourced in both bash and zsh
# No need to export in zsh (causes errors)
