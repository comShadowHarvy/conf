#!/bin/bash

# APK Signing Script
# Usage: ./sign-apk.sh <input.apk> <password>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input.apk> <password>"
    exit 1
fi

APK_FILE="$1"
PASSWORD="$2"
KEYSTORE="my-release-key.keystore"
KEY_ALIAS="my-key-alias"

# Check if APK file exists
if [ ! -f "$APK_FILE" ]; then
    echo "Error: APK file '$APK_FILE' not found!"
    exit 1
fi

# Check if keystore exists
if [ ! -f "$KEYSTORE" ]; then
    echo "Error: Keystore '$KEYSTORE' not found!"
    exit 1
fi

# Get the base name without extension
BASE_NAME="${APK_FILE%.apk}"
ALIGNED_APK="${BASE_NAME}-aligned.apk"
SIGNED_APK="${BASE_NAME}-signed.apk"

echo "Starting APK signing process..."
echo "Input APK: $APK_FILE"

# Step 1: Zipalign the APK
echo ""
echo "Step 1: Running zipalign..."
zipalign -v -p 4 "$APK_FILE" "$ALIGNED_APK"

if [ $? -ne 0 ]; then
    echo "Error: zipalign failed!"
    exit 1
fi

echo "Zipalign completed: $ALIGNED_APK"

# Step 2: Sign the aligned APK
echo ""
echo "Step 2: Signing APK with jarsigner..."
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore "$KEYSTORE" -storepass "$PASSWORD" -keypass "$PASSWORD" "$ALIGNED_APK" "$KEY_ALIAS"

if [ $? -ne 0 ]; then
    echo "Error: jarsigner failed!"
    rm -f "$ALIGNED_APK"
    exit 1
fi

# Rename aligned APK to signed APK
mv "$ALIGNED_APK" "$SIGNED_APK"

echo ""
echo "✓ APK signed successfully!"
echo "Output file: $SIGNED_APK"

# Step 3: Verify the signature
echo ""
echo "Step 3: Verifying signature..."
jarsigner -verify -verbose -certs "$SIGNED_APK"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Signature verified successfully!"
else
    echo ""
    echo "⚠ Warning: Signature verification failed!"
fi
