# LAST SIGNAL — Game Specifications

This document defines the confirmed gameplay rules, mechanics, and design specifications for **Stage 1 Level 1** of LAST SIGNAL.

---

## 1. Game Overview & Mode

- **Game Title:** LAST SIGNAL
- **Target Platform:** PC
- **Engine:** Godot Engine 4.7.2 Standard (GDScript)
- **Game Mode:** Full Arcade Mode (Stage 1).
  - Fixed 1280x720 screen boundaries.
  - No side-scrolling camera; background stars scroll vertically at a continuous rate (27 px/s) to suggest forward ship propulsion through space.
  - Top-down orientation with hazards entering from the top boundary.

---

## 2. Art Direction & Visual Aesthetics

- **Style:** Hand-drawn 2D space aesthetic.
- **Prototypes:** Procedural vector/polygon placeholders drawn using Godot's 2D canvas drawing system (`_draw`, `Polygon2D`, `Line2D`) with geometric silhouettes:
  - **Player Ship:** Sleek cyan arrowhead polygon (`Color(0.35, 0.8, 0.93)`) with warm amber engine plume (`Color(1.0, 0.67, 0.33)`).
  - **Asteroids:** Multi-vertex craggy rock polygons (`Color(0.39, 0.44, 0.53)`) with bright outlines (`Color(0.78, 0.84, 0.92)`) and internal crater detail lines.
  - **Space Background:** Deep cosmic blue/black (`Color(0.025, 0.035, 0.082)`) populated with randomized scrolling star particles.

---

## 3. Player Ship Controls & Facing

- **Control Scheme:** Direct mouse cursor following.
  - The player ship calculates the vector from its position to the global mouse position (`to_mouse`).
  - **Arrival Deadzone:** If the distance to the mouse cursor is within `arrive_distance` (default: `4.0 px`), the ship has arrived at the cursor and its velocity is set to `Vector2.ZERO`. This eliminates micro-twitching caused by sub-pixel optical mouse sensor jitter.
  - When distance exceeds `arrive_distance`, ship position advances along this vector up to `move_speed * delta` (default speed: `500.0 px/s`).
  - Position is clamped within the playable viewport margins (`[24.0, 1256.0]` on X and `[24.0, 696.0]` on Y) to prevent the ship from leaving the visible play area.
- **Facing Direction:**
  - When movement velocity exceeds `stop_threshold` (`8.0 px/s`), the ship's rotation continuously aligns with the movement direction vector (`rotation = Vector2.UP.angle_to(movement_velocity)`).
  - When the ship is stationary or moving below `stop_threshold`, the rotation is strictly preserved at its last facing direction.
- **Primary Weapon:**
  - The player has **no primary weapon** in Stage 1 Level 1 (pure evasion/survival gameplay).

---

## 4. Health, Damage & Contact Mechanics

- **Player HP:**
  - Starting HP: **12**.
  - Maximum HP: **12**.
- **Small Asteroid Properties:**
  - HP: **20** (unshootable in Level 1; undamaged by player collision).
  - Collision Damage: **1 damage** inflicted on the player.
  - Spawn location: Randomized above the top screen boundary ($Y = -38$, $X \in [30, 1250]$).
  - Speed: Randomized between $190.0$ and $300.0$ px/s downwards.
  - Spin: Randomized angular velocity between $-2.0$ and $+2.0$ rad/s.
- **Damage Timing & Contact Pair Rules:**
  - Repeated contact damage is limited to **one damage event per 0.5 seconds per contact pair** (`contact_tick_seconds = 0.5`).
  - **No Generic Invulnerability Frames:** Collision cooldowns are tracked per contacting entity instance (`contact_cooldown[instance_id]`). Multiple asteroids hitting the player simultaneously inflict independent damage events.
  - **Separation & Re-contact Safety:** If an asteroid separates from the player and re-contacts before its 0.5s cooldown has elapsed, it cannot inflict damage until the full 0.5s period expires.
  - **Safe Pruning:** When asteroids exit the screen, are destroyed, or are freed, their entries in the cooldown dictionary are pruned immediately to avoid stale object references or memory leaks.

---

## 5. Passive Health Regeneration

- **Restoration Rate:** 1 HP per second (`regen_per_second = 1.0`).
- **Activation Threshold:** Ship movement speed must remain below `stop_threshold` (`8.0 px/s`).
- **Stationary Delay:** A provisional delay of **2.0 seconds** (`regen_wait = 2.0`) is required before passive regeneration begins.
- **Behavior:**
  - After remaining stationary for $\ge 2.0$s, fractional HP accumulates at $1.0 \times \text{delta}$ per second.
  - When accumulated fraction $\ge 1.0$, 1 HP is restored (capped at `max_health = 12`) and `health_changed` is emitted.
  - Moving above `stop_threshold` resets `still_seconds` to 0.0 and interrupts accumulation.
  - Regeneration is strictly halted upon player death or level completion (when physics processing is disabled).
  - Health cannot exceed `max_health = 12`.
- **Diagnostic Debug Overlay:**
  - An in-game overlay displays current HP, speed, stationary duration, regen progress, regen state, and distance to mouse in real time.
  - Toggleable during gameplay with the **F3** key, or configurable via `@export var show_debug_overlay: bool`.

---

## 6. Level Flow, Win/Loss Conditions, and Reset

- **Survival Duration:** The level timer lasts **30 seconds** (`level_duration = 30.0`).
- **Win Condition (Level Complete):**
  - Player survives until `time_remaining <= 0.0`.
  - Sets `finished = true` and `game_won = true`.
  - Main disables player physics processing via Call Down (`player.set_physics_process(false)`).
  - Displays HUD message: `"LEVEL 1 COMPLETE!\n30 seconds survived\nPress R to replay"`.
- **Loss Condition (Game Over):**
  - Player HP reaches 0 (`player.health == 0`).
  - Player emits `died` signal (Signal Up to Main).
  - Main sets `finished = true` and `game_won = false`.
  - Main disables player physics processing via Call Down (`player.set_physics_process(false)`).
  - Displays HUD message: `"SHIP DESTROYED\nPress R to retry Level 1"`.
- **Restart Action:**
  - Pressing the **R** key at any time triggers `restart_level()`, cleanly reloading the current scene via `get_tree().reload_current_scene()`.
  - All spawned asteroids, timers, and player health are reset to pristine initial state.
- **Quit Action:**
  - Pressing the **Escape** key exits the application via `get_tree().quit()`.

