extends Node
## Documents locaux validés et remplacement prudent dans le même répertoire.
## Cette protection ne garantit pas la survie à toute coupure électrique.

signal storage_error_changed(message: String)

const SCHEMA_VERSION := 1
const DEV_PROFILE_ID := "dev-super-admin"
const DEV_PROFILE_NAME := "Dev"
const INVESTIGATION_VERSION := 1
const CHAPTER_ONE_IDS := ["lighting", "lock", "computer"]
const CHAPTER_TWO_IDS := ["network", "addressing", "security"]
const CHAPTER_THREE_IDS := ["python", "html", "markdown"]
const CHAPTER_FOUR_IDS := ["firewall", "ip_conflict", "subnet_mask"]
const CHAPTER_FIVE_IDS := ["maze"]
const CtfCatalog = preload("res://scripts/game/ctf_catalog.gd")
const HOTEL_VERSION := 2
const HOTEL_REWARD_IDS := ["hotel_ground_floor", "hotel_backpack"]
const COFFEE_WIRES := {"A": "3", "B": "2", "C": "1"}
const HOTEL_ROOMS := ["building_02", "hotel_it", "hotel_stairs_1", "hotel_floor_2", "hotel_room_206", "hotel_breakfast", "ctf_bus_stop", "ctf_lobby"]
const HOTEL_REPAIR_IDS := ["power", "network", "storage", "service"]
const HOTEL_CHECKPOINTS := {
	"new_entrance": "building_02", "hall_it": "building_02", "hall_stairs": "building_02",
	"it_entrance": "hotel_it", "stairs_from_hall": "hotel_stairs_1", "stairs_from_floor2": "hotel_stairs_1",
	"floor2_stairs": "hotel_floor_2", "floor2_room206": "hotel_floor_2",
	"room206_entry": "hotel_room_206", "room206_bed": "hotel_room_206",
	"hall_breakfast": "building_02", "breakfast_entry": "hotel_breakfast", "breakfast_table": "hotel_breakfast",
	"ctf_arrival": "ctf_bus_stop", "ctf_door": "ctf_bus_stop", "ctf_entry": "ctf_lobby"
}
const MISSION_IDS := CHAPTER_ONE_IDS + CHAPTER_TWO_IDS + CHAPTER_THREE_IDS + CHAPTER_FOUR_IDS + CHAPTER_FIVE_IDS
const CHAPTER_TWO_SOLUTIONS := {
	"network": {"observations": ["switch", "link", "cable"], "diagnosis": "cable_unplugged", "repair": "reconnect_rj45"},
	"addressing": {"observations": ["workstation", "gateway", "allocation"], "diagnosis": "wrong_subnet", "repair": "align_subnet"},
	"security": {"observations": ["wifi", "compatibility", "passphrase"], "diagnosis": "open_wifi", "repair": "enable_encryption"}
}
const CHAPTER_FOUR_SOLUTIONS := {
	"firewall": {"observations": ["service", "traffic", "rules"], "diagnosis": "rule_missing", "repair": "allow_https_only"},
	"ip_conflict": {"observations": ["terminal", "printer", "plan"], "diagnosis": "duplicate_ip", "repair": "apply_unique_ip"},
	"subnet_mask": {"observations": ["address", "gateway", "subnet_plan"], "diagnosis": "mask_too_small", "repair": "set_mask_26"}
}
const CHAPTER_THREE_SOLUTIONS := {
	"python": {"answer": "print", "choices": ["print", "input", "for"], "template": "____(\"Bonjour CIEL\")"},
	"html": {"answer": "h1", "choices": ["p", "h1", "img"], "template": "<____>Bonjour CIEL</____>"},
	"markdown": {"answer": "hash", "choices": ["star", "dash", "hash"], "template": "____ Bonjour CIEL"}
}
const LEGACY_MIGRATION_NOTICE := "La progression du prototype contenait des interactions simulées. Elle a été remise au début pour jouer les vrais défis. Vos points, achats et récompenses déjà attribuées sont conservés : ils ne seront pas gagnés une seconde fois."
const DEFAULT_ITEMS := ["avatar_default", "theme_brume", "frame_default"]
const LocalAvatarLibrary := preload("res://scripts/services/local_avatar_library.gd")
const GameLibrary := preload("res://scripts/services/game_library.gd")
const MAX_POINTS := 2147483647
var root_path: String = "user://"
var simulate_write_failure: bool = false
# Dernière erreur réelle d'accès aux documents, conservée même après un nouvel essai.
# Les erreurs de saisie et les mauvaises réponses pédagogiques ne l'alimentent pas.
var last_error: String = ""
var last_error_at: String = ""
var _catalog_by_id: Dictionary = {}
var _mission_ids: Array = []
var _mission_by_id: Dictionary = {}

func _ok(data: Variant = null) -> Dictionary:
	return {"ok": true, "error": "", "data": data}

func _fail(message: String, data: Variant = null) -> Dictionary:
	return {"ok": false, "error": message, "data": data}

func record_storage_error(message: String) -> void:
	last_error = message
	last_error_at = Time.get_datetime_string_from_system(false, true)
	storage_error_changed.emit(message)

func _storage_fail(message: String, data: Variant = null) -> Dictionary:
	record_storage_error(message)
	return _fail(message, data)

func _storage_result(result: Dictionary) -> Dictionary:
	if not result.ok:
		record_storage_error(result.error)
	return result

func invalidate_definitions() -> void:
	# Réessayer le démarrage doit relire les fichiers livrés, sans cache ancien.
	_catalog_by_id.clear()
	_mission_ids.clear()
	_mission_by_id.clear()

func _path(relative: String) -> String:
	return root_path.path_join(relative)

