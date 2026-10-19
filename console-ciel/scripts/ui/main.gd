extends Control
const GlassButton=preload('res://scripts/ui/translucent_button.gd')
const ThemeFactory=preload('res://scripts/ui/theme_factory.gd')
const ProfileCard=preload('res://scripts/ui/profile_card.gd')
const ProductCard=preload('res://scripts/ui/product_card.gd')
const Avatar=preload('res://scripts/ui/avatar_icon.gd')
const Keyboard=preload('res://scripts/ui/virtual_keyboard.gd')
const LocalAvatars=preload('res://scripts/services/local_avatar_library.gd')
const Modal=preload('res://scripts/ui/confirmation_dialog.gd')
const Toast=preload('res://scripts/ui/notification.gd')
const SettingRow=preload('res://scripts/ui/setting_row.gd')
const Navigation=preload('res://scripts/ui/navigation_bar.gd')
const EnquiryArt=preload('res://scripts/ui/enquiry_art.gd')
const GameCard=preload('res://scripts/ui/game_card.gd')
const GameLibrary=preload('res://scripts/services/game_library.gd')
const AppearancePalette=preload('res://scripts/ui/appearance_palette.gd')
const InputSetup=preload('res://scripts/input_setup.gd')
const InputMonitor=preload('res://scripts/ui/input_monitor.gd')
const Demo=preload('res://scripts/game/demo_game.gd')
const HotelLayout=preload('res://scripts/game/hotel_layout.gd')
const JoyNavigation=preload('res://scripts/ui/joy_navigation.gd')
const Startup=preload('res://scenes/startup.tscn')
const Diagnostics=preload('res://scripts/ui/diagnostics_panel.gd')

var background: ColorRect
var ambient_glows: Array[TextureRect]=[]
var shell_column: VBoxContainer
var shell: MarginContainer
var navigation: CenterContainer
var hero_grid: GridContainer
var hero_art: Control
var hero_panel: PanelContainer
var home_labels: Dictionary={}
var home_objectives: Control
var home_story: VBoxContainer
var header_brand: Label
var home_split: GridContainer
var home_game_library: GridContainer
var home_carousel: ScrollContainer
var home_cards: Array[Control]=[]
var arcade: Control
var arcade_id=''
var header_player: HBoxContainer
var header_profile: Label
var header_avatar: Control
var header_points: Label
var header_back: Button
var content: VBoxContainer
var scroll: ScrollContainer
var footer: Label
var toast: Control
var screen='boot'
var parent_screen='home'
var controls_origin='home'
var modal: Control
var responsive_grids: Array=[]
var draft_settings: Dictionary={}
var settings_category=0
var settings_origin='home'
var editor_id=''
var editor_avatar='avatar_default'
var editor_image=''
var editor_record: Dictionary={}
var editor_preview: Control
var editor_preview_name: Label
var editor_name_count: Label
var editor_image_status: Label
var editor_gallery: GridContainer
var editor_keyboard: Control
var editor_image_tab=false
var editor_avatar_buttons: Array[Button]=[]
var name_edit: LineEdit
var shop_filter=0
var shop_inventory=false
var demo: Control
var latest_input=''
var last_profile_id=''
var startup_settings_error=''
var axes_label: Label
var focus_scroll_serial=0
var navigation_serial=0
var background_palette: Dictionary={}
var diagnostics_origin='home'
var _boot_running=false
var _screen_building=false
var _content_tween: Tween
var _axes_elapsed=0.0
var _pending_created_id=''
var _pending_controller_message=''


func _ready() -> void:
	add_child(JoyNavigation.new())
	_build_shell()
	SceneRouter.screen_requested.connect(_show_screen)
	SettingsService.settings_changed.connect(func(_value): _apply_theme())
	AppState.profile_changed.connect(_profile_updated)
	AppState.objectives_changed.connect(func(_progress): _responsive.call_deferred())
	ControllerService.controller_connection_changed.connect(_controller_connection)
	get_viewport().size_changed.connect(_responsive)
	get_tree().auto_accept_quit=false
	get_tree().root.close_requested.connect(_request_quit)
	_boot()

func _boot() -> void:
	if _boot_running or is_instance_valid(modal): return
	_boot_running=true
	startup_settings_error=''
	_clear('boot')
	var loader=Startup.instantiate()
	content.add_child(loader)
	loader.set_status('Chargement des commandes…')
	await get_tree().process_frame
	if not is_inside_tree(): return
	var mapping_result=InputSetup.configure()
	ControllerService.refresh()
	loader.set_status('Lecture des réglages et de l’accessibilité…')
	await get_tree().process_frame
	if not is_inside_tree(): return
	var settings_result=SettingsService.load_settings()
	_apply_theme()
	if not settings_result.ok: startup_settings_error=settings_result.error
	loader.set_status('Validation du catalogue et des missions…')
	await get_tree().process_frame
	if not is_inside_tree(): return
	SaveService.invalidate_definitions()
	var catalog_result=ShopService.load_catalog()
	var rules_result=RewardService.load_rules()
	if not mapping_result.ok or not catalog_result.ok or not rules_result.ok:
		_boot_running=false
		var error=mapping_result.error if not mapping_result.ok else (catalog_result.error if not catalog_result.ok else rules_result.error)
		_show_fatal('Données du projet invalides',error)
		return
	loader.set_status('Lecture des profils locaux…')
	await get_tree().process_frame
	if not is_inside_tree(): return
	var profiles_result=ProfileService.refresh()
	if not profiles_result.ok:
		_boot_running=false
		_show_fatal('Stockage local inaccessible',profiles_result.error)
		return
	var session=SaveService.read_session()
	if session.ok:
		var data=session.get('data',{})
		last_profile_id=data.get('last_profile_id',data.get('profile_id','')) if data is Dictionary else str(data)
	loader.set_status('Ouverture de votre console…')
	await get_tree().process_frame
	if not is_inside_tree(): return
	_boot_running=false
	SettingsService.play_music()
	if not startup_settings_error.is_empty(): _show_settings_recovery()
	elif not ProfileService.issues.is_empty(): _show_recovery()
	elif ProfileService.profiles.is_empty(): _open_editor('')
	else: _show_screen('profiles')

func _build_shell() -> void:
	background=ColorRect.new()
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for _index in range(2):
		var glow=TextureRect.new()
		glow.mouse_filter=Control.MOUSE_FILTER_IGNORE
		glow.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		var gradient=Gradient.new()
		gradient.offsets=PackedFloat32Array([0.0,.5,1.0])
		gradient.colors=PackedColorArray([Color(.32,.50,.64,.14),Color(.32,.50,.64,.035),Color(.32,.50,.64,0)])
		var texture=GradientTexture2D.new()
		texture.width=512;texture.height=512
		texture.fill=GradientTexture2D.FILL_RADIAL
		texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1,.5)
		texture.gradient=gradient
		glow.texture=texture
		background.add_child(glow)
		ambient_glows.append(glow)
	shell=MarginContainer.new()
	add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col=VBoxContainer.new()
	shell_column=col
	col.add_theme_constant_override('separation',16)
	shell.add_child(col)
	var header=HBoxContainer.new()
	header.name='header'
	header.custom_minimum_size.y=46
	header.add_theme_constant_override('separation',12)
	col.add_child(header)
	header_player=HBoxContainer.new()
	header_player.name='header_player'
	header_player.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header_player.alignment=BoxContainer.ALIGNMENT_BEGIN
	header_player.add_theme_constant_override('separation',8)
	header.add_child(header_player)
	header_avatar=Avatar.new()
	header_avatar.name='header_avatar'
	header_avatar.custom_minimum_size=Vector2(44,44)
	header_avatar.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	header_player.add_child(header_avatar)
	var identity=VBoxContainer.new()
	identity.name='header_identity'
	identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	identity.alignment=BoxContainer.ALIGNMENT_CENTER
	identity.add_theme_constant_override('separation',0)
	header_player.add_child(identity)
	header_profile=Label.new()
	header_profile.name='header_profile'
	header_profile.clip_text=true
	header_profile.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	header_profile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	identity.add_child(header_profile)
	header_points=Label.new()
	header_points.name='header_points'
	header_points.clip_text=true
	header_points.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	header_points.theme_type_variation='SecondaryLabel'
	identity.add_child(header_points)
	var brand=Label.new()
	header_brand=brand
	brand.name='header_brand'
	brand.text='Console CIEL'
	brand.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	brand.add_theme_font_size_override('font_size',22)
	brand.add_theme_color_override('font_color',Color('#527FA3'))
	header.add_child(brand)
	header_back=_button(header,'Retour',_back,'header_back')
	header_back.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	header_back.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	header_back.custom_minimum_size.x=112
	scroll=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=false
	scroll.resized.connect(_responsive)
	col.add_child(scroll)
	content=VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override('separation',16)
	scroll.add_child(content)
	footer=Label.new()
	footer.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	footer.add_theme_font_size_override('font_size',16)
	footer.add_theme_color_override('font_color',Color('#586674'))
	footer.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast=Toast.new()
	col.add_child(toast)
	col.add_child(footer)
	navigation=Navigation.new()
	col.add_child(navigation)
	navigation.destination_requested.connect(_navigation_destination)
	_responsive()

func _profile_palette() -> Dictionary:
	if _is_settings_screen(screen) and draft_settings.has('profile_theme') and not AppState.profile.is_empty():
		if draft_settings.profile_theme in AppState.profile.owned_items:
			var preview=ShopService.item(draft_settings.profile_theme)
			if not preview.is_empty(): return preview
	if not AppState.profile.is_empty():
		return ShopService.item(AppState.profile.equipped.theme)
	return {'background':'#F3F5F7','accent':'#527FA3'}

func _palette() -> Dictionary:
	return AppearancePalette.resolve(SettingsService.current,_profile_palette())

