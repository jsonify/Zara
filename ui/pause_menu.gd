extends CanvasLayer

@onready var panel := $Panel

func _ready():
	hide_menu()

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		hide_menu()
	else:
		show_menu()

func show_menu():
	panel.visible = true
	get_tree().paused = true

func hide_menu():
	panel.visible = false
	get_tree().paused = false

func _on_resume_pressed():
	hide_menu()

func _on_main_menu_pressed():
	hide_menu()
	get_tree().change_scene_to_file("res://ui/main.tscn")

func _on_quit_pressed():
	get_tree().quit()
