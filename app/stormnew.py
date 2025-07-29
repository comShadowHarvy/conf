# storm_animation_v2.py
import random
import time
import sys
import os
import math
from dataclasses import dataclass, field
from typing import List, Tuple, Optional, Callable, Dict

# Assumes a 'config.py' file exists in the same directory.
# See the end of this response for a sample config.py.
import config

# --- Type Aliases for Clarity ---
Color = Optional[str]
CharAndColor = Tuple[str, Color]
ScreenBuffer = List[List[CharAndColor]]
Path = List[Tuple[int, int]]


# --- Data Classes for State & Effects ---
@dataclass
class Effect:
    """A generic class for temporary visual effects like splashes or ground strikes."""
    x: int
    y: int
    life: int

@dataclass
class LightningBolt:
    """Represents a single lightning bolt, which may be a main bolt or a branch."""
    path: Path
    char: str

@dataclass
class StormState:
    """Encapsulates the entire dynamic state of the storm animation."""
    width: int
    height: int
    screen_buffer: ScreenBuffer = field(default_factory=list)
    rumble_line_index: int = 0
    splash_line_index: int = 0
    storm_area_height: int = 0

    # Storm parameters
    storm_cycle_angle: float = 0.0
    current_storm_intensity: float = 0.0  # Normalized 0-1
    current_wind_drift: float = 0.0
    target_num_raindrops: int = 0

    # Scene elements
    raindrops: List['Raindrop'] = field(default_factory=list)
    clouds_fg: List['Cloud'] = field(default_factory=list)
    clouds_bg: List['Cloud'] = field(default_factory=list)
    puddles: List['Puddle'] = field(default_factory=list)

    # Ephemeral effects
    active_splashes: List[Effect] = field(default_factory=list)
    active_ground_strikes: List[Effect] = field(default_factory=list)
    lightning_bolts: List[LightningBolt] = field(default_factory=list)
    screen_flash_frames: int = 0
    lightning_flicker_frames: int = 0
    lightning_rumble_frames: int = 0
    current_rumble_text: str = ""


# --- Simulation Object Classes ---
class Raindrop:
    """Represents a single raindrop with its behavior."""

    def __init__(self, width_bound: int, storm_area_height: int, initial_wind_drift: float):
        self.width_bound = width_bound
        self.storm_area_height = storm_area_height
        self.x = 0.0
        self.y = 0.0
        self.char = config.get_rain_char_for_wind(initial_wind_drift)
        self.reset(initial_wind_drift, is_initial_spawn=True)

    def reset(self, wind_drift: float, is_initial_spawn: bool = False) -> None:
        """Resets the raindrop's position, either to the top or to a random side."""
        self.char = config.get_rain_char_for_wind(wind_drift)
        max_y_spawn = max(0, self.storm_area_height - 1)

        # In strong winds, raindrops can originate from the sides
        if not is_initial_spawn and abs(wind_drift) > config.RAIN_SIDE_ORIGIN_THRESHOLD and random.random() < 0.7:
            self.y = float(random.randint(0, max_y_spawn))
            if wind_drift > 0:
                self.x = float(random.randint(-int(abs(wind_drift)) - 3, -1))
            else:
                self.x = float(random.randint(self.width_bound, self.width_bound + int(abs(wind_drift)) + 2))
        else:
            # Standard top-origin or initial full-screen spawn
            self.y = float(random.randint(0, max_y_spawn)) if is_initial_spawn else 0.0
            self.x = float(random.randint(0, self.width_bound - 1))

    def update(self, wind_drift: float, splash_line_index: int) -> Optional[int]:
        """Updates the raindrop's position. Returns splash X-coordinate if it hits the ground."""
        self.y += 1.0
        self.x += wind_drift

        hit_ground = self.y >= splash_line_index
        off_screen_horizontal = not (-5 < self.x < self.width_bound + 5)

        if hit_ground:
            splash_x = int(round(self.x))
            self.reset(wind_drift)
            return splash_x
        if off_screen_horizontal:
            self.reset(wind_drift)
        return None

    def draw(self, screen_buffer: ScreenBuffer, storm_area_height: int, color_override: Color = None) -> None:
        """Draws the raindrop onto the screen buffer."""
        draw_x, draw_y = int(round(self.x)), int(round(self.y))
        if 0 <= draw_y < storm_area_height and 0 <= draw_x < self.width_bound:
            screen_buffer[draw_y][draw_x] = (self.char, color_override or config.COLOR_RAIN)


