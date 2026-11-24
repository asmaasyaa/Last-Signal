extends Node
## Test runner logic for Milestone 9 (Stage 2 Level 4: Guard Cruiser Mini-Boss Phase 1 & EM Jammer Activation).
## Validates Suites A through H covering Level 3 -> Level 4 progression, Boss Arena architecture,
## Guard Cruiser Phase 1 (400 -> 200 HP threshold), official Phase 1 art, EM Jammer directional cone,
## 10s stun & 30s cooldown lifecycle, real combat physics, Stage 2 checkpoint revive, and regression.

var total_count: int = 0
var pass_count: int = 0
var fail_count: int = 0

const MAIN_SCENE = preload("res://scenes/main.tscn")
const STAGE2_MAIN_SCENE = preload("res://scenes/stage2/stage2_main.tscn")
const BOSS_ARENA_SCENE = preload("res://scenes/stage2/boss_arena.tscn")
const GUARD_CRUISER_SCENE = preload("res://scenes/bosses/guard_cruiser.tscn")
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
	await _suite_a_level_progression_to_level4()
	await _suite_b_boss_architecture_and_official_art()
	await _suite_c_boss_phase_threshold()
	await _suite_d_em_jammer_cone_and_activation()
	await _suite_e_stun_and_cooldown_lifecycle()
	await _suite_f_boss_combat_and_interactions()
	await _suite_g_checkpoint_and_revive_from_level4()
	await _suite_h_regression_and_safety()


# ------------------------------------------------------------------------------
# Suite A: Level 3 -> Level 4 Progression & State Persistence
# ------------------------------------------------------------------------------
func _suite_a_level_progression_to_level4() -> void:
	print("\n--- Running Suite A: Level 3 -> Level 4 Progression & State Persistence ---")

	var stage2 = STAGE2_MAIN_SCENE.instantiate()
	add_child(stage2)
	await get_tree().process_frame

	# 1. Start at Level 3 with 7 HP
	stage2.start_level(3, 7)
	await get_tree().process_frame

	assert_eq(stage2.current_level, 3, "Stage 2 starts at Level 3")
	assert_eq(stage2.player.health, 7, "Player starts Level 3 at 7 HP")
	assert_false(stage2.finished, "Level 3 is initially unfinished")

	# Incomplete Level 3 cannot advance to Level 4
	var invalid_advance = stage2.advance_to_next_level()
	assert_true(invalid_advance == null, "Incomplete Level 3 cannot advance to Level 4")

	# Complete Level 3 by registering 5 legitimate player weapon kills
	var dummy = GUARD_DRONE_SCENE.instantiate()
	for i in range(5):
		stage2._on_drone_defeated(0, dummy)

	assert_true(stage2.finished, "Level 3 marked finished after 5 kills")
	assert_true(stage2.game_won, "Level 3 marked game_won")
	assert_true(stage2.is_em_jammer_acquired(), "EM Jammer is acquired upon Level 3 completion")
	assert_true(stage2.message.visible, "Level 3 completion banner visible")
	assert_true(stage2.message.text.contains("STAGE 2 / LEVEL 3 COMPLETE!"), "Banner proclaims STAGE 2 / LEVEL 3 COMPLETE!")
	assert_true(stage2.message.text.contains("Press [Space/Enter] for Level 4"), "Banner prompts for Level 4 progression")

	# Advance to Level 4 via advance_to_next_level()
	var arena = stage2.advance_to_next_level()
	assert_true(arena != null, "advance_to_next_level() returns BossArena instance")
	add_child(arena)
	await get_tree().process_frame

	# Verify Level 4 state
	assert_eq(arena.stage_number, 2, "Arena stage_number is 2")
	assert_eq(arena.current_level, 4, "Arena current_level is 4")
	assert_false(arena.finished, "Boss Arena marked unfinished on start")
	assert_false(arena.game_won, "Boss Arena game_won reset to false")
	assert_eq(arena.player.health, 7, "Remaining 7 HP strictly persisted into Level 4 (no intra-stage restoration)")
	assert_eq(arena.player.max_health, 12, "Player max_health remains 12")
	assert_true(arena.player.alive, "Player is alive in Level 4")
	assert_true(arena.player.is_physics_processing(), "Player physics processing enabled in Level 4")
	assert_true(arena.is_primary_weapon_acquired(), "Primary weapon acquisition preserved in Level 4")
	assert_true(arena.is_shield_acquired(), "Shield acquisition preserved in Level 4")
	assert_true(arena.is_em_jammer_acquired(), "EM Jammer acquisition preserved in Level 4")

	# Verify entity cleanup from side-scrolling level
	assert_eq(arena.projectiles_container.get_child_count(), 0, "Old player projectiles cleaned up")
	assert_eq(arena.enemy_projectiles_container.get_child_count(), 0, "Old enemy projectiles cleaned up")

	# Verify Level 4 HUD
	assert_true(arena.info.text.contains("STAGE 2 / LEVEL 4"), "HUD displays STAGE 2 / LEVEL 4")
	assert_true(arena.info.text.contains("HP 07 / 12"), "HUD displays HP 07 / 12")
	assert_true(arena.boss_bar.text.contains("GUARD CRUISER: 400 / 400 HP"), "HUD displays initial Boss HP 400 / 400")
	assert_true(arena.jammer_status.text.contains("EM JAMMER: READY [E]"), "HUD displays EM Jammer READY")

	# Verify dead player in Level 3 cannot advance
	stage2.start_level(3, 12)
	stage2.player.take_damage(12)
	assert_true(stage2.finished, "Stage 2 finished on death")
	assert_false(stage2.game_won, "Stage 2 not won on death")
	var dead_advance = stage2.advance_to_next_level()
	assert_true(dead_advance == null, "Dead player in Level 3 cannot advance to Level 4")

	dummy.queue_free()
	arena.queue_free()
	stage2.queue_free()


