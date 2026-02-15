#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <username> <ip_address>"
    exit 1
fi

USERNAME="$1"
IP_ADDRESS="$2"

# Check for existing SSH keys
if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    PUB_KEY="$HOME/.ssh/id_ed25519.pub"
    echo "Using existing key: $PUB_KEY"
elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    PUB_KEY="$HOME/.ssh/id_rsa.pub"
    echo "Using existing key: $PUB_KEY"
else
    echo "No SSH key found. Generating a new Ed25519 key..."
    ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N ""
    PUB_KEY="$HOME/.ssh/id_ed25519.pub"
fi

echo "Installing SSH key to $USERNAME@$IP_ADDRESS..."

# Copy the ID to the remote server
if ssh-copy-id -i "$PUB_KEY" "$USERNAME@$IP_ADDRESS"; then
    echo "Key installed successfully!"
    echo "Connecting to $USERNAME@$IP_ADDRESS..."
    ssh "$USERNAME@$IP_ADDRESS"
else
    echo "Failed to install SSH key. Please check your password and try again."
    exit 1
fi
