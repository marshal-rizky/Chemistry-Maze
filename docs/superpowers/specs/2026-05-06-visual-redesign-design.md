# Visual Redesign — Design Spec
**Date:** 2026-05-06
**Project:** ChemBond Adventure (Godot 4.6)

---

## Overview

Three targeted visual improvements: element pickup redesigned as pixel-art hex chip (no sprite), main menu background filled with dense ghost element symbols, tutorial panel restyled to match HUD aesthetic with step progress dots.

---

## 1. Element Pickup — Hex Chip

**Decision:** Replace `atom_orb.png` sprite + spinning ring with pure `_draw()` hexagon.

### Implementation
- Remove `OrbSprite` Sprite2D node from `scenes/element_pickup.tscn`. Scene has only: `Area2D` (root) + `Label` (remove or repurpose for accessibility fallback) + `CollisionShape2D`.
- `element_pickup.gd`:
  - Remove `_process()` ring rotation and `queue_redraw()` call
  - Remove `$OrbSprite` references
  - `_draw()` renders a pixel-art hexagon (flat-top, 6 vertices) at radius ~7 local units:
    - Fill: element color at 18% alpha
    - Stroke: element color at full alpha, 1.5px width, `draw_polyline()`
    - Element symbol centered via `draw_string()` using `ThemeDB.fallback_font`, size 8, element color
  - Keep bobbing tween on whole node (`self` position:y ±2px, 0.8s sine loop)
  - Keep `modulate:a` glow pulse
  - `set_tutorial_highlight()` / `clear_tutorial_highlight()` unchanged

### Pixel art constraints
- Hexagon points computed at 60° intervals: `Vector2(cos(deg_to_rad(60*i - 30)), sin(deg_to_rad(60*i - 30))) * 7.0`
- `draw_polyline` with `antialiased = false`
- Symbol centered: offset by `-font.get_string_size(symbol, ...) / 2`

---

## 2. Main Menu — Dense Ghost Elements

**Decision:** Keep `grid.gdshader` + `_spawn_grid_bg()` unchanged. Replace `spawn_floating_atoms()` with high-density large ghost element symbols.

### Implementation
- `spawn_floating_atoms()` in `main_menu.gd`:
  - Spawn **35 Labels** (was 18 dots)
  - Font size: `randi_range(28, 52)` per atom (large, readable as symbols)
  - `modulate.a = randf_range(0.04, 0.08)` — very faint, atmospheric
  - Symbol pool: all 16 elements (`H O C Na Cl N Mg Ca Si S K Fe Cu Zn P Al`)
  - Each colored per element_colors dict (same as pickup)
  - Random position: full 1280×720 spread
  - Drift tween: ±150px random target, 6–12s duration, `EASE_IN_OUT`, looping
  - `z_index = -5`, `mouse_filter = MOUSE_FILTER_IGNORE`
  - Remove old `ColorRect` dot approach entirely

---

## 3. Tutorial Panel — HUD-style + Step Dots

**Decision:** Restyle existing panel to match HUD. Add step progress dots. Fix OK button.

### Implementation

**Panel styling** (`main.gd._setup_tutorial()`):
- Panel background: `Color("#070b14")` (matches HUD dark)
- Top border: 1px teal `#14b8a6` via `StyleBoxFlat.border_width_top = 1`
- Remove semi-transparent modulate — panel is fully opaque dark

**Step dots** (`tutorial_manager.gd`):
- Add `_spawn_step_dots(panel)` called from `setup()` after panel is ready
- Creates an `HBoxContainer` of 5 `ColorRect` strips: width=20px, height=3px, gap=4px
- Active/past steps: `#14b8a6` (teal). Upcoming: `#1d3554` (dark)
- `_update_step_dots()` called at start of each `show_step()` — recolors strips
- Dots sit at top of panel, full width left-aligned with 14px left margin

**OK button** (`main.gd._setup_tutorial()`):
- Replace naked `Button.new()` with styled button using `UITheme.create_game_theme()`
- Text: `"OK ▶"`
- Apply `UITheme` theme to button — teal border, dark bg, no rounded corners
- Right-aligned inside panel, same row as label text (`HBoxContainer` layout)

**Panel layout change:**
- Replace current VBox-like layout with:
  ```
  Panel
  ├── VBoxContainer (full rect)
  │   ├── HBoxContainer (step dots)
  │   └── HBoxContainer
  │       ├── RichTextLabel (flex, left)
  │       └── Button "OK ▶" (right)
  ```
- Decoy warning text still updates `panel_label.text` — inherits panel style automatically

---

## Files Changed

| File | Change |
|---|---|
| `scenes/element_pickup.tscn` | Remove OrbSprite node |
| `scripts/element_pickup.gd` | Full rewrite — hex _draw(), no ring, no OrbSprite |
| `scripts/main_menu.gd` | Replace spawn_floating_atoms() |
| `scripts/main.gd` | Restyle tutorial panel + OK button |
| `scripts/tutorial_manager.gd` | Add step dots spawn + update logic |
