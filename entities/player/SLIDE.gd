extends UnifiedState

@export var climb_speed := 50
@export var slide_friction := 0.7

func state_process(delta) -> UnifiedState:
	_slide_movement(delta)

	var player := character as Player

	if player.get_next_to_wall() == null:
		return get_parent().get_node("FALL") as UnifiedState

	if player.jump_input_actuation:
		return get_parent().get_node("JUMP") as UnifiedState

	if player.is_on_floor():
		return get_parent().get_node("IDLE") as UnifiedState

	return null

func _slide_movement(delta):
	var player := character as Player

	if player.climb_input and not player.thrust_input:
		if player.movement_input.y < 0:
			player.velocity.y = -climb_speed
		elif player.movement_input.y > 0:
			player.velocity.y = climb_speed
		else:
			player.velocity.y = 0
	else:
		player_movement()
		_apply_gravity(delta)
		player.velocity.y *= slide_friction

func _apply_gravity(delta):
	var player := character as Player
	if not player.is_on_floor():
		player.velocity.y += player.gravity_value * delta
