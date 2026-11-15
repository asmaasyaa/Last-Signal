extends SceneTree
## Milestone 1 Automated Test Suite for LAST SIGNAL (Stage 1 Level 1).
## Validates HP damage, collision cooldown, passive regeneration, and game state transitions.

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0


func _init() -> void:
	print("==================================================")
	print("LAST SIGNAL — Milestone 1 Automated Test Suite")
	print("==================================================")

	var runner = Node.new()
	runner.name = "TestRunner"
	root.add_child(runner)
	runner.set_script(load("res://tests/test_runner_logic.gd"))
