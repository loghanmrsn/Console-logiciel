extends SceneTree
## Lightweight integration tests. All mutations stay below user://tests/.
## Run: godot --headless --path . --script res://tests/run_tests.gd

var checks := 0
var failures: Array[String] = []
var test_root := ""
var saves
var profiles
var shop
var rewards
var investigation
var settings
var state
var alice_id := ""
var bob_id := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	for service_name in ["SaveService", "AppState", "ShopService", "RewardService", "ProfileService", "SettingsService", "InvestigationService"]:
		if not root.has_node(service_name):
			_fail("Autoload indispensable absent : " + service_name)
	if not failures.is_empty():
		_finish()
		return
	saves = root.get_node("SaveService")
	state = root.get_node("AppState")
	shop = root.get_node("ShopService")
	rewards = root.get_node("RewardService")
	investigation = root.get_node("InvestigationService")
	profiles = root.get_node("ProfileService")
	settings = root.get_node("SettingsService")
	test_root = "user://tests/run_%s_%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	print("Données temporaires : ", ProjectSettings.globalize_path(test_root))
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	if not _succeeds(shop.load_catalog(), "Catalogue local chargé"):
		_finish()
		return
	if not _succeeds(rewards.load_rules(), "Règles des missions chargées"):
		_finish()
		return
	_test_profiles()
	if not alice_id.is_empty() and not bob_id.is_empty():
		_test_rewards()
		_test_shop()
		_test_validation()
		_test_recovery()
		_test_session()
		_test_deletion()
	_test_settings()
	_finish()


func _test_profiles() -> void:
	print("\nProfils et isolation")
	var fresh = profiles.refresh()
	_check(fresh.ok and fresh.data.is_empty(), "Racine de test vide, aucun vrai profil chargé")
	var alice = profiles.create_profile("  Alice  ")
	if not _succeeds(alice, "Créer le premier profil"):
		return
	alice_id = alice.data.id
	_check(alice.data.display_name == "Alice", "Espaces extérieurs du pseudo retirés")
	_check(alice_id != "Alice" and saves.is_safe_id(alice_id), "Identifiant interne indépendant du pseudo")
	_check(alice.data.wallet.points == 0, "Un profil commence sans points de test")
	_check(alice.data.owned_items.has("avatar_default") and alice.data.owned_items.has("theme_brume") and alice.data.owned_items.has("frame_default"), "Avatar, thème et cadre gratuits disponibles")
	var bob = profiles.create_profile("Bob")
	if not _succeeds(bob, "Créer un deuxième profil"):
		return
	bob_id = bob.data.id
	_check(bob_id != alice_id, "Deux profils ont des identifiants distincts")
	_check(state.profile.id == bob_id, "Le profil créé devient actif")
	_succeeds(profiles.select_profile(alice_id), "Sélectionner le premier profil")
	var renamed = profiles.update_profile("Alice bis", "avatar_default")
	_succeeds(renamed, "Renommer un profil")
	_check(state.profile.id == alice_id and state.profile.display_name == "Alice bis", "Le renommage conserve l'identifiant et la sauvegarde")
	_check(saves.read_profile(bob_id).data.display_name == "Bob", "Renommer Alice ne modifie pas Bob")
	for invalid_name in ["", "   ", "12345678901234567", "Jo\u0001ueur", "\nJoueur"]:
		_check(not profiles.create_profile(invalid_name).ok, "Pseudo invalide refusé : " + JSON.stringify(invalid_name))
	_check(not saves.validate_display_name(42).ok, "Pseudo d'un type non textuel refusé")
	var before: Dictionary = state.profile.duplicate(true)
	saves.simulate_write_failure = true
	_check(not profiles.update_profile("Échec", "avatar_default").ok, "Échec de sauvegarde pendant renommage signalé")
	saves.simulate_write_failure = false
	_check(state.profile == before and saves.read_profile(alice_id).data == before, "Renommage échoué sans changement mémoire ou disque")
	_check(profiles.refresh().data.size() == 2, "Deux profils seulement après refus de créations invalides")


