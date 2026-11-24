extends Node
## Test runner logic for Milestone 7 (Stage 2 Level 2: Guard Satellite & Accurate Laser Combat).
## Validates Suites A through G covering Level 1 -> Level 2 progression, HP persistence,
## Guard Satellite enemy, accurate laser attacks, real collision & dodge mechanics, 20s survival, and regression.

var total_count: int = 0
var pass_count: int = 0
var fail_count: int = 0

const MAIN_SCENE = preload("res://scenes/main.tscn")
const STAGE2_MAIN_SCENE = preload("res://scenes/stage2/stage2_main.tscn")
const GUARD_BOT_SCENE = preload("res://scenes/enemies/guard_bot.tscn")
const GUARD_SATELLITE_SCENE = preload("res://scenes/enemies/guard_satellite.tscn")
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
	print("==================================================")
	print("LAST SIGNAL — Milestone 7 Automated Test Suite")
	print("==================================================")

	await _suite_a_level_progression_and_persistence()
	await _suite_b_guard_satellite_enemy()
	await _suite_c_accurate_laser_mechanics()
	await _suite_d_real_collision_and_combat_safety()
	await _suite_e_survival_timer_and_level2_completion()
	await _suite_f_stage2_checkpoint_from_level2()
	await _suite_g_regression_and_safety()


# ------------------------------------------------------------------------------
# Suite A: Level 1 -> Level 2 Progression & State Persistence
# ------------------------------------------------------------------------------
func _suite_a_level_progression_and_persistence() -> void:
	print("\n--- Running Suite A: Level 1 -> Level 2 Progression & State Persistence ---")

	var stage2 = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2)
	await get_tree().process_frame

	# 1. Unfinished Level 1 cannot advance
	stage2.finished = false
	stage2.advance_to_next_level()
	assert_eq(stage2.current_level, 1, "Unfinished Level 1 cannot advance to Level 2")

	# 2. Complete Level 1 with reduced HP (e.g., 7 HP) to verify persistent HP
	stage2.player.take_damage(5)
	assert_eq(stage2.player.health, 7, "Player took damage down to 7 HP in Level 1")

	# Spawn dummy enemies/projectiles to test cleanup on progression
	stage2._spawn_guard_bot()
	stage2.weapon_controller.fire_volley()
	assert_true(stage2.enemies_container.get_child_count() > 0, "Guard Bot present before level advance")

	stage2.time_remaining = 0.0
	stage2._complete_level()
	await get_tree().process_frame

	assert_true(stage2.finished, "Level 1 marked finished")
	assert_true(stage2.game_won, "Level 1 marked game_won")
	assert_true(stage2.message.visible, "Level 1 complete message visible")
	assert_true(stage2.message.text.contains("STAGE 2 / LEVEL 1 COMPLETE!"), "Banner proclaims STAGE 2 / LEVEL 1 COMPLETE!")
	assert_true(stage2.message.text.contains("Press [Space/Enter] for Level 2"), "Banner prompts for Level 2 progression")

	# 3. Advance to Level 2
	stage2.advance_to_next_level()
	await get_tree().process_frame

	assert_eq(stage2.current_level, 2, "current_level advanced to 2")
	assert_false(stage2.finished, "Level 2 marked unfinished on start")
	assert_false(stage2.game_won, "Level 2 game_won reset to false")

	# 4. HP Persistence: Exactly 7 HP maintained! (No full restoration within stage)
	assert_eq(stage2.player.health, 7, "Remaining 7 HP strictly persisted into Level 2 (no within-stage restoration)")
	assert_eq(stage2.player.max_health, 12, "Player max_health remains 12")
	assert_true(stage2.player.alive, "Player is alive")
	assert_true(stage2.player.is_physics_processing(), "Player physics processing enabled")

	# 5. Equipment Persistence
	assert_true(stage2.is_primary_weapon_acquired(), "Primary weapon acquisition preserved in Level 2")
	assert_true(stage2.is_shield_acquired(), "Shield acquisition preserved in Level 2")
	assert_true(stage2.weapon_controller.firing_enabled, "Primary weapon remains active in Level 2")

	# 6. Entity and state cleanup
	assert_eq(stage2.enemies_container.get_child_count(), 0, "Old enemies cleaned up on advancing to Level 2")
	assert_eq(stage2.enemy_projectiles_container.get_child_count(), 0, "Old enemy projectiles cleaned up")
	assert_eq(stage2.projectiles_container.get_child_count(), 0, "Old player projectiles cleaned up")

	# 7. Level 2 Timer & HUD
	assert_eq(stage2.level_duration, 20.0, "Level 2 duration is 20.0s")
	assert_true(stage2.time_remaining <= 20.0 and stage2.time_remaining >= 19.8, "Level 2 time_remaining initialized to ~20.0s")
	assert_true(stage2.info.text.contains("STAGE 2 / LEVEL 2"), "HUD displays STAGE 2 / LEVEL 2")
	assert_true(stage2.info.text.contains("HP 07 / 12"), "HUD displays HP 07 / 12")

	# 8. Dead player in Level 1 cannot advance
	var stage2_dead = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2_dead)
	await get_tree().process_frame
	stage2_dead.player.take_damage(12)
	assert_true(stage2_dead.finished, "Game finished on death")
	assert_false(stage2_dead.game_won, "Game not won on death")
	stage2_dead.advance_to_next_level()
	assert_eq(stage2_dead.current_level, 1, "Dead player cannot advance to Level 2")

	stage2.queue_free()
	stage2_dead.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite B: Guard Satellite Enemy Specification
