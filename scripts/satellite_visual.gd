extends Node2D
## Visual presentation node for satellite procedural fallback rendering.
## Encapsulates canvas drawing to decouple presentation from Satellite gameplay logic.

var is_extracted: bool = false
var beacon_phase: float = 0.0


func set_state(extracted: bool, phase: float) -> void:
	is_extracted = extracted
	beacon_phase = phase
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

