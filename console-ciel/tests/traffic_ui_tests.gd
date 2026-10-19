extends "res://tests/morning_ui_tests.gd"
## Native walking, real Area2D cars, profile transactions and retained menus.
const Road = preload("res://scripts/game/road_layout.gd")
var notices: Array[String] = []
var penalties

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
	penalties = root.get_node("PenaltyService")
	controllers.debug_set_devices([0, 1])
	test_root = "user://tests/traffic_ui_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var values: Dictionary = settings.committed.duplicate(true)
	values.reduce_motion = true
	_check(settings.apply_settings(values).ok, "Réglages de circulation isolés")
	if not _prepare_waking_save():
		await _finish()
		return
	var baseline: Dictionary = state.profile.duplicate(true)
	baseline.progress.room_id = "courtyard"
	baseline.progress.checkpoint_id = "from_first"
	baseline.progress.hotel = saves.empty_hotel_progress()
	_install_view(baseline)
	root.size = Vector2i(1280, 720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(30)
	app._show_screen("home")
	await _activate("continue_game")
	await _frames(6)
	_check(app.demo.world.room_id == "courtyard" and is_instance_valid(app.demo.world.traffic), "Le monde réel instancie les voitures et leurs collisions")
	app.demo.world.traffic_notice.connect(func(text: String): notices.append(text))
	await _test_green_and_pause()
	await _test_red_crossing()
	await _test_car_hit()
	await _test_debt_and_retry()
	await _test_signal_cycle()
	var owing: Dictionary = state.profile.duplicate(true)
	await _resume_area("courtyard", "Les pénalités sont conservées en reprenant la partie")
	_check(state.profile == owing and penalties.state().debt == 150, "La reprise ne supprime ni dette ni reçu de traversée")
	await _capture_all_objects(baseline)
	await _finish()

func _install_view(document: Dictionary) -> void:
	var saved: Dictionary = saves.write_profile(document)
	_check(saved.ok, "Fixture de parcours entièrement validée")
	if saved.ok: state.commit_profile(saved.data)

func _safe_cars(phase: int) -> void:
	var traffic = app.demo.world.traffic
	traffic.phase = phase
	traffic.remaining = 20.0
	var positions := [100.0, 320.0, 1480.0, 1780.0]
	for index in range(traffic.cars.size()):
		traffic.cars[index].x = positions[index]
		traffic.cars[index].body.position = Vector2(positions[index], traffic.cars[index].y + 27)
	traffic.queue_redraw()

func _start(at: Vector2) -> void:
	app.demo.world.player.position = at
	app.demo.world.traffic.reset_for_spawn(at)
	app.demo._focus_room()

func _press(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func _walk_to_y(y: float, until_notice := false) -> bool:
	var code: Key = KEY_UP if app.demo.world.player.position.y > y else KEY_DOWN
	var initial_notices := notices.size()
	_press(code, true)
	var arrived := false
	for frame in range(240):
		await physics_frame
		var at: Vector2 = app.demo.world.player.position
		if until_notice and notices.size() > initial_notices:
			arrived = true
			break
		if absf(at.y - y) < 7:
			arrived = true
			break
	_press(code, false)
	await _frames(3)
	_check(arrived, "Le déplacement natif atteint la destination ou son événement attendu")
	return arrived

func _test_green_and_pause() -> void:
	_safe_cars(0)
	_start(Road.SOUTH)
	await _capture("traffic_passage_vert_challenge")
	await _key(KEY_P)
	var clock: float = app.demo.world.traffic.remaining
	var car_at: Vector2 = app.demo.world.traffic.cars[0].body.position
	await _physics_frames(15)
	_check(not app.demo.world.traffic.enabled and app.demo.world.traffic.remaining == clock and app.demo.world.traffic.cars[0].body.position == car_at, "La pause suspend le feu et les voitures")
	await _activate("pause_resume")
	await _walk_to_y(Road.NORTH.y)
	_check(penalties.state().count == 0 and state.profile.wallet.points == 650, "Traverser au vert ne coûte aucun point")
	_check(app.demo.world.traffic.attempt_side == 0, "La traversée se termine sur l’autre trottoir")
	# At a green expiry, a pedestrian already in the crossing is protected.
	_safe_cars(0)
	_start(Road.SOUTH)
	await _walk_to_y(800)
	app.demo.world.traffic.remaining = .01
	await _physics_frames(10)
	_check(app.demo.world.traffic.phase == 0, "Le vert laisse finir le piéton déjà engagé")
	await _walk_to_y(Road.NORTH.y)

func _test_red_crossing() -> void:
	_safe_cars(1)
	_start(Road.NORTH)
	await _capture("traffic_passage_rouge_challenge")
	await _walk_to_y(Road.SOUTH.y)
	_check(penalties.state().count == 1 and state.profile.wallet.points == 450, "Une traversée au rouge sans choc retire exactement 200 points")
	_check(app.demo.world.player.position.y > Road.ROAD.end.y, "Le rouge autorise le passage sans téléportation si aucune voiture ne touche le joueur")
	await _physics_frames(15)
	_check(penalties.state().count == 1, "Rester sur le trottoir ne facture pas de nouvelle pénalité")
	await _capture("traffic_penalite_200_challenge")
	_safe_cars(1)
	_start(Road.SOUTH)
	await _walk_to_y(800)
	await _walk_to_y(Road.SOUTH.y)
	_check(penalties.state().count == 1, "Un demi-tour vers le trottoir de départ ne compte pas comme une traversée")

func _test_car_hit() -> void:
	_safe_cars(1)
	_start(Road.SOUTH)
	var car = app.demo.world.traffic.cars[2]
	car.x = 940.0
	car.body.position = Vector2(940, car.y + 27)
	var before: Dictionary = state.profile.duplicate(true)
	await _walk_to_y(700, true)
	_check(notices.back().begins_with("Voiture touchée") and app.demo.world.player.position.distance_to(Road.SOUTH) < 12, "Le contact réel avec une voiture renvoie au début de la traversée")
	_check(state.profile == before, "Un choc ne réinitialise ni les missions ni les points et n’ajoute pas de pénalité de traversée")
	await _capture("traffic_collision_retour_challenge")
	_safe_cars(1)
	_start(Road.NORTH)
	car = app.demo.world.traffic.cars[0]
	car.x = 840.0
	car.body.position = Vector2(840, car.y + 27)
	await _walk_to_y(700, true)
	_check(app.demo.world.player.position.distance_to(Road.NORTH) < 12 and state.profile == before, "Un choc depuis l’autre bâtiment revient au trottoir nord sans débit")

func _test_debt_and_retry() -> void:
	var spent: Dictionary = state.profile.duplicate(true)
	spent.wallet.points = 50
	_install_view(spent)
	await _frames(4)
	_safe_cars(1)
	_start(Road.SOUTH)
	var before: Dictionary = state.profile.duplicate(true)
	saves.simulate_write_failure = true
	await _walk_to_y(Road.NORTH.y, true)
	saves.simulate_write_failure = false
	_check(notices.back().begins_with("Passage non enregistré") and state.profile == before and app.demo.world.player.position.distance_to(Road.SOUTH) < 12, "Une écriture refusée annule le passage et conserve le profil")
	_safe_cars(1)
	_start(Road.SOUTH)
	await _walk_to_y(Road.NORTH.y)
	_check(penalties.state().count == 2 and penalties.state().debt == 150 and state.profile.wallet.points == 0, "La traversée retentée conserve 150 points de dette sans solde négatif")
	_check("dette 150" in (_find("header_points") as Label).text, "La dette est affichée avec le solde du profil")
	await _capture("traffic_dette_150_challenge")
	await _key(KEY_P)
	var original: Dictionary = settings.committed.duplicate(true)
	var large: Dictionary = original.duplicate(true)
	large.large_text = true
	_check(settings.apply_settings(large).ok, "Grand texte")
	root.size = Vector2i(800, 480)
	await _activate("pause_resume")
	await _frames(8)
	var rect: Rect2 = app.demo.traffic_hud.get_global_rect()
	_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(rect), "Le panneau de circulation tient en 800 × 480")
	await _capture("traffic_compact_challenge")
	_check(settings.apply_settings(original).ok, "Retour aux réglages")
	root.size = Vector2i(1280, 720)
	await _frames(5)

func _test_signal_cycle() -> void:
	_safe_cars(1)
	_start(Road.NORTH)
	var traffic = app.demo.world.traffic
	traffic.remaining = .01
	await _physics_frames(5)
	_check(traffic.phase == 2, "Le rouge passe par une phase de dégagement avant le vert")
	await _physics_frames(260)
	_check(traffic.phase == 0 and traffic._crosswalk_clear(), "Le vert apparaît seulement après le dégagement des voitures")
	await _physics_frames(180)
	_check(traffic._crosswalk_clear(), "Les voitures restent arrêtées hors du passage pendant le vert")
	for index in [0, 2]:
		_check(absf(float(traffic.cars[index].x) - float(traffic.cars[index + 1].x)) >= 154, "Les voitures d’une même voie ne se superposent pas dans la file")
	await _capture("traffic_cycle_vert_challenge")

func _capture_all_objects(baseline: Dictionary) -> void:
	for zone in ["room_01", "room_02", "room_03", "room_04", "room_05", "maze_05", "building_02", "hotel_it", "hotel_stairs_1", "hotel_floor_2", "hotel_room_206", "hotel_breakfast", "ctf_bus_stop", "ctf_lobby"]:
		var document: Dictionary = baseline.duplicate(true)
		document.progress.room_id = zone
		document.progress.checkpoint_id = "maze_entry" if zone == "maze_05" else ("entrance" if zone == "room_01" else "elevator")
		if Hotel.is_zone(zone):
			document.progress.hotel.reserved = true
			document.progress.hotel.repaired = true
			document.progress.hotel.repair_observations = ["power", "network", "storage", "service"]
			var checkpoints: Dictionary = Hotel.checkpoints(zone)
			for key in checkpoints:
				if key != "entrance":
					document.progress.checkpoint_id = key
					break
			if zone in ["hotel_breakfast", "ctf_bus_stop", "ctf_lobby"]:
				document.progress.hotel.luggage_placed = true
				document.progress.hotel.bed_state = "rested"
				document.progress.hotel.morning_stage = 3
				document.rewarded_missions.append("hotel_ground_floor")
				if zone.begins_with("ctf_"):
					document.progress.hotel.morning_stage = 8
					document.progress.hotel.coffee_connections = saves.COFFEE_WIRES.duplicate()
					document.rewarded_missions.append("hotel_backpack")
		_install_view(document)
		await _frames(8)
		app.demo.world.restore_checkpoint()
		await _frames(4)
		_check(app.demo.world.room_id == zone, "Revue visuelle de la zone : " + zone)
		await _capture("objects_" + zone + "_challenge")
