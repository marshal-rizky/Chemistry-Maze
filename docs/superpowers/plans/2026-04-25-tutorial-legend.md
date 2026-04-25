# Tutorial Stage & Legend Stage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an interactive tutorial level and a 3-stage legend mode with a dual-character mirror mechanic to ChemBond Adventure.

**Architecture:** Tutorial and legend modes are gated by flags in GameManager (`is_tutorial`, `is_legend_mode`). `main.gd._ready()` branches on these flags to set up the correct mode. All existing regular-level code paths are untouched.

**Tech Stack:** Godot 4.6, GDScript, existing scene/signal architecture.

---

## Task 1: GameManager — add mode flags and load legend questions

**Files:**
- Modify: `scripts/game_manager.gd`
- Modify: `assets/questions.json`

- [ ] **Step 1: Add legend entries to questions.json**

Open `assets/questions.json`. Append 3 entries before the closing `]`:

```json
[
  { "id": 1, "formula": "H2O", "required": {"H": 2, "O": 1}, "question": "What liquid do all living things need to survive?" },
  { "id": 2, "formula": "CO2", "required": {"C": 1, "O": 2}, "question": "What gas do you exhale with every breath?" },
  { "id": 3, "formula": "CH4", "required": {"C": 1, "H": 4}, "question": "What flammable gas is the main component of natural gas?" },
  { "id": 4, "formula": "NaCl", "required": {"Na": 1, "Cl": 1}, "question": "What compound seasons your food and preserves meat?" },
  { "id": 5, "formula": "H2SO4", "required": {"H": 2, "S": 1, "O": 4}, "question": "What powerful acid is used in car batteries?" },
  { "id": 6, "formula": "NaOH", "required": {"Na": 1, "O": 1, "H": 1}, "question": "What caustic base is used to make soap?" },
  { "id": 7, "formula": "NH4Cl", "required": {"N": 1, "H": 4, "Cl": 1}, "question": "What salt is used in cough medicine and fertilizers?" },
  { "id": 8, "formula": "Ca(OH)2", "required": {"Ca": 1, "O": 2, "H": 2}, "question": "What compound is mixed into cement and treats acidic soil?" },
  { "id": 9, "formula": "Na2CO3", "required": {"Na": 2, "C": 1, "O": 3}, "question": "What washing powder compound softens hard water?" },
  { "id": 10, "formula": "CH3COOH", "required": {"C": 2, "H": 4, "O": 2}, "question": "What acid gives vinegar its sour taste and sharp smell?" },
  { "id": 11, "formula": "C6H12O6", "required": {"C": 6, "H": 12, "O": 6}, "question": "What simple sugar fuels every living cell in your body?", "legend": true },
  { "id": 12, "formula": "Ca3(PO4)2", "required": {"Ca": 3, "P": 2, "O": 8}, "question": "What mineral compound forms your bones and teeth?", "legend": true },
  { "id": 13, "formula": "Al2(SO4)3", "required": {"Al": 2, "S": 3, "O": 12}, "question": "What compound is added to water treatment plants to remove impurities?", "legend": true }
]
```

- [ ] **Step 2: Add flags and legend_questions to game_manager.gd**

Replace the entire file:

```gdscript
extends Node

var questions: Array = []
var legend_questions: Array = []
var current_level: int = 0

var is_tutorial: bool = false
var tutorial_completed: bool = false
var is_legend_mode: bool = false
var legend_level: int = 0
var legend_unlocked: bool = true  # set false before shipping; require level 9 clear

func _ready():
	load_questions()
	print("GameManager: Questions loaded.")

func load_questions():
	if not FileAccess.file_exists("res://assets/questions.json"):
		print("ERROR: questions.json not found!")
		return
	var file = FileAccess.open("res://assets/questions.json", FileAccess.READ)
	var content = file.get_as_text()
	var all_questions = JSON.parse_string(content)
	for q in all_questions:
		if q.get("legend", false):
			legend_questions.append(q)
		else:
			questions.append(q)

func get_current_question():
	if is_legend_mode:
		if legend_level < legend_questions.size():
			return legend_questions[legend_level]
		return null
	if current_level < questions.size():
		return questions[current_level]
	return null

func next_level():
	if is_legend_mode:
		legend_level += 1
		if legend_level >= legend_questions.size():
			legend_level = 0
		return legend_level
	current_level += 1
	if current_level >= questions.size():
		current_level = 0
	return current_level

func reset_mode_flags():
	is_tutorial = false
	is_legend_mode = false
	legend_level = 0
```

- [ ] **Step 3: Verify in Godot editor**

Open Godot. Check Output panel — no parse errors on load. `GameManager` autoload should initialize without error.

- [ ] **Step 4: Commit**

```bash
git add assets/questions.json scripts/game_manager.gd
git commit -m "feat: add GameManager mode flags and legend questions"
```

---

## Task 2: New element colors (P and Al)

**Files:**
- Modify: `scripts/element_pickup.gd`

- [ ] **Step 1: Add P and Al to element_colors dict**

In `element_pickup.gd`, find the `element_colors` dict and add two entries:

