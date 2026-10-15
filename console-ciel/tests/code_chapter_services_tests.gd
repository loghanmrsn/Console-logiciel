extends SceneTree
## Chapter three uses real services, saved documents and isolated user data.
## No Python, HTML or Markdown entered by a player is executed.

const FIRST := ["lighting", "lock", "computer"]
const SECOND := ["network", "addressing", "security"]
const THIRD := ["python", "html", "markdown"]
const ANSWERS := {"python": "print", "html": "h1", "markdown": "hash"}

var checks := 0
var failures: Array[String] = []
var test_root := ""
var saves
var profiles
var shop
var rewards
var investigation
var state
var profile_id := ""
var first_snapshot: Dictionary = {}
var second_snapshot: Dictionary = {}
var final_snapshot: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	shop = root.get_node("ShopService")
	rewards = root.get_node("RewardService")
	investigation = root.get_node("InvestigationService")
	state = root.get_node("AppState")
	test_root = "user://tests/code_chapter_services_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	saves.root_path = test_root
	state.clear_profile()
	print("CODE_CHAPTER_SERVICES_DATA : ", ProjectSettings.globalize_path(test_root))
	if not _ok(shop.load_catalog(), "Catalogue disponible") or not _ok(rewards.load_rules(), "Définitions disponibles"):
		_finish()
		return
	var created: Dictionary = profiles.create_profile("Atelier code")
	if not _ok(created, "Profil isolé créé"):
		_finish()
		return
	profile_id = str(created.data.id)
	_test_rules_and_gates()
	_test_previous_chapters()
	_test_third_chapter()
	_test_migrations()
	_test_invalid_documents()
	_test_replay_and_profile_isolation()
	_finish()


func _test_rules_and_gates() -> void:
	_check(rewards.missions.size() == 9 and saves.MISSION_IDS.size() == 9, "Neuf missions livrées sans dupliquer les identifiants")
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/game_rules.json"))
	var total := 0
	for definition in rewards.missions:
		total += int(definition.reward)
	_check(total == 450 and int(rules.mission_reward_max) == 450, "Plafond de neuf récompenses de 50 : 450 points")
	_check(not investigation.can_enter_chapter(1) and not investigation.can_enter_chapter(3), "Aucun étage jouable avant le démarrage")
	_check(not investigation.enter_chapter(3).ok and not investigation.enter_chapter(4).ok, "Pas de trajet avant enquête ou vers un étage inconnu")
	_ok(profiles.start_game(), "Démarrage de l’enquête")
	_check(investigation.can_enter_chapter(1) and not investigation.can_enter_chapter(2) and not investigation.can_enter_chapter(3), "Un profil neuf accède uniquement au premier chapitre")
	_check(_ids(investigation.chapter_missions(3)) == THIRD, "Chapitre code ordonné : Python, HTML, Markdown")
	for id in THIRD:
		var definition: Dictionary = investigation.mission(id)
		_check(definition.room_id == "room_03" and int(definition.chapter) == 3 and int(definition.reward) == 50, "Défi code affecté au bon étage : " + id)
		_check(definition.observations.is_empty() and definition.checks.is_empty(), "L’exercice simple de code ne demande aucune observation fictive : " + id)
		_check(definition.solution.answer == ANSWERS[id], "Solution pédagogique attendue : " + id)
		_check(not investigation.begin_mission(id).ok and not investigation.submit_code(id, ANSWERS[id]).ok, "Une bonne réponse ne contourne pas les étages : " + id)
		_check(not rewards.complete_mission(id).ok and not rewards._complete_validated_mission(id, "invented_token").ok, "Les raccourcis de récompense sont refusés : " + id)
	for mutation in ["room", "chapter", "order", "answer", "unknown_choice", "duplicate_choice", "total"]:
		var invalid: Dictionary = rules.duplicate(true)
		match mutation:
			"room": invalid.missions[6].room_id = "room_02"
			"chapter": invalid.missions[6].chapter = 2
			"order": invalid.missions[7].prerequisites = ["security"]
			"answer": invalid.missions[7].solution.answer = "p"
			"unknown_choice": invalid.missions[8].code.choices[0].id = "script"
			"duplicate_choice": invalid.missions[6].code.choices[1].id = invalid.missions[6].code.choices[0].id
			"total": invalid.mission_reward_max = 300
		_check(not saves.validate_rules(invalid).ok, "Définitions code incohérentes refusées : " + mutation)
	for wrong_type in [null, true, 12, [], {}]:
		for field in ["template", "prompt", "choices", "answer"]:
			var invalid: Dictionary = rules.duplicate(true)
			if field == "answer":
				invalid.missions[6].solution.answer = wrong_type
			else:
				invalid.missions[6].code[field] = wrong_type
			_check(not saves.validate_rules(invalid).ok, "Champ code mal typé refusé sans erreur moteur : " + field + "/" + str(typeof(wrong_type)))
	for wrong_choice in [null, true, 12, [], {}, {"id": "print", "label": "print", "feedback": null}]:
		var invalid: Dictionary = rules.duplicate(true)
		invalid.missions[6].code.choices[0] = wrong_choice
		_check(not saves.validate_rules(invalid).ok, "Choix code mal typé refusé sans erreur moteur")


