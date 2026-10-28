extends SceneTree
var checks := 0
var failures: Array[String] = []
var saves
var profiles
var state
var console
var investigation
var test_root := ""

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("DEV_CONSOLE_FAIL : ", message)

func _unchanged(command: String) -> void:
	var before: Dictionary = state.profile.duplicate(true)
	var path: String = saves._path("profiles/%s.json" % before.id)
	var raw := FileAccess.get_file_as_bytes(path)
	var result: Dictionary = console.execute(command)
	_check(not result.ok and not result.error.is_empty(), "Commande refusée et expliquée : " + command)
	_check(state.profile == before and FileAccess.get_file_as_bytes(path) == raw, "Refus sans écriture ni mutation : " + command)

func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	state = root.get_node("AppState")
	console = root.get_node("DevConsoleService")
	investigation = root.get_node("InvestigationService")
	test_root = "user://tests/dev_console_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	saves.root_path = test_root
	state.clear_profile()
	_check(not console.execute("help").ok, "Aucun terminal sans profil actif")
	_check(root.get_node("ShopService").load_catalog().ok and root.get_node("RewardService").load_rules().ok, "Définitions chargées")
	_check(profiles.create_profile("Dev").ok, "Un joueur ordinaire peut s'appeler Dev")
	var normal: Dictionary = state.profile.duplicate(true)
	for command in ["help", "add coins 500", "skip missions", "reset missions", "status"]: _unchanged(command)
	_check(profiles.use_dev_profile().ok, "Compte dédié sélectionné")
	var initial: Dictionary = state.profile.duplicate(true)
	for command in ["help", "status", "clear"]:
		_check(console.execute(command).ok and state.profile == initial, "Commande de lecture sans mutation : " + command)
	for command in ["", "add coins", "add coins 0", "add coins -1", "add coins 1.5", "add coins 1e3", "add coins +5", "add coins 99999999999", "add coins 2147483647", "add coins 5 extra", "add coins ٥", "add coins 5\nreset missions", "sudo rm -rf /", "x".repeat(257)]: _unchanged(command)
	saves.simulate_write_failure = true
	_unchanged("add coins 500")
	_unchanged("reset missions")
	saves.simulate_write_failure = false
	_check(console.execute("  ADD  COINS  321  ").ok and state.profile.wallet.points == 1321, "Montant personnalisé et espaces/casse de commande acceptés")
	_check(state.profile.progress == initial.progress and state.profile.rewarded_missions == initial.rewarded_missions, "Ajouter des pièces ne modifie ni défis ni reçus")
	var snapshot: Dictionary = state.profile.duplicate(true)
	state.clear_profile()
	_check(profiles.use_dev_profile().ok and state.profile == snapshot, "Le solde modifié persiste après sélection")
	_check(console.execute("reset missions").ok and state.profile.progress.completed_missions.is_empty() and state.profile.wallet.points == 1321, "Parcours rejouable sans perdre le portefeuille")
	# A valid dedicated Dev with no past receipts exercises each new skip receipt.
	var fixture: Dictionary = state.profile.duplicate(true)
	fixture.rewarded_missions.clear()
	_check(saves.write_profile(fixture).ok, "Départ Dev sans reçus validé")
	state.commit_profile(fixture)
	for chapter in range(1, 6):
		if chapter > 1: _check(investigation.enter_chapter(chapter).ok, "Accès au chapitre suivant")
		for mission in investigation.chapter_missions(chapter):
			var before: Dictionary = state.profile.duplicate(true)
			saves.simulate_write_failure = true
			_unchanged("skip missions")
			saves.simulate_write_failure = false
			var result: Dictionary = console.execute("skip mission" if mission.id == "python" else "skip missions")
			_check(result.ok and state.profile.progress.completed_missions.size() == before.progress.completed_missions.size() + 1, "Une seule mission passée : " + str(mission.id))
			_check(mission.id in state.profile.rewarded_missions and saves.read_profile(state.profile.id).data == state.profile, "Preuves, reçu et disque cohérents : " + str(mission.id))
			_check(state.profile.wallet.points == 1321 and state.profile.progress.run_reward_points == 0, "Skip sans points : " + str(mission.id))
		_unchanged("skip missions")
	for chapter in [4, 3, 2, 1]: _check(investigation.enter_chapter(chapter).ok, "Descente après mystère passé")
	_check(investigation.travel_zone("courtyard").ok, "Sortie réelle vers la ville")
	var hotel_steps := 0
	while int(state.profile.progress.hotel.morning_stage) < 9 and hotel_steps < 30:
		var before: Dictionary = state.profile.duplicate(true)
		saves.simulate_write_failure = true
		_unchanged("skip missions")
		saves.simulate_write_failure = false
		var result: Dictionary = console.execute("skip missions")
		_check(result.ok and state.profile != before, "Objectif hôtel/CTF passé : " + str(result.get("message", result.get("error", ""))))
		_check(state.profile.wallet.points == 1321 and saves.validate_profile(state.profile).ok, "Skip hôtel/CTF sans points et état valide")
		hotel_steps += 1
	_check(hotel_steps == 17 and state.profile.progress.room_id == "courtyard" and state.profile.progress.ctf.completed.size() == 5, "Le parcours complet rejoint la ville après les cinq postes")
	_unchanged("skip missions")
	_check(saves.read_profile(normal.id).data == normal, "Le joueur ordinaire reste inchangé")
	_check(profiles.select_profile(normal.id).ok, "Retour au joueur ordinaire")
	_unchanged("add coins 100")
	_finish()

func _remove_tree(path: String) -> void:
	if not path.begins_with(test_root): return
	var directory := DirAccess.open(path)
	if directory == null: return
	for file in directory.get_files(): directory.remove(file)
	for child in directory.get_directories(): _remove_tree(path.path_join(child))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _finish() -> void:
	state.clear_profile()
	_remove_tree(test_root)
	print("DEV_CONSOLE : %d assertions, %d échec(s)." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
