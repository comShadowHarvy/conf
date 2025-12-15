# install-decompilers.sh

Install all required tools for Android APK decompilation, optimization, and signing.

## Usage

```bash
./install-decompilers.sh
```

## What It Installs

### Decompilation Tools
- **apktool** - Decompiles APK resources and smali code
- **jadx** - DEX to Java source code decompiler
- **dex2jar** - Converts DEX files to JAR format
- **CFR** - Alternative Java decompiler (better for obfuscated code)
- **enjarify** - Google's DEX to JAR converter (more accurate than dex2jar)

### Build & Signing Tools
- **zipalign** - Optimizes APK alignment for Android
- **jarsigner** - Signs APK files (part of JDK)

### Image Optimization
- **optipng** - Lossless PNG compression
- **pngquant** - Lossy PNG compression (high quality)
- **jpegoptim** - JPEG optimization

## Requirements

- Arch Linux or CachyOS
- Internet connection
- Do NOT run as root

## Installation Sources

- Official Arch repos: apktool, android-tools, JDK, image tools
- AUR (if yay/paru available): jadx
- Manual downloads: CFR, dex2jar, enjarify (from GitHub)

## Post-Installation

All tools will be available in your PATH. Verify with:

```bash
apktool --version
jadx --version
zipalign -h
jarsigner
```

## Troubleshooting

**"Please don't run this script as root"**
- Run as your normal user, the script uses sudo when needed

**AUR helper not found**
- Script will download jadx manually from GitHub

**Permission denied**
- Make executable: `chmod +x install-decompilers.sh`
