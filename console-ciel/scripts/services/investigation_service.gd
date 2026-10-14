extends Node
## Observations, vérifications et solutions validées avant toute récompense.
## Le décor dérive ses états uniquement de progress.completed_missions.

signal mission_changed(mission_id: String, state: String)

var _authorizations: Dictionary = {}

func current_chapter() -> int:
	if AppState.profile.is_empty():
		return 1
	return 2 if AppState.profile.progress.room_id == "room_02" else 1

func chapter_missions(chapter: int = 0) -> Array:
	var selected := current_chapter() if chapter == 0 else chapter
	if selected not in [1, 2]:
		return []
	if RewardService.missions.is_empty() and not RewardService.load_rules().ok:
		return []
	var definitions: Array = []
	for definition in RewardService.missions:
		if int(definition.chapter) == selected:
			definitions.append(definition.duplicate(true))
	return definitions

func _chapter_complete(chapter: int) -> bool:
	if AppState.profile.is_empty() or not AppState.profile.progress.started:
		return false
	var definitions := chapter_missions(chapter)
	if definitions.size() != 3:
		return false
	for definition in definitions:
		if definition.id not in AppState.profile.progress.completed_missions:
			return false
	return true

func can_use_elevator() -> bool:
	return _chapter_complete(1)

func enter_chapter(chapter: int) -> Dictionary:
	if chapter not in [1, 2]:
		return SaveService._fail("Cet étage n’existe pas dans l’enquête.")
	if AppState.profile.is_empty():
		return SaveService._fail("Aucun profil actif.")
	var validation := SaveService.validate_profile(AppState.profile)
	if not validation.ok:
		return validation
	if validation.get("migration_required", false):
		return SaveService._fail("Sélectionnez ce profil pour enregistrer sa migration avant de changer d’étage.")
	if not can_use_elevator():
		return SaveService._fail("L’ascenseur se déverrouille après les trois missions du premier chapitre.")
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.room_id = "room_01" if chapter == 1 else "room_02"
	progress.checkpoint_id = "elevator"
	progress.active_mission = ""
	var saved := _save_progress(progress)
	if not saved.ok:
		return saved
	return SaveService._ok({"chapter": chapter, "room_id": progress.room_id, "checkpoint_id": progress.checkpoint_id})

func mission(id: String) -> Dictionary:
	if RewardService.missions.is_empty():
		if not RewardService.load_rules().ok:
			return {}
	for definition in RewardService.missions:
		if definition.id == id:
			return definition.duplicate(true)
	return {}

func mission_state(id: String) -> String:
	var definition := mission(id)
	if definition.is_empty() or AppState.profile.is_empty() or not AppState.profile.progress.started:
		return "locked"
	var progress: Dictionary = AppState.profile.progress
	if id in progress.completed_missions:
		return "completed"
	if progress.room_id != definition.room_id:
		return "locked"
	for prerequisite in definition.prerequisites:
		if prerequisite not in progress.completed_missions:
			return "locked"
	return "in_progress" if progress.active_mission == id else "available"

func _ready_for(id: String) -> Dictionary:
	var definition := mission(id)
	if definition.is_empty():
		return SaveService._fail("Mission inconnue.")
	if AppState.profile.is_empty():
		return SaveService._fail("Aucun profil actif.")
	var validation := SaveService.validate_profile(AppState.profile)
	if not validation.ok:
		return validation
	if validation.get("migration_required", false):
		return SaveService._fail("Sélectionnez ce profil pour enregistrer sa migration avant de jouer.")
	if not AppState.profile.progress.started:
		return SaveService._fail("Commencez une enquête depuis l'accueil.")
	if AppState.profile.progress.room_id != definition.room_id:
		return SaveService._fail("Cette mission se déroule au chapitre %s. Utilise l’ascenseur pour rejoindre cet étage." % definition.chapter)
	for prerequisite in definition.prerequisites:
		if prerequisite not in AppState.profile.progress.completed_missions:
			return SaveService._fail("Objectif verrouillé : termine d'abord « %s ». Observe les équipements accessibles dans le local." % mission(prerequisite).name)
	return SaveService._ok(definition)

