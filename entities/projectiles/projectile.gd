extends Area2D

class_name Projectile

@export var speed := 200.0
@export var damage := 1
@export var lifetime := 2.0

var direction := Vector2.RIGHT

@onready var lifetime_timer := $LifetimeTimer

func _ready():
	lifetime_timer.start(lifetime)

func _physics_process(delta):
	position += direction * speed * delta

func set_direction(dir: Vector2):
	direction = dir.normalized()
	# Rotate sprite to face direction
	rotation = direction.angle()

func _on_body_entered(body):
	for child in body.get_children():
		if child is Damageable:
			child.hit(damage, direction)
	queue_free()

func _on_lifetime_timer_timeout():
	queue_free()
