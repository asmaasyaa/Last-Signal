extends Node
## Test runner logic for Milestone 8 (Stage 2 Level 3: Kamikaze Guard Drone & EM Jammer Acquisition).
## Validates Suites A through H covering Level 2 -> Level 3 progression, HP persistence,
## Guard Drone enemy, kamikaze mechanics & strict kill credit attribution, untimed 5-kill elimination objective,
## EM Jammer acquisition event, Stage 2 checkpoint revive, and full regression.

var total_count: int = 0
var pass_count: int = 0
var fail_count: int = 0

const MAIN_SCENE = preload("res://scenes/main.tscn")
const STAGE2_MAIN_SCENE = preload("res://scenes/stage2/stage2_main.tscn")
const GUARD_BOT_SCENE = preload("res://scenes/enemies/guard_bot.tscn")
const GUARD_SATELLITE_SCENE = preload("res://scenes/enemies/guard_satellite.tscn")
const GUARD_DRONE_SCENE = preload("res://scenes/enemies/guard_drone.tscn")
const ENEMY_PROJECTILE_SCENE = preload("res://scenes/enemies/enemy_projectile.tscn")
const PROJECTILE_SCENE = preload("res://scenes/projectile.tscn")
const PLAYER_SCENE = preload("res://scenes/player.tscn")
const ASTEROID_SCENE = preload("res://scenes/asteroid.tscn")
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
	await _suite_a_level_progression_and_persistence()
	await _suite_b_elimination_objective_and_kill_counter()
	await _suite_c_guard_drone_enemy_specification()
	await _suite_d_kamikaze_mechanics_and_attribution()
	await _suite_e_combat_physics_and_safety()
	await _suite_f_em_jammer_acquisition_and_deferred_state()
	await _suite_g_stage2_checkpoint_and_revive()
	await _suite_h_regression_level_select_and_architecture()


# ------------------------------------------------------------------------------
# Suite A: Level 2 -> Level 3 Progression & State Persistence
# ------------------------------------------------------------------------------
func _suite_a_level_progression_and_persistence() -> void:
	print("\n--- Running Suite A: Level 2 -> Level 3 Progression & State Persistence ---")

	var stage2 = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2)
	await get_tree().process_frame

	# 1. Start at Level 2 with partial health (8 HP)
	stage2.start_level(2, 8)
	await get_tree().process_frame

	assert_eq(stage2.current_level, 2, "Stage 2 started at Level 2")
	assert_eq(stage2.player.health, 8, "Player started Level 2 at 8 HP")
	assert_false(stage2.finished, "Level 2 is not finished initially")

	# Unfinished Level 2 cannot advance to Level 3
	stage2.advance_to_next_level()
	assert_eq(stage2.current_level, 2, "Unfinished Level 2 cannot advance to Level 3")

	# Spawn an enemy in Level 2 to verify cleanup on advance
	var sat = stage2._spawn_guard_satellite()
	assert_true(is_instance_valid(sat), "Guard Satellite present in Level 2 before advance")

	# Complete Level 2
	stage2._complete_level()
	assert_true(stage2.finished, "Level 2 marked finished")
	assert_true(stage2.game_won, "Level 2 marked game_won")
	assert_true(stage2.message.visible, "Level 2 completion message visible")
	assert_true(stage2.message.text.contains("STAGE 2 / LEVEL 2 COMPLETE!"), "Banner proclaims STAGE 2 / LEVEL 2 COMPLETE!")
	assert_true(stage2.message.text.contains("Press [Space/Enter] for Level 3"), "Banner prompts for Level 3 progression")

	# Advance to Level 3
	stage2.advance_to_next_level()
	await get_tree().process_frame

	# Verify Level 3 state
	assert_eq(stage2.current_level, 3, "current_level advanced to 3")
	assert_false(stage2.finished, "Level 3 marked unfinished on start")
	assert_false(stage2.game_won, "Level 3 game_won reset to false")
	assert_eq(stage2.player.health, 8, "Remaining 8 HP strictly persisted into Level 3 (no within-stage restoration)")
	assert_eq(stage2.player.max_health, 12, "Player max_health remains 12")
	assert_true(stage2.player.alive, "Player is alive")
	assert_true(stage2.player.is_physics_processing(), "Player physics processing enabled")
	assert_true(stage2.is_primary_weapon_acquired(), "Primary weapon acquisition preserved in Level 3")
	assert_true(stage2.is_shield_acquired(), "Shield acquisition preserved in Level 3")
	assert_false(stage2.is_em_jammer_acquired(), "EM Jammer is unearned at Level 3 start")

	# Verify entity cleanup from Level 2
	assert_eq(stage2.enemies_container.get_child_count(), 0, "Old enemies cleaned up on advancing to Level 3")
	assert_eq(stage2.enemy_projectiles_container.get_child_count(), 0, "Old enemy projectiles cleaned up")
	assert_eq(stage2.projectiles_container.get_child_count(), 0, "Old player projectiles cleaned up")

	# Verify Level 3 HUD setup
	assert_true(stage2.info.text.contains("STAGE 2 / LEVEL 3"), "HUD displays STAGE 2 / LEVEL 3")
	assert_true(stage2.info.text.contains("HP 08 / 12"), "HUD displays HP 08 / 12")
	assert_true(stage2.info.text.contains("DRONES DESTROYED: 0 / 5"), "HUD displays DRONES DESTROYED: 0 / 5")

	# Verify dead player cannot advance
	stage2.start_level(2, 12)
	stage2.player.take_damage(12)
	assert_true(stage2.finished, "Game finished on death")
	assert_false(stage2.game_won, "Game not won on death")
	stage2.advance_to_next_level()
	assert_eq(stage2.current_level, 2, "Dead player cannot advance to Level 3")

	stage2.queue_free()


