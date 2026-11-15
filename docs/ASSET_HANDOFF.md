# LAST SIGNAL — Asset Handoff Specification for Art & Audio Teams

**Document Version:** 1.1 (Milestone 3.6 - Batch 01 Delivered & Integrated)  
**Target Platform:** PC (Godot 4.7.2 Standard)  
**Viewport Reference:** $1280 \times 720\text{ px}$ (16:9 2D space environment)

---

## 1. Directory Structure & Source File Separation

To ensure source files are preserved and game exports remain lean, assets are strictly divided into source archives and runtime directories:

```
last-signal-starter/
├── assets_src/                        # EDITABLE SOURCE MASTER FILES (Not loaded in runtime)
│   ├── psd/                           # Layered Photoshop documents
│   ├── aseprite/                      # Aseprite project files
│   ├── vector_svg/                    # Vector source files (.svg, .ai)
│   └── audio_projects/                # DAW projects (.flp, .rpp, unmastered audio)
└── assets/                            # RUNTIME ASSETS (Imported directly by Godot)
    ├── sprites/
    │   ├── player/                    # Player ship, thrusters, shields
    │   ├── hazards/                   # Asteroids (small, medium, large variants)
    │   ├── interactables/             # Satellite, beacons, extraction rings
    │   ├── environment/               # Background tiles, dust, wrecked vessels
    │   └── portraits/                 # Dialogue character portraits
    ├── ui/
    │   ├── fonts/                     # TTF / OTF typeface files
    │   ├── icons/                     # UI badges, hearts, weapon icons
    │   └── frames/                    # 9-slice panels and bars
    └── audio/
        ├── sfx/                       # Sound effects (.wav)
        └── music/                     # Music tracks and ambient loops (.ogg)
```

---

## 2. Sprite Orientation & Pivot Standards

### 2.1 Orientation Conventions
- **Directional Vessels & Entities (Player Ship, Projectiles, Directional Hazards):**
  - **MANDATORY ORIENTATION:** Directional assets **MUST BE DRAWN FACING UP (North / $-Y$ axis, 0.0 radians)**.
  - *Rationale:* Godot's 2D coordinate system places $-Y$ towards the top of the viewport. The flight controller uses `rotation = Vector2.UP.angle_to(movement_velocity)`. Drawing ships facing UP ensures mathematical zero rotation matches upward flight without requiring offset rotations in scenes.
- **Non-Directional Assets (Asteroids, Satellites, Space Dust, Debris):**
  - May be oriented naturally according to aesthetic composition. Asteroids undergo randomized runtime spin (`spin = randf_range(-2.0, 2.0)`).

### 2.2 Visual Pivots & Centroid Alignment
- **Pivot at Geometric Centroid:** All sprite artwork must be placed so that its true geometric center of mass sits at the exact mathematical center of the image canvas.
- In Godot, `Sprite2D` nodes default to `centered = true` with `offset = Vector2.ZERO`. When centered correctly, the sprite aligns directly with `CollisionShape2D` at `(0, 0)`.

---

## 3. Recommended Export Dimensions & Collision Reference

> [!NOTE]
> Pixel dimensions in the table below are **recommended export guidelines**, not mandatory rigid canvas limits. Visual silhouettes do not have to fit entirely inside collision circles; protruding wings, antennae, and rock ridges are expected. Collision and art alignment will be reviewed during integration.