```gdscript
var element_colors = {
	"H": Color.CYAN,
	"O": Color.RED,
	"C": Color.GRAY,
	"Na": Color.YELLOW,
	"Cl": Color.GREEN,
	"N": Color.BLUE,
	"Mg": Color.ORANGE,
	"Ca": Color.ORANGE_RED,
	"Si": Color.SADDLE_BROWN,
	"S": Color.YELLOW_GREEN,
	"K": Color.MEDIUM_PURPLE,
	"Fe": Color.DARK_GRAY,
	"Cu": Color.CORAL,
	"Zn": Color.LIGHT_SLATE_GRAY,
	"P": Color.LIME_GREEN,
	"Al": Color.SILVER
}
```

- [ ] **Step 2: Commit**

```bash
git add scripts/element_pickup.gd
git commit -m "feat: add P and Al element colors for legend stage"
```

---

## Task 3: Tutorial maze layout

**Files:**
- Modify: `scripts/maze_manager.gd`

- [ ] **Step 1: Add tutorial_layout and load_tutorial_maze() to maze_manager.gd**

Add after the `layouts` array declaration (before `load_maze`):

```gdscript
var tutorial_layout = {
	"name": "Tutorial: Water (H2O)",
	"ascii": [
		"####################",
		"#S................##",
		"#..................#",
		"#....[H]...........#",
		"#..................#",
		"#..................#",
		"#.......[Na].......#",
		"#..................#",
		"#...........[H]....#",
		"#..................#",
		"#..................#",
		"#...............[O]#",
		"#..................#",
		"#................E.#",
		"####################"
	]
}
```

> Note: `[H]`, `[Na]`, `[O]` are placeholders for readability only — actual spawning is done at runtime by `main.gd` via `get_validated_spawns`. The ASCII layout only needs `.`, `#`, `S`, `E`. Replace with plain `.`:

```gdscript
var tutorial_layout = {
	"name": "Tutorial: Water (H2O)",
	"ascii": [
		"####################",
		"#S.................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#................E.#",
		"####################"
	]
}
```

- [ ] **Step 2: Add load_tutorial_maze() method**

Add this method to `maze_manager.gd` after `load_maze()`:

```gdscript
func load_tutorial_maze():
	var ascii_rows = tutorial_layout.ascii
	tilemap.clear()
	for child in tilemap.get_children():
		child.queue_free()

	var floor_tiles = []
	var start_pos = Vector2i(1, 1)
	var exit_pos = Vector2i(1, 1)

	for y in range(ascii_rows.size()):
		var row = ascii_rows[y]
		for x in range(row.length()):
			var c = row[x]
			var coord = Vector2i(x, y)
			match c:
				"#":
					tilemap.set_cell(coord, 0, Vector2i(1, 0))
					var wall_body = StaticBody2D.new()
					wall_body.position = Vector2(x * 16 + 8, y * 16 + 8)
					var col_shape = CollisionShape2D.new()
					var rect = RectangleShape2D.new()
					rect.size = Vector2(16, 16)
					col_shape.shape = rect
					wall_body.add_child(col_shape)
					tilemap.add_child(wall_body)
				".", "S", "E":
					floor_tiles.append(coord)
					tilemap.set_cell(coord, 0, Vector2i(0, 0))
					var floor_bg = ColorRect.new()
					floor_bg.size = Vector2(16, 16)
					floor_bg.position = Vector2(x * 16, y * 16)
					floor_bg.color = Color("#0f0f23") if (x + y) % 2 == 0 else Color("#121230")
					floor_bg.z_index = -1
					tilemap.add_child(floor_bg)
					if c == "S":
						start_pos = coord
						tilemap.set_cell(coord, 0, Vector2i(2, 0))
					elif c == "E":
						exit_pos = coord
						tilemap.set_cell(coord, 0, Vector2i(3, 0))

	print("Loaded tutorial maze")
	return {"walkable": floor_tiles, "start": start_pos, "exit": exit_pos, "name": tutorial_layout.name}
```

- [ ] **Step 3: Add legend_layouts array and load_legend_maze() method**

Add after `tutorial_layout`:

```gdscript
var legend_layouts = [
	{ "name": "Legend I: Glucose (C6H12O6)", "ascii": [
		"##############################",
		"#............................#",
		"#.###.###.###.###.###.###.#..#",
		"#.#...#...#...#...#.....#.#..#",
		"#.###.#...###.###.###...#.#..#",
		"#...#.#...#...#...#.....#.#..#",
		"#.###.###.###.#...###.###.#..#",
		"#............................#",
		"#............................#",
		"#............................#",
		"S............................S",
		"#............................#",
		"#............................#",
		"#............................#",
		"#.###.###.###.###.###.###.#..#",
		"#...#.#...#...#...#.....#.#..#",
		"#.###.#...###.###.###...#.#..#",
		"#...#.#...#...#...#.....#.#..#",
		"#.###.###.###.#...###.###.#..#",
		"##############################"
	]},
	{ "name": "Legend II: Calcium Phosphate (Ca3(PO4)2)", "ascii": [
		"##############################",
		"#............................#",
		"#.##.###.##.###.##.###.##.##.#",
		"#..#...#..#...#..#...#..#..#.#",
		"#.##.#.##.##.#.#.##.#.##.##.##",
		"#....#....#..#.#..#.#....#...#",
		"#.####.####.##.##.#.####.####.#",
		"#............................#",
		"#............................#",
		"#............................#",
		"S..............E.............S",
		"#............................#",
		"#............................#",
		"#............................#",
		"#.##.###.##.###.##.###.##.##.#",
		"#..#...#..#...#..#...#..#..#.#",
		"#.##.#.##.##.#.#.##.#.##.##.##",
		"#....#....#..#.#..#.#....#...#",
		"#.####.####.##.##.#.####.####.#",
		"##############################"
	]},
	{ "name": "Legend III: Aluminum Sulfate (Al2(SO4)3)", "ascii": [
		"##############################",
		"#............................#",
		"#.##.##.##.###.##.##.##.##.###",
		"#..#..#..#...#..#..#..#..#..##",
		"#.##.##.##.#.##.##.##.##.##.##",
		"#....#....#.#....#....#....#.#",
		"#.####.####.#.####.####.####.#",
		"#............................#",
		"#............................#",
		"#............................#",
		"S..............E.............S",
		"#............................#",
		"#............................#",
		"#............................#",
		"#.##.##.##.###.##.##.##.##.###",
		"#..#..#..#...#..#..#..#..#..##",
		"#.##.##.##.#.##.##.##.##.##.##",
		"#....#....#.#....#....#....#.#",
		"#.####.####.#.####.####.####.#",
		"##############################"
	]}
]
```

