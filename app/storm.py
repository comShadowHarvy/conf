import random
import time
import sys
import os
import math

# --- Configuration ---
WIDTH = 80  # Terminal width
HEIGHT = 24  # Terminal height

# --- Storm Cycle & Intensity ---
STORM_CYCLE_SPEED = 0.01
STORM_GUST_FACTOR = 0.3
MAX_WIND_DRIFT_BASE = 3.0
MIN_RAINDROPS = 10 # Reduced min for lighter rain effect
MAX_RAINDROPS = 150
RAIN_SIDE_ORIGIN_THRESHOLD = 1.5

# --- Rain ---
SPLASH_CHAR = '.'
SPLASH_DURATION_FRAMES = 2

# --- Puddles ---
PUDDLE_CHARS = ['.', '-', '~', '≈'] # Index maps to intensity
PUDDLE_MAX_INTENSITY = len(PUDDLE_CHARS) -1
PUDDLE_FORMATION_PER_SPLASH = 0.5 # How much a splash contributes
PUDDLE_EVAPORATION_RATE = 0.02 # Per frame
PUDDLE_SPREAD_THRESHOLD = 2.0 # Intensity needed to spread width
PUDDLE_MAX_WIDTH_PER_POINT = 5 # Max width a single puddle origin can grow to
PUDDLE_MERGE_DISTANCE = 3 # If puddles are this close, they might merge (visual only for now)

# --- Clouds ---
NUM_CLOUDS_FG = 4
NUM_CLOUDS_BG = 3
CLOUD_CHAR = '☁'
CLOUD_MIN_WIDTH = 5
CLOUD_MAX_WIDTH = 12
BASE_CLOUD_SPEED_FG = 0.3
CLOUD_WIND_FACTOR_FG = 0.4
BASE_CLOUD_SPEED_BG_FACTOR = 0.6
CLOUD_WIND_FACTOR_BG = 0.2

# --- Lightning ---
LIGHTNING_PROBABILITY = 0.03
LIGHTNING_BOLT_CHAR = '#'
RUMBLE_TEXTS = ["RUMBLE...", "CRACK...", "BOOOM...", "rumble..."]
RUMBLE_DURATION_MIN = 12
RUMBLE_DURATION_MAX = 30
LIGHTNING_FLICKER_DURATION = 3
LIGHTNING_COMPLEXITY_PROBABILITY = 0.5
LIGHTNING_MAX_BRANCHES = 4
LIGHTNING_BRANCH_LENGTH_FACTOR = 0.6
LIGHTNING_FLASH_DURATION = 1

# --- Animation ---
ANIMATION_DELAY = 0.09

# --- ANSI Escape Codes & Colors ---
HIDE_CURSOR = "\033[?25l"
SHOW_CURSOR = "\033[?25h"
CLEAR_SCREEN = "\033[2J"
MOVE_CURSOR_HOME = "\033[H"
COLOR_RESET = "\033[0m"
COLOR_RAIN = "\033[34m"
COLOR_CLOUD_FG = "\033[90m"
COLOR_CLOUD_BG = "\033[37m"
COLOR_LIGHTNING = "\033[93m"
COLOR_SPLASH = "\033[36m"
COLOR_RUMBLE_TEXT = "\033[37m"
COLOR_SCREEN_FLASH = "\033[97m"
COLOR_PUDDLE = "\033[34;1m" # Bold Blue, or a darker blue if supported: \033[38;2;0;0;139m

# --- Global State ---
screen_buffer = []
raindrops = []
clouds_fg = []
clouds_bg = []
active_splashes = []
puddles = {} # Using a dict for puddles: {x_coord: {'intensity': float, 'width': int, 'base_x': int}}

lightning_flicker_countdown = 0
lightning_bolt_paths = []
lightning_rumble_frames = 0
current_rumble_text = ""
screen_flash_active_frames = 0

current_wind_drift = 0.0
current_rain_char = '|'
target_num_raindrops = MIN_RAINDROPS
storm_cycle_angle = 0.0
current_storm_intensity = 0.0 # Normalized 0-1

