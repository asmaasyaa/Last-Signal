extends Node
## Test runner logic for Milestone 11 (Stage 3 Level 1: Final Boss Phase 1 + Stage 2 Integration Audit).
## Validates Suites A through I covering Stage 2 -> Stage 3 transition, Stage 3 coordinator architecture,
## Final Boss health & 800->600 Phase 1 threshold, official Phase 1 artwork, provisional Phase 1 AI,
## EM Jammer integration & stun, Stage 3 checkpoint semantics, real Area2D physics collision,
## and full Stage 1-2 progression integration audit.

var total_count: int = 0
var pass_count: int = 0
var fail_count: int = 0

const MAIN_SCENE = preload("res://scenes/main.tscn")
const STAGE2_MAIN_SCENE = preload("res://scenes/stage2/stage2_main.tscn")
const BOSS_ARENA_SCENE = preload("res://scenes/stage2/boss_arena.tscn")
const STAGE3_MAIN_SCENE = preload("res://scenes/stage3/stage3_main.tscn")
const FINAL_BOSS_SCENE = preload("res://scenes/bosses/final_boss.tscn")
const PROJECTILE_SCENE = preload("res://scenes/projectile.tscn")
const ENEMY_PROJECTILE_SCENE = preload("res://scenes/enemies/enemy_projectile.tscn")
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
	await _suite_a_stage2_to_stage3_integration()
	await _suite_b_stage3_architecture()
	await _suite_c_final_boss_health()
	await _suite_d_official_artwork()
	await _suite_e_boss_ai()
	await _suite_f_em_jammer()
	await _suite_g_checkpoint_and_tiebreak()
	await _suite_h_real_physics()
	await _suite_i_stage1_2_integration_audit()


# ------------------------------------------------------------------------------
# Suite A: Stage 2 -> Stage 3 Integration
# ------------------------------------------------------------------------------
func _suite_a_stage2_to_stage3_integration() -> void:
	print("\n--- Running Suite A: Stage 2 -> Stage 3 Integration ---")

	var arena = BOSS_ARENA_SCENE.instantiate()
	add_child(arena)
	await get_tree().process_frame

	arena.start_level(4, 5) # Low HP in Stage 2 to verify Stage 3 restoration to 12/12
	var stage_payloads: Array = []
	arena.stage_completed.connect(func(p): stage_payloads.append(p))

	# 1. Incomplete Stage 2 cannot transition
	assert_true(arena.advance_to_stage_3() == null, "Incomplete Stage 2 (Level 4) cannot transition to Stage 3")

	arena.boss.take_damage(200) # Finish Phase 1
	arena.advance_to_next_level() # Enter Level 5
	assert_true(arena.advance_to_stage_3() == null, "Incomplete Stage 2 (Level 5 before defeat) cannot transition to Stage 3")

	# Set active EM Jammer cooldown to confirm cooldown preservation across new stage boundary
	arena.em_jammer_controller.cooldown_remaining = 14.5

	# 2. Defeat Guard Cruiser -> Stage 2 Completion
	arena.boss.take_damage(200)
	await get_tree().process_frame

	assert_true(arena.is_stage2_completed(), "Stage 2 completed flag set")
	assert_eq(stage_payloads.size(), 1, "stage_completed signal emitted once")
	assert_eq(stage_payloads[0].get("next_stage_available", false), true, "Payload confirms Stage 3 is available")
	assert_true(arena.message.text.contains("Press [Space/Enter] to Begin Stage 3"), "Completion banner prompts Space/Enter to Begin Stage 3")

	# Dead player guard check
	arena.player.alive = false
	assert_true(arena.advance_to_stage_3() == null, "Dead player cannot advance to Stage 3")
	arena.player.alive = true

	# 3. Legitimate Space/Enter transition via advance_to_stage_3()
	var stage3 = arena.advance_to_stage_3()
	assert_true(is_instance_valid(stage3), "advance_to_stage_3() instantiated Stage3Main")

	# Duplicate transition request rejected
	assert_true(arena.advance_to_stage_3() == null, "Duplicate transition to Stage 3 rejected")

	# Clean up arena and mount Stage 3
	arena.queue_free()
	add_child(stage3)
	await get_tree().process_frame

	assert_eq(stage3.stage_number, 3, "Stage 3 coordinator stage_number is 3")
	assert_eq(stage3.current_level, 1, "Stage 3 starts at Level 1")
	assert_eq(stage3.player.health, 12, "Player HP restored to 12/12 upon entering Stage 3")
	assert_eq(stage3.player.max_health, 12, "Player max_health is 12")
	assert_true(stage3.is_primary_weapon_acquired(), "Primary weapon retained in Stage 3")
	assert_true(stage3.is_shield_acquired(), "Shield hardware retained in Stage 3")
	assert_true(stage3.is_em_jammer_acquired(), "EM Jammer acquisition retained in Stage 3")
	assert_true(stage3.em_jammer_controller.cooldown_remaining >= 13.5 and stage3.em_jammer_controller.cooldown_remaining <= 14.5, "EM Jammer cooldown preserved across Stage 2 -> Stage 3 boundary")

	# Confirm no leftover Guard Cruiser or Stage 2 nodes inside Stage 3
	var stray_cruisers: int = 0
	for child in stage3.get_children():
		if "GuardCruiser" in child.name:
			stray_cruisers += 1
	assert_eq(stray_cruisers, 0, "Zero Stage 2 GuardCruiser nodes present in Stage 3")
	assert_eq(stage3.projectiles_container.get_child_count(), 0, "Stage 3 starts with clean PlayerProjectiles")
	assert_eq(stage3.enemy_projectiles_container.get_child_count(), 0, "Stage 3 starts with clean EnemyProjectiles")

	stage3.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite B: Stage 3 Architecture