---

## 7. Node Communication Architecture

- Follows the strict **Call Down, Signal Up** principle:
  - `Main` $\to$ `Player`: Calls `set_physics_process(false)` on death/completion, calls `reset_state()` on reset.
  - `Player` $\to$ `Main`: Emits `health_changed(current, maximum)` and `died()` signals.
  - `Main` spawns and manages `Asteroid` instances.
  - Player detects asteroid overlaps through physics collision masks without coupling to asteroid internal logic.

---

## 8. Authoritative Stage 1 Progression (30s Arcade Mode)

All Stage 1 levels utilize fixed 1280x720 ARCADE mode with vertical cosmic star scrolling and last **30 seconds** each:

1. **Stage 1 Level 1 (Milestone 1 — COMPLETED & APPROVED):**
   - Asteroid evasion and survival (30s).
   - No weapons equipped.
   - Small asteroids (20 HP, 1 contact damage, undamaged by player).
   - Passive HP regeneration (1 HP/s after 2s stationary delay, 4px deadzone).

2. **Stage 1 Level 2 (Milestone 2 — PLANNED):**
   - Asteroid survival (30s).
   - **No weapons equipped.**
   - Optional communication satellite encounter and extraction interaction (extraction is optional and not required to complete the level).

3. **Stage 1 Level 3:**
   - Asteroid survival (30s).
   - **No weapons equipped** during the level.
   - Acquire primary weapon and shield **AFTER completing** this level.

4. **Stage 1 Level 4:**
   - Asteroid survival (30s).
   - Equipped with primary weapon and shield.

5. **Stage 1 Level 5:**
   - Asteroid survival (30s).
   - Equipped with primary weapon and shield.
   - Encounter the damaged mining vessel NPC and receive Stage 2 coordinates upon survival/completion.

---

## 9. Status of Unapproved Mechanics (Explicitly Removed / Unconfirmed)

The following mechanics are **NOT part of the approved Stage 1 design** and must not be introduced or assumed:
- **Primary Weapon Acquisition in Level 2:** **EXPLICITLY REMOVED.** The player has no weapon in Level 1, Level 2, or Level 3. Weapon and shield are acquired strictly AFTER completing Level 3.
- **Asteroid Fragmentation / Splitting:** **UNCONFIRMED / NOT APPROVED.** Asteroids do not fragment or split upon destruction or collision.
- **Scoring Systems:** **UNCONFIRMED / NOT APPROVED.** There is no arcade score counter, multiplier, or point tallying in Stage 1.
- **Collectible Drops:** **UNCONFIRMED / NOT APPROVED.** Destroyed hazards or entities do not drop power-ups, ammo, or collectible items.

---

## 10. Stage 1 Level 2 Specifications (Milestone 2 Implemented)

- **Mode & Duration:** 30 seconds survival in fixed 1280x720 arcade mode.
- **Primary Weapon:** **NO primary weapon** in Level 2.
- **Player HP Persistence Across Levels:**
  - Player HP persists across levels within the same stage. Completing Level 1 at $X$ HP begins Level 2 at $X$ HP.
  - Completing a level does NOT automatically restore HP.
  - HP is restored to full (12 HP) only when entering a new stage or reviving at a stage checkpoint.
- **Stage Checkpoint & Revive Semantics:**
  - Death in Stage 1 Level 2 restarts **Stage 1 Level 1** (the stage checkpoint).
  - Revive restores player HP to full (12 HP) and clears temporary stage acquisitions.
- **Asteroid Density & Size Progression (Layer 2):**
  - Lower overall spawn density than Level 1 (spawn interval range: `0.65s – 1.25s`, average ~0.95s = ~1.05 rocks/s).
  - Introduces **Medium Asteroids** mixed with Small Asteroids (~40% Medium, ~60% Small).
  - Small Asteroid: 20 HP, 1 contact damage, 19.0 px collision radius.
  - Medium Asteroid: 40 HP, 2 contact damage, 35.0 px collision radius.
  - Asteroids take 0 damage from player collision.
- **Optional Communication Satellite Encounter:**
  - Spawns at $T = 20\text{s}$ remaining and drifts downward across the playfield at 100 px/s.
  - Dedicated collision layer 4 (`interactables`), monitors layer 1 (`player`). Does not interact with asteroids; non-solid to player.
  - Proximity extraction: Remaining within 80 px radius for 1.8s extracts telemetry data and emits narrative payload signal.
  - **Extraction Independence:** Satellite extraction is strictly optional. Surviving 30 seconds triggers Level 2 Complete regardless of whether the satellite was extracted, partially extracted, or missed.

---

## 11. Stage 1 Level 3 Specifications (Milestone 3 Implemented)

- **Mode & Duration:** 30 seconds survival in fixed 1280x720 arcade mode.
- **Primary Weapon:** **NO primary weapon** during Level 3 survival gameplay (unarmed).
- **Level 2 to Level 3 Progression:**
  - On completing Level 2, pressing Space/Enter advances to Level 3.
  - Player HP persists exactly (e.g. 6 HP remaining in Level 2 starts Level 3 at 6 HP; no automatic healing).
  - Satellite extraction status and telemetry data persist into Level 3.
  - Survival timer resets to 30.0 seconds. Old Level 2 entities and temporary contact cooldowns are cleared.
- **Large Asteroids (Layer 3 Belt):**
  - Confirmed Stats: **80 HP**, **4 contact damage**, **65.0 px collision radius**.
  - Unshared collision shape: each asteroid instantiates an independent `CircleShape2D.new()`, preventing shared shape mutation.
  - Node scale remains `Vector2.ONE`; drawn geometry scales independently to avoid double-scaling collision.
  - Contact pair rate-limiting: 4 damage repeats at most once per 0.5s per contact pair.
  - Speed: 90–170 px/s downwards (configurable PROPOSAL/TBD).
  - Asteroids take 0 damage from player collision in Stage 1.
- **Asteroid Density & Mix Progression (Layer 3):**
  - Lowest overall spawn density across Stage 1 (spawn interval range: `1.00s – 1.80s`, average ~1.40s = ~0.71 rocks/s).
  - Size distribution: 30% Small, 40% Medium, 30% Large (configurable PROPOSAL/TBD).
- **Stage Checkpoint & Revive:**
  - Death in Level 3 strictly restarts **Stage 1 Level 1** at full 12 HP.
  - Clears all temporary stage acquisitions (satellite telemetry, weapon, shield).
  - Re-initializes Level 1 timer to 30.0s and restores Level 1 asteroid parameters.
