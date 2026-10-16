extends "res://tests/code_chapter_services_tests.gd"
## Vrais services et vrais fichiers, exclusivement dans un répertoire isolé.

const FOURTH := ["firewall", "ip_conflict", "subnet_mask"]
var hotel
var hotel_wallet: Dictionary = {}
var hotel_inventory: Array = []
var hotel_rewards: Array = []
var before_bed: Dictionary = {}

func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	shop = root.get_node("ShopService")
	rewards = root.get_node("RewardService")
	investigation = root.get_node("InvestigationService")
	state = root.get_node("AppState")
	hotel = root.get_node("HotelService")
	test_root = "user://tests/hotel_services_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	saves.root_path = test_root
	state.clear_profile()
	_check(not hotel.reserve_room().ok and not hotel.travel("hotel_it").ok, "Aucun séjour sans profil")
	_check(hotel.state() == saves.empty_hotel_progress() and not hotel.is_hotel_zone(), "État neutre sans profil")
	if not _ok(shop.load_catalog(), "Catalogue") or not _ok(rewards.load_rules(), "Règles"):
		_finish()
		return
	var created: Dictionary = profiles.create_profile("Séjour hôtel")
	if not _ok(created, "Profil isolé créé"):
		_finish()
		return
	profile_id = str(created.data.id)
	_check(state.profile.progress.hotel == saves.empty_hotel_progress(), "Hôtel vide dans les nouveaux profils")
	_test_legacy_migration("profil non commencé")
	_ok(profiles.start_game(), "Démarrage")
	_test_early_actions()
	for chapter in [1, 2, 3, 4]:
		if chapter > 1:
			_ok(investigation.enter_chapter(chapter), "Chapitre précédent")
		for id in [FIRST, SECOND, THIRD, FOURTH][chapter - 1]:
			_complete(id)
		_test_legacy_migration("chapitre " + str(chapter))
	_ok(investigation.enter_chapter(5), "Palier du mystère")
	_ok(investigation.enter_maze(), "Labyrinthe")
	_ok(investigation.terminal_login("admin", "admin"), "Connexion")
	_test_legacy_migration("session authentifiée")
	_ok(investigation.terminal_command("sudo", "admin"), "Mystère réussi")
	_ok(investigation.leave_maze(), "Retour au palier")
	_assert_failed(Callable(hotel, "reserve_room"), "Réservation impossible depuis l’ancien bâtiment")
	for chapter in [4, 3, 2, 1]:
		_ok(investigation.enter_chapter(chapter), "Descente vers la sortie")
	_ok(investigation.travel_zone("courtyard"), "Sortie dans la cour")
	_test_legacy_migration("cour")
	_ok(investigation.travel_zone("building_02"), "Entrée du hall")
	_test_legacy_migration("ancien grand bâtiment 0.10.0")
	_ok(shop.purchase("avatar_orbit"), "Achat conservé pendant le séjour")
	hotel_wallet = state.profile.wallet.duplicate(true)
	hotel_inventory = state.profile.owned_items.duplicate(true)
	hotel_rewards = state.profile.rewarded_missions.duplicate(true)
	_test_reservation_and_repair()
	_test_stairs_and_room()
	_test_bed_choices()
	_test_invalid_hotel_documents()
	_test_profile_isolation_and_reset()
	_finish()

func _assert_failed(action: Callable, label: String, write_failure: bool = false) -> void:
	var before: Dictionary = state.profile.duplicate(true)
	var raw := _disk(profile_id)
	saves.simulate_write_failure = write_failure
	var result: Dictionary = action.call()
	saves.simulate_write_failure = false
	_check(not result.ok and not str(result.error).is_empty(), label + " : erreur expliquée")
	_check(state.profile == before and _disk(profile_id) == raw, label + " : mémoire et disque inchangés")

