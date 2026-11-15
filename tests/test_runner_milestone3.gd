extends Node
## Test runner logic for Milestone 3 (Stage 1 Level 3).
## Validates Level 3 progression, Large Asteroids, Wrecked Spacecraft, and Equipment Acquisition.

var total_count: int = 0
var pass_count: int = 0
var fail_count: int = 0

const PLAYER_SCENE = preload("res://scenes/player.tscn")
const ASTEROID_SCENE = preload("res://scenes/asteroid.tscn")
const SATELLITE_SCENE = preload("res://scenes/satellite.tscn")
const WRECKED_SHIP_SCENE = preload("res://scenes/wrecked_ship.tscn")
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
	await test_suite_b_level_2_to_3_transition()
	await test_suite_c_large_asteroid_properties_and_physics()
	test_suite_d_level_3_density_and_spawner_distribution()
	await test_suite_e_level_3_death_and_checkpoint_revive()
	await test_suite_f_wrecked_spacecraft_and_equipment_acquisition()


# ==============================================================================
# SUITE B: LEVEL 2 TO LEVEL 3 TRANSITION & HP PERSISTENCE
# ==============================================================================
func test_suite_b_level_2_to_3_transition() -> void:
	print("\n--- Running Suite B: Level 2 to Level 3 Transition & HP Persistence ---")
	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	# Start in Level 2 at 10 HP (simulating L1 exit)
	main.start_level(2, 10)
	main.satellite_extracted = true
	main.stage_acquisitions["satellite_telemetry"] = {"id": "sat_01", "recovered": true}
	main._spawn_asteroid()
	main._spawn_asteroid()
	assert_eq(main.current_level, 2, "Main initialized in Level 2")
	assert_eq(main.player.health, 10, "Player starts Level 2 at 10 HP")

	# Take 4 damage in Level 2 (10 -> 6 HP)
	main.player.take_damage(4)
	assert_eq(main.player.health, 6, "Player HP reduced to 6 in Level 2")

	# Simulate surviving 30s in Level 2
	main._process(30.0)
	assert_true(main.finished, "Level 2 marked finished after 30s")
	assert_true(main.game_won, "Level 2 game_won is true")
	assert_true(main.message.text.contains("Press [Space/Enter] for Level 3"), "Level 2 completion prompts advance to Level 3")

	# Advance to Level 3
	main.advance_to_next_level()
	await get_tree().process_frame

	# Verify Level 3 state
	assert_eq(main.current_level, 3, "Transitioned to Stage 1 Level 3")
	assert_eq(main.player.health, 6, "Player HP persisted into Level 3 (6 HP, not healed to 12)")
	assert_eq(main.player.max_health, 12, "Player max_health remains 12")
	assert_true(main.player.alive, "Player is alive in Level 3")
	assert_true(main.player.is_physics_processing(), "Player physics processing enabled in Level 3")
	assert_true(main.time_remaining >= 29.9 and main.time_remaining <= 30.0, "Level 3 survival timer initialized to 30.0s")
	assert_true(not main.finished, "Level 3 starts unfinished")
	assert_true(not main.game_won, "Level 3 starts with game_won false")

	# Verify satellite telemetry persisted across levels
	assert_true(main.satellite_extracted, "Satellite extraction status persisted into Level 3")
	assert_true(main.stage_acquisitions.has("satellite_telemetry"), "Satellite telemetry data preserved in stage acquisitions")

	# Verify old entities cleared
	var old_asteroids: int = 0
	for child in main.get_children():
		if child.is_in_group("asteroids") or child.is_in_group("satellites"):
			old_asteroids += 1
	assert_eq(old_asteroids, 0, "Old Level 2 asteroids and satellite instances cleared upon entering Level 3")

	main.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE C: LARGE ASTEROID PROPERTIES & REAL PHYSICS COLLISION
