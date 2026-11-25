# LAST SIGNAL — Integration Readiness Specification

**Document Version:** 1.1 (Milestone 3.6 - Team Asset Integration Batch 01)  
**Status:** IMPLEMENTED & VERIFIED WITH 428 PASSING TESTS  
**Scope:** Stage 1 Levels 1–3 Codebase (`last-signal-starter`)  
**Engine:** Godot Engine 4.7.2 Standard (GDScript)

---

## 1. Overview & Purpose

This document defines the architectural bridge between the verified Stage 1 gameplay prototypes (Levels 1–3) and incoming official art, animation, sound, and narrative assets. 

The primary objective is to guarantee that visual assets, audio cues, and dialogue scripts can be integrated cleanly **without modifying or breaking existing gameplay mechanics, balance variables, or automated regression tests**.

---

## 2. Visual Subtree Isolation Pattern

To eliminate hardcoded rendering inside gameplay controllers, all visual representations are organized into an isolated presentation layer using the **`Visuals` Subtree Pattern**.

### 2.1 Core Architectural Rule
- The root node (`Area2D` or `Node2D`) owns the gameplay script, collision shapes, collision layers/masks, and state variables.
- All visual rendering (sprites, polygons, particles, animation players) is encapsulated in a dedicated child node named `Visuals` (`Node2D`).
- Gameplay logic interacts with `Visuals` solely through public semantic hooks (e.g. triggering an animation or damage flash).
- **Separation of Transform Scales:** Root node scale must always remain `Vector2.ONE`. Visual sprite scaling is handled strictly within the `Visuals` child node, preventing accidental double-scaling or distortion of underlying `CircleShape2D` collision boundaries.

### 2.2 Entity Hierarchy Structure

```
Entity Root (Area2D / Node2D) [Gameplay Script & Collision]
├── CollisionShape2D [Physics Boundaries - CircleShape2D]
└── Visuals (Node2D) [Presentation Layer]
    ├── ProceduralFallback (Node2D) [Visible when no custom sprite is assigned]
    └── Sprite2D / AnimatedSprite2D [Custom Texture / Animations]
```

### 2.3 Procedural Visual Fallback Mechanism
Because official production art is created iteratively, scenes must seamlessly support both procedural placeholders and final sprites:
1. Under `Visuals`, procedural nodes remain intact inside a `ProceduralFallback` branch or default drawing layer.
2. If a custom `Sprite2D` or `AnimatedSprite2D` texture is assigned and active under `Visuals`, the fallback layer is automatically hidden.
3. If no custom sprite is present, the procedural vector graphics render normally.
4. This ensures the game remains fully playable and testable at all times during asset delivery.

---

## 3. Audited Systems & Scope of Refactoring

### 3.1 Milestone 3.5 Limited Refactor Scope
In accordance with Milestone 3.5 constraints, refactoring is strictly limited to:
- **Player Ship:** Decouple `Polygon2D` visual nodes into a `Visuals` child container with automatic sprite detection and procedural fallback.
- **Asteroid (Small, Medium, Large):** Decouple `_draw()` canvas rendering into `Visuals` presentation with tier-based scaling while preserving unique `CircleShape2D` shapes and `scale = Vector2.ONE`.

### 3.2 Deferred Systems (Preserved for Future Milestones)
The following systems remain untouched during Milestone 3.5 and will be refactored when their corresponding assets and mechanics arrive:
- **Communication Satellite:** Retains existing `_draw()` and proximity logic in Stage 1 Level 2.
- **Wrecked Spacecraft:** Retains existing vector presentation and float loop in Level 3.
- **Main Background & Starfield:** Retains existing scrolling star drawing loop in `main.gd`.
- **HUD & UI:** Retains existing `CanvasLayer` labels and debug overlay.
- **Dialogue System:** Remains an architectural interface design (no runtime dialogue system built yet).

---

## 4. Risks & Compatibility Guidelines

1. **Collision Shape & Art Alignment:**
   - Visual silhouettes are not required to fit 100% inside collision circles. Stylistic elements (wings, antennae, thruster cones, rock ridges) may extend slightly beyond.
   - During integration, developers must enable **Debug -> Visible Collision Shapes** in Godot to visually review gameplay fairness and feel.
