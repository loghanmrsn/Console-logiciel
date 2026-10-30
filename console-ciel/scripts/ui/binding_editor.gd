extends VBoxContainer
## Capture one physical input without passing the same press to navigation.
const Mapping = preload("res://scripts/input_setup.gd")
signal changed(bindings: Dictionary)
var bindings: Dictionary = {}
var waiting_action := ""
var waiting_kind := ""
var status: Label
var rows: Dictionary = {}

func configure(values: Dictionary) -> void:
	bindings = values.duplicate(true)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.text = "Choisissez une commande, puis appuyez sur la touche ou le bouton souhaité. Appliquer enregistre ; Annuler restaure."
	add_child(status)
	for action in Mapping.CUSTOM_ACTIONS:
		var row := HBoxContainer.new()
		add_child(row)
		var title := Label.new()
		title.text = Mapping.CUSTOM_ACTIONS[action]
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(title)
		for kind in ["key", "button"]:
			var button := Button.new()
			button.name = "bind_" + action + "_" + kind
			button.custom_minimum_size = Vector2(135, 44)
			button.pressed.connect(func(): _capture(action, kind))
			row.add_child(button)
			rows[action + ":" + kind] = button
	var cancel := Button.new()
	cancel.text = "Annuler la saisie"
	cancel.pressed.connect(_cancel)
	add_child(cancel)
	var reset := Button.new()
	reset.name = "bindings_reset"
	reset.text = "Restaurer les commandes par défaut"
	reset.pressed.connect(func():
		_cancel()
		bindings = {}
		changed.emit(bindings.duplicate(true))
		_refresh())
	add_child(reset)
	_refresh()

func _refresh() -> void:
	for id in rows:
		var parts: PackedStringArray = id.split(":")
		var action := parts[0]
		var kind := parts[1]
		var names: Array[String] = []
		for event in InputMap.action_get_events(action):
			if kind == "key" and event is InputEventKey: names.append(OS.get_keycode_string(event.keycode))
			elif kind == "button" and event is InputEventJoypadButton: names.append("Bouton %d" % event.button_index)
		rows[id].text = " / ".join(names) if not names.is_empty() else "Attribuer"

func _capture(action: String, kind: String) -> void:
	_refresh()
	waiting_action = action
	waiting_kind = kind
	rows[action + ":" + kind].text = "Appuyez…"
	status.text = "Appuyez sur %s pour : %s. Vous pouvez annuler avec le bouton ci-dessous." % ["une touche" if kind == "key" else "un bouton de manette", Mapping.CUSTOM_ACTIONS[action]]

func _cancel() -> void:
	waiting_action = ""
	waiting_kind = ""
	status.text = "Sélectionnez une commande à modifier."
	_refresh()

func _input(event: InputEvent) -> void:
	if waiting_action.is_empty() or not is_visible_in_tree(): return
	if not ControllerService.accepts_event(event) or event.is_echo(): return
	var code := -1
	if waiting_kind == "key" and event is InputEventKey and event.pressed:
		code = event.keycode
	elif waiting_kind == "button" and event is InputEventJoypadButton and event.pressed:
		code = event.button_index
	if code < 0: return
	get_viewport().set_input_as_handled()
	# UI and gameplay intentionally share buttons; gameplay shortcuts must not.
	if waiting_action.begins_with("game_") or waiting_action == "pause":
		for other in Mapping.CUSTOM_ACTIONS:
			if other == waiting_action or other.begins_with("ui_"): continue
			for assigned in InputMap.action_get_events(other):
				if assigned.is_match(event):
					# Default right arrow is shared with the map outside the hotel.
					if [other, waiting_action].all(func(a): return a in ["game_right", "game_map"]): continue
					rows[waiting_action + ":" + waiting_kind].text = "Déjà utilisé"
					status.text = "Déjà utilisé pour %s. Choisissez une autre touche." % Mapping.CUSTOM_ACTIONS[other]
					return
	if not bindings.has(waiting_action): bindings[waiting_action] = {}
	bindings[waiting_action][waiting_kind] = code
	_cancel()
	changed.emit(bindings.duplicate(true))
	_refresh()
