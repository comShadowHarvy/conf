#!/usr/bin/env python3
import subprocess
import json
import shutil
import os
import sys
import time
import heapq
from collections import defaultdict
from pathlib import Path

def print_title():
    """Prints a fancy title screen."""
    title_art = r"""
  _   _  _____ ____      _                _                   
 | | | |/ ____|  _ \    / \   _ __   __ _| |_   _ _______ ____ 
 | | | | (___ | |_) |  / _ \ | '_ \ / _` | | | | |_  / _ \ '__|
 | |_| |\___ \|  _ <  / ___ \| | | | (_| | | |_| |/ /  __/ |   
  \___/ _____) | |_) |/_/   \_\_| |_|\__,_|_|\__, /___\___|_|   
       |_____/                               |___/              
    """
    print("\033[1;36m" + title_art + "\033[0m")
    print("\033[1;37m       USB Device Discovery & Content Scanner\033[0m")
    print("\n" + "="*60 + "\n")

def get_drive_info():
    """
    Runs lsblk to get information about all block devices.
    Returns a dictionary of devices.
    """
    try:
        cmd = [
            "lsblk", "-J", "-b",
            "-o", "NAME,TRAN,MOUNTPOINT,FSTYPE,SIZE,RO,RM,MODEL,VENDOR,UUID,LABEL"
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error running lsblk: {e}")
        return None
    except json.JSONDecodeError as e:
        print(f"Error parsing lsblk output: {e}")
        return None

def find_usb_devices(lsblk_data):
    """
    Filters lsblk output for USB devices.
    """
    usb_devices = []
    
    if not lsblk_data or 'blockdevices' not in lsblk_data:
        return []

    def recurse_devices(devices, is_usb_parent=False):
        for dev in devices:
            is_usb = is_usb_parent or dev.get('tran') == 'usb'
            if is_usb:
                usb_devices.append(dev)
            
            if 'children' in dev:
                recurse_devices(dev['children'], is_usb)

    recurse_devices(lsblk_data['blockdevices'])
    return usb_devices

def analyze_directory(path):
    """
    Walks a directory to count file extensions and estimate languages.
    Updates a progress indicator on the same line.
    """
    stats = {
        'file_count': 0,
        'skipped_count': 0,
        'extensions': defaultdict(int),
        'languages': defaultdict(int),
        'languages_size': defaultdict(int),
        'size_bytes': 0,
        'largest_files': [] # List of tuples (size, path)
    }
    
    ext_map = {
        '.py': 'Python', '.js': 'JavaScript', '.ts': 'TypeScript', '.jsx': 'React (JS)', '.tsx': 'React (TS)',
        '.vue': 'Vue.js', '.c': 'C', '.cpp': 'C++', '.h': 'C/C++ Header', '.cs': 'C#',
        '.java': 'Java', '.go': 'Go', '.rs': 'Rust', '.swift': 'Swift', '.kt': 'Kotlin',
        '.rb': 'Ruby', '.php': 'PHP', '.html': 'HTML', '.htm': 'HTML',
        '.css': 'CSS', '.scss': 'Sass', '.less': 'Less',
        '.sh': 'Shell', '.bash': 'Shell', '.zsh': 'Shell', '.bat': 'Batch', '.ps1': 'PowerShell',
        '.md': 'Markdown', '.txt': 'Text', '.json': 'JSON', '.yaml': 'YAML', '.yml': 'YAML',
        '.xml': 'XML', '.sql': 'SQL', '.toml': 'TOML', '.ini': 'INI',
        '.jpg': 'Image', '.jpeg': 'Image', '.png': 'Image', '.gif': 'Image', '.svg': 'Image', '.webp': 'Image',
        '.mp4': 'Video', '.mkv': 'Video', '.mov': 'Video', '.avi': 'Video', '.webm': 'Video',
        '.mp3': 'Audio', '.wav': 'Audio', '.flac': 'Audio', '.m4a': 'Audio', '.ogg': 'Audio',
        '.zip': 'Archive', '.tar': 'Archive', '.gz': 'Archive', '.7z': 'Archive', '.rar': 'Archive',
        '.pdf': 'PDF', '.doc': 'Document', '.docx': 'Document', '.xls': 'Spreadsheet', '.xlsx': 'Spreadsheet',
        '.ppt': 'Presentation', '.pptx': 'Presentation'
    }

    print(f"Scanning... ", end="", flush=True)

    try:
        path_obj = Path(path)
        for root, _, files in os.walk(path):
            for file in files:
                stats['file_count'] += 1
                
                if stats['file_count'] % 10 == 0:
                    print(f"\rScanning... {stats['file_count']} files found", end="", flush=True)

                file_path = Path(root) / file
                file_size = 0
                try:
                    file_size = file_path.lstat().st_size
                    stats['size_bytes'] += file_size
                    
                    # Store top 10 largest files using a min-heap
                    # We store (size, path)
                    # If heap is < 10, push. If > 10, pushpop (pushes new, pops smallest)
                    if len(stats['largest_files']) < 10:
                         heapq.heappush(stats['largest_files'], (file_size, str(file_path)))
                    else:
                        heapq.heappushpop(stats['largest_files'], (file_size, str(file_path)))

                except (OSError, ValueError):
                    stats['skipped_count'] += 1
                    continue

                suffix = file_path.suffix.lower()
                if suffix:
                    stats['extensions'][suffix] += 1
                    if suffix in ext_map:
                        lang = ext_map[suffix]
                        stats['languages'][lang] += 1
                        stats['languages_size'][lang] += file_size
                    
    except PermissionError:
        print(f"\nWarning: Permission denied accessing some files in {path}")
    except OSError as e:
        print(f"\nError scanning {path}: {e}")
    
    # Sort largest files descending for final output (heap is min-heap)
    stats['largest_files'].sort(key=lambda x: x[0], reverse=True)

    # Clear the progress line
    print(f"\rScan Complete! Analyzed {stats['file_count']} files.      ")
    return stats

def human_readable_size(size_bytes):
    """Converts bytes to human readable string."""
    if size_bytes is None:
        return "Unknown"
    try:
        size_bytes = int(size_bytes)
    except ValueError:
        return str(size_bytes)

    if size_bytes == 0:
        return "0B"
    size_name = ("B", "KB", "MB", "GB", "TB")
    i = 0
    p = float(size_bytes)
    import math
    if size_bytes > 0:
        i = int(math.floor(math.log(size_bytes, 1024)))
    
    if i >= len(size_name):
        i = len(size_name) - 1
        
    p = round(p / math.pow(1024, i), 2)
    return "%s %s" % (p, size_name[i])

def draw_bar(count, max_count, width=15):
    """Draws an ASCII bar."""
    if max_count == 0:
        filled = 0
    else:
        filled = int((count / max_count) * width)
    
    # Using different block characters for visual interest
    bar = "█" * filled + "░" * (width - filled)
    return bar

def format_output(device_info, scan_stats=None, disk_usage=None):
    """Parses and properly formats the output for the user."""
    
    name = device_info.get('name', 'Unknown')
    size = device_info.get('size')
    mountpoint = device_info.get('mountpoint')
    
    print("-" * 60)
    print(f"\033[1;33mDevice: {name}\033[0m")
    print(f"  Total Size: {human_readable_size(size)}")
    print(f"  Mount Point: {mountpoint if mountpoint else 'Not Mounted'}")
    
    if mountpoint and disk_usage:
        total, used, free = disk_usage
        print(f"  Storage Usage:")
        print(f"    Used: {human_readable_size(used)} / {human_readable_size(total)}")
        print(f"    Free: {human_readable_size(free)}")
    
    if scan_stats:
        print(f"  Content Analysis:")
        print(f"    Total Files: {scan_stats['file_count']} (Skipped: {scan_stats['skipped_count']})")
        print(f"    Data Size:   {human_readable_size(scan_stats['size_bytes'])}")
        
        if scan_stats['languages']:
            print(f"\n    \033[1;32mFile Composition (Count | Size):\033[0m")
            
            sorted_langs = sorted(scan_stats['languages'].items(), key=lambda x: x[1], reverse=True)
            max_count = sorted_langs[0][1] if sorted_langs else 0
            max_size = max(scan_stats['languages_size'].values()) if scan_stats['languages_size'] else 0
            
            # Palette for cycling colors (Red, Green, Yellow, Blue, Magenta, Cyan)
            colors = [
                "\033[31m", # Red
                "\033[32m", # Green
                "\033[33m", # Yellow
                "\033[34m", # Blue
                "\033[35m", # Magenta
                "\033[36m"  # Cyan
            ]
            reset = "\033[0m"

            for i, (lang, count) in enumerate(sorted_langs):
                size_bytes = scan_stats['languages_size'].get(lang, 0)
                
                count_bar = draw_bar(count, max_count, width=10)
                size_bar = draw_bar(size_bytes, max_size, width=10)
                size_str = human_readable_size(size_bytes)
                
                # Assign distinct color per row
                color = colors[i % len(colors)]
                
                lang_str = f"{lang:<12}"
                count_str = f"{str(count):<6}"
                
                print(f"      {color}{lang_str} {count_bar} {count_str} {size_bar} {size_str}{reset}")
        else:
             print("    No recognized file types found.")
             
        if scan_stats.get('largest_files'):
            print(f"\n    \033[1;35mTop 10 Largest Files:\033[0m")
            for size, path in scan_stats['largest_files']:
                # Truncate path if too long?
                # Let's show relative path if possible, or usually just filename is enough if path is super deep
                # For now entire path
                # print formatted: [SIZE] Path
                print(f"      [{human_readable_size(size):>8}] {path}")

    print("-" * 60)
    print("\n") 

def main():
    print_title()
    print("Searching for devices...\n")
    
    data = get_drive_info()
    if not data:
        return

    usb_devices = find_usb_devices(data)
    
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
        print("No USB storage devices found.")
        return

    def get_size(d):
        try:
            return int(d.get('size', 0) or 0)
        except ValueError:
            return float('inf') 

    unique_devices.sort(key=get_size)

    print(f"Found {len(unique_devices)} USB device(s). Processing smallest to largest...\n")
    time.sleep(1) 
    
    for i, dev in enumerate(unique_devices, 1):
        print(f"[{i}/{len(unique_devices)}] Processing {dev.get('name')}...", flush=True)
        
        mountpoint = dev.get('mountpoint')
        scan_stats = None
        disk_usage = None
        
        if mountpoint and os.path.isdir(mountpoint):
            try:
                usage = shutil.disk_usage(mountpoint)
                disk_usage = (usage.total, usage.used, usage.free)
                scan_stats = analyze_directory(mountpoint)
            except Exception as e:
                print(f"Error accessing {mountpoint}: {e}")
        
        format_output(dev, scan_stats, disk_usage)
        
        if i < len(unique_devices):
            print("Processing next device in 2 seconds...", end="", flush=True)
            time.sleep(2)
            print("\r" + " " * 40 + "\r", end="") # Clear line

if __name__ == "__main__":
    main()
