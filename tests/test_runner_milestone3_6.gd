extends Node
## Test runner logic for Milestone 3.6 (Team Asset Integration - Batch 01).
## Validates Player official sprite integration, visual state switching, fallback toggling,
## asset integrity, modular menu UI (Main Menu, Level Select), progression protection,
## and zero gameplay regression.

var total_count: int = 0
var pass_count: int = 0
var fail_count: int = 0

const PLAYER_SCENE = preload("res://scenes/player.tscn")
const ASTEROID_SCENE = preload("res://scenes/asteroid.tscn")
const MAIN_SCENE = preload("res://scenes/main.tscn")
const MAIN_MENU_SCENE = preload("res://scenes/ui/main_menu.tscn")
const LEVEL_SELECT_SCENE = preload("res://scenes/ui/level_select.tscn")


func _ready() -> void:
	await get_tree().process_frame
	await run_all_suites()
	_print_summary()
	get_tree().quit(0 if fail_count == 0 else 1)


func assert_true(condition: bool, description: String) -> void:
	total_count += 1
	if condition:
		pass_count += 1
		print("  [PASS] %s" % description)
	else:
		fail_count += 1
		printerr("  [FAIL] %s" % description)


func assert_eq(actual, expected, description: String) -> void:
	total_count += 1
	if actual == expected:
		pass_count += 1
		print("  [PASS] %s (expected: %s, got: %s)" % [description, str(expected), str(actual)])
	else:
		fail_count += 1
		printerr("  [FAIL] %s (FAILED: expected %s, got %s)" % [description, str(expected), str(actual)])


func run_all_suites() -> void:
	print("==================================================")
	print("LAST SIGNAL — Milestone 3.6 Automated Test Suite")
	print("==================================================")
	await test_suite_1_player_visual_state_and_lifecycle()
	await test_suite_2_player_collision_and_transform_preservation()
	await test_suite_3_asset_integrity_and_file_verification()
	await test_suite_4_main_menu_ui_integration()
	await test_suite_5_level_select_ui_and_progression_protection()
	await test_suite_6_direct_gameplay_execution_and_integration()


# ==============================================================================
# SUITE 1: PLAYER VISUAL STATE & LIFECYCLE SWITCHING
# ==============================================================================
func test_suite_1_player_visual_state_and_lifecycle() -> void:
	print("\n--- Running Suite 1: Player Visual State & Lifecycle Switching ---")
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	var visuals: Node2D = player.get_node_or_null("Visuals")
	assert_true(is_instance_valid(visuals), "Player contains 'Visuals' container")

	var official_art: Node2D = visuals.get_node_or_null("OfficialArt")
	assert_true(is_instance_valid(official_art), "Visuals contains 'OfficialArt' container")

	var alive_sprite: Sprite2D = official_art.get_node_or_null("AliveSprite")
	var dead_sprite: Sprite2D = official_art.get_node_or_null("DeadSprite")
	var fallback: Node2D = visuals.get_node_or_null("ProceduralFallback")

	assert_true(is_instance_valid(alive_sprite), "OfficialArt contains 'AliveSprite' Sprite2D")
	assert_true(is_instance_valid(dead_sprite), "OfficialArt contains 'DeadSprite' Sprite2D")
	assert_true(alive_sprite.texture != null, "AliveSprite has official texture assigned")
	assert_true(dead_sprite.texture != null, "DeadSprite has official texture assigned")

	# Initial alive state
	assert_true(player.alive, "Player is alive initially")
	assert_true(alive_sprite.visible, "AliveSprite is visible in alive state")
	assert_true(not dead_sprite.visible, "DeadSprite is hidden in alive state")
	assert_true(not fallback.visible, "Procedural fallback is hidden when official art is active")

	# Fatal damage -> Dead state
	player.take_damage(12)
	assert_true(not player.alive, "Player alive is false after 12 damage")
	assert_eq(player.health, 0, "Player HP is 0")
	assert_true(not alive_sprite.visible, "AliveSprite is hidden in dead state")
	assert_true(dead_sprite.visible, "DeadSprite is visible in dead state")
	assert_true(not fallback.visible, "Procedural fallback remains hidden during official dead state")

	# Revive via reset_state
	player.reset_state()
	assert_true(player.alive, "Player alive is true after reset_state")
	assert_eq(player.health, 12, "Player HP restored to 12")
	assert_true(alive_sprite.visible, "AliveSprite restores to visible on reset_state")
	assert_true(not dead_sprite.visible, "DeadSprite hides on reset_state")

	# Revive via prepare_for_level
	player.take_damage(12)
	assert_true(dead_sprite.visible, "DeadSprite visible after second fatal hit")
	player.prepare_for_level(8)
	assert_true(player.alive, "Player alive is true after prepare_for_level")
	assert_eq(player.health, 8, "Player HP set to starting health (8)")
	assert_true(alive_sprite.visible, "AliveSprite restores to visible on prepare_for_level")
	assert_true(not dead_sprite.visible, "DeadSprite hides on prepare_for_level")

	# Fallback activation when official art is disabled
	player.official_art_enabled = false
	player.update_visual_state()
	assert_true(not alive_sprite.visible, "AliveSprite hidden when official_art_enabled is false")
	assert_true(not dead_sprite.visible, "DeadSprite hidden when official_art_enabled is false")
	assert_true(fallback.visible, "Procedural fallback automatically activates when official art is disabled")

	# Re-enable official art
	player.official_art_enabled = true
	player.update_visual_state()
	assert_true(alive_sprite.visible, "AliveSprite restores when official_art_enabled is re-enabled")
	assert_true(not fallback.visible, "Procedural fallback re-hides when official art is re-enabled")

	player.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 2: PLAYER COLLISION & TRANSFORM PRESERVATION