func _test_early_actions() -> void:
	for action in [
		Callable(hotel, "reserve_room"), Callable(hotel, "observe_repair").bind("storage"),
		Callable(hotel, "submit_repair"), Callable(hotel, "place_luggage"),
		Callable(hotel, "sit_on_bed"), Callable(hotel, "sleep_in_bed")
	]:
		_assert_failed(action, "Action d’hôtel anticipée")
	for destination in saves.HOTEL_ROOMS:
		_assert_failed(Callable(hotel, "travel").bind(destination), "Pas de téléportation anticipée : " + destination)
	var detached: Dictionary = hotel.state()
	detached.reserved = true
	detached.repair_observations.append("storage")
	_check(state.profile.progress.hotel == saves.empty_hotel_progress(), "L’état retourné est une copie indépendante")

func _test_legacy_migration(label: String) -> void:
	var modern: Dictionary = state.profile.duplicate(true)
	var legacy: Dictionary = modern.duplicate(true)
	legacy.progress.erase("hotel")
	var raw := JSON.stringify(legacy, "\t")
	_check(_write_raw(_path(profile_id), raw), "Ancien document préparé : " + label)
	state.clear_profile()
	var read: Dictionary = saves.read_profile(profile_id)
	_check(read.ok and read.migration_required and read.data == modern, "Migration hôtel sans perte : " + label)
	_check(_disk(profile_id) == raw, "Lecture ancienne sans écriture : " + label)
	saves.simulate_write_failure = true
	var failed: Dictionary = profiles.select_profile(profile_id)
	saves.simulate_write_failure = false
	_check(not failed.ok and state.profile.is_empty() and _disk(profile_id) == raw, "Migration échouée sans sélection partielle : " + label)
	_ok(profiles.select_profile(profile_id), "Migration enregistrée : " + label)
	_check(state.profile == modern and FileAccess.get_file_as_string(_path(profile_id) + ".bak") == raw, "Ancien profil conservé dans .bak : " + label)
	_check(not saves.read_profile(profile_id).migration_required, "Migration effectuée une seule fois : " + label)

func _travel(destination: String, checkpoint: String) -> void:
	_assert_failed(Callable(hotel, "travel").bind(destination), "Passage atomique vers " + destination, true)
	var result: Dictionary = hotel.travel(destination)
	_check(result.ok and result.data.room_id == destination and result.data.checkpoint_id == checkpoint, "Passage enregistré : " + destination)
	var before: Dictionary = state.profile.duplicate(true)
	_reload(profile_id)
	_check(state.profile == before, "Reprise exacte du passage : " + destination)
	_check(investigation.current_chapter() == 0 and investigation.chapter_missions().is_empty(), "Le séjour ne crée pas de faux chapitre")
	_check(not investigation.enter_chapter(5).ok and not investigation.enter_maze().ok, "L’ancien ascenseur reste dans son bâtiment")
	_check(state.profile.wallet == hotel_wallet and state.profile.owned_items == hotel_inventory and state.profile.rewarded_missions == hotel_rewards, "Passage sans frais ni récompense supplémentaire")
	_assert_failed(Callable(hotel, "travel").bind(destination), "Pas de passage vers sa propre salle")

