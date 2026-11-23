extends Node2D
## Stage 1 Coordinator: Manages Level 1, Level 2, Level 3 & Level 4 30s arcade survival/combat runs.
## Implements Call Down, Signal Up, HP persistence, and Stage 1 Checkpoint revive semantics.

signal equipment_acquired(equipment_data: Dictionary)

const ASTEROID_SCENE: PackedScene = preload("res://scenes/asteroid.tscn")
const SATELLITE_SCENE: PackedScene = preload("res://scenes/satellite.tscn")
const WRECKED_SHIP_SCENE: PackedScene = preload("res://scenes/wrecked_ship.tscn")

@export var stage_number: int = 1
@export var current_level: int = 1
@export var stage_checkpoint_level: int = 1
@export var level_duration: float = 30.0

# Level 1 parameters (Dense small asteroid belt)
@export var l1_spawn_interval_min: float = 0.35
@export var l1_spawn_interval_max: float = 0.85
@export var l1_asteroid_speed_min: float = 190.0
@export var l1_asteroid_speed_max: float = 300.0

# Level 2 parameters (Lower overall density, medium + small asteroids) - PROPOSAL / TBD
@export var l2_spawn_interval_min: float = 0.65
@export var l2_spawn_interval_max: float = 1.25
@export var l2_speed_small_min: float = 190.0
@export var l2_speed_small_max: float = 300.0
@export var l2_speed_medium_min: float = 140.0
@export var l2_speed_medium_max: float = 240.0
@export var l2_medium_ratio: float = 0.40 # 40% Medium, 60% Small
@export var l2_satellite_spawn_time: float = 20.0 # at 20s remaining (10s elapsed)

# Level 3 parameters (Lowest density, deep belt with small, medium, large asteroids) - PROPOSAL / TBD
@export var l3_spawn_interval_min: float = 1.00
@export var l3_spawn_interval_max: float = 1.80
@export var l3_small_ratio: float = 0.30  # 30% Small
@export var l3_medium_ratio: float = 0.40 # 40% Medium
@export var l3_large_ratio: float = 0.30  # 30% Large
@export var l3_speed_small_min: float = 190.0
@export var l3_speed_small_max: float = 300.0
@export var l3_speed_medium_min: float = 140.0
@export var l3_speed_medium_max: float = 240.0
@export var l3_speed_large_min: float = 90.0
@export var l3_speed_large_max: float = 170.0

# Level 4 parameters (Asteroid combat & twin-barrel firing) - PROPOSAL / TBD
@export var l4_spawn_interval_min: float = 0.90
@export var l4_spawn_interval_max: float = 1.60
@export var l4_small_ratio: float = 0.35  # 35% Small
@export var l4_medium_ratio: float = 0.40 # 40% Medium
@export var l4_large_ratio: float = 0.25  # 25% Large
@export var l4_speed_small_min: float = 190.0
@export var l4_speed_small_max: float = 300.0
@export var l4_speed_medium_min: float = 140.0
@export var l4_speed_medium_max: float = 240.0
@export var l4_speed_large_min: float = 90.0
@export var l4_speed_large_max: float = 170.0

# Milestone 1 backward compatibility exports
@export var spawn_interval_min: float = 0.35
@export var spawn_interval_max: float = 0.85
@export var asteroid_speed_min: float = 190.0
@export var asteroid_speed_max: float = 300.0
@export var show_debug_overlay: bool = true # Toggleable with F3 key

static var requested_start_level: int = 1

@onready var player = $Player
@onready var info: Label = $HUD/Info
@onready var message: Label = $HUD/Message
@onready var weapon_controller: Node = get_node_or_null("WeaponController")
@onready var projectiles_container: Node = get_node_or_null("Projectiles")

var time_remaining: float = 30.0
var spawn_remaining: float = 0.7
var finished: bool = false
var game_won: bool = false
var stars: Array[Vector2] = []
var star_offset: float = 0.0
var debug_label: Label = null

