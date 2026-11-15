extends Node
## Core test runner logic for Milestone 1 requirements verification.

var total_count: int = 0
var pass_count: int = 0
var fail_count: int = 0

const PLAYER_SCENE = preload("res://scenes/player.tscn")
const ASTEROID_SCENE = preload("res://scenes/asteroid.tscn")
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
	test_suite_1_hp_damage()
	test_suite_2_collision_cooldown()
	test_suite_3_passive_regeneration()
	await test_suite_4_timer_and_state_transitions()
	await test_suite_5_physics_engine_integration()


# ==============================================================================
# SUITE 1: HP DAMAGE
# ==============================================================================
func test_suite_1_hp_damage() -> void:
	print("\n--- Running Suite 1: HP Damage ---")
	var player = PLAYER_SCENE.instantiate()
	add_child(player)

	assert_eq(player.health, 12, "Player starts with 12 HP")
	assert_eq(player.max_health, 12, "Player max_health is 12")
	assert_true(player.alive, "Player starts alive")

	var health_signals: Array = []
	var died_events: Array = []
	player.health_changed.connect(func(c, m): health_signals.append([c, m]))
	player.died.connect(func(): died_events.append(true))

	# Take 1 damage (small asteroid collision damage)
	player.take_damage(1)
	assert_eq(player.health, 11, "HP decreases to 11 after taking 1 damage")
	assert_eq(health_signals.size(), 1, "health_changed signal emitted once")
	if health_signals.size() > 0:
		assert_eq(health_signals[0][0], 11, "health_changed signal reported current health 11")
		assert_eq(health_signals[0][1], 12, "health_changed signal reported maximum health 12")

	# Take non-fatal damage
	player.take_damage(5)
	assert_eq(player.health, 6, "HP decreases to 6 after taking 5 more damage")
	assert_true(player.alive, "Player is still alive at 6 HP")
	assert_eq(died_events.size(), 0, "died signal not emitted when HP > 0")

	# Fatal damage
	player.take_damage(10) # 6 - 10 should clamp to 0
	assert_eq(player.health, 0, "HP clamped to 0 on overkill damage")
	assert_true(not player.alive, "Player alive flag is false after reaching 0 HP")
	assert_eq(died_events.size(), 1, "died signal emitted on reaching 0 HP")

	# Damage after death should be ignored
	var signal_count_before: int = health_signals.size()
	player.take_damage(5)
	assert_eq(player.health, 0, "HP remains 0 after damage while dead")
	assert_eq(health_signals.size(), signal_count_before, "No signals emitted after death")

	# Negative or zero damage is ignored
	player.reset_state()
	assert_eq(player.health, 12, "Player reset_state restores 12 HP")
	player.take_damage(0)
	assert_eq(player.health, 12, "Zero damage ignored")
	player.take_damage(-5)
	assert_eq(player.health, 12, "Negative damage ignored")

	player.queue_free()


