extends RefCounted
## Hotel geometry is shared by scenery, collisions, the map and route tests.
## A destination is a saved room, never a reward-bearing investigation chapter.

const ZONES := ["building_02", "hotel_it", "hotel_stairs_1", "hotel_floor_2", "hotel_room_206"]
const HALL_SIZE := Vector2(6400, 4200)
const BED_SEAT := Vector2(840, 420)

static func is_zone(zone: String) -> bool:
	return ZONES.has(zone)

static func extent(zone: String) -> Vector2:
	match zone:
		"hotel_it": return Vector2(1400, 900)
		"hotel_stairs_1": return Vector2(1600, 1100)
		"hotel_floor_2": return Vector2(2400, 1300)
		"hotel_room_206": return Vector2(1200, 1000)
		_: return HALL_SIZE

static func title(zone: String) -> String:
	match zone:
		"hotel_it": return "Local informatique · rez-de-chaussée"
		"hotel_stairs_1": return "Étage 1 · palier des escaliers"
		"hotel_floor_2": return "Étage 2 · chambres"
		"hotel_room_206": return "Chambre 206"
		_: return "Hôtel CIEL · grand hall"

static func checkpoints(zone: String) -> Dictionary:
	match zone:
		"hotel_it": return {"entrance": Vector2(700, 750), "it_entrance": Vector2(700, 750)}
		"hotel_stairs_1": return {"entrance": Vector2(500, 820), "stairs_from_hall": Vector2(500, 820), "stairs_from_floor2": Vector2(1020, 820)}
		"hotel_floor_2": return {"entrance": Vector2(470, 1130), "floor2_stairs": Vector2(470, 1130), "floor2_room206": Vector2(1670, 790)}
		"hotel_room_206": return {"entrance": Vector2(600, 860), "room206_entry": Vector2(600, 860), "room206_bed": Vector2(840, 560)}
		_: return {"entrance": Vector2(3200, 4000), "new_entrance": Vector2(3200, 4000), "hall_it": Vector2(2390, 3500), "hall_stairs": Vector2(4040, 3710)}

static func interactions(zone: String) -> Array[Dictionary]:
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
			_target("hotel_bed", "Lit · se reposer", Vector2(840, 560), 90)]
		_: return [
			_target("campus_leave", "Porte · retour dans la cour", Vector2(3200, 4050), 100),
			_target("hotel_reception", "Réception · réservation de chambre", Vector2(3200, 3610), 110),
			_target("hotel_it_door", "Local informatique · porte de service", Vector2(2290, 3500), 95),
			_target("hotel_stairs_up", "Escalier · monter au premier palier", Vector2(4040, 3610), 100)]

static func _target(id: String, label: String, at: Vector2, radius: float) -> Dictionary:
	return {"id": id, "label": label, "at": at, "radius": radius}

static func walls(zone: String) -> Array[Rect2]:
	var size := extent(zone)
	var result: Array[Rect2] = [
		Rect2(40, 40, size.x - 80, 24), Rect2(40, size.y - 64, size.x - 80, 24),
		Rect2(40, 64, 24, size.y - 128), Rect2(size.x - 64, 64, 24, size.y - 128)]
	match zone:
		"building_02":
			# The adjoining maintenance room has one clear door on the hall side.
			result.append_array([Rect2(1450, 2800, 800, 24), Rect2(1450, 2800, 24, 920), Rect2(1450, 3696, 800, 24), Rect2(2226, 2824, 24, 550), Rect2(2226, 3626, 24, 70)])
			# Open colonnades frame four quiet lounges without closing the galleries.
			for x in [1850, 4500]:
				for y in [550, 2000]: result.append(Rect2(x, y, 28, 900))
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
	for spec in furniture_specs(zone): result.append(spec.rect)
	return result

static func furniture_specs(zone: String) -> Array[Dictionary]:
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
		"hotel_it":
			result.append_array([_prop("server", Rect2(200, 180, 180, 250)), _prop("server", Rect2(440, 180, 180, 250)), _prop("repair", Rect2(690, 260, 220, 120)), _prop("storage", Rect2(1080, 180, 150, 360))])
		"hotel_stairs_1":
			result.append_array([_prop("stairs_down", Rect2(380, 270, 240, 350)), _prop("stairs_up", Rect2(900, 270, 240, 350)), _prop("planter", Rect2(180, 840, 90, 90)), _prop("planter", Rect2(1300, 840, 90, 90))])
		"hotel_floor_2":
			result.append_array([_prop("stairs_down", Rect2(350, 700, 240, 250)), _prop("planter", Rect2(2110, 910, 90, 90)), _prop("sofa", Rect2(1850, 1090, 380, 100))])
		"hotel_room_206":
			result.append_array([_prop("bed", Rect2(730, 240, 260, 260)), _prop("nightstand", Rect2(660, 265, 58, 75)), _prop("nightstand", Rect2(1002, 265, 58, 75)), _prop("luggage", Rect2(200, 600, 210, 80)), _prop("desk", Rect2(160, 180, 260, 100)), _prop("armchair", Rect2(260, 360, 150, 140)), _prop("storage", Rect2(92, 770, 250, 70)), _prop("planter", Rect2(1020, 750, 80, 80))])
	return result

static func _prop(kind: String, rect: Rect2) -> Dictionary:
	return {"kind": kind, "rect": rect}

static func rooms(zone: String) -> Array[Rect2]:
	match zone:
		"building_02": return [Rect2(2200, 2820, 2100, 1290), Rect2(2200, 550, 2000, 2250), Rect2(300, 650, 1500, 1900), Rect2(4600, 650, 1500, 1900), Rect2(1450, 2800, 800, 920), Rect2(3850, 3000, 650, 720)]
		"hotel_it": return [Rect2(80, 80, 1240, 740)]
		"hotel_stairs_1": return [Rect2(80, 215, 1440, 785)]
		"hotel_floor_2": return [Rect2(80, 675, 2240, 540)]
		"hotel_room_206": return [Rect2(80, 80, 1040, 840)]
	return []
