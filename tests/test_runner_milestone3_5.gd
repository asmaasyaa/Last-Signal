extends Node
## Test runner logic for Milestone 3.5 (Asset Integration Readiness).
## Validates Visuals presentation subtree isolation, fallback rendering,
## sprite drop-in auto-detection, collision independence, and zero gameplay regression.

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
	print("==================================================")
	print("LAST SIGNAL — Milestone 3.5 Automated Test Suite")
	print("==================================================")
	await test_suite_1_player_visual_isolation_and_gameplay_immunity()
	await test_suite_2_asteroid_visual_isolation_and_tier_integrity()
	await test_suite_3_sprite_replacement_and_fallback_toggling()
	await test_suite_4_node_resilience_and_missing_resource_safety()


# ==============================================================================
# SUITE 1: PLAYER VISUAL ISOLATION & GAMEPLAY IMMUNITY
# ==============================================================================
func test_suite_1_player_visual_isolation_and_gameplay_immunity() -> void:
	print("\n--- Running Suite 1: Player Visual Isolation & Gameplay Immunity ---")
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame

	# 1. Structural hierarchy checks
	var visuals: Node2D = player.get_node_or_null("Visuals")
	assert_true(is_instance_valid(visuals), "Player contains 'Visuals' presentation container node")
	assert_true(visuals is Node2D, "Visuals container is a Node2D")
	assert_eq(visuals.scale, Vector2.ONE, "Visuals node scale is Vector2.ONE (no transform distortion)")

	var fallback: Node2D = visuals.get_node_or_null("ProceduralFallback")
	assert_true(is_instance_valid(fallback), "Visuals contains 'ProceduralFallback' child node")
	assert_true(fallback.visible, "ProceduralFallback is visible by default when no sprite is present")

	var ship_body = fallback.get_node_or_null("ShipBody")
	var engine_glow = fallback.get_node_or_null("EngineGlow")
	assert_true(is_instance_valid(ship_body) and ship_body is Polygon2D, "ShipBody Polygon2D is encapsulated inside ProceduralFallback")
	assert_true(is_instance_valid(engine_glow) and engine_glow is Polygon2D, "EngineGlow Polygon2D is encapsulated inside ProceduralFallback")

	# 2. Physics & collision boundaries intact
	var col_shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D")
	assert_true(is_instance_valid(col_shape), "CollisionShape2D remains direct child of Player root")
	assert_true(col_shape.shape is CircleShape2D, "Collision shape is CircleShape2D")
	assert_eq(col_shape.shape.radius, 20.0, "Player collision radius remains exactly 20.0 px")
	assert_eq(player.collision_layer, 1, "Player collision_layer remains 1 (Layer 1: Player)")
	assert_eq(player.collision_mask, 2, "Player collision_mask remains 2 (Layer 2: Hazards)")
	assert_eq(player.scale, Vector2.ONE, "Player root node scale is Vector2.ONE")

	# 3. Gameplay immunity: Visual node state does not influence health or damage
	var hp_signal_fired: Array = [false]
	player.health_changed.connect(func(_c, _m): hp_signal_fired[0] = true)

	# Hide visuals completely
	visuals.visible = false
	player.take_damage(3)
	assert_eq(player.health, 9, "Player takes damage normally when Visuals node is hidden (12 -> 9)")
	assert_true(hp_signal_fired[0], "health_changed signal emits normally when Visuals is hidden")

	# 4. Movement and facing direction immunity
	player.global_position = Vector2(640, 360)
	player.target_position_override = Vector2(740, 360) # Move directly RIGHT
	player._physics_process(0.016)
	assert_true(player.movement_velocity.x > 0.0, "Player updates movement velocity when Visuals is hidden")
	assert_eq(snappedf(player.rotation, 0.01), snappedf(PI * 0.5, 0.01), "Player facing direction rotates to PI/2 (Right) when moving")

	# Stop moving
	player.target_position_override = player.global_position
	player._physics_process(0.016)
	assert_eq(snappedf(player.rotation, 0.01), snappedf(PI * 0.5, 0.01), "Player facing angle preserved when stationary with hidden visuals")

	# 5. Passive HP regeneration immunity
	player.health = 10
	player.still_seconds = 2.5
	player._physics_process(1.0)
	assert_eq(player.health, 11, "Player passive HP regeneration functions normally when Visuals is hidden (10 -> 11)")

	player.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 2: ASTEROID VISUAL ISOLATION & TIER INTEGRITY
