# LAST SIGNAL - Godot Prototype (Milestone 7 — Stage 2 Level 2: Guard Satellite & Accurate Laser Combat)

> **Development Status:** WIP — Milestone 7 implemented, manual GUI QA pending.  
> A verified 2D space SHMUP prototype in Godot 4.7.2 featuring Stage 1 (Levels 1–5) and Stage 2 (Levels 1–2), introducing horizontal side-scrolling gameplay, Guard Bot security automata, Guard Satellite defense units with telegraph-based accurate laser attacks, Level 1 -> Level 2 progression with HP persistence, independent Stage 2 checkpoint revival, and comprehensive automated regression tests (1,116 / 1,116 passing assertions across 10 test suites).

## Setup

1. Download **Godot 4.7.2 stable — Standard** from https://godotengine.org/download/ (not .NET).
2. Extract the starter ZIP to a local folder.
3. In Godot Project Manager, click **Import**, locate this folder's `project.godot`, and open it.
4. Press **F6** from `scenes/main.tscn` (Stage 1 direct gameplay), `scenes/stage2/stage2_main.tscn` (Stage 2 direct gameplay), or `scenes/ui/main_menu.tscn` (menu flow), or **F5** to start.
5. Move the mouse to steer the ship. In Stage 1, evade/destroy asteroids for 30 seconds. In Stage 2 Level 1, survive the hostile sector for 15 seconds against Guard Bots. In Stage 2 Level 2, survive for 20 seconds against Guard Satellites and accurate laser beams. Press **R** to restart/revive, **Esc** to quit.

## Current Prototype Implementation Status (Milestone 7 — Stage 2 Level 2)

- **Stage 1 (Levels 1–5 Complete):**
  - **Level 1:** Unarmed navigation & evasion through small asteroids.
  - **Level 2:** Mixed asteroid belt with optional communication satellite telemetry recovery (`sat_telemetry_01`).
  - **Level 3:** Deep asteroid belt with large hazard rocks; post-survival recovery of twin-barrel pulse cannon and deflector shield from derelict scout craft (`Surveyor-7`).
  - **Level 4:** Twin-barrel combat deployment (12 shots/s, 1 dmg) against multi-hit destructible asteroids.
  - **Level 5:** Final high-density asteroid sector with twin-barrel combat, optional mining survey satellite extraction (`mining_sat_telemetry_01`), and encounter with a drifting damaged mining vessel broadcasting an automated SOS pointing toward Stage 2.
- **Stage 2 Level 1 (Side-Scrolling & Guard Bots):**
  - Horizontal side-scrolling starfield moving right-to-left at $140.0\text{ px/s}$ (`scroll_speed`).
  - 15-second survival objective against Guard Bot security automata (30 HP, 130 px/s drift, aimed projectiles).
  - Surviving 15 seconds displays completion banner prompting [Space/Enter] for Level 2.
- **Stage 2 Level 2 (Guard Satellite & Accurate Laser Combat):**
  - **Level Progression & HP Persistence:** Advancing from Level 1 strictly preserves remaining player HP (no within-stage restoration). Primary weapon and shield acquisitions persist. Old entities and cooldowns are cleaned up.
  - **20-Second Survival Objective:** Sector defense grid duration is strictly 20.0 seconds (`level_duration = 20.0`). Surviving 20 seconds completes Level 2 without requiring all satellites to be destroyed.
  - **Guard Satellite Security Automaton (`scenes/enemies/guard_satellite.tscn`):**
    - Multi-hit combat target with $20\text{ HP}$ (`max_health = 20`), taking 1 damage per player projectile hit.
    - Drifts horizontally leftward at $90.0\text{ px/s}$.
    - Collision Layer 18 (Layer 2 `[2]` Combat Target | Layer 5 `[16]` Enemies), Mask 5 (Layer 1 `[1]` Player | Layer 3 `[4]` Player Projectiles).
    - Integrated official `guard_satellite_idle.png` and `guard_satellite_attacking.png` sprites ($347 \times 267$) scaled $0.35\times$, rotated $-90^\circ$, with procedural armored satellite fallback.
    - Mutual contact damage: Deals 1 damage to player and takes 1 damage in return, rate-limited by $0.5\text{s}$ independent contact pair cooldowns.
  - **Accurate Laser System (`scripts/enemies/guard_satellite_laser_visual.gd`):**
    - **Telegraph Phase (0.5s):** Locks firing orientation toward player's current position (`locked_aim_direction`) and displays a thin red warning aiming line. Does not track player movement after locking. Laser `monitoring = false` (deals 0 damage during warning).
    - **Firing Phase (0.15s):** Fires a high-energy laser beam along the locked direction, switching to the official `attacking.png` sprite pose. Deals exactly 1 HP damage if the player is inside the beam.
    - **Single Damage Guarantee:** `has_dealt_damage` flag ensures damage occurs at most once per laser attack event, eliminating per-frame damage loops.
    - **Dodge Mechanics:** Player can observe the warning line and move out of the beam path before the laser fires to avoid damage completely.
    - **Friendly Fire & Self-Damage Immunity:** Mask 1 ensures laser only damages the player; firing satellite and friendly Guard Bots/Satellites are completely immune.
    - **Destruction Safety:** Destroying the satellite immediately terminates the laser attack (`stop_attack()`) and disables collision.
  - **Stage 2 Checkpoint Revive:** Death in Stage 2 (Level 1 or Level 2) revives the player strictly at **Stage 2 Level 1** at full $12\text{ HP}$ with active weapons. Does NOT reset the player to Stage 1.
  - **Milestone Scope Boundary:** Surviving 20 seconds completes Stage 2 Level 2. Stage 2 Level 3 cannot be started.

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
    enemies/
      guard_bot/               # Guard Bot sprites (idle, attacking)
      guard_satellite/         # Guard Satellite sprites (idle, attacking)
      guard_drone/             # Guard Drone sprites (idle, attacking - reserved)
    npc/                       # Nirawak 1 assets (awaiting confirmation)
    bosses/
      stage2_miniboss/         # Stage 2 mini-boss assets (reserved)
      stage3_boss/             # Stage 3 multi-part boss assets (reserved)
  ui/
    buttons/                   # Main menu & Stage 1-3 level select buttons
    labels/                    # Overheat UI label (reserved)
