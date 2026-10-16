extends "res://tests/code_chapter_services_tests.gd"
const FOURTH := ["firewall","ip_conflict","subnet_mask"]

func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	shop = root.get_node("ShopService")
	rewards = root.get_node("RewardService")
	investigation = root.get_node("InvestigationService")
	state = root.get_node("AppState")
	test_root = "user://tests/campus_services_%s_%s" % [OS.get_process_id(),Time.get_ticks_usec()]
	saves.root_path = test_root
	state.clear_profile()
	_ok(shop.load_catalog(),"Catalogue")
	_ok(rewards.load_rules(),"Règles")
	var made: Dictionary = profiles.create_profile("Deux bâtiments")
	if not _ok(made,"Profil isolé"):
		_finish()
		return
	profile_id = str(made.data.id)
	_ok(profiles.start_game(),"Démarrage")
	var before: Dictionary = state.profile.duplicate(true)
	_check(not investigation.travel_zone("courtyard").ok,"Sortie verrouillée avant le mystère")
	_check(state.profile == before,"Sortie refusée sans effet")
	for chapter in [1,2,3,4]:
		if chapter > 1: _ok(investigation.enter_chapter(chapter),"Étage précédent")
		for id in [FIRST,SECOND,THIRD,FOURTH][chapter-1]: _complete(id)
		_check(not investigation.travel_zone("courtyard").ok,"Les chapitres 1 à 4 seuls n’ouvrent pas la sortie")
	_ok(investigation.enter_chapter(5),"Palier 5")
	_ok(investigation.enter_maze(),"Labyrinthe")
	_ok(investigation.terminal_login("admin","admin"),"Connexion")
	_ok(investigation.terminal_command("sudo","admin"),"Mystère réussi")
	_check(not investigation.travel_zone("courtyard").ok,"Aucune téléportation directe depuis le labyrinthe")
	_ok(investigation.leave_maze(),"Retour palier")
	for chapter in [4,3,2,1]:
		_check(not investigation.travel_zone("courtyard").ok,"La sortie n’existe pas aux étages supérieurs")
		_ok(investigation.enter_chapter(chapter),"Descente un étage à la fois")
		_check(state.profile.progress.room_id == "room_%02d" % chapter,"Chaque descente est enregistrée")
		_reload(profile_id)
	for destination in ["courtyard","building_02","courtyard","room_01"]:
		before = state.profile.duplicate(true)
		var raw := _disk(profile_id)
		saves.simulate_write_failure = true
		_check(not investigation.travel_zone(destination).ok,"Échec de sauvegarde du passage : " + destination)
		saves.simulate_write_failure = false
		_check(state.profile == before and _disk(profile_id) == raw,"Échec atomique mémoire et disque : " + destination)
		_ok(investigation.travel_zone(destination),"Porte franchie : " + destination)
		var saved: Dictionary = state.profile.duplicate(true)
		_reload(profile_id)
		_check(state.profile == saved,"Reprise exacte de la zone : " + destination)
		_check(state.profile.wallet.points == 650 and state.profile.rewarded_missions.size() == 13,"Passage sans nouveau point ni mission")
		if destination in ["courtyard","building_02"]:
			_check(investigation.current_chapter() == 0 and investigation.chapter_missions().is_empty(),"Exploration libre sans faux chapitre")
			_check(not investigation.enter_chapter(5).ok and not investigation.enter_maze().ok,"Revenir par la porte avant l’ascenseur")
			_check(not investigation.conclusion().ok,"Pas de bilan de mission dans la nouvelle zone")
		_check(not investigation.travel_zone(destination).ok,"Pas de passage répété vers sa propre zone")
		_test_bad_travel_saves()
	_check(not investigation.travel_zone("building_02").ok,"La cour doit être traversée")
	var original: Dictionary = state.profile.duplicate(true)
	var other: Dictionary = profiles.create_profile("Nouveau visiteur")
	_check(other.ok and not investigation.travel_zone("courtyard").ok,"Un autre profil n’hérite pas de l’accès")
	_reload(profile_id)
	_check(state.profile == original,"Le premier profil conserve ses acquis")
	_ok(profiles.start_game(),"Nouvelle partie")
	_check(state.profile.progress.room_id == "room_01" and not investigation.travel_zone("courtyard").ok,"Le rejeu redémarre dans le premier bâtiment")
	_check(state.profile.wallet.points == 650,"Le rejeu préserve le portefeuille")
	_finish()

func _test_bad_travel_saves() -> void:
	for pair in [["courtyard","elevator"],["building_02","from_first"],["room_02","new_entrance"],["courtyard","exit"],["building_02","entrance"]]:
		var invalid: Dictionary = state.profile.duplicate(true)
		invalid.progress.room_id = pair[0]
		invalid.progress.checkpoint_id = pair[1]
		_check(not saves.validate_profile(invalid).ok,"Point de passage incohérent refusé : " + str(pair))
	var early: Dictionary = state.profile.duplicate(true)
	early.progress.room_id = "courtyard"
	early.progress.checkpoint_id = "from_first"
	early.progress.completed_missions.erase("maze")
	early.progress.run_reward_points = 600
	_check(not saves.validate_profile(early).ok,"Une sauvegarde ne peut anticiper la sortie")
