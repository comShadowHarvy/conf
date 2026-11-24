#!/usr/bin/env bash
#
# usb-mount.sh — mount a removable USB drive and make it writable for the
#                normal (non-root) user running this script.
#
# Author:  ShadowHarvy
# Comments: AI-generated (written with AI assistance)
#
# HOW IT WORKS
#   1. Finds USB-attached block devices via lsblk (transport == "usb").
#   2. Mounts the chosen partition(s) through udisks2 (udisksctl), which is
#      the same service your desktop file manager uses. udisks runs as root
#      but grants the caller access, so no sudo is required to mount.
#   3. Verifies the mountpoint is actually writable by *you*. udisks usually
#      gets this right for FAT/exFAT/NTFS (it mounts them with uid=<you>),
#      but POSIX filesystems (ext4/btrfs/xfs) keep the ownership stored on
#      the disk. If those filesystems are root-owned, this script offers to
#      chown them to you (that step needs sudo) or to remount FAT-family
#      filesystems with explicit uid/gid options.
#
# USAGE
#   usb-mount.sh                     interactive picker
#   usb-mount.sh /dev/sdb1           mount one partition
#   usb-mount.sh sdb1                same thing, shorthand
#   usb-mount.sh /dev/sdb            mount every mountable partition on the disk
#   usb-mount.sh --label BACKUP      mount the partition whose label is BACKUP
#   usb-mount.sh --list              just show what is plugged in
#
# OPTIONS
#   -l, --list          list removable USB partitions and exit
#   -r, --read-only     mount read-only (still reports writability honestly)
#       --no-fix        never touch ownership/options; only report the problem
#   -y, --yes           answer "yes" to the writability fix prompts
#   -d, --dir DIR       mount into DIR instead of /run/media/$USER/<label>.
#                       This bypasses udisks and therefore needs sudo.
#   -h, --help          show this help
#
# EXIT CODES
#   0 success   1 bad usage   2 nothing/unknown device   3 mount failed
#   4 mounted but still not writable   5 user aborted
#
set -euo pipefail

