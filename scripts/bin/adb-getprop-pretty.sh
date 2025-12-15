#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
RESET='\033[0m'

# Check if adb is available
if ! command -v adb &> /dev/null; then
    echo -e "${RED}Error: adb command not found${RESET}"
    exit 1
fi

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo -e "${RED}Error: No Android device connected${RESET}"
    exit 1
fi

echo -e "${CYAN}Collecting device information...${RESET}"

echo -e "  ${GRAY}→ Getting device properties...${RESET}"
PROPS=$(adb shell getprop)

echo -e "  ${GRAY}→ Getting installed apps...${RESET}"
INSTALLED_APPS=$(adb shell pm list packages -f | sort)

echo -e "  ${GRAY}→ Getting battery info...${RESET}"
BATTERY_INFO=$(adb shell dumpsys battery)

echo -e "  ${GRAY}→ Getting connectivity info...${RESET}"
CONNECTIVITY_INFO=$(adb shell dumpsys connectivity 2>/dev/null || echo "Not available")

echo -e "  ${GRAY}→ Getting network interfaces...${RESET}"
IFCONFIG_INFO=$(adb shell "ip addr 2>/dev/null || ifconfig 2>/dev/null || echo 'Not available'")

echo -e "  ${GRAY}→ Getting network statistics...${RESET}"
NETSTAT_INFO=$(adb shell "netstat 2>/dev/null | head -100 || ss -an 2>/dev/null | head -100 || echo 'Not available'")

echo -e "  ${GRAY}→ Getting usage statistics (this may take a moment)...${RESET}"
USAGE_STATS=$(timeout 10 adb shell dumpsys usagestats 2>/dev/null | head -1000 || echo "Not available or timed out")

echo -e "  ${GRAY}→ Getting battery statistics (this may take a moment)...${RESET}"
BATTERY_STATS=$(timeout 10 adb shell dumpsys batterystats 2>/dev/null | head -1000 || echo "Not available or timed out")

echo -e "  ${GRAY}→ Getting system settings...${RESET}"
SYSTEM_SETTINGS=$(adb shell settings list system 2>/dev/null | sort || echo "Not available")

# Additional forensics data
echo -e "  ${GRAY}→ Getting memory info...${RESET}"
MEMORY_INFO=$(adb shell dumpsys meminfo 2>/dev/null || echo "Not available")

echo -e "  ${GRAY}→ Getting accounts...${RESET}"
ACCOUNTS_INFO=$(adb shell dumpsys account 2>/dev/null || echo "Not available")

echo -e "  ${GRAY}→ Getting registered apps...${RESET}"
REGISTERED_APPS=$(adb shell "dumpsys account | grep -i com.*$ -o | cut -d' ' -f1 | cut -d} -f1 | grep -v com$" 2>/dev/null | sort -u || echo "Not available")

echo -e "  ${GRAY}→ Getting email addresses...${RESET}"
EMAIL_ADDRESSES=$(adb shell "dumpsys account | grep -E -o '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}'" 2>/dev/null | sort -u || echo "Not available")

echo -e "  ${GRAY}→ Getting boot count...${RESET}"
BOOT_COUNT=$(adb shell "settings list global | grep 'boot_count=' | cut -d= -f2" 2>/dev/null || echo "Not available")

echo -e "  ${GRAY}→ Getting contacts...${RESET}"
CONTACTS=$(adb shell "content query --uri content://contacts/phones/ --projection display_name:number" 2>/dev/null | head -100 || echo "Not available or requires permissions")

echo -e "  ${GRAY}→ Getting call logs...${RESET}"
CALL_LOGS=$(adb shell "content query --uri content://call_log/calls" 2>/dev/null | head -100 || echo "Not available or requires permissions")

echo -e "  ${GRAY}→ Getting SMS messages...${RESET}"
SMS_MESSAGES=$(adb shell "content query --uri content://sms/" 2>/dev/null | head -100 || echo "Not available or requires permissions")

echo -e "  ${GRAY}→ Getting network stats...${RESET}"
NETSTATS=$(adb shell dumpsys netstats 2>/dev/null || echo "Not available")

echo -e "  ${GRAY}→ Getting location info...${RESET}"
LOCATION_INFO=$(adb shell dumpsys location 2>/dev/null || echo "Not available")

echo -e "  ${GRAY}→ Getting notifications...${RESET}"
NOTIFICATIONS=$(adb shell dumpsys notification 2>/dev/null | head -500 || echo "Not available")

echo -e "  ${GRAY}→ Getting WiFi info...${RESET}"
WIFI_INFO=$(adb shell dumpsys wifi 2>/dev/null || echo "Not available")

echo -e "  ${GRAY}→ Getting clipboard...${RESET}"
CLIPBOARD=$(adb shell dumpsys clipboard 2>/dev/null || echo "Not available")

echo -e "  ${GRAY}→ Getting window info...${RESET}"
WINDOW_INFO=$(adb shell dumpsys window 2>/dev/null | head -200 || echo "Not available")

echo -e "  ${GRAY}→ Getting sensor service...${RESET}"
SENSOR_INFO=$(adb shell dumpsys sensorservice 2>/dev/null || echo "Not available")

echo -e "  ${GRAY}→ Getting audio playback...${RESET}"
AUDIO_INFO=$(adb shell dumpsys media.audio_flinger 2>/dev/null || echo "Not available")

echo -e "  ${GRAY}→ Getting fingerprint auth...${RESET}"
FINGERPRINT_INFO=$(adb shell dumpsys fingerprint 2>/dev/null || echo "Not available")

echo -e "  ${GRAY}→ Getting power management...${RESET}"
POWER_INFO=$(adb shell dumpsys power 2>/dev/null || echo "Not available")

echo -e "  ${GRAY}→ Getting crash reports...${RESET}"
DROPBOX_INFO=$(adb shell dumpsys dropbox 2>/dev/null | head -200 || echo "Not available")

echo -e "  ${GRAY}→ Getting telephony/call data...${RESET}"
TELECOM_INFO=$(adb shell dumpsys telecom 2>/dev/null || echo "Not available")

echo -e "  ${GRAY}→ Getting USB history...${RESET}"
USB_INFO=$(adb shell dumpsys usb 2>/dev/null || echo "Not available")