func _save_progress(progress: Dictionary) -> Dictionary:
	var profile: Dictionary = AppState.profile.duplicate(true)
	profile.progress = progress.duplicate(true)
	var saved := SaveService.write_profile(profile)
	if not saved.ok:
		return saved
	AppState.commit_profile(saved.data)
	return saved

func begin_mission(id: String) -> Dictionary:
	var ready := _ready_for(id)
	if not ready.ok:
		return ready
	var state := mission_state(id)
	if state == "completed":
		return SaveService._ok({"mission_id": id, "state": state, "already_completed": true})
	if AppState.profile.progress.active_mission != id:
		var progress: Dictionary = AppState.profile.progress.duplicate(true)
		progress.active_mission = id
		var saved := _save_progress(progress)
		if not saved.ok:
			return saved
	mission_changed.emit(id, "in_progress")
	return SaveService._ok({"mission_id": id, "state": "in_progress", "already_completed": false})

func observe(id: String, observation_id: String) -> Dictionary:
	var ready := _ready_for(id)
	if not ready.ok:
		return ready
	var selected: Dictionary = {}
	for observation in ready.data.observations:
		if observation.id == observation_id:
			selected = observation
			break
	if selected.is_empty():
		return SaveService._fail("Observation inconnue pour cette mission.")
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	if observation_id not in progress.observations[id]:
		progress.observations[id].append(observation_id)
		if id not in progress.completed_missions:
			progress.active_mission = id
		var saved := _save_progress(progress)
		if not saved.ok:
			return saved
		mission_changed.emit(id, mission_state(id))
	return SaveService._ok({"mission_id": id, "observation_id": observation_id, "text": selected.text})

func check_computer(check_id: String) -> Dictionary:
	var ready := _ready_for("computer")
	if not ready.ok:
		return ready
	var observations: Array = AppState.profile.progress.observations.computer
	if observations.size() != ready.data.observations.size():
		return SaveService._fail("Observe d'abord l'unité centrale, l'écran et le message « Aucun signal », puis choisis les vérifications.")
	var selected: Dictionary = {}
	for check in ready.data.checks:
		if check.id == check_id:
			selected = check
			break
	if selected.is_empty():
		return SaveService._fail("Vérification inconnue.")
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	if check_id not in progress.checks.computer:
		progress.checks.computer.append(check_id)
		if "computer" not in progress.completed_missions:
			progress.active_mission = "computer"
		var saved := _save_progress(progress)
		if not saved.ok:
			return saved
		mission_changed.emit("computer", mission_state("computer"))
	return SaveService._ok({"check_id": check_id, "text": selected.text})

func _feedback(choices: Array, chosen: String) -> String:
	for choice in choices:
		if choice.id == chosen:
			return choice.feedback
	return "Ce choix n'existe pas dans la simulation. Sélectionne une des propositions."

func _observed_all(id: String, definition: Dictionary) -> bool:
	return AppState.profile.progress.observations[id].size() == definition.observations.size()

func submit_lighting(connections: Array) -> Dictionary:
	return _finish_validated("lighting", {"connections": connections})

