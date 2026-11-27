extends Node
## Test runner logic for Milestone 10 (Stage 2 Level 5: Guard Cruiser Phase 2, Final Defeat & Stage 2 Completion).
## Validates Suites A through H covering Phase 1 -> Phase 2 progression & boss node continuity,
## Phase 2 official art & AI behavior, health lifecycle & defeat clamping, EM Jammer continuity & stun,
## real physics engine collision, Stage 2 completion events & payload, checkpoint revive, and regression.

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
	await _suite_a_progression_and_continuity()
	await _suite_b_boss_phase_2_and_official_art()
	await _suite_c_damage_and_defeat_lifecycle()
	await _suite_d_em_jammer_continuity_and_stun()
	await _suite_e_real_physics_collision()
	await _suite_f_stage_2_completion()
	await _suite_g_checkpoint_and_revive()
	await _suite_h_regression_and_safety()


# ------------------------------------------------------------------------------
# Suite A: Phase 1 -> Phase 2 Progression & Strict Boss Object Continuity
# ------------------------------------------------------------------------------
func _suite_a_progression_and_continuity() -> void:
	print("\n--- Running Suite A: Phase 1 -> Phase 2 Progression & Boss Object Continuity ---")

	var arena = BOSS_ARENA_SCENE.instantiate()
	add_child(arena)
	await get_tree().process_frame

	arena.start_level(4, 7) # Level 4 with 7 HP persisted from Level 3
	await get_tree().process_frame

	assert_eq(arena.current_level, 4, "Arena initialized at Level 4")
	assert_eq(arena.player.health, 7, "Player starts Level 4 at 7 HP")
	assert_eq(arena.boss.health, 400, "Boss starts Level 4 at 400 HP")

	# 1. Cannot transition to Level 5 before Phase 1 completion
	assert_false(arena.advance_to_next_level(), "Cannot advance to Level 5 before Phase 1 is complete")

	# Damage boss down to 200 HP (completes Phase 1)
	arena.boss.take_damage(200)
	assert_eq(arena.boss.health, 200, "Boss reached 200 HP threshold")
	assert_true(arena.boss.phase_1_completed, "Boss phase_1_completed is true")
	assert_true(arena.finished, "Level 4 marked finished")
	assert_true(arena.game_won, "Level 4 marked game_won")
	assert_true(arena.message.visible, "Phase 1 completion message visible")
	assert_true(arena.message.text.contains("STAGE 2 / LEVEL 4 COMPLETE"), "Banner proclaims STAGE 2 / LEVEL 4 COMPLETE")
	assert_true(arena.message.text.contains("Press [Space/Enter] for Level 5"), "Banner prompts for Level 5 advance")

	# 2. Dead player cannot advance to Level 5
	arena.player.alive = false
	assert_false(arena.advance_to_next_level(), "Dead player cannot advance to Level 5")
	arena.player.alive = true

	# 3. Object Continuity: Record node identities before transition
	var boss_instance_id: int = arena.boss.get_instance_id()
	var player_instance_id: int = arena.player.get_instance_id()
	var boss_ref = arena.boss
	var player_ref = arena.player

	# 4. Legitimate transition to Level 5 via advance_to_next_level()
	var transition_success: bool = arena.advance_to_next_level()
	assert_true(transition_success, "advance_to_next_level() succeeded")
	await get_tree().process_frame

	# 5. Verify STRICT Object Identity Continuity (One Boss, Two Phases)
	assert_true(arena.boss == boss_ref, "Guard Cruiser instance reference preserved across phases")
	assert_eq(arena.boss.get_instance_id(), boss_instance_id, "Guard Cruiser node instance ID strictly identical")
	assert_true(arena.player == player_ref, "Player instance reference preserved across phases")
	assert_eq(arena.player.get_instance_id(), player_instance_id, "Player node instance ID strictly identical")

	# 6. Verify Level 5 State & Health Persistence
	assert_eq(arena.current_level, 5, "Arena current_level is 5")
	assert_eq(arena.stage_number, 2, "Arena stage_number remains 2")
	assert_false(arena.finished, "Level 5 combat marked active (not finished)")
	assert_false(arena.game_won, "Level 5 game_won reset to false for active battle")
	assert_eq(arena.player.health, 7, "Remaining 7 HP persisted into Level 5 (no intra-stage restoration)")
	assert_eq(arena.player.max_health, 12, "Player max_health remains 12")
	assert_true(arena.player.alive, "Player is alive in Level 5")
	assert_true(arena.player.is_physics_processing(), "Player physics processing enabled in Level 5")
	assert_true(arena.is_primary_weapon_acquired(), "Primary weapon acquisition retained in Level 5")
	assert_true(arena.is_shield_acquired(), "Shield hardware retained in Level 5")
	assert_true(arena.is_em_jammer_acquired(), "EM Jammer retained in Level 5")
	assert_true(arena.is_phase_2_active(), "is_phase_2_active() reports true")
	assert_true(arena.info.text.contains("STAGE 2 / LEVEL 5"), "HUD displays STAGE 2 / LEVEL 5")
	assert_true(arena.boss_bar.text.contains("200 / 400"), "HUD displays Boss HP 200 / 400")

	# 7. Reject duplicate transition calls
	assert_false(arena.advance_to_next_level(), "Duplicate transition to Level 5 rejected")

	arena.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite B: Boss Phase 2 Architecture & Official Art
