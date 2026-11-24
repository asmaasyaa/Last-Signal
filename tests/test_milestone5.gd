extends SceneTree
## Milestone 5 Automated Test Suite for LAST SIGNAL (Stage 1 Level 5: Final Asteroid Sector & Mining Ship SOS).
## Validates Level 4 -> Level 5 progression, twin-barrel combat in L5, proximity extraction of mining satellite,
## Stage 1 Level 5 completion, damaged mining ship SOS signal emission, Stage 1 checkpoint revive, and zero regression.

func _init() -> void:
	print("==================================================")
	print("LAST SIGNAL — Milestone 5 Automated Test Suite")
	print("==================================================")

	var runner = Node.new()
	runner.name = "TestRunnerMilestone5"
	root.add_child(runner)
	runner.set_script(load("res://tests/test_runner_milestone5.gd"))

