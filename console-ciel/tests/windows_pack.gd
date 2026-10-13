extends SceneTree
## Run externally with --main-pack Console_CIEL.exe; not shipped in the PCK.
## Tests exported resources on the host Godot engine, not the Windows executable.
var assertions := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		print("WINDOWS_PACK_FAIL : " + message)

func _run() -> void:
	await process_frame
	var exported_config := "res://".path_join("project.binary")
	check(FileAccess.file_exists(exported_config), "Configuration exportée présente")
	check(not FileAccess.file_exists("res://tests/windows_pack.gd"), "Tests exclus de la livraison")
	for path in ["res://scenes/main.tscn", "res://scenes/startup.tscn", "res://scenes/demo_game.tscn", "res://scenes/investigation_world.tscn", "res://themes/console_theme.tres", "res://default_bus_layout.tres", "res://assets/audio/menu.wav", "res://assets/audio/confirm.wav", "res://assets/console.svg"]:
		check(ResourceLoader.load(path) != null, "Ressource exportée : " + path)
	for path in ["res://data/shop_catalog.json", "res://data/game_rules.json", "res://data/controller_mapping.json", "res://assets/LICENSES.md", "res://assets/licenses/GODOT_MIT.txt"]:
		check(FileAccess.file_exists(path), "Donnée ou licence exportée : " + path)
	var saves = root.get_node("SaveService")
	var profiles = root.get_node("ProfileService")
	var shop = root.get_node("ShopService")
	var rewards = root.get_node("RewardService")
	var investigation = root.get_node("InvestigationService")
	var settings = root.get_node("SettingsService")
	var state = root.get_node("AppState")
	# The launcher supplies a disposable XDG home. Keep every fixture in tests/.
	saves.root_path = "user://tests/windows_pack_%s" % Time.get_ticks_usec()
	check(settings.load_settings().ok and not settings.current.fullscreen, "Premier lancement en fenêtre")
	check(shop.load_catalog().ok and rewards.load_rules().ok, "Catalogue et missions exportés valides")
	var first: Dictionary = profiles.create_profile("Test export A")
	var second: Dictionary = profiles.create_profile("Test export B")
	check(first.ok and second.ok, "Création de deux profils isolés")
	if not first.ok or not second.ok:
		_finish()
		return
	var first_id: String = first.data.id
	check(profiles.select_profile(first_id).ok, "Sélection du profil A")
	check(profiles.start_game().ok, "Nouvelle enquête avec scripts compilés")
	check(investigation.begin_mission("lighting").ok, "Défi éclairage")
	check(not investigation.submit_lighting(["source_switch"]).ok, "Circuit incomplet refusé")
	check(investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"]).ok, "Circuit fermé validé")
	check(investigation.begin_mission("lock").ok, "Défi serrure débloqué")
	for observation in ["badge", "power", "command", "link"]:
		check(investigation.observe("lock", observation).ok, "Observation serrure : " + observation)
	check(investigation.submit_lock("control_link", "reconnect_control").ok, "Serrure réparée")
	check(investigation.begin_mission("computer").ok, "Défi ordinateur débloqué")
	for observation in ["pc", "display", "no_signal"]:
		check(investigation.observe("computer", observation).ok, "Observation ordinateur : " + observation)
	for verification in ["power", "video"]:
		check(investigation.check_computer(verification).ok, "Vérification ordinateur : " + verification)
	check(investigation.submit_computer(["power", "video"], "video_disconnected", "reconnect_video").ok, "Ordinateur réparé")
	check(state.profile.wallet.points == 150 and state.profile.rewarded_missions.size() == 3, "Trois récompenses uniques")
	check(shop.purchase("avatar_orbit").ok and shop.equip("avatar_orbit").ok, "Achat et équipement depuis les données exportées")
	check(not shop.purchase("avatar_orbit").ok and state.profile.wallet.points == 130, "Double achat refusé")
	var values: Dictionary = settings.committed.duplicate(true)
	values.master = 42
	check(settings.apply_settings(values).ok, "Réglages enregistrés")
	check(profiles.save_active().ok, "Sauvegarde avant fermeture")
	state.clear_profile()
	check(profiles.select_profile(second.data.id).ok and state.profile.wallet.points == 0 and not state.profile.progress.started, "Aucune donnée commune au profil B")
	state.clear_profile()
	check(profiles.select_profile(first_id).ok and state.profile.wallet.points == 130 and state.profile.equipped.avatar == "avatar_orbit" and state.profile.progress.completed_missions.size() == 3, "Profil A repris avec progression et achat")
	check(settings.load_settings().ok and settings.current.master == 42, "Réglages relus depuis user://")
	check(profiles.start_game().ok and investigation.begin_mission("lighting").ok, "Rejeu disponible")
	var replay: Dictionary = investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"])
	check(replay.ok and replay.data.reward == 0 and state.profile.wallet.points == 130, "Rejeu sans gain supplémentaire")
	_finish()

func _finish() -> void:
	print("WINDOWS_PACK : %d assertions, %d échec(s)." % [assertions, failures])
	quit(0 if failures == 0 else 1)