# ------------------------------------------------------------------------------
func _suite_b_boss_phase_2_and_official_art() -> void:
	print("\n--- Running Suite B: Boss Phase 2 Architecture & Official Art ---")

	var boss = GUARD_CRUISER_SCENE.instantiate()
	add_child(boss)
	await get_tree().process_frame

	boss.health = 200
	boss.phase_1_completed = true
	boss.start_phase_2()
	await get_tree().process_frame

	assert_eq(boss.current_phase, 2, "Boss current_phase is 2")
	assert_eq(boss.health, 200, "Boss Phase 2 starts at exactly 200 HP")
	assert_eq(boss.max_health, 400, "Boss max_health remains 400")
	assert_true(boss.can_take_damage, "Boss can_take_damage re-enabled in Phase 2")
	assert_false(boss.is_destroyed, "Boss is not destroyed on Phase 2 start")
	assert_false(boss.is_stunned, "Boss is not stunned on Phase 2 start")
	assert_eq(boss.scale, Vector2.ONE, "Root physics scale strictly neutral Vector2.ONE")

	# Official Art Verification
	assert_true(boss.phase2_sprite != null, "Phase2Sprite exists")
	assert_true(boss.phase2_sprite.texture != null, "Phase2Sprite has official texture loaded")
	assert_true(boss.phase2_sprite.visible, "Phase2Sprite is VISIBLE in Phase 2")
	assert_false(boss.phase1_sprite.visible, "Phase1Sprite is HIDDEN in Phase 2")
	assert_false(boss.dead_sprite.visible, "DeadSprite is HIDDEN in Phase 2")

	# Speed and Attack Parameters
	assert_eq(boss.phase_2_move_speed, 115.0, "Phase 2 move speed is 115.0 px/s")
	assert_eq(boss.phase_2_attack_interval, 2.0, "Phase 2 attack interval is 2.0s")
	assert_eq(boss.phase_2_burst_count, 5, "Phase 2 burst count is 5 projectiles")
	assert_eq(boss.phase_2_projectile_speed, 350.0, "Phase 2 projectile speed is 350.0 px/s")

	# Phase 2 Attack Burst Execution (fires 5 projectiles in ~20 degree spread)
	var fired_projectiles: Array = []
	boss.attack_fired.connect(func(p): fired_projectiles.append(p))
	boss.fire_attack_burst()

	assert_eq(fired_projectiles.size(), 5, "Phase 2 burst fires exactly 5 projectiles")
	for p in fired_projectiles:
		assert_eq(p.speed, 350.0, "Phase 2 projectile speed set to 350.0 px/s")
		p.queue_free()

	boss.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite C: Phase 2 Health Clamping & Final Defeat Lifecycle
