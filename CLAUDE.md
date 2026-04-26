# ChemBond Adventure — CLAUDE.md

Godot 4.6 project. Chemistry maze game where the player collects exact element combinations to form molecules, then exits the maze.

---

## Project Layout

```
chemistry-maze/
├── project.godot          # App name: "ChemBond Adventure", entry: main_menu.tscn
├── assets/
│   ├── questions.json     # All 10 level questions + required element dicts
│   ├── sprites/           # player.png, element.png, gate_locked.png, gate_open.png
│   │                      # joystick_base.png, joystick_handle.png
│   ├── audio/
│   │   ├── music/ambient.wav
│   │   └── sfx/           # collect, gate_unlock, level_complete, game_complete,
│   │                      # ui_click, footstep, reset
│   ├── shaders/
│   │   ├── vignette.gdshader
│   │   └── glow.gdshader
│   └── tiles.png + tileset.tres
├── scenes/
│   ├── main_menu.tscn     # Start screen
│   ├── main.tscn          # Core gameplay scene (spawns everything at runtime)
│   ├── maze.tscn          # TileMapLayer + MazeManager script
│   ├── player.tscn        # CharacterBody2D
│   ├── element_pickup.tscn# Area2D collectible
│   ├── exit_gate.tscn     # Area2D goal
│   └── virtual_joystick.tscn
└── scripts/
    ├── game_manager.gd    # AUTOLOAD — level state, question loading
    ├── audio_manager.gd   # AUTOLOAD — sfx + music
    ├── main.gd            # Orchestrates level load, spawning, HUD, transitions
    ├── maze_manager.gd    # ASCII→TileMap, spawn validation
    ├── level_generator.gd # BFS pathfinding helpers (class_name LevelGenerator)
    ├── player.gd          # Movement, element collection, trail
    ├── element_pickup.gd  # Collectible behavior + VFX
    ├── exit_gate.gd       # Win condition checker
    ├── main_menu.gd       # Menu + floating atoms animation
    ├── virtual_joystick.gd# Touch input → joystick_vector signal
    └── ui_theme.gd        # class_name UITheme, static create_game_theme()
```

---

## Autoloads (Global Singletons)

| Name | File | Responsibility |
|---|---|---|
| `GameManager` | `game_manager.gd` | `current_level: int`, loads `questions.json` into `questions[]` |
| `AudioManager` | `audio_manager.gd` | `play_sfx(name)`, `play_music()`, `stop_music()` |

---

## Core Game Flow

```
main_menu.tscn
  └─ _on_start_pressed() → GameManager.current_level = 0 → change_scene main.tscn

main.tscn (_ready)
  1. Apply UITheme to HUD panels
  2. current_maze = maze.tscn.instantiate() → maze_manager.load_maze(current_level)
     → returns { walkable:[], start:Vector2i, exit:Vector2i, name:String }
  3. get_current_question() → { required: {"H":2,"O":1}, question: "..." }
  4. get_validated_spawns(maze_data, required, decoy_count) → {Vector2i: symbol}
  5. Spawn Player at start tile
  6. Spawn ElementPickup for each spawn_plan entry
  7. Spawn ExitGate at exit tile with required_elements dict
  8. Setup vignette shader overlay

Gameplay loop:
  Player moves → check_precision_collection() → element.collect()
    → player._on_element_collected(symbol) → collected_signal.emit()
    → main._on_player_collected() → gate.check_requirements(inventory)
    → if exact match: gate opens
  Player touches open gate → gate.level_completed.emit()
    → main._on_exit_reached() → WinOverlay or MasterOverlay (level 9)

Progression:
  NextBtn → GameManager.next_level() → reload_current_scene()
  R key   → reload_current_scene() (reset current level)
  Level jump buttons (LevelSelector) → GameManager.current_level = idx → reload
```

---

## Questions / Levels (`assets/questions.json`)

Each entry: `{ "id", "formula", "required": {symbol: count}, "question": "..." }`

