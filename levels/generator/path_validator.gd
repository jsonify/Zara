extends RefCounted
class_name PathValidator

## Validates that generated levels are completable.
## Uses flood-fill algorithm to check reachability.

const PlatformPlacerScript = preload("res://levels/generator/platform_placer.gd")

const TILE_SIZE := 16

# Player jump constraints (must match ChunkGenerator)
const MAX_JUMP_HEIGHT_TILES := 6
const MAX_JUMP_DISTANCE_TILES := 5

var platform_placer  # PlatformPlacer


func _init(p_placer) -> void:
	platform_placer = p_placer


## Validates that the exit is reachable from the entry point
## Returns true if path exists
func validate_path(entry: Vector2i, exit: Vector2i, platforms: Array[Dictionary]) -> bool:
	if platforms.is_empty():
		# Check if direct path is possible
		return _can_reach_directly(entry, exit)

	# Build graph of reachable platforms
	var reachable := _flood_fill_platforms(entry, platforms)

	# Check if exit platform is reachable
	for platform in platforms:
		var pos: Vector2i = platform.pos
		var width: int = platform.width

		# Check if this platform contains or is near the exit
		if pos.x <= exit.x and pos.x + width > exit.x:
			if abs(pos.y - exit.y) <= MAX_JUMP_HEIGHT_TILES:
				# This platform could lead to exit
				if _is_platform_in_set(platform, reachable):
					return true

	# Also check if we can reach exit directly from any reachable platform
	for platform in reachable:
		var end_x: int = platform.pos.x + platform.width
		if _can_reach_directly(Vector2i(end_x, platform.pos.y), exit):
			return true

	return false


## Flood-fill from entry to find all reachable platforms
func _flood_fill_platforms(entry: Vector2i, platforms: Array[Dictionary]) -> Array[Dictionary]:
	var reachable: Array[Dictionary] = []
	var to_check: Array[Dictionary] = []

	# Find platforms reachable from entry
	for platform in platforms:
		if _can_reach_from_point(entry, platform):
			to_check.append(platform)
			reachable.append(platform)

	# BFS to find all connected platforms
	while not to_check.is_empty():
		var current: Dictionary = to_check.pop_front()
		var current_end := Vector2i(current.pos.x + current.width, current.pos.y)

		for platform in platforms:
			if _is_platform_in_set(platform, reachable):
				continue

			# Check if reachable from current platform
			if _can_reach_from_point(current_end, platform) or _can_reach_from_point(current.pos, platform):
				to_check.append(platform)
				reachable.append(platform)

	return reachable


## Checks if a platform can be reached from a point
func _can_reach_from_point(point: Vector2i, platform: Dictionary) -> bool:
	var pos: Vector2i = platform.pos
	var width: int = platform.width

	# Check if any part of the platform is reachable
	for offset in range(width):
		var target := Vector2i(pos.x + offset, pos.y)
		if _can_reach_directly(point, target):
			return true

	return false


## Checks if target can be reached directly from source (single jump)
func _can_reach_directly(from: Vector2i, to: Vector2i) -> bool:
	var dx := abs(to.x - from.x)
	var dy := to.y - from.y  # Positive = going down

	# Falling - can fall any distance within horizontal range
	if dy > 0:
		return dx <= MAX_JUMP_DISTANCE_TILES + dy / 2  # Can drift further while falling

	# Jumping up
	if dy < 0:
		# Must be within jump height and horizontal distance
		return abs(dy) <= MAX_JUMP_HEIGHT_TILES and dx <= MAX_JUMP_DISTANCE_TILES

	# Same level
	return dx <= MAX_JUMP_DISTANCE_TILES


## Helper to check if platform is in a set
func _is_platform_in_set(platform: Dictionary, set: Array[Dictionary]) -> bool:
	for p in set:
		if p.pos == platform.pos and p.width == platform.width:
			return true
	return false


## Validates a complete level structure
## Returns {valid: bool, issues: Array[String]}
func validate_level(rooms: Array[Dictionary], connectors: Array[Array]) -> Dictionary:
	var result := {
		"valid": true,
		"issues": [] as Array[String]
	}

	if rooms.is_empty():
		result.valid = false
		result.issues.append("No rooms in level")
		return result

	# Validate each room has entry and exit
	for i in range(rooms.size()):
		var room: Dictionary = rooms[i]
		if not room.has("entry") or not room.has("exit"):
			result.valid = false
			result.issues.append("Room %d missing entry or exit point" % i)

	# Validate connectors between rooms
	for i in range(connectors.size()):
		if i >= rooms.size() - 1:
			break

		var current_room: Dictionary = rooms[i]
		var next_room: Dictionary = rooms[i + 1]
		var connector: Array = connectors[i]

		# Convert connector to platform dictionaries
		var platforms: Array[Dictionary] = []
		for p in connector:
			if p is Dictionary:
				platforms.append(p)

		if not validate_path(current_room.exit, next_room.entry, platforms):
			result.valid = false
			result.issues.append("Cannot reach room %d from room %d" % [i + 1, i])

	return result


## Finds gaps in a level that might trap the player
func find_death_pits(bounds: Rect2i) -> Array[Vector2i]:
	var pits: Array[Vector2i] = []

	for x in range(bounds.position.x, bounds.position.x + bounds.size.x):
		var has_floor := false
		for y in range(bounds.position.y, bounds.position.y + bounds.size.y):
			if platform_placer.is_solid(Vector2i(x, y)):
				has_floor = true
				break

		if not has_floor:
			pits.append(Vector2i(x, bounds.position.y + bounds.size.y))

	return pits
