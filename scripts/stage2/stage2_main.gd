extends Node2D
## Stage 2 Main Coordinator for LAST SIGNAL (Stage 2 Level 1: Side-Scrolling & First Hostile Contact,
## and Stage 2 Level 2: Guard Satellite & Accurate Laser Combat).
## Implements horizontal side-scrolling starfield, Guard Bot & Guard Satellite wave management,
## survival objectives (15s L1, 20s L2), HP persistence across levels, Stage 2 checkpoint revive,
## and Call Down / Signal Up architecture.

signal level_completed(level: int)
signal enemy_spawned(enemy: Area2D)

const GUARD_BOT_SCENE = preload("res://scenes/enemies/guard_bot.tscn")
const GUARD_SATELLITE_SCENE = preload("res://scenes/enemies/guard_satellite.tscn")
const PROJECTILE_SCENE = preload("res://scenes/projectile.tscn")

@export var stage_number: int = 2
@export var current_level: int = 1
@export var level_duration: float = 15.0 # 15s for Level 1, 20s for Level 2
@export var enemy_spawn_interval_min: float = 2.0 # Bot spawn min (provisional)
@export var enemy_spawn_interval_max: float = 3.2 # Bot spawn max
@export var satellite_spawn_interval_min: float = 3.0 # Satellite spawn min (provisional)
@export var satellite_spawn_interval_max: float = 4.0 # Satellite spawn max
@export var scroll_speed: float = 140.0 # Horizontal side-scrolling starfield speed (px/s)
@export var stage_checkpoint_level: int = 1

var time_remaining: float = 15.0
var finished: bool = false
var game_won: bool = false
var spawn_remaining: float = 1.0
var star_offset: float = 0.0
var stars: Array[Vector2] = []
var stage_acquisitions: Dictionary = {
	"primary_weapon_acquired": true,
	"shield_acquired": true
}
var show_debug_overlay: bool = false

@onready var player: Area2D = get_node_or_null("Player")
@onready var weapon_controller: Node = get_node_or_null("WeaponController")
@onready var projectiles_container: Node = get_node_or_null("Projectiles")
@onready var enemy_projectiles_container: Node = get_node_or_null("EnemyProjectiles")
@onready var enemies_container: Node = get_node_or_null("Enemies")
@onready var hud: CanvasLayer = get_node_or_null("HUD")
@onready var info: Label = get_node_or_null("HUD/Info")
@onready var message: Label = get_node_or_null("HUD/Message")
var debug_label: Label = null


func _ready() -> void:
	randomize()
	for i in range(95):
		stars.append(Vector2(randf_range(0.0, 1280.0), randf_range(0.0, 720.0)))

	if is_instance_valid(player):
		player.health_changed.connect(_on_health_changed)
		player.died.connect(_on_player_died)

	if is_instance_valid(info):
		info.add_theme_font_size_override("font_size", 23)
	if is_instance_valid(message):
		message.add_theme_font_size_override("font_size", 26)
		message.visible = false

	_setup_debug_overlay()

	if not is_instance_valid(weapon_controller):
		weapon_controller = get_node_or_null("WeaponController")
	if not is_instance_valid(projectiles_container):
		projectiles_container = get_node_or_null("Projectiles")
	if not is_instance_valid(enemy_projectiles_container):
		enemy_projectiles_container = get_node_or_null("EnemyProjectiles")
	if not is_instance_valid(enemies_container):
		enemies_container = get_node_or_null("Enemies")

	if is_instance_valid(weapon_controller):
		var proj_parent: Node = projectiles_container if is_instance_valid(projectiles_container) else self
		weapon_controller.setup(player, proj_parent)

	start_level(1, 12) # Stage 2 entry restores full 12 HP


func initialize_from_stage1(p_stage1_data: Dictionary) -> void:
	stage_acquisitions = p_stage1_data.duplicate()
	stage_acquisitions["primary_weapon_acquired"] = true
	stage_acquisitions["shield_acquired"] = true
	start_level(1, 12)


func is_side_scrolling() -> bool:
	return true


func is_primary_weapon_acquired() -> bool:
	return stage_acquisitions.get("primary_weapon_acquired", true)


func is_shield_acquired() -> bool:
	return stage_acquisitions.get("shield_acquired", true)


