#!/usr/bin/env bash
#
# tests/usb/run-tests.sh — offline test harness for usb-mount.sh and usb-eject.sh
#
# Author:  ShadowHarvy
# Comments: AI-generated
#
# The stubs directory puts fake lsblk / udisksctl / findmnt / lsof binaries in
# front of PATH so the whole mount → writability → eject flow can be exercised
# without a USB stick, without root, and without touching real block devices.
# State lives in a throwaway temp directory that is wiped at exit.
#
set -uo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
BIN=$(cd -- "$HERE/../.." && pwd)
ST=$(mktemp -d "${TMPDIR:-/tmp}/usb-tests.XXXXXX")
export FAKE_STATE="$ST"
export PATH="$HERE/stubs:$PATH"
trap 'rm -rf "$ST"' EXIT

pass=0; fail=0

reset_state() {
  rm -rf "$ST"; mkdir -p "$ST"
  printf 'nvme0n1 476.9G WD_SN5000S no\nsdb 32G Ultra_USB usb\n' > "$ST/disks"
  printf '/dev/sdb1 vfat USBSTICK\n/dev/sdb2 ext4 DATA\n' > "$ST/parts"
  : > "$ST/mounted"
  : > "$ST/calls.log"
}

check() { # check <label> <expected-rc> <actual-rc>
  local label=$1 want=$2 got=$3
  if [[ $want == "$got" ]]; then
    printf '  PASS  %-50s rc=%s\n' "$label" "$got"; pass=$((pass+1))
  else
    printf '  FAIL  %-50s rc=%s (wanted %s)\n' "$label" "$got" "$want"; fail=$((fail+1))
  fi
}

assert() { # assert <label> <command...>
  local label=$1; shift
  if "$@" >/dev/null 2>&1; then
    printf '  PASS  %s\n' "$label"; pass=$((pass+1))
  else
    printf '  FAIL  %s\n' "$label"; fail=$((fail+1))
  fi
}

echo "== A. listing =="
reset_state
out=$("$BIN/usb-mount.sh" --list); rc=$?
check "usb-mount --list" 0 $rc
assert "list shows sdb1" grep -q '/dev/sdb1' <<<"$out"
assert "internal nvme disk excluded" bash -c "! grep -q nvme <<<'$out'"

echo "== B. plain mount =="
reset_state
out=$("$BIN/usb-mount.sh" /dev/sdb1); rc=$?
check "mount /dev/sdb1" 0 $rc
assert "reports writable" grep -q 'writable by' <<<"$out"
assert "udisksctl mount called" grep -q 'udisksctl mount -b /dev/sdb1' "$ST/calls.log"
assert "state records the mount" grep -q '/dev/sdb1' "$ST/mounted"

echo "== C. idempotent re-mount =="
out=$("$BIN/usb-mount.sh" sdb1); rc=$?
check "mount already-mounted sdb1" 0 $rc
assert "notes existing mount" grep -q 'already mounted' <<<"$out"

echo "== D. FAT-family remount regains write access =="
reset_state
out=$(FAKE_MOUNT_RO=1 "$BIN/usb-mount.sh" -y /dev/sdb1); rc=$?
check "-y on read-only vfat" 0 $rc
assert "remounted with uid/gid/umask" grep -q -- '-o uid=1000,gid=1000,umask=022' "$ST/calls.log"
assert "writable afterwards" grep -q 'writable by' <<<"$out"

echo "== E. --no-fix reports without touching =="
reset_state
out=$(FAKE_MOUNT_RO=1 "$BIN/usb-mount.sh" --no-fix /dev/sdb1 2>&1); rc=$?
check "--no-fix on read-only vfat" 4 $rc
assert "no remount attempted" bash -c "! grep -q -- '-o uid=' '$ST/calls.log'"

echo "== F. POSIX filesystem refuses silent fixes =="
reset_state
out=$(FAKE_MOUNT_RO=1 "$BIN/usb-mount.sh" /dev/sdb2 </dev/null 2>&1); rc=$?
check "ext4 read-only, no tty" 4 $rc
assert "explains the chown/sudo need" grep -q 'chown needs sudo' <<<"$out"