PROG=${0##*/}

# ---------------------------------------------------------------------------
# Output helpers. Colors are only emitted on a real terminal so piping the
# output into a log file does not fill it with escape sequences.
# ---------------------------------------------------------------------------
if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
  C_RED=$'\033[0;31m'; C_GRN=$'\033[0;32m'; C_YEL=$'\033[1;33m'
  C_CYA=$'\033[0;36m'; C_DIM=$'\033[2m';   C_B=$'\033[1m'; C_0=$'\033[0m'
else
  C_RED=; C_GRN=; C_YEL=; C_CYA=; C_DIM=; C_B=; C_0=
fi

info() { printf '%s==>%s %s\n' "$C_CYA" "$C_0" "$*"; }
ok()   { printf '%s ✓ %s%s\n' "$C_GRN" "$*" "$C_0"; }
warn() { printf '%s ! %s%s\n' "$C_YEL" "$*" "$C_0" >&2; }
die()  { printf '%s ✗ %s%s\n' "$C_RED" "$1" "$C_0" >&2; exit "${2:-1}"; }
dim()  { printf '%s%s%s\n' "$C_DIM" "$*" "$C_0"; }

usage() { sed -n '3,40p' "$0" | sed 's/^# \{0,1\}//'; }

# ---------------------------------------------------------------------------
# Small predicates/utilities
# ---------------------------------------------------------------------------

# Anything that needs a yes/no from the user goes through here. In an
# unattended context (a cron job, a pipe with no tty) we must never hang:
# the default answer is "no" unless -y was passed.
confirm() {
  local prompt=$1
  if [[ $ASSUME_YES -eq 1 ]]; then return 0; fi
  if [[ ! -t 0 ]]; then warn "no terminal to ask; treating as 'no'"; return 1; fi
  local reply
  read -r -p "$prompt [y/N] " reply
  [[ $reply =~ ^[Yy] ]]
}

# Every child partition node of a disk: works for sdb1, nvme0n1p1 and mmcblk0p1
# because it compares on the disk prefix rather than guessing a suffix format.
partitions_of() {
  local disk=$1
  lsblk -lnpo NAME,FSTYPE "/dev/$disk" 2>/dev/null \
    | awk -v d="/dev/$disk" '$1 != d {print $1"\t"$2}'
}

# Strip a partition suffix from a device node: /dev/sdb1 -> sdb, /dev/nvme0n1p1 -> nvme0n1
disk_of() {
  local dev=${1##*/}      # basename
  if [[ $dev =~ ^(nvme[0-9]+n[0-9]+|mmcblk[0-9]+)p[0-9]+$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  else
    printf '%s\n' "${dev%%[0-9]*}"
  fi
}

# Is this whole disk a USB drive? Checks both the lsblk transport column and
# the kernel's removable flag, because a few USB bridges report "sata".
is_usb_disk() {
  local disk=$1 tran removable
  tran=$(lsblk -dno TRAN "/dev/$disk" 2>/dev/null | tr -d ' ' || true)
  removable=$(cat "/sys/block/$disk/removable" 2>/dev/null || echo 0)
  [[ $tran == usb || $removable == 1 ]]
}

# Print "device<TAB>size<TAB>fstype<TAB>label<TAB>mountpoint" for every
# partition sitting on a USB disk. Iterates every disk and lets is_usb_disk
# decide, so enclosures that report transport "sata" are still recognised.
usb_partitions() {
  local disk part size fstype label mnt
  while read -r disk; do
    [[ -z $disk ]] && continue
    is_usb_disk "$disk" || continue
    while read -r part size fstype label mnt; do
      [[ -z $part ]] && continue
      # Skip extended/WinRE-style containers that hold no filesystem.
      [[ -z $fstype ]] && continue
      printf '/dev/%s\t%s\t%s\t%s\t%s\n' "$part" "$size" "${fstype:-?}" "${label:-—}" "${mnt:-—}"
    done < <(lsblk -lno NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "/dev/$disk" 2>/dev/null | grep -v "^$disk ")
  done < <(lsblk -dno NAME 2>/dev/null)
}

# The "nothing is plugged in" explanation lives in one place because both the
# listing and the interactive picker need it. It goes to stderr so a caller
# capturing the picker's stdout (the device nodes) gets a clean list.
no_devices_hint() {
  warn "No USB partitions found. Is the drive plugged in?"
  printf '%sChecked transports: %s%s\n' \
    "$C_DIM" "$(lsblk -dno NAME,TRAN 2>/dev/null | awk '{print $1"("$2")"}' | tr '\n' ' ')" "$C_0" >&2
}

list_devices() {
  local rows
  rows=$(usb_partitions)
  if [[ -z $rows ]]; then
    no_devices_hint
    return 2
  fi
  printf '%sRemovable USB partitions%s\n' "$C_B" "$C_0"
  printf '%s%-3s %-14s %-9s %-8s %-18s %s%s\n' "$C_DIM" "#" "DEVICE" "SIZE" "FSTYPE" "LABEL" "MOUNTPOINT" "$C_0"
  local i=0 dev size fstype label mnt
  while IFS=$'\t' read -r dev size fstype label mnt; do
    i=$((i + 1))
    printf '%s%-3s%s %-14s %-9s %-8s %-18s %s\n' "$C_GRN" "$i" "$C_0" "$dev" "$size" "$fstype" "$label" "$mnt"
  done <<<"$rows"
  return 0
}

# Let the user pick from the list above without retyping a device node.
pick_devices() {
  local rows i=0 n dev rest choice
  rows=$(usb_partitions) || true
  if [[ -z $rows ]]; then
    no_devices_hint      # otherwise the caller only sees "no device selected"
    return 1
  fi
  list_devices >&2          # keep the table on stderr so stdout stays machine-readable
  n=$(wc -l <<<"$rows")
  printf 'Select a partition [1-%d, or "a" for all]: ' "$n" >&2
  read -r choice
  if [[ $choice == a || $choice == A ]]; then
    awk -F'\t' '{print $1}' <<<"$rows"
    return 0
  fi
  [[ $choice =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= n)) || return 1
  awk -F'\t' -v want="$choice" 'NR==want{print $1}' <<<"$rows"
}

# Turn whatever the user typed into a list of partition device nodes.
# Accepts: /dev/sdb1 | sdb1 | /dev/sdb | --label foo
# The disk-vs-partition question is answered by the kernel (lsblk TYPE) rather
# than by guessing from the name, because names like sdb1 and nvme0n1 both end
# in digits.
resolve_targets() {
  local spec=$1 type
  [[ $spec == /dev/* ]] || spec="/dev/$spec"

  type=$(lsblk -dno TYPE "$spec" 2>/dev/null | tr -d ' ' || true)
  case $type in
    disk)
      # Whole disk: hand back every child that carries a filesystem.
      local parts
      parts=$(partitions_of "${spec##*/}" | awk -F'\t' '$2 != "" {print $1}')
      [[ -z $parts ]] && return 2
      printf '%s\n' "$parts"
      ;;
    part|loop|rom)
      printf '%s\n' "$spec"
      ;;
    *)
      # Not in the kernel table (or udev has not caught up yet): accept a real
      # device node as-is and let the mount step produce the real error.
      [[ -b $spec ]] || return 2
      printf '%s\n' "$spec"
      ;;
  esac
  return 0
}

mountpoint_of() {
  findmnt -no TARGET --source "$1" 2>/dev/null || true
}

fstype_of() {
  lsblk -no FSTYPE "$1" 2>/dev/null | tr -d ' ' || true
}

# ---------------------------------------------------------------------------
# Writability: check it for real (a write test), then repair when possible.
# ---------------------------------------------------------------------------
writable_by_user() {
  local dir=$1 probe="$1/.usb-mount-probe.$$"
  # First a cheap permission test, then an actual create/remove. The second
  # step matters because a FAT filesystem can look writable (mode 0777) while
  # the mount options still map your uid to a read-only view.
  [[ -w $dir ]] || return 1
  { : >"$probe"; } 2>/dev/null || return 1
  rm -f -- "$probe" 2>/dev/null
  return 0
}

# FAT-family filesystems carry no ownership on disk: the kernel fakes it from
# mount options. If udisks did not hand the mount to us, remounting with
# uid=/gid= fixes it without touching any data.
fix_fat_family() {
  local dev=$1 dir=$2 fstype=$3 opts
  opts="uid=$(id -u),gid=$(id -g),umask=022"
  case $fstype in
    ntfs|ntfs3|fuseblk) opts="$opts,windows_names" ;;
  esac
  warn "$dir is not writable; remounting $dev with $opts"
  # Declining here is not an error: the caller re-checks writability and
  # reports exit code 4, which is the honest "mounted but read-only for you".
  confirm "Unmount and remount it now?" || return 1
  udisksctl unmount -b "$dev" >/dev/null 2>&1 || true
  # Give the driver a moment to release the device before remounting.
  sleep 0.3
  local out
  if out=$(udisksctl mount -b "$dev" -o "$opts" 2>&1); then
    dim "  ${out//$'\n'/ }"
    return 0
  fi
  warn "remount with explicit uid/gid failed: $out"
  return 1
}

# POSIX filesystems (ext4/btrfs/xfs/f2fs) store ownership in the superblock,
# so mount options cannot help. The only fix is chown, which needs root.
fix_posix_owner() {
  local dir=$1
  command -v sudo >/dev/null || { warn "sudo not installed; cannot chown $dir"; return 1; }
  warn "$dir is owned by uid $(stat -c %u "$dir") (you are $(id -u)); chown needs sudo"
  confirm "Run: sudo chown -R $(id -un):$(id -gn) $dir ?" || return 1
  if ! sudo chown -R "$(id -un):$(id -gn)" "$dir"; then
    warn "chown failed — the drive stays read-only for you"
    return 1
  fi
}

ensure_writable() {
  local dev=$1 dir=$2 fstype=$3
  writable_by_user "$dir" && { ok "writable by $(id -un)"; return 0; }
  [[ $NO_FIX -eq 1 ]] && { warn "not writable (--no-fix given, leaving as is)"; return 4; }

  case $fstype in
    vfat|fat|msdos|exfat|ntfs|ntfs3|fuseblk) fix_fat_family "$dev" "$dir" "$fstype" || true ;;
    *)                                        fix_posix_owner "$dir" || true ;;
  esac

  if writable_by_user "$dir"; then
    ok "writable by $(id -un)"
    return 0
  fi
  warn "still not writable: $dir"
  return 4
}

