extends PanelContainer
const GameCover = preload('res://scripts/ui/game_cover.gd')
const GlassButton = preload('res://scripts/ui/translucent_button.gd')
signal play_requested(id)
signal details_requested(id)

func configure(item: Dictionary, owned: bool, educational: bool = false, compact: bool = false) -> void:
	var identifier = str(item.get('id', 'game_enquete'))
	name = 'game_card_' + identifier
	if compact:
		var panel_style = get_theme_stylebox('panel', 'PanelContainer').duplicate()
		panel_style.content_margin_top = 8
		panel_style.content_margin_bottom = 8
		panel_style.content_margin_left = 10
		panel_style.content_margin_right = 10
		add_theme_stylebox_override('panel', panel_style)
	var column = VBoxContainer.new()
	column.add_theme_constant_override('separation', 4 if compact else 12)
	add_child(column)
	if not compact:
		column.add_child(_label('L’ENQUÊTE ÉDUCATIVE' if educational else ('DANS VOTRE BIBLIOTHÈQUE' if owned else 'À DÉCOUVRIR'), 12, true))
	var cover = GameCover.new()
	cover.name = 'game_cover_' + identifier
	cover.custom_minimum_size = Vector2(0, 54 if compact else 132)
	column.add_child(cover)
	var illustration = item.duplicate(true)
	illustration.educational = educational
	cover.configure(illustration)
	var title = _label(str(item.get('name', 'L’enquête CIEL')), 19 if compact else 25)
	title.name = 'game_name_' + identifier
	column.add_child(title)
	var description = str(item.get('description', 'Trois défis pour explorer, comprendre et progresser.'))
	if not compact and not description.is_empty():
		var subtitle = _label(description, 14 if compact else 16, true)
		subtitle.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(subtitle)
	if compact:
		var status = 'Inclus · 3 défis' if educational else ('Acquis · jeu de test' if owned else '%d pts · jeu de test' % int(item.get('price', 0)))
		column.add_child(_label(status, 12, true))
	else:
		if item.get('placeholder', false) and not educational:
			column.add_child(_label('Test · jeu en préparation', 12, true))
		if not owned and not educational:
			column.add_child(_label('%d points virtuels' % int(item.get('price', 0)), 15))
	var action = GlassButton.new()
	if owned or educational:
		action.name = 'play_' + identifier
		action.text = 'Ouvrir' if compact and not educational else str(item.get('action_label', 'Ouvrir' if item.get('placeholder', false) else 'Jouer'))
		action.theme_type_variation = 'PrimaryButton'
		action.pressed.connect(func(): play_requested.emit(identifier))
	else:
		action.name = 'buy_' + identifier
		action.text = 'Boutique' if compact else 'Voir dans la boutique'
		action.pressed.connect(func(): details_requested.emit(identifier))
	column.add_child(action)
	if compact:
		action.custom_minimum_size.y = 38
		# The normal primary button has generous padding; compact cards use
		# the same colors and focus outline with a smaller vertical inset.
		for state in ['normal', 'hover', 'pressed', 'disabled']:
			var button_style = action.get_theme_stylebox(state).duplicate()
			button_style.content_margin_top = 4
			button_style.content_margin_bottom = 4
			action.add_theme_stylebox_override(state, button_style)

func _label(value: String, font_size: int, muted: bool = false) -> Label:
	var label = Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override('font_size', font_size + maxi(0, get_theme_default_font_size() - 18))
	if muted:
		label.modulate.a = 0.76
	return label
