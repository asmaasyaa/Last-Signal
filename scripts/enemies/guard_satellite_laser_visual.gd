extends Area2D
## Procedural laser hit-detection and beam visual for Guard Satellite in LAST SIGNAL.
## Handles collision queries against the player and renders warning telegraph lines and active energy beams.

var parent_satellite: Area2D = null


func _ready() -> void:
	parent_satellite = get_parent() as Area2D


func _draw() -> void:
	if not is_instance_valid(parent_satellite) or "attack_state" not in parent_satellite:
		return

	var state: int = parent_satellite.attack_state
	var beam_length: float = 1400.0

	# Local +X axis points along firing vector
	if state == 1: # AttackState.TELEGRAPH
		# Warning telegraph line
		draw_line(Vector2.ZERO, Vector2(beam_length, 0.0), Color(1.0, 0.2, 0.2, 0.45), 1.5)
		# Muzzle charge indicator
		draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.2, 0.2, 0.7))

	elif state == 2: # AttackState.FIRING
		# Outer glow corona
		draw_line(Vector2.ZERO, Vector2(beam_length, 0.0), Color(1.0, 0.15, 0.15, 0.35), 14.0)
		# Energy beam core
		draw_line(Vector2.ZERO, Vector2(beam_length, 0.0), Color(1.0, 0.5, 0.2, 0.85), 6.0)
		# Superheated central laser ray
		draw_line(Vector2.ZERO, Vector2(beam_length, 0.0), Color(1.0, 0.95, 0.85, 1.0), 2.5)
		# Muzzle flare
		draw_circle(Vector2.ZERO, 10.0, Color(1.0, 0.4, 0.2, 0.9))
		draw_circle(Vector2.ZERO, 5.0, Color.WHITE)