# ==============================================================================
func test_suite_2_player_collision_and_transform_preservation() -> void:
	print("\n--- Running Suite 2: Player Collision & Transform Preservation ---")
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	assert_eq(player.scale, Vector2.ONE, "Player Area2D root scale is Vector2.ONE")

	var col_shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D")
	assert_true(is_instance_valid(col_shape), "CollisionShape2D is direct child of Player root")
	assert_true(col_shape.shape is CircleShape2D, "Player collision shape is CircleShape2D")
	assert_eq(col_shape.shape.radius, 20.0, "Player collision radius remains strictly 20.0 px")
	assert_eq(player.collision_layer, 1, "Player collision_layer remains 1 (Layer 1: Player)")
	assert_eq(player.collision_mask, 2, "Player collision_mask remains 2 (Layer 2: Hazards)")

	var visuals: Node2D = player.get_node_or_null("Visuals")
	assert_eq(visuals.scale, Vector2.ONE, "Visuals container scale remains Vector2.ONE")

	var official_art: Node2D = visuals.get_node_or_null("OfficialArt")
	assert_eq(official_art.scale, Vector2.ONE, "OfficialArt container scale remains Vector2.ONE")

	var alive_sprite: Sprite2D = official_art.get_node_or_null("AliveSprite")
	var dead_sprite: Sprite2D = official_art.get_node_or_null("DeadSprite")

	assert_eq(alive_sprite.scale, Vector2(0.2, 0.2), "AliveSprite visual scale is Vector2(0.2, 0.2)")
	assert_eq(dead_sprite.scale, Vector2(0.2, 0.2), "DeadSprite visual scale is Vector2(0.2, 0.2)")
	assert_true(alive_sprite.centered, "AliveSprite centered property is true")
	assert_true(dead_sprite.centered, "DeadSprite centered property is true")
	assert_eq(alive_sprite.offset, Vector2.ZERO, "AliveSprite offset is Vector2.ZERO (aligned at origin)")
	assert_eq(dead_sprite.offset, Vector2.ZERO, "DeadSprite offset is Vector2.ZERO (aligned at origin)")

	player.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 3: ASSET INTEGRITY & FILE VERIFICATION
