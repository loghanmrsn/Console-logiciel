extends VBoxContainer
## Browse, try, purchase and equip using the same atomic profile transactions.
signal navigation_changed
const Catalog=preload("res://scripts/services/character_catalog.gd")
const View=preload("res://scripts/character/character_view.gd")
const Card=preload("res://scripts/ui/wardrobe_card.gd")
const ButtonType=preload("res://scripts/ui/translucent_button.gd")
const SLOTS=["top","trousers","headwear","shoes","hair","socks","accessory"]
const TITLES=["Hauts","Pantalons","Couvre-chefs","Chaussures","Coiffures","Chaussettes","Accessoires"]
var host: Control
var category:=0
var inventory:=0
var selected: Dictionary={}
var draft: Dictionary
var search: LineEdit
var grid: GridContainer
var layout: GridContainer
var catalogue_scroll: ScrollContainer
var preview: Control
var preview_panel: PanelContainer
var preview_columns: GridContainer
var title: Label
var description: Label
var ownership: Label
var feedback: Label
var price: Label
var wallet: Label
var colors: HFlowContainer
var buy: Button
var equip: Button
var result_count: Label
func _ready() -> void:
	name="wardrobe_shop"
	add_theme_constant_override("separation",12)
	var filters=GridContainer.new();filters.columns=3;filters.add_theme_constant_override("h_separation",10);add_child(filters)
	var categories=OptionButton.new();categories.name="wardrobe_category";categories.custom_minimum_size=Vector2(160,42);categories.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for text_ in TITLES:categories.add_item(text_)
	categories.item_selected.connect(func(index):category=index;_rebuild());filters.add_child(categories)
	var owned=OptionButton.new();owned.name="wardrobe_filter";owned.custom_minimum_size=Vector2(155,42);owned.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for text_ in ["Tous les articles","Gratuits","Mon dressing"]:owned.add_item(text_)
	owned.item_selected.connect(func(index):inventory=index;_rebuild());filters.add_child(owned)
	search=LineEdit.new();search.name="wardrobe_search";search.placeholder_text="Rechercher";search.custom_minimum_size=Vector2(150,42);search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;search.text_changed.connect(func(_value):_rebuild());filters.add_child(search)
	layout=GridContainer.new();layout.columns=2;layout.add_theme_constant_override("h_separation",18);add_child(layout)
	var browser=VBoxContainer.new();browser.size_flags_horizontal=Control.SIZE_EXPAND_FILL;layout.add_child(browser)
	result_count=Label.new();result_count.name="wardrobe_count";browser.add_child(result_count)
	catalogue_scroll=ScrollContainer.new();catalogue_scroll.follow_focus=true;catalogue_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;browser.add_child(catalogue_scroll)
	grid=GridContainer.new();grid.columns=2;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);catalogue_scroll.add_child(grid)
	preview_panel=PanelContainer.new();preview_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;layout.add_child(preview_panel)
	var column=VBoxContainer.new();column.add_theme_constant_override("separation",6);preview_panel.add_child(column)
	title=_label(column,"",22);title.name="wardrobe_item_name"
	preview_columns=GridContainer.new();preview_columns.columns=2;preview_columns.add_theme_constant_override("h_separation",14);column.add_child(preview_columns)
	var visual=VBoxContainer.new();visual.size_flags_horizontal=Control.SIZE_EXPAND_FILL;preview_columns.add_child(visual)
	var details=VBoxContainer.new();details.custom_minimum_size.x=190;details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;details.add_theme_constant_override("separation",8);preview_columns.add_child(details)
	preview=View.new();preview.name="wardrobe_preview";preview.custom_minimum_size=Vector2(160,230);visual.add_child(preview)
	var rotation=HBoxContainer.new();visual.add_child(rotation)
	_button(rotation,"↶ Tourner",func():preview.turn(-PI/4),"wardrobe_rotate_left")
	_button(rotation,"Tourner ↷",func():preview.turn(PI/4),"wardrobe_rotate_right")
	description=_label(details,"",14);description.name="wardrobe_material"
	colors=HFlowContainer.new();colors.add_theme_constant_override("h_separation",5);colors.add_theme_constant_override("v_separation",5);details.add_child(colors)
	var pricing=VBoxContainer.new();details.add_child(pricing)
	price=_label(pricing,"",21);price.name="wardrobe_price";price.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	ownership=_label(pricing,"",14);ownership.name="wardrobe_ownership"
	wallet=_label(details,"",13);wallet.name="wardrobe_wallet";wallet.hide()
	buy=_button(details,"Acheter",_purchase,"wardrobe_buy")
	equip=_button(details,"Porter cet article",_equip,"wardrobe_equip")
	feedback=_label(details,"",14);feedback.name="wardrobe_feedback"
	get_viewport().size_changed.connect(_fit)
	_rebuild();_fit()
