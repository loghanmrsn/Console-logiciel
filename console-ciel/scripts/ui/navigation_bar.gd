extends CenterContainer
## Five persistent destinations. Selected fill and focus outline are independent.
signal destination_requested(destination: String)
const GlassButton=preload('res://scripts/ui/translucent_button.gd')
const DESTINATIONS=[['home','Accueil'],['shop','Boutique'],['profiles','Profils'],['settings','Paramètres'],['help','Aide']]
var buttons: Array[Button]=[]
var panel: PanelContainer
var selected='home'

func _ready() -> void:
	name='bottom_navigation'
	panel=PanelContainer.new()
	panel.theme_type_variation='NavigationPanel'
	add_child(panel)
	var row=HBoxContainer.new()
	row.add_theme_constant_override('separation',6)
	panel.add_child(row)
	for destination in DESTINATIONS:
		var button=GlassButton.new()
		button.name='home_'+destination[0]
		button.tooltip_text=destination[1]
		button.custom_minimum_size=Vector2(100,64)
		button.theme_type_variation='NavigationButton'
		row.add_child(button)
		var column=VBoxContainer.new()
		column.mouse_filter=Control.MOUSE_FILTER_IGNORE
		column.add_theme_constant_override('separation',0)
		column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		column.offset_top=5;column.offset_bottom=-5
		button.add_child(column)
		var icon=TextureRect.new()
		icon.texture=load('res://assets/art/icons/'+destination[0]+'.svg')
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size=Vector2(24,26)
		icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		column.add_child(icon)
		var label=Label.new()
		label.text=destination[1]
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
		button.pressed.connect(func(): destination_requested.emit(destination[0]))
		buttons.append(button)
	update_state(selected,true)

func update_state(destination: String,active_profile: bool) -> void:
	selected=destination
	for index in range(buttons.size()):
		var button=buttons[index]
		button.theme_type_variation='NavigationSelected' if DESTINATIONS[index][0]==destination else 'NavigationButton'
		button.disabled=not active_profile and DESTINATIONS[index][0] in ['home','shop','settings']
		button.get_child(0).modulate.a=.6 if button.disabled else 1.0

func fit(available_width: float,large: bool,compact: bool) -> void:
	if panel==null: return
	panel.custom_minimum_size.x=minf(880,available_width)
	for button in buttons:
		button.custom_minimum_size.y=68 if large else (60 if compact else 68)
		var label: Label=button.get_child(0).get_child(1)
		label.add_theme_font_size_override('font_size',18 if large else 16)
