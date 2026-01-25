extends Node2D
class_name LevelGenerator

## Main orchestrator for procedural level generation.
## Coordinates room selection, placement, connector generation, and entity spawning.

const DifficultyManagerScript = preload("res://levels/generator/difficulty_manager.gd")
const PlatformPlacerScript = preload("res://levels/generator/platform_placer.gd")
const ChunkGeneratorScript = preload("res://levels/generator/chunk_generator.gd")
const EntitySpawnerScript = preload("res://levels/generator/entity_spawner.gd")
const PathValidatorScript = preload("res://levels/generator/path_validator.gd")

signal generation_started
signal generation_progress(percent: float, message: String)
signal generation_completed(level: Node2D)
signal generation_failed(reason: String)

# Generation parameters
@export var seed_value: int = 0  # 0 = random seed
@export var difficulty: int = 5  # 1-10
@export var level_length: int = 4  # Number of rooms

# Room template paths
const ROOM_TEMPLATES := {
	"start": "res://levels/templates/start_room.tscn",
	"combat": "res://levels/templates/combat_basic.tscn",
	"platforming": "res://levels/templates/platforming_basic.tscn",
	"shop": "res://levels/templates/shop_room.tscn"
}

# Tile size
const TILE_SIZE := 16

# Spacing between rooms (in tiles)
const ROOM_SPACING := 8

# Room metadata keys expected in room scenes
const META_ENTRY := "entry_point"  # Vector2i tile position
const META_EXIT := "exit_point"  # Vector2i tile position
const META_WIDTH := "room_width"  # int tiles
const META_HEIGHT := "room_height"  # int tiles
const META_SPAWN_ZONES := "spawn_zones"  # Array[Vector2]
const META_CATEGORY := "room_category"  # String

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var entities: Node2D = $Entities
@onready var rooms_container: Node2D = $Rooms

var rng: RandomNumberGenerator
var difficulty_manager  # DifficultyManager
var platform_placer  # PlatformPlacer
var chunk_generator  # ChunkGenerator
var entity_spawner  # EntitySpawner
var path_validator  # PathValidator

var _room_cache: Dictionary = {}
var _current_offset := Vector2i.ZERO


func _ready() -> void:
	_initialize_components()


func _initialize_components() -> void:
	rng = RandomNumberGenerator.new()
	difficulty_manager = DifficultyManagerScript.new(difficulty)
	platform_placer = PlatformPlacerScript.new(tilemap)
	chunk_generator = ChunkGeneratorScript.new(rng, difficulty_manager, platform_placer)
	entity_spawner = EntitySpawnerScript.new(rng, difficulty_manager, entities)
	path_validator = PathValidatorScript.new(platform_placer)


## Main generation entry point
func generate_level(p_seed: int = 0, p_difficulty: int = 5, p_length: int = 4) -> Node2D:
	# Initialize
	if p_seed == 0:
		p_seed = randi()
	seed_value = p_seed
	difficulty = p_difficulty
	level_length = p_length

	rng.seed = seed_value
	difficulty_manager.set_difficulty(difficulty)

	generation_started.emit()
	generation_progress.emit(0.0, "Starting generation...")

	# Clear any existing content
	_clear_level()

	# Select room sequence
	generation_progress.emit(0.1, "Selecting rooms...")
	var room_sequence := _select_room_sequence()

	# Place rooms
	generation_progress.emit(0.3, "Placing rooms...")
	var placed_rooms := _place_rooms(room_sequence)

	if placed_rooms.is_empty():
		generation_failed.emit("Failed to place rooms")
		return null

	# Generate connectors
	generation_progress.emit(0.5, "Generating connectors...")
	var connectors := _generate_connectors(placed_rooms)

	# Validate paths
	generation_progress.emit(0.7, "Validating paths...")
	var validation: Dictionary = path_validator.validate_level(placed_rooms, connectors)

	if not validation.valid:
		push_warning("Level validation issues: " + str(validation.issues))
		# Try to fix by adding more platforms
		_add_safety_platforms(placed_rooms, connectors)

	# Spawn entities
	generation_progress.emit(0.85, "Spawning entities...")
	_spawn_entities(placed_rooms, connectors)

	generation_progress.emit(1.0, "Complete!")
	generation_completed.emit(self)

	return self


## Clears all generated content
func _clear_level() -> void:
	tilemap.clear()
	_current_offset = Vector2i.ZERO

	for child in entities.get_children():
		child.queue_free()

	for child in rooms_container.get_children():
		child.queue_free()


## Selects which room types to use based on difficulty and length
func _select_room_sequence() -> Array[String]:
	var sequence: Array[String] = ["start"]  # Always start with start room

	# Remaining rooms
	var remaining := level_length - 1
	var shop_placed := false

	for i in range(remaining):
		var roll := rng.randf()

		# Guarantee shop room once per level
		if not shop_placed and i == remaining - 1:
			sequence.append("shop")
			shop_placed = true
			continue

		# Random room type weighted by difficulty
		if roll < 0.3:
			# Shop room (30% chance, but only once)
			if not shop_placed:
				sequence.append("shop")
				shop_placed = true
			else:
				sequence.append("platforming")
		elif roll < 0.6:
			sequence.append("platforming")
		else:
			sequence.append("combat")

	return sequence