| Level | Formula | Required |
|---|---|---|
| 0 | H₂O | H×2, O×1 |
| 1 | CO₂ | C×1, O×2 |
| 2 | CH₄ | C×1, H×4 |
| 3 | NaCl | Na×1, Cl×1 |
| 4 | H₂SO₄ | H×2, S×1, O×4 |
| 5 | NaOH | Na×1, O×1, H×1 |
| 6 | NH₄Cl | N×1, H×4, Cl×1 |
| 7 | Ca(OH)₂ | Ca×1, O×2, H×2 |
| 8 | Na₂CO₃ | Na×2, C×1, O×3 |
| 9 | CH₃COOH | C×2, H×4, O×2 |

To add levels: append to `questions.json` AND add ASCII layout to `maze_manager.gd layouts[]`. Update the win-check in `main.gd:_on_exit_reached()` (currently hardcoded `current_level == 9`).

---

## Maze System

**Format:** 20×15 ASCII strings in `maze_manager.gd layouts[]`

| Char | Meaning |
|---|---|
| `#` | Wall — creates StaticBody2D collision + tile 1,0 |
| `.` | Floor — walkable, checkerboard dark-blue bg |
| `S` | Start position (tile 2,0) |
| `E` | Exit position (tile 3,0) |

Tile size: **16×16 px**. Maze scaled 3× in MazeContainer. Player position: `Vector2(coord * 16) + Vector2(8,8)`.

---

## Spawn Validation (`maze_manager.get_validated_spawns`)

1. BFS from start + exit → find "zone_b" (tiles not adjacent to start or exit)
2. Cap total elements at 40% of zone_b tiles
3. Place required elements first (random shuffle, spacing check)
4. Place decoys — only if they don't block path to any required element
5. Verify all required tiles reachable from start AND can reach exit
6. Retry up to 20 times on failure

Decoy pool: required symbols + `["Cl","Na","Mg","S","K","Ca","N","Si","Fe","Cu","Zn","H","O","C"]`

---

## Exit Gate Logic (`exit_gate.gd`)

Gate opens **only** when `inventory` exactly equals `required_elements`:
- Every required element must match its exact count
- Any extra elements (even 0-count) cause lock — inventory must be a perfect match

---

## Player Collection (`player.gd`)

- `PickupZone` (Area2D child) detects nearby elements → `nearby_elements[]`
- Each physics frame: swept segment check (prev_pos → curr_pos, threshold 10px)
- Collected into `collected_elements: Dictionary = {symbol: count}`
- Signal chain: `element.collected` → `player._on_element_collected` → `player.collected_signal` → `main._on_player_collected`

---

## Element Colors

```
H=Cyan  O=Red  C=Gray  Na=Yellow  Cl=Green  N=Blue
Mg=Orange  Ca=OrangeRed  Si=SaddleBrown  S=YellowGreen
K=MediumPurple  Fe=DarkGray  Cu=Coral  Zn=LightSlateGray
```

---

## Audio Keys

`collect`, `gate_unlock`, `level_complete`, `game_complete`, `ui_click`, `footstep`, `reset`

---

## UI Node Paths (from main.tscn)

```
Main (Node2D, main.gd)
├── MazeContainer (Node2D) ← maze + player + elements added here at runtime
└── UI (CanvasLayer)
    ├── VirtualJoystick
    ├── HUD (Panel) ← navbar style, top of screen
    │   └── HBar (HBoxContainer)
    │       ├── ObjectiveLabel
    │       ├── InventoryLabel
    │       ├── ControlHint
    │       └── ResetBtn
    ├── LevelSelector ← children are level-jump buttons (0..N)
    ├── WinOverlay
    │   └── VBox/NextBtn
    └── MasterOverlay
        └── VBox/RestartBtn
```

---

## Conventions

- All scene spawning happens at runtime in `main.gd._ready()` — scenes are minimal shells
- `LevelGenerator` is `class_name` registered, called as static methods: `LevelGenerator.has_path(...)`, `LevelGenerator.get_bfs_distances(...)`
- `UITheme` is `class_name` registered, static: `UITheme.create_game_theme()`
- Screen shake: `main.screen_shake(intensity, duration)` — tweens MazeContainer position
- Transitions: fade-to-black tween → reload scene (not scene-change)
- Touch emulation enabled (`pointing/emulate_touch_from_mouse=true`)
