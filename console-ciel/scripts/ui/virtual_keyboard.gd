extends VBoxContainer
## Clavier AZERTY : les pages restent en place, la saisie et le focus sont conservés.

const GlassButton = preload('res://scripts/ui/translucent_button.gd')
const DOUBLE_SHIFT_MSEC := 550
const NAME_LIMIT := 16

signal submitted
signal cancelled
signal layout_changed

var editor: LineEdit
var input_mode := 'letters'
# 0 = minuscules, 1 = prochaine lettre en majuscule, 2 = verrouillage.
var shift_state := 0
var _last_shift_msec := -DOUBLE_SHIFT_MSEC
var _pages: Dictionary = {}
var _letter_buttons: Dictionary = {}
var _shift_button: Button
var _mode_button: Button
var _first_buttons: Dictionary = {}
var _configured := false


func configure(line_edit: LineEdit) -> void:
	editor = line_edit
	# Cliquer une touche ne doit pas supprimer la sélection du pseudo.
	editor.deselect_on_focus_loss_enabled = false
	if _configured:
		return
	_configured = true
	add_theme_constant_override('separation', 5)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_letters()
	_build_numbers()
	_build_symbols()
	_build_actions()
	_update_letter_labels()
	_apply_mode()


func _new_page(mode: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = 'page_' + mode
	page.add_theme_constant_override('separation', 5)
	add_child(page)
	_pages[mode] = page
	return page


func _new_row(host: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override('separation', 4)
	host.add_child(row)
	return row


func _key(host: Node, label: String, id: String, action: Callable) -> Button:
	var button := GlassButton.new()
	button.name = id
	button.text = label
	button.custom_minimum_size = Vector2(0, 38)
	# Le thème général a des marges de carte ; les touches restent compactes,
	# y compris avec le réglage de texte agrandi.
	for state in ['normal', 'hover', 'pressed', 'disabled', 'focus']:
		var box: StyleBox = get_theme_stylebox(state, 'Button').duplicate()
		box.content_margin_left = 4
		box.content_margin_right = 4
		box.content_margin_top = 5
		box.content_margin_bottom = 5
		if box is StyleBoxFlat:
			box.set_corner_radius_all(9)
			box.shadow_size = 0 if state == 'focus' else 2
		button.add_theme_stylebox_override(state, box)
	host.add_child(button)
	button.pressed.connect(action)
	return button


func _letter_row(host: Node, characters: String) -> HBoxContainer:
	var row := _new_row(host)
	for character in characters:
		var button := _key(row, character, 'key_' + character.to_upper(), _type_letter.bind(character))
		_letter_buttons[character] = button
	return row


func _build_letters() -> void:
	var page := _new_page('letters')
	var first := _letter_row(page, 'azertyuiop')
	_first_buttons.letters = first.get_child(0)
	_letter_row(page, 'qsdfghjklm')
	var last := _new_row(page)
	_shift_button = _key(last, '⇧', 'key_Shift', _shift)
	_shift_button.toggle_mode = true
	_shift_button.size_flags_stretch_ratio = 1.4
	_shift_button.tooltip_text = 'Majuscule pour une lettre · double appui : verrouiller les majuscules'
	for character in 'wxcvbn':
		_letter_buttons[character] = _key(last, character, 'key_' + character.to_upper(), _type_letter.bind(character))
	for character in ['é', 'è']:
		_letter_buttons[character] = _key(last, character, 'key_' + character.to_upper(), _type_letter.bind(character))


func _character_row(host: Node, characters: String, mode: String, row_id: int) -> HBoxContainer:
	var row := _new_row(host)
	var index := 0
	for character in characters:
		# Les identifiants des chiffres restent key_0 à key_9.
		var id := 'key_' + character if character.is_valid_int() else 'key_%s_%d_%d' % [mode, row_id, index]
		_key(row, character, id, _insert.bind(character))
		index += 1
	return row


func _build_numbers() -> void:
	var page := _new_page('numbers')
	var first := _character_row(page, '1234567890', 'numbers', 0)
	_first_buttons.numbers = first.get_child(0)
	_character_row(page, '-/:;()€&@"', 'numbers', 1)
	var last := _new_row(page)
	var alternate := _key(last, '#+=', 'key_Symbols', _set_mode.bind('symbols'))
	alternate.size_flags_stretch_ratio = 1.4
	alternate.tooltip_text = 'Plus de symboles et de lettres accentuées'
	for index in range(5):
		var character: String = ['.', ',', '?', '!', "'"][index]
		_key(last, character, 'key_numbers_2_%d' % index, _insert.bind(character))


func _build_symbols() -> void:
	var page := _new_page('symbols')
	var first := _character_row(page, '[]{}#%^*+=', 'symbols', 0)
	_first_buttons.symbols = first.get_child(0)
	_character_row(page, '_\\|~<>$£¥•', 'symbols', 1)
	var last := _new_row(page)
	var alternate := _key(last, '123', 'key_Numbers', _set_mode.bind('numbers'))
	alternate.size_flags_stretch_ratio = 1.4
	alternate.tooltip_text = 'Chiffres et ponctuation'
	for index in range(5):
		var character: String = ['é', 'è', 'à', 'ç', 'ù'][index]
		_key(last, character, 'key_symbols_2_%d' % index, _insert.bind(character))


func _build_actions() -> void:
	var row := _new_row(self)
	row.name = 'actions'
	_mode_button = _key(row, '123', 'key_123', _toggle_mode)
	_mode_button.tooltip_text = 'Passer aux chiffres et symboles, ou revenir aux lettres'
	var space := _key(row, 'Espace', 'key_Espace', _insert.bind(' '))
	space.size_flags_stretch_ratio = 1.7
	_key(row, 'Effacer', 'key_Effacer', _erase)
	_key(row, 'Valider', 'key_Valider', func(): submitted.emit())
	_key(row, 'Annuler', 'key_Annuler', func(): cancelled.emit())


func _type_letter(character: String) -> void:
	var value := character.to_upper() if shift_state > 0 else character
	if _insert(value) and shift_state == 1:
		shift_state = 0
		_update_letter_labels()


func _shift() -> void:
	var now := Time.get_ticks_msec()
	if shift_state == 0:
		shift_state = 1
	elif shift_state == 1 and now - _last_shift_msec <= DOUBLE_SHIFT_MSEC:
		shift_state = 2
	else:
		shift_state = 0
	_last_shift_msec = now
	_update_letter_labels()


func _update_letter_labels() -> void:
	for character in _letter_buttons:
		_letter_buttons[character].text = character.to_upper() if shift_state > 0 else character
	_shift_button.text = '⇪' if shift_state == 2 else '⇧'
	_shift_button.button_pressed = shift_state > 0


func _toggle_mode() -> void:
	_set_mode('numbers' if input_mode == 'letters' else 'letters')


func _set_mode(mode: String) -> void:
	if not _pages.has(mode) or input_mode == mode:
		return
	var focus: Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var restore_first: bool = is_instance_valid(focus) and is_ancestor_of(focus) and _pages[input_mode].is_ancestor_of(focus)
	input_mode = mode
	_apply_mode()
	if restore_first:
		focus_first_key()
	# Main peut rétablir les liens vers les avatars, le pseudo et les actions.
	layout_changed.emit()


func _apply_mode() -> void:
	for mode in _pages:
		_pages[mode].visible = mode == input_mode
	_mode_button.text = '123' if input_mode == 'letters' else 'ABC'
	call_deferred('_wire_keys')


func focus_first_key() -> void:
	if _first_buttons.has(input_mode) and is_inside_tree():
		_first_buttons[input_mode].grab_focus()


func _wire_keys() -> void:
	if not is_inside_tree():
		return
	var rows: Array = []
	for row in _pages[input_mode].get_children():
		rows.append(row.get_children())
	rows.append(get_node('actions').get_children())
	var keys: Array = []
	for row in rows:
		keys.append_array(row)
	for index in range(keys.size()):
		var button: Button = keys[index]
		button.focus_next = button.get_path_to(keys[(index + 1) % keys.size()])
		button.focus_previous = button.get_path_to(keys[posmod(index - 1, keys.size())])
	# Des voisins explicites permettent aussi la navigation manette, sans
	# attendre le recalcul global de Main lors d'un changement de page.
	for row_index in range(rows.size()):
		var row: Array = rows[row_index]
		for index in range(row.size()):
			var button: Button = row[index]
			button.focus_neighbor_left = button.get_path_to(row[posmod(index - 1, row.size())])
			button.focus_neighbor_right = button.get_path_to(row[(index + 1) % row.size()])
			for side in [SIDE_TOP, SIDE_BOTTOM]:
				var next_index := posmod(row_index + (-1 if side == SIDE_TOP else 1), rows.size())
				var next_row: Array = rows[next_index]
				var column := mini(next_row.size() - 1, int((float(index) + 0.5) / row.size() * next_row.size()))
				button.set_focus_neighbor(side, button.get_path_to(next_row[column]))


func _insert(value: String) -> bool:
	if not is_instance_valid(editor) or not editor.editable:
		return false
	var start := editor.get_selection_from_column() if editor.has_selection() else editor.caret_column
	var end := editor.get_selection_to_column() if editor.has_selection() else start
	var replacing := editor.has_selection()
	var limit := mini(NAME_LIMIT, editor.max_length) if editor.max_length > 0 else NAME_LIMIT
	# Valider la longueur avant de toucher à la sélection : une insertion
	# refusée conserve le texte, la sélection et la position du curseur.
	if editor.text.length() - (end - start) + value.length() > limit:
		return false
	if replacing:
		editor.delete_text(start, end)
		editor.deselect()
		editor.caret_column = start
	editor.insert_text_at_caret(value)
	# insert_text_at_caret() n'émet pas text_changed ; delete_text() l'émet
	# de façon différée. Les aperçus du profil doivent aussi suivre une saisie
	# qui n'a remplacé aucune sélection, sans doubler le signal de suppression.
	if not replacing:
		editor.text_changed.emit(editor.text)
	return true


func _erase() -> void:
	if not is_instance_valid(editor) or not editor.editable:
		return
	if editor.has_selection():
		var start := editor.get_selection_from_column()
		editor.delete_text(start, editor.get_selection_to_column())
		editor.deselect()
		editor.caret_column = start
	elif editor.caret_column > 0:
		var column := editor.caret_column
		editor.delete_text(column - 1, column)
		editor.caret_column = column - 1
