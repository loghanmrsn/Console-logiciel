extends "res://tests/code_chapter_ui_tests.gd"
## Real native input, real waiting intervals and isolated saves exercise the
## complete hotel visit. No operating-system clock or production delay changes.
const Hotel = preload("res://scripts/game/hotel_layout.gd")
const FOURTH := ["firewall", "ip_conflict", "subnet_mask"]


func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	settings = root.get_node("SettingsService")
	state = root.get_node("AppState")
	investigation = root.get_node("InvestigationService")
	router = root.get_node("SceneRouter")
	controllers = root.get_node("ControllerService")
	controllers.debug_set_devices([0, 1])
	test_root = "user://tests/hotel_ui_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var values: Dictionary = settings.committed.duplicate(true)
	values.reduce_motion = true
	_check(settings.apply_settings(values).ok, "Réglages de l’hôtel isolés")
	var made: Dictionary = profiles.create_profile("Voyageur CIEL")
	_check(made.ok, "Profil de l’hôtel créé")
	if not made.ok:
		await _finish()
		return
	profile_id = str(made.data.id)
	_check(profiles.start_game().ok, "Enquête démarrée")
	for chapter in [1, 2, 3, 4]:
		if chapter > 1:
			_check(investigation.enter_chapter(chapter).ok, "Préparation du chapitre précédent")
		for id in [FIRST, SECOND, THIRD, FOURTH][chapter - 1]:
			if chapter == 3:
				_check(investigation.submit_code(id, ANSWERS[id]).ok, "Code antérieur validé")
			else:
				_complete_service(id)
	_check(investigation.enter_chapter(5).ok and investigation.enter_maze().ok, "Labyrinthe préparé")
	_check(investigation.terminal_login("admin", "admin").ok and investigation.terminal_command("sudo", "admin").ok, "Les treize épreuves sont réellement réussies")
	_check(investigation.leave_maze().ok, "Retour à l’ascenseur du cinquième chapitre")
	root.size = Vector2i(1280, 720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(35)
	app._show_screen("home")
	await _activate("continue_game")
	if app.demo.overlay_kind == "conclusion":
		await _activate("conclusion_stay")
	for chapter in [4, 3, 2, 1]:
		await _travel(chapter)
	await _walk_axis(KEY_UP, 67)
	await _walk_axis(KEY_LEFT, 280)
	await _walk_axis(KEY_DOWN, 104)
	await _walk_axis(KEY_LEFT, 405)
	_check(app.demo.world.target_id == "building_exit", "Le joueur rejoint la sortie du premier bâtiment")
	await _zone_door("courtyard")
	await _walk_axis(KEY_UP, 550)
	_check(app.demo.world.target_id == "courtyard_second", "La porte de l’hôtel est en face, après la traversée de la cour")
	await _zone_door("building_02")
	if app.demo.world.room_id != "building_02":
		await _finish()
		return
	await _test_reception()
	await _test_it_repair()
	if not state.profile.progress.hotel.repaired:
		await _finish()
		return
	await _test_stairs_and_room()
	if app.demo.world.room_id != "hotel_room_206":
		await _finish()
		return
	await _test_luggage_and_bed()
	_check(state.profile.wallet.points == 650 and state.profile.rewarded_missions.size() == 13 and state.profile.progress.run_reward_points == 650, "L’histoire de l’hôtel ne crée aucun point ni quatorzième épreuve")
	_check(saves.read_profile(profile_id).data == state.profile, "Le document final correspond à la sauvegarde validée")
	await _finish()


func _approach(id: String) -> void:
	if app.demo.world.chapter_id == 5:
		app.demo.world.player.position = Vector2(158, 405)
		await _physics_frames(3)
		return
	await super._approach(id)


func _zone_door(destination: String) -> void:
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "zone_door", "La porte du bâtiment propose le passage")
	await _activate("zone_go", true)
	await _physics_frames(5)
	_check(state.profile.progress.room_id == destination and app.demo.world.room_id == destination, "Le passage est enregistré : " + destination)