func _test_previous_chapters() -> void:
	for id in FIRST:
		_complete(id)
	_check(investigation.can_enter_chapter(2) and not investigation.can_enter_chapter(3), "Chapitre 1 terminé ouvre le réseau, mais pas le code")
	_check(not investigation.enter_chapter(3).ok, "Ascenseur refuse de sauter le chapitre réseau")
	_ok(shop.purchase("avatar_orbit"), "Achat réel avant la migration et les nouveaux exercices")
	first_snapshot = state.profile.duplicate(true)
	_ok(investigation.enter_chapter(2), "Trajet vers le réseau")
	for id in SECOND:
		if id != "security":
			_check(not investigation.can_enter_chapter(3) and not investigation.enter_chapter(3).ok, "Chapitre code verrouillé tant que le réseau n’est pas fini : " + id)
		_complete(id)
	_check(state.profile.wallet.points == 280 and state.profile.progress.run_reward_points == 300, "Six anciennes missions et l’achat conservent leurs montants")
	_check(investigation.can_enter_chapter(3), "Le troisième étage se débloque après les six réussites")
	second_snapshot = state.profile.duplicate(true)


func _test_third_chapter() -> void:
	var before: Dictionary = state.profile.duplicate(true)
	var disk := _disk(profile_id)
	saves.simulate_write_failure = true
	_check(not investigation.enter_chapter(3).ok, "Échec d’écriture de l’ascenseur annoncé")
	saves.simulate_write_failure = false
	_check(state.profile == before and _disk(profile_id) == disk, "Trajet échoué ne change aucun état mémoire ni disque")
	var entered: Dictionary = investigation.enter_chapter(3)
	_check(entered.ok and entered.data.room_id == "room_03" and entered.data.chapter == 3 and entered.data.checkpoint_id == "elevator", "Ascenseur arrive au chapitre 3 près de ses portes")
	_check(state.profile.wallet == before.wallet and state.profile.owned_items == before.owned_items and state.profile.rewarded_missions == before.rewarded_missions, "Le trajet conserve l’économie et les achats")
	_reload(profile_id)
	_check(investigation.current_chapter() == 3 and state.profile.progress.checkpoint_id == "elevator", "Rechargement conserve la salle code et le checkpoint")
	_check(not investigation.submit_diagnostic("python", "print", "print").ok and not investigation.submit_code("network", "print").ok, "Les API réseau et code ne sont pas interchangeables")
	for id in THIRD:
		var definition: Dictionary = investigation.mission(id)
		for later in THIRD.slice(THIRD.find(id) + 1):
			_check(not investigation.begin_mission(later).ok and not investigation.submit_code(later, ANSWERS[later]).ok, "Une solution correcte ne saute pas le prérequis : " + later)
		_ok(investigation.begin_mission(id), "Ouverture réelle du défi : " + id)
		var opened: Dictionary = state.profile.duplicate(true)
		_reload(profile_id)
		_check(state.profile == opened and state.profile.progress.active_mission == id, "Mission code active reprise sans perte : " + id)
		for answer in ["", " ", "unknown", "<script>alert(1)</script>", "print('forged')"]:
			_check(not investigation.submit_code(id, answer).ok, "Réponse vide ou extérieure aux choix refusée : " + id + "/" + answer)
		for choice in definition.code.choices:
			if choice.id != ANSWERS[id]:
				var wrong: Dictionary = investigation.submit_code(id, choice.id)
				_check(not wrong.ok and wrong.error == choice.feedback, "Mauvaise réponse expliquée sans exécuter de code : " + id + "/" + choice.id)
		_check(not investigation._finish_validated(id, {}).ok and not investigation._finish_validated(id, {"answer": 1}).ok and not investigation._finish_validated(id, {"answer": "unknown"}).ok, "Preuves absentes, typées incorrectement ou fabriquées refusées : " + id)
		_test_authorization_attacks(id)
		_check(not rewards._complete_validated_mission(id, "").ok and not rewards._complete_validated_mission(id, "forged").ok, "Jeton vide ou inventé ne peut acheter une réussite : " + id)
		_check(state.profile == opened, "Les refus ne modifient ni points, ni mission, ni indices : " + id)
		var saved_disk := _disk(profile_id)
		saves.simulate_write_failure = true
		_check(not investigation.submit_code(id, ANSWERS[id]).ok, "Échec d’écriture de réussite annoncé : " + id)
		saves.simulate_write_failure = false
		_check(state.profile == opened and _disk(profile_id) == saved_disk and investigation._authorizations.is_empty(), "Échec atomique sans récompense ni jeton résiduel : " + id)
		var success: Dictionary = investigation.submit_code(id, ANSWERS[id])
		_check(success.ok and success.data.reward == 50 and success.data.explanation == definition.success_explanation, "Réponse correcte rapporte exactement 50 et son explication : " + id)
		_check(state.profile.wallet.points == opened.wallet.points + 50 and state.profile.progress.run_reward_points == opened.progress.run_reward_points + 50, "Portefeuille et gain de partie incrémentés ensemble : " + id)
		_check(state.profile.progress.completed_missions.has(id) and state.profile.rewarded_missions.has(id) and state.profile.progress.clues.has(definition.clue.id), "Réussite, jeton durable et indice sauvegardés ensemble : " + id)
		_check(state.profile.progress.checkpoint_id == id and state.profile.progress.active_mission.is_empty(), "Checkpoint code actualisé et mission active fermée : " + id)
		var solved: Dictionary = state.profile.duplicate(true)
		for repeat in range(2):
			var repeated: Dictionary = investigation.submit_code(id, ANSWERS[id])
			_check(repeated.ok and repeated.data.reward == 0 and state.profile == solved, "Validation répétée sans second gain : " + id)
		_reload(profile_id)
		_check(state.profile == solved and saves.read_profile(profile_id).data == solved, "Réussite et checkpoint persistent exactement : " + id)
		if id != "markdown":
			_check(not investigation.conclusion(3).ok, "Bilan code indisponible avant les trois réponses")
	_check(state.profile.wallet.points == 430 and state.profile.progress.run_reward_points == 450 and state.profile.rewarded_missions.size() == 9, "Neuf missions donnent 450 points moins l’achat de 20")
	var bilan: Dictionary = investigation.conclusion()
	_check(bilan.ok and bilan.data.chapter == 3 and _ids(bilan.data.missions) == THIRD and bilan.data.message == investigation.mission("markdown").clue.text, "Bilan local comprend uniquement les trois exercices code")
	_check(bilan.data.wallet_points == 430 and bilan.data.run_reward_points == 450 and investigation.conclusion(1).ok and investigation.conclusion(2).ok, "Les trois bilans gardent le solde et les gains distincts")
	final_snapshot = state.profile.duplicate(true)
	for chapter in [1, 2, 3]:
		_ok(investigation.enter_chapter(chapter), "Retour libre vers l’étage débloqué : " + str(chapter))
		_check(state.profile.progress.active_mission.is_empty() and state.profile.progress.checkpoint_id == "elevator" and state.profile.progress.completed_missions.size() == 9, "Un retour conserve les neuf réussites et restaure l’ascenseur")
		_reload(profile_id)
		_check(investigation.current_chapter() == chapter and state.profile.wallet.points == 430, "Retour et solde fidèles après rechargement")


