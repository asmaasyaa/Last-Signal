extends Node
## Test runner logic for Milestone 5 (Stage 1 Level 5: Final Asteroid Sector & Mining Ship SOS).
## Validates Suites A through F covering Level 4 -> 5 progression, weapon combat in Level 5,
## mining satellite proximity extraction, damaged mining ship SOS ending, checkpoint revive, and regression.

var total_count: int = 0
var pass_count: int = 0
var fail_count: int = 0

const MAIN_SCENE = preload("res://scenes/main.tscn")
const PROJECTILE_SCENE = preload("res://scenes/projectile.tscn")
const ASTEROID_SCENE = preload("res://scenes/asteroid.tscn")
const PLAYER_SCENE = preload("res://scenes/player.tscn")
const SATELLITE_SCENE = preload("res://scenes/satellite.tscn")
const MINING_SATELLITE_SCENE = preload("res://scenes/mining_satellite.tscn")
const DAMAGED_MINING_SHIP_SCENE = preload("res://scenes/damaged_mining_ship.tscn")
const LEVEL_SELECT_SCENE = preload("res://scenes/ui/level_select.tscn")
const MAIN_MENU_SCENE = preload("res://scenes/ui/main_menu.tscn")


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


func assert_false(condition: bool, description: String) -> void:
	total_count += 1
	if not condition:
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
	print("LAST SIGNAL — Milestone 5 Automated Test Suite")
	print("==================================================")
	await test_suite_a_progression_level4_to_level5()
	await test_suite_b_combat_in_level5()
	await test_suite_c_mining_satellite_extraction()
	await test_suite_d_stage1_completion_and_mining_ship_sos()
	await test_suite_e_checkpoint_and_revive_semantics()
	await test_suite_f_system_wide_regression_and_safety()


# ==============================================================================
# SUITE A: LEVEL 4 -> LEVEL 5 PROGRESSION & PERSISTENCE
# ==============================================================================
func test_suite_a_progression_level4_to_level5() -> void:
	print("\n--- Running Suite A: Level 4 -> Level 5 Progression & Persistence ---")

	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	# 1. Start in Level 4 with weapon acquired and persistent HP
	main.stage_acquisitions["primary_weapon_acquired"] = true
	main.stage_acquisitions["shield_acquired"] = true
	main.start_level(4, 7)
	await get_tree().process_frame

	assert_eq(main.current_level, 4, "Main started Level 4")
	assert_eq(main.player.health, 7, "Player HP maintained at 7 in Level 4")
	assert_true(main.is_primary_weapon_acquired(), "Primary weapon is acquired in Level 4")
	assert_true(main.is_shield_acquired(), "Shield is acquired in Level 4")

	# 2. Simulate completing Level 4
	main.time_remaining = 0.0
	main._complete_level()
	await get_tree().process_frame

	assert_true(main.finished, "Level 4 marked finished on survival timer completion")
	assert_true(main.game_won, "Level 4 marked game_won")
	assert_true("STAGE 1 / LEVEL 4 COMPLETE!" in main.message.text, "Level 4 message contains level completion title")
	assert_true("Press [Space/Enter] for Level 5" in main.message.text, "Level 4 message prompts for Level 5 transition")
	assert_true("MILESTONE 4 COMPLETE" in main.message.text, "Level 4 message preserves Milestone 4 completion text")

	# 3. Advance to Level 5 via advance_to_next_level()
	main.advance_to_next_level()
	await get_tree().process_frame

	assert_eq(main.current_level, 5, "Main transitioned to Stage 1 Level 5")
	assert_true(main.time_remaining >= 29.9 and main.time_remaining <= 30.0, "Level 5 survival timer reset to 30.0s")
	assert_eq(main.player.health, 7, "Persistent HP (7) maintained into Level 5")
	assert_true(main.is_primary_weapon_acquired(), "Primary weapon acquisition preserved in Level 5")
	assert_true(main.is_shield_acquired(), "Shield acquisition preserved in Level 5")
	assert_true(main.weapon_controller.firing_enabled, "Weapon firing enabled in Level 5")
	assert_false(main.finished, "Level 5 is actively running (finished == false)")
	assert_false(main.game_won, "Level 5 is in-progress (game_won == false)")

	# 4. Level 5 balance parameters
	assert_eq(main.l5_satellite_spawn_time, 20.0, "Level 5 mining satellite scheduled at 20.0s remaining")
	assert_true(main.l5_spawn_interval_min < main.l5_spawn_interval_max, "Level 5 spawn intervals are valid")
	assert_eq(main.l5_small_ratio, 0.30, "Level 5 small asteroid ratio is 30%")
	assert_eq(main.l5_medium_ratio, 0.40, "Level 5 medium asteroid ratio is 40%")
	assert_eq(main.l5_large_ratio, 0.30, "Level 5 large asteroid ratio is 30%")

	# 5. Verify Space/Enter input handler logic for Level 4 -> 5
	main.start_level(4, 10)
	main.finished = true
	main.game_won = true
	var space_event = InputEventKey.new()
	space_event.pressed = true
	space_event.keycode = KEY_SPACE
	main._unhandled_key_input(space_event)
	await get_tree().process_frame
	assert_eq(main.current_level, 5, "Pressing Space advances from completed Level 4 to Level 5")

	main.queue_free()