# ==============================================================================
func test_suite_3_asset_integrity_and_file_verification() -> void:
	print("\n--- Running Suite 3: Asset Integrity & File Verification ---")

	var required_assets: Array[String] = [
		# Player
		"res://assets/sprites/player/player_alive.png",
		"res://assets/sprites/player/player_dead.png",
		# Stage 2 Mini-Boss
		"res://assets/sprites/bosses/stage2_miniboss/miniboss_alive_p1.png",
		"res://assets/sprites/bosses/stage2_miniboss/miniboss_alive_p2.png",
		"res://assets/sprites/bosses/stage2_miniboss/miniboss_dead.png",
		# Stage 3 Boss Core & Moving Parts
		"res://assets/sprites/bosses/stage3_boss/boss_alive_p1.png",
		"res://assets/sprites/bosses/stage3_boss/boss_alive_p2.png",
		"res://assets/sprites/bosses/stage3_boss/boss_alive_p3.png",
		"res://assets/sprites/bosses/stage3_boss/boss_alive_p4.png",
		"res://assets/sprites/bosses/stage3_boss/boss_dead.png",
		"res://assets/sprites/bosses/stage3_boss/boss_wheel_top.png",
		"res://assets/sprites/bosses/stage3_boss/boss_wheel_bottom.png",
		"res://assets/sprites/bosses/stage3_boss/boss_ropes.png",
		"res://assets/sprites/bosses/stage3_boss/boss_reference_assembled_p1.png",
		"res://assets/sprites/bosses/stage3_boss/boss_reference_assembled_dead.png",
		# UI Buttons
		"res://assets/ui/buttons/btn_start.png",
		"res://assets/ui/buttons/btn_select.png",
		"res://assets/ui/buttons/btn_exit.png",
		"res://assets/ui/buttons/btn_circle_decor.png",
		# Stage 1 Level Buttons
		"res://assets/ui/buttons/stage1_l1.png",
		"res://assets/ui/buttons/stage1_l2.png",
		"res://assets/ui/buttons/stage1_l3.png",
		"res://assets/ui/buttons/stage1_l4.png",
		"res://assets/ui/buttons/stage1_l5.png",
		# Stage 2 Level Buttons
		"res://assets/ui/buttons/stage2_l1.png",
		"res://assets/ui/buttons/stage2_l2.png",
		"res://assets/ui/buttons/stage2_l3_raw.png",
		"res://assets/ui/buttons/stage2_l3_cropped.png",
		"res://assets/ui/buttons/stage2_l4.png",
		"res://assets/ui/buttons/stage2_l5.png",
		# Stage 3 Level Buttons
		"res://assets/ui/buttons/stage3_l1.png",
		"res://assets/ui/buttons/stage3_l2.png",
		"res://assets/ui/buttons/stage3_l3.png",
		"res://assets/ui/buttons/stage3_l4.png",
		"res://assets/ui/buttons/stage3_l5.png",
		# UI Labels
		"res://assets/ui/labels/label_overheat.png"
	]

	for path in required_assets:
		var tex = ResourceLoader.load(path)
		assert_true(tex != null and tex is Texture2D, "Asset exists and loads as Texture2D: %s" % path)

	# Verify Player texture dimensions
	var player_alive_tex = ResourceLoader.load("res://assets/sprites/player/player_alive.png") as Texture2D
	assert_eq(player_alive_tex.get_size(), Vector2(256, 256), "Player alive texture dimensions are 256x256")

	var player_dead_tex = ResourceLoader.load("res://assets/sprites/player/player_dead.png") as Texture2D
	assert_eq(player_dead_tex.get_size(), Vector2(264, 264), "Player dead texture dimensions are 264x264")

	# Verify Stage 2 Level 3 non-destructive cropped derivative dimensions
	var stage2_l3_cropped = ResourceLoader.load("res://assets/ui/buttons/stage2_l3_cropped.png") as Texture2D
	assert_eq(stage2_l3_cropped.get_size(), Vector2(737, 84), "Stage 2 L3 cropped bounding box dimensions are 737x84")

	# Verify raw original Stage 2 Level 3 preserved intact
	var stage2_l3_raw = ResourceLoader.load("res://assets/ui/buttons/stage2_l3_raw.png") as Texture2D
	assert_eq(stage2_l3_raw.get_size(), Vector2(1920, 1080), "Stage 2 L3 raw canvas dimensions preserved intact at 1920x1080")


# ==============================================================================
# SUITE 4: MAIN MENU UI INTEGRATION
# ==============================================================================
func test_suite_4_main_menu_ui_integration() -> void:
	print("\n--- Running Suite 4: Main Menu UI Integration ---")
	var menu = MAIN_MENU_SCENE.instantiate()
	add_child(menu)
	await get_tree().process_frame

	assert_true(is_instance_valid(menu), "MainMenu scene instantiates cleanly")
	assert_true(menu is Control, "MainMenu root is a Control node")

	var start_btn = menu.get_node_or_null("CenterContainer/VBoxContainer/ButtonsContainer/StartButton") as TextureButton
	var select_btn = menu.get_node_or_null("CenterContainer/VBoxContainer/ButtonsContainer/SelectButton") as TextureButton
	var exit_btn = menu.get_node_or_null("CenterContainer/VBoxContainer/ButtonsContainer/ExitButton") as TextureButton

	assert_true(is_instance_valid(start_btn), "MainMenu contains StartButton TextureButton")
	assert_true(is_instance_valid(select_btn), "MainMenu contains SelectButton TextureButton")
	assert_true(is_instance_valid(exit_btn), "MainMenu contains ExitButton TextureButton")

	assert_true(start_btn.texture_normal != null, "StartButton has texture_normal assigned")
	assert_true(select_btn.texture_normal != null, "SelectButton has texture_normal assigned")
	assert_true(exit_btn.texture_normal != null, "ExitButton has texture_normal assigned")

	assert_true(start_btn.is_connected("pressed", menu._on_start_pressed), "StartButton connected to _on_start_pressed")
	assert_true(select_btn.is_connected("pressed", menu._on_select_pressed), "SelectButton connected to _on_select_pressed")
	assert_true(exit_btn.is_connected("pressed", menu._on_exit_pressed), "ExitButton connected to _on_exit_pressed")

	assert_eq(start_btn.focus_mode, Control.FOCUS_ALL, "StartButton has full focus navigation enabled")

	menu.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 5: LEVEL SELECT UI & PROGRESSION PROTECTION
