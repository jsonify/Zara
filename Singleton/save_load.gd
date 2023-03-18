extends Node

const SAVE_PATH = "user://save.json" #use user://savefilename.dat instead here

var default_data := {
	"player": {
		"name": "Jsonify",
		"score": 10,
		"jetpack_enabled": false,
		"level": 1,
		"guns": {
			"small": 10,
			"large": 14
		}
	},
	"powerups": {
		"jetpack_powerup_acquired": false
	},
	"levels_completed": [1, 2, 3]
}

var data = { }


func _ready():
	print(data)
	load_data()
	update_text()

	
func save_data():
	var save_game := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var json_string := JSON.stringify(data)
	#TODO: implement encryption password
	save_game.store_line(json_string)

func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		reset_data()
		return
	var load_game = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string = load_game.get_line()
	data = JSON.parse_string(json_string)
	
func reset_data():
	data = default_data.duplicate(true)

func update_text():
	pass
