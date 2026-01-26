extends Area2D

class_name Projectile

const EXPLOSION_SCENE = preload("res://effects/explosion.tscn")

@export var speed := 150.0
@export var damage := 15  # Passed to explosion
@export var lifetime := 3.0
@export var gravity_force := 300.0
@export var launch_angle := -35.0  # Degrees, negative = upward

var velocity := Vector2.ZERO

@onready var lifetime_timer := $LifetimeTimer

func _ready():
	lifetime_timer.start(lifetime)

func _physics_process(delta):
	# Apply gravity to velocity
	velocity.y += gravity_force * delta

	# Move projectile
	position += velocity * delta

	# Rotate to face movement direction
	if velocity.length() > 0:
		rotation = velocity.angle()

func set_direction(dir: Vector2):
	# Calculate initial velocity with launch angle for arc
	var angle_rad = deg_to_rad(launch_angle)
	if dir.x < 0:
		angle_rad = PI - angle_rad  # Flip angle for left direction

	velocity = Vector2(cos(angle_rad), sin(angle_rad)) * speed
	if dir.x < 0:
		velocity.x = -abs(velocity.x)  # Ensure left direction

func _on_body_entered(_body):
	# Use call_deferred to avoid physics query flush issues
	call_deferred("_explode")

func _on_lifetime_timer_timeout():
	_explode()

func _explode():
	if not is_inside_tree():
		return

	# Spawn explosion at current position
	var explosion = EXPLOSION_SCENE.instantiate()
	explosion.damage = damage
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = global_position

	# Remove grenade
	queue_free()
