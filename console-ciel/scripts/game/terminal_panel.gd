extends VBoxContainer
## Un terminal fictif : textes reconnus uniquement par InvestigationService.
signal close_requested
signal mission_completed(result: Dictionary)
signal navigation_changed
const Keyboard = preload("res://scripts/ui/virtual_keyboard.gd")
var code_keyboard: VBoxContainer
var editor: LineEdit
var prompt: Label
var output: Label
var submit: Button
var phase := "user"
var login_name := ""
var pending_command := ""
var _busy := false
var replay := false

func _ready() -> void:
	name = "maze_terminal_panel"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",5)
	var title := _text("Serveur CIEL · terminal Linux",22)
	title.name = "terminal_title"
	output = _text("Connexion au serveur simulé.",16)
	output.name = "terminal_output"
	output.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	prompt = _text("Identifiant :",18)
	editor = LineEdit.new()
	editor.name = "terminal_entry"
	editor.max_length = 64
	editor.virtual_keyboard_enabled = false
	editor.custom_minimum_size.y = 40
	editor.focus_entered.connect(func(): _edit.call_deferred())
	editor.text_submitted.connect(func(_value: String): _submit())
	add_child(editor)
	code_keyboard = Keyboard.new()
	code_keyboard.name = "terminal_keyboard"
	code_keyboard.navigate_to_editor = true
	add_child(code_keyboard)
	code_keyboard.configure(editor,64)
	code_keyboard.submitted.connect(_submit)
	code_keyboard.cancelled.connect(func(): close_requested.emit())
	code_keyboard.layout_changed.connect(func(): navigation_changed.emit())
	submit = code_keyboard.get_node("actions/key_Valider")
	submit.name = "terminal_validate"
	submit.theme_type_variation = "PrimaryButton"
	code_keyboard.get_node("actions/key_Annuler").name = "terminal_close"
	editor.text_changed.connect(func(_value: String): submit.disabled = editor.text.is_empty() or _busy)
	editor.gui_input.connect(func(event: InputEvent):
		if event.is_action_pressed("ui_down") or (event is InputEventJoypadButton and event.is_action_pressed("ui_accept")):
			code_keyboard.focus_first_key()
			editor.accept_event())
	if InvestigationService.mission_state("maze") == "completed" and not replay:
		output.text = "root@ciel:~#  uid=0(root) · droits complets enregistrés."
		prompt.text = "Cette mission est terminée."
		editor.hide()
		code_keyboard.hide()
		var close := Button.new()
		close.name = "terminal_done_close"
		close.text = "Retour au labyrinthe"
		close.pressed.connect(func(): close_requested.emit())
		add_child(close)
	else:
		_set_phase("command" if InvestigationService.terminal_connected() and not replay else "user")

func _set_phase(value: String) -> void:
	phase = value
	editor.secret = phase in ["password","elevation"]
	prompt.text = {"user":"Identifiant :", "password":"Mot de passe :", "command":"admin@ciel:~$", "elevation":"Authentification des privilèges · mot de passe :"}.get(phase, "Saisie :")
	editor.text = ""
	submit.disabled = true
	editor.placeholder_text = ""
	editor.grab_focus()
	_edit.call_deferred()
	navigation_changed.emit()

func _edit() -> void:
	if is_instance_valid(editor) and editor.has_focus() and editor.editable: editor.edit()

func _submit() -> void:
	if _busy or editor.text.is_empty(): return
	_busy = true
	var value := editor.text
	match phase:
		"user":
			login_name = value
			output.text = "Serveur CIEL · authentification"
			_set_phase("password")
		"password":
			var result: Dictionary = InvestigationService.terminal_login(login_name,value)
			if result.ok:
				output.text = "Session ouverte · Linux · compte admin."
				login_name = ""
				_set_phase("command")
			else:
				output.text = str(result.error)
				_set_phase("password")
		"command":
			var result: Dictionary = InvestigationService.terminal_command(value)
			if not result.ok:
				output.text = str(result.error)
				_set_phase("command")
			elif result.data.get("needs_password",false):
				pending_command = str(result.data.command)
				output.text = "Demande d’authentification reçue."
				_set_phase("elevation")
			else:
				output.text = str(result.data.get("output",""))
				_set_phase("command")
		"elevation":
			var result: Dictionary = InvestigationService.terminal_command(pending_command,value)
			if result.ok:
				editor.text = ""
				pending_command = ""
				_busy = false
				mission_completed.emit(result)
				return
			output.text = str(result.error)
			_set_phase("elevation")
	_busy = false
	submit.disabled = editor.text.is_empty()

func _text(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size + (2 if SettingsService.current.get("large_text",false) else 0))
	add_child(label)
	return label
