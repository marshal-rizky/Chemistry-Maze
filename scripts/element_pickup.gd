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

	# Bobbing animation (keeps collision center static)
	var tween = create_tween().set_loops()
	tween.set_parallel(true)
	tween.tween_property($OrbSprite, "position:y", -2, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Label, "position:y", -14, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_property($OrbSprite, "position:y", 2, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Label, "position:y", -10, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Glow pulse on orb alpha
	var glow_tween = create_tween().set_loops()
	glow_tween.tween_property($OrbSprite, "modulate:a", 0.5, 1.0)
	glow_tween.tween_property($OrbSprite, "modulate:a", 1.0, 1.0)

func _process(delta: float):
	_ring_angle += delta * TAU / 3.0
	queue_redraw()

func _draw():
	var color = element_colors.get(element_symbol, Color.WHITE)
	color.a = 0.45
	# 270-degree spinning arc — orbital ring effect
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
