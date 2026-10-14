extends PanelContainer
const Avatar = preload('res://scripts/ui/avatar_icon.gd')
const GlassButton = preload('res://scripts/ui/translucent_button.gd')
signal selected(id)
signal edited(id)

func configure(profile: Dictionary, item: Dictionary, recent: bool) -> void:
	name = 'profile_card_' + str(profile.id)
	var column = VBoxContainer.new()
	column.add_theme_constant_override('separation', 14)
	add_child(column)
	var heading = HBoxContainer.new()
	heading.add_theme_constant_override('separation', 8)
	column.add_child(heading)
	var kicker = _label('PROFIL JOUEUR', 12, true)
	kicker.autowrap_mode = TextServer.AUTOWRAP_OFF
	kicker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(kicker)
	var active = not AppState.profile.is_empty() and AppState.profile.get('id', '') == profile.id
	if recent or active:
		var badge = _label('● En cours' if active else 'Récent', 12)
		badge.name = 'profile_recent_' + str(profile.id)
		badge.autowrap_mode = TextServer.AUTOWRAP_OFF
		badge.size_flags_horizontal = Control.SIZE_SHRINK_END
		heading.add_child(badge)
	var identity = HBoxContainer.new()
	identity.add_theme_constant_override('separation', 14)
	column.add_child(identity)
	var icon = Avatar.new()
	icon.name = 'profile_avatar_' + str(profile.id)
	icon.custom_minimum_size = Vector2(76, 76)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.color = Color(item.get('color', '#527FA3'))
	icon.variant = int(item.get('variant', {'H':0, 'O':2, 'F':1, 'R':2}.get(item.get('symbol', 'H'), 0)))
	icon.frame = profile.equipped.frame
	icon.frame_spec = ShopService.item(profile.equipped.frame)
	icon.set_local_image(str(profile.get('avatar_image', '')))
	identity.add_child(icon)
	var text_column = VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	text_column.add_theme_constant_override('separation', 4)
	identity.add_child(text_column)
	var label = _label(str(profile.display_name), 24)
	label.name = 'profile_name_' + str(profile.id)
	text_column.add_child(label)
	text_column.add_child(_label('Photo personnelle' if icon.image_texture != null else 'Avatar CIEL', 14, true))
	column.add_child(HSeparator.new())
	var statistics = HBoxContainer.new()
	statistics.add_theme_constant_override('separation', 10)
	column.add_child(statistics)
	_add_statistic(statistics, str(profile.wallet.points), 'points', 'profile_points_' + str(profile.id))
	_add_statistic(statistics, '%d / %d' % [profile.progress.completed_missions.size(), RewardService.missions.size()], 'objectifs', 'profile_progress_' + str(profile.id))
	var games = 0
	for owned_id in profile.get('owned_items', []):
		if ShopService.item(str(owned_id)).get('type', '') == 'game':
			games += 1
	_add_statistic(statistics, str(games), 'jeux acquis', 'profile_games_' + str(profile.id))
	var use = GlassButton.new()
	use.name = 'select_' + str(profile.id)
	use.text = 'Continuer avec ce profil' if active else 'Jouer avec ce profil'
	use.theme_type_variation = 'PrimaryButton'
	use.pressed.connect(func(): selected.emit(str(profile.id)))
	column.add_child(use)
	var edit = GlassButton.new()
	edit.text = 'Personnaliser'
	edit.name = 'edit_' + str(profile.id)
	edit.pressed.connect(func(): edited.emit(str(profile.id)))
	column.add_child(edit)

func _add_statistic(parent: HBoxContainer, value: String, caption: String, identifier: String) -> void:
	var column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override('separation', 2)
	parent.add_child(column)
	var label = _label(value, 23)
	label.name = identifier
	column.add_child(label)
	column.add_child(_label(caption, 13, true))

func _label(value: String, font_size: int, muted: bool = false) -> Label:
	var label = Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override('font_size', font_size + maxi(0, get_theme_default_font_size() - 18))
	if muted:
		label.modulate.a = 0.76
	return label
