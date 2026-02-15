#!/bin/bash

set -e

echo "=== SMB Share Setup ==="

SMB_CONF="/etc/samba/smb.conf"

echo "Adding SMB shares to $SMB_CONF..."

cat >> "$SMB_CONF" <<'EOF'

[USB-Share]
   path = /mnt/usb
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0777
   directory mask = 0777
   force user = root
   force group = root

[USB-Share-2]
   path = /mnt/usb2
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0777
   directory mask = 0777
   force user = root
   force group = root

[ROM-Share]
   path = /mnt/rom
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0777
   directory mask = 0777
   force user = root
   force group = root
EOF

echo "Testing SMB config..."
testparm -s

echo "Restarting Samba..."
systemctl enable smbd
systemctl restart smbd

echo "=== SMB Share Setup Complete ==="