# Derived height variables
RUMBLE_LINE_INDEX = HEIGHT - 1
SPLASH_LINE_INDEX = HEIGHT - 2 # Puddles form here
STORM_AREA_HEIGHT = HEIGHT - 2 # Max Y for rain, clouds etc. is STORM_AREA_HEIGHT - 1

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
    global raindrops, clouds_fg, clouds_bg, active_splashes, puddles
    
    RUMBLE_LINE_INDEX = HEIGHT - 1
    SPLASH_LINE_INDEX = HEIGHT - 2
    STORM_AREA_HEIGHT = HEIGHT - 2

    screen_buffer = [[(' ', None) for _ in range(WIDTH)] for _ in range(HEIGHT)]
    
    raindrops = []
    clouds_fg = []
    clouds_bg = []
    active_splashes = []
    puddles = {}

    for i in range(NUM_CLOUDS_FG):
        cw = random.randint(CLOUD_MIN_WIDTH, CLOUD_MAX_WIDTH)
        clouds_fg.append({'x': float(random.randint(-cw, WIDTH-1)), 
                          'y': random.randint(STORM_AREA_HEIGHT//6, STORM_AREA_HEIGHT//3), 
                          'repr': CLOUD_CHAR*cw, 
                          'width': cw, 'id': f"fg_{i}"})
    for i in range(NUM_CLOUDS_BG):
        cw = random.randint(CLOUD_MIN_WIDTH-1, CLOUD_MAX_WIDTH-2)
        clouds_bg.append({'x': float(random.randint(-cw, WIDTH-1)), 
                          'y': random.randint(0, STORM_AREA_HEIGHT//5), 
                          'repr': CLOUD_CHAR*cw, 
                          'width': cw, 'id': f"bg_{i}"})

def update_storm_parameters():
    global storm_cycle_angle, current_wind_drift, current_rain_char, target_num_raindrops
    global current_storm_intensity

    storm_cycle_angle = (storm_cycle_angle + STORM_CYCLE_SPEED) % (2 * math.pi)
    current_storm_intensity = (math.sin(storm_cycle_angle) + 1) / 2 # Normalized 0-1

    base_drift = MAX_WIND_DRIFT_BASE * current_storm_intensity
    gust = base_drift * random.uniform(-STORM_GUST_FACTOR, STORM_GUST_FACTOR)
    current_wind_drift = base_drift + gust
    current_rain_char = get_rain_char_for_wind(current_wind_drift)

    target_num_raindrops = int(MIN_RAINDROPS + (MAX_RAINDROPS - MIN_RAINDROPS) * current_storm_intensity)

    # Adjust actual raindrops count towards target
    while len(raindrops) < target_num_raindrops:
        raindrops.append({'x': float(random.randint(0,WIDTH-1)), 
                          'y': random.randint(0,STORM_AREA_HEIGHT-1), 
                          'char': current_rain_char})
    while len(raindrops) > target_num_raindrops and raindrops:
        raindrops.pop(random.randrange(len(raindrops)))


def update_rain_and_splashes():
    global active_splashes, puddles
    for drop in raindrops:
        drop['y'] += 1
        drop['x'] += current_wind_drift
        drop['char'] = current_rain_char

        if drop['y'] >= SPLASH_LINE_INDEX:
            splash_x = int(round(drop['x']))
            if 0 <= splash_x < WIDTH:
                active_splashes.append({'x': splash_x, 'y': SPLASH_LINE_INDEX, 'life': SPLASH_DURATION_FRAMES})
                # Contribute to puddle
                if splash_x not in puddles:
                    puddles[splash_x] = {'intensity': 0.0, 'width': 1, 'base_x': splash_x}
                puddles[splash_x]['intensity'] = min(PUDDLE_MAX_INTENSITY + 0.9, puddles[splash_x]['intensity'] + PUDDLE_FORMATION_PER_SPLASH)
            reset_drop_position(drop)
        elif not (-1 < drop['x'] < WIDTH + 1): # Check if drop went off-screen horizontally
            reset_drop_position(drop)

    # Update active splash effects, reducing their lifespan
    new_splashes = []
    for splash in active_splashes:
        splash['life'] -= 1
        if splash['life'] > 0: 
            new_splashes.append(splash)
    active_splashes = new_splashes

def reset_drop_position(drop):
    """Resets a single raindrop, considering wind for side origin."""
    if abs(current_wind_drift) > RAIN_SIDE_ORIGIN_THRESHOLD and random.random() < 0.7: # Chance to originate from side in strong wind
        drop['y'] = random.randint(0, STORM_AREA_HEIGHT -1) # Originate anywhere vertically
        if current_wind_drift > 0: # Wind L to R, rain from Left
            drop['x'] = float(random.randint(-int(abs(current_wind_drift)) -3, -1))
        else: # Wind R to L, rain from Right
            drop['x'] = float(random.randint(WIDTH, WIDTH + int(abs(current_wind_drift)) + 2))
    else: # Standard top origin
        drop['y'] = 0
        drop['x'] = float(random.randint(0, WIDTH - 1))

def update_puddles():
    global puddles
    new_puddles = {}
    sorted_puddle_keys = sorted(puddles.keys())

    for x_coord in sorted_puddle_keys:
        puddle = puddles[x_coord]
        # Evaporation based on global intensity (less rain = faster evaporation)
        evap_rate = PUDDLE_EVAPORATION_RATE * (1.5 - current_storm_intensity) # Less intense storm = faster evaporation
        puddle['intensity'] -= evap_rate
        
        if puddle['intensity'] > 0:
            # Spread width based on intensity
            if puddle['intensity'] > PUDDLE_SPREAD_THRESHOLD:
                puddle['width'] = min(PUDDLE_MAX_WIDTH_PER_POINT, 1 + int(puddle['intensity'] / PUDDLE_SPREAD_THRESHOLD))
            else:
                puddle['width'] = 1 # Min width is 1 if puddle exists
            new_puddles[x_coord] = puddle
    puddles = new_puddles


def update_clouds_layer(cloud_list, base_speed, wind_factor, min_y_pos, max_y_divisor):
    """Helper to update a layer of clouds."""
    for cloud in cloud_list:
        cloud_speed_modifier = current_wind_drift * wind_factor
        # Clouds move with base speed (direction depends on wind) and are pushed by wind
        cloud['x'] += (base_speed * (1 if current_wind_drift >=0 else -1) + cloud_speed_modifier)
        
        cloud_int_x = int(round(cloud['x']))
        # Wrap around logic
        if cloud_int_x >= WIDTH: # Moved off right edge
            cloud['x'] = float(-cloud['width']) # Reset to left edge
            cloud['y'] = random.randint(min_y_pos, STORM_AREA_HEIGHT // max_y_divisor) # Reposition vertically
        elif cloud_int_x + cloud['width'] < 0 : # Moved off left edge
            cloud['x'] = float(WIDTH -1) # Reset to right edge
            cloud['y'] = random.randint(min_y_pos, STORM_AREA_HEIGHT // max_y_divisor) # Reposition vertically

def update_all_clouds():
    update_clouds_layer(clouds_fg, BASE_CLOUD_SPEED_FG, CLOUD_WIND_FACTOR_FG, STORM_AREA_HEIGHT//6, 3)
    update_clouds_layer(clouds_bg, BASE_CLOUD_SPEED_FG*BASE_CLOUD_SPEED_BG_FACTOR, CLOUD_WIND_FACTOR_BG, 0, 5)

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
            current_x = max(0, min(WIDTH - 1, current_x)) # Keep in bounds
    return path

def update_lightning():
    global lightning_flicker_countdown, lightning_bolt_paths, lightning_rumble_frames, current_rumble_text, screen_flash_active_frames
    if screen_flash_active_frames > 0: screen_flash_active_frames -=1
    if lightning_flicker_countdown > 0:
        lightning_flicker_countdown -= 1
        if lightning_flicker_countdown == 0: lightning_bolt_paths = [] # Clear bolt after flicker
    if lightning_rumble_frames > 0: lightning_rumble_frames -= 1

    # New lightning strike
    if random.random() < LIGHTNING_PROBABILITY and lightning_rumble_frames == 0 and lightning_flicker_countdown == 0:
        lightning_flicker_countdown = LIGHTNING_FLICKER_DURATION
        lightning_rumble_frames = random.randint(RUMBLE_DURATION_MIN, RUMBLE_DURATION_MAX)
        current_rumble_text = random.choice(RUMBLE_TEXTS)
        screen_flash_active_frames = LIGHTNING_FLASH_DURATION
        lightning_bolt_paths = []
        is_complex = random.random() < LIGHTNING_COMPLEXITY_PROBABILITY
        
        # Determine bolt start based on foreground clouds if available
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
        bolt_y_end = random.randint(max(bolt_y_start + 2, STORM_AREA_HEIGHT // 2), STORM_AREA_HEIGHT - 1) # End above splash line
        
        # Corrected logic: Ensure bolt_y_end is greater than bolt_y_start
        if bolt_y_end <= bolt_y_start: 
            bolt_y_end = min(bolt_y_start + 2, STORM_AREA_HEIGHT - 1)


        main_bolt_path = generate_bolt_path(bolt_x_start, bolt_y_start, bolt_y_end)
        if main_bolt_path: # Ensure path was generated
            lightning_bolt_paths.append(main_bolt_path)

            if is_complex and len(main_bolt_path) >= 3: # Need at least 3 points for a branch
                num_branches = random.randint(1, LIGHTNING_MAX_BRANCHES)
                for _ in range(num_branches):
                    branch_start_index = random.randint(1, len(main_bolt_path) - 2) # Branch from middle segment
                    branch_x_s, branch_y_s = main_bolt_path[branch_start_index]
                    
                    branch_y_e = branch_y_s + int((bolt_y_end - branch_y_s) * LIGHTNING_BRANCH_LENGTH_FACTOR * random.uniform(0.5, 1.0))
                    branch_y_e = min(branch_y_e, STORM_AREA_HEIGHT - 1) # Ensure branch stays in bounds

                    if branch_y_e > branch_y_s: # Ensure branch goes downwards
                        branch_path = generate_bolt_path(branch_x_s, branch_y_s, branch_y_e, max_deviation=2) # Branches are more jagged
                        lightning_bolt_paths.append(branch_path)

def draw_scene():
    global screen_buffer
    flash_color_override = COLOR_SCREEN_FLASH if screen_flash_active_frames > 0 else None
    base_char, base_color = (' ', flash_color_override)
    screen_buffer = [[(base_char, base_color) for _ in range(WIDTH)] for _ in range(HEIGHT)]

    # Draw Background Clouds
    for cloud_item in clouds_bg:
        cloud_draw_x = int(round(cloud_item['x']))
        for i, char_c in enumerate(cloud_item['repr']): 
            set_char_in_buffer(cloud_draw_x + i, cloud_item['y'], char_c, flash_color_override or COLOR_CLOUD_BG)
    
    # Draw Foreground Clouds
    for cloud_item in clouds_fg:
        cloud_draw_x = int(round(cloud_item['x']))
        for i, char_c in enumerate(cloud_item['repr']): 
            set_char_in_buffer(cloud_draw_x + i, cloud_item['y'], char_c, flash_color_override or COLOR_CLOUD_FG)

    # Draw Rain
    for drop in raindrops:
        set_char_in_buffer(int(round(drop['x'])), drop['y'], drop['char'], flash_color_override or COLOR_RAIN)
    
    # Draw Lightning
    if lightning_flicker_countdown > 0 and lightning_bolt_paths:
        for bolt_path in lightning_bolt_paths:
            for bx, by in bolt_path: 
                set_char_in_buffer(bx, by, LIGHTNING_BOLT_CHAR, flash_color_override or COLOR_LIGHTNING)

    # Draw Puddles on SPLASH_LINE_INDEX
    drawn_puddle_coords = set() 
    for x_coord, puddle_data in puddles.items():
        puddle_char_idx = min(PUDDLE_MAX_INTENSITY, int(puddle_data['intensity']))
        char_to_draw = PUDDLE_CHARS[puddle_char_idx]
        half_width = puddle_data['width'] // 2
        for i in range(puddle_data['width']):
            px = puddle_data['base_x'] - half_width + i
            if 0 <= px < WIDTH and px not in drawn_puddle_coords:
                set_char_in_buffer(px, SPLASH_LINE_INDEX, char_to_draw, flash_color_override or COLOR_PUDDLE)
                drawn_puddle_coords.add(px)
    
    # Draw Splashes (on top of puddles if they overlap)
    for splash in active_splashes:
        set_char_in_buffer(splash['x'], splash['y'], SPLASH_CHAR, flash_color_override or COLOR_SPLASH)

    # Draw Rumble Text
    if lightning_rumble_frames > 0:
        text_len = len(current_rumble_text)
        start_pos = (WIDTH - text_len) // 2
        for i, char_r in enumerate(current_rumble_text): 
            set_char_in_buffer(start_pos + i, RUMBLE_LINE_INDEX, char_r, flash_color_override or COLOR_RUMBLE_TEXT)

def render_screen():
    output_parts = [MOVE_CURSOR_HOME]
    current_active_color = None 
    for y_idx in range(HEIGHT):
        for x_idx in range(WIDTH):
            char_to_print, new_color_code = screen_buffer[y_idx][x_idx]
            if new_color_code != current_active_color:
                output_parts.append(new_color_code or COLOR_RESET) 
                current_active_color = new_color_code
            output_parts.append(char_to_print)
        
        if current_active_color is not None: 
            output_parts.append(COLOR_RESET)
            current_active_color = None
        
        if y_idx < HEIGHT - 1: 
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
            update_rain_and_splashes()
            update_puddles()
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
        print("\nStorm with Puddles animation (No Fog) has ended. Hope you enjoyed it!")

if __name__ == "__main__":
    try:
        cols, rows = os.get_terminal_size()
        WIDTH = cols
        HEIGHT = rows
        
        RUMBLE_LINE_INDEX = HEIGHT - 1
        SPLASH_LINE_INDEX = HEIGHT - 2
        STORM_AREA_HEIGHT = HEIGHT - 2
        print(f"Terminal: {WIDTH}x{HEIGHT}. Starting Storm v3.2 (Puddles, No Fog - Fixed)...")
        time.sleep(1.5)
    except OSError:
        print(f"Default: {WIDTH}x{HEIGHT}. Starting Storm v3.2 (Puddles, No Fog - Fixed)...")
        time.sleep(1.5)
    
    main_animation_loop()
