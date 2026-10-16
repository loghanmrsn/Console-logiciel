extends "res://tests/code_chapter_services_tests.gd"
const FOURTH := ["firewall", "ip_conflict", "subnet_mask"]

func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	shop = root.get_node("ShopService")
	rewards = root.get_node("RewardService")
	investigation = root.get_node("InvestigationService")
	state = root.get_node("AppState")
	test_root = "user://tests/network_lab_services_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	saves.root_path = test_root
	state.clear_profile()
	if not _ok(shop.load_catalog(), "Catalogue") or not _ok(rewards.load_rules(), "Règles à douze missions"):
		_finish()
		return
	var created: Dictionary = profiles.create_profile("Réseau CIEL")
	if not _ok(created, "Profil de test isolé"):
		_finish()
		return
	profile_id = str(created.data.id)
	_ok(profiles.start_game(), "Nouvelle enquête")
	_check(rewards.missions.size() == 13 and _ids(investigation.chapter_missions(4)) == FOURTH, "Treize missions et trois nouveaux diagnostics ordonnés")
	_check(not investigation.enter_chapter(4).ok and not investigation.submit_diagnostic("firewall", "rule_missing", "allow_https_only").ok, "Le chapitre 4 ne peut pas être sauté")
	for chapter in [1, 2, 3]:
		if chapter > 1: _ok(investigation.enter_chapter(chapter), "Préparer étage précédent")
		for id in [FIRST, SECOND, THIRD][chapter - 1]:
			_check(not investigation.can_enter_chapter(4), "Étage 4 verrouillé avant les neuf réussites : " + id)
			_complete(id)
	_check(investigation.can_enter_chapter(4) and state.profile.wallet.points == 450, "L’atelier code ouvre le laboratoire sans changer les anciens gains")
	_test_legacy_nine()
	_ok(investigation.enter_chapter(4), "Ascenseur vers le laboratoire")
	_check(state.profile.progress.room_id == "room_04", "Nouvelle salle persistée")
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/game_rules.json"))
	for mutation in ["room", "prerequisite", "solution", "observations"]:
		var bad: Dictionary = rules.duplicate(true)
		match mutation:
			"room": bad.missions[9].room_id = "room_03"
			"prerequisite": bad.missions[9].prerequisites = ["html"]
			"solution": bad.missions[11].solution.repair = "set_mask_24"
			"observations": bad.missions[10].observations.pop_back()
		_check(not saves.validate_rules(bad).ok, "Règles du laboratoire altérées refusées : " + mutation)
	for id in FOURTH:
		var definition: Dictionary = investigation.mission(id)
		var before: Dictionary = state.profile.duplicate(true)
		_check(not investigation.submit_diagnostic(id, definition.solution.diagnosis, definition.solution.repair).ok, "Les observations ne peuvent pas être sautées : " + id)
		_check(state.profile == before, "Réponse anticipée sans mutation : " + id)
		_ok(investigation.begin_mission(id), "Défi du laboratoire ouvert")
		for observation in definition.observations: _ok(investigation.observe(id, observation.id), "Indice consulté")
		before = state.profile.duplicate(true)
		for diagnosis in definition.diagnoses:
			if diagnosis.id != definition.solution.diagnosis:
				_check(not investigation.submit_diagnostic(id, diagnosis.id, definition.solution.repair).ok, "Mauvais diagnostic refusé : " + diagnosis.id)
		for repair in definition.repairs:
			if repair.id != definition.solution.repair:
				_check(not investigation.submit_diagnostic(id, definition.solution.diagnosis, repair.id).ok, "Mauvaise correction refusée : " + repair.id)
		_check(not rewards.complete_mission(id).ok and not rewards._complete_validated_mission(id, "fake").ok, "Pas de récompense directe")
		_check(state.profile == before and saves.read_profile(profile_id).data == before, "Les erreurs gardent les données et points intacts")
		saves.simulate_write_failure = true
		_check(not investigation.submit_diagnostic(id, definition.solution.diagnosis, definition.solution.repair).ok, "Échec d’écriture remonté")
		saves.simulate_write_failure = false
		_check(state.profile == before and saves.read_profile(profile_id).data == before, "Échec de réussite atomique sans gain ni mission partielle")
		var result: Dictionary = investigation.submit_diagnostic(id, definition.solution.diagnosis, definition.solution.repair)
		_check(result.ok and result.data.reward == 50, "Réussite ajoute exactement 50 points")
		_check(saves.read_profile(profile_id).data == state.profile and state.profile.progress.checkpoint_id == id, "Réussite persistée avec son checkpoint")
		var replay: Dictionary = investigation.submit_diagnostic(id, definition.solution.diagnosis, definition.solution.repair)
		_check(replay.ok and replay.data.reward == 0, "Soumission répétée sans gain")
	_check(state.profile.wallet.points == 600 and state.profile.rewarded_missions.size() == 12 and investigation.conclusion(4).ok, "Quatre chapitres, douze réussites, 600 points et bilan")
	var final: Dictionary = state.profile.duplicate(true)
	for chapter in [3, 2, 1, 2, 3, 4]: _ok(investigation.enter_chapter(chapter), "Revisite des étages accessible")
	_check(state.profile.wallet == final.wallet and state.profile.rewarded_missions == final.rewarded_missions, "Trajets sans altération économique")
	_ok(profiles.start_game(), "Rejouer après le laboratoire")
	for chapter in [1, 2, 3, 4]:
		if chapter > 1: _ok(investigation.enter_chapter(chapter), "Rejeu : ascenseur")
		for id in [FIRST, SECOND, THIRD, FOURTH][chapter - 1]: _complete(id, 0)
	_check(state.profile.wallet.points == 600 and state.profile.progress.run_reward_points == 0 and state.profile.progress.completed_missions.size() == 12, "Rejouer les douze missions ne génère aucun point supplémentaire")
	_finish()

func _test_legacy_nine() -> void:
	var modern: Dictionary = state.profile.duplicate(true)
	var legacy: Dictionary = modern.duplicate(true)
	for id in FOURTH + saves.CHAPTER_FIVE_IDS: legacy.progress.observations.erase(id)
	var raw := JSON.stringify(legacy, "\t")
	_check(_write_raw(_path(profile_id), raw), "Profil 0.7.1 à neuf clés préparé")
	state.clear_profile()
	var read: Dictionary = saves.read_profile(profile_id)
	_check(read.ok and read.migration_required and read.data == modern, "Ancien profil enrichi sans changer identité, monnaie, achats et missions")
	_check(_disk(profile_id) == raw, "La lecture seule ne remplace pas le document")
	saves.simulate_write_failure = true
	_check(not profiles.select_profile(profile_id).ok and state.profile.is_empty(), "Migration échouée sans profil partiel")
	saves.simulate_write_failure = false
	_check(_disk(profile_id) == raw, "Ancienne sauvegarde conservée après échec")
	_ok(profiles.select_profile(profile_id), "Migration à la sélection")
	_check(state.profile == modern and FileAccess.get_file_as_string(_path(profile_id) + ".bak") == raw, "Sauvegarde d’origine conservée dans .bak")
	_check(not saves.read_profile(profile_id).migration_required, "Migration unique")