# ------------------------------------------------------------------------------
func _suite_b_guard_satellite_enemy() -> void:
	print("\n--- Running Suite B: Guard Satellite Enemy Specification ---")

	var sat = GUARD_SATELLITE_SCENE.instantiate()
	add_child(sat)
	await get_tree().process_frame

	# 1. Health and movement parameters
	assert_eq(sat.max_health, 20, "Guard Satellite max_health is 20")
	assert_eq(sat.health, 20, "Guard Satellite starts with full 20 HP")
	assert_eq(sat.speed, 90.0, "Guard Satellite drift speed is 90.0 px/s")
	assert_eq(sat.contact_damage, 1, "Guard Satellite contact damage is 1 HP")

	# 2. Collision layers and groups
	assert_eq(sat.collision_layer, 18, "Guard Satellite collision_layer is 18 (Layer 2 | Layer 5)")
	assert_eq(sat.collision_mask, 5, "Guard Satellite collision_mask is 5 (Layer 1 | Layer 3)")
	assert_true(sat.is_in_group("enemies"), "Guard Satellite is in 'enemies' group")
	assert_true(sat.is_in_group("guard_satellites"), "Guard Satellite is in 'guard_satellites' group")

	# 3. Official art and procedural fallback
	var visuals = sat.get_node_or_null("Visuals")
	assert_true(visuals != null, "Guard Satellite has Visuals child node")
	var official_art = sat.get_node_or_null("Visuals/OfficialArt")
	assert_true(official_art != null, "Guard Satellite has OfficialArt node")
	var idle_spr = sat.get_node_or_null("Visuals/OfficialArt/IdleSprite")
	assert_true(idle_spr != null, "Guard Satellite has IdleSprite")
	assert_true(idle_spr.texture != null, "Guard Satellite IdleSprite has official texture loaded")
	var attack_spr = sat.get_node_or_null("Visuals/OfficialArt/AttackingSprite")
	assert_true(attack_spr != null, "Guard Satellite has AttackingSprite")
	assert_true(attack_spr.texture != null, "Guard Satellite AttackingSprite has official texture loaded")
	var fallback = sat.get_node_or_null("Visuals/ProceduralFallback")
	assert_true(fallback != null, "Guard Satellite has ProceduralFallback node")

	# 4. Default sprite pose visibility
	assert_true(idle_spr.visible, "Default state: IdleSprite is visible")
	assert_false(attack_spr.visible, "Default state: AttackingSprite is hidden")

	# 5. Projectile damage reception & signals
	var damaged_events: Array = []
	sat.damaged.connect(func(amt: int, rem: int):
		damaged_events.append({"amount": amt, "remaining": rem})
	)

	sat.take_damage(1)
	assert_eq(damaged_events.size(), 1, "Guard Satellite emitted damaged signal exactly once")
	if damaged_events.size() > 0:
		assert_eq(damaged_events[0]["amount"], 1, "Damage amount reported is 1")
		assert_eq(damaged_events[0]["remaining"], 19, "Remaining HP reported is 19")
	assert_eq(sat.health, 19, "Guard Satellite current health is 19")

	# 6. Destruction at 0 HP
	var destroyed_events: Array = []
	sat.destroyed.connect(func(): destroyed_events.append(true))

	sat.take_damage(19)
	assert_eq(sat.health, 0, "Guard Satellite health reaches 0")
	assert_true(sat.is_destroyed, "Guard Satellite marked is_destroyed = true")
	assert_eq(destroyed_events.size(), 1, "Guard Satellite emitted destroyed signal")
	assert_eq(sat.contact_damage, 0, "Destroyed Guard Satellite contact damage zeroed out")
	assert_true(sat.is_queued_for_deletion(), "Destroyed Guard Satellite is queued for deletion")

	sat.queue_free()
	await get_tree().process_frame

	# 7. Mutual contact damage & cooldown
	var fresh_sat = GUARD_SATELLITE_SCENE.instantiate()
	var fresh_player = PLAYER_SCENE.instantiate()
	add_child(fresh_sat)
	add_child(fresh_player)
	await get_tree().process_frame

	fresh_player.prepare_for_level(12)
	assert_eq(fresh_player.health, 12, "Player starts at 12 HP")
	assert_eq(fresh_sat.health, 20, "Guard Satellite starts at 20 HP")

	var player_id = fresh_player.get_instance_id()
	fresh_player.take_damage(fresh_sat.contact_damage)
	fresh_sat.take_damage(1)
	fresh_sat.contact_cooldown[player_id] = 0.5

	assert_eq(fresh_player.health, 11, "Player takes 1 contact damage from Guard Satellite")
	assert_eq(fresh_sat.health, 19, "Guard Satellite takes 1 mutual contact damage from Player")
	assert_eq(fresh_sat.contact_cooldown[player_id], 0.5, "Contact pair cooldown initialized to 0.5s")

	# 8. Offscreen cleanup past left margin (X < -120)
	fresh_sat.position = Vector2(-125.0, 300.0)
	fresh_sat._physics_process(0.016)
	assert_true(fresh_sat.is_queued_for_deletion(), "Guard Satellite past X=-120 queued for deletion")

	fresh_player.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite C: Accurate Laser System Mechanics (Telegraph, Aiming, Firing)
