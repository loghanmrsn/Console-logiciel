extends Control
## Read-only preview of the fictitious 5 V teaching circuit.
## Native controls below the board remain the only interactive connections.
const Materials = preload("res://scripts/game/render_materials.gd")
var connections: Array = []

func _ready() -> void:
	custom_minimum_size = Vector2(300, 178)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	theme_changed.connect(queue_redraw)

func set_connections(value: Array) -> void:
	connections = value.duplicate()
	queue_redraw()

func _draw() -> void:
	if size.x < 1 or size.y < 1:
		return
	var surface := get_theme_color("recessed", "Appearance")
	var ink := get_theme_color("font_color", "Label")
	var accent := get_theme_color("focus", "Appearance")
	var edge := ink.lerp(surface, .82)
	Materials.rounded(self, Rect2(Vector2.ZERO, size), surface, 14, edge, 1)
	# Engraved guides and fasteners distinguish the mounting board from the
	# loose insulated leads. There is no flashing or animated current.
	for x in range(20, int(size.x - 10), 18):
		for y in range(18, int(size.y - 10), 18):
			draw_circle(Vector2(x, y), .65, Color(ink, .10))
	for at in [Vector2(11, 11), Vector2(size.x - 11, 11), Vector2(11, size.y - 11), size - Vector2(11, 11)]:
		_screw(at, edge)
	var source := Vector2(size.x * .18, 68)
	var switch_at := Vector2(size.x * .5, 68)
	var lamp := Vector2(size.x * .82, 68)
	var return_y := 110.0
	if connections.has("source_switch"):
		_lead(source, source + Vector2(25, 20), switch_at + Vector2(-25, 20), switch_at, accent)
	if connections.has("switch_lamp"):
		_lead(switch_at, switch_at + Vector2(25, -12), lamp + Vector2(-25, -12), lamp, accent)
	if connections.has("lamp_return"):
		_lead(lamp, lamp + Vector2(16, return_y), source + Vector2(-16, return_y), source, accent.darkened(.18))
	if connections.has("source_lamp"):
		_lead(source, source + Vector2(5, -61), lamp + Vector2(-5, -61), lamp, accent)
	if connections.has("switch_return"):
		_lead(switch_at, switch_at + Vector2(0, return_y), source + Vector2(-18, return_y), source, accent.darkened(.18))
	# Battery holder: moulded cradle, two cylindrical cells, metal contacts.
	Materials.shadow(self, Rect2(source - Vector2(26, 27), Vector2(52, 54)), 7, .16, Vector2(1, 3))
	Materials.rounded(self, Rect2(source - Vector2(26, 27), Vector2(52, 54)), Color("34454b"), 7, Color("6a7a7f"), 1)
	for offset in [-11, 11]:
		var rect := Rect2(source + Vector2(offset - 7, -20), Vector2(14, 40))
		Materials.rounded(self, rect, Color("af784b"), 6)
		Materials.rounded(self, Rect2(rect.position + Vector2(3, 1), Vector2(4, 37)), Color("d5a774"), 2)
		draw_line(rect.position + Vector2(0, 9), rect.position + Vector2(14, 9), Color("493f37"), 3, true)
		draw_line(rect.position + Vector2(3, -1), rect.position + Vector2(11, -1), Color("d6dcda"), 3, true)
		draw_line(rect.position + Vector2(3, 41), rect.position + Vector2(11, 41), Color("aab6b2"), 3, true)
	# Toggle switch: mounting plate, threaded collar and a raised lever.
	var plate := Rect2(switch_at - Vector2(24, 25), Vector2(48, 50))
	Materials.shadow(self, plate, 7, .14, Vector2(1, 3))
	Materials.rounded(self, plate, Color("aebfc0"), 7, Color("637a81"), 1)
	for side in [-1, 1]:
		_screw(switch_at + Vector2(16 * side, 17 * side), Color("75878a"))
	draw_circle(switch_at, 11, Color("42575e"))
	draw_arc(switch_at, 9, 0, TAU, 24, Color("dae3e0"), 3, true)
	draw_line(switch_at, switch_at + Vector2(0, -17), Color("34474d"), 8, true)
	draw_line(switch_at + Vector2(-1, -1), switch_at + Vector2(-1, -18), Color("e0e7e3"), 4, true)
	draw_circle(switch_at + Vector2(0, -18), 5, Color("d5dfdc"))
	# Lamp: ceramic base, threaded cap and a transparent glass envelope.
	Materials.ellipse(self, Rect2(lamp + Vector2(-25, 15), Vector2(50, 13)), Color(0, 0, 0, .13))
	Materials.ellipse(self, Rect2(lamp + Vector2(-23, 7), Vector2(46, 16)), Color("b8c3ba"))
	Materials.rounded(self, Rect2(lamp + Vector2(-11, 0), Vector2(22, 19)), Color("8d9891"), 3)
	for y in [5, 10, 15]:
		draw_line(lamp + Vector2(-10, y), lamp + Vector2(10, y - 2), Color("d8ddcc"), 2, true)
	var lit := connections.has("source_switch") and connections.has("switch_lamp") and connections.has("lamp_return")
	var glass := Color("e9d392") if lit else Color("c4d8d4")
	draw_circle(lamp - Vector2(0, 15), 19, glass.darkened(.14))
	draw_circle(lamp - Vector2(0, 17), 17, glass)
	draw_arc(lamp - Vector2(0, 17), 14, -2.7, -1.1, 16, Color("f6f6e8"), 2, true)
	draw_polyline(PackedVector2Array([lamp + Vector2(-6, 0), lamp + Vector2(-7, -17), lamp + Vector2(-2, -13), lamp + Vector2(3, -18), lamp + Vector2(7, -1)]), Color("8d723f"), 1.5, true)
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var labels := ["Source 5 V", "Interrupteur", "Lampe"]
	var points := [source, switch_at, lamp]
	for index in range(labels.size()):
		var max_width := size.x * .31
		# At the smallest permitted width, use the available three-column label
		# area while retaining the user's requested font size.
		draw_string(font, points[index] + Vector2(-max_width * .5, 59), labels[index], HORIZONTAL_ALIGNMENT_CENTER, max_width, font_size, ink)

func _screw(at: Vector2, color: Color) -> void:
	draw_circle(at + Vector2(0, 1), 3, color.darkened(.35))
	draw_circle(at, 2.6, color.lightened(.18))
	draw_line(at + Vector2(-1.5, 1), at + Vector2(1.5, -1), color.darkened(.4), 1, true)

func _lead(start: Vector2, control_a: Vector2, control_b: Vector2, finish: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var shadow := PackedVector2Array()
	for step in range(33):
		var at := start.bezier_interpolate(control_a, control_b, finish, step / 32.0)
		points.append(at)
		shadow.append(at + Vector2(1, 3))
	draw_polyline(shadow, Color(0, 0, 0, .18), 7, true)
	draw_polyline(points, color.darkened(.25), 5, true)
	draw_polyline(points, color.lightened(.18), 2, true)
