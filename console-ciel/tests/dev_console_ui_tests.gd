extends "res://tests/ctf_ui_tests.gd"
const HotelLayout = preload("res://scripts/game/hotel_layout.gd")

func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	settings = root.get_node("SettingsService")
	state = root.get_node("AppState")
	investigation = root.get_node("InvestigationService")
	router = root.get_node("SceneRouter")
	controllers = root.get_node("ControllerService")
	hotel = root.get_node("HotelService")
	controllers.debug_set_devices([0, 1])
	test_root = "user://tests/dev_console_ui_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var values: Dictionary = settings.committed.duplicate(true)
	values.reduce_motion = true
	_check(settings.apply_settings(values).ok, "Réglages de test isolés")
	_check(profiles.create_profile("Dev").ok, "Joueur ordinaire appelé Dev")
	root.size = Vector2i(1280, 720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(35)
	app._show_screen("profiles")
	await _frames(8)
	_check(_find("open_dev_terminal") == null, "Pas de terminal pour un simple pseudo Dev")
	_check(profiles.use_dev_profile().ok, "Compte privilégié choisi explicitement")
	profile_id = str(state.profile.id)
	app._show_screen("profiles")
	await _frames(8)
	await _activate("open_dev_terminal", true)
	_check(app.screen == "dev_terminal" and _find("dev_console_keyboard") != null, "Le profil ouvre son terminal avec clavier virtuel")
	await _console_command("add coins 543", true)
	_check(state.profile.wallet.points == 1543 and "1543" in app.header_points.text, "Le montant personnel actualise le solde et l'en-tête")
	await _console_command("add coins -1")
	_check(state.profile.wallet.points == 1543 and "Erreur" in (_find("dev_console_output") as Label).text, "Montant négatif expliqué sans changement")
	await _capture("dev_terminal_profile_challenge")
	root.size = Vector2i(800, 480)
	var compact := values.duplicate(true)
	compact.large_text = true
	_check(settings.apply_settings(compact).ok, "Terminal compact en grand texte")
	await _frames(12)
	var validate := _find("key_Valider") as Button
	validate.grab_focus()
	await _frames(10)
	_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(validate.get_global_rect()), "Valider reste accessible en 800 × 480 : " + str(validate.get_global_rect()) + " / " + str(app.scroll.get_global_rect()))
	await _capture("dev_terminal_compact_challenge")
	root.size = Vector2i(1280, 720)
	_check(settings.apply_settings(values).ok, "Dimensions normales restaurées")
	await _frames(10)
	await _console_command("reset missions")
	await _key(KEY_ESCAPE)
	_check(app.screen == "profiles" and state.profile.progress.completed_missions.is_empty(), "Échap ferme le terminal et le parcours est rejouable")
	app._show_screen("home")
	await _frames(8)
	await _activate("continue_game")
	await _key(KEY_P)
	await _activate("pause_dev_terminal", true)
	_check(app.demo.overlay_kind == "dev_terminal" and app.demo.paused, "Terminal du menu Pause ; mouvement suspendu")
	var position_before: Vector2 = app.demo.world.player.position
	await _console_command("skip missions", true)
	_check(state.profile.progress.completed_missions == ["lighting"] and state.profile.wallet.points == 1543, "Un seul objectif passé sans crédit")
	_check(app.demo.world.lighting_restored and not app.demo.world.get_interactable("lighting").visible, "Le rendu et le repère de mission suivent la commande")
	await _capture("dev_terminal_game_challenge")
	await _key(KEY_ESCAPE)
	_check(app.demo.overlay_kind.is_empty() and app.demo.world.player.position == position_before, "Fermer ne téléporte pas le joueur après un simple skip")
	# Exercise the two CTF overlays which formerly ignored Escape.
	var fixture: Dictionary = load("res://scripts/services/dev_profile.gd").build().data
	fixture.wallet.points = 1543
	fixture.progress.room_id = "ctf_lobby"
	fixture.progress.checkpoint_id = "ctf_entry"
	fixture.progress.hotel.morning_stage = 8
	fixture.progress.erase("ctf")
	_check(saves.write_profile(fixture).ok, "Ancien état au CTF préparé")
	state.commit_profile(fixture)
	app.demo.world.restore_checkpoint()
	await _frames(10)
	await _target("ctf_phishing")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "ctf_challenge", "Panneau CTF ouvert")
	await _key(KEY_ESCAPE)
	_check(app.demo.overlay_kind.is_empty(), "Échap ferme maintenant la saisie CTF")
	fixture.progress["ctf"] = {"version": 1, "completed": CtfCatalog.IDS.duplicate()}
	fixture.progress.room_id = "ctf_bus_stop"
	fixture.progress.checkpoint_id = "ctf_arrival"
	_check(saves.write_profile(fixture).ok, "Bus de retour disponible")
	state.commit_profile(fixture)
	app.demo.world.restore_checkpoint()
	await _frames(8)
	await _target("ctf_return_bus")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "ctf_bus", "Panneau du bus CTF ouvert")
	await _key(KEY_ESCAPE)
	_check(app.demo.overlay_kind.is_empty(), "Échap ferme aussi le bus CTF")
	await _capture_existing_rooms()
	_check(saves.read_profile(profile_id).data == state.profile, "Dernier état enregistré cohérent")
	await _finish()

func _console_command(command: String, joy := false) -> void:
	var panel = _find("dev_console_panel")
	_check(panel != null, "Console disponible pour " + command)
	if panel == null: return
	await _physical_text(panel.editor, command)
	await _activate("key_Valider", joy)
	await _frames(6)

func _capture_existing_rooms() -> void:
	var zones := ["room_01", "room_02", "room_03", "room_04", "room_05", "maze_05", "courtyard"] + HotelLayout.ZONES
	for zone in zones:
		var fixture: Dictionary = load("res://scripts/services/dev_profile.gd").build().data
		fixture.wallet.points = 1543
		fixture.progress.room_id = zone
		fixture.progress.checkpoint_id = {"room_01": "entrance", "room_02": "elevator", "room_03": "elevator", "room_04": "elevator", "room_05": "elevator", "maze_05": "maze_entry", "courtyard": "from_first", "building_02": "new_entrance", "hotel_it": "it_entrance", "hotel_stairs_1": "stairs_from_hall", "hotel_floor_2": "floor2_stairs", "hotel_room_206": "room206_entry", "hotel_breakfast": "breakfast_entry", "ctf_bus_stop": "ctf_arrival", "ctf_lobby": "ctf_entry"}[zone]
		if zone == "ctf_bus_stop": fixture.progress.hotel.morning_stage = 7
		if zone == "ctf_lobby": fixture.progress.hotel.morning_stage = 8
		_check(saves.write_profile(fixture).ok, "Sauvegarde de capture valide : " + zone)
		state.commit_profile(fixture)
		app.demo.world.restore_checkpoint()
		await _frames(12)
		await _capture("quality_" + zone + "_challenge")
