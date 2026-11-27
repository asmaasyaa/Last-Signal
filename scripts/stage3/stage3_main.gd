extends Node2D
## Stage 3 Coordinator for LAST SIGNAL (Stage 3 Level 1: Final Boss Phase 1).
## Implements fixed 1280x720 arcade encounter arena, persistent 4-phase Final Boss foundation
## (Phase 1 active: 800 -> 600 HP threshold), equipment inheritance (Primary Weapon, Shield,
## EM Jammer), Stage 3 checkpoint revival, and Call Down / Signal Up architecture.
## Scope: Stage 3 Level 1 (Phase 1) ONLY. Levels 2-5 and escape sequence are deferred.

signal level_completed(level: int)
signal phase_1_completed

@export var stage_number: int = 3
@export var current_level: int = 1
@export var stage_checkpoint_level: int = 1

var finished: bool = false
var game_won: bool = false
var phase_1_complete: bool = false
var stars: Array[Vector2] = []
var star_offset: float = 0.0

# Default equipment flags allow direct F6 launch of Stage 3 Level 1;
# initialize_from_stage2() applies explicit stage transfer state.
var stage_acquisitions: Dictionary = {
	"primary_weapon_acquired": true,
	"shield_acquired": true,
	"em_jammer_acquired": true
}

var _pending_em_jammer_cooldown: float = 0.0
var _apply_pending_cooldown_on_ready: bool = false
var show_debug_overlay: bool = false

@onready var player: Area2D = get_node_or_null("Player")
@onready var boss: Area2D = get_node_or_null("FinalBoss")
@onready var weapon_controller: Node = get_node_or_null("WeaponController")
@onready var em_jammer_controller: Node2D = get_node_or_null("EMJammerController")
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
	for i in range(120):
		stars.append(Vector2(randf_range(0.0, 1280.0), randf_range(0.0, 720.0)))

	_resolve_node_refs()
	_setup_hud_labels()
	_setup_debug_overlay()

	# Stage 3 starts at Level 1 with full 12/12 HP under the established new-stage policy.
	start_level(1, 12)

	if _apply_pending_cooldown_on_ready and is_instance_valid(em_jammer_controller):
		em_jammer_controller.cooldown_remaining = maxf(0.0, _pending_em_jammer_cooldown)
		_apply_pending_cooldown_on_ready = false
		_update_hud()
		_update_debug_overlay()


func _resolve_node_refs() -> void:
	if not is_instance_valid(player):
		player = get_node_or_null("Player")
	if not is_instance_valid(boss):
		boss = get_node_or_null("FinalBoss")
	if not is_instance_valid(weapon_controller):
		weapon_controller = get_node_or_null("WeaponController")
	if not is_instance_valid(em_jammer_controller):
		em_jammer_controller = get_node_or_null("EMJammerController")
	if not is_instance_valid(projectiles_container):
		projectiles_container = get_node_or_null("Projectiles")
	if not is_instance_valid(enemy_projectiles_container):
		enemy_projectiles_container = get_node_or_null("EnemyProjectiles")
	if not is_instance_valid(hud):
		hud = get_node_or_null("HUD")
	if not is_instance_valid(info):
		info = get_node_or_null("HUD/Info")
	if not is_instance_valid(boss_bar):
		boss_bar = get_node_or_null("HUD/BossBar")
	if not is_instance_valid(jammer_status):
		jammer_status = get_node_or_null("HUD/JammerStatus")
	if not is_instance_valid(message):
		message = get_node_or_null("HUD/Message")


func initialize_from_stage2(p_stage2_data: Dictionary) -> void:
	stage_number = 3
	current_level = 1
	stage_acquisitions = p_stage2_data.duplicate()
	stage_acquisitions["primary_weapon_acquired"] = bool(p_stage2_data.get("primary_weapon_acquired", false))
	stage_acquisitions["shield_acquired"] = bool(p_stage2_data.get("shield_acquired", false))
	stage_acquisitions["em_jammer_acquired"] = bool(p_stage2_data.get("em_jammer_acquired", false))

	# Preserve remaining EM Jammer cooldown across the new-stage boundary (provisional rule).
	_pending_em_jammer_cooldown = maxf(0.0, float(p_stage2_data.get("em_jammer_cooldown_remaining", 0.0)))
	_apply_pending_cooldown_on_ready = true

	if is_inside_tree():
		start_level(1, 12)
		if is_instance_valid(em_jammer_controller):
			em_jammer_controller.cooldown_remaining = _pending_em_jammer_cooldown
			_apply_pending_cooldown_on_ready = false
		_update_hud()
		_update_debug_overlay()


