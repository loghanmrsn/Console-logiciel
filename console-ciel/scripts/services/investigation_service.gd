extends Node
## Observations, vérifications et solutions validées avant toute récompense.
## Le décor dérive ses états uniquement de progress.completed_missions.

signal mission_changed(mission_id: String, state: String)

var _authorizations: Dictionary = {}
const CODE_TEXT_LIMIT := 64

func current_chapter() -> int:
	if AppState.profile.is_empty():
		return 1
	return {"room_01": 1, "room_02": 2, "room_03": 3, "room_04": 4, "room_05": 5, "maze_05": 5, "courtyard": 0, "building_02": 0}.get(AppState.profile.progress.room_id, 1)

func chapter_missions(chapter: int = 0) -> Array:
	var selected := current_chapter() if chapter == 0 else chapter
	if selected not in [1, 2, 3, 4, 5]:
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
	if definitions.size() != (1 if chapter == 5 else 3):
		return false
	for definition in definitions:
		if definition.id not in AppState.profile.progress.completed_missions:
			return false
	return true

func can_use_elevator() -> bool:
	return _chapter_complete(1)

func can_enter_chapter(chapter: int) -> bool:
	if chapter not in [1, 2, 3, 4, 5] or AppState.profile.is_empty() or not AppState.profile.progress.started:
		return false
	for previous in range(1, chapter):
		if not _chapter_complete(previous):
			return false
	return true

func enter_chapter(chapter: int) -> Dictionary:
	if chapter not in [1, 2, 3, 4, 5]:
		return SaveService._fail("Cet étage n’existe pas dans l’enquête.")
	if AppState.profile.is_empty():
		return SaveService._fail("Aucun profil actif.")
	var validation := SaveService.validate_profile(AppState.profile)
	if not validation.ok:
		return validation
	if validation.get("migration_required", false):
		return SaveService._fail("Sélectionnez ce profil pour enregistrer sa migration avant de changer d’étage.")
	if current_chapter() == 0:
		return SaveService._fail("Revenez au premier bâtiment par sa porte pour utiliser l’ascenseur.")
	if not can_use_elevator():
		return SaveService._fail("L’ascenseur se déverrouille après les trois missions du premier chapitre.")
	if not can_enter_chapter(chapter):
		return SaveService._fail("Termine les trois missions du chapitre précédent pour monter à cet étage.")
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.room_id = "room_%02d" % chapter
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
	if progress.room_id != definition.room_id and not (id == "maze" and progress.room_id == "room_05"):
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
	if id == "maze": return SaveService._fail("La session du terminal nécessite une authentification.")
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
	if id not in SaveService.CHAPTER_TWO_IDS + SaveService.CHAPTER_FOUR_IDS:
		return SaveService._fail("Ce défi ne fait pas partie des diagnostics de l’étage réseau.")
	return _finish_validated(id, {"diagnosis": diagnosis, "repair": repair})

func submit_code(id: String, answer: String) -> Dictionary:
	if id not in SaveService.CHAPTER_THREE_IDS:
		return SaveService._fail("Ce défi ne fait pas partie de l’atelier code.")
	return _finish_validated(id, {"answer": answer})

func submit_code_text(id: String, text: String) -> Dictionary:
	if id not in SaveService.CHAPTER_THREE_IDS:
		return SaveService._fail("Ce défi ne fait pas partie de l’atelier code.")
	var ready := _ready_for(id)
	if not ready.ok:
		return ready
	if text.length() > CODE_TEXT_LIMIT:
		return SaveService._fail("La réponse doit rester courte : 64 caractères au maximum.")
	var value := text.strip_edges()
	if value.is_empty():
		return SaveService._fail("Saisis le mot ou le symbole manquant avant de valider.")
	var definition: Dictionary = ready.data
	var label := ""
	for choice in definition.code.choices:
		if choice.id == definition.solution.answer:
			label = choice.label
	var example: String = str(definition.code.template).replace("____", label)
	var normalized := value
	if id == "html":
		normalized = value.replace("<H1>", "<h1>").replace("</H1>", "</h1>")
		if value.to_lower() == "h1": normalized = "h1"
	var accepted: Array[String] = [label, example]
	if id == "python": accepted.append(example.replace('"', "'"))
	if id == "html": accepted.append("<h1>")
	if normalized in accepted:
		# Comparaison de texte uniquement : les règles existantes revalident la
		# réponse canonique avant l’écriture de la mission et de sa récompense.
		return submit_code(id, definition.solution.answer)
	for choice in definition.code.choices:
		if value == choice.label:
			return SaveService._fail(choice.feedback)
	return SaveService._fail("Vérifie la syntaxe : tape le mot ou symbole manquant, ou recopie la ligne complète de l’exemple.")

