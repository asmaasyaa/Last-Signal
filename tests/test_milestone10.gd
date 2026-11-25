extends SceneTree
## Milestone 10 Entry Point (Stage 2 Level 5: Guard Cruiser Phase 2, Final Defeat & Stage 2 Completion).
## Executes test_runner_milestone10.gd under Godot 4.7.2 headless mode.

func _init() -> void:
	print("==================================================")
	print("LAST SIGNAL — Milestone 10 Automated Test Suite")
	print("==================================================")

	var runner_script = load("res://tests/test_runner_milestone10.gd")
	var runner = runner_script.new()
	root.add_child(runner)

