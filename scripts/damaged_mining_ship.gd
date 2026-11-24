extends Node2D
## Visual and narrative representation of the damaged mining vessel encountered at the end of Stage 1 Level 5.
## Source of the automated SOS distress beacon transmission pointing toward Stage 2. Non-combat entity.

@export var ship_name: String = "Damaged Mining Vessel [NON-CANONICAL]"
@export var float_speed: float = 1.6
@export var float_amplitude: float = 5.0

var float_timer: float = 0.0
var spark_phase: float = 0.0

@onready var visuals: Node2D = get_node_or_null("Visuals")
@onready var official_art: Node2D = get_node_or_null("Visuals/OfficialArt")
@onready var fallback: Node2D = get_node_or_null("Visuals/ProceduralFallback")


func _ready() -> void:
	add_to_group("mining_ships")
	add_to_group("wrecked_ships")
	queue_redraw()


func _process(delta: float) -> void:
	float_timer += delta * float_speed
	spark_phase = fmod(spark_phase + delta * 8.0, TAU)
	position.y += sin(float_timer) * float_amplitude * delta
	queue_redraw()


func _draw() -> void:
	# If official art is present and active, skip procedural canvas drawing
	if is_instance_valid(official_art) and official_art.visible:
		return

	# 1. Main heavy industrial chassis (dark slate/rust plating)
	var hull_color := Color(0.28, 0.25, 0.24)
	var armor_color := Color(0.42, 0.38, 0.35)
	var outline_color := Color(0.75, 0.65, 0.55)
	var hazard_amber := Color(0.9, 0.6, 0.15)

	# Asymmetric bulky hull polygon
	var hull_pts := PackedVector2Array([
		Vector2(0, -42),      # Bow / Cutter nose
		Vector2(32, -18),     # Starboard cargo container
		Vector2(36, 16),      # Starboard thruster pod
		Vector2(14, 34),      # Rear exhaust port
		Vector2(-18, 34),     # Port exhaust port
		Vector2(-42, 14),     # Port breached hull wall
		Vector2(-30, -22)     # Port forward shield plate
	])
	draw_colored_polygon(hull_pts, hull_color)
	var outline_pts := hull_pts.duplicate()
	outline_pts.append(hull_pts[0])
	draw_polyline(outline_pts, outline_color, 2.0, true)

	# 2. Heavy mining cutting drill / armature at bow
	draw_rect(Rect2(-8, -52, 16, 12), Color(0.35, 0.35, 0.38))
	draw_line(Vector2(0, -52), Vector2(0, -62), Color(0.8, 0.75, 0.7), 3.0)
	draw_line(Vector2(-5, -58), Vector2(5, -58), Color(0.8, 0.75, 0.7), 2.0)

	# 3. Industrial mineral cargo bay & hazard stripes
	var bay_pts := PackedVector2Array([
		Vector2(-16, -10), Vector2(16, -10), Vector2(18, 12), Vector2(-18, 12)
	])
	draw_colored_polygon(bay_pts, armor_color)
	draw_line(Vector2(-12, -4), Vector2(12, -4), hazard_amber, 2.0)
	draw_line(Vector2(-12, 4), Vector2(12, 4), hazard_amber, 2.0)

	# 4. Hull breach with sparking electrical arcs
	draw_line(Vector2(-28, -6), Vector2(-38, 8), Color(0.15, 0.12, 0.1), 3.0)
	if sin(spark_phase * 2.0) > 0.3:
		draw_line(Vector2(-32, 2), Vector2(-46, 0), Color(0.4, 0.85, 1.0), 1.5)
		draw_line(Vector2(-30, 4), Vector2(-26, 14), Color(0.6, 0.95, 1.0), 1.5)

	# 5. Pulsing SOS distress beacon (top mast, intense amber/red strobe)
	draw_line(Vector2(10, -18), Vector2(16, -32), Color(0.6, 0.6, 0.65), 2.0)
	var beacon_glow: float = 0.5 + 0.5 * sin(spark_phase)
	var beacon_color := Color(1.0, 0.45 * beacon_glow + 0.2, 0.1, 0.95)
	draw_circle(Vector2(16, -34), 4.5, beacon_color)
	draw_arc(Vector2(16, -34), 8.0 + 4.0 * beacon_glow, 0.0, TAU, 16, Color(1.0, 0.5, 0.1, 0.35 * beacon_glow), 1.5)

