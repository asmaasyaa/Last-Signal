extends Node2D
## Boss Arena Coordinator for LAST SIGNAL (Stage 2 Level 4: Guard Cruiser Mini-Boss Phase 1 & EM Jammer Activation).
## Implements fixed 1280x720 arcade arena, Guard Cruiser mini-boss combat (400 -> 200 HP threshold),
## EM Jammer active equipment integration, HP persistence from Level 3, Stage 2 checkpoint restart,
## and Call Down / Signal Up architecture.

signal level_completed(level: int)
signal phase_1_completed
signal phase_2_started
signal stage_completed(payload: Dictionary)

const GUARD_CRUISER_SCENE = preload("res://scenes/bosses/guard_cruiser.tscn")
const PROJECTILE_SCENE = preload("res://scenes/projectile.tscn")
const STAGE3_MAIN_SCENE = preload("res://scenes/stage3/stage3_main.tscn")

@export var stage_number: int = 2
@export var current_level: int = 4
@export var stage_checkpoint_level: int = 1

var finished: bool = false
var game_won: bool = false
var stage_2_completed: bool = false
var _transitioning_to_stage3: bool = false
var stars: Array[Vector2] = []
var star_offset: float = 0.0

var stage_acquisitions: Dictionary = {
	"primary_weapon_acquired": true,
	"shield_acquired": true,
	"em_jammer_acquired": true
}

var show_debug_overlay: bool = false
var _pending_starting_hp: int = 12

@onready var player: Area2D = get_node_or_null("Player")
@onready var weapon_controller: Node = get_node_or_null("WeaponController")
@onready var em_jammer_controller: Node2D = get_node_or_null("EMJammerController")
@onready var boss: Area2D = get_node_or_null("GuardCruiser")
@onready var projectiles_container: Node = get_node_or_null("Projectiles")
@onready var enemy_projectiles_container: Node = get_node_or_null("EnemyProjectiles")
@onready var hud: CanvasLayer = get_node_or_null("HUD")
@onready var info: Label = get_node_or_null("HUD/Info")
@onready var boss_bar: Label = get_node_or_null("HUD/BossBar")
@onready var jammer_status: Label = get_node_or_null("HUD/JammerStatus")
@onready var message: Label = get_node_or_null("HUD/Message")
var debug_label: Label = null


func _ready() -> void:
	randomize()
	for i in range(110):
		stars.append(Vector2(randf_range(0.0, 1280.0), randf_range(0.0, 720.0)))

	_setup_hud_labels()
	_setup_debug_overlay()

	if not is_instance_valid(player):
		player = get_node_or_null("Player")
	if not is_instance_valid(weapon_controller):
		weapon_controller = get_node_or_null("WeaponController")
	if not is_instance_valid(em_jammer_controller):
		em_jammer_controller = get_node_or_null("EMJammerController")
	if not is_instance_valid(boss):
		boss = get_node_or_null("GuardCruiser")
	if not is_instance_valid(projectiles_container):
		projectiles_container = get_node_or_null("Projectiles")
	if not is_instance_valid(enemy_projectiles_container):
		enemy_projectiles_container = get_node_or_null("EnemyProjectiles")

	start_level(4, _pending_starting_hp)


func initialize_from_stage2_level3(p_stage_data: Dictionary) -> void:
	stage_acquisitions = p_stage_data.duplicate()
	stage_acquisitions["primary_weapon_acquired"] = true
	stage_acquisitions["shield_acquired"] = true
	stage_acquisitions["em_jammer_acquired"] = true

	var preserved_hp: int = p_stage_data.get("health", 12)
	_pending_starting_hp = preserved_hp
	if is_inside_tree():
		start_level(4, preserved_hp)


func is_primary_weapon_acquired() -> bool:
	return stage_acquisitions.get("primary_weapon_acquired", true)


func is_shield_acquired() -> bool:
	return stage_acquisitions.get("shield_acquired", true)


func is_em_jammer_acquired() -> bool:
	return stage_acquisitions.get("em_jammer_acquired", true)


func _setup_hud_labels() -> void:
	if is_instance_valid(info):
		info.add_theme_font_size_override("font_size", 22)
	if is_instance_valid(boss_bar):
		boss_bar.add_theme_font_size_override("font_size", 22)
	if is_instance_valid(jammer_status):
		jammer_status.add_theme_font_size_override("font_size", 20)
	if is_instance_valid(message):
		message.add_theme_font_size_override("font_size", 26)
		message.visible = false


