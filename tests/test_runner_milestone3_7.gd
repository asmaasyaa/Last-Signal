extends Node
## Test runner logic for Milestone 3.7 (Team Asset Integration - Batch 02).
## Validates Batch 02 delta (35 -> 44 PNGs, 9 new), official Communication Satellite
## visual hierarchy, dual progress indicator readability, automatic procedural fallback,
## collision shape preservation (r=80.0 px), Stage 2 guard reservation, Nirawak 1 status,
## and complete regression immunity across Stage 1 Levels 1-3.

var total_count: int = 0
var pass_count: int = 0
var fail_count: int = 0

const SATELLITE_SCENE = preload("res://scenes/satellite.tscn")
const PLAYER_SCENE = preload("res://scenes/player.tscn")
const ASTEROID_SCENE = preload("res://scenes/asteroid.tscn")
const MAIN_SCENE = preload("res://scenes/main.tscn")
const WRECKED_SHIP_SCENE = preload("res://scenes/wrecked_ship.tscn")
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
	print("LAST SIGNAL — Milestone 3.7 Automated Test Suite")
	print("==================================================")
	await test_suite_1_batch02_asset_files_and_resource_loading()
	await test_suite_2_satellite_visual_architecture_and_hierarchy()
	await test_suite_3_satellite_procedural_fallback_mechanism()
	await test_suite_4_satellite_collision_and_physics_invariance()
	await test_suite_5_satellite_telemetry_and_level_independence()
	await test_suite_6_scope_isolation_guard_and_nirawak_boundaries()
	await test_suite_7_system_wide_regression_and_gameplay_integration()


# ==============================================================================
# SUITE 1: BATCH 02 ASSET FILES & RESOURCE LOADING
# ==============================================================================
func test_suite_1_batch02_asset_files_and_resource_loading() -> void:
	print("\n--- Running Suite 1: Batch 02 Asset Files & Resource Loading ---")

	# 1. Verify pristine archive directory contains Batch 02 files
	assert_true(DirAccess.dir_exists_absolute("res://assets_src/team_batch_02"), "Pristine archive directory 'assets_src/team_batch_02' exists")

	# 2. Check 9 new pristine source assets exist
	var pristine_new_files := [
		"res://assets_src/team_batch_02/assets/entities/npc/commsatt.png",
		"res://assets_src/team_batch_02/assets/entities/guards/bot/idle.png",
		"res://assets_src/team_batch_02/assets/entities/guards/bot/attacking.png",
		"res://assets_src/team_batch_02/assets/entities/guards/satellite/idle.png",
		"res://assets_src/team_batch_02/assets/entities/guards/satellite/attacking.png",
		"res://assets_src/team_batch_02/assets/entities/guards/drone/idle.png",
		"res://assets_src/team_batch_02/assets/entities/guards/drone/attacking.png",
		"res://assets_src/team_batch_02/assets/entities/npc/nirawak1/before-extraction.png",
		"res://assets_src/team_batch_02/assets/entities/npc/nirawak1/after-extraction.png"
	]
	for path in pristine_new_files:
		assert_true(FileAccess.file_exists(path), "Pristine source asset exists: %s" % path)

	# 3. Check runtime copies exist and load cleanly as Texture2D
	var runtime_assets := [
		"res://assets/sprites/interactables/commsatt.png",
		"res://assets/sprites/enemies/guard_bot/guard_bot_idle.png",
		"res://assets/sprites/enemies/guard_bot/guard_bot_attacking.png",
		"res://assets/sprites/enemies/guard_satellite/guard_satellite_idle.png",
		"res://assets/sprites/enemies/guard_satellite/guard_satellite_attacking.png",
		"res://assets/sprites/enemies/guard_drone/guard_drone_idle.png",
		"res://assets/sprites/enemies/guard_drone/guard_drone_attacking.png",
		"res://assets/sprites/npc/nirawak1/before_extraction.png",
		"res://assets/sprites/npc/nirawak1/after_extraction.png"
	]
	for path in runtime_assets:
		assert_true(FileAccess.file_exists(path), "Runtime asset file exists: %s" % path)
		var tex = load(path)
		assert_true(tex != null and tex is Texture2D, "Asset loads cleanly as Texture2D: %s" % path)

	# 4. Specific dimension verifications
	var commsatt_tex: Texture2D = load("res://assets/sprites/interactables/commsatt.png")
	assert_eq(commsatt_tex.get_size(), Vector2(602, 336), "Communication satellite texture dimensions are 602x336")

	var bot_idle_tex: Texture2D = load("res://assets/sprites/enemies/guard_bot/guard_bot_idle.png")
	assert_eq(bot_idle_tex.get_size(), Vector2(129, 129), "Guard Bot idle dimensions are 129x129")

	var bot_atk_tex: Texture2D = load("res://assets/sprites/enemies/guard_bot/guard_bot_attacking.png")
	assert_eq(bot_atk_tex.get_size(), Vector2(129, 129), "Guard Bot attacking dimensions are 129x129")

	var drone_idle_tex: Texture2D = load("res://assets/sprites/enemies/guard_drone/guard_drone_idle.png")
	assert_eq(drone_idle_tex.get_size(), Vector2(152, 316), "Guard Drone idle dimensions are 152x316")

	var drone_atk_tex: Texture2D = load("res://assets/sprites/enemies/guard_drone/guard_drone_attacking.png")
	assert_eq(drone_atk_tex.get_size(), Vector2(151, 316), "Guard Drone attacking dimensions are 151x316")

	var sat_idle_tex: Texture2D = load("res://assets/sprites/enemies/guard_satellite/guard_satellite_idle.png")
	assert_eq(sat_idle_tex.get_size(), Vector2(347, 267), "Guard Satellite idle dimensions are 347x267")

	var sat_atk_tex: Texture2D = load("res://assets/sprites/enemies/guard_satellite/guard_satellite_attacking.png")
	assert_eq(sat_atk_tex.get_size(), Vector2(347, 267), "Guard Satellite attacking dimensions are 347x267")

	var n1_before_tex: Texture2D = load("res://assets/sprites/npc/nirawak1/before_extraction.png")
	assert_eq(n1_before_tex.get_size(), Vector2(870, 303), "Nirawak 1 before-extraction dimensions are 870x303")

	var n1_after_tex: Texture2D = load("res://assets/sprites/npc/nirawak1/after_extraction.png")
	assert_eq(n1_after_tex.get_size(), Vector2(870, 303), "Nirawak 1 after-extraction dimensions are 870x303")


