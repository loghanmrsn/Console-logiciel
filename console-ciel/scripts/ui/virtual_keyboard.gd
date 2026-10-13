extends VBoxContainer
const GlassButton = preload('res://scripts/ui/translucent_button.gd')
signal submitted
signal cancelled
var editor: LineEdit
func configure(line_edit: LineEdit) -> void:
	editor=line_edit
	var grid=GridContainer.new()
	grid.columns=10
	grid.add_theme_constant_override('h_separation',4)
	grid.add_theme_constant_override('v_separation',4)
	add_child(grid)
	for character in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789':
		var b=GlassButton.new()
		b.text=character
		b.custom_minimum_size=Vector2(0,42)
		b.name='key_'+character
		grid.add_child(b)
		b.pressed.connect(func(): _insert(character))
	var row=HBoxContainer.new()
	row.add_theme_constant_override('separation',6)
	add_child(row)
	for entry in ['Espace','Effacer','Valider','Annuler']:
		var b=GlassButton.new()
		b.text=entry
		b.name='key_'+entry
		row.add_child(b)
		match entry:
			'Espace': b.pressed.connect(func(): _insert(' '))
			'Effacer': b.pressed.connect(_erase)
			'Valider': b.pressed.connect(func(): submitted.emit())
			'Annuler': b.pressed.connect(func(): cancelled.emit())
func _insert(value: String) -> void:
	if editor.has_selection():
		var start=editor.get_selection_from_column()
		editor.delete_text(start,editor.get_selection_to_column())
		editor.deselect()
		editor.caret_column=start
	if editor.text.length()+value.length()<=16:
		editor.insert_text_at_caret(value)
func _erase() -> void:
	if editor.has_selection():
		var start=editor.get_selection_from_column()
		editor.delete_text(start,editor.get_selection_to_column())
		editor.deselect()
		editor.caret_column=start
	elif editor.caret_column>0:
		editor.delete_text(editor.caret_column-1,editor.caret_column)
