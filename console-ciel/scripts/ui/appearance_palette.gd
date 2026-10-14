extends RefCounted
## Local appearance preferences never buy or equip profile cosmetics.
## resolve() returns opaque #RRGGBB strings for callers and native themes.

static func presets() -> Array[Dictionary]:
	return [
		{"id": "profile", "name": "Thème du profil", "background": "#F3F5F7", "accent": "#527FA3", "secondary": "#E6EDF2"},
		{"id": "brume", "name": "Brume", "background": "#F3F5F7", "accent": "#527FA3", "secondary": "#E6EDF2"},
		{"id": "sable", "name": "Sable", "background": "#F7F4EE", "accent": "#92764B", "secondary": "#EDE5D8"},
		{"id": "sauge", "name": "Sauge", "background": "#F2F6F2", "accent": "#607F6C", "secondary": "#E3ECE5"},
		{"id": "nuit", "name": "Nuit", "background": "#101826", "accent": "#8CB9E8", "secondary": "#1D2B40"},
		{"id": "aurore", "name": "Aurore", "background": "#241C36", "accent": "#D5A5D9", "secondary": "#3A2C4E"}
	]

static func resolve(settings: Dictionary, profile_palette: Dictionary = {}) -> Dictionary:
	var selected: Dictionary = presets()[0]
	for entry in presets():
		if entry.id == settings.get("appearance_style", "profile"):
			selected = entry
			break
	if selected.id == "profile":
		selected = selected.duplicate(true)
		for key in ["background", "accent", "secondary"]:
			if profile_palette.has(key):
				selected[key] = profile_palette[key]
	var background: Color = _color(selected.background, Color("#F3F5F7"))
	var accent: Color = _color(selected.accent, Color("#527FA3"))
	var custom_background: Variant = settings.get("background_color", "")
	if custom_background is String and not custom_background.is_empty():
		background = _color(custom_background, background)
	var foreground := readable_text(background)
	var dark := luminance(foreground) > 0.5
	var panel := background.lightened(0.08) if dark else background.lerp(Color.WHITE, 0.74)
	if contrast_ratio(foreground, panel) < 4.6:
		panel = background.darkened(0.05)
	var secondary: Color = _color(selected.secondary, panel)
	if not str(custom_background).is_empty() or contrast_ratio(foreground, secondary) < 4.6:
		secondary = panel.lerp(background, 0.34)
	var button := panel
	var custom_button: Variant = settings.get("button_color", "")
	if custom_button is String and not custom_button.is_empty():
		button = _color(custom_button, panel)
		accent = button
	var muted := foreground.lerp(panel, 0.24)
	var amount := 0.24
	while amount > 0.0 and minf(contrast_ratio(muted, background), contrast_ratio(muted, panel)) < 4.6:
		amount = maxf(0.0, amount - 0.03)
		muted = foreground.lerp(panel, amount)
	return {"background": _hex(background), "accent": _hex(accent), "secondary": _hex(secondary), "foreground": _hex(foreground), "muted": _hex(muted), "panel": _hex(panel), "button": _hex(button), "button_text": _hex(readable_text(button))}

static func _color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return Color(value.r, value.g, value.b, 1.0)
	if value is String and Color.html_is_valid(value) and value.length() == 7 and value.begins_with("#"):
		return Color(value)
	return fallback

static func _hex(value: Color) -> String:
	return "#" + value.to_html(false).to_upper()

static func luminance(value: Color) -> float:
	var channels := Vector3(_linear(value.r), _linear(value.g), _linear(value.b))
	return channels.dot(Vector3(0.2126, 0.7152, 0.0722))

static func _linear(channel: float) -> float:
	return channel / 12.92 if channel <= 0.04045 else pow((channel + 0.055) / 1.055, 2.4)

static func contrast_ratio(first: Color, second: Color) -> float:
	var a := luminance(first)
	var b := luminance(second)
	return (maxf(a, b) + 0.05) / (minf(a, b) + 0.05)

static func readable_text(surface: Color) -> Color:
	var dark := Color("#25313C")
	var light := Color("#F5F8FF")
	var selected := dark if contrast_ratio(dark, surface) >= contrast_ratio(light, surface) else light
	if contrast_ratio(selected, surface) < 4.6:
		selected = Color.BLACK if contrast_ratio(Color.BLACK, surface) >= contrast_ratio(Color.WHITE, surface) else Color.WHITE
	return selected