func _apply_theme() -> void:
	if SettingsService.current.get('reduce_motion',false) and _content_tween!=null and _content_tween.is_valid():
		_content_tween.kill()
		content.modulate.a=1.0
	background_palette=_palette()
	theme=ThemeFactory.build(SettingsService.current,background_palette)
	if header_brand!=null: header_brand.add_theme_color_override('font_color',Color(background_palette.foreground))
	if header_profile!=null: header_profile.remove_theme_color_override('font_color')
	if footer!=null: footer.theme_type_variation='SecondaryLabel';footer.remove_theme_color_override('font_color')
	if footer!=null: footer.add_theme_font_size_override('font_size',18 if SettingsService.current.get('large_text',false) else 16)
	if background!=null: background.color=Color(background_palette.get('background','#F3F5F7'))
	var accent=Color(background_palette.get('accent','#527FA3'))
	for glow in ambient_glows:
		glow.texture.gradient.colors=PackedColorArray([Color(accent.r,accent.g,accent.b,.14),Color(accent.r,accent.g,accent.b,.035),Color(accent.r,accent.g,accent.b,0)])
	if navigation!=null: navigation.apply_appearance(SettingsService.current,background_palette)
	_responsive()

func _profile_updated(_profile: Dictionary) -> void:
	if not _profile.is_empty(): last_profile_id=_profile.id
	_update_header()
	_apply_theme()

func _update_header() -> void:
	var active=not AppState.profile.is_empty()
	header_player.visible=active
	header_avatar.visible=active
	header_profile.visible=active
	header_points.visible=active
	var avatar_item=ShopService.item(AppState.profile.equipped.avatar) if active else {}
	var frame_item=ShopService.item(AppState.profile.equipped.frame) if active else {}
	if navigation!=null: navigation.update_player(AppState.profile,avatar_item,frame_item)
	if active:
		var item=ShopService.item(AppState.profile.equipped.avatar)
		header_avatar.color=Color(item.get('color','#527FA3'))
		header_avatar.variant={'H':0,'O':2,'F':1,'R':2}.get(item.get('symbol','H'),0)
		header_avatar.frame=AppState.profile.equipped.frame
		header_avatar.frame_spec=ShopService.item(AppState.profile.equipped.frame)
		header_avatar.set_local_image(AppState.profile.get('avatar_image',''))
		header_avatar.queue_redraw()
	header_profile.text=AppState.profile.display_name if active else ''
	header_profile.tooltip_text=header_profile.text
	header_points.text='%d pts' % AppState.profile.wallet.points if active else ''
	header_points.tooltip_text='%d points disponibles' % AppState.profile.wallet.points if active else ''
	if active and int(PenaltyService.state().debt) > 0:
		header_points.text += ' · dette %d' % int(PenaltyService.state().debt)
		header_points.tooltip_text += ' · %d points à rembourser' % int(PenaltyService.state().debt)

func _responsive() -> void:
	if shell==null: return
	var compact=size.x<1000 or size.y<600
	if ambient_glows.size()==2:
		ambient_glows[0].size=Vector2(size.x*.75,size.y*1.1)
		ambient_glows[0].position=Vector2(-size.x*.15,size.y*.35)
		ambient_glows[1].size=Vector2(size.x*.65,size.y)
		ambient_glows[1].position=Vector2(size.x*.5,-size.y*.35)
	var margin=12 if compact else 28
	if shell_column!=null:shell_column.add_theme_constant_override('separation',10 if compact else 16)
	if footer!=null and screen=='game':
		footer.text=('ZQSD / joystick : marcher · → : carte · Espace : interagir · P : pause' if is_instance_valid(demo) and demo.world != null and HotelLayout.is_zone(demo.world.room_id) else 'Flèches / joystick · Espace : interagir · T / face haut : missions · P / Start : pause')
	if footer!=null and screen in ['home','shop','profiles','help']:
		footer.text='Flèches / joystick · Entrée / face bas : valider · Échap : retour'
	var horizontal=maxi(margin,int((size.x-1400)/2))
	for side in ['left','right']: shell.add_theme_constant_override('margin_'+side,horizontal)
	for side in ['top','bottom']: shell.add_theme_constant_override('margin_'+side,margin)
	if navigation!=null: navigation.fit(size.x-2*horizontal,SettingsService.current.get('large_text',false),compact)
	if screen=='home': _fit_home_library()
	if screen=='game' and is_instance_valid(demo) and demo.is_inside_tree():demo._fit_minimum()
	if header_profile!=null:
		var large=SettingsService.current.get('large_text',false)
		header_profile.add_theme_font_size_override('font_size',(18 if compact else 20)+(2 if large else 0))
		header_points.add_theme_font_size_override('font_size',18 if large else 15)
		header_avatar.custom_minimum_size=Vector2(48,48) if large else Vector2(44,44)
		header_brand.add_theme_font_size_override('font_size',(20 if compact else 22)+(2 if large else 0))
		header_player.get_parent().custom_minimum_size.y=48 if large else 46
	for entry in responsive_grids:
		if is_instance_valid(entry[0]):
			_adapt_grid(entry[0],entry[1],entry[2])
	if content!=null and is_inside_tree(): _wire_navigation()

func _adapt_grid(grid: GridContainer,minimum: int,maximum: int) -> void:
	var available=minf(grid.size.x,size.x-44)
	if available<50: return
	var target=minimum+(55 if SettingsService.current.get('large_text',false) else 0)
	grid.columns=maxi(1,mini(maximum,int((available+14)/(target+14))))

func _clear(next: String) -> void:
	SceneRouter.lock_until_release()
	if _content_tween!=null and _content_tween.is_valid(): _content_tween.kill()
	content.modulate.a=1.0
	if screen!='boot': SceneRouter.remember(screen,get_viewport().gui_get_focus_owner())
	screen=next
	content.add_theme_constant_override('separation',16)
	SceneRouter.current_screen=next
	for child in content.get_children():
		if child==demo: child.hide()
		content.remove_child(child)
		if child!=demo: child.queue_free()
	responsive_grids.clear()
	hero_grid=null;hero_art=null;hero_panel=null;home_labels.clear();home_objectives=null;home_story=null
	home_split=null;home_game_library=null;home_carousel=null;home_cards.clear()
	if is_instance_valid(arcade):
		arcade.queue_free()
		arcade=null
	if navigation!=null:
		var pause_settings=_is_settings_screen(next) and settings_origin=='game'
		var pause_help=(next=='help' or (next=='controls' and controls_origin=='help')) and parent_screen=='game'
		navigation.visible=next in ['home','shop','profiles','settings','help','controls'] and not pause_settings and not pause_help
		navigation.update_state(next,not AppState.profile.is_empty())
	header_back.visible=next not in ['home','boot','recovery','settings_recovery','fatal'] and not (next=='editor' and ProfileService.profiles.is_empty())
	footer.text='Flèches / joystick : naviguer   ·   Entrée / face bas : valider   ·   Échap / face droit : retour'
	scroll.scroll_vertical=0
	_update_header()

func _show_screen(next: String) -> void:
	if next in ['home','game','shop','settings'] and AppState.profile.is_empty(): next='profiles'
	if is_instance_valid(modal) or _screen_building: return
	_screen_building=true
	_clear(next)
	match next:
		'profiles': _profiles()
		'home': _home()
		'shop': _shop()
		'settings': _settings()
		'help': _help()
		'controls': _controls()
		'game': _game()
		'arcade': _arcade()
		'recovery': _recovery_content()
		'diagnostics': _diagnostics()
		_: _home()
	_screen_building=false
	_responsive()
	_focus_initial.call_deferred()
	_wire_navigation()
	if not SettingsService.current.get('reduce_motion',false):
		content.modulate.a=0.5
		_content_tween=create_tween()
		_content_tween.tween_property(content,'modulate:a',1.0,.16)

func _focus_initial() -> void:
	if is_instance_valid(modal): return
	var key=SceneRouter.focus_key(screen)
	var choices=_focusables(content)
	if navigation.visible: choices.append_array(_focusables(navigation))
	for choice in choices:
		if not choice.focus_entered.is_connected(_ensure_focus_visible): choice.focus_entered.connect(_ensure_focus_visible)
	if screen=='game' and is_instance_valid(demo):
		_ensure_focus_visible()
		return
	for choice in choices:
		if choice.name==key:
			choice.grab_focus()
			return
	if not choices.is_empty():
		choices[0].grab_focus()

func _ensure_focus_visible() -> void:
	focus_scroll_serial+=1
	var token=focus_scroll_serial
	await get_tree().process_frame
	if not is_inside_tree(): return
	await get_tree().process_frame
	if not is_inside_tree() or is_instance_valid(modal) or token!=focus_scroll_serial: return
	var owner=get_viewport().gui_get_focus_owner()
	var ancestor=owner
	while is_instance_valid(ancestor):
		if ancestor is CanvasLayer: return
		ancestor=ancestor.get_parent()
	if is_instance_valid(owner) and content.is_ancestor_of(owner):
		var viewport_rect=scroll.get_global_rect()
		var target_rect=owner.get_global_rect()
		var offset=0.0
		if target_rect.position.y<viewport_rect.position.y:
			offset=target_rect.position.y-viewport_rect.position.y
		elif target_rect.end.y>viewport_rect.end.y:
			offset=target_rect.end.y-viewport_rect.end.y
		if absf(offset)>0.5: scroll.scroll_vertical+=int(ceil(offset) if offset>0 else floor(offset))

func _focusables(node: Node) -> Array:
	var result=[]
	if node is Control and node.focus_mode!=Control.FOCUS_NONE and node.is_visible_in_tree() and not (node is BaseButton and node.disabled): result.append(node)
	for child in node.get_children(): result.append_array(_focusables(child))
	return result

