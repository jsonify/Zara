extends Area2D

class_name Projectile

@export var speed := 150.0
@export var damage := 1
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

	print("Projectile launched with velocity: ", velocity)

func _on_body_entered(body):
	print("Projectile hit: ", body.name)

	# Check if it's an enemy with Damageable
	for child in body.get_children():
		if child is Damageable:
			print("Projectile: Found Damageable, applying damage: ", damage)
			child.hit(damage, velocity.normalized())
			queue_free()
			return

	# Hit environment or other obstacle - just destroy
	queue_free()

func _on_lifetime_timer_timeout():
	queue_free()