- **Wrecked Spacecraft Encounter & Equipment Acquisition:**
  - Encounter occurs **AFTER completing** the 30-second survival phase.
  - Wrecked military scout craft (`Surveyor-7`) entity revealed in upper playfield with shattered hull, broken starboard wing, intact twin-barrel hardpoint, and deflector emitter dome.
  - Grants:
    - `primary_weapon_acquired = true`
    - `shield_acquired = true`
  - Equipment is acquired exactly once and recorded in `stage_acquisitions`.
  - Signal emitted: `equipment_acquired(equipment_data: Dictionary)`.
  - Equipment is NOT granted if the player dies in Level 3.
  - Satellite extraction from Level 2 is NOT required to obtain equipment.
  - **Deferred Mechanics:** Active twin-barrel shooting (12 shots/s, 1 dmg, left click) and deflector shield activation/absorption are strictly reserved for Milestone 4. No combat mechanics are activated in Milestone 3.
- **End of Prototype (Milestone 3 Historical Baseline):**
  - In Milestone 3, progression stopped at Level 3. In Milestone 4, Level 3 completion prompts: `"Press [Space/Enter] to proceed to combat zone"` to advance to Level 4.

---

## 12. Stage 1 Level 4 Specifications (Milestone 4 Implemented)

- **Mode & Duration:** 30 seconds survival and combat in fixed 1280x720 arcade mode.
- **Level 3 to Level 4 Transition:**
  - Surviving Level 3 awards the primary weapon and deflector shield.
  - Pressing Space or Enter triggers `advance_to_next_level()`.
  - Player HP persists exactly from Level 3 (no automatic heal).
  - Acquired equipment (`primary_weapon_acquired = true`, `shield_acquired = true`) is preserved.
  - Level 4 survival timer initializes to 30.0 seconds.
  - Derelict wrecked spacecraft, remaining asteroids, and temporary contact cooldowns are cleanly cleared.
- **Twin-Barrel Primary Weapon Mechanics:**
  - **Firing Control:** Left Mouse Button continuous firing with delta-timed cooldown management.
  - **Volley Rate:** 6.0 volleys per second (`volleys_per_second = 6.0`, interval $\approx 0.1667\text{s}$).
  - **Output Density:** 2 projectiles per volley = 12 projectiles per second total.
  - **Damage:** Exactly 1 damage per projectile hit.
  - **Muzzle Geometry & Trajectory:**
    - Dual muzzles separated laterally: Left muzzle at $-12\text{ px}$ lateral, $+24\text{ px}$ forward; Right muzzle at $+12\text{ px}$ lateral, $+24\text{ px}$ forward from ship center.
    - Forward trajectory follows the player's facing direction at firing time (`forward = Vector2.UP.rotated(player.rotation)`).
    - Trajectories are parallel (lateral separation maintained; no automatic cursor homing or converging spread).
  - **Level Restrictions:** Weapon firing is strictly inoperable during Levels 1, 2, and 3. Firing activates only in Level 4 (or combat levels) when equipment is acquired.
  - **Node Architecture (Milestone 2 Suite 8 Preservation):**
    - `WeaponController` (`scripts/weapon_controller.gd`) is mounted to `Main` (NOT `Player`).
    - `Player` contains NO weapon child nodes and NO `shoot()` or `fire()` methods.
- **Projectile Physics & Lifecycle (`scenes/projectile.tscn`):**
  - **Collision Layers:** Collision layer 4 (bitmask 4, Layer 3: Player Projectiles); Collision mask 2 (Layer 2: Asteroids).
  - **Speed & Lifetime:** `speed = 750.0 px/s`, `lifetime = 2.5s`.
  - **Despawn Bounds:** Safe deletion when crossing $X < -50$, $X > 1330$, $Y < -50$, or $Y > 770$.
  - **Asteroid Collision & Damage:** On contact with an asteroid, deals 1 damage via `take_damage(1)`, emits `hit(target)`, and immediately despawns.
  - **Double-Hit Protection:** `has_hit` boolean flag and deferred disabling of `monitoring` and `monitorable` prevents duplicate damage callbacks within the same frame.
  - **Non-Hazard Immunity:** Projectiles cannot collide with or damage Player, Communication Satellite, or Wrecked Ships.
- **Asteroid Multi-Hit Health & Destruction:**
  - **Health Tiers:** Small Asteroid = 20 HP, Medium Asteroid = 40 HP, Large Asteroid = 80 HP.
  - **Contact Damage:** Small = 1 damage, Medium = 2 damage, Large = 4 damage.
  - **Damage Signals:** Taking damage emits `damaged(amount, remaining_health)`.
  - **Destruction Mechanics:** Reaching 0 HP triggers `destroy()`:
    - Sets `is_destroyed = true`.
    - Immediately negates contact damage (`contact_damage = 0`).
    - Disables collision shape deferred (`disabled = true`).
    - Emits `destroyed()` signal and calls `queue_free()`.
    - Ongoing physics movement and damage processing halt immediately upon destruction.
- **Level 4 Asteroid Belt Density & Spawning (Provisional TBD):**
  - Spawn interval range: `0.90s – 1.60s` (average ~1.25s = ~0.80 asteroids/s).
  - Size distribution: 35% Small, 40% Medium, 25% Large.
  - Speed ranges: Small (190–300 px/s), Medium (140–240 px/s), Large (90–170 px/s).
  - Combat is optional: player may evade, shoot to carve paths, or combine tactics to survive 30 seconds.
- **Deflector Shield Status:**
  - Flag `shield_acquired = true` stored in `stage_acquisitions`.
  - Active/passive shield mechanics (energy bar, absorption, activation hotkey) deferred as TBD.
- **Stage Checkpoint & Revive:**
  - Death in Level 4 calls `_on_player_died()` (weapon firing disabled, message prompts checkpoint revive).
  - Revive returns strictly to **Stage 1 Level 1** at full 12 HP.
  - Level timer resets to 30.0s.
  - Stage acquisitions cleared (weapons and shield unacquired).
  - Weapon firing disabled in Level 1; active projectiles cleared.
