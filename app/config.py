# config.py
"""
Configuration settings for the Terminal Storm Animation.
"""
import math
import random

# --- Terminal Dimensions (Can be overridden by os.get_terminal_size()) ---
WIDTH = 80  # Default terminal width
HEIGHT = 24 # Default terminal height

# --- Storm Cycle & Intensity ---
STORM_CYCLE_SPEED = 0.01        # How fast the storm intensity changes
STORM_GUST_FACTOR = 0.3         # How much wind speed can vary randomly
MAX_WIND_DRIFT_BASE = 3.0       # Max horizontal movement of rain/clouds due to wind at peak intensity
MIN_RAINDROPS = 10              # Minimum number of raindrops
MAX_RAINDROPS = 150             # Maximum number of raindrops at peak intensity
RAIN_SIDE_ORIGIN_THRESHOLD = 1.5 # Wind drift magnitude above which rain can start from screen sides

# --- Rain & Splash ---
SPLASH_CHAR = '.'
SPLASH_DURATION_FRAMES = 2      # How many frames a splash effect lasts

# --- Puddles ---
PUDDLE_CHARS = ['.', '-', '~', '≈'] # Characters representing increasing puddle intensity
PUDDLE_MAX_INTENSITY = len(PUDDLE_CHARS) - 1
PUDDLE_FORMATION_PER_SPLASH = 0.5 # How much each splash contributes to puddle intensity
PUDDLE_EVAPORATION_RATE = 0.02    # Base rate of evaporation per frame
PUDDLE_SPREAD_THRESHOLD = 2.0     # Intensity a puddle needs to start spreading wider
PUDDLE_MAX_WIDTH_PER_POINT = 5    # Max width a single puddle origin can grow to (before merging)
PUDDLE_MERGE_DISTANCE = 2         # Max distance between edges of puddles to be considered for merging
PUDDLE_DISTURBANCE_DURATION = 3  # Number of frames a puddle disturbance lasts
INITIAL_PUDDLE_INTENSITY = 2      # Default initial intensity for new puddles

# --- Clouds ---
NUM_CLOUDS_FG = 4
NUM_CLOUDS_BG = 3
CLOUD_CHAR = '☁'                # Base character for simple clouds
CLOUD_MIN_WIDTH = 5
CLOUD_MAX_WIDTH = 12
BASE_CLOUD_SPEED_FG = 0.3
CLOUD_WIND_FACTOR_FG = 0.4      # How much foreground clouds are affected by wind
BASE_CLOUD_SPEED_BG_FACTOR = 0.6 # Background clouds move slower
CLOUD_WIND_FACTOR_BG = 0.2      # Background clouds less affected by wind
# More varied cloud shapes (simple implementation)
CLOUD_SHAPE_PATTERNS = [
    lambda w: CLOUD_CHAR * w, # Original solid cloud
    lambda w: " ".join(CLOUD_CHAR * random.randint(1,3) for _ in range(w//2)).center(w), # Broken cloud
    lambda w: ("-" + CLOUD_CHAR * (w-2) + "-") if w > 2 else CLOUD_CHAR * w, # Streaky cloud
    lambda w: ("(" + CLOUD_CHAR * (w-2) + ")") if w > 2 else CLOUD_CHAR * w, # Contained cloud
]


# --- Lightning ---
LIGHTNING_PROBABILITY = 0.03
LIGHTNING_BOLT_CHARS = ['#', '*', '+', '⚡'] # Characters for lightning, can be chosen randomly
LIGHTNING_PRIMARY_BOLT_CHAR = '#' # Usually the main bolt char
RUMBLE_TEXTS = ["RUMBLE...", "CRACK...", "BOOOM...", "rumble..."]
RUMBLE_DURATION_MIN = 12
RUMBLE_DURATION_MAX = 30
LIGHTNING_FLICKER_DURATION = 3  # How many frames the bolt stays visible
LIGHTNING_COMPLEXITY_PROBABILITY = 0.5 # Chance of having branches
LIGHTNING_MAX_BRANCHES = 4
LIGHTNING_BRANCH_LENGTH_FACTOR = 0.6
LIGHTNING_FLASH_DURATION = 1    # How many frames the screen flash lasts
GROUND_STRIKE_EFFECT_CHAR = '⁂'
GROUND_STRIKE_EFFECT_DURATION = 2

# --- Animation ---
ANIMATION_DELAY = 0.09

# --- ANSI Escape Codes & Colors ---
HIDE_CURSOR = "\033[?25l"
SHOW_CURSOR = "\033[?25h"
CLEAR_SCREEN = "\033[2J"
MOVE_CURSOR_HOME = "\033[H"
COLOR_RESET = "\033[0m"
COLOR_RAIN = "\033[34m"         # Blue
COLOR_CLOUD_FG = "\033[90m"     # Dark Grey / Bright Black
COLOR_CLOUD_BG = "\033[37m"     # White / Light Grey
COLOR_LIGHTNING = "\033[93m"    # Bright Yellow
COLOR_SPLASH = "\033[36m"       # Cyan
COLOR_RUMBLE_TEXT = "\033[37m"  # White / Light Grey
COLOR_SCREEN_FLASH = "\033[97m" # Bright White
COLOR_PUDDLE = "\033[34;1m"     # Bold Blue (or \033[38;2;0;0;139m for a specific dark blue if supported)
COLOR_GROUND_STRIKE = "\033[93;1m" # Bold Bright Yellow

# --- Helper Functions (that are config-dependent) ---
def get_rain_char_for_wind(wind_val):
    """Determines the rain character based on wind direction."""
    if abs(wind_val) < 0.5: return '|'
    elif wind_val > 0: return '/'
    else: return '\\'