func is_primary_weapon_acquired() -> bool:
	return stage_acquisitions.get("primary_weapon_acquired", false)


func is_shield_acquired() -> bool:
	return stage_acquisitions.get("shield_acquired", false)


func is_em_jammer_acquired() -> bool:
	return stage_acquisitions.get("em_jammer_acquired", false)


func set_em_jammer_acquired(acquired: bool) -> void:
	stage_acquisitions["em_jammer_acquired"] = acquired
	if is_instance_valid(em_jammer_controller):
		em_jammer_controller.set_acquired(acquired)
	_update_hud()
	_update_debug_overlay()


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
	debug_label.offset_top = 82.0
	debug_label.offset_right = 760.0
	debug_label.offset_bottom = 260.0
	debug_label.add_theme_font_size_override("font_size", 16)
	debug_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0, 0.95))
	debug_label.visible = show_debug_overlay
	if is_instance_valid(hud):
		hud.add_child(debug_label)


func start_level(target_level: int, starting_hp: int = 12) -> void:
	# Milestone 11 strictly supports Stage 3 Level 1 (Final Boss Phase 1)
	if target_level != 1:
		return

	_resolve_node_refs()
	current_level = 1
	finished = false
	game_won = false
	phase_1_complete = false

	_clear_spawned_projectiles()

	# 1. Setup Player through public interfaces only
	if is_instance_valid(player):
		if not player.health_changed.is_connected(_on_player_health_changed):
			player.health_changed.connect(_on_player_health_changed)
		if not player.died.is_connected(_on_player_died):
			player.died.connect(_on_player_died)

		player.prepare_for_level(starting_hp)
		player.position = Vector2(640.0, 560.0)

	# 2. Setup Weapon Controller through public interfaces only
	if is_instance_valid(weapon_controller):
		var proj_parent: Node = projectiles_container if is_instance_valid(projectiles_container) else self
		weapon_controller.setup(player, proj_parent)
		weapon_controller.set_firing_enabled(is_primary_weapon_acquired())

	# 3. Setup EM Jammer Controller through public interfaces only
	if is_instance_valid(em_jammer_controller):
		em_jammer_controller.setup(player, self)
		em_jammer_controller.set_acquired(is_em_jammer_acquired())

	# 4. Setup Persistent Final Boss in Phase 1 (800 -> 600 HP)
	if is_instance_valid(boss):
		boss.set_target_player(player)
		var enemy_proj_parent: Node = enemy_projectiles_container if is_instance_valid(enemy_projectiles_container) else self
		boss.set_projectiles_container(enemy_proj_parent)

		if not boss.phase_threshold_reached.is_connected(_on_boss_phase_threshold_reached):
			boss.phase_threshold_reached.connect(_on_boss_phase_threshold_reached)
		if not boss.health_changed.is_connected(_on_boss_health_changed):
			boss.health_changed.connect(_on_boss_health_changed)

		boss.position = Vector2(640.0, 160.0)
		boss.reset_for_phase_1()

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
	star_offset = fmod(star_offset + 34.0 * delta, 720.0)
	queue_redraw()

	if finished:
		_update_debug_overlay()
		return

	_update_hud()
	_update_debug_overlay()


func _draw() -> void:
	# Stage 3 deep crimson/indigo core sector space backdrop
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.032, 0.018, 0.046))
	for point in stars:
		var scroll_y: float = fmod(point.y + star_offset, 720.0)
		draw_circle(Vector2(point.x, scroll_y), 1.3, Color(0.82, 0.72, 0.92, 0.65))


func _on_boss_health_changed(_current: int, _maximum: int) -> void:
	_update_hud()
	_update_debug_overlay()


func _on_player_health_changed(_current: int, _maximum: int) -> void:
	_update_hud()
	_update_debug_overlay()


