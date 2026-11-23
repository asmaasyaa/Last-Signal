extends Node
## Test runner logic for Milestone 4 (Stage 1 Level 4: Twin-Barrel Shooting & Asteroid Combat).
## Validates Suites A through F covering Level 3 -> 4 progression, weapon mechanics, projectile physics,
## asteroid health & destruction, Stage 1 checkpoint revive semantics, and zero regression.

var total_count: int = 0
var pass_count: int = 0
var fail_count: int = 0

const MAIN_SCENE = preload("res://scenes/main.tscn")
const PROJECTILE_SCENE = preload("res://scenes/projectile.tscn")
const ASTEROID_SCENE = preload("res://scenes/asteroid.tscn")
const PLAYER_SCENE = preload("res://scenes/player.tscn")
const SATELLITE_SCENE = preload("res://scenes/satellite.tscn")
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
	print("LAST SIGNAL — Milestone 4 Automated Test Suite")
	print("==================================================")
	await test_suite_a_progression_and_level_transition()
	await test_suite_b_weapon_controller_and_firing_rules()
	await test_suite_c_projectile_physics_and_damage_lifecycle()
	await test_suite_d_asteroid_health_damage_and_destruction()
	await test_suite_e_checkpoint_and_revive_semantics()
	await test_suite_f_system_wide_regression_and_integration()


# ==============================================================================
# SUITE A: PROGRESSION & LEVEL 3 -> LEVEL 4 TRANSITION
# ==============================================================================
func test_suite_a_progression_and_level_transition() -> void:
	print("\n--- Running Suite A: Progression & Level 3 -> Level 4 Transition ---")

	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	# 1. Main initial state
	assert_eq(main.current_level, 1, "Main initializes at Stage 1 Level 1")
	assert_true(main.is_primary_weapon_acquired() == false, "Primary weapon is not acquired initially")
	assert_true(main.is_shield_acquired() == false, "Shield is not acquired initially")

	# 2. Start Level 3 and simulate completion
	main.start_level(3, 9)
	assert_eq(main.current_level, 3, "Main started Level 3")
	assert_eq(main.player.health, 9, "Player HP persisted at 9 in Level 3")

	var equip_emitted: Array = []
	main.equipment_acquired.connect(func(payload): equip_emitted.append(payload))

	main.time_remaining = 0.0
	main._complete_level()
	await get_tree().process_frame

	assert_true(main.finished, "Level 3 is marked finished on 30s elapsed")
	assert_true(main.game_won, "Level 3 is marked game_won")
	assert_true(main.is_primary_weapon_acquired(), "Primary weapon acquired upon Level 3 completion")
	assert_true(main.is_shield_acquired(), "Deflector shield acquired upon Level 3 completion")
	assert_true(main.has_equipment(), "Main reports has_equipment() == true")
	assert_eq(equip_emitted.size(), 1, "equipment_acquired signal emitted exactly once")
	if equip_emitted.size() > 0:
		assert_true(equip_emitted[0].get("primary_weapon", false), "Payload includes primary_weapon: true")
		assert_true(equip_emitted[0].get("shield", false), "Payload includes shield: true")

	# Verify wrecked ship derelict spawned
	var found_wreck: bool = false
	for child in main.get_children():
		if child.is_in_group("wrecked_ships"):
			found_wreck = true
			break
	assert_true(found_wreck, "Wrecked scout craft derelict spawned in Level 3 completion")

	# 3. Advance to Level 4
	main.advance_to_next_level()
	await get_tree().process_frame

	assert_eq(main.current_level, 4, "Main successfully transitioned to Stage 1 Level 4")
	assert_true(main.time_remaining >= 29.9 and main.time_remaining <= 30.0, "Level 4 survival timer reset to 30.0s")
	assert_eq(main.player.health, 9, "Persistent HP (9) maintained into Level 4")
	assert_true(main.is_primary_weapon_acquired(), "Primary weapon acquisition preserved in Level 4")
	assert_true(main.is_shield_acquired(), "Shield acquisition preserved in Level 4")

	# Verify old entities cleaned up
	var lingering_wrecks: int = 0
	for child in main.get_children():
		if child.is_in_group("wrecked_ships") and not child.is_queued_for_deletion():
			lingering_wrecks += 1
	assert_eq(lingering_wrecks, 0, "Derelict wrecked ship cleaned up upon entering Level 4")

	main.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE B: WEAPON CONTROLLER & FIRING RULES
