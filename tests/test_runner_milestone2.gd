extends Node
## Test runner logic for Milestone 2 (Stage 1 Level 2).
## Validates HP persistence, Stage Checkpoint revive, medium asteroids, and satellite extraction.

var total_count: int = 0
var pass_count: int = 0
var fail_count: int = 0

const PLAYER_SCENE = preload("res://scenes/player.tscn")
const ASTEROID_SCENE = preload("res://scenes/asteroid.tscn")
const SATELLITE_SCENE = preload("res://scenes/satellite.tscn")
const MAIN_SCENE = preload("res://scenes/main.tscn")


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
	await test_suite_1_hp_persistence()
	await test_suite_2_stage_checkpoint_revive()
	await test_suite_3_medium_asteroids_and_collision()
	test_suite_4_density_progression_parameters()
	await test_suite_5_satellite_lifecycle()
	await test_suite_6_satellite_proximity_extraction()
	await test_suite_7_satellite_optional_independence()
	test_suite_8_no_player_weapons_in_level_2()


# ==============================================================================
# SUITE 1: LEVEL 1 -> LEVEL 2 HP PERSISTENCE
# ==============================================================================
func test_suite_1_hp_persistence() -> void:
	print("\n--- Running Suite 1: Level 1 -> Level 2 HP Persistence ---")
	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	assert_eq(main.current_level, 1, "Game starts at Stage 1 Level 1")
	assert_eq(main.player.health, 12, "Player starts Level 1 at full 12 HP")

	# Take 5 damage in Level 1 (12 -> 7 HP)
	main.player.take_damage(5)
	assert_eq(main.player.health, 7, "Player HP reduced to 7 in Level 1")

	# Simulate surviving 30 seconds
	main._process(30.0)
	assert_true(main.finished, "Level 1 finished after 30s")
	assert_true(main.game_won, "Level 1 game_won is true")

	# Advance to Level 2
	main.advance_to_next_level()
	await get_tree().process_frame

	# Verify persistent HP rule
	assert_eq(main.current_level, 2, "Current level transitioned to 2")
	assert_eq(main.player.health, 7, "Player HP persisted across levels (starts Level 2 at 7 HP, NOT reinitialized to 12)")
	assert_eq(main.player.max_health, 12, "Player max_health remains 12")
	assert_true(main.player.alive, "Player is alive in Level 2")
	assert_true(main.player.is_physics_processing(), "Player physics re-enabled in Level 2")
	assert_true(main.time_remaining >= 29.9 and main.time_remaining <= 30.0, "Level 2 survival timer initialized to 30.0s")
	assert_true(not main.finished, "Level 2 starts unfinished")
	assert_true(not main.game_won, "Level 2 starts with game_won false")

	main.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 2: STAGE CHECKPOINT REVIVE ON DEATH IN LEVEL 2
# ==============================================================================
func test_suite_2_stage_checkpoint_revive() -> void:
	print("\n--- Running Suite 2: Stage Checkpoint Revive on Death in Level 2 ---")
	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	# Advance to Level 2 with 6 HP
	main.start_level(2, 6)
	main.stage_acquisitions["satellite_telemetry"] = {"test": true}
	assert_eq(main.current_level, 2, "Initialized in Level 2")
	assert_eq(main.player.health, 6, "Player starts Level 2 at 6 HP")

	# Die in Level 2 (take 6 damage)
	main.player.take_damage(6)
	assert_eq(main.player.health, 0, "Player HP reaches 0 in Level 2")
	assert_true(not main.player.alive, "Player alive is false")
	assert_true(main.finished, "Level 2 marked finished on death")
	assert_true(not main.game_won, "game_won is false on death")
	assert_true(main.message.visible, "Game over message is visible")
	assert_true(main.message.text.contains("Revive at Stage 1 Checkpoint"), "Message prompts revive at Stage 1 Checkpoint")

	# Revive at Stage 1 Checkpoint
	main.revive_at_stage_checkpoint()
	await get_tree().process_frame

	# Verify revive semantics
	assert_eq(main.current_level, 1, "Revive strictly returns to Stage 1 Level 1 (Stage Checkpoint)")
	assert_eq(main.player.health, 12, "Player HP is restored to full (12 HP) upon revive")
	assert_true(main.player.alive, "Player is alive after revive")
	assert_true(main.player.is_physics_processing(), "Player physics processing active after revive")
	assert_true(main.time_remaining >= 29.9 and main.time_remaining <= 30.0, "Level 1 timer reset to 30.0s")
	assert_true(not main.finished, "Game finished flag reset to false")
	assert_true(main.stage_acquisitions.is_empty(), "Temporary stage acquisitions cleared on stage revive")

	main.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 3: MEDIUM ASTEROIDS & COLLISION PROPERTIES