func _test_reception() -> void:
	_check(app.demo.world.world_extent() == Hotel.HALL_SIZE and Hotel.HALL_SIZE.x > 6000, "L’hôtel conserve un véritable grand hall")
	_check(investigation.chapter_missions().is_empty(), "L’histoire de l’hôtel reste séparée des treize épreuves récompensées")
	await _check_hotel_hud_bounds("arrivée dans le hall")
	await _walk_axis(KEY_UP, 390)
	_check(app.demo.world.target_id == "hotel_reception", "On rejoint la réception à pied depuis l’entrée")
	await _capture("hotel_hall_cinq_etoiles_challenge")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "hotel_reception", "La réception ouvre la réservation")
	await _check_modal_layout("réception")
	await _capture("hotel_reception_challenge")
	await _failed_action("hotel_reserve", "hotel_reception", "Réservation")
	await _activate("hotel_reserve", true)
	await _frames(6)
	_check(state.profile.progress.hotel.reserved and not state.profile.progress.hotel.repaired, "La chambre 206 est réservée et la panne arrive ensuite")
	await _dismiss_dialog()
	await _resume_area("building_02", "Réservation conservée après retour au menu")
	# The hall checkpoint is the entrance, so walk back along the same real aisle.
	await _walk_axis(KEY_UP, 290)
	await _walk_axis(KEY_D, 840)
	await _walk_axis(KEY_UP, 100)
	_check(app.demo.world.target_id == "hotel_stairs_up", "L’escalier est visible à côté de la réception")
	var before: Dictionary = state.profile.duplicate(true)
	await _key(KEY_SPACE)
	await _activate("hotel_travel_go")
	_check(app.demo.overlay_kind == "hotel_error" and app.demo.world.room_id == "building_02" and state.profile == before, "La panne bloque l’accès aux étages avant réparation")
	await _activate("hotel_error_close")
	await _walk_axis(KEY_DOWN, 100)
	await _walk_axis(KEY_Q, 1670)
	await _walk_axis(KEY_UP, 210)
	_check(app.demo.world.target_id == "hotel_it_door", "Le local informatique voisin est accessible sans étage")
	await _hotel_travel("hotel_it", true)
	await _check_layout_connectivity("hotel_it")


func _test_it_repair() -> void:
	await _walk_axis(KEY_UP, 290)
	await _walk_axis(KEY_D, 100)
	_check(app.demo.world.target_id == "hotel_repair", "Le poste de maintenance est accessible à pied")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "hotel_repair", "Le poste ouvre un vrai diagnostic")
	await _check_modal_layout("diagnostic informatique")
	var before: Dictionary = state.profile.duplicate(true)
	await _activate("hotel_diagnosis_network_link")
	await _activate("hotel_fix_reboot_only", true)
	await _activate("hotel_repair_submit")
	_check(state.profile == before and app.demo.overlay_kind == "hotel_repair", "Une hypothèse non prouvée et un simple redémarrage ne réparent rien")
	for id in ["power", "network", "storage", "service"]:
		await _activate("hotel_observe_" + id, id in ["network", "service"])
	_check(state.profile.progress.hotel.repair_observations.size() == 4, "Les quatre contrôles du serveur sont enregistrés")
	await _activate("hotel_diagnosis_network_link")
	await _activate("hotel_fix_disable_firewall")
	before = state.profile.duplicate(true)
	await _activate("hotel_repair_submit", true)
	_check(state.profile == before and not state.profile.progress.hotel.repaired, "Désactiver le pare-feu avec un mauvais diagnostic ne résout pas la panne")
	await _activate("hotel_diagnosis_storage_full", true)
	await _activate("hotel_fix_archive_logs_restart")
	await _capture("hotel_diagnostic_challenge")
	await _failed_action("hotel_repair_submit", "hotel_repair", "Réparation")
	await _activate("hotel_repair_submit", true)
	await _frames(6)
	_check(state.profile.progress.hotel.repaired, "L’archivage des journaux et la relance rétablissent les réservations")
	await _dismiss_dialog()
	await _capture("hotel_serveur_repare_challenge")
	await _resume_area("hotel_it", "Les observations et la réparation survivent au menu")
	await _walk_axis(KEY_DOWN, 45)
	_check(app.demo.world.target_id == "hotel_it_return", "Le local a une vraie porte de retour")
	await _hotel_travel("building_02")