func _validate_code(id: String, answer: String) -> Dictionary:
	var ready := _ready_for(id)
	if not ready.ok:
		return ready
	var definition: Dictionary = ready.data
	if answer != definition.solution.answer:
		return SaveService._fail(_feedback(definition.code.choices, answer))
	# Les choix sont comparés à une solution pédagogique locale.
	# Aucun texte saisi n’est exécuté comme programme ou interprété comme balisage.
	return SaveService._ok()

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

func _validate_solution(id: String, evidence: Dictionary) -> Dictionary:
	# Contrôle commun, effectué à la soumission puis lors de la récompense.
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
		"network", "addressing", "security", "firewall", "ip_conflict", "subnet_mask":
			if not evidence.get("diagnosis") is String or not evidence.get("repair") is String:
				return SaveService._fail("Le diagnostic et la réparation sont absents.")
			checked = _validate_diagnostic(id, evidence.diagnosis, evidence.repair)
		"computer":
			if not evidence.get("checks") is Array or not evidence.get("cause") is String or not evidence.get("correction") is String:
				return SaveService._fail("Les vérifications, la cause et la correction sont absentes.")
			checked = _validate_computer(evidence.checks, evidence.cause, evidence.correction)
		"maze":
			if not evidence.get("command") is String or not evidence.get("password") is String:
				return SaveService._fail("Authentification de la session absente.")
			checked = _validate_maze(evidence.command, evidence.password)
		"python", "html", "markdown":
			if not evidence.get("answer") is String:
				return SaveService._fail("La réponse au défi de code est absente.")
			checked = _validate_code(id, evidence.answer)
		_:
			return SaveService._fail("Mission inconnue.")
	return checked

func _finish_validated(id: String, evidence: Dictionary) -> Dictionary:
	# Même cet intermédiaire revalide une solution concrète ; un appel direct
	# avec un état fabriqué ne peut pas attribuer une réussite.
	var checked := _validate_solution(id, evidence)
	if not checked.ok:
		return checked
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	var definition := mission(id)
	if id in AppState.profile.progress.completed_missions:
		return SaveService._ok({"mission_id": id, "reward": 0, "already_completed": true, "explanation": definition.success_explanation, "clue": definition.clue.duplicate(true)})
	# Autorisation éphémère créée uniquement après les validations ci-dessus.
	# La récompense consomme cette preuve, puis écrit le document complet une seule fois.
	var token := Crypto.new().generate_random_bytes(16).hex_encode()
	_authorizations[token] = {"mission_id": id, "profile_id": AppState.profile.id, "profile_snapshot": AppState.profile.duplicate(true), "progress": progress.duplicate(true), "evidence": evidence.duplicate(true)}
	var result := RewardService._complete_validated_mission(id, token)
	_authorizations.erase(token)
	if result.ok:
		result.data["explanation"] = definition.success_explanation
		result.data["clue"] = definition.clue.duplicate(true)
		mission_changed.emit(id, "completed")
	return result

func _take_authorization(id: String, token: String) -> Dictionary:
	if token.is_empty() or not _authorizations.has(token):
		return SaveService._fail("Validation métier absente : résous le défi avant de demander sa récompense.")
	var pending: Variant = _authorizations[token]
	if not pending is Dictionary or not pending.get("mission_id") is String:
		_authorizations.erase(token)
		return SaveService._fail("La preuve de résolution est invalide.")
	if pending.mission_id != id:
		return SaveService._fail("La preuve de résolution appartient à une autre mission.")
	var authorization: Dictionary = _authorizations[token].duplicate(true)
	_authorizations.erase(token)
	if not authorization.get("profile_id") is String or not authorization.get("profile_snapshot") is Dictionary or not authorization.get("progress") is Dictionary or not authorization.get("evidence") is Dictionary:
		return SaveService._fail("La preuve de résolution est incomplète.")
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
	if selected not in [1, 2, 3, 4, 5]:
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

# Le terminal est un automate local : aucune chaîne n’est passée à un shell.
const ELEVATION_COMMANDS := ["sudo", "sudo -i", "sudo -s", "su -", "s-"]

func enter_maze() -> Dictionary:
	if AppState.profile.is_empty() or not can_enter_chapter(5):
		return SaveService._fail("Le cinquième chapitre n’est pas accessible.")
	var checked := SaveService.validate_profile(AppState.profile)
	if not checked.ok or checked.get("migration_required", false): return SaveService._fail("Rechargez un profil valide avant d’entrer.")
	if AppState.profile.progress.room_id != "room_05": return SaveService._fail("Utilisez le portable du palier.")
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.room_id = "maze_05"
	progress.checkpoint_id = "maze_entry"
	progress.active_mission = ""
	return _save_progress(progress)

