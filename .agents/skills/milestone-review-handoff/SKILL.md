---
name: milestone-review-handoff
description: Use when preparing an auditable technical handoff report and review summary upon completing a development milestone for LAST SIGNAL.
---

# Milestone Review Handoff Skill — LAST SIGNAL

This skill guides the preparation of a complete, auditable technical handoff report when a project milestone is completed.

---

## 1. Handoff Protocol & Structure

When preparing a milestone handoff, structure the final delivery into the following 10 mandatory sections:

### 1. Milestone Identification & Criteria
- Name the milestone being completed (e.g., "Milestone 1: Stage 1 Level 1").
- List each approved requirement and acceptance criterion.

### 2. Specification Compliance Check
- Compare the implemented features directly against `docs/SPECIFICATIONS.md`.
- Explicitly confirm that game mechanics follow documented rules.

### 3. Inventory of Files
- Provide a clean list of all:
  - **Created files** (with clickable file links).
  - **Modified files**.
  - **Deleted files** (if any).

### 4. Architecture & Design Rationale
- Explain the key architectural patterns used:
  - Application of the "Call Down, Signal Up" communication pattern.
  - Component isolation and decoupling between gameplay entities and UI.
  - State management, timer loops, and collision rate-limiting implementations.

### 5. Scope Boundary Analysis
- Explicitly state whether any changes occurred outside the approved milestone scope.
- Confirm that future stages, unapproved weapons, or unapproved features were NOT introduced.

### 6. Executed Test Evidence & Logs
- Present the actual command outputs and test execution results.
- Show test suite breakdown (total executed, passed, failed).
- Report only tests that were actually executed.

### 7. Known Issues, Technical Debt & Unresolved Decisions
- Document any known defects, visual limitations, or deferred polish.
- Reference `docs/DECISIONS_AND_TBD.md` for provisional parameters awaiting lead sign-off.

### 8. Manual Gameplay Verification Checklist
- Provide step-by-step instructions for running the project in the Godot GUI.
- Include a checklist of observable behaviors for interactive validation.

### 9. Code Changes / Diff Summary
- Provide a unified diff (`diff -u`) or clear file-by-file patch of all modifications.
- If Git is not initialized, generate a unified diff comparing changes against original versions.

### 10. Explicit Milestone Status
Conclude with one of the three explicit statuses:
- **`READY FOR REVIEW`**: All milestone acceptance criteria met, all tests passing, ready for external lead evaluation.
- **`NEEDS FIXES`**: Specific criteria failed or defects remain unaddressed.
- **`BLOCKED`**: Progress halted by external dependency, missing approval, or engine limitation.

---

## 2. Hard Stop Protocol

- **Do NOT begin the next milestone automatically.**
- **Do NOT push, merge, or create new branches.**
- Once the handoff report is presented, stop execution and await external review and approval.

