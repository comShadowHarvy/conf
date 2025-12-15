#!/bin/bash

# APK Build and Optimization Script
# Usage: ./build-optimized-apk.sh <apktool-directory>

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <apktool-directory>"
    echo "Example: $0 bloodv2.2-apktool"
    exit 1
fi

APKTOOL_DIR="$1"
OUTPUT_APK="${APKTOOL_DIR}.apk"
OPTIMIZED_APK="${APKTOOL_DIR}-optimized.apk"
ALIGNED_APK="${APKTOOL_DIR}-aligned.apk"

# Check if apktool directory exists
if [ ! -d "$APKTOOL_DIR" ]; then
    echo "Error: Directory '$APKTOOL_DIR' not found!"
    exit 1
fi

echo "=========================================="
echo "APK Optimization and Build Script"
echo "=========================================="
echo "Input directory: $APKTOOL_DIR"
echo ""

# Step 1: Optimize PNG images with optipng and pngquant
echo "Step 1: Optimizing PNG images..."
PNG_COUNT=$(find "$APKTOOL_DIR/res" -name "*.png" 2>/dev/null | wc -l)
echo "Found $PNG_COUNT PNG files"

if [ "$PNG_COUNT" -gt 0 ]; then
    # Check if optimization tools are installed
    if command -v pngquant &> /dev/null && command -v optipng &> /dev/null; then
        echo "Using pngquant + optipng for aggressive compression..."
        find "$APKTOOL_DIR/res" -name "*.png" -type f | while read png; do
            # First pass: pngquant for lossy compression (high quality)
            pngquant --quality=85-95 --speed 1 --force --ext .png "$png" 2>/dev/null
            # Second pass: optipng for lossless optimization
            optipng -o7 -quiet "$png" 2>/dev/null
        done
        echo "✓ PNG optimization completed"
    elif command -v optipng &> /dev/null; then
        echo "Using optipng for lossless compression..."
        find "$APKTOOL_DIR/res" -name "*.png" -type f -exec optipng -o7 -quiet {} \;
        echo "✓ PNG optimization completed"
    elif command -v pngquant &> /dev/null; then
        echo "Using pngquant for lossy compression..."
        find "$APKTOOL_DIR/res" -name "*.png" -type f -exec pngquant --quality=85-95 --speed 1 --force --ext .png {} \; 2>/dev/null
        echo "✓ PNG optimization completed"
    else
        echo "⚠ Warning: No PNG optimization tools found. Install optipng and/or pngquant for better compression."
        echo "  pacman -S optipng pngquant"
    fi
else
    echo "No PNG files found to optimize"
fi

# Step 2: Optimize JPEG/JPG images
echo ""
echo "Step 2: Optimizing JPEG images..."
JPG_COUNT=$(find "$APKTOOL_DIR/res" -name "*.jpg" -o -name "*.jpeg" 2>/dev/null | wc -l)
echo "Found $JPG_COUNT JPEG files"

if [ "$JPG_COUNT" -gt 0 ]; then
    if command -v jpegoptim &> /dev/null; then
        echo "Using jpegoptim for JPEG compression..."
        find "$APKTOOL_DIR/res" \( -name "*.jpg" -o -name "*.jpeg" \) -type f -exec jpegoptim --max=90 --strip-all {} \;
        echo "✓ JPEG optimization completed"
    else
        echo "⚠ Warning: jpegoptim not found. Install it for JPEG compression."
        echo "  pacman -S jpegoptim"
    fi
else
    echo "No JPEG files found to optimize"
fi

# Step 3: Build APK with apktool
echo ""
echo "Step 3: Building APK from smali code..."
apktool b "$APKTOOL_DIR" -o "$OPTIMIZED_APK"

if [ $? -ne 0 ]; then
    echo "Error: apktool build failed!"
    exit 1
fi

echo "✓ APK built: $OPTIMIZED_APK"

# Get original size
ORIGINAL_SIZE=$(du -h "$OPTIMIZED_APK" | cut -f1)
echo "  Size: $ORIGINAL_SIZE"

# Step 4: Zipalign the APK
echo ""
echo "Step 4: Running zipalign..."
zipalign -v -p 4 "$OPTIMIZED_APK" "$ALIGNED_APK"

if [ $? -ne 0 ]; then
    echo "Error: zipalign failed!"
    exit 1
fi

# Remove unaligned APK and rename aligned APK
rm "$OPTIMIZED_APK"
mv "$ALIGNED_APK" "$OPTIMIZED_APK"

echo "✓ Zipalign completed"

# Final size
FINAL_SIZE=$(du -h "$OPTIMIZED_APK" | cut -f1)

echo ""
echo "=========================================="
echo "✓ Build completed successfully!"
echo "=========================================="
echo "Output APK: $OPTIMIZED_APK"
echo "Final size: $FINAL_SIZE"
echo ""
echo "Next step: Sign the APK with:"
echo "  ./sign-apk.sh $OPTIMIZED_APK <password>"
echo "=========================================="