# ------------------------------------------------------------------------------
func _suite_b_stage3_architecture() -> void:
	print("\n--- Running Suite B: Stage 3 Architecture ---")

	var stage3 = STAGE3_MAIN_SCENE.instantiate()
	add_child(stage3)
	await get_tree().process_frame

	assert_true(is_instance_valid(stage3), "Stage3Main scene loads")
	assert_true(is_instance_valid(stage3.boss), "FinalBoss instance exists")
	assert_true(is_instance_valid(stage3.player), "Player instance exists")
	assert_true(is_instance_valid(stage3.weapon_controller), "WeaponController exists")
	assert_true(is_instance_valid(stage3.em_jammer_controller), "EMJammerController exists")
	assert_true(is_instance_valid(stage3.hud), "HUD CanvasLayer exists")
	assert_true(is_instance_valid(stage3.info), "HUD Info label exists")
	assert_true(is_instance_valid(stage3.boss_bar), "HUD BossBar label exists")
	assert_true(is_instance_valid(stage3.jammer_status), "HUD JammerStatus label exists")
	assert_true(is_instance_valid(stage3.message), "HUD Message label exists")

	assert_true(stage3.info.text.contains("STAGE 3 / LEVEL 1"), "HUD Info displays STAGE 3 / LEVEL 1")
	assert_true(stage3.info.text.contains("HP 12 / 12"), "HUD Info displays HP 12 / 12")
	assert_true(stage3.boss_bar.text.contains("FINAL BOSS: 800 / 800 HP"), "HUD BossBar displays 800 / 800 HP")
	assert_true(stage3.jammer_status.text.contains("EM JAMMER: READY [E]"), "HUD JammerStatus displays READY")

	# Count controllers and players to guarantee zero duplicates
	var player_count: int = 0
	var boss_count: int = 0
	var wep_count: int = 0
	var jam_count: int = 0
	for child in stage3.get_children():
		if child.is_in_group("player"):
			player_count += 1
		if child.is_in_group("bosses"):
			boss_count += 1
		if child.name == "WeaponController":
			wep_count += 1
		if child.name == "EMJammerController":
			jam_count += 1
	assert_eq(player_count, 1, "Exactly one Player instance")
	assert_eq(boss_count, 1, "Exactly one FinalBoss instance")
	assert_eq(wep_count, 1, "Exactly one WeaponController instance")
	assert_eq(jam_count, 1, "Exactly one EMJammerController instance")

	# Guard against unimplemented Levels 2-5
	assert_false(stage3.advance_to_next_level(), "advance_to_next_level() returns false (Level 2 deferred)")
	stage3.start_level(2, 12)
	assert_eq(stage3.current_level, 1, "start_level(2) ignored cleanly; remains Level 1")

	stage3.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite C: Final Boss Health & Phase 1 Threshold (800 -> 600 HP)