# ------------------------------------------------------------------------------
func _suite_c_accurate_laser_mechanics() -> void:
	print("\n--- Running Suite C: Accurate Laser System Mechanics ---")

	var sat = GUARD_SATELLITE_SCENE.instantiate()
	var player = PLAYER_SCENE.instantiate()
	add_child(sat)
	add_child(player)
	await get_tree().process_frame

	sat.position = Vector2(800.0, 360.0)
	player.position = Vector2(400.0, 360.0)
	sat.set_target_player(player)

	var laser = sat.get_laser_node()
	assert_true(laser != null, "Guard Satellite has Laser child node")
	assert_eq(laser.collision_layer, 32, "Laser collision_layer is 32 (Layer 6: Enemy Projectiles)")
	assert_eq(laser.collision_mask, 1, "Laser collision_mask is 1 (Layer 1: Player)")

	# 1. Telegraph Phase
	var telegraph_events: Array = []
	sat.attack_telegraph_started.connect(func(dir): telegraph_events.append(dir))

	sat.start_telegraph()
	assert_true(sat.is_telegraphing(), "Satellite reports is_telegraphing() == true")
	assert_false(sat.is_firing_laser(), "Satellite reports is_firing_laser() == false during telegraph")
	assert_false(laser.monitoring, "Laser monitoring is disabled during telegraph (no damage)")
	assert_eq(telegraph_events.size(), 1, "attack_telegraph_started signal emitted")
	assert_eq(sat.get_locked_direction(), Vector2.LEFT, "Locked direction aimed directly left toward player (400, 360)")

	# 2. Moving player after lock does NOT alter locked aim direction (Accurate locked orientation!)
	player.position = Vector2(400.0, 500.0) # Player moves down
	sat._physics_process(0.016)
	assert_eq(sat.get_locked_direction(), Vector2.LEFT, "Locked aim direction maintained after player moves")

	# 3. Firing Phase
	var fired_events: Array = []
	sat.laser_fired.connect(func(dir): fired_events.append(dir))

	player.prepare_for_level(12)
	player.position = Vector2(400.0, 360.0) # Move player back into beam path

	sat.start_firing()
	assert_true(sat.is_firing_laser(), "Satellite reports is_firing_laser() == true")
	assert_false(sat.is_telegraphing(), "Satellite reports is_telegraphing() == false during firing")
	assert_true(laser.monitoring, "Laser monitoring is enabled during firing")
	assert_eq(fired_events.size(), 1, "laser_fired signal emitted")

	# Verify attacking sprite visibility during laser discharge
	var atk_spr: Sprite2D = sat.get_node_or_null("Visuals/OfficialArt/AttackingSprite")
	assert_true(atk_spr.visible, "AttackingSprite is visible during laser firing")

	# 4. Damage application to player
	sat._apply_laser_damage_to(player)
	assert_eq(player.health, 11, "Player took exactly 1 HP damage from laser attack")

	# 5. Prevention of multi-hit damage on subsequent frame
	sat._apply_laser_damage_to(player)
	assert_eq(player.health, 11, "Repeated frame damage prevented: Player HP remains 11")

	# 6. Post-firing cooldown phase
	sat.end_firing()
	assert_false(sat.is_firing_laser(), "Laser firing ended, returns to cooldown")
	assert_false(laser.monitoring, "Laser monitoring disabled after firing ends")
	assert_false(atk_spr.visible, "AttackingSprite hidden after firing ends")

	sat.queue_free()
	player.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite D: Real Physics Collision & Combat Safety
