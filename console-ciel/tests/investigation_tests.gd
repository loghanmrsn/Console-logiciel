extends SceneTree
## Business integration tests for the playable investigation. No mouse/UI bypass.
## All profiles and corruptions are confined to a unique user://tests/ directory.

var assertions := 0
var failures: Array[String] = []
var test_root := ""
var saves
var profiles
var shop
var rewards
var investigation
var state
var alice_id := ""
var bob_id := ""

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	for name in ["SaveService", "ProfileService", "ShopService", "RewardService", "InvestigationService", "AppState"]:
		if not root.has_node(name):
			_check(false, "Service requis : " + name)
	if not failures.is_empty():
		_finish()
		return
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	shop = root.get_node("ShopService")
	rewards = root.get_node("RewardService")
	investigation = root.get_node("InvestigationService")
	state = root.get_node("AppState")
	test_root = "user://tests/investigation_%s_%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	saves.root_path = test_root
	state.clear_profile()
	print("Racine temporaire : ", ProjectSettings.globalize_path(test_root))
	if not _ok(shop.load_catalog(), "Catalogue chargé") or not _ok(rewards.load_rules(), "Définitions chargées"):
		_finish()
		return
	var alice: Dictionary = profiles.create_profile("Enquête A")
	if not _ok(alice, "Créer le premier profil"):
		_finish()
		return
	alice_id = alice.data.id
	var bob: Dictionary = profiles.create_profile("Enquête B")
	if not _ok(bob, "Créer le deuxième profil"):
		_finish()
		return
	bob_id = bob.data.id
	_ok(profiles.select_profile(alice_id), "Sélection du profil A")
	_test_new_game_and_gates()
	_test_lighting()
	_test_lock()
	_test_computer()
	_test_isolation_replay_shop()
	_test_migration()
	_test_save_validation_and_recovery()
	_finish()

func _test_new_game_and_gates() -> void:
	print("\nNouvelle partie et prérequis")
	_check(not investigation.begin_mission("lighting").ok, "Un profil sans partie ne peut pas ouvrir le défi")
	_check(not rewards.complete_mission("lighting").ok, "L'ancienne API ne peut pas attribuer une réussite arbitraire")
	_ok(profiles.start_game(), "Nouvelle enquête initialisée")
	var progress: Dictionary = state.profile.progress
	_check(progress.started and progress.completed_missions.is_empty(), "Une nouvelle partie commence sans objectif terminé")
	_check(progress.investigation_version == 1 and progress.clues.is_empty() and progress.run_reward_points == 0, "Données de reprise initiales cohérentes")
	_check(investigation.mission_state("lighting") == "available" and investigation.mission_state("lock") == "locked" and investigation.mission_state("computer") == "locked", "États initiaux : un objectif disponible et deux verrouillés")
	_check(not investigation.begin_mission("lock").ok, "Serrure verrouillée avant l'éclairage")
	_check(not investigation.begin_mission("computer").ok, "Ordinateur verrouillé avant la serrure")
	_check(not investigation.submit_lock("control_link", "reconnect_control").ok, "Solution de serrure refusée sans prérequis")
	_check(not investigation.submit_computer(["video", "power"], "video_disconnected", "reconnect_video").ok, "Solution ordinateur refusée sans prérequis")
	_check(not investigation.begin_mission("unknown").ok, "Mission inconnue refusée")
	_check(state.profile.wallet.points == 0 and state.profile.progress.completed_missions.is_empty(), "Interactions précoces n'accordent aucun point ni réussite")
	_reload(alice_id, "Reprise d'une nouvelle partie")
	_check(state.profile.progress.started and state.profile.progress.completed_missions.is_empty(), "Nouvelle partie persistée après rechargement")

