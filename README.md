# LAST SIGNAL - Godot Prototype (Milestone 5 — Final Asteroid Sector & Mining Ship SOS)

> **Development Status:** WIP — Milestone 5 implemented, manual GUI QA pending.  
> A verified 2D space SHMUP prototype in Godot 4.7.2 completing the entirety of Stage 1 (Levels 1–5), featuring twin-barrel primary weapon firing, asteroid combat and multi-hit destruction, optional communication and mining satellite extraction, equipment acquisition, damaged mining vessel distress SOS transmission, official team art integration (Batch 01 & Batch 02), modular menu UI, and comprehensive automated regression tests (815/815 passing tests).

## Setup

1. Download **Godot 4.7.2 stable — Standard** from https://godotengine.org/download/ (not .NET).
2. Extract the starter ZIP to a local folder.
3. In Godot Project Manager, click **Import**, locate this folder's `project.godot`, and open it.
4. Press **F6** from `scenes/main.tscn` (direct gameplay) or `scenes/ui/main_menu.tscn` (menu flow), or **F5** to start.
5. Move the mouse to steer the ship. Stay alive for 30 seconds. Press **R** to restart, **Esc** to quit.

## Current Prototype Implementation Status (Milestone 5 — Stage 1 Complete)

- **Stage 1 Levels 1–5:** Full Stage 1 gameplay completed across five 30-second survival and combat sectors with persistent HP, stage checkpoint revival, and progressive challenges:
  - **Level 1:** Unarmed navigation & evasion through small asteroids.
  - **Level 2:** Mixed asteroid belt with optional communication satellite telemetry recovery (`sat_telemetry_01`).
  - **Level 3:** Deep asteroid belt with large hazard rocks; post-survival recovery of twin-barrel pulse cannon and deflector shield from derelict scout craft (`Surveyor-7`).
  - **Level 4:** Twin-barrel combat deployment (12 shots/s, 1 dmg) against multi-hit destructible asteroids.
  - **Level 5:** Final high-density asteroid sector with twin-barrel combat, optional mining survey satellite extraction (`mining_sat_telemetry_01`), and dramatic encounter with a drifting damaged mining vessel broadcasting an automated SOS pointing toward Stage 2.
- **Twin-Barrel Primary Weapon (Levels 4 & 5):**
  - Left Mouse Button continuous firing at 6 volleys/s (12 projectiles/s total), dealing 1 damage per hit.
  - Dual muzzle lateral separation (±12 px lateral, +24 px forward) generating parallel forward trajectories aligned with player facing rotation.
  - Inoperable during Levels 1–3; activated strictly upon entering combat levels with acquired equipment.
- **Optional Proximity Satellites:**
  - **Communication Satellite (Level 2):** Proximity radius 80 px, drift speed 100 px/s, 1.5s extraction time, official `commsatt.png` art with dual overlay indicator rings.
  - **Mining Survey Satellite (Level 5):** Proximity radius 80 px, drift speed 95 px/s, 1.8s extraction time, procedural industrial aesthetic with orange-amber solar panels and survey dish.
  - Satellites are strictly optional bonus telemetry; missing them does not fail the run.
- **Damaged Mining Vessel & Stage 1 Ending:**
  - Surviving 30 seconds in Level 5 concludes Stage 1.
  - Instantiates damaged mining vessel at $(640, 210)$ with heavy industrial silhouette, cargo pods, hull breach electrical sparks, and pulsing amber distress beacon.
  - Disables weapon firing and emits `distress_sos_received` and `stage_completed` signals for future narrative integration.
  - No fake Stage 2 scenes or transitions; prototype cleanly finishes Stage 1.
- **Official Team Art (Batch 01 & Batch 02):**
  - **Player Ship:** `player_alive.png` and `player_dead.png` integrated into `player.tscn` with dynamic state switching.
  - **Communication Satellite:** Official `commsatt.png` integrated into `satellite.tscn` with procedural fallback.
  - **Modular UI:** Main Menu and Level Select UI integrated using official team button textures with progression gating.
  - **Staged & Reserved Assets:** Guard enemies, mini-boss, boss, and overheat label cataloged and reserved for future stages.
- **Stage Checkpoint Revive:** Death in any level (Levels 1–5) returns strictly to Stage 1 Level 1 with 12 HP, resetting stage acquisitions, equipment, and disabling weapons.

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
  mining_satellite.tscn
  wrecked_ship.tscn
  damaged_mining_ship.tscn
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
  mining_satellite.gd
  mining_satellite_visual.gd
  wrecked_ship.gd
  damaged_mining_ship.gd
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
  test_milestone5.gd
  test_runner_milestone5.gd
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

# Milestone 5 verification suite (137 tests)
godot --headless -s tests/test_milestone5.gd
```
Total baseline: **815 passing tests** across 8 test suites (0 failures).

## Git collaboration

- The shared repository is located at `https://github.com/asmaasyaa/last-signal`.
- Active development branch for Milestone 5: `feature/stage1-level5`.
- Stacked from: `feature/stage1-level4` (checkpoint commit `6af4363`).

## Stage 1 Progression (30s Arcade Survival & Combat)

1. **Stage 1 Level 1:** Asteroid survival, no weapon (Completed in Milestone 1).
2. **Stage 1 Level 2:** Asteroid survival, no weapon, optional communication satellite extraction (Completed in Milestone 2).
3. **Stage 1 Level 3:** Asteroid survival, no weapon; acquire primary weapon and shield after completing this level (Completed in Milestone 3).
4. **Stage 1 Level 4:** Twin-barrel shooting combat deployment against destructible asteroids (Completed in Milestone 4).
5. **Stage 1 Level 5:** Final asteroid sector combat, optional mining survey satellite telemetry recovery, and damaged mining vessel distress SOS encounter concluding Stage 1 (Completed in Milestone 5).
4. **Stage 1 Level 4:** Asteroid combat with twin-barrel shooting and multi-hit destructible asteroids (Completed in Milestone 4).
5. **Stage 1 Level 5:** Asteroid survival with weapon and shield; encounter damaged mining vessel NPC and receive Stage 2 coordinates.
