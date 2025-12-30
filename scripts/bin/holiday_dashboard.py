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
import time
import psutil
from datetime import datetime
import holidays
import httpx
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.box import SIMPLE

console = Console()

# --- Configuration ---
LOCATION = {"lat": 43.83, "long": -80.85} # Palmerston, ON
TIMEOUT = 1.5

def get_system_stats():
    """Fetches local system vitals."""
    # Uptime
    boot_time = datetime.fromtimestamp(psutil.boot_time())
    uptime = datetime.now() - boot_time
    hours, remainder = divmod(int(uptime.total_seconds()), 3600)
    minutes, _ = divmod(remainder, 60)
    uptime_str = f"{hours}h {minutes}m"

    # Memory & Disk
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    
    # Local IP
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
    except:
        local_ip = "127.0.0.1"

    return {
        "uptime": uptime_str,
        "ram": f"{mem.percent}%",
        "disk": f"{disk.percent}%",
        "ip": local_ip
    }

def get_weather_data():
    """Fetches Weather + Sunrise/Sunset."""
    url = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude": LOCATION["lat"],
        "longitude": LOCATION["long"],
        "current_weather": "true",
        "daily": "sunrise,sunset",
        "timezone": "auto"
    }
    
    try:
        response = httpx.get(url, params=params, timeout=TIMEOUT)
        response.raise_for_status()
        data = response.json()
        
        # Current Weather
        current = data.get("current_weather", {})
        temp = current.get("temperature")
        code = current.get("weathercode")
        
        # Solar
        daily = data.get("daily", {})
        sunrise = daily.get("sunrise", ["?"])[0][-5:] # Extract HH:MM
        sunset = daily.get("sunset", ["?"])[0][-5:]
        
        # Icons
        condition, icon = "Unknown", "qm"
        if code == 0: condition, icon = "Clear", "☀️"
        elif code in [1, 2, 3]: condition, icon = "Cloudy", "☁️"
        elif code in [45, 48]: condition, icon = "Fog", "🌫️"
        elif 51 <= code <= 67: condition, icon = "Rain", "🌧️"
        elif 71 <= code <= 77: condition, icon = "Snow", "❄️"
        elif code >= 95: condition, icon = "Storm", "⚡"
        
        return {
            "desc": f"{icon} {temp}°C",
            "solar": f"🌅 {sunrise}  🌇 {sunset}"
        }
    except:
        return {"desc": "[dim]N/A[/dim]", "solar": "[dim]N/A[/dim]"}

def get_holiday_info():
    """Finds next holiday and calculates countdown."""
    now = datetime.now()
    on_holidays = holidays.Canada(subdiv='ON', years=[now.year, now.year + 1])
    
    upcoming = []
    for date, name in on_holidays.items():
        h_date = datetime(date.year, date.month, date.day)
        if h_date > now:
            upcoming.append((h_date, name))
            
    if not upcoming:
        return "None", "N/A"
        
    upcoming.sort(key=lambda x: x[0])
    target_date, name = upcoming[0]
    
    remaining = target_date - now
    if remaining.days > 1:
        time_str = f"{remaining.days} days"
    elif remaining.days == 1:
        time_str = "1 day"
    else:
        time_str = f"{int(remaining.seconds/3600)} hours"
        
    return name, time_str

def main():
    sys_stats = get_system_stats()
    weather_data = get_weather_data()
    holiday_name, holiday_time = get_holiday_info()
    
    # Create the layout grid
    # padding=(0, 3) creates the column gap
    grid = Table.grid(padding=(0, 2))
    
    # Define columns
    grid.add_column(style="bold white", justify="right")
    grid.add_column(style="dim", justify="left")
    
    # --- SECTION 1: SYSTEM ---
    grid.add_row("System:", f"{sys_stats['ip']}  |  Uptime: {sys_stats['uptime']}")
    grid.add_row("Resources:", f"RAM: [green]{sys_stats['ram']}[/green]  |  Disk: [green]{sys_stats['disk']}[/green]")
    
    # --- SECTION 2: ENVIRONMENT ---
    grid.add_row() # Spacer
    grid.add_row("Weather:", f"{weather_data['desc']}")
    grid.add_row("Sun Cycle:", f"{weather_data['solar']}")
    
    # --- SECTION 3: TIMELINE ---
    grid.add_row() # Spacer
    grid.add_row("Next Event:", f"[magenta]{holiday_name}[/magenta]")
    grid.add_row("Countdown:", f"[cyan]{holiday_time}[/cyan]")

    # Build the Card
    panel = Panel(
        grid,
        title="[bold red]💀 SHADOWHARVY SYSTEM[/bold red]",
        subtitle="[dim]Omarchy Linux[/dim]",
        subtitle_align="right",
        border_style="red",
        expand=False,
        padding=(0, 2)
    )

    console.print(panel)

if __name__ == "__main__":
    main()