# Satellite & Stage Acquisitions
var satellite_spawned: bool = false
var active_satellite: Area2D = null
var satellite_extracted: bool = false
var stage_acquisitions: Dictionary = {}
var telemetry_notice: String = ""
var telemetry_notice_timer: float = 0.0


func _ready() -> void:
	randomize()
	for i in range(85):
		stars.append(Vector2(randf_range(0.0, 1280.0), randf_range(0.0, 720.0)))

	# Signal Up: Main listens to signals emitted by Player
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
	if is_instance_valid(weapon_controller):
		var proj_parent: Node = projectiles_container if is_instance_valid(projectiles_container) else self
		weapon_controller.setup(player, proj_parent)

	if requested_start_level > 1:
		current_level = requested_start_level
		requested_start_level = 1
	start_level(current_level, player.health if is_instance_valid(player) else 12)


func _setup_debug_overlay() -> void:
	debug_label = Label.new()
	debug_label.name = "DebugOverlay"
	debug_label.offset_left = 20.0
	debug_label.offset_top = 50.0
	debug_label.offset_right = 750.0
	debug_label.offset_bottom = 240.0
	debug_label.add_theme_font_size_override("font_size", 16)
	debug_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0, 0.95))
	debug_label.visible = show_debug_overlay

	var hud = get_node_or_null("HUD")
	if is_instance_valid(hud):
		hud.add_child(debug_label)


func _process(delta: float) -> void:
	star_offset = fmod(star_offset + 27.0 * delta, 720.0)
	queue_redraw()

	if telemetry_notice_timer > 0.0:
		telemetry_notice_timer = maxf(0.0, telemetry_notice_timer - delta)
		if telemetry_notice_timer == 0.0:
			telemetry_notice = ""
			_update_hud()

	if finished:
		_update_debug_overlay()
		return

	time_remaining = maxf(0.0, time_remaining - delta)

	# Level 2 Satellite scheduling
	if current_level == 2 and not satellite_spawned and time_remaining <= l2_satellite_spawn_time:
		_spawn_satellite()

	# Asteroid interval spawner
	spawn_remaining -= delta
	if spawn_remaining <= 0.0:
		_spawn_asteroid()
		var cur_min := l1_spawn_interval_min
		var cur_max := l1_spawn_interval_max
		if current_level == 2:
			cur_min = l2_spawn_interval_min
			cur_max = l2_spawn_interval_max
		elif current_level == 3:
			cur_min = l3_spawn_interval_min
			cur_max = l3_spawn_interval_max
		elif current_level == 4:
			cur_min = l4_spawn_interval_min
			cur_max = l4_spawn_interval_max
		spawn_remaining = randf_range(cur_min, cur_max)

	if time_remaining <= 0.0:
		_complete_level()

	_update_hud()
	_update_debug_overlay()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.025, 0.035, 0.082))
	for point in stars:
		var scroll_y: float = fmod(point.y + star_offset, 720.0)
		draw_circle(Vector2(point.x, scroll_y), 1.3, Color(0.6, 0.76, 0.9, 0.75))