# ------------------------------------------------------------------------------
func _suite_c_final_boss_health() -> void:
	print("\n--- Running Suite C: Final Boss Health & Phase 1 Threshold ---")

	var stage3 = STAGE3_MAIN_SCENE.instantiate()
	add_child(stage3)
	await get_tree().process_frame

	var boss = stage3.boss
	var threshold_signals: Array = []
	var defeated_signals: Array = []
	var hp_signals: Array = []
	var level_complete_signals: Array = []

	boss.phase_threshold_reached.connect(func(p): threshold_signals.append(p))
	boss.defeated.connect(func(): defeated_signals.append(true))
	boss.health_changed.connect(func(cur, mx): hp_signals.append([cur, mx]))
	stage3.level_completed.connect(func(lvl): level_complete_signals.append(lvl))

	assert_eq(boss.max_health, 800, "FinalBoss max_health is 800")
	assert_eq(boss.health, 800, "FinalBoss starts at 800 HP")
	assert_eq(boss.phase_1_threshold, 600, "Phase 1 threshold is 600 HP")
	assert_eq(boss.get_phase_bounds(1).get("end_hp"), 600, "Phase 1 bounds 800->600")
	assert_eq(boss.get_phase_bounds(2).get("end_hp"), 400, "Phase 2 bounds prepared 600->400")
	assert_eq(boss.get_phase_bounds(3).get("end_hp"), 200, "Phase 3 bounds prepared 400->200")
	assert_eq(boss.get_phase_bounds(4).get("end_hp"), 0, "Phase 4 bounds prepared 200->0")

	# Non-positive damage ignored
	boss.take_damage(0)
	boss.take_damage(-25)
	assert_eq(boss.health, 800, "Zero and negative damage ignored")

	# Take damage above 600 HP
	boss.take_damage(195)
	assert_eq(boss.health, 605, "Boss HP reduced from 800 to 605")
	assert_eq(hp_signals.size(), 1, "health_changed emitted on damage")
	assert_false(boss.phase_1_completed, "Phase 1 still active at 605 HP")
	assert_eq(boss.boss_state, boss.BossState.PHASE_1, "Boss remains in PHASE_1 at 605 HP")

	# Overkill crossing threshold clamps cleanly at 600 HP
	boss.take_damage(50)
	assert_eq(boss.health, 600, "Boss HP clamped at exactly 600 HP (never drops below in Phase 1)")
	assert_true(boss.phase_1_completed, "phase_1_completed set true at 600 HP")
	assert_eq(boss.boss_state, boss.BossState.PHASE_1_COMPLETE, "Boss transitions to PHASE_1_COMPLETE")
	assert_eq(threshold_signals.size(), 1, "phase_threshold_reached emitted once")
	assert_eq(threshold_signals[0], 1, "phase_threshold_reached reports Phase 1")
	assert_false(boss.is_destroyed, "Boss is NOT destroyed at 600 HP")
	assert_eq(defeated_signals.size(), 0, "defeated signal NEVER emitted at 600 HP")

	# No extra damage allowed after Phase 1 completion
	boss.take_damage(100)
	assert_eq(boss.health, 600, "No extra damage allowed after Phase 1 completion")
	assert_eq(threshold_signals.size(), 1, "phase_threshold_reached not re-emitted")

	# Stage3Main completion assertions
	assert_true(stage3.finished, "Stage3Main marked finished")
	assert_true(stage3.game_won, "Stage3Main marked game_won")
	assert_eq(level_complete_signals.size(), 1, "Stage3Main emitted level_completed once")
	assert_eq(level_complete_signals[0], 1, "level_completed emitted Level 1")
	assert_false(stage3.weapon_controller.firing_enabled, "Player weapon firing disabled on Phase 1 completion")
	assert_true(stage3.message.visible, "Completion banner visible")
	assert_true(stage3.message.text.contains("STAGE 3 / LEVEL 1 COMPLETE"), "Banner displays STAGE 3 / LEVEL 1 COMPLETE")
	assert_true(stage3.message.text.contains("BOSS HP: 600 / 800"), "Banner displays BOSS HP: 600 / 800")

	stage3.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite D: Official Artwork & Visual Separation