func leave_maze() -> Dictionary:
	if AppState.profile.is_empty() or AppState.profile.progress.room_id != "maze_05": return SaveService._fail("Vous n’êtes pas dans le labyrinthe.")
	return enter_chapter(5)

func terminal_connected() -> bool:
	return not AppState.profile.is_empty() and "login" in AppState.profile.progress.observations.get("maze", [])

func terminal_login(user: String, password: String) -> Dictionary:
	var ready := _ready_for("maze")
	if not ready.ok: return ready
	if user != "admin" or password != "admin": return SaveService._fail("Identifiant ou mot de passe incorrect.")
	if terminal_connected(): return SaveService._ok({"connected": true})
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.observations.maze = ["login"]
	progress.active_mission = "maze"
	progress.checkpoint_id = "maze_terminal"
	var saved := _save_progress(progress)
	if not saved.ok: return saved
	return SaveService._ok({"connected": true})

func terminal_command(text: String, password: String = "") -> Dictionary:
	var ready := _ready_for("maze")
	if not ready.ok: return ready
	if not terminal_connected(): return SaveService._fail("Ouvrez une session avant de saisir une commande.")
	if text.length() > CODE_TEXT_LIMIT: return SaveService._fail("Commande trop longue.")
	var command := " ".join(text.strip_edges().split(" ", false))
	if command in ELEVATION_COMMANDS:
		if password.is_empty(): return SaveService._ok({"needs_password": true, "command": command})
		return _finish_validated("maze", {"command": command, "password": password})
	var privileged: bool = "maze" in AppState.profile.progress.completed_missions
	var replies := {
		"whoami": "root — session privilégiée, uid=0" if privileged else "admin — session utilisateur, uid=1000",
		"id": "uid=0(root) gid=0(root)" if privileged else "uid=1000(admin) gid=1000(admin)",
		"pwd": "/root" if privileged else "/home/admin",
		"ls": "notes.txt  serveur-ciel  archives",
		"help": "Commandes de consultation : ls, pwd, whoami, id. Des mémos sont affichés dans les couloirs.",
		"clear": "", "cls": "cls est une commande Windows. Le serveur CIEL utilise Linux.",
		"dir": "dir est ici une piste Windows. Aucun changement de droits.",
		"ipconfig": "ipconfig concerne Windows. Le serveur CIEL utilise Linux.",
		"runas": "runas appartient à Windows ; ce terminal utilise Linux."
	}
	if command not in replies: return SaveService._fail("Commande inconnue dans ce terminal.")
	return SaveService._ok({"output": replies[command]})

func _validate_maze(command: String, password: String) -> Dictionary:
	var ready := _ready_for("maze")
	if not ready.ok: return ready
	if not terminal_connected(): return SaveService._fail("Aucune session authentifiée.")
	if command not in ELEVATION_COMMANDS: return SaveService._fail("Cette commande ne change pas les droits.")
	if password != "admin": return SaveService._fail("Échec de l’authentification des privilèges.")
	return SaveService._ok()

## Source and destination are checked together, then saved before any world swap.
func travel_zone(destination: String) -> Dictionary:
	if AppState.profile.is_empty(): return SaveService._fail("Aucun profil actif.")
	var valid := SaveService.validate_profile(AppState.profile)
	if not valid.ok: return valid
	if valid.get("migration_required", false): return SaveService._fail("Sélectionnez d’abord ce profil pour enregistrer sa migration.")
	if not _chapter_complete(5): return SaveService._fail("Terminez le défi du chapitre 5, puis redescendez au premier niveau.")
	var source := str(AppState.profile.progress.room_id)
	var routes := {"room_01>courtyard": "from_first", "courtyard>room_01": "building_exit", "courtyard>building_02": "new_entrance", "building_02>courtyard": "from_second"}
	var route := source + ">" + destination
	if not routes.has(route): return SaveService._fail("Rejoignez la porte de ce passage. L’ascenseur descend un étage à la fois.")
	var progress: Dictionary = AppState.profile.progress.duplicate(true)
	progress.room_id = destination
	progress.checkpoint_id = routes[route]
	progress.active_mission = ""
	var saved := _save_progress(progress)
	if not saved.ok: return saved
	return SaveService._ok({"room_id": destination, "checkpoint_id": progress.checkpoint_id})