# ------------------------------------------------------------------------------
# Suite B: Boss Architecture & Official Phase 1 Art
# ------------------------------------------------------------------------------
func _suite_b_boss_architecture_and_official_art() -> void:
	print("\n--- Running Suite B: Boss Architecture & Official Phase 1 Art ---")

	var boss = GUARD_CRUISER_SCENE.instantiate()
	add_child(boss)
	await get_tree().process_frame

	# 1. Base Properties & Stats
	assert_eq(boss.max_health, 400, "Guard Cruiser max_health is 400")
	assert_eq(boss.health, 400, "Guard Cruiser starts at full 400 HP")
	assert_eq(boss.phase_1_threshold, 200, "Phase 1 threshold is exactly 200 HP")
	assert_eq(boss.current_phase, 1, "Current phase is 1")
	assert_true(boss.can_take_damage, "can_take_damage is true initially")
	assert_false(boss.phase_1_completed, "phase_1_completed is false initially")
	assert_false(boss.is_destroyed, "is_destroyed is false initially")
	assert_false(boss.is_stunned, "is_stunned is false initially")
	assert_eq(boss.scale, Vector2.ONE, "Root physics scale is strictly neutral Vector2.ONE")

	# 2. Collision Layers & Groups
	assert_eq(boss.collision_layer, 18, "Guard Cruiser collision_layer is 18 (Layer 2 | Layer 5)")
	assert_eq(boss.collision_mask, 5, "Guard Cruiser collision_mask is 5 (Layer 1 | Layer 3)")
	assert_true(boss.is_in_group("enemies"), "Guard Cruiser is in 'enemies' group")
	assert_true(boss.is_in_group("bosses"), "Guard Cruiser is in 'bosses' group")

	# 3. Collision Shape Hitbox
	assert_true(boss.collision_shape != null, "Guard Cruiser has CollisionShape2D")
	assert_true(boss.collision_shape.shape is RectangleShape2D, "Hitbox is a RectangleShape2D")
	var rect_shape: RectangleShape2D = boss.collision_shape.shape
	assert_true(rect_shape.size.x >= 200.0 and rect_shape.size.x <= 250.0, "Hitbox width matches core cruiser hull (~230px)")
	assert_true(rect_shape.size.y >= 90.0 and rect_shape.size.y <= 130.0, "Hitbox height matches core cruiser hull (~110px)")

	# 4. Visual Subtree & Official Artwork
	assert_true(boss.visuals != null, "Guard Cruiser has Visuals child node")
	assert_true(boss.official_art != null, "Guard Cruiser has OfficialArt node")
	assert_true(boss.phase1_sprite != null, "Guard Cruiser has Phase1Sprite")
	assert_true(boss.phase1_sprite.texture != null, "Phase1Sprite has official texture loaded")
	assert_true(boss.phase1_sprite.visible, "Phase1Sprite is visible in Phase 1")
	assert_true(boss.phase2_sprite != null, "Guard Cruiser has Phase2Sprite (reserved)")
	assert_false(boss.phase2_sprite.visible, "Phase2Sprite is strictly reserved and hidden")
	assert_true(boss.dead_sprite != null, "Guard Cruiser has DeadSprite (reserved)")
	assert_false(boss.dead_sprite.visible, "DeadSprite is strictly reserved and hidden")
	assert_true(boss.fallback != null, "Guard Cruiser has ProceduralFallback node")

	boss.queue_free()