func _setup_debug_overlay() -> void:
	debug_label = Label.new()
	debug_label.name = "DebugOverlay"
	debug_label.offset_left = 20.0
	debug_label.offset_top = 50.0
	debug_label.offset_right = 750.0
	debug_label.offset_bottom = 240.0
	debug_label.add_theme_font_size_override("font_size", 16)
	debug_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0, 0.95))
	debug_label.visible = false
	if is_instance_valid(hud):
		hud.add_child(debug_label)


func _process(delta: float) -> void:
	# Side-scrolling: background stars move right-to-left
	star_offset = fmod(star_offset + scroll_speed * delta, 1280.0)
	queue_redraw()

	if finished:
		_update_debug_overlay()
		return

	time_remaining = maxf(0.0, time_remaining - delta)

	# Level-specific enemy spawner
	spawn_remaining -= delta
	if spawn_remaining <= 0.0:
		if current_level == 1:
			_spawn_guard_bot()
			spawn_remaining = randf_range(enemy_spawn_interval_min, enemy_spawn_interval_max)
		elif current_level == 2:
			_spawn_guard_satellite()
			spawn_remaining = randf_range(satellite_spawn_interval_min, satellite_spawn_interval_max)

	if time_remaining <= 0.0:
		_complete_level()

	_update_hud()
	_update_debug_overlay()


func _draw() -> void:
	# Inner sector deep space background
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.02, 0.03, 0.07))
	for point in stars:
		var scroll_x: float = fmod(point.x - star_offset + 1280.0, 1280.0)
		draw_circle(Vector2(scroll_x, point.y), 1.25, Color(0.65, 0.78, 0.95, 0.75))


func _spawn_guard_bot() -> Area2D:
	if not GUARD_BOT_SCENE:
		return null

	var bot = GUARD_BOT_SCENE.instantiate()
	bot.position = Vector2(1320.0, randf_range(80.0, 640.0))
	bot.set_target_player(player)
	var proj_parent: Node = enemy_projectiles_container if is_instance_valid(enemy_projectiles_container) else self
	bot.set_projectiles_container(proj_parent)

	var target_parent: Node = enemies_container if is_instance_valid(enemies_container) else self
	target_parent.add_child(bot)

	enemy_spawned.emit(bot)
	return bot


func _spawn_guard_satellite() -> Area2D:
	if not GUARD_SATELLITE_SCENE:
		return null

	var sat = GUARD_SATELLITE_SCENE.instantiate()
	sat.position = Vector2(1320.0, randf_range(90.0, 630.0))
	sat.set_target_player(player)

	var target_parent: Node = enemies_container if is_instance_valid(enemies_container) else self
	target_parent.add_child(sat)

	enemy_spawned.emit(sat)
	return sat


func _clear_spawned_entities() -> void:
	if is_instance_valid(enemies_container):
		for child in enemies_container.get_children():
			if child.has_method("stop_attack"):
				child.stop_attack()
			child.queue_free()
	if is_instance_valid(enemy_projectiles_container):
		for child in enemy_projectiles_container.get_children():
			child.queue_free()
	if is_instance_valid(projectiles_container):
		for child in projectiles_container.get_children():
			child.queue_free()

	# Also clear any lingering root-level spawned entities
	for child in get_children():
		if child.is_in_group("enemies") or child.is_in_group("enemy_projectiles") or child.is_in_group("projectiles"):
			if child.has_method("stop_attack"):
				child.stop_attack()
			child.queue_free()

	if is_instance_valid(weapon_controller) and weapon_controller.has_method("clear_projectiles"):
		weapon_controller.clear_projectiles()


func start_level(target_level: int, starting_hp: int = 12) -> void:
	current_level = target_level
	finished = false
	game_won = false

	if current_level == 1:
		level_duration = 15.0 # Confirmed 15s survival objective for Level 1
		spawn_remaining = 0.9
	elif current_level == 2:
		level_duration = 20.0 # Confirmed 20s survival objective for Level 2
		spawn_remaining = 1.2
	else:
		level_duration = 20.0
		spawn_remaining = 1.0

	time_remaining = level_duration

	_clear_spawned_entities()

	if not is_instance_valid(weapon_controller):
		weapon_controller = get_node_or_null("WeaponController")
	if is_instance_valid(weapon_controller):
		weapon_controller.set_firing_enabled(is_primary_weapon_acquired())

	if is_instance_valid(player):
		player.prepare_for_level(starting_hp)
		# Side-scrolling spawn position (left side of screen)
		player.position = Vector2(240.0, 360.0)

	if is_instance_valid(message):
		message.visible = false

	_update_hud()
	_update_debug_overlay()


