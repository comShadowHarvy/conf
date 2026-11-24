# usb-mount.sh / usb-eject.sh

Two small scripts that make USB sticks behave on Linux: one mounts a drive **and makes sure your normal user can actually write to it**, the other unmounts and powers it down safely.

Author: **ShadowHarvy** · Comments: AI-generated

```bash
scripts/bin/usb-mount.sh              # interactive picker, then mount
scripts/bin/usb-eject.sh              # interactive picker, then eject
```

---

## Why this exists

Most "mount my USB" advice is `sudo mount /dev/sdb1 /mnt`, and it fails in two annoying ways:

1. You end up with root doing the work, so files you create later are owned by root.
2. Some filesystems (ext4, btrfs, xfs) store ownership **on the disk**. If the stick was formatted on another machine — or by `dd` from an image — the mountpoint belongs to uid 1000 of *that* machine, and you get read-only access no matter how you mount it.

`usb-mount.sh` mounts through **udisks2** (the same service your file manager uses, so no `sudo` needed), then *tests* writability by creating a file, and only fixes things when the test fails.

## Files

| File | Purpose |
|---|---|
| `usb-mount.sh` | Mount a removable USB partition, verify + repair write access |
| `usb-eject.sh` | Unmount, sync, power off, and verify the drive is gone |
| `USB_MOUNT_README.md` | This document |
| `tests/usb/run-tests.sh` | Offline harness (40 assertions) using stub `lsblk`/`udisksctl` binaries |

## Requirements

- Linux with **udisks2** (`udisksctl`) — present on virtually every desktop distro
- `lsblk`, `findmnt` (util-linux), `bash` 4.4+
- Optional: `lsof` (nicer "who is using this drive" messages), `notify-send` (desktop toast on eject), `sudo` (only for the ownership fix on ext4/btrfs/xfs and for `--dir`)

## Installation

Both scripts are standalone — copy them anywhere on your `PATH`:

```bash
install -m 755 usb-mount.sh ~/.local/bin/usb-mount
install -m 755 usb-eject.sh ~/.local/bin/usb-eject
```

---

## usb-mount.sh

### Usage

```bash
usb-mount.sh                      # pick from a numbered list
usb-mount.sh /dev/sdb1            # one partition
usb-mount.sh sdb1                 # same thing, shorthand
usb-mount.sh /dev/sdb             # every mountable partition on the disk
usb-mount.sh --label BACKUP       # by filesystem label
usb-mount.sh --list               # just show what is plugged in
```

Typical run:

```
$ usb-mount.sh sdb1
==> mounting /dev/sdb1
 ✓ mounted at /run/media/me/USBSTICK
 ✓ writable by me
   path: /run/media/me/USBSTICK
   free: 28G
```

And when the stick is the root-owned kind:

```
$ usb-mount.sh sdb1
==> mounting /dev/sdb1
 ! /run/media/me/OLDSTICK is not writable; remounting /dev/sdb1 with uid=1000,gid=1000,umask=022
Unmount and remount it now? [y/N] y
 ✓ writable by me
```

### Options

| Option | Meaning |
|---|---|
| `-l`, `--list` | List removable USB partitions and exit |
| `-r`, `--read-only` | Mount read-only (skips the writability fix) |
| `--no-fix` | Mount, report the writability problem, change nothing |
| `-y`, `--yes` | Answer yes to the repair prompts (for scripts) |
| `-d`, `--dir DIR` | Mount into `DIR` instead of `/run/media/$USER/<label>`. Bypasses udisks, so it needs `sudo` |
| `--label NAME` | Select by filesystem label instead of device node |
| `-h`, `--help` | Show usage |

### How the writability fix works

The script does not guess from mount options — it performs a real write test and branches on the filesystem type:

- **FAT family** (`vfat`, `exfat`, `ntfs`/`ntfs3`) — these have no ownership on disk, the kernel fakes it. If the mount is read-only for you, the script unmounts and remounts with `uid=<you>,gid=<yourgroup>,umask=022` (plus `windows_names` for NTFS). No data is touched.
- **POSIX filesystems** (`ext4`, `btrfs`, `xfs`, `f2fs`) — ownership lives in the superblock, mount options cannot help, so the only fix is `sudo chown -R you:yourgroup <mountpoint>`. The script asks first and tells you exactly which command it will run.
- **Already writable** — nothing happens; the check is idempotent, so running it twice is safe.