func _test_reservation_and_repair() -> void:
	_check(hotel.is_hotel_zone() and hotel.is_hotel_zone("hotel_floor_2") and not hotel.is_hotel_zone("courtyard"), "Identification des zones de l’hôtel")
	_assert_failed(Callable(hotel, "travel").bind("hotel_it"), "Local fermé avant réservation")
	_assert_failed(Callable(hotel, "travel").bind("hotel_stairs_1"), "Escalier fermé avant réservation")
	_assert_failed(Callable(hotel, "reserve_room"), "Réservation atomique", true)
	_ok(hotel.reserve_room(), "Chambre 206 réservée et panne déclenchée")
	_check(hotel.state().reserved and not hotel.state().repaired and hotel.state().repair_observations.is_empty(), "La réservation déclenche la panne une seule fois")
	var before: Dictionary = state.profile.duplicate(true)
	_ok(hotel.reserve_room(), "Réservation déjà faite")
	_check(state.profile == before, "Réserver encore ne modifie ni le séjour ni les points")
	_assert_failed(Callable(hotel, "travel").bind("hotel_room_206"), "La chambre ne remplace pas l’escalier")
	_assert_failed(Callable(hotel, "travel").bind("hotel_stairs_1"), "Escalier fermé pendant la panne")
	_travel("hotel_it", "it_entrance")
	_assert_failed(Callable(hotel, "reserve_room"), "Réservation uniquement à la réception")
	_assert_failed(Callable(hotel, "observe_repair").bind("unknown"), "Observation inconnue refusée")
	for id in saves.HOTEL_REPAIR_IDS:
		_assert_failed(Callable(hotel, "submit_repair"), "Diagnostic avant toutes les observations")
		_assert_failed(Callable(hotel, "observe_repair").bind(id), "Observation atomique : " + id, true)
		_ok(hotel.observe_repair(id), "Observation réelle : " + id)
		before = state.profile.duplicate(true)
		_ok(hotel.observe_repair(id), "Observation déjà consultée : " + id)
		_check(state.profile == before, "Observation sans doublon : " + id)
		_reload(profile_id)
		_check(id in hotel.state().repair_observations, "Observation conservée après reprise : " + id)
	for diagnosis in ["", "network_down", "power_failure", "storage_full; restart"]:
		_assert_failed(Callable(hotel, "submit_repair").bind(diagnosis, "archive_logs_restart"), "Mauvais diagnostic : " + diagnosis)
	for repair in ["", "restart_only", "erase_reservations", "rm -rf /", "archive_logs_restart\nshutdown"]:
		_assert_failed(Callable(hotel, "submit_repair").bind("storage_full", repair), "Mauvaise réparation : " + repair)
	_assert_failed(Callable(hotel, "submit_repair"), "Réparation atomique", true)
	_ok(hotel.submit_repair(), "Journaux archivés et service redémarré")
	_check(hotel.state().repaired and hotel.state().repair_observations.size() == 4, "Réparation issue des quatre observations")
	before = state.profile.duplicate(true)
	_ok(hotel.submit_repair(), "Réparation déjà faite")
	_check(state.profile == before and state.profile.wallet == hotel_wallet, "Réparer encore ne paie aucun point")
	_travel("building_02", "hall_it")
	_travel("hotel_it", "it_entrance")
	_check(hotel.state().repaired, "Le retour dans le local ne redéclenche pas la panne")
	_travel("building_02", "hall_it")

func _test_stairs_and_room() -> void:
	_travel("hotel_stairs_1", "stairs_from_hall")
	for destination in ["hotel_floor_1", "hotel_room_106", "hotel_room_206", "courtyard", "room_01"]:
		_assert_failed(Callable(hotel, "travel").bind(destination), "Palier 1 limité aux escaliers : " + destination)
	_travel("building_02", "hall_stairs")
	_travel("hotel_stairs_1", "stairs_from_hall")
	_travel("hotel_floor_2", "floor2_stairs")
	_assert_failed(Callable(hotel, "place_luggage"), "Affaires uniquement dans la chambre")
	_travel("hotel_stairs_1", "stairs_from_floor2")
	_travel("hotel_floor_2", "floor2_stairs")
	_travel("hotel_room_206", "room206_entry")
	_assert_failed(Callable(hotel, "sit_on_bed"), "S’asseoir nécessite de poser les affaires")
	_assert_failed(Callable(hotel, "sleep_in_bed"), "Dormir nécessite de poser les affaires")
	_assert_failed(Callable(hotel, "place_luggage"), "Dépose des affaires atomique", true)
	_ok(hotel.place_luggage(), "Affaires posées")
	_check(hotel.state().luggage_placed and hotel.state().bed_state == "standing", "Affaires et lit sont deux étapes distinctes")
	var before: Dictionary = state.profile.duplicate(true)
	_ok(hotel.place_luggage(), "Affaires déjà posées")
	_check(state.profile == before, "La dépose répétée conserve l’état")
	before_bed = state.profile.duplicate(true)