func _validate_lighting(connections: Array) -> Dictionary:
	var ready := _ready_for("lighting")
	if not ready.ok:
		return ready
	var definition: Dictionary = ready.data
	if not SaveService._valid_id_list(connections, SaveService._option_ids(definition, "connections")):
		return SaveService._fail("Une connexion est inconnue ou présente plusieurs fois. Choisis une seule fois chaque liaison proposée.")
	if "source_lamp" in connections:
		return SaveService._fail("La liaison directe source → lampe contourne l'interrupteur. Retire-la : l'interrupteur doit commander la lampe dans la boucle.")
	if "switch_return" in connections:
		return SaveService._fail("Le retour directement depuis l'interrupteur contourne la lampe. Retire cette liaison et fais passer la boucle par la lampe.")
	if "source_switch" not in connections:
		return SaveService._fail("La source n'est pas reliée à l'interrupteur : la boucle reste ouverte. Ajoute cette liaison.")
	if "switch_lamp" not in connections:
		return SaveService._fail("L'interrupteur n'est pas relié à la lampe : la boucle reste ouverte. Ajoute cette liaison.")
	if "lamp_return" not in connections:
		return SaveService._fail("Il manque le retour de la lampe vers la source. Sans retour, aucune boucle fermée ne permet la circulation.")
	if connections.size() != definition.solution.connections.size():
		return SaveService._fail("Choisis uniquement les trois liaisons de la boucle source → interrupteur → lampe → retour.")
	return SaveService._ok()

func submit_lock(diagnosis: String, repair: String) -> Dictionary:
	return _finish_validated("lock", {"diagnosis": diagnosis, "repair": repair})

func _validate_lock(diagnosis: String, repair: String) -> Dictionary:
	var ready := _ready_for("lock")
	if not ready.ok:
		return ready
	var definition: Dictionary = ready.data
	if not _observed_all("lock", definition):
		return SaveService._fail("Consulte les quatre observations : badge, alimentation, actionneur et liaison de commande. Elles justifient le diagnostic.")
	if diagnosis != definition.solution.diagnosis:
		return SaveService._fail(_feedback(definition.diagnoses, diagnosis))
	if repair != definition.solution.repair:
		return SaveService._fail(_feedback(definition.repairs, repair))
	return SaveService._ok()

func submit_diagnostic(id: String, diagnosis: String, repair: String) -> Dictionary:
	if id not in SaveService.CHAPTER_TWO_IDS:
		return SaveService._fail("Ce défi ne fait pas partie des diagnostics de l’étage réseau.")
	return _finish_validated(id, {"diagnosis": diagnosis, "repair": repair})

func _validate_diagnostic(id: String, diagnosis: String, repair: String) -> Dictionary:
	var ready := _ready_for(id)
	if not ready.ok:
		return ready
	var definition: Dictionary = ready.data
	if not _observed_all(id, definition):
		return SaveService._fail("Consulte les trois observations de « %s » avant de choisir un diagnostic et une réparation. Elles permettent de justifier ta réponse." % definition.name)
	if diagnosis != definition.solution.diagnosis:
		return SaveService._fail(_feedback(definition.diagnoses, diagnosis))
	if repair != definition.solution.repair:
		return SaveService._fail(_feedback(definition.repairs, repair))
	return SaveService._ok()

func submit_computer(checks: Array, cause: String, correction: String) -> Dictionary:
	return _finish_validated("computer", {"checks": checks, "cause": cause, "correction": correction})

func _validate_computer(checks: Array, cause: String, correction: String) -> Dictionary:
	var ready := _ready_for("computer")
	if not ready.ok:
		return ready
	var definition: Dictionary = ready.data
	if not _observed_all("computer", definition):
		return SaveService._fail("Observe l'unité centrale, l'écran et le message avant de conclure.")
	if not SaveService._valid_id_list(checks, SaveService._option_ids(definition, "checks")):
		return SaveService._fail("Une vérification choisie est inconnue ou dupliquée.")
	for check in definition.solution.checks:
		if check not in checks or check not in AppState.profile.progress.checks.computer:
			return SaveService._fail("Vérifie réellement les alimentations et la liaison vidéo avec les boutons de vérification avant de conclure.")
	if cause != definition.solution.cause:
		return SaveService._fail(_feedback(definition.causes, cause))
	if correction != definition.solution.correction:
		return SaveService._fail(_feedback(definition.corrections, correction))
	return SaveService._ok()

