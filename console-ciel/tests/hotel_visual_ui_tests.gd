extends "res://tests/morning_ui_tests.gd"
## Real controls and physics, with a validated profile isolated from user data.

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
	test_root = "user://tests/hotel_visual_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var preferences: Dictionary = settings.committed.duplicate(true)
	preferences.reduce_motion = true
	_check(settings.apply_settings(preferences).ok, "Préférences de rendu isolées")
	if not _prepare_waking_save():
		await _finish()
		return
	# Return to the actual outage; the thirteen earlier challenges stay earned.
	var fixture: Dictionary = state.profile.duplicate(true)
	fixture.progress.room_id = "hotel_it"
	fixture.progress.checkpoint_id = "it_entrance"
	fixture.progress.hotel = saves.empty_hotel_progress()
	fixture.progress.hotel.reserved = true
	var saved: Dictionary = saves.write_profile(fixture)
	_check(saved.ok, "L’état de panne passe toute la validation du profil")
	if not saved.ok:
		await _finish()
		return
	state.commit_profile(saved.data)
	root.size = Vector2i(1280, 720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(30)
	app._show_screen("home")
	await _activate("continue_game")
	await _frames(8)
	await _test_diagnostic_presentation()
	if not state.profile.progress.hotel.repaired:
		await _finish()
		return
	await _reach_breakfast()
	await _target("hotel_coffee_machine")
	await _scenery_capture("hotel_visuel_machine_et_tasses_challenge")
	_check(app.demo.world.player.test_move(Transform2D(0, Vector2(1030, 320)), Vector2(0, -90)), "Le meuble à tasses possède une collision physique")
	await _test_coffee()
	if int(state.profile.progress.hotel.morning_stage) == 5:
		await _physics_frames(4)
		_check(app.demo.world.target_id != "hotel_coffee_machine", "Le café servi masque toujours son repère d’épreuve terminée")
		await _scenery_capture("hotel_visuel_cafe_servi_challenge")
	_check(state.profile.wallet.points == 700 and state.profile.rewarded_missions.size() == 14, "Le changement graphique n’invente aucune récompense")
	_check(saves.read_profile(profile_id).data == state.profile, "La dernière présentation correspond à l’état réellement sauvegardé")
	await _finish()

func _test_diagnostic_presentation() -> void:
	await _target("hotel_repair")
	_check(app.demo.world.player.test_move(Transform2D(0, Vector2(215, 720)), Vector2(0, -180)), "L’onduleur bloque réellement le personnage")
	_check(app.demo.world.player.test_move(Transform2D(0, Vector2(1080, 760)), Vector2(0, -180)), "Le chariot de maintenance est un obstacle physique")
	await _scenery_capture("hotel_visuel_local_informatique_challenge")
	var before: Dictionary = state.profile.duplicate(true)
	await _key(KEY_SPACE)
	_check(_find("hotel_diagnostic_panel") != null, "Le diagnostic utilise son composant natif dédié")
	_check((_find("hotel_observation_progress") as ProgressBar).value == 0, "La présentation initiale n’invente aucune observation")
	_check(state.profile == before, "Afficher le nouveau diagnostic ne modifie pas le profil")
	await _capture("hotel_visuel_diagnostic_initial_challenge")
	await _activate("hotel_observe_power")
	_check((_find("hotel_observation_progress") as ProgressBar).value == 1, "Le suivi reflète une seule observation enregistrée")
	_check("alimentés" in (_find("hotel_observation_detail") as Label).text, "Le panneau expose le vrai résultat du contrôle")
	await _activate("hotel_observe_storage", true)
	before = state.profile.duplicate(true)
	await _activate("hotel_observe_power")
	_check("alimentés" in (_find("hotel_observation_detail") as Label).text and state.profile == before, "Réexaminer un ancien indice affiche son détail sans réécrire la progression")
	await _activate("hotel_observe_storage")
	app.demo._modal_scroll.scroll_vertical = 0
	await _frames(6)
	await _capture("hotel_visuel_indices_challenge")
	await _diagnostic_theme_and_compact()
	for id in ["network", "service"]: await _activate("hotel_observe_" + id)
	_check((_find("hotel_observation_progress") as ProgressBar).value == 4, "Les quatre indices graphiques proviennent des quatre observations persistées")
	await _activate("hotel_diagnosis_network_link")
	await _activate("hotel_fix_reboot_only", true)
	before = state.profile.duplicate(true)
	await _activate("hotel_repair_submit")
	_check(state.profile == before and not state.profile.progress.hotel.repaired and _find("hotel_repair_feedback") != null, "Un choix erroné conserve l’état et affiche un retour lisible")
	await _capture("hotel_visuel_diagnostic_erreur_challenge")
	await _activate("hotel_diagnosis_storage_full", true)
	await _activate("hotel_fix_archive_logs_restart")
	await _failed_action("hotel_repair_submit", "hotel_repair", "Diagnostic redessiné")
	await _activate("hotel_repair_submit", true)
	await _dismiss_dialog()
	await _physics_frames(4)
	_check(app.demo.world.target_id != "hotel_repair", "La réparation masque toujours le repère du défi terminé")
	await _scenery_capture("hotel_visuel_serveurs_retablis_challenge")

func _scenery_capture(id: String) -> void:
	var objective_was_open: bool = app.demo.hotel_story.objectives_expanded
	var map_was_open: bool = app.demo.campus_map.expanded
	if objective_was_open: await _key(KEY_T)
	if map_was_open: await _key(KEY_RIGHT)
	await _frames(4)
	await _capture(id)
	if map_was_open: await _key(KEY_RIGHT)
	if objective_was_open: await _key(KEY_T)

func _diagnostic_theme_and_compact() -> void:
	var original: Dictionary = settings.committed.duplicate(true)
	var compact: Dictionary = original.duplicate(true)
	compact.large_text = true
	compact.reduce_transparency = true
	root.size = Vector2i(800, 480)
	_check(settings.apply_settings(compact).ok, "Diagnostic compact avec grand texte")
	await _frames(8)
	await _check_modal_layout("diagnostic redessiné compact")
	app.demo._modal_scroll.scroll_vertical = 0
	await _frames(5)
	await _capture("hotel_visuel_diagnostic_compact_challenge")
	var night: Dictionary = original.duplicate(true)
	night.appearance_style = "nuit"
	_check(settings.apply_settings(night).ok, "Le diagnostic accepte le thème nuit")
	root.size = Vector2i(1280, 720)
	await _frames(8)
	app.demo._modal_scroll.scroll_vertical = 0
	await _frames(5)
	await _capture("hotel_visuel_diagnostic_nuit_challenge")
	_check(settings.apply_settings(original).ok, "Thème et taille d’origine rétablis")
	await _frames(8)

func _reach_breakfast() -> void:
	await _travel_target("hotel_it_return", "building_02")
	await _travel_target("hotel_stairs_up", "hotel_stairs_1")
	await _travel_target("hotel_stairs_up", "hotel_floor_2")
	await _travel_target("hotel_room206", "hotel_room_206")
	await _target("hotel_luggage")
	await _key(KEY_SPACE)
	await _activate("hotel_luggage_place")
	await _target("hotel_bed")
	await _key(KEY_SPACE)
	await _activate("hotel_bed_sleep")
	for frame in range(80):
		await process_frame
		if app.demo.overlay_kind == "hotel_morning": break
	_check(app.demo.overlay_kind == "hotel_morning", "Le parcours jusqu’au matin fonctionne avec les nouveaux modèles")
	if app.demo.overlay_kind == "hotel_morning": await _activate("hotel_morning_continue")
	await _descend_to_hall()
	await _travel_target("hotel_breakfast_door", "hotel_breakfast")
	await _target("hotel_breakfast_table")
	await _key(KEY_SPACE)
	await _activate("hotel_breakfast_sit")
	await _dismiss_dialog()
	_check(int(state.profile.progress.hotel.morning_stage) == 3, "Le vrai séjour mène au câblage de la machine")
