extends CharacterBody2D

@export var resource : Resource
@onready var sprite = $Sprite2D
@onready var health: int
@onready var ledge_checker := $LedgeChecker

func _ready():
	sprite.texture = resource.texture
	health = resource.health
	velocity.x = 25
	

func _physics_process(_delta):
	move()

func move():
	var found_wall = is_on_wall()
	if found_wall:
		velocity.x *= -1

	print(is_on_floor())
		
	move_and_slide()
