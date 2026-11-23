extends Area2D
## Optional Communication Satellite for Stage 1 Level 2.
## Features gentle drift, proximity telemetry extraction, official art with procedural fallback,
## and signal-based narrative integration.

signal extraction_started
signal extraction_progress_changed(progress: float)
signal extracted(payload: Dictionary)

@export var drift_speed: float = 100.0 # PROPOSAL / TBD
@export var extraction_time: float = 1.8 # PROPOSAL / TBD
@export var extraction_radius: float = 80.0 # PROPOSAL / TBD
@export var official_art_enabled: bool = true

var extraction_progress: float = 0.0
var is_extracted: bool = false
var player_in_range: bool = false
var beacon_phase: float = 0.0

@onready var visuals: Node2D = get_node_or_null("Visuals")
@onready var official_art: Node2D = get_node_or_null("Visuals/OfficialArt")
@onready var satellite_sprite: Sprite2D = get_node_or_null("Visuals/OfficialArt/Sprite2D")
@onready var fallback: Node2D = get_node_or_null("Visuals/ProceduralFallback")
@onready var indicator: Node2D = get_node_or_null("Indicator")


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

	update_visual_state()
	queue_redraw()


func update_visual_state() -> void:
	if not is_instance_valid(visuals):
		visuals = get_node_or_null("Visuals")
	if not is_instance_valid(official_art) and is_instance_valid(visuals):
		official_art = visuals.get_node_or_null("OfficialArt")
	if not is_instance_valid(satellite_sprite) and is_instance_valid(official_art):
		satellite_sprite = official_art.get_node_or_null("Sprite2D")
	if not is_instance_valid(fallback) and is_instance_valid(visuals):
		fallback = visuals.get_node_or_null("ProceduralFallback")

	var has_art: bool = official_art_enabled and is_instance_valid(satellite_sprite) and (satellite_sprite.texture != null)
	if is_instance_valid(official_art):
		official_art.visible = has_art
	if is_instance_valid(satellite_sprite):
		satellite_sprite.visible = has_art
	if is_instance_valid(fallback):
		fallback.visible = not has_art
		if fallback.visible and fallback.has_method("set_state"):
			fallback.set_state(is_extracted, beacon_phase)


func get_visuals_node() -> Node2D:
	if not is_instance_valid(visuals):
		visuals = get_node_or_null("Visuals")
	return visuals


func _physics_process(delta: float) -> void:
	position.y += drift_speed * delta
	beacon_phase = fmod(beacon_phase + delta * 6.0, TAU)

	if is_instance_valid(fallback) and fallback.visible and fallback.has_method("set_state"):
		fallback.set_state(is_extracted, beacon_phase)

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
			update_visual_state()
	elif not found_player and player_in_range:
		player_in_range = false

	if is_instance_valid(indicator):
		indicator.queue_redraw()
	queue_redraw()


func _draw() -> void:
	# Fallback indicator drawing if no separate Indicator child node is present
	if not is_instance_valid(indicator):
		var ring_color: Color = Color(0.3, 0.8, 1.0, 0.18) if not player_in_range else Color(0.4, 1.0, 0.6, 0.35)
		draw_arc(Vector2.ZERO, extraction_radius, 0.0, TAU, 32, ring_color, 1.5)

		if extraction_progress > 0.0 and not is_extracted:
			draw_arc(Vector2.ZERO, 30.0, -PI * 0.5, -PI * 0.5 + extraction_progress * TAU, 32, Color(0.3, 1.0, 0.4, 0.95), 3.0)
		elif is_extracted:
			draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 32, Color(0.2, 0.9, 0.4, 0.8), 2.0)