func _wire_navigation() -> void:
	navigation_serial+=1
	var token=navigation_serial
	await get_tree().process_frame
	if not is_inside_tree(): return
	await get_tree().process_frame
	if not is_inside_tree() or token!=navigation_serial or screen=='game' or is_instance_valid(modal): return
	var targets=_focusables(content)
	if navigation.visible: targets.append_array(_focusables(navigation))
	if header_back.visible: targets.append(header_back)
	for index in range(targets.size()):
		var control=targets[index]
		control.focus_next=control.get_path_to(targets[(index+1)%targets.size()])
		control.focus_previous=control.get_path_to(targets[posmod(index-1,targets.size())])
		var origin=control.get_global_rect().get_center()
		for side in [SIDE_TOP,SIDE_BOTTOM,SIDE_LEFT,SIDE_RIGHT]:
			var best: Control=null
			var best_score=INF
			for candidate in targets:
				if candidate==control: continue
				var delta=candidate.get_global_rect().get_center()-origin
				var advance=delta.y*(-1 if side==SIDE_TOP else 1) if side in [SIDE_TOP,SIDE_BOTTOM] else delta.x*(-1 if side==SIDE_LEFT else 1)
				if advance<1: continue
				var cross=absf(delta.x) if side in [SIDE_TOP,SIDE_BOTTOM] else absf(delta.y)
				var score=advance+cross*4.0
				if score<best_score:
					best_score=score
					best=candidate
			if is_instance_valid(best): control.set_focus_neighbor(side,control.get_path_to(best))

	if navigation.visible:
		var body=_focusables(content)
		var tabs=_focusables(navigation)
		for i in range(tabs.size()):
			var tab: Control=tabs[i]
			tab.focus_neighbor_left=tab.get_path_to(tabs[posmod(i-1,tabs.size())])
			tab.focus_neighbor_right=tab.get_path_to(tabs[(i+1)%tabs.size()])
			if not body.is_empty():
				tab.focus_neighbor_top=tab.get_path_to(body[-1])
				tab.focus_neighbor_bottom=tab.get_path_to(body[0])

func _label(host: Node,text: String,font_size: int=0,secondary: bool=false) -> Label:
	var label=Label.new()
	label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if font_size>0: label.add_theme_font_size_override('font_size',font_size+(2 if SettingsService.current.get('large_text',false) else 0))
	if secondary: label.theme_type_variation='SecondaryLabel'
	host.add_child(label)
	return label

func _button(host: Node,text: String,action: Callable,key: String='') -> Button:
	var button=GlassButton.new()
	button.text=text
	if not key.is_empty(): button.name=key
	button.pressed.connect(action)
	host.add_child(button)
	return button

func _panel(host: Node) -> VBoxContainer:
	var panel=PanelContainer.new()
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	host.add_child(panel)
	var col=VBoxContainer.new()
	col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	panel.add_child(col)
	return col

func _grid(host: Node,min_width: int=280,max_columns: int=3) -> GridContainer:
	var grid=GridContainer.new()
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	host.add_child(grid)
	responsive_grids.append([grid,min_width,max_columns])
	grid.resized.connect(func(): _adapt_grid(grid,min_width,max_columns))
	return grid

func _title(title: String,description: String) -> void:
	_label(content,title,32)
	if not description.is_empty(): _label(content,description,0,true)

func _notify(message: String) -> void:
	toast.show_message(message)

func _result(result: Dictionary,success: String='',retry: Callable=Callable()) -> bool:
	if not result.ok:
		if result.get('data') is Dictionary and result.data.get('recovery_required',false):
			_confirm('Une récupération est nécessaire',result.error,'Voir les options',func(): _show_recovery())
			return false
		_confirm('Action impossible',result.error,'Réessayer' if retry.is_valid() else 'Compris',retry if retry.is_valid() else func(): pass)
		return false
	if not success.is_empty(): _notify(success)
	return true

func _confirm(title: String,message: String,action: String,callback: Callable,cancelled: Callable=Callable()) -> void:
	if is_instance_valid(modal): return
	var paused_for_modal=screen=='game' and is_instance_valid(demo) and not demo.paused
	if paused_for_modal: demo.paused=true
	modal=Modal.new()
	modal.closed.connect(_modal_finished.bind(paused_for_modal))
	modal.open(self,title,message,action,callback,cancelled)

func _modal_finished(paused_for_modal: bool=false) -> void:
	modal=null
	if not _pending_controller_message.is_empty():
		if is_instance_valid(demo): demo.call_deferred('controller_lost',_pending_controller_message)
		_pending_controller_message=''
	elif paused_for_modal and is_instance_valid(demo) and demo.overlay_kind.is_empty():
		demo.paused=false
		SceneRouter.lock_until_release()

func _profiles() -> void:
	var loaded=ProfileService.refresh()
	if not loaded.ok:
		_show_fatal("Profils inaccessibles",loaded.error)
		return
	_title('Votre profil' if not AppState.profile.is_empty() else 'Qui joue aujourd’hui ?','Une identité, une bibliothèque et une aventure pour chacun.')
	if not AppState.profile.is_empty():
		_profile_overview()
	var grid=_grid(content,310,3)
	for profile in ProfileService.profiles:
		var card=ProfileCard.new()
		card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		card.configure(profile,ShopService.item(profile.equipped.avatar),profile.id==last_profile_id)
		card.selected.connect(_select_profile)
		card.edited.connect(_open_editor)
	var add=_panel(grid)
	_label(add,'Un nouveau joueur ?',24)
	_label(add,'Un pseudo et un avatar gratuit suffisent.',0,true)
	_button(add,'＋ Ajouter un profil',func(): _open_editor(''),'add_profile')
	if not ProfileService.issues.is_empty(): _button(content,'Données à récupérer',func(): _show_screen('recovery'),'recover_profiles')
	if AppState.profile.is_empty(): _button(content,'Quitter',_request_quit,'quit_profiles')

func _profile_overview() -> void:
	var panel=_panel(content)
	panel.name='profile_overview'
	var row=HBoxContainer.new()
	panel.add_child(row)
	var avatar=Avatar.new()
	avatar.name='profile_overview_avatar'
	avatar.custom_minimum_size=Vector2(70,70)
	avatar.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var spec=ShopService.item(AppState.profile.equipped.avatar)
	avatar.color=Color(spec.get('color','#527FA3'))
	avatar.variant={'H':0,'O':2,'F':1,'R':2}.get(spec.get('symbol','H'),0)
	avatar.frame=AppState.profile.equipped.frame
	avatar.frame_spec=ShopService.item(avatar.frame)
	avatar.set_local_image(AppState.profile.get('avatar_image',''))
	row.add_child(avatar)
	var identity=VBoxContainer.new()
	identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(identity)
	_label(identity,AppState.profile.display_name,24)
	_label(identity,'%d points · %d jeux acquis · %d / %d défis réalisés'%[AppState.profile.wallet.points,GameLibrary.owned_games(AppState.profile,ShopService.catalog).size(),AppState.profile.progress.completed_missions.size(),RewardService.missions.size()],14,true)
	var penalties := PenaltyService.state()
	if int(penalties.count) > 0:
		_label(identity,'%d pénalité(s) · %d points payés · %d points de dette'%[int(penalties.count),int(penalties.paid),int(penalties.debt)],14,true)
	var edit=_button(row,'Personnaliser',func():_open_editor(AppState.profile.id),'profile_personalize')
	edit.size_flags_horizontal=Control.SIZE_SHRINK_END
	edit.custom_minimum_size.x=200

func _select_profile(id: String) -> void:
	# ProfileService sélectionne seulement après sauvegarde réussie de l'ancien joueur.
	if _result(ProfileService.select_profile(id)):
		last_profile_id=id
		if is_instance_valid(demo):
			demo.queue_free()
			demo=null
		_show_screen('home')
		if AppState.profile.progress.get('legacy_migration_notice',false):
			_confirm('Les vrais défis sont disponibles',SaveService.LEGACY_MIGRATION_NOTICE,'Compris',func():
				_result(InvestigationService.acknowledge_migration()))

func _open_editor(id: String) -> void:
	_pending_created_id=''
	editor_id=id
	var record={}
	for p in ProfileService.profiles:
		if p.id==id: record=p
	editor_avatar=record.get('equipped',{}).get('avatar','avatar_default')
	editor_image=record.get('avatar_image','')
	editor_record=record.duplicate(true)
	editor_image_tab=not editor_image.is_empty()
	LocalAvatars.refresh()
	_clear('editor')
	content.add_theme_constant_override('separation',8)
	_title('Créer votre profil' if id.is_empty() else 'Personnaliser le profil','')
	var panel=_panel(content)
	panel.add_theme_constant_override('separation',6)
	var editor_panel=panel.get_parent() as PanelContainer
	var editor_style=editor_panel.get_theme_stylebox('panel').duplicate()
	editor_style.content_margin_top=8
	editor_style.content_margin_bottom=8
	editor_panel.add_theme_stylebox_override('panel',editor_style)
	var identity=HBoxContainer.new()
	identity.add_theme_constant_override('separation',18)
	panel.add_child(identity)
	editor_preview=Avatar.new()
	editor_preview.name='profile_avatar_preview'
	editor_preview.custom_minimum_size=Vector2(88,88)
	editor_preview.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	identity.add_child(editor_preview)
	var details=VBoxContainer.new()
	details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override('separation',6)
	identity.add_child(details)
	editor_preview_name=_label(details,record.get('display_name','Votre profil'),22)
	editor_preview_name.hide()
	editor_preview_name.clip_text=true
	editor_preview_name.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	_label(details,'Votre pseudo',16,true)
	name_edit=LineEdit.new()
	name_edit.name='profile_name'
	name_edit.text=record.get('display_name','Joueur '+str(ProfileService.profiles.size()+1))
	name_edit.max_length=16
	name_edit.select_all()
	name_edit.custom_minimum_size.y=48
	name_edit.select_all_on_focus=true
	name_edit.text_submitted.connect(func(_text): _submit_profile())
	details.add_child(name_edit)
	editor_name_count=_label(details,'',14,true)
	name_edit.text_changed.connect(func(_text): _refresh_editor_preview())
	var gallery_header=HBoxContainer.new()
	panel.add_child(gallery_header)
	_button(gallery_header,'Avatars',func(): _switch_editor_images(false),'profile_tab_avatars').custom_minimum_size.y=38
	_button(gallery_header,'Mes images',func(): _switch_editor_images(true),'profile_tab_images').custom_minimum_size.y=38
	var clear_image=_button(gallery_header,'Avatar classique',func():
		editor_image=''
		_refresh_editor_preview()
		_refresh_editor_choices(),'clear_profile_image')
	clear_image.custom_minimum_size.y=38
	clear_image.tooltip_text='Retirer la photo locale et garder votre avatar de la boutique.'
	editor_image_status=_label(panel,'',14,true)
	var gallery_scroll=ScrollContainer.new()
	gallery_scroll.name='profile_avatar_gallery'
	gallery_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	gallery_scroll.follow_focus=true
	gallery_scroll.custom_minimum_size.y=78
	panel.add_child(gallery_scroll)
	editor_gallery=_grid(gallery_scroll,160,6)
	editor_gallery.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var image_actions=HBoxContainer.new()
	panel.add_child(image_actions)
	_button(image_actions,'Ouvrir le dossier',_open_profile_images,'open_profile_images').custom_minimum_size.y=38
	_button(image_actions,'Actualiser les images',_reload_profile_images,'refresh_profile_images').custom_minimum_size.y=38
	editor_keyboard=Keyboard.new()
	editor_keyboard.name='profile_keyboard'
	panel.add_child(editor_keyboard)
	editor_keyboard.configure(name_edit)
	editor_keyboard.submitted.connect(_submit_profile)
	editor_keyboard.cancelled.connect(_back)
	editor_keyboard.layout_changed.connect(_editor_layout_changed)
	_refresh_editor_choices()
	_refresh_editor_preview()
	if not id.is_empty():
		_button(content,'Supprimer ce profil',_delete_profile,'delete_profile')
	_responsive()
	_editor_layout_changed()
	if id.is_empty(): editor_keyboard.focus_first_key.call_deferred()
	else: name_edit.call_deferred('grab_focus')
	footer.text='Clavier virtuel : flèches + Entrée / face bas. Le clavier physique reste disponible.'

