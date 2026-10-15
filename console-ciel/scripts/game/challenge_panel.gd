extends VBoxContainer
## Native, focusable challenge controls. Only InvestigationService validates a
## solution or commits a mission, its reward and its save in one transaction.

const GlassButton = preload("res://scripts/ui/translucent_button.gd")
const CircuitDiagram = preload("res://scripts/game/circuit_diagram.gd")
const Keyboard = preload("res://scripts/ui/virtual_keyboard.gd")

signal close_requested
signal mission_completed(result: Dictionary)
signal notification_requested(message: String)
signal navigation_changed

var mission_id: String = ""
var definition: Dictionary = {}
var feedback_label: Label
var submit_button: Button
var connection_buttons: Dictionary = {}
var observation_buttons: Dictionary = {}
var check_buttons: Dictionary = {}
var observation_details: Dictionary = {}
var check_details: Dictionary = {}
var diagnosis_selector: OptionButton
var repair_selector: OptionButton
var cause_selector: OptionButton
var correction_selector: OptionButton
var code_edit: LineEdit
var code_keyboard: VBoxContainer
var code_preview: Label
var circuit: Control
var _service: Node
var _busy: bool = false
var _finished: bool = false
var _available: bool = false
var _choice_details: Dictionary = {}
var _navigation_signature: String = ""

func _ready() -> void:
	theme_changed.connect(_sync_code_appearance)

func configure(id: String) -> void:
	mission_id = id
	_busy = false
	_finished = false
	_available = false
	name = "challenge_" + id
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	_service = get_node_or_null("/root/InvestigationService")
	for child in get_children():
		remove_child(child)
		child.queue_free()
	connection_buttons.clear()
	observation_buttons.clear()
	check_buttons.clear()
	observation_details.clear()
	check_details.clear()
	_choice_details.clear()
	_navigation_signature = ""
	code_edit = null
	code_keyboard = null
	code_preview = null
	if _service == null:
		_text("Service d’enquête indisponible.")
		_close_button()
		return
	definition = _service.mission(id)
	var title := _text(str(definition.get("title", definition.get("name", "Défi pédagogique"))))
	title.name = "challenge_title"
	title.add_theme_font_size_override("font_size",get_theme_default_font_size()+8)
	if mission_id not in ["python", "html", "markdown"]:
		_text(str(definition.get("description", "")))
	if mission_id == "lighting":
		_build_lighting()
	elif mission_id == "lock":
		_build_lock()
	elif mission_id == "computer":
		_build_computer()
	elif mission_id in ["network", "addressing", "security"]:
		_build_diagnostic()
	elif mission_id in ["python", "html", "markdown"]:
		_build_code()
	feedback_label = _text("")
	feedback_label.name = "challenge_feedback"
	feedback_label.hide()
	if not is_instance_valid(code_keyboard):
		_close_button()
	var start: Dictionary = _service.begin_mission(id)
	_available = bool(start.get("ok", false))
	if not bool(start.get("ok", false)):
		_feedback(str(start.get("error", "Mission indisponible.")), true)
		if is_instance_valid(submit_button):
			submit_button.disabled = true
	refresh()

