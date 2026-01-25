extends Area2D

func _on_body_entered(body):
	if body is Player:
		Game.jetpack = true
		body.jetpack_enabled = true
		var tween = get_tree().create_tween()
		var tween1 = get_tree().create_tween()
		tween.tween_property(self, "position", position - Vector2(0, 30), .3)
		tween1.tween_property(self, "modulate:a", 0, .3)
		tween.tween_callback(queue_free)
		Utils.saveGame()
		Events.emit_signal("jetpack_collected")

# use this for when we acquire money for upgrades
#func _on_body_entered(body):
#	if body is Player:
#		Game.gold += 5
#		var tween = get_tree().create_tween()
#		var tween1 = get_tree().create_tween()
#		tween.tween_property(self, "position", position - Vector2(0, 30), .3)
#		tween1.tween_property(self, "modulate:a", 0, .3)
#		tween.tween_callback(queue_free)