func _test_authorization_attacks(id: String) -> void:
	var before: Dictionary = state.profile.duplicate(true)
	var disk := _disk(profile_id)
	for mutation in ["missing_evidence", "wrong_answer", "foreign_progress", "stale_snapshot"]:
		var token: String = "test_code_proof_" + id + "_" + mutation
		var authorization := {
			"mission_id": id,
			"profile_id": state.profile.id,
			"profile_snapshot": before.duplicate(true),
			"progress": before.progress.duplicate(true),
			"evidence": {"answer": ANSWERS[id]}
		}
		match mutation:
			"missing_evidence": authorization.erase("evidence")
			"wrong_answer": authorization.evidence.answer = "unknown"
			"foreign_progress": authorization.progress.run_reward_points += 50
			"stale_snapshot": authorization.profile_snapshot.wallet.points += 50
		investigation._authorizations[token] = authorization
		_check(not rewards._complete_validated_mission(id, token).ok, "La récompense revalide même un jeton au bon format : " + id + "/" + mutation)
		_check(not investigation._authorizations.has(token) and not rewards._complete_validated_mission(id, token).ok, "Le jeton refusé est consommé et ne peut être rejoué : " + mutation)
		_check(state.profile == before and _disk(profile_id) == disk, "Une preuve forgée ne modifie aucun document : " + mutation)


