# LAST SIGNAL — Decisions and TBD Parameters

This document tracks unresolved balance parameters, provisional features, and pending design decisions for LAST SIGNAL.

---

## 1. Asteroid Contact Damage Received from Player

- **Current Implementation:** For Milestone 1, asteroids inflict 1 damage upon colliding with the player, but the asteroid itself takes **0 damage** from the player ship (`health` remains 20).
- **Status:** **TBD (Pending Lead Decision)**.
- **Context:** Mutual collision damage is explicitly defined for enemy-ship collisions, whereas asteroid damage is defined separately across size tiers.
- **Open Questions:**
  1. Should player collisions inflict ramming damage on asteroids?
  2. If yes, how much damage should small, medium, and large asteroids take when rammed?
  3. Should ramming an asteroid inflict increased self-damage on the player?

---

## 2. Stationary Regeneration Delay (`regen_wait`)

- **Current Implementation:** Configurable export variable `@export var regen_wait: float = 2.0` on `Player` (default: 2.0 seconds).
- **Status:** **Provisional / TBD**.
- **Context:** The proposal of requiring 2.0 seconds of inactivity before passive HP restoration begins is provisional.
- **Tuning Options:**
  - `0.0s`: Regeneration begins immediately as soon as movement speed drops below `stop_threshold`.
  - `1.0s – 3.0s`: Enforces a brief stationary lull, rewarding safe dodging and stopping.
- **Resolution Path:** Design lead review during playtesting.

---

## 3. Regeneration Interruption by Damage

- **Current Implementation:** Regeneration is currently gated solely by speed (`movement_velocity.length() <= stop_threshold`). Taking damage does not reset `still_seconds` unless the player moves.
- **Status:** **TBD**.
- **Open Questions:**
  1. Should taking asteroid damage reset the stationary timer `still_seconds` to 0?
  2. Should taking damage impose an independent "damage cooldown lockout" (e.g., 3 seconds after taking damage before regeneration can resume)?

---

## 4. Stationary Speed Threshold & Arrival Deadzone (`stop_threshold`, `arrive_distance`)

- **Current Implementation:**
  - `@export var stop_threshold: float = 8.0` px/s (velocity threshold below which the ship is considered stationary).
  - `@export var arrive_distance: float = 4.0` px (arrival deadzone distance within which velocity is clamped to zero).
- **Status:** **TBD / Provisional Tuning**.
- **Context:** Without an arrival deadzone, even a 0.5-pixel optical mouse sensor shift between 60Hz frames produces instantaneous velocity of $30\text{ px/s} > 8.0\text{ px/s}$, repeatedly resetting `still_seconds` and blocking regeneration in human hands. Setting `arrive_distance = 4.0` stabilizes the ship at the cursor while preserving responsive flight when the mouse is moved beyond 4 pixels.
- **Resolution Path:** Validate across multiple mouse DPI settings during playtesting.

---

## 5. Player Movement Physics Model

- **Current Implementation:** Direct velocity clamping (`to_mouse.limit_length(move_speed * delta)`) towards global mouse coordinates, bounded by screen edges.
- **Status:** **TBD (Proposed Baseline)**.
- **Context:** Current implementation provides immediate, crisp control suited for fast-paced arcade evasion.
- **Open Questions:**
  1. Should inertial acceleration / deceleration (smoothing/lerp) be added to simulate spacecraft momentum?
  2. Should mouse steering use a deadzone around the ship?

---

## 6. Asteroid Spawning & Progression Across Stage 1

- **Current Implementation (Level 1):** Simple randomized interval spawning (`spawn_interval_min: 0.35`, `spawn_interval_max: 0.85`, `speed: 190.0 - 300.0`, small asteroids only).
- **Status:** **Configurable Baseline**.
- **Stage 1 Progression Strategy (Level 2+):**
  - In Level 2, tune spawn frequency or speed via exported level configuration parameters.
  - Asteroid size tiers (if any beyond small) remain subject to lead approval.
  - **EXPLICITLY REMOVED / UNCONFIRMED:** Asteroid splitting or fragmentation upon destruction is NOT approved for Stage 1.
  - **EXPLICITLY REMOVED / UNCONFIRMED:** Collectible item drops and arcade scoring systems are NOT approved for Stage 1.