# ==============================================================================
func test_suite_3_medium_asteroids_and_collision() -> void:
	print("\n--- Running Suite 3: Medium Asteroids & Collision Properties ---")
	var small_ast = ASTEROID_SCENE.instantiate()
	var med_ast = ASTEROID_SCENE.instantiate()
	add_child(small_ast)
	add_child(med_ast)

	# Configure medium asteroid
	med_ast.set_size_tier(med_ast.AsteroidSize.MEDIUM)

	# 1. Properties
	assert_eq(small_ast.max_health, 20, "Small asteroid max HP is 20")
	assert_eq(small_ast.contact_damage, 1, "Small asteroid contact damage is 1")
	assert_eq(med_ast.max_health, 40, "Medium asteroid max HP is 40")
	assert_eq(med_ast.contact_damage, 2, "Medium asteroid contact damage is 2")

	# 2. Collision Shape Unshared Verification (No mutation of shared resource)
	var small_shape = small_ast.get_node("CollisionShape2D").shape
	var med_shape = med_ast.get_node("CollisionShape2D").shape
	assert_eq(small_shape.radius, 19.0, "Small asteroid collision radius is 19.0 px")
	assert_eq(med_shape.radius, 35.0, "Medium asteroid collision radius is 35.0 px")
	assert_true(small_shape != med_shape, "Medium asteroid uses independent CircleShape2D instance (no shared resource mutation)")
	assert_eq(med_ast.scale, Vector2.ONE, "Medium asteroid node scale remains (1, 1) (avoids double-scaling collision geometry)")

	# 3. Real Physics Engine Contact Damage Integration (2 damage)
	var player = PLAYER_SCENE.instantiate()
	player.position = Vector2(640, 360)
	player.move_speed = 0.0
	add_child(player)

	med_ast.position = Vector2(640, 360)
	med_ast.speed = 0.0

	# Await physics frames for broadphase detection and physics process damage resolution
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_eq(player.health, 10, "Medium asteroid inflicted 2 contact damage to player (12 -> 10)")
	assert_eq(med_ast.health, 40, "Medium asteroid undamaged by player collision (Milestone 1/2 rule)")

	small_ast.queue_free()
	med_ast.queue_free()
	player.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 4: DENSITY PROGRESSION PARAMETERS
# ==============================================================================
func test_suite_4_density_progression_parameters() -> void:
	print("\n--- Running Suite 4: Density Progression Parameters ---")
	var main = MAIN_SCENE.instantiate()
	add_child(main)

	# Compare Level 1 vs Level 2 spawn interval ranges
	assert_true(main.l1_spawn_interval_min < main.l2_spawn_interval_min, "Level 2 min spawn interval (0.65s) is longer than Level 1 (0.35s)")
	assert_true(main.l1_spawn_interval_max < main.l2_spawn_interval_max, "Level 2 max spawn interval (1.25s) is longer than Level 1 (0.85s)")

	var l1_avg_interval: float = (main.l1_spawn_interval_min + main.l1_spawn_interval_max) * 0.5
	var l2_avg_interval: float = (main.l2_spawn_interval_min + main.l2_spawn_interval_max) * 0.5
	var l1_rate: float = 1.0 / l1_avg_interval
	var l2_rate: float = 1.0 / l2_avg_interval

	assert_true(l2_rate < l1_rate, "Level 2 overall asteroid density (~1.05/s) is lower than Level 1 (~1.67/s)")
	assert_eq(main.l2_medium_ratio, 0.40, "Level 2 medium asteroid ratio is 40% (configurable TBD)")

	main.queue_free()


