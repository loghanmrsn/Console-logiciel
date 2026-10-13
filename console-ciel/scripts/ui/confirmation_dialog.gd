extends Control
const GlassButton = preload('res://scripts/ui/translucent_button.gd')

signal closed

var callback: Callable
var on_cancel: Callable
var disabled_controls: Array = []
var original_focus: Control
var buttons: Array = []
var _closed: bool = false
var _scroll: ScrollContainer
var _column: VBoxContainer
var _panel: PanelContainer
var _layout_serial: int = 0

func open(host: Control, title: String, message: String, confirm: String, accepted: Callable, cancelled: Callable = Callable()) -> void:
	callback = accepted
	on_cancel = cancelled
	_open(host, title, message, [
		{"key": "modal_cancel", "text": "Annuler", "action": cancelled},
		{"key": "modal_confirm", "text": confirm, "action": accepted}
	], false)

func open_choices(host: Control, title: String, message: String, choices: Array) -> void:
	# Le premier choix garde la session ouverte et sert aussi à Échap / Retour.
	if choices.is_empty():
		return
	on_cancel = choices[0].get("action", Callable())
	_open(host, title, message, choices, true)

func _resolved_theme(host: Control) -> Theme:
	var current: Node = host
	while current != null:
		if current is Control and current.theme != null:
			return current.theme
		current = current.get_parent()
	return null

func _open(host: Control, title: String, message: String, choices: Array, vertical: bool) -> void:
	original_focus = host.get_viewport().gui_get_focus_owner()
	_disable_focus(host)
	host.add_child(self)
	add_to_group("blocking_confirmation")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	SceneRouter.lock_until_release()
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var shade := ColorRect.new()
	shade.color = Color(.15, .20, .25, .35)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	# CanvasLayer ne porte pas de thème : l'assigner au contenu garantit le
	# grand texte et les panneaux opaques dans tous les dialogues.
	margin.theme = _resolved_theme(host)
	layer.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	var center := CenterContainer.new()
	margin.add_child(center)
	_panel = PanelContainer.new()
	center.add_child(_panel)
	_scroll = ScrollContainer.new()
	_scroll.name = "modal_scroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.follow_focus = true
	_panel.add_child(_scroll)
	_column = VBoxContainer.new()
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.add_theme_constant_override("separation", 16)
	_scroll.add_child(_column)
	var heading := Label.new()
	heading.text = title
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size", margin.get_theme_default_font_size() + 8)
	_column.add_child(heading)
	var body := Label.new()
	body.text = message
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_column.add_child(body)
	var row: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	_column.add_child(row)
	for choice in choices:
		var button := GlassButton.new()
		button.name = str(choice.get("key", "modal_choice"))
		button.text = str(choice.get("text", "Continuer"))
		row.add_child(button)
		var action: Callable = choice.get("action", Callable())
		button.pressed.connect(_choose.bind(action))
		button.focus_entered.connect(_show_focused.bind(button))
		buttons.append(button)
	for index in range(buttons.size()):
		var button: Control = buttons[index]
		var previous: Control = buttons[(index - 1 + buttons.size()) % buttons.size()]
		var next: Control = buttons[(index + 1) % buttons.size()]
		button.focus_neighbor_left = button.get_path_to(previous)
		button.focus_neighbor_right = button.get_path_to(next)
		button.focus_neighbor_top = button.get_path_to(previous)
		button.focus_neighbor_bottom = button.get_path_to(next)
		button.focus_previous = button.get_path_to(previous)
		button.focus_next = button.get_path_to(next)
	var hint := Label.new()
	hint.text = "Q / E ou boutons supérieurs : défiler le texte"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_column.add_child(hint)
	resized.connect(_resize_dialog)
	_resize_dialog()
	buttons[0].call_deferred("grab_focus")

func _resize_dialog() -> void:
	if _closed or not is_instance_valid(_panel):
		return
	var bounds := get_viewport_rect().size
	_panel.custom_minimum_size.x = minf(maxf(bounds.x - 40, 240), 560)
	var style := _panel.get_theme_stylebox("panel")
	var padding := style.get_content_margin(SIDE_TOP) + style.get_content_margin(SIDE_BOTTOM)
	var available := maxf(bounds.y - 40 - padding, 100)
	_scroll.custom_minimum_size.y = minf(240, available)
	_layout_serial += 1
	_fit_content.call_deferred(_layout_serial, available)

func _fit_content(serial: int, available: float) -> void:
	if _closed or not is_inside_tree(): return
	await get_tree().process_frame
	if _closed or not is_inside_tree(): return
	await get_tree().process_frame
	if _closed or serial != _layout_serial or not is_inside_tree():
		return
	_scroll.custom_minimum_size.y = minf(_column.get_combined_minimum_size().y, available)
	var focused := get_viewport().gui_get_focus_owner()
	if focused in buttons:
		_show_focused(focused)

func _show_focused(button: Control) -> void:
	if not _closed and is_instance_valid(_scroll) and is_instance_valid(button) and button.is_inside_tree():
		_scroll.ensure_control_visible.call_deferred(button)

func _disable_focus(node: Node) -> void:
	if node is Control and node.focus_mode != Control.FOCUS_NONE:
		disabled_controls.append([node, node.focus_mode])
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_disable_focus(child)

func _input(event: InputEvent) -> void:
	if _closed:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		if not SceneRouter.gameplay_allowed():
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cancel_dialog()
	elif event.is_action_pressed("tab_previous") or event.is_action_pressed("tab_next"):
		# Les longues explications restent lisibles au clavier et à la manette.
		var direction := -1 if event.is_action_pressed("tab_previous") else 1
		_scroll.scroll_vertical += direction * 80
		get_viewport().set_input_as_handled()

func cancel_dialog() -> void:
	_choose(on_cancel)

func _accept() -> void:
	_choose(callback)

func _choose(action: Callable) -> void:
	if _closed:
		return
	_close()
	if action.is_valid():
		action.call_deferred()

func _restore_focus() -> void:
	if is_instance_valid(original_focus) and original_focus.is_inside_tree() and original_focus.is_visible_in_tree() and original_focus.focus_mode != Control.FOCUS_NONE:
		original_focus.grab_focus()

func _close() -> void:
	if _closed:
		return
	_closed = true
	remove_from_group("blocking_confirmation")
	SceneRouter.lock_until_release()
	for button in buttons:
		button.disabled = true
	for entry in disabled_controls:
		if is_instance_valid(entry[0]):
			entry[0].focus_mode = entry[1]
	_restore_focus.call_deferred()
	# Le propriétaire libère son contexte avant tout callback qui change d'écran.
	closed.emit()
	queue_free()


func _exit_tree() -> void:
	# Restore surviving controls even if a parent removes the dialog abruptly.
	for entry in disabled_controls:
		if is_instance_valid(entry[0]): entry[0].focus_mode = entry[1]
