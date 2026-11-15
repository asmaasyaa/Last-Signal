extends SceneTree
## Milestone 3.6 Automated Test Suite for LAST SIGNAL (Team Asset Integration - Batch 01).
## Validates Player official sprite integration, visual state switching, fallback toggling,
## asset integrity, modular menu UI (Main Menu, Level Select), progression protection,
## and zero gameplay regression.

func _init() -> void:
	print("==================================================")
	print("LAST SIGNAL — Milestone 3.6 Automated Test Suite")
	print("==================================================")

	var runner = Node.new()
	runner.name = "TestRunnerMilestone3_6"
	root.add_child(runner)
	runner.set_script(load("res://tests/test_runner_milestone3_6.gd"))