- **Level 4 Completion & Progression:**
  - Surviving 30 seconds triggers Level 4 complete screen:
    `"STAGE 1 / LEVEL 4 COMPLETE!\nAsteroid Combat Zone Cleared (HP: %02d/%02d)\nSatellite Extraction: %s\nPrimary Weapon: Twin-barrel Pulse Cannon (Active)\nShield: Deflector Shield Generator (Stored)\n\nPress [Space/Enter] for Level 5\n[END OF PROTOTYPE — MILESTONE 4 COMPLETE]\nPress [R] to replay Stage 1 from Checkpoint"`
  - Pressing Space or Enter triggers `advance_to_next_level()`, transitioning to Stage 1 Level 5.

---

## 13. Stage 1 Level 5 Specifications (Milestone 5 Implemented)

- **Mode & Duration:** 30 seconds survival and combat in fixed 1280x720 arcade mode, completing Stage 1.
- **Level 4 to Level 5 Transition:**
  - On completing Level 4, pressing Space/Enter advances to Level 5.
  - Player HP persists exactly from Level 4 (no automatic heal; e.g., 7 HP in Level 4 starts Level 5 at 7 HP).
  - Acquired equipment (`primary_weapon_acquired = true`, `shield_acquired = true`) is preserved.
  - Primary weapon twin-barrel continuous firing remains active in Level 5.
  - Level 5 survival timer initializes to 30.0 seconds.
  - Previous asteroids, projectiles, and temporary contact cooldowns are cleanly cleared.
- **Level 5 Asteroid Density & Composition (Provisional TBD):**
  - Spawn interval range: `0.85s – 1.50s` (average ~1.175s = ~0.85 asteroids/s).
  - Size distribution: 30% Small (20 HP, 1 dmg), 40% Medium (40 HP, 2 dmg), 30% Large (80 HP, 4 dmg).
  - Speeds: Small (190–300 px/s), Medium (140–240 px/s), Large (90–170 px/s).
  - Twin-barrel combat is active; shooting carves navigable corridors through dense rock clusters.
- **Optional Mining Survey Satellite (`scenes/mining_satellite.tscn`):**
  - **Spawning:** Spawns once at $T \le 20.0\text{s}$ remaining at random $X \in [300.0, 980.0]$, $Y = -50.0$.
  - **Drift Motion:** Drifts downward at $95.0\text{ px/s}$ (`drift_speed = 95.0`).
  - **Detection & Collision:** Area2D on collision layer 8 (Layer 4: Interactables), collision mask 1 (Layer 1: Player).
  - **Extraction Radius:** $80.0\text{ px}$ (`CircleShape2D`, unscaled root).
  - **Extraction Duration:** $1.8\text{ seconds}$ continuous presence within radius (`extraction_time = 1.8`).
  - **Signals:** Emits `extraction_started`, `extraction_progress_changed(progress: float)`, and `extracted(payload: Dictionary)`.
  - **Telemetry Payload:**
    ```gdscript
    {
        "id": "mining_sat_telemetry_01",
        "entity_type": "mining_satellite",
        "stage": 1,
        "level": 5,
        "status": "extracted",
        "data": "Mining sector beacon telemetry recorded [NON-CANONICAL PLACEHOLDER]"
    }
    ```
  - **HUD Feedback:** Setting `telemetry_notice` displays: `[DATA RECOVERED: Mining satellite telemetry stored]` for 5.0 seconds.
  - **Strictly Optional:** Missing or skipping the mining satellite does NOT cause game over or block victory.
  - **Despawn:** Clean deletion when crossing $Y > 780.0$.
- **Damaged Mining Vessel & Stage 1 Conclusion:**
  - Surviving the full 30 seconds in Level 5 marks Stage 1 complete (`finished = true`, `game_won = true`).
  - **Weapon Shutdown:** Weapon firing is immediately disabled (`weapon_controller.set_firing_enabled(false)`).
  - **Entity Cleanup:** Asteroids, projectiles, and active satellites are cleared.
  - **Derelict Spawn:** Damaged Mining Vessel (`scenes/damaged_mining_ship.tscn`) instantiates at $(640.0, 210.0)$.
  - **Visual Presentation:** Procedural heavy industrial vessel with dual heavy cargo nacelles, reinforced cutting laser mount, hull breach electrical arc sparks, and pulsing amber distress beacon.
  - **Signal Emissions:**
    - `distress_sos_received(payload: Dictionary)` with payload:
      ```gdscript
      {
          "event_id": "stage1_l5_sos_received",
          "stage": 1,
          "level": 5,
          "source_entity": "Damaged Mining Vessel",
          "transmission_type": "Automated SOS",
          "next_stage": 2,
          "description": "Distress beacon intercepted from damaged mining vessel drifting in the deep sector."
      }
      ```
    - `stage_completed(payload: Dictionary)` with payload:
      ```gdscript
      {
          "event_id": "stage1_completed",
          "stage": 1,
          "levels_cleared": 5,
          "next_stage": 2,
          "next_stage_available": false
      }
      ```
  - **Completion Banner:**
    `STAGE 1 COMPLETE!\nFinal Asteroid Sector Cleared (HP: %02d/%02d)\nTelemetry: Comm [%s] | Mining [%s]\n\n[DISTRESS BEACON INTERCEPTED: Damaged Mining Vessel]\n[TRANSMISSION: Automated SOS Received]\n(Coordinates point toward Stage 2)\n\nPress [Space/Enter] to advance to Stage 2 (Inner Sector)\n[STAGE 1 COMPLETE — PROTOTYPE ADVANCING]\nPress [R] to replay Stage 1 from Checkpoint`
  - **Milestone 6 Stage 2 Authorization:** With Milestone 6 authorized, pressing [Space/Enter] triggers `advance_to_stage_2()`, transitioning into `scenes/stage2/stage2_main.tscn`.
- **Stage Checkpoint & Revive:**
  - Death in Level 5 calls `_on_player_died()` (displays `SHIP DESTROYED (STAGE 1 / LEVEL 5)`).
  - Checkpoint revive (via 'R' or `revive_at_stage_checkpoint()`) returns strictly to **Stage 1 Level 1** at full 12 HP.
  - Survival timer resets to 30.0s.
  - All stage acquisitions cleared (`primary_weapon_acquired`, `shield_acquired`, `stage1_completed`, satellite telemetry).
  - Weapons disabled in Level 1; all active entities and derelicts cleared.

---

## 14. Milestone 6: Stage 2 Level 1 — Side-Scrolling & First Hostile Contact