# ------------------------------------------------------------------------------
# Suite B: Objective System — Elimination & Kill Counting
# ------------------------------------------------------------------------------
func _suite_b_elimination_objective_and_kill_counter() -> void:
	print("\n--- Running Suite B: Objective System — Elimination & Kill Counting ---")

	var stage2 = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2)
	await get_tree().process_frame

	stage2.start_level(3, 12)
	await get_tree().process_frame

	# 1. Untimed objective verification
	assert_eq(stage2.level_duration, 0.0, "Level 3 level_duration is 0.0s (untimed elimination)")
	assert_eq(stage2.time_remaining, 0.0, "Level 3 time_remaining is 0.0s")
	assert_eq(stage2.get_drones_destroyed(), 0, "Initial drones_destroyed is 0")
	assert_eq(stage2.get_target_kills(), 5, "Target kills is exactly 5")

	# Simulating frame processing does NOT trigger timer completion
	stage2._process(5.0)
	assert_false(stage2.finished, "Level 3 does NOT finish from time passage")
	assert_false(stage2.game_won, "Level 3 is not won by waiting out a timer")

	# Track signals
	var registered_kills: Array = []
	stage2.drone_kill_registered.connect(func(curr, target): registered_kills.append(Vector2i(curr, target)))

	var level_completed_calls: Array = []
	stage2.level_completed.connect(func(lvl): level_completed_calls.append(lvl))

	# 2. Register valid kills (Reason 0 = PLAYER_WEAPON)
	# Kill 1
	var dummy_drone = GUARD_DRONE_SCENE.instantiate()
	stage2._on_drone_defeated(0, dummy_drone)
	assert_eq(stage2.get_drones_destroyed(), 1, "Kill 1: drones_destroyed is 1")
	assert_eq(registered_kills.size(), 1, "drone_kill_registered emitted once")
	assert_eq(registered_kills[0], Vector2i(1, 5), "Signal payload reports (1, 5)")
	assert_true(stage2.info.text.contains("DRONES DESTROYED: 1 / 5"), "HUD updated to 1 / 5")
	assert_false(stage2.finished, "Level 3 not finished after 1 kill")

	# Kills 2, 3, 4
	stage2._on_drone_defeated(0, dummy_drone)
	stage2._on_drone_defeated(0, dummy_drone)
	stage2._on_drone_defeated(0, dummy_drone)
	assert_eq(stage2.get_drones_destroyed(), 4, "Kill 4: drones_destroyed is 4")
	assert_true(stage2.info.text.contains("DRONES DESTROYED: 4 / 5"), "HUD updated to 4 / 5")
	assert_false(stage2.finished, "Level 3 not finished after 4 kills")
	assert_false(stage2.game_won, "Level 3 not won after 4 kills")
	assert_eq(level_completed_calls.size(), 0, "level_completed not emitted before 5th kill")

	# Kill 5: Final kill triggers victory!
	stage2._on_drone_defeated(0, dummy_drone)
	assert_eq(stage2.get_drones_destroyed(), 5, "Kill 5: drones_destroyed is exactly 5")
	assert_true(stage2.finished, "Level 3 finished after 5th kill")
	assert_true(stage2.game_won, "Level 3 game_won true after 5th kill")
	assert_eq(level_completed_calls.size(), 1, "level_completed emitted exactly once")
	assert_eq(level_completed_calls[0], 3, "level_completed emitted with level 3")

	# Counter capping: subsequent kills do not exceed 5
	stage2._on_drone_defeated(0, dummy_drone)
	assert_eq(stage2.get_drones_destroyed(), 5, "Kill counter capped at 5")

	# Verify victory message banner
	assert_true(stage2.message.visible, "Victory banner visible")
	assert_true(stage2.message.text.contains("STAGE 2 / LEVEL 3 COMPLETE!"), "Message proclaims STAGE 2 / LEVEL 3 COMPLETE!")
	assert_true(stage2.message.text.contains("Guard Drone Interceptors Neutralized (5/5)"), "Message confirms 5/5 drones neutralized")
	assert_true(stage2.message.text.contains("[EQUIPMENT RECOVERED: EM Jammer]"), "Message announces EM Jammer recovery")
	assert_true(stage2.message.text.contains("[STAGE 2 LEVEL 3 COMPLETE — PROTOTYPE FINISHED]"), "Message proclaims prototype finished")
	assert_true(stage2.message.text.contains("Press [R] to replay Stage 2 from Checkpoint"), "Message prompts for checkpoint replay")

	dummy_drone.queue_free()
	stage2.queue_free()