scenes/
  main.tscn                    # Stage 1 Coordinator
  player.tscn
  asteroid.tscn
  projectile.tscn
  satellite.tscn
  mining_satellite.tscn
  wrecked_ship.tscn
  damaged_mining_ship.tscn
  enemies/
    guard_bot.tscn             # Guard Bot enemy automaton
    guard_satellite.tscn       # Guard Satellite enemy automaton & laser
    enemy_projectile.tscn      # Enemy normal projectile
  stage2/
    stage2_main.tscn           # Stage 2 Main Coordinator
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
  enemies/
    guard_bot.gd
    guard_bot_visual.gd
    guard_satellite.gd
    guard_satellite_visual.gd
    guard_satellite_laser_visual.gd
    enemy_projectile.gd
    enemy_projectile_visual.gd
  stage2/
    stage2_main.gd
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
  test_milestone6.gd
  test_runner_milestone6.gd
  test_milestone7.gd
  test_runner_milestone7.gd
project.godot
README.md
.gitignore
```

## Running Automated Tests

Run the headless automated test suites via the local Godot 4.7.2 executable:

```bash
# Milestone 1 verification suite (87 assertions)
godot --headless -s tests/test_milestone1.gd

# Milestone 2 verification suite (73 assertions)
godot --headless -s tests/test_milestone2.gd

# Milestone 3 verification suite (81 assertions)
godot --headless -s tests/test_milestone3.gd

# Milestone 3.5 verification suite (56 assertions)
godot --headless -s tests/test_milestone3_5.gd

# Milestone 3.6 verification suite (138 assertions)
godot --headless -s tests/test_milestone3_6.gd

# Milestone 3.7 verification suite (119 assertions)
godot --headless -s tests/test_milestone3_7.gd

# Milestone 4 verification suite (124 assertions)
godot --headless -s tests/test_milestone4.gd

# Milestone 5 verification suite (140 assertions)
godot --headless -s tests/test_milestone5.gd

# Milestone 6 verification suite (145 assertions)
godot --headless -s tests/test_milestone6.gd

# Milestone 7 verification suite (153 assertions)
godot --headless -s tests/test_milestone7.gd
```
Total baseline: **1,116 passing assertions** across 10 test suites (0 failures).

## Git Collaboration

- Shared repository: `https://github.com/asmaasyaa/last-signal`.
- Active development branch for Milestone 7: `feature/stage2-level2`.
- Stacked from: `feature/stage2-level1` (checkpoint commit `5cdda25`).

## Milestone Roadmap & Progression

1. **Stage 1 Level 1:** Unarmed asteroid survival (Milestone 1).
2. **Stage 1 Level 2:** Asteroid evasion, optional communication satellite extraction (Milestone 2).
3. **Stage 1 Level 3:** Deep belt survival; acquire twin-barrel weapon and deflector shield (Milestone 3).
4. **Stage 1 Level 4:** Twin-barrel shooting combat deployment against destructible asteroids (Milestone 4).
5. **Stage 1 Level 5:** Final asteroid sector combat, mining satellite extraction, damaged mining ship SOS (Milestone 5).
6. **Stage 2 Level 1:** Side-scrolling shift, Guard Bot hostile automata, aimed enemy projectiles, 15s survival (Milestone 6).
7. **Stage 2 Level 2:** Guard Satellite defense grid, telegraph-based accurate laser attacks, HP persistence, 20s survival (Milestone 7).
