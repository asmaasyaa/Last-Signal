# LAST SIGNAL — Asset Requests & Technical Feedback for Art Team (Batch 02)

**Document Version:** 1.0 (Milestone 3.6)  
**Target Milestone:** Batch 02 Delivery  
**Engine Reference:** Godot Engine 4.7.2 Standard  
**Viewport Reference:** $1280 \times 720\text{ px}$ (16:9 2D space environment)

---

## 1. Appreciation & Batch 01 Integration Summary

Thank you to the art team for the delivery of **Batch 01** (`Komgraf — Teh Hijau`).

We have successfully integrated the following assets into the active gameplay and UI architecture:
- **Player Ship (`alive.png`, `dead.png`):** Integrated into `player.tscn` with automatic visual state switching on death and checkpoint revive, perfectly preserving the 20 px collision radius.
- **Main Menu UI (`start btn.png`, `select btn.png`, `exit btn.png`):** Integrated into a modular Main Menu scene with full keyboard/mouse navigation.
- **Level Select UI (`Stage 1-3 / L1-L5`):** Integrated into a mission sector map with playable access starting at Stage 1 Level 1, progression gating for Levels 2–3, and protection for locked/unimplemented stages.
- **Boss & Mini-Boss Sprites:** Cataloged and staged cleanly in `res://assets/sprites/bosses/` reserved for later stages (Stage 2 mini-boss and Stage 3 boss; Milestone 4 is Stage 1 Level 4 introducing twin-barrel shooting).

---

## 2. Technical Feedback on Delivered Assets

### 2.1 Stage 2 Level 3 Button Canvas Anomaly (Action Required: High)
- **Delivered Asset:** `assets/UI HUI/stage btn/Stage 2/L3.png`
- **Observed Issue:** The image was exported on a full $1920 \times 1080$ canvas rather than cropped tightly to the button graphic.
- **Bounding Box Found:** The actual button graphic occupies $(X: 518\text{ to } 1255, Y: 409\text{ to } 493)$, yielding dimensions of $737 \times 84\text{ px}$.
- **Interim Engineering Fix:** A non-destructive crop derivative (`stage2_l3_cropped.png`) was created and connected to the UI so the layout functions without distortion.
- **Request to Artist:** Please re-export `Stage 2 L3.png` cropped tightly to its non-transparent bounding box, matching the dimensions of the other Stage 2 buttons (approximately $370 \times 75\text{ px}$), on a transparent RGBA background.

### 2.2 Player Ship Orientation & Quality (Validated: Excellent)
- **Delivered Assets:** `player/alive.png` ($256 \times 256$), `player/dead.png` ($264 \times 264$)
- **Orientation:** The ship was drawn facing straight UP (North / $-Y$). This perfectly matches Godot's flight controller calculation (`rotation = Vector2.UP.angle_to(movement_velocity)`), requiring zero rotation offset.
- **Scale Factor:** At a visual scale factor of $0.2 \times 0.2$ ($\approx 51.2\text{ px}$ visual length), the hull fits the 20 px radius collision circle ($40\text{ px}$ diameter) cleanly while allowing wing edges to protrude naturally.

---

## 3. Prioritized Asset Requests for Batch 02

To achieve complete visual fidelity for currently implemented gameplay (Stage 1 Levels 1–3) without procedural polygon fallbacks, the following assets are requested for Batch 02:

### Priority P0 — Critical Gameplay Blockers (Stage 1 Entities)
These assets directly replace existing procedural geometry in active levels.

