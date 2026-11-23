extends Node
## Weapon Controller for LAST SIGNAL twin-barrel primary cannon.
## Manages delta-timed firing cooldown (6 volleys/s, 12 projectiles/s total),
## dual muzzle lateral separation, and parallel trajectory generation.

signal volley_fired(projectiles: Array)

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectile.tscn")

@export var volleys_per_second: float = 6.0
@export var projectile_damage: int = 1
@export var projectile_speed: float = 750.0
@export var muzzle_offset_lateral: float = 12.0 # Distance left/right from ship center
@export var muzzle_offset_forward: float = 24.0 # Distance forward from ship center

var fire_cooldown: float = 0.0
var firing_enabled: bool = false
var player: Area2D = null
var projectiles_container: Node = null


func setup(p_player: Area2D, p_container: Node = null) -> void:
	player = p_player
	projectiles_container = p_container


func set_firing_enabled(enabled: bool) -> void:
	firing_enabled = enabled
	if not enabled:
		fire_cooldown = 0.0


func can_fire() -> bool:
	if not firing_enabled:
		return false
	if fire_cooldown > 0.0:
		return false
	if not is_instance_valid(player) or not player.alive:
		return false
	return true


func _process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)

	if can_fire() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		fire_volley()


func fire_volley() -> Array:
	if not is_instance_valid(player) or not player.alive:
		return []

	# Reset cooldown cleanly (prevents burst on resuming)
	fire_cooldown = 1.0 / maxf(volleys_per_second, 0.01)

	var forward := Vector2.UP.rotated(player.rotation)
	var right := Vector2.RIGHT.rotated(player.rotation)

	# Parallel trajectories originating from distinct left and right muzzles
	var left_muzzle: Vector2 = player.global_position + forward * muzzle_offset_forward - right * muzzle_offset_lateral
	var right_muzzle: Vector2 = player.global_position + forward * muzzle_offset_forward + right * muzzle_offset_lateral

	var p_left = _spawn_single_projectile(left_muzzle, forward, player.rotation)
	var p_right = _spawn_single_projectile(right_muzzle, forward, player.rotation)

	var created: Array = [p_left, p_right]
	volley_fired.emit(created)
	return created


func _spawn_single_projectile(pos: Vector2, dir: Vector2, rot: float) -> Area2D:
	if not PROJECTILE_SCENE:
		return null
	var proj = PROJECTILE_SCENE.instantiate()
	proj.global_position = pos
	proj.direction = dir
	proj.rotation = rot
	proj.speed = projectile_speed
	proj.damage = projectile_damage

	var parent_target: Node = projectiles_container if is_instance_valid(projectiles_container) else get_parent()
	if is_instance_valid(parent_target):
		parent_target.add_child(proj)
	return proj


func clear_projectiles() -> void:
	var container: Node = projectiles_container if is_instance_valid(projectiles_container) else get_parent()
	if is_instance_valid(container):
		for child in container.get_children():
			if child.is_in_group("projectiles"):
				child.queue_free()

