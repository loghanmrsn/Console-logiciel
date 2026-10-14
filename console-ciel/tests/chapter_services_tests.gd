extends SceneTree
## Chapter transitions and educational solutions use real services and isolated saves.

var assertions := 0
var failures: Array[String] = []
var test_root := ""
var saves
var profiles
var shop
var rewards
var investigation
var state
var first_id := ""
var second_id := ""
var chapter_one_snapshot: Dictionary = {}
var completed_snapshot: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	shop = root.get_node("ShopService")
	rewards = root.get_node("RewardService")
	investigation = root.get_node("InvestigationService")
	state = root.get_node("AppState")
	test_root = "user://tests/chapters_%s_%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	saves.root_path = test_root
	state.clear_profile()
	print("Racine temporaire : ", ProjectSettings.globalize_path(test_root))
	if not _ok(shop.load_catalog(), "Catalogue chargé") or not _ok(rewards.load_rules(), "Six défis chargés"):
		_finish()
		return
	var first: Dictionary = profiles.create_profile("Étage A")
	if not _ok(first, "Créer le profil A"):
		_finish()
		return
	first_id = first.data.id
	var second: Dictionary = profiles.create_profile("Étage B")
	if not _ok(second, "Créer le profil B"):
		_finish()
		return
	second_id = second.data.id
	_ok(profiles.select_profile(first_id), "Sélection du profil A")
	_test_rules_and_initial_gates()
	_test_first_chapter()
	_test_transition()
	_test_second_chapter()
	_test_legacy_expansion()
	_test_invalid_documents()
	_test_profiles_and_replay()
	_finish()

func _test_rules_and_initial_gates() -> void:
	_check(rewards.missions.size() == 6, "Six missions livrées, sans modifier la version d’enquête")
	var reward_total := 0
	for definition in rewards.missions:
		reward_total += int(definition.reward)
	_check(reward_total == 300, "Plafond de six récompenses pédagogiques : 300 points")
	_check(investigation.current_chapter() == 1, "Profil neuf dans le premier chapitre")
	_check(_ids(investigation.chapter_missions()) == ["lighting", "lock", "computer"], "Trois objectifs du chapitre courant")
	_check(_ids(investigation.chapter_missions(2)) == ["network", "addressing", "security"], "Trois objectifs du deuxième chapitre dans l’ordre")
	_check(investigation.chapter_missions(99).is_empty(), "Chapitre inconnu sans missions")
	_check(not investigation.can_use_elevator(), "Ascenseur inaccessible avant de commencer")
	_check(not investigation.enter_chapter(2).ok, "Pas de changement d’étage sans enquête")
	_check(not investigation.enter_chapter(0).ok and not investigation.enter_chapter(3).ok, "Étages inconnus refusés")
	_check(not investigation.conclusion(2).ok and not investigation.conclusion(99).ok, "Pas de bilan anticipé ou inconnu")
	_ok(profiles.start_game(), "Commencer l’enquête")
	for id in saves.CHAPTER_TWO_IDS:
		_check(investigation.mission_state(id) == "locked", "Objectif d’étage initialement verrouillé : " + id)
		_check(not investigation.begin_mission(id).ok, "Défi d’étage inaccessible depuis le rez-de-chaussée : " + id)
		var definition: Dictionary = investigation.mission(id)
		_check(not investigation.observe(id, definition.observations[0].id).ok, "Observation d’étage inaccessible : " + id)
		_check(not investigation.submit_diagnostic(id, definition.solution.diagnosis, definition.solution.repair).ok, "Solution correcte ne contourne pas l’étage : " + id)
	_check(not investigation.submit_diagnostic("lighting", "x", "y").ok, "Diagnostic générique ne contourne pas le circuit électrique")
	_check(not investigation.submit_diagnostic("unknown", "x", "y").ok, "Diagnostic de mission inconnue refusé")
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/game_rules.json"))
	for mutation in ["chapter", "room", "order", "observation", "solution", "total"]:
		var invalid: Dictionary = rules.duplicate(true)
		match mutation:
			"chapter": invalid.missions[3].chapter = 1
			"room": invalid.missions[3].room_id = "room_01"
			"order": invalid.missions[4].prerequisites = ["computer"]
			"observation": invalid.missions[5].observations[0].id = "unexpected"
			"solution": invalid.missions[5].solution.repair = "hide_ssid"
			"total": invalid.mission_reward_max = 150
		_check(not saves.validate_rules(invalid).ok, "Règle d’étage incohérente refusée : " + mutation)