# ==============================================================================
func test_suite_2_asteroid_visual_isolation_and_tier_integrity() -> void:
	print("\n--- Running Suite 2: Asteroid Visual Isolation & Tier Integrity ---")
	var ast_s = ASTEROID_SCENE.instantiate()
	var ast_m = ASTEROID_SCENE.instantiate()
	var ast_l = ASTEROID_SCENE.instantiate()
	add_child(ast_s)
	add_child(ast_m)
	add_child(ast_l)

	ast_s.set_size_tier(ast_s.AsteroidSize.SMALL)
	ast_m.set_size_tier(ast_m.AsteroidSize.MEDIUM)
	ast_l.set_size_tier(ast_l.AsteroidSize.LARGE)
	await get_tree().process_frame

	# 1. Structural hierarchy checks
	var visuals_s: Node2D = ast_s.get_node_or_null("Visuals")
	var visuals_m: Node2D = ast_m.get_node_or_null("Visuals")
	var visuals_l: Node2D = ast_l.get_node_or_null("Visuals")

	assert_true(is_instance_valid(visuals_s), "Small asteroid contains 'Visuals' presentation container")
	assert_true(is_instance_valid(visuals_m), "Medium asteroid contains 'Visuals' presentation container")
	assert_true(is_instance_valid(visuals_l), "Large asteroid contains 'Visuals' presentation container")

	var fallback_s: Node2D = visuals_s.get_node_or_null("ProceduralFallback")
	assert_true(is_instance_valid(fallback_s), "Asteroid Visuals contains 'ProceduralFallback' node")
	assert_true(fallback_s.has_method("set_geometry"), "ProceduralFallback encapsulates canvas drawing with set_geometry()")
	assert_true(fallback_s.visible, "ProceduralFallback is visible by default")

	# 2. Verify NO duplicate drawing on root Asteroid
	assert_true(not ast_s.has_method("_draw"), "Asteroid root node has NO _draw() method (avoids duplicate visuals)")

	# 3. Collision shape and tier properties preserved identically
	assert_eq(ast_s.max_health, 20, "Small asteroid HP remains 20")
	assert_eq(ast_s.contact_damage, 1, "Small asteroid contact damage remains 1")
	assert_eq(ast_m.max_health, 40, "Medium asteroid HP remains 40")
	assert_eq(ast_m.contact_damage, 2, "Medium asteroid contact damage remains 2")
	assert_eq(ast_l.max_health, 80, "Large asteroid HP remains 80")
	assert_eq(ast_l.contact_damage, 4, "Large asteroid contact damage remains 4")

	var shape_s = ast_s.get_node("CollisionShape2D").shape
	var shape_m = ast_m.get_node("CollisionShape2D").shape
	var shape_l = ast_l.get_node("CollisionShape2D").shape

	assert_eq(shape_s.radius, 19.0, "Small asteroid collision radius is 19.0 px")
	assert_eq(shape_m.radius, 35.0, "Medium asteroid collision radius is 35.0 px")
	assert_eq(shape_l.radius, 65.0, "Large asteroid collision radius is 65.0 px")

	# 4. Ensure shape unshared independence and no double scaling
	assert_true(shape_s != shape_m and shape_m != shape_l, "Asteroids own unshared CircleShape2D instances")
	assert_eq(ast_s.scale, Vector2.ONE, "Small asteroid scale remains Vector2.ONE")
	assert_eq(ast_m.scale, Vector2.ONE, "Medium asteroid scale remains Vector2.ONE")
	assert_eq(ast_l.scale, Vector2.ONE, "Large asteroid scale remains Vector2.ONE")
	assert_eq(visuals_s.scale, Vector2.ONE, "Visuals container scale remains Vector2.ONE")

	# 5. Spin and movement loop integrity
	var init_y: float = ast_s.position.y
	ast_s.speed = 200.0
	ast_s._physics_process(0.1)
	assert_eq(snappedf(ast_s.position.y - init_y, 0.1), 20.0, "Asteroid moves down at speed * delta (20 px in 0.1s)")

	ast_s.queue_free()
	ast_m.queue_free()
	ast_l.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 3: SPRITE REPLACEMENT & FALLBACK TOGGLING
