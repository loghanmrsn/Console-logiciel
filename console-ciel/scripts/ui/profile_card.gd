extends PanelContainer
const Avatar = preload('res://scripts/ui/avatar_icon.gd')
const GlassButton = preload('res://scripts/ui/translucent_button.gd')
signal selected(id)
signal edited(id)
func configure(profile: Dictionary, item: Dictionary, recent: bool) -> void:
	var column = VBoxContainer.new()
	add_child(column)
	var row = HBoxContainer.new()
	column.add_child(row)
	var icon = Avatar.new()
	icon.color = Color(item.get('color', '#527FA3'))
	icon.variant = int(item.get('variant', {'H':0,'O':2,'F':1,'R':2}.get(item.get('symbol','H'),0)))
	icon.frame = profile.equipped.frame
	icon.frame_spec = ShopService.item(profile.equipped.frame)
	row.add_child(icon)
	var text_column = VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_column)
	var label = Label.new()
	label.text = profile.display_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override('font_size',24)
	text_column.add_child(label)
	var detail = Label.new()
	detail.text = '%s points · %s/3 objectifs' % [profile.wallet.points,profile.progress.completed_missions.size()]
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_color_override('font_color', Color('#586674'))
	text_column.add_child(detail)
	var use = GlassButton.new()
	use.name = 'select_' + profile.id
	use.text = 'Jouer avec ce profil' + (' · récent' if recent else '')
	use.pressed.connect(func(): selected.emit(profile.id))
	column.add_child(use)
	var edit = GlassButton.new()
	edit.text = 'Modifier le profil'
	edit.name = 'edit_' + profile.id
	edit.pressed.connect(func(): edited.emit(profile.id))
	column.add_child(edit)