# ------------------------------------------------------------------------------
func _suite_d_official_artwork() -> void:
	print("\n--- Running Suite D: Official Artwork & Visual Separation ---")

	var boss = FINAL_BOSS_SCENE.instantiate()
	add_child(boss)
	await get_tree().process_frame

	assert_eq(boss.scale, Vector2.ONE, "FinalBoss root physics scale strictly Vector2.ONE")
	assert_true(is_instance_valid(boss.visuals), "Visuals container exists separate from physics root")
	assert_true(is_instance_valid(boss.official_art), "OfficialArt container exists")
	assert_true(boss.official_art.visible, "OfficialArt visible when art is valid")
	assert_false(boss.fallback.visible, "ProceduralFallback suppressed when official art active")

	assert_true(is_instance_valid(boss.phase1_sprite) and boss.phase1_sprite.texture != null, "Phase1Sprite texture loaded")
	assert_true(is_instance_valid(boss.phase2_sprite) and boss.phase2_sprite.texture != null, "Phase2Sprite texture loaded & reserved")
	assert_true(is_instance_valid(boss.phase3_sprite) and boss.phase3_sprite.texture != null, "Phase3Sprite texture loaded & reserved")
	assert_true(is_instance_valid(boss.phase4_sprite) and boss.phase4_sprite.texture != null, "Phase4Sprite texture loaded & reserved")
	assert_true(is_instance_valid(boss.dead_sprite) and boss.dead_sprite.texture != null, "DeadSprite texture loaded & reserved")

	assert_true(boss.phase1_sprite.visible, "Phase1Sprite visible in Phase 1")
	assert_false(boss.phase2_sprite.visible, "Phase2Sprite hidden in Phase 1")
	assert_false(boss.phase3_sprite.visible, "Phase3Sprite hidden in Phase 1")
	assert_false(boss.phase4_sprite.visible, "Phase4Sprite hidden in Phase 1")
	assert_false(boss.dead_sprite.visible, "DeadSprite hidden in Phase 1")

	# Trigger Phase 1 completion -> DeadSprite must remain hidden!
	boss.take_damage(200)
	assert_true(boss.phase1_sprite.visible, "Phase1Sprite remains visible after Phase 1 completion")
	assert_false(boss.dead_sprite.visible, "DeadSprite stays HIDDEN after Phase 1 completion")

	# Aspect ratio & collision geometry checks
	assert_eq(boss.phase1_sprite.scale.x, boss.phase1_sprite.scale.y, "Uniform sprite scale preserves aspect ratio")
	assert_true(boss.collision_shape.shape is RectangleShape2D, "FinalBoss uses RectangleShape2D hull hitbox")
	var rect_shape: RectangleShape2D = boss.collision_shape.shape
	assert_eq(rect_shape.size, Vector2(180.0, 180.0), "FinalBoss hitbox matches 0.36x scaled core housing")

	boss.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite E: Boss AI (Patrol, Windup, Locked Aim Burst, Dodgeable)
# ------------------------------------------------------------------------------
func _suite_e_boss_ai() -> void:
	print("\n--- Running Suite E: Final Boss Phase 1 AI ---")

	var stage3 = STAGE3_MAIN_SCENE.instantiate()
	add_child(stage3)
	await get_tree().process_frame

	var boss = stage3.boss
	var player = stage3.player
	player.position = Vector2(640.0, 560.0)
	boss.position = Vector2(640.0, 160.0)

	# 1. Patrol movement in upper arena region
	var start_x: float = boss.position.x
	boss._physics_process(0.5)
	assert_true(boss.position.x > start_x, "Boss patrols horizontally rightward (65 px/s)")
	assert_eq(boss.position.y, 160.0, "Boss remains in upper arena patrol region (Y = 160)")

	# Reversal at right patrol boundary
	boss.position.x = boss.max_patrol_x - 2.0
	boss.patrol_direction = 1.0
	boss._physics_process(0.1)
	assert_eq(boss.patrol_direction, -1.0, "Boss reverses patrol direction at max_patrol_x")

	# 2. Attack Windup locks target aim (dodgeable!)
	boss.position = Vector2(640.0, 160.0)
	player.global_position = Vector2(640.0, 560.0)
	boss.start_attack_windup()
	assert_eq(boss.attack_state, boss.AttackState.WINDUP, "Boss enters WINDUP attack state")
	var locked_dir: Vector2 = boss.locked_aim_direction
	assert_true(locked_dir.distance_to(Vector2.DOWN) < 0.05, "Locked aim vector targets player's windup position")

	# Player dodges far right AFTER windup locked; burst must stay along locked_dir
	player.global_position = Vector2(1050.0, 560.0)
	var fired_projs: Array = []
	boss.attack_fired.connect(func(p): fired_projs.append(p))
	boss.fire_attack_burst()

	assert_eq(fired_projs.size(), 3, "Phase 1 burst fires 3 projectiles")
	assert_eq(fired_projs[0].speed, 300.0, "Phase 1 projectile speed is 300 px/s")
	assert_eq(fired_projs[0].damage, 1, "Phase 1 projectile deals 1 HP damage")
	assert_true(fired_projs[1].direction.distance_to(locked_dir) < 0.01, "Center projectile fires along windup-locked trajectory (dodgeable)")

	# 3. Completing Phase 1 stops boss movement and attacks
	boss.take_damage(200)
	var stop_x: float = boss.position.x
	boss._physics_process(3.0)
	assert_eq(boss.position.x, stop_x, "Boss patrol movement stops after Phase 1 completion")
	assert_eq(fired_projs.size(), 3, "Boss stops firing attacks after Phase 1 completion")
	assert_eq(boss.current_phase, 1, "No unimplemented boss phases activated")

	stage3.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite F: EM Jammer in Stage 3