# ------------------------------------------------------------------------------
func _suite_c_damage_and_defeat_lifecycle() -> void:
	print("\n--- Running Suite C: Phase 2 Health Clamping & Final Defeat Lifecycle ---")

	var boss = GUARD_CRUISER_SCENE.instantiate()
	add_child(boss)
	await get_tree().process_frame

	boss.health = 200
	boss.phase_1_completed = true
	boss.start_phase_2()

	var health_signals: Array = []
	boss.health_changed.connect(func(c, m): health_signals.append(Vector2i(c, m)))

	var defeated_signals: Array = []
	boss.defeated.connect(func(): defeated_signals.append(true))

	# 1. Damage decreases from 200 toward 0
	boss.take_damage(50)
	assert_eq(boss.health, 150, "Boss HP reduced from 200 to 150")
	assert_eq(health_signals.size(), 1, "health_changed emitted on hit")
	assert_eq(health_signals[0], Vector2i(150, 400), "Signal payload is (150, 400)")
	assert_false(boss.is_destroyed, "Boss not destroyed at 150 HP")
	assert_eq(defeated_signals.size(), 0, "defeated signal not emitted at 150 HP")

	# 2. Damage down to 1 HP
	boss.take_damage(149)
	assert_eq(boss.health, 1, "Boss HP reduced to 1")
	assert_false(boss.is_destroyed, "Boss not destroyed at 1 HP")
	assert_true(boss.can_take_damage, "can_take_damage remains true at 1 HP")
	assert_eq(defeated_signals.size(), 0, "defeated signal not emitted at 1 HP")

	# 3. Final lethal hit reduces HP to 0 -> Defeat Sequence
	boss.take_damage(1)
	assert_eq(boss.health, 0, "Boss HP reaches exactly 0")
	assert_true(boss.is_destroyed, "Boss marked is_destroyed = true")
	assert_false(boss.can_take_damage, "can_take_damage negated to false on defeat")
	assert_eq(defeated_signals.size(), 1, "defeated signal emitted exactly once")

	# 4. Clamping & Protection: Damage cannot go negative, defeat not re-emitted
	boss.take_damage(50)
	assert_eq(boss.health, 0, "Boss HP clamped at 0 (never negative)")
	assert_eq(defeated_signals.size(), 1, "defeated signal not re-emitted")

	# 5. Visual State on Defeat: DeadSprite visible, alive sprites hidden
	assert_true(boss.dead_sprite.visible, "DeadSprite is VISIBLE on defeat")
	assert_false(boss.phase1_sprite.visible, "Phase1Sprite is HIDDEN on defeat")
	assert_false(boss.phase2_sprite.visible, "Phase2Sprite is HIDDEN on defeat")

	# 6. Safe Collision Deactivation
	await get_tree().physics_frame
	assert_false(boss.monitoring, "Boss monitoring disabled on defeat")
	assert_false(boss.monitorable, "Boss monitorable disabled on defeat")

	# 7. Boss node identity preserved on defeat screen (not instantly freed)
	assert_true(is_instance_valid(boss), "Boss node persists on defeat (not instantly freed)")

	boss.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite D: EM Jammer Continuity & Phase 2 Stun Mechanics