# ==============================================================================
func test_suite_c_large_asteroid_properties_and_physics() -> void:
	print("\n--- Running Suite C: Large Asteroid Properties & Real Physics Collision ---")
	var small_ast = ASTEROID_SCENE.instantiate()
	var med_ast = ASTEROID_SCENE.instantiate()
	var lrg_ast = ASTEROID_SCENE.instantiate()
	add_child(small_ast)
	add_child(med_ast)
	add_child(lrg_ast)

	# Configure sizes
	small_ast.set_size_tier(small_ast.AsteroidSize.SMALL)
	med_ast.set_size_tier(med_ast.AsteroidSize.MEDIUM)
	lrg_ast.set_size_tier(lrg_ast.AsteroidSize.LARGE)

	# 1. Confirmed Stats Verification
	assert_eq(small_ast.max_health, 20, "Small asteroid max HP is 20")
	assert_eq(small_ast.contact_damage, 1, "Small asteroid contact damage is 1")
	assert_eq(med_ast.max_health, 40, "Medium asteroid max HP is 40")
	assert_eq(med_ast.contact_damage, 2, "Medium asteroid contact damage is 2")
	assert_eq(lrg_ast.max_health, 80, "Large asteroid max HP is 80")
	assert_eq(lrg_ast.health, 80, "Large asteroid starts with full 80 HP")
	assert_eq(lrg_ast.contact_damage, 4, "Large asteroid contact damage is 4")

	# 2. Shape Independence & No Double Scaling
	var small_shape = small_ast.get_node("CollisionShape2D").shape
	var med_shape = med_ast.get_node("CollisionShape2D").shape
	var lrg_shape = lrg_ast.get_node("CollisionShape2D").shape

	assert_eq(small_shape.radius, 19.0, "Small asteroid collision radius is 19.0 px")
	assert_eq(med_shape.radius, 35.0, "Medium asteroid collision radius is 35.0 px")
	assert_eq(lrg_shape.radius, 65.0, "Large asteroid collision radius is 65.0 px")

	assert_true(lrg_shape != small_shape and lrg_shape != med_shape, "Large asteroid owns an independent CircleShape2D instance (no shared resource mutation)")
	assert_eq(lrg_ast.scale, Vector2.ONE, "Large asteroid node scale remains Vector2.ONE (prevents double-scaling collision geometry)")

	# 3. Real Physics Engine Contact Damage Integration (4 damage)
	var player = PLAYER_SCENE.instantiate()
	player.position = Vector2(640, 360)
	player.move_speed = 0.0
	add_child(player)

	lrg_ast.position = Vector2(640, 360)
	lrg_ast.speed = 0.0

	# Await physics frames for broadphase detection and physics process damage resolution
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_eq(player.health, 8, "Large asteroid inflicted 4 contact damage to player (12 -> 8)")
	assert_eq(lrg_ast.health, 80, "Large asteroid undamaged by player collision (Milestone 3 rule)")

	# 4. Sustained Overlap (0.5s rate-limiting)
	var lrg_id: int = lrg_ast.get_instance_id()
	assert_true(player.contact_cooldown.has(lrg_id), "Player registered contact cooldown for Large asteroid")
	assert_eq(player.contact_cooldown[lrg_id], 0.5, "Large asteroid cooldown initialized to 0.5s")

	# Wait 25 frames (~0.41s) within cooldown
	for i in range(25):
		await get_tree().physics_frame
	assert_eq(player.health, 8, "No per-frame damage drain during 0.5s cooldown")

	# Wait another 10 frames (> 0.55s total)
	for i in range(10):
		await get_tree().physics_frame
	assert_eq(player.health, 4, "Sustained overlap > 0.5s dealt second 4-damage tick (8 -> 4)")

	small_ast.queue_free()
	med_ast.queue_free()
	lrg_ast.queue_free()
	player.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE D: LEVEL 3 DENSITY & SPAWNER DISTRIBUTION