# ==============================================================================
func test_suite_b_weapon_controller_and_firing_rules() -> void:
	print("\n--- Running Suite B: Weapon Controller & Firing Rules ---")

	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	# 1. Architecture: WeaponController attached to Main, NOT Player
	var weapon_ctrl = main.get_node_or_null("WeaponController")
	assert_true(weapon_ctrl != null, "WeaponController node exists as child of Main")

	# Milestone 2 Suite 8 constraint check: Player has no weapon children and no shoot/fire methods
	for child in main.player.get_children():
		var child_name: String = child.name.to_lower()
		assert_true(not ("weapon" in child_name or "gun" in child_name or "laser" in child_name or "projectile" in child_name),
			"Player node has no forbidden weapon child: %s" % child.name)
	assert_true(not main.player.has_method("shoot"), "Player has no shoot() method (M2 constraint preserved)")
	assert_true(not main.player.has_method("fire"), "Player has no fire() method (M2 constraint preserved)")

	# 2. Weapons inoperable during Levels 1, 2, and 3
	main.start_level(1, 12)
	assert_true(not weapon_ctrl.firing_enabled, "Weapon firing disabled in Level 1")
	assert_true(not weapon_ctrl.can_fire(), "Weapon cannot fire in Level 1")

	main.start_level(2, 12)
	assert_true(not weapon_ctrl.firing_enabled, "Weapon firing disabled in Level 2")
	assert_true(not weapon_ctrl.can_fire(), "Weapon cannot fire in Level 2")

	main.start_level(3, 12)
	assert_true(not weapon_ctrl.firing_enabled, "Weapon firing disabled in Level 3")
	assert_true(not weapon_ctrl.can_fire(), "Weapon cannot fire in Level 3")

	# 3. Weapons active in Level 4 with weapon acquired
	main.stage_acquisitions["primary_weapon_acquired"] = true
	main.start_level(4, 12)
	assert_true(weapon_ctrl.firing_enabled, "Weapon firing enabled in Level 4 when acquired")
	assert_true(weapon_ctrl.can_fire(), "Weapon can fire in Level 4")

	# 4. Firing specifications
	assert_eq(weapon_ctrl.volleys_per_second, 6.0, "Firing rate is 6 volleys per second")
	assert_eq(weapon_ctrl.projectile_damage, 1, "Projectile damage is 1 per bolt")
	assert_eq(weapon_ctrl.projectile_speed, 750.0, "Projectile speed is 750 px/s")
	assert_eq(weapon_ctrl.muzzle_offset_lateral, 12.0, "Lateral muzzle offset is 12 px")
	assert_eq(weapon_ctrl.muzzle_offset_forward, 24.0, "Forward muzzle offset is 24 px")

	# 5. Volley emission
	var volley_fired_emitted: Array = []
	weapon_ctrl.volley_fired.connect(func(arr): volley_fired_emitted.append(arr))

	var projs: Array = weapon_ctrl.fire_volley()
	assert_eq(projs.size(), 2, "Volley produces exactly 2 projectiles (twin barrels)")
	assert_eq(volley_fired_emitted.size(), 1, "volley_fired signal emitted on firing")

	# 6. Muzzle positions & parallel trajectories
	var p_left = projs[0]
	var p_right = projs[1]
	assert_true(is_instance_valid(p_left) and is_instance_valid(p_right), "Both projectiles are valid instances")

	var forward: Vector2 = Vector2.UP.rotated(main.player.rotation)
	var right_vec: Vector2 = Vector2.RIGHT.rotated(main.player.rotation)
	var expected_left: Vector2 = main.player.global_position + forward * 24.0 - right_vec * 12.0
	var expected_right: Vector2 = main.player.global_position + forward * 24.0 + right_vec * 12.0

	assert_true(p_left.global_position.distance_to(expected_left) < 1.0, "Left projectile spawned at correct left muzzle")
	assert_true(p_right.global_position.distance_to(expected_right) < 1.0, "Right projectile spawned at correct right muzzle")
	assert_true(p_left.direction.is_equal_approx(p_right.direction), "Both projectiles share identical forward trajectory (parallel)")

	# 7. Cooldown rate limiting (1.0 / 6.0 = 0.1667s)
	assert_true(weapon_ctrl.fire_cooldown > 0.15, "Fire cooldown set to ~0.1667s after firing")
	assert_true(not weapon_ctrl.can_fire(), "Weapon cannot fire again immediately while in cooldown")

	# Process delta to elapse cooldown
	weapon_ctrl._process(0.18)
	assert_eq(weapon_ctrl.fire_cooldown, 0.0, "Cooldown cleanly reaches 0 after delta elapsed")
	assert_true(weapon_ctrl.can_fire(), "Weapon can fire again after cooldown elapses")

	# 8. Rotation tracking: rotate player by 90 degrees (facing right)
	main.player.rotation = PI * 0.5
	var projs_rotated: Array = weapon_ctrl.fire_volley()
	assert_eq(projs_rotated.size(), 2, "Rotated volley produces 2 projectiles")
	assert_true(projs_rotated[0].direction.is_equal_approx(Vector2.RIGHT), "Rotated projectiles follow player's facing direction (RIGHT)")

	# Cleanup
	weapon_ctrl.clear_projectiles()
	main.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE C: PROJECTILE PHYSICS & DAMAGE LIFECYCLE
