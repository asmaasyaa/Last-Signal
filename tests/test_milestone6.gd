extends SceneTree
## Milestone 6 Automated Test Suite for LAST SIGNAL (Stage 2 Level 1: Side-Scrolling & First Hostile Contact).
## Validates Stage 1 -> Stage 2 transition, side-scrolling mechanics, Guard Bot enemy, enemy projectiles,
## 15-second survival objective, Stage 2 checkpoint revive, and zero regression across M1-M5.

func _init() -> void:
	print("==================================================")
	print("LAST SIGNAL — Milestone 6 Automated Test Suite")
	print("==================================================")

	var runner = Node.new()
	runner.name = "TestRunnerMilestone6"
	root.add_child(runner)
	runner.set_script(load("res://tests/test_runner_milestone6.gd"))

