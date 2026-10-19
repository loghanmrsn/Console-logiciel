extends VBoxContainer
## A native, paged conversation. No profile writes or game rules live here.
const Visual = preload("res://scripts/game/npc_visual.gd")
const ActionButton = preload("res://scripts/ui/translucent_button.gd")
signal close_requested
signal navigation_changed
var character: Dictionary = {}
var pages: Array[String] = []
var page_index := 0
var _body: Label
var _counter: Label
var _previous: Button
var _next: Button

class Portrait extends Control:
	var character: Dictionary = {}
	func _draw() -> void:
		var backdrop := StyleBoxFlat.new()
		backdrop.bg_color = Color(str(character.get("coat", "749b90")), .18)
		backdrop.set_corner_radius_all(16)
		draw_style_box(backdrop, Rect2(Vector2.ZERO, size))
		# Character drawing resets its local transform; this child supplies scale.
	func _ready() -> void:
		var figure := Visual.new()
		figure.configure(character)
		figure.position = Vector2(42, 82)
		figure.scale = Vector2(1.1, 1.1)
		add_child(figure)

func configure(spec: Dictionary, lines: Array[String]) -> void:
	character = spec.duplicate(true)
	pages = lines.duplicate()

func _ready() -> void:
	name = "npc_dialogue_panel"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 14)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	add_child(header)
	var portrait := Portrait.new()
	portrait.name = "npc_portrait"
	portrait.character = character
	portrait.custom_minimum_size = Vector2(84, 92)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(portrait)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(identity)
	_label(identity, str(character.get("name", "")), "npc_speaker", 27)
	_label(identity, str(character.get("role", "")), "npc_role", 17)
	_counter = _label(identity, "", "npc_page_count", 14)
	add_child(HSeparator.new())
	_body = _label(self, "", "npc_dialogue_text", 20)
	_label(self, "Échap / touche droite de la manette : fermer", "npc_dialogue_hint", 14)
	_previous = _button("← Précédent", "npc_previous", _previous_page)
	_next = _button("Suite →", "npc_next", _next_page)
	_refresh()

func _label(host: Node, text: String, id: String, font_size: int) -> Label:
	var label := Label.new()
	label.name = id
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	host.add_child(label)
	return label

func _button(text: String, id: String, action: Callable) -> Button:
	var button := ActionButton.new()
	button.name = id
	button.text = text
	button.custom_minimum_size.y = 46
	button.pressed.connect(action)
	add_child(button)
	return button

func _previous_page() -> void:
	page_index = maxi(0, page_index - 1)
	_refresh()

func _next_page() -> void:
	if page_index + 1 >= pages.size():
		close_requested.emit()
		return
	page_index += 1
	_refresh()

func _refresh() -> void:
	_body.text = pages[page_index] if not pages.is_empty() else ""
	_counter.text = "DISCUSSION · %d / %d" % [page_index + 1, pages.size()]
	_previous.disabled = page_index == 0
	_next.text = "Fermer la discussion" if page_index + 1 >= pages.size() else "Suite →"
	navigation_changed.emit()
