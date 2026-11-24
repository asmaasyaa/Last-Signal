extends Node2D
## EM Jammer Active Equipment Controller for LAST SIGNAL.
## Implements a 120-degree directional cone stun with zero damage, 10-second duration,
## 30-second cooldown, configurable range, and Call Down / Signal Up architecture.

signal activated(cone_direction: Vector2, targets_affected: Array)
signal cooldown_started(duration: float)
signal cooldown_finished

@export var cone_angle_degrees: float = 120.0 # 120 degrees total (±60 deg from heading)
@export var cone_range: float = 600.0 # PROVISIONAL (TBD): 500-700 px range
@export var stun_duration: float = 10.0 # Confirmed 10.0s stun
@export var cooldown_duration: float = 30.0 # Confirmed 30.0s cooldown
@export var input_action_name: String = "em_jammer"

var is_acquired: bool = false
var cooldown_remaining: float = 0.0
var vfx_timer: float = 0.0
var vfx_direction: Vector2 = Vector2.UP
var player: Area2D = null
var arena: Node = null


func _ready() -> void:
	# Ensure em_jammer input action exists in InputMap
	_ensure_input_action()


func setup(p_player: Area2D, p_arena: Node = null) -> void:
	player = p_player
	arena = p_arena


func set_acquired(acquired: bool) -> void:
	is_acquired = acquired


func _ensure_input_action() -> void:
	if not InputMap.has_action(input_action_name):
		InputMap.add_action(input_action_name)
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_E
		InputMap.action_add_event(input_action_name, ev)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(input_action_name):
		activate()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E or event.keycode == KEY_E:
			activate()


func can_activate() -> bool:
	if not is_acquired:
		return false
	if not is_instance_valid(player):
		return false
	if "alive" in player and not player.alive:
		return false
	if is_instance_valid(arena) and "finished" in arena and arena.finished:
		return false
	if cooldown_remaining > 0.0:
		return false
	return true


func activate() -> bool:
	if not can_activate():
		return false

	# 1. Determine player forward heading
	var heading := Vector2.UP
	if is_instance_valid(player):
		heading = Vector2.UP.rotated(player.rotation)

	# 2. 120-degree cone target detection (±60 degrees in radians)
	var half_cone_rad: float = deg_to_rad(cone_angle_degrees * 0.5)
	var affected_targets: Array = []

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue

		var to_enemy: Vector2 = enemy.global_position - player.global_position
		var dist: float = to_enemy.length()

		# Check maximum range
		if dist <= cone_range:
			if dist <= 0.001:
				# Target directly on top of player is within cone
				_apply_stun_to_target(enemy)
				affected_targets.append(enemy)
			else:
				var dir: Vector2 = to_enemy.normalized()
				var angle_diff: float = absf(heading.angle_to(dir))
				if angle_diff <= half_cone_rad:
					_apply_stun_to_target(enemy)
					affected_targets.append(enemy)

	# 3. Enter 30-second cooldown
	cooldown_remaining = cooldown_duration
	cooldown_started.emit(cooldown_duration)

	# 4. Trigger visual cone pulse
	vfx_timer = 0.35
	vfx_direction = heading
	global_position = player.global_position
	queue_redraw()

	# 5. Emit activation signal with zero damage guarantee
	activated.emit(heading, affected_targets)
	return true


func _apply_stun_to_target(target: Node) -> void:
	if target.has_method("apply_stun"):
		target.apply_stun(stun_duration)


func _process(delta: float) -> void:
	if is_instance_valid(player):
		global_position = player.global_position

	if cooldown_remaining > 0.0:
		cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
		if cooldown_remaining == 0.0:
			cooldown_finished.emit()

	if vfx_timer > 0.0:
		vfx_timer = maxf(0.0, vfx_timer - delta)
		queue_redraw()


func _draw() -> void:
	if vfx_timer <= 0.0:
		return

	var progress: float = 1.0 - (vfx_timer / 0.35)
	var current_radius: float = cone_range * (0.3 + 0.7 * progress)
	var alpha: float = (1.0 - progress) * 0.65
	var cone_color := Color(0.2, 0.85, 1.0, alpha)

	var base_angle: float = vfx_direction.angle()
	var half_cone: float = deg_to_rad(cone_angle_degrees * 0.5)

	# Draw expanding 120-degree arc wave
	draw_arc(Vector2.ZERO, current_radius, base_angle - half_cone, base_angle + half_cone, 24, cone_color, 4.0)

	# Draw cone side boundary lines
	var left_pt := Vector2.RIGHT.rotated(base_angle - half_cone) * current_radius
	var right_pt := Vector2.RIGHT.rotated(base_angle + half_cone) * current_radius
	draw_line(Vector2.ZERO, left_pt, Color(cone_color.r, cone_color.g, cone_color.b, alpha * 0.7), 2.0)
	draw_line(Vector2.ZERO, right_pt, Color(cone_color.r, cone_color.g, cone_color.b, alpha * 0.7), 2.0)


func is_ready() -> bool:
	return can_activate()


func get_cooldown_remaining() -> float:
	return cooldown_remaining


func get_cooldown_progress() -> float:
	if cooldown_duration <= 0.0:
		return 1.0
	return 1.0 - (cooldown_remaining / cooldown_duration)