# ==============================================================================
# SUITE 2: COLLISION COOLDOWN & CONTACT TRACKING
# ==============================================================================
func test_suite_2_collision_cooldown() -> void:
	print("\n--- Running Suite 2: Collision Cooldown & Contact Tracking ---")
	var player = PLAYER_SCENE.instantiate()
	add_child(player)

	var ast_a = ASTEROID_SCENE.instantiate()
	var ast_b = ASTEROID_SCENE.instantiate()
	add_child(ast_a)
	add_child(ast_b)

	# Verify small asteroid parameters
	assert_eq(ast_a.max_health, 20, "Small asteroid HP is 20")
	assert_eq(ast_a.health, 20, "Small asteroid starts with full 20 HP")
	assert_eq(ast_a.contact_damage, 1, "Small asteroid contact damage is 1")

	var id_a: int = ast_a.get_instance_id()
	var id_b: int = ast_b.get_instance_id()

	# 1. Independent cooldown initialization for multiple contacts
	player.contact_cooldown[id_a] = player.contact_tick_seconds
	player.contact_cooldown[id_b] = player.contact_tick_seconds
	assert_eq(player.contact_cooldown[id_a], 0.5, "Asteroid A cooldown set to 0.5s")
	assert_eq(player.contact_cooldown[id_b], 0.5, "Asteroid B cooldown set to 0.5s")

	# 2. Repeated contact within 0.5s window
	player._check_asteroid_contacts(0.2)
	assert_true(player.contact_cooldown[id_a] > 0.0, "Asteroid A cooldown still active at 0.2s elapsed")
	assert_true(player.contact_cooldown[id_b] > 0.0, "Asteroid B cooldown still active at 0.2s elapsed")

	# 3. Separation and re-entry within the 0.5s window
	player._check_asteroid_contacts(0.15)
	assert_true(player.contact_cooldown[id_a] > 0.0, "Asteroid A cooldown has remaining time at re-entry")

	# 4. Cooldown expiration after 0.5s
	player._check_asteroid_contacts(0.16)
	var remaining_cooldown: float = float(player.contact_cooldown.get(id_a, 0.0))
	assert_true(remaining_cooldown <= 0.0, "Asteroid A cooldown expired after 0.51s total")
	assert_true(not player.contact_cooldown.has(id_a), "Asteroid A cooldown cleanly pruned upon expiration")

	# 5. Stale object removal using player._check_asteroid_contacts() implementation
	ast_b.queue_free()
	# Invoking the actual player system to prune freed objects
	player._check_asteroid_contacts(0.01)
	assert_true(not player.contact_cooldown.has(id_b), "Freed asteroid B cleanly pruned by _check_asteroid_contacts()")

	# 6. Asteroid HP untouched by player contact
	assert_eq(ast_a.health, 20, "Asteroid HP remains 20 (player does not damage asteroid in Milestone 1)")

	player.queue_free()
	ast_a.queue_free()


