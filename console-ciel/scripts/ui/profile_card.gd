extends PanelContainer
const Avatar = preload('res://scripts/ui/avatar_icon.gd')
const GlassButton = preload('res://scripts/ui/translucent_button.gd')
signal selected(id)
signal edited(id)

func configure(profile: Dictionary, item: Dictionary, recent: bool) -> void:
	name = 'profile_card_' + profile.id
	var column = VBoxContainer.new()
	column.add_theme_constant_override('separation', 16)
	add_child(column)
	var heading = HBoxContainer.new()
	heading.add_theme_constant_override('separation', 8)
	column.add_child(heading)
	var kicker = _label('VOTRE ESPACE', 13, true)
	kicker.autowrap_mode = TextServer.AUTOWRAP_OFF
	kicker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kicker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.add_child(kicker)
	if recent:
		var badge = _label('● Récent', 13, true)
		badge.name = 'profile_recent_' + profile.id
		badge.autowrap_mode = TextServer.AUTOWRAP_OFF
		badge.size_flags_horizontal = Control.SIZE_SHRINK_END
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		heading.add_child(badge)

	var row = HBoxContainer.new()
	row.add_theme_constant_override('separation', 12)
	column.add_child(row)
	var icon = Avatar.new()
	icon.name = 'profile_avatar_' + profile.id
	icon.custom_minimum_size = Vector2(88, 88)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.color = Color(item.get('color', '#527FA3'))
	icon.variant = int(item.get('variant', {'H':0,'O':2,'F':1,'R':2}.get(item.get('symbol','H'),0)))
	icon.frame = profile.equipped.frame
	icon.frame_spec = ShopService.item(profile.equipped.frame)
	icon.set_local_image(str(profile.get('avatar_image', '')))
	row.add_child(icon)
	var text_column = VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	text_column.add_theme_constant_override('separation', 4)
	row.add_child(text_column)
	var label = _label(profile.display_name, 24)
	label.name = 'profile_name_' + profile.id
	text_column.add_child(label)
	var has_photo = icon.image_texture != null
	var detail = _label('Photo personnelle' if has_photo else 'Avatar CIEL', 15, true)
	text_column.add_child(detail)

	var statistics = HBoxContainer.new()
	statistics.add_theme_constant_override('separation', 16)
	column.add_child(statistics)
	_add_statistic(statistics, str(profile.wallet.points), 'points disponibles')
	_add_statistic(statistics, '%s / 3' % profile.progress.completed_missions.size(), 'objectifs réalisés')

	var use = GlassButton.new()
	use.name = 'select_' + profile.id
	use.text = 'Jouer avec ce profil'
	use.theme_type_variation = 'PrimaryButton'
	use.pressed.connect(func(): selected.emit(profile.id))
	column.add_child(use)
	var edit = GlassButton.new()
	edit.text = 'Modifier le profil'
	edit.name = 'edit_' + profile.id
	edit.pressed.connect(func(): edited.emit(profile.id))
	column.add_child(edit)

func _add_statistic(parent: HBoxContainer, value: String, caption: String) -> void:
	var column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override('separation', 1)
	parent.add_child(column)
	column.add_child(_label(value, 24))
	column.add_child(_label(caption, 14, true))

func _label(value: String, font_size: int, muted: bool = false) -> Label:
	var label = Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override('font_size', font_size)
	if muted:
		label.add_theme_color_override('font_color', Color('#586674'))
	return label
