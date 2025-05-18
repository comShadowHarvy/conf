

# storm_animation.py
import random
import time
import sys
import os
import math
import config # Import configuration

# --- Global State (derived from config or dynamic) ---
screen_buffer = []
raindrops = []      # Will hold Raindrop objects
clouds_fg = []      # Will hold Cloud objects
clouds_bg = []      # Will hold Cloud objects
active_splashes = [] # {'x', 'y', 'life'} for visual splash char
puddles = []        # List of Puddle objects
active_ground_strikes = [] # {'x', 'y', 'life'}

lightning_flicker_countdown = 0
lightning_bolt_paths = [] 
lightning_rumble_frames = 0
current_rumble_text = ""
screen_flash_active_frames = 0

current_wind_drift = 0.0
current_rain_char = '|' 
target_num_raindrops = config.MIN_RAINDROPS
storm_cycle_angle = 0.0
current_storm_intensity = 0.0 # Normalized 0-1

RUMBLE_LINE_INDEX = 0
SPLASH_LINE_INDEX = 0 # Ground level for splashes and puddles
STORM_AREA_HEIGHT = 0 # Min height for weather effects

# --- Classes ---
class Raindrop:
    """Represents a single raindrop with its behavior."""
    def __init__(self, width_bound, current_storm_area_height, initial_wind_drift):
        self.width_bound = width_bound
        # Use current_storm_area_height passed during construction
        self.storm_area_height = current_storm_area_height 
        self.reset(initial_wind_drift, is_initial_spawn=True)

    def reset(self, current_wind_drift_val, is_initial_spawn=False):
        self.char = config.get_rain_char_for_wind(current_wind_drift_val)
        
        # Determine valid y_range for spawn, ensuring max_y_spawn is not negative
        # self.storm_area_height is used here, should be at least 1
        max_y_for_random_spawn = self.storm_area_height - 1
        if max_y_for_random_spawn < 0:
             max_y_for_random_spawn = 0 # Clamp to 0 if storm_area_height is 1 (making max_y_for_random_spawn = 0)

        if not is_initial_spawn and \
           abs(current_wind_drift_val) > config.RAIN_SIDE_ORIGIN_THRESHOLD and \
           random.random() < 0.7:
            # Originate from sides in strong wind
            self.y = float(random.randint(0, max_y_for_random_spawn))
            if current_wind_drift_val > 0: 
                self.x = float(random.randint(-int(abs(current_wind_drift_val)) - 3, -1))
            else: 
                self.x = float(random.randint(self.width_bound, self.width_bound + int(abs(current_wind_drift_val)) + 2))
        else: 
            # Standard top origin or initial full-screen spawn
            if is_initial_spawn: # Initial spawn can be anywhere vertically in storm_area
                self.y = float(random.randint(0, max_y_for_random_spawn))
            else: # Reset to top after falling
                self.y = 0.0 
            self.x = float(random.randint(0, self.width_bound - 1))

    def update(self, current_wind_drift_val, current_splash_line_index):
        self.y += 1.0 
        self.x += current_wind_drift_val
        self.char = config.get_rain_char_for_wind(current_wind_drift_val)
        hit_ground = self.y >= current_splash_line_index
        off_screen_horizontal = not (-5 < self.x < self.width_bound + 5)

        if hit_ground:
            splash_x_pos = int(round(self.x))
            self.reset(current_wind_drift_val)
            return splash_x_pos 
        elif off_screen_horizontal:
            self.reset(current_wind_drift_val)
        return None

    def draw(self, buffer, color_override=None):
        draw_x, draw_y = int(round(self.x)), int(round(self.y))
        # Only draw if within the storm area (above splash line)
        if 0 <= draw_y < SPLASH_LINE_INDEX and 0 <= draw_x < config.WIDTH:
            set_char_in_buffer(draw_x, draw_y, self.char, color_override or config.COLOR_RAIN)

