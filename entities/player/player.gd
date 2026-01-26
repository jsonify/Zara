extends CharacterBody2D

class_name Player

@onready var animation_player := $AnimationPlayer
@onready var sprite := $Sprite2D
@onready var thrust_fire := $GPUParticles2D
@onready var state_machine := $StateMachine

@export var MAX_SPEED := 75
@export var ACCELERATION := 10
@export var FRICTION := 10
@export var ADDITIONAL_FALL_GRAVITY := 2
@export var THRUST := -1
@export var MAX_THRUST := 50

var gravity_value = ProjectSettings.get_setting("physics/2d/default_gravity")

# player movement
@export var SPEED = 70.0
@export var JUMP_VELOCITY = -300.0
var last_direction := Vector2.RIGHT

# mechanics
var can_slide := false
var can_dash := true
var can_thrust := false

# player input
var movement_input := Vector2.ZERO
var jump_input := false
var jump_input_actuation := false
var climb_input := false
var dash_input := false
var thrust_input := false
var attack_input := false
var ranged_input := false

var sprite_frames
var jetpack_enabled

var direction = "right"
var fuel_level
var player_position_uv : Vector2
var spawn_position : Vector2

@onready var raycasts = $Raycasts
@onready var screen_dimensions = Vector2(get_viewport().size)
@onready var hurt_box = $HurtBox

func _ready():
	Utils.saveGame()
	Utils.loadGame()

	# Store initial spawn position
	spawn_position = global_position

	jetpack_enabled = Game.jetpack

	# Connect HurtBox to damage handling
	if hurt_box:
		hurt_box.take_damage.connect(_on_hurt_box_take_damage)

func _physics_process(_delta):
	player_input()
	_handle_item_use()

	# Display current state name for debugging
	if state_machine.current_state:
		$Label.text = str(state_machine.current_state.name)

	fuel_level = Game.fuel_level
	if jetpack_enabled:
		use_jetpack_powerup()
		if fuel_level > 0:
			can_thrust = true

	move_and_slide()
	die()

func _handle_item_use():
	if Input.is_action_just_pressed("use_item"):
		# Priority: health potion if HP < max, else fuel canister
		if Game.player_hp < Game.max_player_hp and Game.has_item("health_potion"):
			Game.use_item("health_potion")
		elif Game.fuel_level < Game.max_fuel_level and Game.has_item("fuel_canister"):
			Game.use_item("fuel_canister")

func gravity(delta):
	if not is_on_floor():
		velocity.y += gravity_value * delta

func apply_friction():
	velocity.x = move_toward(velocity.x, 0, FRICTION)

func apply_acceleration(amount):
	velocity.x = move_toward(velocity.x, MAX_SPEED * amount, ACCELERATION)

func player_input():
	movement_input = Vector2.ZERO
	if Input.is_action_pressed("right"):
		movement_input.x += 1
		change_direction(movement_input.x)
	if Input.is_action_pressed("left"):
		movement_input.x -= 1
		change_direction(movement_input.x)

	if Input.is_action_pressed("down"):
		movement_input.x += 1

	# jumps
	if Input.is_action_pressed("jump"):
		jump_input = true
	else:
		jump_input = false
	if Input.is_action_just_pressed("jump"):
		jump_input_actuation = true
	else:
		jump_input_actuation = false

	# CLIMB
	if Input.is_action_pressed("climb"):
		climb_input = true
	else:
		climb_input = false

	# DASH
	if Input.is_action_just_pressed("dash"):
		dash_input = true
	else:
		dash_input = false

	# SLIDE
	if Input.is_action_pressed("slide"):
		climb_input = true
	else:
		climb_input = false

	# THRUST
	if Input.is_action_pressed("thrust"):
		thrust_input = true
		if has_fuel():
			thrust_fire.emitting = true
			Events.emit_signal("thrust_engaged")

	if Input.is_action_just_released("thrust"):
		thrust_fire.emitting = false
		thrust_input = false
		Events.emit_signal("thrust_not_engaged")

	# ATTACK
	if Input.is_action_just_pressed("attack"):
		attack_input = true
	else:
		attack_input = false

	# RANGED
	if Input.is_action_just_pressed("ranged"):
		ranged_input = true
	else:
		ranged_input = false

func has_fuel():
	if Game.fuel_level < 0.01:
		Game.fuel_level = 0.0
	if Game.fuel_level > 0:
		return true
	else:
		thrust_fire.emitting = false
		return false

func change_direction(dir):
	if dir == -1:
		direction = "left"
		$Sprite2D.flip_h = true
		thrust_fire.position = Vector2(2, -2)
	elif dir == 1:
		direction = "right"
		$Sprite2D.flip_h = false
		thrust_fire.position = Vector2(-2, -2)

func use_jetpack_powerup():
	sprite.texture = load("res://entities/player/player_jetpack.tres")

func apply_thrust():
	animation_player.play("thrust")
	velocity.y = lerp(0, MAX_THRUST, THRUST)

func update_direction(input) -> void:
	if input.x > 0:
		set_direction_right()
	elif input.x < 0:
		set_direction_left()

func set_direction_right() -> void:
	direction = "right"
	sprite.flip_h = false

func set_direction_left() -> void:
	direction = "left"
	sprite.flip_h = true

func die():
	if Game.player_hp <= 0:
		var death_state = state_machine.get_state("DEATH")
		if death_state and state_machine.current_state != death_state:
			state_machine.switch_state(death_state)

func respawn():
	# Reset player position
	global_position = spawn_position

	# Reset HP to max
	Game.player_hp = Game.max_player_hp

	# Reset sprite visibility
	sprite.modulate.a = 1.0

	# Re-enable physics
	set_physics_process(true)

	# Transition to IDLE state
	var idle_state = state_machine.get_state("IDLE")
	if idle_state:
		state_machine.switch_state(idle_state)

	# Emit respawn signal
	Events.emit_signal("player_respawned")

func set_checkpoint(pos: Vector2):
	spawn_position = pos

func get_next_to_wall():
	for raycast in raycasts.get_children():
		raycast.force_raycast_update()
		if raycast.is_colliding():
			if raycast.target_position.x > 0:
				return Vector2.RIGHT
			else:
				return Vector2.LEFT
	return null

func _on_dialogue_player_set_player_active(active):
	set_physics_process(active)
	set_process(active)
	set_process_input(active)

func _on_hurt_box_take_damage(amount: int, knockback_direction: Vector2):
	# Check if HIT state exists and player is not already invincible
	var hit_state = state_machine.get_state("HIT")
	if hit_state and not hit_state.is_invincible:
		hit_state.take_hit(amount, knockback_direction)
