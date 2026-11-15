extends Node2D
## Visual presentation node for asteroid procedural fallback rendering.
## Encapsulates canvas drawing to decouple presentation from Asteroid gameplay logic.

var rock_vertices := PackedVector2Array()
var visual_scale: float = 1.0


func set_geometry(vertices: PackedVector2Array, v_scale: float) -> void:
	rock_vertices = vertices
	visual_scale = v_scale
	queue_redraw()


func _draw() -> void:
	if rock_vertices.is_empty():
		return
	draw_colored_polygon(rock_vertices, Color(0.39, 0.44, 0.53))
	var outline: PackedVector2Array = rock_vertices.duplicate()
	outline.append(rock_vertices[0])
	draw_polyline(outline, Color(0.78, 0.84, 0.92), 2.0, true)

	var s: float = visual_scale
	draw_line(Vector2(-9, -4) * s, Vector2(2, -12) * s, Color(0.67, 0.71, 0.78), 2.0)
	draw_line(Vector2(5, 8) * s, Vector2(13, 4) * s, Color(0.67, 0.71, 0.78), 2.0)