# ------------------------------------------------------------------------------
func _suite_f_em_jammer() -> void:
	print("\n--- Running Suite F: EM Jammer Integration in Stage 3 ---")

	# 1. Unacquired EM Jammer is strictly blocked
	var stage3_unearned = STAGE3_MAIN_SCENE.instantiate()
	stage3_unearned.initialize_from_stage2({
		"primary_weapon_acquired": true,
		"shield_acquired": true,
		"em_jammer_acquired": false,
		"em_jammer_cooldown_remaining": 0.0
	})
	add_child(stage3_unearned)
	await get_tree().process_frame
	assert_false(stage3_unearned.em_jammer_controller.activate(), "Unearned EM Jammer activation blocked in Stage 3")
	assert_true(stage3_unearned.jammer_status.text.contains("NOT ACQUIRED"), "HUD displays EM JAMMER: NOT ACQUIRED when unearned")
	stage3_unearned.queue_free()
	await get_tree().process_frame

	# 2. Earned EM Jammer stuns FinalBoss with 0 damage guarantee
	var stage3 = STAGE3_MAIN_SCENE.instantiate()
	add_child(stage3)
	await get_tree().process_frame

	var boss = stage3.boss
	var player = stage3.player
	var jammer = stage3.em_jammer_controller

	player.global_position = Vector2(640.0, 560.0)
	player.rotation = 0.0 # Facing UP toward boss
	boss.global_position = Vector2(640.0, 160.0) # 400 px away, dead ahead inside 120-deg cone

	assert_eq(jammer.cone_angle_degrees, 120.0, "EM Jammer cone remains 120 degrees")

	# Place boss in attack windup to test cancellation
	boss.start_attack_windup()
	assert_eq(boss.attack_state, boss.AttackState.WINDUP, "Boss in WINDUP before stun")

	var did_activate: bool = jammer.activate()
	assert_true(did_activate, "EM Jammer activates cleanly when acquired and aimed")
	assert_true(boss.is_stunned, "FinalBoss is stunned by EM Jammer")
	assert_eq(boss.stun_timer, 10.0, "Stun duration is 10.0 seconds")
	assert_eq(jammer.cooldown_remaining, 30.0, "EM Jammer cooldown is 30.0 seconds")
	assert_eq(boss.health, 800, "EM Jammer stun inflicts ZERO damage to FinalBoss")
	assert_eq(boss.attack_state, boss.AttackState.COOLDOWN, "Boss windup canceled by stun")

	# Duplicate activation during cooldown blocked
	assert_false(jammer.activate(), "Duplicate EM Jammer activation blocked during cooldown")

	# Boss movement & attack halted during stun, but remains vulnerable to player blasters
	var stunned_x: float = boss.position.x
	boss._physics_process(2.0)
	assert_eq(boss.position.x, stunned_x, "Stunned FinalBoss does not patrol")
	boss.take_damage(10)
	assert_eq(boss.health, 790, "Stunned FinalBoss remains vulnerable to player weapon damage")

	# Stun expires after remaining 8.0s and combat resumes
	boss._physics_process(8.0)
	assert_false(boss.is_stunned, "Boss stun expires after full 10.0s")

	# Phase completion cancels active stun while preserving Jammer cooldown
	jammer.cooldown_remaining = 0.0
	jammer.activate()
	assert_true(boss.is_stunned, "Boss re-stunned for threshold check")
	var preserved_cd: float = jammer.cooldown_remaining
	boss.take_damage(190) # 790 -> 600 HP (Phase 1 complete)
	assert_false(boss.is_stunned, "Phase 1 completion clears active stun state cleanly")
	assert_true(jammer.cooldown_remaining >= preserved_cd - 0.5, "EM Jammer cooldown state preserved at Phase 1 completion")

	stage3.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite G: Stage 3 Checkpoint & Deterministic Tie-Breaking
