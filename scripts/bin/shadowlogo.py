#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "rich",
#     "pyfiglet",
#     "psutil",
#     "distro",
# ]
# ///

import sys
import shutil
import time
import platform
import psutil
import distro
import os
from datetime import datetime
from rich.console import Console
from rich.layout import Layout
from rich.panel import Panel
from rich.align import Align
from rich.text import Text
from rich.table import Table
from rich import box
from pyfiglet import Figlet

# Initialize Console
console = Console()

def get_terminal_width():
    """Get the real-time width of the terminal."""
    width, _ = shutil.get_terminal_size()
    return width

def get_header():
    """Generates the top status bar with dynamic date."""
    grid = Table.grid(expand=True)
    grid.add_column(justify="left", ratio=1)
    grid.add_column(justify="center", ratio=1)
    grid.add_column(justify="right", ratio=1)
    
    date_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    term_width = get_terminal_width()
    
    grid.add_row(
        "[bold cyan]USER: SHADOWHARVY[/bold cyan]",
        f"[bold red]/// SECURE_SHELL: {term_width}px ///[/bold red]",
        f"[bold green]{date_str}[/bold green]"
    )
    return Panel(grid, style="white on black", box=box.HEAVY)

def get_logo():
    """
    Generates the ASCII art dynamically sized to the terminal.
    """
    width = get_terminal_width()
    art_width = max(80, width - 60) 
    
    f = Figlet(font='ansi_shadow', width=art_width)
    raw_art = f.renderText('SHADOWHARVY')
    
    style = "bold cyan" if width > 150 else "bold blue"

    return Panel(
        Align.center(Text(raw_art, style=style), vertical="middle"),
        border_style="bright_blue",
        title="[bold white] IDENTITY VERIFIED [/bold white]",
        subtitle=f"[dim]Render Width: {art_width}[/dim]"
    )

def get_real_stats():
    """Fetches REAL system metrics using psutil."""
    try:
        os_name = f"{distro.name(pretty=True)}"
    except:
        os_name = "Linux"
    kernel = platform.release()

    try:
        boot_time = datetime.fromtimestamp(psutil.boot_time())
        uptime = datetime.now() - boot_time
        uptime_str = str(uptime).split('.')[0] 
    except:
        uptime_str = "Unknown"

    cpu_pct = psutil.cpu_percent(interval=0.1)
    mem = psutil.virtual_memory()
    
    cpu_color = "green" if cpu_pct < 50 else "red"
    mem_color = "green" if mem.percent < 70 else "yellow"

    table = Table(show_header=False, expand=True, box=None, padding=(0, 1))
    table.add_column("Key", style="bold green")
    table.add_column("Value", style="dim white")
    
    table.add_row("OS:", f"{os_name}")
    table.add_row("KERNEL:", kernel)
    table.add_row("UPTIME:", uptime_str)
    table.add_row("CPU LOAD:", f"[{cpu_color}]{cpu_pct}%[/{cpu_color}]")
    table.add_row("RAM USE:", f"[{mem_color}]{mem.percent}% ({round(mem.used/1024**3, 1)}GB)[/{mem_color}]")
    table.add_row("SHELL:", os.environ.get('SHELL', 'Unknown'))
    
    return Panel(
        Align.center(table, vertical="middle"),
        title="[ LIVE_TELEMETRY ]",
        border_style="green"
    )

def get_fake_hex_dump():
    hex_data = """
00000000  7f 45 4c 46 02 01 01 00  00 00 00 00 00 00 00 00  |.ELF............|
00000010  02 00 3e 00 01 00 00 00  c0 2d 40 00 00 00 00 00  |..>......-@.....|
00000020  40 00 00 00 00 00 00 00  f8 6a 00 00 00 00 00 00  |@........j......|
00000030  00 00 00 00 40 00 38 00  09 00 40 00 1c 00 1b 00  |....@.8...@.....|
    """
    return Panel(
        Align.center(Text(hex_data.strip(), style="dim white"), vertical="middle"),
        title="[ MEMORY_DUMP ]",
        border_style="white"
    )

def make_layout():
    width = get_terminal_width()
    layout = Layout(name="root")
    
    layout.split(
        Layout(name="header", size=3),
        Layout(name="body", ratio=1),
        Layout(name="footer", size=1)
    )

    if width > 160:
        layout["body"].split_row(
            Layout(name="left", ratio=1),
            Layout(name="center", ratio=3),
            Layout(name="right", ratio=1),
        )
    else:
        layout["body"].split_column(
            Layout(name="center", ratio=2),
            Layout(name="bottom_stats", ratio=1),
        )
        layout["bottom_stats"].split_row(
            Layout(name="left"),
            Layout(name="right"),
        )
    
    return layout

def main():
    layout = make_layout()
    width = get_terminal_width()
    layout["header"].update(get_header())
    
    if width > 160:
        layout["body"]["center"].update(get_logo())
        layout["body"]["left"].update(get_real_stats())
        layout["body"]["right"].update(get_fake_hex_dump())
    else:
        layout["body"]["center"].update(get_logo())
        layout["body"]["bottom_stats"]["left"].update(get_real_stats())
        layout["body"]["bottom_stats"]["right"].update(get_fake_hex_dump())

    layout["footer"].update(Align.center(Text("INITIALIZING ZSH ENVIRONMENT...", style="blink italic grey50")))
    console.print(layout)

if __name__ == "__main__":
    main()