func _test_migrations() -> void:
	for old_count in [3, 6]:
		var created: Dictionary = profiles.create_profile("Ancien " + str(old_count))
		if not _ok(created, "Profil de migration isolé"):
			continue
		var legacy: Dictionary = (first_snapshot if old_count == 3 else second_snapshot).duplicate(true)
		legacy.id = created.data.id
		legacy.display_name = created.data.display_name
		legacy.avatar_image = "portrait_local.png"
		for id in THIRD + (SECOND if old_count == 3 else []):
			legacy.progress.observations.erase(id)
		var original := JSON.stringify(legacy, "\t")
		state.clear_profile()
		_check(_write_raw(_path(legacy.id), original), "Document ancien écrit sans validation moderne")
		var loaded: Dictionary = saves.read_profile(legacy.id)
		if not _ok(loaded, "Document ancien reconnu : " + str(old_count)):
			continue
		var expected: Dictionary = legacy.duplicate(true)
		for id in THIRD + (SECOND if old_count == 3 else []):
			expected.progress.observations[id] = []
		_check(loaded.migration_required and loaded.data == expected and _disk(legacy.id) == original, "Lecture enrichit les observations, sans écrire ni changer identité, avatar, points, achats ou progression")
		saves.simulate_write_failure = true
		_check(not profiles.select_profile(legacy.id).ok, "Échec de migration signalé")
		saves.simulate_write_failure = false
		_check(state.profile.is_empty() and _disk(legacy.id) == original, "Migration échouée laisse l’ancien fichier intact et aucun profil partiel")
		_ok(profiles.select_profile(legacy.id), "Migration enregistrée à la sélection")
		_check(state.profile == expected and FileAccess.get_file_as_string(_path(legacy.id) + ".bak") == original, "Migration conserve le document original dans .bak")
		_check(not saves.read_profile(legacy.id).migration_required and investigation.can_enter_chapter(3) == (old_count == 6), "Migration unique et accès code conforme aux anciens objectifs")
	_reload(profile_id)


func _test_invalid_documents() -> void:
	_check(saves.validate_profile(final_snapshot).ok, "Document final à neuf missions valide")
	for mutation in ["room", "early_room", "wrong_checkpoint", "foreign_observation", "missing_observation", "future_active", "missing_html", "reward_overflow"]:
		var invalid: Dictionary = final_snapshot.duplicate(true)
		match mutation:
			"room": invalid.progress.room_id = "room_04"
			"early_room":
				invalid = first_snapshot.duplicate(true)
				invalid.progress.room_id = "room_03"
				invalid.progress.checkpoint_id = "elevator"
			"wrong_checkpoint": invalid.progress.checkpoint_id = "network"
			"foreign_observation": invalid.progress.observations.python = ["exec"]
			"missing_observation": invalid.progress.observations.erase("python")
			"future_active":
				invalid = second_snapshot.duplicate(true)
				invalid.progress.active_mission = "python"
			"missing_html": invalid.progress.completed_missions.erase("html")
			"reward_overflow": invalid.progress.run_reward_points = 451
		_check(not saves.validate_profile(invalid).ok, "Document chapitre code incohérent refusé : " + mutation)


