extends Button

func _init() -> void:
	custom_minimum_size = Vector2(0, 48)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func _ready() -> void:
	var audio_service=get_node_or_null('/root/SettingsService')
	pressed.connect(func():
		if is_instance_valid(audio_service): audio_service.play_effect())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

func _draw() -> void:
	if disabled or size.x < 40 or size.y < 24:
		return
	# A narrow reflected edge gives the native controls a tactile face without
	# motion, shaders or an extra child that could intercept keyboard focus.
	if theme_type_variation == 'NavigationSelected':
		var marker := get_theme_color('focus', 'Appearance')
		draw_style_box(_marker(marker), Rect2(Vector2(size.x * .5 - 10, size.y - 4), Vector2(20, 2)))
	elif theme_type_variation != 'NavigationButton' and not is_pressed():
		var box := get_theme_stylebox('hover' if is_hovered() else 'normal')
		if box is StyleBoxFlat:
			var reflection := Color.WHITE
			reflection.a = .10 if box.bg_color.get_luminance() < .5 else .48
			draw_line(Vector2(15, 2), Vector2(size.x - 15, 2), reflection, 1, true)

func _marker(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(1)
	return box
