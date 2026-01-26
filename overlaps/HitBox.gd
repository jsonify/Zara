extends Area2D

class_name HitBox

@export var damage := 10


func _on_body_entered(body):
	print("HitBox: body_entered - ", body.name)
	for child in body.get_children():
		if child is Damageable:
			print("HitBox: Found Damageable on ", body.name, ", applying damage: ", damage)
			# Use hitbox's own global position for direction calculation
			var direction_to_damageable = (body.global_position - global_position)
			var direction_sign = sign(direction_to_damageable.x)

			if direction_sign > 0:
				child.hit(damage, Vector2.RIGHT)
			elif direction_sign < 0:
				child.hit(damage, Vector2.LEFT)
			else:
				child.hit(damage, Vector2.ZERO)
			return
	print("HitBox: No Damageable found on ", body.name)