---

## 7. Audio, Feedback & Juice

- **Current Implementation:** Visual HUD text and procedural color outlines.
- **Status:** **Deferred to Later Milestones / Polish Phase**.
- **Items to Define in Later Milestones:**
  - Sound effects for collision, hull damage warning, regeneration tick, level win, satellite extraction, and game over.
  - Screen shake on asteroid collision.
  - Particle explosions upon destruction.

---

## 8. Milestone 2 Level 2 Configurable Parameters (Proposals / TBD)

- **Mechanic Overview:** Stage 1 Level 2 introduces lower asteroid density with medium asteroids and an optional communication satellite drift encounter.
- **Configurable Parameters in Code (`scripts/main.gd` & `scripts/satellite.gd`):**
  1. **Level 2 Asteroid Density:** `@export var l2_spawn_interval_min: float = 0.65`, `@export var l2_spawn_interval_max: float = 1.25` (provisional density ~1.05 rocks/s, ~37% lower than Level 1).
  2. **Level 2 Asteroid Mix:** `@export var l2_medium_ratio: float = 0.40` (40% medium, 60% small).
  3. **Medium Asteroid Speeds:** `@export var l2_speed_medium_min: float = 140.0`, `@export var l2_speed_medium_max: float = 240.0` (heavier/slower than small asteroids).
  4. **Satellite Spawn Timing:** `@export var l2_satellite_spawn_time: float = 20.0` (spawns at $T = 20\text{s}$ remaining / 10s into Level 2).
  5. **Satellite Drift Speed:** `@export var drift_speed: float = 100.0` px/s (steady downward drift).
  6. **Extraction Radius & Duration:** `@export var extraction_radius: float = 80.0` px, `@export var extraction_time: float = 1.8` seconds.
  7. **Narrative Payload Stub:** Successful extraction emits payload containing placeholder decrypted telemetry metadata (`sat_telemetry_01`).
- **Status:** **Configurable / Subject to Lead Review during playtesting.**

---

## 9. Milestone 3 Level 3 Configurable Parameters (Proposals / TBD)

- **Mechanic Overview:** Stage 1 Level 3 represents the deepest layer of the asteroid belt with larger asteroid sizes, lower overall spawn density, persistent player HP from Level 2, stage checkpoint revive to Level 1 with 12 HP, and a post-survival wrecked spacecraft encounter (`Surveyor-7`) that yields the primary weapon and deflector shield.
- **Configurable Parameters in Code (`scripts/main.gd` & `scripts/asteroid.gd`):**
  1. **Level 3 Asteroid Density:** `@export var l3_spawn_interval_min: float = 1.00`, `@export var l3_spawn_interval_max: float = 1.80` (provisional average interval 1.40s, ~0.71 asteroids/s; lower density than Level 2 ~1.05 rocks/s and Level 1 ~1.67 rocks/s to account for large asteroid hazard footprint).
  2. **Level 3 Asteroid Mix:** `@export var l3_large_ratio: float = 0.30`, `@export var l3_medium_ratio: float = 0.40`, remaining 0.30 Small (provisional 30% Large, 40% Medium, 30% Small).
  3. **Large Asteroid Speeds:** `@export var l3_speed_large_min: float = 90.0`, `@export var l3_speed_large_max: float = 170.0` px/s (massive, slower movement profile with high collision impact).
  4. **Large Asteroid Stats:** 80 HP, 4 contact damage, 65.0 px collision radius with unique `CircleShape2D` shape resource and `scale = Vector2.ONE`.
  5. **Post-Survival Wrecked Craft Encounter:** `@export var wrecked_ship_scene: PackedScene` spawned at `(640, 360)` after 30s survival. Grants `primary_weapon_acquired = true` and `shield_acquired = true` in stage acquisitions and emits `equipment_acquired(equipment_data)`.
  6. **Deferred Milestone 4 Combat Systems:**
     - Player twin-barrel primary weapon (12 shots/s, 1 dmg per projectile, Left Mouse Button firing) is strictly deferred to Milestone 4.
     - Player deflector shield activation, energy/cooldown, and absorption mechanics are strictly deferred to Milestone 4.
     - Active shooting, projectile hit detection, and shield combat are not enabled during Milestone 3.
