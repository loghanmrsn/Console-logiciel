extends Node
## Commandes locales du seul compte Dev. Une mutation = une écriture validée.
## Les commandes ne sont jamais transmises à un shell ou à un terminal système.
const Ctf = preload("res://scripts/game/ctf_catalog.gd")
const HELP := "help · afficher les commandes\nstatus · afficher le profil, le solde et la salle\nadd coins <montant> · ajouter un entier positif au solde\nskip missions · valider uniquement l'objectif actuel, sans points\nskip mission · même commande\nreset missions · rejouer depuis le début, en conservant le solde et les achats\nclear · effacer l'historique du terminal"

func execute(command: String) -> Dictionary:
	if not ProfileService.is_super_admin(): return SaveService._fail("Le terminal est réservé au profil Dev · Super administrateur.")
	var valid := SaveService.validate_profile(AppState.profile)
	if not valid.ok: return valid
	if valid.get("migration_required", false): return SaveService._fail("Sélectionnez de nouveau ce profil avant d'utiliser le terminal.")
	if command.length() > 256 or "\n" in command or "\r" in command:
		return SaveService._fail("Saisissez une seule commande de 256 caractères au maximum.")
	var words := command.strip_edges().to_lower().replace("\t", " ").split(" ", false)
	var normalized := " ".join(words)
	if normalized == "help": return _response(HELP)
	if normalized == "clear": return {"ok": true, "error": "", "message": "Historique effacé.", "clear": true}
	if normalized == "status":
		return _response("Dev · %d points · dette : %d · %s\nEnquête : %d / 13 · CTF : %d / 5" % [int(AppState.profile.wallet.points), int(PenaltyService.state().debt), str(AppState.profile.progress.room_id), AppState.profile.progress.completed_missions.size(), CtfService.state().completed.size()])
	var document: Dictionary = AppState.profile.duplicate(true)
	var message := ""
	var moved := false
	if words.size() == 3 and words[0] == "add" and words[1] == "coins":
		var amount_text: String = words[2]
		if amount_text.length() > 10 or amount_text.is_empty(): return _amount_error()
		for character in amount_text:
			if character not in "0123456789": return _amount_error()
		var amount := int(amount_text)
		if amount < 1 or amount > SaveService.MAX_POINTS - int(document.wallet.points): return _amount_error()
		document.wallet.points = int(document.wallet.points) + amount
		message = "+%d points · nouveau solde : %d. La dette reste inchangée." % [amount, int(document.wallet.points)]
	elif normalized in ["skip mission", "skip missions"]:
		var skipped := _skip_current(document)
		if not skipped.ok: return skipped
		message = str(skipped.message) + " · sans ajout de points."
		moved = bool(skipped.get("moved", false))
	elif normalized == "reset missions":
		document.progress = SaveService.empty_investigation_progress()
		document.progress.started = true
		message = "Parcours rejouable depuis la première salle. Solde, achats, récompenses déjà reçues et pénalités conservés."
		moved = true
	else:
		return SaveService._fail("Commande inconnue. Utilisez help ou, par exemple, add coins 500.")
	var saved := SaveService.write_profile(document)
	if not saved.ok: return saved
	AppState.commit_profile(saved.data)
	return {"ok": true, "error": "", "message": message, "changed": true, "moved": moved}

func _response(message: String) -> Dictionary:
	return {"ok": true, "error": "", "message": message}

func _amount_error() -> Dictionary:
	return SaveService._fail("Montant attendu : entier positif, sans dépasser 2 147 483 647 points au total. Exemple : add coins 500.")

func _receipt(document: Dictionary, id: String) -> void:
	if id not in document.rewarded_missions: document.rewarded_missions.append(id)