# ==============================================================================
# SUITE 2: SATELLITE VISUAL ARCHITECTURE & HIERARCHY
# ==============================================================================
func test_suite_2_satellite_visual_architecture_and_hierarchy() -> void:
	print("\n--- Running Suite 2: Satellite Visual Architecture & Hierarchy ---")

	var sat = SATELLITE_SCENE.instantiate()
	add_child(sat)

	# 1. Verify Visuals subtree hierarchy
	var visuals: Node2D = sat.get_node_or_null("Visuals")
	assert_true(is_instance_valid(visuals), "Satellite contains 'Visuals' presentation container")

	var fallback: Node2D = visuals.get_node_or_null("ProceduralFallback")
	assert_true(is_instance_valid(fallback), "Visuals contains 'ProceduralFallback' node")
	assert_true(fallback.has_method("set_state"), "ProceduralFallback has set_state() method")

	var official_art: Node2D = visuals.get_node_or_null("OfficialArt")
	assert_true(is_instance_valid(official_art), "Visuals contains 'OfficialArt' node")

	var sprite: Sprite2D = official_art.get_node_or_null("Sprite2D")
	assert_true(is_instance_valid(sprite), "OfficialArt contains 'Sprite2D' node")

	# 2. Verify official art texture and scaling
	assert_true(sprite.texture != null, "Sprite2D has texture assigned")
	assert_eq(sprite.texture.resource_path, "res://assets/sprites/interactables/commsatt.png", "Sprite2D uses official commsatt.png texture")
	assert_true(sprite.centered, "Sprite2D centered property is true")

	# Uniform scaling check (no aspect ratio distortion)
	assert_eq(sprite.scale.x, sprite.scale.y, "Sprite2D scale is uniform (x == y, no stretching)")
	assert_true(sprite.scale.x >= 0.20 and sprite.scale.x <= 0.25, "Sprite2D scale is within recommended 0.20-0.25 range (actual: %s)" % str(sprite.scale.x))

	# 3. Verify default active states (official art active, fallback hidden to avoid duplicate visuals)
	assert_true(official_art.visible, "OfficialArt is visible by default")
	assert_true(sprite.visible, "Sprite2D is visible by default")
	assert_true(not fallback.visible, "ProceduralFallback is hidden by default (no duplicate visuals)")

	# 4. Verify progress indicator node and z-ordering
	var indicator: Node2D = sat.get_node_or_null("Indicator")
	assert_true(is_instance_valid(indicator), "Satellite contains 'Indicator' child node")
	assert_true(indicator.z_index >= 2, "Indicator z_index >= 2 (renders on top of sprite)")

	sat.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 3: SATELLITE PROCEDURAL FALLBACK MECHANISM