# ------------------------------------------------------------------------------
# Suite C: Guard Drone Enemy Specification & Health
# ------------------------------------------------------------------------------
func _suite_c_guard_drone_enemy_specification() -> void:
	print("\n--- Running Suite C: Guard Drone Enemy Specification & Health ---")

	var drone = GUARD_DRONE_SCENE.instantiate()
	add_child(drone)
	await get_tree().process_frame

	# 1. Base properties & stats
	assert_eq(drone.max_health, 20, "Guard Drone max_health is 20")
	assert_eq(drone.health, 20, "Guard Drone starts with full 20 HP")
	assert_eq(drone.approach_speed, 120.0, "Guard Drone approach speed is 120.0 px/s")
	assert_eq(drone.charge_speed, 360.0, "Guard Drone charge speed is 360.0 px/s")
	assert_eq(drone.telegraph_duration, 0.45, "Guard Drone telegraph duration is 0.45s")
	assert_eq(drone.contact_damage, 1, "Guard Drone contact damage is 1 HP")
	assert_eq(drone.collision_layer, 18, "Guard Drone collision_layer is 18 (Layer 2 | Layer 5)")
	assert_eq(drone.collision_mask, 5, "Guard Drone collision_mask is 5 (Layer 1 | Layer 3)")
	assert_true(drone.is_in_group("enemies"), "Guard Drone is in 'enemies' group")
	assert_true(drone.is_in_group("guard_drones"), "Guard Drone is in 'guard_drones' group")

	# 2. Visuals and Official Artwork Nodes
	assert_true(drone.get_node_or_null("Visuals") != null, "Guard Drone has Visuals child node")
	assert_true(drone.get_node_or_null("Visuals/OfficialArt") != null, "Guard Drone has OfficialArt node")
	assert_true(drone.idle_sprite != null, "Guard Drone has IdleSprite")
	assert_true(drone.idle_sprite.texture != null, "Guard Drone IdleSprite has official texture loaded")
	assert_true(drone.attacking_sprite != null, "Guard Drone has AttackingSprite")
	assert_true(drone.attacking_sprite.texture != null, "Guard Drone AttackingSprite has official texture loaded")
	assert_true(drone.fallback != null, "Guard Drone has ProceduralFallback node")
	assert_true(drone.idle_sprite.visible, "Default state: IdleSprite is visible")
	assert_false(drone.attacking_sprite.visible, "Default state: AttackingSprite is hidden")
	assert_eq(drone.scale, Vector2.ONE, "Neutral root scale is Vector2.ONE")

	# 3. Damage processing
	var damage_signals: Array = []
	drone.damaged.connect(func(amt, rem): damage_signals.append([amt, rem]))

	drone.take_damage(1)
	assert_eq(damage_signals.size(), 1, "Guard Drone emitted damaged signal exactly once")
	assert_eq(damage_signals[0][0], 1, "Damage amount reported is 1")
	assert_eq(damage_signals[0][1], 19, "Remaining HP reported is 19")
	assert_eq(drone.health, 19, "Guard Drone current health is 19")

	# Signal tracking for death
	var destroyed_signals: Array = []
	var defeat_reasons: Array = []
	drone.destroyed.connect(func(): destroyed_signals.append(true))
	drone.drone_defeated.connect(func(reason, _d): defeat_reasons.append(reason))

	# Multi-hit down to lethal (19 more hits)
	for i in range(19):
		drone.take_damage(1)

	assert_eq(drone.health, 0, "Guard Drone health reaches 0")
	assert_true(drone.is_destroyed, "Guard Drone marked is_destroyed = true")
	assert_true(destroyed_signals.size() > 0, "Guard Drone emitted destroyed signal")
	assert_eq(defeat_reasons.size(), 1, "drone_defeated emitted exactly once")
	assert_eq(defeat_reasons[0], 0, "drone_defeated emitted with reason 0 (PLAYER_WEAPON)")
	assert_eq(drone.contact_damage, 0, "Destroyed Guard Drone contact damage zeroed out")
	assert_true(drone.is_queued_for_deletion(), "Destroyed Guard Drone is queued for deletion")

	# Duplicate damage calls ignored
	drone.take_damage(5)
	assert_eq(drone.health, 0, "Further damage ignored on destroyed drone")

	drone.queue_free()


