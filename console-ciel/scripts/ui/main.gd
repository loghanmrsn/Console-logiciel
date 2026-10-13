extends Control
const GlassButton=preload('res://scripts/ui/translucent_button.gd')
const ThemeFactory=preload('res://scripts/ui/theme_factory.gd')
const ProfileCard=preload('res://scripts/ui/profile_card.gd')
const ProductCard=preload('res://scripts/ui/product_card.gd')
const Avatar=preload('res://scripts/ui/avatar_icon.gd')
const Keyboard=preload('res://scripts/ui/virtual_keyboard.gd')
const Modal=preload('res://scripts/ui/confirmation_dialog.gd')
const Toast=preload('res://scripts/ui/notification.gd')
const SettingRow=preload('res://scripts/ui/setting_row.gd')
const Navigation=preload('res://scripts/ui/navigation_bar.gd')
const EnquiryArt=preload('res://scripts/ui/enquiry_art.gd')
const InputSetup=preload('res://scripts/input_setup.gd')
const InputMonitor=preload('res://scripts/ui/input_monitor.gd')
const Demo=preload('res://scripts/game/demo_game.gd')
const JoyNavigation=preload('res://scripts/ui/joy_navigation.gd')
const Startup=preload('res://scenes/startup.tscn')
const Diagnostics=preload('res://scripts/ui/diagnostics_panel.gd')

var background: ColorRect
var shell_column: VBoxContainer
var shell: MarginContainer
var navigation: CenterContainer
var hero_grid: GridContainer
var hero_art: Control
var hero_panel: PanelContainer
var home_labels: Dictionary={}
var home_objectives: Control
var home_story: VBoxContainer
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
	shell=MarginContainer.new()
	add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col=VBoxContainer.new()
	shell_column=col
	col.add_theme_constant_override('separation',16)
	shell.add_child(col)
	var header=HBoxContainer.new()
	header.custom_minimum_size.y=46
	col.add_child(header)
	var brand=Label.new()
	brand.text='Console CIEL'
	brand.add_theme_font_size_override('font_size',26)
	brand.add_theme_color_override('font_color',Color('#527FA3'))
	header.add_child(brand)
	header_back=_button(header,'Retour',_back,'header_back')
	header_back.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	header_back.custom_minimum_size.x=112
	var spacer=Control.new()
	spacer.size_flags_horizontal=Control.SIZE_FILL
	header.add_child(spacer)
	header_profile=Label.new()
	header_avatar=Avatar.new()
	header_avatar.custom_minimum_size=Vector2(40,40)
	header.add_child(header_avatar)
	header_profile.add_theme_color_override('font_color',Color('#586674'))
	header_profile.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	header_profile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header_profile.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(header_profile)
	header.move_child(header_avatar,header_profile.get_index())
	header_points=Label.new()
	header_points.add_theme_font_size_override('font_size',20)
	header.add_child(header_points)
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
	toast=Toast.new()
	col.add_child(toast)
	navigation=Navigation.new()
	col.add_child(navigation)
	navigation.destination_requested.connect(_navigation_destination)
	col.add_child(footer)
	_responsive()

func _palette() -> Dictionary:
	if screen=='settings' and draft_settings.has('profile_theme') and not AppState.profile.is_empty():
		if draft_settings.profile_theme in AppState.profile.owned_items:
			var preview=ShopService.item(draft_settings.profile_theme)
			if not preview.is_empty(): return preview
	if not AppState.profile.is_empty():
		return ShopService.item(AppState.profile.equipped.theme)
	return {'background':'#F3F5F7','accent':'#527FA3'}

func _apply_theme() -> void:
	if SettingsService.current.get('reduce_motion',false) and _content_tween!=null and _content_tween.is_valid():
		_content_tween.kill()
		content.modulate.a=1.0
	background_palette=_palette()
	theme=ThemeFactory.build(SettingsService.current,background_palette)
	if footer!=null: footer.add_theme_font_size_override('font_size',18 if SettingsService.current.get('large_text',false) else 16)
	if background!=null: background.color=Color(background_palette.get('background','#F3F5F7'))
	_responsive()

func _profile_updated(_profile: Dictionary) -> void:
	if not _profile.is_empty(): last_profile_id=_profile.id
	_update_header()
	_apply_theme()

