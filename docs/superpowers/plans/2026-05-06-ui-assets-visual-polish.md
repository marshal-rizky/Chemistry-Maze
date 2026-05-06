# UI Assets & Visual Polish — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace placeholder UI visuals with a cohesive dark pixel-terminal aesthetic across font, main menu, element pickups, and HUD buttons.

**Architecture:** Six sequential tasks. Font + shader have no dependencies. PixelLab atom orb must complete before element_pickup changes. All code changes are GDScript only — no Godot editor scene editing required except element_pickup.tscn. Ring animation is drawn via GDScript `_draw()` + `_process()` on the Area2D itself (no extra asset needed). Icons are Unicode chars in Pixelify Sans (no PNG files).

**Tech Stack:** Godot 4.6, GDScript, PixelLab MCP (atom_orb.png), canvas_item GLSL shader.

---

## File Map

| Action | File | Notes |
|---|---|---|
| Create (manual) | `assets/fonts/PixelifySans-Regular.ttf` | Google Fonts download |
| Create (manual) | `assets/fonts/PixelifySans-Bold.ttf` | Google Fonts download |
| Create | `assets/shaders/grid.gdshader` | Grid bg shader |
| Create (PixelLab) | `assets/sprites/atom_orb.png` | Neutral pixel art orb |
| Modify | `scripts/ui_theme.gd` | Load Pixelify Sans as default font |
| Modify | `scripts/main_menu.gd` | Grid bg + logo nodes + improved floating atoms |
| Modify | `scripts/element_pickup.gd` | OrbSprite refs + ring draw + ring rotation |
| Modify | `scenes/element_pickup.tscn` | Rename Sprite2D → OrbSprite, point to atom_orb.png |
| Modify | `scripts/main.gd` | Add Unicode chars to HUD button text |

---

## Task 1: Font — Download + ui_theme.gd Integration

**Files:**
- Create (manual): `assets/fonts/PixelifySans-Regular.ttf`
- Create (manual): `assets/fonts/PixelifySans-Bold.ttf`
- Modify: `scripts/ui_theme.gd`

- [ ] **Step 1: Download Pixelify Sans from Google Fonts**

