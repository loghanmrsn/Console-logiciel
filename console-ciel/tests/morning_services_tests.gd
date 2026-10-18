extends "res://tests/hotel_services_tests.gd"
## Parcours réel, migrations et transactions : aucune donnée utilisateur utilisée.

var morning_wallet := 0
var morning_run_points := 0
var morning_sleep_snapshot: Dictionary = {}

func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	shop = root.get_node("ShopService")
	rewards = root.get_node("RewardService")
	investigation = root.get_node("InvestigationService")
	state = root.get_node("AppState")
	hotel = root.get_node("HotelService")
	test_root = "user://tests/morning_services_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	saves.root_path = test_root
	state.clear_profile()
	for action in _morning_actions():
		_check(not action.call().ok, "La matinée exige un profil actif")
	if not _ok(shop.load_catalog(), "Catalogue") or not _ok(rewards.load_rules(), "Règles"):
		_finish()
		return
	var created: Dictionary = profiles.create_profile("Café et Sudo")
	if not _ok(created, "Profil isolé créé"):
		_finish()
		return
	profile_id = str(created.data.id)
	_check(saves.HOTEL_VERSION == 2 and hotel.state().morning_stage == 0 and hotel.state().coffee_connections.is_empty(), "Le séjour neuf commence avant la nuit")
	_ok(profiles.start_game(), "Début de l’enquête")
	_setup_stay(50)
	morning_wallet = int(state.profile.wallet.points)
	morning_run_points = int(state.profile.progress.run_reward_points)
	morning_sleep_snapshot = state.profile.duplicate(true)
	_check(morning_wallet == 650 and morning_run_points == 650, "Les treize défis précédents conservent leurs 650 points")
	_test_v1_migration()
	_test_morning_path(50)
	_test_malformed_morning()
	_test_replay_and_isolation()
	_finish()

func _morning_actions() -> Array:
	return [Callable(hotel, "arrive_ground_floor"), Callable(hotel, "sit_for_breakfast"), Callable(hotel, "connect_coffee_wire").bind("A", "3"), Callable(hotel, "take_coffee"), Callable(hotel, "collect_backpack"), Callable(hotel, "board_bus")]

func _setup_stay(expected_reward: int) -> void:
	for chapter in [1, 2, 3, 4]:
		if chapter > 1:
			_ok(investigation.enter_chapter(chapter), "Étage précédent")
		for id in [FIRST, SECOND, THIRD, FOURTH][chapter - 1]:
			_complete(id, expected_reward)
	_ok(investigation.enter_chapter(5), "Mystère")
	_ok(investigation.enter_maze(), "Labyrinthe")
	_ok(investigation.terminal_login("admin", "admin"), "Connexion")
	var result: Dictionary = investigation.terminal_command("sudo", "admin")
	_check(result.ok and result.data.reward == expected_reward, "Mystère réel, récompense unique")
	_ok(investigation.leave_maze(), "Retour du labyrinthe")
	for chapter in [4, 3, 2, 1]:
		_ok(investigation.enter_chapter(chapter), "Descente de l’ancien bâtiment")
	_ok(investigation.travel_zone("courtyard"), "Cour")
	_ok(investigation.travel_zone("building_02"), "Entrée hôtel")
	for action in _morning_actions():
		_assert_failed(action, "Action matinale avant la nuit refusée")
	_assert_failed(Callable(hotel, "travel").bind("hotel_breakfast"), "Petit déjeuner avant la nuit refusé")
	_ok(hotel.reserve_room(), "Réservation 206")
	_ok(hotel.travel("hotel_it"), "Local informatique")
	for id in saves.HOTEL_REPAIR_IDS:
		_ok(hotel.observe_repair(id), "Observation : " + id)
	_ok(hotel.submit_repair(), "Réparation du serveur")
	for destination in ["building_02", "hotel_stairs_1", "hotel_floor_2", "hotel_room_206"]:
		_ok(hotel.travel(destination), "Voyage : " + destination)
	_ok(hotel.place_luggage(), "Affaires posées")
	_ok(hotel.sleep_in_bed(), "Nuit passée")
	_check(hotel.state().morning_stage == 1 and hotel.state().bed_state == "rested", "Le réveil ouvre la mission du rez-de-chaussée")

