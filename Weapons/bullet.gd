extends Area2D

var direction := Vector2.RIGHT
var speed := 200

func _process(delta):
	translate(direction.normalized() * speed * delta)

func _on_body_entered(body):
	# do damage
	print("Hit")
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
