import random
import time
import sys
import os
import math

# --- Configuration ---
WIDTH = 80  # Terminal width
HEIGHT = 24  # Terminal height
# Derived later: RUMBLE_LINE_INDEX, STORM_AREA_HEIGHT

# --- Storm Cycle & Intensity ---
STORM_CYCLE_SPEED = 0.01 # How fast the storm intensity changes
STORM_GUST_FACTOR = 0.3 # Random variation in wind strength (0 to 1)
MAX_WIND_DRIFT_BASE = 3.0 # Max base horizontal shift for rain/clouds due to wind
MIN_RAINDROPS = 15
MAX_RAINDROPS = 150 # Max raindrops for a downpour
RAIN_SIDE_ORIGIN_THRESHOLD = 1.5 # Wind drift magnitude to start rain from sides

# --- Rain ---
# RAIN_CHAR is dynamic
SPLASH_CHAR = '.'
SPLASH_DURATION_FRAMES = 2

# --- Clouds ---
NUM_CLOUDS = 5
CLOUD_CHAR = '☁'
CLOUD_MIN_WIDTH = 5
CLOUD_MAX_WIDTH = 12
BASE_CLOUD_SPEED = 0.3 # Base speed before wind
CLOUD_WIND_FACTOR = 0.4 # How much wind affects cloud speed

# --- Lightning ---
LIGHTNING_PROBABILITY = 0.03  # Chance of lightning per frame
LIGHTNING_BOLT_CHAR = '#'
RUMBLE_DURATION_MIN = 12 # frames
RUMBLE_DURATION_MAX = 30 # frames
LIGHTNING_FLICKER_DURATION = 3 # frames for the bolt to be visible
LIGHTNING_COMPLEXITY_PROBABILITY = 0.5 # Chance of a complex, branching bolt
LIGHTNING_MAX_BRANCHES = 4
LIGHTNING_BRANCH_LENGTH_FACTOR = 0.6 # Branches are shorter than main bolt

# --- Animation ---
ANIMATION_DELAY = 0.09  # Seconds between frames

# --- ANSI Escape Codes & Colors ---
HIDE_CURSOR = "\033[?25l"
SHOW_CURSOR = "\033[?25h"
CLEAR_SCREEN = "\033[2J"
MOVE_CURSOR_HOME = "\033[H"
COLOR_RESET = "\033[0m"
COLOR_RAIN = "\033[34m"       # Blue
COLOR_CLOUD = "\033[90m"      # Dark Grey / Bright Black
COLOR_LIGHTNING = "\033[93m"  # Yellow
COLOR_SPLASH = "\033[36m"     # Cyan
COLOR_RUMBLE_TEXT = "\033[37m" # White

# --- Global State ---
screen_buffer = [] # Initialized in main
raindrops = []
clouds = []
active_splashes = []

lightning_flicker_countdown = 0
lightning_bolt_paths = [] # Stores list of paths, where each path is [(x,y), ...]
lightning_rumble_frames = 0

# Dynamic storm parameters
current_wind_drift = 0.0
current_rain_char = '|'
target_num_raindrops = MIN_RAINDROPS
storm_cycle_angle = 0.0

# Derived height variables (set in main after potential resize)
RUMBLE_LINE_INDEX = HEIGHT - 1
SPLASH_LINE_INDEX = HEIGHT - 2
STORM_AREA_HEIGHT = HEIGHT - 2 # Max Y index for rain/lightning main elements is STORM_AREA_HEIGHT - 1

# --- Helper Functions ---
def get_rain_char_for_wind(wind_val):
    """Determines the rain character based on wind direction."""
    if abs(wind_val) < 0.5: return '|'
    elif wind_val > 0: return '/'
    else: return '\\'

def set_char_in_buffer(x, y, char, color=None):
    """Safely sets a character and its color in the screen buffer."""
    # Ensure y is within buffer, x can be slightly outside due to int conversion for drawing
    if 0 <= y < HEIGHT and 0 <= x < WIDTH:
        screen_buffer[y][x] = (char, color)

