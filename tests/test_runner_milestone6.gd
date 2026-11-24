extends Node
## Test runner logic for Milestone 6 (Stage 2 Level 1: Side-Scrolling & First Hostile Contact).
## Validates Suites A through G covering Stage 1 -> Stage 2 transition, side-scrolling mechanics,
## Guard Bot enemy, enemy projectiles, 15s survival objective, Stage 2 checkpoint revive, and regression.

var total_count: int = 0
var pass_count: int = 0
var fail_count: int = 0

const MAIN_SCENE = preload("res://scenes/main.tscn")
const STAGE2_MAIN_SCENE = preload("res://scenes/stage2/stage2_main.tscn")
const GUARD_BOT_SCENE = preload("res://scenes/enemies/guard_bot.tscn")
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
	print("LAST SIGNAL — Milestone 6 Automated Test Suite")
	print("==================================================")

	await _suite_a_stage_transition()
	await _suite_b_side_scrolling_mechanics()
	await _suite_c_guard_bot_enemy()
	await _suite_d_enemy_projectiles()
	await _suite_e_survival_timer_and_completion()
	await _suite_f_stage2_checkpoint_and_revive()
	await _suite_g_regression_and_safety()


# ------------------------------------------------------------------------------
# Suite A: Stage Transition from Stage 1 to Stage 2 Level 1
# ------------------------------------------------------------------------------
func _suite_a_stage_transition() -> void:
	print("\n--- Running Suite A: Stage Transition from Stage 1 to Stage 2 Level 1 ---")

	var main = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	# 1. Unfinished Stage 1 cannot advance to Stage 2
	main.finished = false
	var blocked_trans = main.advance_to_stage_2()
	assert_true(blocked_trans == null, "Unfinished Stage 1 cannot advance to Stage 2")

	# 2. Complete Stage 1 Level 5
	main.start_level(5, 6) # Start with 6 HP to test full HP restoration
	main.stage_acquisitions["primary_weapon_acquired"] = true
	main.stage_acquisitions["shield_acquired"] = true
	main.time_remaining = 0.0
	main._complete_level()
	await get_tree().process_frame
	assert_true(main.is_stage1_completed(), "Stage 1 reports completed")

	# 3. Transition to Stage 2
	var stage2 = main.advance_to_stage_2()
	assert_true(stage2 != null, "advance_to_stage_2() returns instantiated Stage 2 coordinator")
	add_child(stage2)

	# Check spawn position immediately before mouse steering moves player
	assert_eq(stage2.player.position, Vector2(240.0, 360.0), "Player positioned at side-scrolling spawn coordinates (240, 360)")

	await get_tree().process_frame

	assert_eq(stage2.stage_number, 2, "Stage 2 stage_number is 2")
	assert_eq(stage2.current_level, 1, "Stage 2 starts at Level 1")

	# 4. HP restoration upon entering new Stage
	assert_true(is_instance_valid(stage2.player), "Stage 2 has valid player node")
	assert_eq(stage2.player.health, 12, "Player health fully restored to 12 upon Stage 2 entry")
	assert_eq(stage2.player.max_health, 12, "Player max_health is 12")

	# 6. Equipment retention
	assert_true(stage2.is_primary_weapon_acquired(), "Primary weapon acquisition retained in Stage 2")
	assert_true(stage2.is_shield_acquired(), "Shield hardware acquisition retained in Stage 2")
	assert_true(is_instance_valid(stage2.weapon_controller), "Stage 2 has WeaponController")
	assert_true(stage2.weapon_controller.firing_enabled, "Weapon firing enabled on Stage 2 startup")

	# 7. HUD text reflects Stage 2 Level 1 and 15s timer
	assert_true(is_instance_valid(stage2.info), "Stage 2 Info HUD label is valid")
	assert_true(stage2.info.text.contains("STAGE 2 / LEVEL 1"), "HUD displays STAGE 2 / LEVEL 1")
	assert_true(stage2.info.text.contains("HP 12 / 12"), "HUD displays HP 12 / 12")
	assert_true(stage2.info.text.contains("TIME 15 s"), "HUD displays TIME 15 s")

	# 8. Clean container separation: no Stage 1 asteroids, satellites or mining ships inside stage2
	var stage2_asteroids := 0
	var stage2_satellites := 0
	var stage2_wrecked := 0
	for node in stage2.get_children():
		if node.is_in_group("asteroids"):
			stage2_asteroids += 1
		if node.is_in_group("satellites"):
			stage2_satellites += 1
		if node.is_in_group("wrecked_ships"):
			stage2_wrecked += 1
	assert_eq(stage2_asteroids, 0, "No Stage 1 asteroids in Stage 2")
	assert_eq(stage2_satellites, 0, "No Stage 1 satellites in Stage 2")
	assert_eq(stage2_wrecked, 0, "No Stage 1 wrecked mining ships in Stage 2")

	# 9. Dead player in Stage 1 cannot transition
	main.game_won = false
	var dead_trans = main.advance_to_stage_2()
	assert_true(dead_trans == null, "Dead player in Stage 1 cannot advance to Stage 2")

	stage2.queue_free()
	main.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite B: Side-Scrolling Mechanics & Arena Rules
