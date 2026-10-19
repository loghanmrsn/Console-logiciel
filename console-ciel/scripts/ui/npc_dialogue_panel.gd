extends VBoxContainer
## Native conversation: the header and actions stay visible while the text scrolls.
const Visual = preload("res://scripts/game/npc_visual.gd")
const ActionButton = preload("res://scripts/ui/translucent_button.gd")
const CLOSE_SECONDS := .08
signal close_requested
signal navigation_changed
var character: Dictionary = {}
var pages: Array[String] = []
var page_index := 0
var _body: Label
var _counter: Label
var _previous: Button
var _next: Button
var _close: Button
var _header: HBoxContainer
var _footer: HBoxContainer
var _hint: Label
var _portrait: Control
var _card: PanelContainer
var _reader: ScrollContainer
var _entrance: Tween
var _page_fade: Tween
var _closing := false
var _layout_pending := false
var _shell_fill := Color("f9fbf9")

func _draw() -> void:
	# Keep names and action hints legible over the moving world in glass themes.
	var shell := StyleBoxFlat.new()
	shell.bg_color = _shell_fill
	shell.set_corner_radius_all(12)
	draw_style_box(shell, Rect2(Vector2.ZERO, size))

class Portrait extends Control:
	var character: Dictionary = {}
	var figure: Node2D
	func _ready() -> void:
		clip_contents = true
		figure = Visual.new()
		figure.configure(character)
		add_child(figure)
		figure.set_attention(true)
		resized.connect(_fit)
		_fit()
	func _fit() -> void:
		if not is_instance_valid(figure): return
		var factor := size.x / 58.0
		figure.scale = Vector2(factor, factor)
		figure.position = Vector2(size.x * .5, size.y * 1.24)
		queue_redraw()
	func _draw() -> void:
		var coat := Color(str(character.get("coat", "749b90")))
		var backdrop := StyleBoxFlat.new()
		backdrop.bg_color = coat.darkened(.15)
		backdrop.set_corner_radius_all(18)
		draw_style_box(backdrop, Rect2(Vector2.ZERO, size))
		draw_circle(Vector2(size.x * .72, size.y * .22), size.x * .5, Color(1, 1, 1, .09))
		draw_circle(Vector2(size.x * .2, size.y * .8), size.x * .48, Color(1, 1, 1, .07))

class SpeechCard extends PanelContainer:
	var fill := Color("f3f6f2")
	var edge := Color("ccd8d2")
	func _draw() -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(26, 1), Vector2(26, -9), Vector2(40, 1)]), edge)
		draw_colored_polygon(PackedVector2Array([Vector2(28, 2), Vector2(28, -5), Vector2(37, 2)]), fill)

class ReadArea extends ScrollContainer:
	signal advance_requested
	func _gui_input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_down", true) or event.is_action_pressed("ui_up", true):
			scroll_vertical += 42 if event.is_action_pressed("ui_down", true) else -42
			accept_event()
		elif event.is_action_pressed("ui_accept"):
			advance_requested.emit()
			accept_event()

func configure(spec: Dictionary, lines: Array[String]) -> void:
	character = spec.duplicate(true)
	pages = lines.duplicate()

func _enter_tree() -> void:
	# Controller suspension detaches this exact panel, retaining the page.
	_closing = false
	modulate = Color.WHITE
	if is_instance_valid(_body):
		_body.modulate = Color.WHITE
		_previous.disabled = page_index == 0
		_next.disabled = false
		_close.disabled = false
		_schedule_layout()

func _ready() -> void:
	name = "npc_dialogue_panel"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	_header = HBoxContainer.new()
	_header.add_theme_constant_override("separation", 16)
	add_child(_header)
	_portrait = Portrait.new()
	_portrait.name = "npc_portrait"
	_portrait.character = character
	_portrait.custom_minimum_size = Vector2(96, 96)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_child(_portrait)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	_header.add_child(identity)
	_label(identity, str(character.get("name", "")), "npc_speaker", 28)
	_label(identity, str(character.get("role", "")), "npc_role", 17)
	_counter = _label(identity, "", "npc_page_count", 14)
	_close = ActionButton.new()
	_close.name = "npc_close"
	_close.text = "×"
	_close.tooltip_text = "Fermer la discussion · Échap / face droite"
	_close.custom_minimum_size = Vector2(52, 52)
	_close.size_flags_horizontal = Control.SIZE_SHRINK_END
	_close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_close.add_theme_font_size_override("font_size", 24)
	_close.pressed.connect(_request_close)
	_header.add_child(_close)
	_card = SpeechCard.new()
	_card.name = "npc_message_bubble"
	add_child(_card)
	_reader = ReadArea.new()
	_reader.name = "npc_text_scroll"
	_reader.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_reader.follow_focus = false
	_reader.focus_mode = Control.FOCUS_ALL
	_reader.advance_requested.connect(advance)
	_card.add_child(_reader)
	_body = _label(_reader, "", "npc_dialogue_text", 20)
	_body.minimum_size_changed.connect(_schedule_layout)
	_footer = HBoxContainer.new()
	_footer.add_theme_constant_override("separation", 10)
	add_child(_footer)
	_previous = _button("← Précédent", "npc_previous", _previous_page)
	_next = _button("Suite →", "npc_next", advance)
	_hint = _label(self, "↑↓ : lire · Espace / face bas : suite · Échap / face droite : fermer", "npc_dialogue_hint", 14)
	resized.connect(_schedule_layout)
	get_viewport().size_changed.connect(_schedule_layout)
	theme_changed.connect(_apply_theme)
	_apply_theme()
	_refresh()
	_schedule_layout()
	if not _reduced_motion():
		modulate.a = 0
		_entrance = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_entrance.tween_property(self, "modulate:a", 1.0, .16)