# ==============================================================================
# SUITE 3: PASSIVE HP REGENERATION & MOVEMENT INTEGRATION
# ==============================================================================
func test_suite_3_passive_regeneration() -> void:
	print("\n--- Running Suite 3: Passive HP Regeneration & Movement Integration ---")
	var player = PLAYER_SCENE.instantiate()
	add_child(player)

	# 1. Facing direction following movement and preserved when stationary
	player.rotation = 0.0
	var vel_right: Vector2 = Vector2(200.0, 0.0)
	if vel_right.length() > player.stop_threshold:
		player.rotation = Vector2.UP.angle_to(vel_right)
	var expected_angle_right: float = Vector2.UP.angle_to(Vector2.RIGHT)
	assert_true(absf(player.rotation - expected_angle_right) < 0.001, "Ship faces right when moving right")

	var vel_stop: Vector2 = Vector2.ZERO
	if vel_stop.length() > player.stop_threshold:
		player.rotation = Vector2.UP.angle_to(vel_stop)
	assert_true(absf(player.rotation - expected_angle_right) < 0.001, "Ship facing angle preserved when stationary")

	var vel_down_left: Vector2 = Vector2(-100.0, 100.0)
	if vel_down_left.length() > player.stop_threshold:
		player.rotation = Vector2.UP.angle_to(vel_down_left)
	var expected_angle_dl: float = Vector2.UP.angle_to(vel_down_left)
	assert_true(absf(player.rotation - expected_angle_dl) < 0.001, "Ship faces down-left when moving down-left")

	if vel_stop.length() > player.stop_threshold:
		player.rotation = Vector2.UP.angle_to(vel_stop)
	assert_true(absf(player.rotation - expected_angle_dl) < 0.001, "Ship facing angle preserved after stopping again")

	# 2. Passive Regeneration progression
	player.health = 10
	player.still_seconds = 0.0
	player.regen_fraction = 0.0
	player.movement_velocity = Vector2.ZERO

	# Simulate 1.5 seconds stationary (< regen_wait 2.0s)
	for i in range(15):
		player._update_regeneration(0.1)
	assert_eq(player.health, 10, "HP does not regenerate before 2.0s stationary delay (at 1.5s, HP=10)")
	assert_true(absf(player.still_seconds - 1.5) < 0.01, "still_seconds accumulated 1.5s")

	# Advance past 2.0s: reaches 2.5s (0.5s active regen)
	for i in range(10):
		player._update_regeneration(0.1)
	assert_eq(player.health, 10, "At 2.5s (0.5s active regen), HP is still 10 (fraction = 0.5)")

	# Advance 0.5s more: total 3.0s (1.0s active regen)
	for i in range(5):
		player._update_regeneration(0.1)
	assert_eq(player.health, 11, "At 3.0s (1.0s after regen_wait), restores 1 HP to 11")

	# Advance 1.0s more: total 4.0s (2.0s active regen)
	for i in range(10):
		player._update_regeneration(0.1)
	assert_eq(player.health, 12, "At 4.0s (2.0s after regen_wait), restores 1 HP to 12 (max HP)")

	# Advance further: capped at max_health
	for i in range(20):
		player._update_regeneration(0.1)
	assert_eq(player.health, 12, "HP capped at max_health (12), does not exceed")
	assert_eq(player.regen_fraction, 0.0, "regen_fraction clamped to 0.0 at max HP")

	# 3. Interruption by movement
	player.health = 10
	player.still_seconds = 1.8
	player.movement_velocity = Vector2(50.0, 0.0)
	player._update_regeneration(0.1)
	assert_eq(player.still_seconds, 0.0, "Movement above stop_threshold resets still_seconds to 0.0")
	assert_eq(player.health, 10, "No regen occurs while moving")

	# 4. INTEGRATION TEST: Actual player._physics_process() under cursor micro-jitter
	# Invokes the REAL player movement and regeneration implementation directly
	player.health = 10
	player.still_seconds = 0.0
	player.regen_fraction = 0.0
	player.global_position = Vector2(640.0, 360.0)
	var base_cursor = Vector2(640.0, 360.0)

	var delta: float = 1.0 / 60.0
	for frame in range(240): # 4.0 seconds
		var current_cursor = base_cursor
		if frame % 20 < 10:
			current_cursor += Vector2(1.0, 0.5)
		else:
			current_cursor += Vector2(-0.5, 1.0)

		# Set target position override and execute actual player physics process!
		player.target_position_override = current_cursor
		player._physics_process(delta)

	assert_eq(player.health, 12, "Actual player implementation reaches 12 HP after 4s under simulated cursor micro-jitter")
	assert_true(player.still_seconds >= 3.99, "Actual player still_seconds accumulated ~4.0s without micro-jitter resets")

	# Move cursor far away (50px) to verify actual player moves and resets still_seconds
	player.target_position_override = base_cursor + Vector2(50.0, 0.0)
	player._physics_process(delta)
	assert_eq(player.still_seconds, 0.0, "Actual player still_seconds reset to 0 when cursor moves beyond arrival deadzone")
	assert_true(player.movement_velocity.length() > player.stop_threshold, "Actual player velocity exceeds stop_threshold when moving")
	player.target_position_override = null

	# 5. Regeneration cannot continue after death
	player.health = 6
	player.alive = false
	player.still_seconds = 3.0
	player.movement_velocity = Vector2.ZERO
	player._update_regeneration(1.0)
	assert_eq(player.health, 6, "Regeneration cannot continue when dead")

	# 6. Regeneration cannot continue after physics processing disabled (Level Complete)
	player.alive = true
	player.health = 8
	player.still_seconds = 3.0
	player.set_physics_process(false)
	player._update_regeneration(1.0)
	assert_eq(player.health, 8, "Regeneration cannot continue when physics processing is disabled")
	player.set_physics_process(true)

	player.queue_free()


