extends VBoxContainer
## Bibliothèque native accessible au clavier, à la souris et à la manette.
signal close_requested
signal navigation_changed
const Lessons = preload("res://scripts/game/code_lessons.gd")
const GlassButton = preload("res://scripts/ui/translucent_button.gd")
var selected_book := -1
var page_index := 0
var selection: VBoxContainer
var reader: VBoxContainer
var spread: Control
var page_heading: Label
var body: Label
var example: Label
var page_counter: Label
var previous: Button
var next: Button
var _opening: Tween

class BookCard extends Button:
	var book: Dictionary
	var motion: Tween
	func _ready() -> void:
		custom_minimum_size = Vector2(0, 146)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tooltip_text = "Ouvrir le livre " + str(book.title)
		for key in ["normal", "hover", "pressed", "hover_pressed"]:
			add_theme_stylebox_override(key, StyleBoxEmpty.new())
		focus_entered.connect(func(): _animate(true))
		focus_exited.connect(func(): _animate(false))
		mouse_entered.connect(func(): _animate(true))
		mouse_exited.connect(func(): _animate(has_focus()))
		resized.connect(queue_redraw)
	func _animate(active: bool) -> void:
		if motion != null and motion.is_valid(): motion.kill()
		pivot_offset = size * .5
		if SettingsService.current.get("reduce_motion", false):
			scale = Vector2.ONE
		else:
			motion = create_tween().set_trans(Tween.TRANS_SINE)
			motion.tween_property(self, "scale", Vector2.ONE * (1.025 if active else 1.0), .14)
		queue_redraw()
	func _draw() -> void:
		var area := Rect2(7, 5, maxf(size.x - 14, 1), size.y - 12)
		var color := Color(str(book.color))
		draw_style_box(_box(color.darkened(.12), 10), area)
		draw_rect(Rect2(area.position + Vector2(5, 0), Vector2(8, area.size.y)), color.darkened(.3))
		draw_line(Vector2(area.position.x + 17, area.end.y - 10), area.end - Vector2(8, 10), Color("efe8d8"), 5, true)
		var font := get_theme_default_font()
		var ink := Color("fff9ef")
		draw_string(font, Vector2(27, 47), str(book.symbol), HORIZONTAL_ALIGNMENT_LEFT, area.size.x - 32, 27, ink)
		draw_string(font, Vector2(27, 83), str(book.title), HORIZONTAL_ALIGNMENT_LEFT, area.size.x - 32, 20, ink)
		draw_string(font, Vector2(27, 108), "Ouvrir le livre", HORIZONTAL_ALIGNMENT_LEFT, area.size.x - 32, 14, ink)
	static func _box(color: Color, radius: int) -> StyleBoxFlat:
		var box := StyleBoxFlat.new()
		box.bg_color = color
		box.set_corner_radius_all(radius)
		return box

class BookSpread extends Control:
	var color := Color("688fa3")
	var amount := 0.0:
		set(value):
			amount = value
			queue_redraw()
	func _ready() -> void:
		custom_minimum_size.y = 58
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var center := size * .5
		var half := lerpf(12, minf(140, size.x * .42), amount)
		var outer := Rect2(center - Vector2(half, 25), Vector2(half * 2, 50))
		draw_style_box(BookCard._box(color, 5), outer.grow(3))
		draw_style_box(BookCard._box(Color("f6efdf"), 3), outer)
		draw_line(center - Vector2(0, 24), center + Vector2(0, 24), color.darkened(.1), 2, true)
		for row in range(4):
			var y := center.y - 14 + row * 8
			draw_line(Vector2(center.x - half + 9, y), Vector2(center.x - 9, y), Color("c8c2b2"), 2, true)
			draw_line(Vector2(center.x + 9, y), Vector2(center.x + half - 9, y), Color("c8c2b2"), 2, true)

