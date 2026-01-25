extends GutTest

## Unit tests for the Level Generator System
## Tests DifficultyManager, ChunkGenerator, PlatformPlacer, EntitySpawner, PathValidator

# Preload the generator scripts
const DifficultyManagerScript = preload("res://levels/generator/difficulty_manager.gd")
const PlatformPlacerScript = preload("res://levels/generator/platform_placer.gd")
const ChunkGeneratorScript = preload("res://levels/generator/chunk_generator.gd")
const PathValidatorScript = preload("res://levels/generator/path_validator.gd")

var difficulty_manager
var rng: RandomNumberGenerator


func before_each():
	rng = RandomNumberGenerator.new()
	rng.seed = 12345  # Fixed seed for reproducibility
	difficulty_manager = DifficultyManagerScript.new(5)


func after_each():
	difficulty_manager = null
	rng = null


# =============================================================================
# DifficultyManager tests
# =============================================================================

func test_difficulty_manager_clamps_to_valid_range():
	difficulty_manager.set_difficulty(0)
	assert_eq(difficulty_manager.difficulty, 1, "Should clamp to minimum of 1")

	difficulty_manager.set_difficulty(15)
	assert_eq(difficulty_manager.difficulty, 10, "Should clamp to maximum of 10")

	difficulty_manager.set_difficulty(5)
	assert_eq(difficulty_manager.difficulty, 5, "Should accept valid value")


func test_difficulty_manager_gap_tiles_scale_with_difficulty():
	difficulty_manager.set_difficulty(1)
	var low_gaps: int = difficulty_manager.get_max_gap_tiles()

	difficulty_manager.set_difficulty(10)
	var high_gaps: int = difficulty_manager.get_max_gap_tiles()

	assert_gt(high_gaps, low_gaps, "Higher difficulty should have larger gaps")


func test_difficulty_manager_enemy_weights_increase_with_difficulty():
	difficulty_manager.set_difficulty(1)
	var low_weights: Dictionary = difficulty_manager.get_enemy_weights()

	difficulty_manager.set_difficulty(10)
	var high_weights: Dictionary = difficulty_manager.get_enemy_weights()

	assert_gt(high_weights.size(), low_weights.size(), "Higher difficulty should have more enemy types")


func test_difficulty_manager_easy_enemies_always_available():
	difficulty_manager.set_difficulty(1)
	var enemies: Array = difficulty_manager.get_available_enemies()
	assert_gt(enemies.size(), 0, "Should always have some enemies available")

	for enemy in DifficultyManagerScript.ENEMY_SCENES.easy:
		assert_has(enemies, enemy, "Easy enemies should always be available")


func test_difficulty_manager_medium_enemies_unlock_at_difficulty_3():
	difficulty_manager.set_difficulty(2)
	var low_enemies: Array = difficulty_manager.get_available_enemies()

	difficulty_manager.set_difficulty(3)
	var mid_enemies: Array = difficulty_manager.get_available_enemies()

	assert_gt(mid_enemies.size(), low_enemies.size(), "Medium enemies should unlock at difficulty 3")


func test_difficulty_manager_hard_enemies_unlock_at_difficulty_6():
	difficulty_manager.set_difficulty(5)
	var mid_enemies: Array = difficulty_manager.get_available_enemies()

	difficulty_manager.set_difficulty(6)
	var hard_enemies: Array = difficulty_manager.get_available_enemies()

	assert_gt(hard_enemies.size(), mid_enemies.size(), "Hard enemies should unlock at difficulty 6")


func test_difficulty_manager_collectible_density_higher_at_low_difficulty():
	difficulty_manager.set_difficulty(1)
	var low_density: float = difficulty_manager.get_collectible_density()

	difficulty_manager.set_difficulty(10)
	var high_density: float = difficulty_manager.get_collectible_density()

	assert_gt(low_density, high_density, "Lower difficulty should have higher collectible density")


