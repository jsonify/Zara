extends CanvasLayer

## Debug panel for testing. Enable dev_mode to show on startup.

@export var dev_mode := false

@onready var panel := $Panel
@onready var toggle_btn := $ToggleBtn

var panel_visible := false
var health_bar_visible := true
var fuel_bar_visible := true

func _ready():
	panel.visible = false
	toggle_btn.visible = dev_mode
	if dev_mode:
		show_panel()

func _unhandled_input(event):
	if event.is_action_pressed("debug_toggle"):
		toggle_panel()
		get_viewport().set_input_as_handled()

func toggle_panel():
	if panel_visible:
		hide_panel()
	else:
		show_panel()

func show_panel():
	panel_visible = true
	panel.visible = true
	toggle_btn.visible = false
	_refresh_values()

func hide_panel():
	panel_visible = false
	panel.visible = false
	if dev_mode:
		toggle_btn.visible = true

func _refresh_values():
	$Panel/VBox/HPRow/Val.text = str(Game.player_hp)
	$Panel/VBox/GoldRow/Val.text = str(Game.gold)
	$Panel/VBox/FuelRow/Val.text = str(int(Game.fuel_level))

func _process(_delta):
	if panel_visible:
		_refresh_values()

# HP controls
func _on_hp_down():
	Game.player_hp = max(0, Game.player_hp - 5)
func _on_hp_up():
	Game.player_hp = min(Game.max_player_hp, Game.player_hp + 5)

# Gold controls
func _on_gold_down():
	Game.gold = max(0, Game.gold - 10)
func _on_gold_up():
	Game.gold += 10

# Fuel controls
func _on_fuel_down():
	Game.fuel_level = max(0, Game.fuel_level - 5)
func _on_fuel_up():
	Game.fuel_level = min(Game.max_fuel_level, Game.fuel_level + 5)

# Quick actions
func _on_max_pressed():
	Game.player_hp = Game.max_player_hp
	Game.fuel_level = Game.max_fuel_level

func _on_gold_100_pressed():
	Game.gold += 100

func _on_items_pressed():
	Game.add_item("health_potion", 5)
	Game.add_item("fuel_canister", 5)

func _on_unlock_pressed():
	Game.jetpack = true
	Game.dash = true
	Game.slide = true

func _on_close_pressed():
	hide_panel()

func _on_toggle_btn_pressed():
	show_panel()

# UI visibility toggles - these use modulate.a not visible
func _on_toggle_hp_pressed():
	health_bar_visible = !health_bar_visible
	var ui = get_tree().get_first_node_in_group("game_ui")
	if ui:
		var health_node = ui.get_node_or_null("Health")
		if health_node:
			health_node.modulate.a = 1.0 if health_bar_visible else 0.0
	$Panel/VBox/ToggleRow/HP.text = "HP:" + ("On" if health_bar_visible else "Off")

func _on_toggle_fuel_pressed():
	fuel_bar_visible = !fuel_bar_visible
	var ui = get_tree().get_first_node_in_group("game_ui")
	if ui:
		var fuel_node = ui.get_node_or_null("Fuel")
		if fuel_node:
			fuel_node.modulate.a = 1.0 if fuel_bar_visible else 0.0
	$Panel/VBox/ToggleRow/Fuel.text = "F:" + ("On" if fuel_bar_visible else "Off")