func _test_stairs_and_room() -> void:
	await _walk_axis(KEY_DOWN, 210)
	await _walk_axis(KEY_D, 1650)
	await _walk_axis(KEY_UP, 100)
	_check(app.demo.world.target_id == "hotel_stairs_up", "La réception réparée donne accès aux escaliers")
	await _hotel_travel("hotel_stairs_1", true)
	await _check_layout_connectivity("hotel_stairs_1")
	await _capture("hotel_palier_etage_1_challenge")
	# A held key cannot cross the first-floor partition. Only the shared landing
	# connects the two neighbouring flights; no corridor transition exists.
	app.demo.world.player.position = Vector2(770, 330)
	await _physics_frames(3)
	await _walk_axis(KEY_UP, 240)
	_check(app.demo.world.player.position.y >= 209 and app.demo.world.room_id == "hotel_stairs_1", "Le premier étage reste physiquement fermé au-delà du palier")
	app.demo.world.player.position = Hotel.checkpoints("hotel_stairs_1").stairs_from_hall
	await _physics_frames(3)
	await _walk_axis(KEY_D, 520)
	await _walk_axis(KEY_UP, 120)
	_check(app.demo.world.target_id == "hotel_stairs_up", "Les deux volées se rejoignent à pied sur le même palier")
	await _hotel_travel("hotel_floor_2", true)
	var objective := _find("hotel_objective_text") as Label
	_check(objective != null and objective.is_visible_in_tree() and "206" in objective.text, "Le panneau de mission indique automatiquement la chambre 206 à l’étage 2")
	await _key(KEY_T)
	_check(not app.demo.hotel_story.objectives_expanded, "T replie aussi les objectifs de l’hôtel")
	await _joy(JOY_BUTTON_Y)
	_check(app.demo.hotel_story.objectives_expanded and objective.is_visible_in_tree(), "Le bouton haut de la manette redéploie l’objectif de la chambre")
	await _test_compact_hotel_hud()
	await _capture("hotel_etage_2_objectif_challenge")
	await _check_layout_connectivity("hotel_floor_2")
	await _resume_area("hotel_floor_2", "L’objectif de la chambre revient automatiquement après reprise")
	await _walk_axis(KEY_UP, 130)
	await _walk_axis(KEY_D, 1200)
	await _walk_axis(KEY_UP, 210)
	_check(app.demo.world.target_id == "hotel_room206", "Le couloir mène réellement à la porte de la chambre 206")
	await _hotel_travel("hotel_room_206", true)
	await _check_layout_connectivity("hotel_room_206")