> **Important:** These 30×20 ASCII layouts use `S` at col 0 row 10 AND col 29 row 10, and `E` at col 14 row 10. The `load_legend_maze()` method below handles two `S` tiles by returning both spawn positions.

- [ ] **Step 4: Add load_legend_maze() method**

```gdscript
func load_legend_maze(index: int):
	if index < 0 or index >= legend_layouts.size():
		print("ERROR: Legend maze index out of bounds: ", index)
		return null

	var layout = legend_layouts[index]
	var ascii_rows = layout.ascii
	tilemap.clear()
	for child in tilemap.get_children():
		child.queue_free()

	var floor_tiles = []
	var start_left = Vector2i(0, 10)
	var start_right = Vector2i(29, 10)
	var exit_pos = Vector2i(14, 10)
	var found_starts = []

	for y in range(ascii_rows.size()):
		var row = ascii_rows[y]
		for x in range(row.length()):
			var c = row[x]
			var coord = Vector2i(x, y)
			match c:
				"#":
					tilemap.set_cell(coord, 0, Vector2i(1, 0))
					var wall_body = StaticBody2D.new()
					wall_body.position = Vector2(x * 16 + 8, y * 16 + 8)
					var col_shape = CollisionShape2D.new()
					var rect = RectangleShape2D.new()
					rect.size = Vector2(16, 16)
					col_shape.shape = rect
					wall_body.add_child(col_shape)
					tilemap.add_child(wall_body)
				".", "S", "E":
					floor_tiles.append(coord)
					tilemap.set_cell(coord, 0, Vector2i(0, 0))
					var floor_bg = ColorRect.new()
					floor_bg.size = Vector2(16, 16)
					floor_bg.position = Vector2(x * 16, y * 16)
					floor_bg.color = Color("#0f0f23") if (x + y) % 2 == 0 else Color("#121230")
					floor_bg.z_index = -1
					tilemap.add_child(floor_bg)
					if c == "S":
						tilemap.set_cell(coord, 0, Vector2i(2, 0))
						found_starts.append(coord)
					elif c == "E":
						exit_pos = coord
						tilemap.set_cell(coord, 0, Vector2i(3, 0))

	if found_starts.size() >= 2:
		# left spawn has smaller x
		if found_starts[0].x < found_starts[1].x:
			start_left = found_starts[0]
			start_right = found_starts[1]
		else:
			start_left = found_starts[1]
			start_right = found_starts[0]

	print("Loaded legend maze: ", layout.name)
	return {
		"walkable": floor_tiles,
		"start": start_left,
		"start_right": start_right,
		"exit": exit_pos,
		"name": layout.name
	}
```

- [ ] **Step 5: Commit**

```bash
git add scripts/maze_manager.gd
git commit -m "feat: add tutorial and legend maze layouts"
```

---

## Task 4: TutorialManager script

**Files:**
- Create: `scripts/tutorial_manager.gd`

- [ ] **Step 1: Create tutorial_manager.gd**

```gdscript
extends Node

# TutorialManager — injected into main.tscn, active only when GameManager.is_tutorial

var current_step: int = 0
var step_complete: bool = false

var player: CharacterBody2D = null
var exit_gate: Node = null

# Panel references (set by main.gd after spawning)
var panel: Panel = null
var panel_label: RichTextLabel = null
var dismiss_btn: Button = null

var steps = [
	{
		"text": "[b]Step 1:[/b] Use [b]WASD[/b] / Arrow Keys or the [b]joystick[/b] to move.",
		"trigger": "move",
		"arrow_target": ""
	},
	{
		"text": "[b]Objective:[/b] Collect the atoms shown in your [b]HUD[/b] to form the molecule.",
		"trigger": "tap",
		"arrow_target": "objective"
	},
	{
		"text": "[b]Good![/b] Walk over atoms to collect them. Watch your [b]inventory[/b] update.",
		"trigger": "tap",
		"arrow_target": "inventory"
	},
	{
		"text": "[color=yellow]⚠ Warning:[/color] Only collect the atoms you [b]need[/b]. Extra atoms will keep the gate [b]locked![/b]",
		"trigger": "tap",
		"arrow_target": ""
	},
	{
		"text": "Picked up the wrong atom? Press [b]R[/b] or tap [b]Reset[/b] to restart the level.",
		"trigger": "tap",
		"arrow_target": "reset"
	},
	{
		"text": "[b]Molecule complete![/b] The exit gate is now open — reach it to finish.",
		"trigger": "tap",
		"arrow_target": ""
	}
	# Step 7 (win) is handled by main.gd showing TutorialWinOverlay
]

var atom_collected_once: bool = false
var gate_opened: bool = false

func setup(p: CharacterBody2D, gate: Node):
	player = p
	exit_gate = gate
	player.collected_signal.connect(_on_atom_collected)
	show_step(0)

func _physics_process(_delta):
	if not is_instance_valid(player): return
	if current_step == 0 and not step_complete:
		if player.velocity.length() > 0.1:
			advance_step()

func show_step(index: int):
	if index >= steps.size(): return
	current_step = index
	step_complete = false
	var step = steps[index]
	panel_label.text = step.text
	panel.visible = true

func advance_step():
	if step_complete: return
	step_complete = true
	panel.visible = false
	var next = current_step + 1
	if next < steps.size():
		show_step(next)

func _on_atom_collected(_symbol):
	if current_step == 2 and not atom_collected_once:
		atom_collected_once = true
		advance_step()

func notify_gate_opened():
	if current_step == 4:
		advance_step()
	gate_opened = true

func _on_dismiss_pressed():
	if steps[current_step].trigger == "tap":
		advance_step()
```

