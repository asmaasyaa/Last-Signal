extends Area2D
## Guard Bot hostile security automaton for LAST SIGNAL Stage 2 Level 1.
## Implements side-scrolling movement, aiming and firing normal projectiles,
## official artwork presentation (idle & attacking sprites) with procedural fallback,
## multi-hit damage absorption (30 HP), and independent contact pair cooldowns.

signal damaged(amount: int, remaining_health: int)
signal destroyed
signal attack_fired(projectile: Area2D)

const ENEMY_PROJECTILE_SCENE = preload("res://scenes/enemies/enemy_projectile.tscn")

@export var max_health: int = 30
@export var speed: float = 130.0 # PROVISIONAL (TBD): 100-160 px/s
@export var contact_damage: int = 1
@export var fire_interval_min: float = 1.8 # PROVISIONAL (TBD): 1.5-2.5s
@export var fire_interval_max: float = 2.4
@export var attack_pose_duration: float = 0.35 # Duration in attacking sprite
@export var official_art_enabled: bool = true

var health: int = 30
var is_destroyed: bool = false
var fire_timer: float = 0.0
var attack_pose_timer: float = 0.0
var contact_cooldown: Dictionary = {} # int (instance_id) -> float (cooldown remaining)
var target_player: Area2D = null
var projectiles_container: Node = null

@onready var visuals: Node2D = get_node_or_null("Visuals")
@onready var official_art: Node2D = get_node_or_null("Visuals/OfficialArt")
@onready var idle_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/IdleSprite")
@onready var attacking_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/AttackingSprite")
@onready var fallback: Node2D = get_node_or_null("Visuals/ProceduralFallback")


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("guard_bots")
	collision_layer = 18 # Layer 2: Combat Target (2) | Layer 5: Enemies (16)
	collision_mask = 5   # Layer 1: Player (1) | Layer 3: Player Projectiles (4)
	monitoring = true
	monitorable = true

	health = max_health
	# Stagger initial shot so multiple bots don't fire at the exact same frame
	fire_timer = randf_range(0.8, fire_interval_max)

	update_visual_state()


func set_target_player(player: Area2D) -> void:
	target_player = player


func set_projectiles_container(container: Node) -> void:
	projectiles_container = container


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
	var is_attacking: bool = attack_pose_timer > 0.0
	if is_instance_valid(official_art) and official_art.visible:
		if is_instance_valid(attacking_sprite):
			attacking_sprite.visible = is_attacking
		if is_instance_valid(idle_sprite):
			idle_sprite.visible = not is_attacking
	if is_instance_valid(fallback) and fallback.visible and fallback.has_method("set_attacking"):
		fallback.set_attacking(is_attacking)


func _physics_process(delta: float) -> void:
	if is_destroyed:
		return

	# Side-scrolling horizontal leftward drift
	position.x -= speed * delta

	# Offscreen cleanup past left edge
	if position.x < -100.0:
		queue_free()
		return

	# Attack pose timing
	if attack_pose_timer > 0.0:
		attack_pose_timer = maxf(0.0, attack_pose_timer - delta)
		if attack_pose_timer == 0.0:
			_update_pose_visibility()

	# Firing timer
	fire_timer -= delta
	if fire_timer <= 0.0:
		fire_attack()
		fire_timer = randf_range(fire_interval_min, fire_interval_max)

	_check_player_contact(delta)


func fire_attack() -> Area2D:
	if is_destroyed or not ENEMY_PROJECTILE_SCENE:
		return null

	var aim_dir := Vector2.LEFT
	if is_instance_valid(target_player) and ("alive" not in target_player or target_player.alive):
		var diff: Vector2 = target_player.global_position - global_position
		if diff.length_squared() > 1.0:
			aim_dir = diff.normalized()

	var proj = ENEMY_PROJECTILE_SCENE.instantiate()
	proj.direction = aim_dir
	# Spawn at muzzle offset along firing vector
	proj.global_position = global_position + aim_dir * 24.0

	var container: Node = projectiles_container if is_instance_valid(projectiles_container) else get_parent()
	if is_instance_valid(container):
		container.add_child(proj)

	# Trigger attacking sprite pose
	attack_pose_timer = attack_pose_duration
	_update_pose_visibility()

	attack_fired.emit(proj)
	return proj


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
			# Mutual 1 HP contact damage per specification
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

	var col_shape = get_node_or_null("CollisionShape2D")
	if is_instance_valid(col_shape):
		col_shape.set_deferred("disabled", true)

	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	destroyed.emit()
	queue_free()


func get_visuals_node() -> Node2D:
	if not is_instance_valid(visuals):
		visuals = get_node_or_null("Visuals")
	return visuals