func _test_lighting() -> void:
	print("\nCircuit fermé réel, erreurs et transaction atomique")
	_ok(investigation.begin_mission("lighting"), "Défi éclairage ouvert")
	_check(investigation.mission_state("lighting") == "in_progress", "Un défi ouvert devient en cours")
	_check(not rewards.complete_mission("lighting").ok, "Ouvrir un défi ne permet pas de contourner sa validation métier")
	for connections in [[], ["source_switch"], ["source_switch", "switch_lamp"], ["source_lamp", "lamp_return"], ["source_switch", "switch_lamp", "lamp_return", "lamp_return"], ["source_switch", "switch_lamp", "lamp_return", "switch_return"], ["source_switch", "switch_lamp", "unknown"]]:
		var result: Dictionary = investigation.submit_lighting(connections)
		_check(not result.ok and not str(result.error).is_empty(), "Circuit incorrect expliqué : " + str(connections))
		_check(state.profile.wallet.points == 0 and not state.profile.progress.completed_missions.has("lighting"), "Circuit incorrect sans validation ni gain")
	var before: Dictionary = state.profile.duplicate(true)
	saves.simulate_write_failure = true
	var failed: Dictionary = investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"])
	saves.simulate_write_failure = false
	_check(not failed.ok, "Échec de sauvegarde de la réussite signalé")
	_check(state.profile == before and saves.read_profile(alice_id).data == before, "Échec conserve ensemble la progression, le solde et les récompenses")
	var success: Dictionary = investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"])
	_check(success.ok and success.data.reward == 50, "Boucle source–interrupteur–lampe–retour validée et récompensée")
	_check(state.profile.wallet.points == 50 and state.profile.progress.run_reward_points == 50, "Gain de partie distingué du solde")
	_check(state.profile.progress.completed_missions == ["lighting"] and state.profile.rewarded_missions == ["lighting"], "Mission et identifiant de récompense persistés ensemble")
	_check(investigation.mission_state("lighting") == "completed" and investigation.mission_state("lock") == "available" and investigation.mission_state("computer") == "locked", "Réussir le circuit débloque seulement la porte")
	_check(not state.profile.progress.clues.is_empty(), "La réussite révèle et conserve un indice")
	_check(state.profile.progress.clues.has("badge_note"), "Indice du badge ajouté seulement par la réussite du circuit")
	for attempt in range(5):
		var repeated: Dictionary = investigation.submit_lighting(["lamp_return", "source_switch", "switch_lamp"])
		_check(repeated.ok and repeated.data.reward == 0, "Validation rapide répétée sans second gain : " + str(attempt))
	_check(state.profile.wallet.points == 50 and state.profile.progress.run_reward_points == 50, "Aucun cumul après plusieurs validations")
	var snapshot: Dictionary = state.profile.duplicate(true)
	_reload(alice_id, "Reprise après l'éclairage")
	_check(state.profile == snapshot, "Éclairage, indice, checkpoint et récompense restaurés exactement")
	_ok(shop.purchase("avatar_orbit"), "Les points d'une mission sont immédiatement utilisables dans la boutique")
	_check(state.profile.wallet.points == 30 and state.profile.owned_items.has("avatar_orbit") and state.profile.progress.run_reward_points == 50, "Achat débite le solde sans réécrire le gain de la partie")
	_ok(shop.equip("avatar_orbit"), "Cosmétique équipé pendant l'enquête")

