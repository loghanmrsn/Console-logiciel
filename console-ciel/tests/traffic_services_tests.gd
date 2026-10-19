extends "res://tests/morning_services_tests.gd"
## Real profile files and rewards; synthetic balances represent prior spending.
var penalties

func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	shop = root.get_node("ShopService")
	rewards = root.get_node("RewardService")
	investigation = root.get_node("InvestigationService")
	state = root.get_node("AppState")
	hotel = root.get_node("HotelService")
	penalties = root.get_node("PenaltyService")
	test_root = "user://tests/traffic_services_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	saves.root_path = test_root
	state.clear_profile()
	_check(not penalties.record_crossing("a".repeat(32)).ok, "Aucune pénalité sans profil")
	_ok(shop.load_catalog(), "Catalogue")
	_ok(rewards.load_rules(), "Règles")
	var created: Dictionary = profiles.create_profile("Passage piéton")
	if not _ok(created, "Profil isolé"):
		_finish()
		return
	profile_id = created.data.id
	_check(not state.profile.has("penalties") and penalties.state().count == 0, "Une ancienne forme de profil garde un compteur neutre, sans migration forcée")
	_ok(profiles.start_game(), "Début")
	_check(not penalties.record_crossing("a".repeat(32)).ok, "Pas de pénalité depuis un étage")
	_setup_stay(50)
	var court: Dictionary = state.profile.duplicate(true)
	court.progress.room_id = "courtyard"
	court.progress.checkpoint_id = "from_first"
	_install(court)
	_assert_failed(Callable(penalties, "record_crossing").bind("wrong"), "Identifiant de traversée invalide")
	_assert_failed(Callable(penalties, "record_crossing").bind("a".repeat(32)), "Retrait et compteur atomiques", true)
	_ok(penalties.record_crossing("a".repeat(32)), "Première pénalité")
	_check(state.profile.wallet.points == 450 and penalties.state().paid == 200 and penalties.state().debt == 0, "200 points retirés exactement")
	var before: Dictionary = state.profile.duplicate(true)
	var raw := _disk(profile_id)
	_ok(penalties.record_crossing("a".repeat(32)), "Même traversée soumise à nouveau")
	_check(state.profile == before and _disk(profile_id) == raw, "Une même traversée ne peut être facturée deux fois")
	_ok(penalties.record_crossing("b".repeat(32)), "Deuxième traversée")
	_check(penalties.state().count == 2 and state.profile.wallet.points == 250, "Une nouvelle traversée ajoute une seule pénalité")
	var spent: Dictionary = state.profile.duplicate(true)
	spent.wallet.points = 50
	_install(spent)
	_ok(penalties.record_crossing("c".repeat(32)), "Solde insuffisant")
	_check(state.profile.wallet.points == 0 and penalties.state().debt == 150 and penalties.state().paid == 450, "Le solde reste positif ou nul, le reste devient une dette de 150 points")
	before = state.profile.duplicate(true)
	_reload(profile_id)
	_check(state.profile == before, "La dette et les reçus survivent au rechargement")
	_test_invalid_penalties()
	_assert_failed(Callable(hotel, "travel").bind("building_02"), "Remboursement avec la récompense du hall atomique", true)
	var arrival: Dictionary = hotel.travel("building_02")
	_check(arrival.ok and arrival.reward == 50 and arrival.debt_repaid == 50 and state.profile.wallet.points == 0 and penalties.state().debt == 100, "Le gain du hall rembourse 50 points avant de créditer le portefeuille")
	_ok(hotel.arrive_ground_floor(), "Arrivée déjà récompensée")
	_check(penalties.state().debt == 100, "Rejouer l’arrivée ne rembourse pas une dette gratuitement")
	_ok(hotel.travel("hotel_breakfast"), "Petit déjeuner")
	_ok(hotel.sit_for_breakfast(), "Table")
	for top in saves.COFFEE_WIRES: _ok(hotel.connect_coffee_wire(top, saves.COFFEE_WIRES[top]), "Fil café")
	_ok(hotel.take_coffee(), "Café")
	for destination in ["building_02", "hotel_stairs_1", "hotel_floor_2", "hotel_room_206"]: _ok(hotel.travel(destination), "Retour chambre")
	var bag: Dictionary = hotel.collect_backpack()
	_check(bag.ok and bag.debt_repaid == 50 and bag.credited_points == 0 and penalties.state().debt == 50, "Le sac rembourse la dette dans la même transaction")
	var record: Dictionary = penalties.state()
	_ok(profiles.start_game(), "Nouvelle partie")
	_check(penalties.state() == record, "Une nouvelle partie conserve la dette et le compteur")
	var other: Dictionary = profiles.create_profile("Autre piéton")
	_ok(other, "Autre profil")
	_check(penalties.state().count == 0 and penalties.state().debt == 0, "Les dettes appartiennent au profil")
	_ok(profiles.start_game(), "Autre enquête")
	var owing: Dictionary = state.profile.duplicate(true)
	owing["penalties"] = {"version": 1, "count": 1, "debt": 200, "paid": 0, "last_event": "d".repeat(32)}
	_install(owing)
	_complete("lighting")
	_check(state.profile.wallet.points == 0 and penalties.state().debt == 150 and state.profile.progress.run_reward_points == 50, "Une récompense éducative rembourse aussi la dette, sans changer son reçu ni le total gagné")
	var detached: Dictionary = state.profile.duplicate(true)
	var credited: Dictionary = penalties.credit_reward(detached, 200)
	_check(credited.debt_repaid == 150 and credited.credited_points == 50 and detached.wallet.points == 50 and penalties.state(detached).debt == 0, "Le surplus d’un gain devient disponible après remboursement")
	_finish()

func _install(document: Dictionary) -> void:
	var saved: Dictionary = saves.write_profile(document)
	if _ok(saved, "Fixture de dépenses validée"):
		state.commit_profile(saved.data)

func _test_invalid_penalties() -> void:
	for field in ["count", "debt", "paid", "last_event", "version"]:
		var bad: Dictionary = state.profile.duplicate(true)
		bad.penalties.erase(field)
		_check(not saves.validate_profile(bad).ok, "Champ de pénalité partiel rejeté : " + field)
	for change in [{"count": -1}, {"debt": 1}, {"paid": -1}, {"last_event": "unsafe"}, {"version": 2}, {"count": 1.5}]:
		var bad: Dictionary = state.profile.duplicate(true)
		for key in change: bad.penalties[key] = change[key]
		_check(not saves.validate_profile(bad).ok, "Comptabilité de pénalité malformée rejetée")
