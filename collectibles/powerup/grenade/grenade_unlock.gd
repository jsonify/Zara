extends Area2D

## Grenade ability unlock pickup

func _on_body_entered(body):
	if body is Player:
		Game.has_grenades = true

		# Pickup animation - float up and fade
		var tween = get_tree().create_tween()
		var tween_fade = get_tree().create_tween()
		tween.tween_property(self, "position", position - Vector2(0, 30), 0.3)
		tween_fade.tween_property(self, "modulate:a", 0, 0.3)
		tween.tween_callback(queue_free)

		Utils.saveGame()
		Events.emit_signal("grenades_collected")