class Cloud:
    """Represents a cloud with its movement and appearance."""

    def __init__(self, storm_area_height: int, width_bound: int, is_foreground: bool):
        self.storm_area_height = max(1, storm_area_height)
        self.width_bound = width_bound
        self.is_foreground = is_foreground

        # Set properties based on whether the cloud is in the foreground or background
        if self.is_foreground:
            self.min_y_factor, self.max_y_divisor = 1/6, 3
            self.min_w, self.max_w = config.CLOUD_MIN_WIDTH, config.CLOUD_MAX_WIDTH
        else:
            self.min_y_factor, self.max_y_divisor = 0, 5
            self.min_w = max(1, config.CLOUD_MIN_WIDTH - 2)
            self.max_w = max(self.min_w, config.CLOUD_MAX_WIDTH - 2)

        self.width = 0
        self.repr = ""
        self._regenerate_shape()

        self.x = float(random.randint(-self.width, self.width_bound - 1))
        self.y = self._get_random_y()

    def _get_random_y(self) -> int:
        """Calculates a valid random Y position based on cloud properties."""
        min_y = int(self.storm_area_height * self.min_y_factor)
        max_y = self.storm_area_height // self.max_y_divisor
        return random.randint(min_y, max(min_y, max_y))

    def _regenerate_shape(self) -> None:
        """Generates a new random shape for the cloud."""
        shape_func = random.choice(config.CLOUD_SHAPE_PATTERNS)
        self.width = random.randint(self.min_w, self.max_w)
        self.repr = shape_func(self.width)
        self.width = len(self.repr.strip())
        if not self.repr.strip():
            self.repr = config.CLOUD_CHAR * self.width

    def update(self, base_speed: float, wind_drift: float, wind_factor: float) -> None:
        """Updates the cloud's position."""
        self.x += base_speed + (wind_drift * wind_factor)
        
        # If cloud moves off-screen, reset its position and shape
        if self.x >= self.width_bound:
            self.x = float(-len(self.repr))
            self.y = self._get_random_y()
            self._regenerate_shape()
        elif self.x + len(self.repr) < 0:
            self.x = float(self.width_bound)
            self.y = self._get_random_y()
            self._regenerate_shape()

    def draw(self, screen_buffer: ScreenBuffer, color_override: Color = None) -> None:
        """Draws the cloud onto the screen buffer."""
        draw_x = int(round(self.x))
        color = config.COLOR_CLOUD_FG if self.is_foreground else config.COLOR_CLOUD_BG
        
        if 0 <= self.y < self.storm_area_height:
            for i, char in enumerate(self.repr):
                if char != ' ' and 0 <= draw_x + i < self.width_bound:
                    screen_buffer[self.y][draw_x + i] = (char, color_override or color)


class Puddle:
    """Represents a puddle that grows, evaporates, and merges."""

    def __init__(self, base_x: int):
        self.base_x = base_x
        self.intensity = config.INITIAL_PUDDLE_INTENSITY
        self.width = 1
        self.disturbances: List[Dict[str, int]] = []

    def get_bounds(self) -> Tuple[int, int]:
        """Returns the min and max x-coordinates of the puddle."""
        min_x = self.base_x - self.width // 2
        return min_x, min_x + self.width - 1

    def is_coord_inside(self, x_coord: int) -> bool:
        """Checks if a given x-coordinate is within the puddle."""
        min_x, max_x = self.get_bounds()
        return min_x <= x_coord <= max_x

    def add_splash(self, x_pos: int) -> None:
        """Increases intensity and adds a visual disturbance from a raindrop."""
        self.intensity = min(config.PUDDLE_MAX_INTENSITY, self.intensity + config.PUDDLE_FORMATION_PER_SPLASH)
        # Add a new disturbance effect
        self.disturbances.append({'x': x_pos, 'life': config.PUDDLE_DISTURBANCE_DURATION})

    def update(self, storm_intensity: float) -> bool:
        """Updates puddle effects (evaporation, width) and returns True if it survives."""
        # Evaporate faster in calmer weather
        evap_rate = config.PUDDLE_EVAPORATION_RATE * (1.5 - storm_intensity)
        self.intensity -= evap_rate
        if self.intensity <= 0:
            return False  # Puddle has evaporated

        # Update disturbances
        self.disturbances = [d for d in self.disturbances if d['life'] > 1]
        for d in self.disturbances:
            d['life'] -= 1

        # Update width based on intensity
        if self.intensity > config.PUDDLE_SPREAD_THRESHOLD:
            intensity_factor = (self.intensity - config.PUDDLE_SPREAD_THRESHOLD) / 1.5
            self.width = min(config.PUDDLE_MAX_WIDTH_PER_POINT, 1 + int(intensity_factor))
        else:
            self.width = 1
        return True

    @staticmethod
    def merge(p1: 'Puddle', p2: 'Puddle') -> 'Puddle':
        """Merges two puddles into a new, larger one."""
        p1_min, p1_max = p1.get_bounds()
        p2_min, p2_max = p2.get_bounds()
        
        new_min_x = min(p1_min, p2_min)
        new_max_x = max(p1_max, p2_max)
        new_width = new_max_x - new_min_x + 1
        
        p1_volume = p1.intensity * p1.width
        p2_volume = p2.intensity * p2.width
        
        new_base_x = new_min_x + new_width // 2
        new_puddle = Puddle(new_base_x)
        new_puddle.width = new_width
        new_puddle.intensity = min(config.PUDDLE_MAX_INTENSITY, (p1_volume + p2_volume) / new_width)
        return new_puddle

    def draw(self, screen_buffer: ScreenBuffer, y_line: int, width_bound: int, color_override: Color = None) -> None:
        """Draws the puddle and its disturbances onto the screen buffer."""
        puddle_char_idx = min(len(config.PUDDLE_CHARS) - 1, int(self.intensity))
        char = config.PUDDLE_CHARS[puddle_char_idx]
        min_x, max_x = self.get_bounds()

        for x in range(min_x, max_x + 1):
            if 0 <= x < width_bound:
                # Check for disturbances at this location
                is_disturbed = any(d['x'] == x for d in self.disturbances)
                if is_disturbed:
                    screen_buffer[y_line][x] = (config.PUDDLE_DISTURBANCE_CHAR, color_override or config.COLOR_PUDDLE_DISTURBANCE)
                else:
                    screen_buffer[y_line][x] = (char, color_override or config.COLOR_PUDDLE)


