extends CharacterBody2D

@onready var animation_player := $AnimationPlayer
@onready var sprite := $Marker2D/Sprite2D
@onready var ground_right_check := $Marker2D/GroundRightCheck
@onready var marker_2D = $Marker2D

@export var normal_speed := 10
@export var chase_speed := 50

var direction = Vector2.RIGHT
#var speed

var player_chase := false
var player = null

func _physics_process(delta):
	detect_turn_around()
	detect_chase()
	
	
			
	velocity = direction * normal_speed

	move_and_slide()
			
func detect_turn_around():
	var found_wall = is_on_wall()
	var found_ground = !ground_right_check.is_colliding()
	
	if found_wall or found_ground:
		direction *= -1
	
	if direction.x == 1:
		marker_2D.scale.x = 1
	else:
		marker_2D.scale.x = -1

func detect_chase():
	if player_chase:
		position.x += (player.position.x - position.x) / chase_speed
		
		if player.position.x - position.x > 0:
			marker_2D.scale.x = 1
		else:
			marker_2D.scale.x = -1

func _on_detection_area_body_entered(body):
#	pass
	if body is Player:
		player = body
		player_chase = true
		print(player_chase)
#		if player.position.x < position.x:
#			velocity.x += chase_speed
#		else:
#			scale.x = 1
#		speed = chase_speed
		

func _on_detection_area_body_exited(body):
#	pass
	if body is Player:
		player = null
		player_chase = false