- **Core Gameplay Paradigm Shift:**
  - Moves from Stage 1 vertical dodging into horizontal side-scrolling arcade space combat.
  - Background starfield scrolls horizontally at $140.0\text{ px/s}$ from right to left (`scroll_speed`).
  - Viewport remains standard $1280 \times 720\text{ px}$.
  - Player ship starts at side-scrolling spawn position $(240.0, 360.0)$ on the left sector of the viewport.
- **Survival Objective:**
  - Level duration is strictly 15.0 seconds (`level_duration = 15.0`).
  - Surviving 15.0 seconds completes Stage 2 Level 1 (`game_won = true`, `finished = true`).
  - Destruction of all enemies is NOT required to win; survival alone achieves sector clearance.
- **Stage 1 to Stage 2 Transition:**
  - Accessible via `advance_to_stage_2()` upon completing Stage 1 Level 5.
  - Full HP restoration: Player health is restored to full $12\text{ HP}$ ($12/12$) upon entering Stage 2.
  - Equipment retention: `primary_weapon_acquired = true` and `shield_acquired = true` persist from Stage 1.
  - Weapon firing is immediately active on Stage 2 startup ($6\text{ volleys/s}$, $12\text{ shots/s}$, $1\text{ dmg/hit}$).
  - Clean separation: Stage 1 asteroids, satellites, and wrecked mining vessels are completely cleared.
- **Guard Bot Hostile Automaton (`scenes/enemies/guard_bot.tscn` / `scripts/enemies/guard_bot.gd`):**
  - **HP & Multi-Hit Combat:** $30\text{ HP}$ (`max_health = 30`). Takes 1 damage per player projectile hit. Emits `damaged(amount, remaining_health)` and dies at $0\text{ HP}$ emitting `destroyed`.
  - **Movement:** Drifts horizontally leftward across the screen at $130.0\text{ px/s}$ (`speed`).
  - **Collision Layers:** Collision layer 18 (Layer 2 `[2]` Combat Target | Layer 5 `[16]` Enemies), collision mask 5 (Layer 1 `[1]` Player | Layer 3 `[4]` Player Projectiles).
  - **Official Artwork:** Integrated official `assets/entities/guards/bot/idle.png` ($256 \times 256$) and `assets/entities/guards/bot/attacking.png` ($256 \times 256$) scaled $0.45\times$, rotated $-90^\circ$ to face leftward.
  - **Procedural Fallback:** Armored geometric octagon with glowing red optical sensor and weapon pod, active when textures are unassigned.
  - **Mutual Contact Damage:** Inflicts $1\text{ HP}$ damage to player on contact and takes $1\text{ HP}$ damage in return, governed by independent $0.5\text{s}$ contact pair cooldowns.
  - **Aimed Weapon Attack:** Periodically aims and fires normal enemy projectiles towards the player every $1.8\text{s} - 2.4\text{s}$. Switches to attacking sprite pose for $0.35\text{s}$.
  - **Offscreen Despawn:** Safe deletion when drifting past $X < -100.0\text{ px}$.
- **Enemy Projectiles (`scenes/enemies/enemy_projectile.tscn` / `scripts/enemies/enemy_projectile.gd`):**
  - **Collision Layers:** Collision layer 32 (Layer 6 `[32]` Enemy Projectiles), collision mask 1 (Layer 1 `[1]` Player).
  - **Speed & Damage:** $300.0\text{ px/s}$ linear velocity along firing vector, dealing $1\text{ HP}$ damage per hit to player.
  - **Target Filtering & Friendly Fire Immunity:** Ignores Guard Bots and friendly units; only damages player.
  - **Double-Hit Protection:** `has_hit` flag ensures single damage application per projectile.
  - **Despawn Conditions:** Despawns on player impact, lifetime expiration ($4.0\text{s}$), or boundary margin departure ($X < -60$, $X > 1340$, $Y < -60$, $Y > 780$).
- **Stage 2 Checkpoint & Revival Semantics:**
  - Death in Stage 2 Level 1 triggers `_on_player_died()` displaying `SHIP DESTROYED (STAGE 2 / LEVEL 1)`.
  - Pressing [R] triggers `revive_at_stage_checkpoint()`, reviving player strictly at **Stage 2 Level 1** at full $12\text{ HP}$.
  - Reviving in Stage 2 does **NOT** send the player back to Stage 1!
  - Timer resets to 15.0s, active enemies and projectiles are cleared, and primary weapon remains active.
  - Stage 1 checkpoint revive remains intact, reviving at Stage 1 Level 1 without weapons.
- **Milestone Scope Boundary:**
  - Stage 2 Level 1 completion displays victory banner: `STAGE 2 / LEVEL 1 COMPLETE!`.
  - Stage 2 Level 2 cannot be started; no fake Level 2 scenes or transitions are implemented.





---

## 15. Milestone 7: Stage 2 Level 2 — Guard Satellite & Accurate Laser Combat

- **Core Gameplay Continuation:**
  - Stage 2 Level 2 continues the horizontal side-scrolling format introduced in Level 1.
  - Background starfield continues moving right-to-left at $140.0\text{ px/s}$ (`scroll_speed`).
  - Viewport remains $1280 \times 720\text{ px}$.
- **Survival Objective:**
  - Level duration is strictly 20.0 seconds (`level_duration = 20.0`).
  - Surviving 20.0 seconds completes Stage 2 Level 2 (`game_won = true`, `finished = true`).
  - Defeating a mandatory count of satellites is NOT required to win; survival alone achieves victory.
- **Level 1 to Level 2 Progression & State Persistence:**
  - When Stage 2 Level 1 finishes (15s survived), a completion banner prompts `Press [Space/Enter] for Level 2`.
  - Pressing Space/Enter calls `advance_to_next_level()`.
  - **HP Persistence:** The player ship's remaining HP at the end of Level 1 is strictly preserved into Level 2 (no full HP restoration occurs between levels within Stage 2).
  - **Equipment Retention:** Primary weapon and shield acquisitions persist (`is_primary_weapon_acquired() == true`, `is_shield_acquired() == true`). Weapon firing remains active ($6\text{ volleys/s}$, $12\text{ shots/s}$, $1\text{ dmg/hit}$).
  - **Entity Cleanup:** Remaining Guard Bots, projectiles, and contact cooldowns from Level 1 are cleared.
  - **Level Setup:** `current_level = 2`, survival timer initialized to 20.0s, and HUD displays `STAGE 2 / LEVEL 2`.