func advance_to_next_level() -> void:
	if not (finished and game_won and current_level == 1):
		return

	# Preserve remaining player HP when progressing within Stage 2!
	var preserved_hp: int = player.health if is_instance_valid(player) else 12
	start_level(2, preserved_hp)


func revive_at_stage_checkpoint() -> void:
	# Stage 2 Checkpoint: Death in Stage 2 (Level 1 or Level 2) revives strictly at Stage 2 Level 1 with 12 HP
	if not is_instance_valid(weapon_controller):
		weapon_controller = get_node_or_null("WeaponController")
	if is_instance_valid(weapon_controller):
		weapon_controller.clear_projectiles()

	start_level(stage_checkpoint_level, 12)


func _on_player_died() -> void:
	finished = true
	game_won = false
	if is_instance_valid(player):
		player.set_physics_process(false)
	if is_instance_valid(weapon_controller):
		weapon_controller.set_firing_enabled(false)

	_clear_spawned_entities()

	if is_instance_valid(message):
		message.visible = true
		message.text = "SHIP DESTROYED (STAGE %d / LEVEL %d)\nPress [R] to Revive at Stage 2 Checkpoint" % [stage_number, current_level]
	_update_debug_overlay()


func _complete_level() -> void:
	finished = true
	game_won = true
	if is_instance_valid(player):
		player.set_physics_process(false)
	if is_instance_valid(weapon_controller):
		weapon_controller.set_firing_enabled(false)

	_clear_spawned_entities()

	if is_instance_valid(message):
		message.visible = true
		if current_level == 1:
			message.text = "STAGE 2 / LEVEL 1 COMPLETE!\nSector Incursion Survived (HP: %02d/%02d)\nHostile Contact: Guard Bot Sector Cleared\n\nPress [Space/Enter] for Level 2\nPress [R] to replay Stage 2 from Checkpoint" % [
				player.health, player.max_health
			]
		elif current_level == 2:
			message.text = "STAGE 2 / LEVEL 2 COMPLETE!\nDeep Sector Survived (HP: %02d/%02d)\nGuard Satellite Defense Grid Cleared\n\n[STAGE 2 LEVEL 2 COMPLETE — PROTOTYPE FINISHED]\nPress [R] to replay Stage 2 from Checkpoint" % [
				player.health, player.max_health
			]

	level_completed.emit(current_level)
	_update_debug_overlay()


func _on_health_changed(_current: int, _maximum: int) -> void:
	_update_hud()
	_update_debug_overlay()


func _update_hud() -> void:
	if not is_instance_valid(player) or not is_instance_valid(info):
		return
	info.text = "STAGE %d / LEVEL %d     HP %02d / %02d     TIME %02d s" % [
		stage_number, current_level, player.health, player.max_health, ceili(time_remaining)
	]


func _update_debug_overlay() -> void:
	if not is_instance_valid(debug_label) or not debug_label.visible:
		return
	if not is_instance_valid(player):
		return

	var speed: float = player.movement_velocity.length()
	var state_str: String = player.get_regen_state_string() if player.has_method("get_regen_state_string") else ""
	var enemy_count: int = enemies_container.get_child_count() if is_instance_valid(enemies_container) else 0

	debug_label.text = "[DEBUG OVERLAY — F3 to toggle]\nStage: %d | Level: %d | Level Duration: %.1fs\nMode: Side-Scrolling (Horizontal Drift: %.1f px/s)\nHP: %02d / %02d\nSpeed: %5.1f px/s | Regen: %s\nActive Enemies: %d | Primary Weapon: ACTIVE" % [
		stage_number, current_level, level_duration, scroll_speed,
		player.health, player.max_health,
		speed, state_str,
		enemy_count
	]


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			show_debug_overlay = not show_debug_overlay
			if is_instance_valid(debug_label):
				debug_label.visible = show_debug_overlay
				_update_debug_overlay()
		elif event.keycode == KEY_R or event.physical_keycode == KEY_R:
			revive_at_stage_checkpoint()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if finished and game_won and current_level == 1:
				advance_to_next_level()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()