func _test_luggage_and_bed() -> void:
	await _walk_axis(KEY_UP, 130)
	await _walk_axis(KEY_Q, 300)
	_check(app.demo.world.target_id == "hotel_luggage", "Le porte-bagages est accessible depuis la porte de la chambre")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "hotel_luggage", "Le joueur peut poser ses affaires")
	await _capture("hotel_chambre_206_bagages_challenge")
	await _failed_action("hotel_luggage_place", "hotel_luggage", "Bagages")
	await _activate("hotel_luggage_place", true)
	await _dismiss_dialog()
	_check(state.profile.progress.hotel.luggage_placed, "Les affaires restent posées")
	await _walk_axis(KEY_D, 540)
	await _walk_axis(KEY_UP, 170)
	_check(app.demo.world.target_id == "hotel_bed", "Le lit est accessible après les bagages")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "hotel_bed", "Le lit présente les deux choix initiaux")
	_check(_visible_action_names() == ["hotel_bed_sleep", "hotel_bed_sit"], "Le lit propose exactement dormir ou se poser")
	var standing_fixture: Dictionary = state.profile.duplicate(true)
	await _test_compact_modal("hotel_lit_choix_compact_challenge")
	await _failed_action("hotel_bed_sit", "hotel_bed", "Installation sur le lit")
	await _activate("hotel_bed_sit", true)
	_check(state.profile.progress.hotel.bed_state == "sitting" and app.demo.overlay_kind == "hotel_bed_waiting", "Se poser est enregistré et démarre une véritable attente")
	_check(app.demo.world.player.position.distance_to(Hotel.BED_SEAT) < .1, "Se poser installe réellement le personnage sur le lit")
	var before_position: Vector2 = app.demo.world.player.position
	await _hold(KEY_D, 15)
	await _hold(KEY_UP, 15)
	_check(app.demo.world.player.position.distance_to(before_position) < 1, "Le personnage assis ne peut pas descendre du lit par les déplacements")
	await _capture("hotel_lit_attente_challenge")
	await _key(KEY_ESCAPE)
	_check(app.demo.paused, "Le joueur assis conserve le menu pause")
	var remaining: float = app.demo.hotel_story.wait_remaining_seconds
	await create_timer(.6).timeout
	_check(is_equal_approx(app.demo.hotel_story.wait_remaining_seconds, remaining), "Le délai est suspendu pendant la pause")
	await _key(KEY_ESCAPE)
	_check(app.demo.overlay_kind == "hotel_bed_waiting", "Reprendre restaure l’attente au lit")
	await _test_detached_pages()
	await _assert_inactive_controller()
	await _test_controller_pause()
	await _resume_seated()
	await _wait_for_choices()
	await _capture("hotel_lit_premiers_choix_challenge")
	_check(_visible_action_names() == ["hotel_bed_sleep", "hotel_bed_wait"], "Après dix secondes : dormir ou continuer à attendre, sans quitter le lit")
	await _click_action("hotel_bed_wait")
	_check(app.demo.overlay_kind == "hotel_bed_waiting" and app.demo.hotel_story.wait_remaining_seconds > 9, "Continuer relance un délai complet")
	await _wait_for_choices()
	_check(_visible_action_names() == ["hotel_bed_sleep", "hotel_bed_wait"] and state.profile.progress.hotel.bed_state == "sitting", "Le deuxième choix revient après une nouvelle attente réelle")
	await _activate("hotel_bed_wait")
	await _wait_for_choices()
	_check(state.profile.progress.hotel.bed_state == "sitting", "Un troisième choix laisse encore le joueur assis jusqu’à sa décision")
	await _failed_action("hotel_bed_sleep", "hotel_bed_choices", "Sommeil")
	var animated: Dictionary = settings.committed.duplicate(true)
	animated.reduce_motion = false
	_check(settings.apply_settings(animated).ok, "La nuit est aussi vérifiée avec son animation normale")
	await _click_action("hotel_bed_sleep")
	_check(app.demo.overlay_kind == "hotel_night", "Dormir lance le passage animé de la nuit")
	await _capture("hotel_nuit_challenge")
	for attempt in range(40):
		if app.demo.overlay_kind == "hotel_morning":
			break
		await create_timer(.1).timeout
	_check(state.profile.progress.hotel.bed_state == "rested" and app.demo.overlay_kind == "hotel_morning", "Au matin le sommeil est sauvegardé")
	animated.reduce_motion = true
	_check(settings.apply_settings(animated).ok, "Les transitions réduites sont restaurées")
	await _capture("hotel_matin_challenge")
	await _dismiss_dialog()
	if app.demo.overlay_kind == "hotel_morning":
		await _activate("hotel_morning_continue")
	await _frames(6)
	before_position = app.demo.world.player.position
	await _hold(KEY_Q, 15)
	_check(app.demo.overlay_kind.is_empty() and app.demo.world.player.position.distance_to(before_position) > 25, "Après le matin le personnage retrouve ses déplacements")
	await _resume_area("hotel_room_206", "Le matin est conservé après reprise")
	_check(state.profile.progress.hotel.bed_state == "rested" and app.demo.overlay_kind.is_empty(), "Reprendre une nuit terminée ne remet pas le joueur dans les choix du lit")
	await _test_direct_sleep(standing_fixture)


func _hotel_travel(destination: String, failure := false) -> void:
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "hotel_travel", "Le passage de l’hôtel est explicite : " + destination)
	if failure:
		await _failed_action("hotel_travel_go", "hotel_travel", "Passage vers " + destination)
	await _activate("hotel_travel_go", true)
	await _physics_frames(5)
	_check(state.profile.progress.room_id == destination and app.demo.world.room_id == destination and app.demo.overlay_kind.is_empty(), "Le monde change après l’écriture réussie : " + destination)
	_check(app.demo.campus_map.visible, "La carte reste disponible dans la zone de l’hôtel : " + destination)