# ------------------------------------------------------------------------------
func _suite_d_em_jammer_continuity_and_stun() -> void:
	print("\n--- Running Suite D: EM Jammer Continuity & Phase 2 Stun Mechanics ---")

	var arena = BOSS_ARENA_SCENE.instantiate()
	add_child(arena)
	await get_tree().process_frame

	arena.start_level(4, 12)
	arena.boss.take_damage(200) # Finish Phase 1

	var jammer = arena.em_jammer_controller
	var boss = arena.boss

	# 1. Cooldown continuity: set remaining cooldown to 18.0s, transition to Level 5
	jammer.cooldown_remaining = 18.0
	arena.advance_to_next_level()
	await get_tree().process_frame

	assert_eq(arena.current_level, 5, "Transitioned to Level 5")
	assert_true(jammer.cooldown_remaining >= 17.0 and jammer.cooldown_remaining <= 18.0, "Cooldown strictly preserved across phase boundary (not reset to 0!)")
	assert_false(jammer.is_ready(), "Jammer is not ready during preserved cooldown")
	assert_false(jammer.activate(), "Jammer cannot activate during preserved cooldown")

	# 2. Reset cooldown cleanly to test Phase 2 stun application
	jammer.cooldown_remaining = 0.0
	assert_true(jammer.is_ready(), "Jammer is ready after cooldown finishes")

	# Position player facing boss
	arena.player.global_position = Vector2(640.0, 500.0)
	arena.player.rotation = 0.0
	arena.player.movement_velocity = Vector2.ZERO
	arena.player.target_position_override = arena.player.global_position

	boss.global_position = Vector2(640.0, 200.0)
	boss.start_attack_windup()
	assert_eq(boss.attack_state, 1, "Boss entered WINDUP attack state in Phase 2")

	# 3. Activate EM Jammer in Phase 2
	var activated = jammer.activate()
	assert_true(activated, "EM Jammer activated in Phase 2")
	assert_true(boss.is_stunned, "Phase 2 boss is stunned by EM Jammer")
	assert_eq(boss.stun_timer, 10.0, "Stun duration initialized to 10.0s")
	assert_eq(boss.attack_state, 0, "Boss attack windup canceled by stun (reset to COOLDOWN)")

	# 4. Zero Damage Guarantee on Stun
	assert_eq(boss.health, 200, "Boss received ZERO damage from EM Jammer stun")

	# 5. Stunned Phase 2 boss remains vulnerable to player weapons
	boss.take_damage(20)
	assert_eq(boss.health, 180, "Stunned Phase 2 boss damaged by weapon (200 -> 180 HP)")

	# 6. Stun expiration and resumption
	boss._physics_process(10.0)
	assert_false(boss.is_stunned, "Boss stun expires after 10.0s")
	assert_eq(boss.stun_timer, 0.0, "Stun timer reaches 0.0s")

	# 7. Jammer enters 30.0s cooldown
	assert_eq(jammer.cooldown_remaining, 30.0, "Jammer entered 30.0s cooldown")

	arena.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite E: Real Physics Engine Overlap & Target Filtering
# ------------------------------------------------------------------------------
func _suite_e_real_physics_collision() -> void:
	print("\n--- Running Suite E: Real Physics Engine Overlap & Target Filtering ---")

	var arena = BOSS_ARENA_SCENE.instantiate()
	add_child(arena)
	await get_tree().process_frame

	arena.start_level(4, 12)
	arena.boss.take_damage(200)
	arena.advance_to_next_level()
	await get_tree().process_frame

	var boss = arena.boss
	var player = arena.player
	boss.global_position = Vector2(640.0, 200.0)
	player.global_position = Vector2(640.0, 560.0)

	# 1. Real Area2D Player Projectile Collision with Guard Cruiser
	var proj = PROJECTILE_SCENE.instantiate()
	var proj_hit_events: Array = []
	proj.hit.connect(func(target): proj_hit_events.append(target))
	arena.projectiles_container.add_child(proj)
	proj.global_position = boss.global_position # Position directly inside boss hitbox
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_eq(boss.health, 199, "Real physics: Player projectile damaged Guard Cruiser (200 -> 199)")
	assert_eq(proj_hit_events.size(), 1, "Projectile registered hit signal on collision")

	# 2. Real Area2D Enemy Projectile Collision with Player
	var e_proj = ENEMY_PROJECTILE_SCENE.instantiate()
	var e_proj_hit_events: Array = []
	e_proj.hit.connect(func(target): e_proj_hit_events.append(target))
	arena.enemy_projectiles_container.add_child(e_proj)
	e_proj.global_position = player.global_position # Position directly inside player hitbox
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_eq(player.health, 11, "Real physics: Enemy projectile damaged Player (12 -> 11)")
	assert_eq(e_proj_hit_events.size(), 1, "Enemy projectile registered hit signal on collision")

	# 3. Friendly Fire Immunity: Enemy Projectile on Guard Cruiser
	var e_proj_ff = ENEMY_PROJECTILE_SCENE.instantiate()
	var ff_hit_events: Array = []
	e_proj_ff.hit.connect(func(target): ff_hit_events.append(target))
	arena.enemy_projectiles_container.add_child(e_proj_ff)
	e_proj_ff.global_position = boss.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_eq(boss.health, 199, "Real physics: Enemy projectile dealt 0 damage to Guard Cruiser (Friendly Fire Immunity)")
	assert_eq(ff_hit_events.size(), 0, "Enemy projectile ignored Guard Cruiser (0 hit signals)")
	if is_instance_valid(e_proj_ff):
		e_proj_ff.queue_free()

	arena.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite F: Stage 2 Completion & Narrative Interface