def initialize_global_structures():
    """Initializes or re-initializes structures dependent on WIDTH/HEIGHT."""
    global screen_buffer, RUMBLE_LINE_INDEX, SPLASH_LINE_INDEX, STORM_AREA_HEIGHT
    global raindrops, clouds, active_splashes # Clear these too for re-initialization
    
    RUMBLE_LINE_INDEX = HEIGHT - 1
    SPLASH_LINE_INDEX = HEIGHT - 2
    STORM_AREA_HEIGHT = HEIGHT - 2 # Visuals (rain, lightning) go up to STORM_AREA_HEIGHT - 1 (i.e., HEIGHT - 3)

    screen_buffer = [[(' ', None) for _ in range(WIDTH)] for _ in range(HEIGHT)]
    
    raindrops = []
    clouds = []
    active_splashes = []

    # Initialize clouds (raindrops are managed dynamically)
    for i in range(NUM_CLOUDS):
        cloud_width = random.randint(CLOUD_MIN_WIDTH, CLOUD_MAX_WIDTH)
        clouds.append({
            'x': float(random.randint(-cloud_width, WIDTH - 1)),
            'y': random.randint(0, STORM_AREA_HEIGHT // 4),
            'representation': CLOUD_CHAR * cloud_width,
            'width': cloud_width,
            'id': i
        })
    # Initial raindrops will be added by update_storm_parameters in the first loop

def update_storm_parameters():
    """Updates wind, rain density, etc., based on the storm cycle."""
    global storm_cycle_angle, current_wind_drift, current_rain_char, target_num_raindrops

    storm_cycle_angle += STORM_CYCLE_SPEED
    if storm_cycle_angle > 2 * math.pi:
        storm_cycle_angle -= 2 * math.pi

    # Intensity modulation: (sin + 1)/2 gives a 0 to 1 range
    intensity_modulation = (math.sin(storm_cycle_angle) + 1) / 2

    # Update Wind
    base_drift = MAX_WIND_DRIFT_BASE * intensity_modulation
    # Add gustiness: make wind fluctuate around the base drift
    gust = base_drift * random.uniform(-STORM_GUST_FACTOR, STORM_GUST_FACTOR)
    current_wind_drift = base_drift + gust
    current_rain_char = get_rain_char_for_wind(current_wind_drift)

    # Update Target Raindrops
    target_num_raindrops = int(MIN_RAINDROPS + (MAX_RAINDROPS - MIN_RAINDROPS) * intensity_modulation)

    # Adjust actual raindrops
    while len(raindrops) < target_num_raindrops:
        # Add new raindrop (logic for side origin is in update_rain when drops reset)
        raindrops.append({
            'x': float(random.randint(0, WIDTH - 1)),
            'y': random.randint(0, STORM_AREA_HEIGHT - 1),
            'char': current_rain_char
        })
    while len(raindrops) > target_num_raindrops and raindrops:
        raindrops.pop(random.randrange(len(raindrops))) # Remove random drop

def update_rain():
    """Updates raindrop positions and handles splashes."""
    global active_splashes
    for drop in raindrops:
        drop['y'] += 1
        drop['x'] += current_wind_drift
        drop['char'] = current_rain_char

        # Check for ground hit (splash line is SPLASH_LINE_INDEX)
        if drop['y'] >= SPLASH_LINE_INDEX:
            splash_x = int(round(drop['x']))
            if 0 <= splash_x < WIDTH:
                active_splashes.append({
                    'x': splash_x,
                    'y': SPLASH_LINE_INDEX,
                    'life': SPLASH_DURATION_FRAMES
                })
            # Reset drop
            reset_drop_position(drop)

        # Check for horizontal off-screen
        elif not (-1 < drop['x'] < WIDTH + 1): # Allow slight overshoot before reset
            reset_drop_position(drop)

def reset_drop_position(drop):
    """Resets a single raindrop, considering wind for side origin."""
    if abs(current_wind_drift) > RAIN_SIDE_ORIGIN_THRESHOLD and random.random() < 0.7: # 70% chance to originate from side in strong wind
        drop['y'] = random.randint(0, STORM_AREA_HEIGHT -1) # Originate anywhere vertically
        if current_wind_drift > 0: # Wind L to R, rain from Left
            drop['x'] = float(random.randint(-int(abs(current_wind_drift)) -3, -1))
        else: # Wind R to L, rain from Right
            drop['x'] = float(random.randint(WIDTH, WIDTH + int(abs(current_wind_drift)) + 2))
    else: # Standard top origin
        drop['y'] = 0
        drop['x'] = float(random.randint(0, WIDTH - 1))


def update_splashes():
    global active_splashes
    active_splashes = [s for s in active_splashes if s['life'] > 1 for s['life'] in [s['life']-1]]


def update_clouds():
    for cloud in clouds:
        cloud_speed_modifier = current_wind_drift * CLOUD_WIND_FACTOR
        cloud['x'] += (BASE_CLOUD_SPEED * (1 if current_wind_drift >=0 else -1) + cloud_speed_modifier) # Base speed directionality + wind
        
        cloud_int_x = int(round(cloud['x']))
        # Wrap around
        if cloud_int_x >= WIDTH:
            cloud['x'] = float(-cloud['width'])
            cloud['y'] = random.randint(0, STORM_AREA_HEIGHT // 4)
        elif cloud_int_x + cloud['width'] < 0 :
            cloud['x'] = float(WIDTH -1)
            cloud['y'] = random.randint(0, STORM_AREA_HEIGHT // 4)


def generate_bolt_path(x_start, y_start, y_end, max_deviation=1):
    """Generates a single path for a lightning bolt or branch."""
    path = []
    current_x = x_start
    for y_pos in range(y_start, y_end + 1):
        path.append((current_x, y_pos))
        if y_pos < y_end: # Don't change x for the very last segment point
            deviation = random.randint(-max_deviation, max_deviation)
            # More pronounced jaggedness by sometimes taking bigger steps
            if random.random() < 0.3: # 30% chance of a more significant jag
                 deviation = random.choice([-2, -1, 0, 1, 2]) * (max_deviation > 0) # only if max_dev > 0
            current_x += deviation
            current_x = max(0, min(WIDTH - 1, current_x))
    return path

def update_lightning():
    global lightning_flicker_countdown, lightning_bolt_paths, lightning_rumble_frames

    if lightning_flicker_countdown > 0:
        lightning_flicker_countdown -= 1
        if lightning_flicker_countdown == 0:
            lightning_bolt_paths = []

    if lightning_rumble_frames > 0:
        lightning_rumble_frames -= 1

    if random.random() < LIGHTNING_PROBABILITY and lightning_rumble_frames == 0 and lightning_flicker_countdown == 0:
        lightning_flicker_countdown = LIGHTNING_FLICKER_DURATION
        lightning_rumble_frames = random.randint(RUMBLE_DURATION_MIN, RUMBLE_DURATION_MAX)
        lightning_bolt_paths = []

        is_complex = random.random() < LIGHTNING_COMPLEXITY_PROBABILITY
        
        # Main Bolt
        bolt_x_start = random.randint(WIDTH // 4, 3 * WIDTH // 4)
        # Start near clouds or top third if no clouds
        bolt_y_start = random.randint(0, clouds[0]['y'] + 2 if clouds else STORM_AREA_HEIGHT // 3)
        bolt_y_end = random.randint(STORM_AREA_HEIGHT // 2, STORM_AREA_HEIGHT - 1) # End above splash line
        
        main_bolt_path = generate_bolt_path(bolt_x_start, bolt_y_start, bolt_y_end, max_deviation=1)
        lightning_bolt_paths.append(main_bolt_path)

        if is_complex and main_bolt_path:
            num_branches = random.randint(1, LIGHTNING_MAX_BRANCHES)
            for _ in range(num_branches):
                if len(main_bolt_path) < 3: continue # Not enough points to branch from

                # Pick a random point on the main bolt to branch from (not too close to ends)
                branch_start_index = random.randint(1, len(main_bolt_path) - 2)
                branch_x_start, branch_y_start = main_bolt_path[branch_start_index]

                branch_y_end = branch_y_start + int((bolt_y_end - branch_y_start) * LIGHTNING_BRANCH_LENGTH_FACTOR * random.uniform(0.5, 1.0))
                branch_y_end = min(branch_y_end, STORM_AREA_HEIGHT - 1) # Ensure branch stays in bounds

                if branch_y_end > branch_y_start: # Ensure branch goes downwards
                    # Branches deviate more
                    branch_path = generate_bolt_path(branch_x_start, branch_y_start, branch_y_end, max_deviation=2)
                    lightning_bolt_paths.append(branch_path)

def draw_scene():
    global screen_buffer
    screen_buffer = [[(' ', None) for _ in range(WIDTH)] for _ in range(HEIGHT)] # Clear buffer

    # Draw clouds
    for cloud in clouds:
        cloud_draw_x = int(round(cloud['x']))
        for i, char_c in enumerate(cloud['representation']):
            set_char_in_buffer(cloud_draw_x + i, cloud['y'], char_c, COLOR_CLOUD)

    # Draw rain
    for drop in raindrops:
        set_char_in_buffer(int(round(drop['x'])), drop['y'], drop['char'], COLOR_RAIN)

    # Draw splashes
    for splash in active_splashes:
        set_char_in_buffer(splash['x'], splash['y'], SPLASH_CHAR, COLOR_SPLASH)
    
    # Draw lightning
    if lightning_flicker_countdown > 0 and lightning_bolt_paths:
        for bolt_path in lightning_bolt_paths:
            for bx, by in bolt_path:
                set_char_in_buffer(bx, by, LIGHTNING_BOLT_CHAR, COLOR_LIGHTNING)

    # Draw rumble text
    if lightning_rumble_frames > 0:
        rumble_text = "RUMBLE..."
        text_len = len(rumble_text)
        start_pos = (WIDTH - text_len) // 2
        for i, char_r in enumerate(rumble_text):
            set_char_in_buffer(start_pos + i, RUMBLE_LINE_INDEX, char_r, COLOR_RUMBLE_TEXT)

def render_screen():
    output_parts = [MOVE_CURSOR_HOME]
    current_color = None
    for y in range(HEIGHT):
        for x in range(WIDTH):
            char, color_code = screen_buffer[y][x]
            if color_code != current_color:
                if color_code:
                    output_parts.append(color_code)
                else: # Reset if previous char had color and this one doesn't
                    output_parts.append(COLOR_RESET)
                current_color = color_code
            output_parts.append(char)
        if current_color: # Reset color at end of line
            output_parts.append(COLOR_RESET)
            current_color = None
        if y < HEIGHT - 1:
            output_parts.append("\n")
    sys.stdout.write("".join(output_parts))
    sys.stdout.flush()

def main_animation_loop():
    initialize_global_structures() # Initialize based on current WIDTH/HEIGHT
    try:
        sys.stdout.write(HIDE_CURSOR)
        sys.stdout.write(CLEAR_SCREEN)
        while True:
            update_storm_parameters() # Update wind, rain density
            update_clouds()
            update_rain()
            update_splashes()
            update_lightning()

            draw_scene()
            render_screen()

            time.sleep(ANIMATION_DELAY)
    except KeyboardInterrupt:
        pass
    finally:
        sys.stdout.write(COLOR_RESET)
        sys.stdout.write(SHOW_CURSOR)
        sys.stdout.write(MOVE_CURSOR_HOME)
        sys.stdout.flush()
        print("\nDynamic storm animation ended. Hope you enjoyed the show!")

if __name__ == "__main__":
    try:
        cols, rows = os.get_terminal_size()
        WIDTH = cols
        HEIGHT = rows
        print(f"Terminal size: {WIDTH}x{HEIGHT}. Starting dynamic storm...")
        time.sleep(1.5)
    except OSError:
        print(f"Could not detect terminal size. Using default {WIDTH}x{HEIGHT}.")
        time.sleep(1.5)
    
    main_animation_loop()
