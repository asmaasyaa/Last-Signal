extends Node2D
## Procedural visual fallback and combat telegraph overlay for the Stage 3 Final Boss.
## Renders an armored spherical reactor core with perimeter containment rings when official
## art is unavailable, and supports attack windup/stun visual state indicators.

@export var hull_color: Color = Color(0.24, 0.20, 0.24, 1.0)
@export var frame_edge_color: Color = Color(0.55, 0.50, 0.56, 1.0)
@export var core_color: Color = Color(0.28, 0.82, 0.96, 1.0)
@export var accent_color: Color = Color(0.92, 0.28, 0.22, 1.0)
@export var is_charging_attack: bool = false
@export var is_stunned: bool = false
@export var current_phase: int = 1
@export var is_destroyed: bool = false

var anim_time: float = 0.0


func _process(delta: float) -> void:
	var rate: float = 9.0 if is_charging_attack else (1.5 if is_stunned else 3.2)
	anim_time += delta * rate
	queue_redraw()


func set_charging_attack(charging: bool) -> void:
	is_charging_attack = charging
	queue_redraw()


func set_stunned(stunned_state: bool) -> void:
	is_stunned = stunned_state
	queue_redraw()


func set_phase(p_phase: int) -> void:
	current_phase = p_phase
	queue_redraw()


func set_destroyed(destroyed: bool) -> void:
	is_destroyed = destroyed
	queue_redraw()


func _draw() -> void:
	if is_destroyed:
		draw_rect(Rect2(Vector2(-82.0, -82.0), Vector2(164.0, 164.0)), Color(0.10, 0.10, 0.13, 0.95))
		draw_rect(Rect2(Vector2(-82.0, -82.0), Vector2(164.0, 164.0)), Color(0.28, 0.28, 0.34, 0.8), false, 3.0)
		draw_circle(Vector2.ZERO, 56.0, Color(0.14, 0.15, 0.18, 1.0))
		return

	# Armored outer frame
	draw_rect(Rect2(Vector2(-88.0, -88.0), Vector2(176.0, 176.0)), hull_color)
	draw_rect(Rect2(Vector2(-88.0, -88.0), Vector2(176.0, 176.0)), frame_edge_color, false, 3.0)

	# Four corner anchor clamps
	for corner in [Vector2(-70.0, -70.0), Vector2(70.0, -70.0), Vector2(-70.0, 70.0), Vector2(70.0, 70.0)]:
		draw_circle(corner, 12.0, Color(0.16, 0.16, 0.22, 1.0))
		draw_circle(corner, 6.0, frame_edge_color)

	# White containment ring
	draw_circle(Vector2.ZERO, 68.0, Color(0.92, 0.92, 0.90, 0.95))

	# Inner energy core orb
	var active_core_color: Color = core_color
	if current_phase == 4:
		active_core_color = Color(0.95, 0.35, 0.35, 1.0)
	if is_charging_attack:
		var pulse: float = 0.5 + 0.5 * sin(anim_time * 3.0)
		active_core_color = active_core_color.lerp(Color(1.0, 0.45, 0.2, 1.0), 0.5 + 0.3 * pulse)
	elif is_stunned:
		active_core_color = Color(0.25, 0.65, 0.9, 0.75)

	draw_circle(Vector2.ZERO, 56.0, active_core_color)
	draw_circle(Vector2(-16.0, -16.0), 12.0, Color(1.0, 1.0, 1.0, 0.75))

	# Stun electrical arcs overlay
	if is_stunned:
		var offset_a: float = sin(anim_time * 5.0) * 14.0
		draw_line(Vector2(-75.0, -30.0 + offset_a), Vector2(75.0, 20.0 - offset_a), Color(0.3, 0.9, 1.0, 0.9), 3.0)
		draw_line(Vector2(-60.0, 45.0 - offset_a), Vector2(65.0, -40.0 + offset_a), Color(0.6, 0.95, 1.0, 0.85), 2.5)
	elif is_charging_attack:
		draw_arc(Vector2.ZERO, 96.0 + 4.0 * sin(anim_time * 4.0), 0.0, TAU, 36, accent_color, 3.0)
