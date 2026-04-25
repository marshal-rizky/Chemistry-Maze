# Tutorial Stage & Legend Stage — Design Spec
**Date:** 2026-04-25
**Project:** ChemBond Adventure (Godot 4.6)

---

## Overview

Two new features:
1. **Tutorial Stage** — interactive dedicated level teaching movement, collection, and exit gate. Accessible via main menu button at any time.
2. **Legend Stage** — 3 ultra-hard levels unlocked after completing all 10 regular levels. Dual-character mirror mechanic. `legend_unlocked = true` by default for testing.

---

## 1. Architecture

### GameManager additions (`game_manager.gd`)

```gdscript
var is_tutorial: bool = false
var tutorial_completed: bool = false
var is_legend_mode: bool = false
var legend_level: int = 0          # 0–2
var legend_unlocked: bool = true   # bypass for testing; prod: require level 9 cleared
var legend_questions: Array = []   # loaded from questions.json where "legend": true
```

`legend_questions[]` is populated on `_ready()` by filtering `questions[]` for entries with `"legend": true`.

### New files

| File | Purpose |
|---|---|
| `scripts/tutorial_manager.gd` | Step sequencer — shows/hides tutorial panels, connects to game signals |
| `scripts/legend_controller.gd` | Reads left player `input_dir`, writes mirrored input to right player each physics frame |

### File touch map

| File | Change |
|---|---|
| `game_manager.gd` | +5 vars, legend_questions[] filter on load |
| `main_menu.gd` | +Tutorial button handler, +Legend button handler, +Legend rules popup |
| `main.gd` | Branch on `is_tutorial` / `is_legend_mode` in `_ready()` |
| `maze_manager.gd` | +`tutorial_layout: String`, +`legend_layouts: Array[String]` (3 entries, 30×20) |
| `player.gd` | +`input_dir: Vector2` (exposed), +`mirror_input: bool`, +`mirror_source: Node` |
| `exit_gate.gd` | +`players_on_gate: int` counter for dual-player win condition |
| `element_pickup.gd` | +P = LimeGreen, +Al = Silver in color map |
| `questions.json` | +3 legend entries (id 11–13) with `"legend": true` field |
| `main.tscn` | +TutorialManager node (hidden by default) |
| `main_menu.tscn` | +Tutorial button, +Legend button, +LegendRulesPopup Panel |

---

## 2. Tutorial Stage

### Main Menu
- "HOW TO PLAY" button added below "START"
- "LEGEND" button below that (purple, grayed out when locked)
- Pressing HOW TO PLAY: sets `GameManager.is_tutorial = true`, `GameManager.current_level = 0`, loads `main.tscn`

### Tutorial Maze
- Dedicated `tutorial_layout` string in `maze_manager.gd` (20×15, simple open layout)
- H₂O: 2×H + 1×O atoms placed far apart to encourage exploration
- No decoy atoms
- S at top-left, E at bottom-right

### TutorialManager Node
Added as child of `main.tscn`. Hidden unless `GameManager.is_tutorial == true`.

Step sequence:

| # | Trigger | Panel text | Advance by |
|---|---|---|---|
| 1 | `_ready()` | "Use WASD / arrows or the joystick to move." | Player moves (velocity ≠ zero) |
| 2 | After step 1 | "Collect the atoms shown in your HUD to form the molecule." (arrow → ObjectiveLabel) | Tap/click |
| 3 | First atom collected (`player.collected_signal`) | "Great! Watch your inventory update." (arrow → InventoryLabel) | Tap/click |
| 4 | Gate opens (all atoms collected) | "Molecule complete! The exit gate is now open — reach it to finish." | Tap/click |
| 5 | Player touches gate | Custom overlay: "Tutorial complete! You're ready to play." + Back to Menu button | Button press |

- Game is **not paused** during panels — player moves freely
- `TutorialManager` connects to `player.collected_signal` and `exit_gate.level_completed`
- Step 1 auto-advances on first non-zero velocity detected in `_physics_process`
- Steps 2–4 dismissable by tap/click OR auto-advance on their trigger condition
- On tutorial win: sets `GameManager.tutorial_completed = true`, returns to main menu (does not call `next_level()`)

---

## 3. Legend Stage

