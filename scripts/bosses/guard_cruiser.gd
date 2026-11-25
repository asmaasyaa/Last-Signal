extends Area2D
## Guard Cruiser Mini-Boss for LAST SIGNAL Stage 2 Level 4 (Phase 1).
## Features 400 total HP, Phase 1 combat from 400 to 200 HP,
## controlled aimed projectile burst attacks, EM Jammer stun responsiveness,
## official Phase 1 artwork presentation with procedural fallback, and Call Down / Signal Up architecture.

signal health_changed(current_hp: int, max_hp: int)
signal phase_threshold_reached(phase: int)
signal attack_started
signal attack_fired(projectile: Area2D)
signal stunned(duration: float)
signal stun_ended
signal defeated

const ENEMY_PROJECTILE_SCENE = preload("res://scenes/enemies/enemy_projectile.tscn")

enum AttackState {
	COOLDOWN = 0,
	WINDUP = 1,
	FIRING = 2
}

@export var max_health: int = 400
@export var phase_1_threshold: int = 200
@export var move_speed: float = 85.0 # Phase 1: 70-100 px/s
@export var phase_2_move_speed: float = 115.0 # Phase 2 (Provisional TBD): 100-130 px/s
@export var attack_interval: float = 2.6 # Phase 1: 2.0-3.0s
@export var phase_2_attack_interval: float = 2.0 # Phase 2 (Provisional TBD): 1.8-2.2s
@export var windup_duration: float = 0.5 # PROVISIONAL (TBD): 0.4-0.6s
@export var burst_count: int = 3
@export var phase_2_burst_count: int = 5 # Phase 2 (Provisional TBD): 5 projectiles
@export var projectile_speed: float = 300.0
@export var phase_2_projectile_speed: float = 350.0
@export var burst_spread_angle: float = 12.0 # Phase 1 spread degrees
@export var phase_2_burst_spread_angle: float = 20.0 # Phase 2 spread degrees
@export var contact_damage: int = 1
@export var official_art_enabled: bool = true

var health: int = 400
var current_phase: int = 1
var can_take_damage: bool = true
var phase_1_completed: bool = false
var phase_2_started: bool = false
var is_destroyed: bool = false
var is_stunned: bool = false
var stun_timer: float = 0.0

var patrol_direction: float = 1.0 # 1.0 = right, -1.0 = left
var min_patrol_x: float = 260.0
var max_patrol_x: float = 1020.0
var base_y: float = 150.0

var attack_state: AttackState = AttackState.COOLDOWN
var attack_timer: float = 1.5 # Initial delay before first attack
var state_timer: float = 0.0
var contact_cooldown: Dictionary = {}

var target_player: Area2D = null
var projectiles_container: Node = null

@onready var visuals: Node2D = get_node_or_null("Visuals")
@onready var official_art: Node2D = get_node_or_null("Visuals/OfficialArt")
@onready var phase1_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/Phase1Sprite")
@onready var phase2_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/Phase2Sprite")
@onready var dead_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/DeadSprite")
@onready var fallback: Node2D = get_node_or_null("Visuals/ProceduralFallback")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	collision_layer = 18 # Layer 2: Combat Target (2) | Layer 5: Enemies (16)
	collision_mask = 5   # Layer 1: Player (1) | Layer 3: Player Projectiles (4)
	monitoring = true
	monitorable = true

	health = max_health
	can_take_damage = true
	phase_1_completed = false
	phase_2_started = false
	current_phase = 1

	update_visual_state()


func set_target_player(p_player: Area2D) -> void:
	target_player = p_player


func set_projectiles_container(container: Node) -> void:
	projectiles_container = container


