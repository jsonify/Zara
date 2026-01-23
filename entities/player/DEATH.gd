extends UnifiedState

## Death state for player - handles death animation and respawn trigger

@export var death_duration := 1.0
@export var respawn_delay := 0.5

@onready var death_timer := $DeathTimer
@onready var respawn_timer := $RespawnTimer

var is_dying := false

func state_process(_delta) -> UnifiedState:
	# Stay in death state until respawn
	return null

func on_enter():
	is_dying = true
	var player := character as Player

	# Stop all movement
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)

	# Play death animation if available
	if animation_player.has_animation("death"):
		animation_player.play("death")

	# Visual feedback - fade out
	var tween = create_tween()
	tween.tween_property(player.sprite, "modulate:a", 0.0, death_duration * 0.8)

	# Emit death signal
	Events.emit_signal("player_died")

	# Start death timer
	death_timer.start(death_duration)

func on_exit():
	is_dying = false
	var player := character as Player
	player.sprite.modulate.a = 1.0
	player.set_physics_process(true)

func _on_death_timer_timeout():
	# Start respawn after death animation
	respawn_timer.start(respawn_delay)

func _on_respawn_timer_timeout():
	# Trigger respawn through player
	var player := character as Player
	player.respawn()