## Places rooms in sequence with spacing
func _place_rooms(sequence: Array[String]) -> Array[Dictionary]:
	var placed: Array[Dictionary] = []

	for room_type in sequence:
		var template_path: String = ROOM_TEMPLATES.get(room_type, ROOM_TEMPLATES.start)
		var room_data := _load_and_place_room(template_path)

		if room_data.is_empty():
			push_error("Failed to load room: " + template_path)
			continue

		room_data.type = room_type
		placed.append(room_data)

		# Update offset for next room
		var room_width: int = room_data.get("width", 20)
		_current_offset.x += room_width + ROOM_SPACING

	return placed


## Loads a room template and places it at current offset
func _load_and_place_room(template_path: String) -> Dictionary:
	var scene: PackedScene

	if template_path in _room_cache:
		scene = _room_cache[template_path]
	else:
		if not ResourceLoader.exists(template_path):
			push_warning("Room template not found: " + template_path)
			return {}
		scene = load(template_path)
		_room_cache[template_path] = scene

	var instance: Node2D = scene.instantiate()
	rooms_container.add_child(instance)

	# Position the room
	instance.position = Vector2(_current_offset.x * TILE_SIZE, _current_offset.y * TILE_SIZE)

	# Extract metadata
	var room_data := {
		"instance": instance,
		"offset": _current_offset,
		"width": instance.get_meta(META_WIDTH, 20),
		"height": instance.get_meta(META_HEIGHT, 12),
		"entry": _current_offset + instance.get_meta(META_ENTRY, Vector2i(1, 10)),
		"exit": _current_offset + instance.get_meta(META_EXIT, Vector2i(18, 10)),
		"spawn_zones": instance.get_meta(META_SPAWN_ZONES, [])
	}

	return room_data


## Generates platform connectors between rooms
func _generate_connectors(rooms: Array[Dictionary]) -> Array[Array]:
	var all_connectors: Array[Array] = []

	for i in range(rooms.size() - 1):
		var current_room: Dictionary = rooms[i]
		var next_room: Dictionary = rooms[i + 1]

		var entry: Vector2i = current_room.exit
		var exit: Vector2i = next_room.entry

		var platforms: Array[Dictionary] = chunk_generator.generate_connector(entry, exit, ROOM_SPACING)
		chunk_generator.place_platforms(platforms)

		all_connectors.append(platforms)

	return all_connectors


## Adds safety platforms if validation fails
func _add_safety_platforms(rooms: Array[Dictionary], connectors: Array[Array]) -> void:
	for i in range(rooms.size() - 1):
		var current: Dictionary = rooms[i]
		var next_room: Dictionary = rooms[i + 1]

		# Add a bridge platform if connector is empty or invalid
		if i >= connectors.size() or connectors[i].is_empty():
			var mid_x := (current.exit.x + next_room.entry.x) / 2
			var mid_y := (current.exit.y + next_room.entry.y) / 2

			platform_placer.place_platform(mid_x - 2, mid_y, 5)


## Spawns enemies and collectibles
func _spawn_entities(rooms: Array[Dictionary], connectors: Array[Array]) -> void:
	for room in rooms:
		var room_type: String = room.get("type", "")
		var spawn_zones: Array = room.get("spawn_zones", [])

		# Convert spawn zones to expected format
		var zones: Array[Dictionary] = []
		for zone in spawn_zones:
			if zone is Vector2:
				var world_zone: Vector2 = room.instance.position + zone * TILE_SIZE
				zones.append({"pos": world_zone, "type": EntitySpawnerScript.ZoneType.GROUND})

		# Spawn enemies in combat rooms
		if room_type == "combat":
			entity_spawner.spawn_enemies(zones, 3)

		# Spawn collectibles in platforming rooms
		if room_type == "platforming":
			for zone in zones:
				entity_spawner._spawn_scene(DifficultyManagerScript.COLLECTIBLE_SCENES.gold, zone.pos)

	# Spawn collectibles on connectors
	for connector in connectors:
		var platforms: Array[Dictionary] = []
		for p in connector:
			if p is Dictionary:
				platforms.append(p)
		entity_spawner.spawn_collectibles_on_platforms(platforms)


## Gets the player spawn position
func get_player_spawn() -> Vector2:
	if rooms_container.get_child_count() > 0:
		var first_room: Node2D = rooms_container.get_child(0)
		var entry: Vector2i = first_room.get_meta(META_ENTRY, Vector2i(2, 10))
		return first_room.position + Vector2(entry.x * TILE_SIZE, entry.y * TILE_SIZE - TILE_SIZE)
	return Vector2(32, 128)


## Regenerates with new seed
func regenerate() -> Node2D:
	return generate_level(0, difficulty, level_length)


## Regenerates with same seed (for testing)
func regenerate_same_seed() -> Node2D:
	return generate_level(seed_value, difficulty, level_length)
