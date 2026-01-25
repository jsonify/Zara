extends RefCounted
class_name EntitySpawner

## Handles spawning of enemies and collectibles in generated levels.
## Uses DifficultyManager to determine spawn rates and types.

const DifficultyManagerScript = preload("res://levels/generator/difficulty_manager.gd")

const TILE_SIZE := 16

# Spawn zone types
enum ZoneType {
	GROUND,  # On floor, for walking enemies
	PLATFORM,  # On platforms
	AIR  # Floating collectibles
}

var rng: RandomNumberGenerator
var difficulty_manager  # DifficultyManager
var parent_node: Node2D

# Cached scene resources
var _enemy_cache: Dictionary = {}
var _collectible_cache: Dictionary = {}


func _init(p_rng: RandomNumberGenerator, p_difficulty, p_parent: Node2D) -> void:
	rng = p_rng
	difficulty_manager = p_difficulty
	parent_node = p_parent


## Spawns enemies in the given spawn zones
## zones: Array of {pos: Vector2, type: ZoneType}
func spawn_enemies(zones: Array[Dictionary], base_count: int = 3) -> Array[Node2D]:
	var spawned: Array[Node2D] = []
	var count := roundi(base_count * difficulty_manager.get_enemy_count_multiplier())
	count = mini(count, zones.size())

	# Shuffle zones for random placement
	var available_zones := zones.duplicate()
	_shuffle_array(available_zones)

	for i in range(count):
		if i >= available_zones.size():
			break

		var zone: Dictionary = available_zones[i]
		var enemy_path: String = difficulty_manager.select_random_enemy(rng)
		var enemy := _spawn_scene(enemy_path, zone.pos)
		if enemy:
			spawned.append(enemy)

	return spawned


## Spawns collectibles along a path
## path: Array of Vector2 positions
func spawn_collectibles_on_path(path: Array[Vector2], spacing: float = 24.0) -> Array[Node2D]:
	var spawned: Array[Node2D] = []
	var density: float = difficulty_manager.get_collectible_density()

	# Calculate positions along path
	var accumulated_dist := 0.0
	var adjusted_spacing := spacing / density

	for i in range(1, path.size()):
		var from := path[i - 1]
		var to := path[i]
		var segment_length := from.distance_to(to)
		var direction := (to - from).normalized()

		while accumulated_dist < segment_length:
			var spawn_pos := from + direction * accumulated_dist

			# Randomly choose collectible type
			var collectible_path: String
			var roll := rng.randf()
			if roll < 0.7:
				collectible_path = DifficultyManagerScript.COLLECTIBLE_SCENES.gold
			elif roll < 0.9:
				collectible_path = DifficultyManagerScript.COLLECTIBLE_SCENES.fuel_small
			else:
				collectible_path = DifficultyManagerScript.COLLECTIBLE_SCENES.fuel_large

			var collectible := _spawn_scene(collectible_path, spawn_pos)
			if collectible:
				spawned.append(collectible)

			accumulated_dist += adjusted_spacing

		accumulated_dist -= segment_length

	return spawned


## Spawns collectibles on platforms
func spawn_collectibles_on_platforms(platforms: Array[Dictionary]) -> Array[Node2D]:
	var spawned: Array[Node2D] = []
	var density: float = difficulty_manager.get_collectible_density()

	for platform in platforms:
		var pos: Vector2i = platform.pos
		var width: int = platform.width

		# Chance to spawn on this platform
		if rng.randf() > 0.5 * density:
			continue

		# Spawn 1-3 collectibles on platform
		var count := rng.randi_range(1, ceili(3 * density))
		for i in range(count):
			var offset_x := rng.randi_range(0, width - 1)
			var world_pos := Vector2(
				(pos.x + offset_x) * TILE_SIZE + TILE_SIZE / 2.0,
				pos.y * TILE_SIZE - TILE_SIZE / 2.0  # Above the platform
			)

			var collectible := _spawn_scene(DifficultyManagerScript.COLLECTIBLE_SCENES.gold, world_pos)
			if collectible:
				spawned.append(collectible)

	return spawned


## Spawns a shop station at the given position
func spawn_shop(pos: Vector2) -> Node2D:
	return _spawn_scene("res://collectibles/shop/shop_station.tscn", pos)


## Creates spawn zones from platform data
func create_spawn_zones_from_platforms(platforms: Array[Dictionary]) -> Array[Dictionary]:
	var zones: Array[Dictionary] = []

	for platform in platforms:
		var pos: Vector2i = platform.pos
		var width: int = platform.width

		# Create spawn zone at center of platform
		var center_x := pos.x + width / 2
		var world_pos := Vector2(
			center_x * TILE_SIZE + TILE_SIZE / 2.0,
			pos.y * TILE_SIZE - TILE_SIZE  # One tile above platform
		)

		zones.append({
			"pos": world_pos,
			"type": ZoneType.PLATFORM
		})

	return zones


## Helper to spawn a scene at a position
func _spawn_scene(scene_path: String, pos: Vector2) -> Node2D:
	var scene: PackedScene

	# Check cache first
	if scene_path in _enemy_cache:
		scene = _enemy_cache[scene_path]
	elif scene_path in _collectible_cache:
		scene = _collectible_cache[scene_path]
	else:
		if not ResourceLoader.exists(scene_path):
			push_warning("EntitySpawner: Scene not found: " + scene_path)
			return null

		scene = load(scene_path)
		if scene_path.contains("enemies"):
			_enemy_cache[scene_path] = scene
		else:
			_collectible_cache[scene_path] = scene

	if not scene:
		return null

	var instance: Node2D = scene.instantiate()
	instance.global_position = pos
	parent_node.add_child(instance)

	return instance


## Shuffles an array in place using Fisher-Yates
func _shuffle_array(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp
