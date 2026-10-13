extends SceneTree
## Startup/recovery acceptance. Native keyboard validation; all mutations are
## confined to a unique user://tests/stability_* tree, removed on completion.

var checks := 0
var failures: Array[String] = []
var test_root := ""
var app
var saves
var profiles
var settings
var shop
var state
var router


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	settings = root.get_node("SettingsService")
	shop = root.get_node("ShopService")
	state = root.get_node("AppState")
	router = root.get_node("SceneRouter")
	test_root = "user://tests/stability_%s_%s" % [Time.get_ticks_usec(), OS.get_process_id()]
	root.size = Vector2i(1280, 720)
	print("STABILITY : données isolées ", ProjectSettings.globalize_path(test_root))
	await _test_clean_boot()
	await _test_inaccessible_storage_retry()
	await _test_settings_backup_recovery()
	await _test_settings_defaults_recovery()
	await _test_missing_profile_recovery()
	await _test_missing_session_recovery()
	await _test_catalog_rejection()
	await _dispose_app()
	saves.simulate_write_failure = false
	settings.force_write_failure = false
	_remove_tree(test_root)
	print("STABILITY : %d assertions, %d échec(s)." % [checks, failures.size()])
	print("Démarrage/récupération testés sans affichage ; aucune capture ou manette physique revendiquée.")
	quit(0 if failures.is_empty() else 1)


func _prepare(path: String) -> void:
	saves.root_path = path
	settings.storage_root = path
	saves.simulate_write_failure = false
	settings.force_write_failure = false
	state.clear_profile()
	router.remembered_focus.clear()
	_check(shop.load_catalog().ok and root.get_node("RewardService").load_rules().ok, "Définitions livrées chargées pour le cas isolé")


func _boot(path: String) -> void:
	await _dispose_app()
	_prepare(path)
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "Scène principale native chargeable")
	if packed == null: return
	app = packed.instantiate()
	root.add_child(app)
	await _frames(16)


func _test_clean_boot() -> void:
	print("\nDémarrage sans données")
	await _boot(test_root.path_join("fresh"))
	_check(app.screen == "editor" and state.profile.is_empty(), "Premier lancement : création, aucun faux profil prédéfini")
	_check(_find(app, "key_A") != null and root.gui_get_focus_owner() == _find(app, "key_A"), "Création sans clavier physique : focus initial du clavier virtuel")
	_check(_find_class(app, "ProgressBar") == null, "Le démarrage n'exige aucune fausse barre de progression")
	if not await _activate("key_A"): return
	if not await _activate("key_Valider"): return
	_check(app.screen == "home" and not state.profile.is_empty() and state.profile.wallet.points == 0, "Clavier virtuel : profil valide enregistré et accueil affiché sans points de test")
	var id: String = state.profile.id
	await _boot(saves.root_path)
	_check(app.screen == "profiles" and _find(app, "select_" + id) != null, "Relance avec profil : sélection avant l'accueil")
	await _activate("select_" + id)
	_check(app.screen == "home" and state.profile.id == id, "Sélection native charge le bon profil existant")


func _test_inaccessible_storage_retry() -> void:
	print("\nStockage indisponible puis réessai")
	var path := test_root.path_join("blocked_storage")
	_check(_write_raw(path, "Un fichier occupe volontairement le chemin de la copie de test."), "Indisponibilité de stockage simulée uniquement dans la copie de test")
	await _boot(path)
	_check(app.screen == "fatal", "Stockage inaccessible : écran d'erreur exploitable")
	var retry := _find(app, "fatal_retry")
	_check(retry != null, "Une action Réessayer est disponible après erreur de chargement")
	_check(FileAccess.file_exists(path), "L'erreur de chargement n'efface pas les données défectueuses")
	if retry == null: return
	_check(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK, "Retirer explicitement le fichier de test bloquant")
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path)) == OK, "Rétablir explicitement le répertoire de test")
	await _activate("fatal_retry")
	await _frames(16)
	_check(app.screen == "editor", "Réessayer relance réellement le chargement et ouvre la création après réparation")


