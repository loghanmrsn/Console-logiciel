extends Control
## Read-only preview. Selecting a connection belongs to the native controls below.
## The diagram represents a fictitious 5 V teaching circuit, never mains wiring.

var connections: Array = []

func _ready() -> void:
	custom_minimum_size = Vector2(300, 178)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func set_connections(value: Array) -> void:
	connections = value.duplicate()
	queue_redraw()

func _draw() -> void:
	var font: Font = get_theme_default_font()
	var font_size: int = get_theme_default_font_size()
	var ink := Color("25313c")
	var accent := Color("527fa3")
	var focus_style := get_theme_stylebox("focus", "Button")
	if focus_style is StyleBoxFlat:
		accent = focus_style.border_color
	var box := StyleBoxFlat.new()
	box.bg_color = Color("e6edf2")
	box.border_color = Color("d3dfe7")
	box.set_border_width_all(1)
	box.set_corner_radius_all(14)
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	var source := Vector2(size.x * 0.18, 76)
	var switch_at := Vector2(size.x * 0.5, 76)
	var lamp := Vector2(size.x * 0.82, 76)
	var return_y := 146.0
	var source_top := Vector2(source.x, 27)
	var lamp_top := Vector2(lamp.x, 27)
	if connections.has("source_switch"):
		draw_line(source, switch_at, accent, 4.0, true)
	if connections.has("switch_lamp"):
		draw_line(switch_at, lamp, accent, 4.0, true)
	if connections.has("lamp_return"):
		draw_polyline(PackedVector2Array([lamp, Vector2(lamp.x, return_y), Vector2(source.x, return_y), source]), accent, 4.0, true)
	if connections.has("source_lamp"):
		draw_polyline(PackedVector2Array([source, source_top, lamp_top, lamp]), accent, 4.0, true)
	if connections.has("switch_return"):
		draw_polyline(PackedVector2Array([switch_at, Vector2(switch_at.x, return_y), Vector2(source.x, return_y), source]), accent, 4.0, true)
	for at in [source, switch_at, lamp]:
		draw_circle(at, 26, Color("fbfcfd"))
		draw_arc(at, 26, 0, TAU, 40, accent, 2.0, true)
	# Battery, closed switch and lamp are intentionally abstract symbols.
	draw_line(source + Vector2(-5, -12), source + Vector2(-5, 12), ink, 3.0, true)
	draw_line(source + Vector2(5, -7), source + Vector2(5, 7), ink, 3.0, true)
	draw_line(source + Vector2(-15, 0), source + Vector2(-5, 0), ink, 2.0, true)
	draw_line(source + Vector2(5, 0), source + Vector2(15, 0), ink, 2.0, true)
	draw_circle(switch_at + Vector2(-13, 0), 3, ink)
	draw_circle(switch_at + Vector2(13, 0), 3, ink)
	draw_line(switch_at + Vector2(-13, 0), switch_at + Vector2(13, 0), ink, 3.0, true)
	draw_circle(lamp, 13, Color("f2e2b4"))
	draw_line(lamp + Vector2(-8, -8), lamp + Vector2(8, 8), ink, 2.0, true)
	draw_line(lamp + Vector2(-8, 8), lamp + Vector2(8, -8), ink, 2.0, true)
	var labels := ["Source 5 V", "Interrupteur", "Lampe"]
	var points := [source, switch_at, lamp]
	for index in range(labels.size()):
		var width: float = font.get_string_size(labels[index], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, points[index] + Vector2(-width * 0.5, 51), labels[index], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)
