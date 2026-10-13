extends PanelContainer
const Preview = preload('res://scripts/ui/cosmetic_preview.gd')
const GlassButton = preload('res://scripts/ui/translucent_button.gd')
signal action_requested(id)
func configure(item: Dictionary, owned: bool, equipped: bool, enough: bool) -> void:
	var col = VBoxContainer.new()
	add_child(col)
	var preview=Preview.new()
	col.add_child(preview)
	preview.configure(item)
	var texts=VBoxContainer.new()
	texts.add_theme_constant_override('separation',4)
	col.add_child(texts)
	var type_label = Label.new()
	type_label.text = {'avatar':'AVATAR','theme':'THÈME','frame':'CADRE'}.get(item.type,'OBJET')
	type_label.add_theme_font_size_override('font_size',maxi(14,get_theme_default_font_size()-4))
	type_label.add_theme_color_override('font_color',Color('#586674'))
	texts.add_child(type_label)
	var label = Label.new()
	label.text = item.name
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override('font_size',get_theme_default_font_size()+4)
	texts.add_child(label)
	var desc = Label.new()
	desc.text=item.description
	desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical=Control.SIZE_EXPAND_FILL
	desc.add_theme_color_override('font_color',Color('#586674'))
	col.add_child(desc)
	var price=Label.new()
	price.text='Gratuit · inclus' if item.price==0 else 'Prix : %d points' % item.price
	price.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	col.add_child(price)
	var action = GlassButton.new()
	action.name='product_'+item.id
	if equipped:
		action.text='✓ Équipé'
		action.theme_type_variation='NavigationSelected'
	elif owned:
		action.text='Équiper · possédé'
	elif enough:
		action.text='Acheter · %d points' % item.price
	else:
		action.text='Points insuffisants'
	action.pressed.connect(func(): action_requested.emit(item.id))
	col.add_child(action)