func _editor_layout_changed() -> void:
	for control in _focusables(content):
		if not control.focus_entered.is_connected(_ensure_focus_visible): control.focus_entered.connect(_ensure_focus_visible)
	_wire_navigation()
	_ensure_focus_visible.call_deferred()

func _refresh_editor_preview() -> void:
	if not is_instance_valid(editor_preview):return
	var item=ShopService.item(editor_avatar)
	editor_preview.color=Color(item.get('color','#527FA3'))
	editor_preview.variant={'H':0,'O':2,'F':1,'R':2}.get(item.get('symbol','H'),0)
	editor_preview.frame=editor_record.get('equipped',{}).get('frame','frame_default')
	editor_preview.frame_spec=ShopService.item(editor_preview.frame)
	editor_preview.set_local_image(editor_image)
	editor_preview.queue_redraw()
	editor_preview_name.text=name_edit.text if not name_edit.text.is_empty() else 'Votre profil'
	editor_name_count.text='%d / 16 caractères · enregistré seulement avec Valider'%name_edit.text.length()

func _switch_editor_images(local: bool) -> void:
	editor_image_tab=local
	_refresh_editor_choices()

func _refresh_editor_choices() -> void:
	if not is_instance_valid(editor_gallery):return
	for child in editor_gallery.get_children():
		editor_gallery.remove_child(child)
		child.queue_free()
	editor_avatar_buttons.clear()
	if editor_image_tab:
		var images=LocalAvatars.list_images()
		editor_image_status.text='%d image(s) locale(s) · PNG, JPG ou WEBP · bouton Actualiser après un ajout'%images.size()
		for item in images:
			var filename:String=item.filename
			_add_editor_avatar_choice(item.name,editor_avatar,filename,'image_'+filename.sha256_text().substr(0,12))
		if images.is_empty():
			_label(editor_gallery,'Ajoutez vos images dans le dossier images_profil, puis cliquez sur Actualiser.',0,true)
	else:
		editor_image_status.text='Vos avatars gratuits et ceux déjà obtenus dans la boutique.'
		for item in ShopService.catalog:
			if item.type!='avatar':continue
			if item.price!=0 and not (not editor_record.is_empty() and item.id in editor_record.owned_items):continue
			_add_editor_avatar_choice(item.name,item.id,'','avatar_'+item.id)
	if not editor_image.is_empty() and LocalAvatars.texture_for(editor_image)==null:
		editor_image_status.text+=' · Image absente : votre avatar classique reste affiché.'
	_responsive()
	_editor_layout_changed()

func _add_editor_avatar_choice(title: String,avatar_id: String,filename: String,key: String) -> void:
	var chosen=editor_image==filename and (not filename.is_empty() or editor_avatar==avatar_id)
	var button=_button(editor_gallery,'',func():
		editor_avatar=avatar_id
		editor_image=filename
		_refresh_editor_preview()
		for other in editor_avatar_buttons:
			var selected=other.get_meta('avatar_image')==editor_image and (not editor_image.is_empty() or other.get_meta('avatar_id')==editor_avatar)
			other.theme_type_variation='NavigationSelected' if selected else 'Button'
			var caption=other.find_child('avatar_choice_label',true,false)
			if caption!=null:caption.add_theme_color_override('font_color',other.get_theme_color('font_color',other.theme_type_variation)),key)
	button.set_meta('avatar_image',filename)
	button.set_meta('avatar_id',avatar_id)
	button.custom_minimum_size.y=76
	button.theme_type_variation='NavigationSelected' if chosen else 'Button'
	button.tooltip_text=filename if not filename.is_empty() else title
	var row=HBoxContainer.new()
	row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left=8;row.offset_right=-8;row.offset_top=6;row.offset_bottom=-6
	var avatar=Avatar.new()
	avatar.custom_minimum_size=Vector2(52,52)
	avatar.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var spec=ShopService.item(avatar_id)
	avatar.color=Color(spec.get('color','#527FA3'))
	avatar.variant={'H':0,'O':2,'F':1,'R':2}.get(spec.get('symbol','H'),0)
	avatar.set_local_image(filename)
	row.add_child(avatar)
	var label=Label.new()
	label.text=title
	label.clip_text=true;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.name='avatar_choice_label'
	label.add_theme_color_override('font_color',button.get_theme_color('font_color',button.theme_type_variation))
	row.add_child(label)
	editor_avatar_buttons.append(button)

func _reload_profile_images() -> void:
	LocalAvatars.refresh()
	_refresh_editor_choices()
	_refresh_editor_preview()
	_update_header()

func _open_profile_images() -> void:
	var folder=LocalAvatars.folder_path()
	var result=DirAccess.make_dir_recursive_absolute(folder)
	if result!=OK and result!=ERR_ALREADY_EXISTS:
		_confirm('Dossier indisponible','Impossible de créer le dossier images_profil. Choisissez un emplacement accessible pour les fichiers du programme.','Compris',func():pass)
		return
	if OS.shell_open(folder)!=OK:
		_confirm('Dossier des images',folder+'\nOuvrez ce dossier dans votre explorateur, ajoutez une image PNG, JPG ou WEBP, puis utilisez Actualiser.','Compris',func():pass)

func _submit_profile() -> void:
	if is_instance_valid(modal): return
	if not _pending_created_id.is_empty():
		_select_profile(_pending_created_id)
		return
	var result: Dictionary
	if editor_id.is_empty():
		result=ProfileService.create_profile(name_edit.text,editor_avatar,editor_image)
		if not result.ok and result.get('data') is Dictionary and result.data.has('id'):
			_pending_created_id=result.data.id
			_confirm('Profil créé, sélection à terminer',result.error+' Le profil est conservé. Réessayer sélectionnera ce profil sans en créer un deuxième.','Réessayer',func(): _select_profile(_pending_created_id))
			return
	else:
		if not _result(ProfileService.select_profile(editor_id)): return
		result=ProfileService.update_profile(name_edit.text,editor_avatar,editor_image)
	if _result(result,'✓ Profil créé' if editor_id.is_empty() else '✓ Profil modifié',_submit_profile): _show_screen('home')

func _delete_profile() -> void:
	var label='ce profil'
	for p in ProfileService.profiles:
		if p.id==editor_id: label=p.display_name
	_confirm('Supprimer « '+label+' » ?','Ce profil, sa progression, son inventaire et ses points seront supprimés. Les autres profils seront conservés.','Supprimer',func():
		if _result(ProfileService.delete_profile(editor_id),'Profil supprimé'):
			ProfileService.refresh()
			if ProfileService.profiles.is_empty(): _open_editor('')
			else: _show_screen('profiles'))

func _home() -> void:
	if AppState.profile.is_empty(): return
	_label(content,'Votre bibliothèque',28)
	var entries=GameLibrary.definitions(ShopService.catalog)
	if SettingsService.current.get('home_layout','split')=='carousel':
		var controls=HBoxContainer.new()
		content.add_child(controls)
		_button(controls,'‹ Précédent',func(): _scroll_home(-1),'home_previous').custom_minimum_size.y=38
		_label(controls,'Choisissez une couverture · les jeux Test sont en préparation',14,true)
		_button(controls,'Suivant ›',func(): _scroll_home(1),'home_next').custom_minimum_size.y=38
		home_carousel=ScrollContainer.new()
		home_carousel.name='home_carousel'
		home_carousel.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
		home_carousel.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
		home_carousel.follow_focus=true
		content.add_child(home_carousel)
		var row=HBoxContainer.new()
		row.add_theme_constant_override('separation',14)
		home_carousel.add_child(row)
		for entry in entries:
			var card=_add_home_game(row,entry,true)
			card.custom_minimum_size.x=270
	else:
		home_split=GridContainer.new()
		home_split.name='home_split'
		home_split.columns=2
		home_split.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		home_split.add_theme_constant_override('h_separation',16)
		content.add_child(home_split)
		_add_home_game(home_split,entries[0],false)
		var right=VBoxContainer.new()
		right.name='home_library_column'
		right.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		home_split.add_child(right)
		_label(right,'Vos prochains jeux',20)
		_label(right,'Quatre emplacements de test · achats en points',13,true)
		home_game_library=GridContainer.new()
		home_game_library.name='home_game_library'
		home_game_library.columns=2
		home_game_library.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		home_game_library.add_theme_constant_override('h_separation',10)
		home_game_library.add_theme_constant_override('v_separation',10)
		right.add_child(home_game_library)
		for index in range(1,entries.size()):
			_add_home_game(home_game_library,entries[index],true)
	_fit_home_library()

