extends SceneTree
## Milestone 4 Automated Test Suite for LAST SIGNAL (Stage 1 Level 4: Twin-Barrel Shooting & Asteroid Combat).
## Validates Level 3 -> Level 4 progression, twin-barrel primary weapon mechanics, projectile physics,
## asteroid health & destruction, Stage 1 checkpoint revive semantics, and zero regression.

func _init() -> void:
	print("==================================================")
	print("LAST SIGNAL — Milestone 4 Automated Test Suite")
	print("==================================================")

	var runner = Node.new()
	runner.name = "TestRunnerMilestone4"
	root.add_child(runner)
	runner.set_script(load("res://tests/test_runner_milestone4.gd"))

