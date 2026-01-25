extends BaseEnemy

@onready var animation_player := $AnimationPlayer

@export var chase_speed := 50

var player_detected := false
var player_chase := false

func _physics_process(_delta):
	patrol()
	detect_turn_around()
	move_and_slide()

func patrol():
	animation_player.play("walk")
	velocity = direction * speed