# ==============================================================================
func test_suite_c_projectile_physics_and_damage_lifecycle() -> void:
	print("\n--- Running Suite C: Projectile Physics & Damage Lifecycle ---")

	# 1. Projectile scene verification
	var proj = PROJECTILE_SCENE.instantiate()
	add_child(proj)
	await get_tree().process_frame

	assert_true(proj.is_in_group("projectiles"), "Projectile is in 'projectiles' group")
	assert_eq(proj.collision_layer, 4, "Projectile is on Collision Layer 4 (bitmask 4, Layer 3: Player Projectiles)")
	assert_eq(proj.collision_mask, 2, "Projectile collision mask is 2 (Layer 2: Asteroids)")
	assert_eq(proj.damage, 1, "Projectile deals exactly 1 damage")
	assert_eq(proj.speed, 750.0, "Projectile default speed is 750.0 px/s")
	assert_eq(proj.lifetime, 2.5, "Projectile lifetime is 2.5s")

	# 2. Physics motion
	proj.global_position = Vector2(500, 500)
	proj.direction = Vector2.UP
	proj._physics_process(0.1)
	assert_eq(proj.global_position, Vector2(500, 500 - 750.0 * 0.1), "Projectile moves forward along direction * speed * delta")

	# 3. Safe boundary despawn
	proj.global_position = Vector2(500, -55.0)
	proj._physics_process(0.01)
	assert_true(proj.is_queued_for_deletion(), "Projectile despawns when exceeding top boundary (y < -50)")

	# 4. Safe lifetime despawn
	var proj2 = PROJECTILE_SCENE.instantiate()
	add_child(proj2)
	proj2.global_position = Vector2(500, 300)
	proj2.elapsed_time = 2.6
	proj2._physics_process(0.01)
	assert_true(proj2.is_queued_for_deletion(), "Projectile despawns when exceeding lifetime (2.5s)")

	# 5. Collision with Asteroid
	var proj3 = PROJECTILE_SCENE.instantiate()
	var ast = ASTEROID_SCENE.instantiate()
	add_child(proj3)
	add_child(ast)
	ast.set_size_tier(ast.AsteroidSize.SMALL)
	var initial_ast_hp: int = ast.health

	var hit_emitted: Array = []
	proj3.hit.connect(func(t): hit_emitted.append(t))

	proj3._on_area_entered(ast)
	assert_true(proj3.has_hit, "Projectile marked has_hit = true on collision")
	assert_true(proj3.is_queued_for_deletion(), "Projectile queues free on collision")
	assert_eq(hit_emitted.size(), 1, "Projectile hit signal emitted")
	assert_eq(ast.health, initial_ast_hp - 1, "Asteroid received exactly 1 damage from projectile")

	# 6. Protection against repeated damage callbacks on same frame
	proj3._on_area_entered(ast)
	assert_eq(ast.health, initial_ast_hp - 1, "No double-damage applied on repeated callback")

	# 7. Non-asteroid immunity: Projectile cannot damage player or satellite
	var proj4 = PROJECTILE_SCENE.instantiate()
	var player = PLAYER_SCENE.instantiate()
	add_child(proj4)
	add_child(player)
	var player_initial_hp: int = player.health

	proj4._on_area_entered(player)
	assert_true(not proj4.has_hit, "Projectile does not hit Player Area2D")
	assert_eq(player.health, player_initial_hp, "Player takes 0 damage from projectile")

	var sat = SATELLITE_SCENE.instantiate()
	add_child(sat)
	proj4._on_area_entered(sat)
	assert_true(not proj4.has_hit, "Projectile does not hit Satellite Area2D")

	ast.queue_free()
	player.queue_free()
	sat.queue_free()
	proj4.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE D: ASTEROID HEALTH, DAMAGE & DESTRUCTION
