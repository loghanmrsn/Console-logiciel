extends "res://tests/hotel_ui_tests.gd"
## Native menus exercise the saved morning route after a validated waking save.
## Interaction fixtures place the player at real, collision-checked targets;
## room transitions, wire choices and rewards always use the production UI.
const Campus = preload("res://scripts/game/campus_layout.gd")

var hotel


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
	test_root = "user://tests/morning_ui_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	print("MORNING_UI_DATA : ", ProjectSettings.globalize_path(test_root))
	var values: Dictionary = settings.committed.duplicate(true)
	values.reduce_motion = true
	_check(settings.apply_settings(values).ok, "Réglages du matin isolés")
	if not _prepare_waking_save():
		await _finish()
		return
	root.size = Vector2i(1280, 720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(35)
	app._show_screen("home")
	await _activate("continue_game")
	await _frames(8)
	_check(app.demo.world.room_id == "hotel_room_206" and app.demo.overlay_kind.is_empty(), "La reprise réveillée commence dans la chambre, sans rejouer la nuit")
	_check(_objective_contains("rez-de-chaussée"), "Au réveil la mission demande de rejoindre le rez-de-chaussée")
	await _capture("morning_reveil_objectif_challenge")
	await _descend_to_hall(true)
	if state.profile.progress.room_id != "building_02":
		await _finish()
		return
	_check(state.profile.wallet.points == 700 and "hotel_ground_floor" in state.profile.rewarded_missions, "L’arrivée au rez-de-chaussée attribue exactement 50 points")
	await _capture("morning_hall_50_points_challenge")
	await _target("campus_leave")
	var before: Dictionary = state.profile.duplicate(true)
	await _key(KEY_SPACE)
	if app.demo.overlay_kind == "hotel_travel":
		await _activate("hotel_travel_go")
	elif app.demo.overlay_kind == "zone_door":
		await _activate("zone_go")
	_check(state.profile == before and app.demo.world.room_id == "building_02", "La sortie ne saute pas le petit-déjeuner et le sac à récupérer")
	await _close_error_or_dialog()
	await _travel_target("hotel_breakfast_door", "hotel_breakfast")
	await _check_layout_connectivity("hotel_breakfast")
	await _capture("morning_salle_petit_dejeuner_challenge")
	await _target("hotel_breakfast_table")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "hotel_breakfast", "S’asseoir ouvre le moment du petit-déjeuner")
	await _check_modal_layout("table du petit-déjeuner")
	await _failed_action("hotel_breakfast_sit", "hotel_breakfast", "Installation à table")
	await _activate("hotel_breakfast_sit", true)
	await _dismiss_dialog()
	_check(state.profile.progress.hotel.morning_stage == 3 and _objective_contains("café"), "À table le joueur découvre le café oublié et la machine à réparer")
	await _test_coffee()
	if state.profile.progress.hotel.morning_stage != 5:
		await _finish()
		return
	await _test_backpack_and_departure()
	_check(state.profile.wallet.points == 750 and state.profile.rewarded_missions.size() == 15, "Le matin donne seulement les deux récompenses prévues, soit 100 points")
	_check(state.profile.progress.run_reward_points == 650 and state.profile.progress.completed_missions.size() == 13, "Les treize défis antérieurs et leur plafond restent intacts")
	_check(saves.read_profile(profile_id).data == state.profile, "Le dernier état CTF correspond au document enregistré")
	await _finish()