func _failed_action(id: String, original_overlay: String, label: String) -> void:
	var before: Dictionary = state.profile.duplicate(true)
	var room: String = app.demo.world.room_id
	saves.simulate_write_failure = true
	await _activate(id)
	saves.simulate_write_failure = false
	_check(state.profile == before and saves.read_profile(profile_id).data == before and app.demo.world.room_id == room, label + " : échec d’écriture sans progression partielle")
	if app.demo.overlay_kind == "dialog":
		await _activate("dialog_continue")
	elif app.demo.overlay_kind == "hotel_error":
		await _activate("hotel_retry")
	_check(app.demo.overlay_kind == original_overlay, label + " : la commande peut être réessayée")


func _dismiss_dialog() -> void:
	if app.demo.overlay_kind == "dialog":
		await _activate("dialog_continue")
	await _frames(4)


func _resume_area(room: String, label: String) -> void:
	await _key(KEY_P)
	await _activate("pause_menu")
	await _frames(8)
	_check(app.screen == "home", "Le menu reste accessible sans quitter l’application")
	await _activate("continue_game", true)
	await _frames(10)
	_check(app.demo.world.room_id == room and state.profile.progress.room_id == room, label)


func _resume_seated() -> void:
	await _resume_area("hotel_room_206", "Une reprise conserve le personnage assis")
	_check(state.profile.progress.hotel.bed_state == "sitting" and app.demo.overlay_kind == "hotel_bed_waiting", "Le menu ne permet pas de contourner l’obligation de dormir")
	_check(app.demo.world.player.position.distance_to(Hotel.BED_SEAT) < .1, "Une reprise assise place aussi la position physique sur le lit")
	var before: Vector2 = app.demo.world.player.position
	await _hold(KEY_Q, 10)
	_check(app.demo.world.player.position.distance_to(before) < 1, "La reprise assise garde les déplacements bloqués")
	# Re-read and re-select the real saved document while the app remains alive.
	_check(profiles.select_profile(profile_id).ok, "Le document assis peut être rechargé depuis le disque")
	app.demo.refresh()
	await _frames(6)
	_check(state.profile.progress.hotel.bed_state == "sitting" and app.demo.overlay_kind == "hotel_bed_waiting", "La sélection du même profil ne libère pas le lit")
	_check(app.demo.world.player.position.distance_to(Hotel.BED_SEAT) < .1, "Recharger le profil conserve le joueur et son affichage au même endroit sur le lit")


func _test_controller_pause() -> void:
	controllers.debug_connection_changed(0, false)
	await _frames(6)
	_check(app.demo.overlay_kind == "controller_pause", "Débrancher la manette suspend l’attente")
	var remaining: float = app.demo.hotel_story.wait_remaining_seconds
	await create_timer(.4).timeout
	_check(is_equal_approx(app.demo.hotel_story.wait_remaining_seconds, remaining), "Le délai ne continue pas derrière le choix de reconnexion")
	controllers.debug_connection_changed(0, true)
	await _frames(4)
	await _activate("controller_resume")
	_check(app.demo.overlay_kind == "hotel_bed_waiting", "La reconnexion explicite restaure le choix du lit")
	_check(controllers.active_device == 1, "La seconde manette garde le contrôle après le retrait de la première")


func _test_detached_pages() -> void:
	for destination in ["settings", "help"]:
		await _key(KEY_P)
		await _activate("pause_" + destination)
		await _frames(6)
		_check(app.screen == destination, "Le menu " + destination + " reste disponible au lit")
		var remaining: float = app.demo.hotel_story.wait_remaining_seconds
		await create_timer(.4).timeout
		_check(is_equal_approx(app.demo.hotel_story.wait_remaining_seconds, remaining), "Le délai est suspendu hors de la scène de jeu : " + destination)
		await _key(KEY_ESCAPE)
		await _frames(8)
		_check(app.screen == "game" and app.demo.overlay_kind == "pause", "Le retour de " + destination + " restaure la pause")
		await _key(KEY_ESCAPE)
		_check(state.profile.progress.hotel.bed_state == "sitting" and app.demo.overlay_kind == "hotel_bed_waiting", "Revenir de " + destination + " ne permet pas de quitter le lit")


