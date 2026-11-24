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

---

## 5. Stage 1 Level 5 & Stage 1 Completion Semantic Event Hooks

With Milestone 5 implemented, the following additional narrative event hooks are established for future dialogue integration:

### 5.1 Mining Satellite Telemetry Extraction

| Event ID | Trigger Condition | Source Entity | Proposed Narrative Purpose | Status |
| :--- | :--- | :--- | :--- | :--- |
| `stage1_l5_mining_satellite_spawned` | Mining survey satellite spawns at $T \le 20\text{s}$ | `MiningSatellite` | Sensor warning of nearby automated industrial beacon | PROPOSED |
| `stage1_l5_mining_satellite_extracted` | Player maintains proximity for 1.8s | `MiningSatellite` | Telemetry packet decrypted: sector mining survey and distress clues | IMPLEMENTED (Signal) |
| `stage1_l5_mining_satellite_missed` | Satellite drifts past $Y > 780\text{px}$ without extraction | `Main` | Navigation computer notes missed survey beacon | PROPOSED |

### 5.2 Damaged Mining Vessel & Stage 1 Completion

| Event ID | Trigger Condition | Source Entity | Proposed Narrative Purpose | Status |
| :--- | :--- | :--- | :--- | :--- |
| `stage1_l5_sos_received` | 30s survived in Level 5; mining ship encountered | `Main` / `DamagedMiningShip` | Automated SOS transmission intercepted; distress beacon indicates survivors or cargo ahead | IMPLEMENTED (Signal) |
| `stage1_completed` | Stage 1 Level 5 survival complete | `Main` | Pilot acknowledges exit from Belt into Inner Sector (Stage 2 transition setup) | IMPLEMENTED (Signal) |

### 5.3 Payload Schemas for Level 5 Narrative Events

```json
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

```json
{
  "event_id": "stage1_completed",
  "stage": 1,
  "levels_cleared": 5,
  "next_stage": 2,
  "next_stage_available": false
}
```

> [!IMPORTANT]
> All AI-generated narrative descriptions, distress message logs, and ship identifiers remain **NON-CANONICAL PLACEHOLDERS** until approved by official project narrative leads.


---

## 6. Stage 2 Level 1 Semantic Dialogue Event Hooks (Milestone 6)

With Milestone 6 introducing hostile security automata, the following semantic event IDs are available for dialogue system integration:

| Event ID | Trigger Timing | Associated Payload / Context |
| :--- | :--- | :--- |
| `stage2_l1_incursion_started` | Stage 2 Level 1 startup / entry from Stage 1 | Sector inner perimeter coordinates, 15s survival objective |
| `stage2_l1_guard_bot_contact` | First Guard Bot spawn or proximity | Automaton scan alert, weapons hot authorization |
| `stage2_l1_guard_bot_destroyed` | Guard Bot destroyed by player | Combat kill confirmation, telemetry feedback |
| `stage2_l1_completed` | Surviving 15s sector incursion | Sector breach cleared, perimeter defenses bypassed |

> [!NOTE]
> Like Stage 1 events, all Stage 2 narrative content remains non-canonical stubs until authored and approved by project writing leads.


---

## 7. Stage 2 Level 2 Semantic Dialogue Event Hooks (Milestone 7)

With Milestone 7 introducing Guard Satellites and accurate laser combat, the following semantic event IDs are available for future dialogue and narrative sequencing:

| Event ID | Trigger Timing | Associated Payload / Context |
| :--- | :--- | :--- |
| `stage2_l2_started` | Stage 2 Level 2 entry / progression from Level 1 | Deep perimeter sector coordinates, 20s survival objective |
| `stage2_l2_guard_satellite_encountered` | First Guard Satellite spawn or radar ping | Optical tracking warning, laser grid active alert |
| `stage2_l2_laser_fired` | Guard Satellite laser discharge | High-energy optical beam firing event |
| `stage2_l2_completed` | Surviving 20s satellite defense grid | Satellite perimeter bypassed, stage progression waypoint |

> [!NOTE]
> All Stage 2 Level 2 narrative triggers remain non-canonical stubs pending official creative writing deliverables.
