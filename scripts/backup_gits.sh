#!/bin/bash

# Directory containing git repositories
GIT_ROOT="/home/mw/git"

# Check if a backup file is provided as an argument
if [ -n "$1" ]; then
    BACKUP_FILE="$1"
    APPEND_MODE=true
else
    BACKUP_FILE="$GIT_ROOT/git_backup_list.txt"
    APPEND_MODE=false
fi

if [ "$APPEND_MODE" = true ]; then
    echo "Backing up git repositories from $GIT_ROOT appending to $BACKUP_FILE..."
    # Create file if it doesn't exist
    touch "$BACKUP_FILE"
else
    echo "Backing up git repositories from $GIT_ROOT to $BACKUP_FILE..."
    # Clear existing backup file
    > "$BACKUP_FILE"
fi

# Iterate through directories in GIT_ROOT
for repo_dir in "$GIT_ROOT"/*; do
    if [ -d "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
        # Get the directory name
        dir_name=$(basename "$repo_dir")
        
        # Get the remote origin URL
        if remote_url=$(git -C "$repo_dir" remote get-url origin 2>/dev/null); then
            
            # If appending, check if entry already exists
            if [ "$APPEND_MODE" = true ]; then
                if grep -q "^$dir_name " "$BACKUP_FILE"; then
                    echo "Skipping duplicate: $dir_name"
                    continue
                fi
            fi

            echo "$dir_name $remote_url" >> "$BACKUP_FILE"
            echo "Backed up: $dir_name -> $remote_url"
        else
            echo "Warning: No remote origin found for $dir_name"
        fi
    fi
done

echo "Backup complete!"
