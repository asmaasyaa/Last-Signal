# LAST SIGNAL - Godot Prototype (Milestone 3.6 — Team Asset Integration Batch 01)

> **Development Status:** WIP — Milestone 3.6 implemented, manual GUI QA pending.  
> A verified 2D space SHMUP prototype in Godot 4.7.2 featuring Stage 1 Levels 1–3, official team art integration, modular menu UI, and 435 automated regression tests.

## Setup

1. Download **Godot 4.7.2 stable — Standard** from https://godotengine.org/download/ (not .NET).
2. Extract the starter ZIP to a local folder.
3. In Godot Project Manager, click **Import**, locate this folder's `project.godot`, and open it.
4. Press **F6** from `scenes/main.tscn` (direct gameplay) or `scenes/ui/main_menu.tscn` (menu flow), or **F5** to start.
5. Move the mouse to steer the ship. Stay alive for 30 seconds. Press **R** to restart, **Esc** to quit.

## Current Prototype Implementation Status (Milestone 3.6)

- **Stage 1 Levels 1–3:** Fully implemented 30-second arcade survival gameplay with HP persistence across levels, stage checkpoint revive, optional satellite extraction in Level 2, and weapon/shield recovery in Level 3.
- **Official Team Art (Batch 01):** Player ship (`alive.png`, `dead.png`) integrated into `player.tscn` with dynamic state switching; modular Main Menu and Level Select UI integrated using official team button textures.
- **Safe Fallback Architecture:** Procedural vector drawing serves as an automatic fallback whenever custom art is missing or disabled.
- **Staged Assets:** Stage 2 mini-boss, Stage 3 boss components, and overheat label are imported and cataloged for future milestones without premature mechanics.
- Only small asteroids appear; 1 damage per contact tick (0.5s).
- Player starts at 12 HP. A provisional 2-second stationary regen delay is exposed as `regen_wait` and must be confirmed by the lead.
- Side-scrolling, boss, shield, EM jammer and progression system **are not included yet**.
- Stars move to suggest forward motion while the gameplay camera doesn't follow the player.
- The player moves toward the mouse pointer at finite speed; this is a **proposed movement interpretation** and can be adjusted.

## Project files

```
AGENTS.md
docs/
  SPECIFICATIONS.md
  DECISIONS_AND_TBD.md
  INTEGRATION_READINESS.md
  ASSET_HANDOFF.md
  NARRATIVE_INTERFACE.md
  TEAM_ASSET_MANIFEST.md
  ASSET_REQUESTS_FOR_TEAM.md
assets_src/
  team_batch_01/               # Pristine, untouched original team art archive
assets/
  sprites/
    player/                    # Official player sprites (alive, dead)
    bosses/
      stage2_miniboss/         # Stage 2 mini-boss assets (reserved)
      stage3_boss/             # Stage 3 multi-part boss assets (reserved)
  ui/
    buttons/                   # Main menu & Stage 1-3 level select buttons
    labels/                    # Overheat UI label (reserved)
scenes/
  main.tscn
  player.tscn
  asteroid.tscn
  satellite.tscn
  wrecked_ship.tscn
  ui/
    main_menu.tscn
    level_select.tscn
scripts/
  main.gd
  player.gd
  asteroid.gd
  asteroid_visual.gd
  satellite.gd
  wrecked_ship.gd
  ui/
    main_menu.gd
    level_select.gd
tests/
  test_milestone1.gd
  test_runner_logic.gd
  test_milestone2.gd
  test_runner_milestone2.gd
  test_milestone3.gd
  test_runner_milestone3.gd
  test_milestone3_5.gd
  test_runner_milestone3_5.gd
  test_milestone3_6.gd
  test_runner_milestone3_6.gd
project.godot
README.md
.gitignore
```

## Running Automated Tests

Run the headless automated test suites via the local Godot 4.7.2 executable:

```bash
# Milestone 1 verification suite (87 tests)
godot --headless -s tests/test_milestone1.gd

# Milestone 2 verification suite (73 tests)
godot --headless -s tests/test_milestone2.gd

# Milestone 3 verification suite (81 tests)
godot --headless -s tests/test_milestone3.gd

# Milestone 3.5 verification suite (56 tests)
godot --headless -s tests/test_milestone3_5.gd

# Milestone 3.6 verification suite (138 tests)
godot --headless -s tests/test_milestone3_6.gd
```
Total baseline: **435 passing tests** across 5 test suites (0 failures).

## Git collaboration

- The shared repository is owned by Zhafif. Coordinate **where** the team Godot project will live before committing.
- If Zhafif has already created a repo, clone that repo and integrate this starter in a feature branch; **do not nest a new `.git` directory**.
- For new shared projects, commit `project.godot`, scenes, scripts, assets, and README; **do not commit `.godot/`**.
- Suggested branch: `feature/stage1-core`.

## Stage 1 Progression (30s Arcade Survival)

1. **Stage 1 Level 1:** Asteroid survival, no weapon (Completed in Milestone 1).
2. **Stage 1 Level 2:** Asteroid survival, no weapon, optional communication satellite extraction (Completed in Milestone 2).
3. **Stage 1 Level 3:** Asteroid survival, no weapon; acquire primary weapon and shield after completing this level (Completed in Milestone 3).
4. **Stage 1 Level 4:** Asteroid survival with weapon and shield.
5. **Stage 1 Level 5:** Asteroid survival with weapon and shield; encounter damaged mining vessel NPC and receive Stage 2 coordinates.