func _test_v1_migration() -> void:
	var modern: Dictionary = state.profile.duplicate(true)
	for bed in ["standing", "sitting", "rested"]:
		var expected: Dictionary = modern.duplicate(true)
		expected.progress.hotel.bed_state = bed
		expected.progress.hotel.morning_stage = 1 if bed == "rested" else 0
		expected.progress.checkpoint_id = "room206_entry" if bed == "standing" else "room206_bed"
		var legacy: Dictionary = expected.duplicate(true)
		legacy.progress.hotel.version = 1
		legacy.progress.hotel.erase("morning_stage")
		legacy.progress.hotel.erase("coffee_connections")
		var raw := JSON.stringify(legacy, "\t")
		_check(_write_raw(_path(profile_id), raw), "Document 0.11 préparé : " + bed)
		state.clear_profile()
		var loaded: Dictionary = saves.read_profile(profile_id)
		_check(loaded.ok and loaded.migration_required and loaded.data == expected, "Migration complète 0.11 sans perte : " + bed)
		_check(_disk(profile_id) == raw, "Lecture sans écriture ni récompense : " + bed)
		saves.simulate_write_failure = true
		var failed: Dictionary = profiles.select_profile(profile_id)
		saves.simulate_write_failure = false
		_check(not failed.ok and state.profile.is_empty() and _disk(profile_id) == raw, "Migration échouée sans sélection partielle : " + bed)
		_ok(profiles.select_profile(profile_id), "Migration enregistrée : " + bed)
		_check(state.profile == expected and FileAccess.get_file_as_string(_path(profile_id) + ".bak") == raw, "Migration garde le document original : " + bed)
		_check(not saves.read_profile(profile_id).migration_required, "Migration unique : " + bed)
	for place in [["building_02", "hall_stairs"], ["courtyard", "from_second"], ["room_01", "building_exit"]]:
		var expected: Dictionary = modern.duplicate(true)
		expected.progress.room_id = place[0]
		expected.progress.checkpoint_id = place[1]
		var legacy: Dictionary = expected.duplicate(true)
		legacy.progress.hotel.version = 1
		legacy.progress.hotel.erase("morning_stage")
		legacy.progress.hotel.erase("coffee_connections")
		state.clear_profile()
		var raw := JSON.stringify(legacy, "\t")
		_check(_write_raw(_path(profile_id), raw), "Ancien client hors chambre : " + place[0])
		var loaded: Dictionary = saves.read_profile(profile_id)
		_check(loaded.ok and loaded.migration_required and loaded.data == expected and _disk(profile_id) == raw, "Migration garde sa position et ses points : " + place[0])
		_ok(profiles.select_profile(profile_id), "Reprise ancienne position : " + place[0])
		_check(state.profile == expected and state.profile.wallet.points == morning_wallet, "Réveil ancien sans gain à la lecture : " + place[0])
		if place[0] == "room_01":
			_ok(investigation.travel_zone("courtyard"), "Le client ancien peut revenir dans la cour")
		if place[0] in ["courtyard", "room_01"]:
			var entered: Dictionary = investigation.travel_zone("building_02")
			_check(entered.ok and entered.reward == 50 and hotel.state().morning_stage == 2, "Retour au hall attribue la première mission une seule fois")
	_ok(saves.write_profile(modern), "Réveil restauré")
	state.commit_profile(modern)
	# Un ancien client a pu fermer la version 0.11 alors qu’il était déjà au hall.
	var hall: Dictionary = modern.duplicate(true)
	hall.progress.room_id = "building_02"
	hall.progress.checkpoint_id = "hall_stairs"
	_ok(saves.write_profile(hall), "Ancien réveil directement au hall")
	state.commit_profile(hall)
	_assert_failed(Callable(hotel, "arrive_ground_floor"), "Arrivée migrée atomique", true)
	var arrived: Dictionary = hotel.arrive_ground_floor()
	_check(arrived.ok and arrived.reward == 50 and hotel.state().morning_stage == 2, "Le client déjà au hall reçoit sa mission une fois")
	var after: Dictionary = state.profile.duplicate(true)
	_check(hotel.arrive_ground_floor().ok and state.profile == after, "Rejouer l’arrivée au hall ne rapporte rien")
	_ok(saves.write_profile(modern), "Fixture avant le parcours réel restaurée")
	state.commit_profile(modern)

