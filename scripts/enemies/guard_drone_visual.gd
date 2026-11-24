extends Node2D
## Procedural visual fallback for Guard Drone in LAST SIGNAL Stage 2 Level 3.
## Renders a sleek high-speed kamikaze interceptor drone with an arrowhead armored hull,
## rear thruster exhaust flare, and a forward red optical cluster / charge corona.

@export var is_attacking: bool = false
@export var hull_color: Color = Color(0.20, 0.24, 0.35, 1.0)
@export var armor_edge_color: Color = Color(0.40, 0.50, 0.68, 1.0)
@export var thruster_color: Color = Color(1.0, 0.55, 0.15, 0.95)
@export var sensor_color: Color = Color(1.0, 0.20, 0.20, 1.0)
@export var charge_glow_color: Color = Color(1.0, 0.40, 0.15, 0.85)

var pulse_time: float = 0.0


func _process(delta: float) -> void:
	pulse_time += delta * (12.0 if is_attacking else 4.0)
	queue_redraw()


func set_attacking(p_attacking: bool) -> void:
	is_attacking = p_attacking
	queue_redraw()


func _draw() -> void:
	# Facing leftward in local space (X-negative is forward)
	# 1. Rear thruster exhaust flare (extends rightward from X = 16 to X = 32)
	var flare_len: float = 16.0 + 8.0 * sin(pulse_time * 1.5)
	if is_attacking:
		flare_len += 12.0 # Extended afterburner flare during telegraph/charge
	var flare_pts: PackedVector2Array = [
		Vector2(14.0, -6.0),
		Vector2(14.0 + flare_len, 0.0),
		Vector2(14.0, 6.0)
	]
	draw_colored_polygon(flare_pts, thruster_color)
	draw_circle(Vector2(14.0, 0.0), 4.0, Color.WHITE)

	# 2. Sleek arrowhead interceptor hull (forward tip at X = -24)
	var hull_pts: PackedVector2Array = [
		Vector2(-24.0, 0.0),   # Forward nose tip
		Vector2(-6.0, -16.0),  # Upper wing tip
		Vector2(16.0, -12.0),  # Upper rear engine mount
		Vector2(10.0, 0.0),    # Rear engine center notch
		Vector2(16.0, 12.0),   # Lower rear engine mount
		Vector2(-6.0, 16.0)    # Lower wing tip
	]
	draw_colored_polygon(hull_pts, hull_color)
	draw_polyline(hull_pts + PackedVector2Array([hull_pts[0]]), armor_edge_color, 2.0)

	# 3. Inner armored spine and cockpit canopy
	var spine_pts: PackedVector2Array = [
		Vector2(-14.0, 0.0),
		Vector2(0.0, -5.0),
		Vector2(8.0, 0.0),
		Vector2(0.0, 5.0)
	]
	draw_colored_polygon(spine_pts, Color(0.12, 0.15, 0.22, 1.0))
	draw_polyline(spine_pts + PackedVector2Array([spine_pts[0]]), armor_edge_color, 1.0)

	# 4. Forward optical cluster / kamikaze payload lens (at X = -20)
	var glow_intensity: float = 0.6 + 0.4 * sin(pulse_time)
	var active_sensor_color: Color = sensor_color
	active_sensor_color.a = glow_intensity
	draw_circle(Vector2(-20.0, 0.0), 4.5, active_sensor_color)
	draw_circle(Vector2(-20.0, 0.0), 2.0, Color.WHITE)

	# 5. Attack telegraph / charge corona
	if is_attacking:
		var corona_radius: float = 10.0 + 3.0 * sin(pulse_time * 2.0)
		draw_arc(Vector2(-20.0, 0.0), corona_radius, 0.0, TAU, 16, charge_glow_color, 2.0)
		# Warning shockwave ring
		draw_arc(Vector2(0.0, 0.0), 22.0 + 2.0 * sin(pulse_time), 0.0, TAU, 24, Color(1.0, 0.3, 0.1, 0.4), 1.5)