# ------------------------------------------------------------------------------
func _suite_g_checkpoint_and_tiebreak() -> void:
	print("\n--- Running Suite G: Stage 3 Checkpoint & Tie-Breaking ---")

	var stage3 = STAGE3_MAIN_SCENE.instantiate()
	add_child(stage3)
	await get_tree().process_frame

	# Inflict damage to boss, trigger jammer cooldown, spawn temp projectile, then kill player
	stage3.boss.take_damage(100) # 700 HP
	stage3.em_jammer_controller.cooldown_remaining = 22.0
	var temp_proj = PROJECTILE_SCENE.instantiate()
	stage3.projectiles_container.add_child(temp_proj)

	stage3.player.take_damage(12)
	await get_tree().process_frame

	assert_false(stage3.player.alive, "Player died in Stage 3")
	assert_true(stage3.finished, "Stage3 marked finished on death")
	assert_false(stage3.game_won, "Stage3 game_won is false on death")
	assert_false(stage3.weapon_controller.firing_enabled, "Weapon firing disabled on death")
	assert_false(stage3.em_jammer_controller.can_activate(), "EM Jammer blocked on death")
	assert_true(stage3.message.text.contains("STAGE 3 / LEVEL 1"), "Game Over banner references STAGE 3 / LEVEL 1")
	assert_true(stage3.message.text.contains("Stage 3 Checkpoint"), "Game Over banner prompts Stage 3 Checkpoint")

	# Revive at Stage 3 Checkpoint
	stage3.revive_at_stage_checkpoint()
	await get_tree().process_frame

	assert_eq(stage3.stage_number, 3, "Revive stays strictly in Stage 3 (not Stage 2 or Stage 1)")
	assert_eq(stage3.current_level, 1, "Revive restarts strictly at Stage 3 Level 1")
	assert_eq(stage3.player.health, 12, "Player HP restored to 12")
	assert_true(stage3.player.alive, "Player is alive after revive")
	assert_eq(stage3.boss.health, 800, "FinalBoss reset to 800 HP after checkpoint revive")
	assert_eq(stage3.boss.boss_state, stage3.boss.BossState.PHASE_1, "FinalBoss state reset to PHASE_1")
	assert_true(stage3.boss.can_take_damage, "FinalBoss damageable again after revive")
	assert_true(stage3.is_primary_weapon_acquired(), "Primary weapon persists after Stage 3 revive")
	assert_true(stage3.is_shield_acquired(), "Shield persists after Stage 3 revive")
	assert_true(stage3.is_em_jammer_acquired(), "Legitimately earned EM Jammer NOT stripped on Stage 3 revive")
	assert_eq(stage3.em_jammer_controller.cooldown_remaining, 0.0, "Temporary EM Jammer cooldown reset on fresh Stage 3 run")
	assert_eq(stage3.projectiles_container.get_child_count(), 0, "Projectiles cleared on checkpoint revive")

	# Deterministic Tie-Breaking: Player dies BEFORE boss threshold
	stage3.player.take_damage(12)
	stage3.boss.take_damage(200) # Hits 600 after player death
	assert_false(stage3.game_won, "Tie-break 1: Player loss stands if death occurred first")

	# Deterministic Tie-Breaking: Boss Phase 1 complete BEFORE player death
	stage3.revive_at_stage_checkpoint()
	await get_tree().process_frame
	stage3.boss.take_damage(200) # Reaches 600 first
	stage3.player.take_damage(12)
	assert_true(stage3.game_won, "Tie-break 2: Phase 1 victory stands if finalized first")

	stage3.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite H: Real Physics Engine Overlap Verification