func _label(host: Node, text: String, id: String, font_size: int) -> Label:
	var label := Label.new()
	label.name = id
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size + (2 if SettingsService.current.get("large_text", false) else 0))
	host.add_child(label)
	return label

func _button(text: String, id: String, action: Callable) -> Button:
	var button := ActionButton.new()
	button.name = id
	button.text = text
	button.custom_minimum_size.y = 48
	button.custom_minimum_size.x = 250
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	_footer.add_child(button)
	return button

func _apply_theme() -> void:
	if not is_instance_valid(_card): return
	var night := get_theme_color("font_color", "Label").get_luminance() > .6
	_shell_fill = Color("222c39") if night else Color("f9fbf9")
	queue_redraw()
	var coat := Color(str(character.get("coat", "749b90")))
	_card.fill = Color("283442") if night else Color("f3f6f2")
	_card.edge = coat.lerp(Color("72828e") if night else Color("cbd7d0"), .62)
	var style := StyleBoxFlat.new()
	style.bg_color = _card.fill
	style.border_color = _card.edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_card.add_theme_stylebox_override("panel", style)
	_card.queue_redraw()
	_schedule_layout()

func _schedule_layout() -> void:
	if _layout_pending or not is_inside_tree(): return
	_layout_pending = true
	_fit_reader.call_deferred()

func _fit_reader() -> void:
	_layout_pending = false
	if not is_inside_tree() or not is_instance_valid(_reader): return
	var compact := get_viewport_rect().size.y <= 540
	var portrait_side := 72 if compact else 96
	_portrait.custom_minimum_size = Vector2(portrait_side, portrait_side)
	var frame_padding := 32.0
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is PanelContainer:
			frame_padding = ancestor.get_theme_stylebox("panel").get_minimum_size().y
			break
		ancestor = ancestor.get_parent()
	var fixed := _header.get_combined_minimum_size().y + _footer.get_combined_minimum_size().y + _hint.get_combined_minimum_size().y + 36 + 32
	var available := get_viewport_rect().size.y - 36 - frame_padding - fixed
	var font := _body.get_theme_font("font")
	var font_size := _body.get_theme_font_size("font_size")
	var width := maxf(160, size.x - 50)
	var longest := 72.0
	for text in pages:
		var measured := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size)
		var lines := ceili(measured.y / maxf(1, font.get_height(font_size)))
		longest = maxf(longest, measured.y + maxi(0, lines - 1) * _body.get_theme_constant("line_spacing") + 4)
	_reader.custom_minimum_size.y = minf(clampf(available, 64, 210), longest)
	# Only the text scrolls; changing a page never moves the portrait or actions.

func _previous_page() -> void:
	if _closing: return
	page_index = maxi(0, page_index - 1)
	_refresh()

func advance() -> void:
	if _closing: return
	if page_index + 1 >= pages.size():
		_request_close()
		return
	page_index += 1
	_refresh()

func _request_close() -> void:
	if not _closing: close_requested.emit()

func fade_out() -> void:
	_closing = true
	_previous.disabled = true
	_next.disabled = true
	_close.disabled = true
	if is_instance_valid(_entrance): _entrance.kill()
	if _reduced_motion(): return
	_entrance = create_tween()
	_entrance.tween_property(self, "modulate:a", 0.0, CLOSE_SECONDS)

func _refresh() -> void:
	_body.text = pages[page_index] if not pages.is_empty() else ""
	_counter.text = "●  DISCUSSION · %d / %d" % [page_index + 1, pages.size()]
	_previous.disabled = page_index == 0
	_next.text = "Fermer la discussion" if page_index + 1 >= pages.size() else "Suite →"
	_reader.scroll_vertical = 0
	if is_instance_valid(_page_fade): _page_fade.kill()
	_body.modulate = Color.WHITE
	if not _reduced_motion():
		_body.modulate.a = .45
		_page_fade = create_tween()
		_page_fade.tween_property(_body, "modulate:a", 1.0, .1)
	navigation_changed.emit()

func _reduced_motion() -> bool:
	return bool(SettingsService.current.get("reduce_motion", false))

func _exit_tree() -> void:
	for animation in [_entrance, _page_fade]:
		if is_instance_valid(animation): animation.kill()
