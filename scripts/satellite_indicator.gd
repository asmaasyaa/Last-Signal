extends Node2D
## Visual indicator for proximity radius and extraction progress.
## Rendered with z_index > 0 so indicators remain clearly visible above sprite art.

func _draw() -> void:
	var sat = get_parent()
	if not is_instance_valid(sat):
		return

	# 1. Interaction radius boundary
	var ring_color: Color = Color(0.3, 0.8, 1.0, 0.18) if not sat.player_in_range else Color(0.4, 1.0, 0.6, 0.35)
	draw_arc(Vector2.ZERO, sat.extraction_radius, 0.0, TAU, 32, ring_color, 1.5)

	# 2. Extraction progress ring (visible and readable above sprite)
	var progress_radius: float = 48.0
	if sat.extraction_progress > 0.0 and not sat.is_extracted:
		# Background guide ring
		draw_arc(Vector2.ZERO, progress_radius, 0.0, TAU, 32, Color(0.1, 0.3, 0.2, 0.4), 2.0)
		# Active progress arc
		draw_arc(Vector2.ZERO, progress_radius, -PI * 0.5, -PI * 0.5 + sat.extraction_progress * TAU, 32, Color(0.3, 1.0, 0.4, 0.95), 3.5)
		# Inner arc at 30.0 px
		draw_arc(Vector2.ZERO, 30.0, -PI * 0.5, -PI * 0.5 + sat.extraction_progress * TAU, 32, Color(0.5, 1.0, 0.6, 0.8), 2.0)
	elif sat.is_extracted:
		draw_arc(Vector2.ZERO, progress_radius, 0.0, TAU, 32, Color(0.2, 0.9, 0.4, 0.85), 2.5)
		draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 32, Color(0.3, 1.0, 0.5, 0.7), 1.5)