| Entity | Recommended Export Size | Target Silhouette Guide | Matching Collision Shape | Alignment & Integration Notes |
| :--- | :---: | :---: | :---: | :--- |
| **Player Ship** | $64 \times 64\text{ px}$ | $\approx 40\text{ px} \times 56\text{ px}$ | `CircleShape2D` ($r = 20.0\text{ px}$) | Forward-facing (UP). Hull core covers the 20px radius circle; wingtips may extend past. |
| **Small Asteroid** | $48 \times 48\text{ px}$ | $\approx 36\text{ px} \times 38\text{ px}$ | `CircleShape2D` ($r = 19.0\text{ px}$) | Organic irregular rock silhouette. Inscribes approximately in 19px radius. |
| **Medium Asteroid** | $96 \times 96\text{ px}$ | $\approx 68\text{ px} \times 72\text{ px}$ | `CircleShape2D` ($r = 35.0\text{ px}$) | Heavier rock profile, surface craters. |
| **Large Asteroid** | $160 \times 160\text{ px}$ | $\approx 126\text{ px} \times 130\text{ px}$ | `CircleShape2D` ($r = 65.0\text{ px}$) | Massive hazardous rock body. |
| **Comm Satellite** | $96 \times 64\text{ px}$ | $\approx 76\text{ px} \times 32\text{ px}$ | `CircleShape2D` ($r = 80.0\text{ px}$) | Golden chassis, dual solar arrays. Collision circle is proximity extraction zone. |
| **Wrecked Ship** | $160 \times 128\text{ px}$ | $\approx 110\text{ px} \times 76\text{ px}$ | N/A (Visual Entity) | Sheared hull, visible broken starboard section, intact port weapon hardpoint. |
| **Dialogue Portraits** | $160 \times 160\text{ px}$ | Square framing | N/A (UI) | Character bust portraits with expression variants (`neutral`, `warning`, `alarm`). |

---

## 4. Technical File Format Specifications

- **Static Textures & Sprites:**
  - Format: PNG with 8-bit alpha channel transparency (RGBA8888).
  - Transparency: Clean anti-aliased alpha without black/white matte fringes.
- **Animation Sequences:**
  - Horizontal spritesheet with equal frame widths (e.g., $8\text{ frames} \times 64\text{px} = 512 \times 64\text{px}$), OR numbered PNG sequences (`name_00.png`, `name_01.png`, etc.).
- **Sound Effects (SFX):**
  - Format: Uncompressed 16-bit 44.1 kHz or 48 kHz stereo/mono `.wav`.
- **Music & Ambient Backgrounds:**
  - Format: High-bitrate `.ogg` (Ogg Vorbis) with clean loop points.

---

## 5. Naming Conventions

All assets delivered into `assets/` must use lowercase `snake_case` with descriptive role prefixes:

- `player_hull.png`
- `player_thruster_strip8.png`
- `player_shield_bubble.png`
- `asteroid_small_01.png`, `asteroid_small_02.png`
- `asteroid_medium_01.png`
- `asteroid_large_01.png`
- `satellite_comm_body.png`
- `wreck_derelict_scout.png`
- `portrait_ai_neutral.png`, `portrait_ai_warning.png`
- `sfx_collision_light.wav`, `sfx_collision_heavy.wav`, `sfx_satellite_extract.wav`

---

## 6. Batch 01 Integration Review & Practical Lessons Learned

During the integration of Team Batch 01 art assets in Milestone 3.6, several practical lessons were established:

1. **Player Ship Orientation Confirmed:**
   - The delivered player art (`alive.png`, `dead.png`) was drawn pointing straight UP (North / $-Y$).
   - This matched the mathematical specification `rotation = Vector2.UP.angle_to(movement_velocity)` perfectly, requiring zero rotation offset. All future directional craft should follow this exact orientation.
2. **Player Visual Scaling:**
   - The raw $256 \times 256\text{px}$ sprite was scaled by $0.2 \times 0.2$ ($\approx 51.2\text{px}$) within the visual subtree, aligning naturally with the 20 px radius ($40\text{px}$ diameter) physics circle.
3. **Canvas Padding & Export Bounds:**
   - Button assets must be exported cropped to their visible bounds. `Stage 2 L3.png` was exported on a $1920 \times 1080$ canvas, requiring a non-destructive runtime crop (`stage2_l3_cropped.png`).
4. **Preservation of Source Files:**
   - The unzipped source archive is permanently archived under `assets_src/team_batch_01/` to guarantee no original assets are modified or lost.