# ==============================================================================
func test_suite_5_level_select_ui_and_progression_protection() -> void:
	print("\n--- Running Suite 5: Level Select UI & Progression Protection ---")
	var level_select = LEVEL_SELECT_SCENE.instantiate()
	add_child(level_select)
	await get_tree().process_frame

	assert_true(is_instance_valid(level_select), "LevelSelect scene instantiates cleanly")
	assert_true(level_select is Control, "LevelSelect root is a Control node")

	var back_btn = level_select.get_node_or_null("VBoxContainer/TopBar/BackButton") as Button
	assert_true(is_instance_valid(back_btn), "LevelSelect contains BackButton")
	assert_true(back_btn.is_connected("pressed", level_select._on_back_pressed), "BackButton connected to _on_back_pressed")

	var status_lbl = level_select.get_node_or_null("VBoxContainer/StatusLabel") as Label
	assert_true(is_instance_valid(status_lbl), "LevelSelect contains StatusLabel")
	assert_eq(status_lbl.text, "SELECT A MISSION LEVEL", "StatusLabel initialized with default instruction")

	# Check all 15 buttons registered
	assert_eq(level_select.level_buttons.size(), 15, "All 15 stage/level buttons registered")

	# Playable checks (Only Stage 1 Level 1 is directly playable from Level Select)
	assert_true(level_select.is_level_playable(1, 1), "Stage 1 Level 1 is PLAYABLE from Level Select")
	assert_true(not level_select.is_level_playable(1, 2), "Stage 1 Level 2 is LOCKED from direct selection (accessible via progression)")
	assert_true(not level_select.is_level_playable(1, 3), "Stage 1 Level 3 is LOCKED from direct selection (accessible via progression)")
	assert_true(not level_select.is_level_playable(1, 4), "Stage 1 Level 4 is LOCKED (unimplemented)")
	assert_true(not level_select.is_level_playable(1, 5), "Stage 1 Level 5 is LOCKED (unimplemented)")
	assert_true(not level_select.is_level_playable(2, 1), "Stage 2 Level 1 is LOCKED (future stage)")
	assert_true(not level_select.is_level_playable(2, 3), "Stage 2 Level 3 is LOCKED (future stage)")
	assert_true(not level_select.is_level_playable(3, 1), "Stage 3 Level 1 is LOCKED (future stage)")
	assert_true(not level_select.is_level_playable(3, 5), "Stage 3 Level 5 is LOCKED (future stage)")

	# Verify button enabled/disabled states in scene tree
	var s1l1_btn: TextureButton = level_select.level_buttons[Vector2i(1, 1)]
	var s1l2_btn: TextureButton = level_select.level_buttons[Vector2i(1, 2)]
	var s1l3_btn: TextureButton = level_select.level_buttons[Vector2i(1, 3)]
	var s1l4_btn: TextureButton = level_select.level_buttons[Vector2i(1, 4)]
	var s2l1_btn: TextureButton = level_select.level_buttons[Vector2i(2, 1)]
	var s3l1_btn: TextureButton = level_select.level_buttons[Vector2i(3, 1)]

	assert_true(not s1l1_btn.disabled, "Stage 1 Level 1 button is enabled")
	assert_true(s1l2_btn.disabled, "Stage 1 Level 2 button is disabled")
	assert_true(s1l3_btn.disabled, "Stage 1 Level 3 button is disabled")
	assert_true(s1l4_btn.disabled, "Stage 1 Level 4 button is disabled")
	assert_true(s2l1_btn.disabled, "Stage 2 Level 1 button is disabled")
	assert_true(s3l1_btn.disabled, "Stage 3 Level 1 button is disabled")

	# Test clicking locked levels does not crash and updates status label
	var selected_signals: Array = []
	level_select.level_selected.connect(func(s, l): selected_signals.append([s, l]))

	# Test Stage 1 Level 2 progression notice
	level_select._on_level_button_pressed(1, 2)
	assert_eq(selected_signals.size(), 1, "level_selected signal emitted for Stage 1 Level 2")
	assert_eq(selected_signals[0], [1, 2], "Emitted signal contains [1, 2]")
	assert_true(status_lbl.text.contains("Accessible via gameplay progression"), "StatusLabel updated with S1L2 progression notice")

	# Test Stage 1 Level 3 progression notice
	level_select._on_level_button_pressed(1, 3)
	assert_true(status_lbl.text.contains("Accessible via gameplay progression"), "StatusLabel updated with S1L3 progression notice")

	# Test locked levels
	level_select._on_level_button_pressed(2, 1)
	assert_true(status_lbl.text.contains("Stage 2 not yet implemented"), "StatusLabel updated with Stage 2 locked notice")

	level_select._on_level_button_pressed(1, 4)
	assert_true(status_lbl.text.contains("Stage 1 Level 4 not yet implemented"), "StatusLabel updated with S1L4 locked notice")

	level_select._on_level_button_pressed(3, 3)
	assert_true(status_lbl.text.contains("Stage 3 not yet implemented"), "StatusLabel updated with Stage 3 locked notice")

	# Test gui_input mouse event on disabled button (e.g. S1L2)
	var click_event = InputEventMouseButton.new()
	click_event.pressed = true
	click_event.button_index = MOUSE_BUTTON_LEFT
	level_select._on_level_button_gui_input(click_event, 1, 2)
	assert_true(status_lbl.text.contains("Stage 1 Level 2: Accessible via gameplay progression"), "GUI input on disabled button updates status")

	# Verify direct launch protection
	level_select._launch_level(1, 2)
	assert_true(status_lbl.text.contains("Accessible via gameplay progression"), "_launch_level blocks launching Level 2")
	level_select._launch_level(2, 1)
	assert_true(status_lbl.text.contains("Stage 2 not yet implemented"), "_launch_level blocks launching Stage 2")

	# Verify Stage 2 Level 3 uses cropped texture
	var s2l3_btn: TextureButton = level_select.level_buttons[Vector2i(2, 3)]
	assert_true(s2l3_btn.texture_normal.resource_path.ends_with("stage2_l3_cropped.png"), "Stage 2 L3 button uses non-destructively cropped texture")

	level_select.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 6: DIRECT GAMEPLAY EXECUTION & ZERO REGRESSION