func _test_rewards() -> void:
	print("\nProgression et récompenses uniques")
	_succeeds(profiles.select_profile(alice_id), "Recharger Alice avant les missions")
	_check(not rewards.complete_mission("lighting").ok, "Mission refusée tant que l'enquête n'est pas commencée")
	_succeeds(profiles.start_game(), "Commencer l'enquête jouable")
	_prepare_mission("lighting")
	var first = _submit_mission("lighting")
	_check(first.ok and first.data.reward == 50 and state.profile.wallet.points == 50, "Première mission : exactement 50 points")
	var repeated = _submit_mission("lighting")
	_check(repeated.ok and repeated.data.reward == 0 and state.profile.wallet.points == 50, "Double validation : aucune récompense supplémentaire")
	_prepare_mission("lock")
	var before: Dictionary = state.profile.duplicate(true)
	saves.simulate_write_failure = true
	_check(not _submit_mission("lock").ok, "Échec d'écriture de récompense signalé")
	saves.simulate_write_failure = false
	_check(state.profile == before and saves.read_profile(alice_id).data == before, "Récompense échouée sans progression ni crédit partiels")
	_check(not rewards.complete_mission("mission_inconnue").ok, "Mission inconnue refusée")
	_succeeds(_submit_mission("lock"), "Diagnostiquer et réparer la liaison de commande")
	_prepare_mission("computer")
	_succeeds(_submit_mission("computer"), "Diagnostiquer et reconnecter le câble vidéo")
	_check(state.profile.wallet.points == 150 and state.profile.rewarded_missions.size() == 3, "Trois missions : plafond réel de 150 points")
	_check(saves.read_profile(bob_id).data.wallet.points == 0 and not saves.read_profile(bob_id).data.progress.started, "Récompenses et progression isolées de Bob")
	state.clear_profile()
	_succeeds(profiles.select_profile(alice_id), "Recharger une sauvegarde sans garder l'état mémoire")
	_check(state.profile.wallet.points == 150 and state.profile.progress.completed_missions.size() == 3, "Récompenses et objectifs conservés après rechargement")
	var owned_before: Array = state.profile.owned_items.duplicate()
	_succeeds(profiles.reset_progress(), "Réinitialiser seulement la progression")
	_check(not state.profile.progress.started and state.profile.progress.completed_missions.is_empty(), "Réinitialisation efface les objectifs de l'enquête")
	_check(state.profile.wallet.points == 150 and state.profile.rewarded_missions.size() == 3 and state.profile.owned_items == owned_before, "Réinitialisation conserve points, inventaire et récompenses attribuées")
	_succeeds(profiles.start_game(), "Recommencer après réinitialisation")
	for mission_id in ["lighting", "lock", "computer"]:
		_prepare_mission(mission_id)
		var replay = _submit_mission(mission_id)
		_check(replay.ok and replay.data.reward == 0, "Mission rejouée sans crédit : " + mission_id)
	_check(state.profile.wallet.points == 150, "Rejouer l'enquête ne dépasse pas 150 points")


func _prepare_mission(id: String) -> void:
	_succeeds(investigation.begin_mission(id), "Ouvrir le défi : " + id)
	if id == "lock":
		for clue in ["badge", "power", "command", "link"]:
			_succeeds(investigation.observe(id, clue), "Consulter l'observation : " + clue)
	elif id == "computer":
		for symptom in ["pc", "display", "no_signal"]:
			_succeeds(investigation.observe(id, symptom), "Observer le symptôme : " + symptom)
		for verification in ["video", "power"]:
			_succeeds(investigation.check_computer(verification), "Vérifier : " + verification)


func _submit_mission(id: String) -> Dictionary:
	match id:
		"lighting":
			return investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"])
		"lock":
			return investigation.submit_lock("control_link", "reconnect_control")
		"computer":
			return investigation.submit_computer(["video", "power"], "video_disconnected", "reconnect_video")
	return {"ok": false, "error": "Mission de test inconnue", "data": {}}


func _test_shop() -> void:
	print("\nBoutique et transactions")
	_check(shop.catalog.size() >= 8, "Au moins huit articles locaux")
	var paid: Dictionary = {}
	for product in shop.catalog:
		if product.price > 0 and (paid.is_empty() or product.price < paid.price):
			paid = product.duplicate(true)
	if paid.is_empty():
		_fail("Catalogue sans article achetable")
		return
	_succeeds(profiles.select_profile(bob_id), "Sélectionner Bob pour vérifier le solde insuffisant")
	var bob_before: Dictionary = state.profile.duplicate(true)
	_check(not shop.purchase(paid.id).ok, "Achat refusé avec solde insuffisant")
	_check(not shop.equip(paid.id).ok, "Équipement non possédé refusé")
	_check(not shop.purchase("article_inconnu").ok, "Identifiant d'article inconnu refusé")
	_check(state.profile == bob_before and saves.read_profile(bob_id).data == bob_before, "Achats refusés sans modification de Bob")
	_succeeds(profiles.select_profile(alice_id), "Retour à Alice pour acheter")
	var before: Dictionary = state.profile.duplicate(true)
	saves.simulate_write_failure = true
	_check(not shop.purchase(paid.id).ok, "Échec d'écriture d'achat signalé")
	saves.simulate_write_failure = false
	_check(state.profile == before and saves.read_profile(alice_id).data == before, "Achat échoué : aucun débit ni article ajouté en mémoire ou sur disque")
	_succeeds(shop.purchase(paid.id), "Achat sauvegardé avec succès")
	_check(state.profile.wallet.points == before.wallet.points - paid.price and state.profile.owned_items.has(paid.id), "Solde débité exactement du prix et article présent")
	var bought: Dictionary = state.profile.duplicate(true)
	_check(not shop.purchase(paid.id).ok and state.profile == bought, "Double achat refusé sans second débit")
	_succeeds(shop.equip(paid.id), "Équiper l'article acheté")
	_check(state.profile.equipped[paid.type] == paid.id and state.profile.equipped.size() == 3, "Un seul article équipé par type")
	var equipped_before: Dictionary = state.profile.duplicate(true)
	saves.simulate_write_failure = true
	var default_equipment := {"avatar": "avatar_default", "theme": "theme_brume", "frame": "frame_default"}
	_check(not shop.equip(default_equipment[paid.type]).ok, "Équipement échoué si la sauvegarde échoue")
	saves.simulate_write_failure = false
	_check(state.profile == equipped_before, "Équipement échoué conserve le choix précédent")
	state.clear_profile()
	_succeeds(profiles.select_profile(alice_id), "Recharger après achat et équipement")
	_check(state.profile == equipped_before, "Inventaire, points et équipement survivent au rechargement")
	_succeeds(profiles.reset_progress(), "Réinitialiser une progression avec achat")
	_check(state.profile.owned_items == equipped_before.owned_items and state.profile.wallet == equipped_before.wallet and state.profile.rewarded_missions == equipped_before.rewarded_missions, "Réinitialisation conserve aussi les achats effectifs")
	# Exercise the service guard independently of any disabled UI button.
	var saved_catalog: Array = shop.catalog.duplicate(true)
	for price in [-20, 1.5, "20"]:
		var bad_product: Dictionary = paid.duplicate(true)
		bad_product.price = price
		shop.catalog = [bad_product]
		_check(not shop.purchase(paid.id).ok, "Prix invalide bloqué par le service : " + str(price))
	shop.catalog = saved_catalog


func _test_validation() -> void:
	print("\nValidation des documents")
	var valid: Dictionary = state.profile.duplicate(true)
	_check(saves.validate_profile(valid, alice_id).ok, "Document valide accepté")
	_check(not saves.validate_profile([], alice_id).ok, "Document non objet refusé")
	_check(not saves.validate_profile(valid, bob_id).ok, "Identifiant interne ne correspondant pas au fichier refusé")
	for points in [-1, 1.5, "50", true, 2147483648]:
		var invalid: Dictionary = valid.duplicate(true)
		invalid.wallet.points = points
		_check(not saves.validate_profile(invalid).ok, "Solde invalide refusé : " + str(points))
	var mutations: Array = []
	var unknown_schema: Dictionary = valid.duplicate(true)
	unknown_schema.schema_version = 999
	mutations.append([unknown_schema, "Version de schéma inconnue refusée"])
	var path_id: Dictionary = valid.duplicate(true)
	path_id.id = "../session"
	mutations.append([path_id, "Identifiant contenant un chemin refusé"])
	var unknown_item: Dictionary = valid.duplicate(true)
	unknown_item.owned_items.append("article_inconnu")
	mutations.append([unknown_item, "Article inconnu dans l'inventaire refusé"])
	var duplicate_item: Dictionary = valid.duplicate(true)
	duplicate_item.owned_items.append("avatar_default")
	mutations.append([duplicate_item, "Article dupliqué dans l'inventaire refusé"])
	var wrong_equipment: Dictionary = valid.duplicate(true)
	wrong_equipment.equipped.avatar = "theme_brume"
	mutations.append([wrong_equipment, "Thème équipé en avatar refusé"])
	var unknown_room: Dictionary = valid.duplicate(true)
	unknown_room.progress.room_id = "../scene_inconnue"
	mutations.append([unknown_room, "Scène de reprise inconnue refusée"])
	var unknown_reward: Dictionary = valid.duplicate(true)
	unknown_reward.rewarded_missions.append("inconnue")
	mutations.append([unknown_reward, "Récompense de mission inconnue refusée"])
	var inconsistent_progress: Dictionary = valid.duplicate(true)
	inconsistent_progress.rewarded_missions = []
	inconsistent_progress.progress.started = true
	inconsistent_progress.progress.completed_missions = ["lighting"]
	mutations.append([inconsistent_progress, "Objectif accompli sans identifiant de récompense refusé"])
	for mutation in mutations:
		_check(not saves.validate_profile(mutation[0]).ok, mutation[1])
	var on_disk: String = FileAccess.get_file_as_string(_profile_path(alice_id))
	_check(not saves.write_profile(unknown_schema).ok and FileAccess.get_file_as_string(_profile_path(alice_id)) == on_disk, "Document invalide ne remplace jamais la sauvegarde valide")
	_check(not saves.read_profile("../session").ok, "Lecture de profil avec traversée de chemin refusée")
	_test_catalog_validation()
	var rules: Dictionary = _read_json("res://data/game_rules.json")
	_check(saves.validate_rules(rules).ok, "Règles de récompenses livrées validées")
	var bad_reward: Dictionary = rules.duplicate(true)
	bad_reward.missions[0].reward = -50
	_check(not saves.validate_rules(bad_reward).ok, "Récompense négative refusée dans les données")
	var bad_total: Dictionary = rules.duplicate(true)
	bad_total.mission_reward_max = 999
	_check(not saves.validate_rules(bad_total).ok, "Plafond incohérent avec les récompenses refusé")


func _test_catalog_validation() -> void:
	if not shop.has_method("validate_catalog"):
		_fail("Validation publique du catalogue manquante pour tester des données invalides sans modifier les ressources livrées")
		return
	var valid: Dictionary = _read_json("res://data/shop_catalog.json")
	_check(shop.validate_catalog(valid).ok, "Catalogue livré validé")
	for price in [-1, 1.5, "20", 101]:
		var invalid: Dictionary = valid.duplicate(true)
		invalid.items[3].price = price
		_check(not shop.validate_catalog(invalid).ok, "Catalogue avec prix invalide refusé : " + str(price))
	var malformed: Dictionary = valid.duplicate(true)
	malformed.items[3] = "ceci n'est pas un article"
	_check(not shop.validate_catalog(malformed).ok, "Entrée catalogue d'un type invalide refusée sans plantage")
	var duplicate: Dictionary = valid.duplicate(true)
	duplicate.items[3].id = duplicate.items[0].id
	_check(not shop.validate_catalog(duplicate).ok, "Identifiant catalogue dupliqué refusé")
	var missing_default: Dictionary = valid.duplicate(true)
	missing_default.items.remove_at(0)
	_check(not shop.validate_catalog(missing_default).ok, "Article gratuit par défaut manquant refusé")


func _test_recovery() -> void:
	print("\nCorruption et récupération explicite")
	var created = profiles.create_profile("Copie initiale")
	if not _succeeds(created, "Créer une copie de profil pour corruption"):
		return
	var id: String = created.data.id
	_succeeds(profiles.update_profile("Copie suivante", "avatar_default"), "Sauvegarder une seconde version et créer une copie précédente")
	var backup_text: String = FileAccess.get_file_as_string(_profile_path(id) + ".bak")
	var backup: Dictionary = saves.validate_profile(_read_json(_profile_path(id) + ".bak"), id).data
	var before_corruption: Dictionary = state.profile.duplicate(true)
	state.clear_profile()
	var broken := "{ json volontairement invalide"
	_check(_write_raw(_profile_path(id), broken), "Corrompre uniquement le fichier temporaire de test")
	_check(not saves.read_profile(id).ok, "JSON corrompu signalé au lieu d'être chargé")
	var listed = saves.list_profiles()
	var issue_found := false
	for issue in listed.get("issues", []):
		if issue.id == id and issue.has_backup:
			issue_found = true
	_check(listed.ok and issue_found, "Liste conserve une erreur de récupération avec copie disponible")
	_check(FileAccess.get_file_as_string(_profile_path(id)) == broken, "Lecture et liste n'effacent ni ne restaurent silencieusement le document")
	state.set_profile(before_corruption)
	_check(not profiles.save_active().ok, "Corruption pendant une session : sauvegarde automatique refusée en attente de récupération")
	_check(FileAccess.get_file_as_string(_profile_path(id)) == broken and FileAccess.get_file_as_string(_profile_path(id) + ".bak") == backup_text, "Sauvegarde refusée préserve le document corrompu et la bonne copie précédente")
	state.clear_profile()
	var recovered = saves.recover_profile(id)
	_check(recovered.ok and recovered.data == backup, "Récupération uniquement après appel explicite, depuis la copie précédente")
	_check(saves.read_profile(id).ok and saves.read_profile(id).data == backup, "Document récupéré valide sur disque")
	var quarantined := false
	var directory := DirAccess.open(test_root.path_join("profiles"))
	for filename in directory.get_files():
		if filename.begins_with(id + ".json.corrupt_"):
			quarantined = true
	_check(quarantined, "Copie corrompue conservée à part pour diagnostic")
	_check(DirAccess.remove_absolute(ProjectSettings.globalize_path(_profile_path(id))) == OK, "Simuler un fichier principal absent uniquement dans la copie de test")
	var orphan_list = saves.list_profiles()
	var orphan_issue := false
	for issue in orphan_list.get("issues", []):
		if issue.id == id and issue.has_backup:
			orphan_issue = true
	_check(orphan_issue, "Copie précédente orpheline signalée comme récupérable")
	_succeeds(saves.recover_profile(id), "Restaurer explicitement une copie précédente sans principal")
	_succeeds(profiles.delete_profile(id), "Supprimer le profil récupéré")
	var residual := false
	for filename in directory.get_files():
		if filename == id + ".json" or filename.begins_with(id + ".json."):
			residual = true
	_check(not residual, "Suppression retire aussi les copies associées au profil concerné")
	var future = profiles.create_profile("Version future")
	if not _succeeds(future, "Créer une copie pour version inconnue"):
		return
	var future_id: String = future.data.id
	var unknown: Dictionary = future.data.duplicate(true)
	unknown.schema_version = 999
	state.clear_profile()
	var unknown_text := JSON.stringify(unknown)
	_check(_write_raw(_profile_path(future_id), unknown_text), "Installer un schéma inconnu dans la copie de test")
	_check(not saves.read_profile(future_id).ok and FileAccess.get_file_as_string(_profile_path(future_id)) == unknown_text, "Version inconnue conservée et refusée sans migration implicite")
	_check(not saves.recover_profile(future_id).ok, "Récupération sans copie disponible refusée explicitement")
	_succeeds(profiles.delete_profile(future_id), "Supprimer seulement la copie de test à schéma inconnu")
	_succeeds(profiles.select_profile(alice_id), "Restaurer Alice après les copies de corruption")


func _test_session() -> void:
	print("\nSession et chemins")
	var session_path: String = test_root.path_join("session.json")
	var traversal := JSON.stringify({"schema_version": 1, "last_profile_id": "../../profiles/étranger"})
	_check(_write_raw(session_path, traversal), "Préparer une session de test avec chemin interdit")
	_check(not saves.read_session().ok and FileAccess.get_file_as_string(session_path) == traversal, "Traversée de chemin dans session refusée sans effacement")
	_check(not saves.write_session("../étranger").ok, "Écriture de session contenant un chemin refusée")
	var unknown := JSON.stringify({"schema_version": 999, "last_profile_id": alice_id})
	_check(_write_raw(session_path, unknown) and not saves.read_session().ok, "Version de session inconnue refusée")
	_check(not saves.write_session(alice_id).ok and FileAccess.get_file_as_string(session_path) == unknown, "Session corrompue ne peut être remplacée implicitement")
	_succeeds(saves.write_session(""), "Choisir explicitement de réinitialiser uniquement la session de test")
	_succeeds(saves.write_session(alice_id), "Restaurer une session valide de test")
	_check(saves.read_session().data == alice_id, "Dernier profil utilisé persistant")


