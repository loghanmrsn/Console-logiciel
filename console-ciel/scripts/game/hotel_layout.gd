extends RefCounted
## Hotel geometry is shared by scenery, collisions, the map and route tests.
## A destination is a saved room, never a reward-bearing investigation chapter.

const CtfCatalog = preload("res://scripts/game/ctf_catalog.gd")
const School = preload("res://scripts/game/school_layout.gd")
const ZONES := ["school_stop", "school_cyber", "building_02", "hotel_it", "hotel_stairs_1", "hotel_floor_2", "hotel_room_206", "hotel_breakfast", "ctf_bus_stop", "ctf_lobby"]
const HALL_SIZE := Vector2(6400, 4200)
const BED_SEAT := Vector2(840, 420)

static func is_zone(zone: String) -> bool:
	return ZONES.has(zone)

static func extent(zone: String) -> Vector2:
	if zone.begins_with("school_"): return School.extent(zone)
	match zone:
		"hotel_it": return Vector2(1400, 900)
		"hotel_stairs_1": return Vector2(1600, 1100)
		"hotel_floor_2": return Vector2(2400, 1300)
		"hotel_room_206": return Vector2(1200, 1000)
		"hotel_breakfast": return Vector2(1600, 1050)
		"ctf_bus_stop", "ctf_lobby": return Vector2(1800, 1300)
		_: return HALL_SIZE

static func title(zone: String) -> String:
	if zone.begins_with("school_"): return School.title(zone)
	match zone:
		"hotel_it": return "Local informatique · rez-de-chaussée"
		"hotel_stairs_1": return "Étage 1 · palier des escaliers"
		"hotel_floor_2": return "Étage 2 · chambres"
		"hotel_room_206": return "Chambre 206"
		"hotel_breakfast": return "Petit déjeuner · rez-de-chaussée"
		"ctf_bus_stop": return "sudo hack · arrêt du bus"
		"ctf_lobby": return "sudo hack · accueil du CTF"
		_: return "Hôtel Ritz · grand hall"

static func checkpoints(zone: String) -> Dictionary:
	if zone.begins_with("school_"): return School.checkpoints(zone)
	match zone:
		"hotel_it": return {"entrance": Vector2(700, 750), "it_entrance": Vector2(700, 750)}
		"hotel_stairs_1": return {"entrance": Vector2(500, 820), "stairs_from_hall": Vector2(500, 820), "stairs_from_floor2": Vector2(1020, 820)}
		"hotel_floor_2": return {"entrance": Vector2(470, 1130), "floor2_stairs": Vector2(470, 1130), "floor2_room206": Vector2(1670, 790)}
		"hotel_room_206": return {"entrance": Vector2(600, 860), "room206_entry": Vector2(600, 860), "room206_bed": Vector2(840, 560)}
		"hotel_breakfast": return {"entrance": Vector2(700, 880), "breakfast_entry": Vector2(700, 880), "breakfast_table": Vector2(690, 580)}
		"ctf_bus_stop": return {"entrance": Vector2(900, 930), "ctf_arrival": Vector2(900, 930), "ctf_door": Vector2(900, 430)}
		"ctf_lobby": return {"entrance": Vector2(900, 1100), "ctf_entry": Vector2(900, 1100)}
		_: return {"entrance": Vector2(3200, 4000), "new_entrance": Vector2(3200, 4000), "hall_it": Vector2(2390, 3500), "hall_stairs": Vector2(4040, 3710), "hall_breakfast": Vector2(4660, 3500)}

