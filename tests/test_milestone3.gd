extends SceneTree
## Milestone 3 Automated Test Suite for LAST SIGNAL (Stage 1 Level 3).
## Validates Level 3 progression, large asteroids, wrecked spacecraft encounter, and equipment acquisition.

func _init() -> void:
	print("==================================================")
	print("LAST SIGNAL — Milestone 3 Automated Test Suite")
	print("==================================================")

	var runner = Node.new()
	runner.name = "TestRunnerMilestone3"
	root.add_child(runner)
	runner.set_script(load("res://tests/test_runner_milestone3.gd"))