# ------------------------------------------------------------------------------
func _suite_h_real_physics() -> void:
	print("\n--- Running Suite H: Real Physics Engine Overlap Verification ---")

	var stage3 = STAGE3_MAIN_SCENE.instantiate()
	add_child(stage3)
	await get_tree().process_frame

	var boss = stage3.boss
	var player = stage3.player
	boss.global_position = Vector2(640.0, 160.0)
	player.global_position = Vector2(640.0, 560.0)

	# 1. Player projectile overlaps FinalBoss
	var proj = PROJECTILE_SCENE.instantiate()
	var proj_hits: Array = []
	proj.hit.connect(func(target): proj_hits.append(target))
	stage3.projectiles_container.add_child(proj)
	proj.global_position = boss.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_eq(boss.health, 799, "Real physics: Player projectile dealt 1 damage to FinalBoss (800 -> 799)")
	assert_eq(proj_hits.size(), 1, "Projectile emitted hit signal exactly once")

	# 2. Enemy projectile overlaps Player
	var e_proj = ENEMY_PROJECTILE_SCENE.instantiate()
	var e_hits: Array = []
	e_proj.hit.connect(func(target): e_hits.append(target))
	stage3.enemy_projectiles_container.add_child(e_proj)
	e_proj.global_position = player.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_eq(player.health, 11, "Real physics: Enemy projectile dealt 1 damage to Player (12 -> 11)")
	assert_eq(e_hits.size(), 1, "Enemy projectile emitted hit signal once")

	# 3. Enemy projectile friendly-fire immunity on FinalBoss
	var ff_proj = ENEMY_PROJECTILE_SCENE.instantiate()
	var ff_hits: Array = []
	ff_proj.hit.connect(func(target): ff_hits.append(target))
	stage3.enemy_projectiles_container.add_child(ff_proj)
	ff_proj.global_position = boss.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_eq(boss.health, 799, "Real physics: Enemy projectile ignored FinalBoss (Friendly Fire Immunity)")
	assert_eq(ff_hits.size(), 0, "Friendly-fire projectile emitted 0 hit signals")
	if is_instance_valid(ff_proj):
		ff_proj.queue_free()

	# 4. Collision stops after Phase 1 completion (600 HP)
	boss.take_damage(199) # Drops to 600
	await get_tree().physics_frame
	assert_false(boss.monitoring, "FinalBoss monitoring disabled after Phase 1 completion")
	assert_false(boss.monitorable, "FinalBoss monitorable disabled after Phase 1 completion")

	var post_proj = PROJECTILE_SCENE.instantiate()
	var post_hits: Array = []
	post_proj.hit.connect(func(target): post_hits.append(target))
	stage3.projectiles_container.add_child(post_proj)
	post_proj.global_position = boss.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_eq(boss.health, 600, "No damage from post-Phase-1 projectile")
	assert_eq(post_hits.size(), 0, "Post-Phase-1 projectile does not collide with inactive boss")
	if is_instance_valid(post_proj):
		post_proj.queue_free()

	stage3.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------------------