# ==============================================================================
# SUITE B: TWIN-BARREL COMBAT IN LEVEL 5
# ==============================================================================
func test_suite_b_combat_in_level5() -> void:
	print("\n--- Running Suite B: Twin-Barrel Combat in Level 5 ---")

	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	main.stage_acquisitions["primary_weapon_acquired"] = true
	main.stage_acquisitions["shield_acquired"] = true
	main.start_level(5, 12)
	await get_tree().process_frame

	var wc = main.weapon_controller
	assert_true(is_instance_valid(wc), "WeaponController node exists on Main")
	assert_true(wc.firing_enabled, "Weapon firing is enabled in Level 5 when weapon acquired")
	assert_true(wc.can_fire(), "Weapon can_fire() is true in Level 5")

	# 1. Fire single twin-barrel burst
	var shots_spawned: Array = wc.fire_volley()
	assert_eq(shots_spawned.size(), 2, "fire_volley() creates exactly 2 projectiles (twin-barrel)")

	if shots_spawned.size() == 2:
		var p1 = shots_spawned[0]
		var p2 = shots_spawned[1]
		assert_true(is_instance_valid(p1) and is_instance_valid(p2), "Both projectiles are valid instances")
		assert_eq(p1.damage, 1, "Projectile 1 deals 1 damage")
		assert_eq(p2.damage, 1, "Projectile 2 deals 1 damage")
		assert_true(p1.direction.y < 0.0, "Projectile 1 moves upward")
		assert_true(p2.direction.y < 0.0, "Projectile 2 moves upward")
		assert_eq(p1.collision_layer, 4, "Projectile 1 has collision_layer 4 (Layer 3: Player Projectiles)")
		assert_eq(p1.collision_mask, 2, "Projectile 1 has collision_mask 2 (asteroids)")
		var forward: Vector2 = Vector2.UP.rotated(main.player.rotation)
		var right_vec: Vector2 = Vector2.RIGHT.rotated(main.player.rotation)
		var expected_left: Vector2 = main.player.global_position + forward * 24.0 - right_vec * 12.0
		var expected_right: Vector2 = main.player.global_position + forward * 24.0 + right_vec * 12.0
		assert_true(p1.global_position.distance_to(expected_left) < 1.0, "Left projectile spawned at correct left muzzle")
		assert_true(p2.global_position.distance_to(expected_right) < 1.0, "Right projectile spawned at correct right muzzle")

	# Clean projectiles
	wc.clear_projectiles()

	# 2. Combat interaction with Asteroid
	var asteroid = ASTEROID_SCENE.instantiate()
	asteroid.set_size_tier(asteroid.AsteroidSize.SMALL)
	asteroid.position = Vector2(640.0, 300.0)
	main.add_child(asteroid)
	await get_tree().process_frame

	assert_eq(asteroid.health, 20, "Small asteroid initialized with 20 HP")

	var proj = PROJECTILE_SCENE.instantiate()
	proj.position = Vector2(640.0, 305.0)
	main.add_child(proj)
	await get_tree().process_frame

	# Simulate overlap / direct hit
	proj._on_area_entered(asteroid)
	assert_eq(asteroid.health, 19, "Asteroid HP reduced from 20 to 19 after projectile hit")
	assert_true(proj.is_queued_for_deletion(), "Projectile queued for deletion after impact")

	# Test take_damage direct destruction (assert before freeing frame)
	asteroid.take_damage(19)
	assert_eq(asteroid.health, 0, "Asteroid HP reduced to 0 on lethal damage")
	assert_true(asteroid.is_destroyed, "Asteroid marked is_destroyed = true")
	assert_true(asteroid.is_queued_for_deletion(), "Asteroid queued for deletion upon reaching 0 HP")

	# 3. Unacquired weapon cannot fire
	main.stage_acquisitions.clear()
	main.start_level(5, 12)
	await get_tree().process_frame
	assert_false(main.weapon_controller.firing_enabled, "Firing remains disabled in Level 5 if weapon unacquired")
	assert_false(main.weapon_controller.can_fire(), "can_fire() is false when weapon is unacquired")

	main.queue_free()


