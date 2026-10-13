extends SceneTree
## Named input device filtering, using explicit virtual devices (no hardware claim).
const Mapping := preload("res://scripts/input_setup.gd")
var checks := 0
var failures: Array[String] = []
var controllers: Node

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		push_error(label)

func _axis(device: int, axis: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)

func _button(device: int, button: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)

func _run() -> void:
	await process_frame
	controllers = root.get_node_or_null("ControllerService")
	_check(controllers != null, "Service contrôleur chargé")
	if controllers == null:
		_finish()
		return
	_check(Mapping.configure().ok, "Correspondance manette locale valide")
	controllers.debug_set_devices([])
	_check(controllers.active_device == -1, "Aucune manette active sans périphérique déclaré")
	_axis(0, JOY_AXIS_LEFT_X, 0.9)
	await process_frame
	_check(not Input.is_action_pressed("game_right"), "Axe d'un périphérique inconnu ignoré")
	_axis(0, JOY_AXIS_LEFT_X, 0.0)
	await process_frame
	controllers.debug_set_devices([1, 0])
	_check(controllers.active_device == 0, "Identifiant le plus bas choisi initialement")
	_axis(1, JOY_AXIS_LEFT_X, 0.9)
	await process_frame
	_check(not Input.is_action_pressed("game_right"), "Axe d'une manette secondaire ignoré")
	_axis(1, JOY_AXIS_LEFT_X, 0.0)
	await process_frame
	_button(1, JOY_BUTTON_A, true)
	await process_frame
	_check(not Input.is_action_pressed("ui_accept"), "Validation d'une manette secondaire ignorée")
	_button(1, JOY_BUTTON_A, false)
	_axis(0, JOY_AXIS_LEFT_X, 0.9)
	await process_frame
	_check(Input.is_action_pressed("game_right"), "Axe de la manette active reconnu")
	controllers.debug_connection_changed(2, true)
	_check(controllers.active_device == 0 and Input.is_action_pressed("game_right"), "Connexion secondaire ne perturbe pas l'appui actif")
	var observed: Array = []
	controllers.controller_connection_changed.connect(func(device: int, connected: bool, was_active: bool): observed.append([device, connected, was_active]))
	controllers.debug_connection_changed(0, false)
	_check(controllers.active_device == 1, "Retrait sélectionne la manette restante la plus basse")
	_check(not Input.is_action_pressed("game_right"), "Retrait libère l'action de déplacement")
	_check(observed.back() == [0, false, true], "Signal de retrait identifie la manette active")
	_axis(0, JOY_AXIS_LEFT_X, 0.0)
	controllers.debug_connection_changed(0, true)
	_check(controllers.active_device == 1, "Reconnexion ne vole pas le contrôle")
	controllers.debug_connection_changed(1, false)
	_check(controllers.active_device == 0, "Retrait suivant choisit le plus petit identifiant restant")
	controllers.debug_set_devices([])
	var key := InputEventKey.new()
	key.keycode = KEY_RIGHT
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	_check(Input.is_action_pressed("game_right"), "Clavier utilisable après retrait de toutes les manettes")
	key.pressed = false
	Input.parse_input_event(key)
	var diagnostic := InputEventKey.new()
	diagnostic.keycode = KEY_F3
	diagnostic.pressed = true
	_check(diagnostic.is_action_pressed("debug_diagnostics"), "Diagnostic F3 défini par l'Input Map centrale")
	var valid: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Mapping.MAPPING_PATH))
	var invalid := valid.duplicate(true)
	invalid.actions.game_right.axis = -1
	_check(not Mapping.validate_mapping(invalid).ok, "Indice d'axe négatif rejeté")
	invalid = valid.duplicate(true)
	invalid.actions.game_right.direction = 0
	_check(not Mapping.validate_mapping(invalid).ok, "Direction neutre rejetée")
	invalid = valid.duplicate(true)
	invalid.actions.ui_accept.button = 0.5
	_check(not Mapping.validate_mapping(invalid).ok, "Indice de bouton fractionnaire rejeté")
	invalid = valid.duplicate(true)
	invalid.actions["unrecognized"] = {"button": 0}
	_check(not Mapping.validate_mapping(invalid).ok, "Action inconnue rejetée")
	invalid = valid.duplicate(true)
	invalid.actions.erase("ui_accept")
	_check(not Mapping.validate_mapping(invalid).ok, "Validation manette manquante rejetée")
	invalid = valid.duplicate(true)
	invalid.schema_version = 99
	_check(not Mapping.validate_mapping(invalid).ok, "Schéma de correspondance inconnu rejeté")
	controllers.debug_clear_devices()
	await process_frame
	_finish()

func _finish() -> void:
	print("CONTROLLERS : %d assertions, %d échec(s). Périphériques virtuels de test ; matériel non testé." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
