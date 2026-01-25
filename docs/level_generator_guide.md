# Level Generator Guide

A procedural level generator for Zara that creates platformer levels with floors, walls, platforms, enemies, and collectibles.

## Quick Start - Test Scene

The fastest way to try the generator:

1. Open **`levels/generator/generator_test_scene.tscn`** in Godot
2. Run the scene (F6)
3. Click **"Generate New Level"** or press **R** to create new levels
4. Adjust the difficulty slider (1-10) to change level complexity
5. Play through the generated level with your character

The test scene includes:
- A "Generate New Level" button
- Difficulty slider (1-10)
- Seed display (for sharing/reproducing levels)
- Your player character with camera

## Two Generator Modes

### 1. Standalone Generator (Simple)

Creates levels directly with platforms, walls, and gaps. Best for quick procedural levels.

```gdscript
var generator = preload("res://levels/generator/standalone_generator.tscn").instantiate()
add_child(generator)

# Generate with random seed and difficulty 5
generator.generate(0, 5)

# Position player
player.global_position = generator.get_player_spawn()
```

### 2. Room-Based Generator (Advanced)

Connects pre-designed room templates with procedural connectors. Best for hand-crafted experiences with procedural variety.

## Quick Start (Code)

```gdscript
# Instance and add the generator
var generator = preload("res://levels/generator/level_generator.tscn").instantiate()
add_child(generator)

# Generate a level with seed 12345, difficulty 5, and 4 rooms
generator.generate_level(12345, 5, 4)

# Position the player at the spawn point
player.global_position = generator.get_player_spawn()
```

## Architecture Overview

```
levels/generator/
├── standalone_generator.gd    # Simple generator (recommended)
├── standalone_generator.tscn  # Scene for simple generation
├── generator_test_scene.gd    # Test scene with UI
├── generator_test_scene.tscn  # Runnable test scene
├── level_generator.gd         # Room-based orchestrator
├── level_generator.tscn       # Scene for room-based generation
├── difficulty_manager.gd      # Difficulty scaling
├── chunk_generator.gd         # Procedural connectors
├── platform_placer.gd         # TileMap manipulation
├── entity_spawner.gd          # Enemy/collectible spawning
└── path_validator.gd          # Completability validation

levels/templates/
├── start_room.tscn         # Entry room
├── combat_basic.tscn       # Combat arena
├── platforming_basic.tscn  # Jumping challenge
└── shop_room.tscn          # Shop station room
```

## Standalone Generator (Simple Mode)

The `StandaloneGenerator` creates complete levels with a single method call.

### What It Generates

- **Floor** with gaps based on difficulty
- **Walls** on left and right edges
- **Platforms** at multiple height layers
- **Gold coins** scattered throughout
- **Enemies** on the ground floor

### Usage

```gdscript
# Instance the generator
var generator = preload("res://levels/generator/standalone_generator.tscn").instantiate()
add_child(generator)

# Generate a level
generator.generate(0, 5)  # seed (0=random), difficulty (1-10)

# Get player spawn
var spawn = generator.get_player_spawn()
```

### Exported Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `seed_value` | int | 0 | RNG seed (0 = random) |
| `difficulty` | int | 5 | Difficulty level (1-10) |
| `level_width` | int | 60 | Level width in tiles |
| `level_height` | int | 20 | Level height in tiles |

### Signals

| Signal | Description |
|--------|-------------|
| `generation_completed` | Emitted when generation finishes |

## Core Components

### LevelGenerator

The main orchestrator that coordinates all generation steps.

**Exported Properties:**
| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `seed_value` | int | 0 | RNG seed (0 = random) |
| `difficulty` | int | 5 | Difficulty level (1-10) |
| `level_length` | int | 4 | Number of rooms |

**Signals:**
| Signal | Parameters | Description |
|--------|------------|-------------|
| `generation_started` | - | Emitted when generation begins |
| `generation_progress` | percent: float, message: String | Progress updates |
| `generation_completed` | level: Node2D | Generation finished successfully |
| `generation_failed` | reason: String | Generation failed |

**Methods:**
```gdscript
# Generate a new level
func generate_level(p_seed: int = 0, p_difficulty: int = 5, p_length: int = 4) -> Node2D

# Get the player spawn position
func get_player_spawn() -> Vector2

# Regenerate with a new random seed
func regenerate() -> Node2D

# Regenerate with the same seed (for testing)
func regenerate_same_seed() -> Node2D
```

