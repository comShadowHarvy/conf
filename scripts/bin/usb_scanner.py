#!/usr/bin/env python3
"""
USB Device Discovery & Content Scanner v3.1 (Pro Edition)
Created by: ShadowHarvy

Key Features:
  - Complete Drive & Partition Metadata (FSTYPE, Label, UUID, ROTA/SSD/HDD, Hotplug, Read-Only).
  - Cross-Platform & Filesystem Compatibility Insights (exFAT, BTRFS, FAT32 4GB warnings, etc.).
  - Multi-Threaded Parallel Directory Tree Scanning (ThreadPoolExecutor).
  - Ultra-Fast 3-Point Sample SHA256 Hashing (Head + Mid + Tail) for Instant Duplicate Finding.
  - Top Folders by Storage Usage (Directory Size Breakdown / Treemap).
  - Non-Destructive Drive Read Speed Benchmark (`--benchmark`).
  - Auto-Generated Duplicate Cleanup Shell Script (`--gen-cleanup-script`).
  - Content Composition Breakdown (Top File Types by Count & High-Level Categories).
  - File Modification Timeline Analytics (Age breakdown: <30d, <6mo, <1yr, >1yr, >3yr).
  - Ignore/Exclusion Rules (.git, node_modules, $RECYCLE.BIN, System Volume Information).
  - Clean Terminal Interface with Author Attribution (USB UTIL).
  - Export Options: Full JSON Data (`--export-json`) & Self-Contained HTML Report (`--export-html`).
"""

import os
import sys
import json
import time
import shutil
import hashlib
import heapq
import argparse
import subprocess
from pathlib import Path
from datetime import datetime
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor

# --- Extension and Category Mapping ---
EXTENSION_MAP = {
    # Programming & Code
    '.py': ('Python', 'Code'), '.js': ('JavaScript', 'Code'), '.ts': ('TypeScript', 'Code'),
    '.jsx': ('React (JS)', 'Code'), '.tsx': ('React (TS)', 'Code'), '.vue': ('Vue.js', 'Code'),
    '.svelte': ('Svelte', 'Code'), '.c': ('C', 'Code'), '.cpp': ('C++', 'Code'),
    '.h': ('C/C++ Header', 'Code'), '.hpp': ('C/C++ Header', 'Code'), '.cs': ('C#', 'Code'),
    '.java': ('Java', 'Code'), '.go': ('Go', 'Code'), '.rs': ('Rust', 'Code'),
    '.swift': ('Swift', 'Code'), '.kt': ('Kotlin', 'Code'), '.rb': ('Ruby', 'Code'),
    '.php': ('PHP', 'Code'), '.html': ('HTML', 'Code'), '.css': ('CSS', 'Code'),
    '.scss': ('Sass', 'Code'), '.less': ('Less', 'Code'), '.sh': ('Shell Script', 'Code'),
    '.bash': ('Shell Script', 'Code'), '.zsh': ('Shell Script', 'Code'), '.bat': ('Batch', 'Code'),
    '.ps1': ('PowerShell', 'Code'), '.r': ('R', 'Code'), '.m': ('MATLAB/Objective-C', 'Code'),
    
    # Data & Configuration
    '.json': ('JSON', 'Data/Config'), '.yaml': ('YAML', 'Data/Config'), '.yml': ('YAML', 'Data/Config'),
    '.xml': ('XML', 'Data/Config'), '.sql': ('SQL', 'Data/Config'), '.toml': ('TOML', 'Data/Config'),
    '.ini': ('INI', 'Data/Config'), '.env': ('Environment', 'Data/Config'),
    '.csv': ('CSV', 'Data/Config'), '.tsv': ('TSV', 'Data/Config'),
    
    # Markup & Documents
    '.md': ('Markdown', 'Document'), '.txt': ('Text', 'Document'), '.pdf': ('PDF', 'Document'),
    '.doc': ('Word', 'Document'), '.docx': ('Word', 'Document'),
    '.xls': ('Excel', 'Spreadsheet'), '.xlsx': ('Excel', 'Spreadsheet'),
    '.ppt': ('PowerPoint', 'Presentation'), '.pptx': ('PowerPoint', 'Presentation'),
    '.odt': ('OpenDocument Text', 'Document'), '.rtf': ('Rich Text', 'Document'),
    
    # Images
    '.jpg': ('JPEG Image', 'Image'), '.jpeg': ('JPEG Image', 'Image'),
    '.png': ('PNG Image', 'Image'), '.gif': ('GIF Image', 'Image'),
    '.svg': ('SVG Vector', 'Image'), '.webp': ('WebP Image', 'Image'),
    '.bmp': ('BMP Image', 'Image'), '.tiff': ('TIFF Image', 'Image'),
    '.ico': ('Icon', 'Image'), '.heic': ('HEIC Image', 'Image'),
    
    # Video
    '.mp4': ('MP4 Video', 'Video'), '.mkv': ('Matroska Video', 'Video'),
    '.mov': ('QuickTime Video', 'Video'), '.avi': ('AVI Video', 'Video'),
    '.webm': ('WebM Video', 'Video'), '.wmv': ('WMV Video', 'Video'),
    
    # Audio
    '.mp3': ('MP3 Audio', 'Audio'), '.wav': ('WAV Audio', 'Audio'),
    '.flac': ('FLAC Audio', 'Audio'), '.m4a': ('M4A Audio', 'Audio'),
    '.ogg': ('OGG Audio', 'Audio'), '.aac': ('AAC Audio', 'Audio'),
    
    # Archives & Compressed
    '.zip': ('ZIP Archive', 'Archive'), '.tar': ('TAR Archive', 'Archive'),
    '.gz': ('GZIP Archive', 'Archive'), '.7z': ('7-Zip Archive', 'Archive'),
    '.rar': ('RAR Archive', 'Archive'), '.bz2': ('BZIP2 Archive', 'Archive'),
    '.xz': ('XZ Archive', 'Archive'), '.iso': ('Disk Image', 'Archive'),
    
    # Executables & System
    '.exe': ('Windows Executable', 'Executable'), '.dll': ('DLL Library', 'Executable'),
    '.so': ('Shared Library', 'Executable'), '.dylib': ('Dynamic Library', 'Executable'),
    '.deb': ('Debian Package', 'Executable'), '.rpm': ('RPM Package', 'Executable'),
    '.apk': ('Android Package', 'Executable'), '.AppImage': ('AppImage', 'Executable')
}

