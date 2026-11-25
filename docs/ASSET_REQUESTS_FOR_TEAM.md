# LAST SIGNAL — Asset Requests & Technical Feedback for Art Team (Milestone 5 Review)

**Document Version:** 2.1 (Milestone 5)  
**Batch Reviewed:** `Komgraf — Teh Hijau-20261121T151257Z-1-001.zip` (Batch 02)  
**Engine Reference:** Godot Engine 4.7.2 Standard  
**Viewport Reference:** $1280 \times 720\text{ px}$ (16:9 2D space environment)

---

## 1. Appreciation & Delivery Summary

Thank you to the art team for the delivery of **Batch 02** (`Komgraf — Teh Hijau`).

We have successfully processed all 44 delivered files (35 unchanged originals + 9 newly delivered PNG files):

1. **Communication Satellite (`commsatt.png`): INTEGRATED**
   - Successfully integrated into `scenes/satellite.tscn` under `Visuals/OfficialArt/Sprite2D`.
   - Scaled uniformly to $0.22 \times 0.22$ ($\approx 132.4 \times 73.9\text{px}$) inside the visual subtree, preserving the $80.0\text{px}$ proximity detection radius and unscaled physics root (`scale = Vector2.ONE`).
   - Dual progress rings render via an overlay `Indicator` node ($z=2$) above the sprite, ensuring extraction feedback is crisp and legible.
   - Procedural vector fallback is preserved and activates automatically if official art is disabled or textures are removed.
2. **Stage 2 Guard Enemies: ALL BATCH 02 GUARDS INTEGRATED**
   - Guard Bot (`guard_bot_idle.png`, `guard_bot_attacking.png`): **INTEGRATED** into `scenes/enemies/guard_bot.tscn` (Milestone 6).
   - Guard Satellite (`guard_satellite_idle.png`, `guard_satellite_attacking.png`): **INTEGRATED** into `scenes/enemies/guard_satellite.tscn` (Milestone 7).
   - Guard Drone (`guard_drone_idle.png`, `guard_drone_attacking.png`): **INTEGRATED** into `scenes/enemies/guard_drone.tscn` (Milestone 8). All 6 guard sprites delivered in Batch 02 are now fully operational in gameplay.
3. **Nirawak 1 Spacecraft (2 assets): IMPORTED & AWAITING CONFIRMATION**
   - Staged in `res://assets/sprites/npc/nirawak1/` preserving both `before-extraction.png` and `after-extraction.png`.
   - Visual relationship preserved without inventing unconfirmed narrative roles.
4. **Milestone 5 New Entities (Procedural Fallback Active):**
   - **Mining Survey Satellite (`scenes/mining_satellite.tscn`):** High-detail procedural industrial vector sprite (bronze/ochre chassis, cyan telemetry dish, solar arrays, beacon glow) is actively serving as fallback. Official art slot prepared under `Visuals/OfficialArt/Sprite2D`.
   - **Damaged Mining Vessel (`scenes/damaged_mining_ship.tscn`):** Procedural heavy industrial vessel with dual ore processing pods, heavy cutting laser gantry, animated hull breach electrical sparks, and pulsing amber SOS beacon. Official art slot prepared under `Visuals/OfficialArt/Sprite2D`.

---

## 2. Clarification Needed from Narrative & Art Team

### 2.1 Nirawak 1 Entity & Narrative Event Mapping (Action Required: Team Confirmation)
- **Delivered Assets:** `nirawak1/before-extraction.png` ($870 \times 303\text{px}$) and `nirawak1/after-extraction.png` ($870 \times 303\text{px}$).
- **Status:** **AWAITING TEAM CONFIRMATION**
- **Question for the Team:** Which in-game entity and level do these sprites represent?
  - Option A: The derelict/wrecked scout craft (`Surveyor-7`) encountered at the end of Stage 1 Level 3.
  - Option B: The damaged mining vessel encountered at the end of Stage 1 Level 5 that broadcasts the automated SOS pointing to Stage 2.
  - Option C: A distinct NPC vessel or player-controlled transport for later stages.
- **Engineering Safety Guarantee:** Until officially confirmed, existing procedural visuals for the Level 3 wrecked spacecraft and Level 5 damaged mining vessel remain active. No story text, dialogue, or gameplay triggers have been assumed without authorization.

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
| **Twin-Barrel Projectile Sprites** | 1 sprite | $32 \times 64\text{ px}$ | Capsule or ray ($r = 3\text{px}, h=14\text{px}$) | Blaster bolts facing North ($-Y$) for Level 4 pulse cannon. Procedural glowing fallback active. | UNASSIGNED / TEAM TO CONFIRM |

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

## 5. Milestone 10 Asset Integration Status & Feedback

1. **Stage 2 Mini-Boss Full Lifecycle Sprites (`miniboss_alive_p1.png`, `miniboss_alive_p2.png`, `miniboss_dead.png`):**
   - All three delivered mini-boss sprites are now **INTEGRATED / OPERATIONAL** in `scenes/bosses/guard_cruiser.tscn` scaled $0.4\times$ and rotated $\pi$ ($180^\circ$) to face South toward the player in the arcade arena.
   - `miniboss_alive_p1.png` is active during Level 4 (Phase 1).
   - `miniboss_alive_p2.png` is active during Level 5 (Phase 2).
   - `miniboss_dead.png` is active upon final defeat at 0 HP and persists behind the Stage 2 completion banner.
   - Strict mutual exclusivity guarantees no overlapping rendering between states.
2. **Audio SFX Requests for Boss Combat (Priority P1):**
   - **EM Jammer Pulse SFX:** High-tech electromagnetic surge/EMP discharge sound ($\approx 0.5\text{–}1.0\text{s}$).
   - **Cruiser Plasma Burst SFX:** Heavy energy cannon volley shot ($\approx 0.3\text{–}0.5\text{s}$).
   - **Electrical Stun Loop:** Low buzzing/crackling electrical loop for stunned capital ship ($\approx 2.0\text{s}$ seamless loop).
   - **Cruiser Catastrophic Destruction SFX:** Deep reverberating explosion / reactor core failure sound when HP reaches 0 ($\approx 2.0\text{s}$).
