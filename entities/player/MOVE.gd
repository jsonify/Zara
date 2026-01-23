extends UnifiedState

func state_process(delta) -> UnifiedState:
	animation_player.play("move")
	_apply_gravity(delta)
	player_movement()

	var player := character as Player

	if player.velocity.x == 0:
		return get_parent().get_node("IDLE") as UnifiedState

	if player.velocity.y > 0:
		return get_parent().get_node("FALL") as UnifiedState

	if player.jump_input_actuation:
		return get_parent().get_node("JUMP") as UnifiedState

	if player.dash_input and player.can_dash:
		return get_parent().get_node("DASH") as UnifiedState

	if player.thrust_input and player.can_thrust and player.fuel_level > 0.01:
		return get_parent().get_node("THRUST") as UnifiedState

	if player.attack_input:
		return get_parent().get_node("ATTACK") as UnifiedState

	if player.ranged_input:
		return get_parent().get_node("RANGED") as UnifiedState

	return null

func on_enter():
	var player := character as Player
	player.can_dash = true

func _apply_gravity(delta):
	var player := character as Player
	if not player.is_on_floor():
		player.velocity.y += player.gravity_value * delta