- **Guard Satellite Security Automaton (`scenes/enemies/guard_satellite.tscn` / `scripts/enemies/guard_satellite.gd`):**
  - **HP & Multi-Hit Combat:** $20\text{ HP}$ (`max_health = 20`). Takes 1 damage per player projectile hit. Emits `damaged(amount, remaining_health)` and dies at $0\text{ HP}$ emitting `destroyed`.
  - **Movement:** Drifts horizontally leftward across the screen at $90.0\text{ px/s}$ (`speed`). Spawns from off-screen right ($X = 1320.0\text{ px}$, $Y \in [90.0, 630.0]\text{ px}$).
  - **Collision Layers:** Collision layer 18 (Layer 2 `[2]` Combat Target | Layer 5 `[16]` Enemies), collision mask 5 (Layer 1 `[1]` Player | Layer 3 `[4]` Player Projectiles).
  - **Official Artwork:** Integrated official `assets/sprites/enemies/guard_satellite/guard_satellite_idle.png` ($347 \times 267\text{ px}$) and `guard_satellite_attacking.png` ($347 \times 267\text{ px}$) scaled $0.35\times$, rotated $-90^\circ$ to face leftward.
  - **Procedural Fallback:** Geometric armored chassis with dual solar arrays and forward laser optical emitter in `Visuals/ProceduralFallback`.
  - **Mutual Contact Damage:** Inflicts $1\text{ HP}$ damage to player on contact and takes $1\text{ HP}$ damage in return, governed by independent $0.5\text{s}$ contact pair cooldowns.
  - **Offscreen Despawn:** Safe deletion when drifting past $X < -120.0\text{ px}$.
- **Accurate Laser System (`scripts/enemies/guard_satellite_laser_visual.gd`):**
  - **Attack Lifecycle:**
    1. `TELEGRAPH` ($0.5\text{s}$ warning): Satellite aims toward player's current coordinates, locks firing orientation (`locked_aim_direction`), and displays an amber/red warning telegraph line. The laser does NOT track player movement after direction is locked. Laser `monitoring = false` (deals 0 damage during telegraph).
    2. `FIRING` ($0.15\text{s}$ beam): Fires a high-energy laser beam along the locked direction. Displays official `attacking.png` sprite pose. Laser `monitoring = true`.
    3. `COOLDOWN` ($2.2\text{s} - 3.2\text{s}$): Returns to idle sprite pose and recharges.
  - **Hit Detection & Damage:** Area2D beam extending 1400 px along locked vector (Collision Layer 32, Mask 1). Inflicts exactly $1\text{ HP}$ damage to the player if inside the beam during firing.
  - **Single Damage Guarantee:** `has_dealt_damage` boolean flag ensures damage occurs at most once per laser attack event, eliminating per-frame damage loops.
  - **Dodge Mechanics:** Player can avoid damage by observing the telegraph warning line and moving out of the beam path before the laser fires.
  - **Friendly Fire & Self-Damage Immunity:** Mask 1 ensures laser only detects the player; firing satellite and friendly Guard Bots/Satellites are completely immune.
  - **Destruction Safety:** Destroying the satellite immediately terminates the laser attack (`stop_attack()`), disables collision, and frees the node.
- **Stage 2 Checkpoint & Revival Semantics:**
  - Death in Stage 2 Level 2 triggers `_on_player_died()` displaying `SHIP DESTROYED (STAGE 2 / LEVEL 2)`.
  - Pressing [R] calls `revive_at_stage_checkpoint()`, reviving the player strictly at **Stage 2 Level 1** at full $12\text{ HP}$ with active weapons.
  - Reviving in Stage 2 does **NOT** reset the player to Stage 1.
- **Milestone Scope Boundary:**
  - Surviving 20 seconds in Level 2 displays `STAGE 2 / LEVEL 2 COMPLETE!` and enables progression to Level 3 via [Space/Enter].
- **M7 Laser Alignment Audit:**
  - In `guard_satellite.gd`, the `Laser` node is an integrated child `Area2D` of `GuardSatellite`.
  - When the satellite drifts horizontally leftward during the telegraph warning phase, the laser moves in lockstep because its local transform is anchored to the satellite body.
  - The warning telegraph visual line and the physical `CollisionShape2D` beam share the identical local coordinates ($Vector2(0, 0)$ to $Vector2(1400, 0)$), oriented via `locked_aim_direction.angle()`.
  - Audited and verified: 100% visual and physics alignment is maintained throughout the entire telegraph and firing lifecycle, with zero drift divergence.


---

## 16. Milestone 8: Stage 2 Level 3 — Kamikaze Guard Drone & EM Jammer Acquisition

- **Core Gameplay Continuation:**
  - Stage 2 Level 3 continues the horizontal side-scrolling format introduced in Level 1.
  - Background starfield continues moving right-to-left at $140.0\text{ px/s}$ (`scroll_speed`).
  - Viewport remains fixed at $1280 \times 720\text{ px}$.
- **Untimed 5-Kill Elimination Objective:**
  - Unlike Levels 1 and 2, Level 3 has **no survival timer** and **no time limit** (`level_duration = 0.0`, `time_remaining = 0.0`).
  - Victory condition requires destroying exactly **5 Guard Drones** with the player's twin-barrel pulse cannon (`target_kills = 5`, `drones_destroyed >= 5`).
  - Drones spawn continuously from offscreen right ($X = 1320.0\text{ px}$, $Y \in [80.0, 640.0]\text{ px}$) at randomized intervals (`drone_spawn_interval_min: 2.2s`, `drone_spawn_interval_max: 3.5s`) until 5 legitimate player kills are recorded.
  - HUD displays: `STAGE 2 / LEVEL 3     HP %02d / %02d     DRONES DESTROYED: %d / %d`.
- **Level 2 to Level 3 Progression & State Persistence:**
  - When Stage 2 Level 2 is completed, the victory banner displays: `Press [Space/Enter] for Level 3`.
  - Pressing Space or Enter calls `advance_to_next_level()`.
  - **HP Persistence:** Remaining player HP at the end of Level 2 is strictly preserved into Level 3 (no within-stage restoration).
  - **Equipment Retention:** Primary weapon and deflector shield persist (`is_primary_weapon_acquired() == true`, `is_shield_acquired() == true`).
  - **Entity Cleanup:** Lingering satellites, lasers, projectiles, and cooldowns from Level 2 are cleared.
  - **Level Setup:** `current_level = 3`, `drones_destroyed = 0`, `target_kills = 5`.
