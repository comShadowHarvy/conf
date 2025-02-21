#!/usr/bin/env bash

LOCK_FILE="/var/lib/pacman/db.lck"

# Exit if the lock file doesn't exist
if [ ! -e "$LOCK_FILE" ]; then
    echo "No database lock file found. No action needed."
    exit 0
fi

echo "Database lock file found: $LOCK_FILE"
read -p "Do you want to remove the lock file? (y/n): " response

case "$response" in
    [Yy]* )
        if [ "$(id -u)" -eq 0 ]; then
            rm "$LOCK_FILE"
        else
            sudo rm "$LOCK_FILE"
        fi

        if [ $? -eq 0 ]; then
            echo "Lock file removed successfully."
        else
            echo "Failed to remove lock file." >&2
        fi
        ;;
    * )
        echo "Operation cancelled by the user."
        ;;
esac
