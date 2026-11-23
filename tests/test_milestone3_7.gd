extends SceneTree
## Milestone 3.7 Automated Test Suite for LAST SIGNAL (Team Asset Integration - Batch 02).
## Validates Batch 02 asset extraction & staging (44 total PNGs, 9 new), official Communication
## Satellite integration into Stage 1 Level 2 with Visuals subtree pattern, dual progress indicator rings,
## procedural fallback preservation, unscaled root collision geometry (CircleShape2D r=80.0),
## Stage 2 guard asset reservation, Nirawak 1 boundary preservation, and zero gameplay regression.

func _init() -> void:
	print("==================================================")
	print("LAST SIGNAL — Milestone 3.7 Automated Test Suite")
	print("==================================================")

	var runner = Node.new()
	runner.name = "TestRunnerMilestone3_7"
	root.add_child(runner)
	runner.set_script(load("res://tests/test_runner_milestone3_7.gd"))