# Suite I: Full Stage 1-2 Integration Audit & System Safety
# ------------------------------------------------------------------------------
func _suite_i_stage1_2_integration_audit() -> void:
	print("\n--- Running Suite I: Full Stage 1-2 Integration Audit & System Safety ---")

	# 1. Stage 1 L1 -> L5 progression audit (HP preserved within stage, gear granted at L3)
	var main1 = MAIN_SCENE.instantiate()
	add_child(main1)
	await get_tree().process_frame

	main1.start_level(1, 9)
	main1.time_remaining = 0.0
	main1._complete_level()
	main1.advance_to_next_level() # L2
	assert_eq(main1.current_level, 2, "Audit S1: Advanced L1 -> L2")
	assert_eq(main1.player.health, 9, "Audit S1: Remaining 9 HP preserved into L2")

	main1.time_remaining = 0.0
	main1._complete_level()
	main1.advance_to_next_level() # L3
	assert_eq(main1.current_level, 3, "Audit S1: Advanced L2 -> L3")
	assert_eq(main1.player.health, 9, "Audit S1: Remaining 9 HP preserved into L3")

	main1.time_remaining = 0.0
	main1._complete_level() # Complete L3 -> Weapon & Shield acquired
	assert_true(main1.is_primary_weapon_acquired(), "Audit S1: Primary weapon granted at L3")
	assert_true(main1.is_shield_acquired(), "Audit S1: Shield granted at L3")

	main1.advance_to_next_level() # L4
	main1.time_remaining = 0.0
	main1._complete_level()
	main1.advance_to_next_level() # L5
	assert_eq(main1.current_level, 5, "Audit S1: Advanced to L5")
	assert_eq(main1.player.health, 9, "Audit S1: Remaining 9 HP preserved into L5")
	main1.time_remaining = 0.0
	main1._complete_level()

	# Stage 1 Checkpoint Audit
	main1.revive_at_stage_checkpoint()
	assert_eq(main1.stage_number, 1, "Audit S1 Checkpoint stays in Stage 1")
	assert_eq(main1.current_level, 1, "Audit S1 Checkpoint returns to Level 1")

	# Re-complete Stage 1 L5 for Stage 2 transition audit
	main1.start_level(5, 6)
	main1.stage_acquisitions["primary_weapon_acquired"] = true
	main1.stage_acquisitions["shield_acquired"] = true
	main1.time_remaining = 0.0
	main1._complete_level()
	var stage2 = main1.advance_to_stage_2()
	main1.queue_free()
	add_child(stage2)
	await get_tree().process_frame

	assert_eq(stage2.stage_number, 2, "Audit S1->S2: Stage 2 initialized")
	assert_eq(stage2.player.health, 12, "Audit S1->S2: HP restored to 12 on Stage 2 start")

	# 2. Stage 2 L1 -> L3 progression audit (within-stage HP preserved)
	stage2.start_level(1, 8)
	stage2.time_remaining = 0.0
	stage2._complete_level()
	stage2.advance_to_next_level() # S2 L2
	assert_eq(stage2.player.health, 8, "Audit S2: Remaining 8 HP preserved L1 -> L2")
	stage2.time_remaining = 0.0
	stage2._complete_level()
	stage2.advance_to_next_level() # S2 L3
	assert_eq(stage2.player.health, 8, "Audit S2: Remaining 8 HP preserved L2 -> L3")

	# Complete 5 drone kills in S2 L3 -> EM Jammer acquired
	for _k in range(5):
		stage2._on_drone_defeated(0, null)
	assert_true(stage2.is_em_jammer_acquired(), "Audit S2: EM Jammer granted at S2 L3")

	# S2 L3 -> L4 transition (BossArena) preserves 8 HP
	var arena = stage2.advance_to_next_level()
	stage2.queue_free()
	add_child(arena)
	await get_tree().process_frame

	assert_eq(arena.player.health, 8, "Audit S2 L3->L4: Remaining 8 HP preserved into BossArena")
	var cruiser_id: int = arena.boss.get_instance_id()
	arena.boss.take_damage(200)
	arena.advance_to_next_level() # L5
	assert_eq(arena.boss.get_instance_id(), cruiser_id, "Audit S2: Guard Cruiser single instance across Phase 1 & 2")
	assert_eq(arena.player.health, 8, "Audit S2 L4->L5: Remaining 8 HP preserved into Phase 2")
	arena.boss.take_damage(200)
	assert_true(arena.is_stage2_completed(), "Audit S2: Stage 2 completion triggered cleanly")

	# Check Stage 2 Checkpoint isolation
	var s2_revive = arena.revive_at_stage_checkpoint()
	arena.queue_free()
	assert_true(is_instance_valid(s2_revive), "Audit S2 Checkpoint returned Stage 2 coordinator")
	s2_revive.queue_free()

	# 3. Level Select lock verification
	var level_select = LEVEL_SELECT_SCENE.instantiate()
	add_child(level_select)
	await get_tree().process_frame

	assert_eq(level_select.level_buttons.size(), 15, "Audit UI: All 15 level buttons registered")
	assert_true(level_select.is_level_playable(1, 1), "Audit UI: S1 L1 playable")
	assert_false(level_select.is_level_playable(3, 1), "Audit UI: Stage 3 Level 1 remains LOCKED in Level Select")
	assert_false(level_select.is_level_playable(3, 2), "Audit UI: Stage 3 Level 2 remains LOCKED in Level Select")
	level_select.queue_free()

	# 4. Protected player interface constraint check
	var stage3_check = STAGE3_MAIN_SCENE.instantiate()
	add_child(stage3_check)
	await get_tree().process_frame
	assert_false(stage3_check.player.has_method("shoot"), "Protected Player preserves no shoot() method")
	assert_false(stage3_check.player.has_method("fire"), "Protected Player preserves no fire() method")
	assert_false(stage3_check.player.has_method("activate_em_jammer"), "Protected Player preserves no direct activate_em_jammer() method")
	stage3_check.queue_free()
	await get_tree().process_frame


func _print_summary() -> void:
	print("\n==================================================")
	print("MILESTONE 11 TEST EXECUTION SUMMARY")
	print("==================================================")
	print("Total assertions: %d" % total_count)
	print("Passed:           %d" % pass_count)
	print("Failed:           %d" % fail_count)
	print("VERDICT: %s" % ("ALL TESTS PASSED (100%)" if fail_count == 0 else "TEST SUITE FAILED"))
	print("==================================================")
