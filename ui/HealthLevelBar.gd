extends TextureProgressBar


func _ready():
	value = Game.player_hp


func _process(_delta):
	if Game.player_hp > 0:
		value = Game.player_hp