func is_safe_id(id: String) -> bool:
	if id.is_empty() or id.length() > 64:
		return false
	for character in id:
		var code := character.unicode_at(0)
		if not ((code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or character == "_" or character == "-"):
			return false
	return true

func validate_display_name(value: Variant) -> Dictionary:
	if not value is String:
		return _fail("Le pseudo doit être du texte.")
	var raw_name: String = value
	for character in raw_name:
		var code := character.unicode_at(0)
		if code < 32 or (code >= 127 and code <= 159):
			return _fail("Le pseudo contient un caractère de contrôle interdit.")
	var name: String = value.strip_edges()
	if name.length() < 1 or name.length() > 16:
		return _fail("Le pseudo doit contenir entre 1 et 16 caractères.")
	return _ok(name)

func _is_integer(value: Variant, minimum: int, maximum: int) -> bool:
	if not (value is int or value is float):
		return false
	return is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= minimum and float(value) <= maximum

func _resource_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _fail("Fichier livré introuvable : " + path)
	return _parse_json(FileAccess.get_file_as_string(path), path)

func _parse_json(content: String, label: String) -> Dictionary:
	var json := JSON.new()
	var code := json.parse(content)
	if code != OK:
		return _fail("JSON invalide dans %s (ligne %s)." % [label, json.get_error_line()])
	if not json.data is Dictionary:
		return _fail("Le document %s doit être un objet JSON." % label)
	return _ok(json.data)

func validate_catalog(value: Variant) -> Dictionary:
	if not value is Dictionary or not _is_integer(value.get("schema_version"), SCHEMA_VERSION, SCHEMA_VERSION) or not value.get("items") is Array:
		return _fail("Structure ou version du catalogue invalide.")
	if value.items.size() < 8:
		return _fail("Le catalogue doit proposer au moins huit articles.")
	var seen: Dictionary = {}
	var normalized: Array = []
	for entry in value.items:
		if not entry is Dictionary or not entry.get("id") is String or not is_safe_id(entry.id):
			return _fail("Un identifiant du catalogue est invalide.")
		if seen.has(entry.id) or entry.id == GameLibrary.EDUCATIONAL_ID or entry.get("type") not in ["avatar", "theme", "frame", "game"]:
			return _fail("Article dupliqué ou type inconnu dans le catalogue.")
		# Les jeux peuvent coûter davantage que les cosmétiques ; les deux
		# catégories conservent un prix gratuit explicite, sans conversion
		# d'un nombre invalide ou supérieur au plafond du portefeuille.
		var minimum_paid_price := 200 if entry.type == "game" else 20
		var maximum_price := MAX_POINTS if entry.type == "game" else 100
		if not _is_integer(entry.get("price"), 0, maximum_price) or (int(entry.price) != 0 and int(entry.price) < minimum_paid_price):
			return _fail("Prix invalide dans le catalogue.")
		if not entry.get("name") is String or entry.name.strip_edges().is_empty() or not entry.get("description") is String:
			return _fail("Un texte du catalogue est invalide.")
		if not entry.get("color") is String or not Color.html_is_valid(entry.color):
			return _fail("Une couleur d'aperçu du catalogue est invalide.")
		if entry.type == "theme":
			for key in ["accent", "background", "secondary"]:
				if not entry.get(key) is String or not Color.html_is_valid(entry[key]):
					return _fail("Une couleur de thème est invalide.")
		if entry.type == "avatar" and (not entry.get("symbol") is String or entry.symbol.is_empty() or entry.symbol.length() > 2):
			return _fail("Un symbole d'avatar est invalide.")
		if entry.type == "frame" and (not _is_integer(entry.get("width"), 1, 8) or entry.get("style") not in ["simple", "round", "double"]):
			return _fail("Une apparence de cadre est invalide.")
		if entry.type == "game" and not GameLibrary.is_valid_game_scene(entry.get("scene")):
			return _fail("Le jeu doit proposer une scène locale livrée dans scenes/games.")
		if entry.type == "game" and entry.has("placeholder") and not entry.placeholder is bool:
			return _fail("L'indication de jeu en préparation est invalide.")
		var product: Dictionary = entry.duplicate(true)
		product.price = int(product.price)
		seen[product.id] = product
		normalized.append(product)
	for id in DEFAULT_ITEMS:
		if not seen.has(id) or int(seen[id].price) != 0:
			return _fail("Un article gratuit par défaut manque au catalogue.")
	if seen.avatar_default.type != "avatar" or seen.theme_brume.type != "theme" or seen.frame_default.type != "frame":
		return _fail("Le type d'un article gratuit par défaut est invalide.")
	return _ok(normalized)

func _option_ids(mission: Dictionary, key: String) -> Array:
	var ids: Array = []
	for entry in mission.get(key, []):
		if entry is Dictionary and entry.get("id") is String:
			ids.append(entry.id)
	return ids

func _valid_id_list(value: Variant, allowed: Array) -> bool:
	if not value is Array:
		return false
	var seen: Array = []
	for id in value:
		if not id is String or id not in allowed or id in seen:
			return false
		seen.append(id)
	return true

func validate_rules(value: Variant) -> Dictionary:
	if not value is Dictionary or not _is_integer(value.get("schema_version"), SCHEMA_VERSION, SCHEMA_VERSION) or not value.get("missions") is Array or not _is_integer(value.get("investigation_version"), INVESTIGATION_VERSION, INVESTIGATION_VERSION):
		return _fail("Structure ou version des règles d'enquête invalide.")
	var ids: Array = []
	var clue_ids: Array = []
	var total := 0
	var normalized: Array = []
	for mission in value.missions:
		if not mission is Dictionary or mission.get("id") not in MISSION_IDS or mission.id in ids or not _is_integer(mission.get("reward"), 0, MAX_POINTS):
			return _fail("Une règle de mission est invalide.")
		if not mission.get("name") is String or mission.name.is_empty() or not mission.get("title") is String or mission.title.is_empty() or not mission.get("description") is String or not mission.get("success_explanation") is String:
			return _fail("Un texte de mission est invalide.")
		var expected_chapter := 1 if mission.id in CHAPTER_ONE_IDS else (2 if mission.id in CHAPTER_TWO_IDS else (3 if mission.id in CHAPTER_THREE_IDS else (4 if mission.id in CHAPTER_FOUR_IDS else 5)))
		if not _is_integer(mission.get("chapter"), expected_chapter, expected_chapter) or not mission.get("room_id") is String or mission.room_id != ("maze_05" if expected_chapter == 5 else "room_%02d" % expected_chapter):
			return _fail("Le chapitre ou la salle d’une mission est incohérent.")
		if not _valid_id_list(mission.get("prerequisites"), ids):
			return _fail("Un prérequis est inconnu, dupliqué ou cyclique.")
		if not mission.get("initial_state") is String or mission.get("initial_state") != ("available" if mission.prerequisites.is_empty() else "locked"):
			return _fail("L'état initial d'une mission ne correspond pas à ses prérequis.")
		if not mission.get("clue") is Dictionary or not mission.clue.get("id") is String or not is_safe_id(mission.clue.id) or mission.clue.id in clue_ids or not mission.clue.get("text") is String or mission.clue.text.is_empty():
			return _fail("Un indice livré avec une mission est invalide.")
		clue_ids.append(mission.clue.id)
		for key in ["observations", "checks"]:
			if not mission.get(key) is Array:
				return _fail("Les observations ou vérifications d'une mission sont invalides.")
			var seen: Array = []
			for observation in mission[key]:
				if not observation is Dictionary or not observation.get("id") is String or not is_safe_id(observation.id) or observation.id in seen or not observation.get("title") is String or observation.title.is_empty() or not observation.get("text") is String or observation.text.is_empty():
					return _fail("Une observation ou vérification est invalide.")
				seen.append(observation.id)
		if not mission.get("solution") is Dictionary:
			return _fail("Une solution pédagogique est absente.")
		var option_keys: Array = [] if mission.id in CHAPTER_THREE_IDS + CHAPTER_FIVE_IDS else (["connections"] if mission.id == "lighting" else (["causes", "corrections"] if mission.id == "computer" else ["diagnoses", "repairs"]))
		for key in option_keys:
			if not mission.get(key) is Array or mission[key].is_empty():
				return _fail("Les choix d'une simulation sont absents.")
			var seen: Array = []
			for choice in mission[key]:
				if not choice is Dictionary or not choice.get("id") is String or not is_safe_id(choice.id) or choice.id in seen or not choice.get("label") is String or choice.label.is_empty():
					return _fail("Un choix de simulation est invalide.")
				if key != "connections" and (not choice.get("feedback") is String or choice.feedback.is_empty()):
					return _fail("L'explication d'un choix est absente.")
				seen.append(choice.id)
		if mission.id == "lighting":
			if not _valid_id_list(mission.solution.get("connections"), _option_ids(mission, "connections")) or mission.solution.connections != ["source_switch", "switch_lamp", "lamp_return"]:
				return _fail("La solution d'éclairage doit former la boucle source → interrupteur → lampe → retour.")
		elif mission.id == "lock":
			if mission.prerequisites != ["lighting"] or _option_ids(mission, "observations") != ["badge", "power", "command", "link"] or not mission.solution.get("diagnosis") is String or mission.solution.get("diagnosis") != "control_link" or not mission.solution.get("repair") is String or mission.solution.get("repair") != "reconnect_control" or "control_link" not in _option_ids(mission, "diagnoses") or "reconnect_control" not in _option_ids(mission, "repairs"):
				return _fail("Les observations ou choix de la serrure sont incohérents.")
		elif mission.id == "computer":
			if mission.prerequisites != ["lock"] or _option_ids(mission, "observations") != ["pc", "display", "no_signal"] or not _valid_id_list(mission.solution.get("checks"), _option_ids(mission, "checks")) or not mission.solution.get("cause") is String or mission.solution.get("cause") != "video_disconnected" or not mission.solution.get("correction") is String or mission.solution.get("correction") != "reconnect_video" or "video_disconnected" not in _option_ids(mission, "causes") or "reconnect_video" not in _option_ids(mission, "corrections") or mission.solution.checks.size() != 2 or "power" not in mission.solution.checks or "video" not in mission.solution.checks:
				return _fail("Les observations ou choix de l'ordinateur sont incohérents.")
		elif mission.id == "maze":
			if mission.prerequisites != ["subnet_mask"] or int(mission.reward) != 50 or mission.name != "???" or mission.title != "???" or mission.description != "???" or _option_ids(mission, "observations") != ["login"] or not mission.checks.is_empty() or mission.solution != {"user": "admin", "password": "admin"}:
				return _fail("La mission unique du labyrinthe est incohérente.")
		elif mission.id in CHAPTER_TWO_IDS + CHAPTER_FOUR_IDS:
			var expected: Dictionary = CHAPTER_TWO_SOLUTIONS[mission.id] if mission.id in CHAPTER_TWO_IDS else CHAPTER_FOUR_SOLUTIONS[mission.id]
			var prerequisite: String = MISSION_IDS[MISSION_IDS.find(mission.id) - 1]
			if mission.prerequisites != [prerequisite] or _option_ids(mission, "observations") != expected.observations or not mission.checks.is_empty() or not mission.solution.get("diagnosis") is String or mission.solution.diagnosis != expected.diagnosis or not mission.solution.get("repair") is String or mission.solution.repair != expected.repair or expected.diagnosis not in _option_ids(mission, "diagnoses") or expected.repair not in _option_ids(mission, "repairs"):
				return _fail("Les observations ou choix du chapitre réseau sont incohérents.")
		else:
			var expected: Dictionary = CHAPTER_THREE_SOLUTIONS[mission.id]
			var prerequisite: String = MISSION_IDS[MISSION_IDS.find(mission.id) - 1]
			if mission.prerequisites != [prerequisite] or int(mission.reward) != 50 or not mission.observations.is_empty() or not mission.checks.is_empty():
				return _fail("L’ordre ou la récompense du chapitre code est incohérent.")
			if not mission.get("code") is Dictionary or not mission.code.get("prompt") is String or mission.code.prompt.strip_edges().is_empty() or not mission.code.get("template") is String or mission.code.template != expected.template or not mission.code.get("choices") is Array or not mission.solution.get("answer") is String or mission.solution.answer != expected.answer:
				return _fail("L’exercice de code ou sa solution est invalide.")
			var choice_ids: Array = []
			for choice in mission.code.choices:
				if not choice is Dictionary or not choice.get("id") is String or not is_safe_id(choice.id) or choice.id in choice_ids or not choice.get("label") is String or choice.label.is_empty() or not choice.get("feedback") is String or choice.feedback.is_empty():
					return _fail("Un choix ou une explication du chapitre code est invalide.")
				var expected_label: String = "#" if choice.id == "hash" else ("*" if choice.id == "star" else ("-" if choice.id == "dash" else choice.id))
				if choice.label != expected_label:
					return _fail("Le texte d’un choix de code ne correspond pas à sa syntaxe.")
				choice_ids.append(choice.id)
			if choice_ids != expected.choices:
				return _fail("Les choix du chapitre code sont inconnus ou incomplets.")
		if mission.id == "lighting" and not mission.prerequisites.is_empty():
			return _fail("L'éclairage doit être la première mission disponible.")
		total += int(mission.reward)
		if total > MAX_POINTS:
			return _fail("La somme des récompenses dépasse la limite.")
		ids.append(mission.id)
		var entry: Dictionary = mission.duplicate(true)
		entry.reward = int(entry.reward)
		normalized.append(entry)
	if ids != MISSION_IDS or not _is_integer(value.get("mission_reward_max"), total, total):
		return _fail("Le plafond de récompenses ou la liste des missions est incohérent.")
	return _ok(normalized)

func empty_hotel_progress() -> Dictionary:
	return {
		"version": HOTEL_VERSION, "reserved": false, "repair_observations": [],
		"repaired": false, "luggage_placed": false, "bed_state": "standing",
		"morning_stage": 0, "coffee_connections": {}
	}

func empty_investigation_progress() -> Dictionary:
	return {
		"investigation_version": INVESTIGATION_VERSION,
		"started": false, "room_id": "room_01", "checkpoint_id": "entrance",
		"completed_missions": [], "active_mission": "", "clues": [],
		"observations": {"lighting": [], "lock": [], "computer": [], "network": [], "addressing": [], "security": [], "python": [], "html": [], "markdown": [], "firewall": [], "ip_conflict": [], "subnet_mask": [], "maze": []},
		"checks": {"computer": []}, "run_reward_points": 0,
		"legacy_migration_notice": false, "hotel": empty_hotel_progress()
	}

func _ensure_definitions() -> Dictionary:
	if not _catalog_by_id.is_empty() and not _mission_ids.is_empty() and not _mission_by_id.is_empty():
		return _ok()
	var catalog := _resource_json("res://data/shop_catalog.json")
	if not catalog.ok:
		return catalog
	var checked_catalog := validate_catalog(catalog.data)
	if not checked_catalog.ok:
		return checked_catalog
	var items: Dictionary = {}
	for entry in checked_catalog.data:
		items[entry.id] = entry
	var rules := _resource_json("res://data/game_rules.json")
	if not rules.ok:
		return rules
	var checked_rules := validate_rules(rules.data)
	if not checked_rules.ok:
		return checked_rules
	var missions: Array = []
	var mission_definitions: Dictionary = {}
	for mission in checked_rules.data:
		missions.append(mission.id)
		mission_definitions[mission.id] = mission.duplicate(true)
	_catalog_by_id = items
	_mission_ids = missions
	_mission_by_id = mission_definitions
	return _ok()

func _validate_hotel_progress(progress: Dictionary, completed: Array, rewarded: Array) -> Dictionary:
	var hotel: Variant = progress.get("hotel")
	var keys := empty_hotel_progress().keys()
	if not hotel is Dictionary or hotel.size() != keys.size() or not _valid_id_list(hotel.keys(), keys):
		return _fail("La progression de l’hôtel est absente, partielle ou inconnue.")
	if not _is_integer(hotel.get("version"), HOTEL_VERSION, HOTEL_VERSION):
		return _fail("La version de progression de l’hôtel est inconnue.")
	for field in ["reserved", "repaired", "luggage_placed"]:
		if not hotel.get(field) is bool:
			return _fail("Une étape de l’hôtel est invalide.")
	if not _valid_id_list(hotel.get("repair_observations"), HOTEL_REPAIR_IDS) or not hotel.get("bed_state") is String or hotel.bed_state not in ["standing", "sitting", "rested"]:
		return _fail("Les observations ou l’état du lit sont invalides.")
	var advanced: bool = hotel.reserved or not hotel.repair_observations.is_empty() or hotel.repaired or hotel.luggage_placed or hotel.bed_state != "standing"
	if advanced and (not progress.started or "maze" not in completed):
		return _fail("Terminez le chapitre 5 avant de commencer le séjour à l’hôtel.")
	if not hotel.reserved and (not hotel.repair_observations.is_empty() or hotel.repaired or hotel.luggage_placed or hotel.bed_state != "standing"):
		return _fail("Réservez la chambre avant de commencer les étapes de l’hôtel.")
	if hotel.repaired and hotel.repair_observations.size() != HOTEL_REPAIR_IDS.size():
		return _fail("La panne réparée doit posséder ses quatre observations.")
	if (hotel.luggage_placed or hotel.bed_state != "standing") and not hotel.repaired:
		return _fail("Réparez la panne avant de rejoindre la chambre.")
	if hotel.bed_state != "standing" and not hotel.luggage_placed:
		return _fail("Posez les affaires avant de vous installer sur le lit.")
	if progress.room_id == "hotel_it" and not hotel.reserved:
		return _fail("Le local informatique s’ouvre après la réservation.")
	if progress.room_id in ["hotel_stairs_1", "hotel_floor_2", "hotel_room_206"] and not hotel.repaired:
		return _fail("L’escalier reste fermé pendant la panne informatique.")
	if progress.checkpoint_id == "hall_it" and not hotel.reserved:
		return _fail("Ce retour du local nécessite une réservation.")
	if progress.checkpoint_id == "hall_stairs" and not hotel.repaired:
		return _fail("Ce retour d’escalier nécessite la réparation.")
	if hotel.bed_state == "sitting" and (progress.room_id != "hotel_room_206" or progress.checkpoint_id != "room206_bed"):
		return _fail("Le repos assis se poursuit dans la chambre, sur le lit.")
	if progress.checkpoint_id == "room206_bed" and hotel.bed_state == "standing":
		return _fail("Ce point de reprise nécessite de s’installer sur le lit.")
	if not _is_integer(hotel.get("morning_stage"), 0, 9):
		return _fail("L’étape de la matinée est invalide.")
	var stage := int(hotel.morning_stage)
	if (stage > 0) != (hotel.bed_state == "rested"):
		return _fail("La matinée commence seulement après la nuit passée.")
	if not hotel.get("coffee_connections") is Dictionary or hotel.coffee_connections.size() > COFFEE_WIRES.size():
		return _fail("Les connexions de la machine à café sont invalides.")
	for terminal in hotel.coffee_connections:
		if not terminal is String or not COFFEE_WIRES.has(terminal) or not hotel.coffee_connections[terminal] is String or hotel.coffee_connections[terminal] != COFFEE_WIRES[terminal]:
			return _fail("Un fil de la machine à café est inconnu ou mal raccordé.")
	var connections: int = hotel.coffee_connections.size()
	if (stage < 3 and connections != 0) or (stage == 3 and connections == 3) or (stage >= 4 and connections != 3):
		return _fail("La réparation de la machine ne correspond pas à l’étape de la matinée.")
	if stage >= 2 and "hotel_ground_floor" not in rewarded:
		return _fail("L’arrivée au rez-de-chaussée doit posséder son reçu de récompense.")
	if stage >= 6 and "hotel_backpack" not in rewarded:
		return _fail("Le sac récupéré doit posséder son reçu de récompense.")
	if progress.room_id == "hotel_breakfast" and stage < 2:
		return _fail("Rejoignez d’abord le rez-de-chaussée pour prendre le petit déjeuner.")
	if progress.checkpoint_id == "hall_breakfast" and stage < 2:
		return _fail("Ce retour de la salle de petit déjeuner est encore inaccessible.")
	if progress.checkpoint_id == "breakfast_table" and stage < 3:
		return _fail("Le joueur n’est pas encore installé à sa table.")
	if progress.room_id == "ctf_bus_stop" and stage < 7:
		return _fail("Prenez le bus avec votre sac pour rejoindre le CTF.")
	if progress.room_id == "ctf_lobby" and stage < 8:
		return _fail("Entrez par la porte du bâtiment Sudo Hack.")
	if (stage == 7 and progress.room_id != "ctf_bus_stop") or (stage == 8 and progress.room_id not in ["ctf_bus_stop", "ctf_lobby"]):
		return _fail("Le voyage vers le CTF doit conserver son lieu d’arrivée.")
	return _ok()

func _validate_ctf_progress(progress: Dictionary, rewarded: Array) -> Dictionary:
	var ctf: Variant = progress.get("ctf", CtfCatalog.empty_state())
	if not ctf is Dictionary or ctf.size() != 2 or not _is_integer(ctf.get("version"), 1, 1) or not _valid_id_list(ctf.get("completed"), CtfCatalog.IDS):
		return _fail("La progression du CTF est invalide.")
	var done: Array = ctf.completed
	if done != CtfCatalog.IDS.slice(0, done.size()):
		return _fail("Les épreuves Sudo Hack doivent être validées dans l'ordre.")
	for id in done:
		if "ctf_" + str(id) not in rewarded:
			return _fail("Une réussite Sudo Hack ne possède pas son reçu de récompense.")
	if not done.is_empty() and (not progress.started or int(progress.hotel.morning_stage) < 6):
		return _fail("Le CTF commence après la récupération du sac.")
	if int(progress.hotel.morning_stage) == 9 and done != CtfCatalog.IDS:
		return _fail("Terminez les cinq épreuves avant de revenir en ville.")
	return _ok()

func validate_profile(value: Variant, expected_id: String = "") -> Dictionary:
	var definitions := _ensure_definitions()
	if not definitions.ok:
		return definitions
	if not value is Dictionary:
		return _fail("Le profil doit être un objet JSON.")
	var document: Dictionary = value.duplicate(true)
	if not _is_integer(document.get("schema_version"), 1, 2147483647):
		return _fail("Version de sauvegarde absente ou invalide.")
	if int(document.schema_version) != SCHEMA_VERSION:
		return _fail("Version de sauvegarde inconnue (%s). Le fichier est conservé." % document.schema_version)
	if not document.get("id") is String or not is_safe_id(document.id) or (not expected_id.is_empty() and document.id != expected_id):
		return _fail("Identifiant interne du profil invalide.")
	var name := validate_display_name(document.get("display_name"))
	if not name.ok:
		return name
	if document.display_name != name.data:
		return _fail("Le pseudo enregistré contient des espaces extérieurs.")
	if document.has("role") and (not document.role is String or document.role not in ["player", "super_admin"]):
		return _fail("Le rôle du profil est invalide.")
	if document.get("role", "player") == "super_admin" and (document.id != DEV_PROFILE_ID or document.display_name != DEV_PROFILE_NAME):
		return _fail("Le rôle super administrateur appartient au profil Dev dédié.")
	if document.id == DEV_PROFILE_ID and document.get("role", "player") != "super_admin":
		return _fail("Le profil Dev dédié doit conserver son rôle super administrateur.")
	# Champ facultatif du schéma 1 : une image absente n'invalide jamais le profil.
	# L'avatar du catalogue reste l'équipement possédé et sert de repli visuel.
	if document.has("avatar_image") and (not document.avatar_image is String or (not document.avatar_image.is_empty() and not LocalAvatarLibrary.is_safe_filename(document.avatar_image))):
		return _fail("Le nom de l'image de profil locale est invalide.")
	if not document.get("wallet") is Dictionary or not _is_integer(document.wallet.get("points"), 0, MAX_POINTS):
		return _fail("Le solde du profil est invalide.")
	# This optional extension leaves untouched older profiles unchanged.
	if document.has("penalties") and not PenaltyService.validate_record(document.penalties):
		return _fail("Le compteur ou la dette de pénalités est invalide.")
	if not document.get("owned_items") is Array or not document.get("equipped") is Dictionary:
		return _fail("L'inventaire ou l'équipement du profil est invalide.")
	var owned: Array = []
	for id in document.owned_items:
		if not id is String or not _catalog_by_id.has(id) or id in owned:
			return _fail("L'inventaire contient un article inconnu ou dupliqué.")
		owned.append(id)
	for id in DEFAULT_ITEMS:
		if id not in owned:
			return _fail("L'inventaire ne contient pas tous les articles gratuits.")
	for type in ["avatar", "theme", "frame"]:
		var equipped_id: Variant = document.equipped.get(type)
		if not equipped_id is String or equipped_id not in owned or _catalog_by_id[equipped_id].type != type:
			return _fail("L'équipement %s est invalide ou non possédé." % type)
	# Les jeux appartiennent à la bibliothèque, jamais aux emplacements cosmétiques.
	if document.equipped.has("game"):
		return _fail("Un jeu se lance depuis la bibliothèque ; il ne peut pas être équipé.")
	if not document.get("rewarded_missions") is Array:
		return _fail("La liste des récompenses est invalide.")
	var rewarded: Array = []
	for id in document.rewarded_missions:
		if not id is String or id not in _mission_ids + HOTEL_REWARD_IDS + CtfCatalog.REWARD_IDS or id in rewarded:
			return _fail("La liste des récompenses contient une mission inconnue ou dupliquée.")
		rewarded.append(id)
	if not document.get("progress") is Dictionary:
		return _fail("La progression est invalide.")
	var progress: Dictionary = document.progress
	var allowed_rooms := ["room_01", "room_02", "room_03", "room_04", "room_05", "maze_05", "courtyard"] + HOTEL_ROOMS
	var allowed_checkpoints := ["entrance", "elevator", "exit", "maze_entry", "maze_terminal", "building_exit", "from_first", "from_second"] + HOTEL_CHECKPOINTS.keys() + MISSION_IDS
	if not progress.get("started") is bool or not progress.get("room_id") is String or progress.room_id not in allowed_rooms or progress.get("checkpoint_id") not in allowed_checkpoints or not progress.get("completed_missions") is Array:
		return _fail("La progression contient une scène ou un point de reprise invalide.")
	var completed: Array = []
	for id in progress.completed_missions:
		if not id is String or id not in _mission_ids or id in completed or id not in rewarded:
			return _fail("Les objectifs terminés sont incohérents avec les récompenses.")
		completed.append(id)
	if not progress.started and not completed.is_empty():
		return _fail("Une enquête non commencée ne peut avoir d'objectifs terminés.")
	# Les documents du prototype sont d'abord validés intégralement ci-dessus.
	# Leur progression simulée n'est pas présentée comme la résolution des vrais défis.
	var migrated := not progress.has("investigation_version")
	var expanded := false
	if migrated:
		# Seul le schéma connu du prototype peut être remis au début.
		# Une version absente dans une progression enrichie signale une corruption.
		if progress.room_id != "room_01" or progress.checkpoint_id not in ["entrance", "lighting", "lock", "computer", "exit"] or not _valid_id_list(completed, CHAPTER_ONE_IDS) or not _valid_id_list(rewarded, CHAPTER_ONE_IDS):
			return _fail("La progression du prototype contient un chapitre inconnu. Le fichier est conservé.")
		var legacy_keys := ["started", "room_id", "checkpoint_id", "completed_missions"]
		for key in progress:
			if key not in legacy_keys:
				return _fail("Version d’enquête absente dans une progression récente ou inconnue. Le fichier est conservé ; choisissez une récupération.")
		var migrated_progress := empty_investigation_progress()
		migrated_progress.started = progress.started
		migrated_progress.legacy_migration_notice = true
		document.progress = migrated_progress
		progress = document.progress
	else:
		if not _is_integer(progress.get("investigation_version"), INVESTIGATION_VERSION, INVESTIGATION_VERSION):
			return _fail("Version de progression d'enquête inconnue. Le fichier est conservé.")
		# Les versions précédentes ont déjà de vrais défis : enrichir sans remise à zéro.
		# Reconnaître uniquement les ensembles complets des quatre anciennes versions.
		var legacy_ids: Array = []
		if progress.get("observations") is Dictionary:
			var saved_ids: Array = progress.observations.keys()
			if saved_ids.size() == CHAPTER_ONE_IDS.size() and _valid_id_list(saved_ids, CHAPTER_ONE_IDS):
				legacy_ids = CHAPTER_ONE_IDS.duplicate()
			elif saved_ids.size() == CHAPTER_ONE_IDS.size() + CHAPTER_TWO_IDS.size() and _valid_id_list(saved_ids, CHAPTER_ONE_IDS + CHAPTER_TWO_IDS):
				legacy_ids = (CHAPTER_ONE_IDS + CHAPTER_TWO_IDS).duplicate()
			elif saved_ids.size() == 9 and _valid_id_list(saved_ids, CHAPTER_ONE_IDS + CHAPTER_TWO_IDS + CHAPTER_THREE_IDS):
				legacy_ids = (CHAPTER_ONE_IDS + CHAPTER_TWO_IDS + CHAPTER_THREE_IDS).duplicate()
			elif saved_ids.size() == 12 and _valid_id_list(saved_ids, CHAPTER_ONE_IDS + CHAPTER_TWO_IDS + CHAPTER_THREE_IDS + CHAPTER_FOUR_IDS):
				legacy_ids = (CHAPTER_ONE_IDS + CHAPTER_TWO_IDS + CHAPTER_THREE_IDS + CHAPTER_FOUR_IDS).duplicate()
		if not legacy_ids.is_empty():
			var legacy_rooms: Array = ["room_01", "room_02", "room_03", "room_04"].slice(0, legacy_ids.size() / 3)
			if not _valid_id_list(completed, legacy_ids) or not _valid_id_list(rewarded, legacy_ids) or progress.room_id not in legacy_rooms or progress.get("active_mission", "") not in [""] + legacy_ids or progress.checkpoint_id not in ["entrance", "elevator", "exit"] + legacy_ids:
				return _fail("La progression ancienne contient un chapitre non pris en charge par sa version. Le fichier est conservé.")
			for id in MISSION_IDS:
				if id not in legacy_ids:
					progress.observations[id] = []
			expanded = true
		if not progress.get("active_mission") is String or (not progress.active_mission.is_empty() and (progress.active_mission not in _mission_ids or progress.active_mission in completed)):
			return _fail("La mission en cours est invalide.")
		if not progress.get("legacy_migration_notice") is bool:
			return _fail("L'information de migration est invalide.")
		var expected_clues: Array = []
		var possible_run_rewards: Array = [0]
		for id in completed:
			for prerequisite in _mission_by_id[id].prerequisites:
				if prerequisite not in completed:
					return _fail("Une mission terminée ne possède pas ses prérequis.")
			expected_clues.append(_mission_by_id[id].clue.id)
			var previous_sums: Array = possible_run_rewards.duplicate()
			for subtotal in previous_sums:
				possible_run_rewards.append(int(subtotal) + int(_mission_by_id[id].reward))
		if not _valid_id_list(progress.get("clues"), expected_clues) or progress.clues.size() != expected_clues.size():
			return _fail("Les indices collectés ne correspondent pas aux missions terminées.")
		if not _is_integer(progress.get("run_reward_points"), 0, MAX_POINTS) or int(progress.run_reward_points) not in possible_run_rewards:
			return _fail("Les points gagnés pendant cette enquête sont incohérents.")
		if not progress.get("observations") is Dictionary or progress.observations.keys().size() != _mission_ids.size():
			return _fail("Les observations enregistrées sont invalides.")
		for id in _mission_ids:
			var observation_ids := _option_ids(_mission_by_id[id], "observations")
			if not _valid_id_list(progress.observations.get(id), observation_ids):
				return _fail("Une observation enregistrée est inconnue ou dupliquée.")
			if id in completed and progress.observations[id].size() != observation_ids.size():
				return _fail("Une mission terminée n'a pas toutes ses observations.")
			if not progress.observations[id].is_empty():
				for prerequisite in _mission_by_id[id].prerequisites:
					if prerequisite not in completed:
						return _fail("Des observations ont été enregistrées avant leur prérequis.")
		if not progress.get("checks") is Dictionary or progress.checks.keys() != ["computer"] or not _valid_id_list(progress.checks.get("computer"), _option_ids(_mission_by_id.computer, "checks")):
			return _fail("Les vérifications enregistrées sont invalides.")
		if not progress.checks.computer.is_empty() and ("lock" not in completed or progress.observations.computer.size() != _option_ids(_mission_by_id.computer, "observations").size()):
			return _fail("Des vérifications ont été enregistrées avant les observations requises.")
		if "computer" in completed:
			for check_id in _mission_by_id.computer.solution.checks:
				if check_id not in progress.checks.computer:
					return _fail("L'ordinateur terminé n'a pas ses vérifications requises.")
		if not progress.active_mission.is_empty():
			if _mission_by_id[progress.active_mission].room_id != progress.room_id:
				return _fail("La mission en cours appartient à un autre étage.")
			for prerequisite in _mission_by_id[progress.active_mission].prerequisites:
				if prerequisite not in completed:
					return _fail("La mission en cours est encore verrouillée.")
		var chapter_one_complete := true
		for id in CHAPTER_ONE_IDS:
			chapter_one_complete = chapter_one_complete and id in completed
		var chapter_two_complete := chapter_one_complete
		for id in CHAPTER_TWO_IDS:
			chapter_two_complete = chapter_two_complete and id in completed
		var chapter_three_complete := chapter_two_complete
		for id in CHAPTER_THREE_IDS:
			chapter_three_complete = chapter_three_complete and id in completed
		var chapter_four_complete := chapter_three_complete
		for id in CHAPTER_FOUR_IDS:
			chapter_four_complete = chapter_four_complete and id in completed
		# Travel adds no mission, reward or schema reset. Only a completed mystery
		# permits crossing the two buildings; checkpoints belong to one zone.
		var travel_checkpoints := {"building_exit": "room_01", "from_first": "courtyard", "from_second": "courtyard", "new_entrance": "building_02"}
		travel_checkpoints.merge(HOTEL_CHECKPOINTS)
		if progress.room_id in ["courtyard"] + HOTEL_ROOMS or progress.checkpoint_id in travel_checkpoints:
			if not progress.started or not chapter_four_complete or "maze" not in completed:
				return _fail("Terminez le chapitre 5 avant de quitter le premier bâtiment.")
			if travel_checkpoints.get(progress.checkpoint_id, "") != progress.room_id or not progress.active_mission.is_empty():
				return _fail("Ce point de passage appartient à une autre zone.")
		if progress.room_id in ["room_05", "maze_05"] and (not progress.started or not chapter_four_complete):
			return _fail("Ce chapitre nécessite les douze missions précédentes.")
		if progress.room_id == "room_05" and progress.checkpoint_id != "elevator":
			return _fail("Le palier du cinquième chapitre possède un point de reprise ascenseur.")
		if progress.room_id == "maze_05" and progress.checkpoint_id not in ["maze_entry", "maze_terminal", "maze", "exit"]:
			return _fail("Point de reprise inconnu dans le labyrinthe.")
		if progress.checkpoint_id in ["maze_entry", "maze_terminal"] and progress.room_id != "maze_05":
			return _fail("Ce point de reprise appartient au labyrinthe.")
		if progress.checkpoint_id == "maze_terminal" and "login" not in progress.observations.maze:
			return _fail("Le terminal n’a pas encore de session ouverte.")
		if progress.room_id == "room_04" and (not progress.started or not chapter_three_complete or progress.checkpoint_id == "entrance"):
			return _fail("Le laboratoire réseau nécessite les neuf missions des chapitres précédents.")
		if progress.room_id == "room_02" and (not progress.started or not chapter_one_complete or progress.checkpoint_id == "entrance"):
			return _fail("L’étage réseau n’est pas accessible avant les trois objectifs du premier chapitre.")
		if progress.room_id == "room_03" and (not progress.started or not chapter_two_complete or progress.checkpoint_id == "entrance"):
			return _fail("L’atelier code n’est pas accessible avant les trois objectifs de l’étage réseau.")
		if progress.checkpoint_id == "elevator" and not chapter_one_complete:
			return _fail("L’ascenseur reste verrouillé avant les trois objectifs du premier chapitre.")
		if progress.checkpoint_id in _mission_ids and (progress.checkpoint_id not in completed or _mission_by_id[progress.checkpoint_id].room_id != progress.room_id):
			return _fail("Le point de reprise correspond à une mission non terminée ou à un autre étage.")
		if progress.checkpoint_id == "exit":
			var chapter_ids: Array = CHAPTER_ONE_IDS if progress.room_id == "room_01" else (CHAPTER_TWO_IDS if progress.room_id == "room_02" else (CHAPTER_THREE_IDS if progress.room_id == "room_03" else (CHAPTER_FOUR_IDS if progress.room_id == "room_04" else CHAPTER_FIVE_IDS)))
			for id in chapter_ids:
				if id not in completed:
					return _fail("La conclusion de ce chapitre n’est pas encore accessible.")
		if not progress.started and (progress.room_id != "room_01" or progress.checkpoint_id != "entrance"):
			return _fail("Une enquête non commencée contient un point de reprise actif.")
		if not progress.started and (not progress.active_mission.is_empty() or not progress.clues.is_empty() or int(progress.run_reward_points) != 0 or not progress.checks.computer.is_empty()):
			return _fail("Une enquête non commencée contient un état de partie active.")
		if not progress.started:
			for id in _mission_ids:
				if not progress.observations[id].is_empty():
					return _fail("Une enquête non commencée contient des observations.")
	# Only the complete, otherwise valid pre-hotel document is extended. A new
	# room without its hotel state is corrupt, rather than a legacy migration.
	if not progress.has("hotel"):
		if progress.room_id in HOTEL_ROOMS.slice(1) or (progress.checkpoint_id in HOTEL_CHECKPOINTS and progress.checkpoint_id != "new_entrance"):
			return _fail("La sauvegarde de cette salle ne contient pas son état d’hôtel.")
		progress["hotel"] = empty_hotel_progress()
		expanded = true
	# L’ancien séjour 0.11.0 possède exactement six champs. Une extension
	# partielle n’est jamais traitée comme une ancienne sauvegarde valide.
	if progress.hotel is Dictionary and _is_integer(progress.hotel.get("version"), 1, 1):
		var legacy_keys := ["version", "reserved", "repair_observations", "repaired", "luggage_placed", "bed_state"]
		if progress.hotel.size() != legacy_keys.size() or not _valid_id_list(progress.hotel.keys(), legacy_keys) or not progress.hotel.get("bed_state") is String:
			return _fail("L’ancienne progression de l’hôtel est partielle ou inconnue.")
		if progress.room_id in ["hotel_breakfast", "ctf_bus_stop", "ctf_lobby"] or progress.checkpoint_id in ["hall_breakfast", "breakfast_entry", "breakfast_table", "ctf_arrival", "ctf_door", "ctf_entry"]:
			return _fail("Une ancienne sauvegarde ne peut contenir une étape de la matinée.")
		progress.hotel.version = HOTEL_VERSION
		progress.hotel["morning_stage"] = 1 if progress.hotel.get("bed_state") == "rested" else 0
		progress.hotel["coffee_connections"] = {}
		expanded = true
	var hotel_validation := _validate_hotel_progress(progress, completed, rewarded)
	if not hotel_validation.ok:
		return hotel_validation
	var ctf_validation := _validate_ctf_progress(progress, rewarded)
	if not ctf_validation.ok: return ctf_validation
	if progress.has("ctf"): progress.ctf.version = 1
	progress.hotel.version = HOTEL_VERSION
	progress.hotel.morning_stage = int(progress.hotel.morning_stage)
	document.schema_version = SCHEMA_VERSION
	document.wallet.points = int(document.wallet.points)
	if document.has("penalties"):
		for field in ["version", "count", "debt", "paid"]: document.penalties[field] = int(document.penalties[field])
	document.progress.investigation_version = INVESTIGATION_VERSION
	document.progress.run_reward_points = int(document.progress.run_reward_points)
	var response := _ok(document)
	response["migration_required"] = migrated or expanded
	response["migration_notice"] = LEGACY_MIGRATION_NOTICE if document.progress.legacy_migration_notice else ""
	return response

func _ensure_directory(path: String) -> Dictionary:
	var candidate := ProjectSettings.globalize_path(path)
	while not candidate.is_empty():
		if FileAccess.file_exists(candidate):
			return _storage_fail("Un fichier occupe le chemin du dossier de sauvegarde : " + candidate)
		var parent := candidate.get_base_dir()
		if parent == candidate: break
		candidate = parent
	var code := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	if code != OK:
		return _storage_fail("Impossible de préparer le dossier de sauvegarde (code %s)." % code)
	return _ok()

func _rename(source: String, target: String) -> Error:
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(source), ProjectSettings.globalize_path(target))

