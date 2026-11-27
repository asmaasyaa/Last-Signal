extends Area2D
## Stage 3 Final Boss entity for LAST SIGNAL.
## Persistent 4-phase boss (800 total HP):
## - Phase 1 (Level 1): 800 -> 600 HP (implemented in Milestone 11)
## - Phase 2 (Level 2): 600 -> 400 HP (reserved boundary, unimplemented)
## - Phase 3 (Level 3): 400 -> 200 HP (reserved boundary, unimplemented)
## - Phase 4 (Level 4): 200 -> 0 HP (reserved boundary, unimplemented)
## Note: Canonical proper name is not yet confirmed by the team; neutral "Final Boss" identifier is used.

signal health_changed(current_hp: int, max_hp: int)
signal phase_threshold_reached(phase: int)
signal attack_started
signal attack_fired(projectile: Area2D)
signal stunned(duration: float)
signal stun_ended
signal defeated # Reserved for future Phase 4 at 0 HP; never emitted at Phase 1 completion (600 HP).

const ENEMY_PROJECTILE_SCENE: PackedScene = preload("res://scenes/enemies/enemy_projectile.tscn")

enum BossState {
	PHASE_1 = 1,
	PHASE_1_COMPLETE = 10,
	PHASE_2 = 2,
	PHASE_3 = 3,
	PHASE_4 = 4,
	DEFEATED = 99
}

enum AttackState {
	COOLDOWN = 0,
	WINDUP = 1,
	FIRING = 2
}

# Health & Four-Phase Boundaries
@export var max_health: int = 800
@export var phase_1_threshold: int = 600
@export var phase_2_threshold: int = 400
@export var phase_3_threshold: int = 200
@export var phase_4_threshold: int = 0

# Provisional Phase 1 Combat Configuration (TBD — Subject to Lead Review)
@export var phase_1_move_speed: float = 65.0 # Provisional: 65 px/s upper arena patrol
@export var phase_1_attack_interval: float = 2.8 # Provisional: 2.8s between volleys
@export var phase_1_windup_duration: float = 0.6 # Provisional: 0.6s telegraph warning
@export var phase_1_projectile_speed: float = 300.0 # Provisional: 300 px/s
@export var phase_1_projectile_damage: int = 1 # Provisional: 1 HP per bolt
@export var phase_1_burst_count: int = 3 # Provisional: 3 dodgeable projectiles per burst
@export var phase_1_burst_spread_angle: float = 18.0 # Provisional total fan spread (degrees)

@export var min_patrol_x: float = 240.0
@export var max_patrol_x: float = 1040.0
@export var arena_y: float = 160.0
@export var contact_damage: int = 1
@export var official_art_enabled: bool = true

var health: int = 800
var boss_state: BossState = BossState.PHASE_1
var current_phase: int = 1
var can_take_damage: bool = true
var phase_1_completed: bool = false
var is_destroyed: bool = false
var is_stunned: bool = false
var stun_timer: float = 0.0

var patrol_direction: float = 1.0
var attack_state: AttackState = AttackState.COOLDOWN
var attack_timer: float = 1.5
var state_timer: float = 0.0
var locked_aim_direction: Vector2 = Vector2.DOWN
var contact_cooldown: Dictionary = {}

var target_player: Area2D = null
var projectiles_container: Node = null

@onready var visuals: Node2D = get_node_or_null("Visuals")
@onready var official_art: Node2D = get_node_or_null("Visuals/OfficialArt")
@onready var phase1_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/Phase1Sprite")
@onready var phase2_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/Phase2Sprite")
@onready var phase3_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/Phase3Sprite")
@onready var phase4_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/Phase4Sprite")
@onready var dead_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/DeadSprite")
@onready var fallback: Node2D = get_node_or_null("Visuals/ProceduralFallback")
@onready var telegraph_overlay: Node2D = get_node_or_null("Visuals/TelegraphOverlay")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	collision_layer = 18 # Layer 2: Combat Target (2) | Layer 5: Enemies (16)
	collision_mask = 5   # Layer 1: Player (1) | Layer 3: Player Projectiles (4)
	reset_for_phase_1()


func reset_for_phase_1() -> void:
	health = max_health
	current_phase = 1
	boss_state = BossState.PHASE_1
	can_take_damage = true
	phase_1_completed = false
	is_destroyed = false
	is_stunned = false
	stun_timer = 0.0
	patrol_direction = 1.0
	attack_state = AttackState.COOLDOWN
	attack_timer = 1.5
	state_timer = 0.0
	locked_aim_direction = Vector2.DOWN
	contact_cooldown.clear()

	# Re-enable physics collision safely
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	monitoring = true
	monitorable = true
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", false)
		collision_shape.disabled = false

	update_visual_state()


func set_target_player(p_player: Area2D) -> void:
	target_player = p_player


func set_projectiles_container(container: Node) -> void:
	projectiles_container = container