# ------------------------------------------------------------------------------
# Suite D: Kamikaze Mechanics, Targeting & Zero Kill Credit for Non-Weapon Kills
# ------------------------------------------------------------------------------
func _suite_d_kamikaze_mechanics_and_attribution() -> void:
	print("\n--- Running Suite D: Kamikaze Mechanics & Attribution ---")

	var stage2 = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2)
	await get_tree().process_frame

	stage2.start_level(3, 12)
	await get_tree().process_frame

	# 1. State machine transitions & targeting
	var drone = GUARD_DRONE_SCENE.instantiate()
	stage2.enemies_container.add_child(drone)
	drone.position = Vector2(900.0, 360.0)
	drone.set_target_player(stage2.player)
	stage2.player.position = Vector2(300.0, 360.0)

	assert_false(drone.is_telegraphing(), "Drone starts in APPROACH state")
	assert_false(drone.is_charging(), "Drone is not charging initially")

	# Trigger telegraph
	drone.start_telegraph()
	assert_true(drone.is_telegraphing(), "Drone transitioned to TELEGRAPH")
	assert_false(drone.is_charging(), "Drone is not yet charging during telegraph")
	assert_true(drone.attacking_sprite.visible, "AttackingSprite visible during telegraph")
	assert_false(drone.idle_sprite.visible, "IdleSprite hidden during telegraph")

	# Locked aim direction aimed directly left toward player
	var aim_dir = drone.get_charge_direction()
	assert_eq(aim_dir, Vector2.LEFT, "Locked direction aimed directly left toward player")

	# Player dodges vertically to Y=150
	stage2.player.position = Vector2(300.0, 150.0)

	# Drone does NOT re-track player after telegraph lock!
	drone.start_charge()
	assert_true(drone.is_charging(), "Drone transitioned to CHARGING")
	assert_eq(drone.get_charge_direction(), Vector2.LEFT, "Charge direction remains locked to Vector2.LEFT after player moved")

	# 2. Dodge avoidance verification
	# Move drone past player along Y=360
	drone.global_position = Vector2(300.0, 360.0)
	await get_tree().process_frame
	assert_eq(stage2.player.health, 12, "Dodge successful: Player at Y=150 took 0 damage from drone charging along Y=360")

	# 3. Kamikaze Contact Impact: 1 damage to player, self-destructs, ZERO kill credit
	var kamikaze_drone = stage2._spawn_guard_drone()
	kamikaze_drone.global_position = stage2.player.global_position # Direct overlap

	var kamikaze_reasons: Array = []
	kamikaze_drone.drone_defeated.connect(func(reason, _d): kamikaze_reasons.append(reason))

	# Process contact
	kamikaze_drone.handle_player_contact(stage2.player)
	assert_eq(stage2.player.health, 11, "Player took 1 damage from kamikaze impact (12 -> 11)")
	assert_true(kamikaze_drone.is_destroyed, "Drone self-destructed upon kamikaze impact")
	assert_eq(kamikaze_reasons.size(), 1, "drone_defeated emitted on kamikaze impact")
	assert_eq(kamikaze_reasons[0], 1, "drone_defeated emitted with reason 1 (KAMIKAZE_IMPACT)")
	assert_eq(stage2.get_drones_destroyed(), 0, "ZERO kill credit awarded for kamikaze self-destruction (remains 0/5)")

	# 4. Offscreen Despawn: ZERO kill credit
	var offscreen_drone = stage2._spawn_guard_drone()
	offscreen_drone.position = Vector2(-150.0, 360.0)
	var offscreen_reasons: Array = []
	offscreen_drone.drone_defeated.connect(func(reason, _d): offscreen_reasons.append(reason))

	offscreen_drone._physics_process(0.016)
	assert_true(offscreen_drone.is_destroyed, "Offscreen drone destroyed")
	assert_eq(offscreen_reasons.size(), 1, "drone_defeated emitted on offscreen despawn")
	assert_eq(offscreen_reasons[0], 2, "drone_defeated emitted with reason 2 (OFFSCREEN_DESPAWN)")
	assert_eq(stage2.get_drones_destroyed(), 0, "ZERO kill credit awarded for offscreen despawn (remains 0/5)")

	stage2.queue_free()