# ==============================================================================
func test_suite_d_level_3_density_and_spawner_distribution() -> void:
	print("\n--- Running Suite D: Level 3 Density & Spawner Distribution ---")
	var main = MAIN_SCENE.instantiate()
	add_child(main)

	# Compare spawn intervals across all 3 levels
	assert_true(main.l3_spawn_interval_min > main.l2_spawn_interval_min, "Level 3 min spawn interval (1.00s) > Level 2 (0.65s)")
	assert_true(main.l3_spawn_interval_max > main.l2_spawn_interval_max, "Level 3 max spawn interval (1.80s) > Level 2 (1.25s)")

	var l1_avg: float = (main.l1_spawn_interval_min + main.l1_spawn_interval_max) * 0.5 # ~0.60s = 1.67/s
	var l2_avg: float = (main.l2_spawn_interval_min + main.l2_spawn_interval_max) * 0.5 # ~0.95s = 1.05/s
	var l3_avg: float = (main.l3_spawn_interval_min + main.l3_spawn_interval_max) * 0.5 # ~1.40s = 0.71/s

	assert_true((1.0 / l3_avg) < (1.0 / l2_avg), "Level 3 overall asteroid density (~0.71/s) is lower than Level 2 (~1.05/s)")
	assert_true((1.0 / l2_avg) < (1.0 / l1_avg), "Level 2 overall asteroid density is lower than Level 1")

	# Verify distribution ratios sum to 1.0
	assert_eq(main.l3_small_ratio, 0.30, "Level 3 small asteroid ratio is 30%")
	assert_eq(main.l3_medium_ratio, 0.40, "Level 3 medium asteroid ratio is 40%")
	assert_eq(main.l3_large_ratio, 0.30, "Level 3 large asteroid ratio is 30%")
	assert_true(absf((main.l3_small_ratio + main.l3_medium_ratio + main.l3_large_ratio) - 1.0) < 0.001, "Level 3 asteroid ratios sum to 100%")

	# Verify spawner produces all 3 tiers in Level 3
	main.start_level(3, 12)
	var spawned_small: int = 0
	var spawned_med: int = 0
	var spawned_lrg: int = 0

	# Spawn sample of asteroids to verify tiers
	for i in range(100):
		main._spawn_asteroid()

	for child in main.get_children():
		if child.is_in_group("asteroids"):
			if child.size_tier == child.AsteroidSize.SMALL:
				spawned_small += 1
			elif child.size_tier == child.AsteroidSize.MEDIUM:
				spawned_med += 1
			elif child.size_tier == child.AsteroidSize.LARGE:
				spawned_lrg += 1

	assert_true(spawned_small > 0, "Spawner generated Small asteroids in Level 3")
	assert_true(spawned_med > 0, "Spawner generated Medium asteroids in Level 3")
	assert_true(spawned_lrg > 0, "Spawner generated Large asteroids in Level 3")

	main.queue_free()


# ==============================================================================
# SUITE E: LEVEL 3 DEATH & STAGE CHECKPOINT REVIVE
# ==============================================================================
func test_suite_e_level_3_death_and_checkpoint_revive() -> void:
	print("\n--- Running Suite E: Level 3 Death & Stage Checkpoint Revive ---")
	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	# Start in Level 3 with 4 HP
	main.start_level(3, 4)
	main.satellite_extracted = true
	main.stage_acquisitions["satellite_telemetry"] = {"test": true}
	assert_eq(main.current_level, 3, "Started in Level 3")
	assert_eq(main.player.health, 4, "Player starts Level 3 at 4 HP")

	# Player takes lethal damage in Level 3
	main.player.take_damage(4)
	assert_eq(main.player.health, 0, "Player HP reduced to 0 in Level 3")
	assert_true(not main.player.alive, "Player alive is false")
	assert_true(main.finished, "Level marked finished on death")
	assert_true(not main.game_won, "game_won is false on death")

	# Verify equipment is NOT granted on failure
	assert_true(not main.is_primary_weapon_acquired(), "Primary weapon is NOT granted upon dying in Level 3")
	assert_true(not main.is_shield_acquired(), "Shield is NOT granted upon dying in Level 3")
	assert_true(main.message.text.contains("Revive at Stage 1 Checkpoint"), "Death message prompts revive at Stage 1 Checkpoint")

	# Revive at Stage 1 Checkpoint
	main.revive_at_stage_checkpoint()
	await get_tree().process_frame

	assert_eq(main.current_level, 1, "Revive strictly returns to Stage 1 Level 1 (Stage Checkpoint)")
	assert_eq(main.player.health, 12, "Player HP is restored to full (12 HP) upon revive")
	assert_true(main.player.alive, "Player is alive after revive")
	assert_true(main.time_remaining >= 29.9 and main.time_remaining <= 30.0, "Level 1 timer reset to 30.0s")
	assert_true(main.stage_acquisitions.is_empty(), "Stage acquisitions completely cleared upon checkpoint revive")
	assert_true(not main.satellite_extracted, "Satellite extraction flag cleared upon checkpoint revive")

	main.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE F: WRECKED SPACECRAFT & EQUIPMENT ACQUISITION
