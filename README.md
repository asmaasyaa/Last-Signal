# LAST SIGNAL - Godot Prototype (Milestone 8 — Stage 2 Level 3: Kamikaze Guard Drone & EM Jammer Acquisition)

> **Development Status:** WIP — Milestone 8 implemented, manual GUI QA pending.  
> A verified 2D space SHMUP prototype in Godot 4.7.2 featuring Stage 1 (Levels 1–5) and Stage 2 (Levels 1–3), introducing horizontal side-scrolling gameplay, Guard Bot security automata, Guard Satellite defense units with telegraph-based accurate lasers, Guard Drone kamikaze interceptors with strict kill credit attribution, untimed 5-kill elimination objective, EM Jammer equipment acquisition, independent Stage 2 checkpoint revival, and comprehensive automated regression tests (1,282 / 1,282 passing assertions across 11 test suites).

## Setup

1. Download **Godot 4.7.2 stable — Standard** from https://godotengine.org/download/ (not .NET).
2. Extract the starter ZIP to a local folder.
3. In Godot Project Manager, click **Import**, locate this folder's `project.godot`, and open it.
4. Press **F6** from `scenes/main.tscn` (Stage 1 direct gameplay), `scenes/stage2/stage2_main.tscn` (Stage 2 direct gameplay), or `scenes/ui/main_menu.tscn` (menu flow), or **F5** to start.
5. Move the mouse to steer the ship. In Stage 1, evade/destroy asteroids for 30 seconds. In Stage 2 Level 1, survive the hostile sector for 15 seconds against Guard Bots. In Stage 2 Level 2, survive for 20 seconds against Guard Satellites and accurate laser beams. In Stage 2 Level 3, eliminate 5 Guard Drone interceptors with twin-barrel cannons to recover the EM Jammer. Press **R** to restart/revive, **Esc** to quit.

## Current Prototype Implementation Status (Milestone 8 — Stage 2 Level 3)

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
  - 20-second survival objective against Guard Satellite defense units (20 HP, 90 px/s drift).
  - Accurate telegraph-based laser attack (0.5s warning line, 0.15s high-energy beam, single-damage guarantee, dodgeable).
  - M7 Laser Alignment Audited: Laser is a direct child of Guard Satellite sharing the exact same origin and locked rotation vector, guaranteeing visual and physics correspondence during drift.
- **Stage 2 Level 3 (Kamikaze Guard Drone & EM Jammer Acquisition):**
  - **Level Progression & HP Persistence:** Advancing from Level 2 to Level 3 via [Space/Enter] strictly preserves remaining player HP without within-stage restoration. Primary weapon and shield persist. Old entities, lasers, and projectiles are cleared.
  - **Untimed 5-Kill Elimination Objective:** Level 3 features an elimination objective without a timer countdown. HUD displays `STAGE 2 / LEVEL 3     HP %02d / %02d     DRONES DESTROYED: %d / %d`. Spawning continues until exactly 5 drones are destroyed by the player.
  - **Guard Drone Security Automaton (`scenes/enemies/guard_drone.tscn`):**
    - Multi-hit interceptor drone with $20\text{ HP}$ (`max_health = 20`), taking 1 damage per player projectile hit.
    - Collision Layer 18 (Layer 2 `[2]` Combat Target | Layer 5 `[16]` Enemies), Mask 5 (Layer 1 `[1]` Player | Layer 3 `[4]` Player Projectiles).
    - Integrated official `guard_drone_idle.png` ($152 \times 316$) and `guard_drone_attacking.png` ($151 \times 316$) scaled $0.35\times$, rotated $-90^\circ$, with sleek arrowhead procedural fallback. Neutral root scale `Vector2.ONE`.
    - **FSM States:** `APPROACH` (120 px/s horizontal entry), `TELEGRAPH` (0.45s aim-lock on player position with warning corona), and `CHARGING` (360 px/s dash along locked line).
    - **Dodgeable:** Charge vector does NOT track player movement once locked; player can evade vertically.
  - **Strict Kill Credit Attribution:**
    - Only destruction via player weapon damage (`DestructionReason.PLAYER_WEAPON`) increments the drone kill counter.
    - Kamikaze impact with player deals 1 damage to player and self-destructs (`DestructionReason.KAMIKAZE_IMPACT`), awarding **ZERO** kill credit.
    - Flying off-screen left ($X < -120$) calls `DestructionReason.OFFSCREEN_DESPAWN`, awarding **ZERO** kill credit.
  - **Equipment Acquisition (EM Jammer):**
    - Completing Level 3 (5th kill) sets `stage_acquisitions["em_jammer_acquired"] = true`, emits `em_jammer_acquired_event({"equipment": "em_jammer", "level": 3, "status": "acquired"})`, and displays victory banner.
    - Activation is deferred: EM Jammer specifications (120° cone, 10s stun, 30s cooldown) are documented for Level 4+ integration.
  - **Stage 2 Checkpoint Revive:** Death in Level 3 revives the player strictly at **Stage 2 Level 1** at full $12\text{ HP}$ with active weapons. Unearned EM Jammer is cleared. Does NOT reset to Stage 1.
  - **Milestone Scope Boundary:** Completing Level 3 finishes the current prototype. Stage 2 Level 4 cannot be started.

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
      guard_drone/             # Guard Drone sprites (idle, attacking)
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
    guard_drone.tscn           # Guard Drone kamikaze interceptor
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
    guard_drone.gd
    guard_drone_visual.gd
    enemy_projectile.gd
    enemy_projectile_visual.gd
  stage2/
    stage2_main.gd
  ui/
    main_menu.gd
    level_select.gd
tests/
  test_milestone1.gd           # 87 assertions PASS
  test_milestone2.gd           # 73 assertions PASS
  test_milestone3.gd           # 81 assertions PASS
  test_milestone3_5.gd         # 56 assertions PASS
  test_milestone3_6.gd         # 138 assertions PASS
  test_milestone3_7.gd         # 119 assertions PASS
  test_milestone4.gd           # 124 assertions PASS
  test_milestone5.gd           # 140 assertions PASS
  test_milestone6.gd           # 145 assertions PASS
  test_milestone7.gd           # 153 assertions PASS
  test_milestone8.gd           # 166 assertions PASS
  (Total: 1,282 assertions, 100% PASS across 11 test suites)
```

## Architecture & Style Rules

- **Call Down, Signal Up:** Main/Stage 2 coordinator commands child nodes (`player.set_physics_process(false)`, `weapon_controller.set_firing_enabled(true)`). Children emit signals (`player.health_changed`, `player.died`, `drone.drone_defeated`, `sat.laser_fired`). No upward node hierarchy lookups.
- **Node Isolation & Encapsulation:** All scenes are runnable and testable in isolation. No brittle paths (`/root/...`).
- **Physics in `_physics_process`:** All Area2D movement, projectile updates, and collision checks happen in `_physics_process(delta)`.
- **Provisional Values as `@export`:** Tunable gameplay parameters are exposed with clear comments and sensible defaults.
