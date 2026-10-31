extends "res://tests/appearance_tests.gd"
const Catalog = preload("res://scripts/game/city_network_catalog.gd")
func _run() -> void:
	await process_frame
	settings = root.get_node("SettingsService")
	saves = root.get_node("SaveService")
	var profiles = root.get_node("ProfileService")
	var state = root.get_node("AppState")
	var city = root.get_node("CityService")
	test_root = "user://tests/city_net_%s" % Time.get_ticks_usec()
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	_check(not city.submit("ipv4", {}).ok,"Profil nécessaire")
	var made: Dictionary = profiles.create_profile("Réseau City")
	_check(made.ok,"Profil normal créé")
	var document: Dictionary = load("res://scripts/services/dev_profile.gd").build().data
	document.id = made.data.id
	document.display_name = "Réseau City"
	document.role = "player"
	document.wallet.points = 0
	document.progress.school_wires = saves.COFFEE_WIRES.duplicate()
	document.progress.room_id = "school_network_lab"
	document.progress.checkpoint_id = "city_lab_entry"
	var saved: Dictionary = saves.write_profile(document)
	_check(saved.ok,"Ancien profil sans état City accepté")
	state.commit_profile(saved.data)
	var path: String = saves._path("profiles/"+document.id+".json")
	var untouched := FileAccess.get_file_as_string(path)
	_check(city.state() == Catalog.empty_state() and FileAccess.get_file_as_string(path) == untouched,"Lire ne migre ni n’écrit")
	_check(not city.submit("routing", Catalog.CHALLENGES.routing.answers).ok,"Ordre des exercices imposé")
	for id in Catalog.IDS:
		var before: Dictionary = state.profile.duplicate(true)
		var text := FileAccess.get_file_as_string(path)
		for invalid in [null, [], "255.255.255.0", {}, {"mask":"255.255.0.0"}, {"bits":"32","prefix":"32","network":"2001:db8::/32"}]:
			_check(not city.submit(id,invalid).ok and state.profile == before and FileAccess.get_file_as_string(path) == text,"Erreur de configuration sans effet : "+id)
		saves.simulate_write_failure = true
		_check(not city.submit(id, Catalog.CHALLENGES[id].answers).ok,"Erreur d’écriture signalée")
		saves.simulate_write_failure = false
		_check(state.profile == before and FileAccess.get_file_as_string(path) == text,"Échec atomique")
		var result: Dictionary = city.submit(id, Catalog.CHALLENGES[id].answers)
		_check(result.ok and result.reward == 50,"Validation et 50 points : "+id)
		_check(saves.read_profile(document.id).data == state.profile,"Disque et mémoire identiques")
		before = state.profile.duplicate(true)
		saves.simulate_write_failure = true
		_check(city.submit(id,Catalog.CHALLENGES[id].answers).reward == 0 and state.profile == before,"Relecture déjà validée sans crédit ni écriture")
		saves.simulate_write_failure = false
		state.clear_profile()
		_check(profiles.select_profile(document.id).ok,"Rechargement après réussite")
	_check(state.profile.wallet.points == 150 and city.state().completed == Catalog.IDS,"Trois configurations et 150 points")
	_check(Catalog.accepts("ipv6",{"bits":"128","prefix":"64","network":"2001:0DB8:0050:0001:0000:0000:0000:0000/64"}),"IPv6 étendue acceptée")
	_check(not Catalog.accepts("ipv6",{"bits":"128","prefix":"32","network":"2001:db8:50:1::/64"}),"/32 ne remplace pas /64 dans le LAN")
	var baseline: Dictionary = state.profile.duplicate(true)
	for malformed in [{"version":2,"completed":[]},{"version":1,"completed":["routing"]},{"version":1,"completed":["ipv4","ipv4"]},{"version":1,"completed":false}]:
		var bad := baseline.duplicate(true)
		bad.progress.city_network = malformed
		_check(not saves.validate_profile(bad).ok,"Progression City incohérente refusée")
	var revisit := baseline.duplicate(true)
	revisit.progress.erase("city_network")
	state.commit_profile(saves.write_profile(revisit).data)
	var repeated: Dictionary = city.submit("ipv4",Catalog.CHALLENGES.ipv4.answers)
	_check(repeated.ok and repeated.reward == 0 and state.profile.wallet.points == 150,"Rejouer après remise à zéro du parcours garde le reçu et ne paie pas deux fois")
	var lost_receipt := baseline.duplicate(true)
	lost_receipt.rewarded_missions.erase("city_ipv4")
	_check(not saves.validate_profile(lost_receipt).ok,"Réussite sans reçu refusée")
	var out := baseline.duplicate(true)
	out.progress.room_id = "school_workshop"
	out.progress.checkpoint_id = "school_workshop_entry"
	state.commit_profile(out)
	_check(not city.submit("ipv4",Catalog.CHALLENGES.ipv4.answers).ok,"Pas de soumission hors salle")
	# A historical debt is paid before the wallet; check using a fresh scenario.
	var debt := baseline.duplicate(true)
	debt.progress.erase("city_network")
	for receipt in Catalog.REWARD_IDS: debt.rewarded_missions.erase(receipt)
	debt.wallet.points = 0
	debt.penalties = {"version":1,"count":1,"debt":200,"paid":0,"last_event":"0123456789abcdef0123456789abcdef"}
	state.commit_profile(saves.write_profile(debt).data)
	var paid: Dictionary = city.submit("ipv4",Catalog.CHALLENGES.ipv4.answers)
	_check(paid.ok and paid.debt_repaid == 50 and state.profile.wallet.points == 0 and state.profile.penalties.debt == 150,"Récompense affectée à la dette existante")
	saves.simulate_write_failure = false
	state.clear_profile()
	_remove_tree(test_root)
	print("CITY_NETWORK_SERVICES : %d assertions, %d échec(s)." % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
