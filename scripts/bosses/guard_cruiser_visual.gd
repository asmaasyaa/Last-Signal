extends Node2D
## Procedural visual fallback for Guard Cruiser Mini-Boss in LAST SIGNAL Stage 2 Level 4.
## Renders a heavy capital battlecruiser with an armored command bridge, twin broadside weapon sponsons,
## forward optical sensor array, and pulsating engine thruster flares.

@export var hull_color: Color = Color(0.18, 0.22, 0.32, 1.0)
@export var armor_edge_color: Color = Color(0.38, 0.48, 0.65, 1.0)
@export var accent_color: Color = Color(0.85, 0.30, 0.20, 1.0)
@export var engine_color: Color = Color(0.20, 0.70, 1.0, 0.9)
@export var is_charging_attack: bool = false
@export var is_stunned: bool = false

var anim_time: float = 0.0


func _process(delta: float) -> void:
	anim_time += delta * (10.0 if is_charging_attack else (2.0 if is_stunned else 4.0))
	queue_redraw()


func set_charging_attack(charging: bool) -> void:
	is_charging_attack = charging
	queue_redraw()


func set_stunned(stunned_state: bool) -> void:
	is_stunned = stunned_state
	queue_redraw()


func _draw() -> void:
	# Cruiser faces downward (+Y is forward / towards the player)
	# 1. Rear Engine Plumes (top edge, Y around -60 to -85)
	var thruster_flicker: float = 6.0 * sin(anim_time * 2.0)
	if not is_stunned:
		var left_plume: PackedVector2Array = [
			Vector2(-70.0, -50.0),
			Vector2(-60.0, -75.0 - thruster_flicker),
			Vector2(-50.0, -50.0)
		]
		var right_plume: PackedVector2Array = [
			Vector2(50.0, -50.0),
			Vector2(60.0, -75.0 - thruster_flicker),
			Vector2(70.0, -50.0)
		]
		var center_plume: PackedVector2Array = [
			Vector2(-20.0, -55.0),
			Vector2(0.0, -85.0 - thruster_flicker * 1.5),
			Vector2(20.0, -55.0)
		]
		draw_colored_polygon(left_plume, engine_color)
		draw_colored_polygon(right_plume, engine_color)
		draw_colored_polygon(center_plume, Color(1.0, 0.6, 0.2, 0.95))

	# 2. Main Armored Heavy Cruiser Hull (Wide wedge profile)
	var hull_pts: PackedVector2Array = [
		Vector2(0.0, 65.0),     # Forward prow tip
		Vector2(-45.0, 45.0),   # Forward left bevel
		Vector2(-110.0, 15.0),  # Left wing broadside sponson forward
		Vector2(-125.0, -25.0), # Left wing broadside sponson rear
		Vector2(-80.0, -52.0),  # Left engine shoulder
		Vector2(80.0, -52.0),   # Right engine shoulder
		Vector2(125.0, -25.0),  # Right wing broadside sponson rear
		Vector2(110.0, 15.0),   # Right wing broadside sponson forward
		Vector2(45.0, 45.0)     # Forward right bevel
	]
	draw_colored_polygon(hull_pts, hull_color)
	draw_polyline(hull_pts + PackedVector2Array([hull_pts[0]]), armor_edge_color, 3.0)

	# 3. Inner Armor Plating & Command Deck
	var bridge_pts: PackedVector2Array = [
		Vector2(0.0, 25.0),
		Vector2(-35.0, -10.0),
		Vector2(-30.0, -40.0),
		Vector2(30.0, -40.0),
		Vector2(35.0, -10.0)
	]
	draw_colored_polygon(bridge_pts, Color(0.12, 0.15, 0.24, 1.0))
	draw_polyline(bridge_pts + PackedVector2Array([bridge_pts[0]]), armor_edge_color, 1.5)

	# 4. Command Deck Viewport / Core Crystal
	var core_color: Color = Color(0.2, 0.8, 1.0, 0.9) if not is_charging_attack else Color(1.0, 0.3, 0.2, 1.0)
	draw_circle(Vector2(0.0, -10.0), 9.0, core_color)
	draw_circle(Vector2(0.0, -10.0), 4.5, Color.WHITE)

	# 5. Weapon Muzzles / Sponsons (Left & Right)
	draw_rect(Rect2(Vector2(-105.0, 10.0), Vector2(14.0, 20.0)), Color(0.25, 0.28, 0.38, 1.0))
	draw_rect(Rect2(Vector2(91.0, 10.0), Vector2(14.0, 20.0)), Color(0.25, 0.28, 0.38, 1.0))
	draw_circle(Vector2(-98.0, 30.0), 4.0, accent_color)
	draw_circle(Vector2(98.0, 30.0), 4.0, accent_color)

	# 6. Attack Wind-Up Charging Glow
	if is_charging_attack:
		var charge_pulse: float = 6.0 + 4.0 * sin(anim_time * 2.0)
		draw_arc(Vector2(0.0, 65.0), 12.0 + charge_pulse, 0.0, TAU, 16, Color(1.0, 0.3, 0.2, 0.8), 2.5)
		draw_arc(Vector2(-98.0, 30.0), 8.0 + charge_pulse * 0.7, 0.0, TAU, 12, Color(1.0, 0.5, 0.2, 0.8), 2.0)
		draw_arc(Vector2(98.0, 30.0), 8.0 + charge_pulse * 0.7, 0.0, TAU, 12, Color(1.0, 0.5, 0.2, 0.8), 2.0)

	# 7. EM Jammer Stun Electrical Arc FX
	if is_stunned:
		var stun_alpha: float = 0.6 + 0.4 * sin(anim_time * 3.0)
		var arc_color: Color = Color(0.3, 0.9, 1.0, stun_alpha)
		draw_arc(Vector2(0.0, 0.0), 75.0 + 5.0 * sin(anim_time * 1.5), 0.0, TAU, 24, arc_color, 2.0)
		# Diagonal electric arcs across the hull
		draw_line(Vector2(-70.0, 20.0), Vector2(-15.0, -20.0), arc_color, 2.0)
		draw_line(Vector2(-15.0, -20.0), Vector2(40.0, 10.0), arc_color, 2.0)
		draw_line(Vector2(40.0, 10.0), Vector2(80.0, -15.0), arc_color, 2.0)