# ------------------------------------------------------------------------------
func _suite_b_side_scrolling_mechanics() -> void:
	print("\n--- Running Suite B: Side-Scrolling Mechanics & Arena Rules ---")

	var stage2 = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2)
	await get_tree().process_frame

	# 1. Side-scrolling query method
	assert_true(stage2.is_side_scrolling(), "stage2.is_side_scrolling() returns true")

	# 2. Horizontal scroll speed
	assert_eq(stage2.scroll_speed, 140.0, "Side-scrolling horizontal speed is 140.0 px/s")

	# 3. Starfield offset updates horizontally
	var initial_offset: float = stage2.star_offset
	stage2._process(0.1)
	assert_true(stage2.star_offset > initial_offset, "Starfield offset advances horizontally on process")
	assert_true(absf(stage2.star_offset - fmod(initial_offset + 140.0 * 0.1, 1280.0)) < 0.01, "Starfield offset matches 140 px/s rate")

	# 4. Spawner spawns Guard Bots from right edge (X >= 1280)
	var spawned_bot = stage2._spawn_guard_bot()
	assert_true(spawned_bot != null, "Guard Bot successfully spawned")
	assert_true(spawned_bot.position.x >= 1280.0, "Guard Bot spawned at or beyond right edge (x >= 1280)")
	assert_true(spawned_bot.position.y >= 80.0 and spawned_bot.position.y <= 640.0, "Guard Bot Y spawn is within playfield margin")
	assert_true(spawned_bot.target_player == stage2.player, "Spawned bot references player target")
	assert_true(spawned_bot.projectiles_container == stage2.enemy_projectiles_container, "Spawned bot references EnemyProjectiles container")

	# 5. Player bounds containment
	assert_true(stage2.player.position.x >= 0.0 and stage2.player.position.x <= 1280.0, "Player X is bounded within 1280px")
	assert_true(stage2.player.position.y >= 0.0 and stage2.player.position.y <= 720.0, "Player Y is bounded within 720px")

	# 6. Asteroid spawner is absent from Stage 2
	assert_false(stage2.has_method("spawn_asteroid"), "Stage 2 has no vertical asteroid spawner method")

	stage2.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite C: Guard Bot Enemy Specification & Combat