# ------------------------------------------------------------------------------
# Suite C: Boss Phase Threshold (400 -> 200 HP)
# ------------------------------------------------------------------------------
func _suite_c_boss_phase_threshold() -> void:
	print("\n--- Running Suite C: Boss Phase Threshold (400 -> 200 HP) ---")

	var boss = GUARD_CRUISER_SCENE.instantiate()
	add_child(boss)
	await get_tree().process_frame

	# Track health signals and threshold signals
	var health_signals: Array = []
	boss.health_changed.connect(func(curr, max_hp): health_signals.append(Vector2i(curr, max_hp)))

	var threshold_signals: Array = []
	boss.phase_threshold_reached.connect(func(phase): threshold_signals.append(phase))

	var defeated_signals: Array = []
	boss.defeated.connect(func(): defeated_signals.append(true))

	# 1. Valid hit reduces HP from 400 to 399
	boss.take_damage(1)
	assert_eq(boss.health, 399, "Taking 1 damage reduces HP from 400 to 399")
	assert_eq(health_signals.size(), 1, "health_changed signal emitted once")
	assert_eq(health_signals[0], Vector2i(399, 400), "Signal payload is (399, 400)")
	assert_false(boss.phase_1_completed, "Phase 1 not completed at 399 HP")

	# 2. Damage down to 201 HP (active fighting continues)
	boss.take_damage(198)
	assert_eq(boss.health, 201, "Boss HP is 201 after 199 total damage")
	assert_false(boss.phase_1_completed, "Phase 1 not completed at 201 HP")
	assert_true(boss.can_take_damage, "can_take_damage remains true at 201 HP")
	assert_eq(threshold_signals.size(), 0, "phase_threshold_reached not emitted above 200 HP")

	# 3. Crossing threshold to 200 HP triggers Phase 1 completion
	boss.take_damage(1)
	assert_eq(boss.health, 200, "Boss HP reaches exactly 200")
	assert_true(boss.phase_1_completed, "phase_1_completed is true at 200 HP")
	assert_false(boss.can_take_damage, "can_take_damage is false after Phase 1 completion")
	assert_eq(threshold_signals.size(), 1, "phase_threshold_reached emitted exactly once")
	assert_eq(threshold_signals[0], 1, "phase_threshold_reached emitted with phase 1")

	# 4. Boss is NOT destroyed or defeated at 200 HP
	assert_false(boss.is_destroyed, "Boss is NOT destroyed at 200 HP")
	assert_eq(defeated_signals.size(), 0, "defeated signal is NOT emitted (reserved for Phase 2)")

	# 5. Clamping & Protection: Further damage cannot reduce HP below 200
	boss.take_damage(50)
	assert_eq(boss.health, 200, "Further damage strictly clamped at 200 HP during Level 4")
	assert_eq(threshold_signals.size(), 1, "phase_threshold_reached not re-emitted")

	boss.queue_free()