# ==============================================================================
func test_suite_6_direct_gameplay_execution_and_integration() -> void:
	print("\n--- Running Suite 6: Direct Gameplay Execution & Integration ---")
	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	assert_true(is_instance_valid(main), "scenes/main.tscn boots directly without requiring menu navigation")
	assert_eq(main.current_level, 1, "Default boot starts in Stage 1 Level 1")

	var player = main.get_node_or_null("Player")
	assert_true(is_instance_valid(player), "Player exists in Main scene")

	var official_art = player.get_node_or_null("Visuals/OfficialArt")
	assert_true(is_instance_valid(official_art), "OfficialArt exists in Player under Main scene")

	var alive_sprite = official_art.get_node_or_null("AliveSprite")
	assert_true(alive_sprite.visible, "Player AliveSprite is active during gameplay")

	# Simulate taking 2 damage from hazard
	player.take_damage(2)
	assert_eq(player.health, 10, "Player takes 2 damage correctly (12 -> 10)")
	assert_true(alive_sprite.visible, "AliveSprite remains visible when damaged but alive")

	# Test fatal damage in gameplay
	player.take_damage(10)
	assert_eq(player.health, 0, "Player HP reduced to 0")
	var dead_sprite = official_art.get_node_or_null("DeadSprite")
	assert_true(not alive_sprite.visible, "AliveSprite hidden upon destruction in Main")
	assert_true(dead_sprite.visible, "DeadSprite visible upon destruction in Main")

	main.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUMMARY
# ==============================================================================
func _print_summary() -> void:
	print("\n==================================================")
	print("MILESTONE 3.6 TEST RESULTS SUMMARY")
	print("==================================================")
	print("Total tests executed: %d" % total_count)
	print("Passed: %d" % pass_count)
	print("Failed: %d" % fail_count)
	if fail_count == 0:
		print("STATUS: ALL MILESTONE 3.6 TESTS PASSED SUCCESSFULLY!")
	else:
		printerr("STATUS: SOME TESTS FAILED!")
	print("==================================================")

