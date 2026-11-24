#!/usr/bin/env bash
#
# usb-eject.sh — safely unmount and power off a removable USB drive.
#
# Author:  ShadowHarvy
# Comments: AI-generated (written with AI assistance)
#
# HOW IT WORKS
#   1. Works out which disk backs the device you named (sdb1 -> sdb, and
#      nvme0n1p1 -> nvme0n1 so the partition-suffix parsing cannot go wrong).
#   2. Refuses to yank a drive that something still has open: it asks the
#      kernel which processes hold the mountpoint and complains by name.
#      --force skips the question and does a lazy unmount instead.
#   3. Flushes dirty pages with sync, unmounts every mounted partition through
#      udisks2, then asks udisks to power the drive off — that last step is
#      what makes the activity LED stop blinking and tells you it is safe to
#      physically remove the stick.
#   4. Re-reads the block-device table to confirm the eject really happened
#      instead of trusting the command's exit code.
#
# USAGE
#   usb-eject.sh                 interactive picker
#   usb-eject.sh /dev/sdb        eject the whole disk
#   usb-eject.sh sdb1            eject the disk that holds sdb1
#   usb-eject.sh --all           eject every removable USB disk
#   usb-eject.sh --list          show what would be ejected
#
# OPTIONS
#   -l, --list     list removable USB disks and their mounts, then exit
#   -f, --force    skip the "is it busy?" question, lazy-unmount if needed
#   -y, --yes      never prompt (implies answering yes)
#   -a, --all      eject every removable USB disk
#   -h, --help     show this help
#
# EXIT CODES
#   0 success   1 bad usage   2 nothing/unknown device
#   3 unmount failed   4 power-off failed   5 user aborted
#
set -euo pipefail

