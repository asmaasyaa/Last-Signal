extends SceneTree
## Milestone 8 Automated Test Suite for LAST SIGNAL (Stage 2 Level 3: Kamikaze Guard Drone & EM Jammer Acquisition).
## Validates Level 2 -> Level 3 progression, HP persistence, Guard Drone enemy, kamikaze attack mechanics,
## strict kill credit attribution (player weapons only), untimed 5-kill elimination objective,
## EM Jammer equipment acquisition, Stage 2 checkpoint revive, and zero regression across M1-M7.

func _init() -> void:
	print("==================================================")
	print("LAST SIGNAL — Milestone 8 Automated Test Suite")
	print("==================================================")

	var runner = Node.new()
	runner.name = "TestRunnerMilestone8"
	root.add_child(runner)
	runner.set_script(load("res://tests/test_runner_milestone8.gd"))

