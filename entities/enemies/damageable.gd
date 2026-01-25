extends Node

class_name Damageable

signal on_hit(node: Node, damage_taken: int, knockback_direction: Vector2)

const GOLD_COIN_SCENE = preload("res://collectibles/gold/gold_coin.tscn")

@export var health := 20:
	get: return health
	set(value):
		SignalBus.emit_signal("on_health_changed", get_parent(), value - health)
		health = value

@export var dead_animation_name := "dead"
@export var gold_drop_amount := 5

func hit(damage: int, knockback_direction: Vector2):
	health -= damage

	emit_signal("on_hit", get_parent(), damage, knockback_direction)


func _on_animation_tree_animation_finished(anim_name):
	if anim_name == dead_animation_name:
		# Drop gold before removing from game
		_drop_gold()
		# Character is finished dying, remove from the game
		get_parent().queue_free()

func _drop_gold():
	if gold_drop_amount > 0 and GOLD_COIN_SCENE:
		var gold = GOLD_COIN_SCENE.instantiate()
		if gold:
			gold.gold_amount = gold_drop_amount
			gold.global_position = get_parent().global_position
			get_tree().current_scene.add_child(gold)
