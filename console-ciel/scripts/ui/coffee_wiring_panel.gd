extends Control
## Enlarged, keyboard-accessible connector panel. The service owns the saved
## pairs; this control owns only the temporary highlight and cable drawing.
const TerminalButton = preload("res://scripts/ui/translucent_button.gd")
const TERMINALS := ["A", "B", "C", "1", "2", "3"]
const COLORS := {
	"A": Color("ee6d70"), "B": Color("73c6a4"), "C": Color("c79b72"),
	"1": Color("c79b72"), "2": Color("73c6a4"), "3": Color("ee6d70")
}
const NAMES := {"A": "Rouge", "B": "Vert", "C": "Marron", "1": "Marron", "2": "Vert", "3": "Rouge"}

signal terminal_pressed(terminal_id: String)

var connections: Dictionary = {}
var selected_terminal := ""
var terminal_buttons: Dictionary = {}

func _ready() -> void:
	name = "coffee_wiring_panel"
	custom_minimum_size = Vector2(0, 260)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in TERMINALS:
		var key := str(id)
		var button := TerminalButton.new()
		button.name = "hotel_coffee_" + key
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(func(): terminal_pressed.emit(key))
		add_child(button)
		terminal_buttons[key] = button
	resized.connect(_layout_terminals)
	theme_changed.connect(_layout_terminals)
	get_viewport().size_changed.connect(_layout_terminals)
	refresh(connections, selected_terminal)
	_layout_terminals()

func refresh(saved_connections: Dictionary, selection: String) -> void:
	connections = saved_connections.duplicate(true)
	selected_terminal = selection
	for id in terminal_buttons:
		var button: Button = terminal_buttons[id]
		var linked: bool = connections.has(id) or id in connections.values()
		button.text = ("✓ " if linked else ("● " if terminal_selected(id) else "")) + id + " · " + str(NAMES[id])
		button.tooltip_text = "Borne %s, fil %s. %s" % [id, str(NAMES[id]).to_lower(), "Déjà reliée." if linked else ("Sélectionnée ; appuyez à nouveau pour désélectionner." if terminal_selected(id) else "Sélectionner ce fil.")]
		button.disabled = linked
		if terminal_selected(id):
			var selected := StyleBoxFlat.new()
			selected.bg_color = Color("314951")
			selected.border_color = COLORS[id]
			selected.set_border_width_all(3)
			selected.set_corner_radius_all(12)
			button.add_theme_stylebox_override("normal", selected)
			button.add_theme_stylebox_override("hover", selected)
			for color_name in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
				button.add_theme_color_override(color_name, Color.WHITE)
		else:
			button.remove_theme_stylebox_override("normal")
			button.remove_theme_stylebox_override("hover")
			for color_name in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
				button.remove_theme_color_override(color_name)
	queue_redraw()

func terminal_selected(id: String) -> bool:
	return not selected_terminal.is_empty() and selected_terminal == id

func _layout_terminals() -> void:
	var compact := get_viewport_rect().size.y < 600
	custom_minimum_size.y = 210 if compact else 260
	var width := maxf(1.0, (size.x - 32) / 3.0 - 10)
	for index in range(TERMINALS.size()):
		var button: Button = terminal_buttons[TERMINALS[index]]
		var column := index % 3
		var height := maxf(48, button.get_combined_minimum_size().y)
		button.position = Vector2(16 + column * (width + 10), 40 if index < 3 else size.y - height - 14)
		button.size = Vector2(width, height)
	queue_redraw()

func _socket(id: String) -> Vector2:
	var button: Button = terminal_buttons[id]
	return button.position + Vector2(button.size.x / 2, button.size.y if id in ["A", "B", "C"] else 0)

func _draw() -> void:
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color("345a61")
	plate.border_color = Color("b4945d")
	plate.set_border_width_all(2)
	plate.set_corner_radius_all(18)
	draw_style_box(plate, Rect2(Vector2.ZERO, size))
	# Brass frame, recessed board and fasteners echo the hotel's furnishings.
	draw_line(Vector2(19, 33), Vector2(size.x - 19, 33), Color("78918a"), 1, true)
	for x in [10.0, size.x - 10]:
		for y in [10.0, size.y - 10]:
			draw_circle(Vector2(x, y), 3, Color("bfa97c"))
			draw_line(Vector2(x - 1.5, y + 1), Vector2(x + 1.5, y - 1), Color("53675f"), 1, true)
	draw_string(ThemeDB.fallback_font, Vector2(20, 24), "CIEL · PANNEAU ÉLECTRIQUE", HORIZONTAL_ALIGNMENT_LEFT, size.x - 100, 12, Color("f4ead5"))
	for index in range(3):
		var at := Vector2(size.x - 55 + index * 15, 20)
		draw_circle(at, 5, Color("213f48"))
		draw_circle(at, 3, Color("a7c8a6") if index < connections.size() else Color("a78d62"))
	if terminal_buttons.size() != 6:
		return
	for id in TERMINALS:
		if connections.has(id) or id in connections.values():
			continue
		var start := _socket(id)
		var length := minf(32, maxf(14, (size.y - 136) * .28))
		var direction := 1.0 if id in ["A", "B", "C"] else -1.0
		var finish := start + Vector2(0, length * direction)
		if terminal_selected(id):
			var glow: Color = COLORS[id]
			glow.a = 0.26
			draw_line(start, finish, glow, 17, true)
			draw_circle(finish, 11, glow)
		draw_line(start + Vector2(2, 2), finish + Vector2(2, 2), Color("203c43"), 8, true)
		draw_line(start, finish, COLORS[id], 6 if terminal_selected(id) else 4, true)
		draw_line(finish - Vector2(0, 5 * direction), finish + Vector2(0, 3 * direction), Color("e4c38e"), 3, true)
		draw_circle(start, 6, Color("c1aa7d"))
		draw_circle(start, 3, COLORS[id])
		draw_circle(finish, 4, COLORS[id])
	for top in connections:
		var start := _socket(str(top))
		var finish := _socket(str(connections[top]))
		var points := PackedVector2Array()
		# Different bend depths keep the three insulated cables distinguishable
		# instead of crossing all three through the same central point.
		var gap := finish.y - start.y
		var bend := .3 if top == "A" else (.7 if top == "C" else .5)
		for index in range(33):
			var t := float(index) / 32.0
			points.append(start.bezier_interpolate(start + Vector2(0, gap * bend), finish - Vector2(0, gap * (1 - bend)), finish, t))
		draw_polyline(points, Color("203c43"), 12, true)
		draw_polyline(points, COLORS[top], 7, true)
		draw_polyline(points, Color(COLORS[top].lightened(.3), .6), 2, true)
		for socket in [start, finish]:
			draw_circle(socket, 7, Color("d2bc8b"))
			draw_circle(socket, 4, COLORS[top])
