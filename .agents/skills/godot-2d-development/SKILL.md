---
name: godot-2d-development
description: Use when implementing, modifying, or refactoring 2D gameplay features, nodes, scripts, or scenes in Godot 4.7.2 GDScript for LAST SIGNAL.
---

# Godot 2D Development Skill — LAST SIGNAL

This skill provides guidelines and procedures for implementing and modifying 2D gameplay features in Godot 4.7.2 Standard using maintainable GDScript and modular scenes.

---

## 1. Pre-Implementation Inspection

Before creating or altering any file:
1. **Inspect Existing Files:**
   - Review relevant `.gd` scripts, `.tscn` scenes, `.tres` resources, and `project.godot`.
   - Never assume node structure or property names; read the existing scene tree hierarchy.
2. **Review Project Specifications & Rules:**
   - Check `AGENTS.md` for project architecture rules and milestone constraints.
   - Check `docs/SPECIFICATIONS.md` for confirmed gameplay rules and numbers.
   - Check `docs/DECISIONS_AND_TBD.md` for unresolved or provisional parameters.
3. **Preserve Team Work:**
   - Improve existing scenes and scripts incrementally; do not rewrite working systems or recreate scenes from scratch.
   - Preserve comments, docstrings, and existing working node layouts.

---

## 2. Architecture & Communication Patterns

### Call Down, Signal Up
Strictly follow the hierarchical communication rule:
- **Call Down (Parent $\to$ Child):**
  - Parents command child nodes directly by invoking public methods or setting properties.
  - Example: `Main` calls `player.set_physics_process(false)` or `player.reset_state()`.
- **Signal Up (Child $\to$ Parent):**
  - Children notify parents and ancestors of state changes via signals.
  - Example: `Player` emits `health_changed(current, maximum)` and `died()`.
- **Never Call Up:** Children must never reach into parent nodes via brittle paths (`get_parent().get_parent()`, `get_node("/root/...")`).

### Loose Coupling
Decouple distinct gameplay domains:
- **Player & Input:** Ship controller reads input or mouse positions, updates its own velocity/heading, and manages health state. It does NOT manipulate the HUD directly.
- **HUD & UI:** UI components listen to signals (`health_changed`, `died`) or receive updates from a scene coordinator (`Main`).
- **Enemies & Hazards:** Hazard entities (e.g. Asteroids) expose read-only attributes (e.g., `contact_damage`). Damage resolution is handled through clean collision layers/masks without tightly coupling asteroid logic to player internals.

### Safe Scene References
- Use `@onready var node_name = $NodePath` for internal child nodes.
- Guard node access with `is_instance_valid(node)` before operating on nodes that could be freed or deferred.

---

## 3. GDScript Standards (Godot 4.7.2 Standard)

- **Static Typing:** Always prefer statically typed GDScript for variables, parameters, and return values:
  ```gdscript
  @export var max_health: int = 12
  @export var move_speed: float = 500.0

  func take_damage(amount: int) -> void:
  ```
- **Physics vs. Render Processing:**
  - Movement, velocity calculations, and collision handling for `Area2D` or `CharacterBody2D` MUST reside in `_physics_process(delta: float)`, not variable-framerate `_process(delta: float)`.
  - Purely cosmetic visual effects (e.g. background star parallax, scrolling textures, screen shake) belong in `_process(delta: float)` or `_draw()`.
- **Godot 4 APIs:**
  - Use `instantiate()` (not Godot 3's `instance()`).
  - Use `queue_free()` for safe node deletion.
  - Use `Vector2.limit_length()`, `clampf()`, `mini()`, `maxi()`.
  - Use `PackedVector2Array` for polygons and points.

---

## 4. Architectural Categorization

When designing or implementing code, clearly distinguish between the three architectural tiers:

1. **Reusable Systems:**
   - Independent components or generic mechanics that can apply across multiple entities or stages (e.g. contact pair cooldown tracking, health/damage calculators, boundary clampers).
2. **Level-Specific Mechanics:**
   - Logic specific to an individual level or stage rule set (e.g. 30-second survival countdown timer, level win/loss conditions, stage-specific spawn rates).
3. **Presentation & UI Features:**
   - Visual and audio presentation layers (e.g. HUD text formatting, CanvasLayers, procedural vector drawing via `_draw()`, engine flame animations).

---

## 5. Parameter Policy & Milestone Boundary

- **Exported Parameters for TBD Values:**
  - Any balance value that is provisional or subject to lead review must be exposed as an `@export` variable with clear comments and sensible defaults (e.g., `@export var regen_wait: float = 2.0`).
  - Record the item and its status in `docs/DECISIONS_AND_TBD.md`.
- **Milestone Scope Discipline:**
  - Implement ONLY the approved milestone requirements.
  - Never implement future weapons, shields, secondary mechanics, or extra stages without prior approval.