# ------------------------------------------------------------------------------
func _suite_f_stage_2_completion() -> void:
	print("\n--- Running Suite F: Stage 2 Completion & Narrative Interface ---")

	var arena = BOSS_ARENA_SCENE.instantiate()
	add_child(arena)
	await get_tree().process_frame

	arena.start_level(4, 10)
	arena.boss.take_damage(200)
	arena.advance_to_next_level()
	await get_tree().process_frame

	var stage_complete_signals: Array = []
	arena.stage_completed.connect(func(payload): stage_complete_signals.append(payload))

	var level_complete_signals: Array = []
	arena.level_completed.connect(func(lvl): level_complete_signals.append(lvl))

	# Defeat boss in Phase 2
	arena.boss.take_damage(200)
	await get_tree().process_frame

	assert_true(arena.finished, "Arena marked finished on boss defeat")
	assert_true(arena.game_won, "Arena marked game_won = true on boss defeat")
	assert_true(arena.is_stage2_completed(), "is_stage2_completed() reports true")
	assert_eq(arena.stage_acquisitions.get("stage2_completed", false), true, "stage2_completed recorded in acquisitions")

	# Signals emitted exactly once
	assert_eq(stage_complete_signals.size(), 1, "stage_completed signal emitted exactly once")
	assert_eq(level_complete_signals.size(), 1, "level_completed signal emitted exactly once")
	assert_eq(level_complete_signals[0], 5, "level_completed emitted for Level 5")

	# Payload Schema Verification
	var payload: Dictionary = stage_complete_signals[0]
	assert_eq(payload.get("event_id"), "stage2_completed", "Payload event_id is 'stage2_completed'")
	assert_eq(payload.get("stage"), 2, "Payload stage is 2")
	assert_eq(payload.get("current_level"), 5, "Payload current_level is 5")
	assert_eq(payload.get("boss_name"), "Guard Cruiser", "Payload boss_name is 'Guard Cruiser'")
	assert_eq(payload.get("boss_final_health"), 0, "Payload boss_final_health is 0")
	assert_eq(payload.get("stage_completed"), true, "Payload stage_completed is true")
	assert_eq(payload.get("next_stage"), 3, "Payload next_stage is 3")
	assert_eq(payload.get("next_stage_available"), true, "Payload next_stage_available is true (Stage 3 authorized in M11)")

	# Completion Message & Artwork
	assert_true(arena.message.visible, "Victory message is visible")
	assert_true(arena.message.text.contains("STAGE 2 COMPLETE!"), "Banner proclaims STAGE 2 COMPLETE!")
	assert_true(arena.message.text.contains("GUARD CRUISER DEFEATED"), "Banner proclaims GUARD CRUISER DEFEATED")
	assert_true(arena.message.text.contains("Press [Space/Enter] to Begin Stage 3"), "Banner prompts to begin Stage 3")
	assert_true(arena.boss.dead_sprite.visible, "DeadSprite remains visible on completion screen")

	# Weapons and projectiles cleaned up
	assert_false(arena.weapon_controller.firing_enabled, "Player weapon firing disabled after victory")
	assert_eq(arena.projectiles_container.get_child_count(), 0, "Projectiles container cleared")
	assert_eq(arena.enemy_projectiles_container.get_child_count(), 0, "Enemy projectiles container cleared")

	arena.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite G: Stage 2 Checkpoint Revive & Deterministic Tie-Breaking
