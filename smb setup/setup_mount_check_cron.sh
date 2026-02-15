#!/bin/bash

set -e

echo "=== Setting up mount check cron job ==="

CHECK_SCRIPT="/usr/local/bin/check_mounts.sh"

if [ ! -f "$CHECK_SCRIPT" ]; then
  echo "ERROR: $CHECK_SCRIPT not found. Run setup_delayed_mount.sh first."
  exit 1
fi

chmod +x "$CHECK_SCRIPT"

CRON_JOB="*/5 * * * * $CHECK_SCRIPT"

(crontab -l 2>/dev/null | grep -v "check_mounts.sh"; echo "$CRON_JOB") | crontab -

echo "Cron job added: $CRON_JOB"
echo "=== Cron job setup complete ==="
