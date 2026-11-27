extends SceneTree
## Milestone 11 Entry Point (Stage 3 Level 1: Final Boss Phase 1 + Stage 2 Integration Audit).
## Executes test_runner_milestone11.gd under Godot 4.7.2 headless mode.

func _init() -> void:
	print("==================================================")
	print("LAST SIGNAL — Milestone 11 Automated Test Suite")
	print("==================================================")

	var runner_script = load("res://tests/test_runner_milestone11.gd")
	var runner = runner_script.new()
	root.add_child(runner)