# Ask user if they want to extract secret codes (takes longest)
echo -e "\n${YELLOW}Extract Android secret codes? This may take several minutes.${RESET}"
echo -e "${GRAY}(Secret codes are hidden dialer codes like *#*#4636#*#*)${RESET}"
read -p "Extract secret codes? [y/N]: " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "  ${GRAY}→ Extracting Android secret codes (this may take a while)...${RESET}"
    SECRET_CODES=""
    for pkg in $(adb shell 'pm list packages -s -f' | awk -F 'package:' '{print $2}' | awk -F '=' '{print $2}'); do
        codes=$(adb shell pm dump "$pkg" 2>/dev/null | grep -E 'Scheme: "android_secret_code"|Authority: "[0-9].*"|Authority: "[A-Z].*"')
        if [ -n "$codes" ]; then
            SECRET_CODES+="Package: $pkg\n$codes\n\n"
        fi
    done
    if [ -z "$SECRET_CODES" ]; then
        SECRET_CODES="No secret codes found"
    fi
else
    echo -e "  ${GRAY}Skipping secret codes extraction${RESET}"
    SECRET_CODES="Skipped by user"
fi

echo -e "  ${GRAY}→ Scanning WiFi networks (AirScope)...${RESET}"
echo -e "    ${GRAY}Disabling WiFi...${RESET}"
adb shell svc wifi disable 2>/dev/null
sleep 2
echo -e "    ${GRAY}Enabling WiFi...${RESET}"
adb shell svc wifi enable 2>/dev/null
sleep 5
echo -e "    ${GRAY}Collecting scan results...${RESET}"

WIFI_SCAN=$(adb shell dumpsys wifi 2>/dev/null | \
    grep "Networks filtered out due" | \
    sed 's/.*Networks filtered out due [^:]*: //' | \
    tr '/' '\n' | \
    grep -E '[0-9a-f]{2}(:[0-9a-f]{2}){5}' | \
    sed -E 's/([^:]+):([0-9a-f:]+)\(([^)]+)\)(-?[0-9]+)/\1,\2,\3,\4/' | \
    awk -F, 'NF==4 {print "SSID=" $1 ",BSSID=" $2 ",Band=" $3 ",RSSI=" $4 "dBm"}')

if [ -z "$WIFI_SCAN" ]; then
    WIFI_SCAN="No WiFi networks found or scan failed"
fi