# ==============================================================================
func test_suite_f_wrecked_spacecraft_and_equipment_acquisition() -> void:
	print("\n--- Running Suite F: Wrecked Spacecraft & Equipment Acquisition ---")
	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	var equip_signals: Array = []
	main.equipment_acquired.connect(func(payload): equip_signals.append(payload))

	# 1. Equipment remains absent during survival phase
	main.start_level(3, 8)
	assert_true(not main.is_primary_weapon_acquired(), "Primary weapon NOT acquired during Level 3 survival phase")
	assert_true(not main.is_shield_acquired(), "Shield NOT acquired during Level 3 survival phase")
	assert_true(not main.has_equipment(), "has_equipment() returns false during survival phase")

	# Verify no wrecked ship in scene during survival
	var wrecks_during: int = 0
	for child in main.get_children():
		if child.is_in_group("wrecked_ships"):
			wrecks_during += 1
	assert_eq(wrecks_during, 0, "No wrecked ship present during active survival phase")

	# 2. Simulate surviving the full 30 seconds
	main._process(30.0)
	assert_true(main.finished, "Level 3 finished after 30s")
	assert_true(main.game_won, "Level 3 game_won is true")

	# 3. Verify Equipment Acquisition State
	assert_true(main.is_primary_weapon_acquired(), "primary_weapon_acquired is true after Level 3 success")
	assert_true(main.is_shield_acquired(), "shield_acquired is true after Level 3 success")
	assert_true(main.has_equipment(), "has_equipment() returns true after Level 3 success")
	assert_eq(equip_signals.size(), 1, "equipment_acquired signal emitted exactly once")
	if equip_signals.size() > 0:
		assert_true(equip_signals[0].has("primary_weapon"), "Payload confirms primary_weapon")
		assert_true(equip_signals[0].has("shield"), "Payload confirms shield")
		assert_true(equip_signals[0].has("source"), "Payload attributes source to wrecked scout craft")

	# 4. Verify Wrecked Spacecraft Encounter Revealed
	var wrecks_after: int = 0
	for child in main.get_children():
		if child.is_in_group("wrecked_ships"):
			wrecks_after += 1
	assert_eq(wrecks_after, 1, "Wrecked scout craft entity revealed in scene upon Level 3 completion")

	# 5. Verify Clean Prototype End Screen (No Level 4 silent advance)
	assert_true(main.message.text.contains("STAGE 1 / LEVEL 3 COMPLETE!"), "Displays Level 3 completion banner")
	assert_true(main.message.text.contains("Twin-barrel Pulse Cannon"), "Confirmation displays primary weapon recovered")
	assert_true(main.message.text.contains("Deflector Shield Generator"), "Confirmation displays deflector shield recovered")
	assert_true(main.message.text.contains("END OF PROTOTYPE"), "Message indicates end of prototype milestone")
	assert_true(not main.message.text.contains("for Level 4"), "No Level 4 advance button or prompt is displayed")

	# 6. Verify Player has no active shooting/weapon node during Milestone 3
	var weapon_nodes: int = 0
	for child in main.player.get_children():
		var child_name: String = child.name.to_lower()
		if child_name.contains("weapon") or child_name.contains("gun") or child_name.contains("laser") or child_name.contains("projectile"):
			weapon_nodes += 1
	assert_eq(weapon_nodes, 0, "Player has zero active weapon child nodes in Milestone 3 (shooting reserved for M4)")

	main.queue_free()
	await get_tree().process_frame


func _print_summary() -> void:
	print("\n==================================================")
	print("MILESTONE 3 TEST RESULTS SUMMARY")
	print("==================================================")
	print("Total tests executed: %d" % total_count)
	print("Passed: %d" % pass_count)
	print("Failed: %d" % fail_count)
	if fail_count == 0:
		print("STATUS: ALL MILESTONE 3 TESTS PASSED SUCCESSFULLY!")
	else:
		printerr("STATUS: SOME MILESTONE 3 TESTS FAILED!")
	print("==================================================")

