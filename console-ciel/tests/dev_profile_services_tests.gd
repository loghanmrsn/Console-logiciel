extends SceneTree
## Isolated profile transactions; the preset uses the real save validator.
var checks := 0
var failures: Array[String] = []
var saves
var profiles
var state
var shop
var investigation
var test_root := ""

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("DEV_PROFILE_FAIL : ", message)

func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	state = root.get_node("AppState")
	shop = root.get_node("ShopService")
	investigation = root.get_node("InvestigationService")
	test_root = "user://tests/dev_profile_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	saves.root_path = test_root
	state.clear_profile()
	_check(shop.load_catalog().ok and root.get_node("RewardService").load_rules().ok, "Définitions réelles chargées")
	var made: Dictionary = profiles.create_profile("Joueur normal")
	_check(made.ok, "Profil normal créé pour l’isolation")
	if not made.ok:
		_finish()
		return
	var normal: Dictionary = state.profile.duplicate(true)
	var normal_id := str(normal.id)
	_check(not profiles.is_super_admin() and normal.wallet.points == 0, "Un profil normal ne possède pas le rôle ou les gains Dev")
	saves.simulate_write_failure = true
	_check(not profiles.use_dev_profile().ok and state.profile == normal, "Un stockage indisponible conserve le joueur actif")
	saves.simulate_write_failure = false
	var created: Dictionary = profiles.use_dev_profile()
	_check(created.ok, "Le profil Dev est créé et sélectionné")
	if not created.ok:
		print(created.error)
		_finish()
		return
	var dev: Dictionary = state.profile.duplicate(true)
	_check(dev.display_name == "Dev" and profiles.is_super_admin() and dev.role == "super_admin", "Identité et rôle persistants du super administrateur")
	_check(dev.progress.completed_missions == saves.MISSION_IDS, "Les treize vrais défis sont tous validés")
	_check(dev.rewarded_missions.size() == 15 and dev.wallet.points == 750, "Les récompenses uniques de l’enquête et du matin sont déjà comptabilisées")
	_check(dev.progress.hotel.repaired and dev.progress.hotel.coffee_connections == saves.COFFEE_WIRES and int(dev.progress.hotel.morning_stage) == 6, "Panne informatique, café et sac déjà terminés ; bus disponible")
	_check(saves.validate_profile(dev).ok and saves.read_profile(dev.id).data == dev, "Le document complet est validé et réellement enregistré")
	_check(saves.read_profile(normal_id).data == normal, "Créer Dev ne modifie pas le joueur normal")
	for chapter in range(1, 6):
		_check(investigation.can_enter_chapter(chapter) and investigation.enter_chapter(chapter).ok, "Le chapitre %d est débloqué" % chapter)
		for mission in investigation.chapter_missions(chapter):
			_check(investigation.mission_state(mission.id) == "completed", "Défi terminé selon le vrai service : " + str(mission.id))
	_check(shop.purchase("game_test_1").ok and state.profile.wallet.points == 550, "Les achats utilisent le solde réel de Dev")
	var purchased: Dictionary = state.profile.duplicate(true)
	_check(profiles.use_dev_profile().ok and state.profile == purchased, "Réutiliser le raccourci ne recrée ni ne crédite le profil")
	_check(profiles.start_game().ok and state.profile.progress.completed_missions.size() == 13 and state.profile.wallet.points == 550, "Recommencer Dev conserve les défis validés sans nouveaux points")
	_check(profiles.reset_progress().ok and state.profile.wallet.points == 550 and "game_test_1" in state.profile.owned_items, "La remise en place conserve achats et solde")
	_check(not profiles.update_profile("Autre nom", "avatar_default").ok and state.profile.display_name == "Dev", "Le nom dédié reste Dev")
	dev = state.profile.duplicate(true)
	_check(profiles.select_profile(normal_id).ok and state.profile == normal, "Retour au joueur normal sans progression préremplie")
	_check(profiles.start_game().ok and state.profile.progress.completed_missions.is_empty() and not profiles.is_super_admin(), "Une nouvelle enquête normale reste à résoudre")
	_check(profiles.use_dev_profile().ok and state.profile == dev, "Changer de profil restaure exactement le compte Dev utilisé")
	var fake: Dictionary = normal.duplicate(true)
	fake.role = "super_admin"
	_check(not saves.validate_profile(fake).ok, "Le rôle privilégié n’est pas accepté sur un identifiant de joueur")
	for role in ["admin", "root", 1, null, {}]:
		fake = normal.duplicate(true)
		fake.role = role
		_check(not saves.validate_profile(fake).ok, "Les rôles inconnus ou mal formés sont refusés")
	fake = dev.duplicate(true)
	fake.erase("role")
	_check(not saves.validate_profile(fake).ok, "L’identifiant dédié ne devient pas implicitement un joueur normal")
	var named: Dictionary = profiles.create_profile("Dev")
	_check(named.ok and not profiles.is_super_admin(), "Un pseudo Dev saisi dans la création normale n’accorde pas de rôle")
	_check(profiles.use_dev_profile().ok, "Le raccourci sélectionne le véritable compte réservé")
	var path: String = saves._path("profiles/%s.json" % saves.DEV_PROFILE_ID)
	var original := FileAccess.get_file_as_bytes(path)
	FileAccess.open(path, FileAccess.WRITE).store_string("{invalid")
	var before: Dictionary = state.profile.duplicate(true)
	state.clear_profile()
	_check(not profiles.use_dev_profile().ok and FileAccess.get_file_as_string(path) == "{invalid", "Un compte Dev endommagé n’est pas remplacé par le preset")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(original)
	file.close()
	_check(profiles.use_dev_profile().ok and state.profile == before, "La reprise conserve les données Dev restaurées")
	_finish()

func _remove_tree(path: String) -> void:
	if not path.begins_with(test_root): return
	var dir := DirAccess.open(path)
	if dir == null: return
	for file in dir.get_files(): dir.remove(file)
	for child in dir.get_directories(): _remove_tree(path.path_join(child))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _finish() -> void:
	saves.simulate_write_failure = false
	state.clear_profile()
	_remove_tree(test_root)
	print("DEV_PROFILE_SERVICES : %d assertions, %d échec(s)." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
