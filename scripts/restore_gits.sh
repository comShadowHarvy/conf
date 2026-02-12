#!/bin/bash

# Directory containing git repositories
GIT_ROOT="/home/mw/git"

# Check if a backup file is provided as an argument
if [ -n "$1" ]; then
    BACKUP_FILE="$1"
else
    # File containing the backup list
    BACKUP_FILE="$GIT_ROOT/git_backup_list.txt"
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file $BACKUP_FILE not found!"
    exit 1
fi

echo "Restoring git repositories from $BACKUP_FILE to $GIT_ROOT..."

# Read the backup file line by line
while read -r line; do
    # Skip empty lines
    [ -z "$line" ] && continue
    
    # Read directory name and URL
    dir_name=$(echo "$line" | awk '{print $1}')
    remote_url=$(echo "$line" | awk '{print $2}')
    
    target_dir="$GIT_ROOT/$dir_name"
    
    if [ -d "$target_dir" ]; then
        echo "Skipping existing directory: $dir_name"
    else
        echo "Cloning $dir_name from $remote_url..."
        git clone "$remote_url" "$target_dir"
    fi
done < "$BACKUP_FILE"

echo "Restore complete!"