func _test_bed_choices() -> void:
	_assert_failed(Callable(hotel, "sit_on_bed"), "Installation sur le lit atomique", true)
	_ok(hotel.sit_on_bed(), "Choix : se poser sur le lit")
	_check(hotel.state().bed_state == "sitting" and state.profile.progress.checkpoint_id == "room206_bed", "Position assise et point du lit enregistrés ensemble")
	var sitting: Dictionary = state.profile.duplicate(true)
	_reload(profile_id)
	_check(state.profile == sitting, "Reprise sur le lit après fermeture du logiciel")
	_assert_failed(Callable(hotel, "travel").bind("hotel_floor_2"), "Pas de choix caché pour descendre du lit")
	_assert_failed(Callable(investigation, "travel_zone").bind("courtyard"), "La sortie de l’hôtel ne contourne pas le lit")
	_ok(hotel.sit_on_bed(), "Continuer à attendre sur le lit")
	_check(state.profile == sitting, "Attendre conserve exactement la position assise")
	_assert_failed(Callable(hotel, "sleep_in_bed"), "Sommeil atomique depuis la position assise", true)
	_ok(hotel.sleep_in_bed(), "Choix : dormir après l’attente")
	_check(hotel.state().bed_state == "rested" and state.profile.progress.checkpoint_id == "room206_bed", "La nuit passée est enregistrée au lit")
	var slept: Dictionary = state.profile.duplicate(true)
	_reload(profile_id)
	_check(state.profile == slept, "Reprise après la nuit sans recommencer le choix")
	_ok(hotel.sleep_in_bed(), "Sommeil déjà accompli")
	_check(state.profile == slept, "Une seconde demande ne fait pas passer une nouvelle nuit")
	_assert_failed(Callable(hotel, "sit_on_bed"), "Le séjour terminé n’impose pas une nouvelle boucle d’attente")
	_travel("hotel_floor_2", "floor2_room206")
	_travel("hotel_room_206", "room206_entry")
	_check(hotel.state().bed_state == "rested", "Le retour dans la chambre conserve la nuit passée")
	_ok(saves.write_profile(before_bed), "Préparation du second choix indépendant")
	state.commit_profile(before_bed)
	_assert_failed(Callable(hotel, "sleep_in_bed"), "Sommeil direct atomique", true)
	_ok(hotel.sleep_in_bed(), "Choix : dormir directement")
	_check(hotel.state().bed_state == "rested" and state.profile.wallet == hotel_wallet, "Les deux chemins du lit aboutissent sans modifier l’économie")

