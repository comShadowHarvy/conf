#!/bin/bash

# Script to flash Zigbee coordinator firmware
# Checks for uucp group membership and handles permissions

# Get the group ID of the uucp group
UUCP_GID=$(getent group uucp | cut -d: -f3)

DOCKER_COMMAND="docker run --rm \
    --device /dev/ttyUSB0:/dev/ttyUSB0 \
    --group-add $UUCP_GID \
    --user $(id -u):$(id -g) \
    -e FIRMWARE_URL=https://github.com/Koenkk/Z-Stack-firmware/releases/download/Z-Stack_3.x.0_coordinator_20250321/CC1352P2_CC2652P_launchpad_coordinator_20250321.zip \
    ckware/ti-cc-tool -ewv -p /dev/ttyUSB0 --bootloader-sonoff-usb"

echo "Checking if user $(whoami) is in the uucp group..."

# Check if current user is in uucp group
if groups | grep -q "\buucp\b"; then
    echo "✓ User $(whoami) is already in the uucp group"
    echo "Running Docker command to flash firmware..."
    echo
    eval $DOCKER_COMMAND
else
    echo "✗ User $(whoami) is not in the uucp group"
    echo "Adding user to uucp group..."
    
    # Add user to uucp group
    sudo usermod -a -G uucp $USER
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully added $(whoami) to uucp group"
        echo
        echo "IMPORTANT: You need to log out and log back in (or reboot) for the group change to take effect."
        echo "After logging back in, run this script again to flash the firmware."
        echo
        echo "Alternatively, you can run the following command with sudo right now:"
        echo "sudo $DOCKER_COMMAND"
    else
        echo "✗ Failed to add user to uucp group"
        echo "You may need to run this script with sudo or check your permissions"
        exit 1
    fi
fi
