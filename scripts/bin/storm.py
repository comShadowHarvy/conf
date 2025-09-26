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
MIN_RAINDROPS = 10
MAX_RAINDROPS = 150
RAIN_SIDE_ORIGIN_THRESHOLD = 1.5

# --- Rain ---
SPLASH_CHAR = '.'
SPLASH_DURATION_FRAMES = 2

# --- Puddles ---
PUDDLE_CHARS = ['.', '-', '~', '≈']
PUDDLE_MAX_INTENSITY = len(PUDDLE_CHARS) - 1
PUDDLE_FORMATION_PER_SPLASH = 0.5
PUDDLE_EVAPORATION_RATE = 0.02
PUDDLE_SPREAD_THRESHOLD = 2.0
PUDDLE_MAX_WIDTH_PER_POINT = 5
PUDDLE_MERGE_DISTANCE = 3

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
LIGHTNING_PROBABILITY = 0.015  # Slightly reduced for less chaos
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
COLOR_PUDDLE = "\033[34;1m"

# --- Global State ---
screen_buffer = []
raindrops = []
clouds_fg = []
clouds_bg = []
active_splashes = []
puddles = {}  # {x_coord: {'intensity', 'width', 'base_x'}}

lightning_flicker_countdown = 0
lightning_bolt_paths = []
lightning_rumble_frames = 0
current_rumble_text = ""
screen_flash_active_frames = 0

current_wind_drift = 0.0
current_rain_char = '|'
target_num_raindrops = MIN_RAINDROPS
storm_cycle_angle = 0.0
current_storm_intensity = 0.0

# Derived height variables
RUMBLE_LINE_INDEX = HEIGHT - 1
SPLASH_LINE_INDEX = HEIGHT - 2
STORM_AREA_HEIGHT = HEIGHT - 2


def get_rain_char_for_wind(wind_val):
    """Selects a rain character based on wind speed for a more natural look."""
    if wind_val > 1.5: return '/'
    if wind_val < -1.5: return '\\'
    if wind_val > 0.5: return '/'
    if wind_val < -0.5: return '\\'
    return '|'

def set_char_in_buffer(x, y, char, color=None):
    if 0 <= y < HEIGHT and 0 <= x < WIDTH:
        screen_buffer[y][x] = (char, color)

