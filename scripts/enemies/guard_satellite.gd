extends Area2D
## Guard Satellite hostile security automaton for LAST SIGNAL Stage 2 Level 2.
## Features 20 HP, horizontal side-scrolling drift, official artwork presentation with procedural fallback,
## mutual 1 HP contact damage with rate-limited cooldowns, and an accurate telegraph-based laser attack.

signal damaged(amount: int, remaining_health: int)
signal destroyed
signal attack_telegraph_started(locked_direction: Vector2)
signal laser_fired(locked_direction: Vector2)
signal laser_hit(target: Area2D)

enum AttackState {
	COOLDOWN = 0,
	TELEGRAPH = 1,
	FIRING = 2
}

@export var max_health: int = 20
@export var speed: float = 90.0 # PROVISIONAL (TBD): 75-110 px/s
@export var contact_damage: int = 1
@export var laser_damage: int = 1
@export var telegraph_duration: float = 0.5 # PROVISIONAL (TBD): 0.4-0.7s telegraph warning
@export var laser_duration: float = 0.15 # PROVISIONAL (TBD): 0.10-0.20s active beam
@export var fire_interval_min: float = 2.2 # PROVISIONAL (TBD): 2.0-3.5s
@export var fire_interval_max: float = 3.2
@export var official_art_enabled: bool = true

var health: int = 20
var is_destroyed: bool = false
var attack_state: AttackState = AttackState.COOLDOWN
var state_timer: float = 0.0
var locked_aim_direction: Vector2 = Vector2.LEFT
var has_dealt_damage: bool = false
var contact_cooldown: Dictionary = {} # int (instance_id) -> float (cooldown remaining)
var target_player: Area2D = null

@onready var visuals: Node2D = get_node_or_null("Visuals")
@onready var official_art: Node2D = get_node_or_null("Visuals/OfficialArt")
@onready var idle_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/IdleSprite")
@onready var attacking_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/AttackingSprite")
@onready var fallback: Node2D = get_node_or_null("Visuals/ProceduralFallback")
@onready var laser_node: Area2D = get_node_or_null("Laser")
@onready var laser_collision: CollisionShape2D = get_node_or_null("Laser/CollisionShape2D")


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("guard_satellites")
	collision_layer = 18 # Layer 2: Combat Target (2) | Layer 5: Enemies (16)
	collision_mask = 5   # Layer 1: Player (1) | Layer 3: Player Projectiles (4)
	monitoring = true
	monitorable = true

	health = max_health
	# Initial stagger delay so satellites don't fire at the exact same moment
	state_timer = randf_range(1.0, fire_interval_min)
	attack_state = AttackState.COOLDOWN

	_setup_laser_node()
	update_visual_state()


func set_target_player(player: Area2D) -> void:
	target_player = player


func _setup_laser_node() -> void:
	if not is_instance_valid(laser_node):
		laser_node = get_node_or_null("Laser")
	if is_instance_valid(laser_node):
		laser_node.collision_layer = 32 # Layer 6: Enemy Projectiles
		laser_node.collision_mask = 1   # Layer 1: Player
		laser_node.monitoring = false
		laser_node.monitorable = false
		if not laser_node.area_entered.is_connected(_on_laser_area_entered):
			laser_node.area_entered.connect(_on_laser_area_entered)


func update_visual_state() -> void:
	if not is_instance_valid(visuals):
		visuals = get_node_or_null("Visuals")
	if not is_instance_valid(official_art) and is_instance_valid(visuals):
		official_art = visuals.get_node_or_null("OfficialArt")
	if not is_instance_valid(idle_sprite) and is_instance_valid(official_art):
		idle_sprite = official_art.get_node_or_null("IdleSprite")
	if not is_instance_valid(attacking_sprite) and is_instance_valid(official_art):
		attacking_sprite = official_art.get_node_or_null("AttackingSprite")
	if not is_instance_valid(fallback) and is_instance_valid(visuals):
		fallback = visuals.get_node_or_null("ProceduralFallback")

	var has_art: bool = official_art_enabled and is_instance_valid(idle_sprite) and (idle_sprite.texture != null)
	if is_instance_valid(official_art):
		official_art.visible = has_art
	if is_instance_valid(fallback):
		fallback.visible = not has_art

	_update_pose_visibility()


func _update_pose_visibility() -> void:
	var is_active: bool = attack_state == AttackState.FIRING or attack_state == AttackState.TELEGRAPH
	if is_instance_valid(official_art) and official_art.visible:
		if is_instance_valid(attacking_sprite):
			attacking_sprite.visible = is_active
		if is_instance_valid(idle_sprite):
			idle_sprite.visible = not is_active
	if is_instance_valid(fallback) and fallback.visible and fallback.has_method("set_attacking"):
		fallback.set_attacking(is_active)


