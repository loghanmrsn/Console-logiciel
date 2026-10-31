extends Node
## Saved progression and point settlement are one atomic profile transaction.
const Catalog = preload("res://scripts/game/city_network_catalog.gd")
func state() -> Dictionary:
	return AppState.profile.get("progress", {}).get("city_network", Catalog.empty_state()).duplicate(true)
func mission_state(id: String) -> String:
	var index := Catalog.IDS.find(id)
	if index < 0: return "locked"
	var completed: Array = state().completed
	if id in completed: return "completed"
	return "available" if completed.size() == index else "locked"
func submit(id: String, answers: Variant) -> Dictionary:
	var ready := HotelService._ready_for(["school_network_lab"])
	if not ready.ok: return ready
	if mission_state(id) == "locked": return SaveService._fail("Terminez le poste précédent avant de poursuivre.")
	if not Catalog.accepts(id, answers): return SaveService._fail("La configuration n’est pas encore correcte. Relisez le plan d’adressage et le tableau de cours ; aucune progression ni aucun point n’a été modifié.")
	if mission_state(id) == "completed": return {"ok":true,"error":"","reward":0,"credited_points":0,"debt_repaid":0}
	var document: Dictionary = AppState.profile.duplicate(true)
	var next := state()
	next.completed.append(id)
	document.progress.city_network = next
	var receipt := "city_" + id
	var reward := 0 if receipt in document.rewarded_missions else Catalog.REWARD
	if int(document.wallet.points) > SaveService.MAX_POINTS - reward: return SaveService._fail("Le portefeuille a atteint sa limite.")
	var settlement := PenaltyService.credit_reward(document, reward)
	if receipt not in document.rewarded_missions: document.rewarded_missions.append(receipt)
	var saved := SaveService.write_profile(document)
	if not saved.ok: return saved
	AppState.commit_profile(saved.data)
	var result := SaveService._ok(next.duplicate(true))
	result["reward"] = reward
	result.merge(settlement)
	return result
