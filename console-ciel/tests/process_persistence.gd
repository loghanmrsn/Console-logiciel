extends SceneTree
## True relaunch acceptance worker. Invoked by tools/run_acceptance.py in three
## separate Godot processes, using one marked /tmp fixture and no normal data.

var checks := 0
var failures: Array[String] = []
var stage := ""
var test_root := ""
var saves
var profiles
var settings
var shop
var investigation
var state
var fixture: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	for index in range(args.size() - 1):
		if args[index] == "--stage": stage = args[index + 1]
		if args[index] == "--test-data-root": test_root = args[index + 1]
	if stage not in ["write", "read_replay", "read_final"] or not test_root.begins_with("/tmp/ciel-acceptance-") or ".." in test_root:
		_check(false, "Une étape explicite et une racine /tmp/ciel-acceptance-* sont obligatoires")
		_finish()
		return
	fixture = _json(test_root.path_join("acceptance_fixture.json"))
	if fixture.get("purpose") != "CIEL isolated process acceptance" or fixture.get("schema_version") != 1:
		_check(false, "Le marqueur explicite de données de test est obligatoire")
		_finish()
		return
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	settings = root.get_node("SettingsService")
	shop = root.get_node("ShopService")
	investigation = root.get_node("InvestigationService")
	state = root.get_node("AppState")
	saves.root_path = test_root.path_join("data")
	settings.storage_root = saves.root_path
	_check(state.profile.is_empty(), "Un processus neuf ne conserve aucun profil en mémoire")
	_check(shop.load_catalog().ok and root.get_node("RewardService").load_rules().ok, "Catalogue et missions rechargés depuis les ressources livrées")
	if not failures.is_empty():
		_finish()
		return
	# JSON represents all numeric literals as floats. Compare normalized domain
	# documents, so this assertion checks state rather than JSON parser types.
	if fixture.has("expected_profile"):
		fixture.expected_profile = saves.validate_profile(fixture.expected_profile, fixture.alice_id).data
	if fixture.has("expected_settings"):
		fixture.expected_settings = settings._normalize(fixture.expected_settings).data
	match stage:
		"write": _write_first_session()
		"read_replay": _read_and_replay()
		"read_final": _read_final()
	_finish()


