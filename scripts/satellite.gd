extends Area2D
## Optional Communication Satellite for Stage 1 Level 2.
## Features gentle drift, proximity telemetry extraction, and signal-based narrative integration.

signal extraction_started
signal extraction_progress_changed(progress: float)
signal extracted(payload: Dictionary)

@export var drift_speed: float = 100.0 # PROPOSAL / TBD
@export var extraction_time: float = 1.8 # PROPOSAL / TBD
@export var extraction_radius: float = 80.0 # PROPOSAL / TBD

var extraction_progress: float = 0.0
var is_extracted: bool = false
var player_in_range: bool = false
var beacon_phase: float = 0.0


func _ready() -> void:
	add_to_group("satellites")
	collision_layer = 8 # Layer 4 (interactables)
	collision_mask = 1 # Layer 1 (player)
	monitoring = true
	monitorable = true

	var col_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if is_instance_valid(col_shape):
		var unique_shape := CircleShape2D.new()
		unique_shape.radius = extraction_radius
		col_shape.shape = unique_shape
	queue_redraw()


func _physics_process(delta: float) -> void:
	position.y += drift_speed * delta
	beacon_phase = fmod(beacon_phase + delta * 6.0, TAU)

	if position.y > 780.0:
		queue_free()
		return

	var found_player: bool = false
	for area in get_overlapping_areas():
		if not is_instance_valid(area) or area.is_queued_for_deletion():
			continue
		if area.collision_layer & 1 != 0 or area.name == "Player":
			found_player = true
			break

	if found_player and not is_extracted:
		if not player_in_range:
			player_in_range = true
			extraction_started.emit()
		extraction_progress += delta / maxf(extraction_time, 0.01)
		extraction_progress_changed.emit(clampf(extraction_progress, 0.0, 1.0))
		if extraction_progress >= 1.0:
			extraction_progress = 1.0
			is_extracted = true
			var payload := {
				"id": "sat_telemetry_01",
				"source": "COMMUNICATION SATELLITE",
				"text": "[DECRYPTED TELEMETRY] Unidentified mining vessel distress beacon detected in outer asteroid sector."
			}
			extracted.emit(payload)
	elif not found_player and player_in_range:
		player_in_range = false

	queue_redraw()


func _draw() -> void:
	# 1. Central golden chassis
	var chassis_color := Color(0.95, 0.77, 0.25) if not is_extracted else Color(0.5, 0.9, 0.6)
	draw_rect(Rect2(-10, -14, 20, 28), chassis_color)
	draw_rect(Rect2(-10, -14, 20, 28), Color(1.0, 0.92, 0.6), false, 2.0)

	# 2. Dual solar array wings
	draw_rect(Rect2(-36, -8, 22, 16), Color(0.18, 0.48, 0.82))
	draw_rect(Rect2(-36, -8, 22, 16), Color(0.5, 0.8, 1.0), false, 1.0)
	draw_line(Vector2(-25, -8), Vector2(-25, 8), Color(0.5, 0.8, 1.0), 1.0)

	draw_rect(Rect2(14, -8, 22, 16), Color(0.18, 0.48, 0.82))
	draw_rect(Rect2(14, -8, 22, 16), Color(0.5, 0.8, 1.0), false, 1.0)
	draw_line(Vector2(25, -8), Vector2(25, 8), Color(0.5, 0.8, 1.0), 1.0)

	# 3. Antenna and beacon
	draw_line(Vector2(0, -14), Vector2(0, -24), Color(0.85, 0.85, 0.9), 2.0)
	var beacon_color: Color
	if is_extracted:
		beacon_color = Color(0.2, 1.0, 0.4)
	elif sin(beacon_phase) > 0.0:
		beacon_color = Color(1.0, 0.45, 0.2)
	else:
		beacon_color = Color(0.5, 0.1, 0.1)
	draw_circle(Vector2(0, -25), 3.2, beacon_color)

	# 4. Interaction radius boundary
	var ring_color: Color = Color(0.3, 0.8, 1.0, 0.18) if not player_in_range else Color(0.4, 1.0, 0.6, 0.35)
	draw_arc(Vector2.ZERO, extraction_radius, 0.0, TAU, 32, ring_color, 1.5)

	# 5. Extraction progress ring
	if extraction_progress > 0.0 and not is_extracted:
		draw_arc(Vector2.ZERO, 30.0, -PI * 0.5, -PI * 0.5 + extraction_progress * TAU, 32, Color(0.3, 1.0, 0.4, 0.95), 3.0)
	elif is_extracted:
		draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 32, Color(0.2, 0.9, 0.4, 0.8), 2.0)