# ------------------------------------------------------------------------------
# Suite E: Real Physics Collision & Combat Safety
# ------------------------------------------------------------------------------
func _suite_e_combat_physics_and_safety() -> void:
	print("\n--- Running Suite E: Real Physics Collision & Combat Safety ---")

	var stage2 = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2)
	await get_tree().process_frame

	stage2.start_level(3, 12)
	await get_tree().process_frame

	# 1. Real projectile hit on Guard Drone
	var drone = stage2._spawn_guard_drone()
	drone.global_position = Vector2(400.0, 360.0)

	var proj = PROJECTILE_SCENE.instantiate()
	proj.direction = Vector2.RIGHT
	proj.global_position = Vector2(395.0, 360.0)
	stage2.projectiles_container.add_child(proj)

	# Allow physics detection
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_eq(drone.health, 19, "Guard Drone took 1 damage from player projectile (20 -> 19)")
	assert_true(proj.is_queued_for_deletion() or not proj.monitoring, "Player projectile consumed upon striking drone")

	# 2. Same-frame multi-hit safety
	var proj1 = PROJECTILE_SCENE.instantiate()
	var proj2 = PROJECTILE_SCENE.instantiate()
	proj1.global_position = drone.global_position
	proj2.global_position = drone.global_position
	stage2.projectiles_container.add_child(proj1)
	stage2.projectiles_container.add_child(proj2)

	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_true(drone.health <= 18, "Multiple projectiles processed safely on drone")

	stage2.queue_free()


# ------------------------------------------------------------------------------
# Suite F: Equipment Acquisition — EM Jammer
# ------------------------------------------------------------------------------
func _suite_f_em_jammer_acquisition_and_deferred_state() -> void:
	print("\n--- Running Suite F: Equipment Acquisition — EM Jammer ---")

	var stage2 = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2)
	await get_tree().process_frame

	# Track EM Jammer acquisition event
	var em_events: Array = []
	stage2.em_jammer_acquired_event.connect(func(payload): em_events.append(payload))

	# 1. Unearned state at Level 3 start
	stage2.start_level(3, 12)
	await get_tree().process_frame

	assert_false(stage2.is_em_jammer_acquired(), "is_em_jammer_acquired() is false at Level 3 start")
	assert_false(stage2.stage_acquisitions.get("em_jammer_acquired", false), "stage_acquisitions['em_jammer_acquired'] is false")
	assert_eq(em_events.size(), 0, "em_jammer_acquired_event not emitted at start")

	# 2. Defeat 5 drones legitimately
	var dummy = GUARD_DRONE_SCENE.instantiate()
	for i in range(5):
		stage2._on_drone_defeated(0, dummy)

	# 3. Post-completion state
	assert_true(stage2.is_em_jammer_acquired(), "is_em_jammer_acquired() is true after Level 3 completion")
	assert_true(stage2.stage_acquisitions.get("em_jammer_acquired", false), "stage_acquisitions['em_jammer_acquired'] is true")
	assert_eq(em_events.size(), 1, "em_jammer_acquired_event emitted exactly once")
	assert_eq(em_events[0]["equipment"], "em_jammer", "Payload equipment is 'em_jammer'")
	assert_eq(em_events[0]["level"], 3, "Payload level is 3")
	assert_eq(em_events[0]["status"], "acquired", "Payload status is 'acquired'")

	# 4. Deferred activation: Player node has no direct jammer invocation
	assert_false(stage2.player.has_method("activate_em_jammer"), "Player has no direct activate_em_jammer method (Call Down)")
	assert_false(stage2.player.has_method("use_jammer"), "Player has no use_jammer method (deferred activation)")

	dummy.queue_free()
	stage2.queue_free()