- [ ] **Step 2: Commit**

```bash
git add scripts/tutorial_manager.gd
git commit -m "feat: add TutorialManager step sequencer"
```

---

## Task 5: player.gd — expose input_dir and add mirror support

**Files:**
- Modify: `scripts/player.gd`

- [ ] **Step 1: Add mirror vars and expose input_dir**

Replace the variable declarations at the top of `player.gd` (lines 1–14) with:

```gdscript
extends CharacterBody2D

@export var speed: float = 360.0

var collected_elements: Dictionary = {}
signal collected_signal(symbol)

var nearby_elements: Array = []
const COLLECTION_THRESHOLD: float = 10.0

var trail_timer: float = 0.0
const TRAIL_INTERVAL: float = 0.05
var touch_vector: Vector2 = Vector2.ZERO
var prev_position: Vector2 = Vector2.ZERO

var input_dir: Vector2 = Vector2.ZERO   # exposed for mirror mechanic
var mirror_input: bool = false
var mirror_source: Node = null
```

- [ ] **Step 2: Update _physics_process to use input_dir and respect mirror_input**

Replace the `_physics_process` function:

```gdscript
func _physics_process(delta):
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	prev_position = global_position

	if mirror_input and is_instance_valid(mirror_source):
		input_dir = Vector2(-mirror_source.input_dir.x, mirror_source.input_dir.y)
	else:
		var kb_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		input_dir = kb_direction
		if touch_vector.length() > 0:
			input_dir = touch_vector

	velocity = input_dir * speed
	move_and_slide()

	var actually_moved = global_position.distance_to(prev_position) > 0.1
	if actually_moved:
		trail_timer += delta
		if trail_timer >= TRAIL_INTERVAL:
			spawn_trail()
			trail_timer = 0.0
			AudioManager.play_sfx("footstep")

	check_precision_collection()
```

- [ ] **Step 3: Commit**

```bash
git add scripts/player.gd
git commit -m "feat: expose input_dir and add mirror_input support to player"
```

---

## Task 6: exit_gate.gd — dual-player win condition

**Files:**
- Modify: `scripts/exit_gate.gd`

- [ ] **Step 1: Add players_on_gate counter and update _on_body_entered**

Replace `exit_gate.gd` fully:

```gdscript
extends Area2D

signal level_completed

@export var required_elements: Dictionary = {"H": 2, "O": 1}
var is_open: bool = false
var pulse_tween: Tween
var players_on_gate: int = 0
var legend_mode: bool = false  # set by main.gd when spawning in legend mode

var tex_locked: Texture2D = preload("res://assets/sprites/gate_locked.png")
var tex_open: Texture2D = preload("res://assets/sprites/gate_open.png")

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	update_visuals()
	start_pulse()

func start_pulse():
	if pulse_tween: pulse_tween.kill()
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property($Sprite2D, "modulate:v", 1.5, 0.6)
	pulse_tween.tween_property($Sprite2D, "modulate:v", 1.0, 0.6)

func update_visuals():
	if is_open:
		$Sprite2D.texture = tex_open
		$Sprite2D.modulate = Color.WHITE
		$Label.text = "OPEN"
		$Label.add_theme_color_override("font_color", Color.GREEN)
	else:
		$Sprite2D.texture = tex_locked
		$Sprite2D.modulate = Color.WHITE
		$Label.text = "LOCKED"
		$Label.add_theme_color_override("font_color", Color.DARK_RED)

func check_requirements(inventory: Dictionary):
	var all_met = true
	for element in required_elements:
		if inventory.get(element, 0) != required_elements[element]:
			all_met = false
			break
	if all_met:
		for element in inventory:
			var count = inventory[element]
			if count == 0: continue
			if not required_elements.has(element) or count != required_elements[element]:
				all_met = false
				break
	if all_met:
		if not is_open:
			is_open = true
			update_visuals()
			AudioManager.play_sfx("gate_unlock")
	else:
		if is_open:
			is_open = false
			update_visuals()

func _on_body_entered(body):
	if not (body is CharacterBody2D): return
	if legend_mode:
		players_on_gate += 1
		if players_on_gate >= 2 and is_open:
			level_completed.emit()
	else:
		if is_open:
			level_completed.emit()

func _on_body_exited(body):
	if legend_mode and body is CharacterBody2D:
		players_on_gate = max(0, players_on_gate - 1)
```