func _setup_debug_overlay() -> void:
	debug_label = Label.new()
	debug_label.name = "DebugOverlay"
	debug_label.offset_left = 20.0
	debug_label.offset_top = 80.0
	debug_label.offset_right = 750.0
	debug_label.offset_bottom = 260.0
	debug_label.add_theme_font_size_override("font_size", 16)
	debug_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0, 0.95))
	debug_label.visible = false
	if is_instance_valid(hud):
		hud.add_child(debug_label)


func start_level(target_level: int, starting_hp: int = 12) -> void:
	current_level = target_level
	finished = false
	game_won = false
	stage_2_completed = false
	_transitioning_to_stage3 = false

	_clear_spawned_projectiles()

	# 1. Setup Player
	if is_instance_valid(player):
		if not player.health_changed.is_connected(_on_player_health_changed):
			player.health_changed.connect(_on_player_health_changed)
		if not player.died.is_connected(_on_player_died):
			player.died.connect(_on_player_died)

		player.prepare_for_level(starting_hp)
		player.position = Vector2(640.0, 560.0) # Arcade center-bottom spawn

	# 2. Setup Weapon Controller
	if is_instance_valid(weapon_controller):
		var proj_parent: Node = projectiles_container if is_instance_valid(projectiles_container) else self
		weapon_controller.setup(player, proj_parent)
		weapon_controller.set_firing_enabled(is_primary_weapon_acquired())

	# 3. Setup EM Jammer Controller
	if is_instance_valid(em_jammer_controller):
		em_jammer_controller.setup(player, self)
		em_jammer_controller.set_acquired(is_em_jammer_acquired())

	# 4. Setup Guard Cruiser Mini-Boss
	if is_instance_valid(boss):
		boss.set_target_player(player)
		var enemy_proj_parent: Node = enemy_projectiles_container if is_instance_valid(enemy_projectiles_container) else self
		boss.set_projectiles_container(enemy_proj_parent)

		if not boss.phase_threshold_reached.is_connected(_on_boss_phase_threshold_reached):
			boss.phase_threshold_reached.connect(_on_boss_phase_threshold_reached)
		if not boss.health_changed.is_connected(_on_boss_health_changed):
			boss.health_changed.connect(_on_boss_health_changed)
		if not boss.defeated.is_connected(_on_boss_defeated):
			boss.defeated.connect(_on_boss_defeated)

		boss.position = Vector2(640.0, 150.0)
		boss.health = 400
		boss.can_take_damage = true
		boss.phase_1_completed = false
		boss.is_destroyed = false

	if is_instance_valid(message):
		message.visible = false

	_update_hud()
	_update_debug_overlay()


func _clear_spawned_projectiles() -> void:
	if is_instance_valid(projectiles_container):
		for child in projectiles_container.get_children():
			child.queue_free()
	if is_instance_valid(enemy_projectiles_container):
		for child in enemy_projectiles_container.get_children():
			child.queue_free()
	if is_instance_valid(weapon_controller) and weapon_controller.has_method("clear_projectiles"):
		weapon_controller.clear_projectiles()


func _process(delta: float) -> void:
	# Subtle vertical drift starfield for full arcade space atmosphere
	star_offset = fmod(star_offset + 30.0 * delta, 720.0)
	queue_redraw()

	if finished:
		_update_debug_overlay()
		return

	_update_hud()
	_update_debug_overlay()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.02, 0.025, 0.06))
	for point in stars:
		var scroll_y: float = fmod(point.y + star_offset, 720.0)
		draw_circle(Vector2(point.x, scroll_y), 1.25, Color(0.65, 0.75, 0.95, 0.65))


func _on_boss_health_changed(_current: int, _maximum: int) -> void:
	_update_hud()
	_update_debug_overlay()


func _on_player_health_changed(_current: int, _maximum: int) -> void:
	_update_hud()
	_update_debug_overlay()