func _test_settings_backup_recovery() -> void:
	print("\nRéglages invalides et copie précédente")
	await _dispose_app()
	var path := test_root.path_join("settings_backup")
	_prepare(path)
	var values: Dictionary = settings.defaults.duplicate(true)
	values.master = 11
	_check(settings.apply_settings(values).ok, "Créer une copie valide des réglages")
	values.master = 22
	_check(settings.apply_settings(values).ok, "Créer une copie précédente avant corruption de test")
	var principal := path.path_join("settings.cfg")
	var backup := FileAccess.get_file_as_string(principal + ".bak")
	var broken := "[meta]\nschema_version=999\n[settings]\nmaster=invalid\n"
	_check(_write_raw(principal, broken), "Altérer uniquement les réglages de test")
	await _boot(path)
	_check(app.screen == "settings_recovery", "Réglages inconnus : récupération explicite avant les profils")
	_check(FileAccess.get_file_as_string(principal) == broken and FileAccess.get_file_as_string(principal + ".bak") == backup, "Le démarrage préserve principal invalide et copie précédente")
	settings.force_write_failure = true
	await _activate("recover_settings")
	_check(app.screen == "settings_recovery", "Échec de récupération : l'application reste sur le choix explicite")
	_check(FileAccess.get_file_as_string(principal) == broken and FileAccess.get_file_as_string(principal + ".bak") == backup, "Échec de récupération ne consomme aucune copie récupérable")
	_check(is_instance_valid(app.modal), "Erreur d'écriture : dialogue durable nécessitant une action")
	await _dismiss_modal()
	settings.force_write_failure = false
	await _activate("recover_settings")
	await _frames(12)
	_check(app.screen == "editor" and settings.committed.master == 11, "Nouvelle tentative explicite restaure les réglages précédents et poursuit le démarrage")
	_check(_has_archive(path, "settings.cfg.corrupt"), "Réglages défectueux conservés dans une archive après récupération")
	_check(not saves.last_error.is_empty(), "Dernière erreur de stockage disponible pour le diagnostic après un réessai réussi")
	var diagnostic_error: String = saves.last_error
	saves.validate_display_name("\n")
	_check(saves.last_error == diagnostic_error, "Une erreur de saisie ne remplace pas la dernière erreur de sauvegarde")


func _test_settings_defaults_recovery() -> void:
	print("\nRéglages sans copie : valeurs par défaut explicites")
	await _dispose_app()
	var path := test_root.path_join("settings_defaults")
	var principal := path.path_join("settings.cfg")
	var broken := "Ce document de test est volontairement invalide."
	_check(_write_raw(principal, broken), "Créer un document de réglages de test sans copie valide")
	await _boot(path)
	_check(app.screen == "settings_recovery", "Réglages sans copie : choix de récupération accessible")
	settings.force_write_failure = true
	await _activate("default_settings")
	_check(app.screen == "settings_recovery" and FileAccess.get_file_as_string(principal) == broken, "Défauts non sauvegardés : document original restauré, pas de démarrage silencieux")
	_check(is_instance_valid(app.modal), "Échec du remplacement par défaut : erreur avec action explicite")
	await _dismiss_modal()
	settings.force_write_failure = false
	await _activate("default_settings")
	await _frames(12)
	_check(app.screen == "editor" and settings.committed == settings.defaults, "Réessai de valeurs par défaut : sauvegarde réussie puis création de profil")
	_check(_has_archive(path, "settings.cfg.corrupt"), "La récupération par défaut conserve le fichier endommagé pour diagnostic")


