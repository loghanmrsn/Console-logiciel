extends SceneTree
## Worker for tools/check_close.py. Successful exits use the application's real
## close path, never a replacement for SceneTree.quit. Fixtures are marked /tmp.

var checks := 0
var failures: Array[String] = []
var stage := ""
var test_root := ""
var app
var saves
var profiles
var settings
var state
var expected_profile: Dictionary = {}
var baseline: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	checks += 1
	if condition:
		print("  OK  ", message)
	else:
		failures.append(message)
		print("CLOSE FAIL : ", message)
	return condition

func _run() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	for index in range(args.size() - 1):
		if args[index] == "--case": stage = args[index + 1]
		if args[index] == "--test-data-root": test_root = args[index + 1]
	if not _check(stage in ["apply", "discard", "failure_retry", "failure_cancel"] and test_root.begins_with("/tmp/ciel-close-") and ".." not in test_root, "Racine temporaire et cas explicites obligatoires"):
		_fail_exit()
		return
	var marker = JSON.parse_string(FileAccess.get_file_as_string(test_root.path_join("close_fixture.json")))
	if not _check(marker is Dictionary and marker.get("purpose") == "CIEL isolated native close", "Marqueur de test présent ; aucun profil normal utilisé"):
		_fail_exit()
		return
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	settings = root.get_node("SettingsService")
	state = root.get_node("AppState")
	saves.root_path = test_root.path_join("data")
	settings.storage_root = saves.root_path
	var shop = root.get_node("ShopService")
	var rewards = root.get_node("RewardService")
	var investigation = root.get_node("InvestigationService")
	_check(shop.load_catalog().ok and rewards.load_rules().ok, "Services et catalogue existants chargés")
	baseline = settings.defaults.duplicate(true)
	baseline.master = 31
	_check(settings.apply_settings(baseline).ok, "Réglage initial réellement enregistré")
	_check(profiles.create_profile("Test fermeture").ok, "Profil de test créé par le service normal")
	_check(profiles.start_game().ok, "Enquête commencée dans ce profil isolé")
	_check(investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"]).ok, "Mission validée par ses vraies règles")
	_check(shop.purchase("avatar_orbit").ok and shop.equip("avatar_orbit").ok, "Achat et équipement enregistrés ensemble")
	expected_profile = state.profile.duplicate(true)
	_check(expected_profile.wallet.points == 30 and expected_profile.rewarded_missions == ["lighting"], "Fixture : 50 points gagnés, 20 dépensés, récompense unique")
	state.clear_profile()
	root.size = Vector2i(800, 480)
	app = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(app)
	await _frames(18)
	_check(app.screen == "profiles", "L'application démarre sur la sélection du profil enregistré")
	if not await _activate("select_" + expected_profile.id): return
	_check(app.screen == "home" and state.profile == expected_profile, "La sélection restaure le profil et ses achats")
	if not await _activate("home_settings"): return
	_check(app.screen == "settings", "Paramètres ouverts depuis le menu")
	var volume := _find(app, "setting_master") as HSlider
	if not _check(volume != null, "Slider réel du volume disponible"):
		_fail_exit()
		return
	volume.grab_focus()
	await _press(KEY_RIGHT)
	_check(settings.current.master == 32 and settings.committed.master == 31 and app._settings_dirty(), "Aperçu natif : valeur 32, réglage enregistré 31, brouillon détecté")
	if stage.begins_with("failure"):
		settings.force_write_failure = true
	app._request_quit()
	await _frames(5)
	_check(is_instance_valid(app.modal), "La fermeture demande quoi faire des aperçus")
	if stage == "apply" or stage == "discard":
		await _activate("quit_apply" if stage == "apply" else "quit_discard", 32 if stage == "apply" else 31)
		return
	if not await _activate("quit_apply"): return
	_check(is_instance_valid(app) and is_instance_valid(app.modal), "Erreur d'écriture : session toujours ouverte avec dialogue explicite")
	_check(settings.committed.master == 31 and settings.current.master == 32, "Erreur : état enregistré précédent conservé, aperçu encore annulable")
	var on_disk := ConfigFile.new()
	_check(on_disk.load(settings._path()) == OK and on_disk.get_value("settings", "master", -1) == 31, "Erreur : fichier précédent conservé")
	_check(saves.read_profile(expected_profile.id).data == expected_profile and not saves.last_error.is_empty(), "Erreur : profil inchangé et diagnostic renseigné")
	settings.force_write_failure = false
	if stage == "failure_retry":
		await _activate("modal_confirm", 32)
		return
	await _press(KEY_ESCAPE)
	_check(not is_instance_valid(app.modal) and app.screen == "settings", "Annuler l'erreur laisse revenir aux paramètres")
	if not await _activate("settings_cancel"): return
	_check(app.screen == "home" and settings.current == baseline and settings.committed == baseline, "Annuler restaure réellement tous les aperçus")
	app._request_quit()
	await _frames(5)
	await _activate("modal_confirm", 31)

func _arm_close(expected_master: int) -> void:
	if not failures.is_empty():
		_fail_exit()
		return
	var expected_settings := baseline.duplicate(true)
	expected_settings.master = expected_master
	var report := {"purpose": "CIEL isolated native close", "case": stage, "assertions": checks, "expected_profile": expected_profile, "expected_settings": expected_settings}
	var file := FileAccess.open(test_root.path_join("close_fixture.json"), FileAccess.WRITE)
	if file == null:
		_check(false, "Rapport de test inscriptible")
		_fail_exit()
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("CLOSE_READY ", stage, " : ", checks, " assertions, 0 échec(s). Fermeture réelle attendue par le bouton.")

func _activate(name: String, expected_master: int = -1) -> bool:
	var control := _find(app, name) as Control
	if not _check(control != null and control.is_visible_in_tree(), "Bouton natif accessible : " + name):
		_fail_exit()
		return false
	if expected_master >= 0:
		_arm_close(expected_master)
	control.grab_focus()
	await _frames(3)
	await _press(KEY_ENTER)
	await _frames(5)
	return true

func _press(key: Key) -> void:
	await create_timer(0.23).timeout
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(2)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(3)

func _frames(amount: int) -> void:
	for index in range(amount): await process_frame

func _find(node: Node, name: String) -> Node:
	if not is_instance_valid(node): return null
	if str(node.name) == name: return node
	for child in node.get_children():
		var found := _find(child, name)
		if found != null: return found
	return null

func _fail_exit() -> void:
	# Only an unsuccessful test aborts itself. Successful exits belong to main.gd.
	print("CLOSE_ABORT ", stage, " : ", checks, " assertions, ", failures.size(), " échec(s).")
	quit(1)
