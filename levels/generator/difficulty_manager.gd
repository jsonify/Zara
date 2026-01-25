extends RefCounted
class_name DifficultyManager

## Manages difficulty scaling for procedural level generation.
## Controls enemy mix, platform gaps, and collectible density.

# Difficulty range: 1 (easiest) to 10 (hardest)
const MIN_DIFFICULTY := 1
const MAX_DIFFICULTY := 10

# Enemy scene paths by category
const ENEMY_SCENES := {
	"easy": [
		"res://entities/enemies/flower/flowery.tscn",
		"res://entities/enemies/dummy_test.tscn"
	],
	"medium": [
		"res://entities/enemies/spidey.tscn",
		"res://entities/enemies/blinding_spider.tscn"
	],
	"hard": [
		"res://entities/enemies/enemy.tscn"  # EnemyX - chasing enemy
	]
}

# Collectible scene paths
const COLLECTIBLE_SCENES := {
	"gold": "res://collectibles/gold/gold_coin.tscn",
	"fuel_small": "res://collectibles/fuel/fuel-1sec.tscn",
	"fuel_large": "res://collectibles/fuel/fuel-5sec.tscn"
}

var difficulty: int = 5


func _init(initial_difficulty: int = 5) -> void:
	set_difficulty(initial_difficulty)


func set_difficulty(value: int) -> void:
	difficulty = clampi(value, MIN_DIFFICULTY, MAX_DIFFICULTY)


## Returns the maximum gap size (in tiles) for platforms at current difficulty
func get_max_gap_tiles() -> int:
	if difficulty <= 2:
		return 2
	elif difficulty <= 4:
		return 3
	elif difficulty <= 6:
		return 4
	elif difficulty <= 8:
		return 5
	else:
		return 6


## Returns enemy spawn weights based on difficulty
## Higher weight = more likely to spawn
func get_enemy_weights() -> Dictionary:
	var weights := {}

	# Easy enemies always available, but less common at higher difficulty
	for enemy in ENEMY_SCENES.easy:
		weights[enemy] = maxi(1, 10 - difficulty)

	# Medium enemies unlock at difficulty 3
	if difficulty >= 3:
		for enemy in ENEMY_SCENES.medium:
			weights[enemy] = mini(difficulty - 2, 5)

	# Hard enemies unlock at difficulty 6
	if difficulty >= 6:
		for enemy in ENEMY_SCENES.hard:
			weights[enemy] = mini(difficulty - 5, 5)

	return weights


## Returns list of available enemy scenes for current difficulty
func get_available_enemies() -> Array[String]:
	var enemies: Array[String] = []
	enemies.append_array(ENEMY_SCENES.easy)

	if difficulty >= 3:
		enemies.append_array(ENEMY_SCENES.medium)

	if difficulty >= 6:
		enemies.append_array(ENEMY_SCENES.hard)

	return enemies


## Returns collectible density multiplier (1.0 = normal)
## Lower difficulty = more collectibles
func get_collectible_density() -> float:
	# Range: 1.5 at difficulty 1, down to 0.5 at difficulty 10
	return 1.5 - (difficulty - 1) * 0.11


## Returns enemy count multiplier for a room
func get_enemy_count_multiplier() -> float:
	# Range: 0.5 at difficulty 1, up to 1.5 at difficulty 10
	return 0.5 + (difficulty - 1) * 0.11


## Returns the chance (0-1) of spawning a health pickup in a room
func get_health_pickup_chance() -> float:
	# More health pickups at lower difficulty
	return 0.5 - (difficulty - 1) * 0.04


## Returns platform width range (min, max) in tiles
func get_platform_width_range() -> Vector2i:
	if difficulty <= 3:
		return Vector2i(4, 8)
	elif difficulty <= 6:
		return Vector2i(3, 6)
	else:
		return Vector2i(2, 5)


## Selects a random enemy scene based on weights
func select_random_enemy(rng: RandomNumberGenerator) -> String:
	var weights := get_enemy_weights()
	if weights.is_empty():
		return ENEMY_SCENES.easy[0]

	var total_weight := 0.0
	for weight in weights.values():
		total_weight += weight

	var roll := rng.randf() * total_weight
	var current := 0.0

	for enemy in weights:
		current += weights[enemy]
		if roll <= current:
			return enemy

	return weights.keys()[0]