func _test_missing_profile_recovery() -> void:
	print("\nProfil principal absent, sauvegarde conservée")
	await _dispose_app()
	var path := test_root.path_join("orphan_profile")
	_prepare(path)
	var created: Dictionary = profiles.create_profile("Avant copie")
	if not _ok(created, "Créer le profil de récupération isolé"): return
	var id: String = created.data.id
	_ok(profiles.update_profile("Après copie", "avatar_default"), "Créer une version précédente du profil")
	var principal := path.path_join("profiles/" + id + ".json")
	var backup := FileAccess.get_file_as_string(principal + ".bak")
	_check(DirAccess.remove_absolute(ProjectSettings.globalize_path(principal)) == OK, "Simuler un principal absent dans les fichiers de test")
	_check(not profiles.save_active().ok and not FileAccess.file_exists(principal) and FileAccess.get_file_as_string(principal + ".bak") == backup, "Sauvegarde automatique refusée sans recréer silencieusement un principal ni remplacer .bak")
	await _boot(path)
	_check(app.screen == "recovery" and _find(app, "recover_" + id) != null, "Démarrage : profil orphelin proposé à la récupération")
	saves.simulate_write_failure = true
	await _activate("recover_" + id)
	await _activate("modal_confirm")
	_check(not FileAccess.file_exists(principal) and FileAccess.get_file_as_string(principal + ".bak") == backup, "Échec de restauration de profil sans modification de la copie précédente")
	await _dismiss_modal()
	saves.simulate_write_failure = false
	await _activate("recover_" + id)
	await _activate("modal_confirm")
	await _frames(10)
	_check(app.screen == "profiles" and saves.read_profile(id).ok, "Réessai explicite : restauration du profil sans blocage")
	await _activate("select_" + id)
	_check(app.screen == "home" and state.profile.id == id and state.profile.display_name == "Avant copie", "La copie précédente choisie, plus ancienne, devient le profil actif")


func _test_missing_session_recovery() -> void:
	print("\nSession orpheline et sélection contrôlée")
	await _dispose_app()
	var path := test_root.path_join("orphan_session")
	_prepare(path)
	var alice: Dictionary = profiles.create_profile("Session A")
	var bob: Dictionary = profiles.create_profile("Session B")
	if not _ok(alice, "Créer A pour session") or not _ok(bob, "Créer B pour session"): return
	var principal := path.path_join("session.json")
	var backup := FileAccess.get_file_as_string(principal + ".bak")
	_check(DirAccess.remove_absolute(ProjectSettings.globalize_path(principal)) == OK, "Simuler une session principale absente")
	var snapshot: Dictionary = state.profile.duplicate(true)
	_check(not profiles.select_profile(alice.data.id).ok and state.profile == snapshot, "Session sans principal : changement de profil refusé sans mélange de données")
	_check(not FileAccess.file_exists(principal) and FileAccess.get_file_as_string(principal + ".bak") == backup, "Changement refusé : .bak session intacte et aucune restauration silencieuse")
	var listed: Dictionary = profiles.refresh()
	var recoverable := false
	for issue in listed.get("issues", []):
		if issue.id == "" and issue.has_backup: recoverable = true
	_check(listed.ok and recoverable, "La dernière sélection orpheline apparaît comme récupérable")
	saves.simulate_write_failure = true
	_check(not saves.recover_session().ok and not FileAccess.file_exists(principal) and FileAccess.get_file_as_string(principal + ".bak") == backup, "Échec explicite de restauration session sans consommation de copie")
	saves.simulate_write_failure = false
	_ok(saves.recover_session(), "Réessai de récupération explicite de session")
	_check(saves.read_session().ok and saves.read_session().data == alice.data.id, "La dernière sélection précédente est restaurée sans modifier les profils")
	var broken := "{ session de test volontairement invalide"
	_check(_write_raw(principal, broken), "Altérer une copie de session pour vérifier sa récupération dans l'interface")
	await _boot(path)
	_check(app.screen == "recovery" and _find(app, "restore_session_backup") != null, "Session invalide : option de copie précédente accessible dans l'interface")
	var backup_before := FileAccess.get_file_as_string(principal + ".bak")
	saves.simulate_write_failure = true
	await _activate("restore_session_backup")
	await _activate("modal_confirm")
	_check(app.screen == "recovery" and FileAccess.get_file_as_string(principal) == broken and FileAccess.get_file_as_string(principal + ".bak") == backup_before, "Échec de récupération native : session endommagée et .bak restent exploitables")
	_check(is_instance_valid(app.modal), "Échec de session : erreur affichée jusqu'à acquittement")
	await _dismiss_modal()
	saves.simulate_write_failure = false
	await _activate("restore_session_backup")
	await _activate("modal_confirm")
	await _frames(10)
	_check(app.screen == "profiles" and profiles.last_profile_id == alice.data.id, "Réessai natif : restauration de la dernière sélection et retour aux profils")
	_check(_has_archive(path, "session.json.corrupt"), "L'interface conserve la session malformée dans une archive explicite")
	await _boot(path)
	_check(app.screen == "profiles" and profiles.last_profile_id == alice.data.id, "Démarrage après restauration : sélection de profil et dernier utilisé correct")
	await _activate("select_" + bob.data.id)
	_check(app.screen == "home" and state.profile.id == bob.data.id and state.profile.wallet.points == 0, "Après restauration, choisir B charge uniquement les données de B")