### DifficultyManager

Controls how difficulty affects level generation.

| Difficulty | Enemy Types | Max Gap | Platform Width | Collectibles |
|------------|-------------|---------|----------------|--------------|
| 1-2 | Flowery, Dummy | 2 tiles | 4-8 tiles | High density |
| 3-4 | + Spidey, BlindingSpider | 3 tiles | 3-6 tiles | Medium-high |
| 5-6 | + EnemyX (chasing) | 4 tiles | 3-6 tiles | Medium |
| 7-8 | All enemies | 5 tiles | 2-5 tiles | Medium-low |
| 9-10 | All enemies (aggressive) | 6 tiles | 2-5 tiles | Low density |

### ChunkGenerator

Generates procedural platform bridges between rooms based on player physics:

- **Max jump height:** 6 tiles (~96 pixels)
- **Max jump distance:** 5 tiles horizontal
- **Min platform width:** 2 tiles

### PathValidator

Uses flood-fill algorithm to verify that:
- All platforms are reachable from the entry point
- The exit is reachable from the entry
- No impossible jumps exist

If validation fails, safety platforms are added automatically.

## Room Templates

Room templates are `.tscn` scenes with metadata that defines entry/exit points and spawn zones.

### Required Metadata

Set these on the root Node2D of your room template:

| Key | Type | Description |
|-----|------|-------------|
| `entry_point` | Vector2i | Tile position where player enters |
| `exit_point` | Vector2i | Tile position where player exits |
| `room_width` | int | Room width in tiles |
| `room_height` | int | Room height in tiles |
| `room_category` | String | Category: "start", "combat", "platforming", "shop" |
| `spawn_zones` | Array[Vector2] | Tile positions for enemy/collectible spawning |

### Creating a New Room Template

1. Create a new scene with a Node2D root
2. Add a TileMapLayer child using `res://levels/world.tres`
3. Design your room layout
4. Add metadata to the root node:

```gdscript
# In the Godot editor, select the root node and add metadata:
# Inspector > Node > Metadata

# Or via script:
func _ready():
    set_meta("entry_point", Vector2i(1, 9))
    set_meta("exit_point", Vector2i(18, 9))
    set_meta("room_width", 20)
    set_meta("room_height", 12)
    set_meta("room_category", "combat")
    set_meta("spawn_zones", [Vector2(5, 8), Vector2(10, 8), Vector2(15, 8)])
```

5. Save to `levels/templates/` and register in `level_generator.gd`:

```gdscript
const ROOM_TEMPLATES := {
    # ... existing templates
    "my_room": "res://levels/templates/my_room.tscn"
}
```

### Template Categories

| Category | Description | Features |
|----------|-------------|----------|
| `start` | Level entry point | Safe area, tutorial hints |
| `combat` | Enemy encounters | Multiple spawn zones, arena layout |
| `platforming` | Jumping challenges | Varying heights, collectible placement |
| `shop` | Shop stations | Safe area, shop station included |

## Usage Examples

### Basic Level Generation

```gdscript
extends Node2D

var generator: LevelGenerator
var player: Player

func _ready():
    # Create generator
    generator = preload("res://levels/generator/level_generator.tscn").instantiate()
    add_child(generator)

    # Connect signals
    generator.generation_completed.connect(_on_generation_completed)
    generator.generation_failed.connect(_on_generation_failed)

    # Generate level
    generator.generate_level(0, 5, 4)

func _on_generation_completed(level: Node2D):
    # Spawn player
    player = preload("res://entities/player/player.tscn").instantiate()
    player.global_position = generator.get_player_spawn()
    add_child(player)

func _on_generation_failed(reason: String):
    push_error("Level generation failed: " + reason)
```

### Seeded Generation (Shareable Levels)

```gdscript
# Generate a specific level that can be shared
var seed_code = 42069
generator.generate_level(seed_code, 7, 5)

# Anyone using the same seed gets the same level
print("Share this seed: ", generator.seed_value)
```

### Progressive Difficulty

```gdscript
var current_level = 1

func generate_next_level():
    var difficulty = mini(current_level, 10)
    var room_count = 3 + (current_level / 2)

    generator.generate_level(0, difficulty, room_count)
    current_level += 1
```

