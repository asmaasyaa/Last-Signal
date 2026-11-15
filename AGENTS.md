# AGENTS.md — Development and Review Rules for LAST SIGNAL

This document specifies the mandatory development, architecture, testing, and review rules for AI agents and human contributors working on the **LAST SIGNAL** codebase.

---

## 1. Project Identity & Technical Foundation

- **Project Name:** LAST SIGNAL
- **Engine Version:** Godot Engine 4.7.2 Standard (official Linux/PC build, non-.NET).
- **Primary Language:** GDScript.
- **Target Platform:** PC (Windows / Linux / macOS).
- **Art Direction:** Hand-drawn 2D space aesthetic. Procedural geometric vector/polygon placeholders with custom drawing (`_draw`) are acceptable during prototyping.
- **Milestone Scope:** Strictly implement the currently approved milestone (Milestone 1: Stage 1 Level 1). Do not anticipate or implement future stages or weapons without approval.

---

## 2. Architecture & Communication Conventions

- **Call Down, Signal Up:**
  - **Call Down:** Parent nodes command child nodes directly by invoking public methods or setting properties (e.g., `Main` calling `player.set_physics_process(false)` or `player.reset_state()`).
  - **Signal Up:** Child nodes notify parents and ancestors of state changes via signals (e.g., `player.health_changed`, `player.died`).
  - Do NOT implement "Signal Down, Call Up" or have children directly access or manipulate parent nodes.
- **Node Isolation & Encapsulation:**
  - Scenes must remain modular and testable in isolation.
  - Do not use brittle hardcoded absolute node paths (`/root/...`).
  - Avoid global singletons (autoloads) unless approved by technical leads.
- **Collision & Physics Processing:**
  - Area2D movements and collision handling belong in `_physics_process(delta)`, not variable-framerate `_process(delta)`.
  - Avoid per-frame damage loops and generic invulnerability frames. Contact pair cooldowns must track pairs independently.

---

## 3. Configuration & Parameter Policy

- **Exported Parameters for TBD Values:**
  - Any gameplay balance value that is provisional or subject to lead review must be exposed as an `@export` variable with clear comments and sensible defaults.
  - Examples: `regen_wait` (provisional delay), `stop_threshold` (stationary speed limit), `contact_tick_seconds` (damage tick rate).
- **Document Decisions & TBDs:**
  - Confirmed mechanics belong in `docs/SPECIFICATIONS.md`.
  - Unresolved, provisional, or deferred items must be recorded in `docs/DECISIONS_AND_TBD.md`.
- **Portability:**
  - Do not commit machine-specific paths (e.g. absolute paths to executables or local home directories) into project configuration files.

---

## 4. Verification & Testing Standards

- **Executable Engine Verification:**
  - Validate project loading and script syntax using Godot 4.7.2 headless mode (`--headless --validate --quit` and `--headless --check-only -s <script>`).
- **Automated Test Suite:**
  - Automated tests must be maintained in `tests/` covering:
    1. Player HP damage, clamping, and death signals.
    2. Collision cooldown rate-limiting, separation/re-entry, and multiple simultaneous contacts.
    3. Passive HP regeneration, stationary delay, and movement interruption.
    4. Survival timer progression and game state transitions (Game Over / Level Complete).
    5. Real physics engine collision and overlap integration.
  - **Rule:** Never report a test as passing unless it was actually executed and the exit code/stdout verified.
- **Manual GUI Verification:**
  - Always provide a clear, step-by-step manual testing checklist for visual rendering, mouse control, and interactive feel.

---

## 5. Milestone Boundaries & Review Protocol

- **Preserve Existing Work:**
  - Do not recreate the project from scratch. Improve scenes and scripts incrementally.
  - Do not add external dependencies without explicit approval.
  - Do not initialize or push to a new Git repository without approval.
- **Completion Protocol:**
  - When the milestone requirements are met and tests pass, halt further code changes.
  - Deliver a complete handoff report with diffs, test logs, and instructions.
  - **Wait for external technical review before beginning the next milestone.**