func _skip_current(document: Dictionary) -> Dictionary:
	var progress: Dictionary = document.progress
	if not progress.started: return SaveService._fail("Commencez une enquête avant de passer un objectif.")
	var chapter := InvestigationService.current_chapter()
	if chapter > 0:
		for mission in InvestigationService.chapter_missions(chapter):
			var id: String = mission.id
			if id in progress.completed_missions: continue
			for prerequisite in mission.prerequisites:
				if prerequisite not in progress.completed_missions: return SaveService._fail("Rejoignez d'abord le chapitre précédent.")
			progress.completed_missions.append(id)
			progress.clues.append(str(mission.clue.id))
			progress.observations[id] = []
			for observation in mission.observations: progress.observations[id].append(str(observation.id))
			if id == "computer": progress.checks.computer = mission.solution.checks.duplicate()
			progress.active_mission = ""
			_receipt(document, id)
			return _response("Objectif validé : " + str(mission.name))
		return SaveService._fail("Ce chapitre est déjà terminé. Prenez l'ascenseur ou la porte pour poursuivre.")
	if "maze" not in progress.completed_missions: return SaveService._fail("Terminez d'abord l'enquête du premier bâtiment.")
	var hotel: Dictionary = progress.hotel
	var before := str(progress.room_id)
	var message := ""
	if not hotel.reserved:
		hotel.reserved = true
		message = "Chambre 206 réservée"
	elif not hotel.repaired:
		hotel.repair_observations = SaveService.HOTEL_REPAIR_IDS.duplicate()
		hotel.repaired = true
		message = "Panne informatique de l'hôtel réparée"
	elif not hotel.luggage_placed:
		hotel.luggage_placed = true
		_place(progress, "hotel_room_206", "room206_entry")
		message = "Affaires déposées chambre 206"
	elif hotel.bed_state != "rested":
		hotel.bed_state = "rested"
		hotel.morning_stage = 1
		_place(progress, "hotel_room_206", "room206_bed")
		message = "Nuit passée"
	else:
		match int(hotel.morning_stage):
			1:
				hotel.morning_stage = 2
				_place(progress, "building_02", "hall_stairs")
				_receipt(document, "hotel_ground_floor")
				message = "Rez-de-chaussée rejoint"
			2:
				hotel.morning_stage = 3
				_place(progress, "hotel_breakfast", "breakfast_table")
				message = "Installation au petit déjeuner"
			3:
				hotel.coffee_connections = SaveService.COFFEE_WIRES.duplicate()
				hotel.morning_stage = 4
				message = "Machine à café réparée"
			4:
				hotel.morning_stage = 5
				message = "Café pris"
			5:
				hotel.morning_stage = 6
				_place(progress, "hotel_room_206", "room206_entry")
				_receipt(document, "hotel_backpack")
				message = "Sac et ordinateur récupérés"
			6:
				hotel.morning_stage = 7
				_place(progress, "ctf_bus_stop", "ctf_arrival")
				message = "Bus vers Sudo Hack"
			7:
				hotel.morning_stage = 8
				_place(progress, "ctf_lobby", "ctf_entry")
				message = "Entrée au CTF"
			8:
				var ctf: Dictionary = progress.get("ctf", Ctf.empty_state()).duplicate(true)
				if ctf.completed.size() < Ctf.IDS.size():
					var id: String = Ctf.IDS[ctf.completed.size()]
					ctf.completed.append(id)
					progress["ctf"] = ctf
					_receipt(document, "ctf_" + id)
					message = "CTF validé : " + str(Ctf.CHALLENGES[id].title)
				else:
					hotel.morning_stage = 9
					_place(progress, "courtyard", "from_first")
					message = "Bus de retour en ville"
			_:
				return SaveService._fail("Le parcours actuel est déjà terminé.")
	return {"ok": true, "error": "", "message": message, "moved": before != str(progress.room_id)}

func _place(progress: Dictionary, room: String, checkpoint: String) -> void:
	progress.room_id = room
	progress.checkpoint_id = checkpoint
	progress.active_mission = ""