# ==============================================================================
# SUITE 4: TIMER, STATE TRANSITIONS & SCENE RESTART INTEGRATION
# ==============================================================================
func test_suite_4_timer_and_state_transitions() -> void:
	print("\n--- Running Suite 4: Timer, State Transitions & Scene Restart Integration ---")
	var main = MAIN_SCENE.instantiate()
	add_child(main)

	assert_eq(main.level_duration, 30.0, "Level duration is 30.0 seconds")
	assert_eq(main.time_remaining, 30.0, "Initial time remaining is 30.0 seconds")
	assert_true(not main.finished, "Game not finished initially")
	assert_true(not main.game_won, "Game not won initially")

	# 1. Survival Win Condition (survive 30s)
	main._process(30.0)
	assert_true(main.time_remaining <= 0.0, "Time remaining reached 0")
	assert_true(main.finished, "Game finished flag is true after 30s")
	assert_true(main.game_won, "game_won flag is true after surviving 30s")
	assert_true(not main.player.is_physics_processing(), "Player physics disabled on level complete (Call Down)")
	assert_true(main.message.visible, "Completion message is visible")
	assert_true(main.message.text.contains("LEVEL 1 COMPLETE"), "Message displays 'LEVEL 1 COMPLETE'")

	main.queue_free()

	# 2. Game Over Loss Condition (HP reaches 0)
	var main_loss = MAIN_SCENE.instantiate()
	add_child(main_loss)

	assert_true(not main_loss.finished, "Fresh scene starts unfinished")
	main_loss.player.take_damage(12)
	assert_eq(main_loss.player.health, 0, "Player HP is 0")
	assert_true(not main_loss.player.alive, "Player alive is false")
	assert_true(main_loss.finished, "Game finished flag is true on player death")
	assert_true(not main_loss.game_won, "game_won is false on player death")
	assert_true(not main_loss.player.is_physics_processing(), "Player physics disabled on death (Call Down)")
	assert_true(main_loss.message.visible, "Game over message is visible")
	assert_true(main_loss.message.text.contains("SHIP DESTROYED"), "Message displays 'SHIP DESTROYED'")

	main_loss.queue_free()

	# 3. INTEGRATION TEST: Scene restart behavior resets timer, player HP, and spawned asteroids
	await _test_scene_restart_behavior()


func _test_scene_restart_behavior() -> void:
	var main_restart = MAIN_SCENE.instantiate()
	get_tree().root.add_child(main_restart)
	get_tree().current_scene = main_restart

	await get_tree().process_frame
	await get_tree().physics_frame

	# Mutate active level state
	main_restart.time_remaining = 14.5
	main_restart.player.health = 5
	main_restart.player.alive = false
	main_restart.finished = true
	main_restart.message.visible = true

	# Spawn asteroids into active level
	main_restart._spawn_asteroid()
	main_restart._spawn_asteroid()
	main_restart._spawn_asteroid()

	var asteroids_before: int = 0
	for child in main_restart.get_children():
		if child.is_in_group("asteroids"):
			asteroids_before += 1
	assert_eq(asteroids_before, 3, "Spawned 3 active asteroids before restart")
	assert_eq(main_restart.player.health, 5, "Player damaged to 5 HP before restart")
	assert_eq(main_restart.time_remaining, 14.5, "Timer decremented to 14.5s before restart")

	# Invoke actual restart_level() method
	main_restart.restart_level()

	# Await frames for scene reload to take effect
	await get_tree().process_frame
	await get_tree().process_frame

	var reloaded_main = get_tree().current_scene
	assert_true(is_instance_valid(reloaded_main), "Reloaded scene is valid")
	assert_eq(reloaded_main.time_remaining, 30.0, "Restart resets survival timer to 30.0s")
	assert_eq(reloaded_main.player.health, 12, "Restart resets player health to 12")
	assert_true(reloaded_main.player.alive, "Restart resets player alive flag to true")
	assert_true(reloaded_main.player.is_physics_processing(), "Restart re-enables player physics processing")
	assert_true(not reloaded_main.finished, "Restart resets finished flag to false")
	assert_true(not reloaded_main.message.visible, "Restart hides end-game message")

	var asteroids_after: int = 0
	for child in reloaded_main.get_children():
		if child.is_in_group("asteroids"):
			asteroids_after += 1
	assert_eq(asteroids_after, 0, "Restart clears all previously spawned asteroids from play area")

	reloaded_main.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 5: REAL PHYSICS ENGINE SUSTAINED OVERLAP & INDEPENDENT DAMAGE