func _test_replay_and_profile_isolation() -> void:
	var before: Dictionary = state.profile.duplicate(true)
	var other: Dictionary = profiles.create_profile("Autre code")
	if _ok(other, "Second joueur créé"):
		_check(state.profile.wallet.points == 0 and not investigation.can_enter_chapter(3) and state.profile.rewarded_missions.is_empty(), "Les acquis du code ne passent pas au second profil")
		_check(saves.read_profile(profile_id).data == before, "Créer un second profil préserve l’original")
	_reload(profile_id)
	_ok(profiles.start_game(), "Recommencer les trois chapitres")
	_check(investigation.current_chapter() == 1 and not investigation.can_enter_chapter(3) and state.profile.progress.completed_missions.is_empty(), "Rejeu revient au début et referme le chapitre 3")
	_check(state.profile.wallet.points == 430 and state.profile.rewarded_missions.size() == 9 and state.profile.owned_items.has("avatar_orbit"), "Rejeu conserve monnaie, neuf récompenses et achats")
	for chapter in [1, 2, 3]:
		if chapter > 1:
			_ok(investigation.enter_chapter(chapter), "Accès au chapitre rejoué : " + str(chapter))
		for id in [FIRST, SECOND, THIRD][chapter - 1]:
			_complete(id, 0)
	_check(state.profile.wallet.points == 430 and state.profile.progress.run_reward_points == 0 and state.profile.progress.completed_missions.size() == 9, "Rejouer les neuf solutions ne produit aucun gain supplémentaire")
	_ok(profiles.reset_progress(), "Réinitialisation de progression")
	_check(not state.profile.progress.started and state.profile.progress.observations.size() == 9 and state.profile.rewarded_missions.size() == 9 and state.profile.wallet.points == 430, "Réinitialisation restaure neuf listes sans retirer les acquis économiques")


func _complete(id: String, expected_reward: int = 50) -> void:
	if not _ok(investigation.begin_mission(id), "Ouvrir " + id):
		return
	var definition: Dictionary = investigation.mission(id)
	for observation in definition.observations:
		_ok(investigation.observe(id, observation.id), "Consulter " + id + "/" + observation.id)
	var result: Dictionary
	match id:
		"lighting": result = investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"])
		"lock": result = investigation.submit_lock("control_link", "reconnect_control")
		"computer":
			for check_id in ["video", "power"]:
				_ok(investigation.check_computer(check_id), "Vérifier ordinateur : " + check_id)
			result = investigation.submit_computer(["video", "power"], "video_disconnected", "reconnect_video")
		"python", "html", "markdown": result = investigation.submit_code(id, ANSWERS[id])
		_: result = investigation.submit_diagnostic(id, definition.solution.diagnosis, definition.solution.repair)
	_check(result.ok and result.data.reward == expected_reward, "Solution et récompense réelles : " + id + (" : " + str(result.error) if not result.ok else ""))


func _ids(definitions: Array) -> Array:
	var ids: Array = []
	for definition in definitions:
		ids.append(definition.id)
	return ids


func _reload(id: String) -> void:
	state.clear_profile()
	_ok(profiles.select_profile(id), "Recharger le profil")


func _path(id: String) -> String:
	return test_root.path_join("profiles").path_join(id + ".json")


func _disk(id: String) -> String:
	return FileAccess.get_file_as_string(_path(id))


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
	checks += 1
	if not condition:
		failures.append(label)
		printerr("CODE_CHAPTER_SERVICES_FAIL : " + label)


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
	saves.simulate_write_failure = false
	state.clear_profile()
	_remove_tree(test_root)
	print("CODE_CHAPTER_SERVICES : %d assertions, %d échec(s)." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
