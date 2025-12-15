#!/bin/bash

# Function to handle mounting
do_mount() {
    local REMOTE_NAME=$1
    local MOUNT_POINT=$2

    # 1. Create the directory if it doesn't exist
    if [ ! -d "$MOUNT_POINT" ]; then
        echo "Creating directory: $MOUNT_POINT"
        mkdir -p "$MOUNT_POINT"
    fi

    # 2. Check if already mounted
    if mountpoint -q "$MOUNT_POINT"; then
        echo "Skip: $REMOTE_NAME is already mounted at $MOUNT_POINT"
    else
        echo "Mounting $REMOTE_NAME to $MOUNT_POINT..."
        # --daemon runs it in background and detaches from terminal
        # --vfs-cache-mode full is essential for browsing with Yazi/file managers
        rclone mount "$REMOTE_NAME": "$MOUNT_POINT" \
            --vfs-cache-mode full \
            --daemon
        
        if [ $? -eq 0 ]; then
            echo "Success: $REMOTE_NAME mounted."
        else
            echo "Error: Failed to mount $REMOTE_NAME."
        fi
    fi
}

# --- Execute Mounts ---

# Mount 'photo' remote to ~/GooglePhotos
do_mount "photo" "$HOME/GooglePhotos"

# Mount 'gg' remote to ~/Google
do_mount "gg" "$HOME/Google"