# ==============================================================================
func test_suite_3_satellite_procedural_fallback_mechanism() -> void:
	print("\n--- Running Suite 3: Satellite Procedural Fallback Mechanism ---")

	var sat = SATELLITE_SCENE.instantiate()
	add_child(sat)

	var visuals: Node2D = sat.get_node("Visuals")
	var fallback: Node2D = visuals.get_node("ProceduralFallback")
	var official_art: Node2D = visuals.get_node("OfficialArt")
	var sprite: Sprite2D = official_art.get_node("Sprite2D")

	# Case A: official_art_enabled toggle
	sat.official_art_enabled = false
	sat.update_visual_state()
	assert_true(not official_art.visible, "OfficialArt hidden when official_art_enabled is false")
	assert_true(fallback.visible, "ProceduralFallback visible when official_art_enabled is false")

	# Case B: Re-enabling official art
	sat.official_art_enabled = true
	sat.update_visual_state()
	assert_true(official_art.visible, "OfficialArt restored when official_art_enabled is true")
	assert_true(not fallback.visible, "ProceduralFallback hidden when official_art_enabled is true")

	# Case C: Texture removal triggers automatic fallback
	var orig_tex = sprite.texture
	sprite.texture = null
	sat.update_visual_state()
	assert_true(not official_art.visible, "OfficialArt hidden when sprite texture is null")
	assert_true(fallback.visible, "ProceduralFallback automatically activated when sprite texture is null")

	# Case D: Texture restoration restores official art
	sprite.texture = orig_tex
	sat.update_visual_state()
	assert_true(official_art.visible, "OfficialArt restored when texture is reassigned")
	assert_true(not fallback.visible, "ProceduralFallback hidden when texture is reassigned")

	# Case E: ProceduralFallback responds to state updates (extracted & phase)
	fallback.set_state(true, 1.5)
	assert_true(fallback.is_extracted, "Fallback correctly tracks extracted state")
	assert_eq(fallback.beacon_phase, 1.5, "Fallback correctly tracks beacon phase")

	sat.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 4: SATELLITE COLLISION & PHYSICS INVARIANCE
# ==============================================================================
func test_suite_4_satellite_collision_and_physics_invariance() -> void:
	print("\n--- Running Suite 4: Satellite Collision & Physics Invariance ---")

	var sat = SATELLITE_SCENE.instantiate()
	sat.position = Vector2(640, 200)
	add_child(sat)

	# 1. Physics root scale MUST remain Vector2.ONE (prevents collision distortion)
	assert_eq(sat.scale, Vector2.ONE, "Satellite root scale remains strictly Vector2.ONE")

	# 2. Collision layers and shape
	assert_eq(sat.collision_layer, 8, "Satellite collision_layer is 8 (Layer 4: Interactables)")
	assert_eq(sat.collision_mask, 1, "Satellite collision_mask is 1 (Layer 1: Player)")

	var col_shape: CollisionShape2D = sat.get_node("CollisionShape2D")
	assert_true(is_instance_valid(col_shape), "Satellite has CollisionShape2D")
	assert_true(col_shape.shape is CircleShape2D, "Collision shape is CircleShape2D")
	assert_eq(col_shape.shape.radius, 80.0, "CollisionShape2D radius is exactly 80.0 px (unscaled)")
	assert_eq(sat.extraction_radius, 80.0, "Satellite extraction_radius parameter is 80.0 px")

	# 3. Drift speed and movement
	assert_eq(sat.drift_speed, 100.0, "Satellite drift_speed remains 100.0 px/s")
	var initial_y: float = sat.position.y
	sat._physics_process(0.2)
	assert_eq(sat.position.y, initial_y + 20.0, "Satellite drifts downward at 100 px/s (200 -> 220 at delta=0.2)")

	# 4. Despawn boundary check
	sat.position.y = 800.0
	sat._physics_process(0.01)
	assert_true(sat.is_queued_for_deletion(), "Satellite queues for deletion when crossing Y > 780.0")

	sat.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 5: SATELLITE TELEMETRY & LEVEL INDEPENDENCE