- **Status:** **Configurable / Subject to Lead Review during playtesting.**



---

## 10. Milestone 4 Level 4 Configurable Parameters & Combat TBDs

- **Mechanic Overview:** Stage 1 Level 4 introduces active twin-barrel shooting and multi-hit asteroid destruction while maintaining 30s arcade survival rules, HP persistence from Level 3, and Stage 1 checkpoint revive.
- **Configurable Parameters in Code (`scripts/main.gd` & `scripts/weapon_controller.gd`):**
  1. **Level 4 Asteroid Density:** `@export var l4_spawn_interval_min: float = 0.90`, `@export var l4_spawn_interval_max: float = 1.60` (provisional average interval 1.25s, ~0.80 asteroids/s; calibrated for active shooting flow).
  2. **Level 4 Asteroid Mix:** `@export var l4_small_ratio: float = 0.35` (35% Small), `@export var l4_medium_ratio: float = 0.40` (40% Medium), `@export var l4_large_ratio: float = 0.25` (25% Large).
  3. **Weapon Controller Tuning:**
     - `@export var volleys_per_second: float = 6.0` (6 volleys/s = 12 projectiles/s).
     - `@export var projectile_damage: int = 1` (1 HP per projectile).
     - `@export var projectile_speed: float = 750.0` px/s.
     - `@export var muzzle_offset_lateral: float = 12.0` px.
     - `@export var muzzle_offset_forward: float = 24.0` px.
  4. **Projectile Lifetime & Bounds:** `@export var lifetime: float = 2.5` seconds, bounded by playfield margins ($[-50, 1330]$ X, $[-50, 770]$ Y).
  5. **Deflector Shield System (Deferred TBD):**
     - Shield hardware acquired at Level 3 and stored in `stage_acquisitions["shield_acquired"] = true`.
     - Active/passive shield behavior (e.g., energy bar, passive hit absorption, or active toggle key) is deferred to future milestones.
  6. **Explicitly Excluded Systems (Preserved Boundaries):**
     - No ammunition limits, reloads, weapon overheating, recoil physics, or critical hits.
     - No secondary weapons (missiles, bombs, EM jammers).
     - No asteroid item drops or arcade scoring counters.
- **Status:** **Configurable Baseline / Subject to Lead Playtesting.**

---

## 11. Milestone 5 Level 5 Configurable Parameters & Narrative Interface Decisions