func update_visual_state() -> void:
	if not is_instance_valid(visuals):
		visuals = get_node_or_null("Visuals")
	if not is_instance_valid(official_art) and is_instance_valid(visuals):
		official_art = visuals.get_node_or_null("OfficialArt")
	if not is_instance_valid(phase1_sprite) and is_instance_valid(official_art):
		phase1_sprite = official_art.get_node_or_null("Phase1Sprite")
	if not is_instance_valid(phase2_sprite) and is_instance_valid(official_art):
		phase2_sprite = official_art.get_node_or_null("Phase2Sprite")
	if not is_instance_valid(dead_sprite) and is_instance_valid(official_art):
		dead_sprite = official_art.get_node_or_null("DeadSprite")
	if not is_instance_valid(fallback) and is_instance_valid(visuals):
		fallback = visuals.get_node_or_null("ProceduralFallback")

	var active_sprite: Sprite2D = null
	if is_destroyed:
		active_sprite = dead_sprite
	elif current_phase == 2:
		active_sprite = phase2_sprite
	else:
		active_sprite = phase1_sprite

	var has_art: bool = official_art_enabled and is_instance_valid(active_sprite) and (active_sprite.texture != null)
	if is_instance_valid(official_art):
		official_art.visible = has_art
	if is_instance_valid(fallback):
		fallback.visible = not has_art

	# Mutual exclusivity between sprites: exactly one sprite is visible when art is active
	if is_instance_valid(phase1_sprite):
		phase1_sprite.visible = has_art and (not is_destroyed) and (current_phase == 1)
	if is_instance_valid(phase2_sprite):
		phase2_sprite.visible = has_art and (not is_destroyed) and (current_phase == 2)
	if is_instance_valid(dead_sprite):
		dead_sprite.visible = has_art and is_destroyed

	if is_instance_valid(fallback):
		if fallback.has_method("set_phase"):
			fallback.set_phase(current_phase)
		if fallback.has_method("set_destroyed"):
			fallback.set_destroyed(is_destroyed)


func _physics_process(delta: float) -> void:
	if is_destroyed:
		return

	# Handle EM Jammer Stun state
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			end_stun()
		return # Stunned: No movement, no attack updates

	if current_phase == 1 and phase_1_completed:
		return # Phase 1 completed: Boss holds stationary disabled stance

	# 1. Horizontal patrol movement with gentle vertical sinusoidal bobbing
	var cur_speed: float = phase_2_move_speed if current_phase == 2 else move_speed
	position.x += patrol_direction * cur_speed * delta
	if position.x > max_patrol_x:
		position.x = max_patrol_x
		patrol_direction = -1.0
	elif position.x < min_patrol_x:
		position.x = min_patrol_x
		patrol_direction = 1.0

	# 2. Attack state machine
	_update_attack_state(delta)

	# 3. Contact damage with player
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
			# Burst fires instantaneously or via brief stagger
			attack_state = AttackState.COOLDOWN
			attack_timer = phase_2_attack_interval if current_phase == 2 else attack_interval


func start_attack_windup() -> void:
	if is_destroyed or is_stunned:
		return
	if current_phase == 1 and phase_1_completed:
		return

	attack_state = AttackState.WINDUP
	state_timer = windup_duration
	if is_instance_valid(fallback) and fallback.has_method("set_charging_attack"):
		fallback.set_charging_attack(true)
	attack_started.emit()


