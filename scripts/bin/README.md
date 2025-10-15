# Zigbee Firmware Flash Script

## Overview

`flash_zigbee_firmware.sh` is a bash script that automatically handles flashing Z-Stack coordinator firmware to Zigbee devices (specifically CC1352P2/CC2652P coordinators) using Docker and the ti-cc-tool.

## Features

- **Smart Permission Handling**: Automatically checks if user is in the `uucp` group
- **Automatic Group Management**: Adds user to `uucp` group if needed
- **Clear User Feedback**: Provides step-by-step status updates
- **Fallback Options**: Offers sudo alternative when group changes require reboot
- **No Manual Permission Management**: Eliminates the need to manually handle device permissions

## Requirements

- **Docker**: Must be installed and accessible to your user
- **USB Device**: Zigbee coordinator connected at `/dev/ttyUSB0`
- **Internet Access**: Required to download firmware from GitHub
- **Sudo Access**: Needed for adding user to `uucp` group (one-time setup)

## Supported Hardware

- CC1352P2 LaunchPad coordinators
- CC2652P coordinators
- Sonoff Zigbee 3.0 USB Dongle Plus (and similar devices)

## Usage

### First Time Setup

```bash
# Run the script
~/bin/flash_zigbee_firmware.sh
```

If you're not in the `uucp` group, the script will:
1. Add you to the group
2. Recommend logging out/in or rebooting
3. Provide a sudo alternative for immediate flashing

### After Group Setup

Once you're in the `uucp` group (after logging back in), simply run:

```bash
~/bin/flash_zigbee_firmware.sh
```

The script will automatically flash the firmware without requiring sudo.

## What the Script Does

1. **Group Check**: Verifies if current user is in the `uucp` group
2. **Permission Setup**: Adds user to `uucp` group if needed
3. **Firmware Download**: Downloads latest Z-Stack coordinator firmware
4. **Device Connection**: Connects to the coordinator at `/dev/ttyUSB0`
5. **Firmware Flash**: Erases and writes new firmware
6. **Verification**: Verifies successful flash with CRC32 check

## Firmware Information

**Current Firmware**: Z-Stack 3.x.0 Coordinator (March 21, 2025)
**Source**: [Koenkk/Z-Stack-firmware](https://github.com/Koenkk/Z-Stack-firmware)
**File**: `CC1352P2_CC2652P_launchpad_coordinator_20250321.zip`

## Troubleshooting

### Permission Denied Errors
- Make sure you're in the `uucp` group: `groups | grep uucp`
- If recently added to group, log out and back in
- As fallback, use the provided sudo command

### Device Not Found
- Check if device is connected: `ls -la /dev/ttyUSB*`
- Verify correct device path (script assumes `/dev/ttyUSB0`)
- Try unplugging and reconnecting the device

### Docker Issues
- Ensure Docker is running: `systemctl status docker`
- Verify Docker access: `docker --version`
- Check if user is in docker group: `groups | grep docker`

### Network Issues
- Ensure internet connection for firmware download
- Check if GitHub is accessible
- Verify firewall isn't blocking downloads

## Manual Commands

If you need to run the Docker command manually:

```bash
# With proper group membership
docker run --rm \
    --device /dev/ttyUSB0:/dev/ttyUSB0 \
    -e FIRMWARE_URL=https://github.com/Koenkk/Z-Stack-firmware/releases/download/Z-Stack_3.x.0_coordinator_20250321/CC1352P2_CC2652P_launchpad_coordinator_20250321.zip \
    ckware/ti-cc-tool -ewv -p /dev/ttyUSB0 --bootloader-sonoff-usb

# With sudo (if group setup incomplete)
sudo docker run --rm --user root \
    --device /dev/ttyUSB0:/dev/ttyUSB0 \
    -e FIRMWARE_URL=https://github.com/Koenkk/Z-Stack-firmware/releases/download/Z-Stack_3.x.0_coordinator_20250321/CC1352P2_CC2652P_launchpad_coordinator_20250321.zip \
    ckware/ti-cc-tool -ewv -p /dev/ttyUSB0 --bootloader-sonoff-usb
```

## Path Setup

To run the script from anywhere, ensure `~/bin` is in your PATH:

```bash
# Check if ~/bin is in PATH
echo $PATH | grep -q "$HOME/bin" && echo "✓ ~/bin is in PATH" || echo "✗ ~/bin not in PATH"

# Add to PATH if needed (add to ~/.bashrc)
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Security Notes

- The script requires sudo access to modify group membership
- Device flashing operations are inherently risky - ensure you have the correct firmware
- Always backup your current coordinator configuration before flashing

## Version History

- **v1.0**: Initial release with automatic group management and firmware flashing

## Support

For issues with:
- **Script functionality**: Check this README and troubleshooting section
- **Firmware compatibility**: Refer to [Z-Stack-firmware repository](https://github.com/Koenkk/Z-Stack-firmware)
- **Hardware compatibility**: Check your device documentation

---

*Created: October 2025*
*Compatible with: Arch Linux, other systemd-based distributions*
