extends Node
## Récompense unique et progression dans le même document de profil.
## L'interface soumet une solution à InvestigationService ; elle ne valide pas une mission.

var missions: Array = []

func load_rules() -> Dictionary:
	missions.clear()
	var definitions := SaveService._ensure_definitions()
	if not definitions.ok:
		return definitions
	var parsed := SaveService._resource_json("res://data/game_rules.json")
	if not parsed.ok:
		return parsed
	var validation := SaveService.validate_rules(parsed.data)
	if not validation.ok:
		return validation
	missions = validation.data.duplicate(true)
	return SaveService._ok(missions.duplicate(true))

func complete_mission(_id: String) -> Dictionary:
	return SaveService._fail("Une mission doit être résolue et validée par le service d'enquête avant d'attribuer une récompense.")

func _complete_validated_mission(id: String, authorization_token: String) -> Dictionary:
	if AppState.profile.is_empty():
		return SaveService._fail("Aucun profil actif.")
	var authorized := InvestigationService._take_authorization(id, authorization_token)
	if not authorized.ok:
		return authorized
	if authorized.data.profile_id != AppState.profile.id or authorized.data.profile_snapshot != AppState.profile:
		return SaveService._fail("Le profil a changé pendant la validation. Recommencez cette tentative.")
	if not authorized.data.get("evidence") is Dictionary or not authorized.data.get("progress") is Dictionary or authorized.data.progress != AppState.profile.progress:
		return SaveService._fail("La preuve de résolution ou la progression autorisée est invalide.")
	# Recontrôler la solution réelle avant de modifier les points ou la progression.
	# Un jeton consommé ne suffit jamais à affirmer qu’un exercice a été résolu.
	var checked := InvestigationService._validate_solution(id, authorized.data.evidence)
	if not checked.ok:
		return checked
	if missions.is_empty():
		var loaded := load_rules()
		if not loaded.ok:
			return loaded
	var found: Dictionary = {}
	for mission in missions:
		if mission.id == id:
			found = mission
			break
	if found.is_empty():
		return SaveService._fail("Mission inconnue.")
	var profile: Dictionary = AppState.profile.duplicate(true)
	if not profile.progress.started:
		return SaveService._fail("Commencez l'enquête avant de valider une mission.")
	if profile.progress.room_id != found.room_id:
		return SaveService._fail("La mission appartient à un autre étage de l’enquête.")
	if id in profile.progress.completed_missions:
		return SaveService._ok({"mission_id": id, "reward": 0, "already_completed": true})
	var reward := 0
	var settlement := {"debt_repaid": 0, "credited_points": 0}
	if id not in profile.rewarded_missions:
		reward = int(found.reward)
		if int(profile.wallet.points) > SaveService.MAX_POINTS - reward:
			return SaveService._fail("Le portefeuille a atteint sa limite.")
		settlement = PenaltyService.credit_reward(profile, reward)
		profile.rewarded_missions.append(id)
	profile.progress = authorized.data.progress.duplicate(true)
	profile.progress.completed_missions.append(id)
	profile.progress.active_mission = ""
	profile.progress.checkpoint_id = id
	profile.progress.clues.append(found.clue.id)
	profile.progress.run_reward_points = int(profile.progress.run_reward_points) + reward
	var saved := SaveService.write_profile(profile)
	if not saved.ok:
		return saved
	AppState.commit_profile(saved.data)
	return SaveService._ok({"mission_id": id, "reward": reward, "already_completed": false, "debt_repaid": settlement.debt_repaid, "credited_points": settlement.credited_points})