func _update_header() -> void:
	var active=not AppState.profile.is_empty()
	header_avatar.visible=active
	if active:
		var item=ShopService.item(AppState.profile.equipped.avatar)
		header_avatar.color=Color(item.get('color','#527FA3'))
		header_avatar.variant={'H':0,'O':2,'F':1,'R':2}.get(item.get('symbol','H'),0)
		header_avatar.frame=AppState.profile.equipped.frame
		header_avatar.frame_spec=ShopService.item(AppState.profile.equipped.frame)
		header_avatar.queue_redraw()
	header_profile.text=((AppState.profile.display_name if size.x<1000 else 'Bonjour, '+AppState.profile.display_name)) if active else 'Votre console pédagogique'
	header_points.text='%d pts' % AppState.profile.wallet.points if active else 'Hors ligne'

func _responsive() -> void:
	if shell==null: return
	var compact=size.x<1000 or size.y<600
	var margin=12 if compact else 28
	if shell_column!=null:shell_column.add_theme_constant_override('separation',10 if compact else 16)
	if footer!=null and screen=='game':
		footer.text='Flèches / joystick · Espace / face bas : interagir · P / Start : pause'
	if footer!=null and screen in ['home','shop','profiles','help']:
		footer.text='Flèches / joystick · Entrée / face bas : valider · Échap : retour'
	var horizontal=maxi(margin,int((size.x-1400)/2))
	for side in ['left','right']: shell.add_theme_constant_override('margin_'+side,horizontal)
	for side in ['top','bottom']: shell.add_theme_constant_override('margin_'+side,margin)
	if navigation!=null: navigation.fit(size.x-2*horizontal,SettingsService.current.get('large_text',false),compact)
	if screen=='home' and is_instance_valid(hero_grid):
		hero_grid.columns=2
		var compact_home=size.x<1100 or size.y<650
		hero_grid.add_theme_constant_override('h_separation',18 if compact_home else 36)
		if is_instance_valid(home_story):home_story.add_theme_constant_override('separation',8 if compact_home else 12)
		if home_labels.has('title'):
			home_labels.title.add_theme_font_size_override('font_size',(32 if compact_home else 42)+(2 if SettingsService.current.get('large_text',false) else 0))
			home_labels.kicker.visible=not compact_home
			home_labels.subtitle.visible=not compact_home
			home_labels.note.visible=not compact_home
			if home_labels.has('hint'):home_labels.hint.visible=not compact_home
			home_labels.progress.text=('0 / 3 · Sans sauvegarde' if compact_home and not AppState.profile.progress.started else '%d / 3 missions réalisées'%AppState.profile.progress.completed_missions.size())
			home_labels.description.text='Trois pannes. Un message à retrouver.' if compact_home else 'Un atelier en panne. Trois équipements à rétablir.\nÀ vous de retrouver le message et d’expliquer l’incident.'
			home_objectives.visible=not compact_home
		var hero_style=theme.get_stylebox('panel','HeroPanel').duplicate()
		hero_style.content_margin_left=18 if compact_home else 28
		hero_style.content_margin_right=18 if compact_home else 28
		hero_style.content_margin_top=12 if compact_home else 24
		hero_style.content_margin_bottom=12 if compact_home else 24
		hero_panel.add_theme_stylebox_override('panel',hero_style)
		hero_art.custom_minimum_size=Vector2(200 if compact_home else 420,170 if compact_home else (360 if size.y>=900 else 270))
		hero_panel.custom_minimum_size.y=minf(720,maxf(0,scroll.size.y-4))
	if screen=='game' and is_instance_valid(demo) and demo.is_inside_tree():demo._fit_minimum()
	if header_profile!=null:
		header_profile.add_theme_font_size_override('font_size',(18 if compact else 20)+(2 if SettingsService.current.get('large_text',false) else 0))
		header_profile.text=((AppState.profile.display_name if size.x<1000 else 'Bonjour, '+AppState.profile.display_name)) if not AppState.profile.is_empty() else 'Votre console pédagogique'
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
	SceneRouter.current_screen=next
	for child in content.get_children():
		if child==demo: child.hide()
		content.remove_child(child)
		if child!=demo: child.queue_free()
	responsive_grids.clear()
	hero_grid=null;hero_art=null;hero_panel=null;home_labels.clear();home_objectives=null;home_story=null
	if navigation!=null:
		navigation.visible=next in ['home','shop','profiles','settings','help'] and not (next=='settings' and settings_origin=='game') and not (next=='help' and parent_screen=='game')
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
	if secondary: label.add_theme_color_override('font_color',Color('#586674'))
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
	_title('À chacun son aventure','Chaque profil garde ses points, achats et progression.')
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
	_clear('editor')
	_title('Votre profil' if id.is_empty() else 'Modifier '+record.get('display_name','le profil'),'Pseudo : 1 à 16 caractères. Le clavier à l’écran fonctionne sans clavier physique.')
	var panel=_panel(content)
	name_edit=LineEdit.new()
	name_edit.name='profile_name'
	name_edit.text=record.get('display_name','Joueur '+str(ProfileService.profiles.size()+1))
	name_edit.max_length=16
	name_edit.select_all()
	name_edit.custom_minimum_size.y=48
	name_edit.select_all_on_focus=true
	name_edit.text_submitted.connect(func(_text): _submit_profile())
	panel.add_child(name_edit)
	_label(panel,'Avatar',18)
	var avatars=_grid(panel,180,3)
	for item in ShopService.catalog:
		if item.type!='avatar': continue
		if item.price!=0 and not (not record.is_empty() and item.id in record.owned_items): continue
		var button=_button(avatars,('✓ ' if editor_avatar==item.id else '')+item.name,func():
			editor_avatar=item.id
			for other in avatars.get_children(): other.text=other.text.trim_prefix('✓ ')
			var focus=get_viewport().gui_get_focus_owner()
			if focus is Button: focus.text='✓ '+focus.text,'avatar_'+item.id)
		button.tooltip_text='Avatar gratuit' if item.price==0 else 'Avatar possédé'
	var keyboard=Keyboard.new()
	panel.add_child(keyboard)
	keyboard.configure(name_edit)
	keyboard.submitted.connect(_submit_profile)
	keyboard.cancelled.connect(_back)
	if not id.is_empty():
		_button(content,'Supprimer ce profil',_delete_profile,'delete_profile')
	_responsive()
	for control in _focusables(content):
		if not control.focus_entered.is_connected(_ensure_focus_visible): control.focus_entered.connect(_ensure_focus_visible)
	_wire_navigation()
	if id.is_empty(): keyboard.get_child(0).get_child(0).call_deferred('grab_focus')
	else: name_edit.call_deferred('grab_focus')
	footer.text='Clavier virtuel : flèches + Entrée / face bas. Le clavier physique reste disponible.'