# ==============================================================================
# SUITE C: MINING SATELLITE PROXIMITY EXTRACTION
# ==============================================================================
func test_suite_c_mining_satellite_extraction() -> void:
	print("\n--- Running Suite C: Mining Satellite Proximity Extraction ---")

	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	main.stage_acquisitions["primary_weapon_acquired"] = true
	main.start_level(5, 12)
	await get_tree().process_frame

	# 1. Mining Satellite scene attributes
	var mining_sat = MINING_SATELLITE_SCENE.instantiate()
	main.add_child(mining_sat)
	mining_sat.position = Vector2(640.0, 200.0)
	await get_tree().process_frame

	assert_true(mining_sat.is_in_group("mining_satellites"), "Mining satellite is in 'mining_satellites' group")
	assert_true(mining_sat.is_in_group("satellites"), "Mining satellite is in 'satellites' group")
	assert_eq(mining_sat.collision_layer, 8, "Mining satellite collision layer is 8 (bitmask for Layer 4 interactables)")
	assert_eq(mining_sat.collision_mask, 1, "Mining satellite collision mask is 1 (bitmask for Layer 1 player)")
	assert_eq(mining_sat.drift_speed, 95.0, "Mining satellite downward drift speed is 95 px/s")
	assert_eq(mining_sat.extraction_time, 1.8, "Mining satellite extraction required time is 1.8s")

	var col_shape = mining_sat.get_node_or_null("CollisionShape2D")
	assert_true(is_instance_valid(col_shape), "CollisionShape2D node exists on mining satellite")
	if is_instance_valid(col_shape) and col_shape.shape is CircleShape2D:
		assert_eq(col_shape.shape.radius, 80.0, "Mining satellite proximity radius is 80 px")

	# Visual hierarchy check
	assert_true(mining_sat.has_node("Visuals"), "Mining satellite has Visuals child node")
	assert_true(mining_sat.has_node("Indicator"), "Mining satellite has Indicator child node")

	# 2. Proximity extraction flow via physics frame overlap
	var extracted_events: Array = []
	var started_events: Array = []
	mining_sat.extraction_started.connect(func(): started_events.append(true))
	mining_sat.extracted.connect(func(payload): extracted_events.append(payload))

	var player = main.player
	player.position = Vector2(640.0, 360.0)
	player.move_speed = 0.0
	player.movement_velocity = Vector2.ZERO
	mining_sat.position = Vector2(640.0, 360.0)
	mining_sat.drift_speed = 0.0
	mining_sat.extraction_time = 0.2

	# Wait for physics frames overlap detection
	for i in range(4):
		await get_tree().physics_frame

	assert_true(mining_sat.player_in_range, "Player detected within mining satellite extraction radius")
	assert_true(started_events.size() > 0, "extraction_started signal emitted")

	# Complete extraction
	for i in range(25):
		await get_tree().physics_frame

	assert_true(mining_sat.is_extracted, "Extraction completes after presence in radius")
	assert_eq(extracted_events.size(), 1, "extracted signal emitted exactly once")
	if extracted_events.size() > 0:
		var payload: Dictionary = extracted_events[0]
		assert_eq(payload.get("id", ""), "mining_sat_telemetry_01", "Payload contains id: mining_sat_telemetry_01")
		assert_eq(payload.get("entity_type", ""), "mining_satellite", "Payload contains entity_type: mining_satellite")

	# 3. Main scene telemetry integration
	main._on_mining_satellite_extracted(extracted_events[0])
	assert_true(main.is_mining_satellite_extracted(), "Main reports is_mining_satellite_extracted() == true")
	assert_true(main.stage_acquisitions.has("mining_satellite_telemetry"), "Telemetry recorded in stage_acquisitions")
	assert_true("[DATA RECOVERED: Mining satellite telemetry stored]" in main.telemetry_notice, "HUD telemetry notice set")

	# 4. Satellite despawn offscreen
	mining_sat.position = Vector2(640.0, 800.0)
	mining_sat._physics_process(0.1)
	assert_true(mining_sat.is_queued_for_deletion(), "Mining satellite queued for deletion when past y=780")

	# 5. Scheduling in Main at 20s remaining
	main.mining_satellite_spawned = false
	main.active_mining_satellite = null
	main.time_remaining = 20.0
	main._process(0.1)
	assert_true(main.mining_satellite_spawned, "Mining satellite spawns when time_remaining <= 20.0s")
	assert_true(is_instance_valid(main.active_mining_satellite), "active_mining_satellite reference stored in Main")

	# 6. Missed satellite does not prevent victory
	main.mining_satellite_extracted = false
	main.time_remaining = 0.0
	main._complete_level()
	assert_true(main.game_won, "Level 5 victory achieved even if mining satellite is missed")
	assert_true("Mining [MISSED" in main.message.text, "Level complete banner reflects missed mining satellite")

	main.queue_free()


