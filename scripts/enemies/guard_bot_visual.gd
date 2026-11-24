extends Node2D
## Procedural visual fallback for Guard Bot in LAST SIGNAL.
## Renders an armored security automaton with red central optics and weapon pod.

var is_attacking: bool = false

func set_attacking(attacking: bool) -> void:
	is_attacking = attacking
	queue_redraw()


func _draw() -> void:
	# Armored hull octagon
	var hull_color := Color(0.28, 0.32, 0.42, 1.0)
	var hull_outline := Color(0.48, 0.58, 0.72, 1.0)
	var points := PackedVector2Array([
		Vector2(-18, -12), Vector2(-10, -20), Vector2(10, -20), Vector2(18, -12),
		Vector2(18, 12), Vector2(10, 20), Vector2(-10, 20), Vector2(-18, 12)
	])
	draw_colored_polygon(points, hull_color)
	draw_polyline(points, hull_outline, 2.0)

	# Left-facing weapon hardpoint (aimed forward in side-scroller)
	var muzzle_color := Color(0.9, 0.3, 0.15) if is_attacking else Color(0.6, 0.65, 0.75)
	draw_rect(Rect2(Vector2(-24, -4), Vector2(8, 8)), muzzle_color)

	# Central red optical sensor
	var eye_color := Color(1.0, 0.15, 0.1) if not is_attacking else Color(1.0, 0.9, 0.2)
	draw_circle(Vector2(-2, 0), 5.0, eye_color)
	draw_circle(Vector2(-2, 0), 2.0, Color(1.0, 1.0, 1.0, 0.9))