func fire_attack_burst() -> void:
	if is_destroyed or is_stunned or not ENEMY_PROJECTILE_SCENE:
		return
	if current_phase == 1 and phase_1_completed:
		return

	if is_instance_valid(fallback) and fallback.has_method("set_charging_attack"):
		fallback.set_charging_attack(false)

	# Aim direction towards player
	var base_aim := Vector2.DOWN
	if is_instance_valid(target_player) and ("alive" not in target_player or target_player.alive):
		var diff = target_player.global_position - global_position
		if diff.length_squared() > 1.0:
			base_aim = diff.normalized()

	# In Phase 2: 5 projectiles spread across ~20 degrees. In Phase 1: 3 projectiles spread across ~12 degrees.
	var angles: Array = []
	var proj_speed: float = projectile_speed
	if current_phase == 2:
		angles = [0.0, -0.175, 0.175, -0.35, 0.35]
		proj_speed = phase_2_projectile_speed
	else:
		angles = [0.0, -0.21, 0.21]
		proj_speed = projectile_speed

	var container: Node = projectiles_container if is_instance_valid(projectiles_container) else get_parent()

	for angle in angles:
		var proj = ENEMY_PROJECTILE_SCENE.instantiate()
		proj.direction = base_aim.rotated(angle)
		proj.speed = proj_speed
		proj.global_position = global_position + proj.direction * 36.0
		if is_instance_valid(container):
			container.add_child(proj)
		attack_fired.emit(proj)

	attack_state = AttackState.COOLDOWN
	attack_timer = phase_2_attack_interval if current_phase == 2 else attack_interval


func stop_attack() -> void:
	attack_state = AttackState.COOLDOWN
	state_timer = 0.0
	attack_timer = phase_2_attack_interval if current_phase == 2 else attack_interval
	if is_instance_valid(fallback) and fallback.has_method("set_charging_attack"):
		fallback.set_charging_attack(false)


func apply_stun(duration: float) -> void:
	if is_destroyed:
		return
	if current_phase == 1 and phase_1_completed:
		return

	is_stunned = true
	stun_timer = duration
	stop_attack()

	if is_instance_valid(fallback) and fallback.has_method("set_stunned"):
		fallback.set_stunned(true)

	stunned.emit(duration)


func end_stun() -> void:
	is_stunned = false
	stun_timer = 0.0

	if is_instance_valid(fallback) and fallback.has_method("set_stunned"):
		fallback.set_stunned(false)

	stun_ended.emit()


func start_phase_2() -> void:
	if is_destroyed:
		return
	current_phase = 2
	phase_2_started = true
	can_take_damage = true
	health = clampi(health, 1, phase_1_threshold)
	if is_stunned:
		end_stun()
	stop_attack()
	attack_timer = 1.0 # Initial engagement pause before Phase 2 bursts
	update_visual_state()


func take_damage(amount: int) -> void:
	if not can_take_damage or is_destroyed or amount <= 0:
		return

	if current_phase == 1:
		if phase_1_completed:
			return
		# In Phase 1, damage is strictly clamped so health does not drop below phase_1_threshold (200)
		var max_allowed_damage: int = health - phase_1_threshold
		if max_allowed_damage <= 0:
			return

		var actual_damage: int = mini(amount, max_allowed_damage)
		health -= actual_damage
		health_changed.emit(health, max_health)

		if health <= phase_1_threshold and not phase_1_completed:
			_on_phase_1_completed()
	elif current_phase == 2:
		var actual_damage: int = mini(amount, health)
		health -= actual_damage
		health_changed.emit(health, max_health)

		if health <= 0:
			_on_defeated()


func _on_phase_1_completed() -> void:
	phase_1_completed = true
	can_take_damage = false
	health = phase_1_threshold # Exactly 200 HP
	stop_attack()
	if is_stunned:
		end_stun()

	phase_threshold_reached.emit(1)


func _on_defeated() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	can_take_damage = false
	health = 0
	stop_attack()
	if is_stunned:
		end_stun()

	# Safely disable collision shapes on defeat
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)

	update_visual_state()
	defeated.emit()


func _check_player_contact(delta: float) -> void:
	# Decrement existing contact pair cooldowns
	var ids_to_erase: Array = []
	for id in contact_cooldown.keys():
		contact_cooldown[id] = float(contact_cooldown[id]) - delta
		var inst = instance_from_id(id)
		if not is_instance_valid(inst) or inst.is_queued_for_deletion():
			ids_to_erase.append(id)
	for id in ids_to_erase:
		contact_cooldown.erase(id)

	# Check contact with player
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