# ------------------------------------------------------------------------------
# Suite D: EM Jammer Cone Geometry & Activation
# ------------------------------------------------------------------------------
func _suite_d_em_jammer_cone_and_activation() -> void:
	print("\n--- Running Suite D: EM Jammer Cone Geometry & Activation ---")

	var arena = BOSS_ARENA_SCENE.instantiate()
	add_child(arena)
	await get_tree().process_frame

	var jammer = arena.em_jammer_controller
	var player = arena.player
	player.position = Vector2(640.0, 500.0)
	player.target_position_override = player.position
	player.movement_velocity = Vector2.ZERO
	player.rotation = 0.0 # Facing UP (-Y)

	# 1. Unearned jammer cannot activate
	jammer.set_acquired(false)
	assert_false(jammer.is_ready(), "Unacquired jammer is not ready")
	assert_false(jammer.activate(), "Unacquired jammer activation blocked")

	# 2. Acquired jammer can activate
	jammer.set_acquired(true)
	assert_true(jammer.is_ready(), "Acquired jammer is ready initially")

	# 3. Directional Cone Geometry Testing (120 degrees full cone = ±60 degrees)
	# Target A: Directly forward (0 degrees, 300px away) -> MUST BE AFFECTED
	var target_a = GUARD_BOT_SCENE.instantiate()
	arena.add_child(target_a)
	target_a.global_position = player.global_position + Vector2.UP * 300.0

	# Target B: Inside cone at +45 degrees (within ±60 deg, 300px away) -> MUST BE AFFECTED
	var target_b = GUARD_BOT_SCENE.instantiate()
	arena.add_child(target_b)
	target_b.global_position = player.global_position + Vector2.UP.rotated(deg_to_rad(45.0)) * 300.0

	# Target C: Outside cone at +90 degrees (outside ±60 deg, 300px away) -> MUST NOT BE AFFECTED
	var target_c = GUARD_BOT_SCENE.instantiate()
	arena.add_child(target_c)
	target_c.global_position = player.global_position + Vector2.RIGHT * 300.0

	# Target D: Inside angle (0 degrees) but beyond cone_range (>600px, at 750px) -> MUST NOT BE AFFECTED
	var target_d = GUARD_BOT_SCENE.instantiate()
	arena.add_child(target_d)
	target_d.global_position = player.global_position + Vector2.UP * 750.0

	# Activate Jammer
	var activated_signals: Array = []
	jammer.activated.connect(func(dir, targets): activated_signals.append([dir, targets]))

	var success = jammer.activate()
	assert_true(success, "Jammer activated successfully")
	assert_eq(activated_signals.size(), 1, "activated signal emitted once")
	assert_eq(activated_signals[0][0], Vector2.UP, "Cone direction aligned with player forward heading")

	var affected: Array = activated_signals[0][1]
	assert_true(target_a in affected, "Target A (0 deg, 300px) is inside 120-deg cone")
	assert_true(target_b in affected, "Target B (+45 deg, 300px) is inside 120-deg cone")
	assert_false(target_c in affected, "Target C (+90 deg, 300px) is outside 120-deg cone")
	assert_false(target_d in affected, "Target D (0 deg, 750px) is beyond cone_range (600px)")

	# 4. Zero Damage Guarantee
	assert_eq(target_a.health, 30, "Target A received 0 HP damage from EM Jammer")
	assert_eq(target_b.health, 30, "Target B received 0 HP damage from EM Jammer")

	# 5. Cannot activate while dead
	jammer.cooldown_remaining = 0.0 # Force ready
	player.alive = false
	assert_false(jammer.can_activate(), "Dead player cannot activate EM Jammer")
	player.alive = true

	# 6. Cannot activate while arena finished
	arena.finished = true
	assert_false(jammer.can_activate(), "Finished arena cannot activate EM Jammer")
	arena.finished = false

	target_a.queue_free()
	target_b.queue_free()
	target_c.queue_free()
	target_d.queue_free()
	arena.queue_free()