# ==============================================================================
# SUITE D: STAGE 1 LEVEL 5 COMPLETION & DAMAGED MINING SHIP SOS
# ==============================================================================
func test_suite_d_stage1_completion_and_mining_ship_sos() -> void:
	print("\n--- Running Suite D: Stage 1 Level 5 Completion & Damaged Mining Ship SOS ---")

	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	main.stage_acquisitions["primary_weapon_acquired"] = true
	main.stage_acquisitions["shield_acquired"] = true
	main.start_level(5, 11)
	await get_tree().process_frame

	var sos_signals: Array = []
	var stage_signals: Array = []
	main.distress_sos_received.connect(func(payload): sos_signals.append(payload))
	main.stage_completed.connect(func(payload): stage_signals.append(payload))

	# 1. Trigger Level 5 completion
	main.time_remaining = 0.0
	main._complete_level()
	await get_tree().process_frame

	assert_true(main.finished, "Level 5 marked finished")
	assert_true(main.game_won, "Level 5 marked game_won")
	assert_false(main.weapon_controller.firing_enabled, "Weapon firing disabled upon Stage 1 completion")

	# 2. Check signals emitted
	assert_eq(sos_signals.size(), 1, "distress_sos_received signal emitted exactly once")
	if sos_signals.size() > 0:
		var sos: Dictionary = sos_signals[0]
		assert_eq(sos.get("event_id", ""), "stage1_l5_sos_received", "SOS event_id is 'stage1_l5_sos_received'")
		assert_eq(sos.get("stage", 0), 1, "SOS stage is 1")
		assert_eq(sos.get("level", 0), 5, "SOS level is 5")
		assert_eq(sos.get("source_entity", ""), "Damaged Mining Vessel", "SOS source_entity is Damaged Mining Vessel")
		assert_eq(sos.get("next_stage", 0), 2, "SOS coordinates point toward next_stage: 2")

	assert_eq(stage_signals.size(), 1, "stage_completed signal emitted exactly once")
	if stage_signals.size() > 0:
		var sc: Dictionary = stage_signals[0]
		assert_eq(sc.get("event_id", ""), "stage1_completed", "stage_completed event_id is 'stage1_completed'")
		assert_eq(sc.get("stage", 0), 1, "stage is 1")
		assert_eq(sc.get("levels_cleared", 0), 5, "levels_cleared is 5")
		assert_eq(sc.get("next_stage", 0), 2, "next_stage is 2")
		assert_eq(sc.get("next_stage_available", false), true, "next_stage_available is true (Stage 2 authorized in M6)")

	# 3. Check stage_acquisitions and helper methods
	assert_true(main.is_stage1_completed(), "Main reports is_stage1_completed() == true")
	assert_true(main.has_mining_ship_encountered(), "Main reports has_mining_ship_encountered() == true")

	# 4. Check Damaged Mining Ship spawned in scene
	var found_mining_ship: bool = false
	var mining_ship_ref: Node2D = null
	for child in main.get_children():
		if child.is_in_group("mining_ships"):
			found_mining_ship = true
			mining_ship_ref = child as Node2D
			break

	assert_true(found_mining_ship, "Damaged mining ship instantiated in scene")
	if is_instance_valid(mining_ship_ref):
		assert_true(mining_ship_ref.is_in_group("wrecked_ships"), "Mining ship is in 'wrecked_ships' group")
		assert_true(mining_ship_ref.has_node("Visuals"), "Mining ship has Visuals child node")
		assert_true(mining_ship_ref.position.distance_to(Vector2(640.0, 210.0)) < 2.0, "Mining ship spawned at (640, 210)")

	# 5. Check completion banner text
	assert_true("STAGE 1 COMPLETE!" in main.message.text, "Banner announces STAGE 1 COMPLETE!")
	assert_true("[DISTRESS BEACON INTERCEPTED: Damaged Mining Vessel]" in main.message.text, "Banner mentions distress beacon intercepted")
	assert_true("[TRANSMISSION: Automated SOS Received]" in main.message.text, "Banner mentions transmission received")
	assert_true("Press [Space/Enter] to advance to Stage 2" in main.message.text, "Banner invites player to advance to Stage 2")
	assert_true("Press [R] to replay Stage 1 from Checkpoint" in main.message.text, "Banner indicates checkpoint replay option")

	# 6. Space/Enter transitions to Stage 2 Level 1
	var stage2_node = main.advance_to_stage_2()
	assert_true(is_instance_valid(stage2_node), "advance_to_stage_2() returns instantiated Stage 2 node")
	if is_instance_valid(stage2_node):
		assert_eq(stage2_node.stage_number, 2, "Stage 2 node stage_number is 2")
		assert_eq(stage2_node.current_level, 1, "Stage 2 node current_level is 1")
		stage2_node.queue_free()

	# 7. Player death in Level 5 does NOT trigger completion or Stage 2 transition
	main.stage_acquisitions.clear()
	main.start_level(5, 12)
	main._on_player_died()
	assert_true(main.finished, "Game finished on player death")
	assert_false(main.game_won, "game_won is false on player death")
	assert_false(main.is_stage1_completed(), "Stage 1 not completed on player death")
	assert_true("SHIP DESTROYED (STAGE 1 / LEVEL 5)" in main.message.text, "Death banner shows correct level")
	var dead_advance = main.advance_to_stage_2()
	assert_true(dead_advance == null, "Dead player cannot advance to Stage 2")

	main.queue_free()


