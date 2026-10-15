extends SceneTree
## Clavier réel Godot, événements natifs et callbacks : aucune sauvegarde modifiée.
## godot --headless --path . --script res://tests/keyboard_tests.gd

const Keyboard = preload('res://scripts/ui/virtual_keyboard.gd')
const ThemeFactory = preload('res://scripts/ui/theme_factory.gd')

var checks := 0
var failures: Array[String] = []
var fixture: MarginContainer
var editor: LineEdit
var keyboard
var submitted_count := 0
var cancelled_count := 0
var layout_count := 0
var last_changed_text := ''


func _initialize() -> void:
	call_deferred('_run')


func _run() -> void:
	await process_frame
	Input.use_accumulated_input = false
	# InputSetup réserve les commandes natives à la manette active déclarée.
	# Le périphérique virtuel est explicite et ne prétend pas être physique.
	_check(root.get_node('ControllerService').debug_set_devices([0]), 'Manette virtuelle déclarée pour les événements du test')
	root.size = Vector2i(800, 480)
	await _create_fixture(false)
	await _test_letters()
	await _test_pages()
	_test_selection_and_limits()
	await _test_native_input()
	await _test_focus()
	_test_actions()
	await _check_layout(false)
	await _create_fixture(true)
	await _check_layout(true)
	editor.max_length = 64
	keyboard.configure(editor, 64)
	editor.text = ""
	for character in '<h1>Bonjour CIEL</h1>': keyboard._insert(character)
	_check(editor.text == '<h1>Bonjour CIEL</h1>' and editor.text.length() > 16, 'Le clavier accepte une ligne de code dépassant la limite du pseudo quand configuré pour les défis')
	editor.text = "a".repeat(64)
	editor.caret_column = 64
	_check(not keyboard._insert('b') and editor.text.length() == 64, 'La limite du champ code reste appliquée sans tronquer le texte')
	fixture.queue_free()
	await process_frame
	root.get_node('ControllerService').debug_clear_devices()
	print('KEYBOARD : %d assertions, %d échec(s).' % [checks, failures.size()])
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _create_fixture(large: bool) -> void:
	if is_instance_valid(fixture):
		fixture.queue_free()
		await process_frame
	fixture = MarginContainer.new()
	fixture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ['left', 'right', 'top', 'bottom']:
		fixture.add_theme_constant_override('margin_' + side, 16)
	fixture.theme = ThemeFactory.build({'large_text': large, 'reduce_transparency': false}, {})
	root.add_child(fixture)
	var column := VBoxContainer.new()
	column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	fixture.add_child(column)
	editor = LineEdit.new()
	editor.max_length = 16
	editor.text_changed.connect(func(value: String): last_changed_text = value)
	editor.custom_minimum_size.y = 40
	column.add_child(editor)
	keyboard = Keyboard.new()
	column.add_child(keyboard)
	keyboard.configure(editor)
	keyboard.submitted.connect(func(): submitted_count += 1)
	keyboard.cancelled.connect(func(): cancelled_count += 1)
	keyboard.layout_changed.connect(func(): layout_count += 1)
	await _frames(3)


func _test_letters() -> void:
	_check(keyboard.input_mode == 'letters' and keyboard.shift_state == 0, 'Minuscules et page lettres par défaut')
	var first_row := ''
	for button in _find('key_A').get_parent().get_children():
		first_row += button.text
	_check(first_row == 'azertyuiop', 'Première rangée AZERTY française')
	_check(_find('key_Z').text == 'z' and _find('key_A').text == 'a', 'Identifiants alphabétiques stables avec des étiquettes minuscules')
	editor.text = 'Pseudo proposé'
	editor.grab_focus()
	editor.select_all()
	await _activate('key_A')
	_check(editor.text == 'a' and editor.caret_column == 1, 'Entrée sur une touche remplace la sélection, sans perdre le curseur')
	_check(last_changed_text == 'a', 'Le remplacement avertit les aperçus connectés au changement du pseudo')
	await _activate('key_Shift')
	_check(keyboard.shift_state == 1 and _find('key_A').text == 'A', 'Flèche active la majuscule de la prochaine lettre')
	await _activate('key_B')
	_check(editor.text == 'aB' and keyboard.shift_state == 0 and _find('key_A').text == 'a', 'Après une majuscule, retour automatique aux minuscules')
	_check(last_changed_text == 'aB', 'La saisie sans sélection avertit aussi les aperçus du profil')
	await _activate('key_C')
	_check(editor.text == 'aBc', 'La lettre suivante reste minuscule')
	# Deux callbacks consécutifs testent le double appui sans temporisation
	# dépendante de la vitesse du rendu ou de la machine de CI.
	_find('key_Shift').pressed.emit()
	_find('key_Shift').pressed.emit()
	_check(keyboard.shift_state == 2 and _find('key_Shift').button_pressed, 'Double appui verrouille les majuscules et indique son état')
	_find('key_D').pressed.emit()
	_find('key_E').pressed.emit()
	_check(editor.text == 'aBcDE' and keyboard.shift_state == 2, 'Le verrouillage persiste sur plusieurs lettres')
	_find('key_Shift').pressed.emit()
	_check(keyboard.shift_state == 0 and not _find('key_Shift').button_pressed, 'Nouvel appui déverrouille les majuscules')
	_find('key_É').pressed.emit()
	_check(editor.text == 'aBcDEé', 'Lettre française accentuée accessible sans clavier physique')


