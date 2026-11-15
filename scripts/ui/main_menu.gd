extends Control
## Main Menu screen for LAST SIGNAL.
## Provides Start Game, Level Select, and Exit actions using official team art assets.

@onready var start_button: TextureButton = $CenterContainer/VBoxContainer/ButtonsContainer/StartButton
@onready var select_button: TextureButton = $CenterContainer/VBoxContainer/ButtonsContainer/SelectButton
@onready var exit_button: TextureButton = $CenterContainer/VBoxContainer/ButtonsContainer/ExitButton


func _ready() -> void:
	if is_instance_valid(start_button):
		start_button.pressed.connect(_on_start_pressed)
		start_button.grab_focus()
	if is_instance_valid(select_button):
		select_button.pressed.connect(_on_select_pressed)
	if is_instance_valid(exit_button):
		exit_button.pressed.connect(_on_exit_pressed)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_select_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()

