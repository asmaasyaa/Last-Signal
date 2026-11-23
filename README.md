# LAST SIGNAL - Godot Prototype (Milestone 4 — Twin-Barrel Shooting & Asteroid Combat)

> **Development Status:** WIP — Milestone 4 implemented, manual GUI QA pending.  
> A verified 2D space SHMUP prototype in Godot 4.7.2 featuring Stage 1 Levels 1–4, twin-barrel primary weapon firing, projectile physics, asteroid health and destruction, official team art integration (Batch 01 & Batch 02), communication satellite visual integration, modular menu UI, and comprehensive automated regression tests (678/678 passing tests).

## Setup

1. Download **Godot 4.7.2 stable — Standard** from https://godotengine.org/download/ (not .NET).
2. Extract the starter ZIP to a local folder.
3. In Godot Project Manager, click **Import**, locate this folder's `project.godot`, and open it.
4. Press **F6** from `scenes/main.tscn` (direct gameplay) or `scenes/ui/main_menu.tscn` (menu flow), or **F5** to start.
5. Move the mouse to steer the ship. Stay alive for 30 seconds. Press **R** to restart, **Esc** to quit.

## Current Prototype Implementation Status (Milestone 4)

- **Stage 1 Levels 1–4:** Fully implemented 30-second arcade survival & combat gameplay with HP persistence across levels, stage checkpoint revive, optional satellite extraction in Level 2, weapon/shield recovery in Level 3, and twin-barrel asteroid shooting in Level 4.
- **Twin-Barrel Primary Weapon (Level 4):**
  - Left Mouse Button continuous firing at 6 volleys/s (12 projectiles/s total), dealing 1 damage per hit.
  - Dual muzzle lateral separation (±12 px lateral, +24 px forward) generating parallel forward trajectories aligned with player facing rotation.
  - Inoperable during Levels 1–3; activated strictly upon entering Level 4 with acquired equipment.
- **Projectile & Asteroid Combat Architecture:**
  - Dedicated projectile scene (`scenes/projectile.tscn`) on collision layer 4, masking layer 2 (asteroids).
  - Procedural glowing pulse bolt visual fallback with decoupled `Visuals` presentation layer.
  - Multi-hit asteroid health across size tiers: Small (20 HP, 1 contact dmg), Medium (40 HP, 2 contact dmg), Large (80 HP, 4 contact dmg).
  - Safe destruction upon reaching 0 HP with immediate contact damage negation and physics cleanup.
- **Official Team Art (Batch 01 & Batch 02):**
  - **Player Ship:** `player_alive.png` and `player_dead.png` integrated into `player.tscn` with dynamic state switching.
  - **Communication Satellite:** Official `commsatt.png` integrated into `satellite.tscn` under `Visuals/OfficialArt/Sprite2D` with dual progress indicator rings above the sprite and procedural fallback.
  - **Modular UI:** Main Menu and Level Select UI integrated using official team button textures with progression gating.
  - **Staged & Reserved Assets:** 6 Stage 2 guard enemy sprites, 3 Stage 2 mini-boss sprites, 11 Stage 3 boss sprites, and overheat label cataloged and reserved for future milestones.
- **Safe Fallback Architecture:** Procedural vector drawing serves as an automatic fallback whenever custom art is missing or disabled.
- **Stage Checkpoint Revive:** Death in any level returns strictly to Stage 1 Level 1 with 12 HP, resetting stage acquisitions and disabling weapons.

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
  team_batch_01/               # Pristine Batch 01 art archive (35 files)
  team_batch_02/               # Pristine Batch 02 art archive (44 files)
assets/
  sprites/
    player/                    # Official player sprites (alive, dead)
    interactables/             # Communication satellite (commsatt.png)
    enemies/                   # Stage 2 guard assets (bot, satellite, drone - reserved)
    npc/                       # Nirawak 1 assets (awaiting confirmation)
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
  projectile.tscn
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
  projectile.gd
  projectile_visual.gd
  weapon_controller.gd
  satellite.gd
  satellite_visual.gd
  satellite_indicator.gd
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
  test_milestone3_7.gd
  test_runner_milestone3_7.gd
  test_milestone4.gd
  test_runner_milestone4.gd
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

# Milestone 3.7 verification suite (119 tests)
godot --headless -s tests/test_milestone3_7.gd

# Milestone 4 verification suite (124 tests)
godot --headless -s tests/test_milestone4.gd
```
Total baseline: **678 passing tests** across 7 test suites (0 failures).

## Git collaboration

- The shared repository is owned by Zhafif. Coordinate **where** the team Godot project will live before committing.
- If Zhafif has already created a repo, clone that repo and integrate this starter in a feature branch; **do not nest a new `.git` directory**.
- For new shared projects, commit `project.godot`, scenes, scripts, assets, and README; **do not commit `.godot/`**.
- Active development branch for Milestone 4: `feature/stage1-level4`.

## Stage 1 Progression (30s Arcade Survival & Combat)

1. **Stage 1 Level 1:** Asteroid survival, no weapon (Completed in Milestone 1).
2. **Stage 1 Level 2:** Asteroid survival, no weapon, optional communication satellite extraction (Completed in Milestone 2).
3. **Stage 1 Level 3:** Asteroid survival, no weapon; acquire primary weapon and shield after completing this level (Completed in Milestone 3).
4. **Stage 1 Level 4:** Asteroid combat with twin-barrel shooting and multi-hit destructible asteroids (Completed in Milestone 4).
5. **Stage 1 Level 5:** Asteroid survival with weapon and shield; encounter damaged mining vessel NPC and receive Stage 2 coordinates.
