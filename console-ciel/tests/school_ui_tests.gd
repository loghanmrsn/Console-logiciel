extends "res://tests/code_chapter_ui_tests.gd"
const School = preload("res://scripts/game/school_layout.gd")
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
	test_root = "user://tests/school_%s" % Time.get_ticks_usec()
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	_check(profiles.use_dev_profile().ok, "Profil isolé")
	profile_id = str(state.profile.id)
	var progress: Dictionary = state.profile.progress.duplicate(true)
	progress.room_id = "courtyard"
	progress.checkpoint_id = "from_first"
	_check(investigation._save_progress(progress).ok, "Ville préparée")
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(25)
	app._show_screen("home")
	await _frames(4)
	await _activate("continue_game")
	var before: Dictionary = state.profile.duplicate(true)
	_check(not hotel.board_bus("unknown").ok and state.profile == before, "Arrêt inconnu refusé sans mutation")
	app.demo.hotel_story._show_bus()
	await _frames(4)
	_check(_find("hotel_bus_board") != null and _find("school_bus_board") != null, "Les deux arrêts sont proposés")
	await _capture("bus_destinations_challenge")
	saves.simulate_write_failure = true
	await _activate("school_bus_board")
	_check(state.profile == before and app.demo.overlay_kind == "hotel_error", "Échec de trajet atomique")
	saves.simulate_write_failure = false
	app.demo.hotel_story._show_bus()
	await _activate("school_bus_board")
	_check(state.profile.progress.room_id == "school_stop", "Bus vers le lycée")
	_check(state.profile.wallet == before.wallet and state.profile.progress.completed_missions == before.progress.completed_missions, "Aucune perte de points ou de missions")
	await _frames(8)
	await _approach("school_enter")
	await _capture("lycee_facade_challenge")
	var custom: Dictionary = settings.current.duplicate(true)
	custom.bindings = {"game_map": {"key": KEY_M}, "pause": {"key": KEY_F10}}
	_check(settings.preview(custom).ok, "Personnaliser la carte et la pause")
	await _frames(5)
	_check("M" in str(_find("campus_map_toggle").text), "La carte affiche son nouveau raccourci")
	_check("F10" in str(_find("game_pause").text), "La pause affiche son nouveau raccourci")
	settings.cancel_preview()
	await _frames(5)
	_check("P" in str(_find("game_pause").text), "Annuler restaure aussi la légende")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "hotel_travel", "Porte du lycée accessible")
	# Travel has its own save-before-move contract; exercise that service then restore.
	app.demo._close_overlay()
	_check(hotel.travel("school_cyber").ok, "Entrée dans la salle cyber")
	app.demo.world.restore_progress(state.profile.progress)
	app.demo.world.restore_checkpoint()
	await _frames(8)
	await _approach("school_course")
	await _capture("lycee_cyber_challenge")
	for prop in School.furniture_specs("school_cyber"):
		_check(not _point_clear(prop.rect.get_center()), "Mobilier solide : " + str(prop.kind))
	for target in School.interactions("school_cyber"):
		await _approach(target.id)
		_check(app.demo.world.target_id == target.id, "Cible atteignable : " + target.id)
		await _key(KEY_SPACE)
		_check(not app.demo.overlay_kind.is_empty(), "Interaction : " + target.id)
		app.demo._close_overlay()
	_check(saves.validate_profile(state.profile).ok and saves.read_profile(profile_id).data == state.profile, "Sauvegarde du lycée valide et persistante")
	_check(profiles.select_profile(profile_id).ok and state.profile.progress.room_id == "school_cyber", "Reprise au lycée")
	_check(hotel.travel("school_stop").ok and hotel.return_bus().ok, "Retour au parvis puis en ville")
	_check(hotel.board_bus().ok and state.profile.progress.room_id == "ctf_bus_stop", "Ancien arrêt CTF conservé")
	await _finish()

func _approach(id: String) -> void:
	for target in School.interactions(app.demo.world.room_id):
		if target.id != id: continue
		_check(_point_clear(target.at), "Accès libre : " + id)
		app.demo.world.player.position = target.at
		app.demo.world.player.reset_physics_interpolation()
		await _physics_frames(4)
		await _frames(4)
		_check(app.demo.world.target_id == id, "Cible physique : " + id)
		return
	_check(false, "Cible absente : " + id)
