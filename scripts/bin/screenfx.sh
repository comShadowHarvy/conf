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
SCREENFX_STYLES=(static typewriter loader glitch matrix waves bounce scan fade reveal cascade hologram neon terminal hack decrypt spiral plasma lightning explode radar binary_rain quantum virus neural blackhole) # Available styles

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

screenfx::matrix() {
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
    screenfx::clear_screen
    
    # Matrix rain effect
    local term_size
    term_size=$(screenfx::get_terminal_size)
    local cols=${term_size%% *}
    
    echo -e "${COLORS[bright_green]}[MATRIX PROTOCOL INITIATED]${COLORS[reset]}"
    echo -e "${COLORS[green]}[DECRYPTING NEURAL PATHWAYS...]${COLORS[reset]}"
    echo
    
    # Generate falling matrix characters
    for ((frame=0; frame<8; frame++)); do
        for ((row=0; row<3; row++)); do
            local matrix_line=""
            for ((col=0; col<cols-1; col++)); do
                local char_pool="01アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン"
                local rand_char=${char_pool:$((RANDOM % ${#char_pool})):1}
                if [[ $((RANDOM % 3)) -eq 0 ]]; then
                    matrix_line+="${COLORS[bright_green]}${rand_char}${COLORS[reset]}"
                else
                    matrix_line+="${COLORS[green]}${rand_char}${COLORS[reset]}"
                fi
            done
            echo -e "$matrix_line"
        done
        sleep 0.15
        if [[ $frame -lt 7 ]]; then
            printf "\033[3A"  # Move cursor up 3 lines
        fi
    done
    
    sleep 0.5
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_cyan]}[NEURAL LINK ESTABLISHED]${COLORS[reset]}"
    echo -e "${COLORS[cyan]}[DOWNLOADING CONSCIOUSNESS...]${COLORS[reset]}"
    echo
    
    # Show content line by line with matrix-style reveal
    for ((i=0; i<total_lines; i++)); do
        local line="${lines[i]}"
        local revealed_line=""
        
        # Reveal each character with brief matrix overlay
        for ((j=0; j<${#line}; j++)); do
            local char="${line:$j:1}"
            if [[ $((RANDOM % 4)) -eq 0 ]]; then
                printf "${COLORS[green]}%s${COLORS[reset]}" "${char_pool:$((RANDOM % ${#char_pool})):1}"
                sleep 0.01
                printf "\b"
            fi
            printf "%s" "$char"
        done
        echo
        sleep "$sleep_time"
    done
    
    echo
    echo -e "${COLORS[bright_green]}[DOWNLOAD COMPLETE - WELCOME TO THE MATRIX]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::waves() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_blue]}[WAVE FORM ANALYSIS INITIATED]${COLORS[reset]}"
    echo -e "${COLORS[cyan]}[SYNCHRONIZING FREQUENCIES...]${COLORS[reset]}"
    echo
    
    # Generate wave animation
    local term_size
    term_size=$(screenfx::get_terminal_size)
    local cols=${term_size%% *}
    
    for ((wave=0; wave<6; wave++)); do
        local wave_line=""
        for ((pos=0; pos<cols-1; pos++)); do
            local height=$(echo "scale=2; s(($pos + $wave * 10) * 3.14159 / 20)" | bc -l 2>/dev/null || echo "0")
            local wave_char
            if (( $(echo "$height > 0.5" | bc -l 2>/dev/null || echo "0") )); then
                wave_char="${COLORS[bright_cyan]}~${COLORS[reset]}"
            elif (( $(echo "$height > 0" | bc -l 2>/dev/null || echo "0") )); then
                wave_char="${COLORS[cyan]}-${COLORS[reset]}"
            elif (( $(echo "$height > -0.5" | bc -l 2>/dev/null || echo "0") )); then
                wave_char="${COLORS[blue]}_${COLORS[reset]}"
            else
                wave_char="${COLORS[bright_blue]}~${COLORS[reset]}"
            fi
            wave_line+="$wave_char"
        done
        echo -e "$wave_line"
        sleep 0.1
        if [[ $wave -lt 5 ]]; then
            printf "\033[1A"  # Move cursor up 1 line
        fi
    done
    
    sleep 0.5
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_cyan]}[FREQUENCY LOCKED]${COLORS[reset]}"
    echo -e "${COLORS[cyan]}[TRANSMITTING DATA...]${COLORS[reset]}"
    echo
    
    # Show content with wave effect
    for ((i=0; i<total_lines; i++)); do
        local line="${lines[i]}"
        
        # Add wave-like delay and coloring
        if [[ $((i % 3)) -eq 0 ]]; then
            echo -e "${COLORS[bright_cyan]}$(screenfx::colorize_line "$line")${COLORS[reset]}"
        elif [[ $((i % 3)) -eq 1 ]]; then
            echo -e "${COLORS[cyan]}$(screenfx::colorize_line "$line")${COLORS[reset]}"
        else
            screenfx::colorize_line "$line"
        fi
        
        # Wave-like timing
        local wave_sleep=$(echo "$sleep_time + 0.01 * s($i * 3.14159 / 5)" | bc -l 2>/dev/null || echo "$sleep_time")
        sleep "$wave_sleep"
    done
    
    echo
    echo -e "${COLORS[bright_blue]}[TRANSMISSION COMPLETE - RIDING THE WAVES]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::bounce() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_yellow]}[BOUNCE PROTOCOL ACTIVATED]${COLORS[reset]}"
    echo -e "${COLORS[yellow]}[INITIALIZING KINETIC DISPLAY...]${COLORS[reset]}"
    echo
    
    # Create bouncing ball animation
    local ball="${COLORS[bright_red]}●${COLORS[reset]}"
    local term_size
    term_size=$(screenfx::get_terminal_size)
    local cols=${term_size%% *}
    local max_pos=$((cols - 5))
    
    for ((bounce=0; bounce<4; bounce++)); do
        # Ball bounces left to right
        for ((pos=0; pos<=max_pos; pos+=3)); do
            printf "\r%*s%s" $pos "" "$ball"
            sleep 0.03
        done
        # Ball bounces right to left
        for ((pos=max_pos; pos>=0; pos-=3)); do
            printf "\r%*s%s" $pos "" "$ball"
            sleep 0.03
        done
    done
    
    echo
    echo
    
    echo -e "${COLORS[bright_green]}[KINETIC ENERGY STABILIZED]${COLORS[reset]}"
    echo -e "${COLORS[green]}[DISPLAYING BOUNCED DATA...]${COLORS[reset]}"
    echo
    
    # Show content with bouncing effect
    for ((i=0; i<total_lines; i++)); do
        local line="${lines[i]}"
        
        # Create bouncing entrance effect
        local spaces=$((20 - i % 20))
        if [[ $spaces -lt 0 ]]; then spaces=0; fi
        
        # Bounce in from the side
        for ((j=spaces; j>=0; j-=2)); do
            printf "\r%*s%s" $j "" "$(screenfx::colorize_line "$line")"
            sleep 0.01
        done
        echo
        
        sleep "$sleep_time"
    done
    
    echo
    echo -e "${COLORS[bright_yellow]}[BOUNCE COMPLETE - ALL DATA LANDED SAFELY]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::scan() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_red]}[SCANNER PROTOCOL INITIATED]${COLORS[reset]}"
    echo -e "${COLORS[red]}[PERFORMING DEEP SCAN...]${COLORS[reset]}"
    echo
    
    # Create scanning line effect
    local term_size
    term_size=$(screenfx::get_terminal_size)
    local cols=${term_size%% *}
    local scan_line="${COLORS[bright_red]}$(printf "%*s" $((cols-1)) | tr ' ' '=')${COLORS[reset]}"
    
    # Show scanning animation
    for ((scan=0; scan<total_lines+3; scan++)); do
        screenfx::clear_screen
        echo -e "${COLORS[bright_red]}[SCANNING... $(((scan * 100) / (total_lines + 2)))%]${COLORS[reset]}"
        echo
        
        # Show scanned lines
        for ((i=0; i<scan && i<total_lines; i++)); do
            if [[ $((scan - i)) -eq 1 ]]; then
                echo -e "${COLORS[bright_yellow]}$(screenfx::colorize_line "${lines[i]}")${COLORS[reset]}"
            else
                screenfx::colorize_line "${lines[i]}"
            fi
        done
        
        # Show scanning line
        if [[ $scan -lt $total_lines ]]; then
            echo -e "$scan_line"
        fi
        
        sleep 0.1
    done
    
    echo
    echo -e "${COLORS[bright_green]}[SCAN COMPLETE - ALL DATA ACQUIRED]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::fade() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[gray]}[FADE PROTOCOL INITIATED]${COLORS[reset]}"
    echo -e "${COLORS[gray]}[MATERIALIZING FROM THE VOID...]${COLORS[reset]}"
    echo
    
    # Show content with fading effect (gray to full color)
    local fade_colors=("${COLORS[gray]}" "${COLORS[white]}" "")
    
    for fade_level in 0 1 2; do
        screenfx::clear_screen
        echo -e "${COLORS[bright_white]}[MATERIALIZATION: $(((fade_level + 1) * 33))%]${COLORS[reset]}"
        echo
        
        for ((i=0; i<total_lines; i++)); do
            if [[ $fade_level -eq 2 ]]; then
                screenfx::colorize_line "${lines[i]}"
            else
                echo -e "${fade_colors[fade_level]}${lines[i]}${COLORS[reset]}"
            fi
        done
        
        sleep 0.8
    done
    
    echo
    echo -e "${COLORS[bright_white]}[FADE COMPLETE - FULLY MATERIALIZED]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::reveal() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_magenta]}[REVEAL PROTOCOL INITIATED]${COLORS[reset]}"
    echo -e "${COLORS[magenta]}[DECIPHERING HIDDEN MESSAGES...]${COLORS[reset]}"
    echo
    
    # Show all lines as blocks first, then reveal
    for ((i=0; i<total_lines; i++)); do
        local line="${lines[i]}"
        local block_line=""
        for ((j=0; j<${#line}; j++)); do
            if [[ "${line:$j:1}" == " " ]]; then
                block_line+=" "
            else
                block_line+="${COLORS[gray]}█${COLORS[reset]}"
            fi
        done
        echo -e "$block_line"
    done
    
    sleep 1
    
    # Reveal character by character - simplified approach
    for ((i=0; i<total_lines; i++)); do
        local line="${lines[i]}"
        # Move cursor to the specific line we want to reveal
        printf "\033[%d;1H" $((i + 4))  # +4 to account for header lines
        
        # Reveal each character in place
        for ((j=0; j<${#line}; j++)); do
            local char="${line:$j:1}"
            printf "\033[%d;%dH" $((i + 4)) $((j + 1))  # Position cursor exactly
            printf "%s" "$char"
            sleep 0.01
        done
    done
    
    # Move cursor to end
    printf "\033[%d;1H" $((total_lines + 4))
    
    # Re-colorize all lines
    printf "\033[%dA" $total_lines  # Move to top
    for ((i=0; i<total_lines; i++)); do
        printf "\033[K"  # Clear line
        screenfx::colorize_line "${lines[i]}"
    done
    
    echo
    echo -e "${COLORS[bright_magenta]}[REVEAL COMPLETE - SECRETS EXPOSED]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::cascade() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_blue]}[CASCADE PROTOCOL INITIATED]${COLORS[reset]}"
    echo -e "${COLORS[blue]}[DATA FLOWING LIKE WATERFALLS...]${COLORS[reset]}"
    echo
    
    # Show content cascading down
    local max_width=0
    for ((i=0; i<total_lines; i++)); do
        if [[ ${#lines[i]} -gt $max_width ]]; then
            max_width=${#lines[i]}
        fi
    done
    
    # Create cascading effect
    for ((wave=0; wave<max_width+10; wave++)); do
        screenfx::clear_screen
        echo -e "${COLORS[bright_blue]}[CASCADE WAVE: $wave]${COLORS[reset]}"
        echo
        
        for ((i=0; i<total_lines; i++)); do
            local line="${lines[i]}"
            local cascade_line=""
            
            for ((j=0; j<${#line}; j++)); do
                local char="${line:$j:1}"
                local reveal_time=$((j + i * 2))
                
                if [[ $wave -ge $reveal_time ]]; then
                    if [[ $((wave - reveal_time)) -lt 3 ]]; then
                        cascade_line+="${COLORS[bright_cyan]}${char}${COLORS[reset]}"
                    else
                        cascade_line+="$char"
                    fi
                else
                    cascade_line+=" "
                fi
            done
            
            if [[ -n "$cascade_line" && "$cascade_line" != *[^[:space:]]* ]]; then
                echo
            else
                echo -e "$cascade_line"
            fi
        done
        
        sleep 0.05
    done
    
    # Final colorized display
    screenfx::clear_screen
    echo -e "${COLORS[bright_blue]}[CASCADE COMPLETE]${COLORS[reset]}"
    echo
    
    for ((i=0; i<total_lines; i++)); do
        screenfx::colorize_line "${lines[i]}"
    done
    
    echo
    echo -e "${COLORS[bright_blue]}[DATA CASCADE COMPLETE - FLOW STABILIZED]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::hologram() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_cyan]}[HOLOGRAM PROJECTOR INITIATED]${COLORS[reset]}"
    echo -e "${COLORS[cyan]}[CALIBRATING PHOTONIC MATRIX...]${COLORS[reset]}"
    echo
    
    # Create hologram flicker effect
    for ((flicker=0; flicker<5; flicker++)); do
        if [[ $((flicker % 2)) -eq 0 ]]; then
            for ((i=0; i<total_lines; i++)); do
                local line="${lines[i]}"
                local holo_line=""
                
                for ((j=0; j<${#line}; j++)); do
                    local char="${line:$j:1}"
                    if [[ $((RANDOM % 4)) -eq 0 ]]; then
                        holo_line+="${COLORS[bright_cyan]}${char}${COLORS[reset]}"
                    elif [[ $((RANDOM % 3)) -eq 0 ]]; then
                        holo_line+="${COLORS[cyan]}${char}${COLORS[reset]}"
                    else
                        holo_line+="$char"
                    fi
                done
                echo -e "$holo_line"
            done
        else
            # Flicker - show distorted version
            for ((i=0; i<total_lines; i++)); do
                local line="${lines[i]}"
                local distort_line=""
                
                for ((j=0; j<${#line}; j++)); do
                    local char="${line:$j:1}"
                    if [[ $((RANDOM % 6)) -eq 0 ]]; then
                        distort_line+="${COLORS[bright_white]}░${COLORS[reset]}"
                    elif [[ $((RANDOM % 8)) -eq 0 ]]; then
                        distort_line+=" "
                    else
                        distort_line+="${COLORS[gray]}${char}${COLORS[reset]}"
                    fi
                done
                echo -e "$distort_line"
            done
        fi
        
        sleep 0.3
        
        if [[ $flicker -lt 4 ]]; then
            printf "\033[%dA" $total_lines  # Move cursor back up
        fi
    done
    
    sleep 0.5
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_cyan]}[HOLOGRAM STABILIZED]${COLORS[reset]}"
    echo -e "${COLORS[cyan]}[PROJECTION ONLINE...]${COLORS[reset]}"
    echo
    
    # Show final stable hologram with cyan tint
    for ((i=0; i<total_lines; i++)); do
        local line="${lines[i]}"
        echo -e "${COLORS[cyan]}$(screenfx::colorize_line "$line")${COLORS[reset]}"
        sleep "$sleep_time"
    done
    
    echo
    echo -e "${COLORS[bright_cyan]}[HOLOGRAM COMPLETE - PROJECTION STABLE]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::neon() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_magenta]}[NEON GRID INITIALIZING]${COLORS[reset]}"
    echo -e "${COLORS[magenta]}[POWERING UP CYBERPUNK DISPLAY...]${COLORS[reset]}"
    echo
    
    # Create neon glow effect with multiple passes
    local neon_colors=("${COLORS[magenta]}" "${COLORS[bright_magenta]}" "${COLORS[bright_white]}" "${COLORS[bright_magenta]}" "${COLORS[magenta]}")
    
    for pass in {0..4}; do
        if [[ $pass -gt 0 ]]; then
            printf "\033[%dA" $((total_lines + 2))  # Move cursor back up
        fi
        
        echo -e "${COLORS[bright_magenta]}[NEON INTENSITY: $(((pass + 1) * 20))%]${COLORS[reset]}"
        echo
        
        for ((i=0; i<total_lines; i++)); do
            local line="${lines[i]}"
            local neon_line=""
            local color="${neon_colors[$pass]}"
            
            # Add neon outline effect
            if [[ $pass -eq 2 ]]; then
                # Peak brightness with "glow"
                for ((j=0; j<${#line}; j++)); do
                    local char="${line:$j:1}"
                    if [[ "$char" != " " ]]; then
                        neon_line+="${COLORS[bright_white]}${char}${COLORS[reset]}"
                    else
                        neon_line+=" "
                    fi
                done
            else
                neon_line="${color}${line}${COLORS[reset]}"
            fi
            
            echo -e "$neon_line"
        done
        
        sleep 0.3
    done
    
    # Final colorized display
    echo
    echo -e "${COLORS[bright_magenta]}[NEON GRID ONLINE - CYBERPUNK MODE ACTIVATED]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::terminal() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_green]}[LEGACY TERMINAL MODE INITIATED]${COLORS[reset]}"
    echo -e "${COLORS[green]}[CONNECTING TO MAINFRAME...]${COLORS[reset]}"
    echo
    
    # Show retro terminal boot sequence
    local boot_messages=(
        "SYSTEM BOOT SEQUENCE INITIATED..."
        "LOADING KERNEL MODULES..."
        "INITIALIZING NETWORK STACK..."
        "MOUNTING FILESYSTEMS..."
        "STARTING SERVICES..."
        "ESTABLISHING SECURE CONNECTION..."
    )
    
    for msg in "${boot_messages[@]}"; do
        echo -e "${COLORS[green]}> $msg${COLORS[reset]}"
        sleep 0.2
        local dots=""
        for ((d=0; d<3; d++)); do
            dots+="."
            printf "\r${COLORS[green]}> %s%s${COLORS[reset]}" "$msg" "$dots"
            sleep 0.1
        done
        echo -e " ${COLORS[bright_green]}[OK]${COLORS[reset]}"
    done
    
    echo
    echo -e "${COLORS[bright_green]}[TERMINAL READY - DISPLAYING TRANSMISSION]${COLORS[reset]}"
    echo
    
    # Show content with terminal-style formatting
    for ((i=0; i<total_lines; i++)); do
        printf "${COLORS[green]}%02d:${COLORS[reset]} " $((i + 1))
        screenfx::colorize_line "${lines[i]}"
        sleep "$sleep_time"
    done
    
    echo
    echo -e "${COLORS[bright_green]}[TERMINAL SESSION COMPLETE]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::hack() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_red]}[INITIATING HACK SEQUENCE]${COLORS[reset]}"
    echo -e "${COLORS[red]}[BYPASSING SECURITY PROTOCOLS...]${COLORS[reset]}"
    echo
    
    # Show hacking progress
    local hack_steps=(
        "Scanning for vulnerabilities"
        "Exploiting buffer overflow"
        "Escalating privileges"
        "Injecting payload"
        "Establishing backdoor"
        "Accessing classified data"
    )
    
    for step in "${hack_steps[@]}"; do
        echo -e "${COLORS[yellow]}[HACK] $step...${COLORS[reset]}"
        
        # Progress bar for each step
        for ((p=0; p<=100; p+=20)); do
            local bar=""
            local filled=$((p / 5))
            local empty=$((20 - filled))
            
            printf "\r${COLORS[red]}["
            printf "%*s" $filled | tr ' ' '#'
            printf "%*s" $empty
            printf "] %d%%${COLORS[reset]}" $p
            
            sleep 0.05
        done
        echo -e " ${COLORS[bright_green]}[SUCCESS]${COLORS[reset]}"
    done
    
    echo
    echo -e "${COLORS[bright_red]}[HACK COMPLETE - DATA ACQUIRED]${COLORS[reset]}"
    echo -e "${COLORS[red]}[DISPLAYING STOLEN INTELLIGENCE...]${COLORS[reset]}"
    echo
    
    # Show content with hacker-style effects
    for ((i=0; i<total_lines; i++)); do
        local line="${lines[i]}"
        
        # Simulate "decrypting" effect
        for attempt in {1..3}; do
            local scrambled=""
            for ((j=0; j<${#line}; j++)); do
                if [[ $((RANDOM % 2)) -eq 0 && "${line:$j:1}" != " " ]]; then
                    scrambled+="${COLORS[red]}$(printf "\$(printf '%03o' $((RANDOM % 94 + 33)))")${COLORS[reset]}"
                else
                    scrambled+="${line:$j:1}"
                fi
            done
            
            printf "\r%s" "$scrambled"
            sleep 0.1
        done
        
        printf "\r%s\n" "$(screenfx::colorize_line "$line")"
        sleep "$sleep_time"
    done
    
    echo
    echo -e "${COLORS[bright_red]}[HACK SESSION TERMINATED - COVERING TRACKS]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::decrypt() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_yellow]}[DECRYPTION ENGINE ACTIVATED]${COLORS[reset]}"
    echo -e "${COLORS[yellow]}[ANALYZING ENCRYPTED PAYLOAD...]${COLORS[reset]}"
    echo
    
    # Show encryption keys being tested
    local key_types=("AES-256" "RSA-2048" "BLOWFISH" "3DES" "CHACHA20")
    
    for key_type in "${key_types[@]}"; do
        echo -e "${COLORS[yellow]}[DECRYPT] Trying $key_type key...${COLORS[reset]}"
        
        # Simulate key testing with random hex
        local hex_key=""
        for ((h=0; h<16; h++)); do
            hex_key+="$(printf "%02X" $((RANDOM % 256)))"
        done
        
        echo -e "${COLORS[gray]}Key: $hex_key${COLORS[reset]}"
        
        # Progress animation
        for ((t=0; t<5; t++)); do
            local status=("Testing" "Verifying" "Checking" "Validating" "Analyzing")
            printf "\r${COLORS[yellow]}%s...${COLORS[reset]}" "${status[$t]}"
            sleep 0.2
        done
        
        if [[ "$key_type" == "CHACHA20" ]]; then
            echo -e "\r${COLORS[bright_green]}[KEY MATCH FOUND!]${COLORS[reset]}                "
            break
        else
            echo -e "\r${COLORS[red]}[FAILED]${COLORS[reset]}                        "
        fi
    done
    
    echo
    echo -e "${COLORS[bright_green]}[DECRYPTION SUCCESSFUL]${COLORS[reset]}"
    echo -e "${COLORS[green]}[REVEALING PLAINTEXT DATA...]${COLORS[reset]}"
    echo
    
    # Show content being decrypted
    for ((i=0; i<total_lines; i++)); do
        local line="${lines[i]}"
        
        # Show encrypted version first
        local encrypted=""
        for ((j=0; j<${#line}; j++)); do
            if [[ "${line:$j:1}" != " " ]]; then
                encrypted+="${COLORS[red]}$(printf "%c" $((RANDOM % 26 + 65)))${COLORS[reset]}"
            else
                encrypted+=" "
            fi
        done
        
        echo -e "${COLORS[red]}ENCRYPTED:${COLORS[reset]} $encrypted"
        sleep 0.3
        
        # "Decrypt" to real content
        printf "${COLORS[green]}DECRYPTED:${COLORS[reset]} "
        for ((j=0; j<${#line}; j++)); do
            printf "%s" "${line:$j:1}"
            sleep 0.01
        done
        echo
        
        sleep "$sleep_time"
    done
    
    echo
    echo -e "${COLORS[bright_yellow]}[DECRYPTION COMPLETE - MESSAGE DECODED]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::spiral() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_cyan]}[SPIRAL MATRIX GENERATOR ONLINE]${COLORS[reset]}"
    echo -e "${COLORS[cyan]}[GENERATING DIMENSIONAL VORTEX...]${COLORS[reset]}"
    echo
    
    # Create spinning spiral effect
    local term_size
    term_size=$(screenfx::get_terminal_size)
    local cols=${term_size%% *}
    local center_col=$((cols / 2))
    
    # Generate spiral animation
    for ((frame=0; frame<8; frame++)); do
        screenfx::clear_screen
        echo -e "${COLORS[bright_cyan]}[SPIRAL ROTATION: $(((frame + 1) * 45))°]${COLORS[reset]}"
        echo
        
        for ((radius=1; radius<=5; radius++)); do
            local spiral_line=""
            for ((col=0; col<cols-1; col++)); do
                local distance=$((col - center_col))
                if [[ $distance -lt 0 ]]; then distance=$((-distance)); fi
                
                if [[ $distance -eq $radius ]]; then
                    local angle=$(((col + frame * 2) % 8))
                    case $angle in
                        0|4) spiral_line+="${COLORS[bright_cyan]}○${COLORS[reset]}" ;;
                        1|5) spiral_line+="${COLORS[cyan]}/${COLORS[reset]}" ;;
                        2|6) spiral_line+="${COLORS[blue]}-${COLORS[reset]}" ;;
                        3|7) spiral_line+="${COLORS[cyan]}\\${COLORS[reset]}" ;;
                    esac
                else
                    spiral_line+=" "
                fi
            done
            echo -e "$spiral_line"
        done
        
        sleep 0.2
    done
    
    sleep 0.5
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_cyan]}[VORTEX STABILIZED]${COLORS[reset]}"
    echo -e "${COLORS[cyan]}[EXTRACTING DATA FROM DIMENSION...]${COLORS[reset]}"
    echo
    
    # Show content in spiral order (outside to inside)
    local display_order=()
    local mid=$((total_lines / 2))
    
    for ((offset=mid; offset>=0; offset--)); do
        if [[ $((mid + offset)) -lt $total_lines ]]; then
            display_order+=($((mid + offset)))
        fi
        if [[ $((mid - offset)) -ge 0 && $offset -ne 0 ]]; then
            display_order+=($((mid - offset)))
        fi
    done
    
    for order_idx in "${display_order[@]}"; do
        screenfx::colorize_line "${lines[order_idx]}"
        sleep "$sleep_time"
    done
    
    echo
    echo -e "${COLORS[bright_cyan]}[SPIRAL EXTRACTION COMPLETE]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::plasma() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_magenta]}[PLASMA FIELD GENERATOR ACTIVE]${COLORS[reset]}"
    echo -e "${COLORS[magenta]}[IONIZING PARTICLE STREAM...]${COLORS[reset]}"
    echo
    
    # Generate plasma field effect
    local term_size
    term_size=$(screenfx::get_terminal_size)
    local cols=${term_size%% *}
    local plasma_chars=("∿" "≋" "∼" "~" "∽" "≈")
    local plasma_colors=("${COLORS[bright_magenta]}" "${COLORS[magenta]}" "${COLORS[bright_blue]}" "${COLORS[blue]}" "${COLORS[bright_cyan]}" "${COLORS[cyan]}")
    
    for ((wave=0; wave<6; wave++)); do
        for ((row=0; row<4; row++)); do
            local plasma_line=""
            for ((col=0; col<cols-1; col++)); do
                local char_idx=$(((col + row + wave) % ${#plasma_chars[@]}))
                local color_idx=$(((col + row * 2 + wave) % ${#plasma_colors[@]}))
                local char="${plasma_chars[$char_idx]}"
                local color="${plasma_colors[$color_idx]}"
                plasma_line+="${color}${char}${COLORS[reset]}"
            done
            echo -e "$plasma_line"
        done
        sleep 0.15
        if [[ $wave -lt 5 ]]; then
            printf "\033[4A"  # Move cursor up 4 lines
        fi
    done
    
    sleep 0.5
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_magenta]}[PLASMA FIELD STABILIZED]${COLORS[reset]}"
    echo -e "${COLORS[magenta]}[MATERIALIZING DATA FROM ENERGY...]${COLORS[reset]}"
    echo
    
    # Show content with plasma-style coloring
    for ((i=0; i<total_lines; i++)); do
        local line="${lines[i]}"
        local plasma_line=""
        
        for ((j=0; j<${#line}; j++)); do
            local char="${line:$j:1}"
            local color_choice=$((RANDOM % 3))
            case $color_choice in
                0) plasma_line+="${COLORS[bright_magenta]}${char}${COLORS[reset]}" ;;
                1) plasma_line+="${COLORS[bright_blue]}${char}${COLORS[reset]}" ;;
                2) plasma_line+="${COLORS[bright_cyan]}${char}${COLORS[reset]}" ;;
            esac
        done
        
        echo -e "$plasma_line"
        sleep "$sleep_time"
    done
    
    echo
    echo -e "${COLORS[bright_magenta]}[PLASMA MATERIALIZATION COMPLETE]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::lightning() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_yellow]}[LIGHTNING STORM DETECTED]${COLORS[reset]}"
    echo -e "${COLORS[yellow]}[CHANNELING ELECTRICAL ENERGY...]${COLORS[reset]}"
    echo
    
    # Generate lightning strikes
    local term_size
    term_size=$(screenfx::get_terminal_size)
    local cols=${term_size%% *}
    
    for ((strike=0; strike<5; strike++)); do
        local strike_col=$((RANDOM % (cols - 10) + 5))
        
        # Flash the screen
        echo -e "${COLORS[bright_white]}" 
        
        # Draw lightning bolt
        for ((bolt_row=0; bolt_row<8; bolt_row++)); do
            local bolt_line=""
            local bolt_pos=$((strike_col + (RANDOM % 6) - 3))
            
            for ((col=0; col<cols-1; col++)); do
                if [[ $col -eq $bolt_pos ]]; then
                    case $((RANDOM % 4)) in
                        0) bolt_line+="${COLORS[bright_yellow]}|${COLORS[reset]}" ;;
                        1) bolt_line+="${COLORS[bright_white]}⚡${COLORS[reset]}" ;;
                        2) bolt_line+="${COLORS[yellow]}/${COLORS[reset]}" ;;
                        3) bolt_line+="${COLORS[yellow]}\\${COLORS[reset]}" ;;
                    esac
                else
                    bolt_line+=" "
                fi
            done
            echo -e "$bolt_line"
        done
        
        sleep 0.1
        
        # Clear the lightning
        if [[ $strike -lt 4 ]]; then
            printf "\033[8A"  # Move cursor up
            for ((clear=0; clear<8; clear++)); do
                printf "\033[K\n"  # Clear each line
            done
            printf "\033[8A"  # Move cursor back up
        fi
        
        sleep 0.3
    done
    
    sleep 0.5
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_yellow]}[STORM SUBSIDING]${COLORS[reset]}"
    echo -e "${COLORS[yellow]}[POWER SURGE CAPTURED - DISPLAYING DATA...]${COLORS[reset]}"
    echo
    
    # Show content with electrical effects
    for ((i=0; i<total_lines; i++)); do
        local line="${lines[i]}"
        
        # Random electrical flicker on some lines
        if [[ $((RANDOM % 4)) -eq 0 ]]; then
            # Show brief electrical version
            local electric_line=""
            for ((j=0; j<${#line}; j++)); do
                local char="${line:$j:1}"
                if [[ $((RANDOM % 3)) -eq 0 && "$char" != " " ]]; then
                    electric_line+="${COLORS[bright_yellow]}${char}${COLORS[reset]}"
                else
                    electric_line+="$char"
                fi
            done
            echo -e "$electric_line"
            sleep 0.05
            printf "\033[1A\033[K"  # Move up and clear line
        fi
        
        screenfx::colorize_line "$line"
        sleep "$sleep_time"
    done
    
    echo
    echo -e "${COLORS[bright_yellow]}[ELECTRICAL STORM COMPLETE - ENERGY STORED]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::explode() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_red]}[DETONATION SEQUENCE INITIATED]${COLORS[reset]}"
    echo -e "${COLORS[red]}[WARNING: EXPLOSIVE DECOMPRESSION IMMINENT]${COLORS[reset]}"
    echo
    
    # Countdown
    for ((countdown=3; countdown>=1; countdown--)); do
        echo -e "${COLORS[bright_red]}DETONATION IN: $countdown${COLORS[reset]}"
        sleep 1
        printf "\033[1A\033[K"  # Clear countdown line
    done
    
    echo -e "${COLORS[bright_white]}BOOM!${COLORS[reset]}"
    sleep 0.5
    
    # Create explosion effect
    local term_size
    term_size=$(screenfx::get_terminal_size)
    local cols=${term_size%% *}
    local center_col=$((cols / 2))
    local explosion_chars=("*" "×" "+" "·" "°" "∘")
    
    for ((radius=1; radius<=8; radius++)); do
        screenfx::clear_screen
        echo -e "${COLORS[bright_red]}[EXPLOSION RADIUS: $radius]${COLORS[reset]}"
        echo
        
        for ((row=0; row<8; row++)); do
            local explosion_line=""
            for ((col=0; col<cols-1; col++)); do
                local distance_from_center=$((col - center_col))
                if [[ $distance_from_center -lt 0 ]]; then 
                    distance_from_center=$((-distance_from_center))
                fi
                
                local distance_from_row=$((row - 4))
                if [[ $distance_from_row -lt 0 ]]; then 
                    distance_from_row=$((-distance_from_row))
                fi
                
                local total_distance=$((distance_from_center + distance_from_row))
                
                if [[ $total_distance -eq $radius ]]; then
                    local char_idx=$((RANDOM % ${#explosion_chars[@]}))
                    local char="${explosion_chars[$char_idx]}"
                    case $((radius % 4)) in
                        0) explosion_line+="${COLORS[bright_red]}${char}${COLORS[reset]}" ;;
                        1) explosion_line+="${COLORS[bright_yellow]}${char}${COLORS[reset]}" ;;
                        2) explosion_line+="${COLORS[yellow]}${char}${COLORS[reset]}" ;;
                        3) explosion_line+="${COLORS[red]}${char}${COLORS[reset]}" ;;
                    esac
                elif [[ $total_distance -lt $radius ]]; then
                    explosion_line+="${COLORS[gray]}░${COLORS[reset]}"
                else
                    explosion_line+=" "
                fi
            done
            echo -e "$explosion_line"
        done
        
        sleep 0.1
    done
    
    sleep 0.5
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_yellow]}[SHOCKWAVE SUBSIDING]${COLORS[reset]}"
    echo -e "${COLORS[yellow]}[DEBRIS FIELD ANALYSIS...]${COLORS[reset]}"
    echo
    
    # Show content "reassembling" from explosion
    for ((i=0; i<total_lines; i++)); do
        local line="${lines[i]}"
        
        # Show scattered fragments first
        local fragments=""
        for ((j=0; j<${#line}; j++)); do
            local char="${line:$j:1}"
            if [[ "$char" != " " && $((RANDOM % 3)) -eq 0 ]]; then
                fragments+="${COLORS[red]}${char}${COLORS[reset]}"
            else
                fragments+=" "
            fi
        done
        
        echo -e "$fragments"
        sleep 0.1
        
        # "Reassemble" to correct line
        printf "\033[1A\033[K"  # Move up and clear
        screenfx::colorize_line "$line"
        
        sleep "$sleep_time"
    done
    
    echo
    echo -e "${COLORS[bright_red]}[EXPLOSION COMPLETE - DATA RECONSTRUCTED]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::radar() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_green]}[RADAR SYSTEM ONLINE]${COLORS[reset]}"
    echo -e "${COLORS[green]}[SCANNING FOR TARGETS...]${COLORS[reset]}"
    echo
    
    # Create radar sweep animation
    local term_size
    term_size=$(screenfx::get_terminal_size)
    local cols=${term_size%% *}
    local center_col=$((cols / 2))
    
    # Draw radar circles
    for ((sweep=0; sweep<8; sweep++)); do
        screenfx::clear_screen
        echo -e "${COLORS[bright_green]}[RADAR SWEEP: $(((sweep + 1) * 45))°]${COLORS[reset]}"
        echo
        
        # Draw concentric circles
        for ((row=0; row<10; row++)); do
            local radar_line=""
            for ((col=0; col<cols-1; col++)); do
                local distance_from_center=$((col - center_col))
                if [[ $distance_from_center -lt 0 ]]; then 
                    distance_from_center=$((-distance_from_center))
                fi
                
                local distance_from_row=$((row - 5))
                if [[ $distance_from_row -lt 0 ]]; then 
                    distance_from_row=$((-distance_from_row))
                fi
                
                local total_distance=$((distance_from_center + distance_from_row / 2))
                
                # Draw radar sweep line
                local sweep_angle=$((sweep % 8))
                local is_sweep_line=0
                
                case $sweep_angle in
                    0) [[ $row -eq 5 && $col -ge $center_col ]] && is_sweep_line=1 ;;
                    1) [[ $((row + col - center_col)) -eq 5 && $col -ge $center_col ]] && is_sweep_line=1 ;;
                    2) [[ $col -eq $center_col && $row -ge 5 ]] && is_sweep_line=1 ;;
                    3) [[ $((row - col + center_col)) -eq 5 && $col -le $center_col ]] && is_sweep_line=1 ;;
                    4) [[ $row -eq 5 && $col -le $center_col ]] && is_sweep_line=1 ;;
                    5) [[ $((row + col - center_col)) -eq 5 && $col -le $center_col ]] && is_sweep_line=1 ;;
                    6) [[ $col -eq $center_col && $row -le 5 ]] && is_sweep_line=1 ;;
                    7) [[ $((row - col + center_col)) -eq 5 && $col -ge $center_col ]] && is_sweep_line=1 ;;
                esac
                
                if [[ $is_sweep_line -eq 1 ]]; then
                    radar_line+="${COLORS[bright_green]}-${COLORS[reset]}"
                elif [[ $total_distance -eq 8 ]] || [[ $total_distance -eq 15 ]] || [[ $total_distance -eq 22 ]]; then
                    radar_line+="${COLORS[green]}·${COLORS[reset]}"
                elif [[ $((col + row + sweep)) -eq $((center_col + 5)) ]]; then
                    radar_line+="${COLORS[bright_yellow]}◉${COLORS[reset]}"
                else
                    radar_line+=" "
                fi
            done
            echo -e "$radar_line"
        done
        
        sleep 0.2
    done
    
    sleep 0.5
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_green]}[TARGETS ACQUIRED]${COLORS[reset]}"
    echo -e "${COLORS[green]}[DISPLAYING RADAR DATA...]${COLORS[reset]}"
    echo
    
    # Show content with radar-style blips
    for ((i=0; i<total_lines; i++)); do
        local line="${lines[i]}"
        
        # Add radar blip effect
        if [[ $((RANDOM % 5)) -eq 0 ]]; then
            echo -e "${COLORS[bright_green]}>>> CONTACT DETECTED <<<${COLORS[reset]}"
            sleep 0.1
        fi
        
        echo -e "${COLORS[green]}[$(printf "%02d" $((i + 1)))]${COLORS[reset]} $(screenfx::colorize_line "$line")"
        sleep "$sleep_time"
    done
    
    echo
    echo -e "${COLORS[bright_green]}[RADAR SWEEP COMPLETE - ALL TARGETS MAPPED]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::binary_rain() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_green]}[BINARY RAIN PROTOCOL INITIATED]${COLORS[reset]}"
    echo -e "${COLORS[green]}[DIGITAL PRECIPITATION DETECTED...]${COLORS[reset]}"
    echo
    
    # Generate binary rain effect
    local term_size
    term_size=$(screenfx::get_terminal_size)
    local cols=${term_size%% *}
    
    for ((rain=0; rain<12; rain++)); do
        for ((row=0; row<6; row++)); do
            local rain_line=""
            for ((col=0; col<cols-1; col++)); do
                local binary_char=$((RANDOM % 2))
                local drop_speed=$(((col + rain) % 4))
                case $drop_speed in
                    0) rain_line+="${COLORS[bright_green]}${binary_char}${COLORS[reset]}" ;;
                    1) rain_line+="${COLORS[green]}${binary_char}${COLORS[reset]}" ;;
                    2) rain_line+="${COLORS[gray]}${binary_char}${COLORS[reset]}" ;;
                    3) rain_line+=" " ;;
                esac
            done
            echo -e "$rain_line"
        done
        sleep 0.1
        if [[ $rain -lt 11 ]]; then
            printf "\033[6A"  # Move cursor up 6 lines
        fi
    done
    
    sleep 0.5
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_green]}[BINARY STREAM DECODED]${COLORS[reset]}"
    echo -e "${COLORS[green]}[RECONSTRUCTING DATA...]${COLORS[reset]}"
    echo
    
    # Show content materializing from binary
    for ((i=0; i<total_lines; i++)); do
        local line="${lines[i]}"
        
        # Show binary version first
        local binary_line=""
        for ((j=0; j<${#line}; j++)); do
            if [[ "${line:$j:1}" != " " ]]; then
                binary_line+="${COLORS[green]}$((RANDOM % 2))${COLORS[reset]}"
            else
                binary_line+=" "
            fi
        done
        
        echo -e "$binary_line"
        sleep 0.1
        
        # Replace with actual content
        printf "\033[1A\033[K"  # Move up and clear
        screenfx::colorize_line "$line"
        sleep "$sleep_time"
    done
    
    echo
    echo -e "${COLORS[bright_green]}[BINARY RAIN COMPLETE - DATA MATERIALIZED]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::quantum() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_blue]}[QUANTUM PROCESSOR INITIALIZED]${COLORS[reset]}"
    echo -e "${COLORS[blue]}[ENTERING SUPERPOSITION STATE...]${COLORS[reset]}"
    echo
    
    # Show quantum superposition effect
    local quantum_states=("ψ" "Φ" "α" "β" "γ" "δ" "⟩" "⟨" "∞" "∆")
    
    for ((wave=0; wave<8; wave++)); do
        screenfx::clear_screen
        echo -e "${COLORS[bright_blue]}[QUANTUM WAVE FUNCTION: $((wave + 1))/8]${COLORS[reset]}"
        echo
        
        for ((i=0; i<total_lines; i++)); do
            local line="${lines[i]}"
            local quantum_line=""
            
            for ((j=0; j<${#line}; j++)); do
                local char="${line:$j:1}"
                if [[ "$char" != " " ]]; then
                    local state_idx=$((RANDOM % ${#quantum_states[@]}))
                    local probability=$((RANDOM % 4))
                    case $probability in
                        0) quantum_line+="${COLORS[bright_blue]}${quantum_states[$state_idx]}${COLORS[reset]}" ;;
                        1) quantum_line+="${COLORS[blue]}${char}${COLORS[reset]}" ;;
                        2) quantum_line+="${COLORS[cyan]}${quantum_states[$state_idx]}${COLORS[reset]}" ;;
                        3) quantum_line+="${COLORS[white]}${char}${COLORS[reset]}" ;;
                    esac
                else
                    quantum_line+=" "
                fi
            done
            echo -e "$quantum_line"
        done
        
        sleep 0.2
    done
    
    echo
    echo -e "${COLORS[bright_blue]}[QUANTUM COLLAPSE - OBSERVING REALITY]${COLORS[reset]}"
    echo
    
    # Collapse to actual content
    for ((i=0; i<total_lines; i++)); do
        screenfx::colorize_line "${lines[i]}"
        sleep "$sleep_time"
    done
    
    echo
    echo -e "${COLORS[bright_blue]}[QUANTUM STATE COLLAPSED - REALITY STABILIZED]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::virus() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_red]}[VIRUS DETECTED - INITIATING QUARANTINE]${COLORS[reset]}"
    echo -e "${COLORS[red]}[MALICIOUS CODE SPREADING...]${COLORS[reset]}"
    echo
    
    # Show virus infection spreading
    local virus_chars=("☣" "⚠" "⚡" "※" "⚆" "◉" "●" "▲")
    
    # Initial clean state
    for ((i=0; i<total_lines; i++)); do
        echo -e "${COLORS[green]}[CLEAN] ${lines[i]}${COLORS[reset]}"
    done
    
    sleep 1
    
    # Virus infection waves
    for ((infection=1; infection<=4; infection++)); do
        printf "\033[%dA" $total_lines  # Move cursor back up
        
        for ((i=0; i<total_lines; i++)); do
            local line="${lines[i]}"
            local infection_chance=$((RANDOM % 4))
            
            if [[ $infection_chance -eq 0 ]] || [[ $i -eq $((infection * 2)) ]]; then
                # Show infected line
                local infected_line=""
                for ((j=0; j<${#line}; j++)); do
                    local char="${line:$j:1}"
                    if [[ $((RANDOM % 3)) -eq 0 && "$char" != " " ]]; then
                        local virus_idx=$((RANDOM % ${#virus_chars[@]}))
                        infected_line+="${COLORS[bright_red]}${virus_chars[$virus_idx]}${COLORS[reset]}"
                    else
                        infected_line+="$char"
                    fi
                done
                echo -e "${COLORS[red]}[VIRUS] $infected_line${COLORS[reset]}"
            else
                echo -e "${COLORS[green]}[CLEAN] $line${COLORS[reset]}"
            fi
        done
        
        sleep 0.5
    done
    
    echo
    echo -e "${COLORS[bright_yellow]}[ANTIVIRUS ACTIVATED - PURGING INFECTION]${COLORS[reset]}"
    echo
    
    # Antivirus cleanup
    for ((i=0; i<total_lines; i++)); do
        echo -e "${COLORS[yellow]}[SCANNING] ${lines[i]}${COLORS[reset]}"
        sleep 0.1
        printf "\033[1A\033[K"  # Move up and clear
        echo -e "${COLORS[bright_green]}[CLEANED] $(screenfx::colorize_line "${lines[i]}")${COLORS[reset]}"
        sleep "$sleep_time"
    done
    
    echo
    echo -e "${COLORS[bright_green]}[SYSTEM DISINFECTED - ALL THREATS ELIMINATED]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::neural() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_magenta]}[NEURAL NETWORK ACTIVATION]${COLORS[reset]}"
    echo -e "${COLORS[magenta]}[SYNAPSES FIRING...]${COLORS[reset]}"
    echo
    
    # Show neural network visualization
    local term_size
    term_size=$(screenfx::get_terminal_size)
    local cols=${term_size%% *}
    local neurons=("◉" "○" "●" "◎" "⬡" "⬢")
    local connections=("-" "=" "~" "∼" "≈" "∿")
    
    for ((pulse=0; pulse<6; pulse++)); do
        for ((row=0; row<4; row++)); do
            local neural_line=""
            for ((col=0; col<cols-10; col+=8)); do
                local neuron_idx=$((RANDOM % ${#neurons[@]}))
                local conn_idx=$((RANDOM % ${#connections[@]}))
                local activation=$((RANDOM % 3))
                
                case $activation in
                    0) neural_line+="${COLORS[bright_magenta]}${neurons[$neuron_idx]}${COLORS[reset]}" ;;
                    1) neural_line+="${COLORS[magenta]}${neurons[$neuron_idx]}${COLORS[reset]}" ;;
                    2) neural_line+="${COLORS[cyan]}${neurons[$neuron_idx]}${COLORS[reset]}" ;;
                esac
                
                # Add connections
                for ((c=0; c<6; c++)); do
                    neural_line+="${COLORS[gray]}${connections[$conn_idx]}${COLORS[reset]}"
                done
            done
            echo -e "$neural_line"
        done
        
        sleep 0.2
        if [[ $pulse -lt 5 ]]; then
            printf "\033[4A"  # Move cursor up
        fi
    done
    
    sleep 0.5
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_magenta]}[NEURAL PATTERN RECOGNITION COMPLETE]${COLORS[reset]}"
    echo -e "${COLORS[magenta]}[CONSCIOUSNESS EMERGING...]${COLORS[reset]}"
    echo
    
    # Show content with neural processing effect
    for ((i=0; i<total_lines; i++)); do
        local line="${lines[i]}"
        
        # Show processing pattern
        echo -e "${COLORS[gray]}Processing neural pathway $((i + 1))...${COLORS[reset]}"
        sleep 0.1
        printf "\033[1A\033[K"  # Clear processing line
        
        # Show activated line
        echo -e "${COLORS[bright_magenta]}◉${COLORS[reset]} $(screenfx::colorize_line "$line")"
        sleep "$sleep_time"
    done
    
    echo
    echo -e "${COLORS[bright_magenta]}[NEURAL CONSCIOUSNESS ACHIEVED]${COLORS[reset]}"
    
    screenfx::show_cursor
}

screenfx::blackhole() {
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
    screenfx::clear_screen
    
    echo -e "${COLORS[bright_white]}[GRAVITATIONAL ANOMALY DETECTED]${COLORS[reset]}"
    echo -e "${COLORS[gray]}[BLACK HOLE FORMATION IMMINENT...]${COLORS[reset]}"
    echo
    
    # Show all content first
    for ((i=0; i<total_lines; i++)); do
        screenfx::colorize_line "${lines[i]}"
    done
    
    sleep 1
    
    # Create black hole effect - content gets sucked in
    local term_size
    term_size=$(screenfx::get_terminal_size)
    local cols=${term_size%% *}
    local center_col=$((cols / 2))
    local center_row=$((total_lines / 2 + 3))
    
    echo
    echo -e "${COLORS[bright_red]}[EVENT HORIZON BREACHED - SPACETIME COLLAPSE]${COLORS[reset]}"
    echo
    
    # Suck content into black hole
    for ((radius=20; radius>=1; radius--)); do
        screenfx::clear_screen
        echo -e "${COLORS[bright_white]}[SINGULARITY RADIUS: $radius]${COLORS[reset]}"
        echo
        
        for ((i=0; i<total_lines; i++)); do
            local line="${lines[i]}"
            local warped_line=""
            local row_distance=$((i + 3 - center_row))
            if [[ $row_distance -lt 0 ]]; then row_distance=$((-row_distance)); fi
            
            for ((j=0; j<${#line}; j++)); do
                local char="${line:$j:1}"
                local col_distance=$((j - center_col))
                if [[ $col_distance -lt 0 ]]; then col_distance=$((-col_distance)); fi
                local total_distance=$((col_distance + row_distance))
                
                if [[ $total_distance -le $radius ]]; then
                    # Character is being pulled in
                    local distortion=$((RANDOM % 4))
                    case $distortion in
                        0) warped_line+="${COLORS[red]}${char}${COLORS[reset]}" ;;
                        1) warped_line+="${COLORS[yellow]}·${COLORS[reset]}" ;;
                        2) warped_line+="${COLORS[gray]}░${COLORS[reset]}" ;;
                        3) warped_line+=" " ;;
                    esac
                else
                    warped_line+="$char"
                fi
            done
            
            echo -e "$warped_line"
        done
        
        # Show black hole center
        printf "\033[%d;%dH" $center_row $((center_col - 1))
        echo -e "${COLORS[bright_white]}◉${COLORS[reset]}"
        
        sleep 0.1
    done
    
    # Show singularity
    screenfx::clear_screen
    printf "\033[%d;%dH" $((center_row - 1)) $((center_col - 10))
    echo -e "${COLORS[bright_white]}[SINGULARITY ACHIEVED]${COLORS[reset]}"
    printf "\033[%d;%dH" $center_row $center_col
    echo -e "${COLORS[bright_white]}●${COLORS[reset]}"
    
    sleep 1
    
    # Hawking radiation - information escapes
    echo
    printf "\033[%d;%dH" $((center_row + 2)) $((center_col - 15))
    echo -e "${COLORS[bright_cyan]}[HAWKING RADIATION DETECTED - INFORMATION ESCAPING]${COLORS[reset]}"
    
    sleep 1
    screenfx::clear_screen
    
    # Reconstruct content from radiation
    echo -e "${COLORS[bright_cyan]}[QUANTUM INFORMATION PRESERVED]${COLORS[reset]}"
    echo -e "${COLORS[cyan]}[RECONSTRUCTING FROM HAWKING RADIATION...]${COLORS[reset]}"
    echo
    
    for ((i=0; i<total_lines; i++)); do
        screenfx::colorize_line "${lines[i]}"
        sleep "$sleep_time"
    done
    
    echo
    echo -e "${COLORS[bright_white]}[BLACK HOLE EVAPORATED - INFORMATION PARADOX RESOLVED]${COLORS[reset]}"
    
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
        matrix)
            screenfx::matrix "$file"
            ;;
        waves)
            screenfx::waves "$file"
            ;;
        bounce)
            screenfx::bounce "$file"
            ;;
        scan)
            screenfx::scan "$file"
            ;;
        fade)
            screenfx::fade "$file"
            ;;
        reveal)
            screenfx::reveal "$file"
            ;;
        cascade)
            screenfx::cascade "$file"
            ;;
        hologram)
            screenfx::hologram "$file"
            ;;
        neon)
            screenfx::neon "$file"
            ;;
        terminal)
            screenfx::terminal "$file"
            ;;
        hack)
            screenfx::hack "$file"
            ;;
        decrypt)
            screenfx::decrypt "$file"
            ;;
        spiral)
            screenfx::spiral "$file"
            ;;
        plasma)
            screenfx::plasma "$file"
            ;;
        lightning)
            screenfx::lightning "$file"
            ;;
        explode)
            screenfx::explode "$file"
            ;;
        radar)
            screenfx::radar "$file"
            ;;
        binary_rain)
            screenfx::binary_rain "$file"
            ;;
        quantum)
            screenfx::quantum "$file"
            ;;
        virus)
            screenfx::virus "$file"
            ;;
        neural)
            screenfx::neural "$file"
            ;;
        blackhole)
            screenfx::blackhole "$file"
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