# ==============================================================================
func test_suite_3_sprite_replacement_and_fallback_toggling() -> void:
	print("\n--- Running Suite 3: Sprite Replacement & Fallback Toggling ---")
	var player = PLAYER_SCENE.instantiate()
	var asteroid = ASTEROID_SCENE.instantiate()
	add_child(player)
	add_child(asteroid)
	await get_tree().process_frame

	var player_visuals = player.get_visuals_node()
	var ast_visuals = asteroid.get_visuals_node()
	var player_fallback = player_visuals.get_node("ProceduralFallback")
	var ast_fallback = ast_visuals.get_node("ProceduralFallback")

	assert_true(player_fallback.visible, "Player procedural fallback is visible initially")
	assert_true(ast_fallback.visible, "Asteroid procedural fallback is visible initially")

	# 1. Create a dummy ImageTexture to simulate official production sprite insertion
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var dummy_texture = ImageTexture.create_from_image(img)

	# 2. Add Sprite2D to Player Visuals
	var player_sprite = Sprite2D.new()
	player_sprite.name = "ShipSprite"
	player_sprite.texture = dummy_texture
	player_visuals.add_child(player_sprite)
	player._update_visual_fallback()

	assert_true(not player_fallback.visible, "Adding custom Sprite2D with texture automatically hides Player procedural fallback")
	assert_true(player_sprite.visible, "Custom Player sprite is visible")

	# 3. Remove Sprite2D from Player Visuals
	player_visuals.remove_child(player_sprite)
	player_sprite.queue_free()
	player._update_visual_fallback()

	assert_true(player_fallback.visible, "Removing custom Sprite2D automatically re-enables Player procedural fallback")

	# 4. Add Sprite2D to Asteroid Visuals
	var ast_sprite = Sprite2D.new()
	ast_sprite.name = "RockSprite"
	ast_sprite.texture = dummy_texture
	ast_visuals.add_child(ast_sprite)
	asteroid.set_size_tier(asteroid.size_tier)

	assert_true(not ast_fallback.visible, "Adding custom Sprite2D with texture automatically hides Asteroid procedural fallback")
	assert_true(ast_sprite.visible, "Custom Asteroid sprite is visible")

	# 5. Remove Sprite2D from Asteroid Visuals
	ast_visuals.remove_child(ast_sprite)
	ast_sprite.queue_free()
	asteroid.set_size_tier(asteroid.size_tier)

	assert_true(ast_fallback.visible, "Removing custom Sprite2D automatically re-enables Asteroid procedural fallback")

	player.queue_free()
	asteroid.queue_free()
	await get_tree().process_frame


# ==============================================================================
# SUITE 4: NODE RESILIENCE & MISSING RESOURCE SAFETY
# ==============================================================================
func test_suite_4_node_resilience_and_missing_resource_safety() -> void:
	print("\n--- Running Suite 4: Node Resilience & Missing Resource Safety ---")

	# 1. Player without Visuals child (bare programmatic instantiation)
	var bare_player = Area2D.new()
	var player_script = load("res://scripts/player.gd")
	bare_player.set_script(player_script)
	add_child(bare_player)

	assert_true(is_instance_valid(bare_player), "Bare player without Visuals instantiates safely")
	bare_player.reset_state()
	assert_eq(bare_player.health, 12, "Bare player initializes health to 12 without crashing")
	bare_player.take_damage(2)
	assert_eq(bare_player.health, 10, "Bare player takes damage without crashing")
	bare_player.queue_free()

	# 2. Asteroid without Visuals child (bare programmatic instantiation)
	var bare_ast = Area2D.new()
	var ast_script = load("res://scripts/asteroid.gd")
	bare_ast.set_script(ast_script)
	add_child(bare_ast)

	assert_true(is_instance_valid(bare_ast), "Bare asteroid without Visuals instantiates safely")
	bare_ast.set_size_tier(bare_ast.AsteroidSize.MEDIUM)
	assert_eq(bare_ast.contact_damage, 2, "Bare asteroid updates tier stats without crashing")
	bare_ast.queue_free()

	# 3. Full scene re-instantiation verification
	var p_scene_inst = PLAYER_SCENE.instantiate()
	var a_scene_inst = ASTEROID_SCENE.instantiate()
	assert_true(is_instance_valid(p_scene_inst), "Player scene file loads and instantiates cleanly")
	assert_true(is_instance_valid(a_scene_inst), "Asteroid scene file loads and instantiates cleanly")
	p_scene_inst.queue_free()
	a_scene_inst.queue_free()
	await get_tree().process_frame


func _print_summary() -> void:
	print("\n==================================================")
	print("MILESTONE 3.5 TEST RESULTS SUMMARY")
	print("==================================================")
	print("Total tests executed: %d" % total_count)
	print("Passed: %d" % pass_count)
	print("Failed: %d" % fail_count)
	if fail_count == 0:
		print("STATUS: ALL MILESTONE 3.5 TESTS PASSED SUCCESSFULLY!")
	else:
		printerr("STATUS: SOME MILESTONE 3.5 TESTS FAILED!")
	print("==================================================")
