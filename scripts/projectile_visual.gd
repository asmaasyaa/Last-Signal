extends Node2D
## Procedural fallback graphics for twin-barrel pulse projectile.
## Encapsulates canvas drawing to decouple presentation from projectile physics.

func _draw() -> void:
	# Outer glowing energy bolt
	draw_line(Vector2(0, -7), Vector2(0, 7), Color(0.2, 0.75, 1.0, 0.9), 4.0)
	# Inner bright energy core
	draw_line(Vector2(0, -6), Vector2(0, 6), Color(0.85, 0.95, 1.0, 1.0), 2.0)