func _test_lock() -> void:
	print("\nDiagnostic alimentation / commande / liaison")
	_ok(investigation.begin_mission("lock"), "Serrure disponible après éclairage")
	_check(not investigation.submit_lock("control_link", "reconnect_control").ok, "Diagnostic correct refusé avant consultation des indices")
	_check(not investigation.observe("lock", "unknown").ok, "Observation de serrure inconnue refusée")
	var observation_before: Dictionary = state.profile.duplicate(true)
	saves.simulate_write_failure = true
	_check(not investigation.observe("lock", "badge").ok, "Échec de sauvegarde d'un indice consulté signalé")
	saves.simulate_write_failure = false
	_check(state.profile == observation_before and saves.read_profile(alice_id).data == observation_before, "Indice consulté sans sauvegarde ne reste pas partiellement en mémoire")
	for observation in ["badge", "power", "command"]:
		_ok(investigation.observe("lock", observation), "Observation serrure : " + observation)
	_check(not investigation.submit_lock("control_link", "reconnect_control").ok, "La liaison doit aussi être observée")
	_ok(investigation.observe("lock", "link"), "Liaison de commande examinée")
	_reload(alice_id, "Reprise avec observations de serrure avant résolution")
	_check(state.profile.progress.observations.lock.size() == 4, "Les quatre observations restent disponibles après rechargement")
	for answer in [["power_fault", "reconnect_control"], ["badge_fault", "reconnect_control"], ["control_link", "replace_power"], ["control_link", "change_badge"], ["unknown", "unknown"]]:
		var wrong: Dictionary = investigation.submit_lock(answer[0], answer[1])
		_check(not wrong.ok and not str(wrong.error).is_empty(), "Mauvais diagnostic ou réparation expliqué : " + str(answer))
		_check(not state.profile.progress.completed_missions.has("lock") and state.profile.wallet.points == 30, "Erreur de serrure ne valide pas et ne récompense pas")
	var before: Dictionary = state.profile.duplicate(true)
	saves.simulate_write_failure = true
	_check(not investigation.submit_lock("control_link", "reconnect_control").ok, "Échec d'écriture du diagnostic signalé")
	saves.simulate_write_failure = false
	_check(state.profile == before and saves.read_profile(alice_id).data == before, "Serrure non terminée et portefeuille inchangé après échec d'écriture")
	var success: Dictionary = investigation.submit_lock("control_link", "reconnect_control")
	_check(success.ok and success.data.reward == 50, "Liaison de commande reconnectée après diagnostic justifié")
	_check(state.profile.wallet.points == 80 and state.profile.progress.run_reward_points == 100, "Deux missions donnent 100 points de partie, achat déjà déduit du solde")
	_check(investigation.mission_state("lock") == "completed" and investigation.mission_state("computer") == "available", "La porte débloque le diagnostic ordinateur")
	_check(state.profile.progress.clues.has("video_note"), "La serrure réparée révèle l'indice vidéo")
	var snapshot: Dictionary = state.profile.duplicate(true)
	_reload(alice_id, "Reprise après l'ouverture de la porte")
	_check(state.profile == snapshot and state.profile.progress.completed_missions.has("lock"), "Porte ouverte et observations restaurées depuis une source unique")