# ---------------------------------------------------------------------------
# Mounting
# ---------------------------------------------------------------------------
mount_one() {
  local dev=$1 dir rc=0
  dir=$(mountpoint_of "$dev") || dir=""
  if [[ -n $dir ]]; then
    dim "  $dev already mounted at $dir"
    if [[ $READ_ONLY -eq 0 ]]; then
      ensure_writable "$dev" "$dir" "$(fstype_of "$dev")" || rc=$?
    fi
    report "$dir"
    return $rc
  fi

  local opts=()
  [[ $READ_ONLY -eq 1 ]] && opts=(-o ro)

  info "mounting $dev"
  local out
  if [[ -n $TARGET_DIR ]]; then
    # Explicit directory means we manage the mount ourselves. udisks2 in this
    # version cannot be told a mountpoint, so this path needs real root.
    mkdir -p "$TARGET_DIR"
    local mnt_args=()
    [[ $READ_ONLY -eq 1 ]] && mnt_args=(-o ro)
    if ! sudo mount "${mnt_args[@]}" "$dev" "$TARGET_DIR"; then
      warn "sudo mount failed for $dev"
      return 3
    fi
    out="Mounted $dev at $TARGET_DIR."
    dir=$TARGET_DIR
  else
    if ! out=$(udisksctl mount -b "$dev" "${opts[@]}" 2>&1); then
      warn "$out"
      return 3
    fi
    dim "  ${out//$'\n'/ }"
    dir=$(mountpoint_of "$dev")
    [[ -z $dir ]] && { warn "udisks reported success but $dev is not in findmnt"; return 3; }
  fi

  ok "mounted at $dir"
  [[ $READ_ONLY -eq 1 ]] && { report "$dir"; return 0; }
  ensure_writable "$dev" "$dir" "$(fstype_of "$dev")" || rc=$?
  report "$dir"
  return $rc
}

