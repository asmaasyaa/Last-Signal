extends Node2D
## Visual presentation for mining satellite procedural fallback.
## Displays an industrial mining survey satellite with sensor dish, solar arrays, and beacon.

var is_extracted: bool = false
var beacon_phase: float = 0.0


func set_state(extracted: bool, phase: float) -> void:
	is_extracted = extracted
	beacon_phase = phase
	queue_redraw()


func _draw() -> void:
	# 1. Industrial octagonal mining chassis (bronze/ochre)
	var chassis_color := Color(0.85, 0.52, 0.22) if not is_extracted else Color(0.4, 0.85, 0.55)
	var chassis_pts := PackedVector2Array([
		Vector2(-12, -14), Vector2(12, -14),
		Vector2(16, -6), Vector2(16, 8),
		Vector2(10, 16), Vector2(-10, 16),
		Vector2(-16, 8), Vector2(-16, -6)
	])
	draw_colored_polygon(chassis_pts, chassis_color)
	draw_polyline(chassis_pts, Color(1.0, 0.8, 0.4), 1.5, true)

	# 2. Quad industrial solar panels (angled wings)
	# Left panels
	draw_rect(Rect2(-38, -12, 18, 10), Color(0.2, 0.35, 0.55))
	draw_rect(Rect2(-38, -12, 18, 10), Color(0.4, 0.7, 0.9), false, 1.0)
	draw_rect(Rect2(-38, 4, 18, 10), Color(0.2, 0.35, 0.55))
	draw_rect(Rect2(-38, 4, 18, 10), Color(0.4, 0.7, 0.9), false, 1.0)

	# Right panels
	draw_rect(Rect2(20, -12, 18, 10), Color(0.2, 0.35, 0.55))
	draw_rect(Rect2(20, -12, 18, 10), Color(0.4, 0.7, 0.9), false, 1.0)
	draw_rect(Rect2(20, 4, 18, 10), Color(0.2, 0.35, 0.55))
	draw_rect(Rect2(20, 4, 18, 10), Color(0.4, 0.7, 0.9), false, 1.0)

	# 3. Sensor dish / survey scanner at the bottom
	draw_arc(Vector2(0, 16), 8.0, 0.2, PI - 0.2, 16, Color(0.9, 0.85, 0.7), 2.0)
	draw_line(Vector2(0, 16), Vector2(0, 22), Color(0.9, 0.85, 0.7), 1.5)

	# 4. Antenna and pulsating beacon at top
	draw_line(Vector2(0, -14), Vector2(0, -26), Color(0.85, 0.85, 0.9), 2.0)
	var beacon_color: Color
	if is_extracted:
		beacon_color = Color(0.2, 1.0, 0.4)
	elif sin(beacon_phase) > 0.0:
		beacon_color = Color(1.0, 0.65, 0.1)
	else:
		beacon_color = Color(0.4, 0.2, 0.05)
	draw_circle(Vector2(0, -27), 3.5, beacon_color)