func _test_computer() -> void:
	print("\nOrdinateur : observations, vérifications, cause et correction")
	_ok(investigation.begin_mission("computer"), "Ordinateur disponible après ouverture de la porte")
	_check(not investigation.submit_computer(["video", "power"], "video_disconnected", "reconnect_video").ok, "Réponse ne remplace pas l'observation des symptômes")
	_check(not investigation.check_computer("video").ok, "Une vérification ne court-circuite pas la phase d'observation")
	for symptom in ["pc", "display", "no_signal"]:
		_ok(investigation.observe("computer", symptom), "Symptôme observé : " + symptom)
	_check(not investigation.observe("computer", "unknown").ok, "Symptôme inconnu refusé")
	_check(not investigation.check_computer("unknown").ok, "Vérification inconnue refusée")
	_ok(investigation.check_computer("power"), "Vérifier alimentation de l'écran et démarrage")
	_check(not investigation.submit_computer(["video", "power"], "video_disconnected", "reconnect_video").ok, "L'interface ne peut pas inventer une vérification vidéo non effectuée")
	_ok(investigation.check_computer("video"), "Vérifier le câble vidéo")
	_reload(alice_id, "Reprise avec ordinateur encore en cours de diagnostic")
	_check(state.profile.progress.observations.computer.size() == 3 and state.profile.progress.checks.computer.size() == 2, "Observations et vérifications conservées avant validation finale")
	for answer in [[[], "video_disconnected", "reconnect_video"], [["power"], "video_disconnected", "reconnect_video"], [["video", "power"], "screen_power", "reconnect_video"], [["video", "power"], "network_fault", "reconnect_video"], [["video", "power"], "video_disconnected", "reset_network"], [["video", "power"], "video_disconnected", "replace_screen"], [["video", "power", "unknown"], "video_disconnected", "reconnect_video"]]:
		var wrong: Dictionary = investigation.submit_computer(answer[0], answer[1], answer[2])
		_check(not wrong.ok and not str(wrong.error).is_empty(), "Hypothèse ou correction incorrecte expliquée : " + str(answer))
		_check(not state.profile.progress.completed_missions.has("computer") and state.profile.wallet.points == 80, "Erreur ordinateur sans réussite ni récompense")
	var before: Dictionary = state.profile.duplicate(true)
	saves.simulate_write_failure = true
	_check(not investigation.submit_computer(["video", "power"], "video_disconnected", "reconnect_video").ok, "Échec d'écriture ordinateur signalé")
	saves.simulate_write_failure = false
	_check(state.profile == before and saves.read_profile(alice_id).data == before, "Échec ordinateur laisse une transaction entière inchangée")
	var success: Dictionary = investigation.submit_computer(["video", "power"], "video_disconnected", "reconnect_video")
	_check(success.ok and success.data.reward == 50, "Câble vidéo reconnecté virtuellement après les vérifications")
	_check(state.profile.wallet.points == 130 and state.profile.progress.run_reward_points == 150, "Bilan : 150 points nouvellement gagnés, solde réel 130 après achat")
	_check(state.profile.progress.clues.has("incident_message"), "Le message de conclusion est obtenu seulement après réparation")
	_check(investigation.mission_state("computer") == "completed", "Le troisième objectif est terminé après validation métier")
	_check(state.profile.progress.completed_missions == ["lighting", "lock", "computer"] and state.profile.rewarded_missions.size() == 3, "Les trois missions et récompenses sont cohérentes")
	var snapshot: Dictionary = state.profile.duplicate(true)
	_reload(alice_id, "Reprise de l'enquête terminée")
	_check(state.profile == snapshot, "Conclusion et salle réparée restaurées après rechargement")
	var repeated: Dictionary = investigation.submit_computer(["video", "power"], "video_disconnected", "reconnect_video")
	_check(repeated.ok and repeated.data.reward == 0 and state.profile.wallet.points == 130, "Relancer une validation finale ne double pas le gain")

func _test_isolation_replay_shop() -> void:
	print("\nDeux profils, nouvelle partie et conservation des achats")
	var alice_completed: Dictionary = state.profile.duplicate(true)
	_ok(profiles.select_profile(bob_id), "Changer vers le profil B")
	_check(state.profile.wallet.points == 0 and state.profile.rewarded_missions.is_empty() and state.profile.progress.clues.is_empty() and not state.profile.progress.started, "Aucune donnée d'enquête ou de boutique ne passe au profil B")
	_ok(profiles.start_game(), "Le profil B commence sa propre enquête")
	_ok(investigation.begin_mission("lighting"), "Éclairage du profil B")
	var bob_reward: Dictionary = investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"])
	_check(bob_reward.ok and bob_reward.data.reward == 50 and state.profile.wallet.points == 50, "Le profil B gagne sa propre première récompense")
	_check(saves.read_profile(alice_id).data == alice_completed, "La mission du profil B ne modifie pas le profil A")
	_ok(profiles.select_profile(alice_id), "Retour au profil A")
	_check(state.profile == alice_completed and state.profile.equipped.avatar == "avatar_orbit", "Équipement et progression du profil A conservés")
	_ok(profiles.start_game(), "Rejouer remet à zéro la progression seulement")
	_check(state.profile.progress.completed_missions.is_empty() and state.profile.progress.clues.is_empty() and state.profile.progress.run_reward_points == 0, "Nouvelle partie efface objectifs, indices et compteur de partie")
	_check(state.profile.wallet.points == 130 and state.profile.rewarded_missions.size() == 3 and state.profile.owned_items.has("avatar_orbit") and state.profile.equipped.avatar == "avatar_orbit", "Solde, achats et récompenses déjà attribuées survivent au rejeu")
	for mission_id in ["lighting", "lock", "computer"]:
		_prepare(mission_id)
		var replay: Dictionary = _submit(mission_id)
		_check(replay.ok and replay.data.reward == 0, "Rejouer ne récompense pas une seconde fois : " + mission_id)
	_check(state.profile.wallet.points == 130 and state.profile.progress.run_reward_points == 0, "Conclusion du rejeu affiche zéro point nouvellement gagné")
	_ok(profiles.reset_progress(), "Réinitialisation de progression depuis les paramètres")
	_check(not state.profile.progress.started and state.profile.progress.completed_missions.is_empty() and state.profile.wallet.points == 130 and state.profile.rewarded_missions.size() == 3, "Réinitialiser conserve toutes les données économiques")