# ------------------------------------------------------------------------------
func _suite_c_guard_bot_enemy() -> void:
	print("\n--- Running Suite C: Guard Bot Enemy Specification & Combat ---")

	var bot = GUARD_BOT_SCENE.instantiate()
	add_child(bot)
	await get_tree().process_frame

	# 1. Health parameters
	assert_eq(bot.max_health, 30, "Guard Bot max_health is 30")
	assert_eq(bot.health, 30, "Guard Bot starts with full 30 HP")

	# 2. Collision layers and masks
	# Layer 2 (value 2: Combat Target) | Layer 5 (value 16: Enemies) = 18
	# Mask 1 (value 1: Player) | Mask 3 (value 4: Player Projectiles) = 5
	assert_eq(bot.collision_layer, 18, "Guard Bot collision_layer is 18 (Layer 2 | Layer 5)")
	assert_eq(bot.collision_mask, 5, "Guard Bot collision_mask is 5 (Layer 1 | Layer 3)")
	assert_true(bot.is_in_group("enemies"), "Guard Bot is in 'enemies' group")
	assert_true(bot.is_in_group("guard_bots"), "Guard Bot is in 'guard_bots' group")

	# 3. Official art and procedural fallback
	var visuals = bot.get_node_or_null("Visuals")
	assert_true(visuals != null, "Guard Bot has Visuals child node")
	var official_art = bot.get_node_or_null("Visuals/OfficialArt")
	assert_true(official_art != null, "Guard Bot has OfficialArt node")
	var idle_spr = bot.get_node_or_null("Visuals/OfficialArt/IdleSprite")
	assert_true(idle_spr != null, "Guard Bot has IdleSprite")
	assert_true(idle_spr.texture != null, "Guard Bot IdleSprite has official texture loaded")
	var attack_spr = bot.get_node_or_null("Visuals/OfficialArt/AttackingSprite")
	assert_true(attack_spr != null, "Guard Bot has AttackingSprite")
	assert_true(attack_spr.texture != null, "Guard Bot AttackingSprite has official texture loaded")
	var fallback = bot.get_node_or_null("Visuals/ProceduralFallback")
	assert_true(fallback != null, "Guard Bot has ProceduralFallback node")

	# 4. Default sprite pose visibility
	assert_true(idle_spr.visible, "Default state: IdleSprite is visible")
	assert_false(attack_spr.visible, "Default state: AttackingSprite is hidden")

	# 5. Projectile damage reception & signals (using Array reference for lambda capture)
	var damaged_events: Array = []
	bot.damaged.connect(func(amt: int, rem: int):
		damaged_events.append({"amount": amt, "remaining": rem})
	)

	bot.take_damage(1)
	assert_eq(damaged_events.size(), 1, "Guard Bot emitted damaged signal exactly once")
	if damaged_events.size() > 0:
		assert_eq(damaged_events[0]["amount"], 1, "Damage amount reported is 1")
		assert_eq(damaged_events[0]["remaining"], 29, "Remaining HP reported is 29")
	assert_eq(bot.health, 29, "Guard Bot current health is 29")

	# 6. Destruction at 0 HP
	var destroyed_events: Array = []
	bot.destroyed.connect(func(): destroyed_events.append(true))

	bot.take_damage(29)
	assert_eq(bot.health, 0, "Guard Bot health reaches 0")
	assert_true(bot.is_destroyed, "Guard Bot marked is_destroyed = true")
	assert_eq(destroyed_events.size(), 1, "Guard Bot emitted destroyed signal")
	assert_true(bot.fire_attack() == null, "Destroyed Guard Bot cannot fire attacks")
	assert_eq(bot.contact_damage, 0, "Destroyed Guard Bot contact damage zeroed out")
	assert_true(bot.is_queued_for_deletion(), "Destroyed Guard Bot is queued for deletion")

	bot.queue_free()
	await get_tree().process_frame

	# 7. Mutual contact damage & independent pair cooldown
	var fresh_bot = GUARD_BOT_SCENE.instantiate()
	var fresh_player = PLAYER_SCENE.instantiate()
	add_child(fresh_bot)
	add_child(fresh_player)
	await get_tree().process_frame

	fresh_player.prepare_for_level(12)
	assert_eq(fresh_player.health, 12, "Player starts at 12 HP")
	assert_eq(fresh_bot.health, 30, "Guard Bot starts at 30 HP")

	# Simulate contact overlap
	var player_id = fresh_player.get_instance_id()
	fresh_player.take_damage(fresh_bot.contact_damage)
	fresh_bot.take_damage(1)
	fresh_bot.contact_cooldown[player_id] = 0.5

	assert_eq(fresh_player.health, 11, "Player takes 1 contact damage from Guard Bot")
	assert_eq(fresh_bot.health, 29, "Guard Bot takes 1 mutual contact damage from Player")
	assert_eq(fresh_bot.contact_cooldown[player_id], 0.5, "Contact pair cooldown initialized to 0.5s")

	# Cooldown prevents immediate re-damage
	fresh_bot.contact_cooldown[player_id] = 0.3
	assert_true(fresh_bot.contact_cooldown[player_id] > 0.0, "Cooldown remains active prior to 0.5s expiration")

	# 8. Offscreen cleanup past left margin (X < -100)
	fresh_bot.position = Vector2(-105.0, 300.0)
	fresh_bot._physics_process(0.016)
	assert_true(fresh_bot.is_queued_for_deletion(), "Guard Bot past X=-100 queued for deletion")

	fresh_player.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite D: Enemy Projectiles System
