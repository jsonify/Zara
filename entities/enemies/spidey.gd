extends BaseEnemy
class_name Spidey

@onready var animation_player := $AnimationPlayer
@onready var timer := $Timer


func _process(_delta):
	animation_player.play("walk")
	

func _on_timer_timeout():
	speed_multiplier = 1


func _on_detection_area_player_detected(_body):
	speed_multiplier = 5


func _on_detection_area_player_undetected(_body):
	timer.start()
