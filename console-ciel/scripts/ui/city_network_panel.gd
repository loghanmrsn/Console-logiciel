extends VBoxContainer
signal close_requested
signal mission_completed(result: Dictionary)
signal navigation_changed
const Catalog = preload("res://scripts/game/city_network_catalog.gd")
const Keyboard = preload("res://scripts/ui/virtual_keyboard.gd")
var mission_id := ""
var editors: Dictionary = {}
var keyboard: VBoxContainer
var feedback: Label
var _busy := false
func _ready() -> void:
	name = "city_network_panel"
	add_theme_constant_override("separation",8)
	var entry: Dictionary = Catalog.CHALLENGES[mission_id]
	_text(entry.title,25)
	_text("CITY CIEL · réseau pédagogique · 50 points à la première réussite",14)
	_text(entry.evidence,17)
	var lesson := Button.new()
	lesson.name = "city_lesson_toggle"
	lesson.text = "Consulter le cours et les exemples"
	add_child(lesson)
	var course := _text(Catalog.LESSON,16)
	course.name = "city_inline_lesson"
	course.hide()
	lesson.pressed.connect(func(): course.visible = not course.visible; navigation_changed.emit())
	if CityService.mission_state(mission_id) == "completed":
		_text("✓ Configuration déjà validée. " + entry.explanation,18)
		_close_button()
		return
	for spec in entry.fields:
		_text(spec[1],17)
		var key: String = spec[0]
		var editor := LineEdit.new()
		editor.name = "city_answer_" + key
		editor.max_length = 96
		editor.virtual_keyboard_enabled = false
		editor.custom_minimum_size.y = 44
		editors[key] = editor
		add_child(editor)
		editor.focus_entered.connect(func():
			if keyboard != null: keyboard.editor = editor
			editor.edit.call_deferred())
		editor.text_submitted.connect(func(_value): _submit())
		editor.gui_input.connect(func(event: InputEvent):
			if event.is_action_pressed("ui_down") or (event is InputEventJoypadButton and event.is_action_pressed("ui_accept")):
				keyboard.editor = editor
				keyboard.focus_first_key()
				editor.accept_event())
	feedback = _text("Complétez les trois champs. Le clavier à l’écran saisit dans le dernier champ sélectionné.",16)
	feedback.name = "city_feedback"
	keyboard = Keyboard.new()
	keyboard.name = "city_keyboard"
	keyboard.navigate_to_editor = true
	add_child(keyboard)
	keyboard.configure(editors[entry.fields[0][0]],96)
	keyboard.submitted.connect(_submit)
	keyboard.cancelled.connect(func(): close_requested.emit())
	keyboard.layout_changed.connect(func(): navigation_changed.emit())
	var submit := Button.new()
	submit.name = "city_validate"
	submit.text = "Appliquer la configuration"
	submit.custom_minimum_size.y = 44
	submit.pressed.connect(_submit)
	add_child(submit)
	_close_button()
func _close_button() -> void:
	var close := Button.new()
	close.name = "city_close"
	close.text = "Revenir dans la salle"
	close.pressed.connect(func(): close_requested.emit())
	add_child(close)
func _submit() -> void:
	if _busy: return
	_busy = true
	var answers := {}
	for key in editors: answers[key] = editors[key].text
	var result := CityService.submit(mission_id, answers)
	if result.ok: mission_completed.emit(result)
	else:
		_busy = false
		feedback.text = result.error
		navigation_changed.emit()
func _text(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size",font_size+(2 if SettingsService.current.get("large_text",false) else 0))
	add_child(label)
	return label