# ------------------------------------------------------------------------------
func _suite_d_enemy_projectiles() -> void:
	print("\n--- Running Suite D: Enemy Projectiles System ---")

	var ep = ENEMY_PROJECTILE_SCENE.instantiate()
	add_child(ep)
	await get_tree().process_frame

	# 1. Specifications and collision configuration
	assert_eq(ep.speed, 300.0, "Enemy projectile speed is 300.0 px/s")
	assert_eq(ep.damage, 1, "Enemy projectile damage is 1 HP")
	assert_eq(ep.lifetime, 4.0, "Enemy projectile lifetime is 4.0s")
	assert_eq(ep.collision_layer, 32, "Enemy projectile collision_layer is 32 (Layer 6)")
	assert_eq(ep.collision_mask, 1, "Enemy projectile collision_mask is 1 (Layer 1: Player)")
	assert_true(ep.is_in_group("enemy_projectiles"), "Enemy projectile in 'enemy_projectiles' group")
	assert_true(ep.get_visuals_node() != null, "Enemy projectile has Visuals node")

	# 2. Movement along direction vector
	ep.direction = Vector2.LEFT
	ep.global_position = Vector2(500.0, 300.0)
	ep._physics_process(0.1)
	assert_eq(ep.global_position.x, 470.0, "Projectile moves left at 300 px/s (500 -> 470 in 0.1s)")

	# 3. Damage application to player (using Array reference for lambda capture)
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.prepare_for_level(12)
	await get_tree().process_frame

	var hit_events: Array = []
	ep.hit.connect(func(target): hit_events.append(target))

	ep._on_area_entered(player)
	assert_eq(hit_events.size(), 1, "Enemy projectile emitted hit signal exactly once")
	if hit_events.size() > 0:
		assert_true(hit_events[0] == player, "Hit target reported is player")
	assert_eq(player.health, 11, "Player took 1 damage from enemy projectile (12 -> 11)")
	assert_true(ep.has_hit, "Enemy projectile marked has_hit = true")
	assert_true(ep.is_queued_for_deletion(), "Enemy projectile queued for deletion after hitting player")

	# 4. Double-hit protection
	ep._on_area_entered(player)
	assert_eq(player.health, 11, "Double-hit prevented: Player HP remains 11")

	# 5. Friendly fire immunity: Enemy projectile must not damage Guard Bot or friendly units
	var ep2 = ENEMY_PROJECTILE_SCENE.instantiate()
	var bot = GUARD_BOT_SCENE.instantiate()
	add_child(ep2)
	add_child(bot)
	await get_tree().process_frame

	ep2._on_area_entered(bot)
	assert_eq(bot.health, 30, "Friendly fire prevented: Guard Bot takes 0 damage from enemy projectile")
	assert_false(ep2.has_hit, "Enemy projectile does not mark has_hit against friendly enemy")
	assert_false(ep2.is_queued_for_deletion(), "Enemy projectile does not despawn upon touching friendly bot")

	# 6. Despawn on lifetime expiration
	ep2.elapsed_time = 4.1
	ep2._physics_process(0.01)
	assert_true(ep2.is_queued_for_deletion(), "Enemy projectile despawns when elapsed_time >= lifetime")

	# 7. Despawn on playfield boundary margins
	var ep3 = ENEMY_PROJECTILE_SCENE.instantiate()
	add_child(ep3)
	ep3.global_position = Vector2(-65.0, 300.0)
	ep3._physics_process(0.01)
	assert_true(ep3.is_queued_for_deletion(), "Enemy projectile despawns past left margin (X < -60)")

	player.queue_free()
	bot.queue_free()
	ep3.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite E: Survival Timer, Objective & Level Completion