func _test_pages() -> void:
	editor.text = 'abcdef'
	editor.caret_column = 4
	editor.select(1, 3)
	var caret := editor.caret_column
	var mode_button := _find('key_123')
	await _activate('key_123')
	_check(keyboard.input_mode == 'numbers' and mode_button.text == 'ABC', '123 affiche chiffres et ponctuation avec retour ABC')
	_check(editor.text == 'abcdef' and editor.caret_column == caret and editor.has_selection(), 'Changer de page conserve texte, sélection et curseur')
	_check(root.gui_get_focus_owner() == mode_button, 'Le focus reste sur le bouton de mode stable')
	_check(_find('key_A') == null and _find('key_1') != null, 'Seules les touches de la page active sont visibles')
	await _activate('key_1')
	_check(editor.text == 'a1def' and editor.caret_column == 2, 'Une touche numérique remplace uniquement la sélection')
	await _activate('key_numbers_1_8')
	await _activate('key_numbers_2_0')
	_check(editor.text == 'a1@.def' and editor.caret_column == 4, 'Ponctuation et caractère spécial insérés au curseur')
	await _activate('key_Symbols')
	_check(keyboard.input_mode == 'symbols' and root.gui_get_focus_owner() == _find('key_symbols_0_0'), '#+= ouvre la seconde page et garde un focus visible')
	await _activate('key_symbols_0_0')
	_check(editor.text == 'a1@.[def', 'Symbole de la seconde page saisi')
	await _activate('key_Numbers')
	_check(keyboard.input_mode == 'numbers', '123 sur la page symboles revient aux chiffres')
	await _activate('key_123')
	_check(keyboard.input_mode == 'letters' and _find('key_123') == mode_button, 'ABC revient aux lettres sans recréer les actions')
	_check(layout_count == 4, 'Chaque changement de page signale le recalcul de navigation')


func _test_selection_and_limits() -> void:
	editor.text = '1234567890123456'
	editor.deselect()
	editor.caret_column = 8
	_find('key_A').pressed.emit()
	_check(editor.text == '1234567890123456' and editor.caret_column == 8, 'Limite de 16 : insertion refusée sans modification du texte ou du curseur')
	_find('key_Shift').pressed.emit()
	_find('key_A').pressed.emit()
	_check(keyboard.shift_state == 1, 'Majuscule ponctuelle conservée quand la saisie est refusée')
	editor.select(2, 4)
	var caret := editor.caret_column
	_check(not keyboard._insert('trop'), 'Remplacement dépassant la limite explicitement refusé')
	_check(editor.text == '1234567890123456' and editor.has_selection() and editor.get_selection_from_column() == 2 and editor.get_selection_to_column() == 4 and editor.caret_column == caret, 'Insertion refusée préserve aussi toute la sélection')
	_find('key_A').pressed.emit()
	_check(editor.text == '12A567890123456' and editor.caret_column == 3 and keyboard.shift_state == 0, 'Remplacement permis même à la limite ; majuscule consommée après succès')
	editor.text = 'abcdef'
	editor.caret_column = 3
	editor.deselect()
	_find('key_Effacer').pressed.emit()
	_check(editor.text == 'abdef' and editor.caret_column == 2, 'Effacer retire avant le curseur et recule exactement d’une colonne')
	_find('key_Effacer').pressed.emit()
	_check(editor.text == 'adef' and editor.caret_column == 1, 'Deux effacements successifs utilisent le nouveau curseur')
	editor.select(1, 3)
	_find('key_Effacer').pressed.emit()
	_check(editor.text == 'af' and editor.caret_column == 1 and not editor.has_selection(), 'Effacer retire la sélection et place le curseur à son début')
	editor.caret_column = 0
	_find('key_Effacer').pressed.emit()
	_check(editor.text == 'af' and editor.caret_column == 0, 'Effacer au début ne modifie pas le pseudo')
	editor.max_length = 4
	editor.text = 'abcd'
	editor.select(1, 2)
	_check(not keyboard._insert('XY') and editor.text == 'abcd' and editor.has_selection(), 'Une limite plus stricte du champ est aussi respectée sans suppression préalable')
	editor.max_length = 16
	editor.editable = false
	_find('key_Effacer').pressed.emit()
	_check(not keyboard._insert('x') and editor.text == 'abcd', 'Un champ désactivé ne peut être modifié par le clavier virtuel')
	editor.editable = true