# ==============================================================================
func test_suite_d_asteroid_health_damage_and_destruction() -> void:
	print("\n--- Running Suite D: Asteroid Health, Damage & Destruction ---")

	# 1. Tier health and contact damage
	var ast_small = ASTEROID_SCENE.instantiate()
	ast_small.set_size_tier(ast_small.AsteroidSize.SMALL)
	assert_eq(ast_small.max_health, 20, "Small asteroid max health is 20")
	assert_eq(ast_small.health, 20, "Small asteroid health initialized to 20")
	assert_eq(ast_small.contact_damage, 1, "Small asteroid contact damage is 1")

	var ast_med = ASTEROID_SCENE.instantiate()
	ast_med.set_size_tier(ast_med.AsteroidSize.MEDIUM)
	assert_eq(ast_med.max_health, 40, "Medium asteroid max health is 40")
	assert_eq(ast_med.health, 40, "Medium asteroid health initialized to 40")
	assert_eq(ast_med.contact_damage, 2, "Medium asteroid contact damage is 2")

	var ast_large = ASTEROID_SCENE.instantiate()
	ast_large.set_size_tier(ast_large.AsteroidSize.LARGE)
	assert_eq(ast_large.max_health, 80, "Large asteroid max health is 80")
	assert_eq(ast_large.health, 80, "Large asteroid health initialized to 80")
	assert_eq(ast_large.contact_damage, 4, "Large asteroid contact damage is 4")

	# 2. take_damage signals and health deduction
	add_child(ast_small)
	var damaged_events: Array = []
	var destroyed_events: Array = []
	ast_small.damaged.connect(func(amt, rem): damaged_events.append({"amount": amt, "remaining": rem}))
	ast_small.destroyed.connect(func(): destroyed_events.append(true))

	ast_small.take_damage(1)
	assert_eq(ast_small.health, 19, "Small asteroid health deducted to 19")
	assert_eq(damaged_events.size(), 1, "damaged signal emitted")
	assert_eq(damaged_events[0].remaining, 19, "Signal reported remaining health 19")
	assert_true(not ast_small.is_destroyed, "Asteroid not destroyed yet at 19 HP")

	# Apply 18 more hits (total 19 hits)
	for i in range(18):
		ast_small.take_damage(1)
	assert_eq(ast_small.health, 1, "Asteroid health is 1 after 19 hits")
	assert_true(not ast_small.is_destroyed, "Asteroid not destroyed at 1 HP")

	# 20th hit: destruction
	ast_small.take_damage(1)
	assert_eq(ast_small.health, 0, "Asteroid health reached 0")
	assert_true(ast_small.is_destroyed, "Asteroid marked is_destroyed = true")
	assert_eq(ast_small.contact_damage, 0, "Asteroid contact damage immediately negated to 0 upon destruction")
	assert_eq(destroyed_events.size(), 1, "destroyed signal emitted on reaching 0 HP")
	assert_true(ast_small.is_queued_for_deletion(), "Asteroid queued free on destruction")

	# 3. Medium asteroid 40 hits destruction test
	add_child(ast_med)
	for i in range(39):
		ast_med.take_damage(1)
	assert_eq(ast_med.health, 1, "Medium asteroid at 1 HP after 39 hits")
	ast_med.take_damage(1)
	assert_eq(ast_med.health, 0, "Medium asteroid at 0 HP after 40 hits")
	assert_true(ast_med.is_destroyed, "Medium asteroid destroyed after 40 hits")
	assert_eq(ast_med.contact_damage, 0, "Medium asteroid contact damage negated to 0")

	# 4. Large asteroid 80 hits destruction test
	add_child(ast_large)
	for i in range(79):
		ast_large.take_damage(1)
	assert_eq(ast_large.health, 1, "Large asteroid at 1 HP after 79 hits")
	ast_large.take_damage(1)
	assert_eq(ast_large.health, 0, "Large asteroid at 0 HP after 80 hits")
	assert_true(ast_large.is_destroyed, "Large asteroid destroyed after 80 hits")
	assert_eq(ast_large.contact_damage, 0, "Large asteroid contact damage negated to 0")

	# 5. Damage clamping
	var ast_clamp = ASTEROID_SCENE.instantiate()
	ast_clamp.set_size_tier(ast_clamp.AsteroidSize.SMALL)
	add_child(ast_clamp)
	ast_clamp.take_damage(50) # Excessive damage
	assert_eq(ast_clamp.health, 0, "Health clamped cleanly at 0")
	assert_true(ast_clamp.is_destroyed, "Asteroid destroyed after excess damage")

	await get_tree().process_frame