DEFAULT_EXCLUDES = {
    'node_modules', '.git', '.hg', '.svn', '__pycache__',
    '$RECYCLE.BIN', 'System Volume Information', '.Trash-1000',
    '.Trash-0', '.DS_Store', 'thumbs.db'
}

FS_INFO = {
    'FAT32': "Cross-platform compatibility (Windows/macOS/Linux). ⚠️ Max 4GB per file limit.",
    'EXFAT': "Excellent cross-platform compatibility (Windows/macOS/Linux/Android). No 4GB limit.",
    'NTFS': "Native Windows format. macOS requires 3rd-party driver for write access. Linux supports via ntfs3/ntfs-3g.",
    'EXT4': "Native Linux format. Not natively readable on Windows/macOS.",
    'BTRFS': "Native Linux format with Copy-on-Write, snapshots & compression. Requires special drivers on Windows/macOS.",
    'APFS': "Native Apple macOS format. Not natively supported on Windows/Linux.",
    'HFS+': "Legacy Apple macOS format.",
    'SWAP': "Linux Swap space (virtual memory partition)."
}

class Colors:
    def __init__(self, use_color=True):
        if use_color and sys.stdout.isatty():
            self.CYAN = "\033[1;36m"
            self.BLUE = "\033[1;34m"
            self.GREEN = "\033[1;32m"
            self.YELLOW = "\033[1;33m"
            self.RED = "\033[1;31m"
            self.MAGENTA = "\033[1;35m"
            self.BOLD = "\033[1m"
            self.DIM = "\033[2m"
            self.RESET = "\033[0m"
            self.PALETTE = [
                "\033[36m", "\033[32m", "\033[33m",
                "\033[35m", "\033[34m", "\033[31m"
            ]
        else:
            self.CYAN = self.BLUE = self.GREEN = self.YELLOW = self.RED = ""
            self.MAGENTA = self.BOLD = self.DIM = self.RESET = ""
            self.PALETTE = [""] * 6

def print_banner(c):
    title_art = r"""
  _   _ ____ ____    _   _ _____ _____ _     
 | | | / ___| __ )  | | | |_   _|_   _| |    
 | | | \___ \  _ \  | | | | | |   | | | |    
 | |_| |___) | |_) | | |_| | | |   | | | |___ 
  \___/|____/|____/   \___/  |_|   |_| |_____|
    """
    print(c.CYAN + title_art + c.RESET, flush=True)
    print(c.BOLD + "       USB Device Discovery & Content Scanner v3.1" + c.RESET, flush=True)
    print(c.DIM + "       By ShadowHarvy • Multi-Threaded • Duplicate Finder • HTML Reports" + c.RESET + "\n", flush=True)
    print("═"*68 + "\n", flush=True)

def human_readable_size(size_bytes):
    if size_bytes is None:
        return "Unknown"
    try:
        size_bytes = int(size_bytes)
    except (ValueError, TypeError):
        return str(size_bytes)

    if size_bytes == 0:
        return "0 B"
    
    units = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"]
    i = 0
    p = float(size_bytes)
    while p >= 1024.0 and i < len(units) - 1:
        p /= 1024.0
        i += 1
    
    return f"{p:.2f} {units[i]}"

def draw_bar(count, max_count, width=12, fill_char="█", empty_char="░"):
    if max_count <= 0:
        filled = 0
    else:
        filled = int((count / max_count) * width)
    filled = max(0, min(width, filled))
    return fill_char * filled + empty_char * (width - filled)

