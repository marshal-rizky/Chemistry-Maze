# Tutorial Interactivity Redesign — Design Spec
**Date:** 2026-05-06
**Project:** ChemBond Adventure (Godot 4.6)

---

## Overview

Replace the current read-and-dismiss tutorial with a fully gated, action-driven tutorial. Each step waits silently for the player to perform a specific action before advancing. Named HUD elements are highlighted inline with teal BBCode. Required atoms glow/pulse during the collect step; decoys dim. Wrong atom collection triggers an immediate inline warning.

---

## Step Flow

| # | Trigger type | Panel text | Dismiss btn | Gated on |
|---|---|---|---|---|
| 0 | `move` | `"Use [b]WASD[/b] / arrows or the [b]joystick[/b] to move."` | No | Player velocity > 0.1 |
| 1 | `tap` | `"Your [teal]Objective[/teal] bar shows the molecule to form."` | Yes | Tap OK |
| 2 | `collect_required` | `"[teal]Glowing atoms[/teal] are the ones you need. Walk over them to collect."` | No | First required atom collected |
| 3 | `gate_open` | `"Watch your [teal]Inventory[/teal] fill up. Gate opens on [b]exact match[/b]."` | No | `exit_gate.is_open == true` |
| 4 | `tap` | `"Gate is open! Walk through it to escape."` | Yes | Tap OK |

**[teal]** = `[color=#5eead4][b]…[/b][/color]` in BBCode.

Win is handled by `main.gd` showing `TutorialWinOverlay` as before — step 4 OK dismisses the panel, then player walks to gate normally.

### Wrong atom behaviour (step 2 only)
If `current_step == 2` and collected symbol is NOT in `required_elements`:
- Panel text swaps immediately to:
  `"[color=#ef4444]⚠ That's a decoy![/color] Extra atoms keep the gate [b]locked[/b].\n\nPress [b]R[/b] or tap [b]Reset[/b] to try again."`
- `_showing_decoy_warning = true` — suppresses further swaps on the same warning
- Step does NOT advance
- Player resets scene (R / Reset btn) → tutorial restarts from step 0

### ✓ Confirmation flash
When an action trigger fires:
1. Append `"\n\n[color=#14b8a6]✓ Got it![/color]"` to current panel text
2. Wait 0.8 s (tween or `await get_tree().create_timer(0.8).timeout`)
3. Hide panel, `show_step(current_step + 1)`

---

## Architecture

### `scripts/tutorial_manager.gd` — full rewrite

**New vars:**
```gdscript
var required_elements: Dictionary = {}
var element_pickups: Array = []
var _showing_decoy_warning: bool = false

const STEP_MOVE            = 0
const STEP_OBJECTIVE       = 1
const STEP_COLLECT         = 2
const STEP_GATE            = 3
const STEP_REACH           = 4
```

**Step definitions:**
```gdscript
var steps = [
    { "text": "Use [b]WASD[/b] / arrows or the [b]joystick[/b] to move.",
      "trigger": "move", "show_dismiss": false },
    { "text": "Your [color=#5eead4][b]Objective[/b][/color] bar shows the molecule to form.",
      "trigger": "tap", "show_dismiss": true },
    { "text": "[color=#5eead4]Glowing atoms[/color] are the ones you need.\n\nWalk over them to collect.",
      "trigger": "collect_required", "show_dismiss": false },
    { "text": "Watch your [color=#5eead4][b]Inventory[/b][/color] fill up.\n\nThe gate opens when your atoms are an [b]exact match[/b].",
      "trigger": "gate_open", "show_dismiss": false },
    { "text": "Gate is open! Walk through it to escape.",
      "trigger": "tap", "show_dismiss": true },
]
```

**`setup(p, gate, required, pickups)`:**
```gdscript
func setup(p: CharacterBody2D, gate: Node, required: Dictionary, pickups: Array):
    player = p
    exit_gate = gate
    required_elements = required
    element_pickups = pickups
    player.collected_signal.connect(_on_atom_collected)
    show_step(0)
```

**`show_step(index)`:**
- Sets `current_step`, `step_complete = false`, `_showing_decoy_warning = false`
- Sets `panel_label.text` from step dict
- Shows/hides dismiss_btn per `show_dismiss`
- If `current_step == STEP_COLLECT and index != STEP_COLLECT`: call `_clear_atom_glow()` before updating `current_step`
- After updating `current_step = index`: if `index == STEP_COLLECT`, call `_apply_atom_glow()`
- Shows panel