static func interactions(zone: String) -> Array[Dictionary]:
	if zone.begins_with("school_"): return School.interactions(zone)
	match zone:
		"hotel_it": return [
			_target("hotel_it_return", "Porte · retour à la réception", Vector2(700, 800), 90),
			_target("hotel_repair", "Poste de maintenance informatique", Vector2(800, 460), 95)]
		"hotel_stairs_1": return [
			_target("hotel_stairs_down", "Escalier · descendre au hall", Vector2(500, 700), 90),
			_target("hotel_stairs_up", "Escalier · monter à l’étage 2", Vector2(1020, 700), 90)]
		"hotel_floor_2": return [
			_target("hotel_stairs_down", "Escalier · descendre au palier", Vector2(470, 1020), 90),
			_target("hotel_room206", "Chambre 206 · ouvrir avec la carte", Vector2(1670, 720), 90)]
		"hotel_room_206": return [
			_target("hotel_room206_exit", "Porte · retour dans le couloir", Vector2(600, 900), 85),
			_target("hotel_luggage", "Porte-bagages · poser ses affaires", Vector2(300, 730), 90),
			_target("hotel_bed", "Lit · se reposer", Vector2(840, 560), 90),
			_target("hotel_backpack", "Sac à dos · ordinateur pour sudo hack", Vector2(300, 730), 90)]
		"hotel_breakfast": return [
			_target("hotel_breakfast_return", "Porte · retour au hall", Vector2(700, 930), 85),
			_target("hotel_breakfast_table", "Petit déjeuner · s’asseoir à la table", Vector2(690, 580), 85),
			_target("hotel_coffee_machine", "Machine à café · panneau de connexion", Vector2(1250, 310), 85)]
		"ctf_bus_stop": return [_target("ctf_enter", "sudo hack · entrer dans le bâtiment du CTF", Vector2(900, 360), 90), _target("ctf_return_bus", "Arrêt de bus · retour en ville", Vector2(1390, 785), 90)]
		"ctf_lobby":
			var targets: Array[Dictionary] = [_target("ctf_leave", "Porte · retour à l’arrêt du bus", Vector2(900, 1150), 90)]
			for index in range(5):
				var id: String = CtfCatalog.IDS[index]
				targets.append(_target("ctf_" + id, str(CtfCatalog.CHALLENGES[id].title), ctf_desk(index).get_center() + Vector2(0, 150), 90))
			return targets
		_: return [
			_target("campus_leave", "Porte · retour dans la cour", Vector2(3200, 4050), 100),
			_target("hotel_reception", "Réception · réservation de chambre", Vector2(3200, 3610), 110),
			_target("hotel_it_door", "Local informatique · porte de service", Vector2(2290, 3500), 95),
			_target("hotel_stairs_up", "Escalier · monter au premier palier", Vector2(4040, 3610), 100),
			_target("hotel_breakfast_door", "Porte · salle du petit déjeuner", Vector2(4580, 3500), 95)]

static func _target(id: String, label: String, at: Vector2, radius: float) -> Dictionary:
	return {"id": id, "label": label, "at": at, "radius": radius}

static func walls(zone: String) -> Array[Rect2]:
	if zone.begins_with("school_"): return School.walls(zone)
	var size := extent(zone)
	var result: Array[Rect2] = [
		Rect2(40, 40, size.x - 80, 24), Rect2(40, size.y - 64, size.x - 80, 24),
		Rect2(40, 64, 24, size.y - 128), Rect2(size.x - 64, 64, 24, size.y - 128)]
	match zone:
		"building_02":
			# The adjoining maintenance room has one clear door on the hall side.
			result.append_array([Rect2(1450, 2800, 800, 24), Rect2(1450, 2800, 24, 920), Rect2(1450, 3696, 800, 24), Rect2(2226, 2824, 24, 550), Rect2(2226, 3626, 24, 70)])
			# The restaurant has an adjoining foyer with a broad, visible west door.
			result.append_array([Rect2(4626, 2800, 1500, 24), Rect2(6102, 2800, 24, 920), Rect2(4626, 3696, 1500, 24), Rect2(4626, 2824, 24, 550), Rect2(4626, 3626, 24, 70)])
			# Open colonnades frame four quiet lounges without closing the galleries.
			for x in [1850, 4500]:
				for y in [550, 2000]: result.append(Rect2(x, y, 28, 900))
		"ctf_bus_stop":
			result.append(Rect2(100, 80, 1600, 250))
		"hotel_stairs_1":
			# The first floor is a landing only. A solid partition and grille keep
			# the rest of this floor inaccessible, even when walking around stairs.
			result.append(Rect2(64, 64, 1472, 136))
		"hotel_floor_2":
			# Rooms 201–208 are represented by a continuous, closed facade.
			# Room 206 alone opens through an explicit saved-room transition.
			result.append(Rect2(64, 64, 2272, 596))
	return result

static func furniture(zone: String) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for spec in furniture_specs(zone):
		result.append(footprint(spec))
	return result

## Ground contact is distinct from leaves, lamps and shadows above the floor.
static func footprint(spec: Dictionary) -> Rect2:
	var rect: Rect2 = spec.rect
	if spec.kind == "planter": return Rect2(rect.get_center() - Vector2(24, 6), Vector2(48, 42))
	return rect

static func chair_rect(table: Rect2) -> Rect2:
	return Rect2(table.get_center().x - 36, table.end.y + 22, 72, 28)