func _test_migration() -> void:
	print("\nMigration explicite des anciennes simulations")
	var created: Dictionary = profiles.create_profile("Ancien prototype")
	if not _ok(created, "Créer une copie pour migration"):
		return
	var id: String = created.data.id
	var legacy: Dictionary = created.data.duplicate(true)
	legacy.wallet.points = 130
	legacy.owned_items.append("avatar_orbit")
	legacy.equipped.avatar = "avatar_orbit"
	legacy.rewarded_missions = ["lighting", "lock", "computer"]
	legacy.progress = {"started": true, "room_id": "room_01", "checkpoint_id": "computer", "completed_missions": ["lighting", "lock", "computer"]}
	state.clear_profile()
	var legacy_text := JSON.stringify(legacy)
	_check(_write_raw(_profile_path(id), legacy_text), "Copie de l'ancien schéma écrite uniquement dans la racine de test")
	var migration: Dictionary = saves.read_profile(id)
	if not _ok(migration, "Ancien document reconnu sans l'effacer"):
		return
	_check(FileAccess.get_file_as_string(_profile_path(id)) == legacy_text, "Une lecture seule n'écrase pas l'ancienne sauvegarde")
	_check(migration.data.wallet == legacy.wallet and migration.data.owned_items == legacy.owned_items and migration.data.equipped == legacy.equipped and migration.data.rewarded_missions == legacy.rewarded_missions, "Migration conserve portefeuille, récompenses et cosmétiques")
	_check(migration.data.progress.completed_missions.is_empty() and migration.data.progress.checkpoint_id == "entrance" and migration.data.progress.legacy_migration_notice, "Les simulations ne sont pas présentées comme des défis résolus, avec avis explicite")
	_ok(profiles.select_profile(id), "La sélection persiste la migration avec copie précédente")
	var persisted: Dictionary = _read_json(_profile_path(id))
	_check(persisted.progress.investigation_version == 1 and FileAccess.get_file_as_string(_profile_path(id) + ".bak") == legacy_text, "Document enrichi enregistré et prototype précédent conservé")
	_ok(investigation.acknowledge_migration(), "L'avis de migration peut être acquitté explicitement")
	_check(not state.profile.progress.legacy_migration_notice, "L'avis acquitté ne revient pas à chaque chargement")
	_ok(profiles.start_game(), "Nouvelle enquête réelle après migration")
	_prepare("lighting")
	var reward: Dictionary = _submit("lighting")
	_check(reward.ok and reward.data.reward == 0 and state.profile.wallet.points == 130, "Les points du prototype ne peuvent pas être gagnés une deuxième fois")
	_ok(profiles.select_profile(alice_id), "Restaurer le profil A après la copie de migration")