func _test_native_input() -> void:
	editor.text = ''
	editor.deselect()
	editor.caret_column = 0
	editor.grab_focus()
	await _press(KEY_Z, 'z')
	await _press(KEY_9, '9')
	await _press(KEY_SLASH, '?', true)
	_check(editor.text == 'z9?', 'Le clavier physique conserve lettres, chiffres et ponctuation')
	await _press(KEY_LEFT)
	await _press(KEY_X, 'x')
	_check(editor.text == 'z9x?', 'Le clavier physique conserve la navigation du curseur et l’insertion au milieu')


func _test_focus() -> void:
	editor.text = ''
	editor.deselect()
	keyboard.focus_first_key()
	_check(root.gui_get_focus_owner() == _find('key_A'), 'API de focus initial sur la première touche de la page active')
	await _press(KEY_RIGHT)
	_check(root.gui_get_focus_owner() == _find('key_Z'), 'Flèche droite navigue au caractère AZERTY suivant')
	await _press(KEY_DOWN)
	_check(root.gui_get_focus_owner() == _find('key_S'), 'Flèche bas navigue à la rangée suivante')
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(2)
	_check(editor.text == 's', 'Validation par face bas manette simulée saisit une lettre une seule fois')
	await _activate('key_123')
	keyboard.focus_first_key()
	_check(root.gui_get_focus_owner() == _find('key_1'), 'La même API de focus fonctionne sur la page chiffres')
	await _press(KEY_RIGHT)
	_check(root.gui_get_focus_owner() == _find('key_2'), 'Navigation clavier recalculée sur les chiffres')
	await _activate('key_123')
	for button in _visible_keys():
		for side in [SIDE_TOP, SIDE_BOTTOM, SIDE_LEFT, SIDE_RIGHT]:
			var target := button.get_node_or_null(button.get_focus_neighbor(side)) as Control
			_check(is_instance_valid(target) and target.is_visible_in_tree(), 'Voisin visible utilisable par la manette : %s / %d' % [button.name, side])


func _test_actions() -> void:
	var before := editor.text
	_find('key_Valider').pressed.emit()
	_find('key_Annuler').pressed.emit()
	_check(submitted_count == 1 and cancelled_count == 1 and editor.text == before, 'Valider et Annuler émettent leurs signaux sans modifier le pseudo')
	_find('key_Espace').pressed.emit()
	_check(editor.text == before + ' ', 'Bouton Espace conservé')


func _check_layout(large: bool) -> void:
	for mode in ['letters', 'numbers', 'symbols']:
		keyboard._set_mode(mode)
		await _frames(3)
		_check(keyboard.get_combined_minimum_size().x <= 768 and keyboard.size.x <= 768, 'Clavier tient en largeur à 800×480 / %s / grand=%s' % [mode, large])
		_check(keyboard.size.y <= 190, 'Clavier compact en quatre rangées / %s / grand=%s' % [mode, large])
		var bounds: Rect2 = keyboard.get_global_rect()
		var ids := {}
		for button in _visible_keys():
			var rect := button.get_global_rect()
			_check(rect.position.x >= bounds.position.x - 1 and rect.end.x <= bounds.end.x + 1 and rect.end.y <= 480, 'Touche dans le viewport : %s / grand=%s' % [button.name, large])
			_check(button.get_theme_font_size('font_size') == (22 if large else 18), 'Réglage de taille de texte préservé : %s' % button.name)
			_check(not ids.has(button.name), 'Identifiant unique sur la page : ' + button.name)
			ids[button.name] = true


func _visible_keys() -> Array[Button]:
	var result: Array[Button] = []
	for node in keyboard.find_children('*', 'Button', true, false):
		if node.is_visible_in_tree():
			result.append(node)
	return result


func _find(id: String) -> Button:
	for button in _visible_keys():
		if button.name == id:
			return button
	return null


func _activate(id: String) -> void:
	var button := _find(id)
	_check(button != null, 'Touche active disponible : ' + id)
	if button == null:
		return
	button.grab_focus()
	await _press(KEY_ENTER)


func _press(keycode: Key, character := '', shift := false) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.unicode = character.unicode_at(0) if not character.is_empty() else 0
	event.shift_pressed = shift
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(2)


func _frames(count: int) -> void:
	for index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