func _morning_travel(destination: String, reward: int = 0) -> void:
	_assert_failed(Callable(hotel, "travel").bind(destination), "Voyage atomique vers " + destination, true)
	var result: Dictionary = hotel.travel(destination)
	_check(result.ok and result.data.room_id == destination and result.data.reward == reward and result.reward == reward, "Voyage et récompense enregistrés : " + destination)
	var before: Dictionary = state.profile.duplicate(true)
	_reload(profile_id)
	_check(state.profile == before and saves.validate_profile(before).ok, "Voyage repris exactement : " + destination)
	_check(state.profile.progress.run_reward_points == morning_run_points, "La matinée ne change pas le bilan des treize défis")

func _test_wallet_limit(action: Callable, label: String) -> void:
	var initial: Dictionary = state.profile.duplicate(true)
	var full: Dictionary = initial.duplicate(true)
	full.wallet.points = saves.MAX_POINTS
	_ok(saves.write_profile(full), "Portefeuille plein : " + label)
	state.commit_profile(full)
	_assert_failed(action, "Plafond du portefeuille atomique : " + label)
	_ok(saves.write_profile(initial), "Portefeuille restauré : " + label)
	state.commit_profile(initial)

func _test_morning_path(reward: int) -> void:
	_assert_failed(Callable(hotel, "collect_backpack"), "Le sac attend le café")
	_assert_failed(Callable(hotel, "travel").bind("hotel_breakfast"), "Pas de téléportation de la chambre au petit déjeuner")
	_morning_travel("hotel_floor_2")
	_morning_travel("hotel_stairs_1")
	if reward > 0:
		_test_wallet_limit(Callable(hotel, "travel").bind("building_02"), "Mission rez-de-chaussée")
	_morning_travel("building_02", reward)
	_check(hotel.state().morning_stage == 2 and "hotel_ground_floor" in state.profile.rewarded_missions, "Arrivée au hall et reçu durable enregistrés ensemble")
	var settled: Dictionary = state.profile.duplicate(true)
	_check(hotel.arrive_ground_floor().ok and state.profile == settled, "Le hall n’attribue jamais deux fois ses points")
	_assert_failed(Callable(hotel, "travel").bind("courtyard"), "On ne part pas au CTF avant le café et le sac")
	_assert_failed(Callable(investigation, "travel_zone").bind("courtyard"), "L’ancienne API de porte ne contourne pas la matinée")
	_morning_travel("hotel_stairs_1")
	_morning_travel("building_02")
	_morning_travel("hotel_breakfast")
	_assert_failed(Callable(hotel, "connect_coffee_wire").bind("A", "3"), "On découvre le café oublié à table avant de réparer")
	_assert_failed(Callable(hotel, "take_coffee"), "Pas de café avant réparation")
	_assert_failed(Callable(hotel, "sit_for_breakfast"), "Installation à table atomique", true)
	_ok(hotel.sit_for_breakfast(), "Installation à table")
	_check(hotel.state().morning_stage == 3 and state.profile.progress.checkpoint_id == "breakfast_table", "Table et café oublié persistent ensemble")
	settled = state.profile.duplicate(true)
	_ok(hotel.sit_for_breakfast(), "Table déjà découverte")
	_check(state.profile == settled, "Répéter l’installation ne réinitialise pas la panne")
	for top in ["", "D", "a", "A", "B", "C"]:
		for bottom in ["", "0", "1", "2", "3", "4"]:
			if saves.COFFEE_WIRES.get(top, "invalid") != bottom:
				_assert_failed(Callable(hotel, "connect_coffee_wire").bind(top, bottom), "Mauvais raccord refusé : " + top + "/" + bottom)
	for top in ["C", "A", "B"]:
		var bottom: String = saves.COFFEE_WIRES[top]
		_assert_failed(Callable(hotel, "connect_coffee_wire").bind(top, bottom), "Raccord atomique : " + top, true)
		_ok(hotel.connect_coffee_wire(top, bottom), "Fils de même couleur raccordés : " + top + bottom)
		settled = state.profile.duplicate(true)
		_ok(hotel.connect_coffee_wire(top, bottom), "Raccord déjà enregistré")
		_check(state.profile == settled, "Un fil répété ne change rien")
		_reload(profile_id)
		_check(state.profile == settled and hotel.state().coffee_connections[top] == bottom, "Le raccord persiste après redémarrage")
		if hotel.state().coffee_connections.size() < 3:
			_check(hotel.state().morning_stage == 3, "La réparation attend les trois couleurs")
			_assert_failed(Callable(hotel, "take_coffee"), "Pas de café avec un circuit incomplet")
	_check(hotel.state().morning_stage == 4 and hotel.state().coffee_connections == {"A": "3", "B": "2", "C": "1"}, "Trois couleurs reliées valident exactement la réparation")
	_assert_failed(Callable(hotel, "take_coffee"), "Service du café atomique", true)
	_ok(hotel.take_coffee(), "Café servi")
	_check(hotel.state().morning_stage == 5, "Le café ouvre la récupération du sac")
	settled = state.profile.duplicate(true)
	_ok(hotel.take_coffee(), "Café déjà pris")
	_check(state.profile == settled, "Le café ne se reprend pas pour une récompense")
	_morning_travel("building_02")
	for destination in ["hotel_stairs_1", "hotel_floor_2", "hotel_room_206"]:
		_morning_travel(destination)
	if reward > 0:
		_test_wallet_limit(Callable(hotel, "collect_backpack"), "Mission sac")
	_assert_failed(Callable(hotel, "collect_backpack"), "Sac et points atomiques", true)
	var collected: Dictionary = hotel.collect_backpack()
	_check(collected.ok and collected.reward == reward and hotel.state().morning_stage == 6, "Sac et ordinateur récupérés avec leur récompense")
	_check("hotel_backpack" in state.profile.rewarded_missions, "Reçu de la mission sac conservé")
	settled = state.profile.duplicate(true)
	var repeated: Dictionary = hotel.collect_backpack()
	_check(repeated.ok and repeated.reward == 0 and state.profile == settled, "Le sac ne rapporte qu’une fois")
	_reload(profile_id)
	_check(state.profile == settled, "Sac et portefeuille persistants")
	_assert_failed(Callable(hotel, "board_bus"), "Le bus se prend à son arrêt")
	for destination in ["hotel_floor_2", "hotel_stairs_1", "building_02", "courtyard"]:
		_morning_travel(destination)
	_assert_failed(Callable(hotel, "board_bus"), "Trajet de bus atomique", true)
	var boarded: Dictionary = hotel.board_bus()
	_check(boarded.ok and boarded.data.room_id == "ctf_bus_stop" and boarded.data.checkpoint_id == "ctf_arrival" and hotel.state().morning_stage == 7, "Le bus arrive devant Sudo Hack avec le sac")
	_reload(profile_id)
	_check(state.profile.progress.room_id == "ctf_bus_stop" and hotel.state().morning_stage == 7, "Reprise à l’arrêt du CTF")
	_morning_travel("ctf_lobby")
	_check(hotel.state().morning_stage == 8 and state.profile.progress.checkpoint_id == "ctf_entry", "Entrée du CTF sans inventer les cinq missions futures")
	_morning_travel("ctf_bus_stop")
	_morning_travel("ctf_lobby")
	_check(state.profile.wallet.points == morning_wallet + reward * 2 and state.profile.progress.run_reward_points == morning_run_points, "Seules les deux missions demandées rapportent des points")
	_check(state.profile.progress.completed_missions.size() == 13 and state.profile.progress.observations.size() == 13, "Les cinq prochaines épreuves du CTF restent à créer")