# ==============================================================================
func test_suite_5_satellite_telemetry_and_level_independence() -> void:
	print("\n--- Running Suite 5: Satellite Telemetry & Level Independence ---")

	var sat = SATELLITE_SCENE.instantiate()
	sat.position = Vector2(640, 360)
	sat.drift_speed = 0.0
	sat.extraction_time = 0.2
	add_child(sat)

	var player = PLAYER_SCENE.instantiate()
	player.position = Vector2(640, 360)
	player.move_speed = 0.0
	add_child(player)

	var started_signals: Array = []
	var progress_values: Array = []
	var extracted_payloads: Array = []

	sat.extraction_started.connect(func(): started_signals.append(true))
	sat.extraction_progress_changed.connect(func(prog: float): progress_values.append(prog))
	sat.extracted.connect(func(payload: Dictionary): extracted_payloads.append(payload))

	# Wait for physics overlap
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_true(sat.player_in_range, "Player detected in extraction range")
	assert_eq(started_signals.size(), 1, "extraction_started signal emitted")
	assert_true(progress_values.size() > 0, "extraction_progress_changed signals emitted")

	# Wait for extraction completion (0.2s = ~12 frames)
	for i in range(20):
		await get_tree().physics_frame

	assert_eq(sat.extraction_progress, 1.0, "Extraction progress reached 1.0 (100%)")
	assert_true(sat.is_extracted, "Satellite is_extracted flag is true")
	assert_eq(extracted_payloads.size(), 1, "extracted signal emitted exactly once")

	if extracted_payloads.size() > 0:
		var payload: Dictionary = extracted_payloads[0]
		assert_eq(payload.get("id"), "sat_telemetry_01", "Payload contains id 'sat_telemetry_01'")
		assert_eq(payload.get("source"), "COMMUNICATION SATELLITE", "Payload contains source 'COMMUNICATION SATELLITE'")
		assert_true(payload.has("text"), "Payload contains narrative text")
		assert_true(payload["text"].contains("distress beacon"), "Payload text mentions distress beacon")

	# Verify optional completion: main game in Level 2 completes without extraction
	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	main.start_level(2, 10)
	main.satellite_extracted = false # Satellite missed
	main._process(30.0)

	assert_true(main.finished, "Level 2 finishes when timer expires")
	assert_true(main.game_won, "Level 2 won WITHOUT satellite extraction (extraction is strictly optional)")
	assert_true(main.message.text.contains("MISSED (Satellite Drifted Away)"), "End-game message reports satellite missed without causing game over")

	sat.queue_free()
	player.queue_free()
	main.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 6: SCOPE ISOLATION, GUARD AND NIRAWAK BOUNDARIES
# ==============================================================================
func test_suite_6_scope_isolation_guard_and_nirawak_boundaries() -> void:
	print("\n--- Running Suite 6: Scope Isolation, Guard and Nirawak Boundaries ---")

	# 1. Verify 6 guard assets exist and are staged in enemies directory
	var guard_paths := [
		"res://assets/sprites/enemies/guard_bot/guard_bot_idle.png",
		"res://assets/sprites/enemies/guard_bot/guard_bot_attacking.png",
		"res://assets/sprites/enemies/guard_satellite/guard_satellite_idle.png",
		"res://assets/sprites/enemies/guard_satellite/guard_satellite_attacking.png",
		"res://assets/sprites/enemies/guard_drone/guard_drone_idle.png",
		"res://assets/sprites/enemies/guard_drone/guard_drone_attacking.png"
	]
	for gp in guard_paths:
		assert_true(FileAccess.file_exists(gp), "Guard asset present: %s" % gp)

	# 2. Verify NO Stage 2 enemy scenes exist in active scenes/
	assert_true(not FileAccess.file_exists("res://scenes/guard_bot.tscn"), "No premature guard_bot.tscn scene exists")
	assert_true(not FileAccess.file_exists("res://scenes/guard_satellite.tscn"), "No premature guard_satellite.tscn scene exists")
	assert_true(not FileAccess.file_exists("res://scenes/guard_drone.tscn"), "No premature guard_drone.tscn scene exists")

	# 3. Verify Nirawak 1 assets exist and are staged in npc directory
	assert_true(FileAccess.file_exists("res://assets/sprites/npc/nirawak1/before_extraction.png"), "Nirawak 1 before-extraction asset exists")
	assert_true(FileAccess.file_exists("res://assets/sprites/npc/nirawak1/after_extraction.png"), "Nirawak 1 after-extraction asset exists")

	# 4. Verify Wrecked Spacecraft scene was NOT replaced with Nirawak 1
	var wrecked = WRECKED_SHIP_SCENE.instantiate()
	add_child(wrecked)
	assert_true(is_instance_valid(wrecked), "Wrecked spacecraft instantiates cleanly")
	var w_script = wrecked.get_script()
	assert_true(w_script != null, "Wrecked spacecraft has script attached")
	assert_true(not wrecked.has_node("Visuals/OfficialArt/NirawakSprite"), "Wrecked spacecraft does NOT assume Nirawak 1 art without confirmation")
	wrecked.queue_free()

	# 5. Verify documentation manifest exists and reflects Batch 02 count (44 PNGs)
	assert_true(FileAccess.file_exists("res://docs/TEAM_ASSET_MANIFEST.md"), "TEAM_ASSET_MANIFEST.md exists")
	var manifest_text = FileAccess.get_file_as_string("res://docs/TEAM_ASSET_MANIFEST.md")
	assert_true(manifest_text.contains("44 visual assets") or manifest_text.contains("44 PNG"), "Manifest documents 44 delivered PNG assets")
	assert_true(manifest_text.contains("AWAITING TEAM CONFIRMATION"), "Manifest contains AWAITING TEAM CONFIRMATION status for Nirawak 1")
	assert_true(manifest_text.contains("RESERVED FOR STAGE 2") or manifest_text.contains("RESERVED"), "Manifest contains RESERVED status for guards")
	assert_true(manifest_text.contains("commsatt.png"), "Manifest catalogs commsatt.png")