func _physics_process(delta: float) -> void:
	if is_destroyed:
		return

	# Side-scrolling horizontal drift
	position.x -= speed * delta

	# Offscreen cleanup past left edge
	if position.x < -120.0:
		queue_free()
		return

	_update_attack_state_machine(delta)
	_check_player_contact(delta)


func _update_attack_state_machine(delta: float) -> void:
	state_timer -= delta

	match attack_state:
		AttackState.COOLDOWN:
			if state_timer <= 0.0:
				start_telegraph()
		AttackState.TELEGRAPH:
			if state_timer <= 0.0:
				start_firing()
		AttackState.FIRING:
			_check_laser_hit()
			if state_timer <= 0.0:
				end_firing()


func start_telegraph() -> void:
	if is_destroyed:
		return
	attack_state = AttackState.TELEGRAPH
	state_timer = telegraph_duration

	# Lock aim direction at the moment telegraph starts!
	# The warning line will point here, allowing the player to dodge before firing.
	var dir := Vector2.LEFT
	if is_instance_valid(target_player) and ("alive" not in target_player or target_player.alive):
		var diff: Vector2 = target_player.global_position - global_position
		if diff.length_squared() > 1.0:
			dir = diff.normalized()

	locked_aim_direction = dir
	has_dealt_damage = false

	if is_instance_valid(laser_node):
		laser_node.rotation = locked_aim_direction.angle()
		laser_node.monitoring = false
		laser_node.monitorable = false
		laser_node.queue_redraw()

	_update_pose_visibility()
	attack_telegraph_started.emit(locked_aim_direction)


func start_firing() -> void:
	if is_destroyed:
		return
	attack_state = AttackState.FIRING
	state_timer = laser_duration
	has_dealt_damage = false

	if is_instance_valid(laser_node):
		laser_node.rotation = locked_aim_direction.angle()
		laser_node.monitoring = true
		laser_node.monitorable = true
		laser_node.queue_redraw()
		# Immediate check on activation frame
		_check_laser_hit()

	_update_pose_visibility()
	laser_fired.emit(locked_aim_direction)


func end_firing() -> void:
	attack_state = AttackState.COOLDOWN
	state_timer = randf_range(fire_interval_min, fire_interval_max)
	has_dealt_damage = false

	if is_instance_valid(laser_node):
		laser_node.monitoring = false
		laser_node.monitorable = false
		laser_node.queue_redraw()

	_update_pose_visibility()


func stop_attack() -> void:
	attack_state = AttackState.COOLDOWN
	state_timer = fire_interval_min
	has_dealt_damage = false

	if is_instance_valid(laser_node):
		laser_node.monitoring = false
		laser_node.monitorable = false
		laser_node.queue_redraw()

	_update_pose_visibility()


func _check_laser_hit() -> void:
	if attack_state != AttackState.FIRING or has_dealt_damage or not is_instance_valid(laser_node):
		return

	for other in laser_node.get_overlapping_areas():
		if _apply_laser_damage_to(other):
			break


func _on_laser_area_entered(area: Area2D) -> void:
	if attack_state != AttackState.FIRING or has_dealt_damage:
		return
	_apply_laser_damage_to(area)


func _apply_laser_damage_to(target: Area2D) -> bool:
	if has_dealt_damage or not is_instance_valid(target) or target.is_queued_for_deletion():
		return false

	# Strict target filtering: Laser only damages the player
	if not (target.is_in_group("player") or target.name == "Player"):
		return false

	has_dealt_damage = true
	if target.has_method("take_damage"):
		target.take_damage(laser_damage)
	laser_hit.emit(target)
	return true


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
			take_damage(1)
			contact_cooldown[id] = 0.5


func take_damage(amount: int) -> void:
	if is_destroyed or amount <= 0:
		return

	var actual_damage: int = mini(amount, health)
	health -= actual_damage
	damaged.emit(actual_damage, health)

	if health <= 0:
		destroy()


func destroy() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	contact_damage = 0
	stop_attack()

	var col_shape = get_node_or_null("CollisionShape2D")
	if is_instance_valid(col_shape):
		col_shape.set_deferred("disabled", true)

	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	destroyed.emit()
	queue_free()


func is_telegraphing() -> bool:
	return attack_state == AttackState.TELEGRAPH


func is_firing_laser() -> bool:
	return attack_state == AttackState.FIRING


func get_locked_direction() -> Vector2:
	return locked_aim_direction


func get_laser_node() -> Area2D:
	if not is_instance_valid(laser_node):
		laser_node = get_node_or_null("Laser")
	return laser_node

