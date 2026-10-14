extends CenterContainer
## The four persistent destinations share one floating glass capsule.
## A selected destination has a soft fill; keyboard focus has its own outline.
signal destination_requested(destination: String)

const GlassButton = preload('res://scripts/ui/translucent_button.gd')
const AvatarIcon = preload('res://scripts/ui/avatar_icon.gd')
const DESTINATIONS = [['home', 'Accueil'], ['shop', 'Boutique'], ['settings', 'Paramètres'], ['profiles', 'Profil']]
const MAX_WIDTH = 900.0

var buttons: Array[Button] = []
var destination_labels: Array[Label] = []
var panel: PanelContainer
var profile_name_label: Label
var profile_points_label: Label
var profile_avatar: Control
var selected = 'home'

var _icons: Array[TextureRect] = []
var _contents: Array[Control] = []
var _profile_content: VBoxContainer
var _profile: Dictionary = {}
var _avatar_spec: Dictionary = {}
var _frame_spec: Dictionary = {}
var _settings: Dictionary = {}
var _palette: Dictionary = {}
var _active_profile = true
var _available_width = MAX_WIDTH
var _large = false
var _compact = false

func _ready() -> void:
	name = 'bottom_navigation'
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel = PanelContainer.new()
	panel.name = 'glass_capsule'
	panel.theme_type_variation = 'NavigationPanel'
	add_child(panel)
	var row = HBoxContainer.new()
	row.add_theme_constant_override('separation', 4)
	panel.add_child(row)
	for destination in DESTINATIONS:
		var key: String = destination[0]
		var button = GlassButton.new()
		button.name = 'home_' + key
		button.tooltip_text = destination[1]
		button.theme_type_variation = 'NavigationButton'
		button.size_flags_stretch_ratio = 1.0
		row.add_child(button)
		buttons.append(button)
		if key == 'profiles':
			_build_profile(button)
		else:
			_build_destination(button, key, destination[1])
		button.pressed.connect(func(): destination_requested.emit(key))
	update_player(_profile, _avatar_spec, _frame_spec)
	apply_appearance(_settings, _palette)
	update_state(selected, _active_profile)
	fit(_available_width, _large, _compact)

func _build_destination(button: Button, destination: String, title: String) -> void:
	var column = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override('separation', 1)
	button.add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 8
	column.offset_right = -8
	column.offset_top = 5
	column.offset_bottom = -5
	_contents.append(column)
	var icon = TextureRect.new()
	icon.texture = load('res://assets/art/icons/' + destination + '.svg')
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(32, 32)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(icon)
	_icons.append(icon)
	var label = _clipped_label(title)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)
	destination_labels.append(label)

func _build_profile(button: Button) -> void:
	_profile_content = VBoxContainer.new()
	_profile_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_profile_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_profile_content.add_theme_constant_override('separation', 1)
	button.add_child(_profile_content)
	_profile_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_profile_content.offset_left = 8
	_profile_content.offset_right = -8
	_profile_content.offset_top = 5
	_profile_content.offset_bottom = -5
	_contents.append(_profile_content)
	profile_avatar = AvatarIcon.new()
	profile_avatar.custom_minimum_size = Vector2(32, 32)
	profile_avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_profile_content.add_child(profile_avatar)
	var destination = _clipped_label('Profil')
	destination.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_profile_content.add_child(destination)
	destination_labels.append(destination)
	# Keep these data labels for callers; the visible identity belongs to the header.
	profile_name_label = _clipped_label('Votre profil')
	profile_name_label.name = 'navigation_profile_name'
	profile_name_label.hide()
	_profile_content.add_child(profile_name_label)
	profile_points_label = _clipped_label('0 pts')
	profile_points_label.name = 'navigation_profile_points'
	profile_points_label.hide()
	_profile_content.add_child(profile_points_label)

func _clipped_label(value: String) -> Label:
	var label = Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label