- [ ] **Step 2: Commit**

```bash
git add scripts/exit_gate.gd
git commit -m "feat: add dual-player win condition to exit gate"
```

---

## Task 7: main.gd — tutorial and legend branching

**Files:**
- Modify: `scripts/main.gd`

- [ ] **Step 1: Add tutorial branch in _ready()**

After the existing `# 1. Load Maze` block, replace lines 36–88 with the following full `_ready()` body:

```gdscript
func _ready():
	print("!!! MAIN STARTING !!!")

	var game_theme = UITheme.create_game_theme()
	$UI/HUD.theme = game_theme
	$UI/LevelSelector.theme = game_theme
	$UI/WinOverlay.theme = game_theme
	$UI/MasterOverlay.theme = game_theme

	var navbar_style = StyleBoxFlat.new()
	navbar_style.bg_color = Color(0.04, 0.04, 0.12, 0.75)
	navbar_style.border_color = Color(0.0, 0.4, 0.5, 0.4)
	navbar_style.border_width_bottom = 1
	navbar_style.set_corner_radius_all(0)
	navbar_style.set_content_margin_all(6)
	$UI/HUD.add_theme_stylebox_override("panel", navbar_style)

	$UI/WinOverlay/VBox/NextBtn.pressed.connect(func(): AudioManager.play_sfx("ui_click"); _on_next_level_pressed())
	$UI/MasterOverlay/VBox/RestartBtn.pressed.connect(func(): AudioManager.play_sfx("ui_click"); _on_restart_game_pressed())
	$UI/HUD/HBar/ResetBtn.pressed.connect(func(): AudioManager.play_sfx("reset"); get_tree().reload_current_scene())

	var selector = $UI/LevelSelector
	for i in range(selector.get_child_count()):
		var btn = selector.get_child(i)
		var level_idx = i
		btn.pressed.connect(func(): AudioManager.play_sfx("ui_click"); _on_level_jump(level_idx))

	var maze_container = $MazeContainer
	var maze_scene = load("res://scenes/maze.tscn")
	current_maze = maze_scene.instantiate()
	maze_container.add_child(current_maze)

	var maze_data
	if GameManager.is_tutorial:
		maze_data = current_maze.load_tutorial_maze()
	elif GameManager.is_legend_mode:
		maze_data = current_maze.load_legend_maze(GameManager.legend_level)
	else:
		maze_data = current_maze.load_maze(GameManager.current_level)

	if not maze_data: return

	maze_container.scale = Vector2(3.0, 3.0) if not GameManager.is_legend_mode else Vector2(2.0, 2.0)
	maze_container.position = Vector2(640.0 - (maze_container.scale.x * 240.0), 360.0 - (maze_container.scale.y * 160.0))

	var current_q = GameManager.get_current_question()
	if not current_q: return

	$UI/HUD/HBar/ObjectiveLabel.text = "Objective: " + current_q.question
	$UI/HUD/HBar/InventoryLabel.text = "Inventory: (empty)"

	var decoy_count = 1 if GameManager.is_tutorial else (6 + GameManager.current_level)
	var spawn_plan = current_maze.get_validated_spawns(maze_data, current_q.required, decoy_count)

	if not spawn_plan:
		get_tree().call_deferred("reload_current_scene")
		return

	var player_scene = load("res://scenes/player.tscn")
	var player = player_scene.instantiate()
	player.name = "Player"
	player.position = Vector2(maze_data.start * 16) + Vector2(8, 8)
	player.collected_signal.connect(_on_player_collected)
	current_maze.add_child(player)

	var pickup_scene = load("res://scenes/element_pickup.tscn")
	for pos in spawn_plan:
		var pickup = pickup_scene.instantiate()
		pickup.element_symbol = spawn_plan[pos]
		pickup.position = Vector2(pos * 16) + Vector2(8, 8)
		current_maze.add_child(pickup)

	var exit_scene = load("res://scenes/exit_gate.tscn")
	var exit_gate = exit_scene.instantiate()
	exit_gate.name = "ExitGate"
	exit_gate.position = Vector2(maze_data.exit * 16) + Vector2(8, 8)
	exit_gate.required_elements = current_q.required
	exit_gate.level_completed.connect(_on_exit_reached)
	current_maze.add_child(exit_gate)

	if GameManager.is_legend_mode:
		exit_gate.legend_mode = true
		_setup_legend_second_player(maze_data, player, current_q.required, spawn_plan)

	if GameManager.is_tutorial:
		_setup_tutorial(player, exit_gate)

	setup_vignette()
	print("!!! LEVEL VALIDATED AND LOADED !!!")
```

- [ ] **Step 2: Add _setup_legend_second_player()**

Add this new method to `main.gd`:

```gdscript
func _setup_legend_second_player(maze_data: Dictionary, player_left: CharacterBody2D, required: Dictionary, spawn_plan: Dictionary):
	var player_scene = load("res://scenes/player.tscn")
	var player_right = player_scene.instantiate()
	player_right.name = "PlayerRight"
	player_right.position = Vector2(maze_data.start_right * 16) + Vector2(8, 8)
	player_right.mirror_input = true
	player_right.mirror_source = player_left
	player_right.modulate = Color(0.8, 0.6, 1.0)
	player_right.collected_signal.connect(_on_player_collected)
	current_maze.add_child(player_right)
```

