# LAST SIGNAL - Godot Prototype (Milestone 9 — Stage 2 Level 4: Guard Cruiser Mini-Boss Phase 1 & EM Jammer Activation)

> **Development Status:** WIP — Milestone 9 implemented, manual GUI QA pending.
> A verified 2D space SHMUP prototype in Godot 4.7.2 featuring Stage 1 (Levels 1–5) and Stage 2 (Levels 1–4), introducing horizontal side-scrolling gameplay, Guard Bot security automata, Guard Satellite defense units with telegraph-based accurate lasers, Guard Drone kamikaze interceptors, EM Jammer active equipment (120° directional cone stun), full arcade mini-boss arena, Guard Cruiser mini-boss Phase 1 combat (400 to 200 HP threshold), official mini-boss Phase 1 artwork integration, independent Stage 2 checkpoint revival, and comprehensive automated regression tests (1,451 / 1,451 passing assertions across 12 test suites).

## Setup

1. Download **Godot 4.7.2 stable — Standard** from https://godotengine.org/download/ (not .NET).
2. Extract the starter ZIP to a local folder.
3. In Godot Project Manager, click **Import**, locate this folder's `project.godot`, and open it.
4. Press **F6** from `scenes/main.tscn` (Stage 1 direct gameplay), `scenes/stage2/stage2_main.tscn` (Stage 2 side-scrolling), `scenes/stage2/boss_arena.tscn` (Stage 2 Level 4 Boss Arena), or `scenes/ui/main_menu.tscn` (menu flow), or **F5** to start.
5. Move the mouse to steer the ship. In Stage 1, evade/destroy asteroids for 30 seconds. In Stage 2 Level 1, survive the hostile sector for 15 seconds against Guard Bots. In Stage 2 Level 2, survive for 20 seconds against Guard Satellites and accurate laser beams. In Stage 2 Level 3, eliminate 5 Guard Drone interceptors to recover the EM Jammer. In Stage 2 Level 4, face the Guard Cruiser mini-boss in the arcade arena: fire blasters with Left Mouse Button, trigger the EM Jammer with **E** to stun the cruiser for 10 seconds, and reduce its HP from 400 to 200 to complete Phase 1. Press **R** to restart/revive, **Esc** to quit.

## Current Prototype Implementation Status (Milestone 9 — Stage 2 Level 4)

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
  - **Milestone Scope Boundary:** Completing Level 3 prompts [Space/Enter] for Level 4.
