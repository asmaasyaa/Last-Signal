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
- **Level 4 Completion & Prototype Boundary:**
  - Surviving 30 seconds triggers Level 4 complete screen:
    `"STAGE 1 / LEVEL 4 COMPLETE!\nAsteroid Combat Zone Cleared (HP: %02d/%02d)\nSatellite Extraction: %s\nPrimary Weapon: Twin-barrel Pulse Cannon (Active)\nShield: Deflector Shield Generator (Stored)\n\n[END OF PROTOTYPE — MILESTONE 4 COMPLETE]\nPress [R] to replay Stage 1 from Checkpoint"`
  - Halts further progression cleanly (no Level 5 auto-advance).


