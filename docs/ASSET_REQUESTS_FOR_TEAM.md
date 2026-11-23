# LAST SIGNAL — Asset Requests & Technical Feedback for Art Team (Batch 02 Review)

**Document Version:** 2.0 (Milestone 3.7)  
**Batch Reviewed:** `Komgraf — Teh Hijau-20261121T151257Z-1-001.zip` (Batch 02)  
**Engine Reference:** Godot Engine 4.7.2 Standard  
**Viewport Reference:** $1280 \times 720\text{ px}$ (16:9 2D space environment)

---

## 1. Appreciation & Batch 02 Delivery Summary

Thank you to the art team for the delivery of **Batch 02** (`Komgraf — Teh Hijau`).

We have successfully processed all 44 delivered files (35 unchanged originals + 9 newly delivered PNG files):

1. **Communication Satellite (`commsatt.png`): INTEGRATED**
   - Successfully integrated into `scenes/satellite.tscn` under `Visuals/OfficialArt/Sprite2D`.
   - Scaled uniformly to $0.22 \times 0.22$ ($\approx 132.4 \times 73.9\text{px}$) inside the visual subtree, preserving the $80.0\text{px}$ proximity detection radius and unscaled physics root (`scale = Vector2.ONE`).
   - Dual progress rings render via an overlay `Indicator` node ($z=2$) above the sprite, ensuring extraction feedback is crisp and legible.
   - Procedural vector fallback is preserved and activates automatically if official art is disabled or textures are removed.
2. **Stage 2 Guard Enemies (6 assets): IMPORTED & RESERVED**
   - Guard Bot (`idle.png`, `attacking.png`)
   - Guard Satellite (`idle.png`, `attacking.png`)
   - Guard Drone (`idle.png`, `attacking.png`)
   - Cleanly staged in `res://assets/sprites/enemies/`.
   - Reserved strictly for Stage 2. No enemy AI, combat, lasers, or missiles were prematurely invented.
3. **Nirawak 1 Spacecraft (2 assets): IMPORTED & AWAITING CONFIRMATION**
   - Staged in `res://assets/sprites/npc/nirawak1/` preserving both `before-extraction.png` and `after-extraction.png`.
   - Visual relationship preserved without inventing unconfirmed narrative roles.

---

## 2. Clarification Needed from Narrative & Art Team

### 2.1 Nirawak 1 Entity & Narrative Event Mapping (Action Required: Team Confirmation)
- **Delivered Assets:** `nirawak1/before-extraction.png` ($870 \times 303\text{px}$) and `nirawak1/after-extraction.png` ($870 \times 303\text{px}$).
- **Status:** **AWAITING TEAM CONFIRMATION**
- **Question for the Team:** Which in-game entity and level do these sprites represent?
  - Option A: The derelict/wrecked spacecraft encountered at the end of Stage 1 Level 3.
  - Option B: The damaged mining vessel mentioned in the decrypted satellite telemetry for Stage 1 Level 5.
  - Option C: A distinct NPC vessel or player-controlled transport for later stages.
- **Engineering Safety Guarantee:** Until officially confirmed, existing procedural visuals for the Level 3 wrecked spacecraft remain active. No story text, dialogue, or gameplay triggers have been assumed.

### 2.2 Stage 2 Level 3 Button Canvas Anomaly (Action Required: High)
- **Delivered Asset:** `assets/UI HUI/stage btn/Stage 2/L3.png`
- **Observed Issue:** Still exported on a full $1920 \times 1080$ canvas rather than cropped tightly to the button graphic.
- **Interim Fix:** Non-destructive crop `stage2_l3_cropped.png` ($737 \times 84\text{px}$) remains active in `LevelSelect`.
- **Request:** Please re-export `Stage 2 L3.png` cropped tightly to its visible pixels ($\approx 370 \times 75\text{px}$), matching the other Stage 2 buttons on transparent RGBA.

---

## 3. Prioritized Asset Requests for Next Delivery (Batch 03)

To complete visual fidelity for currently implemented gameplay (Stage 1 Levels 1–3) and prepare for Milestone 4 (Stage 1 Level 4: Twin-Barrel Shooting), the following assets are requested:

### Priority P0 — Critical Stage 1 Gameplay Requirements

| Entity / Asset | Quantity / Variants | Target Canvas Size | Matching Collision | Visual Orientation & Notes | Assigned Owner |
| :--- | :---: | :---: | :---: | :--- | :---: |
| **Small Asteroid** | 2–3 variants | $48 \times 48\text{ px}$ | `CircleShape2D` ($r = 19.0\text{px}$) | Non-directional irregular rock; runtime spin applied. Inscribes in $r=19$ circle. | UNASSIGNED / TEAM TO CONFIRM |
| **Medium Asteroid** | 2 variants | $96 \times 96\text{ px}$ | `CircleShape2D` ($r = 35.0\text{px}$) | Cratered rock profile; runtime spin applied. Inscribes in $r=35$ circle. | UNASSIGNED / TEAM TO CONFIRM |
| **Large Asteroid** | 1–2 variants | $160 \times 160\text{ px}$ | `CircleShape2D` ($r = 65.0\text{px}$) | Heavy hazardous rock body; runtime spin applied. Inscribes in $r=65$ circle. | UNASSIGNED / TEAM TO CONFIRM |
| **Wrecked Scout Craft (Confirmed)** | 1 sprite (or Nirawak 1 confirmation) | $160 \times 128\text{ px}$ | Visual entity (N/A) | Derelict vessel floating in space at Level 3 completion. | UNASSIGNED / TEAM TO CONFIRM |
| **Twin-Barrel Projectile Sprites** | 1 sprite | $32 \times 64\text{ px}$ | Capsule or ray ($r = 4\text{px}$) | Blaster bolts facing North ($-Y$) for Milestone 4 shooting mechanics. | UNASSIGNED / TEAM TO CONFIRM |

### Priority P1 — UI Polish & Feedback

| UI Asset | Target Dimensions | Format | Notes | Assigned Owner |
| :--- | :---: | :---: | :--- | :---: |
| **Primary Weapon Icon** | $64 \times 64\text{ px}$ | PNG RGBA8888 | HUD badge / recovery banner for acquired blasters. | UNASSIGNED / TEAM TO CONFIRM |
| **Shield Generator Icon** | $64 \times 64\text{ px}$ | PNG RGBA8888 | HUD badge / recovery banner for deflector shield. | UNASSIGNED / TEAM TO CONFIRM |
| **Space Parallax Background** | $1280 \times 720\text{ px}$ | PNG RGBA8888 | Deep space nebula / starfield layer to replace simple point stars. | UNASSIGNED / TEAM TO CONFIRM |
| **Button Hover / Pressed States** | Match button sizes | PNG RGBA8888 | Visual feedback variants for Start, Select, Exit buttons. | UNASSIGNED / TEAM TO CONFIRM |

### Priority P2 — Audio & Music

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
4. **No Canvas Padding:** Trim excess transparent pixels tightly around buttons and icons.
5. **Color Profile:** Use standard sRGB color space.