func _test_catalog_rejection() -> void:
	print("\nCatalogue de test invalide")
	await _dispose_app()
	var bad_path := test_root.path_join("bad_catalog.json")
	_check(_write_raw(bad_path, "{\"schema_version\":1,\"items\":[]}"), "Créer un catalogue invalide de test sans toucher res://data")
	_check(not shop.load_catalog(bad_path).ok and shop.catalog.is_empty(), "Échec de chargement : ancien catalogue retiré, pas de transactions sur des données périmées")
	_check(shop.load_catalog().ok and shop.catalog.size() >= 8, "Ressources livrées rechargeables après erreur de test")
	var rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/game_rules.json"))
	if rules is Dictionary:
		rules.missions[0].reward = -50
		_check(not saves.validate_rules(rules).ok, "Règles essentielles invalides refusées avant toute validation de mission")


func _activate(name: String) -> bool:
	var control := _find(app, name) as Control
	_check(control != null and control.is_visible_in_tree(), "Commande native accessible : " + name)
	if control == null or not control.is_visible_in_tree(): return false
	control.grab_focus()
	await _frames(3)
	await _press(KEY_ENTER)
	await _frames(6)
	return true


func _press(code: Key) -> void:
	# This is real Control navigation, not Button.pressed.emit().
	await create_timer(0.22).timeout
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(2)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(3)


func _dismiss_modal() -> void:
	if is_instance_valid(app) and is_instance_valid(app.modal):
		await _press(KEY_ESCAPE)
		await _frames(3)


func _find(node: Node, name: String) -> Node:
	if not is_instance_valid(node): return null
	if str(node.name) == name: return node
	for child in node.get_children():
		var found := _find(child, name)
		if found != null: return found
	return null


func _find_class(node: Node, name: String) -> Node:
	if node.is_class(name): return node
	for child in node.get_children():
		var found := _find_class(child, name)
		if found != null: return found
	return null


func _has_archive(path: String, prefix: String) -> bool:
	var directory := DirAccess.open(path)
	if directory == null: return false
	for filename in directory.get_files():
		if filename.begins_with(prefix): return true
	return false


func _write_raw(path: String, text: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir())) != OK: return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(text)
	file.close()
	return true


func _frames(count: int) -> void:
	for index in range(count): await process_frame


func _dispose_app() -> void:
	if is_instance_valid(app):
		root.remove_child(app)
		app.queue_free()
		app = null
	await _frames(3)


func _ok(result: Dictionary, label: String) -> bool:
	_check(result.ok, label + (" : " + result.error if not result.ok else ""))
	return result.ok


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		print("ECHEC : ", label)


func _remove_tree(path: String) -> void:
	if not path.begins_with(test_root): return
	var directory := DirAccess.open(path)
	if directory == null: return
	for filename in directory.get_files(): directory.remove(filename)
	for child in directory.get_directories(): _remove_tree(path.path_join(child))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