func _test_save_validation_and_recovery() -> void:
	print("\nValidation du nouveau progrès et récupération contrôlée")
	var valid: Dictionary = state.profile.duplicate(true)
	_check(saves.validate_profile(valid).ok, "Nouveau document valide accepté")
	for key_value in [["investigation_version", 999], ["investigation_version", "1"], ["clues", ["unknown_clue"]], ["clues", "badge"], ["active_mission", "unknown"], ["run_reward_points", -1], ["run_reward_points", 49], ["run_reward_points", 500], ["run_reward_points", 1.5], ["legacy_migration_notice", "oui"], ["observations", {"lighting": [], "lock": ["unknown"], "computer": []}], ["checks", {"computer": ["unknown"]}]]:
		var invalid: Dictionary = valid.duplicate(true)
		invalid.progress[key_value[0]] = key_value[1]
		_check(not saves.validate_profile(invalid).ok, "Champ de progression invalide refusé : " + str(key_value))
	var out_of_order: Dictionary = valid.duplicate(true)
	out_of_order.progress.started = true
	out_of_order.progress.completed_missions = ["computer"]
	out_of_order.rewarded_missions = ["computer"]
	_check(not saves.validate_profile(out_of_order).ok, "Mission terminée sans prérequis refusée dans le nouveau schéma")
	var created: Dictionary = profiles.create_profile("Copie enquête")
	if not _ok(created, "Créer une copie de corruption"):
		return
	var id: String = created.data.id
	_ok(profiles.start_game(), "Commencer la copie de corruption")
	_prepare("lighting")
	_ok(_submit("lighting"), "Terminer l'éclairage de la copie")
	_ok(profiles.save_active(), "Créer une sauvegarde précédente de la progression valide")
	var before: Dictionary = state.profile.duplicate(true)
	state.clear_profile()
	var corrupted := "{ sauvegarde de test corrompue"
	_check(_write_raw(_profile_path(id), corrupted), "Corrompre uniquement le document de test")
	_check(not saves.read_profile(id).ok and FileAccess.get_file_as_string(_profile_path(id)) == corrupted, "Corruption signalée sans effacement silencieux")
	var recovered: Dictionary = saves.recover_profile(id)
	_check(recovered.ok and recovered.data == before and saves.read_profile(id).data == before, "Copie précédente restaure mission, indice et récompense de manière cohérente")
	_ok(profiles.select_profile(id), "Recharger le document récupéré")
	var repeated: Dictionary = _submit("lighting")
	_check(repeated.ok and repeated.data.reward == 0 and state.profile.wallet.points == 50, "Une récupération ne permet pas de cumuler la récompense déjà sauvegardée")

func _prepare(id: String) -> void:
	_ok(investigation.begin_mission(id), "Défi ouvert : " + id)
	if id == "lock":
		for observation in ["badge", "power", "command", "link"]:
			_ok(investigation.observe(id, observation), "Observation : " + observation)
	elif id == "computer":
		for observation in ["pc", "display", "no_signal"]:
			_ok(investigation.observe(id, observation), "Symptôme : " + observation)
		for verification in ["video", "power"]:
			_ok(investigation.check_computer(verification), "Vérification : " + verification)

func _submit(id: String) -> Dictionary:
	match id:
		"lighting": return investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"])
		"lock": return investigation.submit_lock("control_link", "reconnect_control")
		"computer": return investigation.submit_computer(["video", "power"], "video_disconnected", "reconnect_video")
	return {"ok": false, "error": "Mission inconnue", "data": {}}

func _reload(id: String, description: String) -> void:
	state.clear_profile()
	_ok(profiles.select_profile(id), description)

func _profile_path(id: String) -> String:
	return test_root.path_join("profiles").path_join(id + ".json")

func _ok(result: Dictionary, description: String) -> bool:
	var success := bool(result.get("ok", false))
	_check(success, description + (" : " + str(result.get("error", "")) if not success else ""))
	return success

func _check(condition: bool, description: String) -> void:
	assertions += 1
	if condition:
		print("  OK  ", description)
	else:
		failures.append(description)
		printerr("  ÉCHEC  ", description)

func _write_raw(path: String, content: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	file.flush()
	var written := file.get_error() == OK
	file.close()
	return written

func _read_json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _remove_tree(path: String) -> void:
	if test_root.is_empty() or not path.begins_with(test_root):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file in directory.get_files():
		directory.remove(file)
	for child in directory.get_directories():
		_remove_tree(path.path_join(child))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _finish() -> void:
	if not test_root.is_empty():
		_remove_tree(test_root)
	print("\nRésultat enquête : %s assertions, %s échec(s)." % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
