# LAST SIGNAL — Narrative & Dialogue Interface Specification

**Document Version:** 1.0 (Milestone 3.5)  
**Status:** SPECIFICATION & INTERFACE CONTRACT  
**Target:** Decoupled Event-Driven Dialogue Integration

---

## 1. Canonical Status of Existing Narrative Details

> [!CAUTION]
> All AI-generated names, vessel designations, equipment descriptions, and story text created during early prototyping are **NON-CANONICAL / PLACEHOLDERS**.
>
> Official writing, character lore, story scripts, and faction names are strictly owned by the creative and writing team.

### Audit of Prototyping Placeholders:
| Identifier / Element | Prototyping Value in Code | Status | Integration Plan |
| :--- | :--- | :--- | :--- |
| **Wrecked Craft Name** | `"Wrecked Scout Craft (Surveyor-7)"` | **NON-CANONICAL** | Strip "Surveyor-7"; replace with official designation when confirmed. |
| **Equipment Names** | `"Twin-barrel Pulse Cannon"`, `"Deflector Shield Generator"` | **PROVISIONAL** | Subject to confirmation by technical/design lead. |
| **Satellite Telemetry Text** | `"[DECRYPTED TELEMETRY] Unidentified mining vessel..."` | **NON-CANONICAL** | Replace with official narrative script upon delivery. |
| **Telemetry Notice** | `"[DATA RECOVERED: Encrypted telemetry packet stored]"` | **UI PLACEHOLDER** | Migrate to localized UI notification system. |
| **Level Win / Death Strings** | Multiline plaintext in `main.gd` | **UI PLACEHOLDER** | Migrate to themed UI / dialogue modal sequences. |

---

## 2. Gameplay Events Inventory: Implemented vs. Proposed Hooks

To ensure developers and writers know exactly where dialogue can attach, this inventory delineates signals that already exist in code versus proposed future triggers.

### 2.1 Existing Implemented Gameplay Signals & State Transitions
These events exist and fire reliably in the current codebase:

| Signal / State Transition | Origin Node / Script | Existing Parameters / Data |
| :--- | :--- | :--- |
| `health_changed(current, maximum)` | `Player` (`player.gd`) | `current: int`, `maximum: int` |
| `died` | `Player` (`player.gd`) | None |
| `extraction_started` | `Satellite` (`satellite.gd`) | None |
| `extraction_progress_changed(progress)`| `Satellite` (`satellite.gd`) | `progress: float` ($0.0 \dots 1.0$) |
| `extracted(payload)` | `Satellite` (`satellite.gd`) | `payload: Dictionary` (`{"id": "...", ...}`) |
| `equipment_acquired(equipment_data)` | `Main` (`main.gd`) | `equipment_data: Dictionary` |
| `start_level(target_level, starting_hp)`| `Main` (`main.gd`) | `target_level: int`, `starting_hp: int` |
| `_complete_level()` | `Main` (`main.gd`) | Triggered when `time_remaining <= 0.0` |

### 2.2 Proposed Semantic Dialogue Event Hooks (Interface Design)
These stable event IDs will be dispatched to the dialogue system when implemented:

- `stage1_l1_briefing`: Dispatched upon starting Stage 1 Level 1 (mission introduction).
- `stage1_l1_cleared`: Dispatched upon surviving Level 1 (30s complete).
- `stage1_l2_briefing`: Dispatched upon entering Stage 1 Level 2.
- `stage1_l2_satellite_ping`: Dispatched when satellite spawns into the sector ($T = 20\text{s}$).
- `stage1_l2_satellite_extracted`: Dispatched when satellite proximity extraction finishes.
- `stage1_l2_satellite_missed`: Dispatched if satellite drifts off-screen unextracted.
- `stage1_l2_cleared`: Dispatched upon surviving Level 2.
- `stage1_l3_briefing`: Dispatched upon entering deep belt (Level 3).
- `stage1_l3_wreck_spotted`: Dispatched when wrecked craft appears at Level 3 completion.
- `stage1_l3_equipment_secured`: Dispatched when primary weapon and shield are acquired.
- `player_hull_breached`: Dispatched upon player death.

---

## 3. External Dialogue Data Schema

Dialogue content will be authored in external JSON files located in `assets/data/dialogue/` (e.g. `stage1_dialogue.json`).

### Schema Structure:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "version": "1.0",
  "events": {
    "stage1_l2_satellite_extracted": [
      {
        "speaker_id": "ship_ai",
        "speaker_display_name": "ONBOARD AI",
        "portrait": "res://assets/sprites/portraits/ai_neutral.png",
        "dialogue_text": "Signal handshake established. Telemetry buffer downloaded and decrypted.",
        "duration": 3.5,
        "audio_cue": "res://assets/audio/sfx/telemetry_chime.wav",
        "interruptible": true
      }
    ]
  }
}
```

---

## 4. Development Warning & Runtime Graceful Fallback Policy

To ensure robust behavior across both development and production builds:

1. **Development Mode Reporting:**
   - In debug builds (`OS.is_debug_build()`), if an event ID is requested but not found in the dialogue database, the dialogue manager must output an explicit warning to the console:
     ```
     [DIALOGUE WARNING] Missing dialogue event ID: 'stage1_l2_satellite_extracted'. Continuing without dialogue.
     ```
   - This ensures writers and designers immediately detect typos or unmapped event IDs during testing.
2. **Runtime Graceful Fallback:**
   - The dialogue manager must **never crash, assert-fail, or halt the game** when an event ID, speaker portrait, or audio file is missing.
   - If an event is missing, the manager safely no-ops and allows gameplay to proceed uninterrupted.
   - If an audio file or portrait texture is missing, the text is displayed with a blank portrait or silent audio.

