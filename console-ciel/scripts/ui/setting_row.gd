extends VBoxContainer
var heading: HBoxContainer
func configure(title: String, editor: Control, help: String = '') -> void:
	add_theme_constant_override('separation',6)
	heading=HBoxContainer.new()
	add_child(heading)
	var label = Label.new()
	label.text=title
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.add_child(label)
	add_child(editor)
	if not help.is_empty():
		var detail=Label.new()
		detail.text=help
		detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_color_override('font_color',Color('#586674'))
		detail.add_theme_font_size_override('font_size',maxi(16,get_theme_default_font_size()-2))
		add_child(detail)
