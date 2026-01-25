extends RefCounted
class_name ChunkGenerator

## Generates procedural platform connectors between rooms.
## Ensures all platforms are reachable based on player physics.

const DifficultyManagerScript = preload("res://levels/generator/difficulty_manager.gd")
const PlatformPlacerScript = preload("res://levels/generator/platform_placer.gd")

# Player physics constraints (from player.gd)
const JUMP_VELOCITY := 300.0  # Absolute value
const GRAVITY := 980.0  # Default Godot gravity
const MAX_SPEED := 75.0

# Calculated jump constraints (in tiles, conservative estimates)
const MAX_JUMP_HEIGHT_TILES := 6  # ~96 pixels at jump apex
const MAX_JUMP_DISTANCE_TILES := 5  # Horizontal distance while jumping
const MIN_PLATFORM_WIDTH := 2

var rng: RandomNumberGenerator
var difficulty_manager  # DifficultyManager
var platform_placer  # PlatformPlacer


func _init(p_rng: RandomNumberGenerator, p_difficulty, p_placer) -> void:
	rng = p_rng
	difficulty_manager = p_difficulty
	platform_placer = p_placer


## Generates platforms connecting two points (entry and exit)
## Returns array of platform positions [{pos: Vector2i, width: int}]
func generate_connector(entry: Vector2i, exit: Vector2i, width_tiles: int) -> Array[Dictionary]:
	var platforms: Array[Dictionary] = []

	var height_diff := exit.y - entry.y
	var horizontal_dist := exit.x - entry.x

	# Generate stepping platforms between entry and exit
	if abs(height_diff) <= MAX_JUMP_HEIGHT_TILES and horizontal_dist <= MAX_JUMP_DISTANCE_TILES:
		# Direct jump possible - no intermediate platforms needed
		return platforms

	# Need intermediate platforms
	var current_pos := entry
	var max_gap: int = difficulty_manager.get_max_gap_tiles()
	var width_range: Vector2i = difficulty_manager.get_platform_width_range()

	while current_pos.x < exit.x - MAX_JUMP_DISTANCE_TILES:
		# Calculate next platform position
		var gap := rng.randi_range(2, max_gap)
		var next_x := current_pos.x + gap

		# Height variation (must be jumpable)
		var max_height_change := mini(MAX_JUMP_HEIGHT_TILES - 1, 3)
		var height_change := rng.randi_range(-max_height_change, max_height_change)
		var next_y := clampi(current_pos.y + height_change,
			mini(entry.y, exit.y) - MAX_JUMP_HEIGHT_TILES,
			maxi(entry.y, exit.y) + MAX_JUMP_HEIGHT_TILES)

		# Platform width
		var plat_width := rng.randi_range(width_range.x, width_range.y)
		plat_width = mini(plat_width, exit.x - next_x)

		if plat_width >= MIN_PLATFORM_WIDTH:
			platforms.append({
				"pos": Vector2i(next_x, next_y),
				"width": plat_width
			})
			current_pos = Vector2i(next_x + plat_width, next_y)
		else:
			break

	return platforms


## Generates a vertical shaft with platforms for climbing up or down
func generate_vertical_shaft(start: Vector2i, end_y: int, width: int) -> Array[Dictionary]:
	var platforms: Array[Dictionary] = []
	var going_up := end_y < start.y
	var step := -3 if going_up else 3  # Step size in tiles

	var current_y := start.y
	var platform_x := start.x
	var alternate := false

	while (going_up and current_y > end_y) or (not going_up and current_y < end_y):
		current_y += step

		# Alternate platform placement for zigzag pattern
		if alternate:
			platform_x = start.x
		else:
			platform_x = start.x + width - 3

		var plat_width := rng.randi_range(2, 4)
		platforms.append({
			"pos": Vector2i(platform_x, current_y),
			"width": plat_width
		})

		alternate = not alternate

	return platforms


## Places all generated platforms on the tilemap
func place_platforms(platforms: Array[Dictionary]) -> void:
	for platform in platforms:
		platform_placer.place_platform(platform.pos.x, platform.pos.y, platform.width)


## Generates a floor section with optional gaps
func generate_floor_with_gaps(start_x: int, end_x: int, y: int, max_gaps: int = 2) -> Array[Dictionary]:
	var platforms: Array[Dictionary] = []
	var current_x := start_x
	var max_gap: int = difficulty_manager.get_max_gap_tiles()
	var gaps_placed := 0

	while current_x < end_x:
		# Decide platform length
		var remaining := end_x - current_x
		var min_length := 3
		var max_length := mini(10, remaining)

		if max_length < min_length:
			# Just fill the rest
			platforms.append({
				"pos": Vector2i(current_x, y),
				"width": remaining
			})
			break

		var length := rng.randi_range(min_length, max_length)
		platforms.append({
			"pos": Vector2i(current_x, y),
			"width": length
		})

		current_x += length

		# Maybe add a gap
		if gaps_placed < max_gaps and current_x < end_x - 5:
			var should_gap := rng.randf() < 0.4
			if should_gap:
				var gap := rng.randi_range(2, max_gap)
				current_x += gap
				gaps_placed += 1

	return platforms


## Validates that a platform is reachable from another
func is_reachable(from: Vector2i, to: Vector2i) -> bool:
	var dx := abs(to.x - from.x)
	var dy := to.y - from.y  # Positive = going down

	# Can always fall down within horizontal jump range
	if dy > 0 and dx <= MAX_JUMP_DISTANCE_TILES:
		return true

	# Jumping up - check both height and distance
	if dy < 0:
		return abs(dy) <= MAX_JUMP_HEIGHT_TILES and dx <= MAX_JUMP_DISTANCE_TILES

	# Same level - just horizontal distance
	return dx <= MAX_JUMP_DISTANCE_TILES