func _add_home_game(host: Node,entry: Dictionary,compact: bool) -> Control:
	var educational=entry.id==GameLibrary.EDUCATIONAL_ID
	var definition=entry.duplicate(true)
	if educational:
		definition.description='Cinq chapitres et séjour à l’hôtel · jusqu’à 750 points.'
		definition.action_label='Continuer' if AppState.profile.progress.started else 'Commencer'
	var card=GameCard.new()
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL if host is GridContainer else Control.SIZE_FILL
	host.add_child(card)
	card.configure(definition,educational or entry.id in AppState.profile.owned_items,educational,compact)
	card.play_requested.connect(_launch_library_game)
	card.details_requested.connect(func(id): shop_filter=4;shop_inventory=false;_show_screen('shop');_focus_product.call_deferred(id))
	var cover=card.find_child('game_cover_'+entry.id,true,false)
	if cover!=null:
		cover.name='home_education_cover' if educational else 'library_cover_'+entry.id
		if is_instance_valid(home_carousel):cover.custom_minimum_size.y=132
	if educational:
		hero_panel=card
		hero_panel.name='home_hero'
		hero_art=cover
		var action=card.find_child('play_'+entry.id,true,false)
		action.name='continue_game' if AppState.profile.progress.started else 'new_game'
		var column=card.get_child(0)
		column.add_theme_constant_override('separation',8)
		home_labels.progress=_label(column,_investigation_progress_text(),15,true)
		var secondary=_button(column,'Nouvelle partie' if AppState.profile.progress.started else 'Continuer',_new_game if AppState.profile.progress.started else _continue_game,'new_game' if AppState.profile.progress.started else 'continue_game')
		secondary.disabled=not AppState.profile.progress.started
		secondary.visible=AppState.profile.progress.started
		secondary.custom_minimum_size.y=38
	home_cards.append(card)
	return card

func _investigation_progress_text() -> String:
	if InvestigationService.current_chapter() == 0:
		var room_id: String = AppState.profile.progress.room_id
		var hotel: Dictionary = HotelService.state()
		match int(hotel.get("morning_stage", 0)):
			1: return "Hôtel · descendez au rez-de-chaussée"
			2: return "Hôtel · rejoignez la salle du petit-déjeuner"
			3: return "Petit-déjeuner · réparez la machine à café"
			4: return "Petit-déjeuner · prenez votre café"
			5: return "Chambre 206 · récupérez votre sac"
			6: return "CTF sudo hack · rejoignez l’arrêt de bus"
			7: return "CTF sudo hack · entrez dans le bâtiment"
			8: return "CTF sudo hack · rendez-vous à l’accueil"
		if room_id == "courtyard": return "Cour · vers l’hôtel d’en face"
		if hotel.bed_state == "rested": return "Hôtel · le lendemain matin"
		if hotel.bed_state == "sitting": return "Chambre 206 · installé sur le lit"
		if room_id == "hotel_room_206": return "Chambre 206 · déposez vos affaires" if not hotel.luggage_placed else "Chambre 206 · une nuit de repos"
		if room_id == "hotel_floor_2": return "Hôtel · rendez-vous chambre 206"
		if room_id == "hotel_stairs_1": return "Hôtel · palier du premier étage"
		if not hotel.reserved: return "Hôtel · réservez à la réception"
		return "Hôtel · réparez le système de réservation" if not hotel.repaired else "Hôtel · rejoignez le deuxième étage"
	var missions: Array = InvestigationService.chapter_missions()
	var completed: Array = AppState.profile.get('progress',{}).get('completed_missions',[])
	var count := 0
	for mission in missions:
		if mission.id in completed: count += 1
	return 'Chapitre %d · %d / %d défis réalisés'%[InvestigationService.current_chapter(),count,missions.size()]

func _fit_home_library() -> void:
	if not AppState.profile.is_empty() and home_labels.has('progress') and is_instance_valid(home_labels.progress):
		home_labels.progress.text=_investigation_progress_text()
	if is_instance_valid(home_split):
		home_split.columns=1 if size.x<1000 else 2
		# Two equally sized columns on a desktop; stack them on the small console.
		if home_split.columns==2:
			var half=maxf(250,(size.x-2*maxf(28,(size.x-1400)/2)-16)/2)
			for child in home_split.get_children(): child.custom_minimum_size.x=half-18
		else:
			for child in home_split.get_children(): child.custom_minimum_size.x=0
		if is_instance_valid(hero_art): hero_art.custom_minimum_size.y=96 if size.y<600 else 112
	if is_instance_valid(home_game_library):home_game_library.columns=2
	if is_instance_valid(home_carousel):
		for card in home_cards:card.custom_minimum_size.x=250 if size.x<1000 else 270

func _scroll_home(direction: int) -> void:
	if not is_instance_valid(home_carousel): return
	var step=264 if size.x<1000 else 284
	var maximum=maxf(0,home_carousel.get_h_scroll_bar().max_value-home_carousel.get_h_scroll_bar().page)
	home_carousel.scroll_horizontal=int(clampf(home_carousel.scroll_horizontal+direction*step,0,maximum))

func _focus_product(id: String) -> void:
	var button=content.find_child('product_'+id,true,false)
	if button!=null:button.grab_focus()

func _launch_library_game(id: String) -> void:
	if not GameLibrary.can_play(AppState.profile,id,ShopService.catalog):
		_confirm('Jeu à débloquer','Achetez cet emplacement avec les points de l’enquête pour le retrouver dans votre bibliothèque.','Compris',func():pass)
		return
	if id==GameLibrary.EDUCATIONAL_ID:
		if AppState.profile.progress.started:_continue_game()
		else:_new_game()
		return
	if not _result(ProfileService.save_active()):return
	arcade_id=id
	_show_screen('arcade')

func _arcade() -> void:
	if not GameLibrary.can_play(AppState.profile,arcade_id,ShopService.catalog):
		_notify('Cet emplacement n’est pas possédé par ce profil.')
		_show_screen.call_deferred('home')
		return
	var entry=GameLibrary.entry(ShopService.catalog,arcade_id)
	var scene=load(entry.scene) as PackedScene
	var instance=scene.instantiate() if scene!=null else null
	if not instance is Control:
		if instance!=null:instance.queue_free()
		_confirm('Jeu indisponible','La scène du jeu ne peut pas être ouverte. Vos achats sont conservés.','Revenir',func():_show_screen('home'))
		return
	arcade=instance
	if arcade.has_method('configure'):arcade.call('configure',entry)
	if arcade.has_signal('menu_requested'):arcade.connect('menu_requested',_close_arcade)
	content.add_child(arcade)
	footer.text='Emplacement de test · le vrai jeu sera ajouté lorsqu’il sera prêt · Échap : bibliothèque'

func _close_arcade() -> void:
	var played=arcade_id
	_show_screen('home')
	var action=content.find_child('play_'+played,true,false)
	if action!=null:action.grab_focus.call_deferred()

func _is_settings_screen(view: String) -> bool:
	return view=='settings' or (view=='help' and parent_screen=='settings') or (view=='controls' and (controls_origin=='settings' or (controls_origin=='help' and parent_screen=='settings')))

func _navigation_destination(next: String) -> void:
	if next==screen or is_instance_valid(modal) or not SceneRouter.gameplay_allowed(): return
	var settings_subpage=screen!='settings' and _is_settings_screen(screen)
	if next=='settings' and settings_subpage:
		_show_screen('settings')
		return
	if screen=='settings' or settings_subpage:
		if _settings_dirty():
			_confirm('Quitter les réglages ?','Les aperçus non appliqués seront annulés. Pour les conserver, revenez ici et choisissez Appliquer.','Annuler les aperçus',func():
				_discard_settings()
				_navigate(next))
			return
		_discard_settings()
	_navigate(next)

func _navigate(next: String) -> void:
	if next=='help': parent_screen=screen
	if next=='profiles' and not _result(ProfileService.save_active()): return
	if next=='settings':
		settings_origin=screen
		draft_settings=SettingsService.committed.duplicate(true)
	_show_screen(next)

func _new_game() -> void:
	if AppState.profile.progress.started:
		_confirm('Nouvelle partie ?','La progression actuelle de l’enquête sera remise à zéro. Vos achats, points et récompenses déjà attribuées seront conservés ; rejouer ne donne pas de points supplémentaires.','Recommencer',_start_game)
	else: _start_game()

func _start_game() -> void:
	if _result(ProfileService.start_game(),'',_start_game):
		if is_instance_valid(demo): demo.queue_free()
		demo=null
		SceneRouter.lock_until_release()
		_show_screen('game')

func _continue_game() -> void:
	var loaded=SaveService.read_profile(AppState.profile.id)
	if not loaded.ok:
		_confirm('Progression illisible',loaded.error,'Récupération',func(): _show_recovery())
		return
	AppState.commit_profile(loaded.data)
	if not AppState.profile.progress.started:
		_notify('Aucune progression valide à continuer.')
		return
	SceneRouter.lock_until_release()
	_show_screen('game')

func _game() -> void:
	header_back.hide()
	footer.text='Flèches / joystick : déplacement · Espace / face bas : interagir · T / face haut : missions · P : pause'
	if not is_instance_valid(demo):
		demo=Demo.new()
		demo.menu_requested.connect(func():
			_show_screen('home')
			demo.queue_free()
			demo=null)
		demo.settings_requested.connect(func():
			settings_origin='game'
			draft_settings=SettingsService.committed.duplicate(true)
			_show_screen('settings'))
		demo.help_requested.connect(func():
			parent_screen='game'
			_show_screen('help'))
		demo.notification_requested.connect(_notify)
	content.add_child(demo)
	demo.show()
	demo.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	demo.custom_minimum_size.y=maxf(170,scroll.size.y)
	if demo.has_method('refresh'): demo.refresh()
	_responsive()