# ------------------------------------------------------------------------------
# Suite G: Stage 2 Checkpoint & Revive from Level 3
# ------------------------------------------------------------------------------
func _suite_g_stage2_checkpoint_and_revive() -> void:
	print("\n--- Running Suite G: Stage 2 Checkpoint & Revive from Level 3 ---")

	var stage2 = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2)
	await get_tree().process_frame

	# Start at Level 3
	stage2.start_level(3, 10)
	await get_tree().process_frame

	# Register 2 kills
	var dummy = GUARD_DRONE_SCENE.instantiate()
	stage2._on_drone_defeated(0, dummy)
	stage2._on_drone_defeated(0, dummy)
	assert_eq(stage2.get_drones_destroyed(), 2, "2 kills registered before death")

	# Spawn active drone
	var active_drone = stage2._spawn_guard_drone()
	assert_true(is_instance_valid(active_drone), "Active drone present in Level 3 before death")

	# Player dies in Level 3
	stage2.player.take_damage(10)
	assert_eq(stage2.player.health, 0, "Player HP is 0")
	assert_true(stage2.finished, "Game is marked finished")
	assert_false(stage2.game_won, "Game is not won")
	assert_true(stage2.message.visible, "Death message visible")
	assert_true(stage2.message.text.contains("SHIP DESTROYED (STAGE 2 / LEVEL 3)"), "Death message displays STAGE 2 / LEVEL 3")
	assert_true(stage2.message.text.contains("Press [R] to Revive at Stage 2 Checkpoint"), "Prompts for Stage 2 Checkpoint")

	# Revive at Stage 2 checkpoint
	stage2.revive_at_stage_checkpoint()
	await get_tree().process_frame

	# Verify revive state
	assert_eq(stage2.stage_number, 2, "Revive stays in Stage 2 (does NOT reset to Stage 1)")
	assert_eq(stage2.current_level, 1, "Revive restarts strictly at Stage 2 Level 1")
	assert_eq(stage2.player.health, 12, "Player HP fully restored to 12")
	assert_eq(stage2.player.max_health, 12, "Player max_health is 12")
	assert_true(stage2.player.alive, "Player alive is true")
	assert_false(stage2.finished, "Game finished reset to false")
	assert_false(stage2.game_won, "Game won reset to false")
	assert_true(stage2.player.is_physics_processing(), "Player physics processing re-enabled")
	assert_true(stage2.is_primary_weapon_acquired(), "Primary weapon remains active after Stage 2 checkpoint revive")
	assert_false(stage2.is_em_jammer_acquired(), "Unearned EM Jammer cleared on revive")
	assert_eq(stage2.get_drones_destroyed(), 0, "Drones destroyed counter reset to 0")
	assert_eq(stage2.enemies_container.get_child_count(), 0, "Enemies container cleared on checkpoint revive")

	# Verify Stage 1 coordinator still revives at Stage 1 Level 1
	var main1 = MAIN_SCENE.instantiate()
	add_child(main1)
	await get_tree().process_frame
	main1.start_level(3, 5)
	main1.player.take_damage(5)
	main1.revive_at_stage_checkpoint()
	assert_eq(main1.current_level, 1, "Stage 1 checkpoint still revives at Stage 1 Level 1")
	assert_eq(main1.player.health, 12, "Stage 1 player HP restored to 12")
	main1.queue_free()

	dummy.queue_free()
	stage2.queue_free()