- **Guard Drone Security Automaton (`scenes/enemies/guard_drone.tscn` / `scripts/enemies/guard_drone.gd`):**
  - **HP & Multi-Hit Combat:** $20\text{ HP}$ (`max_health = 20`). Takes 1 damage per player projectile hit. Emits `damaged(amount, remaining_health)` and dies at $0\text{ HP}$ emitting `destroyed` and `drone_defeated(DestructionReason.PLAYER_WEAPON, self)`.
  - **Collision Layers:** Collision layer 18 (Layer 2 `[2]` Combat Target | Layer 5 `[16]` Enemies), collision mask 5 (Layer 1 `[1]` Player | Layer 3 `[4]` Player Projectiles).
  - **Official Artwork:** Integrated official `assets/sprites/enemies/guard_drone/guard_drone_idle.png` ($152 \times 316\text{ px}$) and `guard_drone_attacking.png` ($151 \times 316\text{ px}$) scaled $0.35\times$, rotated $-90^\circ$ to face leftward.
  - **Procedural Fallback:** Sleek arrowhead armored hull with rear thruster exhaust flare and forward glowing optical cluster / charge corona in `Visuals/ProceduralFallback`.
  - **FSM AI State Machine:**
    1. `APPROACH` ($120.0\text{ px/s}$): Enters from right edge, drifting leftward for an approach duration (`approach_timer = 1.0 - 2.0s`).
    2. `TELEGRAPH` ($0.45\text{s}$ warning): Locks charge trajectory toward player's current position (`locked_charge_direction`), activates `guard_drone_attacking.png` sprite pose, and aligns visual rotation. Does NOT track player turning once locked.
    3. `CHARGING` ($360.0\text{ px/s}$ dash): High-speed linear dash along `locked_charge_direction`.
    4. `DESTROYED`: Collision and monitoring disabled, queued for deletion.
  - **Dodge Mechanics:** Because the trajectory locks during telegraph, the player can observe the warning pose/corona and maneuver vertically out of the drone's flight line.
- **Strict Kill Credit Attribution Rules:**
  - `DestructionReason.PLAYER_WEAPON` ($0$): Drone destroyed by player weapon damage. Only this increments `drones_destroyed` and counts toward the 5-kill objective.
  - `DestructionReason.KAMIKAZE_IMPACT` ($1$): Drone collides with player ship. Deals $1\text{ HP}$ contact damage to player and immediately self-destructs. Awards **ZERO** kill credit (`drones_destroyed` does not increment).
  - `DestructionReason.OFFSCREEN_DESPAWN` ($2$): Drone flies past offscreen left ($X < -120.0\text{ px}$). Self-destructs with **ZERO** kill credit.
  - `DestructionReason.LEVEL_CLEANUP` ($3$): Drone cleared on level reset or player death. Awards **ZERO** kill credit.
- **Equipment Acquisition (EM Jammer):**
  - Unearned at Level 3 start (`is_em_jammer_acquired() == false`, `stage_acquisitions["em_jammer_acquired"] = false`).
  - Achieved upon registering the 5th legitimate drone kill:
    - Sets `stage_acquisitions["em_jammer_acquired"] = true`.
    - Emits `em_jammer_acquired_event({"equipment": "em_jammer", "level": 3, "status": "acquired"})`.
    - Emits `level_completed(3)`.
    - Displays victory banner:
      `STAGE 2 / LEVEL 3 COMPLETE!\nGuard Drone Interceptors Neutralized (5/5)\n[EQUIPMENT RECOVERED: EM Jammer]\n\n[STAGE 2 LEVEL 3 COMPLETE — PROTOTYPE FINISHED]\nPress [R] to replay Stage 2 from Checkpoint`
  - **Deferred Activation:** EM Jammer weapon behavior (120° forward cone, 10s enemy stun, 30s cooldown) is deferred to Stage 2 Level 4+. Player node has no active input bindings in Level 3.
- **Stage 2 Checkpoint & Revival Semantics:**
  - Death in Stage 2 Level 3 triggers `_on_player_died()` displaying `SHIP DESTROYED (STAGE 2 / LEVEL 3)\nPress [R] to Revive at Stage 2 Checkpoint`.
  - Pressing [R] calls `revive_at_stage_checkpoint()`, reviving player strictly at **Stage 2 Level 1** at full $12\text{ HP}$ with active weapons.
  - Unearned EM Jammer is cleared on revive (`is_em_jammer_acquired() == false`).
  - `drones_destroyed` is reset to 0.
  - Reviving in Stage 2 does **NOT** reset the player to Stage 1.
- **Milestone Scope Boundary:**
  - Completing Level 3 displays completion banner prompting [Space/Enter] for Level 4.

---

## 17. Milestone 9: Stage 2 Level 4 — Guard Cruiser Mini-Boss Phase 1 & EM Jammer Activation

- **Arena Architecture & Transition from Side-Scrolling (`scenes/stage2/boss_arena.tscn` / `scripts/stage2/boss_arena.gd`):**
  - **Arcade Arena Layout:** Transitions from horizontal side-scrolling to a fixed $1280 \times 720\text{ px}$ arcade boss arena. Starfield drifts gently downward at $25.0\text{ px/s}$, centering visual focus on the mini-boss encounter.
  - **Player Spawn:** Player spawns centered in the lower sector at $(640.0, 560.0)\text{ px}$, free to maneuver with standard mouse steering within $(24.0, 24.0)$ to $(1256.0, 696.0)\text{ px}$.
  - **HUD Information Display:**
    - Player Status: `STAGE 2 / LEVEL 4     HP %02d / %02d`
    - Boss HP Bar: `GUARD CRUISER: %03d / 400 HP`
    - EM Jammer Status: `EM JAMMER: READY [E]` (cyan) when charged, or `EM JAMMER: COOLING (%.1fs)` (amber) during cooldown.
- **Level 3 to Level 4 Progression & State Persistence:**
  - Pressing [Space/Enter] after completing Level 3 triggers `advance_to_next_level()`.
  - **Strict HP Persistence:** Remaining player HP from Level 3 is strictly preserved into Level 4 (no intra-stage restoration).
  - **Equipment Retention:** Primary twin-barrel blasters ($6\text{ volleys/s}$, $12\text{ shots/s}$, $1\text{ dmg}$), deflector shield hardware, and the EM Jammer acquired at the end of Level 3 persist into Level 4.
  - **Entity Cleanup:** Old side-scrolling drones, projectiles, and hazards are cleared cleanly.
