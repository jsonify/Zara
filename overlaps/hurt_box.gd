extends Area2D

class_name HurtBox

signal take_damage(amount: int, knockback_direction: Vector2)

const HIT_EFFECT = preload("res://effects/hit_effect.tscn")

var is_invincible := false

func _on_area_entered(area: Area2D):
	if is_invincible:
		return

	# Check if the area is a HitBox
	if area is HitBox:
		# Ignore hitboxes from the same character (prevent self-damage)
		var my_root = _get_character_root(self)
		var hitbox_root = _get_character_root(area)
		if my_root and hitbox_root and my_root == hitbox_root:
			return
		var hitbox = area as HitBox
		var damage = hitbox.damage

		# Calculate knockback direction
		var direction_to_self = (global_position - area.global_position).normalized()
		var knockback_direction = Vector2(sign(direction_to_self.x), -0.5).normalized()

		emit_signal("take_damage", damage, knockback_direction)

		# Spawn hit effect
		_spawn_hit_effect()

func _spawn_hit_effect():
	if HIT_EFFECT:
		var effect = HIT_EFFECT.instantiate()
		effect.global_position = global_position
		get_tree().current_scene.add_child(effect)

func set_invincible(value: bool):
	is_invincible = value

func _get_character_root(node: Node) -> Node:
	# Walk up the tree to find the CharacterBody2D root
	var current = node
	while current:
		if current is CharacterBody2D:
			return current
		current = current.get_parent()
	return null