func _test_first_chapter() -> void:
	for id in saves.CHAPTER_ONE_IDS:
		_complete(id)
		if id != "computer":
			_check(not investigation.can_use_elevator() and not investigation.enter_chapter(2).ok, "Ascenseur reste verrouillé après " + id)
	_check(state.profile.wallet.points == 150 and state.profile.progress.run_reward_points == 150, "Premier chapitre conserve ses trois gains de 50")
	_check(investigation.can_use_elevator(), "Ascenseur déverrouillé uniquement après les trois défis")
	for id in saves.CHAPTER_TWO_IDS:
		_check(investigation.mission_state(id) == "locked", "Objectif supérieur encore verrouillé tant qu’on reste en bas : " + id)
		_check(not investigation.begin_mission(id).ok, "Prérequis accomplis ne permettent pas d’ouvrir le défi depuis le mauvais étage : " + id)
	_check(not investigation.conclusion(2).ok, "Bilan du deuxième chapitre encore verrouillé")
	var first_bilan: Dictionary = investigation.conclusion()
	_check(first_bilan.ok and first_bilan.data.chapter == 1 and first_bilan.data.missions.size() == 3, "Ancien appel conclusion() reste limité au premier chapitre")
	_ok(shop.purchase("game_test_1"), "Acheter un jeu avec les points du premier chapitre")
	_ok(shop.equip("theme_brume"), "Équipement de profil enregistré")
	_check(state.profile.wallet.points == 130 and state.profile.progress.run_reward_points == 150, "Achat conserve le total gagné et débite uniquement le portefeuille")
	chapter_one_snapshot = state.profile.duplicate(true)
	var exit_document: Dictionary = chapter_one_snapshot.duplicate(true)
	exit_document.progress.checkpoint_id = "exit"
	_check(saves.validate_profile(exit_document).ok, "Ancien point de reprise exit reste valide après les trois premières missions")
	_reload(first_id, "Reprendre le premier chapitre terminé")
	_check(state.profile == chapter_one_snapshot, "Les six définitions ne changent pas une progression récente valide")