func _prepare_waking_save() -> bool:
	var made: Dictionary = profiles.create_profile("Matin sudo hack")
	_check(made.ok, "Profil indépendant pour le parcours du matin")
	if not made.ok:
		return false
	profile_id = str(made.data.id)
	_check(profiles.start_game().ok, "Parcours éducatif préparé par les vrais services")
	for chapter in [1, 2, 3, 4]:
		if chapter > 1:
			_check(investigation.enter_chapter(chapter).ok, "Préparation du chapitre " + str(chapter))
		for id in [FIRST, SECOND, THIRD, FOURTH][chapter - 1]:
			if chapter == 3:
				_check(investigation.submit_code(id, ANSWERS[id]).ok, "Ancien défi code validé : " + id)
			else:
				_complete_service(id)
	_check(investigation.enter_chapter(5).ok and investigation.enter_maze().ok, "Ancien labyrinthe préparé")
	_check(investigation.terminal_login("admin", "admin").ok and investigation.terminal_command("sudo", "admin").ok, "Treize défis terminés avant le séjour")
	_check(investigation.leave_maze().ok, "Labyrinthe quitté")
	var fixture: Dictionary = state.profile.duplicate(true)
	fixture.progress.room_id = "hotel_room_206"
	fixture.progress.checkpoint_id = "room206_bed"
	fixture.progress.active_mission = ""
	fixture.progress.hotel = saves.empty_hotel_progress()
	fixture.progress.hotel.reserved = true
	fixture.progress.hotel.repaired = true
	fixture.progress.hotel.repair_observations = ["power", "network", "storage", "service"]
	fixture.progress.hotel.luggage_placed = true
	fixture.progress.hotel.bed_state = "rested"
	fixture.progress.hotel.morning_stage = 1
	var written: Dictionary = saves.write_profile(fixture)
	_check(written.ok, "La fixture réveillée passe la validation complète de SaveService")
	if written.ok:
		state.set_profile(written.data)
	return written.ok


func _descend_to_hall(with_failure := false) -> void:
	await _travel_target("hotel_room206_exit", "hotel_floor_2")
	await _travel_target("hotel_stairs_down", "hotel_stairs_1")
	await _travel_target("hotel_stairs_down", "building_02", with_failure)


func _target(id: String) -> void:
	var zone: String = app.demo.world.room_id
	var targets: Array = Hotel.interactions(zone) if Hotel.is_zone(zone) else Campus.interactions(zone)
	var found := false
	for target in targets:
		if str(target.id) == id:
			app.demo.world.player.position = target.at
			found = true
			break
	_check(found, "Interaction définie dans le plan réel : " + id)
	await _physics_frames(4)
	_check(found and _point_clear(app.demo.world.player.position), "L’approche de l’interaction ne chevauche aucun obstacle : " + id)
	_check(app.demo.world.target_id == id, "La physique sélectionne la cible attendue : " + id)


func _travel_target(id: String, destination: String, failure := false) -> void:
	await _target(id)
	if id == "campus_leave":
		await _zone_door(destination)
	else:
		await _hotel_travel(destination, failure)


func _objective_contains(text: String) -> bool:
	var label := _find("hotel_objective_text") as Label
	return label != null and text.to_lower() in label.text.to_lower()


func _close_error_or_dialog() -> void:
	if app.demo.overlay_kind == "hotel_error":
		await _activate("hotel_error_close")
	elif app.demo.overlay_kind == "dialog":
		await _activate("dialog_continue")
	elif not app.demo.overlay_kind.is_empty():
		await _key(KEY_ESCAPE)
	await _frames(4)
	if not app.demo.overlay_kind.is_empty():
		await _key(KEY_ESCAPE)


