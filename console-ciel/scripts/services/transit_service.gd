extends Node
## One transaction: debit and arrival are saved together before the cutscene.
const FARE := 10
const DESTINATIONS := {"courtyard":"Centre · Hôtel Ritz", "ctf_bus_stop":"1 · Sudo Hack", "school_stop":"2 · Lycée Louise Michel"}
func travel(destination: String, walking := false) -> Dictionary:
	var plan := HotelService.bus_plan(destination, destination == "courtyard")
	if not plan.ok: return plan
	var document: Dictionary = AppState.profile.duplicate(true)
	if not walking and int(document.wallet.points) < FARE:
		return SaveService._fail("Billet : 1 € = 10 points. Solde insuffisant. Vous pouvez rejoindre les bâtiments à pied depuis la ville, ou choisir le retour à pied à l’arrêt.")
	document.progress = plan.data.duplicate(true)
	if not walking:
		var ledger: Dictionary = document.get("bus_travel",{"version":1,"rides":0,"spent_points":0,"last_stop":"courtyard"}).duplicate(true)
		if int(ledger.rides)>=1000000: return SaveService._fail("L’historique des billets a atteint sa limite.")
		document.wallet.points -= FARE
		ledger.rides += 1
		ledger.spent_points += FARE
		ledger.last_stop = str(document.progress.room_id)
		document.bus_travel = ledger
	var saved := SaveService.write_profile(document)
	if not saved.ok: return saved
	AppState.commit_profile(saved.data)
	var result := SaveService._ok({"room_id":document.progress.room_id,"checkpoint_id":document.progress.checkpoint_id})
	result["fare"] = 0 if walking else FARE
	result["destination"] = DESTINATIONS[document.progress.room_id]
	return result
