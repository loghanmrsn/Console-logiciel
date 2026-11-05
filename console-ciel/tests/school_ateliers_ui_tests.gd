extends "res://tests/school_ui_tests.gd"
## Real room transitions, persistence, equipment actions and native render captures.
const Ateliers = preload("res://scripts/game/school_ateliers.gd")
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
	var hotel = root.get_node("HotelService")
	test_root="user://tests/ateliers_%s" % Time.get_ticks_usec()
	saves.root_path=test_root
	settings.storage_root=test_root
	state.clear_profile()
	captures="--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	_check(profiles.use_dev_profile().ok,"Profil isolé")
	profile_id=state.profile.id
	var progress: Dictionary=state.profile.progress.duplicate(true)
	progress.room_id="school_cyber"
	progress.checkpoint_id="school_entry"
	_check(investigation._save_progress(progress).ok,"Ancienne sauvegarde cyber compatible")
	var original: Dictionary=state.profile.duplicate(true)
	# A forged checkpoint cannot bypass the existing secure door.
	for room in Ateliers.NEW_IDS:
		var locked: Dictionary=original.duplicate(true)
		locked.progress.room_id=room
		locked.progress.checkpoint_id=room+"_entry"
		_check(not saves.validate_profile(locked).ok,"Accès protégé : "+room)
	app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(25)
	app._show_screen("game")
	await _frames(10)
	app.demo._close_overlay()
	await _inspect("school_cyber")
	_check(hotel.travel("school_hall").ok,"Entrée du couloir")
	for pair in [["A","3"],["B","2"],["C","1"]]: _check(hotel.connect_school_wire(pair[0],pair[1]).ok,"Câblage conservé")
	_check(hotel.travel("school_passage").ok,"Couloir des ateliers")
	await _restore()
	await _approach("school_workshop")
	await _key(KEY_SPACE)
	var before: Dictionary=state.profile.duplicate(true)
	saves.simulate_write_failure=true
	await _activate("hotel_travel_go")
	_check(state.profile==before and app.demo.world.room_id=="school_passage","Échec disque : aucune téléportation")
	saves.simulate_write_failure=false
	app.demo._close_overlay()
	for room in ["school_workshop"]:
		await _approach(room)
		await _key(KEY_SPACE)
		await _activate("hotel_travel_go")
		_check(state.profile.progress.room_id==room and app.demo.world.room_id==room,"Porte jouable : "+room)
		await _inspect(room)
		_check(profiles.select_profile(profile_id).ok and state.profile.progress.room_id==room,"Reprise persistante : "+room)
		await _approach("school_passage_return")
		await _controller_interact()
		_check(app.demo.overlay_kind=="hotel_travel","Porte par bouton 0 : "+room)
		await _activate("hotel_travel_go")
		_check(state.profile.progress.room_id=="school_passage","Retour au couloir : "+room)
		_check(_point_clear(app.demo.world.player.position),"Retour sans collision")
	_check(state.profile.wallet==original.wallet and state.profile.rewarded_missions==original.rewarded_missions,"Exploration sans récompense ni coût ajouté")
	_check(saves.read_profile(profile_id).data==state.profile,"Dernier passage écrit sur disque")
	await _capture("couloir_porte_unique_challenge")
	root.size=Vector2i(800,480)
	await _frames(10)
	await _approach("school_workshop")
	await _controller_interact()
	_check(_find("hotel_travel_go").is_visible_in_tree(),"Porte disponible en 800 × 480")
	await _capture("atelier_porte_compact_challenge")
	await _finish()
func _restore() -> void:
	app.demo.world.restore_progress(state.profile.progress)
	app.demo.world.restore_checkpoint()
	await _frames(8)
func _inspect(room: String) -> void:
	await _frames(8)
	for item in School.furniture_specs(room): _check(not _point_clear(item.rect.get_center()),"Équipement solide : "+room+"/"+item.kind)
	for target in Ateliers.targets(room):
		if target.id=="school_passage_return": continue
		await _approach(target.id)
		await _key(KEY_SPACE)
		_check(not app.demo.overlay_kind.is_empty(),"Observation de l’équipement : "+target.id)
		app.demo._close_overlay()
	# Capture the full cutaway and an eye-level play area, using the real renderer.
	var size: Vector2=School.extent(room)
	app.demo.world.player.position=Ateliers.entry(room)
	app.demo.world.player.reset_physics_interpolation()
	var cam: Camera2D=app.demo.world.camera
	var old_zoom := cam.zoom
	var old_offset := cam.offset
	cam.zoom=Vector2.ONE*minf(1100.0/size.x,510.0/size.y)
	cam.offset=Vector2.ZERO
	cam.reset_smoothing()
	await _frames(8)
	await _capture(room+"_ensemble_challenge")
	cam.zoom=old_zoom
	var focus: Vector2={"school_workshop":Vector2(820,600),"school_tne":Vector2(1200,900),"school_meeting":Vector2(1090,700),"school_cyber":Vector2(1050,1020),"school_fed":Vector2(1550,1060)}[room]
	app.demo.world.player.position=focus
	app.demo.world.player.reset_physics_interpolation()
	cam.offset=old_offset
	cam.reset_smoothing()
	await _frames(8)
	await _capture(room+"_jeu_challenge")
func _controller_interact() -> void:
	if not router.gameplay_allowed(): await create_timer(.24).timeout
	var event := InputEventJoypadButton.new()
	event.device=controllers.active_device
	event.button_index=JOY_BUTTON_A
	event.pressed=true
	Input.parse_input_event(event)
	await _frames(2)
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	await _frames(4)
