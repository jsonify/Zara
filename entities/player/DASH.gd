extends UnifiedState

@export var dash_duration := 0.2

@onready var dash_duration_timer := $DashDuration

var dash_direction := Vector2.ZERO
var dash_speed := 240
var dashing := false

func state_process(_delta) -> UnifiedState:
	if !dashing:
		return get_parent().get_node("FALL") as UnifiedState
	return null

func on_enter():
	var player := character as Player
	player.can_dash = false
	dashing = true
	dash_duration_timer.start(dash_duration)

	if player.movement_input != Vector2.ZERO:
		dash_direction = player.movement_input
	else:
		dash_direction = player.last_direction

	player.velocity = dash_direction.normalized() * dash_speed

func on_exit():
	dashing = false

func _on_timer_timeout():
	dashing = false
