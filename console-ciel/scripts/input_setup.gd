class_name InputSetup
extends RefCounted

## Keys are the development mapping. Only measured joypad indices belong in
## controller_mapping.json; gameplay code consumes named InputMap actions.
const NO_CONTROLLER_DEVICE := 2147483647
const MAPPING_PATH := "res://data/controller_mapping.json"
const JOY_ACTIONS := ["ui_up", "ui_down", "ui_left", "ui_right", "ui_accept", "ui_cancel", "tab_previous", "tab_next", "game_up", "game_down", "game_left", "game_right", "game_interact", "game_missions", "pause", "game_sprint"]
const CUSTOM_ACTIONS := {
 "game_up": "Marcher vers le haut", "game_down": "Marcher vers le bas",
 "game_left": "Marcher à gauche", "game_right": "Marcher à droite",
 "game_interact": "Interagir", "game_missions": "Missions", "game_map": "Carte",
 "game_sprint": "Sprint (+10 %)", "pause": "Pause",
 "ui_accept": "Valider", "ui_cancel": "Retour",
 "ui_up": "Menu : haut", "ui_down": "Menu : bas",
 "ui_left": "Menu : gauche", "ui_right": "Menu : droite",
 "tab_previous": "Catégorie précédente", "tab_next": "Catégorie suivante"
}
static var _applied_bindings: Dictionary = {}
static var controller_device := NO_CONTROLLER_DEVICE
static var mapping_error := ""
static var _joy_mapping: Dictionary = {}

static func configure(deadzone: float = 0.25) -> Dictionary:
	var loaded := _load_mapping()
	mapping_error = loaded.error
	_joy_mapping = loaded.data if loaded.ok else {}
	var keys := {
		"ui_up": [_key(KEY_UP)], "ui_down": [_key(KEY_DOWN)],
		"ui_left": [_key(KEY_LEFT)], "ui_right": [_key(KEY_RIGHT)],
		"ui_accept": [_key(KEY_ENTER), _key(KEY_KP_ENTER)], "ui_cancel": [_key(KEY_ESCAPE)],
		"tab_previous": [_key(KEY_Q)], "tab_next": [_key(KEY_E)],
		"game_up": [_key(KEY_UP), _key(KEY_Z)], "game_down": [_key(KEY_DOWN), _key(KEY_S)],
		"game_left": [_key(KEY_LEFT), _key(KEY_Q)], "game_right": [_key(KEY_RIGHT), _key(KEY_D)],
		"game_interact": [_key(KEY_SPACE)], "game_missions": [_key(KEY_T)], "pause": [_key(KEY_P)], "game_sprint": [_key(KEY_SHIFT)]
	}
	for action in JOY_ACTIONS:
		var events: Array = keys[action]
		var joy: Dictionary = _joy_mapping.get(action, {})
		if joy.has("button"):
			events.append(_button(int(joy.button)))
		if joy.has("axis"):
			events.append(_axis(int(joy.axis), float(joy.direction)))
		_set_action(action, events, deadzone)
	_set_action("game_map", [_key(KEY_RIGHT)], deadzone)
	_applied_bindings = {}
	_configure_walk_right(deadzone)
	_set_action("ui_focus_next", [_key(KEY_TAB)], deadzone)
	var previous := _key(KEY_TAB)
	previous.shift_pressed = true
	_set_action("ui_focus_prev", [previous], deadzone)
	# Root gates the diagnostic screen with OS.has_feature("debug"). This key
	# remains configured even when the joypad mapping is absent or invalid.
	_set_action("debug_diagnostics", [_key(KEY_F3)], deadzone)
	return loaded

static func bind_controller(device: int) -> void:
	controller_device = device if device >= 0 else NO_CONTROLLER_DEVICE
	# InputMap filtering also protects Input.get_vector() and native Control input.
	# Consuming an event alone would leave Godot's action state already updated.
	for action in JOY_ACTIONS + ["game_walk_right", "game_sprint", "game_map"]:
		if not InputMap.has_action(action):
			continue
		var events := InputMap.action_get_events(action)
		InputMap.action_erase_events(action)
		for event in events:
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				event.device = controller_device
			InputMap.action_add_event(action, event)
		Input.action_release(action)

static func set_deadzone(value: float) -> void:
	for action in ["ui_up", "ui_down", "ui_left", "ui_right", "game_up", "game_down", "game_left", "game_right", "game_walk_right"]:
		if InputMap.has_action(action):
			InputMap.action_set_deadzone(action, clampf(value, 0.1, 0.6))

static func _load_mapping() -> Dictionary:
	if not FileAccess.file_exists(MAPPING_PATH):
		return _mapping_failure("Correspondance manette absente. Le clavier reste disponible.")
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(MAPPING_PATH)) != OK:
		return _mapping_failure("Correspondance manette illisible. Le clavier reste disponible.")
	return validate_mapping(parser.data)