func _submit_profile() -> void:
	if is_instance_valid(modal): return
	if not _pending_created_id.is_empty():
		_select_profile(_pending_created_id)
		return
	var result: Dictionary
	if editor_id.is_empty():
		result=ProfileService.create_profile(name_edit.text,editor_avatar)
		if not result.ok and result.get('data') is Dictionary and result.data.has('id'):
			_pending_created_id=result.data.id
			_confirm('Profil créé, sélection à terminer',result.error+' Le profil est conservé. Réessayer sélectionnera ce profil sans en créer un deuxième.','Réessayer',func(): _select_profile(_pending_created_id))
			return
	else:
		if not _result(ProfileService.select_profile(editor_id)): return
		result=ProfileService.update_profile(name_edit.text,editor_avatar)
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
	hero_panel=PanelContainer.new()
	hero_panel.name='home_hero'
	hero_panel.theme_type_variation='HeroPanel'
	hero_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_child(hero_panel)
	hero_grid=GridContainer.new()
	hero_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	hero_grid.add_theme_constant_override('h_separation',36)
	hero_grid.add_theme_constant_override('v_separation',18)
	hero_panel.add_child(hero_grid)
	var story=VBoxContainer.new()
	home_story=story
	story.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	story.size_flags_vertical=Control.SIZE_EXPAND|Control.SIZE_SHRINK_CENTER
	story.add_theme_constant_override('separation',12)
	hero_grid.add_child(story)
	home_labels.kicker=_label(story,'EXPLORER · COMPRENDRE · RÉSOUDRE',15,true)
	home_labels.title=_label(story,'L’enquête CIEL',42)
	home_labels.subtitle=_label(story,'Le message du local technique',24)
	home_labels.description=_label(story,'Un atelier en panne. Trois équipements à rétablir.
À vous de retrouver le message et d’expliquer l’incident.',0,true)
	var done=AppState.profile.progress.completed_missions
	home_labels.progress=_label(story,'%d / 3 missions réalisées'%done.size(),20)
	var actions=HBoxContainer.new()
	story.add_child(actions)
	var started=AppState.profile.progress.started
	var primary=_button(actions,'Continuer' if started else 'Commencer',_continue_game if started else _new_game,'continue_game' if started else 'new_game')
	primary.theme_type_variation='PrimaryButton'
	primary.custom_minimum_size=Vector2(170,56)
	primary.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	var secondary=_button(actions,'Nouvelle partie' if started else 'Continuer',_new_game if started else _continue_game,'new_game' if started else 'continue_game')
	secondary.disabled=not started
	secondary.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	secondary.custom_minimum_size.x=220 if started else 155
	if not started:
		secondary.tooltip_text='Commencez une partie pour créer une progression.'
		home_labels.hint=_label(story,'Aucune partie enregistrée : choisissez Commencer.',16,true)
	var art_column=VBoxContainer.new()
	art_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	art_column.size_flags_vertical=Control.SIZE_EXPAND|Control.SIZE_SHRINK_CENTER
	hero_grid.add_child(art_column)
	hero_art=EnquiryArt.new()
	hero_art.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	hero_art.size_flags_vertical=Control.SIZE_EXPAND_FILL
	art_column.add_child(hero_art)
	var objectives=VBoxContainer.new()
	home_objectives=objectives
	objectives.add_theme_constant_override('separation',6)
	art_column.add_child(objectives)
	for mission in RewardService.missions:
		var title={'lighting':'Rétablir l’éclairage','lock':'Ouvrir le bureau','computer':'Retrouver le message'}.get(mission.id,mission.name)
		_label(objectives,('✓  ' if mission.id in done else '○  ')+title,16)
	home_labels.note=_label(story,'Données locales · points gagnés dans les missions',14,true)

func _navigation_destination(next: String) -> void:
	if next==screen or is_instance_valid(modal) or not SceneRouter.gameplay_allowed(): return
	if screen=='settings':
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
	footer.text='Flèches / ZQSD / joystick : déplacement   ·   Espace / face bas : interaction   ·   P / Start : pause'
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

func _shop() -> void:
	_title('Une touche personnelle','Des cosmétiques en points virtuels, sans achat réel.')
	var bar=_grid(content,250,3)
	var filter=OptionButton.new()
	filter.name='shop_filter'
	filter.custom_minimum_size.y=48
	for title in ['Tous les articles','Avatars','Thèmes','Cadres']: filter.add_item(title)
	filter.selected=shop_filter
	filter.item_selected.connect(func(index): shop_filter=index; _show_screen('shop'))
	bar.add_child(filter)
	_button(bar,'Catalogue' if shop_inventory else 'Mon inventaire',func(): shop_inventory=not shop_inventory; _show_screen('shop'),'shop_inventory')
	_label(bar,'Solde : %d points' % AppState.profile.wallet.points,22)
	var grid=_grid(content,290,3)
	var count=0
	for item in ShopService.catalog:
		if shop_filter>0 and item.type!=['','avatar','theme','frame'][shop_filter]: continue
		var owned=item.id in AppState.profile.owned_items
		if shop_inventory and not owned: continue
		var card=ProductCard.new()
		card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		card.configure(item,owned,AppState.profile.equipped.get(item.type,'')==item.id,AppState.profile.wallet.points>=item.price)
		card.action_requested.connect(_product_action)
		count+=1
	if count==0: _label(content,'Aucun article possédé dans cette catégorie.',0,true)

func _product_action(id: String) -> void:
	var item=ShopService.item(id)
	if item.is_empty(): _notify('Cet article est inconnu.'); return
	if id in AppState.profile.owned_items:
		if AppState.profile.equipped.get(item.type,'')==id: _notify('Cet article est déjà équipé.'); return
		if _result(ShopService.equip(id),'✓ « '+item.name+' » équipé',func(): _product_action(id)): _show_screen('shop')
	elif AppState.profile.wallet.points<item.price:
		var maximum=0
		for mission in RewardService.missions: maximum+=mission.reward
		_confirm('Points insuffisants','Résolvez les trois missions de l’enquête pour gagner jusqu’à %d points par profil. Une mission ne récompense qu’une seule fois. Cet article coûte %d points ; votre solde est de %d.' % [maximum,item.price,AppState.profile.wallet.points],'Compris',func(): pass)
	else:
		_confirm('Acheter « '+item.name+' » ?','Prix : %d points virtuels. Nouveau solde : %d points. Aucun argent réel.' % [item.price,AppState.profile.wallet.points-item.price],'Acheter',func():
			if _result(ShopService.purchase(id),'✓ Achat réussi et enregistré',func(): _product_action(id)): _show_screen('shop'))

func _settings() -> void:
	_title('Paramètres','Appliquer enregistre. Annuler restaure les aperçus.')
	var categories=OptionButton.new()
	categories.name='settings_categories'
	categories.custom_minimum_size=Vector2(320,48)
	categories.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	for title in ['Audio','Affichage','Accessibilité','Commandes','Apparence','Données','À propos']: categories.add_item(title)
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
			_toggle(panel,'Plein écran','fullscreen')
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
			_label(panel,'Thèmes possédés · aperçu temporaire',22)
			for item in ShopService.catalog:
				if item.type=='theme' and item.id in AppState.profile.owned_items:
					_button(panel,('✓ ' if draft_settings.get('profile_theme',AppState.profile.equipped.theme)==item.id else '')+item.name,func():
						draft_settings.profile_theme=item.id
						_apply_theme()
						_show_screen('settings'),'theme_'+item.id)
			_label(panel,'D’autres thèmes sont disponibles dans la boutique locale.',0,true)
		5:
			_label(panel,'Progression de l’enquête',22)
			_button(panel,'Réinitialiser la progression',_reset_progress,'reset_progress')
			_label(panel,'Les achats, le solde et les identifiants des récompenses sont conservés. Supprimer un profil efface l’ensemble de ses données.',0,true)
		6:
			_label(panel,'Console CIEL · logiciel '+str(ProjectSettings.get_setting('application/config/version'))+'\nGodot 4.6.3 · rendu Compatibility\nProjet scolaire bac pro CIEL',22)
			_label(panel,'Logiciel : Loghan\nConstruction et assemblage : binôme, nom à compléter\nDonnées locales ; aucune connexion requise.',0,true)
			_label(panel,'Données : '+PlatformService.user_data_directory()+'\nJournaux : '+PlatformService.application_log_directory(),0,true)
			_button(panel,'Aide / Crédits',func(): parent_screen='settings'; _show_screen('help'),'settings_help')
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
	footer.text='Q / E ou boutons supérieurs : catégorie   ·   Échap : annuler   ·   Aperçus temporaires'

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
	_label(panel,'Flèches : navigation et déplacement\nEntrée : valider · Échap : retour\nP : pause de l’enquête\nQ / E : catégories (hors saisie)\nZQSD : déplacement · Espace : interagir')
	_label(panel,'À la manette',24)
	_label(panel,'Croix ou joystick gauche : naviguer / se déplacer\nBouton de face bas : valider / interagir\nBouton de face droit : retour\nStart / Menu : pause · LB / RB : catégories\nLes noms A/B, Croix/Rond dépendent de la manette. Le test montre les entrées réellement reçues.')
	_button(panel,'Test des commandes',func(): controls_origin='help'; _show_screen('controls'),'help_controls')
	var credits=_panel(content)
	_label(credits,'Crédits & licences',24)
	_label(credits,'Logiciel : Loghan\nConstruction et assemblage : binôme, nom à compléter\nFormes et illustrations originales : CC0 1.0\nSons originaux : CC0 1.0\nMoteur Godot et police intégrée : licences fournies dans assets/LICENSES.md et assets/licenses/.')
	_label(credits,'L’enquête « Le message du local technique » comporte trois défis : boucle électrique fermée, liaison de commande d’une serrure et diagnostic vidéo. Simulations fictives uniquement ; le circuit 5 V ne constitue pas un tutoriel de câblage secteur.',0,true)
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
		for action in ['ui_accept','ui_cancel','game_interact','pause','tab_previous','tab_next']:
			if action in ['game_interact','pause','tab_previous','tab_next'] and get_viewport().gui_get_focus_owner() is LineEdit: continue
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
			if screen=='settings': settings_category=posmod(settings_category+step,7)
			else: shop_filter=posmod(shop_filter+step,4)
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