func _on_boss_phase_threshold_reached(phase: int) -> void:
	if phase == 1:
		finished = true
		game_won = true

		if is_instance_valid(player):
			player.set_physics_process(false)
		if is_instance_valid(weapon_controller):
			weapon_controller.set_firing_enabled(false)

		_clear_spawned_projectiles()

		if is_instance_valid(message):
			message.visible = true
			var boss_hp: int = boss.health if is_instance_valid(boss) else 200
			var boss_max: int = boss.max_health if is_instance_valid(boss) else 400
			message.text = "STAGE 2 / LEVEL 4 COMPLETE\nGUARD CRUISER — PHASE 1 DISABLED\nBOSS HP: %d / %d\n\nPress [Space/Enter] for Level 5 (Phase 2)\nPress [R] to replay Stage 2 from Checkpoint" % [
				boss_hp, boss_max
			]

		phase_1_completed.emit()
		level_completed.emit(current_level)
		_update_debug_overlay()


func advance_to_next_level() -> bool:
	if not (finished and game_won and current_level == 4):
		return false
	if not is_instance_valid(player) or not player.alive:
		return false
	if not is_instance_valid(boss) or boss.health > boss.phase_1_threshold or boss.is_destroyed:
		return false

	start_phase_2()
	return true


func start_phase_2() -> void:
	current_level = 5
	finished = false
	game_won = false

	if is_instance_valid(message):
		message.visible = false

	_clear_spawned_projectiles()

	if is_instance_valid(player) and player.alive:
		player.set_physics_process(true)
	if is_instance_valid(weapon_controller):
		weapon_controller.set_firing_enabled(is_primary_weapon_acquired())

	if is_instance_valid(boss):
		boss.start_phase_2()

	phase_2_started.emit()
	_update_hud()
	_update_debug_overlay()


func _on_boss_defeated() -> void:
	if finished and not game_won:
		# If player has already died, Game Over stands deterministically
		return

	finished = true
	game_won = true
	stage_2_completed = true

	if is_instance_valid(player):
		player.set_physics_process(false)
	if is_instance_valid(weapon_controller):
		weapon_controller.set_firing_enabled(false)

	_clear_spawned_projectiles()

	var stage2_complete_payload: Dictionary = {
		"event_id": "stage2_completed",
		"stage": 2,
		"current_level": 5,
		"boss_name": "Guard Cruiser",
		"remaining_player_health": player.health if is_instance_valid(player) else 0,
		"boss_final_health": 0,
		"boss_max_health": 400,
		"stage_completed": true,
		"next_stage": 3,
		"next_stage_available": true
	}

	stage_acquisitions["stage2_completed"] = true
	stage_acquisitions["stage2_complete_payload"] = stage2_complete_payload

	stage_completed.emit(stage2_complete_payload)
	level_completed.emit(5)

	if is_instance_valid(message):
		message.visible = true
		message.text = "STAGE 2 COMPLETE!\n\nGUARD CRUISER DEFEATED\nBOSS HP: 000 / 400\n\nPress [Space/Enter] to Begin Stage 3\nPress [R] to Replay Stage 2"

	_update_hud()
	_update_debug_overlay()


func _on_player_died() -> void:
	if finished and game_won:
		# If boss was already defeated, victory stands deterministically
		return

	finished = true
	game_won = false

	if is_instance_valid(player):
		player.set_physics_process(false)
	if is_instance_valid(weapon_controller):
		weapon_controller.set_firing_enabled(false)

	if is_instance_valid(boss):
		boss.stop_attack()

	_clear_spawned_projectiles()

	if is_instance_valid(message):
		message.visible = true
		message.text = "SHIP DESTROYED (STAGE %d / LEVEL %d)\nPress [R] to Revive at Stage 2 Checkpoint" % [stage_number, current_level]

	_update_debug_overlay()