Open browser → go to `https://fonts.google.com/specimen/Pixelify+Sans` → click **Download family** → unzip → copy these two files into `assets/fonts/` (create the folder if it doesn't exist):

```
assets/fonts/PixelifySans-Regular.ttf
assets/fonts/PixelifySans-Bold.ttf
```

Verify both files exist before continuing.

- [ ] **Step 2: Update `scripts/ui_theme.gd` to load and apply the font**

Replace the entire `create_game_theme()` function (lines 26–55) with:

```gdscript
static func create_game_theme() -> Theme:
	var theme = Theme.new()

	var font_reg  = load("res://assets/fonts/PixelifySans-Regular.ttf") as FontFile
	var font_bold = load("res://assets/fonts/PixelifySans-Bold.ttf")    as FontFile
	if font_reg:
		theme.set_default_font(font_reg)
		theme.set_default_font_size(16)

	var btn_normal   = _make_stylebox(BG_PANEL,   BORDER,    1)
	var btn_hover    = _make_stylebox(BG_HOVER,   BORDER_HI, 2)
	var btn_pressed  = _make_stylebox(BG_PRESSED, BORDER_HI, 2)
	var btn_disabled = _make_stylebox(BG_DEEP,    BORDER_DIM, 1)

	theme.set_stylebox("normal",   "Button", btn_normal)
	theme.set_stylebox("hover",    "Button", btn_hover)
	theme.set_stylebox("pressed",  "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_stylebox("focus",    "Button", _make_stylebox(BG_HOVER, BORDER_HI, 2))
	theme.set_color("font_color",          "Button", TEXT)
	theme.set_color("font_hover_color",    "Button", TEXT_HI)
	theme.set_color("font_pressed_color",  "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", TEXT_DIM)
	theme.set_constant("h_separation", "Button", 4)

	var panel_style = _make_stylebox(Color(0.027, 0.043, 0.075, 0.92), BORDER, 1)
	panel_style.set_content_margin_all(10)
	theme.set_stylebox("panel", "Panel", panel_style)

	theme.set_color("font_color", "Label", TEXT)
	theme.set_font_size("font_size", "Label", 16)

	return theme
```

- [ ] **Step 3: Open Godot, check Output panel for font errors**

Run the project (F5). If you see `"Failed to load resource: res://assets/fonts/PixelifySans-Regular.ttf"`, the file path or name is wrong — fix the filename and retry.

Expected: buttons and labels throughout the game now render in Pixelify Sans.

- [ ] **Step 4: Commit**

```bash
git add assets/fonts/ scripts/ui_theme.gd
git commit -m "feat: add Pixelify Sans font and apply via UITheme"
```

---

## Task 2: Grid Background Shader

**Files:**
- Create: `assets/shaders/grid.gdshader`

- [ ] **Step 1: Create `assets/shaders/grid.gdshader`**

```glsl
shader_type canvas_item;

uniform float grid_size : hint_range(4.0, 128.0) = 20.0;
uniform vec4 bg_color : source_color = vec4(0.027, 0.043, 0.075, 1.0);
uniform vec4 line_color : source_color = vec4(0.078, 0.718, 0.651, 0.12);
uniform float line_width : hint_range(0.5, 4.0) = 0.5;

void fragment() {
	vec2 pixel = FRAGCOORD.xy;
	vec2 grid = mod(pixel, grid_size);
	float on_h = step(grid_size - line_width, grid.x);
	float on_v = step(grid_size - line_width, grid.y);
	float on_line = clamp(on_h + on_v, 0.0, 1.0);
	COLOR = mix(bg_color, line_color, on_line);
}
```

- [ ] **Step 2: Verify shader compiles in Godot**

Open Godot. In the FileSystem panel, click on `assets/shaders/grid.gdshader`. If the shader has a syntax error, Godot will show it in the Output panel. Fix any errors before continuing.

Expected: no errors in Output.

- [ ] **Step 3: Commit**

```bash
git add assets/shaders/grid.gdshader
git commit -m "feat: add grid background shader"
```

---

## Task 3: Generate atom_orb.png via PixelLab MCP

**Files:**
- Create: `assets/sprites/atom_orb.png`

This generates a neutral pixel art orb. Godot will modulate its color per element.

- [ ] **Step 1: Submit PixelLab generation job**

Call `mcp__pixellab__create_object` with:

```json
{
  "description": "glowing circular orb, white and light gray, pixel art game sprite, soft inner highlight, subtle shadow at bottom, no background, transparent, clean edges",
  "directions": 1,
  "size": 32,
  "object_view": "top-down"
}
```

Save the returned `object_id` — you'll need it in the next step.

- [ ] **Step 2: Poll until complete**

Call `mcp__pixellab__get_object` with the `object_id` from Step 1. Check the `status` field:
- `"generating"` — wait 30–90 seconds and poll again
- `"review"` — call `mcp__pixellab__select_object_frames` with `indices: [0]` to confirm, then poll again
- `"completed"` — proceed to Step 3

The response when completed contains a URL to the generated image. Copy it.

- [ ] **Step 3: Download and save the image**

Using PowerShell:

```powershell
Invoke-WebRequest -Uri "<URL_FROM_STEP_2>" -OutFile "assets/sprites/atom_orb.png"
```

Replace `<URL_FROM_STEP_2>` with the actual URL returned by PixelLab.

- [ ] **Step 4: Verify file exists**

```powershell
Test-Path "assets/sprites/atom_orb.png"
```

Expected: `True`. If False, the download failed — retry Step 3.

- [ ] **Step 5: Commit**

```bash
git add assets/sprites/atom_orb.png
git commit -m "feat: add atom orb pixel art sprite from PixelLab"
```

---

## Task 4: Upgrade main_menu.gd

**Files:**
- Modify: `scripts/main_menu.gd`

Adds: grid background ColorRect (with shader), logo label row, improved floating atoms (colored circles instead of text).

- [ ] **Step 1: Replace `scripts/main_menu.gd` in full**

```gdscript
extends Control

func _ready():
	theme = UITheme.create_game_theme()

	_spawn_grid_bg()
	_spawn_logo()

	$VBoxContainer/StartBtn.pressed.connect(func(): AudioManager.play_sfx("ui_click"); _on_start_pressed())
	$VBoxContainer/TutorialBtn.pressed.connect(func(): AudioManager.play_sfx("ui_click"); _on_tutorial_pressed())
	$VBoxContainer/LegendBtn.pressed.connect(func(): AudioManager.play_sfx("ui_click"); _on_legend_btn_pressed())
	$VBoxContainer/QuitBtn.pressed.connect(func(): AudioManager.play_sfx("ui_click"); _on_quit_pressed())
	$LegendRulesPopup/VBox/GotItBtn.pressed.connect(_on_got_it_pressed)

	$VBoxContainer/LegendBtn.disabled = not GameManager.legend_unlocked
	$LegendRulesPopup.visible = false

	AudioManager.play_music()
	spawn_floating_atoms()

func _spawn_grid_bg():
	var grid = ColorRect.new()
	grid.name = "GridBg"
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.z_index = -10
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader = load("res://assets/shaders/grid.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("grid_size", 24.0)
	mat.set_shader_parameter("bg_color", Color(0.027, 0.043, 0.075, 1.0))
	mat.set_shader_parameter("line_color", Color(0.078, 0.718, 0.651, 0.12))
	mat.set_shader_parameter("line_width", 0.5)
	grid.material = mat
	grid.color = Color.WHITE
	add_child(grid)
	move_child(grid, 0)

func _spawn_logo():
	var hbox = HBoxContainer.new()
	hbox.name = "LogoRow"
	hbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hbox.offset_top = 40
	hbox.offset_bottom = 100
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	add_child(hbox)

	var hex = _make_hex_icon()
	hbox.add_child(hex)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var title_lbl = Label.new()
	title_lbl.text = "CHEMBOND"
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", Color("#5eead4"))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "ADVENTURE"
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color("#cfeae6"))
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(sub_lbl)

	hbox.add_child(vbox)

func _make_hex_icon() -> Control:
	var ctrl = Control.new()
	ctrl.custom_minimum_size = Vector2(40, 40)
	var draw_node = Node2D.new()
	draw_node.name = "HexDraw"
	draw_node.position = Vector2(20, 20)

	# Attach a script that draws a hexagon
	var scr = GDScript.new()
	scr.source_code = """extends Node2D
func _draw():
	var pts = PackedVector2Array()
	for i in 6:
		var a = deg_to_rad(60.0 * i - 30.0)
		pts.append(Vector2(cos(a), sin(a)) * 16.0)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color("#14b8a6"), 2.0, true)
"""
	draw_node.set_script(scr)
	ctrl.add_child(draw_node)
	return ctrl

func spawn_floating_atoms():
	var element_colors = {
		"H": Color.CYAN, "O": Color.RED, "C": Color.GRAY,
		"Na": Color.YELLOW, "Cl": Color.GREEN, "N": Color.BLUE,
		"Mg": Color.ORANGE, "Ca": Color.ORANGE_RED
	}
	var symbols = element_colors.keys()
	for i in range(18):
		var sym = symbols[randi() % symbols.size()]
		var col = element_colors[sym]
		col.a = randf_range(0.15, 0.35)
		var dot = ColorRect.new()
		dot.size = Vector2.ONE * randf_range(3, 8)
		dot.color = col
		dot.position = Vector2(randf_range(0, 1280), randf_range(0, 720))
		dot.z_index = -5
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dot)
		var tween = create_tween().set_loops()
		var target = dot.position + Vector2(randf_range(-120, 120), randf_range(-120, 120))
		tween.tween_property(dot, "position", target, randf_range(4.0, 8.0)).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(dot, "position", dot.position, randf_range(4.0, 8.0)).set_ease(Tween.EASE_IN_OUT)

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

- [ ] **Step 2: Verify in Godot**

Run project → navigate to main menu. Verify:
- Grid pattern visible behind menu
- "CHEMBOND" in large teal Pixelify Sans above buttons
- "ADVENTURE" subtitle below
- Hexagon outline icon left of title
- Colored dot particles drifting slowly

If hex icon doesn't appear: Godot may not allow inline GDScript on dynamically created nodes in all versions. If so, skip `_make_hex_icon()` and replace the `hex` child with a plain teal `Label.new()` with text `"⬡"` and font size 32.

- [ ] **Step 3: Commit**

```bash
git add scripts/main_menu.gd
git commit -m "feat: add grid bg, logo, and colored atom particles to main menu"
```

---

## Task 5: element_pickup.tscn — Rename Sprite + Point to atom_orb.png

**Files:**
- Modify: `scenes/element_pickup.tscn`

- [ ] **Step 1: Edit `scenes/element_pickup.tscn`**

Replace the entire file with:

```
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/element_pickup.gd" id="1_element"]
[ext_resource type="Texture2D" path="res://assets/sprites/atom_orb.png" id="2_sprite"]

[sub_resource type="CircleShape2D" id="CircleShape2D_7uyte"]
radius = 5.0

[node name="ElementPickup" type="Area2D"]
collision_layer = 2
collision_mask = 2
monitoring = true
monitorable = true
script = ExtResource("1_element")

[node name="OrbSprite" type="Sprite2D" parent="."]
texture_filter = 0
texture = ExtResource("2_sprite")

[node name="Label" type="Label" parent="."]
offset_left = -10.0
offset_top = -12.0
offset_right = 10.0
offset_bottom = 11.0
theme_override_font_sizes/font_size = 10
text = "H"
horizontal_alignment = 1
vertical_alignment = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_7uyte")
```

Key changes from original:
- `Sprite2D` → `OrbSprite`
- texture points to `atom_orb.png` instead of `element.png`
- Removed `modulate = Color(1, 1, 0, 1)` from sprite (color set in script)
- Label font_size reduced from 12 → 10 (fits better on 32px orb)

- [ ] **Step 2: Verify in Godot editor**

Open Godot. In FileSystem, double-click `scenes/element_pickup.tscn`. The scene tree should show:
```
ElementPickup (Area2D)
├── OrbSprite (Sprite2D)
├── Label
└── CollisionShape2D
```

No errors in Output panel.

- [ ] **Step 3: Commit**

```bash
git add scenes/element_pickup.tscn
git commit -m "feat: update element_pickup scene to use atom_orb sprite"
```

---

## Task 6: element_pickup.gd — OrbSprite refs + orbital ring draw + rotation

**Files:**
- Modify: `scripts/element_pickup.gd`

The orbital ring is drawn via `_draw()` on the Area2D itself and rotated by updating `_ring_angle` each `_process()` frame. No extra node or asset needed.

- [ ] **Step 1: Replace `scripts/element_pickup.gd` in full**

```gdscript
extends Area2D

signal collected(element_symbol)

@export var element_symbol: String = "H"

var _tutorial_tween: Tween = null
var _ring_angle: float = 0.0

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

func _ready():
	var color = element_colors.get(element_symbol, Color.WHITE)
	$OrbSprite.modulate = color
	$OrbSprite.scale = Vector2(0.5, 0.5)
	$Label.text = element_symbol
	$Label.add_theme_color_override("font_color", color)

	# Bobbing animation on sprite only (keeps collision center static)
	var tween = create_tween().set_loops()
	tween.set_parallel(true)
	tween.tween_property($OrbSprite, "position:y", -2, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Label, "position:y", -14, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_property($OrbSprite, "position:y", 2, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Label, "position:y", -10, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Glow pulse on orb
	var glow_tween = create_tween().set_loops()
	glow_tween.tween_property($OrbSprite, "modulate:a", 0.5, 1.0)
	glow_tween.tween_property($OrbSprite, "modulate:a", 1.0, 1.0)

func _process(delta: float):
	_ring_angle += delta * TAU / 3.0
	queue_redraw()

func _draw():
	var color = element_colors.get(element_symbol, Color.WHITE)
	color.a = 0.45
	# 270-degree spinning arc — looks like an orbital ring
	draw_arc(Vector2.ZERO, 12.0, _ring_angle, _ring_angle + TAU * 0.75, 36, color, 1.5, true)

func collect():
	play_collect_effect()
	collected.emit(element_symbol)
	for sig in collected.get_connections():
		collected.disconnect(sig.callable)
	queue_free()

func play_collect_effect():
	var color = element_colors.get(element_symbol, Color.WHITE)
	var scene_root = get_tree().current_scene

	var flash = Sprite2D.new()
	flash.texture = $OrbSprite.texture
	flash.global_position = global_position
	flash.modulate = Color.WHITE
	flash.z_index = 10
	scene_root.add_child(flash)
	var ft = flash.create_tween()
	ft.set_parallel(true)
	ft.tween_property(flash, "scale", Vector2(3, 3), 0.3)
	ft.tween_property(flash, "modulate:a", 0.0, 0.3)
	ft.tween_callback(flash.queue_free).set_delay(0.3)

	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = color
		particle.global_position = global_position - Vector2(2, 2)
		particle.z_index = 9
		scene_root.add_child(particle)
		var angle = i * TAU / 8.0
		var dist = randf_range(15, 30)
		var target = global_position + Vector2(cos(angle) * dist, sin(angle) * dist)
		var pt = particle.create_tween()
		pt.set_parallel(true)
		pt.tween_property(particle, "global_position", target, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		pt.tween_property(particle, "modulate:a", 0.0, 0.4)
		pt.tween_property(particle, "scale", Vector2(0.2, 0.2), 0.4)
		pt.tween_callback(particle.queue_free).set_delay(0.4)

func set_tutorial_highlight(is_required: bool):
	if _tutorial_tween:
		_tutorial_tween.kill()
		_tutorial_tween = null
	if is_required:
		modulate.a = 1.0
		scale = Vector2(1.0, 1.0)
		_tutorial_tween = create_tween().set_loops()
		_tutorial_tween.tween_property(self, "scale", Vector2(1.18, 1.18), 0.5).set_ease(Tween.EASE_IN_OUT)
		_tutorial_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_IN_OUT)
	else:
		modulate.a = 0.4

func clear_tutorial_highlight():
	if _tutorial_tween:
		_tutorial_tween.kill()
		_tutorial_tween = null
	modulate.a = 1.0
	scale = Vector2(1.0, 1.0)
```

- [ ] **Step 2: Verify in Godot**

Run project → start any level. Verify:
- Element pickups show the pixel art orb sprite colored per element
- A partial arc (orbital ring) spins around each pickup
- Element symbol label appears in matching element color
- Bobbing animation still works
- Collecting an element triggers the burst particle effect

- [ ] **Step 3: Commit**

```bash
git add scripts/element_pickup.gd
git commit -m "feat: redesign element pickup with atom orb sprite and orbital ring"
```

---

## Task 7: HUD Unicode Icons on Buttons

**Files:**
- Modify: `scripts/main.gd`

Adds ↺ and ✕ symbol prefixes to the Reset and Leave buttons using Pixelify Sans (which supports these Unicode characters). No PNG files needed.

- [ ] **Step 1: Add icon text to HUD buttons in `main.gd`**

In `scripts/main.gd`, in `_ready()`, after the line:
```gdscript
$UI/HUD/HBar/LeaveBtn.pressed.connect(func(): AudioManager.play_sfx("ui_click"); _go_to_menu())
```

Add:
```gdscript
$UI/HUD/HBar/ResetBtn.text = "↺ Reset"
$UI/HUD/HBar/LeaveBtn.text = "✕ Leave"
```

And after:
```gdscript
$UI/WinOverlay/VBox/NextBtn.pressed.connect(func(): AudioManager.play_sfx("ui_click"); _on_next_level_pressed())
```

Add:
```gdscript
$UI/WinOverlay/VBox/NextBtn.text = "Next →"
```

- [ ] **Step 2: Verify in Godot**

Run project → start a level. Verify:
- Reset button shows "↺ Reset"
- Leave button shows "✕ Leave"
- Complete a level → Win overlay Next button shows "Next →"

If symbols appear as □ (missing glyph): Pixelify Sans may not include these Unicode points. Fallback — use ASCII alternatives: `"< Reset"`, `"X Leave"`, `"Next >"`.

- [ ] **Step 3: Commit**

```bash
git add scripts/main.gd
git commit -m "feat: add Unicode icon chars to HUD Reset, Leave, and Next buttons"
```