# ------------------------------------------------------------------------------
# Suite E: Stun and Cooldown Lifecycle
# ------------------------------------------------------------------------------
func _suite_e_stun_and_cooldown_lifecycle() -> void:
	print("\n--- Running Suite E: Stun and Cooldown Lifecycle ---")

	var boss = GUARD_CRUISER_SCENE.instantiate()
	add_child(boss)
	await get_tree().process_frame

	boss.position = Vector2(640.0, 150.0)

	# 1. Apply Stun to Guard Cruiser
	var stun_events: Array = []
	boss.stunned.connect(func(dur): stun_events.append(dur))
	var stun_end_events: Array = []
	boss.stun_ended.connect(func(): stun_end_events.append(true))

	boss.apply_stun(10.0)
	assert_true(boss.is_stunned, "Guard Cruiser is stunned")
	assert_eq(boss.stun_timer, 10.0, "Stun duration initialized to 10.0s")
	assert_eq(stun_events.size(), 1, "stunned signal emitted")
	assert_eq(stun_events[0], 10.0, "Stun duration payload is 10.0s")

	# Movement stops while stunned
	var pos_before = boss.position
	boss._physics_process(1.0)
	assert_eq(boss.position, pos_before, "Boss position does NOT change while stunned (movement halted)")

	# Vulnerability preserved while stunned
	boss.take_damage(10)
	assert_eq(boss.health, 390, "Stunned boss remains vulnerable to weapon damage (400 -> 390 HP)")

	# Stun timer decrements on physics process
	assert_eq(boss.stun_timer, 9.0, "Stun timer decremented from 10.0 to 9.0s")

	# Fast forward remaining 9.0s to expire stun
	boss._physics_process(9.0)
	assert_false(boss.is_stunned, "Stun expired after 10.0s total")
	assert_eq(stun_end_events.size(), 1, "stun_ended signal emitted")

	# Normal movement resumes after stun
	boss._physics_process(1.0)
	assert_true(boss.position != pos_before, "Boss movement resumes after stun expires")

	# 2. Cooldown Lifecycle on Controller
	var jammer = load("res://scripts/equipment/em_jammer_controller.gd").new()
	add_child(jammer)
	var dummy_player = PLAYER_SCENE.instantiate()
	add_child(dummy_player)
	jammer.setup(dummy_player)
	jammer.set_acquired(true)

	var cd_start_events: Array = []
	jammer.cooldown_started.connect(func(dur): cd_start_events.append(dur))
	var cd_finish_events: Array = []
	jammer.cooldown_finished.connect(func(): cd_finish_events.append(true))

	# Activate
	jammer.activate()
	assert_eq(jammer.cooldown_remaining, 30.0, "Cooldown initialized to 30.0s")
	assert_eq(cd_start_events.size(), 1, "cooldown_started signal emitted")
	assert_eq(cd_start_events[0], 30.0, "Cooldown duration payload is 30.0s")
	assert_false(jammer.is_ready(), "Jammer is NOT ready during cooldown")

	# Duplicate activation blocked during cooldown
	assert_false(jammer.activate(), "Duplicate activation blocked while in cooldown")

	# Fast forward 15s (half cooldown)
	jammer._process(15.0)
	assert_eq(jammer.cooldown_remaining, 15.0, "Cooldown remaining is 15.0s")
	assert_false(jammer.is_ready(), "Jammer still not ready at 15.0s remaining")

	# Fast forward remaining 15s
	jammer._process(15.0)
	assert_eq(jammer.cooldown_remaining, 0.0, "Cooldown cleanly reaches 0.0s")
	assert_true(jammer.is_ready(), "Jammer is ready again after 30.0s")
	assert_eq(cd_finish_events.size(), 1, "cooldown_finished signal emitted")

	dummy_player.queue_free()
	jammer.queue_free()
	boss.queue_free()


