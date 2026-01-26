extends Area2D

class_name Explosion

@export var damage := 15
@export var radius := 32.0
@export var lifetime := 0.4

@onready var lifetime_timer := $LifetimeTimer
@onready var collision_shape := $CollisionShape2D
@onready var sprite := $ExplosionSprite

var has_dealt_damage := false

func _ready():
	# Set collision shape radius
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius

	# Deal damage and start visuals after position is set (deferred to next frame)
	call_deferred("_start_explosion")

func _start_explosion():
	# Deal damage
	_deal_area_damage()

	# Visual effect - expand and fade
	if sprite:
		sprite.scale = Vector2.ZERO
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "scale", Vector2(6, 6), lifetime * 0.3).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "modulate:a", 0.0, lifetime).set_ease(Tween.EASE_IN)

	# Start lifetime timer
	lifetime_timer.start(lifetime)

func _deal_area_damage():
	if has_dealt_damage:
		return
	has_dealt_damage = true

	# Use direct physics query (works immediately, unlike get_overlapping_bodies)
	var space_state = get_world_2d().direct_space_state
	if not space_state:
		return

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = CircleShape2D.new()
	query.shape.radius = radius
	query.transform = global_transform
	query.collision_mask = collision_mask  # Use same mask as Area2D (layer 3 = Enemy)
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var results = space_state.intersect_shape(query)

	for result in results:
		var body = result.collider
		print("  - Found body: ", body.name, " layer=", body.collision_layer)
		# Look for Damageable component
		for child in body.get_children():
			print("    - Child: ", child.name, " is Damageable: ", child is Damageable)
			if child is Damageable:
				# Calculate knockback direction from explosion center
				var knockback_dir = (body.global_position - global_position).normalized()
				if knockback_dir == Vector2.ZERO:
					knockback_dir = Vector2.UP

				child.hit(damage, knockback_dir)
				break

func _on_lifetime_timer_timeout():
	queue_free()
