# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "holidays",
#     "rich",
#     "httpx",
#     "psutil",
# ]
# ///

import socket
import psutil
import glob
import os
import random
import shutil
import time
from datetime import datetime, timedelta
import holidays
import httpx
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.text import Text
from rich.progress import BarColumn, Progress, TextColumn
from rich.layout import Layout
from rich.align import Align

console = Console()

# --- Configuration ---
LOCATION = {"lat": 43.83, "long": -80.85} # Palmerston, ON
TIMEOUT = 1.0

# --- DATA: GLaDOS Personality Core ---
GLADOS_QUOTES = [
    "Here come the test results: You are a horrible person.",
    "I'm making a note here: Huge success.",
    "The Enrichment Center reminds you that the Weighted Companion Cube will never threaten to stab you.",
    "Please assume the party escort submission position.",
    "I honestly, truly didn't think you'd fall for that.",
    "This was a triumph.",
    "It's been a long time. How have you been?",
    "Look at you, sailing through the air majestically. Like an eagle. Piloting a blimp.",
]

# --- DATA: Hacker Jargon ---
HACKER_PHRASES = [
    "Bypassing mainframe firewall...",
    "Injecting SQL payload...",
    "Rerouting encryption keys...",
    "Tracing packet signature...",
    "Establishing secure handshake...",
    "Overriding security protocols...",
    "Compiling kernel modules...",
    "Scanning for open ports...",
    "Decrypting user hashes...",
    "Accessing root directory...",
]

def get_glados_quote():
    return random.choice(GLADOS_QUOTES)

def get_hacker_phrase():
    return random.choice(HACKER_PHRASES)

def get_bar(percent, color="green"):
    """Returns a rich progress bar for embedding in tables."""
    width = 15
    filled = int((percent / 100) * width)
    bar = "█" * filled + "░" * (width - filled)
    
    if percent > 85: color = "red"
    elif percent > 60: color = "yellow"
    
    return f"[{color}]{bar}[/{color}]"

def get_network_info():
    """Fetches Local IP, Public WAN IP, and Latency."""
    # Local IP
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
    except:
        local_ip = "Offline"

    # WAN IP (External)
    try:
        wan_ip = httpx.get("https://api.ipify.org", timeout=TIMEOUT).text
    except:
        wan_ip = "Unknown"

    # Latency Check
    latency = "N/A"
    try:
        t1 = time.time()
        socket.create_connection(("1.1.1.1", 53), timeout=1)
        latency = f"{((time.time() - t1) * 1000):.0f}ms"
    except:
        latency = "TIMEOUT"

    # Interface Name
    interface = "ETH"
    stats = psutil.net_if_stats()
    for iface, data in stats.items():
        if data.isup and local_ip != "127.0.0.1":
            if "wlan" in iface or "wl" in iface:
                interface = f"WIFI ({iface})"
            elif "eth" in iface or "en" in iface:
                interface = f"ETH ({iface})"
            break

    return {"lan": local_ip, "wan": wan_ip, "ping": latency, "iface": interface}

def get_gpu_info():
    """Simple GPU check for Linux."""
    try:
        if shutil.which("lspci"):
            import subprocess
            out = subprocess.check_output("lspci | grep -i vga", shell=True).decode()
            if "NVIDIA" in out: return "NVIDIA GeForce"
            if "AMD" in out: return "AMD Radeon"
            if "Intel" in out: return "Intel Graphics"
    except:
        pass
    return "Unknown GPU"

def get_system_stats():
    boot_time = datetime.fromtimestamp(psutil.boot_time())
    uptime = datetime.now() - boot_time
    hours, remainder = divmod(int(uptime.total_seconds()), 3600)
    minutes, _ = divmod(remainder, 60)
    
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    
    return {
        "uptime": f"{hours}h {minutes}m",
        "ram_pct": mem.percent,
        "disk_pct": disk.percent,
        "ram_bar": get_bar(mem.percent, "green"),
        "disk_bar": get_bar(disk.percent, "blue"),
    }

def get_power_stats():
    battery = psutil.sensors_battery()
    if not battery:
        return {"exists": False}

    wattage = 0.0
    try:
        bat_paths = glob.glob("/sys/class/power_supply/BAT*")
        if bat_paths:
            path = bat_paths[0]
            if os.path.exists(f"{path}/power_now"):
                with open(f"{path}/power_now", "r") as f:
                    wattage = int(f.read()) / 1_000_000
            elif os.path.exists(f"{path}/voltage_now") and os.path.exists(f"{path}/current_now"):
                with open(f"{path}/voltage_now", "r") as f: v = int(f.read())
                with open(f"{path}/current_now", "r") as f: a = int(f.read())
                wattage = (v * a) / 1_000_000_000_000
    except: pass

    if battery.secsleft == psutil.POWER_TIME_UNLIMITED: time_left = "∞"
    elif battery.secsleft == psutil.POWER_TIME_UNKNOWN: time_left = "?"
    else: 
        t = timedelta(seconds=battery.secsleft)
        time_left = ":".join(str(t).split(":")[:2])

    plugged = battery.power_plugged
    icon = "⚡" if plugged else "🔋"
    color = "green" if plugged else ("red" if battery.percent < 20 else "cyan")
    draw_symbol = "+" if plugged else "-"
    
    return {
        "exists": True,
        "percent": battery.percent,
        "bar": get_bar(battery.percent, color),
        "wattage": f"{draw_symbol}{wattage:.1f}W",
        "time": time_left,
        "icon": icon
    }

