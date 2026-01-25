extends RefCounted
class_name PlatformPlacer

## Handles TileMap manipulation for platform placement.
## Provides methods to place platforms, floors, and walls.

# Tile size in pixels (from world.tres)
const TILE_SIZE := 16

# TileSet source and tile coordinates for different platform types
# These match the tiles in world.tres
const TILESET_SOURCE_ID := 0

# Tile atlas coordinates for platform tiles
const TILE_GROUND := Vector2i(5, 1)  # Solid ground tile with physics
const TILE_GROUND_LEFT := Vector2i(1, 3)  # Left edge
const TILE_GROUND_RIGHT := Vector2i(3, 5)  # Right edge
const TILE_GROUND_MIDDLE := Vector2i(1, 5)  # Middle section

var tilemap: TileMapLayer


func _init(target_tilemap: TileMapLayer) -> void:
	tilemap = target_tilemap


## Places a horizontal platform at the given tile position
func place_platform(start_x: int, y: int, width: int) -> void:
	for x in range(start_x, start_x + width):
		tilemap.set_cell(Vector2i(x, y), TILESET_SOURCE_ID, TILE_GROUND)


## Places a platform with left and right edge tiles
func place_platform_with_edges(start_x: int, y: int, width: int) -> void:
	if width <= 0:
		return

	if width == 1:
		tilemap.set_cell(Vector2i(start_x, y), TILESET_SOURCE_ID, TILE_GROUND)
		return

	# Left edge
	tilemap.set_cell(Vector2i(start_x, y), TILESET_SOURCE_ID, TILE_GROUND_LEFT)

	# Middle tiles
	for x in range(start_x + 1, start_x + width - 1):
		tilemap.set_cell(Vector2i(x, y), TILESET_SOURCE_ID, TILE_GROUND_MIDDLE)

	# Right edge
	tilemap.set_cell(Vector2i(start_x + width - 1, y), TILESET_SOURCE_ID, TILE_GROUND_RIGHT)


## Places a vertical wall at the given tile position
func place_wall(x: int, start_y: int, height: int) -> void:
	for y in range(start_y, start_y + height):
		tilemap.set_cell(Vector2i(x, y), TILESET_SOURCE_ID, TILE_GROUND)


## Places a filled rectangle of tiles
func place_filled_rect(start: Vector2i, size: Vector2i) -> void:
	for x in range(start.x, start.x + size.x):
		for y in range(start.y, start.y + size.y):
			tilemap.set_cell(Vector2i(x, y), TILESET_SOURCE_ID, TILE_GROUND)


## Clears all tiles in a rectangular area
func clear_rect(start: Vector2i, size: Vector2i) -> void:
	for x in range(start.x, start.x + size.x):
		for y in range(start.y, start.y + size.y):
			tilemap.erase_cell(Vector2i(x, y))


## Checks if a tile position has a solid tile
func is_solid(pos: Vector2i) -> bool:
	return tilemap.get_cell_source_id(pos) != -1


## Checks if a tile position is empty (no tile)
func is_empty(pos: Vector2i) -> bool:
	return tilemap.get_cell_source_id(pos) == -1


## Gets the bounds of placed tiles
func get_used_rect() -> Rect2i:
	return tilemap.get_used_rect()


## Converts world position to tile position
static func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / TILE_SIZE), floori(world_pos.y / TILE_SIZE))


## Converts tile position to world position (top-left corner of tile)
static func tile_to_world(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * TILE_SIZE, tile_pos.y * TILE_SIZE)


## Converts tile position to world position (center of tile)
static func tile_to_world_center(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * TILE_SIZE + TILE_SIZE / 2.0, tile_pos.y * TILE_SIZE + TILE_SIZE / 2.0)
