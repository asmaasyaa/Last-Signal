extends Area2D
## Guard Drone hostile security automaton for LAST SIGNAL Stage 2 Level 3.
## Features 20 HP, high-speed kamikaze charge with telegraph phase,
## official artwork presentation (idle & attacking sprites) with procedural fallback,
## attributed destruction (only player weapons grant kill credit; kamikaze and offscreen do not),
## and neutral root scale.

signal damaged(amount: int, remaining_health: int)
signal destroyed
signal drone_defeated(reason: int, drone: Area2D)
signal attack_telegraph_started(locked_direction: Vector2)
signal charge_started(locked_direction: Vector2)

enum DroneState {
	APPROACH = 0,
	TELEGRAPH = 1,
	CHARGING = 2,
	DESTROYED = 3
}

enum DestructionReason {
	PLAYER_WEAPON = 0,
	KAMIKAZE_IMPACT = 1,
	OFFSCREEN_DESPAWN = 2,
	LEVEL_CLEANUP = 3
}

@export var max_health: int = 20
@export var approach_speed: float = 120.0 # PROVISIONAL (TBD): 100-140 px/s
@export var charge_speed: float = 360.0 # PROVISIONAL (TBD): 320-400 px/s
@export var telegraph_duration: float = 0.45 # PROVISIONAL (TBD): 0.4-0.6s
@export var contact_damage: int = 1
@export var official_art_enabled: bool = true

var health: int = 20
var is_destroyed: bool = false
var drone_state: DroneState = DroneState.APPROACH
var state_timer: float = 0.0
var approach_timer: float = 0.0
var locked_charge_direction: Vector2 = Vector2.LEFT
var target_player: Area2D = null
var contact_cooldown: Dictionary = {}

@onready var visuals: Node2D = get_node_or_null("Visuals")
@onready var official_art: Node2D = get_node_or_null("Visuals/OfficialArt")
@onready var idle_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/IdleSprite")
@onready var attacking_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/AttackingSprite")
@onready var fallback: Node2D = get_node_or_null("Visuals/ProceduralFallback")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("guard_drones")
	collision_layer = 18 # Layer 2: Combat Target (2) | Layer 5: Enemies (16)
	collision_mask = 5   # Layer 1: Player (1) | Layer 3: Player Projectiles (4)
	monitoring = true
	monitorable = true

	health = max_health
	drone_state = DroneState.APPROACH
	# Stagger initial approach time before telegraphing
	approach_timer = randf_range(1.0, 2.0)

	area_entered.connect(_on_area_entered)
	update_visual_state()


func set_target_player(player: Area2D) -> void:
	target_player = player


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
	var is_atk: bool = drone_state == DroneState.TELEGRAPH or drone_state == DroneState.CHARGING
	if is_instance_valid(official_art) and official_art.visible:
		if is_instance_valid(attacking_sprite):
			attacking_sprite.visible = is_atk
		if is_instance_valid(idle_sprite):
			idle_sprite.visible = not is_atk
	if is_instance_valid(fallback) and fallback.visible and fallback.has_method("set_attacking"):
		fallback.set_attacking(is_atk)


func _physics_process(delta: float) -> void:
	if is_destroyed:
		return

	match drone_state:
		DroneState.APPROACH:
			# Drift leftward while scanning for player
			position.x -= approach_speed * delta
			approach_timer -= delta
			if approach_timer <= 0.0:
				start_telegraph()

		DroneState.TELEGRAPH:
			# Decelerate / slight drift during telegraph
			position.x -= (approach_speed * 0.25) * delta
			state_timer -= delta
			if state_timer <= 0.0:
				start_charge()

		DroneState.CHARGING:
			# High-speed dash along locked trajectory
			global_position += locked_charge_direction * charge_speed * delta

	# Check offscreen cleanup
	if position.x < -120.0 or position.y < -120.0 or position.y > 840.0:
		destroy(DestructionReason.OFFSCREEN_DESPAWN)
		return

	_check_player_contact(delta)


func start_telegraph() -> void:
	if is_destroyed or drone_state != DroneState.APPROACH:
		return

	drone_state = DroneState.TELEGRAPH
	state_timer = telegraph_duration

	# Lock aim vector toward player's current position
	if is_instance_valid(target_player) and ("alive" not in target_player or target_player.alive):
		var diff: Vector2 = target_player.global_position - global_position
		if diff.length_squared() > 1.0:
			locked_charge_direction = diff.normalized()
		else:
			locked_charge_direction = Vector2.LEFT
	else:
		locked_charge_direction = Vector2.LEFT

	# Align visual node rotation with locked charge direction (offset from default leftward facing)
	if is_instance_valid(visuals):
		visuals.rotation = locked_charge_direction.angle() - PI

	_update_pose_visibility()
	attack_telegraph_started.emit(locked_charge_direction)


func start_charge() -> void:
	if is_destroyed or drone_state != DroneState.TELEGRAPH:
		return

	drone_state = DroneState.CHARGING
	_update_pose_visibility()
	charge_started.emit(locked_charge_direction)


func _on_area_entered(area: Area2D) -> void:
	if is_destroyed:
		return
	if not is_instance_valid(area) or area.is_queued_for_deletion():
		return
	if area.is_in_group("player") or area.name == "Player":
		handle_player_contact(area)


func handle_player_contact(p_player: Area2D) -> void:
	if is_destroyed:
		return
	if is_instance_valid(p_player) and p_player.has_method("take_damage"):
		p_player.take_damage(contact_damage)
	destroy(DestructionReason.KAMIKAZE_IMPACT)


func _check_player_contact(_delta: float) -> void:
	if is_destroyed:
		return

	for other in get_overlapping_areas():
		if not is_instance_valid(other) or other.is_queued_for_deletion():
			continue
		if other.is_in_group("player") or other.name == "Player":
			handle_player_contact(other)
			return


func take_damage(amount: int) -> void:
	if is_destroyed or amount <= 0:
		return

	var actual_damage: int = mini(amount, health)
	health -= actual_damage
	damaged.emit(actual_damage, health)

	if health <= 0:
		destroy(DestructionReason.PLAYER_WEAPON)


func destroy(reason: int = DestructionReason.LEVEL_CLEANUP) -> void:
	if is_destroyed:
		return

	is_destroyed = true
	drone_state = DroneState.DESTROYED
	contact_damage = 0

	if not is_instance_valid(collision_shape):
		collision_shape = get_node_or_null("CollisionShape2D")
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)

	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	drone_defeated.emit(reason, self)
	destroyed.emit()
	queue_free()


func stop_attack() -> void:
	if is_destroyed:
		return
	destroy(DestructionReason.LEVEL_CLEANUP)


func is_telegraphing() -> bool:
	return drone_state == DroneState.TELEGRAPH


func is_charging() -> bool:
	return drone_state == DroneState.CHARGING


func get_charge_direction() -> Vector2:
	return locked_charge_direction


func get_visuals_node() -> Node2D:
	if not is_instance_valid(visuals):
		visuals = get_node_or_null("Visuals")
	return visuals
