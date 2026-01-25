extends Area2D

@export var gold_amount := 1
@export var spawn_indicator_offset := -20

func _on_body_entered(body):
	if body is Player:
		Game.gold += gold_amount
		Events.emit_signal("gold_collected", gold_amount)
		spawn_indicator(gold_amount)
		queue_free()

func spawn_effect(EFFECT: PackedScene, effect_position: Vector2 = global_position):
	if EFFECT:
		var effect = EFFECT.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = effect_position
		return effect

func spawn_indicator(amount: int):
	var indicator = spawn_effect(Utils.INDICATOR_DAMAGE)
	if indicator:
		indicator.position.y += spawn_indicator_offset
		indicator.label.text = "+" + str(amount) + "g"
