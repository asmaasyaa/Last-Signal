# LAST SIGNAL — Team Asset Manifest (Batch 02)

**Document Version:** 2.0 (Milestone 3.7 — Team Asset Integration Batch 02)  
**Batch Identifier:** `Komgraf — Teh Hijau-20261121T151257Z-1-001.zip`  
**Previous Batch Identifier:** `Komgraf — Teh Hijau-20261115T170428Z-1-001.zip` (Batch 01)  
**Preserved Pristine Originals:** `res://assets_src/team_batch_02/` (and `team_batch_01/`)  
**Imported Runtime Root:** `res://assets/`  
**Engine:** Godot Engine 4.7.2 Standard (GDScript)

---

## 1. Executive Summary & Batch Comparison

This manifest catalogs all **44 visual assets** delivered by the art team across Batch 01 and Batch 02, plus 1 non-destructive runtime-derived asset generated for layout compatibility.

### Batch 02 Delta Summary:
- **Previous Asset Count (Batch 01):** 35 PNG files
- **Updated Asset Count (Batch 02):** 44 PNG files
- **Unchanged Files:** 35 PNG files (byte-for-byte identical to Batch 01)
- **Newly Added Files:** 9 PNG files
- **Removed Files:** 0 PNG files

Every asset has been evaluated against the existing codebase, classified into standard statuses, and traced from its source path to its runtime location:

- **INTEGRATED (21 assets):** Actively connected to game entities or user interface scenes with passing automated test coverage. (Includes Player alive/dead, Start/Select/Exit buttons, 15 stage/level buttons, and now **Communication Satellite**).
- **IMPORTED / RESERVED FOR FUTURE (20 assets):** Staged in clean runtime directories for upcoming milestones; no gameplay or mechanics were invented prematurely. (Includes decorative button backplate, overheat label, Stage 2 mini-boss [3], Stage 3 final boss [11], and **Stage 2 Guards [6]**).
- **AWAITING TEAM CONFIRMATION (2 assets):** **Nirawak 1** (`before-extraction.png` and `after-extraction.png`). Visual state relationship preserved; awaiting authoritative confirmation on narrative event and level mapping.
- **NEEDS REVISION (1 asset):** Stage 2 Level 3 button (`stage2_l3_raw.png` - $1920 \times 1080$ canvas anomaly). Interim non-destructive crop (`stage2_l3_cropped.png`) remains active in UI.
- **MISSING (Stage 1 Gameplay Assets):** Documented with priority ratings and specifications for upcoming delivery.

---

## 2. Status Classification Table

