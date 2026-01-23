extends UnifiedState

## Ranged attack state for player - spawns projectile

@export var ranged_cooldown := 0.5
@export var projectile_scene: PackedScene

@onready var cooldown_timer := $CooldownTimer
@onready var spawn_point := $SpawnPoint

var can_shoot := true
var shooting := false

func _ready():
	# Load projectile scene if not set
	if projectile_scene == null:
		projectile_scene = preload("res://entities/projectiles/projectile.tscn")

func state_process(_delta) -> UnifiedState:
	if not shooting:
		return get_parent().get_node("IDLE") as UnifiedState
	return null

func on_enter():
	if not can_shoot:
		# Can't shoot yet, return to idle
		next_state = get_parent().get_node("IDLE") as UnifiedState
		return

	shooting = true
	can_shoot = false

	# Spawn projectile
	_spawn_projectile()

	# Animation if available
	if animation_player.has_animation("ranged"):
		animation_player.play("ranged")
		# Wait for animation to finish
		await animation_player.animation_finished

	shooting = false
	cooldown_timer.start(ranged_cooldown)

func on_exit():
	shooting = false

func _spawn_projectile():
	var player := character as Player
	var projectile = projectile_scene.instantiate()

	# Get spawn position - offset from player based on direction
	var spawn_offset = Vector2(8, -5) if player.direction == "right" else Vector2(-8, -5)
	projectile.global_position = player.global_position + spawn_offset

	# Set projectile direction based on player facing
	var proj_direction = Vector2.RIGHT if player.direction == "right" else Vector2.LEFT
	projectile.set_direction(proj_direction)

	# Add to scene tree
	player.get_tree().current_scene.add_child(projectile)

func _on_cooldown_timer_timeout():
	can_shoot = true