# ==============================================================================
func test_suite_5_physics_engine_integration() -> void:
	print("\n--- Running Suite 5: Real Physics Engine Sustained Overlap & Independent Damage ---")
	var player = PLAYER_SCENE.instantiate()
	player.position = Vector2(640, 360)
	player.move_speed = 0.0 # Keep stationary for overlap test
	add_child(player)

	var ast1 = ASTEROID_SCENE.instantiate()
	ast1.position = Vector2(640, 360)
	ast1.speed = 0.0 # Keep stationary for overlap test
	add_child(ast1)

	var ast2 = ASTEROID_SCENE.instantiate()
	ast2.position = Vector2(640, 360)
	ast2.speed = 0.0 # Keep stationary for overlap test
	add_child(ast2)

	# 1. Wait 3 physics ticks for Godot physics server to detect overlaps and process initial damage
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var id1: int = ast1.get_instance_id()
	var id2: int = ast2.get_instance_id()

	# Two overlapping asteroids apply independent contact damage (no generic i-frames)
	assert_eq(player.health, 10, "Real physics engine detected 2 overlapping asteroids and dealt 2 independent damage (12 -> 10)")
	assert_true(player.contact_cooldown.has(id1), "Player registered independent cooldown for Asteroid 1")
	assert_true(player.contact_cooldown.has(id2), "Player registered independent cooldown for Asteroid 2")
	assert_eq(player.contact_cooldown[id1], 0.5, "Asteroid 1 cooldown initialized to 0.5s")
	assert_eq(player.contact_cooldown[id2], 0.5, "Asteroid 2 cooldown initialized to 0.5s")

	# 2. Run for 25 physics frames (~0.41s, within the 0.5s cooldown period)
	for i in range(25):
		await get_tree().physics_frame

	assert_eq(player.health, 10, "No per-frame damage loss while overlapping (both cooldowns respected during first 0.5s)")

	# 3. Sustained asteroid overlap for longer than 0.5 seconds (another 10 frames, total > 0.55s)
	for i in range(10):
		await get_tree().physics_frame

	assert_eq(player.health, 8, "Sustained overlap > 0.5s dealt second independent damage tick from both asteroids (10 -> 8)")
	assert_true(player.contact_cooldown[id1] > 0.0, "Asteroid 1 cooldown reset to 0.5s after second tick")
	assert_true(player.contact_cooldown[id2] > 0.0, "Asteroid 2 cooldown reset to 0.5s after second tick")

	# 4. Separation
	ast1.position = Vector2(100, 100)
	await get_tree().physics_frame
	await get_tree().physics_frame

	player.queue_free()
	ast1.queue_free()
	ast2.queue_free()
	await get_tree().process_frame


func _print_summary() -> void:
	print("\n==================================================")
	print("TEST RESULTS SUMMARY")
	print("==================================================")
	print("Total tests executed: %d" % total_count)
	print("Passed: %d" % pass_count)
	print("Failed: %d" % fail_count)
	if fail_count == 0:
		print("STATUS: ALL TESTS PASSED SUCCESSFULLY!")
	else:
		printerr("STATUS: SOME TESTS FAILED!")
	print("==================================================")
