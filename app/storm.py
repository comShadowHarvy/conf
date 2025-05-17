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
NUM_CLOUDS_FG = 4 # Foreground clouds
NUM_CLOUDS_BG = 3 # Background clouds
CLOUD_CHAR = '☁'
CLOUD_MIN_WIDTH = 5
CLOUD_MAX_WIDTH = 12
BASE_CLOUD_SPEED_FG = 0.3
CLOUD_WIND_FACTOR_FG = 0.4
BASE_CLOUD_SPEED_BG_FACTOR = 0.6 # Background clouds are slower relative to FG
CLOUD_WIND_FACTOR_BG = 0.2   # Background clouds less affected by wind

# --- Lightning ---
LIGHTNING_PROBABILITY = 0.03
LIGHTNING_BOLT_CHAR = '#'
RUMBLE_TEXTS = ["RUMBLE...", "CRACK...", "BOOOM...", "rumble..."]
RUMBLE_DURATION_MIN = 12
RUMBLE_DURATION_MAX = 30
LIGHTNING_FLICKER_DURATION = 3 # Bolt visibility
LIGHTNING_COMPLEXITY_PROBABILITY = 0.5
LIGHTNING_MAX_BRANCHES = 4
LIGHTNING_BRANCH_LENGTH_FACTOR = 0.6
LIGHTNING_FLASH_DURATION = 1 # Frames for screen flash

# --- Animation ---
ANIMATION_DELAY = 0.09

# --- ANSI Escape Codes & Colors ---
HIDE_CURSOR = "\033[?25l"
SHOW_CURSOR = "\033[?25h"
CLEAR_SCREEN = "\033[2J"
MOVE_CURSOR_HOME = "\033[H"
COLOR_RESET = "\033[0m"
COLOR_RAIN = "\033[34m"       # Blue
COLOR_CLOUD_FG = "\033[90m"   # Dark Grey / Bright Black for Foreground
COLOR_CLOUD_BG = "\033[37m"   # White (acts as lighter grey) for Background
COLOR_LIGHTNING = "\033[93m"  # Yellow
COLOR_SPLASH = "\033[36m"     # Cyan
COLOR_RUMBLE_TEXT = "\033[37m" # White
COLOR_SCREEN_FLASH = "\033[97m" # Bright White for flash

# --- Global State ---
screen_buffer = []
raindrops = []
clouds_fg = []
clouds_bg = []
active_splashes = []

lightning_flicker_countdown = 0
lightning_bolt_paths = []
lightning_rumble_frames = 0
current_rumble_text = ""
screen_flash_active_frames = 0 # For screen-wide flash effect

current_wind_drift = 0.0
current_rain_char = '|'
target_num_raindrops = MIN_RAINDROPS
storm_cycle_angle = 0.0

RUMBLE_LINE_INDEX = HEIGHT - 1
SPLASH_LINE_INDEX = HEIGHT - 2
STORM_AREA_HEIGHT = HEIGHT - 2

# --- Helper Functions ---
def get_rain_char_for_wind(wind_val):
    if abs(wind_val) < 0.5: return '|'
    elif wind_val > 0: return '/'
    else: return '\\'

def set_char_in_buffer(x, y, char, color=None):
    if 0 <= y < HEIGHT and 0 <= x < WIDTH:
        screen_buffer[y][x] = (char, color)

