extends "res://scripts/game/interactable.gd"
## A quiet idle bubble opens into a name tag when the player approaches.
var speaker_name := "":
	set(value):
		speaker_name = value
		queue_redraw()
var _focus := 0.0:
	set(value):
		_focus = value
		queue_redraw()
var _transition: Tween

func _highlight_changed() -> void:
	if is_instance_valid(_transition): _transition.kill()
	var settings := get_node_or_null("/root/SettingsService") if is_inside_tree() else null
	if not is_inside_tree() or (settings != null and settings.current.get("reduce_motion", false)):
		_focus = 1.0 if highlighted else 0.0
		return
	_transition = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_transition.tween_property(self, "_focus", 1.0 if highlighted else 0.0, .14)

func _exit_tree() -> void:
	if is_instance_valid(_transition): _transition.kill()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var text_width := font.get_string_size(speaker_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	var width := lerpf(27, text_width + 43, _focus)
	var height := lerpf(21, 27, _focus)
	var rect := Rect2(-14, -height * .5, width, height)
	draw_set_transform(marker_offset)
	var bubble := StyleBoxFlat.new()
	bubble.bg_color = Color("fcfcf6")
	bubble.border_color = Color("9baea8").lerp(accent, _focus)
	bubble.set_border_width_all(1 if _focus < .5 else 2)
	bubble.set_corner_radius_all(9)
	bubble.shadow_color = Color(.16, .24, .25, .15)
	bubble.shadow_size = 3
	bubble.shadow_offset = Vector2(0, 2)
	draw_style_box(bubble, rect)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, height * .5 - 1), Vector2(-6, height * .5 + 6), Vector2(1, height * .5 - 1)]), bubble.border_color)
	draw_colored_polygon(PackedVector2Array([Vector2(-6, height * .5 - 2), Vector2(-5, height * .5 + 3), Vector2(-1, height * .5 - 2)]), bubble.bg_color)
	for x in [-6, 0, 6]: draw_circle(Vector2(x, 0), 1.35, Color("81958e").lerp(accent, _focus))
	if _focus > 0:
		draw_string(font, Vector2(17, 5), speaker_name, HORIZONTAL_ALIGNMENT_LEFT, text_width, 13, Color(.17, .25, .27, _focus))
	draw_set_transform(Vector2.ZERO)