class Cloud:
    """Represents a cloud with its movement and appearance."""
    def __init__(self, id_val, min_w, max_w, min_y_pos_factor, max_y_div, base_char,
                 width_bound, current_storm_area_height, is_fg=True): # Pass current_storm_area_height
        self.id = id_val
        self.base_char = base_char
        self.width_bound = width_bound
        self.storm_area_height = current_storm_area_height # Use passed value
        self.min_y_factor = min_y_pos_factor # e.g. 1/6 for FG
        self.max_y_divisor = max_y_div
        self.is_foreground = is_fg
        
        self.regenerate_shape(min_w, max_w)
        self.x = float(random.randint(-self.width, width_bound -1)) 
        
        # Calculate y based on factors of the (guaranteed positive) storm_area_height
        min_y_abs = int(self.storm_area_height * self.min_y_factor)
        max_y_abs = self.storm_area_height // self.max_y_divisor
        if min_y_abs > max_y_abs: max_y_abs = min_y_abs # Ensure valid range for randint

        self.y = random.randint(min_y_abs, max_y_abs)


    def regenerate_shape(self, min_w, max_w):
        actual_min_w = max(1, min_w) 
        actual_max_w = max(actual_min_w, max_w)
        self.width = random.randint(actual_min_w, actual_max_w)
        
        shape_func = random.choice(config.CLOUD_SHAPE_PATTERNS)
        self.repr = shape_func(self.width)
        
        stripped_repr = self.repr.strip()
        self.width = len(stripped_repr) 
        if not stripped_repr: 
            self.repr = config.CLOUD_CHAR * random.randint(actual_min_w, actual_max_w)
            self.width = len(self.repr)


    def update(self, base_speed, wind_drift, wind_factor):
        cloud_speed_modifier = wind_drift * wind_factor
        self.x += (base_speed * (1 if wind_drift >= 0 else -1) + cloud_speed_modifier)
        cloud_int_x = int(round(self.x))
        
        # Recalculate y bounds for reset, similar to __init__
        min_y_abs = int(self.storm_area_height * self.min_y_factor)
        max_y_abs = self.storm_area_height // self.max_y_divisor
        if min_y_abs > max_y_abs: max_y_abs = min_y_abs

        if cloud_int_x >= self.width_bound: 
            self.x = float(-len(self.repr) - random.randint(0,5)) # Use len(self.repr) for full visual width
            self.y = random.randint(min_y_abs, max_y_abs)
            self.regenerate_shape(config.CLOUD_MIN_WIDTH, config.CLOUD_MAX_WIDTH)
        elif cloud_int_x + len(self.repr) < 0 : 
            self.x = float(self.width_bound -1 + random.randint(0,5)) 
            self.y = random.randint(min_y_abs, max_y_abs)
            self.regenerate_shape(config.CLOUD_MIN_WIDTH, config.CLOUD_MAX_WIDTH)


    def draw(self, buffer, color_override=None):
        default_color = config.COLOR_CLOUD_FG if self.is_foreground else config.COLOR_CLOUD_BG
        cloud_draw_x = int(round(self.x))
        
        # Ensure cloud y is within visual storm area, not on splash/rumble line
        # self.storm_area_height is the upper limit for generation, drawing happens up to STORM_AREA_HEIGHT -1
        if self.y >= self.storm_area_height: # If somehow it got too low (e.g. due to rounding or direct manipulation)
             min_y_abs = int(self.storm_area_height * self.min_y_factor)
             max_y_abs = self.storm_area_height // self.max_y_divisor
             if min_y_abs > max_y_abs: max_y_abs = min_y_abs
             self.y = random.randint(min_y_abs, max_y_abs)


        for i, char_c in enumerate(self.repr):
            # Only draw if y is valid (0 to STORM_AREA_HEIGHT-1)
            if 0 <= self.y < self.storm_area_height:
                if char_c != ' ': 
                    set_char_in_buffer(cloud_draw_x + i, self.y, char_c, color_override or default_color)