func _test_deletion() -> void:
	print("\nSuppression ciblée")
	var alice_before: Dictionary = saves.read_profile(alice_id).data.duplicate(true)
	saves.simulate_write_failure = true
	_check(not profiles.delete_profile(bob_id).ok, "Suppression refusée en cas d'échec disque")
	saves.simulate_write_failure = false
	_check(saves.read_profile(bob_id).ok, "Suppression échouée conserve le profil")
	_succeeds(profiles.delete_profile(bob_id), "Supprimer Bob")
	_check(not saves.read_profile(bob_id).ok, "Profil supprimé absent")
	_check(saves.read_profile(alice_id).data == alice_before and state.profile.id == alice_id, "Suppression de Bob conserve Alice et la session active")


func _test_settings() -> void:
	print("\nRéglages, aperçus et persistance")
	load("res://scripts/input_setup.gd").configure()
	if not _succeeds(settings.load_settings(), "Charger les réglages par défaut de la racine isolée"):
		return
	var original: Dictionary = settings.committed.duplicate(true)
	var preview: Dictionary = original.duplicate(true)
	preview.master = 0
	preview.music = 37.0 # HSlider emits floating values even when step is 1.
	preview.effects = 0
	preview.large_text = true
	preview.reduce_motion = true
	preview.reduce_transparency = true
	preview.deadzone = 0.49
	preview.fullscreen = false
	_succeeds(settings.preview(preview), "Prévisualiser audio, accessibilité et zone morte")
	var normalized_preview: Dictionary = preview.duplicate(true)
	normalized_preview.music = int(preview.music)
	_check(settings.current == normalized_preview and settings.committed == original, "L'aperçu change current et conserve committed")
	var master_index := AudioServer.get_bus_index("Master")
	var music_index := AudioServer.get_bus_index("Music")
	var effects_index := AudioServer.get_bus_index("Effects")
	_check(master_index >= 0 and music_index >= 0 and effects_index >= 0, "Trois bus audio distincts disponibles")
	if master_index >= 0 and effects_index >= 0:
		_check(AudioServer.is_bus_mute(master_index) and AudioServer.is_bus_mute(effects_index), "Volume zéro coupe réellement les bus audio")
	_check(is_equal_approx(InputMap.action_get_deadzone("ui_right"), 0.49) and is_equal_approx(InputMap.action_get_deadzone("game_left"), 0.49), "Zone morte appliquée aux entrées UI et au jeu")
	settings.cancel_preview()
	_check(settings.current == original and settings.committed == original, "Annuler restaure tous les aperçus sans modifier les valeurs enregistrées")
	_check(is_equal_approx(InputMap.action_get_deadzone("ui_right"), float(original.deadzone)), "Annuler restaure également la zone morte effective")
	_succeeds(settings.apply_settings(preview), "Appliquer et sauvegarder les réglages")
	var settings_path: String = test_root.path_join("settings.cfg")
	_check(FileAccess.file_exists(settings_path), "ConfigFile enregistré dans la racine temporaire uniquement")
	var persisted_text := FileAccess.get_file_as_string(settings_path)
	var saved: Dictionary = settings.committed.duplicate(true)
	settings.preview(original)
	_succeeds(settings.load_settings(), "Relire les réglages enregistrés après changement mémoire")
	_check(settings.current == saved and settings.committed == saved, "Réglages persistants restaurés depuis le disque")
	var changed: Dictionary = saved.duplicate(true)
	changed.master = 61
	settings.force_write_failure = true
	_check(not settings.apply_settings(changed).ok, "Échec d'écriture de réglages signalé")
	settings.force_write_failure = false
	_check(settings.committed == saved and FileAccess.get_file_as_string(settings_path) == persisted_text, "Échec conserve les valeurs validées et le fichier précédent")
	settings.cancel_preview()
	_check(settings.current == saved, "Annulation après échec restaure les réglages validés")
	for key_value in [["master", -1], ["music", 101], ["effects", "fort"], ["large_text", "oui"], ["deadzone", 0.01]]:
		var invalid: Dictionary = saved.duplicate(true)
		invalid[key_value[0]] = key_value[1]
		_check(not settings.preview(invalid).ok, "Réglage invalide refusé : " + str(key_value[0]))
	_check(settings.current == saved, "Aperçus invalides sans modification des valeurs courantes")
	_succeeds(settings.apply_settings(original), "Créer une deuxième sauvegarde et une copie précédente des réglages")
	var corrupt_text := "[console\ncontenu volontairement invalide"
	_check(_write_raw(settings_path, corrupt_text), "Corrompre la copie de réglages de test")
	_check(not settings.load_settings().ok, "Réglages corrompus refusés sans plantage")
	_check(FileAccess.get_file_as_string(settings_path) == corrupt_text, "Chargement ne remplace pas silencieusement les réglages corrompus")
	var backup_text: String = FileAccess.get_file_as_string(settings_path + ".bak")
	settings.force_write_failure = true
	_check(not settings.recover_settings("backup").ok, "Échec d'écriture pendant récupération des réglages signalé")
	settings.force_write_failure = false
	_check(FileAccess.get_file_as_string(settings_path) == corrupt_text and FileAccess.get_file_as_string(settings_path + ".bak") == backup_text, "Récupération échouée conserve les fichiers et permet une nouvelle tentative")
	# Keep later scenarios independent if this assertion catches a real regression.
	if not FileAccess.file_exists(settings_path):
		_write_raw(settings_path, corrupt_text)
	if not FileAccess.file_exists(settings_path + ".bak"):
		_write_raw(settings_path + ".bak", backup_text)
	_succeeds(settings.recover_settings("backup"), "Restaurer les réglages après choix explicite de la copie précédente")
	_check(settings.committed == saved and settings.current == saved, "Copie précédente des réglages restaurée et appliquée")
	var restored_text: String = FileAccess.get_file_as_string(settings_path)
	settings.force_write_failure = true
	_check(not settings.recover_settings("defaults").ok, "Échec d'écriture pendant récupération des valeurs par défaut signalé")
	settings.force_write_failure = false
	_check(FileAccess.get_file_as_string(settings_path) == restored_text and settings.committed == saved, "Récupération des valeurs par défaut échouée conserve la configuration validée")
	if not FileAccess.file_exists(settings_path):
		_write_raw(settings_path, restored_text)
	_succeeds(settings.recover_settings("defaults"), "Demander explicitement les valeurs par défaut")
	_check(settings.current == settings.defaults and settings.committed == settings.defaults, "Valeurs par défaut sauvegardées et appliquées")