**`advance_step()`:**
```gdscript
func advance_step():
    if step_complete: return
    step_complete = true
    panel_label.text += "\n\n[color=#14b8a6]✓ Got it![/color]"
    await get_tree().create_timer(0.8).timeout
    panel.visible = false
    var next = current_step + 1
    if next < steps.size():
        show_step(next)
```

**`_on_atom_collected(symbol)`:**
```gdscript
func _on_atom_collected(symbol: String):
    if current_step != STEP_COLLECT or step_complete: return
    if required_elements.has(symbol) and required_elements[symbol] > 0:
        advance_step()
    elif not _showing_decoy_warning:
        _showing_decoy_warning = true
        panel_label.text = "[color=#ef4444]⚠ That's a decoy![/color] Extra atoms keep the gate [b]locked[/b].\n\nPress [b]R[/b] or tap [b]Reset[/b] to try again."
        dismiss_btn.visible = false
```

**`notify_gate_opened()`:**
```gdscript
func notify_gate_opened():
    if current_step == STEP_GATE and not step_complete:
        advance_step()
```

**`_on_dismiss_pressed()`:**
```gdscript
func _on_dismiss_pressed():
    if steps[current_step].trigger == "tap" and not step_complete:
        advance_step()
```

**`_physics_process(_delta)`:**
```gdscript
func _physics_process(_delta):
    if not is_instance_valid(player): return
    if current_step == STEP_MOVE and not step_complete:
        if player.velocity.length() > 0.1:
            advance_step()
```

**`_apply_atom_glow()`:**
```gdscript
func _apply_atom_glow():
    for pickup in element_pickups:
        if not is_instance_valid(pickup): continue
        var is_req = required_elements.has(pickup.element_symbol) and required_elements[pickup.element_symbol] > 0
        pickup.set_tutorial_highlight(is_req)
```

**`_clear_atom_glow()`:**
```gdscript
func _clear_atom_glow():
    for pickup in element_pickups:
        if not is_instance_valid(pickup): continue
        pickup.clear_tutorial_highlight()
```

---

### `scripts/element_pickup.gd` — two new methods

Add instance var at top:
```gdscript
var _tutorial_tween: Tween = null
```

Add methods:
```gdscript
func set_tutorial_highlight(is_required: bool):
    if _tutorial_tween:
        _tutorial_tween.kill()
    if is_required:
        modulate.a = 1.0
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

---

### `scripts/main.gd` — `_setup_tutorial()` update

Replace existing `_setup_tutorial(player, exit_gate)` call and method:

```gdscript
# In _ready(), replace:
if GameManager.is_tutorial:
    _setup_tutorial(player, exit_gate)

# _setup_tutorial signature change:
func _setup_tutorial(player: CharacterBody2D, exit_gate: Node):
    var tm = $UI/TutorialManager
    if not tm: return

    # ... existing panel/label/btn creation unchanged ...

    # Collect all ElementPickup nodes spawned in current_maze
    var pickups: Array = []
    for child in current_maze.get_children():
        if child.has_method("set_tutorial_highlight"):
            pickups.append(child)

    var required = GameManager.get_current_question().required
    tm.setup(player, exit_gate, required, pickups)
```

---

## Edge Cases

| Scenario | Behaviour |
|---|---|
| Player resets (R) mid-tutorial | Scene reloads → tutorial restarts from step 0. No special handling needed. |
| Player collects decoy on step != STEP_COLLECT | `_on_atom_collected` exits early (`if current_step != STEP_COLLECT`). No warning shown. |
| Player collects multiple decoys on step 2 | `_showing_decoy_warning` flag prevents re-swap after first warning. |
| Player collects required atom AFTER decoy warning shown | `step_complete` is false and `required_elements.has(symbol)` → `advance_step()` fires normally. Reset clears inventory so this won't happen without reset. |
| Gate already open when step 3 entered (impossible in practice — gate requires all atoms, step 3 starts on first atom) | `notify_gate_opened()` guard `current_step == STEP_GATE` prevents premature advance. |
| element_pickup already collected before step 2 entered | Pickup is already freed; `is_instance_valid()` check in `_apply_atom_glow()` skips it safely. |
