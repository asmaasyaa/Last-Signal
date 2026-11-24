extends SceneTree
## Milestone 7 Automated Test Suite for LAST SIGNAL (Stage 2 Level 2: Guard Satellite & Accurate Laser Combat).
## Validates Level 1 -> Level 2 progression, HP persistence, Guard Satellite enemy, accurate laser attacks,
## real physics collision & dodge mechanics, 20-second survival objective, Stage 2 checkpoint revive, and zero regression.

func _init() -> void:
	print("==================================================")
	print("LAST SIGNAL — Milestone 7 Automated Test Suite")
	print("==================================================")

	var runner = Node.new()
	runner.name = "TestRunnerMilestone7"
	root.add_child(runner)
	runner.set_script(load("res://tests/test_runner_milestone7.gd"))