# --- Main Application Class ---
class StormAnimation:
    """Manages the state, updates, and rendering of the storm animation."""

    def __init__(self, width: int, height: int):
        if height < 4:
            print(f"Terminal height ({height}) is too small. Minimum 4 lines required.", file=sys.stderr)
            sys.exit(1)
        
        self.state = StormState(width=width, height=height)
        self._initialize_state()

    def _initialize_state(self) -> None:
        """Sets up the initial state of the animation."""
        st = self.state
        st.splash_line_index = st.height - 2
        st.rumble_line_index = st.height - 1
        st.storm_area_height = st.height - 2
        st.target_num_raindrops = config.MIN_RAINDROPS

        # Create initial clouds
        for _ in range(config.NUM_CLOUDS_FG):
            st.clouds_fg.append(Cloud(st.storm_area_height, st.width, is_foreground=True))
        for _ in range(config.NUM_CLOUDS_BG):
            st.clouds_bg.append(Cloud(st.storm_area_height, st.width, is_foreground=False))

    def run(self) -> None:
        """Starts and runs the main animation loop."""
        sys.stdout.write(config.HIDE_CURSOR + config.CLEAR_SCREEN)
        while True:
            self._update()
            self._draw()
            self._render()
            time.sleep(config.ANIMATION_DELAY)

    def _update(self) -> None:
        """Calls all state update methods for a single frame."""
        self._update_storm_parameters()
        self._update_clouds()
        self._update_rain_and_splashes()
        self._update_puddles()
        self._update_lightning()

    def _update_storm_parameters(self) -> None:
        """Updates overall storm intensity, wind, and rain density."""
        st = self.state
        st.storm_cycle_angle = (st.storm_cycle_angle + config.STORM_CYCLE_SPEED) % (2 * math.pi)
        st.current_storm_intensity = (math.sin(st.storm_cycle_angle) + 1) / 2

        base_drift = config.MAX_WIND_DRIFT_BASE * st.current_storm_intensity
        gust = base_drift * random.uniform(-config.STORM_GUST_FACTOR, config.STORM_GUST_FACTOR)
        st.current_wind_drift = base_drift + gust

        st.target_num_raindrops = int(config.MIN_RAINDROPS + (config.MAX_RAINDROPS - config.MIN_RAINDROPS) * st.current_storm_intensity)

        # Adjust number of raindrops to match target
        while len(st.raindrops) < st.target_num_raindrops:
            st.raindrops.append(Raindrop(st.width, st.storm_area_height, st.current_wind_drift))
        while len(st.raindrops) > st.target_num_raindrops:
            st.raindrops.pop(random.randrange(len(st.raindrops)))

    def _update_clouds(self) -> None:
        """Updates the position of all clouds."""
        st = self.state
        for cloud in st.clouds_fg:
            cloud.update(config.BASE_CLOUD_SPEED_FG, st.current_wind_drift, config.CLOUD_WIND_FACTOR_FG)
        for cloud in st.clouds_bg:
            bg_speed = config.BASE_CLOUD_SPEED_FG * config.BASE_CLOUD_SPEED_BG_FACTOR
            cloud.update(bg_speed, st.current_wind_drift, config.CLOUD_WIND_FACTOR_BG)
            
    def _update_rain_and_splashes(self) -> None:
        """Updates raindrops and creates splashes and puddles where they land."""
        st = self.state
        new_splashes = []
        for drop in st.raindrops:
            splash_x = drop.update(st.current_wind_drift, st.splash_line_index)
            if splash_x is not None and 0 <= splash_x < st.width:
                new_splashes.append(Effect(x=splash_x, y=st.splash_line_index, life=config.SPLASH_DURATION_FRAMES))
                
                # Check if the splash hits an existing puddle
                hit_puddle = next((p for p in st.puddles if p.is_coord_inside(splash_x)), None)
                if hit_puddle:
                    hit_puddle.add_splash(splash_x)
                else:
                    new_puddle = Puddle(splash_x)
                    new_puddle.add_splash(splash_x)
                    st.puddles.append(new_puddle)
        
        # Update splash effect lifetimes
        st.active_splashes.extend(new_splashes)
        st.active_splashes = [s for s in st.active_splashes if s.life > 1]
        for s in st.active_splashes:
            s.life -= 1

    def _update_puddles(self) -> None:
        """Updates evaporation, growth, and merging of puddles."""
        st = self.state
        if not st.puddles:
            return

        # Update individual puddles and remove evaporated ones
        st.puddles = [p for p in st.puddles if p.update(st.current_storm_intensity)]
        if len(st.puddles) < 2:
            return

        # Merge overlapping puddles
        st.puddles.sort(key=lambda p: p.get_bounds()[0])
        merged = []
        current_merge = st.puddles[0]
        for i in range(1, len(st.puddles)):
            next_puddle = st.puddles[i]
            cp_min, cp_max = current_merge.get_bounds()
            np_min, _ = next_puddle.get_bounds()
            
            if np_min <= cp_max + config.PUDDLE_MERGE_DISTANCE:
                current_merge = Puddle.merge(current_merge, next_puddle)
            else:
                merged.append(current_merge)
                current_merge = next_puddle
        merged.append(current_merge)
        st.puddles = merged

    def _update_lightning(self) -> None:
        """Handles lightning strikes, flashes, and thunder rumble effects."""
        st = self.state
        
        # Decrement countdowns for active effects
        if st.screen_flash_frames > 0: st.screen_flash_frames -= 1
        if st.lightning_flicker_frames > 0:
            st.lightning_flicker_frames -= 1
            if st.lightning_flicker_frames == 0:
                st.lightning_bolts.clear()
        if st.lightning_rumble_frames > 0: st.lightning_rumble_frames -= 1
        
        st.active_ground_strikes = [gs for gs in st.active_ground_strikes if gs.life > 1]
        for gs in st.active_ground_strikes: gs.life -= 1

        # Trigger a new lightning event
        can_strike = st.lightning_flicker_frames == 0 and st.lightning_rumble_frames == 0
        if random.random() < config.LIGHTNING_PROBABILITY and can_strike:
            self._trigger_lightning_event()
    
    def _trigger_lightning_event(self) -> None:
        """Generates a new lightning bolt, flash, and rumble."""
        st = self.state
        st.lightning_flicker_frames = config.LIGHTNING_FLICKER_DURATION
        st.lightning_rumble_frames = random.randint(config.RUMBLE_DURATION_MIN, config.RUMBLE_DURATION_MAX)
        st.current_rumble_text = random.choice(config.RUMBLE_TEXTS)
        st.screen_flash_frames = config.LIGHTNING_FLASH_DURATION
        st.lightning_bolts = []

        # Determine start position of bolt (from a cloud if possible)
        source_cloud = random.choice(st.clouds_fg) if st.clouds_fg else None
        if source_cloud:
            x_start = int(round(source_cloud.x + source_cloud.width / 2))
            y_start = source_cloud.y + 1
        else:
            x_start = random.randint(st.width // 4, 3 * st.width // 4)
            y_start = random.randint(0, st.storm_area_height // 3)
        
        x_start = max(0, min(st.width - 1, x_start))
        y_start = max(0, min(st.storm_area_height - 1, y_start))

        # Determine end position and generate main bolt path
        y_end_max = st.storm_area_height - 1
        y_end_min = y_start + 2  # Ensure bolt has some length
        if y_end_min > y_end_max: return # Not enough space to strike

        y_end = random.randint(y_end_min, y_end_max)
        main_bolt_path = self._generate_bolt_path(x_start, y_start, y_end)
        
        if not main_bolt_path: return
        st.lightning_bolts.append(LightningBolt(path=main_bolt_path, char=config.LIGHTNING_PRIMARY_BOLT_CHAR))

        # Check for ground strike
        last_x, last_y = main
