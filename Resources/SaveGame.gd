extends Resource

class_name SaveGame

const SAVE_GAME_PATH := "user://save.tres"

# Use this to detect old player saves and update their data
@export var version := 1

@export var character: Resource


func write_savegame():
	ResourceSaver.save(self, SAVE_GAME_PATH)
	
func save_exists() -> bool:
	return ResourceLoader.exists(SAVE_GAME_PATH)
	
func load_savegame() -> Resource:
	if not ResourceLoader.has_cached(SAVE_GAME_PATH):
		return ResourceLoader.load(SAVE_GAME_PATH, "", 1)