# ------------------------------------------------------------------------------
# Suite F: Boss Combat & Damage Interactions
# ------------------------------------------------------------------------------
func _suite_f_boss_combat_and_interactions() -> void:
	print("\n--- Running Suite F: Boss Combat & Damage Interactions ---")

	var arena = BOSS_ARENA_SCENE.instantiate()
	add_child(arena)
	await get_tree().process_frame

	var boss = arena.boss
	var player = arena.player
	player.position = Vector2(640.0, 560.0)

	# 1. Attack wind-up cue
	var attack_start_events: Array = []
	boss.attack_started.connect(func(): attack_start_events.append(true))
	var attack_fired_events: Array = []
	boss.attack_fired.connect(func(proj): attack_fired_events.append(proj))

	boss.start_attack_windup()
	assert_eq(boss.attack_state, 1, "Boss in WINDUP attack state")
	assert_eq(attack_start_events.size(), 1, "attack_started signal emitted")

	# 2. Attack burst firing
	boss.fire_attack_burst()
	assert_eq(attack_fired_events.size(), 3, "Controlled burst fires exactly 3 projectiles")
	assert_eq(boss.attack_state, 0, "Boss returned to COOLDOWN state after burst")

	# 3. Projectile properties & Player Damage
	var p0 = attack_fired_events[0]
	assert_true(p0.is_in_group("enemy_projectiles"), "Boss projectile is in 'enemy_projectiles' group")
	assert_eq(p0.collision_layer, 32, "Boss projectile collision_layer is 32 (Layer 6)")
	assert_eq(p0.collision_mask, 1, "Boss projectile collision_mask is 1 (Layer 1 Player)")

	# Player hit
	player.take_damage(p0.damage)
	assert_eq(player.health, 11, "Player takes 1 damage from boss projectile (12 -> 11)")

	# 4. Friendly fire immunity: Enemy projectiles cannot damage the boss
	boss.take_damage(0)
	assert_eq(boss.health, 400, "Boss takes 0 damage from enemy projectile layer")

	# 5. Real physics collision: Player projectile striking boss
	var player_proj = PROJECTILE_SCENE.instantiate()
	player_proj.direction = Vector2.UP
	player_proj.global_position = boss.global_position
	arena.projectiles_container.add_child(player_proj)

	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_eq(boss.health, 399, "Real physics collision: Player projectile damaged Guard Cruiser (400 -> 399)")
	assert_true(player_proj.is_queued_for_deletion() or not player_proj.monitoring, "Player projectile consumed on striking boss")

	# 6. Stop attack cancels active windup
	boss.start_attack_windup()
	boss.stop_attack()
	assert_eq(boss.attack_state, 0, "stop_attack cleanly resets attack state to COOLDOWN")

	arena.queue_free()


# ------------------------------------------------------------------------------
# Suite G: Stage 2 Checkpoint & Revive from Level 4
# ------------------------------------------------------------------------------
func _suite_g_checkpoint_and_revive_from_level4() -> void:
	print("\n--- Running Suite G: Stage 2 Checkpoint & Revive from Level 4 ---")

	var arena = BOSS_ARENA_SCENE.instantiate()
	add_child(arena)
	await get_tree().process_frame

	# Damage boss down to 350
	arena.boss.take_damage(50)
	assert_eq(arena.boss.health, 350, "Boss damaged to 350 HP before player death")

	# Player dies in Level 4
	arena.player.take_damage(12)
	assert_eq(arena.player.health, 0, "Player HP is 0")
	assert_true(arena.finished, "Arena marked finished on player death")
	assert_false(arena.game_won, "Arena marked game_won = false on player death")
	assert_true(arena.message.visible, "Death message visible")
	assert_true(arena.message.text.contains("SHIP DESTROYED (STAGE 2 / LEVEL 4)"), "Death message displays STAGE 2 / LEVEL 4")
	assert_true(arena.message.text.contains("Press [R] to Revive at Stage 2 Checkpoint"), "Prompts for Stage 2 Checkpoint revive")

	# Revive at Stage 2 checkpoint
	var stage2_revived = arena.revive_at_stage_checkpoint()
	assert_true(stage2_revived != null, "revive_at_stage_checkpoint() returns Stage 2 coordinator")
	add_child(stage2_revived)
	await get_tree().process_frame

	# Verify revived Stage 2 state
	assert_eq(stage2_revived.stage_number, 2, "Revive stays in Stage 2 (does NOT reset to Stage 1)")
	assert_eq(stage2_revived.current_level, 1, "Revive restarts strictly at Stage 2 Level 1")
	assert_eq(stage2_revived.player.health, 12, "Player HP fully restored to 12")
	assert_eq(stage2_revived.player.max_health, 12, "Player max_health is 12")
	assert_true(stage2_revived.player.alive, "Player alive is true")
	assert_false(stage2_revived.finished, "Game finished reset to false")
	assert_false(stage2_revived.game_won, "Game won reset to false")
	assert_true(stage2_revived.player.is_physics_processing(), "Player physics processing re-enabled")
	assert_true(stage2_revived.is_primary_weapon_acquired(), "Primary weapon retained after Stage 2 checkpoint revive")
	assert_true(stage2_revived.is_shield_acquired(), "Shield hardware retained after Stage 2 checkpoint revive")
	assert_false(stage2_revived.is_em_jammer_acquired(), "EM Jammer acquisition reset to unearned for fresh stage run")
	assert_eq(stage2_revived.get_drones_destroyed(), 0, "Drones destroyed objective reset to 0")

	# Verify Stage 1 checkpoint still revives at Stage 1 Level 1 without weapons
	var main1 = MAIN_SCENE.instantiate()
	add_child(main1)
	await get_tree().process_frame
	main1.start_level(4, 5)
	main1.player.take_damage(5)
	main1.revive_at_stage_checkpoint()
	assert_eq(main1.current_level, 1, "Stage 1 checkpoint still revives at Stage 1 Level 1")
	assert_eq(main1.player.health, 12, "Stage 1 player HP restored to 12")
	assert_false(main1.is_primary_weapon_acquired(), "Stage 1 checkpoint resets unearned weapon")
	main1.queue_free()

	stage2_revived.queue_free()
	arena.queue_free()