func advance_to_stage_3() -> Node:
	if _transitioning_to_stage3:
		return null
	if not (finished and game_won and current_level == 5 and stage_2_completed):
		return null
	if not is_instance_valid(player) or not player.alive:
		return null

	_transitioning_to_stage3 = true

	if is_instance_valid(player):
		player.set_physics_process(false)
	if is_instance_valid(weapon_controller):
		weapon_controller.set_firing_enabled(false)
	if is_instance_valid(boss):
		boss.stop_attack()
	_clear_spawned_projectiles()

	var jammer_cd: float = 0.0
	if is_instance_valid(em_jammer_controller) and em_jammer_controller.has_method("get_cooldown_remaining"):
		jammer_cd = em_jammer_controller.get_cooldown_remaining()

	var stage_data: Dictionary = {
		"primary_weapon_acquired": is_primary_weapon_acquired(),
		"shield_acquired": is_shield_acquired(),
		"em_jammer_acquired": is_em_jammer_acquired(),
		"em_jammer_cooldown_remaining": jammer_cd,
		"stage_2_completed": true,
		"from_stage": 2,
		"from_level": 5
	}

	var stage3_inst: Node = STAGE3_MAIN_SCENE.instantiate()
	if stage3_inst.has_method("initialize_from_stage2"):
		stage3_inst.initialize_from_stage2(stage_data)

	if is_inside_tree() and get_tree().current_scene == self:
		var tree: SceneTree = get_tree()
		tree.root.add_child(stage3_inst)
		tree.current_scene = stage3_inst
		queue_free()

	return stage3_inst


func revive_at_stage_checkpoint() -> Node:
	# Reviving from Level 4/5 returns strictly to Stage 2 Level 1!
	_transitioning_to_stage3 = false
	var stage2_scene = load("res://scenes/stage2/stage2_main.tscn") as PackedScene
	var stage2_inst = stage2_scene.instantiate()
	if stage2_inst.has_method("revive_at_stage_checkpoint"):
		stage2_inst.revive_at_stage_checkpoint()

	if is_inside_tree() and get_tree().current_scene == self:
		var tree: SceneTree = get_tree()
		tree.root.add_child(stage2_inst)
		tree.current_scene = stage2_inst
		queue_free()
	return stage2_inst


func _update_hud() -> void:
	if not is_instance_valid(player):
		return

	if is_instance_valid(info):
		info.text = "STAGE %d / LEVEL %d     HP %02d / %02d" % [
			stage_number, current_level, player.health, player.max_health
		]

	if is_instance_valid(boss_bar):
		if is_instance_valid(boss):
			boss_bar.text = "GUARD CRUISER: %03d / %03d HP" % [boss.health, boss.max_health]
		else:
			boss_bar.text = "GUARD CRUISER: --- / 400 HP"

	if is_instance_valid(jammer_status):
		if is_instance_valid(em_jammer_controller):
			if em_jammer_controller.is_ready():
				jammer_status.text = "EM JAMMER: READY [E]"
				jammer_status.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
			else:
				var cd: float = em_jammer_controller.get_cooldown_remaining()
				jammer_status.text = "EM JAMMER: COOLING (%.1fs)" % cd
				jammer_status.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))


func _update_debug_overlay() -> void:
	if not is_instance_valid(debug_label) or not debug_label.visible:
		return
	if not is_instance_valid(player):
		return

	var speed: float = player.movement_velocity.length()
	var state_str: String = player.get_regen_state_string() if player.has_method("get_regen_state_string") else ""
	var p_phase: int = boss.current_phase if is_instance_valid(boss) else 1
	var b_hp: int = boss.health if is_instance_valid(boss) else 0
	var b_stun: String = "STUNNED (%.1fs)" % boss.stun_timer if (is_instance_valid(boss) and boss.is_stunned) else ("DEFEATED" if (is_instance_valid(boss) and boss.is_destroyed) else "ACTIVE")
	var jammer_cd: float = em_jammer_controller.get_cooldown_remaining() if is_instance_valid(em_jammer_controller) else 0.0

	debug_label.text = "[DEBUG OVERLAY — F3 to toggle]\nStage: %d | Level: %d | Mode: Full Arcade Boss Arena\nPlayer HP: %02d / %02d | Speed: %5.1f px/s | Regen: %s\nBoss HP: %d / 400 | Phase: %d | Boss State: %s\nEM Jammer: %s (CD: %.1fs) | Weapon: ACTIVE" % [
		stage_number, current_level,
		player.health, player.max_health, speed, state_str,
		b_hp, p_phase, b_stun,
		"READY" if (is_instance_valid(em_jammer_controller) and em_jammer_controller.is_ready()) else "COOLING",
		jammer_cd
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
			if finished and game_won:
				if current_level == 4:
					advance_to_next_level()
				elif current_level == 5 and stage_2_completed:
					advance_to_stage_3()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()


func is_stage2_completed() -> bool:
	return stage_acquisitions.get("stage2_completed", false)


func is_phase_2_active() -> bool:
	return current_level == 5 and not finished
