extends "res://tests/morning_ui_tests.gd"
## Six real, solid characters and native conversations, with isolated saves.
const People = preload("res://scripts/game/npc_catalog.gd")

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
	test_root = "user://tests/npc_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var values: Dictionary = settings.committed.duplicate(true)
	values.reduce_motion = true
	_check(settings.apply_settings(values).ok, "Préférences des PNJ isolées")
	var made: Dictionary = profiles.create_profile("Rencontres CIEL")
	_check(made.ok and profiles.start_game().ok, "Nouvelle enquête validée pour rencontrer Nora")
	if not made.ok:
		await _finish()
		return
	profile_id = str(made.data.id)
	root.size = Vector2i(1280, 720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(30)
	app._show_screen("home")
	await _activate("continue_game")
	await _frames(8)
	await _conversation("npc_workshop", "atelier", true)
	await _compact_conversation()
	_check(state.profile.wallet.points == 0 and state.profile.progress.completed_missions.is_empty(), "Les explications initiales n’accordent ni points ni mission")
	# Prepare later scenes through the validated educational service fixtures.
	if not _prepare_waking_save():
		await _finish()
		return
	await _frames(5)
	await _fixture_zone("room_05", "elevator")
	await _conversation("npc_top_floor", "ascenseur", false)
	await _fixture_zone("courtyard", "from_second")
	await _conversation("npc_hotel_door", "réception", true)
	await _conversation("npc_crossing", "feu", false)
	await _fixture_zone("building_02", "new_entrance")
	_check(int(hotel.state().morning_stage) == 2 and state.profile.wallet.points == 700, "L’arrivée réelle au rez-de-chaussée ouvre le petit déjeuner avec ses 50 points habituels")
	await _fixture_zone("hotel_breakfast", "breakfast_entry")
	await _conversation("npc_buffet", "table", true)
	await _fixture_zone("hotel_stairs_1", "stairs_from_hall")
	await _conversation("npc_closed_floor", "fermé", false)
	await _target("hotel_stairs_up")
	_check(app.demo.world.target_id == "hotel_stairs_up", "Le PNJ du palier ne remplace pas l’accès à l’escalier")
	_check(not _point_clear(Vector2(775, 150)), "La fermeture physique du premier étage reste en place")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "hotel_travel", "Monter reste possible depuis le palier fermé")
	await _activate("hotel_travel_go")
	_check(app.demo.world.room_id == "hotel_floor_2", "La chambre du deuxième étage reste accessible")
	await _fixture_zone("room_02", "elevator")
	_check(app.demo.world.get_interactable("network") != null, "Les défis du chapitre 2 dans le premier bâtiment sont conservés")
	var before: Dictionary = state.profile.duplicate(true)
	app.demo._interaction_requested("npc_not_defined")
	app.demo._interaction_requested("npc_buffet")
	_check(app.demo.overlay_kind.is_empty() and state.profile == before, "Un identifiant inconnu ou un PNJ d’un autre lieu n’ouvre aucun défi")
	_test_context()
	_check(state.profile.wallet.points == 700 and state.profile.rewarded_missions.size() == 14, "Les six rencontres ne créent aucune récompense supplémentaire")
	_check(saves.read_profile(profile_id).data == state.profile, "Les dialogues laissent le document sauvegardé intact")
	await _finish()

func _fixture_zone(zone: String, checkpoint: String) -> void:
	var fixture: Dictionary = state.profile.duplicate(true)
	fixture.progress.room_id = zone
	fixture.progress.checkpoint_id = checkpoint
	var written: Dictionary = saves.write_profile(fixture)
	_check(written.ok, "Changement de lieu validé : " + zone)
	if written.ok: state.commit_profile(written.data)
	await _physics_frames(4)
	await _frames(5)
	if not app.demo.overlay_kind.is_empty():
		await _key(KEY_ESCAPE)
	await _frames(4)
	_check(app.demo.world.room_id == zone, "Le vrai monde présente le lieu : " + zone)

func _approach_person(id: String) -> void:
	var spec := People.find(id)
	_check(not spec.is_empty(), "PNJ défini : " + id)
	if spec.is_empty(): return
	app.demo.world.player.position = spec.approach
	app.demo.world.player.facing = Vector2.UP
	await _physics_frames(4)
	await _frames(3)
	_check(_point_clear(spec.approach), "Approche libre : " + id)
	_check(app.demo.world.target_id == id, "La proximité physique sélectionne le PNJ : " + id)
	var body: Node = app.demo.world._props.get_node_or_null(NodePath(id))
	_check(body is StaticBody2D and body.get_parent().y_sort_enabled, "Le PNJ et le joueur partagent le tri de profondeur : " + id)
	_check(app.demo.world.player.test_move(Transform2D(0, spec.approach), spec.at - spec.approach), "Les pieds du PNJ bloquent réellement le joueur : " + id)
	var target = app.demo.world.get_interactable(id)
	_check(target != null and target.dialogue_marker and target.highlighted, "Une bulle distingue la discussion d’une épreuve : " + id)