# ==============================================================================
# SUITE E: CHECKPOINT & REVIVE SEMANTICS
# ==============================================================================
func test_suite_e_checkpoint_and_revive_semantics() -> void:
	print("\n--- Running Suite E: Checkpoint & Revive Semantics ---")

	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	# 1. Setup acquisitions and simulate death in Level 5
	main.stage_acquisitions["primary_weapon_acquired"] = true
	main.stage_acquisitions["shield_acquired"] = true
	main.stage_acquisitions["mining_satellite_telemetry"] = {"id": "test"}
	main.stage_acquisitions["stage1_completed"] = true
	main.satellite_extracted = true
	main.mining_satellite_extracted = true
	main.start_level(5, 4)
	await get_tree().process_frame

	# Simulate death
	main.player.take_damage(20)
	await get_tree().process_frame

	assert_true(main.finished, "Finished is true on death")
	assert_false(main.game_won, "Game won is false on death")
	assert_eq(main.player.health, 0, "Player HP clamped to 0")

	# 2. Revive via 'R' key
	var r_event = InputEventKey.new()
	r_event.pressed = true
	r_event.keycode = KEY_R
	main._unhandled_key_input(r_event)
	await get_tree().process_frame

	assert_eq(main.current_level, 1, "Reviving from Level 5 returns strictly to Stage 1 Level 1")
	assert_eq(main.player.health, 12, "Player HP restored to full 12 HP on checkpoint revive")
	assert_true(main.time_remaining >= 29.9 and main.time_remaining <= 30.0, "Survival timer reset to 30.0s")
	assert_false(main.is_primary_weapon_acquired(), "Primary weapon acquisition cleared upon checkpoint reset")
	assert_false(main.is_shield_acquired(), "Shield acquisition cleared upon checkpoint reset")
	assert_false(main.is_stage1_completed(), "stage1_completed cleared upon checkpoint reset")
	assert_false(main.is_mining_satellite_extracted(), "mining_satellite_extracted cleared upon checkpoint reset")
	assert_false(main.satellite_extracted, "satellite_extracted cleared upon checkpoint reset")
	assert_false(main.weapon_controller.firing_enabled, "Weapon firing disabled in Level 1 after revive")

	# 3. Old entities cleared
	var leftover_ships: int = 0
	for child in main.get_children():
		if (child.is_in_group("mining_ships") or child.is_in_group("wrecked_ships")) and not child.is_queued_for_deletion():
			leftover_ships += 1
	assert_eq(leftover_ships, 0, "No leftover mining or wrecked ships remain after checkpoint reset")

	main.queue_free()