def initialize_global_structures():
    global screen_buffer, RUMBLE_LINE_INDEX, SPLASH_LINE_INDEX, STORM_AREA_HEIGHT
    global raindrops, clouds_fg, clouds_bg, active_splashes
    
    RUMBLE_LINE_INDEX = HEIGHT - 1
    SPLASH_LINE_INDEX = HEIGHT - 2
    STORM_AREA_HEIGHT = HEIGHT - 2

    screen_buffer = [[(' ', None) for _ in range(WIDTH)] for _ in range(HEIGHT)]
    
    raindrops = []
    clouds_fg = []
    clouds_bg = []
    active_splashes = []

    # Initialize Foreground Clouds
    for i in range(NUM_CLOUDS_FG):
        cloud_width = random.randint(CLOUD_MIN_WIDTH, CLOUD_MAX_WIDTH)
        clouds_fg.append({
            'x': float(random.randint(-cloud_width, WIDTH - 1)),
            'y': random.randint(STORM_AREA_HEIGHT // 6, STORM_AREA_HEIGHT // 3), # Lower
            'representation': CLOUD_CHAR * cloud_width,
            'width': cloud_width, 'id': f"fg_{i}"
        })
    # Initialize Background Clouds
    for i in range(NUM_CLOUDS_BG):
        cloud_width = random.randint(CLOUD_MIN_WIDTH -1, CLOUD_MAX_WIDTH -2) # Slightly smaller
        clouds_bg.append({
            'x': float(random.randint(-cloud_width, WIDTH - 1)),
            'y': random.randint(0, STORM_AREA_HEIGHT // 5), # Higher
            'representation': CLOUD_CHAR * cloud_width,
            'width': cloud_width, 'id': f"bg_{i}"
        })

def update_storm_parameters():
    global storm_cycle_angle, current_wind_drift, current_rain_char, target_num_raindrops

    storm_cycle_angle = (storm_cycle_angle + STORM_CYCLE_SPEED) % (2 * math.pi)
    intensity_modulation = (math.sin(storm_cycle_angle) + 1) / 2

    base_drift = MAX_WIND_DRIFT_BASE * intensity_modulation
    gust = base_drift * random.uniform(-STORM_GUST_FACTOR, STORM_GUST_FACTOR)
    current_wind_drift = base_drift + gust
    current_rain_char = get_rain_char_for_wind(current_wind_drift)

    target_num_raindrops = int(MIN_RAINDROPS + (MAX_RAINDROPS - MIN_RAINDROPS) * intensity_modulation)

    while len(raindrops) < target_num_raindrops:
        raindrops.append({
            'x': float(random.randint(0, WIDTH - 1)),
            'y': random.randint(0, STORM_AREA_HEIGHT - 1),
            'char': current_rain_char
        })
    while len(raindrops) > target_num_raindrops and raindrops:
        raindrops.pop(random.randrange(len(raindrops)))

def update_rain():
    global active_splashes
    for drop in raindrops:
        drop['y'] += 1
        drop['x'] += current_wind_drift
        drop['char'] = current_rain_char

        if drop['y'] >= SPLASH_LINE_INDEX:
            splash_x = int(round(drop['x']))
            if 0 <= splash_x < WIDTH:
                active_splashes.append({'x': splash_x, 'y': SPLASH_LINE_INDEX, 'life': SPLASH_DURATION_FRAMES})
            reset_drop_position(drop)
        elif not (-1 < drop['x'] < WIDTH + 1):
            reset_drop_position(drop)

def reset_drop_position(drop):
    if abs(current_wind_drift) > RAIN_SIDE_ORIGIN_THRESHOLD and random.random() < 0.7:
        drop['y'] = random.randint(0, STORM_AREA_HEIGHT -1)
        if current_wind_drift > 0:
            drop['x'] = float(random.randint(-int(abs(current_wind_drift)) -3, -1))
        else:
            drop['x'] = float(random.randint(WIDTH, WIDTH + int(abs(current_wind_drift)) + 2))
    else:
        drop['y'] = 0
        drop['x'] = float(random.randint(0, WIDTH - 1))

def update_splashes():
    global active_splashes
    new_splashes = []
    for splash in active_splashes:
        splash['life'] -= 1
        if splash['life'] > 0:
            new_splashes.append(splash)
    active_splashes = new_splashes

def update_clouds_layer(cloud_list, base_speed, wind_factor, min_y, max_y_divisor):
    """Helper to update a layer of clouds."""
    for cloud in cloud_list:
        cloud_speed_modifier = current_wind_drift * wind_factor
        cloud['x'] += (base_speed * (1 if current_wind_drift >=0 else -1) + cloud_speed_modifier)
        
        cloud_int_x = int(round(cloud['x']))
        if cloud_int_x >= WIDTH:
            cloud['x'] = float(-cloud['width'])
            cloud['y'] = random.randint(min_y, STORM_AREA_HEIGHT // max_y_divisor)
        elif cloud_int_x + cloud['width'] < 0 :
            cloud['x'] = float(WIDTH -1)
            cloud['y'] = random.randint(min_y, STORM_AREA_HEIGHT // max_y_divisor)

def update_all_clouds():
    update_clouds_layer(clouds_fg, BASE_CLOUD_SPEED_FG, CLOUD_WIND_FACTOR_FG, STORM_AREA_HEIGHT // 6, 3)
    update_clouds_layer(clouds_bg, BASE_CLOUD_SPEED_FG * BASE_CLOUD_SPEED_BG_FACTOR, CLOUD_WIND_FACTOR_BG, 0, 5)


def generate_bolt_path(x_start, y_start, y_end, max_deviation=1):
    path = []
    current_x = x_start
    for y_pos in range(y_start, y_end + 1):
        path.append((current_x, y_pos))
        if y_pos < y_end:
            deviation = random.randint(-max_deviation, max_deviation)
            if random.random() < 0.3:
                 deviation = random.choice([-2, -1, 0, 1, 2]) * (max_deviation > 0)
            current_x += deviation
            current_x = max(0, min(WIDTH - 1, current_x))
    return path

def update_lightning():
    global lightning_flicker_countdown, lightning_bolt_paths, lightning_rumble_frames, current_rumble_text, screen_flash_active_frames

    if screen_flash_active_frames > 0:
        screen_flash_active_frames -=1

    if lightning_flicker_countdown > 0:
        lightning_flicker_countdown -= 1
        if lightning_flicker_countdown == 0:
            lightning_bolt_paths = []

    if lightning_rumble_frames > 0:
        lightning_rumble_frames -= 1

    if random.random() < LIGHTNING_PROBABILITY and lightning_rumble_frames == 0 and lightning_flicker_countdown == 0:
        lightning_flicker_countdown = LIGHTNING_FLICKER_DURATION
        lightning_rumble_frames = random.randint(RUMBLE_DURATION_MIN, RUMBLE_DURATION_MAX)
        current_rumble_text = random.choice(RUMBLE_TEXTS)
        screen_flash_active_frames = LIGHTNING_FLASH_DURATION
        lightning_bolt_paths = []

        is_complex = random.random() < LIGHTNING_COMPLEXITY_PROBABILITY
        
        # Determine bolt start y based on foreground clouds if available
        potential_cloud_sources = [c for c in clouds_fg if c['x'] < WIDTH and c['x'] + c['width'] > 0] # Visible FG clouds
        if potential_cloud_sources:
            source_cloud = random.choice(potential_cloud_sources)
            bolt_x_start = random.randint(int(source_cloud['x']), int(source_cloud['x'] + source_cloud['width'] -1))
            bolt_x_start = max(0, min(WIDTH -1, bolt_x_start)) # clamp
            bolt_y_start = source_cloud['y'] + 1 # Start just below the cloud
        else: # Fallback if no FG clouds visible
            bolt_x_start = random.randint(WIDTH // 4, 3 * WIDTH // 4)
            bolt_y_start = random.randint(0, STORM_AREA_HEIGHT // 3)

        bolt_y_start = min(bolt_y_start, STORM_AREA_HEIGHT -2) # Ensure start_y is not too low
        bolt_y_end = random.randint(max(bolt_y_start + 2, STORM_AREA_HEIGHT // 2), STORM_AREA_HEIGHT - 1)
        
        if bolt_y_end <= bolt_y_start: # Ensure bolt has length
            bolt_y_end = bolt_y_start + 2
            bolt_y_end = min(bolt_y_end, STORM_AREA_HEIGHT -1)

        main_bolt_path = generate_bolt_path(bolt_x_start, bolt_y_start, bolt_y_end, max_deviation=1)
        if main_bolt_path: # Ensure path was generated
            lightning_bolt_paths.append(main_bolt_path)

            if is_complex and len(main_bolt_path) >= 3:
                num_branches = random.randint(1, LIGHTNING_MAX_BRANCHES)
                for _ in range(num_branches):
                    branch_start_index = random.randint(1, len(main_bolt_path) - 2)
                    branch_x_s, branch_y_s = main_bolt_path[branch_start_index]
                    branch_y_e = branch_y_s + int((bolt_y_end - branch_y_s) * LIGHTNING_BRANCH_LENGTH_FACTOR * random.uniform(0.5, 1.0))
                    branch_y_e = min(branch_y_e, STORM_AREA_HEIGHT - 1)
                    if branch_y_e > branch_y_s:
                        branch_path = generate_bolt_path(branch_x_s, branch_y_s, branch_y_e, max_deviation=2)
                        lightning_bolt_paths.append(branch_path)

def draw_scene():
    global screen_buffer
    # Determine overall color override for screen flash
    flash_override_color = COLOR_SCREEN_FLASH if screen_flash_active_frames > 0 else None

    # Clear buffer: fill with space and no color (or flash color for spaces if flash active)
    base_char, base_color = (' ', flash_override_color if flash_override_color else None)
    screen_buffer = [[(base_char, base_color) for _ in range(WIDTH)] for _ in range(HEIGHT)]

    # Draw Background Clouds
    for cloud in clouds_bg:
        cloud_draw_x = int(round(cloud['x']))
        for i, char_c in enumerate(cloud['representation']):
            set_char_in_buffer(cloud_draw_x + i, cloud['y'], char_c, flash_override_color or COLOR_CLOUD_BG)
    
    # Draw Foreground Clouds
    for cloud in clouds_fg:
        cloud_draw_x = int(round(cloud['x']))
        for i, char_c in enumerate(cloud['representation']):
            set_char_in_buffer(cloud_draw_x + i, cloud['y'], char_c, flash_override_color or COLOR_CLOUD_FG)

    # Draw rain
    for drop in raindrops:
        set_char_in_buffer(int(round(drop['x'])), drop['y'], drop['char'], flash_override_color or COLOR_RAIN)

    # Draw splashes
    for splash in active_splashes:
        set_char_in_buffer(splash['x'], splash['y'], SPLASH_CHAR, flash_override_color or COLOR_SPLASH)
    
    # Draw lightning (should appear on top of flash or be the primary color during flash)
    if lightning_flicker_countdown > 0 and lightning_bolt_paths:
        for bolt_path in lightning_bolt_paths:
            for bx, by in bolt_path:
                # Lightning is always its own color, even during flash, or uses flash color if brighter
                set_char_in_buffer(bx, by, LIGHTNING_BOLT_CHAR, flash_override_color or COLOR_LIGHTNING)

    # Draw rumble text
    if lightning_rumble_frames > 0:
        text_len = len(current_rumble_text)
        start_pos = (WIDTH - text_len) // 2
        for i, char_r in enumerate(current_rumble_text):
            set_char_in_buffer(start_pos + i, RUMBLE_LINE_INDEX, char_r, flash_override_color or COLOR_RUMBLE_TEXT)


def render_screen():
    output_parts = [MOVE_CURSOR_HOME]
    current_active_color = None # Tracks the color currently active in the terminal output stream

    for y_idx in range(HEIGHT):
        for x_idx in range(WIDTH):
            char_to_print, new_color_code = screen_buffer[y_idx][x_idx]

            if new_color_code != current_active_color:
                if new_color_code:  # Transition to a new specific color
                    output_parts.append(new_color_code)
                else:  # Transition to default terminal color (new_color_code is None)
                    output_parts.append(COLOR_RESET) # Reset any previously active color
                current_active_color = new_color_code
            
            output_parts.append(char_to_print)
        
        # After processing all characters in a line, if a color is still active, reset it
        # This ensures the next line or subsequent terminal output starts fresh unless specified.
        if current_active_color is not None:
            output_parts.append(COLOR_RESET)
            current_active_color = None
        
        if y_idx < HEIGHT - 1: # Avoid extra newline at the very end of the screen
            output_parts.append("\n")

    sys.stdout.write("".join(output_parts))
    sys.stdout.flush()

def main_animation_loop():
    initialize_global_structures()
    try:
        sys.stdout.write(HIDE_CURSOR)
        sys.stdout.write(CLEAR_SCREEN)
        while True:
            update_storm_parameters()
            update_all_clouds()
            update_rain()
            update_splashes()
            update_lightning() # This can trigger screen_flash_active_frames

            draw_scene() # Considers screen_flash_active_frames
            render_screen()

            time.sleep(ANIMATION_DELAY)
    except KeyboardInterrupt:
        pass
    finally:
        sys.stdout.write(COLOR_RESET) # Final reset
        sys.stdout.write(SHOW_CURSOR)
        sys.stdout.write(MOVE_CURSOR_HOME)
        sys.stdout.flush()
        print("\nEnhanced storm animation has concluded. Stay safe out there!")

if __name__ == "__main__":
    try:
        cols, rows = os.get_terminal_size()
        WIDTH = cols
        HEIGHT = rows
        print(f"Terminal size: {WIDTH}x{HEIGHT}. Starting enhanced dynamic storm v2...")
        time.sleep(1.5)
    except OSError:
        print(f"Could not detect terminal size. Using default {WIDTH}x{HEIGHT}.")
        time.sleep(1.5)
    
    main_animation_loop()