### Monitoring Generation Progress

```gdscript
func _ready():
    generator.generation_progress.connect(_on_progress)

func _on_progress(percent: float, message: String):
    progress_bar.value = percent * 100
    status_label.text = message
```

## Customization

### Adding New Enemy Types

Edit `difficulty_manager.gd`:

```gdscript
const ENEMY_SCENES := {
    "easy": [
        "res://entities/enemies/flower/flowery.tscn",
        "res://entities/enemies/dummy_test.tscn",
        "res://entities/enemies/my_easy_enemy.tscn"  # Add here
    ],
    "medium": [
        "res://entities/enemies/spidey.tscn",
        "res://entities/enemies/blinding_spider.tscn"
    ],
    "hard": [
        "res://entities/enemies/enemy.tscn",
        "res://entities/enemies/my_boss.tscn"  # Add here
    ]
}
```

### Adding New Collectibles

Edit `difficulty_manager.gd`:

```gdscript
const COLLECTIBLE_SCENES := {
    "gold": "res://collectibles/gold/gold_coin.tscn",
    "fuel_small": "res://collectibles/fuel/fuel-1sec.tscn",
    "fuel_large": "res://collectibles/fuel/fuel-5sec.tscn",
    "health": "res://collectibles/health/health_pickup.tscn"  # Add here
}
```

### Adjusting Jump Physics

If you modify player jump velocity, update `chunk_generator.gd`:

```gdscript
# These must match player capabilities
const MAX_JUMP_HEIGHT_TILES := 6   # Tiles player can jump up
const MAX_JUMP_DISTANCE_TILES := 5  # Tiles player can jump horizontally
```

### Custom Room Selection Logic

Override `_select_room_sequence()` in `level_generator.gd`:

```gdscript
func _select_room_sequence() -> Array[String]:
    var sequence: Array[String] = ["start"]

    # Custom logic: alternate combat and platforming
    for i in range(level_length - 1):
        if i % 2 == 0:
            sequence.append("combat")
        else:
            sequence.append("platforming")

    # Always end with shop
    sequence[-1] = "shop"

    return sequence
```

## Testing

Run the unit tests:

```bash
# Command line
/Applications/Godot.app/Contents/MacOS/Godot --headless \
  -s addons/gut/gut_cmdln.gd \
  -gtest=test/unit/test_level_generator.gd \
  --path /path/to/Zara

# Or use the GUT panel in the Godot editor
```

### Manual Testing Checklist

1. Generate with seed, verify same seed produces identical output
2. Play through generated levels at difficulty 1, 5, and 10
3. Verify all jumps are achievable
4. Check enemy spawns match difficulty settings
5. Confirm shop rooms have functional shop stations

## Troubleshooting

### "Room template not found"

Ensure the template path in `ROOM_TEMPLATES` matches the actual file location.

### Levels are impossible to complete

Check that:
- Room entry/exit points are accessible (not inside walls)
- `spawn_zones` metadata positions are on platforms
- Jump constraints match actual player physics

### Enemies spawning in walls

Verify `spawn_zones` in room templates are above solid ground, not inside tiles.

### Same seed produces different levels

Ensure no external RNG calls occur between `generate_level()` calls. The generator uses its own `RandomNumberGenerator` instance.

## File Reference

| File | Purpose |
|------|---------|
| `standalone_generator.gd` | Simple level generator (recommended) |
| `standalone_generator.tscn` | Scene for simple generation |
| `generator_test_scene.gd` | Test scene controller with UI |
| `generator_test_scene.tscn` | **Run this to test the generator** |
| `level_generator.gd` | Room-based orchestrator |
| `level_generator.tscn` | Scene for room-based generation |
| `difficulty_manager.gd` | Difficulty scaling configuration |
| `chunk_generator.gd` | Procedural platform bridge generation |
| `platform_placer.gd` | TileMap tile placement utilities |
| `entity_spawner.gd` | Enemy and collectible instantiation |
| `path_validator.gd` | Level completability validation |
| `start_room.tscn` | Entry room template |
| `combat_basic.tscn` | Combat encounter template |
| `platforming_basic.tscn` | Jumping challenge template |
| `shop_room.tscn` | Shop station template |
| `test_level_generator.gd` | Unit tests (26 tests) |