# ==============================================================================
# SUITE E: CHECKPOINT & REVIVE SEMANTICS
# ==============================================================================
func test_suite_e_checkpoint_and_revive_semantics() -> void:
	print("\n--- Running Suite E: Checkpoint & Revive Semantics ---")

	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	# 1. Setup in Level 4 with weapon acquired
	main.stage_acquisitions["primary_weapon_acquired"] = true
	main.stage_acquisitions["shield_acquired"] = true
	main.start_level(4, 7)
	assert_eq(main.current_level, 4, "Main running Level 4")
	assert_true(main.weapon_controller.firing_enabled, "Weapons enabled in Level 4")

	# 2. Player death in Level 4
	main.player.take_damage(7)
	assert_true(main.finished, "Level finished on player death")
	assert_true(not main.game_won, "Game marked not won")
	assert_true(not main.weapon_controller.firing_enabled, "Weapon firing disabled immediately on player death")
	assert_true("SHIP DESTROYED (STAGE 1 / LEVEL 4)" in main.message.text, "Death message indicates Level 4 loss")
	assert_true("Revive at Stage 1 Checkpoint" in main.message.text, "Death message instructs to revive at Checkpoint")

	# 3. Revive at Stage 1 Checkpoint
	main.revive_at_stage_checkpoint()
	await get_tree().process_frame

	assert_eq(main.current_level, 1, "Checkpoint revive returns strictly to Stage 1 Level 1")
	assert_eq(main.player.health, 12, "Player HP restored to 12 on checkpoint revive")
	assert_true(main.time_remaining >= 29.9 and main.time_remaining <= 30.0, "Survival timer reset to 30.0s")
	assert_true(not main.is_primary_weapon_acquired(), "Primary weapon acquisition cleared on checkpoint revive")
	assert_true(not main.is_shield_acquired(), "Shield acquisition cleared on checkpoint revive")
	assert_true(not main.weapon_controller.firing_enabled, "Weapon firing disabled in Level 1 after revive")

	main.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE F: SYSTEM-WIDE REGRESSION & INTEGRATION
# ==============================================================================
func test_suite_f_system_wide_regression_and_integration() -> void:
	print("\n--- Running Suite F: System-Wide Regression & Integration ---")

	# 1. Level 4 successful completion
	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	main.stage_acquisitions["primary_weapon_acquired"] = true
	main.stage_acquisitions["shield_acquired"] = true
	main.start_level(4, 11)
	main.time_remaining = 0.0
	main._complete_level()
	await get_tree().process_frame

	assert_true(main.finished, "Level 4 complete marked finished")
	assert_true(main.game_won, "Level 4 complete marked game_won")
	assert_true(not main.weapon_controller.firing_enabled, "Weapon firing disabled upon Level 4 completion")
	assert_true("STAGE 1 / LEVEL 4 COMPLETE!" in main.message.text, "Message contains Stage 1 / Level 4 Complete")
	assert_true("END OF PROTOTYPE — MILESTONE 4 COMPLETE" in main.message.text, "Message marks Milestone 4 complete")

	# 2. Level Select UI restrictions
	var level_select = LEVEL_SELECT_SCENE.instantiate()
	add_child(level_select)
	await get_tree().process_frame

	assert_true(level_select.is_level_playable(1, 1), "Stage 1 Level 1 is playable from Level Select")
	assert_true(not level_select.is_level_playable(1, 2), "Stage 1 Level 2 locked from Level Select")
	assert_true(not level_select.is_level_playable(1, 3), "Stage 1 Level 3 locked from Level Select")
	assert_true(not level_select.is_level_playable(1, 4), "Stage 1 Level 4 locked from Level Select")
	assert_true(not level_select.is_level_playable(1, 5), "Stage 1 Level 5 locked from Level Select")
	assert_true(not level_select.is_level_playable(2, 1), "Stage 2 Level 1 locked from Level Select")

	level_select._show_locked_status(1, 4)
	assert_true("Accessible via gameplay progression from Level 1" in level_select.status_label.text,
		"Level 4 locked message informs player it is accessible via gameplay progression")

	# 3. Main Menu integrity
	var main_menu = MAIN_MENU_SCENE.instantiate()
	add_child(main_menu)
	await get_tree().process_frame
	assert_true(main_menu.has_node("CenterContainer/VBoxContainer/ButtonsContainer/StartButton"), "Main Menu Start button present")
	assert_true(main_menu.has_node("CenterContainer/VBoxContainer/ButtonsContainer/SelectButton"), "Main Menu Level Select button present")

	main.queue_free()
	level_select.queue_free()
	main_menu.queue_free()
	await get_tree().process_frame


func _print_summary() -> void:
	print("\n==================================================")
	print("MILESTONE 4 TEST SUMMARY: %d Total | %d Passed | %d Failed" % [total_count, pass_count, fail_count])
	print("==================================================")