def initialize_global_structures():
    global screen_buffer, raindrops, clouds_fg, clouds_bg, active_splashes, puddles
    screen_buffer = [[(' ', None) for _ in range(WIDTH)] for _ in range(HEIGHT)]
    raindrops = []
    clouds_fg = []
    clouds_bg = []
    active_splashes = []
    puddles = {}
    for i in range(NUM_CLOUDS_FG):
        cw = random.randint(CLOUD_MIN_WIDTH, CLOUD_MAX_WIDTH)
        clouds_fg.append({
            'x': float(random.randint(-cw, WIDTH - 1)),
            'y': random.randint(STORM_AREA_HEIGHT // 6, STORM_AREA_HEIGHT // 3),
            'repr': CLOUD_CHAR * cw,
            'width': cw
        })
    for i in range(NUM_CLOUDS_BG):
        cw = random.randint(CLOUD_MIN_WIDTH - 1, CLOUD_MAX_WIDTH - 2)
        clouds_bg.append({
            'x': float(random.randint(-cw, WIDTH - 1)),
            'y': random.randint(0, STORM_AREA_HEIGHT // 5),
            'repr': CLOUD_CHAR * cw,
            'width': cw
        })

def update_storm_parameters():
    global storm_cycle_angle, current_wind_drift, current_rain_char, target_num_raindrops, current_storm_intensity
    storm_cycle_angle = (storm_cycle_angle + STORM_CYCLE_SPEED) % (2 * math.pi)
    current_storm_intensity = (math.sin(storm_cycle_angle) + 1) / 2
    base_drift = MAX_WIND_DRIFT_BASE * current_storm_intensity
    gust = base_drift * random.uniform(-STORM_GUST_FACTOR, STORM_GUST_FACTOR)
    current_wind_drift = base_drift + gust
    current_rain_char = get_rain_char_for_wind(current_wind_drift)
    target_num_raindrops = int(MIN_RAINDROPS + (MAX_RAINDROPS - MIN_RAINDROPS) * current_storm_intensity)
    while len(raindrops) < target_num_raindrops:
        raindrops.append({
            'x': float(random.randint(0, WIDTH - 1)),
            'y': random.randint(0, STORM_AREA_HEIGHT - 1),
            'char': current_rain_char
        })
    while len(raindrops) > target_num_raindrops and raindrops:
        raindrops.pop(random.randrange(len(raindrops)))

def reset_drop_position(drop):
    if abs(current_wind_drift) > RAIN_SIDE_ORIGIN_THRESHOLD and random.random() < 0.7:
        drop['y'] = random.randint(0, STORM_AREA_HEIGHT - 1)
        if current_wind_drift > 0:
            drop['x'] = float(random.randint(-int(abs(current_wind_drift)) - 3, -1))
        else:
            drop['x'] = float(random.randint(WIDTH, WIDTH + int(abs(current_wind_drift)) + 2))
    else:
        drop['y'] = 0
        drop['x'] = float(random.randint(0, WIDTH - 1))

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
                if splash_x not in puddles:
                    puddles[splash_x] = {'intensity': 0.0, 'width': 1, 'base_x': splash_x}
                puddles[splash_x]['intensity'] = min(PUDDLE_MAX_INTENSITY + 0.9, puddles[splash_x]['intensity'] + PUDDLE_FORMATION_PER_SPLASH)
            reset_drop_position(drop)
        elif not (-1 < drop['x'] < WIDTH + 1):
            reset_drop_position(drop)
    active_splashes = [s for s in active_splashes if s['life'] - 1 > 0]
    for s in active_splashes:
        s['life'] -= 1

def update_puddles():
    global puddles
    new_puddles = {}
    for x_coord, puddle in puddles.items():
        evap_rate = PUDDLE_EVAPORATION_RATE * (1.5 - current_storm_intensity)
        puddle['intensity'] -= evap_rate
        if puddle['intensity'] > 0:
            if puddle['intensity'] > PUDDLE_SPREAD_THRESHOLD:
                puddle['width'] = min(PUDDLE_MAX_WIDTH_PER_POINT, 1 + int(puddle['intensity'] / PUDDLE_SPREAD_THRESHOLD))
            else:
                puddle['width'] = 1
            new_puddles[x_coord] = puddle
    puddles = new_puddles

def update_clouds_layer(cloud_list, base_speed, wind_factor, min_y_pos, max_y_divisor):
    for cloud in cloud_list:
        cloud_speed_modifier = current_wind_drift * wind_factor
        cloud['x'] += (base_speed * (1 if current_wind_drift >= 0 else -1) + cloud_speed_modifier)
        cloud_int_x = int(round(cloud['x']))
        if cloud_int_x >= WIDTH:
            cloud['x'] = float(-cloud['width'])
            cloud['y'] = random.randint(min_y_pos, STORM_AREA_HEIGHT // max(1, max_y_divisor))
        elif cloud_int_x + cloud['width'] < 0:
            cloud['x'] = float(WIDTH - 1)
            cloud['y'] = random.randint(min_y_pos, STORM_AREA_HEIGHT // max(1, max_y_divisor))

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
            current_x += deviation
            current_x = max(0, min(WIDTH - 1, current_x))
    return path

def update_lightning():
    global lightning_flicker_countdown, lightning_bolt_paths, lightning_rumble_frames, current_rumble_text, screen_flash_active_frames
    if screen_flash_active_frames > 0: screen_flash_active_frames -= 1
    if lightning_flicker_countdown > 0:
        lightning_flicker_countdown -= 1
        if lightning_flicker_countdown == 0: lightning_bolt_paths = []
    if lightning_rumble_frames > 0: lightning_rumble_frames -= 1
    if random.random() < LIGHTNING_PROBABILITY and lightning_rumble_frames == 0 and lightning_flicker_countdown == 0:
        lightning_flicker_countdown = LIGHTNING_FLICKER_DURATION
        lightning_rumble_frames = random.randint(RUMBLE_DURATION_MIN, RUMBLE_DURATION_MAX)
        current_rumble_text = random.choice(RUMBLE_TEXTS)
        screen_flash_active_frames = LIGHTNING_FLASH_DURATION
        lightning_bolt_paths = []
        is_complex = random.random() < LIGHTNING_COMPLEXITY_PROBABILITY
        potential_cloud_sources = [c for c in clouds_fg if c['x'] < WIDTH and c['x'] + c['width'] > 0]
        if potential_cloud_sources:
            source_cloud = random.choice(potential_cloud_sources)
            bolt_x_start = random.randint(int(source_cloud['x']), int(source_cloud['x'] + source_cloud['width'] - 1))
            bolt_x_start = max(0, min(WIDTH - 1, bolt_x_start))
            bolt_y_start = source_cloud['y'] + 1
        else:
            bolt_x_start = random.randint(WIDTH // 4, 3 * WIDTH // 4)
            bolt_y_start = random.randint(0, STORM_AREA_HEIGHT // 3)

        # --- THIS IS THE FIXED SECTION ---
        y_end_min = bolt_y_start + 2
        y_end_max = STORM_AREA_HEIGHT - 1
        if y_end_min >= y_end_max:
            return  # Not enough space for a bolt, exit to prevent crash
        bolt_y_end = random.randint(y_end_min, y_end_max)
        # --- END OF FIX ---

        main_bolt_path = generate_bolt_path(bolt_x_start, bolt_y_start, bolt_y_end)
        if main_bolt_path:
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
    flash_color_override = "\033[47m" if screen_flash_active_frames > 0 else None
    base_char, base_color = (' ', flash_color_override)
    screen_buffer = [[(base_char, base_color) for _ in range(WIDTH)] for _ in range(HEIGHT)]
    for cloud_item in clouds_bg:
        cloud_draw_x = int(round(cloud_item['x']))
        for i, char_c in enumerate(cloud_item['repr']):
            set_char_in_buffer(cloud_draw_x + i, cloud_item['y'], char_c, flash_color_override or COLOR_CLOUD_BG)
    for cloud_item in clouds_fg:
        cloud_draw_x = int(round(cloud_item['x']))
        for i, char_c in enumerate(cloud_item['repr']):
            set_char_in_buffer(cloud_draw_x + i, cloud_item['y'], char_c, flash_color_override or COLOR_CLOUD_FG)
    for drop in raindrops:
        set_char_in_buffer(int(round(drop['x'])), int(round(drop['y'])), drop['char'], flash_color_override or COLOR_RAIN)
    if lightning_flicker_countdown > 0 and lightning_bolt_paths:
        for bolt_path in lightning_bolt_paths:
            for bx, by in bolt_path:
                set_char_in_buffer(bx, by, LIGHTNING_BOLT_CHAR, flash_color_override or COLOR_LIGHTNING)
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
    for splash in active_splashes:
        set_char_in_buffer(splash['x'], splash['y'], SPLASH_CHAR, flash_color_override or COLOR_SPLASH)
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
        if y_idx < HEIGHT - 1:
            output_parts.append("\n")
    sys.stdout.write("".join(output_parts))
    sys.stdout.flush()

def main_animation_loop():
    initialize_global_structures()
    try:
        sys.stdout.write(HIDE_CURSOR + CLEAR_SCREEN)
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
        sys.stdout.write(COLOR_RESET + SHOW_CURSOR)
        sys.stdout.flush()
        print("\nStorm animation has ended. Hope you enjoyed it!")

if __name__ == "__main__":
    try:
        cols, rows = os.get_terminal_size()
        WIDTH, HEIGHT = cols, rows
    except OSError:
        print(f"Could not get terminal size. Using default: {WIDTH}x{HEIGHT}")
    # Update derived constants
    RUMBLE_LINE_INDEX = HEIGHT - 1
    SPLASH_LINE_INDEX = HEIGHT - 2
    STORM_AREA_HEIGHT = HEIGHT - 2
    print(f"Terminal: {WIDTH}x{HEIGHT}. Starting Storm...")
    time.sleep(1.5)
    main_animation_loop()