# ==============================================================================
# SUITE F: SYSTEM-WIDE REGRESSION, LEVEL SELECT RESTRICTIONS & SAFETY
# ==============================================================================
func test_suite_f_system_wide_regression_and_safety() -> void:
	print("\n--- Running Suite F: System-Wide Regression, Level Select Restrictions & Safety ---")

	# 1. Level Select Scene Verification
	var level_select = LEVEL_SELECT_SCENE.instantiate()
	add_child(level_select)
	await get_tree().process_frame

	assert_eq(level_select.level_buttons.size(), 15, "All 15 stage/level buttons registered")

	# Playable checks (Only Stage 1 Level 1 is playable directly from Level Select)
	assert_true(level_select.is_level_playable(1, 1), "Stage 1 Level 1 is PLAYABLE from Level Select")
	assert_false(level_select.is_level_playable(1, 2), "Stage 1 Level 2 is LOCKED from direct selection")
	assert_false(level_select.is_level_playable(1, 3), "Stage 1 Level 3 is LOCKED from direct selection")
	assert_false(level_select.is_level_playable(1, 4), "Stage 1 Level 4 is LOCKED from direct selection")
	assert_false(level_select.is_level_playable(1, 5), "Stage 1 Level 5 is LOCKED from direct selection")

	# Button disabled states
	var s1l1_btn: TextureButton = level_select.level_buttons[Vector2i(1, 1)]
	var s1l2_btn: TextureButton = level_select.level_buttons[Vector2i(1, 2)]
	var s1l3_btn: TextureButton = level_select.level_buttons[Vector2i(1, 3)]
	var s1l4_btn: TextureButton = level_select.level_buttons[Vector2i(1, 4)]
	var s1l5_btn: TextureButton = level_select.level_buttons[Vector2i(1, 5)]
	var status_lbl: Label = level_select.get_node_or_null("VBoxContainer/StatusLabel")

	assert_false(s1l1_btn.disabled, "Stage 1 Level 1 button is enabled")
	assert_true(s1l2_btn.disabled, "Stage 1 Level 2 button is disabled")
	assert_true(s1l3_btn.disabled, "Stage 1 Level 3 button is disabled")
	assert_true(s1l4_btn.disabled, "Stage 1 Level 4 button is disabled")
	assert_true(s1l5_btn.disabled, "Stage 1 Level 5 button is disabled")

	# Status message tests when pressing buttons
	level_select._on_level_button_pressed(1, 2)
	assert_true("Stage 1 Level 2" in status_lbl.text, "Status label explains Level 2 progression lock")

	level_select._on_level_button_pressed(1, 3)
	assert_true("Stage 1 Level 3" in status_lbl.text, "Status label explains Level 3 progression lock")

	level_select._on_level_button_pressed(1, 4)
	assert_true("Stage 1 Level 4" in status_lbl.text, "Status label explains Level 4 progression lock")

	level_select._on_level_button_pressed(1, 5)
	assert_true("Stage 1 Level 5" in status_lbl.text, "Status label explains Level 5 progression lock")

	level_select.queue_free()

	# 2. Main Menu scene verification
	var menu = MAIN_MENU_SCENE.instantiate()
	add_child(menu)
	await get_tree().process_frame

	var start_btn = menu.get_node_or_null("CenterContainer/VBoxContainer/ButtonsContainer/StartButton")
	var select_btn = menu.get_node_or_null("CenterContainer/VBoxContainer/ButtonsContainer/SelectButton")
	var exit_btn = menu.get_node_or_null("CenterContainer/VBoxContainer/ButtonsContainer/ExitButton")

	assert_true(is_instance_valid(start_btn), "Main menu Start button exists")
	assert_true(is_instance_valid(select_btn), "Main menu Select button exists")
	assert_true(is_instance_valid(exit_btn), "Main menu Exit button exists")

	menu.queue_free()

	# 3. Architectural Visual node isolation checks
	var player = PLAYER_SCENE.instantiate()
	assert_true(player.has_node("Visuals"), "Player scene has Visuals child node")
	assert_false(player.has_method("shoot"), "Player has no shoot() method (M2 architectural constraint)")
	assert_false(player.has_method("fire"), "Player has no fire() method (M2 architectural constraint)")
	player.queue_free()

	var asteroid = ASTEROID_SCENE.instantiate()
	assert_true(asteroid.has_node("Visuals"), "Asteroid scene has Visuals child node")
	asteroid.queue_free()

	var comm_sat = SATELLITE_SCENE.instantiate()
	assert_true(comm_sat.has_node("Visuals"), "Communication satellite has Visuals child node")
	comm_sat.queue_free()

	var mining_sat = MINING_SATELLITE_SCENE.instantiate()
	assert_true(mining_sat.has_node("Visuals"), "Mining satellite has Visuals child node")
	mining_sat.queue_free()

	var mining_ship = DAMAGED_MINING_SHIP_SCENE.instantiate()
	assert_true(mining_ship.has_node("Visuals"), "Damaged mining ship has Visuals child node")
	mining_ship.queue_free()


func _print_summary() -> void:
	print("\n==================================================")
	print("MILESTONE 5 TEST EXECUTION SUMMARY")
	print("==================================================")
	print("Total assertions: %d" % total_count)
	print("Passed:           %d" % pass_count)
	print("Failed:           %d" % fail_count)
	if fail_count == 0:
		print("VERDICT: ALL TESTS PASSED (100%%)")
	else:
		printerr("VERDICT: TEST SUITE FAILED (%d failures)" % fail_count)
	print("==================================================")