- [ ] **Step 3: Add _setup_tutorial()**

```gdscript
func _setup_tutorial(player: CharacterBody2D, exit_gate: Node):
	var tm = $UI/TutorialManager
	if not tm: return
	tm.visible = true

	# Build panel UI dynamically
	var panel = Panel.new()
	panel.name = "TutorialPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.custom_minimum_size = Vector2(0, 100)
	panel.offset_top = -110
	panel.offset_bottom = -10
	panel.modulate = Color(1, 1, 1, 0.92)
	tm.add_child(panel)

	var lbl = RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left = 16; lbl.offset_right = -120
	lbl.offset_top = 8; lbl.offset_bottom = -8
	panel.add_child(lbl)

	var btn = Button.new()
	btn.text = "OK"
	btn.set_anchor_and_offset(SIDE_RIGHT, 1.0, -8)
	btn.set_anchor_and_offset(SIDE_LEFT, 1.0, -100)
	btn.set_anchor_and_offset(SIDE_TOP, 0.5, -20)
	btn.set_anchor_and_offset(SIDE_BOTTOM, 0.5, 20)
	panel.add_child(btn)

	tm.panel = panel
	tm.panel_label = lbl
	tm.dismiss_btn = btn
	btn.pressed.connect(tm._on_dismiss_pressed)
	tm.setup(player, exit_gate)
```

- [ ] **Step 4: Update _on_player_collected to route through TutorialManager if active**

Replace `_on_player_collected`:

```gdscript
func _on_player_collected(_symbol):
	var player = current_maze.get_node_or_null("Player")
	if not player: return
	var inventory = player.collected_elements

	# Merge right player inventory in legend mode
	if GameManager.is_legend_mode:
		var player_right = current_maze.get_node_or_null("PlayerRight")
		if player_right:
			for sym in player_right.collected_elements:
				inventory[sym] = inventory.get(sym, 0) + player_right.collected_elements[sym]

	$UI/HUD/HBar/InventoryLabel.text = format_inventory(inventory)
	screen_shake(2.0, 0.1)
	AudioManager.play_sfx("collect")

	var gate = current_maze.get_node_or_null("ExitGate")
	if gate:
		gate.check_requirements(inventory)
		if gate.is_open and GameManager.is_tutorial:
			var tm = get_node_or_null("UI/TutorialManager")
			if tm: tm.notify_gate_opened()
```

- [ ] **Step 5: Update _on_exit_reached for tutorial and legend**

Replace `_on_exit_reached`:

```gdscript
func _on_exit_reached():
	var flash = ColorRect.new()
	flash.color = Color.WHITE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(flash)
	var ft = create_tween()
	ft.tween_property(flash, "modulate:a", 0.0, 0.4)
	ft.tween_callback(flash.queue_free)
	screen_shake(4.0, 0.2)

	if GameManager.is_tutorial:
		GameManager.tutorial_completed = true
		GameManager.is_tutorial = false
		$UI/TutorialWinOverlay.visible = true
		AudioManager.play_sfx("level_complete")
		return

	if GameManager.is_legend_mode:
		if GameManager.legend_level == 2:
			$UI/LegendaryOverlay.visible = true
			AudioManager.play_sfx("game_complete")
		else:
			$UI/WinOverlay.visible = true
			AudioManager.play_sfx("level_complete")
		return

	if GameManager.current_level == 9:
		$UI/MasterOverlay.visible = true
		AudioManager.play_sfx("game_complete")
	else:
		$UI/WinOverlay.visible = true
		AudioManager.play_sfx("level_complete")
```

- [ ] **Step 6: Commit**

```bash
git add scripts/main.gd
git commit -m "feat: branch main.gd for tutorial and legend mode setup"
```

---

## Task 8: main_menu.gd — Tutorial and Legend buttons

**Files:**
- Modify: `scripts/main_menu.gd`

- [ ] **Step 1: Replace main_menu.gd**

```gdscript
extends Control

func _ready():
	theme = UITheme.create_game_theme()
	$VBoxContainer/Title.modulate = Color(0, 1, 1)

	$VBoxContainer/StartBtn.pressed.connect(func(): AudioManager.play_sfx("ui_click"); _on_start_pressed())
	$VBoxContainer/TutorialBtn.pressed.connect(func(): AudioManager.play_sfx("ui_click"); _on_tutorial_pressed())
	$VBoxContainer/LegendBtn.pressed.connect(func(): AudioManager.play_sfx("ui_click"); _on_legend_btn_pressed())
	$VBoxContainer/QuitBtn.pressed.connect(func(): AudioManager.play_sfx("ui_click"); _on_quit_pressed())
	$LegendRulesPopup/GotItBtn.pressed.connect(_on_got_it_pressed)

	$VBoxContainer/LegendBtn.disabled = not GameManager.legend_unlocked
	$LegendRulesPopup.visible = false

	AudioManager.play_music()
	spawn_floating_atoms()

func spawn_floating_atoms():
	var symbols = ["H", "O", "C", "Na", "Cl", "Si"]
	for i in range(12):
		var atom = Label.new()
		atom.text = symbols[randi() % symbols.size()]
		atom.scale = Vector2(2, 2)
		atom.position = Vector2(randf_range(0, 1280), randf_range(0, 720))
		atom.modulate.a = 0.3
		add_child(atom)
		var tween = create_tween().set_loops()
		var target = atom.position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		tween.tween_property(atom, "position", target, randf_range(3.0, 6.0)).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(atom, "position", atom.position, randf_range(3.0, 6.0)).set_ease(Tween.EASE_IN_OUT)

func _on_start_pressed():
	GameManager.reset_mode_flags()
	GameManager.current_level = 0
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_tutorial_pressed():
	GameManager.reset_mode_flags()
	GameManager.is_tutorial = true
	GameManager.current_level = 0
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_legend_btn_pressed():
	$LegendRulesPopup.visible = true

func _on_got_it_pressed():
	$LegendRulesPopup.visible = false
	GameManager.reset_mode_flags()
	GameManager.is_legend_mode = true
	GameManager.legend_level = 0
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_pressed():
	get_tree().quit()
```