func _finish_validated(id: String, evidence: Dictionary) -> Dictionary:
	# Même cet intermédiaire revalide une solution concrète ; un appel direct
	# avec un état fabriqué ne peut pas attribuer une réussite.
	var checked: Dictionary
	match id:
		"lighting":
			if not evidence.get("connections") is Array:
				return SaveService._fail("Les connexions de la solution sont absentes.")
			checked = _validate_lighting(evidence.connections)
		"lock":
			if not evidence.get("diagnosis") is String or not evidence.get("repair") is String:
				return SaveService._fail("Le diagnostic et la réparation sont absents.")
			checked = _validate_lock(evidence.diagnosis, evidence.repair)
		"network", "addressing", "security":
			if not evidence.get("diagnosis") is String or not evidence.get("repair") is String:
				return SaveService._fail("Le diagnostic et la réparation sont absents.")
			checked = _validate_diagnostic(id, evidence.diagnosis, evidence.repair)
		"computer":
			if not evidence.get("checks") is Array or not evidence.get("cause") is String or not evidence.get("correction") is String:
				return SaveService._fail("Les vérifications, la cause et la correction sont absentes.")
			checked = _validate_computer(evidence.checks, evidence.cause, evidence.correction)
		_:
			return SaveService._fail("Mission inconnue.")
	if not checked.ok:
		return checked
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	var definition := mission(id)
	if id in AppState.profile.progress.completed_missions:
		return SaveService._ok({"mission_id": id, "reward": 0, "already_completed": true, "explanation": definition.success_explanation, "clue": definition.clue.duplicate(true)})
	# Autorisation éphémère créée uniquement après les validations ci-dessus.
	# La récompense consomme cette preuve, puis écrit le document complet une seule fois.
	var token := Crypto.new().generate_random_bytes(16).hex_encode()
	_authorizations[token] = {"mission_id": id, "profile_id": AppState.profile.id, "profile_snapshot": AppState.profile.duplicate(true), "progress": progress.duplicate(true)}
	var result := RewardService._complete_validated_mission(id, token)
	_authorizations.erase(token)
	if result.ok:
		result.data["explanation"] = definition.success_explanation
		result.data["clue"] = definition.clue.duplicate(true)
		mission_changed.emit(id, "completed")
	return result

func _take_authorization(id: String, token: String) -> Dictionary:
	if token.is_empty() or not _authorizations.has(token) or _authorizations[token].mission_id != id:
		return SaveService._fail("Validation métier absente : résous le défi avant de demander sa récompense.")
	var authorization: Dictionary = _authorizations[token].duplicate(true)
	_authorizations.erase(token)
	return SaveService._ok(authorization)

func acknowledge_migration() -> Dictionary:
	if AppState.profile.is_empty():
		return SaveService._fail("Aucun profil actif.")
	if not AppState.profile.progress.legacy_migration_notice:
		return SaveService._ok()
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.legacy_migration_notice = false
	return _save_progress(progress)

func conclusion(chapter: int = 0) -> Dictionary:
	var selected := current_chapter() if chapter == 0 else chapter
	if selected not in [1, 2]:
		return SaveService._fail("Ce chapitre n’existe pas dans l’enquête.")
	if AppState.profile.is_empty():
		return SaveService._fail("Aucun profil actif.")
	var validation := SaveService.validate_profile(AppState.profile)
	if not validation.ok:
		return validation
	if validation.get("migration_required", false):
		return SaveService._fail("Sélectionnez ce profil pour enregistrer sa migration avant de lire le bilan.")
	if not _chapter_complete(selected):
		return SaveService._fail("Termine les trois objectifs du chapitre %s pour lire son bilan." % selected)
	var definitions := chapter_missions(selected)
	return SaveService._ok({"chapter": selected, "message": definitions.back().clue.text, "run_reward_points": int(AppState.profile.progress.run_reward_points), "wallet_points": int(AppState.profile.wallet.points), "missions": definitions})
