extends Node2D
## Procedural visual fallback for Guard Satellite in LAST SIGNAL Stage 2 Level 2.
## Renders an armored orbital defense satellite with dual solar arrays and a forward laser optical emitter.

@export var is_attacking: bool = false
@export var core_color: Color = Color(0.18, 0.22, 0.32, 1.0)
@export var armor_color: Color = Color(0.28, 0.35, 0.48, 1.0)
@export var solar_color: Color = Color(0.15, 0.45, 0.85, 0.95)
@export var emitter_color: Color = Color(1.0, 0.25, 0.25, 1.0)

var pulse_time: float = 0.0


func _process(delta: float) -> void:
	pulse_time += delta * (8.0 if is_attacking else 3.0)
	queue_redraw()


func set_attacking(p_attacking: bool) -> void:
	is_attacking = p_attacking
	queue_redraw()


func _draw() -> void:
	# Facing leftward in local space (X-negative is forward)
	# 1. Dual solar array panels (top and bottom wings)
	var wing_top := Rect2(Vector2(-14.0, -38.0), Vector2(28.0, 16.0))
	var wing_bot := Rect2(Vector2(-14.0, 22.0), Vector2(28.0, 16.0))
	draw_rect(wing_top, solar_color)
	draw_rect(wing_top, Color.WHITE, false, 1.0)
	draw_rect(wing_bot, solar_color)
	draw_rect(wing_bot, Color.WHITE, false, 1.0)

	# Panel grid lines
	draw_line(Vector2(0.0, -38.0), Vector2(0.0, -22.0), Color(0.8, 0.9, 1.0, 0.7), 1.0)
	draw_line(Vector2(0.0, 22.0), Vector2(0.0, 38.0), Color(0.8, 0.9, 1.0, 0.7), 1.0)

	# 2. Main armored satellite hull (hexagonal profile)
	var hull_pts: PackedVector2Array = [
		Vector2(-20.0, 0.0),
		Vector2(-12.0, -18.0),
		Vector2(14.0, -18.0),
		Vector2(22.0, 0.0),
		Vector2(14.0, 18.0),
		Vector2(-12.0, 18.0)
	]
	draw_colored_polygon(hull_pts, core_color)
	draw_polyline(hull_pts + PackedVector2Array([hull_pts[0]]), armor_color, 2.0)

	# 3. Inner armored housing
	draw_circle(Vector2(2.0, 0.0), 10.0, Color(0.12, 0.15, 0.22, 1.0))
	draw_arc(Vector2(2.0, 0.0), 10.0, 0.0, TAU, 16, armor_color, 1.5)

	# 4. Forward optical laser aperture (at nose, X = -20)
	var glow_alpha: float = 0.5 + 0.5 * sin(pulse_time)
	var lens_color: Color = Color(1.0, 0.3, 0.3, glow_alpha) if is_attacking else emitter_color
	draw_circle(Vector2(-20.0, 0.0), 5.0, lens_color)
	draw_circle(Vector2(-20.0, 0.0), 2.5, Color.WHITE)

	if is_attacking:
		# Attack charge corona
		draw_arc(Vector2(-20.0, 0.0), 9.0 + 2.0 * sin(pulse_time * 2.0), 0.0, TAU, 16, Color(1.0, 0.4, 0.2, 0.8), 2.0)

