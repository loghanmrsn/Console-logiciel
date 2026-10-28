extends VBoxContainer
signal close_requested
signal navigation_changed
signal command_applied(result: Dictionary)
const Keyboard = preload("res://scripts/ui/virtual_keyboard.gd")
var editor: LineEdit
var code_keyboard: VBoxContainer
var output: Label
var _history: Array[String] = []
var _profile_id := ""
var _busy := false

func _ready() -> void:
	name = "dev_console_panel"
	_profile_id = str(AppState.profile.get("id", ""))
	add_theme_constant_override("separation", 7)
	_text("Terminal Dev", 25)
	_text("Commandes locales · help pour la liste · Échap pour fermer", 15)
	output = _text("", 16)
	output.name = "dev_console_output"
	_append("Dev · terminal prêt. Exemple : add coins 500")
	editor = LineEdit.new()
	editor.name = "dev_console_entry"
	editor.max_length = 256
	editor.virtual_keyboard_enabled = false
	editor.custom_minimum_size.y = 42
	editor.placeholder_text = "Commande…"
	add_child(editor)
	editor.text_submitted.connect(func(_value: String): _submit())
	code_keyboard = Keyboard.new()
	code_keyboard.name = "dev_console_keyboard"
	code_keyboard.navigate_to_editor = true
	add_child(code_keyboard)
	code_keyboard.configure(editor, 256)
	code_keyboard.submitted.connect(_submit)
	code_keyboard.cancelled.connect(func(): close_requested.emit())
	code_keyboard.layout_changed.connect(func(): navigation_changed.emit())
	editor.focus_entered.connect(func(): editor.edit.call_deferred())
	editor.gui_input.connect(func(event: InputEvent):
		if event.is_action_pressed("ui_down") or (event is InputEventJoypadButton and event.is_action_pressed("ui_accept")):
			code_keyboard.focus_first_key()
			editor.accept_event())

func _submit() -> void:
	if _busy or editor.text.strip_edges().is_empty(): return
	_busy = true
	var command := editor.text
	# A retained panel must never target a different profile after selection.
	var result: Dictionary = DevConsoleService.execute(command) if _profile_id == str(AppState.profile.get("id", "")) else {"ok": false, "error": "Le profil a changé. Fermez et rouvrez le terminal."}
	if result.get("clear", false): _history.clear()
	else: _append("> " + command)
	_append(str(result.get("message", "")) if result.ok else "Erreur · " + str(result.error))
	if result.ok:
		editor.clear()
		command_applied.emit(result)
	_busy = false
	navigation_changed.emit()

func _append(line: String) -> void:
	_history.append(line)
	while _history.size() > 6: _history.pop_front()
	output.text = "\n".join(_history)

func _text(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size + (2 if SettingsService.current.get("large_text", false) else 0))
	add_child(label)
	return label
