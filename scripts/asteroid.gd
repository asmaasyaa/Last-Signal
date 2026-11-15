extends Area2D
## Asteroid for Stage 1 (small, medium, and large sizes).
## Visual representation is decoupled into the child Visuals node.
## Asteroid contact damage received from player is TBD and not implemented.

enum AsteroidSize { SMALL, MEDIUM, LARGE }

@export var size_tier: AsteroidSize = AsteroidSize.SMALL
@export var speed: float = 220.0
@export var contact_damage: int = 1
@export var max_health: int = 20

var health: int = 20
var spin: float = 0.0

const BASE_VERTICES := [
	Vector2(-16, -10), Vector2(-4, -22), Vector2(13, -17),
	Vector2(23, -4), Vector2(14, 15), Vector2(-6, 20), Vector2(-22, 5)
]
var rock_vertices := PackedVector2Array()

@onready var visuals: Node2D = get_node_or_null("Visuals")


func _ready() -> void:
	add_to_group("asteroids")
	set_size_tier(size_tier)
	spin = randf_range(-2.0, 2.0)


func set_size_tier(tier: AsteroidSize) -> void:
	size_tier = tier
	var collision_radius: float = 19.0
	var visual_scale: float = 1.0

	match size_tier:
		AsteroidSize.SMALL:
			max_health = 20
			health = 20
			contact_damage = 1
			collision_radius = 19.0
			visual_scale = 1.0
		AsteroidSize.MEDIUM:
			max_health = 40
			health = 40
			contact_damage = 2
			collision_radius = 35.0
			visual_scale = 1.8
		AsteroidSize.LARGE:
			max_health = 80
			health = 80
			contact_damage = 4
			collision_radius = 65.0
			visual_scale = 3.2

	# Avoid shared CollisionShape2D mutation by creating an independent shape instance
	var col_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if is_instance_valid(col_shape):
		var unique_shape := CircleShape2D.new()
		unique_shape.radius = collision_radius
		col_shape.shape = unique_shape

	# Populate rock_vertices for presentation and backward compatibility
	rock_vertices.clear()
	for v in BASE_VERTICES:
		rock_vertices.append(v * visual_scale)

	# Update visual presentation layer
	_update_visuals(visual_scale)


func _update_visuals(visual_scale: float) -> void:
	if not is_instance_valid(visuals):
		visuals = get_node_or_null("Visuals")
	if not is_instance_valid(visuals):
		return

	var fallback = visuals.get_node_or_null("ProceduralFallback")
	var has_custom_sprite: bool = false
	for child in visuals.get_children():
		if child == fallback:
			continue
		if (child is Sprite2D and child.texture != null) or (child is AnimatedSprite2D and child.sprite_frames != null):
			has_custom_sprite = true
			break

	if is_instance_valid(fallback):
		fallback.visible = not has_custom_sprite
		if not has_custom_sprite and fallback.has_method("set_geometry"):
			fallback.set_geometry(rock_vertices, visual_scale)


func _physics_process(delta: float) -> void:
	position.y += speed * delta
	rotation += spin * delta
	if position.y > 780.0:
		queue_free()


func get_visuals_node() -> Node2D:
	if not is_instance_valid(visuals):
		visuals = get_node_or_null("Visuals")
	return visuals
