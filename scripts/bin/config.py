# config.py
import random
from typing import Callable
# --- Terminal & Display ---
WIDTH = 120  # Default width if terminal size can't be detected
HEIGHT = 30  # Default height if terminal size can't be detected
ANIMATION_DELAY = 0.07  # Seconds between frames (e.g., 0.05 is 20 FPS)

# --- ANSI Escape Codes (for color and terminal control) ---
COLOR_RESET = "\033[0m"
HIDE_CURSOR = "\033[?25l"
SHOW_CURSOR = "\033[?25h"
CLEAR_SCREEN = "\033[2J"
MOVE_CURSOR_HOME = "\033[H"

# Colors (ANSI 8-bit color codes)
# You can find color charts online, e.g., https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html#256-colors
COLOR_RAIN = "\033[38;5;244m"  # A medium grey
COLOR_SPLASH = "\033[38;5;250m"  # A lighter grey
COLOR_CLOUD_FG = "\033[38;5;240m" # Dark grey for foreground clouds
COLOR_CLOUD_BG = "\033[38;5;236m" # Very dark grey for background clouds
COLOR_LIGHTNING = "\033[38;5;231m" # Bright white/yellowish
COLOR_SCREEN_FLASH = "\033[48;5;254m" # Background color for screen flash (light grey)
COLOR_RUMBLE_TEXT = "\033[38;5;246m"
COLOR_PUDDLE = "\033[38;5;238m"
COLOR_PUDDLE_DISTURBANCE = "\033[38;5;244m"
COLOR_GROUND_STRIKE = "\033[38;5;228m" # Bright yellow for ground impact
COLOR_GROUND = "\033[38;5;234m" # Very dark grey for the ground line

# --- Rain ---
MIN_RAINDROPS = 20
MAX_RAINDROPS = 150
RAIN_SIDE_ORIGIN_THRESHOLD = 0.4 # Wind strength needed for rain to come from the side
SPLASH_CHAR = "."
SPLASH_DURATION_FRAMES = 2 # How many frames a splash character lasts
# Dynamically select rain character based on wind
RAIN_CHARS_BY_WIND = {
    -2.0: ':',
    -1.0: '/',
    0.0: '|',
    1.0: '\\',
    2.0: ':'
}
def get_rain_char_for_wind(wind_drift: float) -> str:
    """Selects the best rain character based on the wind's direction and speed."""
    if wind_drift < -1.5: return RAIN_CHARS_BY_WIND[-2.0]
    if wind_drift < -0.5: return RAIN_CHARS_BY_WIND[-1.0]
    if wind_drift > 1.5: return RAIN_CHARS_BY_WIND[2.0]
    if wind_drift > 0.5: return RAIN_CHARS_BY_WIND[1.0]
    return RAIN_CHARS_BY_WIND[0.0]

# --- Clouds ---
NUM_CLOUDS_FG = 5
NUM_CLOUDS_BG = 4
CLOUD_CHAR = "░" # Shaded block character
CLOUD_MIN_WIDTH = 15
CLOUD_MAX_WIDTH = 35
BASE_CLOUD_SPEED_FG = 0.2  # Base speed per frame
BASE_CLOUD_SPEED_BG_FACTOR = 0.6 # BG clouds move at a fraction of FG speed
CLOUD_WIND_FACTOR_FG = 0.4 # How much wind affects FG cloud speed
CLOUD_WIND_FACTOR_BG = 0.2 # How much wind affects BG cloud speed
# Functions to generate different cloud shapes
def shape_flat(width): return CLOUD_CHAR * width
def shape_fluffy(width):
    w = max(1, width)
    return f"{' ' * int(w*0.1)}{CLOUD_CHAR * int(w*0.8)}{' ' * int(w*0.1)}"
def shape_wispy(width):
    return "".join(random.choice([CLOUD_CHAR, ' ']) for _ in range(width))
CLOUD_SHAPE_PATTERNS: list[Callable[[int], str]] = [shape_flat, shape_fluffy, shape_wispy]

# --- Puddles ---
GROUND_CHAR = "_"
PUDDLE_CHARS = ['_', '`', '·', '…', '∴', 'because'] # Characters for increasing puddle intensity
PUDDLE_DISTURBANCE_CHAR = 'o'
PUDDLE_DISTURBANCE_DURATION = 4 # Frames
INITIAL_PUDDLE_INTENSITY = 1
PUDDLE_MAX_INTENSITY = len(PUDDLE_CHARS) -1
PUDDLE_FORMATION_PER_SPLASH = 0.5 # How much each raindrop adds to intensity
PUDDLE_EVAPORATION_RATE = 0.01 # How much intensity is lost per frame
PUDDLE_SPREAD_THRESHOLD = 3.0 # Intensity required for a puddle to become wider than 1 char
PUDDLE_MAX_WIDTH_PER_POINT = 20
PUDDLE_MERGE_DISTANCE = 1 # Puddles this close or closer will merge

# --- Lightning & Thunder ---
LIGHTNING_PROBABILITY = 0.008 # Chance of a strike per frame
LIGHTNING_FLASH_DURATION = 2 # Frames the whole screen flashes
LIGHTNING_FLICKER_DURATION = 4 # Frames the bolt itself is visible
LIGHTNING_PRIMARY_BOLT_CHAR = "│"
LIGHTNING_BOLT_CHARS = ['|', '/', '\\']
LIGHTNING_COMPLEXITY_PROBABILITY = 0.7 # Chance a strike has branches
LIGHTNING_MAX_BRANCHES = 3
LIGHTNING_BRANCH_LENGTH_FACTOR = 0.7 # Branches are this fraction of the main bolt's remaining length
GROUND_STRIKE_EFFECT_CHAR = "X"
GROUND_STRIKE_EFFECT_DURATION = 3 # Frames
RUMBLE_DURATION_MIN = 20 # Minimum frames for thunder text to show
RUMBLE_DURATION_MAX = 50 # Maximum frames for thunder text to show
RUMBLE_TEXTS = ["rrumble...", "RUMBLE", "...brrrrmmm...", "CRACK...", "..."]

# --- Storm Cycle ---
STORM_CYCLE_SPEED = 0.003 # How fast the storm builds and subsides
MAX_WIND_DRIFT_BASE = 1.0 # Max wind speed at peak storm intensity
STORM_GUST_FACTOR = 0.5 # How much wind can vary frame-to-frame (0 to 1)