- [ ] **Step 2: Commit**

```bash
git add scripts/main_menu.gd
git commit -m "feat: add Tutorial and Legend button handlers to main menu"
```

---

## Task 9: Scene setup — main_menu.tscn

**Files:**
- Modify: `scenes/main_menu.tscn` (via Godot editor or MCP)

- [ ] **Step 1: Add TutorialBtn and LegendBtn to VBoxContainer**

In Godot editor, open `scenes/main_menu.tscn`. In the `VBoxContainer`, add two new `Button` nodes between `StartBtn` and `QuitBtn`:
- Name: `TutorialBtn`, Text: `? HOW TO PLAY`
- Name: `LegendBtn`, Text: `⚡ LEGEND`, Modulate: `Color(0.8, 0.6, 1.0)`

- [ ] **Step 2: Add LegendRulesPopup Panel**

Add a `Panel` node as a direct child of the root `Control`, named `LegendRulesPopup`. Set anchors to full-rect center with fixed size 600×400. Add inside it:
- `VBoxContainer` (anchored center) with:
  - `Label` (text: `"Legend Mode Rules"`, bold)
  - `RichTextLabel` (bbcode enabled, text below)
  - `Button` named `GotItBtn`, text `"Got it!"`

RichTextLabel text:
```
Two characters appear — you control the LEFT one.

Moving [b]left or right[/b] also moves the other character in the [b]opposite[/b] direction.
Moving [b]up or down[/b] moves [b]both[/b] the same way.

Atoms are split between both halves of the maze.
Both characters collect into a [b]shared inventory[/b].

Reach the center gate [b]together[/b] to win.
```

- [ ] **Step 3: Commit**

```bash
git add scenes/main_menu.tscn
git commit -m "feat: add Tutorial/Legend buttons and rules popup to main menu scene"
```

---

## Task 10: Scene setup — main.tscn

**Files:**
- Modify: `scenes/main.tscn` (via Godot editor or MCP)

- [ ] **Step 1: Add TutorialManager node**

In Godot editor, open `scenes/main.tscn`. Under the `UI` CanvasLayer, add a new `Node` named `TutorialManager`. Assign script `scripts/tutorial_manager.gd`. Set `visible = false`.

- [ ] **Step 2: Add TutorialWinOverlay**

Under `UI`, add a new `Panel` named `TutorialWinOverlay`. Set anchors full-rect, `visible = false`. Add inside:
- `VBoxContainer` (centered) with:
  - `Label`: `"Tutorial Complete! You're ready to play ChemBond Adventure."`
  - `Button` named `MenuBtn`, text `"Back to Menu"`

Wire `MenuBtn.pressed` in `main.gd`. Add to `_ready()`:
```gdscript
$UI/TutorialWinOverlay/VBox/MenuBtn.pressed.connect(func():
    AudioManager.play_sfx("ui_click")
    GameManager.reset_mode_flags()
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
)
```

- [ ] **Step 3: Add LegendaryOverlay**

Under `UI`, add a `Panel` named `LegendaryOverlay`, `visible = false`. Add inside:
- `VBoxContainer` with:
  - `Label`: `"LEGENDARY CHEMIST"`  (large font, gold color)
  - `Label`: `"You have mastered all of ChemBond Adventure!"`
  - `Button` named `RestartBtn`, text `"Main Menu"`

Wire in `_ready()`:
```gdscript
$UI/LegendaryOverlay/VBox/RestartBtn.pressed.connect(func():
    AudioManager.play_sfx("ui_click")
    GameManager.reset_mode_flags()
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
)
```

- [ ] **Step 4: Commit**

```bash
git add scenes/main.tscn scripts/main.gd
git commit -m "feat: add TutorialManager, TutorialWinOverlay, LegendaryOverlay to main scene"
```

---

## Task 11: Legend atom distribution — half-split spawn

**Files:**
- Modify: `scripts/maze_manager.gd`

- [ ] **Step 1: Add get_legend_spawns() method**

Add this method to `maze_manager.gd`:

