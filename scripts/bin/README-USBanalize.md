# USBanalize (v3.1 Pro Edition)

**USB Storage Discovery, Content Scanner & Duplicate Analyzer**  
*Created by **ShadowHarvy***

![Python Version](https://img.shields.io/badge/python-3.8%2B-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux-green.svg)
![Dependencies](https://img.shields.io/badge/dependencies-zero-success.svg)
![License](https://img.shields.io/badge/license-MIT-purple.svg)

```text
  _   _ ____ ____                       _ _ ze 
 | | | / ___| __ )  __─█████─█─█─█▀█─██▀  ██  
 | | | \___ \  _ \ / _` / _ \| ' \/ _` | | |  
 | |_| |___) | |_) | (_| | (_) | | | (_| | | |  
  \___/|____/|____/ \__,_|\___/|_| |_|\__,_|_|_|  
  
   USB Storage Discovery & Content Analyzer v3.1 Pro
   Created by: ShadowHarvy
```

`USBanalize` is an ultra-fast, multi-threaded command-line utility for Linux systems designed to discover USB drives, inspect filesystem metadata, benchmark read speeds, map directory storage usage, find duplicate files instantly, and generate visual HTML/JSON reports.

---

## ⚡ Highlights & Key Capabilities

* **🔌 Smart Device & Partition Discovery**: Uses Linux `lsblk` to detect USB drives, external HDDs, SSDs, and flash media. Automatically inherits hardware vendor and model info from parent drive nodes to child partitions.
* **💽 Drive Metadata & Compatibility Insights**: Inspects Filesystem Formats (`exFAT`, `BTRFS`, `FAT32`, `NTFS`, `ext4`), volume UUIDs, volume labels, read-only status, and provides cross-platform compatibility notes (such as FAT32 4GB single-file limit warnings).
* **⚙️ Hardware Drive Type Detection**: Inspects block device sysfs `ROTA` flags to distinguish **HDD (Rotational)** platter disks from **SSD / Flash Memory**.
* **⚡ High-Performance Parallel Tree Scanning**: Combines `os.scandir()` with `ThreadPoolExecutor` to scan tens of thousands of files across directories in seconds.
* **🔎 Ultra-Fast 3-Point Sample Duplicate Detection (`--find-duplicates`)**: Employs instantaneous 3-point SHA256 sample hashing (Head + Middle + Tail chunks) to find duplicate multi-gigabyte files without waiting minutes for full disk reads.
* **🧹 Safe Duplicate Cleanup Script Generator (`--gen-cleanup-script`)**: Generates a safe bash script (`delete_duplicates.sh`) listing duplicate file sets with commented-out `rm` commands for safe manual review and storage recovery.
* **⏱️ Sequential Read Speed Benchmark (`--benchmark`)**: Non-destructively measures real-time sequential read bandwidth (MB/s) of mounted storage volumes.
* **📁 Directory Storage Treemap**: Calculates and ranks the top largest folders consuming disk space on each drive.
* **📊 Dual Category & Extension Analytics**: Groups drive content into high-level categories (*Archive*, *Code*, *Audio*, *Video*, *Images*, *Executables*) alongside specific extension/language counts (*Python*, *C*, *PNG*, *OGG*, *ZIP*, etc.).
* **📅 File Age Timeline Breakdown**: Visualizes file age distribution across modification timelines (*< 30 Days*, *1 - 6 Months*, *6 - 12 Months*, *1 - 3 Years*, *Older than 3 Years*).
* **📄 Interactive HTML & JSON Exports**: Export full scan analytics into a responsive HTML report (`--export-html report.html`) or structured raw data (`--export-json report.json`).

---

## 🛠️ Prerequisites & Installation

### Requirements

* **Operating System:** Linux (Ubuntu, Debian, Fedora, Arch Linux, openSUSE, RHEL, etc.)
* **Python:** Python 3.8+
* **System Utilities:** Standard Linux `lsblk` utility (pre-installed on virtually all Linux distros).
* **Dependencies:** **Zero external pip packages!** Uses Python standard library modules (`os`, `json`, `subprocess`, `hashlib`, `concurrent.futures`, `shutil`).

### Setup

Download or copy `usb_scanner.py` to your system and ensure it is executable:

```bash
chmod +x usb_scanner.py
```

---

## 📖 Quick Start & Examples

### 1. Basic USB Scan

Discover and scan all connected USB devices:

```bash
python3 usb_scanner.py
```

### 2. Deep Analysis with Benchmark & Duplicate Detection

Find duplicate files, run a read speed benchmark, and export an HTML report:

```bash
python3 usb_scanner.py --find-duplicates --benchmark --export-html USBanalize_Report.html
```

### 3. Safely Reclaiming Space from Duplicate Files

Generate a safe duplicate cleanup shell script:

```bash
python3 usb_scanner.py --find-duplicates --gen-cleanup-script delete_duplicates.sh
```

**How to review and execute the cleanup script:**
1. Open `delete_duplicates.sh` in any text editor.
2. Review the duplicate groups (the original copy is safely kept as a comment reference).
3. Uncomment (`#`) the `rm` commands for duplicate files you want to remove:
   ```bash
   # rm -v "/run/media/me/USB/path/to/duplicate_file.zip"
   ```
4. Execute the script to safely free disk space:
   ```bash
   ./delete_duplicates.sh
   ```

### 4. Custom Path Analysis

Scan any local folder (e.g., `~/Downloads` or `/var/log`) instead of scanning USB drives:

```bash
python3 usb_scanner.py --path ~/Downloads --top 20 --find-duplicates
```

### 5. Including Internal Disks & NVMe Storage

Include internal SATA/NVMe disks and swap partitions in the scan:

```bash
python3 usb_scanner.py --all
```

---

## 🎛️ Command-Line Arguments Reference

| Option | Type | Description |
| :--- | :--- | :--- |
| `--all` | Flag | Include all block devices (NVMe, internal drives, swap partitions). |
| `--path PATH` | String | Scan a specific folder path instead of discovering USB drives. |
| `--top N` | Integer | Number of largest files to display (default: `10`). |
| `--find-duplicates` | Flag | Scan for duplicate files and calculate wasted storage space. |
| `--dup-min-mb MB` | Integer | Minimum file size in MB for duplicate candidate screening (default: `1`). |
| `--benchmark` | Flag | Run a non-destructive sequential read speed test (MB/s). |
| `--gen-cleanup-script FILE` | String | Generate a safe bash script listing duplicates for manual review & deletion. |
| `--threads N` | Integer | Number of parallel worker threads for directory scanning (default: `8`). |
| `--exclude PATTERN...` | List | Custom directory or filename patterns to ignore (e.g. `--exclude temp backup`). |
| `--export-json FILE` | String | Export full scan metadata and statistics to a JSON file. |
| `--export-html FILE` | String | Export scan report to a self-contained HTML file. |
| `--no-color` | Flag | Disable ANSI colored terminal output. |

---

## 💻 Sample Console Output

```text
  _   _ ____ ____                       _ _ ze 
 | | | / ___| __ )  __─█████─█─█─█▀█─██▀  ██  
 | | | \___ \  _ \ / _` / _ \| ' \/ _` | | |  
 | |_| |___) | |_) | (_| | (_) | | | (_| | | |  
  \___/|____/|____/ \__,_|\___/|_| |_|\__,_|_|_|  

       USB Device Discovery & Content Scanner v3.1
       By ShadowHarvy • Multi-Threaded • Duplicate Finder • HTML Reports

════════════════════════════════════════════════════════════════════

Benchmarking read speed for /dev/sda1... Read Speed Benchmark: 59.1 MB/s

┌──────────────────────────────────────────────────────────────────┐
│ Device Node: /dev/sda1                                           │
├──────────────────────────────────────────────────────────────────┤
│   Hardware Model:  Seagate BUP Slim RD                            │
│   Parent Drive:    /dev/sda                                      │
│   Drive Type:      HDD (Rotational)                              │
│   Filesystem:      BTRFS                                         │
│   Read Speed:      59.1 MB/s (Sequential Benchmark)              │
│   Filesystem UUID: ba69a7af-7285-47f1-ad92-c5c561aa41df          │
│   Total Capacity:  931.51 GiB                                    │
│   Mount Point:     /run/media/me/ba69a7af-7285-47f1-ad92-...      │
│   Access Flags:    Read-Write                                    │
├──────────────────────────────────────────────────────────────────┤
│   Storage Usage:                                                 │
│     Used: 624.66 GiB [█████████████░░░░░░░]  67.1%             │
│     Free: 306.66 GiB                                           │
└──────────────────────────────────────────────────────────────────┘

  Content Analysis Summary:
    Directories: 1,133  │  Files: 23,776  │  Data Size: 622.78 GiB

    Top Folders by Storage Usage:
      pirate/              [████████████] 374.40 GiB  (296 files)
      12/                  [███░░░░░░░░░] 100.26 GiB  (36 files)
      11/                  [█░░░░░░░░░░░]  53.05 GiB  (36 files)

    Content Categories:
      Archive              [████████████] 504.99 GiB  (357 files)
      Other                [██░░░░░░░░░░] 112.20 GiB  (7,746 files)

    Duplicate Files Alert:
      Found 54 duplicate set(s) wasting 21.32 GiB of space!
      • Set size: 7.25 GiB × 2 copies (Wasted: 7.25 GiB)
        └─ pirate/Sample.zip
        └─ 11/Sample.zip

✓ Safe duplicate cleanup script generated: delete_duplicates.sh
✓ Interactive HTML scan report exported to: USBanalize_Report.html
```

---

## 👤 Author & License

* **Author:** **ShadowHarvy**
* **Project Name:** `USBanalize`
* **License:** MIT License