func _text(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(label)
	return label

func _action(value: String, key: String, action: Callable) -> Button:
	var button := GlassButton.new()
	button.name = key
	button.text = value
	button.pressed.connect(action)
	add_child(button)
	return button

func _close_button() -> void:
	_action("Retour à la pièce", "challenge_close", func() -> void: close_requested.emit())

func _build_lighting() -> void:
	_text("Simulation pédagogique fictive en très basse tension (5 V). Ce défi ne décrit aucun câblage secteur.")
	circuit = CircuitDiagram.new()
	add_child(circuit)
	_text("Fermez la boucle : source → interrupteur → lampe → retour à la source. Choisissez les liaisons, puis vérifiez.")
	for raw in definition.get("connections", []):
		var item: Dictionary = raw
		var id := str(item.get("id", ""))
		var button := CheckButton.new()
		button.name = "light_connection_" + id
		button.text = str(item.get("label", id))
		button.custom_minimum_size.y = 48
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggled.connect(func(_pressed: bool) -> void: _connections_changed())
		add_child(button)
		connection_buttons[id] = button
	submit_button = _action("Vérifier le circuit", "light_validate", _submit_lighting)
	submit_button.theme_type_variation="PrimaryButton"

func _connections_changed() -> void:
	if is_instance_valid(circuit):
		circuit.set_connections(_selected_connections())

func _selected_connections() -> Array:
	var chosen: Array = []
	for id in connection_buttons:
		if connection_buttons[id].button_pressed:
			chosen.append(id)
	return chosen

func _observations() -> void:
	_text("1 · Consultez les observations avant de choisir un diagnostic.")
	for raw in definition.get("observations", []):
		var item: Dictionary = raw
		var id := str(item.get("id", ""))
		var button := _action(str(item.get("title", id)), "observation_" + id, func() -> void: _observe(id))
		button.set_meta("observation_title", button.text)
		observation_buttons[id] = button
		var details := _text(str(item.get("text", "")))
		details.hide()
		observation_details[id] = details

func _build_lock() -> void:
	_text("Serrure fictive : comparez alimentation, reconnaissance du badge et signal de commande.")
	_observations()
	_text("2 · Choisissez la cause qui explique toutes les observations.")
	diagnosis_selector = _selector("lock_diagnosis", "Choisir un diagnostic", definition.get("diagnoses", []))
	_text("3 · Sélectionnez la réparation virtuelle correspondante.")
	repair_selector = _selector("lock_repair", "Choisir une réparation", definition.get("repairs", []))
	submit_button = _action("Vérifier diagnostic et réparation", "lock_validate", _submit_lock)

func _build_computer() -> void:
	_text("Un ordinateur fictif : observez, vérifiez, puis expliquez la panne. Aucun réglage de ce PC de développement n’est modifié.")
	_observations()
	_text("2 · Effectuez les vérifications utiles dans la simulation.")
	for raw in definition.get("checks", []):
		var item: Dictionary = raw
		var id := str(item.get("id", ""))
		var button := _action(str(item.get("title", id)), "computer_check_" + id, func() -> void: _check_computer(id))
		button.set_meta("check_title", button.text)
		check_buttons[id] = button
		var details := _text(str(item.get("text", "")))
		details.hide()
		check_details[id] = details
	_text("3 · Identifiez la cause à partir de vos vérifications.")
	cause_selector = _selector("computer_cause", "Choisir une cause", definition.get("causes", []))
	_text("4 · Appliquez la correction virtuelle.")
	correction_selector = _selector("computer_correction", "Choisir une correction", definition.get("corrections", []))
	submit_button = _action("Vérifier et corriger l’ordinateur", "computer_validate", _submit_computer)

func _build_diagnostic() -> void:
	_text("Chapitre 2 · Simulation réseau locale. Les choix concernent uniquement les équipements fictifs de cette pièce.")
	_observations()
	_text("2 · Comparez les indices et identifiez la cause de la panne.")
	diagnosis_selector = _selector(mission_id + "_diagnosis", "Choisir un diagnostic", definition.get("diagnoses", []))
	_text("3 · Choisissez la correction qui résout cette cause.")
	repair_selector = _selector(mission_id + "_repair", "Choisir une réparation", definition.get("repairs", []))
	submit_button = _action("Vérifier diagnostic et correction", mission_id + "_validate", _submit_diagnostic)
	submit_button.theme_type_variation = "PrimaryButton"

func _build_code() -> void:
	var code: Dictionary = definition.get("code", {})
	add_theme_constant_override("separation", 5)
	_text(str(code.get("prompt", "Choisissez le mot ou le symbole qui complète ce code.")))
	code_preview = _text(str(code.get("template", "")))
	code_preview.name = mission_id + "_code_preview"
	# A plain Label preserves <h1>, quotes and # as literal text. The exercises
	# never execute Python, render HTML or interpret Markdown from a response.
	var monospace := SystemFont.new()
	monospace.font_names = PackedStringArray(["DejaVu Sans Mono", "Consolas", "Liberation Mono", "monospace"])
	code_preview.add_theme_font_override("font", monospace)
	_sync_code_appearance()
	code_preview.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	code_preview.custom_minimum_size.y = 30
	code_preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	code_edit = LineEdit.new()
	code_edit.name = mission_id + "_answer"
	code_edit.placeholder_text = "Mot / symbole manquant, ou exemple complet"
	code_edit.max_length = 64
	code_edit.custom_minimum_size.y = 40
	code_edit.virtual_keyboard_enabled = false
	code_edit.focus_entered.connect(func() -> void: _begin_code_edit.call_deferred())
	code_edit.text_changed.connect(func(_text: String) -> void:
		_update_code_preview()
		if is_instance_valid(feedback_label): feedback_label.hide()
		_update_submit_state())
	code_edit.text_submitted.connect(func(_text: String) -> void: _submit_code())
	add_child(code_edit)
	code_keyboard = Keyboard.new()
	code_keyboard.name = mission_id + "_keyboard"
	add_child(code_keyboard)
	code_keyboard.navigate_to_editor = true
	code_keyboard.configure(code_edit, 64)
	code_keyboard.submitted.connect(_submit_code)
	code_keyboard.cancelled.connect(func() -> void: close_requested.emit())
	code_keyboard.layout_changed.connect(func() -> void: navigation_changed.emit())
	submit_button = code_keyboard.get_node("actions/key_Valider")
	submit_button.name = mission_id + "_validate"
	submit_button.theme_type_variation = "PrimaryButton"
	code_keyboard.get_node("actions/key_Annuler").name = "challenge_close"
	code_edit.gui_input.connect(func(event: InputEvent) -> void:
		if event.is_action_pressed("ui_down") or (event is InputEventJoypadButton and event.is_action_pressed("ui_accept")):
			code_keyboard.focus_first_key()
			code_edit.accept_event())
	if mission_id == "markdown": code_keyboard._set_mode("symbols")

func _begin_code_edit() -> void:
	# Revenir depuis une touche à la manette peut focaliser le LineEdit sans
	# activer son édition. Le texte physique doit rester utilisable aussitôt.
	if is_instance_valid(code_edit) and code_edit.has_focus() and code_edit.editable:
		code_edit.edit()

func _sync_code_appearance() -> void:
	if is_instance_valid(code_preview):
		code_preview.add_theme_font_size_override("font_size", get_theme_font_size("font_size", "Label") + 2)

func _update_code_preview() -> void:
	if not is_instance_valid(code_preview) or not is_instance_valid(code_edit):
		return
	var template := str(definition.get("code", {}).get("template", ""))
	var value := code_edit.text.strip_edges()
	var full_line := (mission_id == "python" and value.contains("(")) or (mission_id == "html" and value.contains(">") and value.contains("</")) or (mission_id == "markdown" and value.contains(" "))
	if mission_id == "html" and value.to_lower() == "<h1>": value = value.substr(1, 2)
	code_preview.text = value if full_line else template.replace("____", value if not value.is_empty() else "____")

func _selector(key: String, placeholder: String, choices: Array, explain_choice: bool = true) -> OptionButton:
	var selector := OptionButton.new()
	selector.name = key
	selector.custom_minimum_size.y = 48
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.fit_to_longest_item = false
	selector.add_item(placeholder)
	selector.set_item_metadata(0, "")
	for raw in choices:
		var item: Dictionary = raw
		selector.add_item(str(item.get("label", item.get("id", ""))))
		selector.set_item_metadata(selector.item_count - 1, str(item.get("id", "")))
	add_child(selector)
	var details := _text("")
	details.hide()
	_choice_details[key] = details
	selector.item_selected.connect(func(index: int) -> void:
		if explain_choice and index > 0 and index <= choices.size():
			var item: Dictionary = choices[index - 1]
			details.text = str(item.get("feedback", ""))
			details.visible = not details.text.is_empty()
		else:
			details.hide()
		_update_submit_state())
	return selector

func _selection(selector: OptionButton) -> String:
	if not is_instance_valid(selector) or selector.selected < 0:
		return ""
	return str(selector.get_item_metadata(selector.selected))

func _stored_observations() -> Array:
	var state := get_node_or_null("/root/AppState")
	if state == null:
		return []
	var progress: Dictionary = state.profile.get("progress", {})
	var all: Dictionary = progress.get("observations", {})
	return all.get(mission_id, [])

func _stored_checks() -> Array:
	var state := get_node_or_null("/root/AppState")
	if state == null:
		return []
	var progress: Dictionary = state.profile.get("progress", {})
	var all: Dictionary = progress.get("checks", {})
	return all.get("computer", [])

func _observe(id: String) -> void:
	if _busy or _finished:
		return
	_busy = true
	var result: Dictionary = _service.observe(mission_id, id)
	_busy = false
	if bool(result.get("ok", false)):
		_feedback(str(result.get("data", {}).get("text", "Observation enregistrée.")))
	else:
		_feedback(str(result.get("error", "Observation non enregistrée.")), true)
	refresh()

func _check_computer(id: String) -> void:
	if _busy or _finished:
		return
	_busy = true
	var result: Dictionary = _service.check_computer(id)
	_busy = false
	if bool(result.get("ok", false)):
		_feedback(str(result.get("data", {}).get("text", "Vérification enregistrée.")))
	else:
		_feedback(str(result.get("error", "Vérification non enregistrée.")), true)
	refresh()

func refresh() -> void:
	var seen: Array = _stored_observations()
	for id in observation_buttons:
		var button: Button = observation_buttons[id]
		button.text = ("✓ " if seen.has(id) else "Voir · ") + str(button.get_meta("observation_title"))
		button.disabled = not _available or _finished
		observation_details[id].visible = seen.has(id)
	var checked: Array = _stored_checks()
	for id in check_buttons:
		var button: Button = check_buttons[id]
		button.text = ("✓ " if checked.has(id) else "○ ") + str(button.get_meta("check_title"))
		button.disabled = not _available or _finished or seen.size() < observation_buttons.size()
		check_details[id].visible = checked.has(id)
	for button in connection_buttons.values():
		button.disabled = not _available or _finished
	_update_submit_state()

func _update_submit_state() -> void:
	if not is_instance_valid(submit_button):
		return
	var seen: Array = _stored_observations()
	var observed_all := _available and seen.size() >= observation_buttons.size()
	if mission_id in ["lock", "network", "addressing", "security"]:
		diagnosis_selector.disabled = not observed_all
		repair_selector.disabled = not observed_all
		submit_button.disabled = _busy or _finished or not observed_all or _selection(diagnosis_selector).is_empty() or _selection(repair_selector).is_empty()
	elif mission_id == "computer":
		var checked: Array = _stored_checks()
		var verified := observed_all and checked.has("video") and checked.has("power")
		cause_selector.disabled = not verified
		correction_selector.disabled = not verified
		submit_button.disabled = _busy or _finished or not verified or _selection(cause_selector).is_empty() or _selection(correction_selector).is_empty()
	elif mission_id in ["python", "html", "markdown"]:
		code_edit.editable = _available and not _busy and not _finished
		for button in code_keyboard.find_children("*", "BaseButton", true, false):
			button.disabled = not code_edit.editable
		submit_button.disabled = not code_edit.editable or code_edit.text.strip_edges().is_empty()
	else:
		submit_button.disabled = not _available or _busy or _finished
	var states: Array = []
	for child in get_children():
		if child is BaseButton:
			states.append([str(child.name), child.disabled])
	if is_instance_valid(code_keyboard):
		states.append(["code_submit", submit_button.disabled])
	var next_signature := JSON.stringify(states)
	if next_signature != _navigation_signature:
		_navigation_signature = next_signature
		navigation_changed.emit()

func _feedback(value: String, is_error: bool = false) -> void:
	if not is_instance_valid(feedback_label):
		return
	feedback_label.text = ("! " if is_error else "ℹ ") + value
	feedback_label.show()
	# The symbol and message remain understandable without depending on color.
	feedback_label.remove_theme_color_override("font_color")
	notification_requested.emit(value)

func _submit_lighting() -> void:
	if _busy or _finished:
		return
	_busy = true
	_finish_submission(_service.submit_lighting(_selected_connections()))

func _submit_lock() -> void:
	if _busy or _finished:
		return
	_busy = true
	_finish_submission(_service.submit_lock(_selection(diagnosis_selector), _selection(repair_selector)))

func _submit_computer() -> void:
	if _busy or _finished:
		return
	_busy = true
	_finish_submission(_service.submit_computer(_stored_checks(), _selection(cause_selector), _selection(correction_selector)))

func _submit_diagnostic() -> void:
	if _busy or _finished:
		return
	_busy = true
	_finish_submission(_service.submit_diagnostic(mission_id, _selection(diagnosis_selector), _selection(repair_selector)))

func _submit_code() -> void:
	if _busy or _finished or not _available or not is_instance_valid(code_edit) or code_edit.text.strip_edges().is_empty():
		return
	_busy = true
	_finish_submission(_service.submit_code_text(mission_id, code_edit.text))

func _finish_submission(result: Dictionary) -> void:
	_busy = false
	if not bool(result.get("ok", false)):
		_feedback(str(result.get("error", "Réponse non validée. Modifiez votre choix puis réessayez.")), true)
		_update_submit_state()
		return
	_finished = true
	_update_submit_state()
	mission_completed.emit(result)