func _remove(path: String) -> Error:
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func atomic_write_text(path: String, content: String) -> Dictionary:
	if simulate_write_failure:
		return _storage_fail("Échec d'écriture simulé pour les tests.")
	var ready := _ensure_directory(path.get_base_dir())
	if not ready.ok:
		return ready
	var temporary := path + ".tmp"
	var backup := path + ".bak"
	var previous := path + ".bak.previous"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _storage_fail("Impossible d'écrire la sauvegarde temporaire (code %s)." % FileAccess.get_open_error())
	file.store_string(content)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK or FileAccess.get_file_as_string(temporary) != content:
		_remove(temporary)
		return _storage_fail("La vérification de la sauvegarde temporaire a échoué.")
	var had_main := FileAccess.file_exists(path)
	var had_backup := FileAccess.file_exists(backup)
	if had_main and had_backup:
		if FileAccess.file_exists(previous) and _remove(previous) != OK:
			_remove(temporary)
			return _storage_fail("Impossible de préparer la rotation des sauvegardes.")
		if _rename(backup, previous) != OK:
			_remove(temporary)
			return _storage_fail("Impossible de conserver la sauvegarde précédente.")
	if had_main and _rename(path, backup) != OK:
		if had_backup:
			_rename(previous, backup)
		_remove(temporary)
		return _storage_fail("Impossible de préparer le remplacement du document.")
	if _rename(temporary, path) != OK:
		var rollback_ok := true
		if had_main:
			rollback_ok = _rename(backup, path) == OK
		# Ne jamais remplacer une .bak encore nécessaire si le retour au principal échoue.
		if had_main and had_backup and rollback_ok:
			_rename(previous, backup)
		_remove(temporary)
		if not rollback_ok:
			return _storage_fail("Le remplacement et sa restauration ont échoué. Les copies .bak et .bak.previous sont conservées pour récupération.")
		return _storage_fail("Impossible de remplacer la sauvegarde. Le document précédent a été conservé.")
	if had_main and had_backup:
		_remove(previous)
	return _ok()