func _shop() -> void:
	_label(content,'La boutique CIEL',28)
	var wallet=_panel(content)
	wallet.name='shop_wallet'
	var bar=HBoxContainer.new()
	wallet.add_child(bar)
	var balance=_label(bar,'%d points'%AppState.profile.wallet.points,22)
	balance.autowrap_mode=TextServer.AUTOWRAP_OFF
	balance.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	var filter=OptionButton.new()
	filter.name='shop_filter'
	filter.custom_minimum_size=Vector2(180,42)
	filter.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for title in ['Tout découvrir','Avatars','Thèmes','Cadres','Jeux']:filter.add_item(title)
	filter.selected=shop_filter
	filter.item_selected.connect(func(index):shop_filter=index;_show_screen('shop'))
	bar.add_child(filter)
	_button(bar,'Tout découvrir' if shop_inventory else 'Mes achats',func():shop_inventory=not shop_inventory;_show_screen('shop'),'shop_inventory').custom_minimum_size.y=42
	_label(wallet,'Gagnés dans les défis de l’enquête · aucun argent réel',13,true)
	var games=_grid(content,240,4)
	games.name='shop_games'
	var cosmetics=_grid(content,260,3)
	cosmetics.name='shop_cosmetics'
	var count=0
	for item in ShopService.catalog:
		if shop_filter>0 and item.type!=['','avatar','theme','frame','game'][shop_filter]:continue
		var owned=item.id in AppState.profile.owned_items
		if shop_inventory and not owned:continue
		var card=ProductCard.new()
		card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		(games if item.type=='game' else cosmetics).add_child(card)
		card.configure(item,owned,AppState.profile.equipped.get(item.type,'')==item.id,AppState.profile.wallet.points>=item.price)
		card.action_requested.connect(_product_action)
		count+=1
	if games.get_child_count()==0:games.hide()
	if cosmetics.get_child_count()==0:cosmetics.hide()
	if count==0:_label(content,'Aucun achat dans cette catégorie pour le moment.',0,true)
	_label(content,'Test 1 à Test 4 sont des emplacements en préparation. Leur achat permet de vérifier votre bibliothèque.',13,true)

func _product_action(id: String) -> void:
	var item=ShopService.item(id)
	if item.is_empty(): _notify('Cet article est inconnu.'); return
	if id in AppState.profile.owned_items:
		if item.type=='game':_launch_library_game(id);return
		if AppState.profile.equipped.get(item.type,'')==id: _notify('Cet article est déjà équipé.'); return
		if _result(ShopService.equip(id),'✓ « '+item.name+' » équipé',func(): _product_action(id)): _show_screen('shop')
	elif AppState.profile.wallet.points<item.price:
		var maximum=0
		for mission in RewardService.missions: maximum+=mission.reward
		_confirm('Points insuffisants','Résolvez les missions des cinq chapitres pour gagner jusqu’à %d points par profil. Une mission ne récompense qu’une seule fois. Cet article coûte %d points ; votre solde est de %d.' % [maximum,item.price,AppState.profile.wallet.points],'Compris',func(): pass)
	else:
		_confirm('Acheter « '+item.name+' » ?','Prix : %d points virtuels. Nouveau solde : %d points. Aucun argent réel.' % [item.price,AppState.profile.wallet.points-item.price],'Acheter',func():
			if _result(ShopService.purchase(id),'✓ Achat réussi et enregistré',func(): _product_action(id)): _show_screen('shop'))

func _settings() -> void:
	_title('Paramètres','Appliquer enregistre. Annuler restaure les aperçus.')
	var categories=OptionButton.new()
	categories.name='settings_categories'
	categories.custom_minimum_size=Vector2(260,42)
	categories.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	for title in ['Audio','Affichage','Accessibilité','Commandes','Apparence','Données','À propos','Crédits']: categories.add_item(title)
	categories.selected=settings_category
	categories.item_selected.connect(func(index): settings_category=index; _show_screen('settings'))
	content.add_child(categories)
	var panel=_panel(content)
	match settings_category:
		0:
			_slider(panel,'Volume général','master',0,100,1,'%')
			_slider(panel,'Musique','music',0,100,1,'%')
			_slider(panel,'Effets','effects',0,100,1,'%')
			_button(panel,'Écouter un effet',func(): SettingsService.play_effect(),'test_effect')
		1:
			_label(panel,'Votre écran et votre bibliothèque',22)
			_toggle(panel,'Plein écran','fullscreen')
			_home_layout_setting(panel)
			_label(panel,'Base : 1280 × 720. Mode compact : 800 × 480 et 1024 × 600. La taille de fenêtre reste ajustable sur PC.',0,true)
		2:
			_toggle(panel,'Grand texte','large_text')
			_toggle(panel,'Réduire les animations','reduce_motion')
			_toggle(panel,'Réduire la transparence','reduce_transparency')
		3:
			_slider(panel,'Zone morte du joystick','deadzone',.1,.6,.01,'')
			axes_label=_label(panel,'',0,true)
			_button(panel,'Test des commandes',func(): controls_origin='settings'; _show_screen('controls'),'test_controls')
			_label(panel,'La correspondance USB HID du contrôleur fabriqué devra être mesurée sur le matériel. Le joystick au repos doit rester dans la zone morte.',0,true)
		4:
			_appearance_settings(panel)
		5:
			_label(panel,'Progression de l’enquête',22)
			_button(panel,'Réinitialiser la progression',_reset_progress,'reset_progress')
			_label(panel,'Les achats, le solde et les identifiants des récompenses sont conservés. Supprimer un profil efface l’ensemble de ses données.',0,true)
		6:
			_label(panel,'Console CIEL · logiciel '+str(ProjectSettings.get_setting('application/config/version'))+'\nGodot 4.6.3 · rendu Compatibility\nProjet scolaire bac pro CIEL',22)
			_label(panel,'Logiciel : Loghan\nConstruction et assemblage : binôme, nom à compléter\nDonnées locales ; aucune connexion requise.',0,true)
			_label(panel,'Données : '+PlatformService.user_data_directory()+'\nJournaux : '+PlatformService.application_log_directory(),0,true)
			_button(panel,'Aide / Crédits',func(): parent_screen='settings'; _show_screen('help'),'settings_help')
		7:
			_settings_credits(panel)
	var actions=_grid(content,215,3)
	_button(actions,'Appliquer',_apply_settings,'settings_apply')
	_button(actions,'Annuler',_cancel_settings,'settings_cancel')
	_button(actions,'Valeurs par défaut',func():
		draft_settings=SettingsService.defaults.duplicate(true)
		SettingsService.preview(draft_settings)
		_show_screen('settings'),'settings_defaults')
	var system_actions=HBoxContainer.new()
	content.add_child(system_actions)
	var quit_button=_button(system_actions,'Quitter l’application',_request_quit,'quit')
	quit_button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	quit_button.custom_minimum_size.x=260
	if PlatformService.is_pi():
		var shutdown=_button(system_actions,'Arrêt système non configuré',func(): pass,'shutdown')
		shutdown.disabled=true
	var credits=_panel(content)
	credits.name='settings_credits_footer'
	_label(credits,'Crédits · Console CIEL',16)
	_label(credits,'Logiciel : Loghan · projet scolaire bac pro CIEL · moteur Godot',13,true)
	if settings_category!=7:_button(credits,'Voir les crédits et les licences',func():settings_category=7;_show_screen('settings'),'settings_credits').custom_minimum_size.y=38
	footer.text='Q / E ou boutons supérieurs : catégorie   ·   Échap : annuler   ·   Aperçus temporaires'

func _home_layout_setting(host: Node) -> void:
	_label(host,'Disposition de l’accueil',20)
	var selector=OptionButton.new()
	selector.name='setting_home_layout'
	selector.custom_minimum_size.y=42
	selector.add_item('Enquête à gauche · quatre jeux à droite')
	selector.add_item('Couvertures égales · défilement horizontal')
	selector.selected=1 if draft_settings.get('home_layout','split')=='carousel' else 0
	selector.item_selected.connect(func(index):
		draft_settings.home_layout='carousel' if index==1 else 'split'
		SettingsService.preview(draft_settings))
	host.add_child(selector)
	_label(host,'L’affichage s’adapte aux petits écrans. Le défilement suit aussi le focus de la manette.',14,true)

func _appearance_settings(host: Node) -> void:
	_label(host,'Un style qui vous ressemble',22)
	_label(host,'Styles de la console · aperçu immédiat · annulation possible',14,true)
	var styles=_grid(host,180,3)
	for preset in AppearancePalette.presets():
		var id:String=preset.id
		var button=_button(styles,preset.name,func():
			draft_settings.appearance_style=id
			if id!='profile':draft_settings.erase('profile_theme')
			SettingsService.preview(draft_settings)
			_show_screen('settings'),'appearance_'+id)
		button.theme_type_variation='NavigationSelected' if draft_settings.get('appearance_style','profile')==id else 'Button'
		button.custom_minimum_size.y=42
	var color_grid=_grid(host,390,2)
	_color_setting(color_grid,'Couleur du fond','background_color',[
		['Couleur du style',''],['Brume','#F3F5F7'],['Bleu nuit','#101827'],['Sable','#F7F0E3'],['Sauge','#DDEBE3'],['Lilas','#E7DFF5'],['Rose','#F4E0E8']])
	_color_setting(color_grid,'Couleur des boutons','button_color',[
		['Couleur du style',''],['Bleu CIEL','#527FA3'],['Violet','#7760BC'],['Émeraude','#327D68'],['Corail','#C56C55'],['Or','#C39B42'],['Noir','#1B2435']])
	_label(host,'Thèmes de votre profil',20)
	for item in ShopService.catalog:
		if item.type=='theme' and item.id in AppState.profile.owned_items:
			var id:String=item.id
			var selected=draft_settings.get('appearance_style','profile')=='profile' and draft_settings.get('profile_theme',AppState.profile.equipped.theme)==id
			var button=_button(host,('✓ ' if selected else '')+item.name,func():
				draft_settings.profile_theme=id
				draft_settings.appearance_style='profile'
				SettingsService.preview(draft_settings)
				_show_screen('settings'),'theme_'+id)
			button.custom_minimum_size.y=38
			button.theme_type_variation='NavigationSelected' if selected else 'Button'
	_label(host,'Les styles gratuits ci-dessus n’utilisent pas vos points. Les cosmétiques du profil restent dans la boutique.',13,true)