func _test_coffee() -> void:
	await _target("hotel_coffee_machine")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "hotel_coffee", "La machine ouvre son panneau électrique en gros plan")
	var panel = app.demo.hotel_story.coffee_panel
	_check(is_instance_valid(panel) and panel.terminal_buttons.size() == 6, "Le panneau possède six bornes natives : A, B, C, 1, 2 et 3")
	if not is_instance_valid(panel):
		return
	await _check_modal_layout("panneau électrique initial")
	var a := _find("hotel_coffee_A") as Button
	a.grab_focus()
	await _frames(3)
	await _joy(JOY_BUTTON_DPAD_RIGHT)
	_check(root.gui_get_focus_owner() == _find("hotel_coffee_B"), "La croix droite parcourt les bornes de la rangée supérieure")
	await _activate("hotel_coffee_A")
	_check(panel.selected_terminal == "A" and panel.terminal_selected("A"), "Une borne choisie est visuellement signalée comme sélectionnée")
	await _key(KEY_P)
	_check(app.demo.overlay_kind == "hotel_coffee" and panel.selected_terminal == "A", "P ne déclenche pas de pause derrière le panneau de câblage")
	await _inactive_coffee_controller()
	await _capture("morning_cafe_fil_selectionne_challenge")
	await _activate("hotel_coffee_A", true)
	_check(panel.selected_terminal.is_empty() and not panel.terminal_selected("A"), "Un second appui désélectionne la borne et éteint sa lueur")
	await _activate("hotel_coffee_A")
	var before: Dictionary = state.profile.duplicate(true)
	await _activate("hotel_coffee_1", true)
	_check(state.profile == before and panel.connections.is_empty() and panel.selected_terminal == "A", "Deux couleurs différentes ne créent pas de liaison et gardent la sélection de départ")
	await _click_action("hotel_coffee_3")
	_check(state.profile.progress.hotel.coffee_connections == {"A": "3"} and panel.connections == {"A": "3"}, "Relier A à 3 enregistre réellement les deux fils rouges")
	_check((_find("hotel_coffee_A") as BaseButton).disabled and (_find("hotel_coffee_3") as BaseButton).disabled, "Les deux extrémités reliées ne peuvent plus être utilisées deux fois")
	_check(panel.selected_terminal.is_empty() and not panel.terminal_selected("A"), "La liaison terminée remplace la sélection lumineuse")
	await _capture("morning_cafe_premiere_liaison_challenge")
	await _activate("hotel_coffee_close")
	await _resume_area("hotel_breakfast", "Une pause et le menu conservent la réparation partielle")
	_check(profiles.select_profile(profile_id).ok, "Le profil partiellement câblé est relu depuis le disque")
	app.demo.refresh()
	await _frames(6)
	await _target("hotel_coffee_machine")
	await _key(KEY_SPACE)
	panel = app.demo.hotel_story.coffee_panel
	_check(panel.connections == {"A": "3"} and panel.selected_terminal.is_empty(), "La réouverture restaure le fil posé sans conserver une sélection provisoire")
	await _compact_morning("morning_cafe_compact_challenge", true)
	await _activate("hotel_coffee_B", true)
	before = state.profile.duplicate(true)
	saves.simulate_write_failure = true
	await _activate("hotel_coffee_2")
	saves.simulate_write_failure = false
	_check(state.profile == before and saves.read_profile(profile_id).data == before, "Une écriture refusée ne crée pas de fil partiel en mémoire ou sur disque")
	if app.demo.overlay_kind == "hotel_error":
		await _activate("hotel_retry")
	panel = app.demo.hotel_story.coffee_panel
	if panel.selected_terminal != "B":
		await _activate("hotel_coffee_B")
	await _activate("hotel_coffee_2", true)
	await _activate("hotel_coffee_1")
	await _activate("hotel_coffee_C", true)
	_check(state.profile.progress.hotel.coffee_connections == {"A": "3", "B": "2", "C": "1"} and state.profile.progress.hotel.morning_stage == 4, "Les trois bonnes paires réparent la machine")
	_check(state.profile.wallet.points == 700, "Le câblage ne donne aucun point supplémentaire non demandé")
	await _check_modal_layout("machine réparée")
	await _capture("morning_cafe_machine_reparee_challenge")
	await _failed_action("hotel_coffee_take", "hotel_coffee", "Prise du café")
	await _click_action("hotel_coffee_take")
	await _dismiss_dialog()
	_check(state.profile.progress.hotel.morning_stage == 5 and _objective_contains("sac"), "Prendre le café demande ensuite de récupérer le sac dans la chambre 206")