func _spawn_asteroid() -> void:
	if not ASTEROID_SCENE:
		return
	var rock = ASTEROID_SCENE.instantiate()
	rock.position = Vector2(randf_range(30.0, 1250.0), -38.0)

	if current_level == 1:
		rock.speed = randf_range(l1_asteroid_speed_min, l1_asteroid_speed_max)
	elif current_level == 2:
		# Level 2: mixed small and medium asteroids (lower overall density)
		if randf() < l2_medium_ratio:
			rock.set_size_tier(rock.AsteroidSize.MEDIUM)
			rock.speed = randf_range(l2_speed_medium_min, l2_speed_medium_max)
		else:
			rock.set_size_tier(rock.AsteroidSize.SMALL)
			rock.speed = randf_range(l2_speed_small_min, l2_speed_small_max)
	elif current_level == 3:
		# Level 3: deep belt (lowest density, small 30%, medium 40%, large 30%)
		var roll: float = randf()
		if roll < l3_small_ratio:
			rock.set_size_tier(rock.AsteroidSize.SMALL)
			rock.speed = randf_range(l3_speed_small_min, l3_speed_small_max)
		elif roll < l3_small_ratio + l3_medium_ratio:
			rock.set_size_tier(rock.AsteroidSize.MEDIUM)
			rock.speed = randf_range(l3_speed_medium_min, l3_speed_medium_max)
		else:
			rock.set_size_tier(rock.AsteroidSize.LARGE)
			rock.speed = randf_range(l3_speed_large_min, l3_speed_large_max)
	elif current_level == 4:
		# Level 4: combat belt (small 35%, medium 40%, large 25%)
		var roll: float = randf()
		if roll < l4_small_ratio:
			rock.set_size_tier(rock.AsteroidSize.SMALL)
			rock.speed = randf_range(l4_speed_small_min, l4_speed_small_max)
		elif roll < l4_small_ratio + l4_medium_ratio:
			rock.set_size_tier(rock.AsteroidSize.MEDIUM)
			rock.speed = randf_range(l4_speed_medium_min, l4_speed_medium_max)
		else:
			rock.set_size_tier(rock.AsteroidSize.LARGE)
			rock.speed = randf_range(l4_speed_large_min, l4_speed_large_max)

	add_child(rock)


func _spawn_satellite() -> void:
	satellite_spawned = true
	if not SATELLITE_SCENE:
		return
	active_satellite = SATELLITE_SCENE.instantiate()
	active_satellite.position = Vector2(randf_range(300.0, 980.0), -50.0)
	active_satellite.extracted.connect(_on_satellite_extracted)
	add_child(active_satellite)


func _on_satellite_extracted(payload: Dictionary) -> void:
	satellite_extracted = true
	stage_acquisitions["satellite_telemetry"] = payload
	telemetry_notice = "[DATA RECOVERED: Encrypted telemetry packet stored]"
	telemetry_notice_timer = 5.0
	_update_hud()
	_update_debug_overlay()


func _clear_spawned_entities() -> void:
	for child in get_children():
		if child.is_in_group("asteroids") or child.is_in_group("satellites") or child.is_in_group("wrecked_ships") or child.is_in_group("projectiles"):
			child.queue_free()
	if not is_instance_valid(weapon_controller):
		weapon_controller = get_node_or_null("WeaponController")
	if is_instance_valid(weapon_controller) and weapon_controller.has_method("clear_projectiles"):
		weapon_controller.clear_projectiles()


func start_level(target_level: int, starting_hp: int = -1) -> void:
	current_level = target_level
	finished = false
	game_won = false
	time_remaining = level_duration
	satellite_spawned = false
	active_satellite = null
	telemetry_notice = ""
	telemetry_notice_timer = 0.0

	if not is_instance_valid(weapon_controller):
		weapon_controller = get_node_or_null("WeaponController")

	if target_level == 1:
		satellite_extracted = false
		stage_acquisitions.clear()
		spawn_remaining = 0.7
		if is_instance_valid(weapon_controller):
			weapon_controller.set_firing_enabled(false)
	elif target_level == 2:
		spawn_remaining = 1.0
		if is_instance_valid(weapon_controller):
			weapon_controller.set_firing_enabled(false)
	elif target_level == 3:
		spawn_remaining = 1.2
		if is_instance_valid(weapon_controller):
			weapon_controller.set_firing_enabled(false)
	elif target_level == 4:
		spawn_remaining = 1.0
		if is_instance_valid(weapon_controller):
			weapon_controller.set_firing_enabled(is_primary_weapon_acquired())

	_clear_spawned_entities()

	if is_instance_valid(player):
		if starting_hp > 0:
			player.prepare_for_level(starting_hp)
		else:
			player.reset_state()
		player.position = Vector2(640, 570)

	if is_instance_valid(message):
		message.visible = false

	_update_hud()
	_update_debug_overlay()


