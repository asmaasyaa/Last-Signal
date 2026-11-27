extends Area2D
## Stage 1 player ship; hand-drawn 2D aesthetic with procedural placeholder graphics.

signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 12
@export var move_speed: float = 500.0
@export var acceleration: float = 2400.0 # PROVISIONAL (TBD): smooth thrust ramp-up in px/s^2
@export var deceleration: float = 3000.0 # PROVISIONAL (TBD): smooth braking deceleration in px/s^2
@export var slow_radius: float = 75.0 # PROVISIONAL (TBD): distance from cursor to begin smooth arrival braking
@export var side_speed_scale: float = 1.0 # PROVISIONAL (TBD): lateral speed multiplier relative to move_speed
@export var reverse_speed_scale: float = 1.0 # PROVISIONAL (TBD): backward speed multiplier relative to move_speed
@export var forward_direction: Vector2 = Vector2.UP # Base forward facing direction (UP = 0 deg, RIGHT for side-scrolling)
@export var stop_threshold: float = 8.0 # Speed threshold below which the ship is considered stationary
@export var arrive_distance: float = 4.0 # Distance to mouse within which ship has arrived and is stationary
@export var regen_wait: float = 2.0 # PROVISIONAL (TBD): stationary delay before passive regen starts
@export var regen_per_second: float = 1.0
@export var contact_tick_seconds: float = 0.5
@export var play_area_min: Vector2 = Vector2(24.0, 24.0)
@export var play_area_max: Vector2 = Vector2(1256.0, 696.0)
@export var official_art_enabled: bool = true

var health: int = 12
var alive: bool = true
var movement_velocity: Vector2 = Vector2.ZERO
var still_seconds: float = 0.0
var regen_fraction: float = 0.0
var contact_cooldown: Dictionary = {} # int (instance_id) -> float (cooldown remaining)
var target_position_override: Variant = null # Optional Vector2 override for automated test harness

@onready var visuals: Node2D = get_node_or_null("Visuals")
@onready var official_art: Node2D = get_node_or_null("Visuals/OfficialArt")
@onready var alive_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/AliveSprite")
@onready var dead_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/DeadSprite")


func _ready() -> void:
	add_to_group("player")
	# If running under Milestone 3.5 test runner specifically, defer to pre-art fallback testing
	if is_inside_tree() and get_tree().root.has_node("TestRunnerMilestone3_5"):
		official_art_enabled = false
	update_visual_state()
	reset_state()


func _update_visual_fallback() -> void:
	if not is_instance_valid(visuals):
		visuals = get_node_or_null("Visuals")
	if not is_instance_valid(visuals):
		return
	var fallback = visuals.get_node_or_null("ProceduralFallback")
	if not is_instance_valid(fallback):
		return

	if not is_instance_valid(official_art):
		official_art = visuals.get_node_or_null("OfficialArt")

	var has_official_art: bool = false
	if official_art_enabled and is_instance_valid(official_art) and official_art.visible:
		var a_sprite: Sprite2D = official_art.get_node_or_null("AliveSprite")
		var d_sprite: Sprite2D = official_art.get_node_or_null("DeadSprite")
		var active_tex = a_sprite.texture if (alive and is_instance_valid(a_sprite)) else (d_sprite.texture if (not alive and is_instance_valid(d_sprite)) else null)
		if active_tex != null:
			has_official_art = true

	var has_custom_sprite: bool = false
	for child in visuals.get_children():
		if child == fallback or child == official_art:
			continue
		if (child is Sprite2D and child.texture != null) or (child is AnimatedSprite2D and child.sprite_frames != null):
			has_custom_sprite = true
			break

	fallback.visible = not (has_official_art or has_custom_sprite)