### Unlock
- `GameManager.legend_unlocked = true` by default (testing)
- Production: set `legend_unlocked = true` inside `_on_exit_reached()` when `current_level == 9`
- Legend button on main menu: always visible, enabled only when `legend_unlocked`

### Legend Rules Popup
Shown when Legend button pressed, before scene loads. Simple Panel overlay on `main_menu.tscn`:

> **Legend Mode Rules**
> Two characters appear — you control the left one.
> Moving left or right also moves the other character in the **opposite** direction.
> Moving up or down moves **both** the same way.
> Atoms are split between both halves of the maze.
> Both characters collect into a **shared inventory**.
> Reach the center gate together to win.

Single "Got it!" button → sets legend flags → loads `main.tscn`.

### Maze Layout
- Size: **30×20** ASCII in `legend_layouts[3]` in `maze_manager.gd`
- Left player spawn: left-edge midpoint (col 0, row 10) — `S` tile
- Right player spawn: right-edge midpoint (col 29, row 10) — second `S` tile
- Exit gate: exact center (col 14–15, row 9–10) — `E` tile
- Left half atoms: x < 15 | Right half atoms: x ≥ 15
- BFS validates path from each spawn to center gate independently

### Mirror Mechanic

`player.gd` change:
```gdscript
var input_dir: Vector2 = Vector2.ZERO  # exposed
var mirror_input: bool = false
var mirror_source: Node = null

# in _physics_process():
if mirror_input and mirror_source:
    input_dir = Vector2(-mirror_source.input_dir.x, mirror_source.input_dir.y)
else:
    # existing keyboard + joystick input reading
```

`legend_controller.gd`:
```gdscript
# holds refs to player_left and player_right
# _physics_process: nothing extra needed — player_right reads mirror_source directly
```

Right player setup in `main.gd` when `is_legend_mode`:
```gdscript
player_right.mirror_input = true
player_right.mirror_source = player_left
player_right.modulate = Color(0.8, 0.6, 1.0)  # purple tint to distinguish
```

### Atom Distribution
- Required atoms split: ⌊n/2⌋ of each element type → left half, remainder → right half
- Example C₆H₁₂O₆: C×3 left + C×3 right, H×6 left + H×6 right, O×3 left + O×3 right
- Odd counts (e.g. Ca×3): 1 left + 2 right (or vice versa — implementation choice)
- `get_validated_spawns()` gets a legend variant that accepts a `half: String` param ("left"/"right") and filters candidate tiles by x position
- Decoys present in both halves

### Win Condition
`exit_gate.gd` in legend mode:
```gdscript
var players_on_gate: int = 0

func _on_body_entered(body):
    if body is CharacterBody2D:
        players_on_gate += 1
        if players_on_gate == 2 and is_open:
            level_completed.emit()

func _on_body_exited(body):
    if body is CharacterBody2D:
        players_on_gate -= 1
```

Due to mirror sync, both characters arrive simultaneously — `players_on_gate == 2` fires naturally.

### Legend Progression
- After each legend win: `legend_level += 1`, reload scene
- After L3 win (`legend_level == 2`): show "LEGENDARY CHEMIST" master overlay (separate from regular `MasterOverlay`)
- Level selector buttons: L1 / L2 / L3 (same pattern as existing level buttons)

### New Element Colors
Added to color map in `element_pickup.gd`:

| Element | Color |
|---|---|
| P (Phosphorus) | LimeGreen |
| Al (Aluminum) | Silver |

### Legend Questions (`questions.json`)

```json
{ "id": 11, "formula": "C6H12O6",   "required": {"C":6,"H":12,"O":6},  "question": "What simple sugar fuels every living cell in your body?",           "legend": true },
{ "id": 12, "formula": "Ca3(PO4)2", "required": {"Ca":3,"P":2,"O":8},  "question": "What mineral compound forms your bones and teeth?",                   "legend": true },
{ "id": 13, "formula": "Al2(SO4)3", "required": {"Al":2,"S":3,"O":12}, "question": "What compound is added to water treatment plants to remove impurities?", "legend": true }
```

---

## Implementation Notes

- Tutorial and legend modes are fully gated by GameManager flags — zero impact on regular levels
- `is_tutorial`, `is_legend_mode`, and `legend_level` are all reset when returning to main menu
- Legend maze ASCII layouts need manual design ensuring BFS-valid paths + good puzzle flow
- `legend_unlocked = true` default — flip to conditional check before shipping
