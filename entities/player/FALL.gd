extends UnifiedState

@onready var coyote_timer = $CoyoteTimer

@export var coyote_duration := 0.2

var can_jump := true

func state_process(delta) -> UnifiedState:
	animation_player.play("fall")
	_apply_gravity(delta)
	player_movement()

	var player := character as Player
	var state_machine := get_parent() as UnifiedStateMachine

	if player.is_on_floor():
		return get_parent().get_node("IDLE") as UnifiedState

	if player.dash_input and player.can_dash:
		return get_parent().get_node("DASH") as UnifiedState

	if player.get_next_to_wall() != null and player.can_slide:
		return get_parent().get_node("SLIDE") as UnifiedState

	if player.jump_input_actuation and can_jump:
		return get_parent().get_node("JUMP") as UnifiedState

	if player.thrust_input and player.can_thrust and player.fuel_level > 0.01:
		return get_parent().get_node("THRUST") as UnifiedState

	return null

func on_enter():
	var player := character as Player
	var state_machine := get_parent() as UnifiedStateMachine

	# Check if we can coyote jump based on previous state
	var prev_state_name = ""
	if state_machine.prev_state:
		prev_state_name = state_machine.prev_state.name

	if prev_state_name in ["IDLE", "MOVE", "SLIDE"]:
		can_jump = true
		coyote_timer.start(coyote_duration)
	else:
		can_jump = false

func _on_coyote_timer_timeout():
	can_jump = false

func _apply_gravity(delta):
	var player := character as Player
	if not player.is_on_floor():
		player.velocity.y += player.gravity_value * delta
