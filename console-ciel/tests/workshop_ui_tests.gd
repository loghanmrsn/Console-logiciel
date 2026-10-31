extends "res://tests/school_ui_tests.gd"
func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	settings = root.get_node("SettingsService")
	state = root.get_node("AppState")
	investigation = root.get_node("InvestigationService")
	router = root.get_node("SceneRouter")
	controllers = root.get_node("ControllerService")
	controllers.debug_set_devices([0])
	var hotel = root.get_node("HotelService")
	test_root = "user://tests/workshop_%s" % Time.get_ticks_usec()
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	_check(profiles.use_dev_profile().ok, "Profil de test")
	profile_id = state.profile.id
	var progress: Dictionary = state.profile.progress.duplicate(true)
	progress.room_id = "school_cyber"
	progress.checkpoint_id = "school_entry"
	_check(investigation._save_progress(progress).ok, "Arrivée lycée")
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(25)
	app._show_screen("home")
	await _frames(4)
	await _activate("continue_game")
	_check(hotel.travel("school_hall").ok, "Premier couloir")
	var before: Dictionary = state.profile.duplicate(true)
	_check(not hotel.travel("school_passage").ok and state.profile == before, "Porte verrouillée avant mission")
	await _approach("school_secure")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "hotel_travel", "Panneau câblage ouvert")
	await _capture("porte_cablage_challenge")
	await _activate("hotel_coffee_A")
	saves.simulate_write_failure = true
	await _activate("hotel_coffee_3")
	_check(state.profile == before, "Erreur disque sans connexion perdue ni ouverture")
	saves.simulate_write_failure = false
	await _activate("hotel_coffee_1")
	_check(state.profile == before, "Mauvaise paire refusée")
	for pair in [["A","3"],["B","2"],["C","1"]]:
		if pair[0] != "A": await _activate("hotel_coffee_"+pair[0])
		await _activate("hotel_coffee_"+pair[1])
	_check(state.profile.progress.get("school_wires",{}).size() == 3, "Trois paires enregistrées")
	await _activate("hotel_travel_go")
	_check(state.profile.progress.room_id == "school_passage", "Passage déverrouillé")
	await _approach("school_workshop")
	await _capture("couloir_atelier_challenge")
	await _key(KEY_SPACE)
	await _activate("hotel_travel_go")
	_check(state.profile.progress.room_id == "school_workshop", "Atelier accessible par porte à gauche")
	await _approach("school_3d")
	await _capture("atelier_equipements_challenge")
	for prop in School.furniture_specs("school_workshop"):
		_check(not _point_clear(prop.rect.get_center()), "Collision équipement : " + prop.kind)
	_check(profiles.select_profile(profile_id).ok and state.profile.progress.room_id == "school_workshop", "Reprise dans l’atelier")
	_check(state.profile.wallet == before.wallet and state.profile.progress.completed_missions == before.progress.completed_missions, "Enquête et points conservés")
	_check(hotel.travel("school_passage").ok and hotel.travel("school_hall").ok and hotel.travel("school_passage").ok, "Allers-retours sans refaire le câblage")
	await _finish()