func _label(parent: Node,text_: String,font_size: int) -> Label:
	var label=Label.new();label.text=text_;label.add_theme_font_size_override("font_size",font_size);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(label);return label
func _button(parent: Node,text_: String,callback: Callable,id: String) -> Button:
	var button=ButtonType.new();button.text=text_;button.name=id;button.custom_minimum_size.y=42;button.pressed.connect(callback);parent.add_child(button);return button
func _fit() -> void:
	var compact=get_viewport_rect().size.x<950
	grid.columns=2 if compact else 3
	catalogue_scroll.custom_minimum_size=Vector2(320 if compact else 500,260 if compact else 360)
	preview_columns.columns=1 if compact else 2
	preview.custom_minimum_size.y=150 if get_viewport_rect().size.y<600 else 230
	navigation_changed.emit()
func _rebuild() -> void:
	for child in grid.get_children():grid.remove_child(child);child.queue_free()
	var items=[];var record_=CharacterService.current()
	for item in Catalog.ITEMS:
		if item.id=="none" or item.slot!=SLOTS[category]:continue
		if item.slot=="hair" and record_.appearance.model=="rabbit":continue
		if inventory==1 and item.price!=0:continue
		if inventory==2 and not Catalog.owned(record_,item):continue
		if not search.text.strip_edges().is_empty() and not item.name.to_lower().contains(search.text.strip_edges().to_lower()):continue
		items.append(item)
	var found=false
	for item in items:
		if not selected.is_empty() and item.id==selected.id and item.slot==selected.slot:found=true
	if not found:selected={} if items.is_empty() else items[0]
	for item in items:
		var card=Card.new();grid.add_child(card)
		var a=record_.appearance
		card.configure(item,Catalog.owned(record_,item),a[item.slot]==item.id,not selected.is_empty() and selected.id==item.id)
		card.pressed.connect(func():_select(item))
	result_count.text="%d article(s) · %s"%[items.size(),TITLES[category]] if not items.is_empty() else "Aucun article ne correspond aux filtres."
	if SLOTS[category]=="hair" and record_.appearance.model=="rabbit":result_count.text="Les coiffures sont proposées aux personnages humains. Le lapin personnalise son pelage dans Mon personnage 3D."
	preview_panel.visible=not selected.is_empty()
	if not selected.is_empty():_select(selected,false)
	navigation_changed.emit()
func _select(item: Dictionary,update_cards:=true) -> void:
	var field=item.slot+"_color"
	var remembered=draft.get(field,"") if not update_cards and draft.get(item.slot,"")==item.id else ""
	selected=item.duplicate()
	draft=CharacterService.current().appearance
	draft[item.slot]=item.id
	var available=Catalog.allowed_colors(item.slot,item.id)
	if remembered in available:draft[field]=remembered
	if draft[field] not in available:draft[field]=available[0]
	if update_cards:
		for card in grid.get_children():card.button_pressed=card.item.id==item.id;card.theme_type_variation="NavigationSelected" if card.button_pressed else ""
	preview.configure(draft)
	preview.focus_face(item.slot=="hair" or item.slot=="headwear")
	if item.slot=="top":
		preview.camera.size=1.65 if item.id=="madison" else 1.0;preview.camera.position=Vector3(0,1.0 if item.id=="madison" else 1.24,4);preview.camera.look_at(Vector3(0,.85 if item.id=="madison" else 1.18,0));preview.refresh()
	elif item.slot in ["shoes","socks","trousers"]:
		var framing={"shoes":[.12,.42],"socks":[.18,.55],"trousers":[.56,1.08]}[item.slot]
		preview.camera.size=framing[1];preview.camera.position=Vector3(0,framing[0]+.15,4);preview.camera.look_at(Vector3(0,framing[0],0));preview.refresh()
	if draft.model!="classic" or item.slot=="accessory":
		preview.focus_face(item.slot in ["hair","headwear"] or item.id=="glasses")
		preview.heading=PI-.35 if item.id=="backpack" else .25
		preview.refresh()
	title.text=item.name
	description.text=_material(item)+" · coloris inclus" if item.price>0 else _material(item)+" · disponible sans points"
	for child in colors.get_children():colors.remove_child(child);child.queue_free()
	for color in available:
		var swatch=ButtonType.new();swatch.name="wardrobe_color_"+color;swatch.text="●";swatch.tooltip_text=Catalog.COLOR_NAMES.get(color,color.capitalize());swatch.custom_minimum_size=Vector2(32,32);swatch.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		var c=Color(str(Catalog.HAIR_COLORS[color] if item.slot=="hair" else Catalog.COLORS[color]))
		var outline=Color.WHITE if c.get_luminance()<.25 else Color("273c48")
		for state_ in ["normal","hover","pressed","focus"]:
			var box=StyleBoxFlat.new();box.bg_color=c;box.set_corner_radius_all(7);box.set_border_width_all(3 if state_!="normal" else 1);box.border_color=outline
			for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:box.set_content_margin(side,2)
			swatch.add_theme_stylebox_override(state_,box)
		swatch.add_theme_color_override("font_color",outline);swatch.add_theme_color_override("font_hover_color",outline);swatch.add_theme_color_override("font_focus_color",outline);swatch.add_theme_font_size_override("font_size",14)
		swatch.toggle_mode=true;swatch.button_pressed=draft[field]==color
		swatch.text="✓" if swatch.button_pressed else ""
		swatch.pressed.connect(func():
			draft[field]=color;preview.configure(draft)
			for button in colors.get_children():button.button_pressed=String(button.name)=="wardrobe_color_"+color;button.text="✓" if button.button_pressed else ""
			_update_state())
		colors.add_child(swatch)
	feedback.text="";feedback.visible=false
	_update_state();navigation_changed.emit()
