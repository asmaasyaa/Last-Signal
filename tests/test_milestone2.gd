extends SceneTree
## Milestone 2 Automated Test Suite for LAST SIGNAL (Stage 1 Level 2).
## Validates HP persistence, stage revive semantics, medium asteroids, and satellite extraction.

func _init() -> void:
	print("==================================================")
	print("LAST SIGNAL — Milestone 2 Automated Test Suite")
	print("==================================================")

	var runner = Node.new()
	runner.name = "TestRunnerMilestone2"
	root.add_child(runner)
	runner.set_script(load("res://tests/test_runner_milestone2.gd"))

