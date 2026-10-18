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
	custom_minimum_size = Vector2(0, 230)
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
	custom_minimum_size.y = 180 if compact else 230
	var width := maxf(1.0, (size.x - 32) / 3.0 - 10)
	for index in range(TERMINALS.size()):
		var button: Button = terminal_buttons[TERMINALS[index]]
		var column := index % 3
		var height := 44.0 if compact else 48.0
		button.position = Vector2(16 + column * (width + 10), 14 if index < 3 else size.y - height - 14)
		button.size = Vector2(width, height)
	queue_redraw()

func _socket(id: String) -> Vector2:
	var button: Button = terminal_buttons[id]
	return button.position + Vector2(button.size.x / 2, button.size.y if id in ["A", "B", "C"] else 0)

func _draw() -> void:
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color("182b35")
	plate.border_color = Color("57747f")
	plate.set_border_width_all(2)
	plate.set_corner_radius_all(18)
	draw_style_box(plate, Rect2(Vector2.ZERO, size))
	if terminal_buttons.size() != 6:
		return
	for id in TERMINALS:
		if connections.has(id) or id in connections.values():
			continue
		var start := _socket(id)
		var length := minf(39, maxf(15, (size.y - 124) * 0.5 - 6))
		var finish := start + Vector2(0, length if id in ["A", "B", "C"] else -length)
		if terminal_selected(id):
			var glow: Color = COLORS[id]
			glow.a = 0.26
			draw_line(start, finish, glow, 17, true)
			draw_circle(finish, 11, glow)
		draw_line(start, finish, COLORS[id], 5 if terminal_selected(id) else 3, true)
		draw_circle(finish, 5, COLORS[id])
	for top in connections:
		var start := _socket(str(top))
		var finish := _socket(str(connections[top]))
		var points := PackedVector2Array()
		for index in range(25):
			var t := float(index) / 24.0
			points.append(start.bezier_interpolate(start + Vector2(0, 95), finish - Vector2(0, 95), finish, t))
		draw_polyline(points, COLORS[top], 5, true)