func _test_malformed_morning() -> void:
	var valid: Dictionary = state.profile.duplicate(true)
	for field in ["morning_stage", "coffee_connections"]:
		var partial: Dictionary = valid.duplicate(true)
		partial.progress.hotel.erase(field)
		_check(not saves.validate_profile(partial).ok, "Extension partielle refusée : " + field)
	for stage in [-1, 9, 1.5, null, true, "8", [], {}]:
		var invalid: Dictionary = valid.duplicate(true)
		invalid.progress.hotel.morning_stage = stage
		_check(not saves.validate_profile(invalid).ok, "Étape mal typée ou inconnue refusée")
	for wires in [null, true, [], "A3", {"A": 3}, {"A": "1"}, {"D": "3"}, {1: "3"}, {"A": "3", "B": "2"}, {"A": "3", "B": "2", "C": "1", "D": "4"}]:
		var invalid: Dictionary = valid.duplicate(true)
		invalid.progress.hotel.coffee_connections = wires
		_check(not saves.validate_profile(invalid).ok, "Circuit mal typé ou incohérent refusé")
	for mutation in ["night_missing", "ground_receipt_missing", "bag_receipt_missing", "ctf_without_bus", "bus_before_bag", "room_after_bus", "partial_v1", "v1_new_room", "v1_bad_bed", "unknown_receipt", "duplicate_receipt"]:
		var invalid: Dictionary = valid.duplicate(true)
		match mutation:
			"night_missing": invalid.progress.hotel.bed_state = "standing"
			"ground_receipt_missing": invalid.rewarded_missions.erase("hotel_ground_floor")
			"bag_receipt_missing": invalid.rewarded_missions.erase("hotel_backpack")
			"ctf_without_bus": invalid.progress.hotel.morning_stage = 6
			"bus_before_bag":
				invalid.progress.room_id = "ctf_bus_stop"
				invalid.progress.checkpoint_id = "ctf_arrival"
				invalid.progress.hotel.morning_stage = 5
			"room_after_bus":
				invalid.progress.room_id = "hotel_room_206"
				invalid.progress.checkpoint_id = "room206_entry"
			"partial_v1": invalid.progress.hotel.version = 1
			"v1_new_room":
				invalid.progress.hotel.version = 1
				invalid.progress.hotel.erase("morning_stage")
				invalid.progress.hotel.erase("coffee_connections")
			"v1_bad_bed":
				invalid.progress.room_id = "hotel_room_206"
				invalid.progress.checkpoint_id = "room206_entry"
				invalid.progress.hotel.version = 1
				invalid.progress.hotel.erase("morning_stage")
				invalid.progress.hotel.erase("coffee_connections")
				invalid.progress.hotel.bed_state = 1
			"unknown_receipt": invalid.rewarded_missions.append("hotel_coffee")
			"duplicate_receipt": invalid.rewarded_missions.append("hotel_backpack")
		_check(not saves.validate_profile(invalid).ok, "Matinée incohérente refusée : " + mutation)
	var detached: Dictionary = hotel.state()
	detached.morning_stage = 0
	detached.coffee_connections.clear()
	_check(state.profile == valid and saves.read_profile(profile_id).data == valid, "Les refus et copies externes ne changent jamais le profil")