func _test_transition() -> void:
	var before: Dictionary = state.profile.duplicate(true)
	var disk := FileAccess.get_file_as_string(_profile_path(first_id))
	saves.simulate_write_failure = true
	var failed: Dictionary = investigation.enter_chapter(2)
	saves.simulate_write_failure = false
	_check(not failed.ok, "Échec d’écriture du changement d’étage signalé")
	_check(state.profile == before and FileAccess.get_file_as_string(_profile_path(first_id)) == disk, "Transition échouée ne déplace ni personnage sauvegardé ni données économiques")
	var entered: Dictionary = investigation.enter_chapter(2)
	_check(entered.ok and entered.data.chapter == 2 and entered.data.room_id == "room_02" and entered.data.checkpoint_id == "elevator", "Ascenseur mène au deuxième chapitre et à son point de reprise")
	_check(investigation.current_chapter() == 2 and _ids(investigation.chapter_missions()) == saves.CHAPTER_TWO_IDS, "Chapitre et tableau de missions dérivent de la salle sauvegardée")
	_check(state.profile.progress.active_mission.is_empty() and state.profile.wallet == before.wallet and state.profile.owned_items == before.owned_items and state.profile.rewarded_missions == before.rewarded_missions, "Transition conserve portefeuille, achats et récompenses, sans mission active d’un autre étage")
	_check(investigation.mission_state("network") == "available" and investigation.mission_state("addressing") == "locked" and investigation.mission_state("security") == "locked", "Seule la première mission réseau est disponible à l’arrivée")
	_check(not investigation.begin_mission("lighting").ok and not investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"]).ok, "Interactions du premier étage refusées dans la salle réseau")
	var snapshot: Dictionary = state.profile.duplicate(true)
	_reload(first_id, "Reprendre après le trajet en ascenseur")
	_check(state.profile == snapshot and investigation.current_chapter() == 2, "L’étage d’arrivée est repris fidèlement après rechargement")
	_ok(investigation.begin_mission("network"), "Ouvrir le diagnostic réseau")
	_ok(investigation.enter_chapter(1), "Redescendre avant de finir le réseau")
	_check(investigation.current_chapter() == 1 and state.profile.progress.checkpoint_id == "elevator" and state.profile.progress.active_mission.is_empty(), "Retour au premier étage près de l’ascenseur avec mission active vidée")
	_check(investigation.conclusion(1).ok and not investigation.conclusion(2).ok, "Bilans restent propres au chapitre demandé après le retour")
	_ok(investigation.enter_chapter(2), "Revenir dans la salle réseau")

func _test_second_chapter() -> void:
	for id in saves.CHAPTER_TWO_IDS:
		var definition: Dictionary = investigation.mission(id)
		var before: Dictionary = state.profile.duplicate(true)
		_check(not investigation.submit_diagnostic(id, definition.solution.diagnosis, definition.solution.repair).ok, "Bonne réponse refusée sans les observations : " + id)
		_check(state.profile == before, "Tentative sans preuve ne change pas la sauvegarde : " + id)
		_ok(investigation.begin_mission(id), "Ouvrir le défi : " + id)
		_check(not investigation.observe(id, "unknown").ok, "Observation inconnue refusée : " + id)
		var observation_disk := FileAccess.get_file_as_string(_profile_path(first_id))
		var observation_snapshot: Dictionary = state.profile.duplicate(true)
		saves.simulate_write_failure = true
		_check(not investigation.observe(id, definition.observations[0].id).ok, "Observation échouée à l’écriture signalée : " + id)
		saves.simulate_write_failure = false
		_check(state.profile == observation_snapshot and FileAccess.get_file_as_string(_profile_path(first_id)) == observation_disk, "Observation échouée ne reste pas partiellement consultée : " + id)
		for index in range(definition.observations.size()):
			_ok(investigation.observe(id, definition.observations[index].id), "Observation pédagogique : " + id + "/" + definition.observations[index].id)
			if index < definition.observations.size() - 1:
				_check(not investigation.submit_diagnostic(id, definition.solution.diagnosis, definition.solution.repair).ok, "Toutes les observations restent nécessaires : " + id + "/" + str(index))
		var observed: Dictionary = state.profile.duplicate(true)
		_ok(investigation.observe(id, definition.observations[0].id), "Observation répétée sans duplication : " + id)
		_check(state.profile == observed, "Relire un indice laisse la progression identique : " + id)
		_reload(first_id, "Reprendre avant le diagnostic : " + id)
		_check(state.profile == observed, "Observations et mission active conservées avant solution : " + id)
		for choice in definition.diagnoses:
			if choice.id != definition.solution.diagnosis:
				var wrong: Dictionary = investigation.submit_diagnostic(id, choice.id, definition.solution.repair)
				_check(not wrong.ok and wrong.error == choice.feedback, "Diagnostic incorrect fournit son explication pédagogique : " + id + "/" + choice.id)
		for choice in definition.repairs:
			if choice.id != definition.solution.repair:
				var wrong: Dictionary = investigation.submit_diagnostic(id, definition.solution.diagnosis, choice.id)
				_check(not wrong.ok and wrong.error == choice.feedback, "Réparation incorrecte fournit son explication pédagogique : " + id + "/" + choice.id)
		_check(not investigation.submit_diagnostic(id, "unknown", definition.solution.repair).ok and not investigation.submit_diagnostic(id, definition.solution.diagnosis, "unknown").ok, "Solutions inconnues refusées : " + id)
		_check(state.profile == observed, "Les mauvaises solutions n’accordent ni réussite ni gain : " + id)
		var before_solution: Dictionary = state.profile.duplicate(true)
		var solution_disk := FileAccess.get_file_as_string(_profile_path(first_id))
		saves.simulate_write_failure = true
		_check(not investigation.submit_diagnostic(id, definition.solution.diagnosis, definition.solution.repair).ok, "Récompense échouée à l’écriture signalée : " + id)
		saves.simulate_write_failure = false
		_check(state.profile == before_solution and FileAccess.get_file_as_string(_profile_path(first_id)) == solution_disk, "Réussite et récompense restent indivisibles après l’échec : " + id)
		var success: Dictionary = investigation.submit_diagnostic(id, definition.solution.diagnosis, definition.solution.repair)
		_check(success.ok and success.data.reward == 50 and success.data.explanation == definition.success_explanation, "Solution justifiée rapporte 50 points et son explication : " + id)
		_check(state.profile.wallet.points == before_solution.wallet.points + 50 and state.profile.progress.run_reward_points == before_solution.progress.run_reward_points + 50, "Gain économique enregistré exactement une fois : " + id)
		_check(state.profile.progress.completed_missions.has(id) and state.profile.rewarded_missions.has(id) and state.profile.progress.clues.has(definition.clue.id) and state.profile.progress.checkpoint_id == id, "Réussite, indice, récompense et reprise enregistrés ensemble : " + id)
		var solved: Dictionary = state.profile.duplicate(true)
		for repetition in range(3):
			var repeated: Dictionary = investigation.submit_diagnostic(id, definition.solution.diagnosis, definition.solution.repair)
			_check(repeated.ok and repeated.data.reward == 0 and state.profile == solved, "Validation répétée sans second gain : " + id + "/" + str(repetition))
		_reload(first_id, "Recharger une réussite d’étage : " + id)
		_check(state.profile == solved, "Réussite d’étage reprise exactement : " + id)
		if id != "security":
			_check(not investigation.conclusion(2).ok, "Bilan d’étage reste verrouillé avant les trois solutions : " + id)
	_check(state.profile.wallet.points == 280 and state.profile.progress.run_reward_points == 300 and state.profile.rewarded_missions.size() == 6, "Six missions donnent 300 points, moins l’achat de 20 déjà réalisé")
	var second_bilan: Dictionary = investigation.conclusion()
	_check(second_bilan.ok and second_bilan.data.chapter == 2 and _ids(second_bilan.data.missions) == saves.CHAPTER_TWO_IDS and second_bilan.data.message == investigation.mission("security").clue.text, "Bilan du deuxième chapitre ne reprend pas le message ni les missions du premier")
	_check(second_bilan.data.run_reward_points == 300 and second_bilan.data.wallet_points == 280, "Bilan expose le gain cumulé et le solde après achats séparément")
	_check(investigation.conclusion(1).ok and investigation.conclusion(1).data.missions.size() == 3, "Premier bilan reste consultable depuis le deuxième étage")
	var exit_document: Dictionary = state.profile.duplicate(true)
	exit_document.progress.checkpoint_id = "exit"
	_check(saves.validate_profile(exit_document).ok, "Sortie du deuxième chapitre permise après ses trois objectifs")
	completed_snapshot = state.profile.duplicate(true)
	_ok(investigation.enter_chapter(1), "Redescendre après les six objectifs")
	_check(state.profile.progress.completed_missions.size() == 6 and state.profile.wallet.points == 280, "Retour ne perd pas les missions de l’étage ni ses gains")
	_ok(investigation.enter_chapter(2), "Remonter après le bilan")

func _test_legacy_expansion() -> void:
	var created: Dictionary = profiles.create_profile("Ancien chapitre")
	if not _ok(created, "Profil isolé pour une sauvegarde 0.5.0"):
		return
	var legacy: Dictionary = chapter_one_snapshot.duplicate(true)
	legacy.id = created.data.id
	legacy.display_name = created.data.display_name
	legacy.avatar_image = "portrait_local.png"
	legacy.progress.checkpoint_id = "exit"
	for id in saves.CHAPTER_TWO_IDS:
		legacy.progress.observations.erase(id)
	var original := JSON.stringify(legacy, "\t")
	state.clear_profile()
	_check(_write_raw(_profile_path(legacy.id), original), "Ancienne sauvegarde à trois listes écrite dans la racine isolée")
	var read: Dictionary = saves.read_profile(legacy.id)
	if not _ok(read, "Ancienne sauvegarde pédagogique reconnue"):
		return
	_check(read.migration_required and FileAccess.get_file_as_string(_profile_path(legacy.id)) == original, "Lecture reconnaît l’enrichissement sans écrire sur l’original")
	var expected: Dictionary = legacy.duplicate(true)
	for id in saves.CHAPTER_TWO_IDS:
		expected.progress.observations[id] = []
	_check(read.data == expected, "Migration ajoute seulement trois listes : identité, avatar local, missions, indices, récompenses, points, achats et checkpoint restent fidèles")
	saves.simulate_write_failure = true
	_check(not profiles.select_profile(legacy.id).ok, "Échec de persistance de l’enrichissement signalé")
	saves.simulate_write_failure = false
	_check(state.profile.is_empty() and FileAccess.get_file_as_string(_profile_path(legacy.id)) == original, "Migration échouée laisse la sauvegarde originale et aucun profil partiellement chargé")
	_ok(profiles.select_profile(legacy.id), "Sélection enregistre l’enrichissement compatible")
	_check(state.profile == expected and FileAccess.get_file_as_string(_profile_path(legacy.id) + ".bak") == original, "Profil enrichi chargé et ancien document intégral conservé dans .bak")
	_check(not saves.read_profile(legacy.id).migration_required and not state.profile.progress.legacy_migration_notice, "L’enrichissement ne répète pas la migration ni l’avis du prototype")
	_check(investigation.can_use_elevator() and investigation.conclusion(1).ok, "Ancien premier chapitre terminé ouvre directement l’ascenseur et son bilan")
	_ok(investigation.enter_chapter(2), "Ancienne sauvegarde continue réellement au chapitre 2")
	_check(state.profile.progress.completed_missions == saves.CHAPTER_ONE_IDS and state.profile.wallet.points == 130 and state.profile.owned_items.has("game_test_1"), "Nouveau chapitre conserve fidèlement les acquis de l’ancienne sauvegarde")
	_reload(first_id, "Revenir au profil principal après la copie ancienne")

func _test_invalid_documents() -> void:
	var valid: Dictionary = completed_snapshot.duplicate(true)
	_check(saves.validate_profile(valid).ok, "Document complet à six missions valide")
	for mutation in ["room", "early_floor", "wrong_checkpoint", "early_elevator", "early_exit", "future_active", "missing_observation", "extra_observation", "foreign_choice", "missing_security", "reward_total"]:
		var invalid: Dictionary = valid.duplicate(true)
		match mutation:
			"room": invalid.progress.room_id = "room_03"
			"early_floor":
				invalid = _fresh_started(valid)
				invalid.progress.room_id = "room_02"
				invalid.progress.checkpoint_id = "elevator"
			"wrong_checkpoint": invalid.progress.checkpoint_id = "computer"
			"early_elevator":
				invalid = _fresh_started(valid)
				invalid.progress.checkpoint_id = "elevator"
			"early_exit":
				invalid = chapter_one_snapshot.duplicate(true)
				invalid.progress.room_id = "room_02"
				invalid.progress.checkpoint_id = "exit"
			"future_active":
				invalid = chapter_one_snapshot.duplicate(true)
				invalid.progress.active_mission = "network"
			"missing_observation": invalid.progress.observations.erase("network")
			"extra_observation": invalid.progress.observations.extra = []
			"foreign_choice": invalid.progress.observations.security = ["wifi", "compatibility", "unknown"]
			"missing_security": invalid.progress.observations.security = []
			"reward_total": invalid.progress.run_reward_points = 500
		_check(not saves.validate_profile(invalid).ok, "Progression d’étage incohérente refusée : " + mutation)
	var wrong_order: Dictionary = chapter_one_snapshot.duplicate(true)
	wrong_order.progress.room_id = "room_02"
	wrong_order.progress.checkpoint_id = "addressing"
	wrong_order.progress.completed_missions.append("addressing")
	wrong_order.rewarded_missions.append("addressing")
	wrong_order.progress.observations.addressing = ["workstation", "gateway", "allocation"]
	wrong_order.progress.clues.append("security_note")
	_check(not saves.validate_profile(wrong_order).ok, "Mission IPv4 ne peut être sauvegardée accomplie avant la liaison réseau")
	var unwarranted: Dictionary = investigation._finish_validated("security", {"diagnosis": "open_wifi"})
	_check(not unwarranted.ok, "Intermédiaire sans réparation n’autorise pas la récompense")
	_check(not rewards._complete_validated_mission("security", "invented_token").ok, "Jeton inventé ne contourne pas la validation des défis")

func _test_profiles_and_replay() -> void:
	var before: Dictionary = state.profile.duplicate(true)
	_ok(profiles.select_profile(second_id), "Sélectionner un autre profil")
	_check(investigation.current_chapter() == 1 and not investigation.can_use_elevator() and state.profile.wallet.points == 0 and state.profile.rewarded_missions.is_empty(), "Autre profil ne récupère ni étage ni récompenses ni accès à l’ascenseur")
	_ok(profiles.start_game(), "Nouvelle partie du second profil")
	_complete("lighting")
	_check(state.profile.wallet.points == 50 and saves.read_profile(first_id).data == before, "Récompense du second profil indépendante du premier")
	_ok(profiles.select_profile(first_id), "Reprendre le premier profil")
	_check(state.profile == before and investigation.current_chapter() == 2, "Changement de profil restaure le bon étage et ses données")
	_ok(profiles.start_game(), "Rejouer l’enquête entière")
	_check(investigation.current_chapter() == 1 and not investigation.can_use_elevator() and state.profile.progress.completed_missions.is_empty() and state.profile.progress.run_reward_points == 0, "Rejeu revient au premier chapitre, referme l’ascenseur et efface les six objectifs")
	_check(state.profile.wallet.points == 280 and state.profile.rewarded_missions.size() == 6 and state.profile.owned_items.has("game_test_1"), "Rejeu préserve tous les gains antérieurs et les achats")
	for id in saves.CHAPTER_ONE_IDS:
		_complete(id, 0)
	_ok(investigation.enter_chapter(2), "Rejeu déverrouille à nouveau le trajet vers l’étage")
	for id in saves.CHAPTER_TWO_IDS:
		_complete(id, 0)
	_check(state.profile.wallet.points == 280 and state.profile.progress.run_reward_points == 0 and investigation.conclusion(2).data.run_reward_points == 0, "Aucune des six missions ne rapporte une seconde récompense au rejeu")
	_ok(profiles.reset_progress(), "Réinitialiser la progression depuis les paramètres")
	_check(not state.profile.progress.started and investigation.current_chapter() == 1 and state.profile.progress.observations.size() == 6 and state.profile.progress.completed_missions.is_empty(), "Réinitialisation remet les six listes et les deux chapitres au début")
	_check(state.profile.wallet.points == 280 and state.profile.rewarded_missions.size() == 6 and state.profile.owned_items.has("game_test_1"), "Réinitialisation conserve les données économiques")
	_check(not investigation.enter_chapter(2).ok and not investigation.conclusion(2).ok, "Après réinitialisation, ascenseur et bilan redeviennent verrouillés")

func _complete(id: String, expected_reward: int = 50) -> void:
	_ok(investigation.begin_mission(id), "Défi ouvert : " + id)
	var definition: Dictionary = investigation.mission(id)
	for observation in definition.observations:
		_ok(investigation.observe(id, observation.id), "Observation : " + id + "/" + observation.id)
	if id == "computer":
		for check_id in ["video", "power"]:
			_ok(investigation.check_computer(check_id), "Vérification ordinateur : " + check_id)
	var result: Dictionary
	match id:
		"lighting": result = investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"])
		"lock": result = investigation.submit_lock("control_link", "reconnect_control")
		"computer": result = investigation.submit_computer(["video", "power"], "video_disconnected", "reconnect_video")
		_: result = investigation.submit_diagnostic(id, definition.solution.diagnosis, definition.solution.repair)
	_check(result.ok and result.data.reward == expected_reward, "Solution métier et récompense attendue : " + id + (" : " + str(result.error) if not result.ok else ""))

func _fresh_started(original: Dictionary) -> Dictionary:
	var document: Dictionary = original.duplicate(true)
	document.progress = saves.empty_investigation_progress()
	document.progress.started = true
	return document

func _ids(definitions: Array) -> Array:
	var ids: Array = []
	for definition in definitions:
		ids.append(definition.id)
	return ids

func _reload(id: String, label: String) -> void:
	state.clear_profile()
	_ok(profiles.select_profile(id), label)

func _profile_path(id: String) -> String:
	return test_root.path_join("profiles").path_join(id + ".json")

func _write_raw(path: String, content: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	file.flush()
	var success := file.get_error() == OK
	file.close()
	return success

func _ok(result: Dictionary, label: String) -> bool:
	var success := bool(result.get("ok", false))
	_check(success, label + (" : " + str(result.get("error", "")) if not success else ""))
	return success

func _check(condition: bool, label: String) -> void:
	assertions += 1
	if condition:
		print("  OK  ", label)
	else:
		failures.append(label)
		printerr("  ÉCHEC  ", label)

func _remove_tree(path: String) -> void:
	if test_root.is_empty() or not path.begins_with(test_root):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for filename in directory.get_files():
		directory.remove(filename)
	for child in directory.get_directories():
		_remove_tree(path.path_join(child))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _finish() -> void:
	state.clear_profile()
	if not test_root.is_empty():
		_remove_tree(test_root)
	print("\nRésultat chapitres services : %s assertions, %s échec(s)." % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
