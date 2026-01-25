extends Node2D
class_name StandaloneGenerator

## Simplified level generator that creates platforms and walls directly.
## Use this for quick procedural level generation without room templates.

const DifficultyManagerScript = preload("res://levels/generator/difficulty_manager.gd")
const PlatformPlacerScript = preload("res://levels/generator/platform_placer.gd")

signal generation_completed

@export var seed_value: int = 0
@export var difficulty: int = 5
@export var level_width: int = 60  # Width in tiles
@export var level_height: int = 20  # Height in tiles

const TILE_SIZE := 16

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var entities: Node2D = $Entities

var rng: RandomNumberGenerator
var difficulty_manager
var platform_placer


func _ready() -> void:
	rng = RandomNumberGenerator.new()
	difficulty_manager = DifficultyManagerScript.new(difficulty)
	platform_placer = PlatformPlacerScript.new(tilemap)


## Generate a complete level with floor, platforms, and walls
func generate(p_seed: int = 0, p_difficulty: int = 5) -> void:
	if p_seed == 0:
		p_seed = randi()
	seed_value = p_seed
	difficulty = p_difficulty

	rng.seed = seed_value
	difficulty_manager.set_difficulty(difficulty)

	# Clear existing level
	_clear()

	# Generate level structure
	_generate_floor()
	_generate_walls()
	_generate_platforms()
	_generate_gaps()
	_spawn_collectibles()
	_spawn_enemies()

	generation_completed.emit()


func _clear() -> void:
	tilemap.clear()
	for child in entities.get_children():
		child.queue_free()


func _generate_floor() -> void:
	# Create ground floor
	var floor_y := level_height - 2
	for x in range(level_width):
		platform_placer.place_platform(x, floor_y, 1)
		# Add some depth below floor
		platform_placer.place_platform(x, floor_y + 1, 1)


func _generate_walls() -> void:
	# Left wall
	for y in range(level_height):
		platform_placer.place_platform(0, y, 1)

	# Right wall
	for y in range(level_height):
		platform_placer.place_platform(level_width - 1, y, 1)


func _generate_platforms() -> void:
	var floor_y := level_height - 2
	var max_gap: int = difficulty_manager.get_max_gap_tiles()
	var width_range: Vector2i = difficulty_manager.get_platform_width_range()

	# Generate 3-5 layers of platforms
	var num_layers := rng.randi_range(3, 5)
	var layer_spacing := (floor_y - 4) / num_layers

	for layer in range(num_layers):
		var y := floor_y - (layer + 1) * layer_spacing
		var x := 2  # Start after left wall

		while x < level_width - 3:
			# Random gap
			var gap := rng.randi_range(2, max_gap + 2)
			x += gap

			if x >= level_width - 3:
				break

			# Random platform width
			var width := rng.randi_range(width_range.x, width_range.y)
			width = mini(width, level_width - x - 2)

			if width >= 2:
				platform_placer.place_platform(x, y, width)

			x += width


func _generate_gaps() -> void:
	var floor_y := level_height - 2
	var max_gap: int = difficulty_manager.get_max_gap_tiles()
	var num_gaps := rng.randi_range(1, 3)

	for i in range(num_gaps):
		var gap_x := rng.randi_range(5, level_width - 10)
		var gap_width := rng.randi_range(2, max_gap)

		# Remove floor tiles to create gap
		for x in range(gap_x, gap_x + gap_width):
			tilemap.erase_cell(Vector2i(x, floor_y))
			tilemap.erase_cell(Vector2i(x, floor_y + 1))


func _spawn_collectibles() -> void:
	var density: float = difficulty_manager.get_collectible_density()
	var num_coins := roundi(10 * density)
	var coin_scene: PackedScene = preload("res://collectibles/gold/gold_coin.tscn")

	for i in range(num_coins):
		var x := rng.randi_range(2, level_width - 3)
		var y := rng.randi_range(2, level_height - 4)

		var coin: Node2D = coin_scene.instantiate()
		coin.position = Vector2(x * TILE_SIZE + 8, y * TILE_SIZE + 8)
		entities.add_child(coin)


func _spawn_enemies() -> void:
	var floor_y := level_height - 2
	var enemy_mult: float = difficulty_manager.get_enemy_count_multiplier()
	var num_enemies := roundi(3 * enemy_mult)

	for i in range(num_enemies):
		var enemy_path: String = difficulty_manager.select_random_enemy(rng)
		if not ResourceLoader.exists(enemy_path):
			continue

		var enemy_scene: PackedScene = load(enemy_path)
		var enemy: Node2D = enemy_scene.instantiate()

		var x := rng.randi_range(5, level_width - 6)
		enemy.position = Vector2(x * TILE_SIZE, (floor_y - 1) * TILE_SIZE)
		entities.add_child(enemy)


## Get a safe spawn position for the player
func get_player_spawn() -> Vector2:
	var floor_y := level_height - 2
	return Vector2(3 * TILE_SIZE, (floor_y - 2) * TILE_SIZE)