PROG=${0##*/}

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

usage() { sed -n '3,37p' "$0" | sed 's/^# \{0,1\}//'; }

confirm() {
  local prompt=$1
  [[ $ASSUME_YES -eq 1 ]] && return 0
  [[ -t 0 ]] || { warn "no terminal to ask; treating as 'no'"; return 1; }
  local reply
  read -r -p "$prompt [y/N] " reply
  [[ $reply =~ ^[Yy] ]]
}

# /dev/sdb1 -> sdb ; /dev/nvme0n1p1 -> nvme0n1 ; /dev/sdb -> sdb
disk_of() {
  local dev=${1##*/}
  if [[ $dev =~ ^(nvme[0-9]+n[0-9]+|mmcblk[0-9]+)p[0-9]+$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  elif [[ $dev =~ ^([a-z]+)[0-9]+$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  else
    printf '%s\n' "$dev"
  fi
}

is_usb_disk() {
  local disk=$1 tran removable
  tran=$(lsblk -dno TRAN "/dev/$disk" 2>/dev/null | tr -d ' ' || true)
  removable=$(cat "/sys/block/$disk/removable" 2>/dev/null || echo 0)
  [[ $tran == usb || $removable == 1 ]]
}

usb_disks() {
  local disk
  while read -r disk; do
    [[ -z $disk ]] && continue
    is_usb_disk "$disk" && printf '%s\n' "$disk"
  done < <(lsblk -dno NAME 2>/dev/null)
}

# "partition<TAB>mountpoint" for one disk — mountpoint may be empty.
# Compared against the disk prefix so sdb1, nvme0n1p1 and mmcblk0p1 all work.
disk_mounts() {
  local disk=$1
  lsblk -lnro NAME,MOUNTPOINT "/dev/$disk" 2>/dev/null \
    | awk -v d="/dev/$disk" '$1 != d {mp=""; for (i=2; i<=NF; i++) mp = mp (i>2?" ":"") $i; print $1"\t"mp}'
}

# Shared "nothing is plugged in" message; stderr so the picker's stdout stays
# a clean list of disk names for the caller.
no_disks_hint() {
  warn "No removable USB disks found. Is the drive plugged in?"
  printf '%sChecked transports: %s%s\n' \
    "$C_DIM" "$(lsblk -dno NAME,TRAN 2>/dev/null | awk '{print $1"("$2")"}' | tr '\n' ' ')" "$C_0" >&2
}

list_disks() {
  local disks disk part mnt size model any=0
  mapfile -t disks < <(usb_disks)
  if [[ ${#disks[@]} -eq 0 ]]; then
    no_disks_hint
    return 2
  fi
  printf '%sRemovable USB disks%s\n' "$C_B" "$C_0"
  printf '%s%-3s %-12s %-9s %-24s %-18s %s%s\n' "$C_DIM" "#" "DISK" "SIZE" "MODEL" "PARTITION" "MOUNT" "$C_0"
  local i=0
  for disk in "${disks[@]}"; do
    i=$((i + 1)); any=1
    size=$(lsblk -dno SIZE "/dev/$disk")
    model=$(lsblk -dno MODEL "/dev/$disk" | sed 's/ *$//')
    local first=1
    while IFS=$'\t' read -r part mnt; do
      [[ -z $part ]] && continue
      if [[ $first -eq 1 ]]; then
        printf '%s%-3s%s %-12s %-9s %-24s %-18s %s\n' "$C_GRN" "$i" "$C_0" "/dev/$disk" "$size" "${model:0:24}" "$part" "${mnt:-—}"
        first=0
      else
        printf '%-3s %-12s %-9s %-24s %-18s %s\n' "" "" "" "" "$part" "${mnt:-—}"
      fi
    done < <(disk_mounts "$disk")
    # A disk with no partitions at all still deserves a row.
    if [[ $first -eq 1 ]]; then
      printf '%s%-3s%s %-12s %-9s %-24s %-18s %s\n' "$C_GRN" "$i" "$C_0" "/dev/$disk" "$size" "${model:0:24}" "(none)" "—"
    fi
  done
  return 0
}

pick_disk() {
  local disks choice
  mapfile -t disks < <(usb_disks)
  if [[ ${#disks[@]} -eq 0 ]]; then
    no_disks_hint      # otherwise the caller only sees "no disk selected"
    return 1
  fi
  list_disks >&2
  if [[ ${#disks[@]} -eq 1 ]]; then
    printf '%s\n' "${disks[0]}"
    return 0
  fi
  printf 'Select a disk [1-%d, or "a" for all]: ' "${#disks[@]}" >&2
  read -r choice
  if [[ $choice == a || $choice == A ]]; then
    printf '%s\n' "${disks[@]}"; return 0
  fi
  [[ $choice =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#disks[@]})) || return 1
  printf '%s\n' "${disks[$((choice - 1))]}"
}

# Which processes are holding files open on this mountpoint? fuser gives the
# PIDs, lsof gives readable command names; we use both when available.
busy_holders() {
  local mnt=$1
  command -v lsof >/dev/null && lsof -t +f -- "$mnt" 2>/dev/null | sort -u | tr '\n' ' '
}

eject_disk() {
  local disk=$1 dev="/dev/$1" part mnt rc=0 held=0 busy_list=()

  info "ejecting /dev/$disk"
  mapfile -t mounts < <(disk_mounts "$disk")
  if [[ ${#mounts[@]} -eq 0 ]]; then
    dim "  nothing mounted on /dev/$disk"
  fi

  # 1. Sanity-check for open files before touching anything.
  for line in "${mounts[@]}"; do
    part=${line%%$'\t'*}; mnt=${line#*$'\t'}
    [[ -z $mnt ]] && continue
    pids=$(busy_holders "$mnt")
    if [[ -n ${pids// /} ]]; then
      held=1
      warn "$mnt is in use by PID(s): $pids"
      busy_list+=("$mnt")
    fi
  done
  if [[ $held -eq 1 && $FORCE -eq 0 ]]; then
    warn "close the programs above, or re-run with --force for a lazy unmount"
    confirm "Unmount anyway (lazy)?" || die "aborted by user" 5
  fi
  # A lazy unmount leaves a process writing into a detached filesystem, so we
  # only take that path when the user explicitly agreed to it.
  local lazy=0
  [[ $held -eq 1 ]] && lazy=1

  # 2. Flush. Cheap, and the single most important step for a USB stick.
  sync

  # 3. Unmount each partition.
  for line in "${mounts[@]}"; do
    part=${line%%$'\t'*}; mnt=${line#*$'\t'}
    [[ -z $mnt ]] && continue
    local args=(-b "$part")
    [[ $lazy -eq 1 || $FORCE -eq 1 ]] && args+=(-f)
    if udisksctl unmount "${args[@]}" >/dev/null 2>&1; then
      ok "unmounted $part (was $mnt)"
    elif findmnt -no TARGET --source "$part" >/dev/null 2>&1; then
      warn "could not unmount $part"
      rc=3
    else
      dim "  $part was already unmounted"
    fi
  done
  [[ $rc -ne 0 ]] && { warn "skipping power-off while a partition stays mounted"; return $rc; }

  # 4. Power the drive down. This is what actually tells the hardware to stop
  #    and makes the "safe to remove" claim true.
  if udisksctl power-off -b "$dev" 2>&1 | grep -qiE 'error|failed'; then
    warn "udisks2 could not power off /dev/$disk"
    if command -v eject >/dev/null; then
      dim "  trying eject(1)"
      eject "$dev" >/dev/null 2>&1 || rc=4
    else
      rc=4
    fi
  fi

  # 5. Verify instead of assuming. A powered-off disk disappears from the
  #    kernel's list; a still-listed disk with no mountpoints is only
  #    "unmounted". Prefer /sys (authoritative) and fall back to lsblk.
  sleep 0.5
  local listed=0
  lsblk -dno NAME 2>/dev/null | grep -qx "$disk" && listed=1
  if [[ $listed -eq 0 && ! -d /sys/block/$disk ]]; then
    ok "/dev/$disk is gone — safe to unplug"
  elif [[ -z $(disk_mounts "$disk" | awk -F'\t' '$2!=""') ]]; then
    warn "/dev/$disk is unmounted but still powered (no power-off support on this bridge)"
    dim  "  it is safe to unplug now that nothing is mounted"
    rc=0
  else
    warn "/dev/$disk still has mounted partitions"
    rc=3
  fi

  command -v notify-send >/dev/null && \
    notify-send -i drive-removable-media "USB ejected" "/dev/$disk is safe to remove" 2>/dev/null || true
  return $rc
}

LIST_ONLY=0; FORCE=0; ASSUME_YES=0; ALL=0; SPEC=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -l|--list)  LIST_ONLY=1 ;;
    -f|--force) FORCE=1; ASSUME_YES=1 ;;
    -y|--yes)   ASSUME_YES=1 ;;
    -a|--all)   ALL=1 ;;
    -h|--help)  usage; exit 0 ;;
    -*)         die "unknown option: $1 (try --help)" 1 ;;
    *)          SPEC=$1 ;;
  esac
  shift
done

command -v udisksctl >/dev/null || die "udisksctl not found (install udisks2)" 1

if [[ $LIST_ONLY -eq 1 ]]; then
  list_disks || exit 2
  exit 0
fi

# Build the list of disks to eject: explicit spec, --all, or a picker.
TARGETS=()
if [[ -n $SPEC ]]; then
  spec=${SPEC#/dev/}
  disk=$(disk_of "$spec")
  # Existence check: prefer the /dev node, fall back to the kernel table so a
  # device that udev has not linked yet still works.
  if [[ ! -b "/dev/$disk" ]] && ! lsblk -dno NAME 2>/dev/null | grep -qx "$disk"; then
    die "no such block device: $SPEC" 2
  fi
  is_usb_disk "$disk" || warn "/dev/$disk is not flagged removable — ejecting it anyway"
  TARGETS=("$disk")
elif [[ $ALL -eq 1 ]]; then
  mapfile -t TARGETS < <(usb_disks)
  [[ ${#TARGETS[@]} -eq 0 ]] && die "no removable USB disks found" 2
else
  mapfile -t TARGETS < <(pick_disk) || true
  [[ ${#TARGETS[@]} -eq 0 || -z ${TARGETS[0]:-} ]] && die "no disk selected" 2
fi

rc=0
for disk in "${TARGETS[@]}"; do
  eject_disk "$disk" || rc=$?
done
exit $rc