extends Node
## Wallet, debt and count are committed together. A replay keeps all receipts.
const COST := 200
const MAX_COUNT := 1000000

func empty_record() -> Dictionary:
	return {"version": 1, "count": 0, "debt": 0, "paid": 0, "last_event": ""}

func state(profile: Dictionary = {}) -> Dictionary:
	var selected := AppState.profile if profile.is_empty() else profile
	return selected.get("penalties", empty_record()).duplicate(true)

func validate_record(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 5: return false
	for key in empty_record():
		if not value.has(key): return false
	if not SaveService._is_integer(value.version, 1, 1): return false
	if not SaveService._is_integer(value.count, 0, MAX_COUNT): return false
	for key in ["paid", "debt"]:
		if not SaveService._is_integer(value[key], 0, MAX_COUNT * COST): return false
	if int(value.count) * COST != int(value.paid) + int(value.debt): return false
	if not value.last_event is String: return false
	return value.last_event.is_empty() if int(value.count) == 0 else _valid_event(value.last_event)

func _valid_event(value: String) -> bool:
	if value.length() != 32: return false
	for character in value:
		if character not in "0123456789abcdef": return false
	return true

func record_crossing(event_id: String) -> Dictionary:
	if AppState.profile.is_empty(): return SaveService._fail("Aucun profil actif.")
	var valid := SaveService.validate_profile(AppState.profile)
	if not valid.ok: return valid
	if valid.get("migration_required", false): return SaveService._fail("Sélectionnez d’abord ce profil pour enregistrer sa migration.")
	if AppState.profile.progress.room_id != "courtyard" or "maze" not in AppState.profile.progress.completed_missions:
		return SaveService._fail("Cette pénalité concerne le passage piéton entre les bâtiments.")
	if not _valid_event(event_id): return SaveService._fail("Cette traversée n’est pas identifiée.")
	var record := state()
	if record.last_event == event_id: return SaveService._ok({"cost": 0, "already_recorded": true, "debt": record.debt})
	if int(record.count) >= MAX_COUNT: return SaveService._fail("La limite de pénalités du profil est atteinte.")
	var document: Dictionary = AppState.profile.duplicate(true)
	var payment := mini(COST, int(document.wallet.points))
	document.wallet.points = int(document.wallet.points) - payment
	record.count = int(record.count) + 1
	record.paid = int(record.paid) + payment
	record.debt = int(record.debt) + COST - payment
	record.last_event = event_id
	document["penalties"] = record
	var saved := SaveService.write_profile(document)
	if not saved.ok: return saved
	AppState.commit_profile(saved.data)
	return SaveService._ok({"cost": COST, "paid": payment, "debt": record.debt, "already_recorded": false})

## This changes only the caller's detached transaction, never live state.
func credit_reward(document: Dictionary, amount: int) -> Dictionary:
	var record := state(document)
	var repayment := mini(maxi(0, amount), int(record.debt))
	if repayment > 0:
		record.debt = int(record.debt) - repayment
		record.paid = int(record.paid) + repayment
		document["penalties"] = record
	var credited := amount - repayment
	document.wallet.points = int(document.wallet.points) + credited
	return {"debt_repaid": repayment, "credited_points": credited}

func reward_message(message: String, result: Dictionary) -> String:
	var reward := int(result.get("reward", 0))
	var repayment := int(result.get("debt_repaid", 0))
	return "%s · %d points, dont %d remboursés" % [message, reward, repayment] if repayment > 0 else "%s · +%d points" % [message, reward]