| Entity / Asset | Quantity / Variants | Target Canvas Size | Matching Collision | Visual Orientation & Notes | Assigned Owner |
| :--- | :---: | :---: | :---: | :--- | :---: |
| **Small Asteroid** | 2–3 variants | $48 \times 48\text{ px}$ | `CircleShape2D` ($r = 19.0\text{px}$) | Non-directional irregular rock; will have runtime spin applied. | UNASSIGNED / TEAM TO CONFIRM |
| **Medium Asteroid** | 2 variants | $96 \times 96\text{ px}$ | `CircleShape2D` ($r = 35.0\text{px}$) | Cratered rock profile; will have runtime spin applied. | UNASSIGNED / TEAM TO CONFIRM |
| **Large Asteroid** | 1–2 variants | $160 \times 160\text{ px}$ | `CircleShape2D` ($r = 65.0\text{px}$) | Heavy hazardous rock body; will have runtime spin applied. | UNASSIGNED / TEAM TO CONFIRM |
| **Communication Satellite** | 1 sprite | $96 \times 64\text{ px}$ | Proximity zone ($r = 80.0\text{px}$) | Gold/metallic chassis with dual solar arrays; drifts downward at 100 px/s. | UNASSIGNED / TEAM TO CONFIRM |
| **Wrecked Scout Craft** | 1 sprite | $160 \times 128\text{ px}$ | Visual entity (N/A) | Broken derelict scout vessel; floats in space at Level 3 completion. | UNASSIGNED / TEAM TO CONFIRM |

### Priority P1 — UI Polish & Feedback (Stage 1 Completion)
These assets improve the feedback loops of the verified gameplay mechanics.

| UI Asset | Target Dimensions | Format | Notes | Assigned Owner |
| :--- | :---: | :---: | :--- | :---: |
| **Primary Weapon Icon** | $64 \times 64\text{ px}$ | PNG RGBA8888 | HUD badge / recovery banner for acquired blasters. | UNASSIGNED / TEAM TO CONFIRM |
| **Shield Generator Icon** | $64 \times 64\text{ px}$ | PNG RGBA8888 | HUD badge / recovery banner for deflector shield. | UNASSIGNED / TEAM TO CONFIRM |
| **Space Parallax Background** | $1280 \times 720\text{ px}$ | PNG RGBA8888 | Deep space nebula / starfield layer to replace simple point stars. | UNASSIGNED / TEAM TO CONFIRM |
| **Button Hover / Pressed States** | Match button sizes | PNG RGBA8888 | Visual feedback variants for Start, Select, Exit buttons. | UNASSIGNED / TEAM TO CONFIRM |

### Priority P2 — Audio & Music
Audio assets required for full sensory feedback.

| Audio Role | Target Format | Duration / Type | Notes | Assigned Owner |
| :--- | :---: | :---: | :--- | :---: |
| **Asteroid Collision Light** | 16-bit WAV | $\approx 0.3\text{s}$ | Impact SFX when touching small asteroids. | UNASSIGNED / TEAM TO CONFIRM |
| **Asteroid Collision Heavy** | 16-bit WAV | $\approx 0.5\text{s}$ | Heavy thud/crunch when touching large asteroids. | UNASSIGNED / TEAM TO CONFIRM |
| **Satellite Extraction SFX** | 16-bit WAV | $\approx 1.5\text{s}$ | Electronic telemetry download / ping sound. | UNASSIGNED / TEAM TO CONFIRM |
| **Ship Destruction SFX** | 16-bit WAV | $\approx 1.2\text{s}$ | Hull explosion / breach sound when HP reaches 0. | UNASSIGNED / TEAM TO CONFIRM |
| **Stage 1 Exploration Track** | Stereo OGG | 2–3 min loop | Low-tempo suspenseful space survival background music. | UNASSIGNED / TEAM TO CONFIRM |

---

## 4. Delivery & Technical Guidelines for Artists

1. **File Format:** All raster graphics must be exported as **PNG with 8-bit alpha transparency (RGBA8888)**.
2. **Directional Art:** All spaceships, turrets, and projectiles must be drawn facing **UP (North / $-Y$ axis)**.
3. **Pivots & Centering:** Ensure the visual center of mass is centered in the canvas so it matches collision circles automatically.
4. **No Canvas Padding:** Trim excess transparent pixels tightly around buttons and icons (avoiding the $1920 \times 1080$ canvas issue seen on S2L3).
5. **Color Profile:** Use standard sRGB color space to ensure colors render identically in the Godot engine.

