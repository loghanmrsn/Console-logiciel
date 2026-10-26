extends VBoxContainer
## Le même clavier AZERTY que les défis de code, avec chiffres et symboles.
signal close_requested
signal mission_completed(result: Dictionary)
signal navigation_changed
const Catalog = preload("res://scripts/game/ctf_catalog.gd")
const Keyboard = preload("res://scripts/ui/virtual_keyboard.gd")
var mission_id := ""
var editor: LineEdit
var code_keyboard: VBoxContainer
var feedback: Label
var _busy := false

func _ready() -> void:
	name = "ctf_challenge_panel"
	add_theme_constant_override("separation", 7)
	var entry: Dictionary = Catalog.CHALLENGES[mission_id]
	_text(str(entry.title), 25)
	_text("SUDO HACK · " + str(entry.skill) + " · 50 points", 14)
	_text(str(entry.evidence), 17)
	if CtfService.mission_state(mission_id) == "completed":
		_text("Épreuve validée · " + str(entry.explanation), 18)
		var close := Button.new()
		close.name = "ctf_done_close"
		close.text = "Revenir aux postes"
		close.pressed.connect(func(): close_requested.emit())
		add_child(close)
		return
	_text(str(entry.prompt), 18)
	feedback = _text("Utilisez le clavier physique ou le clavier à l'écran.", 16)
	feedback.name = "ctf_feedback"
	editor = LineEdit.new()
	editor.name = "ctf_answer"
	editor.max_length = 128
	editor.virtual_keyboard_enabled = false
	editor.custom_minimum_size.y = 42
	add_child(editor)
	editor.text_submitted.connect(func(_value: String): _submit())
	code_keyboard = Keyboard.new()
	code_keyboard.name = "ctf_keyboard"
	code_keyboard.navigate_to_editor = true
	add_child(code_keyboard)
	code_keyboard.configure(editor, 128)
	code_keyboard.submitted.connect(_submit)
	code_keyboard.cancelled.connect(func(): close_requested.emit())
	code_keyboard.layout_changed.connect(func(): navigation_changed.emit())
	editor.gui_input.connect(func(event: InputEvent):
		if event.is_action_pressed("ui_down") or (event is InputEventJoypadButton and event.is_action_pressed("ui_accept")):
			code_keyboard.focus_first_key()
			editor.accept_event())
	editor.focus_entered.connect(func(): editor.edit.call_deferred())

func _submit() -> void:
	if _busy or editor.text.strip_edges().is_empty(): return
	_busy = true
	var result: Dictionary = CtfService.submit(mission_id, editor.text)
	if result.ok:
		mission_completed.emit(result)
	else:
		_busy = false
		feedback.text = str(result.error)
		navigation_changed.emit()

func _text(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size + (2 if SettingsService.current.get("large_text", false) else 0))
	add_child(label)
	return label
