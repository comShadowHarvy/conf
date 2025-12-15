#!/bin/bash

# Script to decompile all APK files in the current directory
# Uses apktool for resources/smali and jadx for Java source code

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== APK Decompiler ===${NC}"
echo "Searching for APK files in current directory..."

# Find all APK files
apk_files=(*.apk)

if [ ${#apk_files[@]} -eq 0 ] || [ ! -e "${apk_files[0]}" ]; then
    echo -e "${RED}No APK files found in current directory${NC}"
    exit 1
fi

echo -e "Found ${GREEN}${#apk_files[@]}${NC} APK file(s)"
echo ""

# Process each APK
for apk in "${apk_files[@]}"; do
    if [ ! -f "$apk" ]; then
        continue
    fi
    
    basename="${apk%.apk}"
    echo -e "${YELLOW}Processing: ${apk}${NC}"
    
    # Decompile with apktool
    echo "  [1/2] Running apktool..."
    apktool_dir="${basename}-apktool"
    if [ -d "$apktool_dir" ]; then
        echo "  Warning: ${apktool_dir} already exists, skipping apktool"
    else
        if apktool d "$apk" -o "$apktool_dir" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} apktool completed: ${apktool_dir}"
        else
            echo -e "  ${RED}✗${NC} apktool failed"
        fi
    fi
    
    # Decompile with jadx (full featured)
    echo "  [2/3] Running jadx (full)..."
    jadx_dir="${basename}-jadx"
    if [ -d "$jadx_dir" ]; then
        echo "  Warning: ${jadx_dir} already exists, skipping jadx"
    else
        # Try jadx with full features for best output
        if timeout 300 jadx "$apk" -d "$jadx_dir" --deobf --show-bad-code -j $(nproc) > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} jadx completed: ${jadx_dir}"
        else
            # If full jadx fails/times out, try minimal version
            echo "  Trying jadx with minimal options..."
            rm -rf "$jadx_dir"
            if jadx "$apk" -d "$jadx_dir" --no-res --no-debug-info --no-imports --no-inline-anonymous > /dev/null 2>&1; then
                echo -e "  ${YELLOW}✓${NC} jadx completed (minimal): ${jadx_dir}"
            else
                echo -e "  ${YELLOW}⚠${NC} jadx had issues but may have partial output"
            fi
        fi
    fi
    
    # Extract classes.dex for manual inspection
    echo "  [3/3] Extracting DEX files..."
    dex_dir="${basename}-dex"
    if [ -d "$dex_dir" ]; then
        echo "  Warning: ${dex_dir} already exists, skipping extraction"
    else
        mkdir -p "$dex_dir"
        if unzip -q "$apk" '*.dex' -d "$dex_dir" 2>/dev/null; then
            dex_count=$(find "$dex_dir" -name '*.dex' | wc -l)
            echo -e "  ${GREEN}✓${NC} Extracted ${dex_count} DEX file(s): ${dex_dir}"
        else
            rmdir "$dex_dir" 2>/dev/null || true
            echo -e "  ${RED}✗${NC} No DEX files found"
        fi
    fi
    
    echo ""
done

echo -e "${GREEN}=== Decompilation complete ===${NC}"
echo ""
echo "Output directories:"
for apk in "${apk_files[@]}"; do
    if [ ! -f "$apk" ]; then
        continue
    fi
    basename="${apk%.apk}"
    echo "  ${apk}:"
    [ -d "${basename}-apktool" ] && echo "    - ${basename}-apktool/ (resources, smali, AndroidManifest.xml)"
    [ -d "${basename}-jadx" ] && echo "    - ${basename}-jadx/ (Java source code)"
    [ -d "${basename}-dex" ] && echo "    - ${basename}-dex/ (raw DEX files)"
done
