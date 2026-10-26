extends Node
## Validation et récompense atomiques. La lecture d'un poste reste sans effet.
const Catalog = preload("res://scripts/game/ctf_catalog.gd")

func state() -> Dictionary:
	var value: Variant = AppState.profile.get("progress", {}).get("ctf", Catalog.empty_state())
	return value.duplicate(true) if value is Dictionary else Catalog.empty_state()

func completed() -> bool:
	return state().completed.size() == Catalog.IDS.size()

func mission_state(id: String) -> String:
	var index := Catalog.IDS.find(id)
	if index < 0: return "locked"
	var done: Array = state().completed
	if id in done: return "completed"
	return "available" if done.size() == index else "locked"

func submit(id: String, answer: String) -> Dictionary:
	var ready := HotelService._ready_for(["ctf_lobby"])
	if not ready.ok: return ready
	if not Catalog.IDS.has(id): return SaveService._fail("Cette épreuve n'existe pas.")
	if mission_state(id) == "locked": return SaveService._fail("Validez le poste précédent avant cette épreuve.")
	if not Catalog.accepts(id, answer): return SaveService._fail(str(Catalog.CHALLENGES[id].hint))
	if mission_state(id) == "completed": return {"ok": true, "error": "", "reward": 0, "credited_points": 0, "debt_repaid": 0}
	var document: Dictionary = AppState.profile.duplicate(true)
	var progress := state()
	progress.completed.append(id)
	document.progress["ctf"] = progress
	var reward_id := "ctf_" + id
	var reward := 0 if reward_id in document.rewarded_missions else Catalog.REWARD
	if int(document.wallet.points) > SaveService.MAX_POINTS - reward:
		return SaveService._fail("Le portefeuille a atteint sa limite.")
	var settlement := PenaltyService.credit_reward(document, reward)
	if reward_id not in document.rewarded_missions: document.rewarded_missions.append(reward_id)
	var saved := SaveService.write_profile(document)
	if not saved.ok: return saved
	AppState.commit_profile(saved.data)
	var result := SaveService._ok(saved.data.progress.ctf.duplicate(true))
	result["reward"] = reward
	result.merge(settlement)
	return result
