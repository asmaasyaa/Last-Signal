extends SceneTree
## Milestone 9 Automated Test Suite for LAST SIGNAL (Stage 2 Level 4: Guard Cruiser Mini-Boss Phase 1 & EM Jammer Activation).
## Validates Level 3 -> Level 4 progression, transition to full arcade boss arena,
## Guard Cruiser mini-boss entity (400 -> 200 HP threshold), official Phase 1 art integration,
## controlled aimed burst attacks, EM Jammer directional cone (120 deg, 10s stun, 30s CD),
## Stage 2 checkpoint revive, and system-wide regression across M1-M8.

func _init() -> void:
	print("==================================================")
	print("LAST SIGNAL — Milestone 9 Automated Test Suite")
	print("==================================================")

	var runner = Node.new()
	runner.name = "TestRunnerMilestone9"
	root.add_child(runner)
	runner.set_script(load("res://tests/test_runner_milestone9.gd"))