func _test_direct_sleep(standing_fixture: Dictionary) -> void:
	# An independent validated save fixture covers the other branch without
	# claiming a second walkthrough of the already tested hotel corridors.
	await _key(KEY_P)
	await _activate("pause_menu")
	await _frames(8)
	var made: Dictionary = profiles.create_profile("Sommeil direct")
	_check(made.ok, "Profil indépendant pour le choix Dormir immédiatement")
	if not made.ok:
		return
	profile_id = str(made.data.id)
	var fixture: Dictionary = state.profile.duplicate(true)
	for field in ["progress", "wallet", "rewarded_missions"]:
		fixture[field] = standing_fixture[field].duplicate(true)
	var written: Dictionary = saves.write_profile(fixture)
	_check(written.ok, "Arrivée indépendante avant le lit validée par SaveService")
	if not written.ok:
		return
	state.set_profile(written.data)
	app._show_screen("home")
	await _activate("continue_game", true)
	await _walk_axis(KEY_UP, 130)
	await _walk_axis(KEY_D, 240)
	await _walk_axis(KEY_UP, 170)
	_check(app.demo.world.target_id == "hotel_bed", "Le second profil rejoint le lit depuis son arrivée sauvegardée")
	await _key(KEY_SPACE)
	await _failed_action("hotel_bed_sleep", "hotel_bed", "Dormir immédiatement")
	_check(state.profile.progress.hotel.bed_state == "standing", "Un sommeil non enregistré ne fait pas passer la nuit")
	await _activate("hotel_bed_sleep", true)
	for attempt in range(40):
		if app.demo.overlay_kind == "hotel_morning":
			break
		await create_timer(.1).timeout
	_check(state.profile.progress.hotel.bed_state == "rested" and app.demo.overlay_kind == "hotel_morning", "Le choix initial Dormir passe directement au matin, sans imposer de s’asseoir")
	await _activate("hotel_morning_continue")


func _assert_inactive_controller() -> void:
	var before: Dictionary = state.profile.duplicate(true)
	for button in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_START]:
		var event := InputEventJoypadButton.new()
		event.device = 1
		event.button_index = button
		event.pressed = true
		Input.parse_input_event(event)
		await _frames(2)
		event = event.duplicate()
		event.pressed = false
		Input.parse_input_event(event)
		await _frames(2)
	_check(state.profile == before and app.demo.overlay_kind == "hotel_bed_waiting", "Une manette inactive ne déclenche ni sommeil ni pause ni sortie")


func _joy(code: JoyButton) -> void:
	# The controller handover deliberately disconnects device 0. Continue with
	# the controller selected by the application rather than its old device ID.
	if not router.gameplay_allowed():
		await create_timer(.23).timeout
	var event := InputEventJoypadButton.new()
	event.device = controllers.active_device
	event.button_index = code
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(2)
	await physics_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(4)


func _wait_for_choices() -> void:
	_check(app.demo.overlay_kind == "hotel_bed_waiting", "Une attente réelle précède les choix du lit")
	var remaining: float = app.demo.hotel_story.wait_remaining_seconds
	var began := Time.get_ticks_msec()
	# Poll using wall-clock timers; this deliberately does not call _tick_wait,
	# change Engine.time_scale, replace timers or edit the production interval.
	for attempt in range(120):
		if app.demo.overlay_kind != "hotel_bed_waiting":
			break
		await create_timer(.1).timeout
	_check(app.demo.overlay_kind == "hotel_bed_choices", "Les deux propositions réapparaissent après dix secondes réellement écoulées")
	_check(float(Time.get_ticks_msec() - began) / 1000.0 >= remaining - .15, "Les choix ne précèdent pas le délai actif restant")
	_check(not app.demo.world.player.controls_enabled, "Le lit garde le personnage assis pendant le nouveau choix")
	await _check_modal_layout("choix du lit après attente")


func _visible_action_names() -> Array[String]:
	var result: Array[String] = []
	for control in app._focusables(app.demo.modal_content):
		if control is BaseButton and control.is_visible_in_tree() and not control.disabled:
			result.append(str(control.name))
	return result


func _click_action(id: String) -> void:
	var control := _find(id) as BaseButton
	_check(control != null and control.is_visible_in_tree() and not control.disabled, "Bouton souris natif disponible : " + id)
	if control == null or not control.is_visible_in_tree() or control.disabled:
		return
	control.grab_focus()
	await _frames(6)
	var at := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	await _frames(2)
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(2)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(6)