- **Guard Cruiser Mini-Boss Entity (`scenes/bosses/guard_cruiser.tscn` / `scripts/bosses/guard_cruiser.gd`):**
  - **HP & Multi-Hit Health System:** Total health is $400\text{ HP}$ (`max_health = 400`). Takes 1 damage per player projectile hit, emitting `health_changed(current, max_health)`.
  - **Phase 1 Damage Clamping (400 to 200 HP):**
    - Phase 1 encompasses the health range from $400\text{ HP}$ down to $200\text{ HP}$.
    - Crossing the threshold at $200\text{ HP}$ emits `phase_threshold_reached(1)` exactly once and sets `phase_1_completed = true`.
    - `can_take_damage` is set to `false`, and any subsequent hits are strictly clamped at $200\text{ HP}$.
    - Boss is **NOT destroyed** and **NOT defeated** (`is_destroyed = false`, `defeated` signal reserved for Phase 2 in a future milestone).
  - **Collision Layers & Geometry:**
    - Collision Layer 18 (Layer 2 `[2]` Combat Target | Layer 5 `[16]` Enemies), Collision Mask 5 (Layer 1 `[1]` Player | Layer 3 `[4]` Player Projectiles).
    - Neutral root scale `Vector2.ONE`. Central hull hitbox is a `RectangleShape2D(230.0, 110.0)`.
  - **Official Artwork Integration:**
    - Integrated official `assets/sprites/bosses/stage2_miniboss/miniboss_alive_p1.png` ($601 \times 321\text{ px}$) under `Visuals/OfficialArt/Phase1Sprite`.
    - Scaled visually to $0.4 \times 0.4$ ($\approx 240.4 \times 128.4\text{ px}$) and rotated $\pi$ ($180^\circ$) so the capital ship's heavy prow faces South toward the player.
    - Official sprites `miniboss_alive_p2.png` and `miniboss_dead.png` are staged under `Visuals/OfficialArt/Phase2Sprite` and `Visuals/OfficialArt/DeadSprite`, strictly hidden and reserved for Phase 2 and defeat in future milestones.
    - Procedural battlecruiser fallback in `Visuals/ProceduralFallback` (`scripts/bosses/guard_cruiser_visual.gd`) with dual warp nacelles, reinforced command bridge, and dynamic electrical stun arc overlays.
  - **Movement & Sweeps:** Patrols horizontally in the upper sector ($Y = 150.0\text{ px}$) between $X = 220.0\text{ px}$ and $X = 1060.0\text{ px}$ at $85.0\text{ px/s}$ (`move_speed = 85.0`). Reversing direction upon reaching sector turnaround limits.
  - **Controlled Burst Attacks:**
    - Fires controlled 3-projectile aimed bursts (`burst_count = 3`) every $2.6\text{s}$ (`attack_interval = 2.6`).
    - **Windup Warning ($0.5\text{s}$):** Enters `WINDUP` state, displaying charging electrical hull glow.
    - **Firing:** Emits 3 energy bolts along the player's vector with a narrow $12^\circ$ spread ($300.0\text{ px/s}$, Layer 32 Enemy Projectiles, Mask 1 Player). Each bolt deals $1\text{ HP}$ damage on player impact.
    - **Dodgeable:** Firing direction locks at windup initiation; player can evade laterally.
    - **Friendly Fire & Self-Damage Immunity:** Mask 1 ensures enemy projectiles never damage the boss or other enemies.
- **EM Jammer Active Equipment System (`scripts/equipment/em_jammer_controller.gd`):**
  - **Input Activation:** Action `em_jammer` mapped to physical key `E` (with provisional direct key fallback).
  - **Directional Cone Geometry ($120^\circ$ Cone):**
    - Evaluates targets within a full $120^\circ$ sector ($\pm 60^\circ$ from player's forward facing heading `Vector2.UP.rotated(player.rotation)`).
    - Maximum effective range is $600.0\text{ px}$ (`cone_range = 600.0`).
    - Targets within range and inside the $\pm 60^\circ$ angular delta are affected: `absf(heading.angle_to(to_enemy.normalized())) <= deg_to_rad(60.0)`.
  - **Non-Damaging Stun Effect ($10.0\text{s}$ Duration):**
    - Calls `apply_stun(10.0)` on all affected enemy targets.
    - **Zero Damage Guarantee:** Strictly inflicts 0 damage to boss or enemies.
    - Halts boss patrol movement (`is_stunned = true`) and cancels any ongoing attack or windup.
    - Boss remains fully vulnerable to player blasters during the stunned state.
    - Boss resumes movement and combat timers smoothly after 10.0 seconds expire (`stun_ended` signal).
  - **Cooldown Lifecycle ($30.0\text{s}$ Cooldown):**
    - Successful activation triggers a $30.0\text{s}$ cooldown timer (`cooldown_duration = 30.0`).
    - Duplicate activations are rejected while cooling down.
    - Emits `cooldown_started(30.0)` and `cooldown_finished` upon completion.
  - **Visual Feedback:** Renders an expanding arc pulse wave (`_draw`) in cyan/electric blue for $0.35\text{s}$ along the activation heading.
- **Phase 1 Completion Banner:**
  - Upon reaching $200\text{ HP}$, the level finishes with `finished = true`, `game_won = true`, player weapons disabled, and displays the banner:
    ```
    STAGE 2 / LEVEL 4 COMPLETE
    GUARD CRUISER — PHASE 1 DISABLED
    BOSS HP: 200 / 400
    [PHASE 2 — NEXT MILESTONE]
    Press [R] to replay Stage 2 from Checkpoint
    ```
- **Stage 2 Checkpoint & Revival Semantics:**
  - Player death in Level 4 halts physics and displays:
    `SHIP DESTROYED (STAGE 2 / LEVEL 4)\nPress [R] to Revive at Stage 2 Checkpoint`
  - Pressing [R] invokes `revive_at_stage_checkpoint()`, reviving strictly at **Stage 2 Level 1** at full $12\text{ HP}$ with primary weapon and shield retained.
  - Unearned EM Jammer is cleared on revive.
  - Reviving in Stage 2 does **NOT** reset the player to Stage 1.
- **Milestone Scope Boundary:**
  - Milestone 9 is strictly limited to Phase 1 of the Guard Cruiser encounter.
  - Phase 2 combat patterns, Phase 2 sprites, boss destruction, and Stage 2 Level 5 are strictly deferred to future milestones.