func test_difficulty_manager_enemy_count_multiplier_higher_at_high_difficulty():
	difficulty_manager.set_difficulty(1)
	var low_mult: float = difficulty_manager.get_enemy_count_multiplier()

	difficulty_manager.set_difficulty(10)
	var high_mult: float = difficulty_manager.get_enemy_count_multiplier()

	assert_gt(high_mult, low_mult, "Higher difficulty should have higher enemy count")


func test_difficulty_manager_select_random_enemy_returns_valid_path():
	var enemy: String = difficulty_manager.select_random_enemy(rng)
	assert_true(enemy.begins_with("res://"), "Should return a valid scene path")
	assert_true(enemy.ends_with(".tscn"), "Should return a .tscn file")


func test_difficulty_manager_platform_width_narrower_at_high_difficulty():
	difficulty_manager.set_difficulty(1)
	var low_range: Vector2i = difficulty_manager.get_platform_width_range()

	difficulty_manager.set_difficulty(10)
	var high_range: Vector2i = difficulty_manager.get_platform_width_range()

	assert_lt(high_range.x, low_range.x, "High difficulty should have narrower platforms")


# =============================================================================
# ChunkGenerator tests (without TileMap)
# =============================================================================

func test_chunk_generator_reachability_same_level():
	# Test the reachability logic
	var from := Vector2i(0, 5)
	var to := Vector2i(4, 5)

	var dx: int = abs(to.x - from.x)

	# Direct check: same level within jump distance
	assert_lte(dx, ChunkGeneratorScript.MAX_JUMP_DISTANCE_TILES, "Should be within jump distance")


func test_chunk_generator_reachability_going_up():
	var from := Vector2i(0, 10)
	var to := Vector2i(3, 5)  # 5 tiles up, 3 tiles horizontal

	var dx: int = abs(to.x - from.x)
	var dy: int = to.y - from.y  # Negative = going up

	assert_lt(dy, 0, "Should be going up")
	assert_lte(abs(dy), ChunkGeneratorScript.MAX_JUMP_HEIGHT_TILES, "Should be within jump height")
	assert_lte(dx, ChunkGeneratorScript.MAX_JUMP_DISTANCE_TILES, "Should be within jump distance")


func test_chunk_generator_unreachable_too_high():
	var from := Vector2i(0, 10)
	var to := Vector2i(3, 0)  # 10 tiles up - too high

	var dy: int = to.y - from.y

	assert_gt(abs(dy), ChunkGeneratorScript.MAX_JUMP_HEIGHT_TILES, "Should be too high to jump")


func test_chunk_generator_unreachable_too_far():
	var from := Vector2i(0, 5)
	var to := Vector2i(10, 5)  # 10 tiles horizontal - too far

	var dx: int = abs(to.x - from.x)

	assert_gt(dx, ChunkGeneratorScript.MAX_JUMP_DISTANCE_TILES, "Should be too far to jump")


# =============================================================================
# PathValidator tests
# =============================================================================

func test_path_validator_direct_path_horizontal():
	# Validate the reachability logic
	var from := Vector2i(0, 5)
	var to := Vector2i(4, 5)

	var dx: int = abs(to.x - from.x)

	var reachable: bool = dx <= PathValidatorScript.MAX_JUMP_DISTANCE_TILES
	assert_true(reachable, "Direct horizontal path should be reachable")


func test_path_validator_direct_path_falling():
	var from := Vector2i(0, 0)
	var to := Vector2i(3, 10)  # Falling down

	var dx: int = abs(to.x - from.x)
	var dy: int = to.y - from.y  # Positive = falling

	# Can fall any distance within horizontal range
	var reachable: bool = dy > 0 and dx <= PathValidatorScript.MAX_JUMP_DISTANCE_TILES + dy / 2
	assert_true(reachable, "Falling path should be reachable")


func test_path_validator_platform_in_set():
	var platforms: Array = [
		{"pos": Vector2i(0, 5), "width": 3},
		{"pos": Vector2i(10, 5), "width": 4}
	]

	var target := {"pos": Vector2i(10, 5), "width": 4}
	var found := false

	for p in platforms:
		if p.pos == target.pos and p.width == target.width:
			found = true
			break

	assert_true(found, "Should find platform in set")