# ------------------------------------------------------------------------------
# Suite H: System-Wide Regression, Level Select Restrictions & Architecture
# ------------------------------------------------------------------------------
func _suite_h_regression_level_select_and_architecture() -> void:
	print("\n--- Running Suite H: System-Wide Regression, Level Select Restrictions & Architecture ---")

	# 1. Level Select Restrictions
	var level_select = LEVEL_SELECT_SCENE.instantiate()
	add_child(level_select)
	await get_tree().process_frame

	assert_eq(level_select.level_buttons.size(), 15, "All 15 level buttons registered in Level Select")
	assert_true(level_select.is_level_playable(1, 1), "Stage 1 Level 1 is PLAYABLE")
	assert_false(level_select.is_level_playable(1, 2), "Stage 1 Level 2 is LOCKED")
	assert_false(level_select.is_level_playable(1, 3), "Stage 1 Level 3 is LOCKED")
	assert_false(level_select.is_level_playable(1, 4), "Stage 1 Level 4 is LOCKED")
	assert_false(level_select.is_level_playable(1, 5), "Stage 1 Level 5 is LOCKED")
	assert_false(level_select.is_level_playable(2, 1), "Stage 2 Level 1 is LOCKED in Level Select (must be reached via progression)")
	assert_false(level_select.is_level_playable(2, 2), "Stage 2 Level 2 is LOCKED in Level Select (must be reached via progression)")
	assert_false(level_select.is_level_playable(2, 3), "Stage 2 Level 3 is LOCKED in Level Select (must be reached via progression)")

	level_select.queue_free()

	# 2. Main Menu Verification
	var menu = MAIN_MENU_SCENE.instantiate()
	add_child(menu)
	await get_tree().process_frame

	assert_true(menu.start_button != null, "Main menu Start button exists")
	assert_true(menu.select_button != null, "Main menu Select button exists")
	assert_true(menu.exit_button != null, "Main menu Exit button exists")

	menu.queue_free()

	# 3. Architectural constraint: Player has no direct shoot() or fire() methods
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	assert_false(player.has_method("shoot"), "Player has no shoot() method (Call Down constraint preserved)")
	assert_false(player.has_method("fire"), "Player has no fire() method (Call Down constraint preserved)")
	assert_true(player.get_node_or_null("Visuals") != null, "Player scene has Visuals child node")

	player.queue_free()

	# 4. Previous Entity Scenes Validation
	var ast = ASTEROID_SCENE.instantiate()
	assert_true(ast.get_node_or_null("Visuals") != null, "Asteroid scene has Visuals child node")
	ast.queue_free()

	var sat = SATELLITE_SCENE.instantiate()
	assert_true(sat.get_node_or_null("Visuals") != null, "Communication satellite has Visuals child node")
	sat.queue_free()

	var msat = MINING_SATELLITE_SCENE.instantiate()
	assert_true(msat.get_node_or_null("Visuals") != null, "Mining satellite has Visuals child node")
	msat.queue_free()

	var dship = DAMAGED_MINING_SHIP_SCENE.instantiate()
	assert_true(dship.get_node_or_null("Visuals") != null, "Damaged mining ship has Visuals child node")
	dship.queue_free()

	var bot = GUARD_BOT_SCENE.instantiate()
	assert_true(bot.get_node_or_null("Visuals") != null, "Guard Bot has Visuals child node")
	bot.queue_free()

	var gsat = GUARD_SATELLITE_SCENE.instantiate()
	assert_true(gsat.get_node_or_null("Visuals") != null, "Guard Satellite has Visuals child node")
	gsat.queue_free()

	var drone = GUARD_DRONE_SCENE.instantiate()
	assert_true(drone.get_node_or_null("Visuals") != null, "Guard Drone has Visuals child node")
	drone.queue_free()


func _print_summary() -> void:
	print("\n==================================================")
	print("MILESTONE 8 TEST EXECUTION SUMMARY")
	print("==================================================")
	print("Total assertions: %d" % total_count)
	print("Passed:           %d" % pass_count)
	print("Failed:           %d" % fail_count)
	if fail_count == 0:
		print("VERDICT: ALL TESTS PASSED (100%)")
	else:
		print("VERDICT: TEST SUITE FAILED")
	print("==================================================\n")
