extends Area2D
## Normal enemy projectile for LAST SIGNAL Stage 2 hostile entities (e.g., Guard Bot).
## Deals 1 HP damage per hit to the player, ignores friendly units,
## despawns on contact or exceeding playfield bounds, and protects against double-hits.

signal hit(target: Area2D)

@export var speed: float = 300.0 # PROVISIONAL (TBD): 260-360 px/s
@export var damage: int = 1
@export var lifetime: float = 4.0

var direction: Vector2 = Vector2.LEFT
var has_hit: bool = false
var elapsed_time: float = 0.0

@onready var visuals: Node2D = get_node_or_null("Visuals")


func _ready() -> void:
	add_to_group("enemy_projectiles")
	collision_layer = 32 # Layer 6: Enemy Projectiles
	collision_mask = 1   # Layer 1: Player
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if has_hit:
		return

	global_position += direction * speed * delta
	elapsed_time += delta

	# Safe playfield bounds check (1280x720 with margins)
	if elapsed_time >= lifetime or global_position.x < -60.0 or global_position.x > 1340.0 or global_position.y < -60.0 or global_position.y > 780.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if has_hit:
		return
	if not is_instance_valid(area) or area.is_queued_for_deletion():
		return
	# Strict target filtering: Enemy projectiles must only damage the player
	if not (area.is_in_group("player") or area.name == "Player"):
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