# ==============================================================================
# SUITE 5: SATELLITE LIFECYCLE & DRIFT
# ==============================================================================
func test_suite_5_satellite_lifecycle() -> void:
	print("\n--- Running Suite 5: Satellite Lifecycle & Drift ---")
	var sat = SATELLITE_SCENE.instantiate()
	sat.position = Vector2(500, 100)
	add_child(sat)

	assert_eq(sat.collision_layer, 8, "Satellite collision_layer is 8 (Layer 4: Interactables)")
	assert_eq(sat.collision_mask, 1, "Satellite collision_mask is 1 (Layer 1: Player)")
	assert_true(not sat.is_extracted, "Satellite is initially unextracted")
	assert_eq(sat.extraction_progress, 0.0, "Initial extraction progress is 0.0")
	assert_eq(sat.drift_speed, 100.0, "Satellite drift speed is 100.0 px/s")

	# Test drift movement
	var delta: float = 0.1
	sat._physics_process(delta)
	assert_eq(sat.position.y, 110.0, "Satellite drifts downward at 100 px/s (100 -> 110 at delta=0.1)")

	# Test safe bottom screen despawn
	sat.position.y = 800.0
	sat._physics_process(0.01)
	assert_true(sat.is_queued_for_deletion(), "Satellite queues for deletion when crossing Y > 780")

	sat.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 6: SATELLITE PROXIMITY EXTRACTION
# ==============================================================================
func test_suite_6_satellite_proximity_extraction() -> void:
	print("\n--- Running Suite 6: Satellite Proximity Extraction ---")
	var sat = SATELLITE_SCENE.instantiate()
	sat.position = Vector2(640, 360)
	sat.drift_speed = 0.0 # Keep stationary for extraction test
	sat.extraction_time = 0.3 # Use short duration for test
	add_child(sat)

	var player = PLAYER_SCENE.instantiate()
	player.position = Vector2(640, 360) # In proximity
	player.move_speed = 0.0
	add_child(player)

	var started_events: Array = []
	var extracted_events: Array = []
	sat.extraction_started.connect(func(): started_events.append(true))
	sat.extracted.connect(func(payload): extracted_events.append(payload))

	# Wait 3 physics frames for Area2D overlap detection
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_true(sat.player_in_range, "Player detected within satellite extraction radius")
	assert_true(started_events.size() > 0, "extraction_started signal emitted")
	assert_true(sat.extraction_progress > 0.0, "Extraction progress accumulated while in range")

	# Wait for extraction duration to complete (0.3s = ~18 frames)
	for i in range(25):
		await get_tree().physics_frame

	assert_eq(sat.extraction_progress, 1.0, "Extraction progress reached 100%")
	assert_true(sat.is_extracted, "Satellite is_extracted is true")
	assert_eq(extracted_events.size(), 1, "extracted signal emitted exactly once")
	if extracted_events.size() > 0:
		assert_true(extracted_events[0].has("id"), "Payload contains telemetry id")
		assert_eq(extracted_events[0]["id"], "sat_telemetry_01", "Payload id is 'sat_telemetry_01'")
		assert_true(extracted_events[0].has("text"), "Payload contains narrative text")

	# Move player out of range; verify cannot re-extract
	player.position = Vector2(100, 100)
	for i in range(5):
		await get_tree().physics_frame
	assert_true(not sat.player_in_range, "Player out of range")
	assert_eq(extracted_events.size(), 1, "Satellite cannot be extracted multiple times")

	sat.queue_free()
	player.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 7: SATELLITE EXTRACTION INDEPENDENCE (STRICT CONSTRAINT)