func _color_setting(host: Node,title: String,key: String,choices: Array) -> void:
	var row=SettingRow.new()
	host.add_child(row)
	var controls=HBoxContainer.new()
	controls.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var selector=OptionButton.new()
	selector.name='setting_'+key
	selector.custom_minimum_size=Vector2(180,42)
	selector.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var chosen:String=draft_settings.get(key,'')
	var selected=0
	for index in range(choices.size()):
		selector.add_item(choices[index][0])
		if chosen==choices[index][1]:selected=index
	if not chosen.is_empty() and selected==0:
		choices=choices.duplicate(true)
		choices.append(['Personnalisée',chosen])
		selector.add_item('Personnalisée')
		selected=choices.size()-1
	selector.selected=selected
	selector.item_selected.connect(func(index):draft_settings[key]=choices[index][1];SettingsService.preview(draft_settings))
	controls.add_child(selector)
	var picker=ColorPickerButton.new()
	picker.name='background_custom' if key=='background_color' else 'button_custom'
	picker.custom_minimum_size=Vector2(130,42)
	picker.text='Personnaliser'
	picker.edit_alpha=false
	picker.color=Color(chosen if not chosen.is_empty() else background_palette.get('background' if key=='background_color' else 'button','#527FA3'))
	picker.color_changed.connect(func(color):draft_settings[key]='#'+color.to_html(false).to_upper();SettingsService.preview(draft_settings))
	controls.add_child(picker)
	row.configure(title,controls,'Un choix de couleur reste temporaire jusqu’à Appliquer.')

