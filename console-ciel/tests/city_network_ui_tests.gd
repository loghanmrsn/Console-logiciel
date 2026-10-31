extends "res://tests/school_ui_tests.gd"
const CityCatalog = preload("res://scripts/game/city_network_catalog.gd")
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
	var city = root.get_node("CityService")
	test_root = "user://tests/city_network_ui_%s" % Time.get_ticks_usec()
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var made: Dictionary = profiles.create_profile("City CIEL")
	_check(made.ok,"Profil normal isolé")
	profile_id = made.data.id
	var doc: Dictionary = load("res://scripts/services/dev_profile.gd").build().data
	doc.id = profile_id
	doc.display_name = "City CIEL"
	doc.role = "player"
	doc.wallet.points = 0
	doc.progress.school_wires = saves.COFFEE_WIRES.duplicate()
	doc.progress.room_id = "school_workshop"
	doc.progress.checkpoint_id = "school_workshop_entry"
	state.commit_profile(saves.write_profile(doc).data)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(25)
	app._show_screen("home")
	await _frames(4)
	await _activate("continue_game")
	await create_timer(.25).timeout
	app.demo.world.player.position = Vector2(140,730)
	app.demo.world.player.reset_physics_interpolation()
	Input.action_press("game_left")
	await _physics_frames(45)
	Input.action_release("game_left")
	await _physics_frames(3)
	_check(app.demo.world.player.position.x >= 49 and app.demo.world.player.position.x < 70,"Le renfoncement de porte bloque la sortie dans le vide")
	_check(not _point_clear(Vector2(50,500)),"Mur extérieur solide hors ouverture")
	await _approach("school_city_door")
	await _capture("city_ciel_porte_challenge")
	await _key(KEY_SPACE)
	await _activate("hotel_travel_go")
	_check(state.profile.progress.room_id == "school_network_lab", "Porte gauche mène au laboratoire")
	var entry: Dictionary = state.profile.duplicate(true)
	await _approach("school_city_lesson")
	await _key(KEY_RIGHT)
	_check(not app.demo.campus_map.expanded,"Carte masquée pour découvrir l’architecture")
	await _capture("city_architecture_challenge")
	await _key(KEY_RIGHT)
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "dialog", "Tableau de cours consultable")
	await _capture("city_cours_challenge")
	await _activate("dialog_continue")
	await _approach("school_city_ipv6")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "dialog" and state.profile == entry,"Mission suivante verrouillée sans effet")
	await _activate("dialog_continue")
	for id in CityCatalog.IDS:
		await _approach("school_city_" + id)
		await _key(KEY_SPACE)
		var panel = app.demo.modal_content.get_node("city_network_panel")
		_check(panel.keyboard != null and panel.editors.size() == 3,"Formulaire et clavier virtuel : " + id)
		await _activate("city_lesson_toggle")
		_check(_find("city_inline_lesson").visible,"Cours déployé")
		await _activate("city_lesson_toggle")
		if id == "ipv4":
			var mask = panel.editors.mask
			mask.grab_focus()
			await _frames(4)
			_check(panel.keyboard.editor == mask,"Clavier associé au champ sélectionné")
			await _activate("key_123")
			await _activate("key_1")
			_check(mask.text == "1", "Chiffre saisi au clavier virtuel")
			# Physical input is handled by the same LineEdit, never by gameplay.
			mask.text = "255.255.0.0"
			panel.editors.network.text = "192.168.50.0"
			panel.editors.last.text = "192.168.50.254"
			await _activate("city_validate")
			_check(city.state().completed.is_empty(),"Masque erroné refusé")
		for field in CityCatalog.CHALLENGES[id].fields:
			panel.editors[field[0]].text = CityCatalog.CHALLENGES[id].answers[field[0]]
		if id == "ipv6":
			root.size = Vector2i(800,480)
			await _frames(6)
		await _capture("city_" + id + "_challenge")
		if id == "ipv4":
			saves.simulate_write_failure = true
			await _activate("city_validate")
			_check(city.state().completed.is_empty() and state.profile.wallet.points == 0,"Erreur disque sans validation ni points")
			saves.simulate_write_failure = false
		await _activate("city_validate")
		_check(app.demo.overlay_kind == "dialog" and city.mission_state(id) == "completed","Configuration réussie : " + id)
		await _activate("dialog_continue")
		root.size = Vector2i(1280,720)
		await _frames(5)
	_check(state.profile.wallet.points == 150,"150 points pour les trois missions")
	for prop in School.furniture_specs("school_network_lab"):
		_check(not _point_clear(prop.rect.get_center()),"Mobilier solide : "+prop.kind)
	_check(not _point_clear(Vector2(1468,320)),"Cloison solide")
	_check(_point_clear(Vector2(1475,750)),"Passage libre vers la baie")
	await _approach("school_city_routing")
	await _capture("city_salle_reseau_challenge")
	_check(profiles.select_profile(profile_id).ok and city.state().completed == CityCatalog.IDS,"Reprise durable des trois missions")
	_check(hotel.travel("school_workshop").ok,"Retour à City CIEL")
	_check(state.profile.progress.checkpoint_id == "city_workshop_return", "Retour près de la porte gauche")
	_check(hotel.travel("school_network_lab").ok and state.profile.wallet.points == 150,"Nouvelle visite sans crédit supplémentaire")
	await _finish()