func update_player(profile: Dictionary, avatar_spec: Dictionary, frame_spec: Dictionary) -> void:
	_profile = profile.duplicate(true)
	_avatar_spec = avatar_spec.duplicate(true)
	_frame_spec = frame_spec.duplicate(true)
	if profile_name_label == null:
		return
	var active = not profile.is_empty()
	var display_name: String = str(profile.get('display_name', 'Votre profil')) if active else 'Votre profil'
	profile_name_label.text = display_name
	profile_name_label.tooltip_text = display_name
	profile_points_label.text = '%d pts' % int(profile.get('wallet', {}).get('points', 0)) if active else 'Choisir'
	profile_points_label.tooltip_text = '%d points disponibles' % int(profile.get('wallet', {}).get('points', 0)) if active else 'Choisir ou créer un profil'
	buttons[3].tooltip_text = 'Profil · %s · %s' % [display_name, profile_points_label.text] if active else 'Choisir ou créer un profil'
	profile_avatar.color = Color(avatar_spec.get('color', '#527FA3'))
	profile_avatar.variant = int(avatar_spec.get('variant', {'H': 0, 'O': 2, 'F': 1, 'R': 2}.get(avatar_spec.get('symbol', 'H'), 0)))
	profile_avatar.frame = profile.get('equipped', {}).get('frame', 'frame_default')
	profile_avatar.frame_spec = frame_spec.duplicate(true)
	profile_avatar.set_local_image(str(profile.get('avatar_image', '')))
	profile_avatar.queue_redraw()

func apply_appearance(settings: Dictionary, palette: Dictionary) -> void:
	_settings = settings.duplicate(true)
	_palette = palette.duplicate(true)
	if panel == null:
		return
	# Native translucent surfaces stay compatible with the Compatibility renderer.
	# There are no movement tweens, including when reduced motion is requested.
	# Labels inherit the current theme, including during a settings preview.
	# Imported SVGs keep their original dark strokes unless their alpha mask is
	# recolored; multiplying those pixels by a light modulate would stay dark.
	var foreground := Color(palette.get('foreground', get_theme_color('font_color', 'Label')))
	for icon in _icons:
		_recolor_icon(icon, foreground)
	fit(_available_width, bool(settings.get('large_text', _large)), _compact)

func _recolor_icon(icon: TextureRect, foreground: Color) -> void:
	if icon.texture == null:
		return
	var image := icon.texture.get_image()
	if image == null or image.is_empty():
		return
	if image.is_compressed() and image.decompress() != OK:
		return
	image.convert(Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var alpha := image.get_pixel(x, y).a
			image.set_pixel(x, y, Color(foreground.r, foreground.g, foreground.b, alpha))
	icon.texture = ImageTexture.create_from_image(image)

func update_state(destination: String, active_profile: bool) -> void:
	selected = 'settings' if destination in ['help', 'controls'] else destination
	_active_profile = active_profile
	for index in range(buttons.size()):
		var button = buttons[index]
		button.theme_type_variation = 'NavigationSelected' if DESTINATIONS[index][0] == selected else 'NavigationButton'
		button.disabled = not active_profile and DESTINATIONS[index][0] in ['home', 'shop', 'settings']
		_contents[index].modulate.a = 0.5 if button.disabled else 1.0

func fit(available_width: float, large: bool, compact: bool) -> void:
	_available_width = available_width
	_large = large
	_compact = compact
	if panel == null:
		return
	var capsule_width = minf(MAX_WIDTH, maxf(0.0, available_width))
	panel.custom_minimum_size = Vector2(capsule_width, 0)
	var height = 78 if large else (66 if compact else 72)
	for index in range(buttons.size()):
		buttons[index].custom_minimum_size = Vector2(0, height)
		var label: Label = destination_labels[index]
		label.add_theme_font_size_override('font_size', (20 if compact else 22) if large else 16)
	for icon in _icons:
		icon.custom_minimum_size = Vector2(36,36) if large else (Vector2(28,28) if compact else Vector2(32,32))
	profile_avatar.custom_minimum_size = Vector2(36,36) if large else (Vector2(28,28) if compact else Vector2(32,32))
