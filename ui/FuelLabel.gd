extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	visible = Game.jetpack

func _process(_delta):
	visible = Game.jetpack
