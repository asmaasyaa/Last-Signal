extends Area2D
## Reusable projectile for LAST SIGNAL twin-barrel pulse cannon.
## Deals 1 HP damage per hit, despawns on collision or exceeding boundary/lifetime,
## and protects against repeated damage callbacks.

signal hit(target: Area2D)

@export var speed: float = 750.0
@export var damage: int = 1
@export var lifetime: float = 2.5

var direction: Vector2 = Vector2.UP
var has_hit: bool = false
var elapsed_time: float = 0.0

@onready var visuals: Node2D = get_node_or_null("Visuals")


func _ready() -> void:
	add_to_group("projectiles")
	collision_layer = 4 # Layer 3: Player Projectiles
	collision_mask = 2  # Layer 2: Asteroids
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if has_hit:
		return

	global_position += direction * speed * delta
	elapsed_time += delta

	# Safe off-screen cleanup and lifetime timeout
	if elapsed_time >= lifetime or global_position.y < -50.0 or global_position.y > 770.0 or global_position.x < -50.0 or global_position.x > 1330.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if has_hit:
		return
	if not is_instance_valid(area) or area.is_queued_for_deletion():
		return
	if not area.is_in_group("asteroids"):
		return
	if "is_destroyed" in area and area.is_destroyed:
		return

	has_hit = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	hit.emit(area)

	if area.has_method("take_damage"):
		area.take_damage(damage)

	queue_free()


func get_visuals_node() -> Node2D:
	if not is_instance_valid(visuals):
		visuals = get_node_or_null("Visuals")
	return visuals