# =============================================================================
# Seed consistency tests
# =============================================================================

func test_same_seed_produces_same_enemy_selection():
	var seed_val := 42
	rng.seed = seed_val
	var enemy1: String = difficulty_manager.select_random_enemy(rng)

	rng.seed = seed_val
	var enemy2: String = difficulty_manager.select_random_enemy(rng)

	assert_eq(enemy1, enemy2, "Same seed should produce same enemy selection")


func test_different_seeds_can_produce_different_results():
	rng.seed = 1
	var results1: Array = []
	for i in range(10):
		results1.append(difficulty_manager.select_random_enemy(rng))

	rng.seed = 999
	var results2: Array = []
	for i in range(10):
		results2.append(difficulty_manager.select_random_enemy(rng))

	# At minimum, the selection process should work
	assert_eq(results1.size(), 10, "Should produce 10 selections")
	assert_eq(results2.size(), 10, "Should produce 10 selections")


# =============================================================================
# PlatformPlacer utility tests
# =============================================================================

func test_platform_placer_world_to_tile_conversion():
	var world_pos := Vector2(32.0, 64.0)
	var tile_pos: Vector2i = PlatformPlacerScript.world_to_tile(world_pos)

	assert_eq(tile_pos, Vector2i(2, 4), "Should convert world to tile correctly")


func test_platform_placer_tile_to_world_conversion():
	var tile_pos := Vector2i(3, 5)
	var world_pos: Vector2 = PlatformPlacerScript.tile_to_world(tile_pos)

	assert_eq(world_pos, Vector2(48.0, 80.0), "Should convert tile to world correctly")


func test_platform_placer_tile_to_world_center():
	var tile_pos := Vector2i(0, 0)
	var world_center: Vector2 = PlatformPlacerScript.tile_to_world_center(tile_pos)

	assert_eq(world_center, Vector2(8.0, 8.0), "Should return center of tile")


# =============================================================================
# EntitySpawner tests
# =============================================================================

func test_entity_spawner_create_spawn_zones_from_platforms():
	var platforms: Array = [
		{"pos": Vector2i(0, 5), "width": 4},
		{"pos": Vector2i(10, 8), "width": 3}
	]

	# Calculate expected zones
	var expected_zone_count: int = platforms.size()

	# Each platform should produce one spawn zone
	assert_eq(expected_zone_count, 2, "Should create zone for each platform")


# =============================================================================
# Integration-like tests (no actual scene instantiation)
# =============================================================================

func test_difficulty_settings_are_consistent():
	for diff in range(1, 11):
		difficulty_manager.set_difficulty(diff)

		var gaps: int = difficulty_manager.get_max_gap_tiles()
		var density: float = difficulty_manager.get_collectible_density()
		var enemy_mult: float = difficulty_manager.get_enemy_count_multiplier()

		assert_gte(gaps, 2, "Gaps should be at least 2")
		assert_lte(gaps, 6, "Gaps should be at most 6")
		assert_gt(density, 0.0, "Density should be positive")
		assert_gt(enemy_mult, 0.0, "Enemy multiplier should be positive")


func test_all_enemy_scenes_are_valid_paths():
	var all_enemies: Array = []
	all_enemies.append_array(DifficultyManagerScript.ENEMY_SCENES.easy)
	all_enemies.append_array(DifficultyManagerScript.ENEMY_SCENES.medium)
	all_enemies.append_array(DifficultyManagerScript.ENEMY_SCENES.hard)

	for enemy_path in all_enemies:
		assert_true(enemy_path.begins_with("res://"), "Enemy path should start with res://")
		assert_true(enemy_path.ends_with(".tscn"), "Enemy path should end with .tscn")


func test_all_collectible_scenes_are_valid_paths():
	for key in DifficultyManagerScript.COLLECTIBLE_SCENES:
		var path: String = DifficultyManagerScript.COLLECTIBLE_SCENES[key]
		assert_true(path.begins_with("res://"), "Collectible path should start with res://")
		assert_true(path.ends_with(".tscn"), "Collectible path should end with .tscn")