func _test_compact_modal(capture_id: String) -> void:
	root.size = Vector2i(800, 480)
	var original: Dictionary = settings.committed.duplicate(true)
	var large: Dictionary = original.duplicate(true)
	large.large_text = true
	large.reduce_transparency = true
	_check(settings.apply_settings(large).ok, "Choix du lit en grand texte au format 800 × 480")
	await _frames(10)
	await _check_modal_layout("lit compact avec grand texte")
	await _capture(capture_id)
	_check(settings.apply_settings(original).ok, "Taille habituelle restaurée")
	root.size = Vector2i(1280, 720)
	await _frames(10)


func _test_compact_hotel_hud() -> void:
	var original: Dictionary = settings.committed.duplicate(true)
	var large: Dictionary = original.duplicate(true)
	large.large_text = true
	large.reduce_transparency = true
	root.size = Vector2i(800, 480)
	_check(settings.apply_settings(large).ok, "L’objectif d’étage et sa carte supportent le grand texte compact")
	await _frames(10)
	var objective: Rect2 = app.demo.hotel_story.objective_panel.get_global_rect()
	var map_rect: Rect2 = app.demo.campus_map.get_global_rect()
	await _check_hotel_hud_bounds("étage 2 en 800 × 480 avec grand texte")
	_check(not objective.intersects(map_rect), "La carte à gauche ne masque pas la mission de la chambre à droite")
	await _capture("hotel_etage_2_compact_challenge")
	_check(settings.apply_settings(original).ok, "La taille de lecture habituelle revient")
	root.size = Vector2i(1280, 720)
	await _frames(10)


func _check_hotel_hud_bounds(context: String) -> void:
	await _frames(3)
	var game_rect: Rect2 = app.demo.get_global_rect()
	var objective: Rect2 = app.demo.hotel_story.objective_panel.get_global_rect()
	var map_rect: Rect2 = app.demo.campus_map.get_global_rect()
	_check(app.demo.hotel_story.objective_panel.is_visible_in_tree() and app.demo.campus_map.is_visible_in_tree(), "L’objectif et la carte sont réellement affichés : " + context)
	_check(game_rect.grow(.5).encloses(objective) and game_rect.grow(.5).encloses(map_rect), "L’objectif et toute la carte restent dans la surface du jeu : " + context)
	_check(objective.size.y < minf(220.0, game_rect.size.y - 24.0), "Le panneau de mission garde une hauteur adaptée à son contenu : " + context)


func _check_layout_connectivity(zone: String) -> void:
	_check(app.demo.world.room_id == zone, "Contrôle physique dans la zone réelle " + zone)
	var at: Vector2 = app.demo.world.player.position
	var expanded: bool = app.demo.campus_map.expanded
	await _hold(KEY_RIGHT, 3)
	_check(app.demo.campus_map.expanded != expanded and app.demo.world.player.position.distance_to(at) < 1, "La flèche droite change seulement la carte dans " + zone)
	await _key(KEY_RIGHT)
	_check(app.demo.campus_map.expanded == expanded, "Un nouvel appui restaure la carte dans " + zone)
	var size: Vector2 = Hotel.extent(zone)
	var seed := Vector2i(app.demo.world.player.position / 50)
	var reachable := {seed: true}
	var pending: Array[Vector2i] = [seed]
	var cursor := 0
	while cursor < pending.size():
		var cell: Vector2i = pending[cursor]
		cursor += 1
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			var point := Vector2(next) * 50 + Vector2(25, 25)
			if reachable.has(next) or point.x < 75 or point.y < 75 or point.x > size.x - 75 or point.y > size.y - 75:
				continue
			if not _point_clear(point):
				continue
			var ray := PhysicsRayQueryParameters2D.create(Vector2(cell) * 50 + Vector2(25, 25), point, 1)
			if not app.demo.world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
				continue
			reachable[next] = true
			pending.append(next)
	for target in Hotel.interactions(zone):
		var target_at: Vector2 = target.at
		var nearest := Vector2i(target_at / 50)
		var found := false
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if reachable.has(nearest + Vector2i(dx, dy)):
					found = true
		_check(found, "Le plan physique relie l’arrivée à l’interaction " + str(target.id))
	for checkpoint in Hotel.checkpoints(zone).values():
		_check(_point_clear(checkpoint), "Le checkpoint ne chevauche aucun meuble ni mur : " + zone)
