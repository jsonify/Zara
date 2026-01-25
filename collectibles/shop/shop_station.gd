extends Area2D

@onready var take_sign := $TakeSign
@onready var shop_menu := $ShopMenu

var player_in_range := false

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("take"):
		shop_menu.show_menu()

func _on_body_entered(body):
	if body is Player:
		player_in_range = true
		take_sign.visible = true

func _on_body_exited(body):
	if body is Player:
		player_in_range = false
		take_sign.visible = false
