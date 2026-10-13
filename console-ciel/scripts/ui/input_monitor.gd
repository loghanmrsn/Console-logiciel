extends VBoxContainer
## Raw hardware readings only. This panel does not assume the custom HID mapping.
signal controller_status_changed(message: String)

var _devices: Label
var _buttons: Label
var _axes: Label
var _rest: Label
var _last_event: Label
var _history: Array[String] = []
var _controllers: Node
var _elapsed := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 220)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 10)
	_devices = _label("")
	_buttons = _label("Boutons pressés : aucune manette connectée.")
	_axes = _label("Axes bruts : aucune manette connectée.")
	_rest = _label("")
	_last_event = _label("Appuyez sur une commande. Les indices bruts permettent de mesurer le futur contrôleur USB HID ; ils ne constituent pas encore sa correspondance définitive.")
	_controllers = get_node_or_null("/root/ControllerService")
	if _controllers != null:
		_controllers.controller_connection_changed.connect(_connection_changed)
		_controllers.active_controller_changed.connect(_active_changed)
	_refresh_devices()
	_refresh_hardware()

func _label(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(label)
	return label

func _exit_tree() -> void:
	if _controllers != null:
		if _controllers.controller_connection_changed.is_connected(_connection_changed):
			_controllers.controller_connection_changed.disconnect(_connection_changed)
		if _controllers.active_controller_changed.is_connected(_active_changed):
			_controllers.active_controller_changed.disconnect(_active_changed)

func _refresh_devices() -> void:
	var lines: Array[String] = []
	for device in Input.get_connected_joypads():
		var active: bool = _controllers != null and device == _controllers.active_device
		lines.append("#%d · %s%s\nGUID %s" % [device, Input.get_joy_name(device), " · ACTIVE" if active else " · diagnostic seulement", Input.get_joy_guid(device)])
	_set_text(_devices, "Manette : aucune connectée. Le clavier reste disponible." if lines.is_empty() else "Périphériques réels détectés :\n" + "\n".join(lines))

func _active_changed(_device: int) -> void:
	_refresh_devices()

func _connection_changed(device: int, connected: bool, _was_active: bool) -> void:
	_refresh_devices()
	controller_status_changed.emit("Manette #%d %s. Le clavier reste disponible." % [device, "connectée" if connected else "déconnectée"])

func _input(event: InputEvent) -> void:
	if not is_instance_valid(_last_event):
		return
	if event is InputEventJoypadButton:
		_record("#%d · bouton %d · %s · pression %.2f" % [event.device, event.button_index, "appuyé" if event.pressed else "relâché", event.pressure])
	elif event is InputEventJoypadMotion:
		_set_text(_last_event, "Dernier événement brut : #%d · axe %d · %.3f" % [event.device, event.axis, event.axis_value])
	elif event is InputEventKey and event.pressed and not event.echo:
		_record("Clavier : " + event.as_text())

func _record(value: String) -> void:
	_history.push_front(value)
	if _history.size() > 3:
		_history.resize(3)
	_set_text(_last_event, "Événements reçus :\n" + "\n".join(_history))

func _process(delta: float) -> void:
	# Diagnostics only need 10 samples/s; no allocation/text reshaping every frame.
	_elapsed += delta
	if _elapsed < 0.1:
		return
	_elapsed = 0.0
	_refresh_hardware()

func _refresh_hardware() -> void:
	if not is_instance_valid(_axes):
		return
	var axes_lines: Array[String] = []
	var button_lines: Array[String] = []
	var rest_lines: Array[String] = []
	var deadzone := InputMap.action_get_deadzone("game_left") if InputMap.has_action("game_left") else 0.25
	var horizontal := _mapped_axis("game_right", JOY_AXIS_LEFT_X)
	var vertical := _mapped_axis("game_down", JOY_AXIS_LEFT_Y)
	for device in Input.get_connected_joypads():
		var received: Array[String] = []
		for axis in range(JOY_AXIS_MAX):
			received.append("%d: %.3f" % [axis, Input.get_joy_axis(device, axis)])
		axes_lines.append("#%d · %s" % [device, "  ".join(received)])
		var pressed: Array[String] = []
		for button in range(JOY_BUTTON_MAX):
			if Input.is_joy_button_pressed(device, button):
				pressed.append(str(button))
		button_lines.append("#%d · %s" % [device, "aucun" if pressed.is_empty() else ", ".join(pressed)])
		var position := Vector2(Input.get_joy_axis(device, horizontal), Input.get_joy_axis(device, vertical))
		rest_lines.append("#%d · axes %d/%d · %s · amplitude %.3f" % [device, horizontal, vertical, "AU REPOS (dans la zone morte)" if position.length() <= deadzone else "HORS ZONE MORTE", position.length()])
	_set_text(_axes, "Axes bruts : aucune manette connectée." if axes_lines.is_empty() else "Axes bruts (non filtrés) :\n" + "\n".join(axes_lines))
	_set_text(_buttons, "Boutons pressés : aucune manette connectée." if button_lines.is_empty() else "Boutons actuellement pressés :\n" + "\n".join(button_lines))
	_set_text(_rest, "Zone morte : %.2f · %s" % [deadzone, "repos non mesurable sans manette" if rest_lines.is_empty() else "\n" + "\n".join(rest_lines)])

func _mapped_axis(action: String, fallback: int) -> int:
	if InputMap.has_action(action):
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadMotion:
				return event.axis
	return fallback

func _set_text(label: Label, value: String) -> void:
	if label.text != value:
		label.text = value
