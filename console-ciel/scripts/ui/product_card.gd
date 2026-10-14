extends PanelContainer
## Compact catalogue card. Prices and ownership come from the services.
const Preview = preload('res://scripts/ui/cosmetic_preview.gd')
const GameCover = preload('res://scripts/ui/game_cover.gd')
const GlassButton = preload('res://scripts/ui/translucent_button.gd')
signal action_requested(id)

func configure(item: Dictionary, owned: bool, equipped: bool, enough: bool) -> void:
	name = 'product_card_' + str(item.id)
	var column = VBoxContainer.new()
	column.add_theme_constant_override('separation', 6 if item.get('type') == 'game' else 10)
	add_child(column)
	var heading = HBoxContainer.new()
	heading.add_theme_constant_override('separation', 8)
	column.add_child(heading)
	var category = _label({'avatar':'AVATAR', 'theme':'THÈME', 'frame':'CADRE', 'game':'JEU'}.get(item.get('type', ''), 'COLLECTION'), 12, true)
	category.autowrap_mode = TextServer.AUTOWRAP_OFF
	category.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(category)
	var status = _label('✓ Équipé' if equipped else ('✓ Possédé' if owned else ('Inclus' if int(item.get('price', 0)) == 0 else '%d pts' % int(item.price))), 13)
	status.name = 'product_status_' + str(item.id)
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	status.size_flags_horizontal = Control.SIZE_SHRINK_END
	heading.add_child(status)
	var preview: Control
	if item.get('type') == 'game':
		preview = GameCover.new()
	else:
		preview = Preview.new()
	column.add_child(preview)
	preview.call('configure', item)
	preview.custom_minimum_size = Vector2(0, 84)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.name = 'product_preview_' + str(item.id)
	var title = _label(str(item.get('name', 'Article')), 22)
	title.name = 'product_name_' + str(item.id)
	column.add_child(title)
	if item.get('type') != 'game' or not item.get('placeholder', false):
		var description = _label(str(item.get('description', '')), 15, true)
		description.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(description)
	if item.get('placeholder', false):
		column.add_child(_label('Test · jeu en préparation', 13, true))
	var price = _label('Gratuit · inclus' if int(item.get('price', 0)) == 0 else '%d points virtuels' % int(item.price), 15)
	price.name = 'product_price_' + str(item.id)
	if item.get('type') != 'game':column.add_child(price)
	else:price.free()
	var action = GlassButton.new()
	action.name = 'product_' + str(item.id)
	if equipped:
		action.text = '✓ Équipé'
		action.theme_type_variation = 'NavigationSelected'
	elif owned:
		action.text = 'Ouvrir' if item.get('type') == 'game' else 'Équiper · possédé'
	elif enough:
		action.text = 'Acheter · %d points' % int(item.price)
		action.theme_type_variation = 'PrimaryButton'
	else:
		action.text = 'Points insuffisants'
	# The caller explains missing points, so this action stays reachable.
	action.pressed.connect(func(): action_requested.emit(str(item.id)))
	column.add_child(action)

func _label(value: String, font_size: int, muted: bool = false) -> Label:
	var label = Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override('font_size', font_size + maxi(0, get_theme_default_font_size() - 18))
	if muted:
		label.modulate.a = 0.76
	return label
