extends UnifiedState

## Ranged attack state for player - spawns grenade with charged throw

@export var ranged_cooldown := 0.5
@export var projectile_scene: PackedScene
@export var min_charge_time := 0.0  # Instant throw
@export var max_charge_time := 1.0  # Full charge
@export var min_speed := 100.0  # Quick tap throw
@export var max_speed := 200.0  # Full charge throw
@export var min_angle := -25.0  # Quick tap angle (degrees)
@export var max_angle := -50.0  # Full charge angle (degrees)
@export var trajectory_points := 15  # Number of dots in preview
@export var trajectory_time_step := 0.05  # Time between each point

@onready var cooldown_timer := $CooldownTimer
@onready var spawn_point := $SpawnPoint

var can_shoot := true
var charging := false
var charge_time := 0.0
var trajectory_line: Line2D

func _ready():
	# Load projectile scene if not set
	if projectile_scene == null:
		projectile_scene = preload("res://entities/projectiles/projectile.tscn")

func state_process(delta) -> UnifiedState:
	if charging:
		# Accumulate charge while button is held
		charge_time += delta
		charge_time = min(charge_time, max_charge_time)

		# Update trajectory preview
		_update_trajectory_preview()

		# Check if button released - throw!
		if not Input.is_action_pressed("ranged"):
			_throw_grenade()
			_remove_trajectory_preview()
			charging = false
			cooldown_timer.start(ranged_cooldown)
			return get_parent().get_node("IDLE") as UnifiedState

		# Allow movement while charging
		player_movement()

	return null

func on_enter():
	if not can_shoot:
		next_state = get_parent().get_node("IDLE") as UnifiedState
		return

	# Check if player has grenades unlocked
	if not Game.has_grenades:
		next_state = get_parent().get_node("IDLE") as UnifiedState
		return

	# Check if player has enough fuel
	if Game.fuel_level < Game.grenade_fuel_cost:
		next_state = get_parent().get_node("IDLE") as UnifiedState
		return

	# Start charging
	charging = true
	charge_time = 0.0
	can_shoot = false

	# Create trajectory preview
	_create_trajectory_preview()

	# Animation if available
	if animation_player.has_animation("ranged"):
		animation_player.play("ranged")

func on_exit():
	charging = false
	charge_time = 0.0
	_remove_trajectory_preview()

func _throw_grenade():
	# Deduct fuel cost
	Game.fuel_level -= Game.grenade_fuel_cost

	# Calculate charge percentage (0.0 to 1.0)
	var charge_percent = charge_time / max_charge_time

	# Interpolate speed and angle based on charge
	var throw_speed = lerp(min_speed, max_speed, charge_percent)
	var throw_angle = lerp(min_angle, max_angle, charge_percent)

	_spawn_projectile(throw_speed, throw_angle)

func _spawn_projectile(throw_speed: float, throw_angle: float):
	var player := character as Player
	var projectile = projectile_scene.instantiate()

	# Override projectile settings based on charge
	projectile.speed = throw_speed
	projectile.launch_angle = throw_angle

	# Get spawn position - offset from player based on direction
	var spawn_offset = Vector2(4, -6) if player.direction == "right" else Vector2(-4, -6)
	var target_pos = player.global_position + spawn_offset

	# Add to scene tree first, then set position
	player.get_tree().current_scene.add_child(projectile)
	projectile.global_position = target_pos

	# Set projectile direction based on player facing
	var proj_direction = Vector2.RIGHT if player.direction == "right" else Vector2.LEFT
	projectile.set_direction(proj_direction)

func _on_cooldown_timer_timeout():
	can_shoot = true

func _create_trajectory_preview():
	var player := character as Player

	# Create Line2D for trajectory
	trajectory_line = Line2D.new()
	trajectory_line.width = 1.0
	trajectory_line.default_color = Color(1, 0.7, 0.3, 0.5)  # Subtle orange
	trajectory_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trajectory_line.end_cap_mode = Line2D.LINE_CAP_ROUND

	# Add to scene (not as child of player so it doesn't move with player)
	player.get_tree().current_scene.add_child(trajectory_line)
	trajectory_line.global_position = Vector2.ZERO  # Ensure points are in global coordinates

func _update_trajectory_preview():
	if not trajectory_line or not is_instance_valid(trajectory_line):
		return

	var player := character as Player
	if not player:
		return

	var charge_percent = charge_time / max_charge_time

	# Calculate current throw parameters
	var throw_speed = lerp(min_speed, max_speed, charge_percent)
	var throw_angle = lerp(min_angle, max_angle, charge_percent)

	# Starting position - same as where projectile spawns
	var facing_right = player.direction == "right"
	var spawn_offset = Vector2(4, -6) if facing_right else Vector2(-4, -6)
	var start_pos = player.global_position + spawn_offset

	# Calculate initial velocity - match projectile.gd logic exactly
	var angle_rad = deg_to_rad(throw_angle)
	if not facing_right:
		angle_rad = PI - angle_rad

	var vel = Vector2(cos(angle_rad), sin(angle_rad)) * throw_speed
	if not facing_right:
		vel.x = -abs(vel.x)

	# Simulate trajectory until hitting ground/wall
	var gravity = 300.0  # Match projectile gravity_force
	var points: PackedVector2Array = []
	var pos = start_pos
	var max_iterations = 100  # Safety limit

	points.append(pos)

	var space_state = player.get_world_2d().direct_space_state
	if not space_state:
		return

	for i in range(max_iterations):
		var prev_pos = pos
		vel.y += gravity * trajectory_time_step
		pos += vel * trajectory_time_step

		# Raycast from previous position to current position to check for collision
		var query = PhysicsRayQueryParameters2D.create(prev_pos, pos)
		query.collision_mask = 1  # Environment layer only
		query.collide_with_areas = false
		query.collide_with_bodies = true

		var result = space_state.intersect_ray(query)
		if result:
			# Hit something - end trajectory at collision point
			points.append(result.position)
			break
		else:
			points.append(pos)

		# Safety: stop if trajectory goes too far down (off screen)
		if pos.y > start_pos.y + 500:
			break

	trajectory_line.points = points

func _remove_trajectory_preview():
	if trajectory_line and is_instance_valid(trajectory_line):
		trajectory_line.queue_free()
		trajectory_line = null