report() {
  local dir=$1
  printf '   %spath:%s %s\n' "$C_DIM" "$C_0" "$dir"
  printf '   %sfree:%s %s\n' "$C_DIM" "$C_0" "$(df -h --output=avail "$dir" 2>/dev/null | tail -1 | tr -d ' ')"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
LIST_ONLY=0; READ_ONLY=0; NO_FIX=0; ASSUME_YES=0; TARGET_DIR=""; SPEC=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -l|--list)       LIST_ONLY=1 ;;
    -r|--read-only)  READ_ONLY=1 ;;
    --no-fix)        NO_FIX=1 ;;
    -y|--yes)        ASSUME_YES=1 ;;
    -d|--dir)        TARGET_DIR=${2:?--dir needs a path}; shift ;;
    --label)         SPEC="LABEL=${2:?--label needs a name}"; shift ;;
    -h|--help)       usage; exit 0 ;;
    -*)              die "unknown option: $1 (try --help)" 1 ;;
    *)               SPEC=$1 ;;
  esac
  shift
done

command -v udisksctl >/dev/null || die "udisksctl not found (install udisks2)" 1
command -v lsblk     >/dev/null || die "lsblk not found (install util-linux)" 1

if [[ $LIST_ONLY -eq 1 ]]; then
  list_devices || exit 2
  exit 0
fi

# Resolve what to mount. Nothing given -> interactive picker.
if [[ -z $SPEC ]]; then
  mapfile -t DEVICES < <(pick_devices) || true
  [[ ${#DEVICES[@]} -eq 0 || -z ${DEVICES[0]:-} ]] && die "no device selected" 2
elif [[ $SPEC == LABEL=* ]]; then
  label=${SPEC#LABEL=}
  mapfile -t DEVICES < <(lsblk -lnpo NAME,LABEL | awk -v l="$label" '$2==l{print $1}')
  [[ ${#DEVICES[@]} -eq 0 || -z ${DEVICES[0]:-} ]] && die "no partition labelled '$label'" 2
else
  mapfile -t DEVICES < <(resolve_targets "$SPEC") || true
  [[ ${#DEVICES[@]} -eq 0 || -z ${DEVICES[0]:-} ]] && die "no such block device: $SPEC" 2
fi

rc=0
for dev in "${DEVICES[@]}"; do
  mount_one "$dev" || rc=$?
  [[ $rc -eq 5 ]] && die "aborted by user" 5
done
exit $rc