```gdscript
func get_legend_spawns(maze_data: Dictionary, required: Dictionary, decoy_count: int):
	var walkable = maze_data.walkable
	var start_left = maze_data.start
	var start_right = maze_data.start_right
	var exit = maze_data.exit

	var half_x = 15  # maze width 30, center col

	var left_tiles = walkable.filter(func(t): return t.x < half_x)
	var right_tiles = walkable.filter(func(t): return t.x >= half_x)

	# Split required atoms: floor(n/2) left, ceil(n/2) right
	var left_required = {}
	var right_required = {}
	for symbol in required:
		var count = required[symbol]
		left_required[symbol] = count / 2
		right_required[symbol] = count - (count / 2)

	var spawn_plan = {}

	var left_plan = _spawn_half(left_tiles, start_left, exit, left_required, decoy_count / 2)
	var right_plan = _spawn_half(right_tiles, start_right, exit, right_required, decoy_count - decoy_count / 2)

	if not left_plan or not right_plan:
		print("ERROR: Legend spawn generation failed")
		return null

	for pos in left_plan: spawn_plan[pos] = left_plan[pos]
	for pos in right_plan: spawn_plan[pos] = right_plan[pos]
	return spawn_plan

func _spawn_half(tiles: Array, spawn: Vector2i, exit: Vector2i, required: Dictionary, decoy_count: int):
	var req_list = []
	for symbol in required:
		for i in range(required[symbol]): req_list.append(symbol)

	var decoy_pool = ["Cl", "Na", "Mg", "S", "K", "Ca", "N", "Si", "Fe", "Cu", "Zn", "H", "O", "C", "P", "Al"]

	var spawn_plan = {}
	var attempts = 0
	while attempts < 20:
		spawn_plan.clear()
		var occupied = [spawn, exit]
		var candidates = tiles.duplicate()
		candidates.shuffle()

		var success = true
		for symbol in req_list:
			var found = false
			for i in range(candidates.size()):
				var tile = candidates[i]
				if is_spacing_valid(tile, occupied):
					spawn_plan[tile] = symbol
					occupied.append(tile)
					candidates.remove_at(i)
					found = true
					break
			if not found:
				success = false
				break
		if not success:
			attempts += 1
			continue

		for _d in range(decoy_count):
			for i in range(candidates.size()):
				var tile = candidates[i]
				if is_spacing_valid(tile, occupied):
					spawn_plan[tile] = decoy_pool[randi() % decoy_pool.size()]
					occupied.append(tile)
					candidates.remove_at(i)
					break

		return spawn_plan

	return null
```

- [ ] **Step 2: Update main.gd to call get_legend_spawns() in legend mode**

In `main.gd._ready()`, find the spawn_plan line and add legend branch:

```gdscript
var spawn_plan
if GameManager.is_legend_mode:
	var decoy_count_legend = 4
	spawn_plan = current_maze.get_legend_spawns(maze_data, current_q.required, decoy_count_legend)
elif GameManager.is_tutorial:
	spawn_plan = current_maze.get_validated_spawns(maze_data, current_q.required, 1)
else:
	var decoy_count = 6 + GameManager.current_level
	spawn_plan = current_maze.get_validated_spawns(maze_data, current_q.required, decoy_count)
```

- [ ] **Step 3: Commit**

```bash
git add scripts/maze_manager.gd scripts/main.gd
git commit -m "feat: add legend half-split atom spawning"
```

---

## Task 12: Return-to-menu resets flags

**Files:**
- Modify: `scripts/main.gd`

- [ ] **Step 1: Wire MasterOverlay restart to reset flags**

In `_on_restart_game_pressed()`, add reset:

```gdscript
func _on_restart_game_pressed():
	GameManager.reset_mode_flags()
	GameManager.current_level = 0
	get_tree().call_deferred("reload_current_scene")
```

- [ ] **Step 2: Wire WinOverlay next for legend progression**

Replace `_on_next_level_pressed()`:

```gdscript
func _on_next_level_pressed():
	if GameManager.is_legend_mode:
		GameManager.legend_level += 1
		get_tree().reload_current_scene()
	else:
		transition_to_next()
```

- [ ] **Step 3: Commit**

```bash
git add scripts/main.gd
git commit -m "feat: reset mode flags on restart, handle legend next level"
```

---

## Task 13: Maze scale fix for legend (30×20 vs 20×15)

**Files:**
- Modify: `scripts/main.gd`

- [ ] **Step 1: Fix maze container scale and position for legend**

The 30×20 maze at tile size 16 = 480×320 px. At scale 2× = 960×640. Center it at 1280×720:

Replace the scale/position lines in `_ready()`:

```gdscript
if GameManager.is_legend_mode:
	maze_container.scale = Vector2(2.0, 2.0)
	maze_container.position = Vector2(640.0 - 480.0, 360.0 - 320.0)
else:
	maze_container.scale = Vector2(3.0, 3.0)
	maze_container.position = Vector2(640.0 - (960.0 / 2.0), 360.0 - (720.0 / 2.0))
```

- [ ] **Step 2: Verify in editor**

Run the game. Press Legend → Got It. Confirm the 30×20 maze appears centered and both player spawn points are visible.

- [ ] **Step 3: Commit**

```bash
git add scripts/main.gd
git commit -m "fix: correct maze container scale and position for legend mode"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Task |
|---|---|
| GameManager flags | Task 1 |
| P/Al element colors | Task 2 |
| Tutorial maze layout | Task 3 |
| TutorialManager step sequence | Task 4 |
| player.gd mirror input | Task 5 |
| exit_gate dual-player win | Task 6 |
| main.gd branching | Task 7 |
| Tutorial win overlay | Task 10 |
| main_menu Tutorial button | Tasks 8, 9 |
| Legend rules popup | Tasks 8, 9 |
| Legend maze layouts (30×20) | Task 3 |
| Legend second player spawn | Task 7 |
| Legend atom distribution (half-split) | Task 11 |
| Legend progression / LegendaryOverlay | Tasks 7, 10, 12 |
| Return-to-menu flag reset | Task 12 |
| Legend maze scale fix | Task 13 |

All spec requirements covered. No placeholders. Method names consistent across tasks.