2. **Automated Test Immunity:**
   - Existing automated test suites (Milestones 1, 2, and 3) must continue to pass with 0 failures.
   - Root entity properties (`health`, `movement_velocity`, `contact_cooldown`, `speed`, `collision_shape.shape.radius`) must not change names, types, or behaviors.
3. **Texture Filtering:**
   - Hand-drawn vector / digital painted textures must use `Linear` texture filtering (`CanvasItem.TEXTURE_FILTER_LINEAR`). Pixel art (if specified) should use `Nearest`.

---

## 5. Milestone 3.6 Implementation Results (Batch 01 Art Integration)

Milestone 3.6 successfully integrated the first delivery of official team visual assets without regressing any gameplay mechanics:

1. **Player Official Art Integration:**
   - Integrated `player_alive.png` ($256 \times 256$) and `player_dead.png` ($264 \times 264$) into `player.tscn` under `Visuals/OfficialArt`.
   - Scaled visually to $0.2 \times 0.2$ ($\approx 51.2\text{px}$) inside the visual subtree, preserving the $r = 20.0\text{px}$ `CircleShape2D` physics radius and `scale = Vector2.ONE`.
   - Automatic visual switching: `AliveSprite` displays while `alive == true`; `DeadSprite` activates on death (`died` signal / HP = 0); `AliveSprite` restores upon checkpoint revive (`prepare_for_level` or `reset_state`).
   - Procedural vector fallback is automatically preserved and reactivates if official art is disabled or textures are missing.
2. **Modular Menu Architecture:**
   - Implemented `scenes/ui/main_menu.tscn` and `scripts/ui/main_menu.gd` with official Start, Select, and Exit button textures.
   - Implemented `scenes/ui/level_select.tscn` and `scripts/ui/level_select.gd` with official level buttons for Stages 1–3.
   - Preserved progression safety: Only Stage 1 Level 1 may start a normal gameplay run from Level Select; Levels 2–3 remain accessible through normal gameplay progression from Level 1; all other stages/levels are disabled/locked and display clear status notices without crashing or enabling unintended transitions.
   - Direct execution of `scenes/main.tscn` remains intact for automated tests and standalone verification.
3. **Anomaly Handling:**
   - Resolved the $1920 \times 1080$ canvas anomaly on `Stage 2 L3.png` via non-destructive runtime crop derivative `stage2_l3_cropped.png` ($737 \times 84\text{px}$), keeping original file intact.
4. **Automated Verification:**
   - Milestone 1: 87/87 tests passed
   - Milestone 2: 73/73 tests passed
   - Milestone 3: 81/81 tests passed
   - Milestone 3.5: 56/56 tests passed
   - Milestone 3.6: 138/138 tests passed
   - **Total:** 435 passing tests across all test suites with 0 regressions.

---

## 6. Milestone 3.7 Implementation Results (Batch 02 Art Integration)

Milestone 3.7 integrated the official Communication Satellite asset from Batch 02 while maintaining all previously accepted gameplay systems:

1. **Communication Satellite Official Art Integration:**
   - Integrated `commsatt.png` ($602 \times 336\text{px}$) into `scenes/satellite.tscn` under `Visuals/OfficialArt/Sprite2D`.
   - Scaled visually to $0.22 \times 0.22$ ($\approx 132.4 \times 73.9\text{px}$) inside the visual subtree, preserving the $80.0\text{px}$ proximity detection radius (`CircleShape2D`) and keeping root `scale = Vector2.ONE`.
   - Proximity radius arc and dual extraction progress rings render on an overlay `Indicator` node ($z=2$) above the sprite, ensuring extraction feedback remains crisp and unobstructed.
   - Procedural vector fallback is encapsulated in `Visuals/ProceduralFallback` (`scripts/satellite_visual.gd`) and reactivates automatically if official art is disabled or texture is missing.
   - All Stage 1 Level 2 gameplay mechanics preserved: drift speed $100.0\text{ px/s}$, extraction accumulation time $1.8\text{s}$, decrypted telemetry payload emission, and strict level completion independence (satellite remains fully optional).
2. **Stage 2 Guard Assets Staged & Reserved:**
   - Imported 6 guard enemy sprites (Bot, Satellite, Drone in both idle and attacking states) into `res://assets/sprites/enemies/`.
   - Explicitly reserved for Stage 2 without creating premature AI, attacks, or combat systems.
