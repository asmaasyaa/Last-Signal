extends Node2D
## Visual and narrative representation of the wrecked scout craft encountered at the end of Stage 1 Level 3.
## Source of the player's primary weapon and deflector shield acquisition. Non-combat entity.

@export var ship_name: String = "Wrecked Scout Craft (Surveyor-7)"
@export var float_speed: float = 1.8
@export var float_amplitude: float = 6.0

var float_timer: float = 0.0
var spark_phase: float = 0.0


func _ready() -> void:
	add_to_group("wrecked_ships")
	queue_redraw()


func _process(delta: float) -> void:
	float_timer += delta * float_speed
	spark_phase = fmod(spark_phase + delta * 8.0, TAU)
	position.y += sin(float_timer) * float_amplitude * delta
	queue_redraw()


func _draw() -> void:
	# 1. Main fuselage (shattered scout craft, dark metallic slate)
	var hull_color := Color(0.24, 0.28, 0.35)
	var plate_color := Color(0.38, 0.44, 0.54)
	var outline_color := Color(0.68, 0.75, 0.86)

	# Main chassis polygon (sheared off rear starboard quadrant)
	var hull_pts := PackedVector2Array([
		Vector2(0, -38),      # Nose
		Vector2(24, -12),     # Starboard wing root (fractured)
		Vector2(12, 18),      # Broken starboard breach
		Vector2(-4, 30),      # Exposed engine bulkhead
		Vector2(-28, 22),     # Port engine mount
		Vector2(-52, 0),      # Port wing tip (intact)
		Vector2(-24, -18)     # Port forward canard
	])
	draw_colored_polygon(hull_pts, hull_color)
	var hull_outline := hull_pts.duplicate()
	hull_outline.append(hull_pts[0])
	draw_polyline(hull_outline, outline_color, 2.0, true)

	# 2. Port wing plating and intact weapon mount
	var port_plate := PackedVector2Array([
		Vector2(-18, -12), Vector2(-46, 2), Vector2(-26, 16), Vector2(-8, 6)
	])
	draw_colored_polygon(port_plate, plate_color)
	draw_polyline(port_plate, Color(0.5, 0.6, 0.75), 1.5)

	# Primary twin-barrel weapon assembly on intact port hardpoint (gold/amber accent)
	draw_rect(Rect2(-40, -18, 5, 20), Color(0.85, 0.7, 0.2))
	draw_rect(Rect2(-33, -18, 5, 20), Color(0.85, 0.7, 0.2))
	draw_line(Vector2(-37, -26), Vector2(-37, -18), Color(0.95, 0.85, 0.4), 2.0)
	draw_line(Vector2(-30, -26), Vector2(-30, -18), Color(0.95, 0.85, 0.4), 2.0)

	# 3. Deflector shield emitter dome (central chassis, glowing cyan)
	var shield_pulse: float = 0.5 + 0.5 * sin(spark_phase * 0.5)
	var shield_color := Color(0.2, 0.7, 1.0, 0.4 + 0.3 * shield_pulse)
	draw_circle(Vector2(-6, 2), 10.0, shield_color)
	draw_arc(Vector2(-6, 2), 10.0, 0.0, TAU, 24, Color(0.4, 0.9, 1.0, 0.9), 1.5)

	# 4. Cockpit canopy (cracked amber/bronze polarized glass)
	var canopy_pts := PackedVector2Array([
		Vector2(-6, -24), Vector2(6, -18), Vector2(4, -6), Vector2(-8, -10)
	])
	draw_colored_polygon(canopy_pts, Color(0.75, 0.45, 0.15, 0.75))
	draw_line(Vector2(-6, -24), Vector2(4, -6), Color(0.9, 0.8, 0.4), 1.0) # Fracture crack

	# 5. Starboard breach & electrical conduit hazard sparks
	draw_line(Vector2(24, -12), Vector2(12, 18), Color(0.95, 0.4, 0.15), 2.5) # Jagged fracture edge
	draw_line(Vector2(16, -2), Vector2(28, 6), Color(0.8, 0.35, 0.1), 1.5)
	if sin(spark_phase) > 0.3:
		draw_line(Vector2(18, 2), Vector2(24, -4), Color(1.0, 0.85, 0.3), 2.0)
		draw_circle(Vector2(24, -4), 2.5, Color(1.0, 0.95, 0.6))

