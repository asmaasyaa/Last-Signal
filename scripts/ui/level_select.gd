extends Control
## Level Select map for LAST SIGNAL.
## Only Stage 1 Level 1 may start a normal gameplay run from Level Select.
## Stage 1 Levels 2-3 remain accessible through normal gameplay progression, not direct level selection.
## All unimplemented/locked stages remain unavailable with clear status notifications.

signal level_selected(stage: int, level: int)

@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var back_button: Button = $VBoxContainer/TopBar/BackButton

# Dictionary mapping Vector2i(stage, level) -> TextureButton
var level_buttons: Dictionary = {}


func _ready() -> void:
	if is_instance_valid(back_button):
		back_button.pressed.connect(_on_back_pressed)

	_setup_buttons()


func _setup_buttons() -> void:
	for s in range(1, 4):
		for l in range(1, 6):
			var btn_path = "VBoxContainer/StagesContainer/Stage%d/LevelsContainer/L%d" % [s, l]
			var btn = get_node_or_null(btn_path)
			if is_instance_valid(btn) and btn is TextureButton:
				level_buttons[Vector2i(s, l)] = btn
				var is_playable: bool = is_level_playable(s, l)
				btn.disabled = not is_playable
				if not is_playable:
					btn.modulate = Color(0.45, 0.45, 0.45, 0.6)
				else:
					btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
				btn.pressed.connect(_on_level_button_pressed.bind(s, l))
				btn.gui_input.connect(_on_level_button_gui_input.bind(s, l))


func is_level_playable(stage: int, level: int) -> bool:
	# Only Stage 1 Level 1 may start a normal gameplay run directly from Level Select.
	# Stage 1 Levels 2-3 are unlocked through normal gameplay progression, not direct selection.
	return stage == 1 and level == 1


func _on_level_button_pressed(stage: int, level: int) -> void:
	level_selected.emit(stage, level)

	if not is_level_playable(stage, level):
		_show_locked_status(stage, level)
		return

	set_status("Launching Stage 1 Level 1...")
	_launch_level(stage, level)


func _on_level_button_gui_input(event: InputEvent, stage: int, level: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_level_playable(stage, level):
			level_selected.emit(stage, level)
			_show_locked_status(stage, level)


func _show_locked_status(stage: int, level: int) -> void:
	if stage == 1:
		if level == 2 or level == 3:
			set_status("Stage 1 Level %d: Accessible via gameplay progression from Level 1." % level)
		else:
			set_status("Stage 1 Level %d not yet implemented." % level)
	else:
		set_status("Stage %d not yet implemented (Reserved for future stages)." % stage)


func _launch_level(stage: int, level: int) -> void:
	# Guard: Only Stage 1 Level 1 may launch gameplay from Level Select
	if not is_level_playable(stage, level):
		_show_locked_status(stage, level)
		return

	var main_script = load("res://scripts/main.gd")
	if main_script != null and "requested_start_level" in main_script:
		main_script.requested_start_level = 1
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func set_status(text: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = text


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