class Puddle:
    """Represents a puddle with intensity, width, and disturbances."""
    def __init__(self, base_x, initial_intensity=config.INITIAL_PUDDLE_INTENSITY, initial_width=1, puddle_id=None):
        self.id = puddle_id or f"puddle_{base_x}_{time.time()}_{random.randint(0,1000)}"
        self.base_x = base_x 
        self.intensity = initial_intensity
        self.width = initial_width
        self.disturbances = [] 

    def get_min_max_x(self):
        min_x = self.base_x - self.width // 2
        max_x = min_x + self.width - 1
        return min_x, max_x

    def is_coord_inside(self, x_coord):
        min_x, max_x = self.get_min_max_x()
        return min_x <= x_coord <= max_x

    def add_splash_contribution(self):
        self.intensity = min(config.PUDDLE_MAX_INTENSITY + 0.99, self.intensity + config.PUDDLE_FORMATION_PER_SPLASH)

    def add_disturbance(self, x_pos):
        self.disturbances = [d for d in self.disturbances if d['x'] != x_pos]
        self.disturbances.append({'x': x_pos, 'life': config.PUDDLE_DISTURBANCE_DURATION})

    def update_effects(self, storm_intensity_val):
        new_disturbances = [d for d in self.disturbances if d['life'] -1 > 0]
        for d in new_disturbances: d['life'] -=1
        self.disturbances = new_disturbances

        evap_rate = config.PUDDLE_EVAPORATION_RATE * (1.5 - storm_intensity_val)
        self.intensity -= evap_rate
        if self.intensity <= 0:
            return False 

        if self.intensity > config.PUDDLE_SPREAD_THRESHOLD:
            intensity_factor_width = int((self.intensity - config.PUDDLE_SPREAD_THRESHOLD) / 1.5) # Tuned divisor
            self.width = min(config.PUDDLE_MAX_WIDTH_PER_POINT, 1 + intensity_factor_width)
        else:
            self.width = 1 
        self.width = max(1, self.width) # Ensure width is at least 1
        return True


    @staticmethod
    def merge(p1, p2):
        p1_min_x, p1_max_x = p1.get_min_max_x()
        p2_min_x, p2_max_x = p2.get_min_max_x()
        new_abs_min_x = min(p1_min_x, p2_min_x)
        new_abs_max_x = max(p1_max_x, p2_max_x)
        p1_volume = p1.intensity * p1.width
        p2_volume = p2.intensity * p2.width
        new_width = new_abs_max_x - new_abs_min_x + 1
        new_base_x = new_abs_min_x + new_width // 2
        new_intensity = min(config.PUDDLE_MAX_INTENSITY + 0.99, (p1_volume + p2_volume) / new_width if new_width > 0 else 0)
        merged_puddle = Puddle(new_base_x, new_intensity, new_width, puddle_id=f"merged_{p1.id}_{p2.id}")
        return merged_puddle

    def draw(self, buffer, line_y, color_override=None):
        puddle_char_idx = min(config.PUDDLE_MAX_INTENSITY, int(self.intensity))
        char_to_draw = config.PUDDLE_CHARS[puddle_char_idx]
        min_x, max_x = self.get_min_max_x()
        for px in range(min_x, max_x + 1):
            if 0 <= px < config.WIDTH:
                is_disturbed = False
                for d in self.disturbances:
                    if d['x'] == px:
                        set_char_in_buffer(px, line_y, config.PUDDLE_DISTURBANCE_CHAR, color_override or config.COLOR_PUDDLE_DISTURBANCE)
                        is_disturbed = True
                        break
                if not is_disturbed:
                    set_char_in_buffer(px, line_y, char_to_draw, color_override or config.COLOR_PUDDLE)

