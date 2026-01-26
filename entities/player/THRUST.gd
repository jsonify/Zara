extends UnifiedState

func state_process(delta) -> UnifiedState:
	_apply_gravity(delta)
	player_movement()
	_thrust_movement(delta)

	var player := character as Player

	# Allow attacks while thrusting
	if player.attack_input:
		return get_parent().get_node("ATTACK") as UnifiedState

	if player.ranged_input:
		return get_parent().get_node("RANGED") as UnifiedState

	if player.velocity.y > 0:
		return get_parent().get_node("FALL") as UnifiedState

	if player.velocity.y == 0:
		return get_parent().get_node("IDLE") as UnifiedState

	return null

func _thrust_movement(delta):
	var player := character as Player

	if player.jetpack_enabled:
		if player.can_thrust:
			if player.fuel_level > 0.01 and player.thrust_input:
				animation_player.play("thrust")
				player.apply_thrust()
				Game.fuel_level -= delta
			else:
				next_state = get_parent().get_node("FALL") as UnifiedState
		if player.fuel_level <= 0:
			player.can_thrust = false

func _apply_gravity(delta):
	var player := character as Player
	if not player.is_on_floor():
		player.velocity.y += player.gravity_value * delta
