extends Node

const GameLibrary := preload("res://scripts/services/game_library.gd")

signal catalog_loaded(items: Array)
var catalog: Array = []

func validate_catalog(document: Variant) -> Dictionary:
	return SaveService.validate_catalog(document)

func load_catalog(path: String = "res://data/shop_catalog.json") -> Dictionary:
	catalog.clear()
	var parsed := SaveService._resource_json(path)
	if not parsed.ok:
		return parsed
	var validation := validate_catalog(parsed.data)
	if not validation.ok:
		return validation
	catalog = validation.data.duplicate(true)
	catalog_loaded.emit(catalog.duplicate(true))
	return SaveService._ok(catalog.duplicate(true))

func item(id: String) -> Dictionary:
	if catalog.is_empty():
		load_catalog()
	for product in catalog:
		if product.id == id:
			return product.duplicate(true)
	return {}

func purchase(id: String) -> Dictionary:
	if AppState.profile.is_empty():
		return SaveService._fail("Sélectionnez un profil avant d'acheter.")
	var product := item(id)
	if product.is_empty():
		return SaveService._fail("Article inconnu.")
	if not SaveService._is_integer(product.get("price"), 0, 100):
		return SaveService._fail("Prix d'article invalide.")
	if product.get("type") not in ["avatar", "theme", "frame", "game"]:
		return SaveService._fail("Type d'article invalide.")
	if product.type == "game" and not GameLibrary.is_valid_game_scene(product.get("scene")):
		return SaveService._fail("Ce jeu n'est pas disponible dans les fichiers locaux livrés.")
	var profile: Dictionary = AppState.profile.duplicate(true)
	var validation := SaveService.validate_profile(profile)
	if not validation.ok:
		return validation
	if id in profile.owned_items:
		return SaveService._fail("Cet article est déjà possédé.")
	if int(profile.wallet.points) < int(product.price):
		return SaveService._fail("Points insuffisants. Résolvez les missions de l’enquête pour en gagner.")
	profile.wallet.points = int(profile.wallet.points) - int(product.price)
	profile.owned_items.append(id)
	var saved := SaveService.write_profile(profile)
	if not saved.ok:
		return saved
	AppState.commit_profile(saved.data)
	return SaveService._ok(product)

func equip(id: String) -> Dictionary:
	if AppState.profile.is_empty():
		return SaveService._fail("Sélectionnez un profil avant d'équiper un article.")
	var product := item(id)
	if product.is_empty():
		return SaveService._fail("Article inconnu.")
	if product.get("type") == "game":
		return SaveService._fail("Un jeu se lance depuis la bibliothèque ; il ne peut pas être équipé.")
	var profile: Dictionary = AppState.profile.duplicate(true)
	if id not in profile.owned_items:
		return SaveService._fail("Cet article n'est pas possédé.")
	if product.type not in ["avatar", "theme", "frame"]:
		return SaveService._fail("Type d'équipement inconnu.")
	# Rééquiper l'avatar courant doit aussi retirer une image personnelle active.
	if profile.equipped.get(product.type) == id and not (product.type == "avatar" and profile.has("avatar_image")):
		return SaveService._ok(product)
	profile.equipped[product.type] = id
	if product.type == "avatar":
		profile.erase("avatar_image")
	var saved := SaveService.write_profile(profile)
	if not saved.ok:
		return saved
	AppState.commit_profile(saved.data)
	return SaveService._ok(product)