# ==============================================================================
func test_suite_7_satellite_optional_independence() -> void:
	print("\n--- Running Suite 7: Satellite Extraction Independence ---")

	# SCENARIO A: 30s survival WITH satellite extracted -> LEVEL 2 WON
	var main_extracted = MAIN_SCENE.instantiate()
	add_child(main_extracted)
	await get_tree().process_frame

	main_extracted.start_level(2, 10)
	main_extracted.satellite_extracted = true
	main_extracted._process(30.0)

	assert_true(main_extracted.finished, "Scenario A: Finished flag set after 30s")
	assert_true(main_extracted.game_won, "Scenario A: Level 2 won with satellite extracted")
	assert_true(main_extracted.message.text.contains("STAGE 1 / LEVEL 2 COMPLETE"), "Scenario A: Displays Level 2 complete message")
	assert_true(main_extracted.message.text.contains("SUCCESS (Telemetry Recovered)"), "Scenario A: Reports extraction success")

	main_extracted.queue_free()
	await get_tree().process_frame

	# SCENARIO B: 30s survival WITHOUT satellite extracted -> LEVEL 2 STILL WON!
	var main_missed = MAIN_SCENE.instantiate()
	add_child(main_missed)
	await get_tree().process_frame

	main_missed.start_level(2, 10)
	main_missed.satellite_extracted = false # Satellite missed / unextracted
	main_missed._process(30.0)

	assert_true(main_missed.finished, "Scenario B: Finished flag set after 30s without extraction")
	assert_true(main_missed.game_won, "Scenario B: Level 2 won without satellite extraction (extraction is strictly optional!)")
	assert_true(main_missed.message.text.contains("STAGE 1 / LEVEL 2 COMPLETE"), "Scenario B: Displays Level 2 complete message")
	assert_true(main_missed.message.text.contains("MISSED (Satellite Drifted Away)"), "Scenario B: Reports satellite missed without failing level")

	main_missed.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 8: NO PLAYER WEAPONS IN LEVEL 2
# ==============================================================================
func test_suite_8_no_player_weapons_in_level_2() -> void:
	print("\n--- Running Suite 8: No Player Weapons in Level 2 ---")
	var main = MAIN_SCENE.instantiate()
	add_child(main)
	main.start_level(2, 12)

	assert_eq(main.current_level, 2, "Main is in Level 2")
	assert_true(is_instance_valid(main.player), "Player exists in Level 2")

	# Verify no weapon child nodes or shooting methods
	var weapon_nodes: int = 0
	for child in main.player.get_children():
		var child_name: String = child.name.to_lower()
		if child_name.contains("weapon") or child_name.contains("gun") or child_name.contains("laser") or child_name.contains("projectile"):
			weapon_nodes += 1

	assert_eq(weapon_nodes, 0, "Player has zero weapon child nodes in Level 2")
	assert_true(not main.player.has_method("shoot"), "Player has no shoot() method in Level 2")
	assert_true(not main.player.has_method("fire"), "Player has no fire() method in Level 2")

	main.queue_free()


func _print_summary() -> void:
	print("\n==================================================")
	print("MILESTONE 2 TEST RESULTS SUMMARY")
	print("==================================================")
	print("Total tests executed: %d" % total_count)
	print("Passed: %d" % pass_count)
	print("Failed: %d" % fail_count)
	if fail_count == 0:
		print("STATUS: ALL MILESTONE 2 TESTS PASSED SUCCESSFULLY!")
	else:
		printerr("STATUS: SOME MILESTONE 2 TESTS FAILED!")
	print("==================================================")