func _profile_path(id: String) -> String:
	return test_root.path_join("profiles").path_join(id + ".json")


func _succeeds(result: Dictionary, description: String) -> bool:
	var success := bool(result.get("ok", false))
	_check(success, description + (" : " + str(result.get("error", "")) if not success else ""))
	return success


func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("  OK  ", description)
	else:
		_fail(description)


func _fail(description: String) -> void:
	failures.append(description)
	printerr("  ÉCHEC  ", description)


func _write_raw(path: String, contents: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("Écriture de la copie de test impossible : " + path)
		return false
	file.store_string(contents)
	file.flush()
	var success := file.get_error() == OK
	file.close()
	return success


func _read_json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _remove_tree(path: String) -> void:
	# This guard makes accidental deletion outside the ephemeral test root impossible.
	if test_root.is_empty() or not path.begins_with(test_root):
		_fail("Nettoyage refusé hors de la racine temporaire")
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for child in directory.get_files():
		directory.remove(child)
	for child in directory.get_directories():
		_remove_tree(path.path_join(child))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _finish() -> void:
	if checks == 0:
		_fail("Aucune assertion exécutée : services/tests encore incomplets")
	if not test_root.is_empty():
		_remove_tree(test_root)
	print("\nRésultat : %s assertions, %s échec(s)." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
