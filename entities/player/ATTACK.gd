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
	if not can_attack:
		# Can't attack yet, return to idle
		next_state = get_parent().get_node("IDLE") as UnifiedState
		return

	attacking = true
	can_attack = false
	animation_player.play("attack")
	attack_timer.start(attack_duration)

	# Enable hitbox during attack
	if hitbox:
		hitbox.monitoring = true

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