func _on_boss_phase_threshold_reached(phase: int) -> void:
	if phase != 1:
		return
	if finished:
		# Deterministic tie-breaking: if player has already died, Game Over stands.
		return

	finished = true
	game_won = true
	phase_1_complete = true

	if is_instance_valid(player):
		player.set_physics_process(false)
	if is_instance_valid(weapon_controller):
		weapon_controller.set_firing_enabled(false)

	_clear_spawned_projectiles()

	if is_instance_valid(message):
		message.visible = true
		var boss_hp: int = boss.health if is_instance_valid(boss) else 600
		var boss_max: int = boss.max_health if is_instance_valid(boss) else 800
		message.text = "STAGE 3 / LEVEL 1 COMPLETE\nFINAL BOSS — PHASE 1 COMPLETE\nBOSS HP: %03d / %03d\n\n[PHASE 2 — NEXT MILESTONE]\nPress [R] to Replay Stage 3" % [
			boss_hp, boss_max
		]

	phase_1_completed.emit()
	level_completed.emit(current_level)
	_update_hud()
	_update_debug_overlay()


func _on_player_died() -> void:
	if finished and game_won:
		# Deterministic tie-breaking: if Phase 1 completion already finalized, victory stands.
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
		message.text = "SHIP DESTROYED (STAGE %d / LEVEL %d)\nPress [R] to Revive at Stage 3 Checkpoint" % [
			stage_number, current_level
		]

	_update_hud()
	_update_debug_overlay()


func revive_at_stage_checkpoint() -> void:
	# Stage 3 Checkpoint: revives strictly at Stage 3 Level 1 with full 12 HP,
	# resetting boss to 800 HP, clearing projectiles & combat cooldowns, and retaining earned gear.
	_apply_pending_cooldown_on_ready = false
	_pending_em_jammer_cooldown = 0.0

	if is_instance_valid(em_jammer_controller):
		em_jammer_controller.cooldown_remaining = 0.0
	if is_instance_valid(weapon_controller):
		weapon_controller.fire_cooldown = 0.0
		weapon_controller.clear_projectiles()

	start_level(stage_checkpoint_level, 12)


func advance_to_next_level() -> bool:
	# Stage 3 Level 2 (Phase 2) is deferred to Milestone 12
	return false


func _update_hud() -> void:
	if not is_instance_valid(player):
		return

	if is_instance_valid(info):
		info.text = "STAGE %d / LEVEL %d     HP %02d / %02d" % [
			stage_number, current_level, player.health, player.max_health
		]

	if is_instance_valid(boss_bar):
		if is_instance_valid(boss):
			boss_bar.text = "FINAL BOSS: %03d / %03d HP" % [boss.health, boss.max_health]
		else:
			boss_bar.text = "FINAL BOSS: --- / 800 HP"

	if is_instance_valid(jammer_status):
		if not is_em_jammer_acquired():
			jammer_status.text = "EM JAMMER: NOT ACQUIRED"
			jammer_status.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		elif is_instance_valid(em_jammer_controller):
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

	var b_hp: int = boss.health if is_instance_valid(boss) else 0
	var b_phase: int = boss.current_phase if is_instance_valid(boss) else 1
	var b_state: String = "PHASE_1_COMPLETE" if (is_instance_valid(boss) and boss.phase_1_completed) else ("STUNNED" if (is_instance_valid(boss) and boss.is_stunned) else "ACTIVE")
	var jammer_cd: float = em_jammer_controller.get_cooldown_remaining() if is_instance_valid(em_jammer_controller) else 0.0

	debug_label.text = "[DEBUG OVERLAY — F3 to toggle]\nStage: %d | Level: %d | Mode: Full Arcade Final Boss\nPlayer HP: %02d / %02d | Weapon: %s | EM Jammer: %s (CD: %.1fs)\nFinal Boss HP: %d / 800 | Phase: %d | State: %s" % [
		stage_number, current_level,
		player.health, player.max_health,
		"ACTIVE" if is_primary_weapon_acquired() else "NONE",
		"READY" if (is_instance_valid(em_jammer_controller) and em_jammer_controller.is_ready()) else ("LOCKED" if not is_em_jammer_acquired() else "COOLING"),
		jammer_cd,
		b_hp, b_phase, b_state
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
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()