func advance_to_next_level() -> void:
	if finished and game_won:
		var persistent_hp: int = player.health if is_instance_valid(player) else 12
		if current_level == 1:
			start_level(2, persistent_hp)
		elif current_level == 2:
			start_level(3, persistent_hp)
		elif current_level == 3:
			start_level(4, persistent_hp)


func revive_at_stage_checkpoint() -> void:
	stage_acquisitions.clear()
	satellite_extracted = false
	if not is_instance_valid(weapon_controller):
		weapon_controller = get_node_or_null("WeaponController")
	if is_instance_valid(weapon_controller):
		weapon_controller.set_firing_enabled(false)
		weapon_controller.clear_projectiles()
	start_level(stage_checkpoint_level, 12)


func restart_level() -> void:
	if current_level == 1:
		get_tree().reload_current_scene()
	else:
		revive_at_stage_checkpoint()


func is_primary_weapon_acquired() -> bool:
	return stage_acquisitions.get("primary_weapon_acquired", false)


func is_shield_acquired() -> bool:
	return stage_acquisitions.get("shield_acquired", false)


func has_equipment() -> bool:
	return is_primary_weapon_acquired() and is_shield_acquired()


func _on_health_changed(_current: int, _maximum: int) -> void:
	_update_hud()
	_update_debug_overlay()


func _update_hud() -> void:
	if not is_instance_valid(player) or not is_instance_valid(info):
		return
	var base_info := "STAGE %d / LEVEL %d     HP %02d / %02d     TIME %02d s" % [
		stage_number, current_level, player.health, player.max_health, ceili(time_remaining)
	]
	if not telemetry_notice.is_empty():
		base_info += "     " + telemetry_notice
	info.text = base_info


func _update_debug_overlay() -> void:
	if not is_instance_valid(debug_label) or not debug_label.visible:
		return
	if not is_instance_valid(player):
		return

	var speed: float = player.movement_velocity.length()
	var state_str: String = player.get_regen_state_string() if player.has_method("get_regen_state_string") else ""
	var mouse_pos: Vector2 = player.get_global_mouse_position()
	var dist_to_mouse: float = (mouse_pos - player.global_position).length()
	var sat_status: String = "EXTRACTED" if satellite_extracted else ("ACTIVE" if is_instance_valid(active_satellite) else ("PENDING" if not satellite_spawned else "MISSED"))
	var wep_status: String = "ACTIVE" if (is_primary_weapon_acquired() and current_level == 4) else ("ACQUIRED" if is_primary_weapon_acquired() else "NO")
	var shd_status: String = "YES" if is_shield_acquired() else "NO"

	debug_label.text = "[DEBUG OVERLAY — F3 to toggle]\nStage: %d | Level: %d | Level Duration: %.1fs\nHP: %02d / %02d (Persisted across levels)\nSpeed: %5.1f px/s (Threshold: %.1f px/s | Deadzone: %.1f px)\nStationary Duration: %4.2f s (Wait Required: %.1f s)\nRegen Progress: %5.1f%% (+%.1f HP/s) | State: %s\nDistance to Mouse: %5.2f px\nSatellite Status: %s (Optional) | Weapon: %s | Shield: %s" % [
		stage_number, current_level, level_duration,
		player.health, player.max_health,
		speed, player.stop_threshold, player.arrive_distance,
		player.still_seconds, player.regen_wait,
		player.regen_fraction * 100.0, player.regen_per_second, state_str,
		dist_to_mouse,
		sat_status, wep_status, shd_status
	]


func _on_player_died() -> void:
	finished = true
	game_won = false
	if is_instance_valid(player):
		player.set_physics_process(false)
	if not is_instance_valid(weapon_controller):
		weapon_controller = get_node_or_null("WeaponController")
	if is_instance_valid(weapon_controller):
		weapon_controller.set_firing_enabled(false)
	if is_instance_valid(message):
		message.visible = true
		if current_level == 1:
			message.text = "SHIP DESTROYED\nPress [R] to retry Level 1"
		else:
			message.text = "SHIP DESTROYED (STAGE %d / LEVEL %d)\nPress [R] to Revive at Stage 1 Checkpoint" % [stage_number, current_level]
	_update_debug_overlay()


