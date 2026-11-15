---
name: godot-gameplay-testing
description: Use when verifying gameplay mechanics, running automated test scripts, validating physics and collisions, and diagnosing runtime issues in Godot 4.7.2 for LAST SIGNAL.
---

# Godot Gameplay Testing Skill — LAST SIGNAL

This skill provides procedures and verification standards for validating gameplay correctness, diagnosing bugs, and executing test suites in Godot 4.7.2 Standard.

---

## 1. Locating the Engine Executable

1. Check for `godot` on the system `PATH`:
   ```bash
   which godot
   ```
2. If not on `PATH`, check standard local paths (e.g., `~/Downloads/app/Godot_v4.7.2-stable_linux.x86_64` or local engine installs).
3. Confirm version:
   ```bash
   <godot_path> --version
   ```
4. **Portability Rule:** Never commit machine-specific absolute executable paths into project files (`project.godot`, `.gd`, `.tscn`).

---

## 2. Static & Headless Project Validation

Execute headless engine parsing before running tests:
1. **Headless Project Validation:**
   ```bash
   <godot_path> --headless --validate --quit
   ```
   Ensures scene files, UID references, and resources load without syntax or parse errors.
2. **Script Syntax Check:**
   ```bash
   <godot_path> --headless --check-only -s <script_path>
   ```
3. **Inspect Output & Exit Codes:**
   - Both commands must return exit code `0`.
   - Inspect stdout and stderr for warnings, missing resource errors, or broken script references.
4. **Critical Rule:** Headless validation proves **syntactic validity only**, not gameplay correctness. Never declare a feature working based solely on `--validate`.

---

## 3. Automated Test Construction & Execution

Where feasible, create automated test scripts under `tests/` (e.g. `tests/test_milestone1.gd`) executed via:
```bash
<godot_path> --headless -s tests/test_milestone1.gd
```

### Core Areas to Validate Against `docs/SPECIFICATIONS.md`:
1. **Health & Damage:**
   - Initial HP matches specification (e.g., 12 HP).
   - Taking single-hit damage reduces HP correctly and emits `health_changed`.
   - Zero and negative damage amounts are safely ignored.
   - Overkill damage clamps HP strictly at 0.
   - Fatal damage emits `died` and sets `alive = false`.
   - Damage attempts after death do not emit duplicate signals or mutate state.
2. **Collision Cooldown & Rate-Limiting:**
   - Contact cooldown matches specification (e.g., 0.5s per contact pair).
   - Sustained overlap does not inflict per-frame damage.
   - **No Generic Invulnerability Frames:** Two hazards overlapping simultaneously must each inflict independent damage events.
   - **Separation & Re-entry Safety:** An entity separating and re-entering within the cooldown period must not bypass the remaining cooldown.
   - **Safe Object Pruning:** Destroyed or queued-for-deletion entities (`queue_free()`) must be cleanly pruned from cooldown tracking dictionaries without leaving stale references.
3. **Passive Health Regeneration:**
   - Regeneration activates only when movement speed $\le$ `stop_threshold`.
   - Stationary delay (`regen_wait`) is honored before regeneration accumulation starts.
   - Regeneration accumulates at the specified rate (e.g. 1 HP/s) and restores integer HP correctly.
   - Health does not exceed `max_health`.
   - Moving above `stop_threshold` immediately resets `still_seconds` and halts regeneration.
4. **Timers & State Transitions:**
   - Level countdown timer decrements accurately.
   - Reaching 0 HP cleanly transitions to Game Over and disables player physics.
   - Reaching 0 timer seconds cleanly transitions to Level Complete and disables player physics.
   - Restart mechanism (`restart_level()`) cleanly reloads or resets state.
5. **Real Physics Integration:**
   - Validate that actual `Area2D` collision shapes detect overlaps across physics ticks (`await get_tree().physics_frame`).

---

## 4. Verification Evidence & Reporting Standards

- **Strict Evidence Rule:** Never report a test as passing unless it was actually executed and the stdout output and exit code were verified.
- **Categorized Test Reporting:** Group all verification results into three distinct categories:
  - **PASS:** Confirmed by executed automated test or validated command output.
  - **FAIL:** Executed check that did not produce the expected result.
  - **NOT TESTED:** Features requiring manual GUI interaction or deferred to future milestones.

---

## 5. Manual GUI Testing Requirements

For behaviors that cannot be fully automated headlessly (e.g., mouse steering feel, visual aesthetic, HUD legibility, window sizing), always supply a numbered manual testing checklist:
1. Specific user action (e.g. "Move mouse cursor to top-left corner").
2. Expected visual or interactive behavior (e.g. "Ship follows cursor and clamps at 24px screen margin without leaving screen").
3. Verification confirmation box `[ ]`.

