extends VBoxContainer
## Preview is a real 3D rig; a draft never equips an unowned item.
signal close_requested
signal walk_requested
signal navigation_changed
const Catalog=preload("res://scripts/services/character_catalog.gd")
const View=preload("res://scripts/character/character_view.gd")
const ButtonType=preload("res://scripts/ui/translucent_button.gd")
const PAGES=["Visage","Coiffure","Hauts","Pantalons","Couvre-chefs","Chaussettes","Chaussures"]
var draft: Dictionary
var saved: Dictionary
var page:=0
var view: Control
var grid: GridContainer
var controls: VBoxContainer
var options_scroll: ScrollContainer
var status: Label
var balance: Label
var buy: Button
var apply: Button
var dirty:=false
func _ready() -> void:
	name="character_configurator"
	saved=CharacterService.current().appearance
	draft=saved.duplicate(true)
	add_theme_constant_override("separation",12)
	var title=Label.new();title.text="Mon personnage 3D";title.add_theme_font_size_override("font_size",28);add_child(title)
	grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",24);add_child(grid)
	var left=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(left)
	var stage=PanelContainer.new();left.add_child(stage)
	view=View.new();view.name="character_preview";view.custom_minimum_size=Vector2(240,300);stage.add_child(view)
	var rotate=HBoxContainer.new();left.add_child(rotate)
	_button(rotate,"↶ Tourner",func():view.turn(-PI/4),"character_rotate_left")
	_button(rotate,"Visage / corps",func():view.focus_face(not view.close_up),"character_zoom")
	_button(rotate,"Tourner ↷",func():view.turn(PI/4),"character_rotate_right")
	_button(rotate,"Marche",func():
		view.focus_face(false)
		view.set_motion(not view.walking and not SettingsService.current.reduce_motion,Vector2(sin(view.heading),cos(view.heading))),"character_animate")
	var body=Label.new();body.text="1,70 m · gabarit standard fixe";body.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;body.add_theme_font_size_override("font_size",14);left.add_child(body)
	var right=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.custom_minimum_size.x=290;grid.add_child(right)
	var tabs=OptionButton.new();tabs.name="character_category";tabs.custom_minimum_size.y=44
	for title_ in PAGES:tabs.add_item(title_)
	tabs.item_selected.connect(func(i):page=i;_page())
	right.add_child(tabs)
	balance=Label.new();balance.name="character_balance";right.add_child(balance)
	options_scroll=ScrollContainer.new();options_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;options_scroll.follow_focus=true;right.add_child(options_scroll)
	controls=VBoxContainer.new();controls.size_flags_horizontal=Control.SIZE_EXPAND_FILL;controls.add_theme_constant_override("separation",9);options_scroll.add_child(controls)
	status=Label.new();status.name="character_status";status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;right.add_child(status)
	buy=_button(right,"Acheter",_purchase,"character_buy")
	apply=_button(left,"Enregistrer l’apparence",_save,"character_save")
	_button(left,"Annuler les modifications",_reset,"character_reset")
	_button(right,"Marcher en 3D",func():walk_requested.emit(),"character_walk")
	_button(left,"Retour",func():close_requested.emit(),"character_back")
	var hint=Label.new();hint.text="Les achats utilisent uniquement les points gagnés en jeu. Aucun argent réel.";hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.add_theme_font_size_override("font_size",13);right.add_child(hint)
	get_viewport().size_changed.connect(_fit)
	_page();_fit()
func _fit() -> void:
	view.custom_minimum_size=Vector2(200,160) if get_viewport_rect().size.y<600 else Vector2(260,280)
	options_scroll.custom_minimum_size.y=150 if get_viewport_rect().size.y<600 else 245
func _button(host: Node,text_: String,action: Callable,id: String) -> Button:
	var b=ButtonType.new();b.text=text_;b.name=id;b.custom_minimum_size.y=42;b.pressed.connect(action);host.add_child(b);return b
func _choice(label_: String,field: String,values: Array,names: Dictionary={}) -> void:
	var label=Label.new();label.text=label_;controls.add_child(label)
	var options=OptionButton.new();options.name="character_"+field;options.custom_minimum_size.y=40;options.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for id in values:
		options.add_item(str(names.get(id,id)).capitalize());options.set_item_metadata(options.item_count-1,id)
	options.selected=maxi(0,values.find(draft[field]))
	options.item_selected.connect(func(index):draft[field]=options.get_item_metadata(index);_changed())
	controls.add_child(options)