func write_profile(document: Dictionary) -> Dictionary:
	var validation := validate_profile(document)
	if not validation.ok:
		return validation
	var path := _path("profiles/%s.json" % validation.data.id)
	if not FileAccess.file_exists(path) and FileAccess.file_exists(path + ".bak"):
		return _storage_fail("Le document principal du profil manque. Choisissez la récupération de sa copie précédente avant de sauvegarder.", {"recovery_required": true, "id": validation.data.id})
	# Un fichier altéré après sélection ne doit pas être remplacé silencieusement.
	# Cela conserve aussi une éventuelle .bak valide jusqu'au choix de récupération.
	if FileAccess.file_exists(path):
		var previous := read_profile(validation.data.id)
		if not previous.ok:
			return _storage_fail("Le profil sur disque nécessite une récupération avant sauvegarde : " + previous.error, {"recovery_required": true, "id": validation.data.id})
	var saved := atomic_write_text(path, JSON.stringify(validation.data, "\t"))
	if not saved.ok:
		return saved
	return _ok(validation.data)

func read_profile(id: String) -> Dictionary:
	if not is_safe_id(id):
		return _fail("Identifiant de profil invalide.")
	var path := _path("profiles/%s.json" % id)
	if not FileAccess.file_exists(path):
		return _storage_fail("Le profil est introuvable.")
	var parsed := _parse_json(FileAccess.get_file_as_string(path), path)
	if not parsed.ok:
		return _storage_result(parsed)
	return _storage_result(validate_profile(parsed.data, id))