func _inactive_coffee_controller() -> void:
	var before: Dictionary = state.profile.duplicate(true)
	for code in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_START]:
		var event := InputEventJoypadButton.new()
		event.device = 1
		event.button_index = code
		event.pressed = true
		Input.parse_input_event(event)
		await _frames(2)
		event = event.duplicate()
		event.pressed = false
		Input.parse_input_event(event)
		await _frames(2)
	_check(state.profile == before and app.demo.overlay_kind == "hotel_coffee" and app.demo.hotel_story.coffee_panel.selected_terminal == "A", "Une manette inactive ne sélectionne, ne ferme et ne suspend pas le câblage")


func _test_backpack_and_departure() -> void:
	await _travel_target("hotel_breakfast_return", "building_02")
	await _travel_target("hotel_stairs_up", "hotel_stairs_1")
	await _travel_target("hotel_stairs_up", "hotel_floor_2")
	await _travel_target("hotel_room206", "hotel_room_206")
	await _target("hotel_backpack")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "hotel_backpack", "Le sac avec l’ordinateur est récupérable après le café")
	await _capture("morning_sac_ordinateur_challenge")
	await _failed_action("hotel_backpack_take", "hotel_backpack", "Récupération du sac")
	await _activate("hotel_backpack_take", true)
	await _dismiss_dialog()
	_check(state.profile.progress.hotel.morning_stage == 6 and state.profile.wallet.points == 750 and "hotel_backpack" in state.profile.rewarded_missions, "Le sac enregistré donne exactement 50 points")
	await _resume_area("hotel_room_206", "Le sac et les points survivent à la reprise")
	await _descend_to_hall()
	_check(state.profile.wallet.points == 750, "Redescendre une seconde fois ne répète pas la récompense du hall")
	await _travel_target("campus_leave", "courtyard")
	await _target("campus_bus")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "hotel_bus", "L’arrêt propose le trajet vers sudo hack")
	await _failed_action("hotel_bus_board", "hotel_bus", "Trajet en bus")
	await _activate("hotel_bus_board", true)
	await _frames(8)
	_check(app.demo.world.room_id == "ctf_bus_stop" and state.profile.progress.hotel.morning_stage == 7, "Le bus arrive à un autre arrêt devant le bâtiment du CTF")
	await _check_layout_connectivity("ctf_bus_stop")
	await _capture("morning_arret_bus_ctf_challenge")
	await _travel_target("ctf_enter", "ctf_lobby", true)
	_check(state.profile.progress.hotel.morning_stage == 8 and investigation.chapter_missions().is_empty(), "L’entrée sudo hack termine le trajet sans inventer les cinq prochaines missions")
	await _check_layout_connectivity("ctf_lobby")
	await _compact_morning("morning_hall_ctf_compact_challenge", false)
	await _capture("morning_hall_sudo_hack_challenge")
	await _resume_area("ctf_lobby", "Le point d’arrivée au CTF est repris depuis le menu")


func _compact_morning(capture_id: String, modal: bool) -> void:
	var original: Dictionary = settings.committed.duplicate(true)
	var large: Dictionary = original.duplicate(true)
	large.large_text = true
	large.reduce_transparency = true
	root.size = Vector2i(800, 480)
	_check(settings.apply_settings(large).ok, "Le matin fonctionne en 800 × 480 avec le grand texte")
	await _frames(10)
	if modal:
		await _check_modal_layout("câblage compact avec grand texte")
	else:
		await _check_hotel_hud_bounds("arrivée CTF compacte")
		var objective: Rect2 = app.demo.hotel_story.objective_panel.get_global_rect()
		_check(not objective.intersects(app.demo.campus_map.get_global_rect()), "La mission et la carte compactes ne se recouvrent pas")
	await _capture(capture_id)
	_check(settings.apply_settings(original).ok, "Les réglages habituels reviennent après la vue compacte")
	root.size = Vector2i(1280, 720)
	await _frames(8)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("MORNING_UI_FAIL : " + label)