func _test_invalid_hotel_documents() -> void:
	var valid: Dictionary = state.profile.duplicate(true)
	for field in saves.empty_hotel_progress():
		var missing: Dictionary = valid.duplicate(true)
		missing.progress.hotel.erase(field)
		_check(not saves.validate_profile(missing).ok, "État d’hôtel partiel refusé : " + field)
	for invalid_hotel in [null, true, 1, "hotel", [], {}]:
		var invalid: Dictionary = valid.duplicate(true)
		invalid.progress.hotel = invalid_hotel
		_check(not saves.validate_profile(invalid).ok, "Hôtel mal typé refusé")
	for field in ["version", "reserved", "repaired", "luggage_placed", "repair_observations", "bed_state"]:
		for wrong in [null, [], {}, "invalid", 100]:
			var invalid: Dictionary = valid.duplicate(true)
			invalid.progress.hotel[field] = wrong
			_check(not saves.validate_profile(invalid).ok, "Champ d’hôtel mal typé refusé : " + field)
	for mutation in ["unknown", "duplicate_observation", "unknown_observation", "unreserved", "repair_missing", "luggage_missing", "sitting_elsewhere", "sitting_checkpoint", "standing_checkpoint", "missing_hotel", "checkpoint_cross_room"]:
		var invalid: Dictionary = valid.duplicate(true)
		match mutation:
			"unknown": invalid.progress.hotel.extra = true
			"duplicate_observation": invalid.progress.hotel.repair_observations.append("storage")
			"unknown_observation": invalid.progress.hotel.repair_observations[0] = "invented"
			"unreserved": invalid.progress.hotel.reserved = false
			"repair_missing": invalid.progress.hotel.repair_observations.erase("storage")
			"luggage_missing": invalid.progress.hotel.luggage_placed = false
			"sitting_elsewhere":
				invalid.progress.hotel.bed_state = "sitting"
				invalid.progress.room_id = "building_02"
				invalid.progress.checkpoint_id = "new_entrance"
			"sitting_checkpoint":
				invalid.progress.hotel.bed_state = "sitting"
				invalid.progress.checkpoint_id = "room206_entry"
			"standing_checkpoint": invalid.progress.hotel.bed_state = "standing"
			"missing_hotel": invalid.progress.erase("hotel")
			"checkpoint_cross_room": invalid.progress.checkpoint_id = "floor2_stairs"
		_check(not saves.validate_profile(invalid).ok, "Progression d’hôtel incohérente refusée : " + mutation)
	for pair in [["hotel_it", "it_entrance"], ["hotel_stairs_1", "stairs_from_hall"], ["hotel_floor_2", "floor2_stairs"], ["hotel_room_206", "room206_entry"], ["building_02", "hall_it"], ["building_02", "hall_stairs"]]:
		var early: Dictionary = valid.duplicate(true)
		early.progress.hotel = saves.empty_hotel_progress()
		early.progress.room_id = pair[0]
		early.progress.checkpoint_id = pair[1]
		_check(not saves.validate_profile(early).ok, "Point de reprise avant son étape refusé : " + str(pair))
	var before_maze: Dictionary = valid.duplicate(true)
	before_maze.progress.room_id = "room_01"
	before_maze.progress.checkpoint_id = "entrance"
	before_maze.progress.completed_missions.erase("maze")
	before_maze.progress.clues.erase(investigation.mission("maze").clue.id)
	before_maze.progress.observations.maze = []
	before_maze.progress.run_reward_points = 600
	_check(not saves.validate_profile(before_maze).ok, "Réservation falsifiée avant le mystère refusée")
	_check(state.profile == valid and saves.read_profile(profile_id).data == valid, "Tous les refus laissent le véritable profil intact")

func _test_profile_isolation_and_reset() -> void:
	var completed: Dictionary = state.profile.duplicate(true)
	var other: Dictionary = profiles.create_profile("Autre client")
	_check(other.ok and hotel.state() == saves.empty_hotel_progress() and not hotel.reserve_room().ok, "Séjour isolé par profil")
	_reload(profile_id)
	_check(state.profile == completed and hotel.state().bed_state == "rested", "Le premier client retrouve sa chambre et son état")
	_ok(profiles.start_game(), "Nouvelle enquête")
	_check(state.profile.progress.hotel == saves.empty_hotel_progress() and state.profile.progress.room_id == "room_01", "Une nouvelle partie réinitialise entièrement le séjour")
	_check(state.profile.wallet == hotel_wallet and state.profile.owned_items == hotel_inventory and state.profile.rewarded_missions == hotel_rewards, "La nouvelle partie conserve points, achats et treize récompenses")
	_test_early_actions()
	_ok(profiles.reset_progress(), "Réinitialisation sans démarrer")
	_check(not state.profile.progress.started and hotel.state() == saves.empty_hotel_progress(), "La remise à zéro laisse un hôtel vierge")

func _finish() -> void:
	saves.simulate_write_failure = false
	state.clear_profile()
	_remove_tree(test_root)
	print("HOTEL_SERVICES : %d assertions, %d échec(s)." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