3. **Nirawak 1 Assets Staged Without Assumptions:**
   - Staged `before_extraction.png` and `after_extraction.png` in `res://assets/sprites/npc/nirawak1/`.
   - Documented as AWAITING TEAM CONFIRMATION regarding narrative event and level mapping; existing Level 3 wrecked spacecraft visuals remain unaffected.
4. **Regression Immunity:**
   - 435 baseline tests across Milestones 1–3.6 pass with zero regressions.



---

## 7. Milestone 4 Projectile Visual Integration Readiness

Milestone 4 introduces the reusable projectile system (`scenes/projectile.tscn`) for the twin-barrel primary pulse cannon, designed in full compliance with the `Visuals` subtree isolation pattern:

1. **Projectile Visual Architecture (`scenes/projectile.tscn`):**
   - **Root Node (`Area2D`):** Script `scripts/projectile.gd` manages collision detection, speed ($750\text{ px/s}$), damage ($1\text{ HP}$), boundary cleanup, and despawn lifecycle.
   - **Collision Geometry:** `CapsuleShape2D` (radius $3.0\text{ px}$, height $14.0\text{ px}$) on Collision Layer 4 (bitmask 4, Layer 3: Player Projectiles) and Collision Mask 2 (Layer 2: Asteroids).
   - **Presentation Layer (`Visuals` Node2D):** All rendering is strictly isolated within the `Visuals` child container.
   - **Procedural Energy Bolt (`Visuals/ProceduralFallback`):** Script `scripts/projectile_visual.gd` draws a bright cyan/white pulse bolt with glowing aura (`_draw`):
     - Outer glow: Capsule with radius $6\text{ px}$, height $18\text{ px}$ (`Color(0.2, 0.7, 1.0, 0.45)`).
     - Inner core bolt: Capsule with radius $2.5\text{ px}$, height $12\text{ px}$ (`Color(0.85, 0.95, 1.0, 1.0)`).
     - Forward tip spark: Circle with radius $2.0\text{ px}$ at leading edge.
   - **Seamless Art Integration Ready:** When official blaster bolts or pulse effects are delivered, inserting `Visuals/OfficialArt/Sprite2D` or `AnimatedSprite2D` automatically suppresses the procedural fallback without altering projectile physics, speed, or collision checks.
2. **Automated Verification Baseline:**
   - 678 total automated tests across 7 test suites (Milestones 1, 2, 3, 3.5, 3.6, 3.7, 4) passing with 0 failures.


---

## 8. Milestone 6: Stage 2 Level 1 Art Integration Results

Milestone 6 integrated the first hostile security automaton artwork from Batch 02 into the active gameplay runtime:

1. **Guard Bot Official Artwork Integration (`scenes/enemies/guard_bot.tscn`):**
   - **Delivered Sprites:** `assets/entities/guards/bot/idle.png` ($256 \times 256\text{ px}$) and `assets/entities/guards/bot/attacking.png` ($256 \times 256\text{ px}$).
   - **Visual Subtree Isolation:** Integrated into `scenes/enemies/guard_bot.tscn` under `Visuals/OfficialArt/IdleSprite` and `Visuals/OfficialArt/AttackingSprite`.
   - **Scale & Orientation:** Scaled to $0.45 \times 0.45$ ($\approx 115 \times 115\text{ px}$) and rotated $-90^\circ$ to face leftward toward the player in the side-scrolling orientation. Root node maintains `scale = Vector2.ONE`.
   - **State Switching:** `IdleSprite` displays during normal drift; `AttackingSprite` dynamically triggers for $0.35\text{s}$ upon firing aimed energy projectiles.
   - **Procedural Fallback:** `Visuals/ProceduralFallback` (`scripts/enemies/guard_bot_visual.gd`) features a geometric armored octagon with glowing red optical sensor and weapon pod, cleanly hidden when official art is active.
2. **Enemy Projectiles Visual Readiness (`scenes/enemies/enemy_projectile.tscn`):**
   - Procedural glowing plasma energy bolt (`Visuals/ProceduralFallback`) draws a luminous amber/red energy sphere with trailing plasma corona.
   - Official art slot prepared under `Visuals/OfficialArt/Sprite2D`.
3. **Automated Verification Baseline:**
   - 963 total automated assertions across 9 test suites (Milestones 1, 2, 3, 3.5, 3.6, 3.7, 4, 5, 6) passing with 0 failures.


