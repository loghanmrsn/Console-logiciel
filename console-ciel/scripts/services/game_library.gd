extends RefCounted
## Bibliothèque locale : les jeux de la boutique sont des scènes livrées avec
## l'application. L'enquête gratuite garde son parcours de lancement existant.

const EDUCATIONAL_ID := "game_enquete"
const GAMES_DIRECTORY := "res://scenes/games/"
const EDUCATIONAL_GAME := {
	"id": EDUCATIONAL_ID, "type": "game", "name": "L’enquête CIEL",
	"description": "Deux chapitres, six défis. Explorez, comprenez et gagnez des points.",
	"price": 0, "color": "#527FA3", "scene": "res://scenes/investigation_world.tscn",
	"educational": true
}


static func is_valid_game_scene(value: Variant) -> bool:
	if not value is String:
		return false
	var path: String = value
	if path.length() > 256 or not path.begins_with(GAMES_DIRECTORY) or not path.ends_with(".tscn"):
		return false
	var relative := path.trim_prefix(GAMES_DIRECTORY)
	for segment in relative.split("/"):
		if segment.is_empty() or segment in [".", ".."]:
			return false
		var identifier := segment.trim_suffix(".tscn") if segment == relative.get_file() else segment
		if identifier.is_empty():
			return false
		for character in identifier:
			var code := character.unicode_at(0)
			if not ((code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or character in ["_", "-"]):
				return false
	if not ResourceLoader.exists(path, "PackedScene"):
		return false
	return ResourceLoader.load(path, "PackedScene") is PackedScene


static func definitions(catalog: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = [EDUCATIONAL_GAME.duplicate(true)]
	var seen: Array[String] = [EDUCATIONAL_ID]
	for product in catalog:
		if not product is Dictionary or product.get("type") != "game" or not product.get("id") is String or product.id in seen:
			continue
		if not is_valid_game_scene(product.get("scene")):
			continue
		seen.append(product.id)
		result.append(product.duplicate(true))
	return result


static func entry(catalog: Array, id: String) -> Dictionary:
	for game in definitions(catalog):
		if game.id == id:
			return game
	return {}


static func owned_games(profile: Dictionary, catalog: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not profile.get("owned_items") is Array:
		return result
	for game in definitions(catalog):
		if game.id != EDUCATIONAL_ID and game.id in profile.owned_items:
			result.append(game)
	return result


static func can_play(profile: Dictionary, id: String, catalog: Array) -> bool:
	if profile.is_empty() or entry(catalog, id).is_empty():
		return false
	if id == EDUCATIONAL_ID:
		return true
	return profile.get("owned_items") is Array and id in profile.owned_items