func get_phase_bounds(phase_num: int) -> Dictionary:
	match phase_num:
		1:
			return {"start_hp": max_health, "end_hp": phase_1_threshold, "level": 1}
		2:
			return {"start_hp": phase_1_threshold, "end_hp": phase_2_threshold, "level": 2}
		3:
			return {"start_hp": phase_2_threshold, "end_hp": phase_3_threshold, "level": 3}
		4:
			return {"start_hp": phase_3_threshold, "end_hp": phase_4_threshold, "level": 4}
		_:
			return {}


func update_visual_state() -> void:
	if not is_instance_valid(visuals):
		visuals = get_node_or_null("Visuals")
	if not is_instance_valid(official_art) and is_instance_valid(visuals):
		official_art = visuals.get_node_or_null("OfficialArt")
	if not is_instance_valid(phase1_sprite) and is_instance_valid(official_art):
		phase1_sprite = official_art.get_node_or_null("Phase1Sprite")
	if not is_instance_valid(phase2_sprite) and is_instance_valid(official_art):
		phase2_sprite = official_art.get_node_or_null("Phase2Sprite")
	if not is_instance_valid(phase3_sprite) and is_instance_valid(official_art):
		phase3_sprite = official_art.get_node_or_null("Phase3Sprite")
	if not is_instance_valid(phase4_sprite) and is_instance_valid(official_art):
		phase4_sprite = official_art.get_node_or_null("Phase4Sprite")
	if not is_instance_valid(dead_sprite) and is_instance_valid(official_art):
		dead_sprite = official_art.get_node_or_null("DeadSprite")
	if not is_instance_valid(fallback) and is_instance_valid(visuals):
		fallback = visuals.get_node_or_null("ProceduralFallback")
	if not is_instance_valid(telegraph_overlay) and is_instance_valid(visuals):
		telegraph_overlay = visuals.get_node_or_null("TelegraphOverlay")

	var active_sprite: Sprite2D = null
	if is_destroyed or boss_state == BossState.DEFEATED:
		active_sprite = dead_sprite
	elif current_phase == 4:
		active_sprite = phase4_sprite
	elif current_phase == 3:
		active_sprite = phase3_sprite
	elif current_phase == 2:
		active_sprite = phase2_sprite
	else:
		active_sprite = phase1_sprite

	var has_art: bool = official_art_enabled and is_instance_valid(active_sprite) and (active_sprite.texture != null)
	if is_instance_valid(official_art):
		official_art.visible = has_art
	if is_instance_valid(fallback):
		fallback.visible = not has_art
		if fallback.has_method("set_phase"):
			fallback.set_phase(current_phase)
		if fallback.has_method("set_destroyed"):
			fallback.set_destroyed(is_destroyed)

	# Strict mutual exclusivity: only the active state sprite displays
	var show_alive: bool = has_art and (not is_destroyed) and (boss_state != BossState.DEFEATED)
	if is_instance_valid(phase1_sprite):
		phase1_sprite.visible = show_alive and (current_phase == 1)
	if is_instance_valid(phase2_sprite):
		phase2_sprite.visible = show_alive and (current_phase == 2)
	if is_instance_valid(phase3_sprite):
		phase3_sprite.visible = show_alive and (current_phase == 3)
	if is_instance_valid(phase4_sprite):
		phase4_sprite.visible = show_alive and (current_phase == 4)
	if is_instance_valid(dead_sprite):
		dead_sprite.visible = has_art and (is_destroyed or boss_state == BossState.DEFEATED)


func _physics_process(delta: float) -> void:
	# Only Phase 1 is active in Milestone 11; Phase 2-4, PHASE_1_COMPLETE, and DEFEATED do not run active AI.
	if boss_state != BossState.PHASE_1 or is_destroyed:
		return

	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			end_stun()
		return

	# 1. Horizontal upper-arena patrol
	position.x += patrol_direction * phase_1_move_speed * delta
	if position.x >= max_patrol_x:
		position.x = max_patrol_x
		patrol_direction = -1.0
	elif position.x <= min_patrol_x:
		position.x = min_patrol_x
		patrol_direction = 1.0

	# 2. Attack state machine
	_update_attack_state(delta)

	# 3. Contact damage pair cooldown handling
	_check_player_contact(delta)


func _update_attack_state(delta: float) -> void:
	match attack_state:
		AttackState.COOLDOWN:
			attack_timer -= delta
			if attack_timer <= 0.0:
				start_attack_windup()

		AttackState.WINDUP:
			state_timer -= delta
			if state_timer <= 0.0:
				fire_attack_burst()

		AttackState.FIRING:
			attack_state = AttackState.COOLDOWN
			attack_timer = phase_1_attack_interval


