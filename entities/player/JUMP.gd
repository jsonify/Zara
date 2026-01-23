extends UnifiedState

func state_process(delta) -> UnifiedState:
	animation_player.play("jump")
	_apply_gravity(delta)
	player_movement()

	var player := character as Player

	if player.velocity.y > 0:
		return get_parent().get_node("FALL") as UnifiedState

	if player.dash_input and player.can_dash:
		return get_parent().get_node("DASH") as UnifiedState

	if player.get_next_to_wall() != null and player.can_slide:
		return get_parent().get_node("SLIDE") as UnifiedState

	return null

func on_enter():
	var player := character as Player
	player.velocity.y = player.JUMP_VELOCITY

func _apply_gravity(delta):
	var player := character as Player
	if not player.is_on_floor():
		player.velocity.y += player.gravity_value * delta