# ------------------------------------------------------------------------------
func _suite_d_real_collision_and_combat_safety() -> void:
	print("\n--- Running Suite D: Real Physics Collision & Combat Safety ---")

	var stage2 = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2)
	await get_tree().process_frame

	stage2.start_level(2, 12)
	await get_tree().process_frame

	# 1. Real player projectile overlap with Guard Satellite
	var sat = stage2._spawn_guard_satellite()
	sat.position = Vector2(500.0, 360.0)
	await get_tree().process_frame

	assert_eq(sat.health, 20, "Guard Satellite starts at 20 HP")
	var proj = stage2.weapon_controller._spawn_single_projectile(Vector2(500.0, 360.0), Vector2.RIGHT, 0.0)
	await get_tree().physics_frame

	# Simulate overlap entry directly on physics area
	proj._on_area_entered(sat)
	assert_eq(sat.health, 19, "Guard Satellite took 1 damage from player projectile (20 -> 19)")
	assert_true(proj.is_queued_for_deletion(), "Player projectile queued for deletion upon striking satellite")

	# 2. Dodge avoidance verification
	var dodging_player = stage2.player
	dodging_player.prepare_for_level(12)
	dodging_player.position = Vector2(300.0, 360.0)

	sat.position = Vector2(600.0, 360.0)
	sat.start_telegraph() # Aims directly left towards (300, 360)
	assert_eq(sat.get_locked_direction(), Vector2.LEFT, "Laser aimed along Y=360")

	# Player dodges to Y=200 before laser fires
	dodging_player.position = Vector2(300.0, 200.0)
	sat.start_firing()
	sat._check_laser_hit()
	assert_eq(dodging_player.health, 12, "Dodge successful: Player at Y=200 took 0 damage from laser aimed at Y=360")

	# 3. Friendly fire & self-damage immunity
	var bot = stage2._spawn_guard_bot()
	bot.position = Vector2(500.0, 360.0) # In the path of the laser

	sat._apply_laser_damage_to(sat) # Self-damage attempt
	assert_eq(sat.health, 19, "Self-damage prevented: Firing satellite takes 0 damage from its own laser")

	sat._apply_laser_damage_to(bot) # Friendly enemy attempt
	assert_eq(bot.health, 30, "Friendly fire prevented: Friendly Guard Bot takes 0 damage from satellite laser")

	# 4. Immediate stop & cleanup on destruction
	var laser = sat.get_laser_node()
	sat.take_damage(19)
	assert_true(sat.is_destroyed, "Guard Satellite is destroyed")
	assert_false(laser.monitoring, "Laser monitoring disabled immediately upon satellite destruction")
	assert_false(sat.is_firing_laser(), "Destroyed satellite cannot fire laser")

	stage2.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite E: Survival Timer, Objective & Level 2 Completion
