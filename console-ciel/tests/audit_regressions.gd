extends SceneTree
## Régressions de l'audit : données isolées, moteur et interfaces natifs.
const Mapping=preload('res://scripts/input_setup.gd')
var checks=0
var failures=0
var fixture=''
var app
var saves
var profiles
var settings
var shop
var investigation
var state
func _initialize(): call_deferred('_run')
func check(ok: bool,message: String):
	checks+=1
	if not ok: failures+=1
	print(('OK ' if ok else 'AUDIT_FAIL ')+message)
func frames(count: int):
	for i in range(count): await process_frame
func find(node: Node,key: String) -> Node:
	if str(node.name)==key: return node
	for child in node.get_children():
		var found=find(child,key)
		if found!=null: return found
	return null
func remove_tree(path: String):
	var dir=DirAccess.open(path)
	if dir==null: return
	for name in dir.get_files(): DirAccess.remove_absolute(path.path_join(name))
	for name in dir.get_directories(): remove_tree(path.path_join(name))
	DirAccess.remove_absolute(path)
func _run():
	await process_frame
	saves=root.get_node('SaveService'); profiles=root.get_node('ProfileService')
	settings=root.get_node('SettingsService'); shop=root.get_node('ShopService')
	investigation=root.get_node('InvestigationService'); state=root.get_node('AppState')
	fixture='user://tests/audit_'+str(Time.get_ticks_usec())
	saves.root_path=fixture; settings.storage_root=fixture
	check(shop.load_catalog().ok and root.get_node('RewardService').load_rules().ok,'Définitions livrées')
	check(profiles.create_profile('Audit').ok and profiles.start_game().ok,'Profil isolé et nouvelle enquête')
	check(investigation.submit_lighting(['source_switch','switch_lamp','lamp_return']).ok,'Éclairage par règles réelles')
	var modern=state.profile.duplicate(true)
	modern.progress.erase('investigation_version')
	check(not saves.validate_profile(modern).ok,'Progression récente tronquée refusée sans migration destructive')
	var legacy=state.profile.duplicate(true)
	legacy.progress={'started':true,'room_id':'room_01','checkpoint_id':'lighting','completed_missions':['lighting']}
	check(saves.validate_profile(legacy).ok and saves.validate_profile(legacy).migration_required,'Ancien prototype réel toujours migrable')
	var cfg=ConfigFile.new()
	cfg.set_value('meta','schema_version',true)
	for key in settings.defaults: cfg.set_value('settings',key,settings.defaults[key])
	var bad_cfg=fixture.path_join('invalid.cfg')
	cfg.save(bad_cfg)
	check(not settings._read(bad_cfg).ok,'Version booléenne CFG refusée')
	cfg.set_value('meta','schema_version',1.0);cfg.save(bad_cfg)
	check(not settings._read(bad_cfg).ok,'Version flottante CFG refusée')
	var mapping=JSON.parse_string(FileAccess.get_file_as_string('res://data/controller_mapping.json'))
	mapping.schema_version=true
	check(not Mapping.validate_mapping(mapping).ok,'Version booléenne du mapping refusée')
	for observation in ['badge','power','command','link']: check(investigation.observe('lock',observation).ok,'Observation serrure '+observation)
	check(investigation.submit_lock('control_link','reconnect_control').ok,'Serrure par diagnostic')
	for observation in ['pc','display','no_signal']: check(investigation.observe('computer',observation).ok,'Observation ordinateur '+observation)
	for item in ['power','video']: check(investigation.check_computer(item).ok,'Vérification ordinateur '+item)
	check(investigation.submit_computer(['power','video'],'video_disconnected','reconnect_video').ok,'Troisième mission et 150 points')
	app=load('res://scenes/main.tscn').instantiate();root.add_child(app)
	await frames(18)
	app._select_profile(state.profile.id);await frames(6)
	app._continue_game();await frames(8)
	var game=app.demo
	check(game.overlay_kind=='conclusion','Reprise terminée ouvre bilan')
	game._confirm_replay();await frames(4)
	game.handle_back();await frames(4)
	check(game.overlay_kind=='conclusion' and game.paused,'Échap annule Rejouer et restitue le bilan')
	game._close_overlay();await frames(3)
	check(game.modal_content.get_child_count()==0 and game.challenge==null,'Panneaux fermés libérés sans conserver de défi masqué')
	profiles.start_game()
	game._interaction_requested('lighting');await frames(5)
	var old=weakref(game.challenge)
	game._close_overlay();await frames(3)
	check(old.get_ref()==null,'Défi fermé réellement libéré')
	game._return_to_menu();await frames(5)
	check(shop.purchase('theme_sable').ok,'Thème acheté par transaction normale')
	app.settings_category=4;app._navigate('settings');await frames(5)
	var button=find(app,'theme_theme_sable') as Button
	check(button!=null,'Choix de thème possédé')
	if button!=null: button.pressed.emit()
	await frames(5)
	button=find(app,'theme_theme_sable') as Button
	check(button!=null and button.text.begins_with('✓ '),'Aperçu de thème possède un état sélectionné exact')
	app._cancel_settings();await frames(3)
	check(state.profile.equipped.theme=='theme_brume','Annuler conserve le thème enregistré')
	var controllers=root.get_node('ControllerService')
	controllers.debug_set_devices([0])
	app._continue_game();await frames(5)
	app.demo.request_pause();await frames(4)
	find(app.demo,'pause_settings').pressed.emit();await frames(5)
	app.draft_settings.reduce_transparency=not settings.committed.reduce_transparency
	settings.preview(app.draft_settings)
	app._request_quit();await frames(4)
	controllers.debug_connection_changed(0,false);await frames(2)
	find(app,'quit_keep').pressed.emit();await frames(5)
	app._cancel_settings();await frames(6)
	check(app.demo.overlay_kind=='controller_pause','Déconnexion pendant fermeture de réglages transmise au jeu conservé')
	app.demo._resume_controller();await frames(3)
	check(app.demo.overlay_kind=='pause' and app.demo.paused,'Reprise explicite restitue la pause des paramètres')
	app.demo._return_to_menu();await frames(4)
	controllers.debug_clear_devices()
	app._open_editor(state.profile.id);await frames(4)
	app.name_edit.text='';app.name_edit.grab_focus()
	for entry in [[KEY_P,112],[KEY_SPACE,32],[KEY_E,101]]:
		root.get_node('SceneRouter').lock_until_release()
		var event=InputEventKey.new()
		event.keycode=entry[0];event.unicode=entry[1];event.pressed=true
		Input.parse_input_event(event);await frames(1)
		event=event.duplicate();event.pressed=false;Input.parse_input_event(event)
	check(app.name_edit.text=='p e','Saisie P, espace et E préservée pendant verrou de transition')
	app.name_edit.text='ABC';app.name_edit.caret_column=3
	var virtual=find(app,'key_Effacer') as Button
	virtual.pressed.emit();virtual.pressed.emit()
	check(app.name_edit.text=='A' and app.name_edit.caret_column==1,'Effacement virtuel répété conserve le caret')
	var modal=load('res://scripts/ui/confirmation_dialog.gd').new()
	modal.open(app,'Audit','Disposition interrompue','Compris',func(): pass)
	await frames(1)
	app.remove_child(modal)
	await frames(3)
	modal.free()
	check(app.name_edit.focus_mode==Control.FOCUS_ALL,'Suppression inattendue du dialogue restaure les contrôles survivants')
	check(true,'Dialogue retiré pendant attente de disposition sans erreur de script')
	var base=saves.root_path
	var blocker=fixture.path_join('blocked')
	var file=FileAccess.open(blocker,FileAccess.WRITE);file.store_string('fixture');file.close()
	saves.root_path=blocker
	app._show_screen('profiles');await frames(4)
	check(app.screen=='fatal' and find(app,'fatal_retry')!=null,'Liste inaccessible ouvre une erreur et un vrai réessai')
	saves.root_path=base
	app.queue_free();await frames(4)
	state.clear_profile()
	remove_tree(ProjectSettings.globalize_path(fixture))
	print('AUDIT_REGRESSIONS : %d assertions, %d échec(s).'%[checks,failures])
	quit(0 if failures==0 else 1)
