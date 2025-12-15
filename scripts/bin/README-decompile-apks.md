# decompile-apks.sh

Automatically decompile all APK files in the current directory.

## Usage

```bash
./decompile-apks.sh
```

## What It Does

Processes every `.apk` file in the current directory and creates three output directories for each:

### Output Directories

1. **`*-apktool/`**
   - Resources (images, layouts, strings)
   - Smali code (Android bytecode)
   - AndroidManifest.xml (decoded)
   - Best for: Modifying resources and low-level code

2. **`*-jadx/`**
   - Decompiled Java source code
   - Readable and well-structured
   - Best for: Understanding app logic

3. **`*-dex/`**
   - Raw DEX files extracted from APK
   - Best for: Manual inspection with other tools

## Example

```bash
# Input files in directory:
bloodv2.2.apk
com.loudtalks.apk

# After running script:
bloodv2.2-apktool/
bloodv2.2-jadx/
bloodv2.2-dex/
com.loudtalks-apktool/
com.loudtalks-jadx/
com.loudtalks-dex/
```

## Features

- ✅ Colored terminal output for easy reading
- ✅ Processes multiple APKs automatically
- ✅ Skips existing directories (won't overwrite)
- ✅ Timeout protection for large APKs (5 minutes)
- ✅ Fallback to minimal decompilation if full fails
- ✅ Parallel processing for faster decompilation

## Requirements

- apktool
- jadx
- unzip

Install with: `./install-decompilers.sh`

## Troubleshooting

**"No APK files found"**
- Make sure you're in a directory with `.apk` files

**"Directory already exists, skipping"**
- Delete old directories if you want to re-decompile:
  ```bash
  rm -rf bloodv2.2-apktool bloodv2.2-jadx bloodv2.2-dex
  ```

**jadx times out or fails**
- Script will automatically try minimal decompilation
- Check `*-jadx/` folder for partial output

**Permission denied**
- Make executable: `chmod +x decompile-apks.sh`
