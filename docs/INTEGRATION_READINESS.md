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