# --- Helper Functions ---
def set_char_in_buffer(x, y, char, color=None):
    if 0 <= y < config.HEIGHT and 0 <= x < config.WIDTH:
        screen_buffer[y][x] = (char, color)

def initialize_global_structures():
    global screen_buffer, RUMBLE_LINE_INDEX, SPLASH_LINE_INDEX, STORM_AREA_HEIGHT
    global raindrops, clouds_fg, clouds_bg, active_splashes, puddles, active_ground_strikes
    global current_wind_drift, current_rain_char, target_num_raindrops, storm_cycle_angle, current_storm_intensity
    global lightning_flicker_countdown, lightning_bolt_paths, lightning_rumble_frames, current_rumble_text, screen_flash_active_frames

    RUMBLE_LINE_INDEX = config.HEIGHT - 1
    SPLASH_LINE_INDEX = config.HEIGHT - 2 
    # CRITICAL FIX: Ensure STORM_AREA_HEIGHT is at least 1
    # This is the area where weather effects (rain, clouds, lightning paths) can occur.
    # It's config.HEIGHT - 2, meaning it's above the splash and rumble lines.
    STORM_AREA_HEIGHT = max(1, config.HEIGHT - 2) 

    screen_buffer = [[(' ', None) for _ in range(config.WIDTH)] for _ in range(config.HEIGHT)]
    
    raindrops.clear()
    clouds_fg.clear()
    clouds_bg.clear()
    active_splashes.clear()
    puddles.clear() 
    active_ground_strikes.clear()

    current_wind_drift = 0.0
    current_rain_char = config.get_rain_char_for_wind(0)
    target_num_raindrops = config.MIN_RAINDROPS
    
    lightning_flicker_countdown = 0
    lightning_bolt_paths = []
    lightning_rumble_frames = 0
    current_rumble_text = ""
    screen_flash_active_frames = 0

    # Pass the calculated STORM_AREA_HEIGHT to Cloud constructor
    for i in range(config.NUM_CLOUDS_FG):
        clouds_fg.append(Cloud(f"fg_{i}", config.CLOUD_MIN_WIDTH, config.CLOUD_MAX_WIDTH,
                               1/6, 3, config.CLOUD_CHAR, # Use factor 1/6 of storm_area_height
                               config.WIDTH, STORM_AREA_HEIGHT, is_fg=True))
    for i in range(config.NUM_CLOUDS_BG):
        min_w_bg = max(1, config.CLOUD_MIN_WIDTH - 2)
        max_w_bg = max(min_w_bg, config.CLOUD_MAX_WIDTH - 2)
        clouds_bg.append(Cloud(f"bg_{i}", min_w_bg, max_w_bg,
                               0, 5, config.CLOUD_CHAR, # Min_y_factor 0 for BG clouds (can start at very top of storm area)
                               config.WIDTH, STORM_AREA_HEIGHT, is_fg=False))

def update_storm_parameters():
    global storm_cycle_angle, current_wind_drift, current_rain_char, target_num_raindrops
    global current_storm_intensity, raindrops

    storm_cycle_angle = (storm_cycle_angle + config.STORM_CYCLE_SPEED) % (2 * math.pi)
    current_storm_intensity = (math.sin(storm_cycle_angle) + 1) / 2

    base_drift = config.MAX_WIND_DRIFT_BASE * current_storm_intensity
    gust = base_drift * random.uniform(-config.STORM_GUST_FACTOR, config.STORM_GUST_FACTOR)
    current_wind_drift = base_drift + gust
    current_rain_char = config.get_rain_char_for_wind(current_wind_drift)

    target_num_raindrops = int(config.MIN_RAINDROPS + (config.MAX_RAINDROPS - config.MIN_RAINDROPS) * current_storm_intensity)

    # Pass STORM_AREA_HEIGHT to Raindrop constructor
    while len(raindrops) < target_num_raindrops:
        raindrops.append(Raindrop(config.WIDTH, STORM_AREA_HEIGHT, current_wind_drift))
    while len(raindrops) > target_num_raindrops and raindrops:
        raindrops.pop(random.randrange(len(raindrops)))