func _settings_credits(host: Node) -> void:
	_label(host,'Crédits et licences',24)
	_label(host,'Console CIEL · logiciel '+str(ProjectSettings.get_setting('application/config/version')),20)
	_label(host,'Logiciel : Loghan
Construction et assemblage : binôme, nom à compléter
Projet scolaire bac pro CIEL',16,true)
	_label(host,'Illustrations et sons originaux : CC0 1.0.
Moteur Godot : licence MIT.
Polices et dépendances du moteur : notices fournies dans assets/licenses/.',16,true)
	_label(host,'L’enquête CIEL est une simulation pédagogique fictive. Test 1 à Test 4 sont des emplacements en attente des vrais jeux. Points virtuels uniquement ; aucun compte ni paiement réel.',16,true)
	_button(host,'Aide et commandes',func():parent_screen='settings';_show_screen('help'),'credits_help')

func _toggle(host: Node,title: String,key: String) -> void:
	var check=CheckButton.new()
	check.name='setting_'+key
	check.text=title
	check.button_pressed=draft_settings.get(key,SettingsService.defaults[key])
	check.custom_minimum_size.y=48
	check.toggled.connect(func(value):
		draft_settings[key]=value
		SettingsService.preview(draft_settings))
	host.add_child(check)

func _slider(host: Node,title: String,key: String,minimum: float,maximum: float,step_size: float,suffix: String) -> void:
	var row=SettingRow.new()
	host.add_child(row)
	var slider=HSlider.new()
	slider.name='setting_'+key
	slider.min_value=minimum
	slider.max_value=maximum
	slider.step=step_size
	slider.value=draft_settings.get(key,SettingsService.defaults[key])
	slider.custom_minimum_size=Vector2(0,36)
	slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.configure(title,slider,'0 = silence' if suffix=='%' else 'Seuil appliqué à la navigation et aux déplacements.')
	var value_label=_label(row.heading,str(int(slider.value))+' '+suffix if suffix=='%' else '%.2f' % slider.value,18,true)
	value_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	value_label.size_flags_horizontal=Control.SIZE_SHRINK_END
	slider.value_changed.connect(func(value):
		draft_settings[key]=value
		value_label.text=str(int(value))+' '+suffix if suffix=='%' else '%.2f' % value
		SettingsService.preview(draft_settings))
	slider.gui_input.connect(func(event):
		if event.is_action_pressed('ui_up') or event.is_action_pressed('ui_down'):
			var side=SIDE_TOP if event.is_action_pressed('ui_up') else SIDE_BOTTOM
			var next=slider.find_valid_focus_neighbor(side)
			if is_instance_valid(next): next.grab_focus()
			slider.accept_event())

func _persist_settings() -> bool:
	var saved=SettingsService.apply_settings(draft_settings)
	if not saved.ok:
		_confirm('Réglages non enregistrés',saved.error+' Vos aperçus restent disponibles.','Réessayer',func(): _apply_settings())
		return false
	if draft_settings.has('profile_theme') and not AppState.profile.is_empty():
		var equipment=ShopService.equip(draft_settings.profile_theme)
		if not equipment.ok:
			_confirm('Thème non enregistré','Les réglages de la console sont enregistrés ; le thème précédent est conservé. '+equipment.error,'Réessayer',func(): _apply_settings())
			return false
	draft_settings=SettingsService.committed.duplicate(true)
	return true

func _apply_settings() -> void:
	if not _persist_settings(): return
	_notify('Réglages enregistrés')
	_show_screen(settings_origin)

func _discard_settings() -> void:
	draft_settings=SettingsService.committed.duplicate(true)
	SettingsService.cancel_preview()
	_apply_theme()

func _cancel_settings() -> void:
	_discard_settings()
	_show_screen(settings_origin)

func _reset_progress() -> void:
	_confirm('Réinitialiser l’enquête ?','Seule la progression du jeu sera supprimée. Vos achats, votre solde et les identifiants des récompenses déjà attribuées sont conservés. Rejouer ne permettra pas de regagner ces points.','Réinitialiser',func():
		if _result(ProfileService.reset_progress(),'Progression réinitialisée'):
			if is_instance_valid(demo): demo.queue_free(); demo=null
			settings_origin='home')

func _help() -> void:
	_title('Tout commence par une commande','Console CIEL · un projet pédagogique porté par deux élèves.')
	var panel=_panel(content)
	_label(panel,'Au clavier',24)
	_label(panel,'Flèches : navigation et déplacement\nEntrée : valider · Échap : retour\nP : pause de l’enquête · T : afficher / masquer les missions\nQ / E : catégories (hors saisie)\nZQSD : déplacement · Espace : interagir\nHôtel : → affiche / masque la carte ; D ou joystick pour marcher à droite.')
	_label(panel,'À la manette',24)
	_label(panel,'Croix ou joystick gauche : naviguer / se déplacer\nBouton de face bas : valider / interagir\nBouton de face droit : retour\nBouton de face haut (Triangle / Y / X) : afficher / masquer les missions\nStart / Menu : pause · LB / RB : catégories\nLes noms varient selon la manette. Le test montre les entrées réellement reçues.')
	_label(panel,'Passage piéton : attendez le feu vert. Traverser au rouge sans choc coûte 200 points. Un choc ramène au trottoir de départ avec les missions conservées. Le reste à payer devient une dette, remboursée par les prochaines récompenses.',0,true)
	_button(panel,'Test des commandes',func(): controls_origin='help'; _show_screen('controls'),'help_controls')
	var credits=_panel(content)
	_label(credits,'Crédits & licences',24)
	_label(credits,'Logiciel : Loghan\nConstruction et assemblage : binôme, nom à compléter\nFormes et illustrations originales : CC0 1.0\nSons originaux : CC0 1.0\nMoteur Godot et police intégrée : licences fournies dans assets/LICENSES.md et assets/licenses/.')
	_label(credits,'Cinq chapitres et treize défis : atelier, réseau, code, laboratoire réseau et labyrinthe. L’hôtel prolonge le récit après le chapitre 5 : réservation, panne informatique, escaliers et chambre 206. Ces exercices sont des simulations locales : ils n’exécutent aucun code et ne modifient aucun réglage du système.',0,true)
	_label(credits,'Points virtuels uniquement. Pas de compte, de serveur, de paiement ni d’indicateur de batterie simulé.',0,true)

func _controls() -> void:
	_title('Test des commandes','Boutons et axes réellement reçus par Godot. Débranchez/rebranchez pour vérifier la récupération de la navigation.')
	var monitor=InputMonitor.new()
	monitor.custom_minimum_size.y=250
	content.add_child(monitor)
	_button(content,'Retour',_back,'controls_back')

func _show_recovery() -> void:
	_show_screen('recovery')

func _recovery_content() -> void:
	_title('Des données demandent votre attention','Aucun fichier invalide n’est effacé automatiquement. Vous pouvez restaurer une copie précédente ou conserver l’original à part.')
	var loaded=ProfileService.refresh()
	if not loaded.ok:
		_show_fatal("Profils inaccessibles",loaded.error)
		return
	for issue in ProfileService.issues:
		var panel=_panel(content)
		if issue.get('id','').is_empty():
			_label(panel,'Dernière session illisible',22)
			_label(panel,issue.error,0,true)
			if issue.get('has_backup',false):
				_button(panel,'Restaurer la dernière sélection précédente',func():
					_confirm('Restaurer la sélection précédente ?','La session actuelle sera conservée à part. Aucun profil ne sera modifié.','Restaurer',func():
						if _result(SaveService.recover_session()): _after_recovery()),'restore_session_backup')
			_button(panel,'Conserver la session et choisir un profil',func():
				_confirm('Réinitialiser la dernière sélection ?','La session défectueuse et sa copie seront conservées à part. Les documents des profils restent inchangés.','Continuer',func():
					if _result(SaveService.reset_session()): _after_recovery()),'recover_session')
			continue
		_label(panel,'Profil '+str(issue.get('id','inconnu')),22)
		_label(panel,issue.error,0,true)
		if issue.get('has_backup',false):
			_button(panel,'Restaurer la sauvegarde précédente',func():
				_confirm('Restaurer ce profil ?','Le fichier actuel sera conservé à part. La copie précédente remplacera les données actives ; elle peut être moins récente.','Restaurer',func():
					if _result(ProfileService.recover(issue.id),'Copie précédente restaurée'): _after_recovery()),'recover_'+str(issue.id))
		_button(panel,'Conserver à part et continuer',func():
			_confirm('Conserver le fichier invalide ?','L’original sera placé en quarantaine et restera disponible pour une réparation manuelle. Il ne sera pas utilisé comme profil actif.','Conserver à part',func():
				if _result(ProfileService.quarantine(issue.id),'Fichier conservé en quarantaine'): _after_recovery()),'quarantine_'+str(issue.id))
	if not ProfileService.profiles.is_empty(): _button(content,'Utiliser les profils valides',func(): _show_screen('profiles'),'valid_profiles')
	else: _button(content,'Créer un profil indépendant',func(): _open_editor(''),'recovery_new_profile')
	_button(content,'Quitter',_request_quit,'recovery_quit')

func _after_recovery() -> void:
	var loaded=ProfileService.refresh()
	if not loaded.ok:
		_show_fatal("Profils inaccessibles",loaded.error)
		return
	if not ProfileService.issues.is_empty(): _show_screen('recovery')
	elif ProfileService.profiles.is_empty(): _open_editor('')
	else: _show_screen('profiles')

func _show_settings_recovery() -> void:
	_clear('settings_recovery')
	_title('Réglages illisibles',startup_settings_error)
	_label(content,'Le fichier d’origine sera conservé. Choisissez une récupération explicite ; les profils ne sont pas modifiés.',0,true)
	var backup=_button(content,'Restaurer la copie précédente',func():
		if _result(SettingsService.recover_settings()): startup_settings_error=''; _after_recovery(),'recover_settings')
	backup.disabled=not SettingsService._read(SettingsService._path()+'.bak').ok
	if backup.disabled: backup.text='Copie précédente valide indisponible'
	_button(content,'Conserver à part, utiliser les valeurs par défaut',func():
		if _result(SettingsService.recover_settings('defaults')):
			startup_settings_error=''
			_after_recovery(),'default_settings')
	_button(content,'Réessayer le chargement',_boot,'retry_settings')
	_button(content,'Quitter',_request_quit,'settings_recovery_quit')
	_focus_initial.call_deferred()
	_wire_navigation()

func _show_fatal(title: String,message: String) -> void:
	_clear('fatal')
	_title(title,message)
	_label(content,'Vérifiez le stockage et les fichiers data/shop_catalog.json, data/game_rules.json et data/controller_mapping.json. Les sauvegardes personnelles restent intactes.',0,true)
	_button(content,'Réessayer le chargement',_boot,'fatal_retry')
	_button(content,'Quitter',_request_quit,'fatal_quit')
	_focus_initial.call_deferred()
	_wire_navigation()

func _diagnostics() -> void:
	if not OS.has_feature('debug'): return
	_title('Diagnostic de développement','Mesures locales réelles · F3 pour ouvrir · aucune donnée matérielle inventée.')
	content.add_child(Diagnostics.new())
	_button(content,'Retour',func(): _show_screen(diagnostics_origin),'diagnostics_back')

func _open_diagnostics() -> void:
	if not OS.has_feature('debug') or is_instance_valid(modal) or screen in ['boot','fatal','settings_recovery','recovery','editor']: return
	if screen=='diagnostics': _show_screen(diagnostics_origin); return
	diagnostics_origin=screen
	if screen=='game' and is_instance_valid(demo) and not demo.paused: demo.request_pause()
	_show_screen('diagnostics')

func _back() -> void:
	if is_instance_valid(modal): modal.cancel_dialog(); return
	match screen:
		'home': _request_quit()
		'arcade': _close_arcade()
		'game':
			if is_instance_valid(demo) and demo.has_method('handle_back'): demo.handle_back()
		'settings': _cancel_settings()
		'controls': _show_screen(controls_origin)
		'diagnostics': _show_screen(diagnostics_origin)
		'help':
			_show_screen(parent_screen if parent_screen in ['settings','game'] else 'home')
		'editor':
			if ProfileService.profiles.is_empty(): _notify('Créez le premier profil pour continuer.'); return
			_show_screen('profiles')
		'profiles':
			if AppState.profile.is_empty(): _request_quit()
			else: _show_screen('home')
		'shop': _show_screen('home')

func _settings_dirty() -> bool:
	if SettingsService.current!=SettingsService.committed: return true
	return not AppState.profile.is_empty() and draft_settings.has('profile_theme') and draft_settings.profile_theme!=AppState.profile.equipped.theme

func _request_quit() -> void:
	if _boot_running or is_instance_valid(modal): return
	if _settings_dirty():
		modal=Modal.new()
		modal.closed.connect(_modal_finished)
		modal.open_choices(self,'Des réglages restent à appliquer','Choisissez quoi faire des aperçus avant de fermer l’application. Cette fermeture n’éteint pas le système.',[
			{'key':'quit_keep','text':'Revenir aux réglages','action':func():
				if screen!='settings': _show_screen('settings')},
			{'key':'quit_apply','text':'Appliquer et quitter','action':_quit_apply},
			{'key':'quit_discard','text':'Annuler les aperçus et quitter','action':func():
				_discard_settings()
				if screen=='settings': _show_screen('settings')
				_quit_saved()}])
		return
	_confirm('Quitter Console CIEL ?','La session sera sauvegardée avant la fermeture de l’application. Cette action n’éteint pas le système.','Quitter',_quit_saved)

func _quit_apply() -> void:
	var saved=SettingsService.apply_settings(draft_settings)
	if not saved.ok:
		_confirm('Fermeture suspendue',saved.error+' La session reste ouverte.','Réessayer',_quit_apply)
		return
	if draft_settings.has('profile_theme') and not AppState.profile.is_empty():
		var equipped=ShopService.equip(draft_settings.profile_theme)
		if not equipped.ok:
			_confirm('Fermeture suspendue',equipped.error+' Les réglages de la console sont enregistrés ; le thème reste à appliquer.','Réessayer',_quit_apply)
			return
	draft_settings=SettingsService.committed.duplicate(true)
	_quit_saved()

func _quit_saved() -> void:
	if not AppState.profile.is_empty():
		var saved=ProfileService.save_active()
		if not saved.ok:
			_confirm('Fermeture suspendue',saved.error+' La session reste ouverte ; aucune fermeture n’a été exécutée.','Réessayer',_quit_saved)
			return
	get_tree().quit()

func _controller_connection(device: int,connected: bool,was_active: bool) -> void:
	if not connected and was_active and is_instance_valid(demo):
		var message='La manette active a été déconnectée. Le jeu reste suspendu. Utilisez le clavier ou reconnectez une manette, puis choisissez Reprendre.'
		if is_instance_valid(modal):
			demo.paused=true
			_pending_controller_message=message
		else: demo.controller_lost(message)
	_notify(('Manette connectée : '+ControllerService.controller_name(device)+' · reprise explicite dans l’enquête') if connected else ('Manette active déconnectée · clavier disponible' if was_active else 'Manette secondaire déconnectée'))

func _input(event: InputEvent) -> void:
	if not ControllerService.accepts_event(event): return
	if event.is_action_pressed('debug_diagnostics') and not event.is_echo():
		get_viewport().set_input_as_handled()
		_open_diagnostics()
		return
	if not SceneRouter.gameplay_allowed():
		for action in ['ui_accept','ui_cancel','game_interact','game_missions','pause','tab_previous','tab_next']:
			if action in ['game_interact','game_missions','pause','tab_previous','tab_next'] and get_viewport().gui_get_focus_owner() is LineEdit: continue
			if event.is_action_pressed(action):
				get_viewport().set_input_as_handled()
				return

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(modal): return
	if event.is_action_pressed('ui_cancel'):
		get_viewport().set_input_as_handled()
		_back()
		return
	var focus=get_viewport().gui_get_focus_owner()
	if screen=='editor' or focus is LineEdit: return
	if screen in ['settings','shop']:
		var step=0
		if event.is_action_pressed('tab_next'): step=1
		elif event.is_action_pressed('tab_previous'): step=-1
		if step!=0:
			get_viewport().set_input_as_handled()
			if screen=='settings': settings_category=posmod(settings_category+step,8)
			else: shop_filter=posmod(shop_filter+step,5)
			_show_screen(screen)

func _process(delta: float) -> void:
	_axes_elapsed+=delta
	if _axes_elapsed<0.1: return
	_axes_elapsed=0.0
	if screen=='settings' and settings_category==3 and is_instance_valid(axes_label):
		var d=ControllerService.active_device
		if d<0: axes_label.text='Aucune manette active · navigation clavier disponible'
		else:
			var x_axis=JOY_AXIS_LEFT_X
			var y_axis=JOY_AXIS_LEFT_Y
			for event in InputMap.action_get_events('game_right'):
				if event is InputEventJoypadMotion: x_axis=event.axis
			for event in InputMap.action_get_events('game_down'):
				if event is InputEventJoypadMotion: y_axis=event.axis
			var pos=Vector2(Input.get_joy_axis(d,x_axis),Input.get_joy_axis(d,y_axis))
			axes_label.text='%s · %s\nAxes %d/%d : %.3f / %.3f · zone morte %.2f' % [ControllerService.controller_name(), 'Au repos' if pos.length()<=float(draft_settings.deadzone) else 'Joystick hors zone morte',x_axis,y_axis,pos.x,pos.y,draft_settings.deadzone]

func _exit_tree() -> void:
	if is_instance_valid(demo) and demo.get_parent()==null: demo.free()