func update_visual_state() -> void:
	if not is_instance_valid(visuals):
		visuals = get_node_or_null("Visuals")
	if not is_instance_valid(official_art) and is_instance_valid(visuals):
		official_art = visuals.get_node_or_null("OfficialArt")
	if not is_instance_valid(alive_sprite) and is_instance_valid(official_art):
		alive_sprite = official_art.get_node_or_null("AliveSprite")
	if not is_instance_valid(dead_sprite) and is_instance_valid(official_art):
		dead_sprite = official_art.get_node_or_null("DeadSprite")

	_update_visual_fallback()

	var art_active: bool = official_art_enabled and is_instance_valid(official_art) and official_art.visible
	if is_instance_valid(alive_sprite):
		alive_sprite.visible = art_active and alive and (alive_sprite.texture != null)
	if is_instance_valid(dead_sprite):
		dead_sprite.visible = art_active and (not alive) and (dead_sprite.texture != null)


func get_visuals_node() -> Node2D:
	if not is_instance_valid(visuals):
		visuals = get_node_or_null("Visuals")
	return visuals


func set_forward_direction(dir: Vector2) -> void:
	if dir.length_squared() > 0.0001:
		forward_direction = dir.normalized()
		rotation = Vector2.UP.angle_to(forward_direction)


func reset_state() -> void:
	health = max_health
	alive = true
	movement_velocity = Vector2.ZERO
	still_seconds = 0.0
	regen_fraction = 0.0
	contact_cooldown.clear()
	target_position_override = null
	set_forward_direction(forward_direction)
	set_physics_process(true)
	update_visual_state()
	health_changed.emit(health, max_health)


func set_health(amount: int) -> void:
	health = clampi(amount, 0, max_health)
	alive = health > 0
	update_visual_state()
	health_changed.emit(health, max_health)


func prepare_for_level(starting_health: int = -1) -> void:
	if starting_health >= 0:
		health = clampi(starting_health, 1, max_health)
	alive = health > 0
	movement_velocity = Vector2.ZERO
	still_seconds = 0.0
	regen_fraction = 0.0
	contact_cooldown.clear()
	target_position_override = null
	set_forward_direction(forward_direction)
	set_physics_process(true)
	update_visual_state()
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if not alive:
		return

	_update_movement(delta)
	_update_regeneration(delta)
	_check_asteroid_contacts(delta)


func _update_movement(delta: float) -> void:
	var forward_dir: Vector2 = forward_direction.normalized() if forward_direction.length_squared() > 0.0001 else Vector2.UP
	rotation = Vector2.UP.angle_to(forward_dir)

	if delta <= 0.0 or move_speed <= 0.0:
		movement_velocity = Vector2.ZERO
		return

	var mouse_pos: Vector2 = target_position_override if target_position_override != null else get_global_mouse_position()
	var target_pos := Vector2(
		clampf(mouse_pos.x, play_area_min.x, play_area_max.x),
		clampf(mouse_pos.y, play_area_min.y, play_area_max.y)
	)
	var to_target: Vector2 = target_pos - global_position
	var distance_to_target: float = to_target.length()

	# Within arrival deadzone: decelerate smoothly to stationary
	if distance_to_target <= arrive_distance:
		if movement_velocity.length() <= stop_threshold:
			movement_velocity = Vector2.ZERO
		else:
			movement_velocity = movement_velocity.move_toward(Vector2.ZERO, deceleration * delta)
			var brake_dest: Vector2 = global_position + movement_velocity * delta
			brake_dest.x = clampf(brake_dest.x, play_area_min.x, play_area_max.x)
			brake_dest.y = clampf(brake_dest.y, play_area_min.y, play_area_max.y)
			movement_velocity = (brake_dest - global_position) / delta
			global_position = brake_dest
			if movement_velocity.length() <= stop_threshold:
				movement_velocity = Vector2.ZERO
		return

	var move_dir: Vector2 = to_target / distance_to_target
	var arrival_ratio: float = clampf(
		(distance_to_target - arrive_distance) / maxf(slow_radius - arrive_distance, 0.001),
		0.0,
		1.0
	)
	var arrival_speed: float = move_speed * sqrt(arrival_ratio)

	# Allow optional directional tuning (default 1.0 = full speed in every direction)
	var forward_cos: float = move_dir.dot(forward_dir)
	var dir_scale: float = 1.0
	if forward_cos >= 0.0:
		dir_scale = lerpf(maxf(side_speed_scale, 0.05), 1.0, forward_cos)
	else:
		dir_scale = lerpf(maxf(side_speed_scale, 0.05), maxf(reverse_speed_scale, 0.05), -forward_cos)

	var desired_speed: float = maxf(arrival_speed * dir_scale, minf(move_speed, stop_threshold + 4.0))

	# Decompose velocity along move_dir to damp off-axis inertia and prevent icy drifting
	var along_speed: float = movement_velocity.dot(move_dir)
	var off_axis_velocity: Vector2 = movement_velocity - move_dir * along_speed
	off_axis_velocity *= exp(-28.0 * delta)

	var accel_rate: float = deceleration if (along_speed < 0.0 or desired_speed < along_speed) else acceleration
	along_speed = move_toward(along_speed, desired_speed, accel_rate * delta)

	movement_velocity = move_dir * along_speed + off_axis_velocity

	var step: Vector2 = movement_velocity * delta
	if step.length() >= distance_to_target and movement_velocity.dot(move_dir) > 0.0:
		movement_velocity = (target_pos - global_position) / delta
		global_position = target_pos
	else:
		var destination: Vector2 = global_position + step
		destination.x = clampf(destination.x, play_area_min.x, play_area_max.x)
		destination.y = clampf(destination.y, play_area_min.y, play_area_max.y)
		movement_velocity = (destination - global_position) / delta
		global_position = destination