def update_rain_and_splashes():
    global active_splashes, puddles 
    
    new_visual_splashes = []
    for drop in raindrops:
        splash_x_pos = drop.update(current_wind_drift, SPLASH_LINE_INDEX)
        if splash_x_pos is not None and 0 <= splash_x_pos < config.WIDTH:
            new_visual_splashes.append({'x': splash_x_pos, 'y': SPLASH_LINE_INDEX, 'life': config.SPLASH_DURATION_FRAMES})
            hit_existing_puddle = False
            for puddle_obj in puddles:
                if puddle_obj.is_coord_inside(splash_x_pos):
                    puddle_obj.add_splash_contribution()
                    puddle_obj.add_disturbance(splash_x_pos)
                    hit_existing_puddle = True
                    break 
            if not hit_existing_puddle:
                new_puddle = Puddle(splash_x_pos)
                # new_puddle.add_splash_contribution() # Already has INITIAL_PUDDLE_INTENSITY
                new_puddle.add_disturbance(splash_x_pos)
                puddles.append(new_puddle)
    
    active_splashes.extend(new_visual_splashes)
    updated_active_splashes = [s for s in active_splashes if s['life'] -1 > 0]
    for s in updated_active_splashes: s['life'] -=1
    active_splashes = updated_active_splashes


def update_puddles():
    global puddles
    if not puddles:
        return

    surviving_puddles = [p for p in puddles if p.update_effects(current_storm_intensity)]
    puddles = surviving_puddles

    if not puddles or len(puddles) < 2: # No merging needed for 0 or 1 puddle
        return

    puddles.sort(key=lambda p: p.get_min_max_x()[0])
    
    merged_puddles_list = []
    current_merged = puddles[0]

    for i in range(1, len(puddles)):
        next_puddle = puddles[i]
        cp_min_x, cp_max_x = current_merged.get_min_max_x()
        np_min_x, np_max_x = next_puddle.get_min_max_x()

        if np_min_x <= cp_max_x + config.PUDDLE_MERGE_DISTANCE: 
            current_merged = Puddle.merge(current_merged, next_puddle)
        else:
            merged_puddles_list.append(current_merged)
            current_merged = next_puddle
            
    merged_puddles_list.append(current_merged) # Add the last processed puddle
    puddles = merged_puddles_list


def update_all_clouds():
    for cloud in clouds_fg:
        cloud.update(config.BASE_CLOUD_SPEED_FG, current_wind_drift, config.CLOUD_WIND_FACTOR_FG)
    for cloud in clouds_bg:
        cloud.update(config.BASE_CLOUD_SPEED_FG * config.BASE_CLOUD_SPEED_BG_FACTOR,
                     current_wind_drift, config.CLOUD_WIND_FACTOR_BG)

def generate_bolt_path(x_start, y_start, y_end, max_deviation=1):
    path = []
    current_x = x_start
    # Ensure y_start <= y_end for range to work correctly
    if y_start > y_end: y_start = y_end 

    for y_pos in range(y_start, y_end + 1):
        path.append((current_x, y_pos))
        if y_pos < y_end:
            deviation = random.randint(-max_deviation, max_deviation)
            if random.random() < 0.3: 
                deviation = random.choice([-2, -1, 0, 1, 2]) * (max_deviation > 0)
            current_x += deviation
            current_x = max(0, min(config.WIDTH - 1, current_x))
    return path

