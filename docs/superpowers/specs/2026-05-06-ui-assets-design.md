# UI Assets & Visual Polish — Design Spec
**Date:** 2026-05-06
**Project:** ChemBond Adventure (Godot 4.6)

---

## Overview

Replace placeholder UI visuals with a cohesive dark pixel-terminal aesthetic. Scope: custom font, main menu logo + background, element pickup redesign, HUD button icons. All assets generated via Figma MCP (logo, grid, icons, ring) and PixelLab MCP (atom orb). No premium tools required beyond existing MCP access.

---

## Visual Direction

**Palette:** Existing `ui_theme.gd` colors unchanged — dark navy (#070b14), teal (#14b8a6), teal-hi (#5eead4), text (#cfeae6).

**Style:** Retro pixel terminal. Pixel font, bracketed/bordered UI elements, monospace rhythm. No rounded corners. No gradients on interactive elements.

---

## Font

**Choice:** Pixelify Sans (Google Fonts, free, `.ttf`)

**Download:** `https://fonts.google.com/specimen/Pixelify+Sans` → Download family → extract `PixelifySans-Regular.ttf` and `PixelifySans-Bold.ttf`.

**Placement:** `assets/fonts/PixelifySans-Regular.ttf`, `assets/fonts/PixelifySans-Bold.ttf`

**Integration:** `ui_theme.gd` loads both via `load("res://assets/fonts/PixelifySans-Regular.ttf")` and sets as default font on the Theme. All Labels, Buttons, RichTextLabels inherit automatically.

---

## Main Menu

### Logo (`assets/ui/logo.png`)

**Layout:** Inline — hex icon left, text stack right.
- Icon: geometric hexagon outline, teal (#14b8a6), ~40×40px, 2px border
- Text: "CHEMBOND" in Pixelify Sans Bold, teal, glow effect; "ADVENTURE" below in smaller Pixelify Sans Regular, #cfeae6, letter-spaced
- Separator line below full logo: horizontal teal gradient line
- Export: PNG with transparency, ~320×80px
- **Tool:** Figma MCP → export PNG

### Background

Two layers composited in Godot:

**Layer 1 — Grid tile (`assets/ui/bg_grid.png`)**
- 64×64px PNG, dark navy base (#070b14), teal grid lines (#14b8a6 at 12% opacity), 0.5px stroke
- Tiled as `TextureRect` with `TILE` repeat mode, covering full viewport
- **Tool:** Figma MCP → export PNG

**Layer 2 — Floating atom particles (GDScript, no asset)**
- Colored dots matching element color system: H=cyan, O=red, C=gray, Na=yellow, Cl=green, N=blue
- 12–20 dots, sizes 3–8px, random positions, slow drift via tween
- Already partially implemented in `main_menu.gd` floating atoms — extend with element colors and varied sizes
- Rendered as `ColorRect` children added at runtime

### Node structure in `main_menu.tscn`

```
MainMenu (Node2D)
├── BgGrid (TextureRect)          ← new, bg_grid.png tiled
├── AtomParticles (Node2D)        ← new, colored dots added at runtime
├── Logo (TextureRect)            ← new, logo.png
├── VBox (existing buttons)
└── ...
```

---

## Element Pickup Redesign

**Style:** Atom orb + orbital ring. Orb is grayscale pixel art from PixelLab; Godot modulates to element color. Ring is a separate teal dashed sprite that rotates continuously.

### Assets

| Asset | Tool | Size | Notes |
|---|---|---|---|
| `assets/sprites/atom_orb.png` | PixelLab MCP | 32×32px | Neutral grayscale pixel art orb. No color — Godot modulates. |
| `assets/sprites/atom_ring.png` | Figma MCP | 40×40px | Dashed circle ring, white (#fff), transparent bg. Godot modulates to element color at 60% opacity. |

### PixelLab prompt for `atom_orb.png`

> "Pixel art atom orb, 32×32, grayscale, circular glowing sphere with subtle inner highlight and dark shadow, clean edges, no background, transparent, top-down view, game sprite style"

### `element_pickup.tscn` scene structure

```
ElementPickup (Area2D)
├── CollisionShape2D
├── OrbSprite (Sprite2D)          ← atom_orb.png, modulated to element color
├── RingSprite (Sprite2D)         ← atom_ring.png, modulated to element color 60% alpha, rotates
└── Label                         ← element symbol, Pixelify Sans Bold, element color
```

### `element_pickup.gd` changes

- `_ready()`: set `OrbSprite.texture`, `RingSprite.texture`; apply `element_colors[element_symbol]` to both; start ring rotation tween (continuous, 3s full rotation)
- Remove old `$Sprite2D.scale = Vector2(0.5, 0.5)` line — new sprites sized correctly at 32×32
- Bobbing tween: move to `OrbSprite` and `Label` (same as before, different node name)
- Glow pulse: move to `OrbSprite.modulate:a` (same logic)
- `set_tutorial_highlight()` / `clear_tutorial_highlight()`: unchanged in logic, update node ref from `self.scale` — scale tweens still apply to root node

### Ring rotation tween

```gdscript
var ring_tween = create_tween().set_loops()
ring_tween.tween_property($RingSprite, "rotation", TAU, 3.0).set_ease(Tween.EASE_IN_OUT)
```

---

## HUD Button Icons

Three 16×16px PNG icons replace text-only buttons:

| Icon | Symbol | File | Button |
|---|---|---|---|
| Reset | ↺ | `assets/ui/icon_reset.png` | `ResetBtn` |
| Leave | ✕ | `assets/ui/icon_leave.png` | `LeaveBtn` |
| Next | → | `assets/ui/icon_next.png` | `NextBtn` (WinOverlay) |

**Style:** Pixelify Sans symbol rendered in teal (#5eead4), transparent background, 16×16px.
**Tool:** Figma MCP → export PNG each.

**Integration:** `main.gd` or scene — set `Button.icon = load("res://assets/ui/icon_reset.png")`. Keep text label alongside icon or replace with tooltip.

---

## `ui_theme.gd` Font Integration

```gdscript
static func create_game_theme() -> Theme:
    var theme = Theme.new()
    var font_regular = load("res://assets/fonts/PixelifySans-Regular.ttf")
    var font_bold    = load("res://assets/fonts/PixelifySans-Bold.ttf")
    theme.set_default_font(font_regular)
    theme.set_default_font_size(16)
    # ... existing styleboxes unchanged ...
    return theme
```

Bold variant applied per-node where needed: `$Label.add_theme_font_override("font", font_bold)`.

---

## File Map

```
assets/
├── fonts/
│   ├── PixelifySans-Regular.ttf    ← user downloads from Google Fonts
│   └── PixelifySans-Bold.ttf       ← user downloads from Google Fonts
├── ui/
│   ├── logo.png                    ← Figma MCP
│   ├── bg_grid.png                 ← Figma MCP
│   ├── icon_reset.png              ← Figma MCP
│   ├── icon_leave.png              ← Figma MCP
│   └── icon_next.png               ← Figma MCP
└── sprites/
    ├── atom_orb.png                ← PixelLab MCP
    └── atom_ring.png               ← Figma MCP
```

```
scripts/
├── ui_theme.gd     ← load Pixelify Sans, set as default font
├── main_menu.gd    ← add BgGrid TextureRect, atom particles, Logo TextureRect
└── element_pickup.gd ← swap sprites, add ring rotation tween
scenes/
└── element_pickup.tscn ← add OrbSprite + RingSprite nodes
```

---

## Edge Cases

| Scenario | Behaviour |
|---|---|
| Font TTF missing | Godot falls back to default font. No crash. Log warning. |
| PixelLab credits exhausted | Fall back to existing `element.png` sprite — color modulation still works |
| atom_ring.png missing | `RingSprite` invisible, rest of pickup unaffected |
| Logo PNG missing | TextureRect shows nothing — menu still functional |
| Atom particles overlap UI | AtomParticles `z_index = -1`, always behind buttons |