---

## 9. Milestone 7: Stage 2 Level 2 Art Integration Results

Milestone 7 integrated the official Guard Satellite artwork from Batch 02 into active gameplay:

1. **Guard Satellite Official Artwork Integration (`scenes/enemies/guard_satellite.tscn`):**
   - **Delivered Sprites:** `assets/sprites/enemies/guard_satellite/guard_satellite_idle.png` ($347 \times 267\text{ px}$) and `guard_satellite_attacking.png` ($347 \times 267\text{ px}$).
   - **Visual Subtree Isolation:** Integrated into `scenes/enemies/guard_satellite.tscn` under `Visuals/OfficialArt/IdleSprite` and `Visuals/OfficialArt/AttackingSprite`.
   - **Scale & Orientation:** Scaled to $0.35 \times 0.35$ ($\approx 121 \times 93\text{ px}$) and rotated $-90^\circ$ to face leftward. Root node maintains `scale = Vector2.ONE`.
   - **Dynamic State Switching:** `IdleSprite` displays during normal drift and cooldown; `AttackingSprite` dynamically triggers during the laser firing phase.
   - **Procedural Fallback:** `Visuals/ProceduralFallback` (`scripts/enemies/guard_satellite_visual.gd`) features an armored chassis with dual solar array wings and a glowing optical emitter.
2. **Procedural Laser VFX Architecture (`scripts/enemies/guard_satellite_laser_visual.gd`):**
   - Renders a warning telegraph aiming line during preparation ($0.5\text{s}$) and a multi-layered glowing energy beam during firing ($0.15\text{s}$).
   - Documented as interim procedural visual layer until dedicated beam VFX textures/shaders are delivered.
3. **Automated Verification Baseline:**
   - 1,116 total automated assertions across 10 test suites (Milestones 1 through 7) passing with 0 failures.


---

## 10. Milestone 8: Stage 2 Level 3 Art Integration Results

Milestone 8 integrated the official Guard Drone artwork from Batch 02 into active gameplay:

1. **Guard Drone Official Artwork Integration (`scenes/enemies/guard_drone.tscn`):**
   - **Delivered Sprites:** `assets/sprites/enemies/guard_drone/guard_drone_idle.png` ($152 \times 316\text{ px}$) and `guard_drone_attacking.png` ($151 \times 316\text{ px}$).
   - **Visual Subtree Isolation:** Integrated into `scenes/enemies/guard_drone.tscn` under `Visuals/OfficialArt/IdleSprite` and `Visuals/OfficialArt/AttackingSprite`.
   - **Scale & Orientation:** Scaled to $0.35 \times 0.35$ ($\approx 53 \times 110\text{ px}$) and rotated $-90^\circ$ to face leftward toward the player in the side-scrolling orientation. Root node maintains `scale = Vector2.ONE`.
   - **Dynamic State Switching:** `IdleSprite` displays during the approach phase; `AttackingSprite` dynamically triggers during telegraph lock-on and high-speed kamikaze charge.
   - **Procedural Fallback:** `Visuals/ProceduralFallback` (`scripts/enemies/guard_drone_visual.gd`) features a sleek arrowhead interceptor hull with rear thruster exhaust flare and forward glowing optical sensor / charge corona.
2. **Attributed Destruction Integration:**
   - Visual presentation cleanly supports all 4 destruction reasons (`PLAYER_WEAPON`, `KAMIKAZE_IMPACT`, `OFFSCREEN_DESPAWN`, `LEVEL_CLEANUP`) with immediate collision shape deactivation, single-hit damage protection, and node freeing.
3. **Automated Verification Baseline:**
   - 1,282 total automated assertions across 11 test suites (Milestones 1 through 8) passing with 0 failures.

---

## 11. Milestone 9: Stage 2 Level 4 Guard Cruiser Phase 1 & EM Jammer Integration Results

Milestone 9 integrates the official Phase 1 Guard Cruiser mini-boss artwork from Batch 01 into active gameplay:

1. **Guard Cruiser Mini-Boss Official Artwork Integration (`scenes/bosses/guard_cruiser.tscn`):**
   - **Delivered Sprites:**
     - Active: `assets/sprites/bosses/stage2_miniboss/miniboss_alive_p1.png` ($601 \times 321\text{ px}$).
     - Staged & Reserved: `miniboss_alive_p2.png` ($601 \times 321\text{ px}$) and `miniboss_dead.png` ($601 \times 321\text{ px}$).
   - **Visual Subtree Isolation:** Integrated into `scenes/bosses/guard_cruiser.tscn` under `Visuals/OfficialArt/Phase1Sprite`. `Phase2Sprite` and `DeadSprite` are staged under the same container, strictly hidden and reserved for Phase 2 and defeat in future milestones.
   - **Scale & Orientation:** Scaled to $0.4 \times 0.4$ ($\approx 240.4 \times 128.4\text{ px}$) and rotated $\pi$ ($180^\circ$) so the cruiser's heavy prow faces South toward the player in the arcade arena. Root `Area2D` maintains neutral scale `Vector2.ONE`.
   - **Hitbox Alignment:** Central hull collision shape is `RectangleShape2D(230.0, 110.0)`, closely matching the scaled sprite footprint without overlapping empty transparent margins.
   - **Procedural Fallback:** `Visuals/ProceduralFallback` (`scripts/bosses/guard_cruiser_visual.gd`) features a geometric armored capital hull with twin warp nacelles, glowing bridge, and dynamic electrical stun arc overlays.
2. **EM Jammer Visual Wave Presentation (`scripts/equipment/em_jammer_controller.gd`):**
   - Expanding $120^\circ$ circular arc pulse wave in cyan/electric blue rendered via custom `_draw` for $0.35\text{s}$ along the player's firing vector.
   - Zero damage guarantee verified by automated test assertions.
3. **Automated Verification Baseline:**
   - 1,451 total automated assertions across 12 test suites (Milestones 1 through 9) passing with 0 failures.

---

## 12. Milestone 10: Stage 2 Level 5 Guard Cruiser Phase 2 & Defeat Art Integration Results

Milestone 10 activates the remaining official Guard Cruiser artwork from Batch 01, completing the full visual lifecycle of the Stage 2 mini-boss encounter:

1. **Guard Cruiser Phase 2 & Defeat Official Artwork Integration (`scenes/bosses/guard_cruiser.tscn`):**
   - **Delivered Sprites:**
     - Phase 1: `assets/sprites/bosses/stage2_miniboss/miniboss_alive_p1.png` ($601 \times 321\text{ px}$) — active during Level 4.
     - Phase 2: `assets/sprites/bosses/stage2_miniboss/miniboss_alive_p2.png` ($601 \times 321\text{ px}$) — **ACTIVE / OPERATIONAL** during Level 5 ($200 \to 0\text{ HP}$).
     - Defeat: `assets/sprites/bosses/stage2_miniboss/miniboss_dead.png` ($601 \times 321\text{ px}$) — **ACTIVE / OPERATIONAL** upon reaching $0\text{ HP}$ and on the victory screen.
   - **Mutual Exclusivity:** `update_visual_state()` in `scripts/bosses/guard_cruiser.gd` guarantees strict mutual exclusivity:
     - Phase 1: `Phase1Sprite` visible, `Phase2Sprite` hidden, `DeadSprite` hidden.
     - Phase 2: `Phase1Sprite` hidden, `Phase2Sprite` visible, `DeadSprite` hidden.
     - Defeated: `Phase1Sprite` hidden, `Phase2Sprite` hidden, `DeadSprite` visible.
   - **Scale, Rotation & Alignment:** All three sprites share identical scale ($0.4 \times 0.4$, $\approx 240.4 \times 128.4\text{ px}$) and rotation ($\pi$, $180^\circ$) facing South. Physics root scale remains strictly `Vector2.ONE`.
   - **Procedural Fallback Continuity:** `Visuals/ProceduralFallback` (`scripts/bosses/guard_cruiser_visual.gd`) features Phase 2 amber hull plating with active reactor flares, and upon defeat shifts to a shattered, smoking dark hull silhouette.
2. **Full Batch 01 Stage 2 Mini-Boss Coverage Achieved:**
   - All 3 delivered mini-boss sprites from Batch 01 are now fully connected, active, and operational in runtime gameplay.
3. **Automated Verification Baseline:**
   - 1,614 total automated assertions across 13 test suites (Milestones 1 through 10) passing with 0 failures.
