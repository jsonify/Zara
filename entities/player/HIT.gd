extends UnifiedState

## Hit state for player - handles damage reaction with knockback and invincibility

@export var hit_duration := 0.3
@export var invincibility_duration := 1.0
@export var knockback_speed := 150.0

@onready var hit_timer := $HitTimer
@onready var invincibility_timer := $InvincibilityTimer

var is_hit := false
var is_invincible := false
var knockback_direction := Vector2.ZERO

func state_process(_delta) -> UnifiedState:
	if not is_hit:
		var player := character as Player
		if player.is_on_floor():
			return get_parent().get_node("IDLE") as UnifiedState
		else:
			return get_parent().get_node("FALL") as UnifiedState
	return null

func on_enter():
	is_hit = true
	is_invincible = true
	hit_timer.start(hit_duration)
	invincibility_timer.start(invincibility_duration)

	# Apply knockback
	var player := character as Player
	player.velocity = knockback_direction * knockback_speed

	# Play hit animation if available
	if animation_player.has_animation("hit"):
		animation_player.play("hit")

	# Visual feedback - flash or transparency
	_start_flash()

func on_exit():
	is_hit = false

func take_hit(damage: int, direction: Vector2):
	knockback_direction = direction
	# Reduce player HP
	Game.player_hp -= damage
	# Trigger state transition
	emit_signal("interrupt_state", self)

func _start_flash():
	var player := character as Player
	if player.sprite:
		# Create flash effect using modulate
		var tween = create_tween()
		tween.set_loops(5)
		tween.tween_property(player.sprite, "modulate:a", 0.3, 0.1)
		tween.tween_property(player.sprite, "modulate:a", 1.0, 0.1)

func _on_hit_timer_timeout():
	is_hit = false

func _on_invincibility_timer_timeout():
	is_invincible = false
	# Reset sprite visibility
	var player := character as Player
	if player.sprite:
		player.sprite.modulate.a = 1.0