- **Mechanic Overview:** Stage 1 Level 5 completes Stage 1 gameplay, featuring the final dense asteroid sector, active twin-barrel shooting, an optional mining survey satellite proximity extraction, and an encounter with a drifting damaged mining vessel emitting an automated SOS pointing toward Stage 2.
- **Configurable Parameters in Code (`scripts/main.gd` & `scripts/mining_satellite.gd`):**
  1. **Level 5 Asteroid Density:** `@export var l5_spawn_interval_min: float = 0.85`, `@export var l5_spawn_interval_max: float = 1.50` (provisional average interval 1.175s, ~0.85 asteroids/s; densest sector requiring active shooting to carve navigational corridors).
  2. **Level 5 Asteroid Distribution:** `@export var l5_small_ratio: float = 0.30` (30% Small), `@export var l5_medium_ratio: float = 0.40` (40% Medium), `@export var l5_large_ratio: float = 0.30` (30% Large).
  3. **Mining Satellite Scheduling & Mechanics:**
     - `@export var l5_satellite_spawn_time: float = 20.0` (spawns once when 20s or fewer remain).
     - `@export var drift_speed: float = 95.0` px/s downward.
     - `@export var extraction_time: float = 1.8` seconds of continuous proximity presence.
     - `@export var extraction_radius: float = 80.0` px (`CircleShape2D`, unscaled root).
  4. **Damaged Mining Vessel Presentation:**
     - Positioned at `Vector2(640.0, 210.0)` with floating bobbing oscillation.
     - Procedural visual fallback implemented (`scripts/damaged_mining_ship.gd`) with heavy industrial silhouette, cargo pods, cutting laser mount, hull breach electrical sparks, and pulsing amber SOS beacon.
     - `nirawak1/before-extraction.png` and `after-extraction.png` remain unassigned until officially confirmed by art and narrative leads.
  5. **Stage 1 Completion & Signal Architecture:**
     - Surviving 30 seconds disables weapon firing and emits `distress_sos_received(payload)` and `stage_completed(payload)`.
     - Recorded in `stage_acquisitions["stage1_completed"] = true` and `stage_acquisitions["mining_ship_encountered"] = true`.
     - Stage 2 remains strictly unplayable; no fake Stage 2 scenes or transitions.
  6. **Stage Checkpoint Revive:**
     - Death in Level 5 returns strictly to Stage 1 Level 1 at full 12 HP.
     - All temporary stage acquisitions (telemetry, weapon, shield, stage1_completed) cleared.
- **Status:** **Configurable Baseline / Subject to Lead Review during playtesting.**


---

## 12. Milestone 6 Stage 2 Level 1 Configurable Parameters & Hostile Combat TBDs

- **Mechanic Overview:** Stage 2 Level 1 transitions LAST SIGNAL into horizontal side-scrolling combat, introducing the Guard Bot enemy automaton, aimed enemy projectiles, 15s survival objective, and independent Stage 2 checkpoint revive.
- **Configurable Parameters in Code (`scripts/stage2/stage2_main.gd`, `scripts/enemies/guard_bot.gd`, `scripts/enemies/enemy_projectile.gd`):**
  1. **Arena & Scrolling Tuning:**
     - `@export var scroll_speed: float = 140.0` px/s (horizontal starfield drift speed from right to left).
     - `@export var level_duration: float = 15.0` seconds (confirmed Stage 2 Level 1 survival objective).
  2. **Enemy Spawner Tuning:**
     - `@export var enemy_spawn_interval_min: float = 2.0` seconds.
     - `@export var enemy_spawn_interval_max: float = 3.2` seconds.
     - Spawns Guard Bots at $X = 1320.0\text{ px}$ with randomized $Y \in [80.0, 640.0]\text{ px}$.
  3. **Guard Bot Automaton Parameters:**
     - `@export var max_health: int = 30` (requires 30 player projectile hits or mutual contact).
     - `@export var speed: float = 130.0` px/s (leftward horizontal drift velocity).
     - `@export var contact_damage: int = 1` HP (inflicts 1 damage to player; takes 1 damage in return).
     - `@export var fire_interval_min: float = 1.8` seconds, `@export var fire_interval_max: float = 2.4` seconds.
     - `@export var attack_pose_duration: float = 0.35` seconds (attacking sprite visibility duration).
     - `@export var official_art_enabled: bool = true` (uses official `idle.png` and `attacking.png`).
  4. **Enemy Projectile Parameters:**
     - `@export var speed: float = 300.0` px/s (linear velocity towards player).
     - `@export var damage: int = 1` HP.
     - `@export var lifetime: float = 4.0` seconds.
  5. **Stage 2 Checkpoint & Progression Semantics:**
     - Stage transition restores player HP to full $12\text{ HP}$ ($12/12$).
     - Death in Stage 2 Level 1 revives player strictly at **Stage 2 Level 1** at full $12\text{ HP}$ with weapons active.
     - Surviving 15 seconds displays completion banner; Level 2 cannot start.
- **Status:** **Configurable Baseline / Subject to Lead Review during playtesting.**