func list_profiles() -> Dictionary:
	var ready := _ensure_directory(_path("profiles"))
	if not ready.ok:
		return ready
	var directory := DirAccess.open(_path("profiles"))
	if directory == null:
		return _storage_fail("Impossible de lire les profils locaux.")
	var profiles: Array = []
	var issues: Array = []
	var file_names := directory.get_files()
	for file_name in file_names:
		if not file_name.ends_with(".json"):
			continue
		var id: String = file_name.trim_suffix(".json")
		var result := read_profile(id)
		if result.ok:
			profiles.append(result.data)
		else:
			issues.append({"id": id, "path": _path("profiles/" + file_name), "error": result.error, "has_backup": is_safe_id(id) and FileAccess.file_exists(_path("profiles/%s.json.bak" % id))})
	# Une interruption entre les renommages peut laisser uniquement la .bak.
	# La proposer explicitement évite de traiter le joueur comme un premier lancement.
	for file_name in file_names:
		if not file_name.ends_with(".json.bak"):
			continue
		var id: String = file_name.trim_suffix(".json.bak")
		if not FileAccess.file_exists(_path("profiles/%s.json" % id)):
			issues.append({"id": id, "path": _path("profiles/" + file_name), "error": "Le document principal est absent ; une copie précédente a été conservée. Choisissez une récupération.", "has_backup": is_safe_id(id)})
	profiles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.display_name.naturalnocasecmp_to(b.display_name) < 0)
	var response := _ok(profiles)
	response["issues"] = issues
	return response