- **Stage 2 Level 4 (Guard Cruiser Mini-Boss Phase 1 & EM Jammer Activation):**
  - **Level Progression & State Persistence:** Pressing [Space/Enter] after completing Level 3 transitions from side-scrolling to the arcade boss arena. Remaining player HP strictly persists (no within-stage restoration). Primary weapon, shield, and EM Jammer equipment persist. Old side-scrolling entities and projectiles are cleanly removed.
  - **Boss Arena Architecture (`scenes/stage2/boss_arena.tscn` / `scripts/stage2/boss_arena.gd`):** Full $1280 \times 720\text{ px}$ arcade arena with starry drift background, HUD displaying player HP, boss HP bar (`GUARD CRUISER: 400 / 400 HP`), and real-time EM Jammer status (`EM JAMMER: READY [E]` or cooldown timer).
  - **EM Jammer Active Equipment (`scripts/equipment/em_jammer_controller.gd`):**
    - Input action `em_jammer` (mapped to key `E`) triggers a directional $120^\circ$ cone stun ($\pm 60^\circ$ from player facing heading).
    - Configurable range ($600.0\text{ px}$), 10.0-second non-damaging stun, and 30.0-second cooldown timer.
    - Emits expanding cyan wave VFX (`_draw`) and guarantees zero damage to enemies.
    - Dead player or finished arena cannot trigger the jammer.
  - **Guard Cruiser Mini-Boss (`scenes/bosses/guard_cruiser.tscn` / `scripts/bosses/guard_cruiser.gd`):**
    - Heavy capital warship entity with $400\text{ HP}$ total health.
    - Collision Layer 18 (Layer 2 `[2]` Combat Target | Layer 5 `[16]` Enemies), Mask 5 (Layer 1 `[1]` Player | Layer 3 `[4]` Player Projectiles).
    - Neutral root scale `Vector2.ONE`, `RectangleShape2D(230, 110)` central hull hitbox.
    - Integrated official `assets/sprites/bosses/stage2_miniboss/miniboss_alive_p1.png` ($601 \times 321\text{ px}$) scaled $0.4\times$, rotated $\pi$ to face South toward player. Phase 2 and Dead sprites are strictly reserved and hidden.
    - Procedural battlecruiser fallback in `Visuals/ProceduralFallback` (`scripts/bosses/guard_cruiser_visual.gd`) with dual nacelles, glowing bridge, and electrical stun arc overlays.
    - **Combat Behavior:** Horizontal patrol sweeps ($85.0\text{ px/s}$), controlled 3-projectile aimed bursts ($300.0\text{ px/s}$, $1\text{ HP}$ damage per bolt, friendly fire immune to enemy projectiles, dodgeable).
    - **Stunned State:** Applying EM Jammer halts movement and attack windup, cancels ongoing attacks, maintains vulnerability to player blasters, and automatically resumes after 10.0 seconds.
  - **Phase 1 Threshold Clamping & Completion:**
    - Taking damage reduces HP from 400 down to 200.
    - Reaching exactly $200\text{ HP}$ triggers `phase_threshold_reached` and completes Phase 1 (`phase_1_completed = true`).
    - Boss is NOT destroyed or defeated (health is strictly clamped at 200 HP).
    - Victory banner proclaims:
      ```
      STAGE 2 / LEVEL 4 COMPLETE
      GUARD CRUISER — PHASE 1 DISABLED
      BOSS HP: 200 / 400
      [PHASE 2 — NEXT MILESTONE]
      Press [R] to replay Stage 2 from Checkpoint
      ```
  - **Stage 2 Checkpoint Revive:** Player death in Level 4 prompts [R] to revive at **Stage 2 Level 1** at full $12\text{ HP}$ with primary weapon and shield retained, while unearned EM Jammer is cleared. Does NOT reset to Stage 1.
  - **Milestone Scope Boundary:** Phase 2 combat and Stage 2 Level 5 are strictly deferred.

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
      stage2_miniboss/         # Stage 2 mini-boss assets (P1 integrated, P2/Dead reserved)
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
  bosses/
    guard_cruiser.tscn         # Guard Cruiser mini-boss entity (Phase 1)
  stage2/
    stage2_main.tscn           # Stage 2 Main Coordinator (Levels 1-3)
    boss_arena.tscn            # Stage 2 Boss Arena (Level 4)
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
  bosses/
    guard_cruiser.gd
    guard_cruiser_visual.gd
  equipment/
    em_jammer_controller.gd
  stage2/
    stage2_main.gd
    boss_arena.gd
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
  test_milestone9.gd           # 169 assertions PASS
  (Total: 1,451 assertions, 100% PASS across 12 test suites)
```

## Architecture & Style Rules

- **Call Down, Signal Up:** Main/Stage 2 coordinator commands child nodes (`player.set_physics_process(false)`, `weapon_controller.set_firing_enabled(true)`). Children emit signals (`player.health_changed`, `player.died`, `drone.drone_defeated`, `sat.laser_fired`). No upward node hierarchy lookups.
- **Node Isolation & Encapsulation:** All scenes are runnable and testable in isolation. No brittle paths (`/root/...`).
- **Physics in `_physics_process`:** All Area2D movement, projectile updates, and collision checks happen in `_physics_process(delta)`.
- **Provisional Values as `@export`:** Tunable gameplay parameters are exposed with clear comments and sensible defaults.