# ------------------------------------------------------------------------------
func _suite_e_survival_timer_and_level2_completion() -> void:
	print("\n--- Running Suite E: Survival Timer, Objective & Level 2 Completion ---")

	var stage2 = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2)
	await get_tree().process_frame

	stage2.start_level(2, 10)
	await get_tree().process_frame

	# 1. 20-second survival duration
	assert_eq(stage2.level_duration, 20.0, "Stage 2 Level 2 duration is exactly 20.0s")
	assert_true(stage2.time_remaining <= 20.0 and stage2.time_remaining >= 19.8, "Initial time_remaining is ~20.0s")
	assert_false(stage2.finished, "Stage 2 Level 2 starts unfinished")
	assert_false(stage2.game_won, "Stage 2 Level 2 starts game_won = false")

	# 2. Timer countdown
	var t_before: float = stage2.time_remaining
	stage2._process(1.0)
	assert_true(absf(stage2.time_remaining - (t_before - 1.0)) < 0.05, "Time remaining decrements by ~1.0s on process")

	# 3. Survival completion at 0.0s
	var completed_events: Array = []
	stage2.level_completed.connect(func(lvl: int): completed_events.append(lvl))

	stage2.time_remaining = 0.0
	stage2._process(0.01)

	assert_true(stage2.finished, "Level 2 marked finished = true on survival")
	assert_true(stage2.game_won, "Level 2 marked game_won = true on survival")
	assert_eq(completed_events.size(), 1, "level_completed signal emitted exactly once")
	if completed_events.size() > 0:
		assert_eq(completed_events[0], 2, "level_completed signal emitted with level 2")

	# 4. Call Down: player physics disabled and weapon firing disabled
	assert_false(stage2.player.is_physics_processing(), "Player physics disabled on Level 2 complete (Call Down)")
	assert_false(stage2.weapon_controller.firing_enabled, "Weapon firing disabled on Level 2 complete")

	# 5. Completion banner
	assert_true(stage2.message.visible, "Completion message visible")
	assert_true(stage2.message.text.contains("STAGE 2 / LEVEL 2 COMPLETE!"), "Message proclaims STAGE 2 / LEVEL 2 COMPLETE!")
	assert_true(stage2.message.text.contains("Deep Sector Survived"), "Message confirms survival objective")
	assert_true(stage2.message.text.contains("Guard Satellite Defense Grid Cleared"), "Message confirms satellite defense grid cleared")

	# 6. Milestone scope boundary: Level 3 cannot start
	assert_eq(stage2.current_level, 2, "current_level remains 2 (no premature Level 3 started)")

	# 7. Player death does NOT trigger level completion
	var stage2_fail = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2_fail)
	await get_tree().process_frame
	stage2_fail.start_level(2, 10)
	await get_tree().process_frame

	var fail_completed_events: Array = []
	stage2_fail.level_completed.connect(func(lvl): fail_completed_events.append(lvl))

	stage2_fail.player.take_damage(10)
	assert_true(stage2_fail.finished, "Game finished on player death")
	assert_false(stage2_fail.game_won, "game_won is false on player death")
	assert_eq(fail_completed_events.size(), 0, "level_completed signal NOT emitted on death")
	assert_true(stage2_fail.message.text.contains("SHIP DESTROYED (STAGE 2 / LEVEL 2)"), "Death message displays Level 2")

	stage2.queue_free()
	stage2_fail.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite F: Stage 2 Checkpoint & Revive from Level 2
