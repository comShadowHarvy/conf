#!/bin/bash

# Define the target network
TARGET="192.168.1.0/24"

# Define the output directory
OUTPUT_DIR="/path/to/output"

# Create the output directory if it doesn't exist
mkdir -p $OUTPUT_DIR

# Get the current timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Run the Nmap scan and save the output
nmap $TARGET -oN $OUTPUT_DIR/nmap_scan_$TIMESTAMP.txt

# Print a message indicating the scan is complete
echo "Nmap scan completed. Output saved to $OUTPUT_DIR/nmap_scan_$TIMESTAMP.txt"

