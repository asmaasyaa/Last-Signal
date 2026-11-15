extends SceneTree
## Milestone 3.5 Automated Test Suite for LAST SIGNAL (Asset Integration Readiness).
## Validates Visuals presentation subtree isolation, fallback rendering,
## sprite drop-in auto-detection, collision independence, and zero gameplay regression.

func _init() -> void:
	print("==================================================")
	print("LAST SIGNAL — Milestone 3.5 Automated Test Suite")
	print("==================================================")

	var runner = Node.new()
	runner.name = "TestRunnerMilestone3_5"
	root.add_child(runner)
	runner.set_script(load("res://tests/test_runner_milestone3_5.gd"))