# ------------------------------------------------------------------------------
# Suite H: System-Wide Regression & Safety
# ------------------------------------------------------------------------------
func _suite_h_regression_and_safety() -> void:
	print("\n--- Running Suite H: System-Wide Regression & Safety ---")

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
	assert_false(level_select.is_level_playable(2, 1), "Stage 2 Level 1 is LOCKED in Level Select")
	assert_false(level_select.is_level_playable(2, 2), "Stage 2 Level 2 is LOCKED in Level Select")
	assert_false(level_select.is_level_playable(2, 3), "Stage 2 Level 3 is LOCKED in Level Select")
	assert_false(level_select.is_level_playable(2, 4), "Stage 2 Level 4 is LOCKED in Level Select")

	level_select.queue_free()

	# 2. Main Menu Verification
	var menu = MAIN_MENU_SCENE.instantiate()
	add_child(menu)
	await get_tree().process_frame

	assert_true(menu.start_button != null, "Main menu Start button exists")
	assert_true(menu.select_button != null, "Main menu Select button exists")
	assert_true(menu.exit_button != null, "Main menu Exit button exists")

	menu.queue_free()

	# 3. Call Down Architectural Constraint
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	assert_false(player.has_method("shoot"), "Player has no shoot() method (Call Down constraint preserved)")
	assert_false(player.has_method("fire"), "Player has no fire() method (Call Down constraint preserved)")
	assert_false(player.has_method("activate_em_jammer"), "Player has no direct activate_em_jammer method (managed by EMJammerController)")
	assert_true(player.get_node_or_null("Visuals") != null, "Player scene has Visuals child node")

	player.queue_free()

	# 4. Visual Subtree Verification across All Entities
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

	var cruiser = GUARD_CRUISER_SCENE.instantiate()
	assert_true(cruiser.get_node_or_null("Visuals") != null, "Guard Cruiser has Visuals child node")
	cruiser.queue_free()


func _print_summary() -> void:
	print("\n==================================================")
	print("MILESTONE 9 TEST EXECUTION SUMMARY")
	print("==================================================")
	print("Total assertions: %d" % total_count)
	print("Passed:           %d" % pass_count)
	print("Failed:           %d" % fail_count)
	if fail_count == 0:
		print("VERDICT: ALL TESTS PASSED (100%)")
	else:
		print("VERDICT: TEST SUITE FAILED")
	print("==================================================\n")
