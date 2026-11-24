# LAST SIGNAL - Godot Prototype (Milestone 6 — Stage 2 Level 1: Side-Scrolling & First Hostile Contact)

> **Development Status:** WIP — Milestone 6 implemented, manual GUI QA pending.  
> A verified 2D space SHMUP prototype in Godot 4.7.2 featuring Stage 1 (Levels 1–5) and Stage 2 Level 1, introducing horizontal side-scrolling gameplay, Guard Bot security automata with official artwork and procedural fallback, aimed enemy projectiles, 15-second survival objective, full HP restoration upon entering Stage 2, independent Stage 2 checkpoint revival, and comprehensive automated regression tests (963/963 passing assertions across 9 test suites).

## Setup

1. Download **Godot 4.7.2 stable — Standard** from https://godotengine.org/download/ (not .NET).
2. Extract the starter ZIP to a local folder.
3. In Godot Project Manager, click **Import**, locate this folder's `project.godot`, and open it.
4. Press **F6** from `scenes/main.tscn` (Stage 1 direct gameplay), `scenes/stage2/stage2_main.tscn` (Stage 2 direct gameplay), or `scenes/ui/main_menu.tscn` (menu flow), or **F5** to start.
5. Move the mouse to steer the ship. In Stage 1, evade/destroy asteroids for 30 seconds. In Stage 2 Level 1, survive the hostile sector for 15 seconds against Guard Bots. Press **R** to restart/revive, **Esc** to quit.

## Current Prototype Implementation Status (Milestone 6 — Stage 2 Level 1)

- **Stage 1 (Levels 1–5 Complete):**
  - **Level 1:** Unarmed navigation & evasion through small asteroids.
  - **Level 2:** Mixed asteroid belt with optional communication satellite telemetry recovery (`sat_telemetry_01`).
  - **Level 3:** Deep asteroid belt with large hazard rocks; post-survival recovery of twin-barrel pulse cannon and deflector shield from derelict scout craft (`Surveyor-7`).
  - **Level 4:** Twin-barrel combat deployment (12 shots/s, 1 dmg) against multi-hit destructible asteroids.
  - **Level 5:** Final high-density asteroid sector with twin-barrel combat, optional mining survey satellite extraction (`mining_sat_telemetry_01`), and encounter with a drifting damaged mining vessel broadcasting an automated SOS pointing toward Stage 2.
- **Stage 2 Level 1 (Side-Scrolling & First Hostile Contact):**
  - **Horizontal Side-Scrolling:** Arena shifts from vertical dodging to horizontal scrolling. Deep space starfield moves right-to-left at $140.0\text{ px/s}$ (`scroll_speed`).
  - **15-Second Survival Objective:** Sector incursion duration is strictly 15.0 seconds (`level_duration = 15.0`). Surviving 15 seconds completes the level without requiring all enemies to be destroyed.
  - **Stage Transition & Restoration:** Advancing from Stage 1 Level 5 restores player HP to full $12\text{ HP}$ ($12/12$), retains acquired twin-barrel weapon and shield hardware, and enables weapons immediately.
  - **Guard Bot Security Automaton (`scenes/enemies/guard_bot.tscn`):**
    - Multi-hit combat target with $30\text{ HP}$ (`max_health = 30`), taking 1 damage per player projectile.
    - Drifts horizontally leftward at $130.0\text{ px/s}$.
    - Collision Layer 18 (Layer 2 `[2]` Combat Target | Layer 5 `[16]` Enemies), Mask 5 (Layer 1 `[1]` Player | Layer 3 `[4]` Player Projectiles).
    - Integrated official `idle.png` and `attacking.png` sprites ($256 \times 256$) scaled $0.45\times$, rotated $-90^\circ$ to face leftward, with geometric procedural fallback.
    - Mutual contact damage: Deals 1 damage to player and takes 1 damage in return, rate-limited by $0.5\text{s}$ independent contact pair cooldowns.
    - Aimed weapon attack: Periodically fires normal enemy projectiles towards the player every $1.8\text{s} - 2.4\text{s}$, triggering an attacking sprite pose for $0.35\text{s}$.
  - **Enemy Projectiles (`scenes/enemies/enemy_projectile.tscn`):**
    - Collision Layer 32 (Layer 6: Enemy Projectiles), Mask 1 (Layer 1: Player).
    - Linear velocity $300.0\text{ px/s}$, dealing 1 HP damage per hit to player.
    - Friendly fire immunity: Ignores Guard Bots and friendly units.
    - Double-hit protection and safe despawn on playfield boundary margins ($X < -60$, $X > 1340$, $Y < -60$, $Y > 780$) or lifetime ($4.0\text{s}$).
  - **Stage 2 Checkpoint Revive:** Death in Stage 2 Level 1 revives player strictly at **Stage 2 Level 1** at full $12\text{ HP}$ with weapons active. Does NOT send player back to Stage 1.
  - **Milestone Scope Boundary:** Surviving 15 seconds completes Stage 2 Level 1. Stage 2 Level 2 cannot be started.

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
    enemies/                   # Stage 2 guard assets (bot, satellite, drone)
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
project.godot
README.md
.gitignore
```

## Running Automated Tests

Run the headless automated test suites via the local Godot 4.7.2 executable:

```bash
# Milestone 1 verification suite (38 assertions)
godot --headless -s tests/test_milestone1.gd

# Milestone 2 verification suite (55 assertions)
godot --headless -s tests/test_milestone2.gd

# Milestone 3 verification suite (73 assertions)
godot --headless -s tests/test_milestone3.gd

# Milestone 3.5 verification suite (126 assertions)
godot --headless -s tests/test_milestone3_5.gd

# Milestone 3.6 verification suite (143 assertions)
godot --headless -s tests/test_milestone3_6.gd

# Milestone 3.7 verification suite (119 assertions)
godot --headless -s tests/test_milestone3_7.gd

# Milestone 4 verification suite (124 assertions)
godot --headless -s tests/test_milestone4.gd

# Milestone 5 verification suite (140 assertions)
godot --headless -s tests/test_milestone5.gd

# Milestone 6 verification suite (145 assertions)
godot --headless -s tests/test_milestone6.gd
```
Total baseline: **963 passing assertions** across 9 test suites (0 failures).

## Git Collaboration

- Shared repository: `https://github.com/asmaasyaa/last-signal`.
- Active development branch for Milestone 6: `feature/stage2-level1`.
- Stacked from: `feature/stage1-level5` (checkpoint commit `5226f03`).

## Milestone Roadmap & Progression

1. **Stage 1 Level 1:** Unarmed asteroid survival (Milestone 1).
2. **Stage 1 Level 2:** Asteroid evasion, optional communication satellite extraction (Milestone 2).
3. **Stage 1 Level 3:** Deep belt survival; acquire twin-barrel weapon and deflector shield (Milestone 3).
4. **Stage 1 Level 4:** Twin-barrel shooting combat deployment against destructible asteroids (Milestone 4).
5. **Stage 1 Level 5:** Final asteroid sector combat, mining satellite extraction, damaged mining ship SOS (Milestone 5).
6. **Stage 2 Level 1:** Side-scrolling shift, Guard Bot hostile automata, aimed enemy projectiles, 15s survival (Milestone 6).
