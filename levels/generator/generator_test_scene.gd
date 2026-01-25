extends Node2D

## Test scene for the level generator.
## Press the Generate button or R key to create a new level.

@onready var generator: Node2D = $StandaloneGenerator
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var ui: CanvasLayer = $UI
@onready var seed_label: Label = $UI/Panel/VBox/SeedLabel
@onready var difficulty_slider: HSlider = $UI/Panel/VBox/DifficultySlider
@onready var difficulty_label: Label = $UI/Panel/VBox/DifficultyLabel

var current_difficulty := 5


func _ready() -> void:
	difficulty_slider.value = current_difficulty
	_update_difficulty_label()
	_generate_new_level()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

	# Press R to regenerate
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_generate_new_level()


func _generate_new_level() -> void:
	generator.generate(0, current_difficulty)
	player.global_position = generator.get_player_spawn()
	seed_label.text = "Seed: " + str(generator.seed_value)


func _on_generate_button_pressed() -> void:
	_generate_new_level()


func _on_difficulty_slider_value_changed(value: float) -> void:
	current_difficulty = int(value)
	_update_difficulty_label()


func _update_difficulty_label() -> void:
	difficulty_label.text = "Difficulty: " + str(current_difficulty)