# ------------------------------------------------------------------------------
func _suite_f_stage2_checkpoint_from_level2() -> void:
	print("\n--- Running Suite F: Stage 2 Checkpoint & Revive from Level 2 ---")

	var stage2 = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2)
	await get_tree().process_frame

	stage2.start_level(2, 8)
	await get_tree().process_frame

	# 1. Kill player in Stage 2 Level 2
	stage2.player.take_damage(8)
	assert_eq(stage2.player.health, 0, "Player HP is 0")
	assert_true(stage2.finished, "Game is marked finished")
	assert_false(stage2.game_won, "Game is not won")

	# Spawn entities before revive
	stage2._spawn_guard_satellite()
	stage2.weapon_controller.fire_volley()
	assert_true(stage2.enemies_container.get_child_count() > 0, "Enemies present before checkpoint reset")

	# 2. Revive at Stage 2 Checkpoint
	stage2.revive_at_stage_checkpoint()

	# 3. Checkpoint Validations: Revives strictly at Stage 2 Level 1!
	assert_eq(stage2.stage_number, 2, "Revive stays in Stage 2 (does NOT send player back to Stage 1)")
	assert_eq(stage2.current_level, 1, "Revive restarts strictly at Stage 2 Level 1")
	assert_eq(stage2.player.health, 12, "Player HP fully restored to 12")
	assert_eq(stage2.player.max_health, 12, "Player max_health is 12")
	assert_true(stage2.player.alive, "Player alive is true")
	assert_false(stage2.finished, "Game finished reset to false")
	assert_false(stage2.game_won, "Game won reset to false")
	assert_eq(stage2.time_remaining, 15.0, "Survival timer reset to Level 1 duration (15.0s)")
	assert_true(stage2.player.is_physics_processing(), "Player physics processing re-enabled")
	assert_true(stage2.weapon_controller.firing_enabled, "Primary weapon remains active after Stage 2 checkpoint revive")

	# Wait 1 frame for queue_free() scheduled deletions to execute
	await get_tree().process_frame
	assert_eq(stage2.enemies_container.get_child_count(), 0, "Enemies container cleared on checkpoint revive")
	assert_eq(stage2.enemy_projectiles_container.get_child_count(), 0, "Enemy projectiles container cleared")
	assert_eq(stage2.projectiles_container.get_child_count(), 0, "Player projectiles container cleared")

	# 4. Stage 1 Checkpoint integrity check
	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	main.start_level(3, 8)
	main.player.take_damage(8)
	main.revive_at_stage_checkpoint()
	assert_eq(main.current_level, 1, "Stage 1 checkpoint still revives at Stage 1 Level 1")
	assert_eq(main.player.health, 12, "Stage 1 player HP restored to 12")
	assert_false(main.is_primary_weapon_acquired(), "Stage 1 checkpoint resets unearned weapon")

	stage2.queue_free()
	main.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite G: System-Wide Regression, Level Select Restrictions & Safety
# ------------------------------------------------------------------------------
func _suite_g_regression_and_safety() -> void:
	print("\n--- Running Suite G: System-Wide Regression, Level Select Restrictions & Safety ---")

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

	var s1l1_btn: TextureButton = level_select.level_buttons[Vector2i(1, 1)]
	var s1l2_btn: TextureButton = level_select.level_buttons[Vector2i(1, 2)]
	var s2l1_btn: TextureButton = level_select.level_buttons[Vector2i(2, 1)]
	var s2l2_btn: TextureButton = level_select.level_buttons[Vector2i(2, 2)]
	assert_false(s1l1_btn.disabled, "S1L1 button is enabled")
	assert_true(s1l2_btn.disabled, "S1L2 button is disabled")
	assert_true(s2l1_btn.disabled, "S2L1 button is disabled")
	assert_true(s2l2_btn.disabled, "S2L2 button is disabled")

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

	assert_false(player.has_method("shoot"), "Player has no shoot() method (M2 Call Down constraint preserved)")
	assert_false(player.has_method("fire"), "Player has no fire() method (M2 Call Down constraint preserved)")
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

	var mship = DAMAGED_MINING_SHIP_SCENE.instantiate()
	assert_true(mship.get_node_or_null("Visuals") != null, "Damaged mining ship has Visuals child node")
	mship.queue_free()

	var bot = GUARD_BOT_SCENE.instantiate()
	assert_true(bot.get_node_or_null("Visuals") != null, "Guard Bot has Visuals child node")
	bot.queue_free()

	var ep = ENEMY_PROJECTILE_SCENE.instantiate()
	assert_true(ep.get_node_or_null("Visuals") != null, "Enemy projectile has Visuals child node")
	ep.queue_free()

	await get_tree().process_frame


func _print_summary() -> void:
	print("\n==================================================")
	print("MILESTONE 7 TEST EXECUTION SUMMARY")
	print("==================================================")
	print("Total assertions: %d" % total_count)
	print("Passed:           %d" % pass_count)
	print("Failed:           %d" % fail_count)
	if fail_count == 0:
		print("VERDICT: ALL TESTS PASSED (100%)")
	else:
		printerr("VERDICT: %d ASSERTION(S) FAILED" % fail_count)
	print("==================================================")