func _complete_level() -> void:
	finished = true
	game_won = true
	if is_instance_valid(player):
		player.set_physics_process(false)
	if is_instance_valid(message):
		message.visible = true
		if current_level == 1:
			message.text = "LEVEL 1 COMPLETE!\n30 seconds survived (HP: %02d/%02d)\nPress [Space/Enter] for Level 2\nPress [R] to replay Level 1" % [
				player.health, player.max_health
			]
		elif current_level == 2:
			var sat_str := "SUCCESS (Telemetry Recovered)" if satellite_extracted else "MISSED (Satellite Drifted Away)"
			message.text = "STAGE 1 / LEVEL 2 COMPLETE!\n30 seconds survived (HP: %02d/%02d)\nSatellite Extraction: %s\nPress [Space/Enter] for Level 3\nPress [R] to replay Stage 1" % [
				player.health, player.max_health, sat_str
			]
		elif current_level == 3:
			# Successful Level 3 completion grants primary weapon and deflector shield
			stage_acquisitions["primary_weapon_acquired"] = true
			stage_acquisitions["shield_acquired"] = true
			stage_acquisitions["equipment_source"] = "Wrecked Scout Craft (Surveyor-7)"

			var equip_payload := {
				"primary_weapon": true,
				"shield": true,
				"source": "Wrecked Scout Craft (Surveyor-7)",
				"weapon_type": "Twin-barrel Pulse Cannon",
				"shield_type": "Deflector Shield Generator"
			}
			equipment_acquired.emit(equip_payload)

			_clear_spawned_entities()
			if WRECKED_SHIP_SCENE:
				var wreck = WRECKED_SHIP_SCENE.instantiate()
				wreck.position = Vector2(640.0, 210.0)
				add_child(wreck)

			var sat_str := "SUCCESS (Telemetry Recovered)" if satellite_extracted else "MISSED (Satellite Drifted Away)"
			message.text = "STAGE 1 / LEVEL 3 COMPLETE!\nDeep Asteroid Belt Cleared (HP: %02d/%02d)\nSatellite Extraction: %s\n\n[DERELICT ENCOUNTERED: Wrecked Scout Craft]\n[EQUIPMENT RECOVERED]\n* Twin-barrel Pulse Cannon (Primary Weapon)\n* Deflector Shield Generator\n(Hardware secured for combat deployment)\n\nPress [Space/Enter] to proceed to combat zone\n[END OF PROTOTYPE]\nPress [R] to replay Stage 1 from Checkpoint" % [
				player.health, player.max_health, sat_str
			]
		elif current_level == 4:
			if not is_instance_valid(weapon_controller):
				weapon_controller = get_node_or_null("WeaponController")
			if is_instance_valid(weapon_controller):
				weapon_controller.set_firing_enabled(false)
			_clear_spawned_entities()
			var sat_str := "SUCCESS (Telemetry Recovered)" if satellite_extracted else "MISSED (Satellite Drifted Away)"
			message.text = "STAGE 1 / LEVEL 4 COMPLETE!\nAsteroid Combat Zone Cleared (HP: %02d/%02d)\nSatellite Extraction: %s\nPrimary Weapon: Twin-barrel Pulse Cannon (Active)\nShield: Deflector Shield Generator (Stored)\n\n[END OF PROTOTYPE — MILESTONE 4 COMPLETE]\nPress [R] to replay Stage 1 from Checkpoint" % [
				player.health, player.max_health, sat_str
			]
	_update_debug_overlay()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			show_debug_overlay = not show_debug_overlay
			if is_instance_valid(debug_label):
				debug_label.visible = show_debug_overlay
				_update_debug_overlay()
		elif event.keycode == KEY_R or event.physical_keycode == KEY_R:
			if current_level == 1:
				restart_level()
			else:
				revive_at_stage_checkpoint()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if finished and game_won and (current_level >= 1 and current_level <= 3):
				advance_to_next_level()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()
