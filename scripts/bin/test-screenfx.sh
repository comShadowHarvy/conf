#!/usr/bin/env zsh
# Test all ScreenFX animations

# Usage: test-screenfx.sh [speed]
# speed: fast, normal, slow (default: normal)

SPEED="${1:-normal}"
SOURCE_FILE="$HOME/git/conf/screen.txt"

# Load ScreenFX
source ~/bin/screenfx.sh

echo "Testing all ScreenFX animations with speed: $SPEED"
echo "Press Enter after each animation to continue, or Ctrl+C to stop"
echo ""

for style in "${SCREENFX_STYLES[@]}"; do
    echo "========================================"
    echo "Testing: $style"
    echo "========================================"
    
    # Test the animation
    SCREENFX_STYLE="$style" SCREENFX_SPEED="$SPEED" screenfx::show "$SOURCE_FILE" 2>&1
    
    # Check if it had errors
    if [[ $? -ne 0 ]]; then
        echo "❌ FAILED: $style had errors"
    else
        echo "✅ SUCCESS: $style"
    fi
    
    echo ""
    read -k1 -s "?Press any key to continue..."
    echo ""
done

echo ""
echo "Testing complete!"
