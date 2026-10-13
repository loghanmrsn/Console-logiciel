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