func _write_first_session() -> void:
	_check(profiles.refresh().ok and profiles.profiles.is_empty(), "Premier processus : aucun profil préexistant dans la copie de test")
	var alice: Dictionary = profiles.create_profile("Recette A")
	var bob: Dictionary = profiles.create_profile("Recette B")
	if not _ok(alice, "Création du profil A") or not _ok(bob, "Création du profil B"):
		return
	fixture.alice_id = alice.data.id
	fixture.bob_id = bob.data.id
	_ok(profiles.select_profile(fixture.alice_id), "Sélection de A")
	_ok(profiles.start_game(), "Initialisation de la première enquête")
	_check(not investigation.begin_mission("lock").ok, "Liaison de commande indisponible avant l'éclairage")
	_ok(investigation.begin_mission("lighting"), "Ouverture de la mission éclairage")
	_check(not investigation.submit_lighting(["source_switch", "switch_lamp"]).ok and state.profile.wallet.points == 0, "Boucle ouverte : erreur expliquée sans gain")
	var before: Dictionary = state.profile.duplicate(true)
	saves.simulate_write_failure = true
	_check(not investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"]).ok, "Erreur d'écriture de mission injectée dans les données de test")
	saves.simulate_write_failure = false
	_check(state.profile == before and saves.read_profile(fixture.alice_id).data == before, "Échec : mémoire, document, points et récompenses restent cohérents")
	_ok(_solve("lighting"), "Nouvel essai de mission réussi")
	_check(state.profile.wallet.points == 50 and state.profile.progress.run_reward_points == 50, "Première mission : 50 points réellement sauvegardés")
	_ok(_solve("lock"), "Diagnostic et correction de la serrure")
	_ok(_solve("computer"), "Diagnostic et correction vidéo")
	_check(state.profile.wallet.points == 150 and state.profile.progress.run_reward_points == 150, "Trois missions terminées : 150 points gagnés pendant cette partie")
	var result: Dictionary = investigation.conclusion()
	_check(result.ok and result.data.run_reward_points == 150 and result.data.wallet_points == 150, "Bilan : gains de partie et solde distincts")
	before = state.profile.duplicate(true)
	saves.simulate_write_failure = true
	_check(not shop.purchase("avatar_orbit").ok, "Erreur d'écriture d'achat injectée")
	saves.simulate_write_failure = false
	_check(state.profile == before and saves.read_profile(fixture.alice_id).data == before, "Achat échoué : aucun débit partiel")
	_ok(shop.purchase("avatar_orbit"), "Achat en points gagnés dans l'enquête")
	_ok(shop.equip("avatar_orbit"), "Équipement du cosmétique acheté")
	_check(state.profile.wallet.points == 130 and state.profile.equipped.avatar == "avatar_orbit", "20 points débités exactement, avatar équipé")
	var original: Dictionary = settings.committed.duplicate(true)
	var changed: Dictionary = original.duplicate(true)
	changed.master = 41
	changed.deadzone = 0.34
	changed.reduce_motion = true
	_ok(settings.preview(changed), "Aperçu réel de réglages")
	settings.cancel_preview()
	_check(settings.current == original, "Annuler restaure l'aperçu audio, accessibilité et commandes")
	_ok(settings.apply_settings(changed), "Réglages appliqués et sauvegardés")
	_ok(profiles.save_active(), "Sauvegarde explicite avant fermeture du premier processus")
	fixture.expected_profile = state.profile.duplicate(true)
	fixture.expected_settings = settings.committed.duplicate(true)
	_check(_write_json(test_root.path_join("acceptance_fixture.json"), fixture), "Identifiants de test transmis au prochain processus")


func _read_and_replay() -> void:
	_ok(settings.load_settings(), "Second processus : lecture des réglages persistants")
	_check(settings.current == fixture.expected_settings and settings.committed == fixture.expected_settings, "Réglages conservés après fermeture complète et nouvelle exécution")
	_ok(profiles.refresh(), "Second processus : lecture des deux profils")
	_check(profiles.profiles.size() == 2 and profiles.last_profile_id == fixture.alice_id, "Les deux profils et la dernière sélection sont conservés après relance")
	_ok(profiles.select_profile(fixture.alice_id), "Reprise du profil A après relance réelle")
	_check(state.profile == fixture.expected_profile, "Progression, indices, checkpoint, points, inventaire, récompenses et équipement restaurés à l'identique")
	for id in ["lighting", "lock", "computer"]:
		_check(investigation.mission_state(id) == "completed", "La reprise restaure la mission terminée : " + id)
		var repeated: Dictionary = _solve(id)
		_check(repeated.ok and repeated.data.reward == 0, "Nouvelle validation après relance ne double pas le gain : " + id)
	_check(state.profile.wallet.points == 130, "Le solde n'augmente pas en reprenant des missions terminées")
	var snapshot: Dictionary = state.profile.duplicate(true)
	_check(not shop.purchase("avatar_orbit").ok and state.profile == snapshot, "Double achat après relance refusé sans débit")
	_ok(profiles.select_profile(fixture.bob_id), "Changement vers le profil B")
	_check(state.profile.wallet.points == 0 and state.profile.rewarded_missions.is_empty() and state.profile.progress.completed_missions.is_empty() and not state.profile.owned_items.has("avatar_orbit"), "B n'hérite ni progression, ni indice, ni points, ni objet de A")
	_ok(profiles.select_profile(fixture.alice_id), "Retour vers le profil A")
	_check(state.profile == snapshot, "Changer de profil restaure toutes les données du bon joueur")
	_ok(profiles.reset_progress(), "Réinitialiser uniquement l'enquête de A")
	_check(state.profile.wallet.points == 130 and state.profile.rewarded_missions.size() == 3 and state.profile.owned_items.has("avatar_orbit") and state.profile.equipped.avatar == "avatar_orbit", "La remise à zéro conserve achats, solde, récompenses et équipement")
	_ok(profiles.start_game(), "Rejouer l'enquête sans crédit de test")
	var replay: Dictionary = _solve("lighting")
	_check(replay.ok and replay.data.reward == 0 and state.profile.progress.run_reward_points == 0 and state.profile.wallet.points == 130, "Éclairage rejoué : aucun nouveau gain, y compris après relance")
	_ok(profiles.save_active(), "Sauvegarde avant fermeture du deuxième processus")
	fixture.expected_profile = state.profile.duplicate(true)
	_check(_write_json(test_root.path_join("acceptance_fixture.json"), fixture), "Nouvel état de test transmis au troisième processus")


func _read_final() -> void:
	_ok(profiles.refresh(), "Troisième processus : lecture de la dernière session")
	_ok(profiles.select_profile(fixture.alice_id), "Reprise après relance d'une enquête rejouée")
	_check(state.profile == fixture.expected_profile and state.profile.wallet.points == 130 and state.profile.progress.completed_missions == ["lighting"], "L'état de reprise enregistré après replay survit à une seconde relance réelle")
	_ok(profiles.update_profile("Recette renommée", "avatar_orbit"), "Renommer après relance")
	_check(state.profile.id == fixture.alice_id, "Le renommage conserve l'identifiant indépendant du pseudo")
	var alice: Dictionary = state.profile.duplicate(true)
	_ok(profiles.delete_profile(fixture.bob_id), "Supprimer seulement le profil B de test")
	_check(not saves.read_profile(fixture.bob_id).ok and saves.read_profile(fixture.alice_id).data == alice, "La suppression de B laisse intactes toutes les données de A")
	_ok(profiles.refresh(), "Liste après suppression ciblée")
	_check(profiles.profiles.size() == 1 and profiles.profiles[0].id == fixture.alice_id, "Un seul profil reste, celui conservé")


func _solve(id: String) -> Dictionary:
	var opened: Dictionary = investigation.begin_mission(id)
	if not opened.ok:
		return opened
	match id:
		"lighting": return investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"])
		"lock":
			for observation in ["badge", "power", "command", "link"]:
				var result: Dictionary = investigation.observe(id, observation)
				if not result.ok: return result
			return investigation.submit_lock("control_link", "reconnect_control")
		"computer":
			for observation in ["pc", "display", "no_signal"]:
				var result: Dictionary = investigation.observe(id, observation)
				if not result.ok: return result
			for check in ["video", "power"]:
				var result: Dictionary = investigation.check_computer(check)
				if not result.ok: return result
			return investigation.submit_computer(["video", "power"], "video_disconnected", "reconnect_video")
	return {"ok": false, "error": "Mission de test inconnue.", "data": null}


func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var value = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}


func _write_json(path: String, value: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(value, "\t"))
	file.close()
	return true


func _ok(result: Dictionary, label: String) -> bool:
	_check(result.ok, label + (" : " + str(result.error) if not result.ok else ""))
	return result.ok


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		print("ECHEC : ", label)


func _finish() -> void:
	print("PROCESS_PERSISTENCE %s : %d assertions, %d échec(s)." % [stage, checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