func _slot() -> String: return ["","hair","top","trousers","headwear","socks","shoes"][page]
func _page() -> void:
	view.focus_face(page==0)
	var focus=get_viewport().gui_get_focus_owner()
	var focus_id=str(focus.name) if focus!=null and controls.is_ancestor_of(focus) else ""
	for child in controls.get_children():controls.remove_child(child);child.queue_free()
	if page==0:
		_choice("Démarche","gait",Catalog.GAITS,{"loose":"Souple et bancale","natural":"Naturelle"})
		_choice("Teint","skin",Catalog.SKIN.keys(),{"porcelain":"Porcelaine","light":"Clair","warm":"Doré","tan":"Mat","brown":"Brun","deep":"Profond"})
		_choice("Forme des yeux","eyes",Catalog.EYES,{"almond":"Amande","round":"Arrondis","soft":"Doux"})
		_choice("Couleur des yeux","eye_color",Catalog.EYE_COLORS.keys(),{"brown":"Marron","hazel":"Noisette","green":"Vert","blue":"Bleu","grey":"Gris"})
		_choice("Sourire","smile",Catalog.SMILES,{"soft":"Léger","wide":"Souriant","neutral":"Neutre"})
		_choice("Couleur des lèvres","lips",Catalog.LIPS.keys(),{"natural":"Naturel","rose":"Rose","peach":"Pêche","berry":"Prune","brown":"Brun"})
	else:
		var slot=_slot();var ids=[];var names_={}
		for entry in Catalog.ITEMS:
			if entry.slot==slot:
				ids.append(entry.id)
				names_[entry.id]=entry.name+(" · gratuit" if entry.price==0 else (" · acquis" if Catalog.owned(CharacterService.current(),entry) else " · %d pts"%entry.price))
		_choice(PAGES[page],slot,ids,names_)
		var chooser=controls.get_node("character_"+slot)
		chooser.item_selected.disconnect(chooser.item_selected.get_connections()[0].callable)
		chooser.item_selected.connect(func(index):
			draft[slot]=chooser.get_item_metadata(index)
			var field=slot+"_color"
			var colors=Catalog.allowed_colors(slot,draft[slot])
			if draft[field] not in colors: draft[field]=colors[0]
			_page())
		var field=slot+"_color"
		_choice("Couleur",field,Catalog.allowed_colors(slot,draft[slot]),Catalog.COLOR_NAMES if slot!="hair" else {"black":"Noir","brown":"Brun","chestnut":"Châtain","blonde":"Blond","copper":"Cuivré","silver":"Argenté","white":"Blanc"})
	_changed()
	navigation_changed.emit()
	if not focus_id.is_empty() and controls.has_node(focus_id): controls.get_node(focus_id).grab_focus.call_deferred()
func _missing() -> Array:
	var result=[];var record_=CharacterService.current()
	for slot in Catalog.CATEGORIES:
		var entry=Catalog.item(draft[slot],slot)
		if not Catalog.owned(record_,entry):result.append(entry)
	return result
func _changed() -> void:
	view.configure(draft)
	dirty=draft!=saved
	balance.text="%d points disponibles"%AppState.profile.wallet.points
	var missing=_missing()
	apply.disabled=not missing.is_empty() or not dirty
	buy.visible=not missing.is_empty()
	buy.disabled=not missing.is_empty() and int(AppState.profile.wallet.points)<int(missing[0].price)
	if missing.is_empty():status.text="Aperçu · modifications à enregistrer" if dirty else "Apparence enregistrée"
	else:
		buy.text="Acheter %s · %d pts"%[missing[0].name,missing[0].price]
		status.text="Essayage · %d article(s) à acquérir avant d’enregistrer"%missing.size()
func _purchase() -> void:
	var missing=_missing()
	if missing.is_empty():return
	var entry=missing[0]
	var result=CharacterService.purchase(entry.slot,entry.id)
	if result.ok:_page();status.text="Achat enregistré. Vous pouvez équiper l’article."
	else:status.text=result.error
func _save() -> void:
	var result=CharacterService.apply(draft)
	if result.ok:saved=draft.duplicate(true);_changed()
	else:status.text=result.error
func _reset() -> void:
	draft=saved.duplicate(true)
	_page()