func start_attack_windup() -> void:
	if boss_state != BossState.PHASE_1 or is_destroyed or is_stunned:
		return

	# Lock target aim direction at windup start so player can dodge out of trajectory
	locked_aim_direction = Vector2.DOWN
	if is_instance_valid(target_player) and ("alive" not in target_player or target_player.alive):
		var diff: Vector2 = target_player.global_position - global_position
		if diff.length_squared() > 1.0:
			locked_aim_direction = diff.normalized()

	attack_state = AttackState.WINDUP
	state_timer = phase_1_windup_duration
	if is_instance_valid(fallback) and fallback.has_method("set_charging_attack"):
		fallback.set_charging_attack(true)
	_sync_telegraph_overlay()
	attack_started.emit()


func fire_attack_burst() -> void:
	if boss_state != BossState.PHASE_1 or is_destroyed or is_stunned or not ENEMY_PROJECTILE_SCENE:
		return

	if is_instance_valid(fallback) and fallback.has_method("set_charging_attack"):
		fallback.set_charging_attack(false)

	var count: int = maxi(phase_1_burst_count, 1)
	var half_spread_rad: float = deg_to_rad(phase_1_burst_spread_angle * 0.5)
	var container: Node = projectiles_container if is_instance_valid(projectiles_container) else get_parent()

	for i in range(count):
		var t: float = 0.0 if count == 1 else float(i) / float(count - 1)
		var angle_offset: float = 0.0 if count == 1 else lerpf(-half_spread_rad, half_spread_rad, t)
		var proj_dir: Vector2 = locked_aim_direction.rotated(angle_offset)

		var proj = ENEMY_PROJECTILE_SCENE.instantiate()
		proj.direction = proj_dir
		proj.speed = phase_1_projectile_speed
		proj.damage = phase_1_projectile_damage
		proj.global_position = global_position + proj_dir * 42.0
		if is_instance_valid(container):
			container.add_child(proj)
		attack_fired.emit(proj)

	attack_state = AttackState.COOLDOWN
	attack_timer = phase_1_attack_interval
	_sync_telegraph_overlay()


func stop_attack() -> void:
	attack_state = AttackState.COOLDOWN
	state_timer = 0.0
	attack_timer = phase_1_attack_interval
	if is_instance_valid(fallback) and fallback.has_method("set_charging_attack"):
		fallback.set_charging_attack(false)
	_sync_telegraph_overlay()


func apply_stun(duration: float) -> void:
	if is_destroyed or boss_state != BossState.PHASE_1:
		return

	is_stunned = true
	stun_timer = duration
	stop_attack()

	if is_instance_valid(fallback) and fallback.has_method("set_stunned"):
		fallback.set_stunned(true)
	_sync_telegraph_overlay()

	stunned.emit(duration)


func end_stun() -> void:
	is_stunned = false
	stun_timer = 0.0

	if is_instance_valid(fallback) and fallback.has_method("set_stunned"):
		fallback.set_stunned(false)
	_sync_telegraph_overlay()

	stun_ended.emit()


func _sync_telegraph_overlay() -> void:
	if not is_instance_valid(telegraph_overlay):
		return
	if telegraph_overlay.has_method("set_state"):
		telegraph_overlay.set_state(attack_state == AttackState.WINDUP, is_stunned, locked_aim_direction)


func take_damage(amount: int) -> void:
	if not can_take_damage or is_destroyed or amount <= 0:
		return
	if boss_state != BossState.PHASE_1 or phase_1_completed:
		return

	# Clamp health cleanly at phase_1_threshold (600 HP)
	var max_allowed_damage: int = health - phase_1_threshold
	if max_allowed_damage <= 0:
		return

	var actual_damage: int = mini(amount, max_allowed_damage)
	health -= actual_damage
	health_changed.emit(health, max_health)

	if health <= phase_1_threshold and not phase_1_completed:
		_on_phase_1_completed()


func _on_phase_1_completed() -> void:
	phase_1_completed = true
	boss_state = BossState.PHASE_1_COMPLETE
	can_take_damage = false
	health = phase_1_threshold
	stop_attack()
	if is_stunned:
		end_stun()

	# Safely stop physics collision upon Phase 1 completion while preserving visible boss node
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)

	phase_threshold_reached.emit(1)


func _check_player_contact(delta: float) -> void:
	var ids_to_erase: Array = []
	for id in contact_cooldown.keys():
		contact_cooldown[id] = float(contact_cooldown[id]) - delta
		var inst = instance_from_id(id)
		if not is_instance_valid(inst) or inst.is_queued_for_deletion():
			ids_to_erase.append(id)
	for id in ids_to_erase:
		contact_cooldown.erase(id)

	for other in get_overlapping_areas():
		if not is_instance_valid(other) or other.is_queued_for_deletion():
			continue
		if not (other.is_in_group("player") or other.name == "Player"):
			continue

		var id: int = other.get_instance_id()
		var cd_remaining: float = float(contact_cooldown.get(id, 0.0))
		if cd_remaining <= 0.0:
			if other.has_method("take_damage"):
				other.take_damage(contact_damage)
			contact_cooldown[id] = 0.5


func get_visuals_node() -> Node2D:
	if not is_instance_valid(visuals):
		visuals = get_node_or_null("Visuals")
	return visuals