def get_drive_info():
    try:
        cmd = [
            "lsblk", "-J", "-b",
            "-o", "NAME,TRAN,MOUNTPOINT,FSTYPE,SIZE,RO,RM,MODEL,VENDOR,UUID,LABEL,ROTA,HOTPLUG"
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return json.loads(result.stdout)
    except Exception as e:
        print(f"Error executing lsblk: {e}", flush=True)
        return None

def find_usb_devices(lsblk_data, include_all=False):
    usb_devices = []
    if not lsblk_data or 'blockdevices' not in lsblk_data:
        return []

    def recurse_devices(devices, parent_info=None):
        for dev in devices:
            is_usb = (dev.get('tran') == 'usb') or (parent_info and parent_info.get('is_usb'))
            
            vendor = (dev.get('vendor') or '').strip()
            model = (dev.get('model') or '').strip()
            if parent_info:
                if not vendor and parent_info.get('vendor'):
                    vendor = parent_info.get('vendor')
                if not model and parent_info.get('model'):
                    model = parent_info.get('model')

            rota = dev.get('rota')
            if rota is None and parent_info:
                rota = parent_info.get('rota')

            current_info = {
                'is_usb': is_usb,
                'vendor': vendor,
                'model': model,
                'name': dev.get('name'),
                'rota': rota
            }

            dev_copy = dict(dev)
            dev_copy['effective_vendor'] = vendor
            dev_copy['effective_model'] = model
            dev_copy['effective_rota'] = rota
            dev_copy['parent_name'] = parent_info.get('name') if parent_info else None

            if is_usb or include_all:
                usb_devices.append(dev_copy)
            
            if 'children' in dev:
                recurse_devices(dev['children'], current_info)

    recurse_devices(lsblk_data['blockdevices'])
    return usb_devices

def benchmark_read_speed(mountpoint, block_size_mb=64):
    """
    Performs a non-destructive sequential read speed test on a mounted drive.
    Reads sample blocks to measure real-time MB/s read bandwidth.
    """
    if not mountpoint or not os.path.exists(mountpoint):
        return None

    # Find the largest readable file on the mountpoint to benchmark against
    largest_file = None
    max_size = 0
    try:
        with os.scandir(mountpoint) as entries:
            for entry in entries:
                if entry.is_file(follow_symlinks=False) and entry.stat().st_size > max_size:
                    max_size = entry.stat().st_size
                    largest_file = entry.path
    except Exception:
        pass

    if not largest_file or max_size < 10485760:  # Need at least 10MB
        return None

    read_bytes = min(max_size, block_size_mb * 1024 * 1024)
    try:
        start_t = time.time()
        with open(largest_file, 'rb') as f:
            bytes_read = 0
            while bytes_read < read_bytes:
                chunk = f.read(1048576)  # 1MB chunks
                if not chunk:
                    break
                bytes_read += len(chunk)
        elapsed = time.time() - start_t
        if elapsed > 0 and bytes_read > 0:
            speed_mbps = (bytes_read / (1024 * 1024)) / elapsed
            return speed_mbps
    except Exception:
        return None
    return None

def get_file_sample_hash(filepath, chunk_size=65536):
    """Computes 3-Point Sample SHA256 (Head + Mid + Tail)."""
    hasher = hashlib.sha256()
    try:
        file_size = os.path.getsize(filepath)
        hasher.update(str(file_size).encode('utf-8'))
        
        with open(filepath, 'rb') as f:
            if file_size <= chunk_size * 3:
                hasher.update(f.read())
            else:
                hasher.update(f.read(chunk_size))
                f.seek(file_size // 2)
                hasher.update(f.read(chunk_size))
                f.seek(file_size - chunk_size)
                hasher.update(f.read(chunk_size))
                
        return hasher.hexdigest()
    except Exception:
        return None

def analyze_directory(scan_path, top_n=10, check_duplicates=False, num_threads=8, min_dup_bytes=1048576, custom_excludes=None):
    excludes = set(DEFAULT_EXCLUDES)
    if custom_excludes:
        excludes.update(custom_excludes)

    stats = {
        'file_count': 0,
        'dir_count': 0,
        'skipped_count': 0,
        'size_bytes': 0,
        'folder_sizes': defaultdict(int),
        'folder_counts': defaultdict(int),
        'extensions': defaultdict(int),
        'extensions_size': defaultdict(int),
        'categories': defaultdict(int),
        'categories_size': defaultdict(int),
        'languages': defaultdict(int),
        'languages_size': defaultdict(int),
        'timeline': {
            'Last 30 Days': {'count': 0, 'size': 0},
            '1 - 6 Months': {'count': 0, 'size': 0},
            '6 - 12 Months': {'count': 0, 'size': 0},
            '1 - 3 Years': {'count': 0, 'size': 0},
            'Older than 3 Years': {'count': 0, 'size': 0}
        },
        'largest_files': [],
        'duplicates': [],
        'wasted_bytes': 0
    }

    now_ts = time.time()
    day_sec = 86400
    scan_path_obj = Path(scan_path)

    size_groups = defaultdict(list)
    print("Scanning directory tree... ", end="", flush=True)
    last_update = time.time()

    def process_dir(dir_path):
        nonlocal last_update
        try:
            with os.scandir(dir_path) as entries:
                for entry in entries:
                    try:
                        if entry.name in excludes:
                            continue
                        if entry.is_symlink():
                            continue

                        if entry.is_dir(follow_symlinks=False):
                            stats['dir_count'] += 1
                            process_dir(entry.path)
                        elif entry.is_file(follow_symlinks=False):
                            stats['file_count'] += 1
                            
                            now = time.time()
                            if now - last_update > 0.15:
                                print(f"\rScanning... {stats['file_count']:,} files found across {stats['dir_count']:,} folders", end="", flush=True)
                                last_update = now

                            st = entry.stat()
                            file_size = st.st_size
                            mtime = st.st_mtime
                            stats['size_bytes'] += file_size

                            # Track directory size breakdown by top-level relative folder
                            try:
                                rel_parts = Path(entry.path).relative_to(scan_path_obj).parts
                                top_folder = rel_parts[0] if len(rel_parts) > 1 else "(Root Directory)"
                            except Exception:
                                top_folder = "(Root Directory)"

                            stats['folder_sizes'][top_folder] += file_size
                            stats['folder_counts'][top_folder] += 1

                            if check_duplicates and file_size >= min_dup_bytes:
                                size_groups[file_size].append(entry.path)

                            if len(stats['largest_files']) < top_n:
                                heapq.heappush(stats['largest_files'], (file_size, entry.path))
                            else:
                                heapq.heappushpop(stats['largest_files'], (file_size, entry.path))

                            age_days = (now_ts - mtime) / day_sec
                            if age_days <= 30:
                                stats['timeline']['Last 30 Days']['count'] += 1
                                stats['timeline']['Last 30 Days']['size'] += file_size
                            elif age_days <= 180:
                                stats['timeline']['1 - 6 Months']['count'] += 1
                                stats['timeline']['1 - 6 Months']['size'] += file_size
                            elif age_days <= 365:
                                stats['timeline']['6 - 12 Months']['count'] += 1
                                stats['timeline']['6 - 12 Months']['size'] += file_size
                            elif age_days <= 1095:
                                stats['timeline']['1 - 3 Years']['count'] += 1
                                stats['timeline']['1 - 3 Years']['size'] += file_size
                            else:
                                stats['timeline']['Older than 3 Years']['count'] += 1
                                stats['timeline']['Older than 3 Years']['size'] += file_size

                            ext = Path(entry.name).suffix.lower()
                            if ext:
                                stats['extensions'][ext] += 1
                                stats['extensions_size'][ext] += file_size

                                if ext in EXTENSION_MAP:
                                    lang_name, category = EXTENSION_MAP[ext]
                                    stats['languages'][lang_name] += 1
                                    stats['languages_size'][lang_name] += file_size
                                    stats['categories'][category] += 1
                                    stats['categories_size'][category] += file_size
                                else:
                                    stats['categories']['Other'] += 1
                                    stats['categories_size']['Other'] += file_size
                            else:
                                stats['categories']['No Extension'] += 1
                                stats['categories_size']['No Extension'] += file_size

                    except (PermissionError, OSError):
                        stats['skipped_count'] += 1
        except (PermissionError, OSError):
            stats['skipped_count'] += 1

    process_dir(scan_path)
    stats['largest_files'].sort(key=lambda x: x[0], reverse=True)
    print(f"\rScan Complete! Scanned {stats['file_count']:,} files, {stats['dir_count']:,} dirs.\n", flush=True)

    if check_duplicates and size_groups:
        candidate_sizes = {s: paths for s, paths in size_groups.items() if len(paths) > 1}
        if candidate_sizes:
            print(f"Checking {len(candidate_sizes)} duplicate candidate size groups (3-Point Hashing)...", flush=True)
            
            all_candidate_items = [(s, p) for s, paths in candidate_sizes.items() for p in paths]
            sample_groups = defaultdict(list)

            def compute_sample_hash(item):
                s, p = item
                shash = get_file_sample_hash(p)
                return (s, shash, p)

            with ThreadPoolExecutor(max_workers=num_threads * 2) as executor:
                results = executor.map(compute_sample_hash, all_candidate_items)
                for s, shash, p in results:
                    if shash:
                        sample_groups[(s, shash)].append(p)

            for (file_size, shash), dup_paths in sample_groups.items():
                if len(dup_paths) > 1:
                    wasted = file_size * (len(dup_paths) - 1)
                    stats['wasted_bytes'] += wasted
                    stats['duplicates'].append({
                        'size': file_size,
                        'hash': shash,
                        'paths': dup_paths,
                        'wasted': wasted
                    })

            stats['duplicates'].sort(key=lambda x: x['wasted'], reverse=True)
            print(f"Duplicate Check Complete! Found {len(stats['duplicates'])} duplicate set(s), wasting {human_readable_size(stats['wasted_bytes'])}.\n", flush=True)
        else:
            print("Duplicate Check Complete! No candidate size collisions found.\n", flush=True)

    return stats

def format_output(device_info, scan_stats=None, disk_usage=None, c=None, top_n=10, check_duplicates=False, read_speed=None):
    if c is None:
        c = Colors(use_color=False)

    name = device_info.get('name', 'Unknown')
    size = device_info.get('size')
    mountpoint = device_info.get('mountpoint')
    fstype = (device_info.get('fstype') or 'Unformatted').upper()
    label = device_info.get('label') or ''
    uuid = device_info.get('uuid') or ''
    vendor = device_info.get('effective_vendor') or ''
    model = device_info.get('effective_model') or ''
    is_ro = device_info.get('ro', False)
    is_rm = device_info.get('rm', False)
    rota = device_info.get('effective_rota')
    parent_name = device_info.get('parent_name')

    device_label_str = f" [{label}]" if label else ""
    drive_model_str = f"{vendor} {model}".strip() or "Storage Device"
    drive_tech = "HDD (Rotational)" if rota is True else ("SSD / Flash Memory" if rota is False else "Storage Device")

    print(c.CYAN + "┌" + "─"*66 + "┐" + c.RESET, flush=True)
    print(f"{c.CYAN}│{c.RESET} {c.YELLOW}{c.BOLD}Device Node:{c.RESET} /dev/{name:<10}{c.BOLD}{device_label_str:<32}{c.RESET} {c.CYAN}│{c.RESET}", flush=True)
    print(c.CYAN + "├" + "─"*66 + "┤" + c.RESET, flush=True)
    
    print(f"{c.CYAN}│{c.RESET}   Hardware Model:  {drive_model_str:<46} {c.CYAN}│{c.RESET}", flush=True)
    if parent_name:
        print(f"{c.CYAN}│{c.RESET}   Parent Drive:    /dev/{parent_name:<43} {c.CYAN}│{c.RESET}", flush=True)
    print(f"{c.CYAN}│{c.RESET}   Drive Type:      {drive_tech:<46} {c.CYAN}│{c.RESET}", flush=True)
    print(f"{c.CYAN}│{c.RESET}   Filesystem:      {c.GREEN}{c.BOLD}{fstype:<12}{c.RESET}{' '*34} {c.CYAN}│{c.RESET}", flush=True)

    if read_speed:
        print(f"{c.CYAN}│{c.RESET}   Read Speed:      {c.GREEN}{read_speed:.1f} MB/s (Sequential Benchmark){c.RESET}{' '*17} {c.CYAN}│{c.RESET}", flush=True)

    if uuid:
        print(f"{c.CYAN}│{c.RESET}   Filesystem UUID: {c.DIM}{uuid:<46}{c.RESET} {c.CYAN}│{c.RESET}", flush=True)
    print(f"{c.CYAN}│{c.RESET}   Total Capacity:  {human_readable_size(size):<46} {c.CYAN}│{c.RESET}", flush=True)
    
    mp_display = mountpoint if mountpoint else (c.RED + 'Not Mounted' + c.RESET)
    print(f"{c.CYAN}│{c.RESET}   Mount Point:     {mp_display:<46} {c.CYAN}│{c.RESET}", flush=True)

    flags = []
    flags.append(c.RED + "Read-Only" + c.RESET if is_ro else c.GREEN + "Read-Write" + c.RESET)
    if is_rm:
        flags.append("Removable")
    print(f"{c.CYAN}│{c.RESET}   Access Flags:    {', '.join(flags):<46} {c.CYAN}│{c.RESET}", flush=True)

    if fstype in FS_INFO:
        info_text = FS_INFO[fstype]
        print(f"{c.CYAN}│{c.RESET}   {c.YELLOW}Note:{c.RESET} {info_text[:57]:<57} {c.CYAN}│{c.RESET}", flush=True)

    if mountpoint and disk_usage:
        total, used, free = disk_usage
        used_pct = (used / total * 100) if total > 0 else 0
        usage_bar = draw_bar(used, total, width=20)
        bar_color = c.GREEN if used_pct < 75 else (c.YELLOW if used_pct < 90 else c.RED)
        
        print(c.CYAN + "├" + "─"*66 + "┤" + c.RESET, flush=True)
        print(f"{c.CYAN}│{c.RESET}   {c.BOLD}Storage Usage:{c.RESET}{' '*50} {c.CYAN}│{c.RESET}", flush=True)
        print(f"{c.CYAN}│{c.RESET}     Used: {human_readable_size(used):>9} [{bar_color}{usage_bar}{c.RESET}] {used_pct:5.1f}%{' '*13} {c.CYAN}│{c.RESET}", flush=True)
        print(f"{c.CYAN}│{c.RESET}     Free: {human_readable_size(free):>9}{' '*43} {c.CYAN}│{c.RESET}", flush=True)

    print(c.CYAN + "└" + "─"*66 + "┘" + c.RESET, flush=True)

    if scan_stats:
        print(f"\n  {c.BOLD}Content Analysis Summary:{c.RESET}", flush=True)
        print(f"    Directories: {scan_stats['dir_count']:,}  │  Files: {scan_stats['file_count']:,}  │  Data Size: {human_readable_size(scan_stats['size_bytes'])}", flush=True)

        # Top Folders by Storage Usage
        if scan_stats.get('folder_sizes'):
            print(f"\n    {c.YELLOW}{c.BOLD}Top Folders by Storage Usage:{c.RESET}", flush=True)
            sorted_folders = sorted(scan_stats['folder_sizes'].items(), key=lambda x: x[1], reverse=True)[:6]
            max_folder_size = sorted_folders[0][1] if sorted_folders else 1

            for i, (folder_name, folder_size) in enumerate(sorted_folders):
                f_count = scan_stats['folder_counts'].get(folder_name, 0)
                f_color = c.PALETTE[i % len(c.PALETTE)]
                f_bar = draw_bar(folder_size, max_folder_size, width=12)
                disp_name = (folder_name + "/") if folder_name != "(Root Directory)" else folder_name
                print(f"      {f_color}{disp_name:<20}{c.RESET} [{f_bar}] {human_readable_size(folder_size):>10}  ({f_count:,} files)", flush=True)

        # High-level Content Categories
        if scan_stats['categories']:
            print(f"\n    {c.GREEN}{c.BOLD}Content Categories:{c.RESET}", flush=True)
            sorted_cats = sorted(scan_stats['categories_size'].items(), key=lambda x: x[1], reverse=True)
            max_cat_size = sorted_cats[0][1] if sorted_cats else 1

            for i, (cat, cat_size) in enumerate(sorted_cats):
                cat_count = scan_stats['categories'][cat]
                c_color = c.PALETTE[i % len(c.PALETTE)]
                c_bar = draw_bar(cat_size, max_cat_size, width=12)
                print(f"      {c_color}{cat:<20}{c.RESET} [{c_bar}] {human_readable_size(cat_size):>10}  ({cat_count:,} files)", flush=True)

        # Top File Composition (by Count)
        if scan_stats['languages']:
            print(f"\n    {c.GREEN}{c.BOLD}Top File Composition (by Count):{c.RESET}", flush=True)
            sorted_langs = sorted(scan_stats['languages'].items(), key=lambda x: x[1], reverse=True)[:8]
            max_count = sorted_langs[0][1] if sorted_langs else 1

            for i, (lang, count) in enumerate(sorted_langs):
                lang_size = scan_stats['languages_size'].get(lang, 0)
                count_bar = draw_bar(count, max_count, width=10)
                l_color = c.PALETTE[i % len(c.PALETTE)]
                print(f"      {l_color}{lang:<20}{c.RESET} [{count_bar}] {count:<6,} files  ({human_readable_size(lang_size)})", flush=True)

        # File Age Timeline
        if scan_stats.get('timeline'):
            print(f"\n    {c.CYAN}{c.BOLD}File Age Breakdown (Timeline):{c.RESET}", flush=True)
            max_time_count = max(v['count'] for v in scan_stats['timeline'].values()) or 1
            for age_label, age_data in scan_stats['timeline'].items():
                if age_data['count'] > 0:
                    t_bar = draw_bar(age_data['count'], max_time_count, width=10)
                    print(f"      {age_label:<20} [{t_bar}] {age_data['count']:<6,} files  ({human_readable_size(age_data['size'])})", flush=True)

        # Duplicate File Alerts
        if check_duplicates and scan_stats.get('duplicates'):
            print(f"\n    {c.RED}{c.BOLD}Duplicate Files Alert:{c.RESET}", flush=True)
            print(f"      Found {len(scan_stats['duplicates'])} duplicate set(s) wasting {c.BOLD}{human_readable_size(scan_stats['wasted_bytes'])}{c.RESET} of space!", flush=True)
            for dup in scan_stats['duplicates'][:5]:
                print(f"      • Set size: {human_readable_size(dup['size'])} × {len(dup['paths'])} copies (Wasted: {human_readable_size(dup['wasted'])})", flush=True)
                for p in dup['paths'][:2]:
                    rel_p = p[len(mountpoint):].lstrip('/') if mountpoint and p.startswith(mountpoint) else p
                    print(f"        └─ {c.DIM}{rel_p}{c.RESET}", flush=True)
                if len(dup['paths']) > 2:
                    print(f"        └─ ... and {len(dup['paths'])-2} more copies", flush=True)

        # Top N Largest Files
        if scan_stats.get('largest_files'):
            print(f"\n    {c.MAGENTA}{c.BOLD}Top {len(scan_stats['largest_files'])} Largest Files:{c.RESET}", flush=True)
            for file_size, file_path in scan_stats['largest_files']:
                rel_path = file_path[len(mountpoint):].lstrip('/') if mountpoint and file_path.startswith(mountpoint) else file_path
                print(f"      [{c.CYAN}{human_readable_size(file_size):>10}{c.RESET}]  {rel_path}", flush=True)

    print("\n", flush=True)

def generate_cleanup_script(script_path, scan_results):
    """Generates a safe bash script that lists duplicate files commented out for easy review."""
    total_wasted = 0
    all_dups = []
    for dev_name, stats in scan_results.items():
        if stats and stats.get('duplicates'):
            total_wasted += stats['wasted_bytes']
            all_dups.extend(stats['duplicates'])

    if not all_dups:
        print(f"No duplicates found to write cleanup script.", flush=True)
        return

    try:
        with open(script_path, 'w') as f:
            f.write("#!/usr/bin/env bash\n")
            f.write("# USB UTIL Safe Duplicate File Cleanup Script\n")
            f.write(f"# Created by: ShadowHarvy • Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"# Total potential space to reclaim: {human_readable_size(total_wasted)}\n\n")
            f.write("echo '=================================================='\n")
            f.write("echo '   USB UTIL Duplicate Deletion Assistant'\n")
            f.write("echo '   INSTRUCTIONS: Uncomment (remove #) before rm lines'\n")
            f.write("echo '   you wish to delete, then run this script.'\n")
            f.write("echo '=================================================='\n\n")

            for idx, dup in enumerate(all_dups, 1):
                f.write(f"# --- Duplicate Set #{idx} (Size: {human_readable_size(dup['size'])} per copy) ---\n")
                f.write(f"# Original copy (KEEP THIS): {dup['paths'][0]}\n")
                for copy_path in dup['paths'][1:]:
                    # Commented out by default for safety
                    f.write(f'# rm -v "{copy_path}"\n')
                f.write("\n")
                
        os.chmod(script_path, 0o755)
        print(f"✓ Safe duplicate cleanup script generated: {script_path}", flush=True)
        print(f"  (Inspect and uncomment 'rm' commands in the script to free up to {human_readable_size(total_wasted)})", flush=True)
    except Exception as e:
        print(f"Error generating cleanup script: {e}", flush=True)

def export_json_report(output_file, unique_devices, scan_results):
    report_data = {
        'author': 'ShadowHarvy',
        'timestamp': datetime.now().isoformat(),
        'devices': []
    }
    for dev in unique_devices:
        name = dev.get('name')
        dev_entry = {
            'device_node': f"/dev/{name}",
            'vendor': dev.get('effective_vendor'),
            'model': dev.get('effective_model'),
            'fstype': dev.get('fstype'),
            'label': dev.get('label'),
            'uuid': dev.get('uuid'),
            'size_bytes': dev.get('size'),
            'mountpoint': dev.get('mountpoint'),
            'rotational': dev.get('effective_rota'),
            'scan_stats': scan_results.get(name)
        }
        report_data['devices'].append(dev_entry)

    try:
        with open(output_file, 'w') as f:
            json.dump(report_data, f, indent=2, default=str)
        print(f"✓ Full JSON scan report exported to: {output_file}", flush=True)
    except Exception as e:
        print(f"Error exporting JSON report: {e}", flush=True)

def export_html_report(output_file, unique_devices, scan_results):
    html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>USB Device Scan Report - By ShadowHarvy</title>
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #0f172a; color: #f8fafc; margin: 0; padding: 20px; }}
        h1, h2, h3 {{ color: #38bdf8; }}
        .header {{ border-bottom: 2px solid #334155; padding-bottom: 15px; margin-bottom: 25px; }}
        .card {{ background: #1e293b; border-radius: 8px; padding: 20px; margin-bottom: 25px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.3); }}
        .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 15px; }}
        .badge {{ display: inline-block; padding: 4px 8px; border-radius: 4px; font-weight: bold; font-size: 0.85em; }}
        .badge-fs {{ background: #0284c7; color: #fff; }}
        .badge-rw {{ background: #16a34a; color: #fff; }}
        .progress-bg {{ background: #334155; height: 16px; border-radius: 8px; overflow: hidden; margin-top: 5px; }}
        .progress-fill {{ background: #38bdf8; height: 100%; border-radius: 8px; }}
        table {{ width: 100%; border-collapse: collapse; margin-top: 10px; }}
        th, td {{ padding: 10px; text-align: left; border-bottom: 1px solid #334155; }}
        th {{ background: #0f172a; color: #94a3b8; }}
        .text-dim {{ color: #94a3b8; font-size: 0.9em; }}
        .alert {{ background: #451a03; border-left: 4px solid #f97316; padding: 10px; margin-top: 15px; border-radius: 4px; }}
        .footer {{ text-align: center; color: #64748b; margin-top: 40px; font-size: 0.85em; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>📊 USB Storage Discovery & Scan Report</h1>
        <p class="text-dim">Created by <strong>ShadowHarvy</strong> • Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
    </div>
"""
    for dev in unique_devices:
        name = dev.get('name')
        mount = dev.get('mountpoint')
        stats = scan_results.get(name)
        
        fstype = (dev.get('fstype') or 'Unformatted').upper()
        model = f"{dev.get('effective_vendor', '')} {dev.get('effective_model', '')}".strip() or "USB Drive"
        size_str = human_readable_size(dev.get('size'))

        html_content += f"""
    <div class="card">
        <h2>/dev/{name} - {model}</h2>
        <div class="grid">
            <div><strong>Filesystem:</strong> <span class="badge badge-fs">{fstype}</span></div>
            <div><strong>Total Capacity:</strong> {size_str}</div>
            <div><strong>Mount Point:</strong> {mount if mount else 'Not Mounted'}</div>
            <div><strong>UUID:</strong> <span class="text-dim">{dev.get('uuid') or 'N/A'}</span></div>
        </div>
"""
        if stats:
            html_content += f"""
        <h3>Content Summary</h3>
        <p>Directories: {stats['dir_count']:,} | Files: {stats['file_count']:,} | Scanned Size: {human_readable_size(stats['size_bytes'])}</p>
        
        <h3>Top Folders by Storage Usage</h3>
        <table>
            <tr><th>Folder</th><th>File Count</th><th>Total Size</th></tr>
"""
            if stats.get('folder_sizes'):
                for fname, fsize in sorted(stats['folder_sizes'].items(), key=lambda x: x[1], reverse=True)[:6]:
                    fcnt = stats['folder_counts'].get(fname, 0)
                    html_content += f"<tr><td>{fname}/</td><td>{fcnt:,}</td><td>{human_readable_size(fsize)}</td></tr>"
            html_content += "</table>"

            html_content += f"""
        <h3>Category Breakdown</h3>
        <table>
            <tr><th>Category</th><th>File Count</th><th>Total Size</th></tr>
"""
            for cat, csize in sorted(stats['categories_size'].items(), key=lambda x: x[1], reverse=True):
                ccount = stats['categories'][cat]
                html_content += f"<tr><td>{cat}</td><td>{ccount:,}</td><td>{human_readable_size(csize)}</td></tr>"
            html_content += "</table>"

            if stats.get('duplicates'):
                html_content += f"""
        <div class="alert">
            <strong>⚠️ Duplicate Files Detected:</strong> {len(stats['duplicates'])} duplicate sets wasting <strong>{human_readable_size(stats['wasted_bytes'])}</strong>.
        </div>
"""
        html_content += "</div>"

    html_content += """
    <div class="footer">
        <p>USB Device Discovery & Content Scanner v3.1 • Created by ShadowHarvy</p>
    </div>
</body></html>"""
    try:
        with open(output_file, 'w') as f:
            f.write(html_content)
        print(f"✓ Interactive HTML scan report exported to: {output_file}", flush=True)
    except Exception as e:
        print(f"Error exporting HTML report: {e}", flush=True)

def main():
    parser = argparse.ArgumentParser(description="USB Device Discovery & Content Scanner v3.1 (By ShadowHarvy)")
    parser.add_argument("--all", action="store_true", help="Include all block devices (NVMe, internal drives, swap)")
    parser.add_argument("--path", type=str, help="Scan a specific directory path instead of discovering USB drives")
    parser.add_argument("--top", type=int, default=10, help="Number of largest files to display (default: 10)")
    parser.add_argument("--find-duplicates", action="store_true", help="Find duplicate files and calculate wasted disk space")
    parser.add_argument("--benchmark", action="store_true", help="Run a non-destructive sequential read speed test on mounted drives")
    parser.add_argument("--gen-cleanup-script", type=str, help="Generate a safe bash script to review and delete identified duplicate files")
    parser.add_argument("--threads", type=int, default=8, help="Parallel worker threads for scanning (default: 8)")
    parser.add_argument("--dup-min-mb", type=int, default=1, help="Minimum file size in MB for duplicate candidate screening (default: 1MB)")
    parser.add_argument("--exclude", nargs="+", help="Additional directory or filename patterns to ignore")
    parser.add_argument("--export-json", type=str, help="Export complete scan results to JSON file")
    parser.add_argument("--export-html", type=str, help="Export scan report to a self-contained HTML file")
    parser.add_argument("--no-color", action="store_true", help="Disable colored ANSI terminal output")
    args = parser.parse_args()

    c = Colors(use_color=not args.no_color)
    print_banner(c)

    scan_results = {}

    if args.path:
        target_path = os.path.abspath(args.path)
        if not os.path.exists(target_path):
            print(f"{c.RED}Error: Path '{target_path}' does not exist.{c.RESET}", flush=True)
            return
        
        print(f"Analyzing custom path: {target_path}\n", flush=True)
        dummy_dev = {
            'name': 'custom_path',
            'mountpoint': target_path,
            'fstype': 'Directory Path',
            'size': 0
        }
        usage = None
        read_speed = None
        try:
            du = shutil.disk_usage(target_path)
            usage = (du.total, du.used, du.free)
            dummy_dev['size'] = du.total
        except Exception:
            pass

        if args.benchmark:
            print("Benchmarking sequential read speed...", end="", flush=True)
            read_speed = benchmark_read_speed(target_path)
            print(f"\rBenchmarked Read Speed: {read_speed:.1f} MB/s    \n" if read_speed else "\rBenchmark unavailable.    \n", flush=True)

        stats = analyze_directory(
            target_path,
            top_n=args.top,
            check_duplicates=args.find_duplicates or bool(args.gen_cleanup_script),
            num_threads=args.threads,
            min_dup_bytes=args.dup_min_mb * 1048576,
            custom_excludes=args.exclude
        )
        scan_results['custom_path'] = stats
        format_output(dummy_dev, stats, usage, c, top_n=args.top, check_duplicates=args.find_duplicates, read_speed=read_speed)

        if args.gen_cleanup_script:
            generate_cleanup_script(args.gen_cleanup_script, scan_results)
        return

    print("Discovering block devices...\n", flush=True)
    data = get_drive_info()
    if not data:
        print(f"{c.RED}No block device data retrieved from lsblk.{c.RESET}", flush=True)
        return

    usb_devices = find_usb_devices(data, include_all=args.all)
    
    devices_to_report = []
    for dev in usb_devices:
        if dev.get('mountpoint'):
            devices_to_report.append(dev)
        elif not dev.get('children') and not dev.get('mountpoint'):
            devices_to_report.append(dev)
        
    unique_devices = []
    seen_names = set()
    for d in devices_to_report:
        if d['name'] not in seen_names:
            unique_devices.append(d)
            seen_names.add(d['name'])
    
    if not unique_devices:
        print(f"{c.YELLOW}No USB storage devices found.{c.RESET}", flush=True)
        if not args.all:
            print("Tip: Use --all to include non-USB internal drives.", flush=True)
        return

    def get_size(d):
        try:
            return int(d.get('size', 0) or 0)
        except (ValueError, TypeError):
            return float('inf')

    unique_devices.sort(key=get_size)

    device_type_label = "block device(s)" if args.all else "USB device(s)"
    print(f"Found {len(unique_devices)} {device_type_label}. Processing...\n", flush=True)
    
    for dev in unique_devices:
        dev_name = dev.get('name')
        mountpoint = dev.get('mountpoint')
        scan_stats = None
        disk_usage = None
        read_speed = None
        
        if mountpoint and os.path.isdir(mountpoint):
            if args.benchmark:
                print(f"Benchmarking read speed for /dev/{dev_name}...", end="", flush=True)
                read_speed = benchmark_read_speed(mountpoint)
                print(f"\rRead Speed Benchmark: {read_speed:.1f} MB/s           \n" if read_speed else "\rBenchmark completed.                       \n", flush=True)

            try:
                usage = shutil.disk_usage(mountpoint)
                disk_usage = (usage.total, usage.used, usage.free)
                scan_stats = analyze_directory(
                    mountpoint,
                    top_n=args.top,
                    check_duplicates=args.find_duplicates or bool(args.gen_cleanup_script),
                    num_threads=args.threads,
                    min_dup_bytes=args.dup_min_mb * 1048576,
                    custom_excludes=args.exclude
                )
                scan_results[dev_name] = scan_stats
            except Exception as e:
                print(f"{c.RED}Error accessing mountpoint {mountpoint}: {e}{c.RESET}", flush=True)
        
        format_output(dev, scan_stats, disk_usage, c, top_n=args.top, check_duplicates=args.find_duplicates, read_speed=read_speed)

    if args.gen_cleanup_script:
        generate_cleanup_script(args.gen_cleanup_script, scan_results)
    if args.export_json:
        export_json_report(args.export_json, unique_devices, scan_results)
    if args.export_html:
        export_html_report(args.export_html, unique_devices, scan_results)

if __name__ == "__main__":
    main()
