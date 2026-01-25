extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var raycast = $RayCast2D
@onready var detection_area = $DetectionArea

@export var speed := 100
@export var chase_speed := 200
@export var detection_range := 200
@export var detection_area_size := Vector2(200, 200)
@export var raycast_distance := 50

var player_chase := false
var player = null

func _ready():
	# Configure detection area if it has a collision shape
	if detection_area and detection_area.has_node("CollisionShape2D"):
		var shape = detection_area.get_node("CollisionShape2D")
		if shape.shape is RectangleShape2D:
			shape.shape.size = detection_area_size

func _physics_process(_delta):
	# Check if player is out of detection range
	if player and abs(player.global_position.x - global_position.x) > detection_range:
		player_chase = false

	if player_chase and player:
		# Chase the player
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * chase_speed
		if direction.x != 0:
			sprite.scale.x = sign(direction.x)
	else:
		# Patrol logic
		if raycast:
			raycast.target_position = Vector2(sprite.scale.x * raycast_distance, 0)
			raycast.force_raycast_update()
			if not raycast.is_colliding() or is_on_wall():
				sprite.scale.x *= -1

		velocity.x = speed * sprite.scale.x

	move_and_slide()

func _on_detection_area_body_entered(body):
	if body is Player:
		player = body
		player_chase = true

func _on_detection_area_body_exited(body):
	if body is Player:
		player = null
		player_chase = false
