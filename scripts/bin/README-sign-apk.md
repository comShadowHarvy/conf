# sign-apk.sh

Sign an APK file with a keystore for installation on Android devices.

## Usage

```bash
./sign-apk.sh <input.apk> <password>
```

## Example

```bash
./sign-apk.sh bloodv2.2-apktool-optimized.apk Jbean343

# Output: bloodv2.2-apktool-optimized-signed.apk
```

## Signing Process

### Step 1: Zipalign
- Aligns APK data on 4-byte boundaries
- Required for optimal Android performance
- Creates temporary aligned APK

### Step 2: Sign with jarsigner
- Algorithm: SHA256withRSA
- Uses keystore: `my-release-key.keystore`
- Key alias: `my-key-alias`

### Step 3: Verify Signature
- Confirms signature is valid
- Shows certificate details
- Displays any warnings

## Requirements

- jarsigner (part of JDK)
- zipalign (from android-tools)
- Keystore file: `my-release-key.keystore`

Install with: `./install-decompilers.sh`

## Output

Creates: `<input-name>-signed.apk`

This APK can now be installed on Android devices:
```bash
adb install bloodv2.2-apktool-optimized-signed.apk
```

## Certificate Warnings (NORMAL!)

You will see warnings like:
```
Warning: Invalid certificate chain: PKIX path building failed
```

**This is completely normal for self-signed certificates!**

- The APK is still properly signed
- The APK will install and run correctly
- The warning occurs because the certificate is not from a trusted CA
- This is standard for development/personal APK signing

### What Matters

✅ **"jar signed"** message appears  
✅ **Signed APK file is created**  
✅ **Verification shows signature applied**  

❌ Ignore certificate chain warnings

## Keystore Details

- **File**: `my-release-key.keystore` (must be in current directory)
- **Alias**: `my-key-alias`
- **Algorithm**: SHA256withRSA (2048-bit RSA key)
- **Certificate**: Self-signed, valid until 2053

## Complete Workflow

```bash
# 1. Decompile
./decompile-apks.sh

# 2. Modify code
nano bloodv2.2-apktool/smali/...

# 3. Build optimized APK
./build-optimized-apk.sh bloodv2.2-apktool

# 4. Sign APK
./sign-apk.sh bloodv2.2-apktool-optimized.apk Jbean343

# 5. Install on device
adb install bloodv2.2-apktool-optimized-signed.apk
```

## Troubleshooting

**"Keystore not found"**
- Ensure `my-release-key.keystore` is in the current directory

**"APK file not found"**
- Check the APK path and filename
- Use tab completion to avoid typos

**"jarsigner failed"**
- Verify password is correct
- Check that JDK is installed: `java -version`

**Signature verification fails**
- Check keystore is not corrupted
- Ensure password matches keystore

**Permission denied**
- Make executable: `chmod +x sign-apk.sh`

## Installing the Signed APK

### Via ADB
```bash
adb install bloodv2.2-apktool-optimized-signed.apk
```

### Replace Existing App
```bash
adb install -r bloodv2.2-apktool-optimized-signed.apk
```

### Device Settings
Enable "Install from unknown sources" in Android settings if needed.
