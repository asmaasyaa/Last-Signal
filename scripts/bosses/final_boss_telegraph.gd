extends Node2D
## Overlay indicator rendering attack windup telegraph and EM Jammer stun feedback
## cleanly on top of official Final Boss artwork.

var charging: bool = false
var stunned_active: bool = false
var aim_dir: Vector2 = Vector2.DOWN
var pulse_time: float = 0.0


func _process(delta: float) -> void:
	if charging or stunned_active:
		pulse_time += delta * 8.0
		queue_redraw()


func set_state(is_charging: bool, is_stunned: bool, p_aim_dir: Vector2) -> void:
	charging = is_charging
	stunned_active = is_stunned
	aim_dir = p_aim_dir
	queue_redraw()


func _draw() -> void:
	if stunned_active:
		var jitter: float = 10.0 * sin(pulse_time * 2.5)
		draw_arc(Vector2.ZERO, 108.0, 0.0, TAU, 32, Color(0.25, 0.88, 1.0, 0.85), 3.0)
		draw_line(Vector2(-80.0, -25.0 + jitter), Vector2(80.0, 25.0 - jitter), Color(0.4, 0.95, 1.0, 0.95), 3.0)
		draw_line(Vector2(-75.0, 30.0 - jitter), Vector2(75.0, -30.0 + jitter), Color(0.4, 0.95, 1.0, 0.95), 2.5)
	elif charging:
		var pulse_alpha: float = 0.55 + 0.35 * sin(pulse_time * 2.0)
		draw_arc(Vector2.ZERO, 112.0, 0.0, TAU, 36, Color(1.0, 0.32, 0.22, pulse_alpha), 3.5)
		draw_line(aim_dir * 42.0, aim_dir * 165.0, Color(1.0, 0.4, 0.25, pulse_alpha * 0.7), 2.0)