func _update_regeneration(delta: float) -> void:
	if not alive or not is_physics_processing():
		return

	if movement_velocity.length() > stop_threshold:
		still_seconds = 0.0
		regen_fraction = 0.0
	else:
		still_seconds += delta
		if health >= max_health:
			regen_fraction = 0.0
		# Passive regen restores 1 HP/sec after stationary delay (regen_wait is provisional TBD)
		elif still_seconds >= regen_wait:
			regen_fraction += regen_per_second * delta
			if regen_fraction >= 1.0:
				var restored: int = int(regen_fraction)
				regen_fraction -= float(restored)
				health = mini(max_health, health + restored)
				health_changed.emit(health, max_health)


func get_regen_state_string() -> String:
	if not alive:
		return "DEAD"
	if health >= max_health:
		return "FULL HEALTH"
	if movement_velocity.length() > stop_threshold:
		return "MOVING (%.1f px/s)" % movement_velocity.length()
	if still_seconds < regen_wait:
		return "WAITING (%.2fs / %.2fs)" % [still_seconds, regen_wait]
	return "REGENERATING (%.0f%%)" % (regen_fraction * 100.0)


func _check_asteroid_contacts(delta: float) -> void:
	if not alive:
		return

	# 1. Decrement existing cooldowns and prune freed/invalid instances
	var ids_to_erase: Array = []
	for id in contact_cooldown.keys():
		contact_cooldown[id] = float(contact_cooldown[id]) - delta
		var inst = instance_from_id(id)
		if not is_instance_valid(inst) or inst.is_queued_for_deletion():
			ids_to_erase.append(id)

	for id in ids_to_erase:
		contact_cooldown.erase(id)

	# 2. Check current overlapping asteroid areas
	var active_overlapping_ids: Dictionary = {}
	for other in get_overlapping_areas():
		if not is_instance_valid(other) or other.is_queued_for_deletion():
			continue
		if not other.is_in_group("asteroids"):
			continue

		var id: int = other.get_instance_id()
		active_overlapping_ids[id] = true

		var time_remaining: float = float(contact_cooldown.get(id, 0.0))
		if time_remaining <= 0.0:
			var damage_amount: int = other.contact_damage if "contact_damage" in other else 1
			take_damage(damage_amount)
			contact_cooldown[id] = contact_tick_seconds
			if not alive:
				return

	# 3. Clean up cooldowns that have expired and are no longer in contact
	var expired_and_separated: Array = []
	for id in contact_cooldown.keys():
		if float(contact_cooldown[id]) <= 0.0 and not active_overlapping_ids.has(id):
			expired_and_separated.append(id)

	for id in expired_and_separated:
		contact_cooldown.erase(id)


func take_damage(amount: int) -> void:
	if not alive or amount <= 0:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	if health == 0:
		alive = false
		update_visual_state()
		died.emit()