echo "== G. bad device =="
reset_state
"$BIN/usb-mount.sh" /dev/sdz9 >/dev/null 2>&1; check "unknown device" 2 $?

echo "== H. whole-disk spec =="
reset_state
out=$("$BIN/usb-mount.sh" /dev/sdb); rc=$?
check "mount whole disk /dev/sdb" 0 $rc
assert "both partitions mounted" bash -c "test \$(wc -l < '$ST/mounted') -eq 2"

echo "== I. eject listing =="
reset_state
out=$("$BIN/usb-eject.sh" --list); rc=$?
check "usb-eject --list" 0 $rc
assert "lists sdb" grep -q 'sdb' <<<"$out"

echo "== J. eject protects a busy drive =="
reset_state
"$BIN/usb-mount.sh" /dev/sdb1 >/dev/null 2>&1
awk '/sdb1/{print $2}' "$ST/mounted" > "$ST/holders"
out=$("$BIN/usb-eject.sh" /dev/sdb1 </dev/null 2>&1); rc=$?
check "busy drive, no tty, no --force" 5 $rc
assert "names the holding PID" grep -q 'in use by PID' <<<"$out"
assert "nothing was unmounted" bash -c "! grep -q 'udisksctl unmount' '$ST/calls.log'"

echo "== K. eject --force lazy-unmounts and powers off =="
reset_state
"$BIN/usb-mount.sh" /dev/sdb1 >/dev/null 2>&1
awk '/sdb1/{print $2}' "$ST/mounted" > "$ST/holders"
out=$("$BIN/usb-eject.sh" --force sdb1 2>&1); rc=$?
check "eject --force" 0 $rc
assert "lazy unmount used" grep -q -- 'udisksctl unmount -b /dev/sdb1 -f' "$ST/calls.log"
assert "whole disk powered off" grep -q 'udisksctl power-off -b /dev/sdb' "$ST/calls.log"
assert "verifies the disk is gone" grep -q 'is gone' <<<"$out"
assert "disk removed from table" bash -c "! grep -qx sdb '$ST/disks'"

echo "== L. eject idle drive =="
reset_state
"$BIN/usb-mount.sh" /dev/sdb1 >/dev/null 2>&1
out=$("$BIN/usb-eject.sh" /dev/sdb1 2>&1); rc=$?
check "eject idle partition" 0 $rc
assert "plain unmount, no -f" grep -q -- 'unmount -b /dev/sdb1$' "$ST/calls.log"
assert "desktop notification sent" grep -q 'USB ejected' "$ST/calls.log"

echo "== M. --all =="
reset_state
printf 'nvme0n1 476.9G WD_SN5000S no\nsdb 32G Ultra_USB usb\nsdc 8G Kingston usb\n' > "$ST/disks"
printf '/dev/sdb1 vfat A\n/dev/sdc1 exfat B\n' > "$ST/parts"
"$BIN/usb-eject.sh" --all >/dev/null 2>&1; check "--all" 0 $?
assert "both disks powered off" bash -c "test \$(grep -c power-off '$ST/calls.log') -eq 2"

echo "== N. real block-device table, no USB attached =="
reset_state
out=$(PATH=/usr/bin:/bin "$BIN/usb-mount.sh" --list 2>&1); rc=$?
check "real lsblk, no USB" 2 $rc
assert "clear message" grep -q 'No USB partitions found' <<<"$out"

echo "== O. picker with nothing plugged in explains itself =="
reset_state
: > "$ST/disks"; : > "$ST/parts"
out=$("$BIN/usb-mount.sh" </dev/null 2>&1); rc=$?
check "mount picker, no devices" 2 $rc
assert "mount hint names the cause" grep -q 'No USB partitions found' <<<"$out"
out=$("$BIN/usb-eject.sh" </dev/null 2>&1); rc=$?
check "eject picker, no devices" 2 $rc
assert "eject hint names the cause" grep -q 'No removable USB disks found' <<<"$out"

echo
echo "-------------------------------------------"
printf 'passed: %s   failed: %s\n' "$pass" "$fail"
[[ $fail -eq 0 ]]