func _update_state() -> void:
	var record_=CharacterService.current();var owned=Catalog.owned(record_,selected)
	wallet.text="Solde : %d points · uniquement gagnés en jeu"%AppState.profile.wallet.points
	var wearing=record_.appearance[selected.slot]==selected.id and record_.appearance[selected.slot+"_color"]==draft[selected.slot+"_color"]
	ownership.text="✓ Équipé" if wearing else ("✓ Dans votre dressing" if owned else "À débloquer avec les missions")
	price.text="Gratuit" if selected.price==0 else "%d points"%selected.price
	buy.visible=not owned
	buy.text="Acheter · %d points"%selected.price if int(AppState.profile.wallet.points)>=int(selected.price) else "Points insuffisants · %d points"%selected.price
	equip.visible=owned;equip.disabled=wearing
	equip.text="✓ Déjà équipé" if wearing else "Porter cet article"
func _purchase() -> void:
	if int(AppState.profile.wallet.points)<int(selected.price):
		host._confirm("Points insuffisants","Cet article coûte %d points. Votre solde est de %d points. Les missions permettent de gagner des points, sans argent réel."%[selected.price,AppState.profile.wallet.points],"Compris",func():pass)
		return
	var entry=selected.duplicate()
	host._confirm("Acheter « %s » ?"%entry.name,"Prix : %d points de mission. Solde après achat : %d points. Tous les coloris de cet article sont inclus."%[entry.price,AppState.profile.wallet.points-entry.price],"Acheter",func():
		var result=CharacterService.purchase(entry.slot,entry.id)
		if result.ok:
			_rebuild();feedback.text="Achat enregistré. Choisissez Porter cet article pour l’équiper."
			equip.grab_focus.call_deferred()
		else:feedback.text=result.error
		feedback.visible=true)
func _equip() -> void:
	var result=CharacterService.apply(draft)
	if result.ok:
		_rebuild();feedback.text="Apparence enregistrée : l’article est maintenant porté en jeu."
		var card=grid.get_node_or_null("wardrobe_card_"+selected.slot+"_"+selected.id)
		if card!=null:card.grab_focus.call_deferred()
	else:feedback.text=result.error
	feedback.visible=true
static func _material(item: Dictionary) -> String:
	if item.slot=="accessory":return {"scarf":"Maille douce","backpack":"Toile et poche extérieure","glasses":"Monture ronde"}.get(item.id,"Accessoire")
	if item.slot=="hair":return "Mèches et reflets doux"
	if item.id=="madison":return "Maille ajustée · collants intégrés"
	if item.id=="tights":return "Maille fine"
	if item.slot=="top":return "Maille texturée" if item.id in ["sweater","cardigan"] else "Coton tissé"
	if item.slot=="trousers":return "Denim texturé" if item.id=="baggy" else "Coton souple"
	if item.slot=="socks":return "Maille côtelée"
	if item.slot=="headwear":return {"cap_denim":"Denim et coutures","cap_flat":"Tissu et coutures","straw":"Paille tressée","fedora":"Feutre mat"}.get(item.id,"Tissu")
	return {"canvas":"Toile tissée","court":"Cuir grainé","boots":"Finition veloutée","loafers":"Cuir souple","runner":"Maille sportive","high":"Cuir grainé"}.get(item.id,"Tissu")
