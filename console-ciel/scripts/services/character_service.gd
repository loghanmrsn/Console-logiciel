extends Node
const Catalog=preload("res://scripts/services/character_catalog.gd")
func current() -> Dictionary: return Catalog.record(AppState.profile)
func purchase(slot: String,id: String) -> Dictionary:
	if AppState.profile.is_empty(): return SaveService._fail("Sélectionnez un profil.")
	var entry=Catalog.item(id,slot)
	if entry.is_empty() or entry.get("retired",false): return SaveService._fail("Article inconnu.")
	var document=AppState.profile.duplicate(true)
	var character=Catalog.record(document)
	if Catalog.owned(character,entry): return SaveService._fail("Cet article est déjà disponible.")
	if int(document.wallet.points)<int(entry.price): return SaveService._fail("Points insuffisants. Gagnez des points dans les missions.")
	document.wallet.points-=int(entry.price)
	character.owned.append(Catalog.key(slot,id))
	document.character=character
	return _commit(document)
func apply(appearance: Dictionary) -> Dictionary:
	if AppState.profile.is_empty(): return SaveService._fail("Sélectionnez un profil.")
	if appearance.get("top")=="madison": return SaveService._fail("Cette tenue a été retirée. Choisissez un autre haut.")
	var document=AppState.profile.duplicate(true)
	var character=Catalog.record(document)
	character.appearance=appearance.duplicate(true)
	if not Catalog.valid(character): return SaveService._fail("Choisissez des articles disponibles et des couleurs valides.")
	document.character=character
	return _commit(document)
func _commit(document: Dictionary) -> Dictionary:
	var saved=SaveService.write_profile(document)
	if saved.ok: AppState.commit_profile(saved.data)
	return saved
