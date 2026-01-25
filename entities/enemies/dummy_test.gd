extends CharacterBody2D

@export var speed := 10
@export var speed_multiplier := 1

var direction = Vector2.RIGHT

func _physics_process(_delta):
	detect_turn_around()
	patrol()
	move_and_slide()

func patrol():
	velocity = direction * speed * speed_multiplier
	

func detect_turn_around():
	
	var found_wall = is_on_wall()
#	var found_ground = !ledge_check.is_colliding()
	
	if found_wall:
		direction *= -1
	
	if direction.x == 1:
		scale.x = 1
	else:
		scale.x = -1


func _on_hurt_box_area_entered(_area):
	queue_free()