# ==============================================================================
# SUITE 7: SYSTEM-WIDE REGRESSION & GAMEPLAY INTEGRATION
# ==============================================================================
func test_suite_7_system_wide_regression_and_gameplay_integration() -> void:
	print("\n--- Running Suite 7: System-Wide Regression & Gameplay Integration ---")

	# 1. Main scene direct execution starts at Stage 1 Level 1
	var main = MAIN_SCENE.instantiate()
	add_child(main)
	assert_eq(main.current_level, 1, "Default game boot starts in Stage 1 Level 1")
	assert_eq(main.level_duration, 30.0, "Level duration remains 30.0 seconds")

	# 2. Player official art and state transitions
	var player = main.get_node("Player")
	assert_true(is_instance_valid(player), "Player exists in main scene")
	assert_true(player.official_art_enabled, "Player official_art_enabled is true")

	var alive_sprite = player.get_node("Visuals/OfficialArt/AliveSprite")
	var dead_sprite = player.get_node("Visuals/OfficialArt/DeadSprite")
	assert_true(alive_sprite.visible, "Player AliveSprite is active during gameplay")
	assert_true(not dead_sprite.visible, "Player DeadSprite is hidden during gameplay")

	# 3. Main menu scene instantiates cleanly
	var menu = MAIN_MENU_SCENE.instantiate()
	add_child(menu)
	assert_true(is_instance_valid(menu), "MainMenu instantiates cleanly")
	assert_true(menu.has_node("CenterContainer/VBoxContainer/ButtonsContainer/StartButton"), "MainMenu has StartButton")
	assert_true(menu.has_node("CenterContainer/VBoxContainer/ButtonsContainer/SelectButton"), "MainMenu has SelectButton")
	assert_true(menu.has_node("CenterContainer/VBoxContainer/ButtonsContainer/ExitButton"), "MainMenu has ExitButton")

	# 4. Level select scene instantiates cleanly with progression protection
	var lselect = LEVEL_SELECT_SCENE.instantiate()
	add_child(lselect)
	await get_tree().process_frame

	assert_true(is_instance_valid(lselect), "LevelSelect instantiates cleanly")
	assert_eq(lselect.level_buttons.size(), 15, "All 15 stage/level buttons registered")

	var s1l1_btn: TextureButton = lselect.level_buttons[Vector2i(1, 1)]
	var s1l2_btn: TextureButton = lselect.level_buttons[Vector2i(1, 2)]
	var s1l3_btn: TextureButton = lselect.level_buttons[Vector2i(1, 3)]
	assert_true(not s1l1_btn.disabled, "Stage 1 Level 1 is enabled and playable")
	assert_true(s1l2_btn.disabled, "Stage 1 Level 2 is disabled / progression locked")
	assert_true(s1l3_btn.disabled, "Stage 1 Level 3 is disabled / progression locked")

	main.queue_free()
	menu.queue_free()
	lselect.queue_free()
	await get_tree().process_frame


func _print_summary() -> void:
	print("\n==================================================")
	print("MILESTONE 3.7 TEST RESULTS SUMMARY")
	print("==================================================")
	print("Total tests executed: %d" % total_count)
	print("Passed: %d" % pass_count)
	print("Failed: %d" % fail_count)
	if fail_count == 0:
		print("STATUS: ALL MILESTONE 3.7 TESTS PASSED SUCCESSFULLY!")
	else:
		printerr("STATUS: SOME TESTS FAILED!")
	print("==================================================")
