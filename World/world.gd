extends Node2D

const PlayerScene = preload("res://Player/player.tscn")
const JetPack = preload("res://PowerUps/jet_pack.tscn")

var player_spawn_location = Vector2.ZERO

@onready var camera := $Camera2D
@onready var player := $Player
@onready var timer := $Timer

@export var jetpack_offset := 20

func _ready():
	RenderingServer.set_default_clear_color(Color.DARK_SLATE_GRAY)
	player.connect_camera(camera)
	player_spawn_location = player.global_position
	Events.player_died.connect(_on_player_died)
	Events.hit_checkpoint.connect(_on_hit_checkpoint)
	Events.platform_activated.connect(_on_power_up_platform_activated)


func _on_player_died():
	timer.start(1.0)
	await timer.timeout
	var player = PlayerScene.instantiate()
	add_child(player)
	player.position = player_spawn_location
	player.connect_camera(camera)


func _on_hit_checkpoint(checkpoint_position):
	player_spawn_location = checkpoint_position


func _on_power_up_platform_activated():
	var jetpack = JetPack.instantiate()
	add_child(jetpack)
	var platform_position = get_node("PowerUpPlatform/PlatformWarpAnimatedSprite")
	jetpack.position = get_node("PowerUpPlatform").position
	jetpack.position.y -= jetpack_offset


func _on_button_pressed():
	pass # Replace with function body.