# ------------------------------------------------------------------------------
func _suite_g_checkpoint_and_revive() -> void:
	print("\n--- Running Suite G: Stage 2 Checkpoint Revive & Deterministic Tie-Breaking ---")

	# 1. Player dies in Level 5 -> Revives at Stage 2 Level 1
	var arena = BOSS_ARENA_SCENE.instantiate()
	add_child(arena)
	await get_tree().process_frame

	arena.start_level(4, 12)
	arena.boss.take_damage(200)
	arena.advance_to_next_level()
	await get_tree().process_frame

	arena.player.take_damage(12)
	assert_eq(arena.player.health, 0, "Player HP reduced to 0 in Level 5")
	assert_true(arena.finished, "Arena finished on player death")
	assert_false(arena.game_won, "Arena game_won is false on player death")
	assert_true(arena.message.text.contains("SHIP DESTROYED (STAGE 2 / LEVEL 5)"), "Death banner displays STAGE 2 / LEVEL 5")

	var revived_stage2 = arena.revive_at_stage_checkpoint()
	assert_true(revived_stage2 != null, "revive_at_stage_checkpoint() returns Stage 2 coordinator")
	add_child(revived_stage2)
	await get_tree().process_frame

	assert_eq(revived_stage2.stage_number, 2, "Revive stays in Stage 2 (does NOT reset to Stage 1)")
	assert_eq(revived_stage2.current_level, 1, "Revive restarts strictly at Stage 2 Level 1")
	assert_eq(revived_stage2.player.health, 12, "Player HP restored to 12")
	assert_true(revived_stage2.is_primary_weapon_acquired(), "Primary weapon retained after checkpoint revive")
	assert_true(revived_stage2.is_shield_acquired(), "Shield hardware retained after checkpoint revive")
	assert_false(revived_stage2.is_em_jammer_acquired(), "EM Jammer reset to unearned for fresh stage run")

	revived_stage2.queue_free()
	arena.queue_free()
	await get_tree().process_frame

	# 2. Deterministic Tie-Breaking: Player dies first -> Boss defeat ignored
	var arena_tie1 = BOSS_ARENA_SCENE.instantiate()
	add_child(arena_tie1)
	await get_tree().process_frame
	arena_tie1.start_level(4, 12)
	arena_tie1.boss.take_damage(200)
	arena_tie1.advance_to_next_level()
	await get_tree().process_frame

	arena_tie1._on_player_died() # Player dies first
	arena_tie1._on_boss_defeated() # Boss defeat arrives late
	assert_true(arena_tie1.finished, "Tie-break 1 finished")
	assert_false(arena_tie1.game_won, "Tie-break 1: Player loss stands deterministically")
	assert_false(arena_tie1.is_stage2_completed(), "Tie-break 1: Stage 2 victory NOT granted")
	arena_tie1.queue_free()
	await get_tree().process_frame

	# 3. Deterministic Tie-Breaking: Boss defeated first -> Player death ignored
	var arena_tie2 = BOSS_ARENA_SCENE.instantiate()
	add_child(arena_tie2)
	await get_tree().process_frame
	arena_tie2.start_level(4, 12)
	arena_tie2.boss.take_damage(200)
	arena_tie2.advance_to_next_level()
	await get_tree().process_frame

	arena_tie2._on_boss_defeated() # Boss defeated first
	arena_tie2._on_player_died() # Player death arrives late
	assert_true(arena_tie2.finished, "Tie-break 2 finished")
	assert_true(arena_tie2.game_won, "Tie-break 2: Victory stands deterministically")
	assert_true(arena_tie2.is_stage2_completed(), "Tie-break 2: Stage 2 completed is true")
	arena_tie2.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite H: System-Wide Regression & Safety