# Get device info and create directories BEFORE MVT prompt
DEVICE_BRAND=$(echo "$PROPS" | grep "\[ro.product.brand\]" | sed -n 's/\[.*\]: \[\(.*\)\]/\1/p' | tr '[:upper:]' '[:lower:]')
DEVICE_MODEL=$(echo "$PROPS" | grep "\[ro.product.model\]" | sed -n 's/\[.*\]: \[\(.*\)\]/\1/p' | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_DIR="$HOME/log/$DEVICE_BRAND"
DUMP_DIR="$LOG_DIR/${DEVICE_MODEL}_dump_${TIMESTAMP}"
LOG_FILE="$LOG_DIR/${DEVICE_MODEL}.md"
mkdir -p "$LOG_DIR"
mkdir -p "$DUMP_DIR"

# Ask user if they want to generate bugreport and run MVT
echo -e "\n${YELLOW}Run security analysis with Mobile Verification Toolkit (MVT)?${RESET}"
echo -e "${GRAY}Options:${RESET}"
echo -e "${GRAY}  [1] Full bugreport + MVT (5-10 min, most thorough)${RESET}"
echo -e "${GRAY}  [2] MVT ADB mode only (2-3 min, direct device scan)${RESET}"
echo -e "${GRAY}  [N] Skip security analysis${RESET}"
read -p "Choice [1/2/N]: " -n 1 -r
echo

BUGREPORT_GENERATED=false
MVT_ANALYSIS="Skipped by user"

if [[ $REPLY =~ ^[1]$ ]]; then
    # Option 1: Full bugreport + MVT
    echo -e "  ${GRAY}→ Generating bugreport (this will take several minutes)...${RESET}"
    
    # Check if mvt-android is installed
    MVT_INSTALLED=false
    if command -v mvt-android &> /dev/null; then
        MVT_INSTALLED=true
        echo -e "  ${GREEN}✓ MVT found${RESET}"
    else
        echo -e "  ${YELLOW}⚠ MVT not found - will skip analysis${RESET}"
        echo -e "    ${GRAY}Install with: pip install mvt${RESET}"
    fi
    
    BUGREPORT_FILE="$DUMP_DIR/bugreport.zip"
    
    if adb shell 'command -v bugreportz' &> /dev/null; then
        adb bugreport "$BUGREPORT_FILE" 2>&1 | while IFS= read -r line; do
            if [[ $line == *%* ]]; then
                echo -e "\r  ${CYAN}Progress: $line${RESET}\c"
            fi
        done
        echo
    else
        # Fallback for older devices
        BUGREPORT_FILE="${BUGREPORT_FILE%.zip}.txt"
        adb bugreport > "$BUGREPORT_FILE" 2>&1
    fi
    
    if [ -f "$BUGREPORT_FILE" ]; then
        echo -e "  ${GREEN}✓ Bugreport saved to: $BUGREPORT_FILE${RESET}"
        BUGREPORT_GENERATED=true
        MVT_MODE="bugreport"
        
        # Run MVT analysis if installed
        if [ "$MVT_INSTALLED" = true ]; then
            echo -e "\n  ${GRAY}→ Running MVT analysis (this may take a few minutes)...${RESET}"
            MVT_OUTPUT_DIR="$DUMP_DIR/mvt_analysis"
            mkdir -p "$MVT_OUTPUT_DIR"
            
            # Run MVT with verbose output
            echo -e "  ${GRAY}Command: mvt-android check-bugreport --output \"$MVT_OUTPUT_DIR\" \"$BUGREPORT_FILE\"${RESET}"
            echo -e "  ${YELLOW}Note: This may take 2-5 minutes depending on bugreport size${RESET}"
            
            if mvt-android check-bugreport --output "$MVT_OUTPUT_DIR" "$BUGREPORT_FILE" > "$MVT_OUTPUT_DIR/mvt.log" 2>&1; then
                MVT_EXIT_CODE=0
            else
                MVT_EXIT_CODE=$?
            fi
            
            # Always show the log output
            echo -e "\n  ${GRAY}MVT Output:${RESET}"
            tail -20 "$MVT_OUTPUT_DIR/mvt.log" | while IFS= read -r line; do
                echo -e "    ${GRAY}$line${RESET}"
            done
            
            if [ $MVT_EXIT_CODE -eq 0 ]; then
                echo -e "\n  ${GREEN}✓ MVT analysis complete${RESET}"
                
                # List all JSON files created
                echo -e "  ${GRAY}Files created:${RESET}"
                ls -lh "$MVT_OUTPUT_DIR"/*.json 2>/dev/null | awk '{print "    " $9 " (" $5 ")"}' || echo "    No JSON files found"
                
                # Check for detections in all timeline JSON files
                DETECTION_COUNT=0
                DETECTION_FILES=""
                
                for json_file in "$MVT_OUTPUT_DIR"/*.json; do
                    if [ -f "$json_file" ]; then
                        # Check if file contains detections (results array with ioc_matches)
                        if grep -q '"ioc_matches"' "$json_file" 2>/dev/null; then
                            matches=$(jq '[.[] | select(.ioc_matches != null)] | length' "$json_file" 2>/dev/null || echo "0")
                            if [ "$matches" -gt 0 ]; then
                                DETECTION_COUNT=$((DETECTION_COUNT + matches))
                                DETECTION_FILES="$DETECTION_FILES\n  - $(basename "$json_file"): $matches detection(s)"
                            fi
                        fi
                    fi
                done
                
                if [ "$DETECTION_COUNT" -gt 0 ]; then
                    MVT_ANALYSIS="⚠️ WARNING: $DETECTION_COUNT potential indicator(s) of compromise detected!\nFiles with detections:$DETECTION_FILES\n\nFull results in: $MVT_OUTPUT_DIR"
                    echo -e "  ${RED}⚠️ WARNING: $DETECTION_COUNT potential indicator(s) detected${RESET}"
                else
                    MVT_ANALYSIS="✓ No indicators of compromise detected\nAnalysis completed successfully\nResults in: $MVT_OUTPUT_DIR"
                    echo -e "  ${GREEN}✓ No indicators of compromise detected${RESET}"
                fi
            else
                MVT_ANALYSIS="MVT analysis failed with exit code $MVT_EXIT_CODE\nCheck $MVT_OUTPUT_DIR/mvt.log for details"
                echo -e "  ${RED}✗ MVT analysis failed (exit code: $MVT_EXIT_CODE)${RESET}"
                echo -e "  ${GRAY}Check log: $MVT_OUTPUT_DIR/mvt.log${RESET}"
            fi
        fi
    else
        echo -e "  ${RED}✗ Bugreport generation failed${RESET}"
        
        # Try MVT in ADB mode as fallback
        if [ "$MVT_INSTALLED" = true ]; then
            echo -e "\n  ${YELLOW}→ Falling back to MVT ADB mode (direct device analysis)...${RESET}"
            MVT_OUTPUT_DIR="$DUMP_DIR/mvt_analysis"
            mkdir -p "$MVT_OUTPUT_DIR"
            MVT_MODE="adb"
            
            echo -e "  ${GRAY}Command: mvt-android check-adb --fast --output \"$MVT_OUTPUT_DIR\"${RESET}"
            
            if mvt-android check-adb --fast --output "$MVT_OUTPUT_DIR" > "$MVT_OUTPUT_DIR/mvt.log" 2>&1; then
                MVT_EXIT_CODE=0
            else
                MVT_EXIT_CODE=$?
            fi
            
            # Show the log output
            echo -e "\n  ${GRAY}MVT Output:${RESET}"
            tail -20 "$MVT_OUTPUT_DIR/mvt.log" | while IFS= read -r line; do
                echo -e "    ${GRAY}$line${RESET}"
            done
            
            if [ $MVT_EXIT_CODE -eq 0 ]; then
                echo -e "\n  ${GREEN}✓ MVT ADB analysis complete${RESET}"
                BUGREPORT_GENERATED=false
                
                # List all JSON files created
                echo -e "  ${GRAY}Files created:${RESET}"
                ls -lh "$MVT_OUTPUT_DIR"/*.json 2>/dev/null | awk '{print "    " $9 " (" $5 ")"}' || echo "    No JSON files found"
                
                # Check for detections
                DETECTION_COUNT=0
                DETECTION_FILES=""
                
                for json_file in "$MVT_OUTPUT_DIR"/*.json; do
                    if [ -f "$json_file" ]; then
                        if grep -q '"ioc_matches"' "$json_file" 2>/dev/null; then
                            matches=$(jq '[.[] | select(.ioc_matches != null)] | length' "$json_file" 2>/dev/null || echo "0")
                            if [ "$matches" -gt 0 ]; then
                                DETECTION_COUNT=$((DETECTION_COUNT + matches))
                                DETECTION_FILES="$DETECTION_FILES\n  - $(basename "$json_file"): $matches detection(s)"
                            fi
                        fi
                    fi
                done
                
                if [ "$DETECTION_COUNT" -gt 0 ]; then
                    MVT_ANALYSIS="⚠️ WARNING: $DETECTION_COUNT potential indicator(s) of compromise detected!\nFiles with detections:$DETECTION_FILES\n\nAnalysis mode: Direct ADB (bugreport failed)\nFull results in: $MVT_OUTPUT_DIR"
                    echo -e "  ${RED}⚠️ WARNING: $DETECTION_COUNT potential indicator(s) detected${RESET}"
                else
                    MVT_ANALYSIS="✓ No indicators of compromise detected\nAnalysis mode: Direct ADB (bugreport failed)\nResults in: $MVT_OUTPUT_DIR"
                    echo -e "  ${GREEN}✓ No indicators of compromise detected${RESET}"
                fi
            else
                MVT_ANALYSIS="Bugreport generation failed. MVT ADB analysis also failed with exit code $MVT_EXIT_CODE\nCheck $MVT_OUTPUT_DIR/mvt.log for details"
                echo -e "  ${RED}✗ MVT ADB analysis also failed (exit code: $MVT_EXIT_CODE)${RESET}"
            fi
        else
            MVT_ANALYSIS="Bugreport generation failed and MVT not installed"
        fi
    fi
elif [[ $REPLY =~ ^[2]$ ]]; then
    # Option 2: MVT ADB mode only (faster, no bugreport)
    echo -e "  ${GRAY}→ Running MVT in ADB mode (direct device scan)...${RESET}"
    
    # Check if mvt-android is installed
    if command -v mvt-android &> /dev/null; then
        MVT_OUTPUT_DIR="$DUMP_DIR/mvt_analysis"
        mkdir -p "$MVT_OUTPUT_DIR"
        MVT_MODE="adb"
        
        echo -e "  ${GREEN}✓ MVT found${RESET}"
        echo -e "  ${GRAY}Restarting ADB server to clear busy state...${RESET}"
        adb kill-server > /dev/null 2>&1
        sleep 1
        adb start-server > /dev/null 2>&1
        sleep 2
        echo -e "  ${GRAY}Running MVT modules (skipping ChromeHistory due to device restrictions)...${RESET}"
        
        # Run MVT modules separately to avoid ChromeHistory blocking everything
        # We'll run the key modules that don't have device busy issues
        MODULES="SMS,Packages,Settings,DumpsysReceivers,DumpsysAppOps,Processes,RootBinaries"
        echo -e "  ${GRAY}Modules: $MODULES${RESET}"
        
        if mvt-android check-adb --fast --module "$MODULES" --output "$MVT_OUTPUT_DIR" > "$MVT_OUTPUT_DIR/mvt.log" 2>&1; then
            MVT_EXIT_CODE=0
        else
            MVT_EXIT_CODE=$?
        fi
        
        # Show the log output
        echo -e "\n  ${GRAY}MVT Output:${RESET}"
        tail -20 "$MVT_OUTPUT_DIR/mvt.log" | while IFS= read -r line; do
            echo -e "    ${GRAY}$line${RESET}"
        done
        
        if [ $MVT_EXIT_CODE -eq 0 ]; then
            echo -e "\n  ${GREEN}✓ MVT ADB analysis complete${RESET}"
            
            # List all JSON files created
            echo -e "  ${GRAY}Files created:${RESET}"
            ls -lh "$MVT_OUTPUT_DIR"/*.json 2>/dev/null | awk '{print "    " $9 " (" $5 ")"}' || echo "    No JSON files found"
            
            # Check for detections
            DETECTION_COUNT=0
            DETECTION_FILES=""
            
            for json_file in "$MVT_OUTPUT_DIR"/*.json; do
                if [ -f "$json_file" ]; then
                    if grep -q '"ioc_matches"' "$json_file" 2>/dev/null; then
                        matches=$(jq '[.[] | select(.ioc_matches != null)] | length' "$json_file" 2>/dev/null || echo "0")
                        if [ "$matches" -gt 0 ]; then
                            DETECTION_COUNT=$((DETECTION_COUNT + matches))
                            DETECTION_FILES="$DETECTION_FILES\n  - $(basename "$json_file"): $matches detection(s)"
                        fi
                    fi
                fi
            done
            
            if [ "$DETECTION_COUNT" -gt 0 ]; then
                MVT_ANALYSIS="⚠️ WARNING: $DETECTION_COUNT potential indicator(s) of compromise detected!\nFiles with detections:$DETECTION_FILES\n\nAnalysis mode: Direct ADB\nFull results in: $MVT_OUTPUT_DIR"
                echo -e "  ${RED}⚠️ WARNING: $DETECTION_COUNT potential indicator(s) detected${RESET}"
            else
                MVT_ANALYSIS="✓ No indicators of compromise detected\nAnalysis mode: Direct ADB\nResults in: $MVT_OUTPUT_DIR"
                echo -e "  ${GREEN}✓ No indicators of compromise detected${RESET}"
            fi
        else
            MVT_ANALYSIS="MVT ADB analysis failed with exit code $MVT_EXIT_CODE\nCheck $MVT_OUTPUT_DIR/mvt.log for details"
            echo -e "  ${RED}✗ MVT ADB analysis failed (exit code: $MVT_EXIT_CODE)${RESET}"
            echo -e "  ${GRAY}Check log: $MVT_OUTPUT_DIR/mvt.log${RESET}"
        fi
    else
        echo -e "  ${RED}✗ MVT not found${RESET}"
        echo -e "    ${GRAY}Install with: pip install mvt${RESET}"
        MVT_ANALYSIS="MVT not installed"
    fi
else
    echo -e "  ${GRAY}Skipping security analysis${RESET}"
fi

# Initialize markdown log file with header (directories already created)
cat > "$LOG_FILE" << EOF
# Android Device Properties

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')  
**Brand:** $DEVICE_BRAND  
**Model:** $DEVICE_MODEL

---

EOF

# Helper function to get property value
get_prop() {
    echo "$PROPS" | grep "\[$1\]" | sed -n 's/\[.*\]: \[\(.*\)\]/\1/p'
}

# Helper function to print section header
print_header() {
    local header="\n${BOLD}${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    local title="${BOLD}${CYAN}║${RESET}  $1"
    local footer="${BOLD}${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo -e "$header"
    echo -e "$title"
    echo -e "$footer"
}

# Helper function to print property
print_prop() {
    local label="$1"
    local value="$2"
    local color="$3"
    printf "  ${color}%-20s${RESET} ${WHITE}%s${RESET}\n" "$label:" "$value"
}

# Function to save individual dump files
save_dump_file() {
    local filename="$1"
    local content="$2"
    echo "$content" > "$DUMP_DIR/$filename"
}

# Function to save all data to markdown log
save_to_markdown() {
    # Device Overview
    cat >> "$LOG_FILE" << EOF
## 📱 Device Overview

- **Manufacturer:** $(get_prop ro.product.manufacturer)
- **Brand:** $(get_prop ro.product.brand)
- **Model:** $(get_prop ro.product.model)
- **Device:** $(get_prop ro.product.device)
- **Board:** $(get_prop ro.product.board)
- **Android Version:** $(get_prop ro.build.version.release)
- **SDK Version:** $(get_prop ro.build.version.sdk)
- **Security Patch:** $(get_prop ro.build.version.security_patch)

## 🔧 Hardware Information

- **CPU ABI:** $(get_prop ro.product.cpu.abi)
- **CPU ABI List:** $(get_prop ro.product.cpu.abilist)
- **Hardware:** $(get_prop ro.hardware)
- **Bootloader:** $(get_prop ro.bootloader)
- **Radio Version:** $(get_prop gsm.version.baseband)

## 🏗️ Build Information

- **Build ID:** $(get_prop ro.build.id)
- **Build Display:** $(get_prop ro.build.display.id)
- **Fingerprint:** $(get_prop ro.build.fingerprint)
- **Build Type:** $(get_prop ro.build.type)
- **Build Tags:** $(get_prop ro.build.tags)

EOF

    # Save detailed properties by category
    save_category "ro.product" "📦 Product Properties"
    save_category "ro.build" "🏗️ Build Properties"
    save_category "ro.hardware" "⚙️ Hardware Properties"
    save_category "ro.boot" "🚀 Boot Properties"
    save_category "sys" "💻 System Properties"
    save_category "dalvik" "☕ Dalvik/ART Properties"
    save_category "persist" "💾 Persistent Properties"
    save_category "net\|wifi\|gsm" "📡 Network Properties"
    save_category "security\|selinux" "🔒 Security Properties"
    save_category "init" "⚡ Init Properties"
    save_category "debug" "🐛 Debug Properties"
    
    # Other properties
    echo "" >> "$LOG_FILE"
    echo "## 📋 Other Properties" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$PROPS" | grep -v "^\[ro\.product\|^\[ro\.build\|^\[ro\.hardware\|^\[ro\.boot\|^\[sys\|^\[dalvik\|^\[persist\|^\[net\|^\[wifi\|^\[gsm\|^\[security\|^\[selinux\|^\[init\|^\[debug" | sort | while IFS= read -r line; do
        prop=$(echo "$line" | sed -n 's/\[\(.*\)\]: \[\(.*\)\]/\1/p')
        value=$(echo "$line" | sed -n 's/\[\(.*\)\]: \[\(.*\)\]/\2/p')
        echo "$prop = $value" >> "$LOG_FILE"
    done
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Installed Apps
    echo "" >> "$LOG_FILE"
    echo "## 📦 Installed Applications" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    local app_count=$(echo "$INSTALLED_APPS" | wc -l)
    echo "**Total Apps:** $app_count" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$INSTALLED_APPS" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Battery Info
    echo "" >> "$LOG_FILE"
    echo "## 🔋 Battery Information" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$BATTERY_INFO" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Connectivity Info
    echo "" >> "$LOG_FILE"
    echo "## 🌐 Connectivity Information" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$CONNECTIVITY_INFO" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Network Interface Config
    echo "" >> "$LOG_FILE"
    echo "## 🔌 Network Interfaces (ifconfig)" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$IFCONFIG_INFO" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Network Statistics
    echo "" >> "$LOG_FILE"
    echo "## 📊 Network Statistics (netstat)" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$NETSTAT_INFO" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Usage Statistics
    echo "" >> "$LOG_FILE"
    echo "## 📈 Usage Statistics" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$USAGE_STATS" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Battery Stats
    echo "" >> "$LOG_FILE"
    echo "## 🔌 Battery Statistics" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$BATTERY_STATS" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # System Settings
    echo "" >> "$LOG_FILE"
    echo "## ⚙️ System Settings" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$SYSTEM_SETTINGS" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Memory Info
    echo "" >> "$LOG_FILE"
    echo "## 🧠 Memory Information" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$MEMORY_INFO" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Accounts
    echo "" >> "$LOG_FILE"
    echo "## 👤 Account Information" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "### Registered Apps with Accounts" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$REGISTERED_APPS" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "### Email Addresses" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$EMAIL_ADDRESSES" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "### Full Account Details" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$ACCOUNTS_INFO" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Boot Count
    echo "" >> "$LOG_FILE"
    echo "## 🔄 Boot Statistics" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "**Total Reboots:** $BOOT_COUNT" >> "$LOG_FILE"
    
    # Contacts & Communications
    echo "" >> "$LOG_FILE"
    echo "## 📞 Contacts & Communications" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "### Contacts" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$CONTACTS" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "### Call Logs" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$CALL_LOGS" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "### SMS Messages" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$SMS_MESSAGES" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Network Stats
    echo "" >> "$LOG_FILE"
    echo "## 📊 Network Statistics (Detailed)" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$NETSTATS" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Location
    echo "" >> "$LOG_FILE"
    echo "## 📍 Location Services" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$LOCATION_INFO" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Notifications
    echo "" >> "$LOG_FILE"
    echo "## 🔔 Notifications" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$NOTIFICATIONS" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # WiFi
    echo "" >> "$LOG_FILE"
    echo "## 📶 WiFi Information" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$WIFI_INFO" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Clipboard
    echo "" >> "$LOG_FILE"
    echo "## 📋 Clipboard History" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$CLIPBOARD" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Windows
    echo "" >> "$LOG_FILE"
    echo "## 🖥️ Window Information" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$WINDOW_INFO" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Sensors
    echo "" >> "$LOG_FILE"
    echo "## 🎯 Sensor Activity" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$SENSOR_INFO" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Audio
    echo "" >> "$LOG_FILE"
    echo "## 🔊 Audio Playback History" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$AUDIO_INFO" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Fingerprint
    echo "" >> "$LOG_FILE"
    echo "## 👆 Fingerprint Authentication" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$FINGERPRINT_INFO" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Power
    echo "" >> "$LOG_FILE"
    echo "## ⚡ Power Management" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$POWER_INFO" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Dropbox/Crashes
    echo "" >> "$LOG_FILE"
    echo "## 🐞 System Crashes & Events" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$DROPBOX_INFO" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Telephony
    echo "" >> "$LOG_FILE"
    echo "## 📱 Telephony/Call System" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$TELECOM_INFO" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # USB
    echo "" >> "$LOG_FILE"
    echo "## 🔌 USB Connection History" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$USB_INFO" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Secret Codes
    echo "" >> "$LOG_FILE"
    echo "## 🔐 Android Secret Dialer Codes" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo -e "$SECRET_CODES" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # WiFi Scan (AirScope)
    echo "" >> "$LOG_FILE"
    echo "## 📡 WiFi Network Scan (AirScope)" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    if [ "$WIFI_SCAN" = "No WiFi networks found or scan failed" ]; then
        echo "*No WiFi networks detected*" >> "$LOG_FILE"
    else
        echo "\`\`\`" >> "$LOG_FILE"
        echo "$WIFI_SCAN" | awk -F'[=,]' '
        BEGIN {
            printf "%-32s %-7s %-10s %s\n", "SSID", "BAND", "RSSI", "BSSID"
            print "--------------------------------------------------------------------------------"
        }
        {
            for(i=1;i<=NF;i++) gsub(/^ +| +$/, "", $i)
            ssid=$2; bssid=$4; band=$6; rssi=$8
            gsub(" dBm","",rssi)
            if (ssid=="" || bssid=="" || band=="" || rssi=="") next
            if (!(bssid in best) || rssi > best[bssid]) {
                best[bssid]=rssi
                data[bssid]=sprintf("%-32s %-7s %-10s %s", ssid, band, rssi " dBm", bssid)
            }
        }
        END {
            for (b in data) print data[b]
        }' | sort -t' ' -k3 -n -r >> "$LOG_FILE"
        echo "\`\`\`" >> "$LOG_FILE"
    fi
    
    # Bugreport and MVT Analysis
    echo "" >> "$LOG_FILE"
    echo "## 🐛 Security Analysis" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "### Bugreport" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    if [ "$BUGREPORT_GENERATED" = true ]; then
        echo "**Status:** ✓ Generated" >> "$LOG_FILE"
        echo "**Location:** \`$BUGREPORT_FILE\`" >> "$LOG_FILE"
    else
        echo "**Status:** Skipped or failed" >> "$LOG_FILE"
    fi
    echo "" >> "$LOG_FILE"
    echo "### Mobile Verification Toolkit (MVT) Analysis" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    if [ -n "${MVT_MODE:-}" ]; then
        echo "**Analysis Mode:** ${MVT_MODE}" >> "$LOG_FILE"
        echo "" >> "$LOG_FILE"
    fi
    echo "\`\`\`" >> "$LOG_FILE"
    echo -e "$MVT_ANALYSIS" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    
    # Dump directory info
    echo "" >> "$LOG_FILE"
    echo "---" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "## 📁 Additional Data Files" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "Individual data dumps saved to: \`$DUMP_DIR\`" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "### Files included:" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "- \`device_info.txt\` - Basic device information" >> "$LOG_FILE"
    echo "- \`installed_apps.txt\` - List of all installed applications" >> "$LOG_FILE"
    echo "- \`registered_apps.txt\` - Apps with registered accounts" >> "$LOG_FILE"
    echo "- \`emails.txt\` - Email addresses found on device" >> "$LOG_FILE"
    echo "- \`contacts.txt\` - Contact information" >> "$LOG_FILE"
    echo "- \`call_logs.txt\` - Call history" >> "$LOG_FILE"
    echo "- \`sms.txt\` - SMS messages" >> "$LOG_FILE"
    echo "- \`wifi_scan.txt\` - WiFi network scan results" >> "$LOG_FILE"
    echo "- \`battery_info.txt\` - Battery information" >> "$LOG_FILE"
    echo "- \`network_info.txt\` - Network configuration" >> "$LOG_FILE"
    echo "- \`system_settings.txt\` - System settings" >> "$LOG_FILE"
    echo "- \`secret_codes.txt\` - Android secret dialer codes" >> "$LOG_FILE"
    if [ "$BUGREPORT_GENERATED" = true ]; then
        echo "- \`bugreport.zip\` - Full Android bugreport" >> "$LOG_FILE"
        echo "- \`mvt_analysis/\` - MVT security analysis results" >> "$LOG_FILE"
    fi
}

# Function to save a category to markdown
save_category() {
    local pattern="$1"
    local title="$2"
    
    echo "" >> "$LOG_FILE"
    echo "## $title" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "\`\`\`" >> "$LOG_FILE"
    echo "$PROPS" | grep "^\[$pattern" | sort | while IFS= read -r line; do
        prop=$(echo "$line" | sed -n 's/\[\(.*\)\]: \[\(.*\)\]/\1/p')
        value=$(echo "$line" | sed -n 's/\[\(.*\)\]: \[\(.*\)\]/\2/p')
        echo "$prop = $value" >> "$LOG_FILE"
    done
    echo "\`\`\`" >> "$LOG_FILE"
}

# Save all data to markdown log immediately
save_to_markdown

# Save individual dump files
echo -e "${GRAY}Saving individual data files to dump directory...${RESET}"
save_dump_file "device_info.txt" "$(echo "$PROPS" | grep -E 'ro.product.model|ro.product.manufacturer|ro.build.version')"
save_dump_file "installed_apps.txt" "$INSTALLED_APPS"
save_dump_file "registered_apps.txt" "$REGISTERED_APPS"
save_dump_file "emails.txt" "$EMAIL_ADDRESSES"
save_dump_file "contacts.txt" "$CONTACTS"
save_dump_file "call_logs.txt" "$CALL_LOGS"
save_dump_file "sms.txt" "$SMS_MESSAGES"
save_dump_file "wifi_scan.txt" "$WIFI_SCAN"
save_dump_file "battery_info.txt" "$BATTERY_INFO"
save_dump_file "network_info.txt" "$IFCONFIG_INFO"
save_dump_file "system_settings.txt" "$SYSTEM_SETTINGS"
save_dump_file "secret_codes.txt" "$SECRET_CODES"

clear

# Main header
echo -e "${BOLD}${WHITE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║          🤖  ANDROID DEVICE INFORMATION  🤖                ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e "${CYAN}💾 Log saved to: ${WHITE}$LOG_FILE${RESET}\n"

# Device Overview
print_header "📱 DEVICE OVERVIEW"
print_prop "Manufacturer" "$(get_prop ro.product.manufacturer)" "$GREEN"
print_prop "Brand" "$(get_prop ro.product.brand)" "$GREEN"
print_prop "Model" "$(get_prop ro.product.model)" "$GREEN"
print_prop "Device" "$(get_prop ro.product.device)" "$GREEN"
print_prop "Board" "$(get_prop ro.product.board)" "$CYAN"
print_prop "Android Version" "$(get_prop ro.build.version.release)" "$YELLOW"
print_prop "SDK Version" "$(get_prop ro.build.version.sdk)" "$YELLOW"
print_prop "Security Patch" "$(get_prop ro.build.version.security_patch)" "$YELLOW"

print_header "🔧 HARDWARE INFORMATION"
print_prop "CPU ABI" "$(get_prop ro.product.cpu.abi)" "$MAGENTA"
print_prop "CPU ABI2" "$(get_prop ro.product.cpu.abilist)" "$MAGENTA"
print_prop "Hardware" "$(get_prop ro.hardware)" "$MAGENTA"
print_prop "Bootloader" "$(get_prop ro.bootloader)" "$BLUE"
print_prop "Radio Version" "$(get_prop gsm.version.baseband)" "$CYAN"

print_header "🏗️  BUILD INFORMATION"
print_prop "Build ID" "$(get_prop ro.build.id)" "$YELLOW"
print_prop "Build Display" "$(get_prop ro.build.display.id)" "$YELLOW"
print_prop "Fingerprint" "$(get_prop ro.build.fingerprint)" "$YELLOW"
print_prop "Build Type" "$(get_prop ro.build.type)" "$YELLOW"
print_prop "Build Tags" "$(get_prop ro.build.tags)" "$YELLOW"

echo -e "\n${BOLD}${WHITE}Press ENTER to see detailed properties...${RESET}"
read -r

# Function to print properties by category
print_category() {
    local pattern="$1"
    local title="$2"
    local color="$3"
    
    print_header "$title"
    
    echo "$PROPS" | grep "^\[$pattern" | sort | while IFS= read -r line; do
        prop=$(echo "$line" | sed -n 's/\[\(.*\)\]: \[\(.*\)\]/\1/p')
        value=$(echo "$line" | sed -n 's/\[\(.*\)\]: \[\(.*\)\]/\2/p')
        printf "  ${color}%-50s${RESET} ${WHITE}%s${RESET}\n" "$prop" "$value"
    done
    
    echo -e "\n${GRAY}Press ENTER for next section...${RESET}"
    read -r
}

# Detailed sections
print_category "ro.product" "📦 PRODUCT PROPERTIES" "$GREEN"
print_category "ro.build" "🏗️  BUILD PROPERTIES" "$YELLOW"
print_category "ro.hardware" "⚙️  HARDWARE PROPERTIES" "$MAGENTA"
print_category "ro.boot" "🚀 BOOT PROPERTIES" "$BLUE"
print_category "sys" "💻 SYSTEM PROPERTIES" "$BLUE"
print_category "dalvik" "☕ DALVIK/ART PROPERTIES" "$RED"
print_category "persist" "💾 PERSISTENT PROPERTIES" "$MAGENTA"
print_category "net\|wifi\|gsm" "📡 NETWORK PROPERTIES" "$CYAN"
print_category "security\|selinux" "🔒 SECURITY PROPERTIES" "$RED"
print_category "init" "⚡ INIT PROPERTIES" "$CYAN"
print_category "debug" "🐛 DEBUG PROPERTIES" "$GRAY"

# All other properties
print_header "📋 OTHER PROPERTIES"
echo "$PROPS" | grep -v "^\[ro\.product\|^\[ro\.build\|^\[ro\.hardware\|^\[ro\.boot\|^\[sys\|^\[dalvik\|^\[persist\|^\[net\|^\[wifi\|^\[gsm\|^\[security\|^\[selinux\|^\[init\|^\[debug" | sort | while IFS= read -r line; do
    prop=$(echo "$line" | sed -n 's/\[\(.*\)\]: \[\(.*\)\]/\1/p')
    value=$(echo "$line" | sed -n 's/\[\(.*\)\]: \[\(.*\)\]/\2/p')
    printf "  ${WHITE}%-50s${RESET} ${GRAY}%s${RESET}\n" "$prop" "$value"
done

echo -e "\n${GRAY}Press ENTER for next section...${RESET}"
read -r

# Installed Applications
print_header "📦 INSTALLED APPLICATIONS"
APP_COUNT=$(echo "$INSTALLED_APPS" | wc -l)
echo -e "  ${GREEN}Total Applications:${RESET} ${WHITE}$APP_COUNT${RESET}\n"
echo "$INSTALLED_APPS" | while IFS= read -r line; do
    # Parse package format: package:/path/to.apk=com.package.name
    apk_path=$(echo "$line" | sed -n 's/package:\(.*\)=.*/\1/p')
    package_name=$(echo "$line" | sed -n 's/package:.*=\(.*\)/\1/p')
    printf "  ${CYAN}%-50s${RESET} ${GRAY}%s${RESET}\n" "$package_name" "$apk_path"
done

echo -e "\n${GRAY}Press ENTER for next section...${RESET}"
read -r

# Battery Information
print_header "🔋 BATTERY INFORMATION"
echo "$BATTERY_INFO" | while IFS= read -r line; do
    echo -e "  ${YELLOW}$line${RESET}"
done

echo -e "\n${GRAY}Press ENTER for next section...${RESET}"
read -r

# Connectivity Information
print_header "🌐 CONNECTIVITY INFORMATION"
echo "$CONNECTIVITY_INFO" | head -50 | while IFS= read -r line; do
    echo -e "  ${CYAN}$line${RESET}"
done
echo -e "\n  ${GRAY}(Truncated - see full output in log file)${RESET}"

echo -e "\n${GRAY}Press ENTER for next section...${RESET}"
read -r

# Network Interfaces
print_header "🔌 NETWORK INTERFACES (ifconfig)"
echo "$IFCONFIG_INFO" | while IFS= read -r line; do
    echo -e "  ${GREEN}$line${RESET}"
done

echo -e "\n${GRAY}Press ENTER for next section...${RESET}"
read -r

# Network Statistics
print_header "📊 NETWORK STATISTICS (netstat)"
echo "$NETSTAT_INFO" | head -50 | while IFS= read -r line; do
    echo -e "  ${BLUE}$line${RESET}"
done
echo -e "\n  ${GRAY}(Truncated - see full output in log file)${RESET}"

echo -e "\n${GRAY}Press ENTER for next section...${RESET}"
read -r

# Usage Statistics
print_header "📈 USAGE STATISTICS"
echo "$USAGE_STATS" | head -50 | while IFS= read -r line; do
    echo -e "  ${MAGENTA}$line${RESET}"
done
echo -e "\n  ${GRAY}(Truncated - see full output in log file)${RESET}"

echo -e "\n${GRAY}Press ENTER for next section...${RESET}"
read -r

# Battery Statistics
print_header "🔌 BATTERY STATISTICS"
echo "$BATTERY_STATS" | head -50 | while IFS= read -r line; do
    echo -e "  ${YELLOW}$line${RESET}"
done
echo -e "\n  ${GRAY}(Truncated - see full output in log file)${RESET}"

echo -e "\n${GRAY}Press ENTER for next section...${RESET}"
read -r

# System Settings
print_header "⚙️ SYSTEM SETTINGS"
echo "$SYSTEM_SETTINGS" | while IFS= read -r line; do
    echo -e "  ${WHITE}$line${RESET}"
done

echo -e "\n${GRAY}Press ENTER for next section...${RESET}"
read -r

# Secret Codes
print_header "🔐 ANDROID SECRET DIALER CODES"
if [ "$SECRET_CODES" = "No secret codes found" ]; then
    echo -e "  ${GRAY}No secret codes found${RESET}"
else
    echo -e "$SECRET_CODES" | while IFS= read -r line; do
        if [[ $line == Package:* ]]; then
            echo -e "  ${CYAN}$line${RESET}"
        elif [[ $line == *Scheme:* ]] || [[ $line == *Authority:* ]]; then
            echo -e "    ${GREEN}$line${RESET}"
        else
            echo -e "  ${WHITE}$line${RESET}"
        fi
    done
fi

echo -e "\n${GRAY}Press ENTER for next section...${RESET}"
read -r

# WiFi Scan (AirScope)
print_header "📡 WIFI NETWORK SCAN (AirScope)"
if [ "$WIFI_SCAN" = "No WiFi networks found or scan failed" ]; then
    echo -e "  ${GRAY}No WiFi networks detected${RESET}"
else
    echo "$WIFI_SCAN" | awk -F'[=,]' '
    function color_rssi(r) {
        if (r >= -70) return "\033[1;32m" r " dBm\033[0m"   # green
        if (r >= -85) return "\033[1;33m" r " dBm\033[0m"   # yellow
        return "\033[1;31m" r " dBm\033[0m"                 # red
    }
    function color_bssid(b) { return "\033[1;35m" b "\033[0m" }
    {
        for(i=1;i<=NF;i++) gsub(/^ +| +$/, "", $i)
        ssid=$2; bssid=$4; band=$6; rssi=$8
        gsub(" dBm","",rssi)
        if (ssid=="" || bssid=="" || band=="" || rssi=="") next
        if (!(bssid in best) || rssi > best[bssid]) {
            best[bssid]=rssi
            data[bssid]=ssid "|" band "|" rssi "|" bssid
        }
    }
    END {
        print "\033[1;37m" sprintf("  %-32s %-7s %-10s %s", "SSID", "BAND", "RSSI", "BSSID") "\033[0m"
        print "\033[1;37m  --------------------------------------------------------------------------------\033[0m"
        for (b in data) print data[b]
    }' | sort -t'|' -k3 -n -r | awk -F"|" '
    function color_rssi(r){
        if (r ~ /^-?[0-9]+$/) {
            if (r >= -70) return "\033[1;32m" r " dBm\033[0m"
            if (r >= -85) return "\033[1;33m" r " dBm\033[0m"
            return "\033[1;31m" r " dBm\033[0m"
        } else {
            return r
        }
    }
    function color_bssid(b){ return "\033[1;35m" b "\033[0m" }
    NR==1 || NR==2 {print; next}
    {
        printf "  \033[1;37m%-32s %-7s %-10s %s\033[0m\n", $1, $2, color_rssi($3), color_bssid($4)
    }'
fi

echo -e "\n${GRAY}Press ENTER for security analysis results...${RESET}"
read -r

# Security Analysis
print_header "🐛 SECURITY ANALYSIS"

if [ "$BUGREPORT_GENERATED" = true ]; then
    echo -e "  ${GREEN}✓ Bugreport Generated${RESET}"
    echo -e "    ${GRAY}Location: $BUGREPORT_FILE${RESET}"
    echo
    echo -e "  ${CYAN}Mobile Verification Toolkit (MVT) Results:${RESET}"
    echo -e "$MVT_ANALYSIS" | while IFS= read -r line; do
        if [[ $line == *WARNING* ]] || [[ $line == *⚠️* ]]; then
            echo -e "    ${RED}$line${RESET}"
        elif [[ $line == *✓* ]] || [[ $line == *"No indicators"* ]]; then
            echo -e "    ${GREEN}$line${RESET}"
        else
            echo -e "    ${WHITE}$line${RESET}"
        fi
    done
else
    echo -e "  ${GRAY}Bugreport not generated${RESET}"
    echo -e "  ${GRAY}MVT analysis: Skipped${RESET}"
fi

echo -e "\n${BOLD}${GREEN}✓ Complete!${RESET}"
echo -e "\n${CYAN}📁 Dump directory: ${WHITE}$DUMP_DIR${RESET}"
if [ "$BUGREPORT_GENERATED" = true ]; then
    echo -e "${CYAN}🔒 Bugreport: ${WHITE}$BUGREPORT_FILE${RESET}"
    if [ -d "$DUMP_DIR/mvt_analysis" ]; then
        echo -e "${CYAN}🐛 MVT Results: ${WHITE}$DUMP_DIR/mvt_analysis/${RESET}"
    fi
fi
echo
