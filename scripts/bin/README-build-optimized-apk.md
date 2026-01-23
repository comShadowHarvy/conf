# build-optimized-apk.sh

Build and optimize an APK from modified apktool output.

## Usage

```bash
./build-optimized-apk.sh <apktool-directory>
```

## Example

```bash
# After modifying files in bloodv2.2-apktool/
./build-optimized-apk.sh bloodv2.2-apktool

# Output: bloodv2.2-apktool-optimized.apk
```

## Optimization Process

### Step 1: PNG Optimization
- **pngquant**: Lossy compression at 85-95% quality
- **optipng**: Lossless compression (level 7)
- Can reduce image sizes by 30-70%

### Step 2: JPEG Optimization
- **jpegoptim**: 90% quality compression
- Strips metadata (EXIF data)
- Typically 10-30% size reduction

### Step 3: APK Build
- Rebuilds APK from smali code
- Recompresses all resources
- Creates unsigned APK

### Step 4: Zipalign
- Aligns data for optimal Android performance
- Required before signing
- Improves app loading speed

## Requirements

### Required
- apktool
- zipalign (from android-tools)

### Optional (for optimization)
- optipng
- pngquant
- jpegoptim

Install all: `./install-decompilers.sh`

## Output

Creates: `<directory-name>-optimized.apk`

**⚠️ This APK is UNSIGNED and cannot be installed yet!**

Next step: Sign it with `./sign-apk.sh`

## Typical Workflow

```bash
# 1. Decompile
./decompile-apks.sh

# 2. Modify code in bloodv2.2-apktool/
nano bloodv2.2-apktool/smali/com/example/MainActivity.smali

# 3. Build optimized APK
./build-optimized-apk.sh bloodv2.2-apktool

# 4. Sign APK
./sign-apk.sh bloodv2.2-apktool-optimized.apk <password>
```

## Troubleshooting

**"Directory not found"**
- Make sure the apktool directory exists
- Use the directory name, not the APK name

**"apktool build failed"**
- Check for syntax errors in modified smali files
- Verify AndroidManifest.xml is valid
- Check apktool output for specific errors

**Image optimization tools not found**
- Script will continue without optimization
- Install tools: `sudo pacman -S optipng pngquant jpegoptim`

**Permission denied**
- Make executable: `chmod +x build-optimized-apk.sh`

## Size Comparison

Before/after sizes are displayed at the end:
```
Output APK: bloodv2.2-apktool-optimized.apk
Final size: 12M
```

Optimization typically reduces APK size by 10-40% depending on image content.
