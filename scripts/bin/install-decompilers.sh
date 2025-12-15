#!/bin/bash

# Script to install additional APK decompilation tools for better results

set -e

echo "=== Installing APK Decompilation Tools ==="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "Please don't run this script as root"
    exit 1
fi

# Image optimization tools
echo "[1/8] Installing image optimization tools..."
echo "  Installing optipng, pngquant, jpegoptim..."
sudo pacman -S --noconfirm optipng pngquant jpegoptim
echo "  ✓ Image optimization tools installed"

# apktool - core tool for APK decompilation
echo "[2/8] Installing apktool..."
if command -v apktool &> /dev/null; then
    echo "  ✓ apktool already installed"
else
    echo "  Installing from Arch repos..."
    sudo pacman -S --noconfirm android-apktool
    echo "  ✓ apktool installed"
fi

# jadx - DEX to Java decompiler
echo "[3/8] Installing jadx..."
if command -v jadx &> /dev/null; then
    echo "  ✓ jadx already installed"
else
    echo "  Checking AUR..."
    if command -v yay &> /dev/null; then
        yay -S --noconfirm jadx
        echo "  ✓ jadx installed"
    elif command -v paru &> /dev/null; then
        paru -S --noconfirm jadx
        echo "  ✓ jadx installed"
    else
        echo "  Downloading jadx manually..."
        cd /tmp
        wget -q https://github.com/skylot/jadx/releases/download/v1.5.0/jadx-1.5.0.zip
        unzip -q jadx-1.5.0.zip -d jadx
        sudo mv jadx /opt/jadx
        sudo ln -sf /opt/jadx/bin/jadx /usr/local/bin/jadx
        sudo ln -sf /opt/jadx/bin/jadx-gui /usr/local/bin/jadx-gui
        rm -f jadx-1.5.0.zip
        echo "  ✓ jadx installed"
    fi
fi

# dex2jar - converts DEX to JAR files
echo "[4/8] Installing dex2jar..."
if command -v d2j-dex2jar &> /dev/null; then
    echo "  ✓ dex2jar already installed"
else
    echo "  Downloading dex2jar..."
    cd /tmp
    wget -q https://github.com/pxb1988/dex2jar/releases/download/v2.4/dex-tools-v2.4.zip
    unzip -q dex-tools-v2.4.zip
    sudo mv dex-tools-v2.4 /opt/dex2jar
    sudo chmod +x /opt/dex2jar/*.sh
    echo "  Creating symlinks..."
    for tool in /opt/dex2jar/*.sh; do
        toolname=$(basename "$tool" .sh)
        sudo ln -sf "$tool" "/usr/local/bin/$toolname" 2>/dev/null || true
    done
    rm -f dex-tools-v2.4.zip
    echo "  ✓ dex2jar installed"
fi

# CFR - another Java decompiler (often better than jadx for obfuscated code)
echo "[5/8] Installing CFR decompiler..."
if [ -f /opt/cfr/cfr.jar ]; then
    echo "  ✓ CFR already installed"
else
    echo "  Downloading CFR..."
    sudo mkdir -p /opt/cfr
    sudo wget -q https://github.com/leibnitz27/cfr/releases/download/0.152/cfr-0.152.jar -O /opt/cfr/cfr.jar
    echo '#!/bin/bash' | sudo tee /usr/local/bin/cfr > /dev/null
    echo 'java -jar /opt/cfr/cfr.jar "$@"' | sudo tee -a /usr/local/bin/cfr > /dev/null
    sudo chmod +x /usr/local/bin/cfr
    echo "  ✓ CFR installed"
fi

# Enjarify - Google's dex to jar converter (more accurate than dex2jar)
echo "[6/8] Installing enjarify..."
if command -v enjarify &> /dev/null; then
    echo "  ✓ enjarify already installed"
else
    echo "  Cloning enjarify..."
    cd /tmp
    git clone -q https://github.com/Storyyeller/enjarify.git
    cd enjarify
    sudo python3 setup.py install > /dev/null 2>&1 || {
        # If install fails, create wrapper script
        sudo mv /tmp/enjarify /opt/enjarify
        echo '#!/bin/bash' | sudo tee /usr/local/bin/enjarify > /dev/null
        echo 'python3 /opt/enjarify/enjarify.py "$@"' | sudo tee -a /usr/local/bin/enjarify > /dev/null
        sudo chmod +x /usr/local/bin/enjarify
    }
    echo "  ✓ enjarify installed"
fi

# zipalign - APK optimization tool
echo "[7/8] Installing zipalign..."
if command -v zipalign &> /dev/null; then
    echo "  ✓ zipalign already installed"
else
    echo "  Installing from Arch repos..."
    sudo pacman -S --noconfirm android-tools
    echo "  ✓ zipalign installed"
fi

# jarsigner - APK signing tool (usually part of JDK)
echo "[8/8] Checking jarsigner..."
if command -v jarsigner &> /dev/null; then
    echo "  ✓ jarsigner already installed"
else
    echo "  Installing JDK..."
    sudo pacman -S --noconfirm jdk-openjdk
    echo "  ✓ jarsigner installed"
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Installed tools:"
echo "  - optipng, pngquant, jpegoptim: image optimization"
echo "  - apktool: decompiles APK resources and smali"
echo "  - jadx: DEX to Java source decompiler"
echo "  - dex2jar: converts DEX to JAR"
echo "  - CFR: alternative Java decompiler"
echo "  - enjarify: Google's DEX to JAR converter"
echo "  - zipalign: APK optimization"
echo "  - jarsigner: APK signing"
echo ""
echo "Run './decompile-apks.sh' to decompile APKs"
echo "Run './build-optimized-apk.sh <directory>' to build and optimize APKs"
echo "Run './sign-apk.sh <apk> <password>' to sign APKs"
