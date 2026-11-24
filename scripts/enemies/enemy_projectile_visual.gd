extends Node2D
## Procedural visual fallback for enemy projectiles in LAST SIGNAL.
## Renders a high-visibility glowing energy round with core and aura.

func _draw() -> void:
	# Outer glow aura
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.25, 0.1, 0.45))
	# Mid energy ring
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.45, 0.15, 0.85))
	# White-hot plasma core
	draw_circle(Vector2.ZERO, 2.0, Color(1.0, 0.95, 0.8, 1.0))

