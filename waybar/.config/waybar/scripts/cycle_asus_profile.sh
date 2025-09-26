#!/bin/bash

# Get the current profile, taking the first word of the second line from the output
current_profile=$(asusctl profile -p | awk 'NR==2 {print $1}')

# Cycle to the next profile
case "$current_profile" in
"Quiet")
  next_profile="Balanced"
  ;;
"Balanced")
  next_profile="Performance"
  ;;
"Performance")
  next_profile="Quiet"
  ;;
*)
  # Default case if something unexpected is returned
  next_profile="Balanced"
  ;;
esac

# Set the new profile using the passwordless sudo permission we set up
sudo asusctl profile -P "$next_profile"