### Exit codes

| Code | Meaning |
|---|---|
| `0` | Mounted (and writable, unless `--read-only`) |
| `1` | Bad usage / missing dependency |
| `2` | No USB device found, or unknown device |
| `3` | Mount failed |
| `4` | Mounted, but still not writable by you |
| `5` | Aborted at a prompt |

---

## usb-eject.sh

### Usage

```bash
usb-eject.sh                    # pick from a numbered list
usb-eject.sh /dev/sdb           # whole disk
usb-eject.sh sdb1               # resolves to the disk that holds sdb1
usb-eject.sh --all              # every removable USB disk
usb-eject.sh --list             # show what would be ejected
```

Typical run:

```
$ usb-eject.sh /dev/sdb1
==> ejecting /dev/sdb
 ✓ unmounted /dev/sdb1 (was /run/media/me/USBSTICK)
 ✓ /dev/sdb is gone — safe to unplug
```

### What it does, in order

1. Maps the partition back to its disk (`sdb1` → `sdb`, `nvme0n1p1` → `nvme0n1`).
2. Asks the kernel which processes hold the mountpoint open and **names their PIDs**. If anything is in use it stops and asks — a drive yanked out from under a running copy is how filesystems die.
3. `sync` — flushes dirty pages. This is the step people skip and regret.
4. `udisksctl unmount` each partition (`-f` lazy unmount only when you agreed to it or passed `--force`).
5. `udisksctl power-off` the whole disk, which stops the spindle / kills the LED.
6. **Verifies**: re-reads the block-device table and confirms the disk actually disappeared, rather than trusting an exit code.

### Options

| Option | Meaning |
|---|---|
| `-l`, `--list` | List removable USB disks and mounts, then exit |
| `-f`, `--force` | Skip the "is it busy?" question; lazy-unmount if needed |
| `-y`, `--yes` | Never prompt |
| `-a`, `--all` | Eject every removable USB disk |
| `-h`, `--help` | Show usage |

### Exit codes

| Code | Meaning |
|---|---|
| `0` | Unmounted and powered off (or unmounted with no power-off support) |
| `2` | Nothing or unknown device |
| `3` | Unmount failed |
| `4` | Power-off failed |
| `5` | Aborted at a prompt (drive in use) |

If the bridge does not support power-off (some cheap SATA-USB enclosures), the disk stays visible in `lsblk` but the script tells you it is unmounted and safe to pull.

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `No USB partitions found` | Drive not inserted, or a bridge that reports transport `sata`. Check `lsblk -o NAME,TRAN`; if `removable` is `1` the scripts still detect it. |
| `Error: not authorized` from udisksctl | The session has no polkit agent (typical for SSH / bare tty). Log in on the desktop session, or use `--dir` with `sudo`. |
| Mounted, but `still not writable` | POSIX filesystem with foreign ownership: run the `sudo chown` the script printed, or reformat. |
| `dirty bit` / mount refused on NTFS | Old Windows hibernation/fast-startup left the volume dirty. Mount with `ntfsfix` or reconnect on Windows and eject properly. |
| Eject says "unmounted but still powered" | Normal for bridges without power-off support; nothing is mounted, so it is safe. |
| Everything loops "already mounted" | The device has several partitions; pass a specific one, e.g. `usb-mount.sh sdb2`. |

## Testing

`tests/usb/run-tests.sh` puts fake `lsblk`, `udisksctl`, `findmnt` and `lsof` binaries in front of `PATH` and drives both scripts through 40 assertions — listing, plain mount, idempotent re-mount, FAT-family remount, `--no-fix`, POSIX ownership refusal, whole-disk expansion, busy-drive protection, `--force` lazy unmount, `--all`, and the no-hardware error path:

```bash
bash scripts/bin/tests/usb/run-tests.sh
# passed: 40   failed: 0
```

No USB stick, no root and no real block device is touched — state lives in a temp directory that is removed on exit.

Real-hardware notes:

- udisks assigns `/run/media/$USER/<label>`; labels with slashes or spaces get sanitised.
- `--dir` deliberately uses `sudo mount`, because udisks2 2.12 cannot be told a mountpoint.