# ------------------------------------------------------------------------------
func _suite_e_survival_timer_and_completion() -> void:
	print("\n--- Running Suite E: Survival Timer, Objective & Level Completion ---")

	var stage2 = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2)
	await get_tree().process_frame

	# 1. 15-second survival duration
	assert_eq(stage2.level_duration, 15.0, "Stage 2 Level 1 duration is exactly 15.0s")
	assert_true(stage2.time_remaining <= 15.0 and stage2.time_remaining >= 14.8, "Initial time_remaining is ~15.0s")
	assert_false(stage2.finished, "Stage 2 starts unfinished")
	assert_false(stage2.game_won, "Stage 2 starts game_won = false")

	# 2. Timer decrement
	var t_before: float = stage2.time_remaining
	stage2._process(1.0)
	assert_true(absf(stage2.time_remaining - (t_before - 1.0)) < 0.05, "Time remaining decrements by ~1.0s on process")

	# 3. Survival completion at 0.0s (using Array reference for lambda capture)
	var completed_events: Array = []
	stage2.level_completed.connect(func(lvl: int): completed_events.append(lvl))

	stage2.time_remaining = 0.0
	stage2._process(0.01)

	assert_true(stage2.finished, "Stage 2 marked finished = true on survival")
	assert_true(stage2.game_won, "Stage 2 marked game_won = true on survival")
	assert_eq(completed_events.size(), 1, "level_completed signal emitted exactly once")
	if completed_events.size() > 0:
		assert_eq(completed_events[0], 1, "level_completed signal emitted with level 1")

	# 4. Call Down: player physics disabled and weapon firing disabled
	assert_false(stage2.player.is_physics_processing(), "Player physics disabled on level complete (Call Down)")
	assert_false(stage2.weapon_controller.firing_enabled, "Weapon firing disabled on level complete")

	# 5. Completion message
	assert_true(stage2.message.visible, "Completion message visible")
	assert_true(stage2.message.text.contains("STAGE 2 / LEVEL 1 COMPLETE!"), "Message proclaims STAGE 2 / LEVEL 1 COMPLETE!")
	assert_true(stage2.message.text.contains("Sector Incursion Survived"), "Message confirms survival objective")
	assert_true(stage2.message.text.contains("Guard Bot Sector Cleared"), "Message confirms Guard Bot sector cleared")

	# 6. Milestone boundary: Level 2 cannot start
	assert_eq(stage2.current_level, 1, "current_level remains 1 (no fake Level 2 started)")

	# 7. Player death does NOT trigger level complete
	var stage2_fail = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2_fail)
	await get_tree().process_frame

	var fail_completed_events: Array = []
	stage2_fail.level_completed.connect(func(lvl): fail_completed_events.append(lvl))

	stage2_fail.player.take_damage(12)
	assert_true(stage2_fail.finished, "Game finished on player death")
	assert_false(stage2_fail.game_won, "game_won is false on player death")
	assert_eq(fail_completed_events.size(), 0, "level_completed signal NOT emitted on death")
	assert_true(stage2_fail.message.text.contains("SHIP DESTROYED (STAGE 2 / LEVEL 1)"), "Death message displayed")

	stage2.queue_free()
	stage2_fail.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite F: Stage 2 Checkpoint & Revive Semantics
