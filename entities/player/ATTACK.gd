extends UnifiedState

## Melee attack state for player

@export var attack_duration := 0.3
@export var attack_damage := 1
@export var attack_cooldown := 0.2

@onready var attack_timer := $AttackTimer
@onready var cooldown_timer := $CooldownTimer
@onready var hitbox := $AttackHitBox

var attacking := false
var can_attack := true

func _ready():
	# Ensure hitbox starts disabled
	if hitbox:
		hitbox.monitoring = false

func state_process(_delta) -> UnifiedState:
	if not attacking:
		return get_parent().get_node("IDLE") as UnifiedState
	return null

func on_enter():
	print("ATTACK: on_enter called, can_attack=", can_attack)
	if not can_attack:
		# Can't attack yet, return to idle
		print("ATTACK: Can't attack, returning to IDLE")
		next_state = get_parent().get_node("IDLE") as UnifiedState
		return

	attacking = true
	can_attack = false
	print("ATTACK: Starting attack animation")
	animation_player.play("attack")
	attack_timer.start(attack_duration)

	# Position hitbox based on player facing direction (use global position since parent is Node, not Node2D)
	var player := character as Player
	if hitbox:
		var hitbox_offset_x = 10
		var hitbox_offset_y = -5  # At player torso level
		if player.direction == "left":
			hitbox.global_position = player.global_position + Vector2(-hitbox_offset_x, hitbox_offset_y)
		else:
			hitbox.global_position = player.global_position + Vector2(hitbox_offset_x, hitbox_offset_y)
		hitbox.monitoring = true
		print("ATTACK: Player at ", player.global_position, ", Hitbox global: ", hitbox.global_position)

func on_exit():
	attacking = false
	# Disable hitbox when exiting attack
	if hitbox:
		hitbox.monitoring = false
	# Start cooldown
	cooldown_timer.start(attack_cooldown)

func _on_attack_timer_timeout():
	attacking = false

func _on_cooldown_timer_timeout():
	can_attack = true