func _conversation(id: String, fragment: String, controller: bool) -> void:
	await _approach_person(id)
	if app.demo.world.target_id != id: return
	await _capture(id + "_scene_challenge")
	var before: Dictionary = state.profile.duplicate(true)
	if controller: await _joy(JOY_BUTTON_A)
	else: await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "npc", "Le dialogue utilise sa présentation dédiée : " + id)
	if app.demo.overlay_kind != "npc": return
	_check(fragment in (_find("npc_dialogue_text") as Label).text.to_lower(), "Le discours correspond au contexte : " + id)
	_check((_find("npc_speaker") as Label).text == str(People.find(id).name), "Le portrait porte le nom du bon personnage")
	_check(not app.demo.world.player.controls_enabled and app.demo.paused, "Le joueur s’arrête pendant la conversation")
	var at: Vector2 = app.demo.world.player.position
	await _hold(KEY_D, 12)
	_check(app.demo.world.player.position.is_equal_approx(at), "La marche ne déplace pas le joueur derrière le dialogue")
	if is_instance_valid(app.demo.world.traffic):
		var remaining: float = app.demo.world.traffic.remaining
		var car_at: Vector2 = app.demo.world.traffic.cars[0].body.position
		await _frames(20)
		_check(is_equal_approx(app.demo.world.traffic.remaining, remaining) and app.demo.world.traffic.cars[0].body.position == car_at, "Voitures et feu restent figés pendant la discussion sur le trottoir")
	await _check_modal_layout(id)
	await _capture(id + "_dialogue_challenge")
	await _activate("npc_next", controller)
	_check("2 / 2" in (_find("npc_page_count") as Label).text, "La suite se lit sans quitter la conversation")
	var second_page: String = (_find("npc_dialogue_text") as Label).text
	if id == "npc_crossing":
		var panel := _find("npc_dialogue_panel")
		controllers.debug_connection_changed(0, false)
		await _frames(5)
		_check(app.demo.overlay_kind == "controller_pause", "La déconnexion de la manette suspend aussi une discussion")
		controllers.debug_connection_changed(0, true)
		await _frames(5)
		_check(app.demo.overlay_kind == "controller_pause", "La reconnexion ne ferme pas la discussion automatiquement")
		await _activate("controller_resume")
		_check(app.demo.overlay_kind == "npc" and _find("npc_dialogue_panel") == panel and (_find("npc_dialogue_text") as Label).text == second_page, "Reprendre restitue la même discussion, son portrait et la page courante")
	await _activate("npc_previous", not controller)
	_check("1 / 2" in (_find("npc_page_count") as Label).text, "La page précédente peut être relue")
	await _activate("npc_next", controller)
	_check((_find("npc_dialogue_text") as Label).text == second_page, "Relire ne change pas le contenu du dialogue")
	await _activate("npc_next", not controller)
	_check(app.demo.overlay_kind.is_empty() and not app.demo.paused, "Fermer la dernière page rend les commandes au jeu")
	_check(state.profile == before and saves.read_profile(profile_id).data == before, "Discuter ne modifie ni progression ni points : " + id)
	await _approach_person(id)
	saves.simulate_write_failure = true
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "npc", "Le dialogue fonctionne même si le stockage est indisponible")
	if controller: await _joy(JOY_BUTTON_B)
	else: await _key(KEY_ESCAPE)
	saves.simulate_write_failure = false
	_check(app.demo.overlay_kind.is_empty() and state.profile == before, "Retour clavier ou manette ferme sans enregistrer")

func _compact_conversation() -> void:
	await _approach_person("npc_workshop")
	var original: Dictionary = settings.committed.duplicate(true)
	var compact: Dictionary = original.duplicate(true)
	compact.large_text = true
	compact.appearance_style = "nuit"
	_check(settings.apply_settings(compact).ok, "Grand texte et thème nuit pour la conversation")
	root.size = Vector2i(800, 480)
	await _frames(12)
	await _key(KEY_SPACE)
	await _check_modal_layout("PNJ compact grand texte")
	await _activate("npc_next", true)
	await _check_modal_layout("PNJ compact deuxième page")
	await _capture("npc_compact_nuit_challenge")
	# A real pointer event activates the visible final button.
	var button := _find("npc_next") as Button
	var mouse := InputEventMouseButton.new()
	mouse.position = button.get_global_rect().get_center()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	await _frames(2)
	mouse = mouse.duplicate()
	mouse.pressed = false
	Input.parse_input_event(mouse)
	await _frames(6)
	_check(app.demo.overlay_kind.is_empty(), "Un clic réel ferme la conversation sur petit écran")
	root.size = Vector2i(1280, 720)
	_check(settings.apply_settings(original).ok, "Préférences restaurées après le contrôle compact")
	await _frames(12)

func _test_context() -> void:
	var input := {"completed_missions": [], "hotel": {"morning_stage": 3}}
	var before: Dictionary = input.duplicate(true)
	_check("panne" in People.pages("npc_buffet", input)[0], "Lucie explique la machine pendant la panne")
	_check(input == before, "La sélection d’un discours ne modifie pas sa donnée d’entrée")
	input.hotel.morning_stage = 4
	_check("prendre" in People.pages("npc_buffet", input)[0], "Lucie invite à prendre le café après réparation")
	input.hotel.morning_stage = 5
	_check("sac" in People.pages("npc_buffet", input)[1], "Lucie rappelle les affaires après le café")
	input.hotel.morning_stage = 6
	_check("bus" in People.pages("npc_hotel_door", input)[1], "Camille indique le bus une fois le sac récupéré")
	_check("réserver" in People.pages("npc_hotel_door", {})[1], "Camille présente la réservation avant le séjour")
	var mystery := " ".join(People.pages("npc_top_floor", {})).to_lower()
	_check(not "admin" in mystery and not "sudo" in mystery, "Idris préserve la découverte de l’épreuve mystère")
	_check(People.pages("npc_unknown", {}).is_empty(), "Aucun texte trompeur pour un personnage inconnu")