static func validate_mapping(document: Variant) -> Dictionary:
	if not document is Dictionary or not _bounded_integer(document.get("schema_version"), 1, 1) or not document.get("actions") is Dictionary:
		return _mapping_failure("Version ou structure de correspondance manette invalide.")
	for action in JOY_ACTIONS:
		# Previous custom HID files do not define this new shortcut. Preserve
		# their measured mappings and keep T usable without guessing a HID index.
		if action in ["game_missions", "game_sprint"] and not document.actions.has(action):
			continue
		if not document.actions.has(action):
			return _mapping_failure("Commande manette obligatoire absente : " + action)
	var normalized: Dictionary = {}
	for action in document.actions:
		if not action is String or action not in JOY_ACTIONS or not document.actions[action] is Dictionary:
			return _mapping_failure("Action manette inconnue : " + str(action))
		var spec: Dictionary = document.actions[action]
		if spec.is_empty():
			return _mapping_failure("Commande manette vide : " + action)
		for key in spec:
			if key not in ["button", "axis", "direction"]:
				return _mapping_failure("Champ de correspondance inconnu : " + str(key))
		var output: Dictionary = {}
		if spec.has("button"):
			if not _bounded_integer(spec.button, 0, JOY_BUTTON_MAX - 1):
				return _mapping_failure("Indice de bouton invalide : " + action)
			output.button = int(spec.button)
		if spec.has("axis"):
			if not _bounded_integer(spec.axis, 0, JOY_AXIS_MAX - 1) or not _bounded_integer(spec.get("direction"), -1, 1) or int(spec.get("direction", 0)) == 0:
				return _mapping_failure("Axe ou sens invalide : " + action)
			output.axis = int(spec.axis)
			output.direction = float(spec.direction)
		elif spec.has("direction"):
			return _mapping_failure("Un sens nécessite un axe : " + action)
		normalized[action] = output
	if not normalized.has("game_missions"):
		normalized.game_missions = {}
	return {"ok": true, "error": "", "data": normalized}

static func _bounded_integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= minimum and float(value) <= maximum

static func _mapping_failure(message: String) -> Dictionary:
	return {"ok": false, "error": message, "data": {}}

static func _set_action(action: String, events: Array, deadzone: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)
	InputMap.action_erase_events(action)
	InputMap.action_set_deadzone(action, clampf(deadzone, 0.1, 0.6))
	for event in events:
		InputMap.action_add_event(action, event)

static func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	return event

static func _button(index: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = controller_device
	event.button_index = index
	return event

static func _axis(index: int, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = controller_device
	event.axis = index
	event.axis_value = value
	return event

# Derive this alias from the measured right-hand action, rather than adding a
# new mandatory entry to existing custom controller mappings.
static func _configure_walk_right(deadzone: float) -> void:
	var events: Array = []
	for event in InputMap.action_get_events("game_right"):
		if event is InputEventKey and event.keycode == KEY_RIGHT: continue
		events.append(event.duplicate())
	_set_action("game_walk_right", events, deadzone)

## Store only portable key/button identifiers, never serialized InputEvent objects.
static func valid_bindings(bindings: Variant) -> bool:
	if not bindings is Dictionary: return false
	for action in bindings:
		if action not in CUSTOM_ACTIONS or not bindings[action] is Dictionary: return false
		for kind in bindings[action]:
			var code: Variant = bindings[action][kind]
			if kind == "key":
				if not _bounded_integer(code, 1, KEY_UNKNOWN - 1): return false
			elif kind == "button":
				if not _bounded_integer(code, 0, JOY_BUTTON_MAX - 1): return false
			else: return false
	return true

static func apply_bindings(bindings: Dictionary, deadzone: float) -> void:
	if bindings == _applied_bindings: return
	configure(deadzone)
	for action in bindings:
		for kind in bindings[action]:
			for event in InputMap.action_get_events(action):
				if (kind == "key" and event is InputEventKey) or (kind == "button" and event is InputEventJoypadButton):
					InputMap.action_erase_event(action, event)
			var code := int(bindings[action][kind])
			InputMap.action_add_event(action, _key(code) if kind == "key" else _button(code))
	# In hotel zones the map's keyboard shortcut must not also move the player.
	var walk: Array = []
	for event in InputMap.action_get_events("game_right"):
		var conflicts := false
		for map_event in InputMap.action_get_events("game_map"):
			if map_event.is_match(event): conflicts = true
		if not conflicts: walk.append(event.duplicate())
	_set_action("game_walk_right", walk, deadzone)
	_applied_bindings = bindings.duplicate(true)

static func label_for(action: String) -> String:
	var names: Array[String] = []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey: names.append(OS.get_keycode_string(event.keycode))
		elif event is InputEventJoypadButton: names.append("bouton %d" % event.button_index)
	return " / ".join(names)

static func keyboard_label_for(action: String) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey: return OS.get_keycode_string(event.keycode)
	return "—"