# ------------------------------------------------------------------------------
func _suite_h_regression_and_safety() -> void:
	print("\n--- Running Suite H: System-Wide Regression & Safety ---")

	# 1. Level Select Registry
	var lvl_select = LEVEL_SELECT_SCENE.instantiate()
	add_child(lvl_select)
	await get_tree().process_frame

	assert_eq(lvl_select.level_buttons.size(), 15, "All 15 level buttons registered in Level Select")
	assert_true(lvl_select.is_level_playable(1, 1), "Stage 1 Level 1 is PLAYABLE")
	assert_false(lvl_select.is_level_playable(1, 2), "Stage 1 Level 2 is LOCKED")
	assert_false(lvl_select.is_level_playable(1, 3), "Stage 1 Level 3 is LOCKED")
	assert_false(lvl_select.is_level_playable(1, 4), "Stage 1 Level 4 is LOCKED")
	assert_false(lvl_select.is_level_playable(1, 5), "Stage 1 Level 5 is LOCKED")
	assert_false(lvl_select.is_level_playable(2, 1), "Stage 2 Level 1 is LOCKED in Level Select")
	assert_false(lvl_select.is_level_playable(2, 2), "Stage 2 Level 2 is LOCKED in Level Select")
	assert_false(lvl_select.is_level_playable(2, 3), "Stage 2 Level 3 is LOCKED in Level Select")
	assert_false(lvl_select.is_level_playable(2, 4), "Stage 2 Level 4 is LOCKED in Level Select")
	assert_false(lvl_select.is_level_playable(2, 5), "Stage 2 Level 5 is LOCKED in Level Select")
	assert_false(lvl_select.is_level_playable(3, 1), "Stage 3 Level 1 is LOCKED in Level Select")

	lvl_select.queue_free()
	await get_tree().process_frame

	# 2. Main Menu Verification
	var menu = MAIN_MENU_SCENE.instantiate()
	add_child(menu)
	await get_tree().process_frame

	assert_true(menu.start_button != null, "Main menu Start button exists")
	assert_true(menu.select_button != null, "Main menu Select button exists")
	assert_true(menu.exit_button != null, "Main menu Exit button exists")

	menu.queue_free()
	await get_tree().process_frame

	# 3. Call Down Architectural Constraint: Player has no direct weapon/jammer execution methods
	var player_test = PLAYER_SCENE.instantiate()
	add_child(player_test)
	await get_tree().process_frame

	assert_false(player_test.has_method("shoot"), "Player has no shoot() method (Call Down constraint preserved)")
	assert_false(player_test.has_method("fire"), "Player has no fire() method (Call Down constraint preserved)")
	assert_false(player_test.has_method("activate_em_jammer"), "Player has no direct activate_em_jammer method (managed by EMJammerController)")

	player_test.queue_free()
	await get_tree().process_frame

	# 4. Visuals Node Presentation Pattern across entities
	var entities = [
		PLAYER_SCENE.instantiate(),
		ASTEROID_SCENE.instantiate(),
		SATELLITE_SCENE.instantiate(),
		MINING_SATELLITE_SCENE.instantiate(),
		DAMAGED_MINING_SHIP_SCENE.instantiate(),
		GUARD_BOT_SCENE.instantiate(),
		GUARD_SATELLITE_SCENE.instantiate(),
		GUARD_DRONE_SCENE.instantiate(),
		GUARD_CRUISER_SCENE.instantiate()
	]

	for ent in entities:
		add_child(ent)
		await get_tree().process_frame
		assert_true(ent.get_node_or_null("Visuals") != null, "%s has Visuals child node" % ent.name)
		ent.queue_free()
		await get_tree().process_frame


func _print_summary() -> void:
	print("\n==================================================")
	print("MILESTONE 10 TEST EXECUTION SUMMARY")
	print("==================================================")
	print("Total assertions: %d" % total_count)
	print("Passed:           %d" % pass_count)
	print("Failed:           %d" % fail_count)
	if fail_count == 0:
		print("VERDICT: ALL TESTS PASSED (100%)")
	else:
		print("VERDICT: TEST SUITE FAILED")
	print("==================================================\n")