func write_session(id: String) -> Dictionary:
	if not id.is_empty() and not is_safe_id(id):
		return _fail("Identifiant de session invalide.")
	if id.is_empty() and ((FileAccess.file_exists(_path("session.json")) and not _read_session_document(_path("session.json")).ok) or (not FileAccess.file_exists(_path("session.json")) and FileAccess.file_exists(_path("session.json.bak")))):
		return reset_session()
	if not id.is_empty() and not FileAccess.file_exists(_path("session.json")) and FileAccess.file_exists(_path("session.json.bak")):
		return _storage_fail("Le document principal de session manque. Choisissez une récupération avant de changer de profil.", {"recovery_required": true, "id": ""})
	if not id.is_empty() and FileAccess.file_exists(_path("session.json")):
		var previous := read_session()
		if not previous.ok:
			return _storage_fail("La session nécessite une récupération avant changement de profil : " + previous.error, {"recovery_required": true, "id": ""})
	return atomic_write_text(_path("session.json"), JSON.stringify({"schema_version": SCHEMA_VERSION, "last_profile_id": id}, "\t"))

func _read_session_document(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _fail("Le document de session est absent.")
	var parsed := _parse_json(FileAccess.get_file_as_string(path), path)
	if not parsed.ok:
		return parsed
	if not _is_integer(parsed.data.get("schema_version"), SCHEMA_VERSION, SCHEMA_VERSION) or not parsed.data.get("last_profile_id") is String:
		return _fail("Le document de session est invalide ; les profils sont conservés.")
	var id: String = parsed.data.last_profile_id
	if not id.is_empty() and not is_safe_id(id):
		return _fail("La session contient un identifiant invalide.")
	return _ok(id)

func read_session() -> Dictionary:
	var path := _path("session.json")
	if not FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			return _storage_fail("Le document principal de session manque. Une copie précédente est conservée ; choisissez une récupération.")
		return _ok("")
	return _storage_result(_read_session_document(path))

func session_backup_available() -> bool:
	return _read_session_document(_path("session.json.bak")).ok

func recover_session() -> Dictionary:
	var path := _path("session.json")
	var checked := _read_session_document(path + ".bak")
	if not checked.ok:
		return _storage_fail("Aucune copie précédente valide de la session n'est disponible.")
	return _replace_session_preserving_original(checked.data, false)

func reset_session() -> Dictionary:
	# Choix explicite : oublier le dernier profil, sans toucher aux profils eux-mêmes.
	return _replace_session_preserving_original("", true)

func _replace_session_preserving_original(id: String, archive_backup: bool) -> Dictionary:
	if simulate_write_failure:
		return _storage_fail("Échec d'écriture simulé pour les tests.")
	var path := _path("session.json")
	var marker := ".corrupt_%s_%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	var sources: Array[String] = [path]
	if archive_backup:
		sources.append(path + ".bak")
	var moved: Array[String] = []
	for source in sources:
		if not FileAccess.file_exists(source):
			continue
		if _rename(source, source + marker) != OK:
			for previous in moved:
				_rename(previous + marker, previous)
			return _storage_fail("Impossible de conserver les documents de session avant récupération.")
		moved.append(source)
	var saved := atomic_write_text(path, JSON.stringify({"schema_version": SCHEMA_VERSION, "last_profile_id": id}, "\t"))
	if not saved.ok:
		for source in moved:
			_rename(source + marker, source)
		return saved
	return _ok(id)

func recover_profile(id: String) -> Dictionary:
	if not is_safe_id(id):
		return _fail("Identifiant de profil invalide.")
	var path := _path("profiles/%s.json" % id)
	var backup := path + ".bak"
	if not FileAccess.file_exists(backup):
		return _storage_fail("Aucune sauvegarde précédente n'est disponible.")
	var parsed := _parse_json(FileAccess.get_file_as_string(backup), backup)
	if not parsed.ok:
		return _storage_result(parsed)
	var checked := validate_profile(parsed.data, id)
	if not checked.ok:
		return _storage_result(checked)
	if simulate_write_failure:
		return _storage_fail("Échec d'écriture simulé pour les tests.")
	var quarantine := path + ".corrupt_%s_%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	var had_main := FileAccess.file_exists(path)
	if had_main and _rename(path, quarantine) != OK:
		return _storage_fail("Impossible de mettre le fichier invalide à l'écart.")
	var restored := atomic_write_text(path, JSON.stringify(checked.data, "\t"))
	if not restored.ok:
		if had_main:
			_rename(quarantine, path)
		return restored
	return _ok(checked.data)

func quarantine_profile(id: String) -> Dictionary:
	if not is_safe_id(id):
		return _fail("Identifiant de profil invalide.")
	if simulate_write_failure:
		return _storage_fail("Échec d'écriture simulé pour les tests.")
	var path := _path("profiles/%s.json" % id)
	var candidates: Array[String] = []
	for suffix in ["", ".bak", ".bak.previous", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			candidates.append(path + suffix)
	if candidates.is_empty():
		return _storage_fail("Le fichier à mettre à l'écart est introuvable.")
	var marker := ".corrupt_%s_%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	var moved: Array[String] = []
	for candidate in candidates:
		if _rename(candidate, candidate + marker) != OK:
			for prior in moved:
				_rename(prior + marker, prior)
			return _storage_fail("Impossible de mettre tous les documents du profil à l'écart. Ils sont conservés.")
		moved.append(candidate)
	return _ok(candidates[0] + marker)

func delete_profile(id: String) -> Dictionary:
	if not is_safe_id(id):
		return _fail("Identifiant de profil invalide.")
	if simulate_write_failure:
		return _storage_fail("Échec d'écriture simulé pour les tests.")
	var path := _path("profiles/%s.json" % id)
	if not FileAccess.file_exists(path):
		return _storage_fail("Le profil à supprimer est introuvable.")
	# Les deux documents sont déplacés avant suppression, avec retour possible.
	var paths: Array = []
	var directory := DirAccess.open(path.get_base_dir())
	if directory == null:
		return _storage_fail("Impossible de lire le dossier du profil.")
	var base_name := path.get_file()
	for file_name in directory.get_files():
		if file_name == base_name or file_name.begins_with(base_name + "."):
			paths.append(path.get_base_dir().path_join(file_name))
	var suffix := ".deleting_%s_%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	var moved: Array = []
	for source in paths:
		if _rename(source, source + suffix) != OK:
			for previous_path in moved:
				_rename(previous_path + suffix, previous_path)
			return _storage_fail("Impossible de préparer la suppression. Le profil est conservé.")
		moved.append(source)
	for source in moved:
		if _remove(source + suffix) != OK:
			return _storage_fail("La suppression n'a pas pu terminer. Un document .deleting reste à vérifier.")
	return _ok()
