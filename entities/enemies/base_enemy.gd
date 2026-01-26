extends CharacterBody2D
class_name BaseEnemy

@onready var sprite := $Marker2D/Sprite2D
@onready var ledge_check := $Marker2D/LedgeCheck
@onready var marker_2D = $Marker2D
@onready var damageable := $Damageable
@onready var hurt_box := $HurtBox

@export var speed := 10
@export var speed_multiplier := 1

var can_patrol := false
var direction = Vector2.RIGHT
var is_dead := false

var player = null

func _ready():
	# Connect damage signals
	if damageable:
		damageable.on_hit.connect(_on_damageable_hit)
	if hurt_box:
		hurt_box.take_damage.connect(_on_hurt_box_take_damage)

func _physics_process(_delta):
	if is_dead:
		return
	detect_turn_around()
	patrol()
	move_and_slide()

func patrol():
	velocity = direction * speed * speed_multiplier
	

func detect_turn_around():
	var found_wall = is_on_wall()
	var found_ground = !ledge_check.is_colliding()

	if found_wall or found_ground:
		direction *= -1

	if direction.x == 1:
		marker_2D.scale.x = 1
	else:
		marker_2D.scale.x = -1

func _on_damageable_hit(_node: Node, _damage_taken: int, knockback_direction: Vector2):
	# Apply knockback
	velocity = knockback_direction * 100

	# Flash effect
	_flash_damage()

	# Check for death
	if damageable.health <= 0:
		_die()

func _on_hurt_box_take_damage(amount: int, knockback_direction: Vector2):
	if damageable:
		damageable.hit(amount, knockback_direction)

func _flash_damage():
	# Simple flash effect
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.RED, 0.05)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.05)

func _die():
	is_dead = true

	# Drop gold
	if damageable:
		damageable._drop_gold()

	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
