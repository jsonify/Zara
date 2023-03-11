extends CharacterBody2D
class_name Player

@export var SPEED := 100.0
@export var JUMP_VELOCITY := -160.0
@export var JUMP_RELEASE_FORCE := -40
@export var MAX_SPEED := 75
@export var ACCELERATION := 10
@export var FRICTION := 10
@export var GRAVITY := 5
@export var ADDITIONAL_FALL_GRAVITY := 2
@export var THRUST := -1
@export var MAX_THRUST := 50

@onready var animation_player := $AnimationPlayer
@onready var state_label := $StateLabel
@onready var sprite := $Sprite2D
@onready var remoteTransform2D := $RemoteTransform2D

var jetpack_enabled = false

#var stats: Character : set = set_stats, get = _get_stats

enum states { RUN, JUMP, FALL, IDLE, THRUST }

var debug_enabled_status := false

var state = states.FALL
var direction := "right"

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	debug_enabled(debug_enabled_status)
	
func set_stats():
	pass
	
func _get_stats():
	pass

func _physics_process(delta):
	var input = Vector2.ZERO
	input.x = Input.get_axis("left", "right")
	input.y = Input.get_axis("thrust", "ui_down")
	
	if jetpack_enabled:
		sprite.texture = load("res://Assets/Player/hero_JETPACK_24x36.png")

	match state:
		states.RUN:
			run_state(input)
		states.JUMP:
			jump_state(input)
		states.FALL:
			fall_state(input)
		states.IDLE:
			idle_state(input)
		states.THRUST:
			thrust_state(input)

	fast_fall()
	move_and_slide()


func apply_thrust():
	animation_player.play("Thrust")
	velocity.y = lerp(0, MAX_THRUST, THRUST)


func fast_fall():
	if velocity.y > 0:
		velocity.y += ADDITIONAL_FALL_GRAVITY


func apply_gravity():
	velocity.y += GRAVITY


func apply_acceleration(amount):
	velocity.x = move_toward(velocity.x, MAX_SPEED * amount, ACCELERATION)


func apply_friction():
	velocity.x = move_toward(velocity.x, 0, FRICTION)


func run_state(input):
	update_direction(input)
	apply_gravity()

	if input.x == 0:
		state = states.IDLE
	else:
		animation_player.play("Run")
		apply_acceleration(input.x)
	if not is_on_floor() and velocity.y > 0:
		state = states.FALL
	if Input.is_action_pressed("thrust") and jetpack_enabled:
		state = states.THRUST
	elif Input.is_action_pressed("jump"):
		state = states.JUMP


func jump_state(input):
	if is_on_floor():
		if Input.is_action_pressed("jump"):
			animation_player.play("Jump")
			velocity.y = JUMP_VELOCITY

	update_direction(input)
	apply_gravity()
	if Input.is_action_pressed("right") or Input.is_action_pressed("left"):
		apply_acceleration(input.x)
	if velocity.y < 0:
		state = states.FALL
		#research this again on heartbeast


#		if Input.is_action_just_released("jump") and velocity.y < JUMP_RELEASE_FORCE:
#			animation_player.play("Jump")
#			velocity.y = JUMP_RELEASE_FORCE


func fall_state(input):
	apply_gravity()
	update_direction(input)
	animation_player.play("Fall")
	if is_on_floor():
		state = states.IDLE
	elif Input.is_action_pressed("thrust") and jetpack_enabled:
		state = states.THRUST

	if Input.is_action_pressed("right") or Input.is_action_pressed("left"):
		apply_acceleration(input.x)


func idle_state(input):
	apply_friction()
	animation_player.play("Idle")
	if Input.is_action_pressed("right") or Input.is_action_pressed("left"):
		state = states.RUN
	elif Input.is_action_pressed("jump"):
		state = states.JUMP
	elif Input.is_action_pressed("thrust") and jetpack_enabled:
		state = states.THRUST

	if velocity.y > 0:
		state = states.FALL


func thrust_state(input):
	if jetpack_enabled:
		animation_player.play("Thrust")
		apply_thrust()
		update_direction(input)
		if Input.is_action_just_released("thrust"):
			state = states.FALL
		elif input.x != 0:
			apply_acceleration(input.x)


func player_die():
	queue_free()
	print("from player node, player_die()")
	Events.emit_signal("player_died")


func connect_camera(camera):
	var camera_path = camera.get_path()
	remoteTransform2D.remote_path = camera_path


func update_direction(input) -> void:
	if input.x > 0:
		set_direction_right()
	elif input.x < 0:
		set_direction_left()


func debug_enabled(status):
	debug_enabled_status = status
	if debug_enabled_status == true:
		state_label.text = states.keys()[state]


func set_direction_right() -> void:
	direction = "right"
	sprite.flip_h = false


func set_direction_left() -> void:
	direction = "left"
	sprite.flip_h = true
#	$HitboxPosition.rotation_degrees = 180
