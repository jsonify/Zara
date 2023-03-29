extends Area2D

class_name Bullet

@export var damage = 1

var direction := Vector2.RIGHT
var speed := 200

func _ready():
	look_at(position + direction)

func _process(delta):
	translate(direction.normalized() * speed * delta)
	

# TODO: add timer to remove bullets

func _on_body_entered(_body):
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()


func _on_timer_timeout():
	queue_free()


func _on_area_entered(area):
#	pass
	print("Hit " + str(area.name))
#	var enemy = area.get_parent()
#	print(enemy.name)
#	if "FlowerEnemy" in enemy.name:
#		print(enemy.name)
#	enemy.take_damage(damage)
#	enemy.queue_free()