static func furniture_specs(zone: String) -> Array[Dictionary]:
	if zone.begins_with("school_"): return School.furniture_specs(zone)
	var result: Array[Dictionary] = []
	match zone:
		"building_02":
			result.append_array([
				_prop("reception", Rect2(2860, 3420, 680, 130)),
				_prop("fountain", Rect2(3040, 2430, 320, 320)),
				_prop("stairs_up", Rect2(3920, 3140, 240, 320)),
				_prop("stairs_down", Rect2(4220, 3140, 240, 320))])
			for x in [2600, 3700]:
				for y in [3040, 3820]: result.append(_prop("planter", Rect2(x - 45, y - 45, 90, 90)))
			for x in [580, 4800]:
				for y in [980, 2150]:
					result.append(_prop("sofa", Rect2(x, y, 620, 120)))
					result.append(_prop("coffee", Rect2(x + 200, y + 230, 220, 110)))
					result.append(_prop("armchair", Rect2(x, y + 440, 180, 160)))
					result.append(_prop("armchair", Rect2(x + 440, y + 440, 180, 160)))
			for x in [2250, 4150]:
				for y in [800, 1500, 2200]: result.append(_prop("column", Rect2(x - 52, y - 52, 104, 104)))
		"hotel_breakfast":
			result.append_array([_prop("breakfast_table", Rect2(550, 350, 280, 150)), _prop("breakfast_table", Rect2(190, 350, 230, 150)), _prop("breakfast_table", Rect2(960, 640, 270, 150)), _prop("buffet", Rect2(160, 130, 700, 100)), _prop("coffee_machine", Rect2(1150, 180, 200, 100)), _prop("planter", Rect2(1380, 760, 90, 90))])
			result.append(_prop("cup_station", Rect2(960, 180, 145, 100)))
		"ctf_bus_stop":
			result.append_array([_prop("bus_shelter", Rect2(1240, 560, 300, 160)), _prop("planter", Rect2(270, 520, 90, 90)), _prop("planter", Rect2(270, 790, 90, 90))])
		"ctf_lobby":
			for index in range(5): result.append(_prop("ctf_desk", ctf_desk(index)))
			result.append_array([_prop("ctf_reception", Rect2(700, 260, 400, 140)), _prop("sofa", Rect2(200, 980, 350, 120)), _prop("sofa", Rect2(1250, 980, 350, 120)), _prop("planter", Rect2(260, 360, 90, 90)), _prop("planter", Rect2(1450, 360, 90, 90))])
		"hotel_it":
			result.append_array([_prop("server", Rect2(200, 180, 180, 250)), _prop("server", Rect2(440, 180, 180, 250)), _prop("repair", Rect2(690, 260, 220, 120)), _prop("storage", Rect2(1080, 180, 150, 360))])
			result.append_array([_prop("ups", Rect2(160, 550, 110, 116)), _prop("maintenance_cart", Rect2(990, 610, 180, 86))])
		"hotel_stairs_1":
			result.append_array([_prop("stairs_down", Rect2(380, 270, 240, 350)), _prop("stairs_up", Rect2(900, 270, 240, 350)), _prop("planter", Rect2(180, 840, 90, 90)), _prop("planter", Rect2(1300, 840, 90, 90))])
		"hotel_floor_2":
			result.append_array([_prop("stairs_down", Rect2(350, 700, 240, 250)), _prop("planter", Rect2(2110, 910, 90, 90)), _prop("sofa", Rect2(1850, 1090, 380, 100))])
		"hotel_room_206":
			result.append_array([_prop("bed", Rect2(730, 240, 260, 260)), _prop("nightstand", Rect2(660, 265, 58, 75)), _prop("nightstand", Rect2(1002, 265, 58, 75)), _prop("luggage", Rect2(200, 600, 210, 80)), _prop("desk", Rect2(160, 180, 260, 100)), _prop("armchair", Rect2(260, 360, 150, 140)), _prop("storage", Rect2(92, 770, 250, 70)), _prop("planter", Rect2(1020, 750, 80, 80))])
	for spec in result.duplicate():
		if spec.kind == "breakfast_table": result.append(_prop("breakfast_chair", chair_rect(spec.rect)))
	return result

static func _prop(kind: String, rect: Rect2) -> Dictionary:
	return {"kind": kind, "rect": rect}

static func rooms(zone: String) -> Array[Rect2]:
	if zone.begins_with("school_"): return School.rooms(zone)
	match zone:
		"building_02": return [Rect2(2200, 2820, 2100, 1290), Rect2(2200, 550, 2000, 2250), Rect2(300, 650, 1500, 1900), Rect2(4600, 650, 1500, 1900), Rect2(1450, 2800, 800, 920), Rect2(3850, 3000, 650, 720)]
		"hotel_it": return [Rect2(80, 80, 1240, 740)]
		"hotel_stairs_1": return [Rect2(80, 215, 1440, 785)]
		"hotel_floor_2": return [Rect2(80, 675, 2240, 540)]
		"hotel_room_206": return [Rect2(80, 80, 1040, 840)]
		"hotel_breakfast": return [Rect2(80, 80, 1440, 890)]
		"ctf_bus_stop": return [Rect2(100, 350, 1600, 850)]
		"ctf_lobby": return [Rect2(80, 80, 1640, 1140)]
	return []

static func ctf_desk(index: int) -> Rect2:
	var centers := [Vector2(360, 490), Vector2(900, 490), Vector2(1440, 490), Vector2(570, 820), Vector2(1230, 820)]
	return Rect2(centers[index] - Vector2(150, 55), Vector2(300, 110))