| Original Archive Path | Imported Runtime Resource | Dimensions | Mode | Orientation | Status | Notes / Runtime Integration |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **Player Ship (Batch 01)** | | | | | | |
| `assets/entities/player/alive.png` | `res://assets/sprites/player/player_alive.png` | $256 \times 256$ | RGBA | North ($-Y$) | **INTEGRATED** | Connected to `Player/Visuals/OfficialArt/AliveSprite`. Scaled to $0.2 \times 0.2$ ($\approx 51.2\text{px}$). Forward axis matches `Vector2.UP`. |
| `assets/entities/player/dead.png` | `res://assets/sprites/player/player_dead.png` | $264 \times 264$ | RGBA | North ($-Y$) | **INTEGRATED** | Connected to `Player/Visuals/OfficialArt/DeadSprite`. Scaled to $0.2 \times 0.2$. Automatic state switching on HP = 0 and checkpoint revive. |
| **Interactables / NPC (Batch 02)** | | | | | | |
| `assets/entities/npc/commsatt.png` | `res://assets/sprites/interactables/commsatt.png` | $602 \times 336$ | RGBA | Horizontal | **INTEGRATED** | Connected to `Satellite/Visuals/OfficialArt/Sprite2D`. Scaled to $0.22 \times 0.22$ ($\approx 132.4 \times 73.9\text{px}$). Collision radius remains $r=80.0\text{px}$. Progress indicators render on top via `Indicator` ($z=2$). Procedural fallback preserved. |
| `assets/entities/npc/nirawak1/before-extraction.png` | `res://assets/sprites/npc/nirawak1/before_extraction.png` | $870 \times 303$ | RGBA | Horizontal | **AWAITING TEAM CONFIRMATION** | Pristine original staged. Visual state before extraction. Intended level, entity role, and narrative mapping awaiting team confirmation. NOT replacing Level 3 wrecked spacecraft. |
| `assets/entities/npc/nirawak1/after-extraction.png` | `res://assets/sprites/npc/nirawak1/after_extraction.png` | $870 \times 303$ | RGBA | Horizontal | **AWAITING TEAM CONFIRMATION** | Pristine original staged. Visual state after extraction. Paired with `before-extraction.png`. Intended narrative event awaiting team confirmation. |
| **Stage 2 Guard Enemies (Batch 02)** | | | | | | |
| `assets/entities/guards/bot/idle.png` | `res://assets/sprites/enemies/guard_bot/guard_bot_idle.png` | $129 \times 129$ | RGBA | North ($-Y$) | **INTEGRATED / OPERATIONAL** | Guard Bot idle state. Integrated in `scenes/enemies/guard_bot.tscn`. |
| `assets/entities/guards/bot/attacking.png` | `res://assets/sprites/enemies/guard_bot/guard_bot_attacking.png` | $129 \times 129$ | RGBA | North ($-Y$) | **INTEGRATED / OPERATIONAL** | Guard Bot attack pose. Integrated in `scenes/enemies/guard_bot.tscn`. |
| `assets/entities/guards/satellite/idle.png` | `res://assets/sprites/enemies/guard_satellite/guard_satellite_idle.png` | $347 \times 267$ | RGBA | North ($-Y$) | **INTEGRATED / OPERATIONAL** | Guard Satellite idle state. Integrated in `scenes/enemies/guard_satellite.tscn`. |
| `assets/entities/guards/satellite/attacking.png` | `res://assets/sprites/enemies/guard_satellite/guard_satellite_attacking.png` | $347 \times 267$ | RGBA | North ($-Y$) | **INTEGRATED / OPERATIONAL** | Guard Satellite attack pose. Integrated in `scenes/enemies/guard_satellite.tscn`. |
| `assets/entities/guards/drone/idle.png` | `res://assets/sprites/enemies/guard_drone/guard_drone_idle.png` | $152 \times 316$ | RGBA | North ($-Y$) | **IMPORTED / RESERVED** | Guard Drone idle state. Staged for Stage 2. |
| `assets/entities/guards/drone/attacking.png` | `res://assets/sprites/enemies/guard_drone/guard_drone_attacking.png` | $151 \times 316$ | RGBA | North ($-Y$) | **IMPORTED / RESERVED** | Guard Drone attack pose. Staged for Stage 2. |
| **Main Menu UI (Batch 01)** | | | | | | |
| `assets/UI HUI/start btn.png` | `res://assets/ui/buttons/btn_start.png` | $629 \times 131$ | RGBA | N/A | **INTEGRATED** | Connected to `MainMenu/CenterContainer/VBoxContainer/ButtonsContainer/StartButton`. Launches Stage 1 Level 1 (`scenes/main.tscn`). |
| `assets/UI HUI/select btn.png` | `res://assets/ui/buttons/btn_select.png` | $639 \times 135$ | RGBA | N/A | **INTEGRATED** | Connected to `MainMenu/CenterContainer/VBoxContainer/ButtonsContainer/SelectButton`. Transitions to `scenes/ui/level_select.tscn`. |
| `assets/UI HUI/exit btn.png` | `res://assets/ui/buttons/btn_exit.png` | $651 \times 137$ | RGBA | N/A | **INTEGRATED** | Connected to `MainMenu/CenterContainer/VBoxContainer/ButtonsContainer/ExitButton`. Triggers `get_tree().quit()`. |
| `assets/UI HUI/buletan buat start select exit btn.png` | `res://assets/ui/buttons/btn_circle_decor.png` | $517 \times 142$ | RGBA | N/A | **IMPORTED / RESERVED** | Decorative circular button backplate. Staged for menu visual polish. |
| **Stage 1 Level Buttons (Batch 01)** | | | | | | |
| `assets/UI HUI/stage btn/Stage 1/L1.png` | `res://assets/ui/buttons/stage1_l1.png` | $384 \times 78$ | RGBA | N/A | **INTEGRATED** | Connected to `LevelSelect/Stage1/L1`. Enabled / Playable. Launches Stage 1 Level 1. |
| `assets/UI HUI/stage btn/Stage 1/L2.png` | `res://assets/ui/buttons/stage1_l2.png` | $380 \times 78$ | RGBA | N/A | **INTEGRATED** | Connected to `LevelSelect/Stage1/L2`. Progression Locked. Accessible via normal gameplay progression from Level 1. |
| `assets/UI HUI/stage btn/Stage 1/L3.png` | `res://assets/ui/buttons/stage1_l3.png` | $381 \times 76$ | RGBA | N/A | **INTEGRATED** | Connected to `LevelSelect/Stage1/L3`. Progression Locked. Accessible via normal gameplay progression from Level 2. |
| `assets/UI HUI/stage btn/Stage 1/L4.png` | `res://assets/ui/buttons/stage1_l4.png` | $384 \times 75$ | RGBA | N/A | **INTEGRATED** | Connected to `LevelSelect/Stage1/L4`. Disabled / Locked. Unimplemented. |
| `assets/UI HUI/stage btn/Stage 1/L5.png` | `res://assets/ui/buttons/stage1_l5.png` | $384 \times 77$ | RGBA | N/A | **INTEGRATED** | Connected to `LevelSelect/Stage1/L5`. Disabled / Locked. Unimplemented. |
| **Stage 2 Level Buttons (Batch 01)** | | | | | | |
| `assets/UI HUI/stage btn/Stage 2/L1.png` | `res://assets/ui/buttons/stage2_l1.png` | $368 \times 73$ | RGBA | N/A | **INTEGRATED** | Connected to `LevelSelect/Stage2/L1`. Disabled / Locked. Reports Stage 2 reserved status. |
| `assets/UI HUI/stage btn/Stage 2/L2.png` | `res://assets/ui/buttons/stage2_l2.png` | $370 \times 75$ | RGBA | N/A | **INTEGRATED** | Connected to `LevelSelect/Stage2/L2`. Disabled / Locked. |
| `assets/UI HUI/stage btn/Stage 2/L3.png` | `res://assets/ui/buttons/stage2_l3_raw.png` | $1920 \times 1080$ | RGBA | N/A | **NEEDS REVISION** | Full HD canvas anomaly. Visible button occupies bounding box $(518, 409, 1255, 493)$. Original preserved intact. |
| *[Runtime Crop Derivative]* | `res://assets/ui/buttons/stage2_l3_cropped.png` | $737 \times 84$ | RGBA | N/A | **INTEGRATED** | Non-destructive crop of `stage2_l3_raw.png`. Connected to `LevelSelect/Stage2/L3` (Disabled / Locked). |
| `assets/UI HUI/stage btn/Stage 2/L4.png` | `res://assets/ui/buttons/stage2_l4.png` | $371 \times 75$ | RGBA | N/A | **INTEGRATED** | Connected to `LevelSelect/Stage2/L4`. Disabled / Locked. |
| `assets/UI HUI/stage btn/Stage 2/L5.png` | `res://assets/ui/buttons/stage2_l5.png` | $373 \times 75$ | RGBA | N/A | **INTEGRATED** | Connected to `LevelSelect/Stage2/L5`. Disabled / Locked. |
| **Stage 3 Level Buttons (Batch 01)** | | | | | | |
| `assets/UI HUI/stage btn/Stage 3/L1.png` | `res://assets/ui/buttons/stage3_l1.png` | $371 \times 75$ | RGBA | N/A | **INTEGRATED** | Connected to `LevelSelect/Stage3/L1`. Disabled / Locked. Reports Stage 3 reserved status. |
| `assets/UI HUI/stage btn/Stage 3/L2.png` | `res://assets/ui/buttons/stage3_l2.png` | $370 \times 75$ | RGBA | N/A | **INTEGRATED** | Connected to `LevelSelect/Stage3/L2`. Disabled / Locked. |
| `assets/UI HUI/stage btn/Stage 3/L3.png` | `res://assets/ui/buttons/stage3_l3.png` | $371 \times 74$ | RGBA | N/A | **INTEGRATED** | Connected to `LevelSelect/Stage3/L3`. Disabled / Locked. |
| `assets/UI HUI/stage btn/Stage 3/L4.png` | `res://assets/ui/buttons/stage3_l4.png` | $372 \times 73$ | RGBA | N/A | **INTEGRATED** | Connected to `LevelSelect/Stage3/L4`. Disabled / Locked. |
| `assets/UI HUI/stage btn/Stage 3/L5.png` | `res://assets/ui/buttons/stage3_l5.png` | $371 \times 76$ | RGBA | N/A | **INTEGRATED** | Connected to `LevelSelect/Stage3/L5`. Disabled / Locked. |
| **HUD & Labels (Batch 01)** | | | | | | |
| `assets/UI HUI/overheat label.png` | `res://assets/ui/labels/label_overheat.png` | $298 \times 112$ | RGBA | N/A | **IMPORTED / RESERVED** | Overheat warning label. Reserved for future weapon heat mechanics. |
| **Stage 2 Mini-Boss (Batch 01)** | | | | | | |
| `assets/entities/mini-boss/alive-p1.png` | `res://assets/sprites/bosses/stage2_miniboss/miniboss_alive_p1.png` | $601 \times 321$ | RGBA | North ($-Y$) | **IMPORTED / RESERVED** | Phase 1 sprite. Reserved for Stage 2 (NOT Milestone 4; Milestone 4 is S1L4 twin-barrel shooting). |
| `assets/entities/mini-boss/alive-p2.png` | `res://assets/sprites/bosses/stage2_miniboss/miniboss_alive_p2.png` | $601 \times 321$ | RGBA | North ($-Y$) | **IMPORTED / RESERVED** | Phase 2 animated variant. Reserved for Stage 2. |
| `assets/entities/mini-boss/dead.png` | `res://assets/sprites/bosses/stage2_miniboss/miniboss_dead.png` | $601 \times 321$ | RGBA | North ($-Y$) | **IMPORTED / RESERVED** | Destruction state sprite. Reserved for Stage 2. |
| **Stage 3 Final Boss (Batch 01)** | | | | | | |
| `assets/entities/boss/core/alive-p1.png` | `res://assets/sprites/bosses/stage3_boss/boss_alive_p1.png` | $513 \times 622$ | RGBA | North ($-Y$) | **IMPORTED / RESERVED** | Core component animation frame 1. Reserved for Stage 3. |
| `assets/entities/boss/core/alive-p2.png` | `res://assets/sprites/bosses/stage3_boss/boss_alive_p2.png` | $513 \times 622$ | RGBA | North ($-Y$) | **IMPORTED / RESERVED** | Core component animation frame 2. Reserved for Stage 3. |
| `assets/entities/boss/core/alive-p3.png` | `res://assets/sprites/bosses/stage3_boss/boss_alive_p3.png` | $513 \times 622$ | RGBA | North ($-Y$) | **IMPORTED / RESERVED** | Core component animation frame 3. Reserved for Stage 3. |
| `assets/entities/boss/core/alive-p4.png` | `res://assets/sprites/bosses/stage3_boss/boss_alive_p4.png` | $513 \times 625$ | RGBA | North ($-Y$) | **IMPORTED / RESERVED** | Core component animation frame 4. Reserved for Stage 3. |
| `assets/entities/boss/core/dead.png` | `res://assets/sprites/bosses/stage3_boss/boss_dead.png` | $513 \times 622$ | RGBA | North ($-Y$) | **IMPORTED / RESERVED** | Core destruction state. Reserved for Stage 3. |
| `assets/entities/boss/moving-parts/Wheel Top.png` | `res://assets/sprites/bosses/stage3_boss/boss_wheel_top.png` | $513 \times 200$ | RGBA | N/A | **IMPORTED / RESERVED** | Modular top wheel assembly component. Reserved for Stage 3. |
| `assets/entities/boss/moving-parts/Wheel Bottom.png` | `res://assets/sprites/bosses/stage3_boss/boss_wheel_bottom.png` | $513 \times 200$ | RGBA | N/A | **IMPORTED / RESERVED** | Modular bottom wheel assembly component. Reserved for Stage 3. |
| `assets/entities/boss/moving-parts/Ropes.png` | `res://assets/sprites/bosses/stage3_boss/boss_ropes.png` | $408 \times 1035$ | RGBA | N/A | **IMPORTED / RESERVED** | Connecting cable / tether asset. Reserved for Stage 3. |
| `assets/entities/boss/Example 1 Alive Phase 1.png` | `res://assets/sprites/bosses/stage3_boss/boss_reference_assembled_p1.png` | $513 \times 1425$ | RGBA | North ($-Y$) | **IMPORTED / RESERVED** | Reference visual assembly guide for Phase 1 boss hierarchy. Reserved for Stage 3. |
| `assets/entities/boss/Example 2 Dead.png` | `res://assets/sprites/bosses/stage3_boss/boss_reference_assembled_dead.png` | $513 \times 1425$ | RGBA | North ($-Y$) | **IMPORTED / RESERVED** | Reference visual assembly guide for defeated boss state. Reserved for Stage 3. |

