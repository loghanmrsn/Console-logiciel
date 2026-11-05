extends "res://tests/school_ui_tests.gd"
## Entry, two choices, atomic escort, bounded real animation and both return routes.
func _initialize() -> void:
	Engine.max_fps=60
	super._initialize()
func _run() -> void:
	await process_frame
	saves=root.get_node("SaveService")
	profiles=root.get_node("ProfileService")
	settings=root.get_node("SettingsService")
	state=root.get_node("AppState")
	investigation=root.get_node("InvestigationService")
	router=root.get_node("SceneRouter")
	controllers=root.get_node("ControllerService")
	controllers.debug_set_devices([0])
	var hotel=root.get_node("HotelService")
	test_root="user://tests/reception_%s" % Time.get_ticks_usec()
	saves.root_path=test_root
	settings.storage_root=test_root
	state.clear_profile()
	captures="--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	_check(profiles.use_dev_profile().ok,"Profil isolé")
	profile_id=state.profile.id
	var doc: Dictionary=state.profile.duplicate(true)
	doc.progress.room_id="school_stop"
	doc.progress.checkpoint_id="school_arrival"
	doc.progress.erase("school_guided")
	doc.progress.erase("school_wires")
	state.commit_profile(saves.write_profile(doc).data)
	var invalid: Dictionary=state.profile.duplicate(true)
	invalid.progress.school_guided="yes"
	_check(not saves.validate_profile(invalid).ok,"Accompagnement mal formé refusé")
	_check(not hotel.escort_to_workshops().ok,"Accompagnement impossible depuis le parvis")
	_check(not hotel.travel("school_cyber").ok,"La porte extérieure ne mène plus à la salle cyber")
	app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(25)
	app._show_screen("game")
	await _frames(8)
	if app.demo.campus_map.expanded: app.demo.campus_map.toggle_map()
	for spec in School.furniture_specs("school_stop"):
		_check(spec.kind!="sign","Grande pancarte du parvis supprimée")
	for spec in preload("res://scripts/game/town_layout.gd").props():
		_check(spec.kind!="campus_sign","Grande pancarte supprimée aussi en ville")
	await _approach("school_enter")
	await _capture("lycee_sans_pancarte")
	await _key(KEY_SPACE)
	_check(_find("hotel_travel_go")!=null,"Porte d’accueil accessible au clavier")
	await _activate("hotel_travel_go")
	_check(app.demo.world.room_id=="school_reception" and state.profile.progress.room_id=="school_reception","Entrée enregistrée à l’accueil")
	await _frames(8)
	for spec in School.furniture_specs("school_reception"):
		_check(not _point_clear(spec.rect.get_center()),"Mobilier d’accueil solide : "+spec.kind)
	var person := preload("res://scripts/game/npc_catalog.gd").find("npc_school_supervisor")
	_check(person.name=="Surveillant" and person.hairstyle=="bun","Identité de la surveillante")
	_check(not _point_clear(person.at-Vector2(0,4)),"Surveillante solide")
	_check(_point_clear(person.approach),"Approche de la surveillante libre")
	app.demo.world.player.position=person.approach
	app.demo.world.player.reset_physics_interpolation()
	await _physics_frames(5)
	await _frames(5)
	await _capture("accueil_surveillance")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind=="school_guide","Dialogue de choix ouvert")
	_check(_find("school_guide_go")!=null and _find("school_guide_leave").text=="Rien","Deux choix explicites")
	var before: Dictionary=state.profile.duplicate(true)
	await _activate("school_guide_leave",true)
	_check(app.demo.overlay_kind.is_empty() and state.profile==before,"Rien ferme sans déplacement ni écriture")
	await _key(KEY_SPACE)
	saves.simulate_write_failure=true
	await _activate("school_guide_go")
	_check(app.demo.overlay_kind=="hotel_error" and state.profile==before and app.demo.world.room_id=="school_reception","Échec disque : ni animation ni déplacement")
	saves.simulate_write_failure=false
	app.demo.hotel_story.show_school_supervisor()
	root.size=Vector2i(800,480)
	await _frames(10)
	_check(_find("school_guide_go").is_visible_in_tree() and _find("school_guide_leave").is_visible_in_tree(),"Choix visibles sur petit écran")
	await _capture("surveillant_choix_compact")
	root.size=Vector2i(1280,720)
	await _frames(5)
	var values: Dictionary=settings.committed.duplicate(true)
	values.reduce_motion=false
	settings.apply_settings(values)
	await _activate("school_guide_go")
	_check(app.demo.overlay_kind=="school_escort","Animation lancée après confirmation")
	var panel=app.demo.modal_content.get_node("school_escort_panel")
	_check(panel.DURATION<=3 and panel.DURATION>0,"Durée nominale inférieure à trois secondes")
	_check(state.profile.progress.room_id=="school_passage" and app.demo.overlay_kind=="school_escort","Destination sauvée avant la présentation")
	_check(saves.read_profile(profile_id).data==state.profile,"Interruption : reprise déjà persistée au couloir")
	_check(state.profile.progress.school_guided and state.profile.progress.get("school_wires",{}).is_empty(),"Accompagnement sans résoudre le câblage")
	_check(state.profile.wallet==before.wallet and state.profile.rewarded_missions==before.rewarded_missions,"Aucun coût ni récompense")
	var already: Dictionary=state.profile.duplicate(true)
	_check(not hotel.escort_to_workshops().ok and state.profile==already,"Confirmation double sans effet")
	# Deterministic samples from the same live panel, before its natural timing run.
	panel.set_process(false)
	panel.advance(.4-panel.elapsed)
	var start: Vector2=panel.scene.player.position
	await _capture("accompagnement_escalier")
	panel.advance(.45)
	_check(panel.scene.player.position.y<start.y and panel.scene.player.position.x>start.x,"Le joueur monte réellement les marches")
	_check(panel.scene.guide.position.x>panel.scene.player.position.x,"La surveillante ouvre la marche")
	panel.advance(.65)
	_check("couloir" in panel.status.text,"Deuxième plan : couloir du lycée")
	await _capture("accompagnement_couloir")
	panel.finish()
	panel.finish()
	await _frames(8)
	_check(app.demo.world.room_id=="school_passage" and app.demo.overlay_kind.is_empty(),"Arrivée unique au couloir des ateliers")
	_check(_point_clear(app.demo.world.player.position),"Arrivée sans collision")
	_check(profiles.select_profile(profile_id).ok and state.profile.progress.room_id=="school_passage","Reprise au bon couloir")
	await _capture("arrivee_ateliers")
	_check(hotel.travel("school_cyber").ok,"Atelier informatique accessible depuis le couloir")
	_check(hotel.travel("school_reception").ok,"Retour informatique vers l’accueil")
	await _restore_reception()
	# Natural clock, no advance/skip calls, normal motion: measure total duration.
	app.demo.hotel_story.show_school_supervisor()
	var started := Time.get_ticks_usec()
	app.demo.hotel_story._start_school_escort()
	while app.demo.overlay_kind=="school_escort" and Time.get_ticks_usec()-started<4000000: await process_frame
	var duration := (Time.get_ticks_usec()-started)/1000000.0
	_check(app.demo.world.room_id=="school_passage" and duration<=3.0,"Animation naturelle terminée en trois secondes maximum : %.3f" % duration)
	_check(hotel.travel("school_reception").ok,"Retour par l’escalier d’accueil")
	await _restore_reception()
	app.demo.hotel_story.show_school_supervisor()
	app.demo.hotel_story._start_school_escort()
	await _frames(4)
	panel=app.demo.modal_content.get_node("school_escort_panel")
	var elapsed: float=panel.elapsed
	app.demo.controller_lost("Test de déconnexion")
	await _frames(12)
	_check(panel.elapsed==elapsed,"Déconnexion : animation suspendue, sans perdre l’arrivée")
	app.demo._resume_controller()
	await _frames(5)
	_check(panel.elapsed>elapsed,"Reprise explicite de l’animation")
	app.demo.handle_back()
	await _frames(5)
	_check(app.demo.world.room_id=="school_passage","Échap termine proprement l’accompagnement")
	_check(hotel.travel("school_reception").ok,"Retour pour l’accessibilité")
	await _restore_reception()
	values.reduce_motion=true
	settings.apply_settings(values)
	app.demo.hotel_story.show_school_supervisor()
	app.demo.hotel_story._start_school_escort()
	await _frames(5)
	_check(app.demo.world.room_id=="school_passage" and app.demo.overlay_kind.is_empty(),"Animations réduites : arrivée directe")
	_check(hotel.travel("school_reception").ok and hotel.travel("school_stop").ok,"Sortie par accueil et parvis")
	# Both straight hotel flights and both landing views share one renderer.
	for view in [{"room":"building_02","checkpoint":"hall_stairs","at":Vector2(4190,3510),"image":"hotel_deux_escaliers_droits"},{"room":"hotel_stairs_1","checkpoint":"stairs_from_hall","at":Vector2(800,780),"image":"hotel_palier_droit"}]:
		var copy: Dictionary=state.profile.duplicate(true)
		copy.progress.room_id=view.room
		copy.progress.checkpoint_id=view.checkpoint
		state.commit_profile(saves.write_profile(copy).data)
		await _restore_reception()
		app.demo.world.player.position=view.at
		app.demo.world.player.reset_physics_interpolation()
		app.demo.world.camera.zoom=Vector2.ONE*.65
		await _frames(8)
		await _capture(view.image)
	if captures:
		var output := FileAccess.open(OS.get_environment("CIEL_CAPTURE_DIR").path_join("escort_timing.json"),FileAccess.WRITE)
		output.store_string(JSON.stringify({"natural_duration_seconds":duration,"maximum_seconds":3,"deterministic_stairs_and_corridor_captures":true}));output.close()
	await _finish()
func _restore_reception() -> void:
	app.demo._close_overlay()
	app.demo.world.restore_progress(state.profile.progress)
	app.demo.world.restore_checkpoint()
	await _frames(8)
func _capture(id: String) -> void:
	await super._capture(id+"_challenge")