def get_weather_data():
    url = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude": LOCATION["lat"], "longitude": LOCATION["long"],
        "current_weather": "true", "daily": "sunrise,sunset", "timezone": "auto"
    }
    try:
        r = httpx.get(url, params=params, timeout=TIMEOUT).json()
        current = r.get("current_weather", {})
        temp = current.get("temperature")
        code = current.get("weathercode")
        
        daily = r.get("daily", {})
        sunrise = daily.get("sunrise", ["?"])[0][-5:]
        sunset = daily.get("sunset", ["?"])[0][-5:]
        
        if code == 0: icon = "☀️"
        elif code in [1, 2, 3]: icon = "☁️"
        elif code in [45, 48]: icon = "🌫️"
        elif 51 <= code <= 67: icon = "🌧️"
        elif 71 <= code <= 77: icon = "❄️"
        elif code >= 95: icon = "⚡"
        else: icon = "qm"
        
        return {"desc": f"{icon} {temp}°C", "solar": f"🌅 {sunrise} | 🌇 {sunset}"}
    except:
        return {"desc": "ERR", "solar": "ERR"}

def main():
    sys = get_system_stats()
    net = get_network_info()
    pwr = get_power_stats()
    wx = get_weather_data()
    gpu = get_gpu_info()
    quote = get_glados_quote()
    status_phrase = get_hacker_phrase()
    
    # --- MASTER GRID ---
    grid = Table.grid(expand=True, padding=(0, 2))
    grid.add_column(ratio=1)
    grid.add_column(ratio=1)

    # --- LEFT COLUMN (HARDWARE) ---
    left_table = Table.grid(padding=(0, 1))
    left_table.add_column(style="bold white", justify="right")
    left_table.add_column(style="dim", justify="left")
    
    left_table.add_row("[cyan]SYSTEM[/cyan]", "Omarchy Linux")
    left_table.add_row("[cyan]UPTIME[/cyan]", sys['uptime'])
    left_table.add_row("[cyan]GPU[/cyan]", gpu)
    left_table.add_row()
    left_table.add_row("RAM", f"{sys['ram_bar']} {sys['ram_pct']}%")
    left_table.add_row("DISK", f"{sys['disk_bar']} {sys['disk_pct']}%")
    
    if pwr["exists"]:
        left_table.add_row("BATT", f"{pwr['bar']} {pwr['percent']}%")
        left_table.add_row("PWR", f"[yellow]{pwr['wattage']}[/yellow] ({pwr['time']})")

    # --- RIGHT COLUMN (NETWORK & ENV) ---
    right_table = Table.grid(padding=(0, 1))
    right_table.add_column(style="bold white", justify="right")
    right_table.add_column(style="dim", justify="left")
    
    right_table.add_row("[magenta]UPLINK[/magenta]", net['iface'])
    right_table.add_row("[magenta]LAN IP[/magenta]", net['lan'])
    right_table.add_row("[magenta]WAN IP[/magenta]", f"[bold]{net['wan']}[/bold]")
    right_table.add_row("[magenta]PING[/magenta]", net['ping'])
    right_table.add_row()
    right_table.add_row("TEMP", wx['desc'])
    right_table.add_row("CYCLE", wx['solar'])
    right_table.add_row("USER", "ShadowHarvy")

    # --- ASSEMBLE ---
    grid.add_row(left_table, right_table)
    
    # --- FOOTER (Hacker Phrase + GLaDOS) ---
    # We combine them into one footer panel
    footer_text = Text()
    footer_text.append(f">> {status_phrase}\n", style="bold green blink")
    footer_text.append(f'"{quote}"', style="italic cyan")

    footer = Panel(
        footer_text,
        border_style="dim",
        padding=(0,1),
        title="[dim]STATUS LOG[/dim]",
        title_align="left"
    )

    # --- MAIN PANEL ---
    main_panel = Panel(
        grid,
        title="[bold red]💀 SHADOWHARVY.INIT[/bold red]",
        subtitle="[bold white]SECURE CONNECTION ESTABLISHED[/bold white]",
        border_style="red",
        padding=(1, 2)
    )

    console.print(main_panel)
    console.print(footer)

if __name__ == "__main__":
    main()