---

## 3. Missing Assets Inventory (Stage 1 Gameplay Requirements)

The following assets are required for complete visual fidelity in currently implemented gameplay (Stage 1 Levels 1–3). Procedural vector fallbacks remain active in their absence. Note: Communication Satellite has been delivered in Batch 02 and successfully integrated.

| Missing Asset Role | Target Stage / Level | Recommended Dimensions | Format | Priority | Assigned Owner | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **Small Asteroid (2-3 variants)** | S1 L1–L3 | $48 \times 48\text{ px}$ | RGBA8888 | **P0** | UNASSIGNED / TEAM TO CONFIRM | Inscribes in $r=19.0\text{px}$ circle. Procedural fallback currently active. |
| **Medium Asteroid (2 variants)** | S1 L2–L3 | $96 \times 96\text{ px}$ | RGBA8888 | **P0** | UNASSIGNED / TEAM TO CONFIRM | Inscribes in $r=35.0\text{px}$ circle. Procedural fallback currently active. |
| **Large Asteroid (2 variants)** | S1 L3 | $160 \times 160\text{ px}$ | RGBA8888 | **P0** | UNASSIGNED / TEAM TO CONFIRM | Inscribes in $r=65.0\text{px}$ circle. Procedural fallback currently active. |
| **Wrecked Scout Craft (Confirmed)** | S1 L3 | $160 \times 128\text{ px}$ | RGBA8888 | **P0** | UNASSIGNED / TEAM TO CONFIRM | Derelict vessel floating in space. Awaiting team confirmation whether Nirawak 1 or a dedicated sprite represents this entity. |
| **Twin-Barrel Projectile Sprites** | S1 L4 | $32 \times 64\text{ px}$ | RGBA8888 | **P0** | UNASSIGNED / TEAM TO CONFIRM | Energy bolts for Milestone 4 shooting mechanics. |
| **Weapon & Shield Recovery Icons** | S1 L3 / HUD | $64 \times 64\text{ px}$ | RGBA8888 | **P1** | UNASSIGNED / TEAM TO CONFIRM | Equipment recovery confirmation badges. |
| **Starfield / Space Dust Backdrop** | Stage 1 All | $1280 \times 720\text{ px}$ | RGBA8888 | **P1** | UNASSIGNED / TEAM TO CONFIRM | High-res background or tileable parallax layers. |
| **Audio SFX (Collisions, Extraction)** | Stage 1 All | N/A | 16-bit WAV | **P1** | UNASSIGNED / TEAM TO CONFIRM | Impact hits, satellite extraction ping, ship destruction. |
| **Stage 1 Ambient Music** | Stage 1 All | N/A | Stereo OGG | **P2** | UNASSIGNED / TEAM TO CONFIRM | Continuous low-tempo space exploration loop. |

---

## 4. Verification & Integrity Confirmation

- All 44 delivered files are preserved verbatim in `res://assets_src/team_batch_02/`.
- All runtime copies in `res://assets/` have been verified to import and instantiate without errors via headless Godot 4.7.2.
- 435 regression tests across Milestones 1 through 3.6 pass with zero regressions.
- Milestone 3.7 test suite independently validates Batch 02 asset loading, satellite visual hierarchy, fallback activation, and collision preservation.