def update_lightning():
    global lightning_flicker_countdown, lightning_bolt_paths, lightning_rumble_frames
    global current_rumble_text, screen_flash_active_frames, active_ground_strikes

    if screen_flash_active_frames > 0: screen_flash_active_frames -=1
    
    if lightning_flicker_countdown > 0:
        lightning_flicker_countdown -= 1
        if lightning_flicker_countdown == 0: 
            lightning_bolt_paths = [] 
    
    if lightning_rumble_frames > 0: lightning_rumble_frames -= 1

    new_ground_strikes = [gs for gs in active_ground_strikes if gs['life'] -1 > 0]
    for gs in new_ground_strikes: gs['life'] -=1
    active_ground_strikes = new_ground_strikes

    if random.random() < config.LIGHTNING_PROBABILITY and lightning_rumble_frames == 0 and lightning_flicker_countdown == 0:
        lightning_flicker_countdown = config.LIGHTNING_FLICKER_DURATION
        lightning_rumble_frames = random.randint(config.RUMBLE_DURATION_MIN, config.RUMBLE_DURATION_MAX)
        current_rumble_text = random.choice(config.RUMBLE_TEXTS)
        screen_flash_active_frames = config.LIGHTNING_FLASH_DURATION
        lightning_bolt_paths = []
        is_complex = random.random() < config.LIGHTNING_COMPLEXITY_PROBABILITY
        
        potential_cloud_sources = [c for c in clouds_fg if int(round(c.x)) < config.WIDTH and int(round(c.x)) + len(c.repr) > 0]
        if potential_cloud_sources:
            source_cloud = random.choice(potential_cloud_sources)
            cloud_repr_stripped = source_cloud.repr.strip()
            cloud_actual_width = len(cloud_repr_stripped)
            cloud_start_x_on_screen = int(round(source_cloud.x)) + source_cloud.repr.find(cloud_repr_stripped[0] if cloud_repr_stripped else "")
            if cloud_actual_width > 0:
                 bolt_x_start = random.randint(cloud_start_x_on_screen, cloud_start_x_on_screen + cloud_actual_width -1)
            else: 
                 bolt_x_start = int(round(source_cloud.x)) + len(source_cloud.repr) // 2
            bolt_x_start = max(0, min(config.WIDTH -1, bolt_x_start))
            bolt_y_start = source_cloud.y + 1 
        else: 
            bolt_x_start = random.randint(config.WIDTH // 4, 3 * config.WIDTH // 4)
            bolt_y_start = random.randint(0, STORM_AREA_HEIGHT // 3 if STORM_AREA_HEIGHT >=3 else 0) 
        
        # Clamp bolt_y_start to be within the drawable storm area [0, STORM_AREA_HEIGHT-1]
        bolt_y_start = max(0, min(bolt_y_start, STORM_AREA_HEIGHT - 1))

        min_bolt_length = 2 # Minimum segments for a bolt

        # Determine the upper limit for the bolt's end y-coordinate
        max_y_for_bolt_end = STORM_AREA_HEIGHT - 1

        # Determine the earliest possible y-coordinate for the bolt's end
        min_y_for_bolt_end_strict = bolt_y_start + 1
        preferred_min_y_for_bolt_end = bolt_y_start + min_bolt_length
        
        actual_lower_bound_for_randint = max(min_y_for_bolt_end_strict, preferred_min_y_for_bolt_end)
        actual_lower_bound_for_randint = min(actual_lower_bound_for_randint, max_y_for_bolt_end) # Cannot exceed max_y

        if actual_lower_bound_for_randint > max_y_for_bolt_end :
            # Not enough space for a bolt, make a single point flash if possible
            if 0 <= bolt_y_start <= max_y_for_bolt_end: # Check if bolt_y_start is itself valid
                 main_bolt_path = [(bolt_x_start, bolt_y_start)]
            else: # bolt_y_start is somehow out of already restricted storm_area_height
                 main_bolt_path = [] 
        else:
            bolt_y_end = random.randint(actual_lower_bound_for_randint, max_y_for_bolt_end)
            main_bolt_path = generate_bolt_path(bolt_x_start, bolt_y_start, bolt_y_end)

        if main_bolt_path:
            lightning_bolt_paths.append({'path': main_bolt_path, 'char': config.LIGHTNING_PRIMARY_BOLT_CHAR})
            last_segment = main_bolt_path[-1]
            # Check if lightning hits ground (SPLASH_LINE_INDEX) or very near it
            if last_segment[1] >= SPLASH_LINE_INDEX -1 : 
                 active_ground_strikes.append({
                     'x': last_segment[0], 
                     'y': last_segment[1], # Draw at actual hit y
                     'life': config.GROUND_STRIKE_EFFECT_DURATION
                 })

            if is_complex and len(main_bolt_path) >= 3:
                num_branches = random.randint(1, config.LIGHTNING_MAX_BRANCHES)
                for _ in range(num_branches):
                    if len(main_bolt_path) < 2: continue # Need at least 2 points for a branch start
                    branch_start_index = random.randint(0, len(main_bolt_path) - 2) # Branch from any segment except the last point
                    branch_x_s, branch_y_s = main_bolt_path[branch_start_index]
                    
                    # Branch end y calculation relative to main bolt's end
                    branch_y_e_lower = branch_y_s + 1 # Must go down at least one
                    branch_y_e_upper = branch_y_s + int((main_bolt_path[-1][1] - branch_y_s) * config.LIGHTNING_BRANCH_LENGTH_FACTOR * random.uniform(0.5, 1.0))
                    branch_y_e_upper = min(branch_y_e_upper, STORM_AREA_HEIGHT - 1) # Clamp to storm area

                    if branch_y_e_lower <= branch_y_e_upper: # If valid range for branch end
                        branch_y_e = random.randint(branch_y_e_lower, branch_y_e_upper)
                        branch_char = random.choice(config.LIGHTNING_BOLT_CHARS)
                        branch_path = generate_bolt_path(branch_x_s, branch_y_s, branch_y_e, max_deviation=2)
                        if branch_path:
                           lightning_bolt_paths.append({'path': branch_path, 'char': branch_char})


def draw_scene():
    global screen_buffer
    flash_color_override = config.COLOR_SCREEN_FLASH if screen_flash_active_frames > 0 else None
    base_char, base_color = (' ', flash_color_override)
    screen_buffer = [[(base_char, base_color) for _ in range(config.WIDTH)] for _ in range(config.HEIGHT)]

    for cloud_obj in clouds_bg:
        cloud_obj.draw(screen_buffer, flash_color_override)
    for cloud_obj in clouds_fg:
        cloud_obj.draw(screen_buffer, flash_color_override)
    for drop_obj in raindrops: # Raindrops draw themselves above splash_line
        drop_obj.draw(screen_buffer, flash_color_override)
    
    if lightning_flicker_countdown > 0 and lightning_bolt_paths:
        for bolt_info in lightning_bolt_paths:
            bolt_char_to_draw = bolt_info['char']
            for bx, by in bolt_info['path']: # bx, by are within [0, STORM_AREA_HEIGHT-1]
                set_char_in_buffer(bx, by, bolt_char_to_draw, flash_color_override or config.COLOR_LIGHTNING)
    
    for strike in active_ground_strikes: # These are at or near SPLASH_LINE_INDEX
        set_char_in_buffer(strike['x'], strike['y'], config.GROUND_STRIKE_EFFECT_CHAR, flash_color_override or config.COLOR_GROUND_STRIKE)

    for puddle_obj in puddles: # Puddles draw themselves on SPLASH_LINE_INDEX
        puddle_obj.draw(screen_buffer, SPLASH_LINE_INDEX, flash_color_override)
    
    for splash in active_splashes: # Visual splash dots on SPLASH_LINE_INDEX
        set_char_in_buffer(splash['x'], splash['y'], config.SPLASH_CHAR, flash_color_override or config.COLOR_SPLASH)

    if lightning_rumble_frames > 0:
        text_len = len(current_rumble_text)
        start_pos = (config.WIDTH - text_len) // 2
        for i, char_r in enumerate(current_rumble_text): # Rumble text on RUMBLE_LINE_INDEX
            set_char_in_buffer(start_pos + i, RUMBLE_LINE_INDEX, char_r, flash_color_override or config.COLOR_RUMBLE_TEXT)


def render_screen():
    output_parts = [config.MOVE_CURSOR_HOME]
    current_active_color = None
    for y_idx in range(config.HEIGHT):
        for x_idx in range(config.WIDTH):
            char_to_print, new_color_code = screen_buffer[y_idx][x_idx]
            if new_color_code != current_active_color:
                output_parts.append(new_color_code or config.COLOR_RESET)
                current_active_color = new_color_code
            output_parts.append(char_to_print)
        
        if current_active_color is not None:
            output_parts.append(config.COLOR_RESET)
            current_active_color = None
        
        if y_idx < config.HEIGHT - 1:
            output_parts.append("\n")

    sys.stdout.write("".join(output_parts))
    sys.stdout.flush()

def main_animation_loop():
    try:
        sys.stdout.write(config.HIDE_CURSOR)
        sys.stdout.write(config.CLEAR_SCREEN)
        while True:
            update_storm_parameters()
            update_all_clouds()
            update_rain_and_splashes() 
            update_puddles()           
            update_lightning()
            
            draw_scene()
            render_screen()
            
            time.sleep(config.ANIMATION_DELAY)
    except KeyboardInterrupt:
        pass
    except Exception as e: # Catch any other unexpected error during the loop
        # Clean up terminal before printing error
        sys.stdout.write(config.COLOR_RESET)
        sys.stdout.write(config.SHOW_CURSOR)
        sys.stdout.write(config.MOVE_CURSOR_HOME)
        for i in range(config.HEIGHT): 
             sys.stdout.write(f"\033[{i+1};0H\033[K")
        sys.stdout.write(config.MOVE_CURSOR_HOME) 
        sys.stdout.flush()
        print(f"\nUNEXPECTED ERROR DURING ANIMATION: {e}")
        import traceback
        traceback.print_exc()

    finally:
        # Ensure cleanup happens even if loop broken by non-KeyboardInterrupt error
        if not isinstance(sys.exc_info()[1], KeyboardInterrupt): # if not already handled by above except
            sys.stdout.write(config.COLOR_RESET)
            sys.stdout.write(config.SHOW_CURSOR)
            sys.stdout.write(config.MOVE_CURSOR_HOME)
            for i in range(config.HEIGHT): 
                 sys.stdout.write(f"\033[{i+1};0H\033[K")
            sys.stdout.write(config.MOVE_CURSOR_HOME) 
            sys.stdout.flush()
        print(f"\nStorm Animation (Height Fix v{random.uniform(2.2,2.3):.1f}) has ended. Hope you enjoyed it!")

if __name__ == "__main__":
    try:
        cols, rows = os.get_terminal_size()
        config.WIDTH = cols
        config.HEIGHT = rows
        # Ensure minimum height for the script to be somewhat functional
        if config.HEIGHT < 3: # Need at least 3 lines for rumble, splash, and a bit of storm area
            print(f"Terminal height ({config.HEIGHT}) is too small. Minimum 3 lines required.")
            print("Please increase terminal height and try again.")
            sys.exit(1)
        print(f"Terminal: {config.WIDTH}x{config.HEIGHT}. Initializing Storm...")
    except OSError:
        print(f"Could not get terminal size. Using default: {config.WIDTH}x{config.HEIGHT}. Initializing Storm...")
        if config.HEIGHT < 3: # Check default too
             print(f"Default height ({config.HEIGHT}) is too small. Minimum 3 lines required.")
             sys.exit(1)

    initialize_global_structures() 
    time.sleep(1.0) 
    main_animation_loop()