func _ready() -> void:
	name = "lesson_library"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)
	selection = VBoxContainer.new()
	selection.add_theme_constant_override("separation", 10)
	add_child(selection)
	_label(selection, "Le coin ressources", 26)
	_label(selection, "Trois livres pour apprendre à votre rythme. Choisissez un langage : les leçons donnent aussi les réponses aux défis.")
	var row := HBoxContainer.new()
	row.name = "books"
	row.add_theme_constant_override("separation", 10)
	selection.add_child(row)
	for index in range(Lessons.BOOKS.size()):
		var card := BookCard.new()
		card.name = "book_" + str(Lessons.BOOKS[index].id)
		card.book = Lessons.BOOKS[index]
		card.pressed.connect(func(): open_book(index))
		row.add_child(card)
	_button(selection, "Retour à la pièce", "library_close", func(): close_requested.emit())
	reader = VBoxContainer.new()
	reader.add_theme_constant_override("separation", 8)
	add_child(reader)
	spread = BookSpread.new()
	reader.add_child(spread)
	page_heading = _label(reader, "", 24)
	body = _label(reader, "")
	example = _label(reader, "", 19)
	example.name = "lesson_example"
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["DejaVu Sans Mono", "Consolas", "monospace"])
	example.add_theme_font_override("font", mono)
	example.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	page_counter = _label(reader, "")
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	reader.add_child(actions)
	previous = _button(actions, "← Précédente", "lesson_previous", func(): turn_page(-1))
	next = _button(actions, "Suivante →", "lesson_next", func(): turn_page(1))
	_button(reader, "Fermer le livre", "lesson_close", close_book)
	reader.hide()

func open_book(index: int) -> void:
	if index < 0 or index >= Lessons.BOOKS.size(): return
	_stop_animation()
	selected_book = index
	page_index = 0
	selection.hide()
	reader.show()
	spread.color = Color(str(Lessons.BOOKS[index].color))
	spread.amount = 1.0 if _reduced_motion() else 0.0
	reader.modulate = Color.WHITE
	_update_page()
	if not _reduced_motion():
		reader.modulate.a = .35
		_opening = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_opening.tween_property(spread, "amount", 1.0, .32)
		_opening.tween_property(reader, "modulate:a", 1.0, .25)
	navigation_changed.emit()

func turn_page(direction: int) -> void:
	if selected_book < 0: return
	page_index = clampi(page_index + direction, 0, Lessons.BOOKS[selected_book].pages.size() - 1)
	_update_page()
	if not _reduced_motion():
		_stop_animation()
		body.modulate.a = .45
		_opening = create_tween()
		_opening.tween_property(body, "modulate:a", 1.0, .16)
	navigation_changed.emit()

func _update_page() -> void:
	var book: Dictionary = Lessons.BOOKS[selected_book]
	var page: Dictionary = book.pages[page_index]
	page_heading.text = str(book.title) + " · " + str(page.title)
	body.text = str(page.body)
	example.text = str(page.example)
	page_counter.text = "Leçon %d / %d" % [page_index + 1, book.pages.size()]
	previous.disabled = page_index == 0
	next.disabled = page_index == book.pages.size() - 1

func close_book() -> void:
	_stop_animation()
	reader.hide()
	selection.show()
	var id := str(Lessons.BOOKS[selected_book].id) if selected_book >= 0 else "python"
	selected_book = -1
	selection.get_node("books/book_" + id).grab_focus()
	navigation_changed.emit()

func handle_back() -> bool:
	if selected_book < 0: return false
	close_book()
	return true

func _stop_animation() -> void:
	if _opening != null and _opening.is_valid(): _opening.kill()
	if is_instance_valid(body): body.modulate = Color.WHITE
	if is_instance_valid(reader): reader.modulate = Color.WHITE
	if is_instance_valid(spread): spread.amount = 1.0

func _reduced_motion() -> bool:
	return SettingsService.current.get("reduce_motion", false)

func _label(host: Node, value: String, font_size: int = 0) -> Label:
	var text := Label.new()
	text.text = value
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if font_size > 0: text.add_theme_font_size_override("font_size", font_size + (2 if SettingsService.current.get("large_text", false) else 0))
	host.add_child(text)
	return text

func _button(host: Node, value: String, key: String, action: Callable) -> Button:
	var button := GlassButton.new()
	button.name = key
	button.text = value
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	host.add_child(button)
	return button