func _test_replay_and_isolation() -> void:
	var finished: Dictionary = state.profile.duplicate(true)
	var other: Dictionary = profiles.create_profile("Autre café")
	_check(other.ok and state.profile.wallet.points == 0 and state.profile.rewarded_missions.is_empty() and hotel.state().morning_stage == 0, "La matinée et ses points sont propres à chaque profil")
	_reload(profile_id)
	_check(state.profile == finished, "Le premier joueur retrouve le CTF et son sac")
	_ok(profiles.start_game(), "Nouvelle partie après Sudo Hack")
	_check(hotel.state() == saves.empty_hotel_progress() and state.profile.rewarded_missions.size() == 15 and state.profile.wallet.points == 750, "Nouvelle partie réinitialise l’histoire et conserve les quinze reçus")
	morning_wallet = int(state.profile.wallet.points)
	morning_run_points = 0
	_setup_stay(0)
	_test_morning_path(0)
	_check(state.profile.wallet.points == 750 and state.profile.progress.run_reward_points == 0, "Rejouer tout le séjour ne permet pas de produire des points")
	_ok(profiles.reset_progress(), "Réinitialisation hors partie")
	_check(not state.profile.progress.started and hotel.state() == saves.empty_hotel_progress() and state.profile.rewarded_missions.size() == 15 and state.profile.wallet.points == 750, "Réinitialisation conserve points, achats et reçus de la matinée")

func _finish() -> void:
	saves.simulate_write_failure = false
	state.clear_profile()
	_remove_tree(test_root)
	print("MORNING_SERVICES : %d assertions, %d échec(s)." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