# ------------------------------------------------------------------------------
func _suite_f_stage2_checkpoint_and_revive() -> void:
	print("\n--- Running Suite F: Stage 2 Checkpoint & Revive Semantics ---")

	var stage2 = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2)
	await get_tree().process_frame

	# 1. Kill player in Stage 2 Level 1
	stage2.player.take_damage(12)
	assert_eq(stage2.player.health, 0, "Player HP is 0")
	assert_true(stage2.finished, "Game is marked finished")
	assert_false(stage2.game_won, "Game is not won")

	# Spawn dummy enemies and volley to verify cleanup
	var spawned_bot = stage2._spawn_guard_bot()
	var spawned_volley = stage2.weapon_controller.fire_volley()
	assert_true(stage2.enemies_container.get_child_count() > 0, "Enemies present before checkpoint reset")

	# 2. Revive at Stage 2 Checkpoint
	stage2.revive_at_stage_checkpoint()

	# 3. Validations: Stays in Stage 2 Level 1!
	assert_eq(stage2.stage_number, 2, "Revive stays in Stage 2 (does NOT send player back to Stage 1)")
	assert_eq(stage2.current_level, 1, "Revive restarts at Stage 2 Level 1")
	assert_eq(stage2.player.health, 12, "Player HP fully restored to 12")
	assert_eq(stage2.player.max_health, 12, "Player max_health is 12")
	assert_true(stage2.player.alive, "Player alive is true")
	assert_false(stage2.finished, "Game finished reset to false")
	assert_false(stage2.game_won, "Game won reset to false")
	assert_eq(stage2.time_remaining, 15.0, "Survival timer reset to 15.0s")
	assert_true(stage2.player.is_physics_processing(), "Player physics processing re-enabled")
	assert_true(stage2.weapon_controller.firing_enabled, "Primary weapon remains active after Stage 2 checkpoint revive")

	# Wait 1 frame for queue_free() scheduled deletions to execute
	await get_tree().process_frame

	# 4. Cleanup of entities
	assert_eq(stage2.enemies_container.get_child_count(), 0, "Enemies container cleared on checkpoint revive")
	assert_eq(stage2.enemy_projectiles_container.get_child_count(), 0, "Enemy projectiles container cleared")
	assert_eq(stage2.projectiles_container.get_child_count(), 0, "Player projectiles container cleared")

	# 5. Stage 1 Checkpoint integrity check
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
	assert_false(level_select.is_level_playable(2, 2), "Stage 2 Level 2 is LOCKED")

	var s1l1_btn: TextureButton = level_select.level_buttons[Vector2i(1, 1)]
	var s1l2_btn: TextureButton = level_select.level_buttons[Vector2i(1, 2)]
	var s2l1_btn: TextureButton = level_select.level_buttons[Vector2i(2, 1)]
	assert_false(s1l1_btn.disabled, "S1L1 button is enabled")
	assert_true(s1l2_btn.disabled, "S1L2 button is disabled")
	assert_true(s2l1_btn.disabled, "S2L1 button is disabled")

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

	await get_tree().process_frame


func _print_summary() -> void:
	print("\n==================================================")
	print("MILESTONE 6 TEST EXECUTION SUMMARY")
	print("==================================================")
	print("Total assertions: %d" % total_count)
	print("Passed:           %d" % pass_count)
	print("Failed:           %d" % fail_count)
	if fail_count == 0:
		print("VERDICT: ALL TESTS PASSED (100%)")
	else:
		printerr("VERDICT: %d ASSERTION(S) FAILED" % fail_count)
	print("==================================================")
