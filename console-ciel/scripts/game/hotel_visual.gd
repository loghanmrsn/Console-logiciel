extends Node2D
## Original, static vector scenery. Gold inlays and a calm marble palette link
## the vast lobby, the stair landings and the private guest room.
const Layout = preload("res://scripts/game/hotel_layout.gd")
const IVORY := Color("f2ede2")
const STONE := Color("ded8ca")
const GOLD := Color("b4945d")
const INK := Color("344950")
const VELVET := Color("345a61")
var zone := "building_02"
var state: Dictionary = {}
var bed_pose := "standing"

func _draw() -> void:
	var bounds := Layout.extent(zone)
	draw_rect(Rect2(Vector2.ZERO, bounds), IVORY)
	if zone != "ctf_bus_stop": _marble(bounds)
	match zone:
		"building_02": _hall()
		"hotel_it": _maintenance()
		"hotel_stairs_1": _landing()
		"hotel_floor_2": _corridor()
		"hotel_room_206": _bedroom()
		"hotel_breakfast": _breakfast()
		"ctf_bus_stop": _ctf_exterior()
		"ctf_lobby": _ctf_lobby()
	for wall in Layout.walls(zone): _wall(wall)
	for spec in Layout.furniture_specs(zone): _furniture(str(spec.kind), spec.rect)
	match zone:
		"building_02": _hall_signage()
		"hotel_it": _door(Vector2(700, 836), "RETOUR AU HALL")
		"hotel_stairs_1": _landing_signage()
		"hotel_floor_2": _room_doors()
		"hotel_room_206":
			_door(Vector2(600, 936), "206")
			if bool(state.get("luggage_placed", false)):
				_suitcase(Vector2(275, 618))
				if int(state.get("morning_stage", 0)) < 6: _backpack(Vector2(363, 622))
			if bed_pose == "sitting": _seated_guest(Layout.BED_SEAT)
		"hotel_breakfast": _door(Vector2(700, 986), "RETOUR AU HALL")
		"ctf_bus_stop": _ctf_facade()
		"ctf_lobby": _door(Vector2(900, 1236), "ARRÊT DU BUS")

func _marble(bounds: Vector2) -> void:
	for x in range(64, int(bounds.x - 40), 160):
		draw_line(Vector2(x, 64), Vector2(x, bounds.y - 64), Color("e7e1d5"), 1)
	for y in range(64, int(bounds.y - 40), 160):
		draw_line(Vector2(64, y), Vector2(bounds.x - 64, y), Color("e7e1d5"), 1)
	# A few quiet stone veins avoid an animated or visually busy floor.
	for x in range(200, int(bounds.x - 100), 640):
		for y in range(280, int(bounds.y - 100), 800):
			draw_polyline(PackedVector2Array([Vector2(x, y), Vector2(x + 35, y - 15), Vector2(x + 95, y - 9), Vector2(x + 125, y - 28)]), Color("e4ddcf"), 1, true)

func _hall() -> void:
	# Fifty times the original room's area, with a continuous central promenade.
	_rounded(Rect2(2780, 700, 840, 3330), Color("e7dfcd"), 50)
	_rounded(Rect2(2804, 724, 792, 3282), IVORY, 40)
	for y in [1400, 2100, 2860, 3770]:
		draw_line(Vector2(2825, y), Vector2(3575, y), GOLD, 2)
	for x in [2750, 3650]:
		draw_line(Vector2(x, 650), Vector2(x, 4010), GOLD, 3)
	for x in [2200, 4200]:
		draw_line(Vector2(x, 650), Vector2(x, 3900), Color("d8c6a0"), 2)
	for rect in [Rect2(440, 850, 960, 1000), Rect2(4660, 850, 960, 1000), Rect2(440, 2020, 960, 1000), Rect2(4660, 2020, 960, 1000)]:
		_rug(rect, Color("d1b999"))
	_rug(Rect2(2960, 3730, 480, 260), VELVET)
	_text("CIEL", Vector2(3200, 3865), 42, IVORY, true)
	_text("H Ô T E L", Vector2(3200, 3904), 21, Color("e1c997"), true)
	for y in [1100, 1850]: _chandelier(Vector2(3200, y))
	for x in [900, 5480]:
		_text("SALON", Vector2(x, 770), 29, INK, true)
	_text("GALERIE DU GRAND HALL", Vector2(3200, 740), 32, INK, true)
	for x in range(400, 6100, 520):
		_window(Rect2(x, 76, 300, 110))

func _hall_signage() -> void:
	_text("HÔTEL CIEL", Vector2(3200, 3320), 37, INK, true)
	_text("★ ★ ★ ★ ★", Vector2(3200, 3360), 23, GOLD, true)
	_text("RÉCEPTION", Vector2(3200, 3587), 25, INK, true)
	_person(Vector2(3200, 3402), false)
	var outage := bool(state.get("reserved", false)) and not bool(state.get("repaired", false))
	_rounded(Rect2(3410, 3390, 86, 46), Color("35464c"), 4)
	draw_circle(Vector2(3479, 3403), 4, Color("d2936b") if outage else Color("93bea6"))
	_text("HORS LIGNE" if outage else "BIENVENUE", Vector2(3453, 3420), 9, Color("e9e9d8"), true)
	_door(Vector2(3200, 4136), "COUR · SORTIE")
	# The maintenance portal aligns exactly with the gap in the solid partition.
	_rounded(Rect2(2226, 3374, 24, 252), Color("cbb98e"), 4)
	draw_line(Vector2(2238, 3384), Vector2(2238, 3616), GOLD, 3)
	_text("LOCAL INFORMATIQUE", Vector2(1910, 2960), 24, INK, true)
	_text("ENTRÉE →", Vector2(2150, 3540), 17, INK, true)
	_text("ESCALIERS", Vector2(4190, 3070), 27, INK, true)
	_text("MONTER", Vector2(4040, 3510), 18, INK, true)
	_text("ARRIVÉES", Vector2(4340, 3510), 18, INK, true)
	_text("Réception ←", Vector2(3740, 3710), 20, INK)
	_rounded(Rect2(4626, 3374, 24, 252), VELVET, 4)
	draw_line(Vector2(4638, 3384), Vector2(4638, 3616), GOLD, 3)
	_text("PETIT DÉJEUNER", Vector2(5350, 3010), 30, INK, true)
	_text("SALLE DU RESTAURANT →", Vector2(4950, 3520), 19, INK, true)

func _maintenance() -> void:
	draw_rect(Rect2(95, 100, 1210, 540), Color("d8e0da"))
	_text("MAINTENANCE · SYSTÈME DE RÉSERVATION", Vector2(700, 128), 24, INK, true)
	_rug(Rect2(620, 410, 360, 130), Color("acc0b3"))
	for x in [290, 530]:
		draw_line(Vector2(x, 450), Vector2(x, 560), Color("7e9d8e"), 5)
	draw_line(Vector2(290, 560), Vector2(800, 560), Color("7e9d8e"), 5)
	draw_line(Vector2(800, 560), Vector2(800, 430), Color("7e9d8e"), 5)
	_text("POSTE DE CONTRÔLE", Vector2(800, 603), 17, INK, true)
	_text("LIAISON DU HALL", Vector2(400, 500), 16, INK, true)

func _landing() -> void:
	_rug(Rect2(330, 650, 860, 330), VELVET)
	# This grille sits on the collision partition: the floor cannot be entered.
	for x in range(620, 982, 24): draw_line(Vector2(x, 70), Vector2(x, 195), GOLD, 6)
	draw_line(Vector2(610, 80), Vector2(990, 80), INK, 10)
	draw_line(Vector2(610, 188), Vector2(990, 188), INK, 10)

func _landing_signage() -> void:
	_text("ÉTAGE 1 · PALIER", Vector2(800, 250), 31, INK, true)
	_text("Accès à l’étage fermé", Vector2(800, 150), 23, INK, true)
	_text("VERS LE HALL", Vector2(500, 680), 20, IVORY, true)
	_text("VERS L’ÉTAGE 2", Vector2(1020, 680), 20, IVORY, true)
	_text("Les deux escaliers rejoignent ce même palier.", Vector2(800, 1010), 20, INK, true)

func _corridor() -> void:
	_rug(Rect2(670, 690, 1480, 330), VELVET)
	_text("ÉTAGE 2", Vector2(800, 1105), 27, INK, true)
	_text("201 — 208", Vector2(1770, 1105), 23, INK, true)
	_text("VERS LE PALIER", Vector2(470, 990), 19, INK, true)

func _room_doors() -> void:
	# Other guest rooms stay closed; 206 is the only story destination.
	for index in range(8):
		var x := 270.0 + index * 280.0
		var number := 201 + index
		var color := Color("8c7561") if number != 206 else Color("55736d")
		_rounded(Rect2(x - 48, 565, 96, 96), color, 5)
		draw_rect(Rect2(x - 40, 576, 80, 75), Color("a08c72") if number != 206 else VELVET)
		draw_circle(Vector2(x + 27, 631), 4, GOLD)
		_rounded(Rect2(x - 35, 531, 70, 29), GOLD, 3)
		_text(str(number), Vector2(x, 552), 18, Color("fcf8ed"), true)
		if number == 206:
			draw_rect(Rect2(x - 59, 664, 118, 18), Color("c9b78f"))

func _bedroom() -> void:
	# Warm parquet and a velvet runner distinguish the private room from marble.
	draw_rect(Rect2(66, 66, 1068, 868), Color("dccbb1"))
	for y in range(95, 934, 48):
		draw_line(Vector2(66, y), Vector2(1134, y), Color("cdbb9f"), 1)
		for x in range(100 + (int(y / 48) % 2) * 90, 1134, 180):
			draw_line(Vector2(x, y), Vector2(x, y + 48), Color("cdbb9f"), 1)
	_rug(Rect2(630, 195, 460, 480), Color("e9e2d2"))
	_window(Rect2(500, 78, 440, 94))
	_text("CHAMBRE 206", Vector2(600, 795), 24, INK, true)
	_text("PORTE-BAGAGES", Vector2(305, 701), 16, INK, true)
	if bed_pose == "rested":
		draw_colored_polygon(PackedVector2Array([Vector2(510, 174), Vector2(924, 174), Vector2(1115, 735), Vector2(715, 735)]), Color(1.0, 0.94, 0.70, 0.13))

func _breakfast() -> void:
	_rug(Rect2(480, 300, 420, 360), Color("dfcfad"))
	for x in [230, 620, 1080]: _window(Rect2(x, 78, 240, 65))
	_text("LE PETIT DÉJEUNER", Vector2(800, 850), 28, INK, true)
	_text("BUFFET", Vector2(510, 268), 20, INK, true)
	_text("CAFÉ", Vector2(1250, 354), 20, INK, true)
	_text("Votre table", Vector2(690, 650), 18, INK, true)

func _breakfast_table(rect: Rect2) -> void:
	_rounded(rect, Color("af9572"), 20)
	_rounded(rect.grow(-10), Color("fff9ea"), 15)
	for x in [rect.position.x + 60, rect.end.x - 60]:
		var plate := Vector2(x, rect.get_center().y)
		draw_circle(plate, 27, Color("e0d7c2"))
		draw_circle(plate, 22, Color("fcf8ed"))
		draw_arc(plate + Vector2(-3, 0), 12, PI * .2, PI * 1.65, 20, Color("c69a5e"), 9, true)
		draw_line(plate + Vector2(-36, -19), plate + Vector2(-36, 21), GOLD, 3)
		draw_line(plate + Vector2(36, -19), plate + Vector2(36, 21), GOLD, 3)
	# The chair is decoration below the tabletop, leaving a clear approach.
	_rounded(Rect2(rect.get_center().x - 36, rect.end.y + 22, 72, 28), VELVET, 10)
	if int(state.get("morning_stage", 0)) >= 5 and rect.position.x == 550:
		_cup(rect.position + Vector2(140, 35))

func _buffet(rect: Rect2) -> void:
	_rounded(rect, Color("a28c6a"), 10)
	_rounded(Rect2(rect.position + Vector2(-5, -5), rect.size + Vector2(10, 12)), Color("e9dfc9"), 9)
	for index in range(7):
		var center := rect.position + Vector2(50 + index * 96, 42)
		_rounded(Rect2(center - Vector2(34, 25), Vector2(68, 50)), Color("9aa7a1"), 7)
		_rounded(Rect2(center - Vector2(28, 19), Vector2(56, 38)), Color("d4af71") if index % 2 == 0 else Color("a9b77b"), 6)

func _coffee_machine(rect: Rect2) -> void:
	_rounded(rect, Color("aa9270"), 8)
	var machine := Rect2(rect.position + Vector2(45, -45), Vector2(110, 112))
	_rounded(machine, INK, 10)
	_rounded(machine.grow(-8), Color("5d7677"), 7)
	var repaired := int(state.get("morning_stage", 0)) >= 4
	_rounded(Rect2(machine.position + Vector2(15, 12), Vector2(80, 28)), Color("b9d5be") if repaired else Color("caae7f"), 4)
	_text("PRÊTE" if repaired else "CONNEXION", machine.position + Vector2(55, 31), 11, INK, true)
	for index in range(3):
		draw_circle(machine.position + Vector2(26 + index * 29, 55), 6, [Color("cf6159"), Color("80a47b"), Color("926d4e")][index])
	draw_rect(Rect2(machine.position + Vector2(45, 69), Vector2(20, 14)), Color("d1c6ac"))
	_cup(machine.position + Vector2(55, 96))

func _cup(at: Vector2) -> void:
	draw_circle(at + Vector2(0, 5), 17, Color("e1d7c3"))
	draw_arc(at + Vector2(13, -1), 7, -PI * .5, PI * .5, 12, IVORY, 4, true)
	_rounded(Rect2(at - Vector2(11, 11), Vector2(22, 23)), Color("faf7e9"), 6)
	draw_circle(at - Vector2(0, 7), 8, Color("684e38"))

func _ctf_exterior() -> void:
	draw_rect(Rect2(Vector2.ZERO, Layout.extent(zone)), Color("dbe5df"))
	draw_rect(Rect2(64, 340, 1672, 660), Color("e7e6dc"))
	for x in range(100, 1700, 100): draw_line(Vector2(x, 350), Vector2(x, 1000), Color("d7d9ce"), 1)
	for y in range(400, 1000, 100): draw_line(Vector2(64, y), Vector2(1736, y), Color("d7d9ce"), 1)
	draw_rect(Rect2(64, 1000, 1672, 236), Color("68777c"))
	draw_line(Vector2(64, 998), Vector2(1736, 998), Color("c5b58a"), 9)
	for x in range(100, 1700, 200): draw_line(Vector2(x, 1175), Vector2(x + 110, 1175), Color("eee4c8"), 5)
	_bus(Vector2(1230, 1050))
	_text("ARRÊT · SUDO HACK", Vector2(1350, 800), 24, INK, true)
	_text("ACCUEIL DES PARTICIPANTS ↑", Vector2(900, 680), 23, INK, true)

func _ctf_facade() -> void:
	draw_rect(Rect2(100, 80, 1600, 250), Color("435362"))
	for x in range(170, 1640, 170):
		if abs(x - 900) > 130:
			_rounded(Rect2(x, 120, 104, 104), Color("698a91"), 5)
			draw_line(Vector2(x + 52, 122), Vector2(x + 52, 222), Color("bdd1c7"), 4)
	_text("sudo hack", Vector2(900, 185), 43, Color("eddfad"), true)
	_text("CAPTURE THE FLAG", Vector2(900, 226), 19, Color("dfebe1"), true)
	_rounded(Rect2(820, 254, 160, 78), VELVET, 5)
	draw_line(Vector2(900, 258), Vector2(900, 330), GOLD, 3)
	_text("ENTRÉE", Vector2(900, 408), 20, INK, true)

func _bus_shelter(rect: Rect2) -> void:
	_rounded(rect.grow(10), Color("8ca4a2"), 8)
	_rounded(rect.grow(-3), Color("cadbd3"), 5)
	for x in [rect.position.x + 8, rect.end.x - 12]: draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), INK, 7)
	_rounded(Rect2(rect.position + Vector2(-15, -18), Vector2(rect.size.x + 30, 30)), VELVET, 9)
	_rounded(Rect2(rect.position + Vector2(25, 95), Vector2(rect.size.x - 50, 30)), Color("947c60"), 5)
	_text("BUS", rect.position + Vector2(150, 54), 22, INK, true)

func _bus(at: Vector2) -> void:
	_rounded(Rect2(at - Vector2(185, 40), Vector2(370, 100)), VELVET, 17)
	for x in [-150, -75, 0, 75]: _rounded(Rect2(at + Vector2(x, -29), Vector2(62, 42)), Color("a7c6c3"), 5)
	for x in [-115, 115]: draw_circle(at + Vector2(x, 62), 22, INK)
	_text("SUDO HACK", at + Vector2(0, 42), 17, IVORY, true)

func _ctf_lobby() -> void:
	_rug(Rect2(620, 440, 560, 680), Color("d4d4dc"))
	_text("sudo hack", Vector2(900, 180), 49, INK, true)
	_text("ACCUEIL DU CTF", Vector2(900, 230), 22, INK, true)
	_text("Bienvenue aux participants", Vector2(900, 485), 27, INK, true)
	_text("La suite des épreuves arrive bientôt.", Vector2(900, 535), 21, INK, true)
	for x in [340, 1460]: _window(Rect2(x - 100, 90, 200, 130))

func _backpack(at: Vector2) -> void:
	# The laptop is visible in the open top, making the CTF bag identifiable.
	draw_arc(at - Vector2(0, 15), 15, PI, TAU, 16, INK, 5, true)
	_rounded(Rect2(at - Vector2(24, 18), Vector2(48, 55)), VELVET, 11)
	_rounded(Rect2(at + Vector2(-15, -25), Vector2(30, 25)), Color("b5cdd0"), 3)
	draw_line(at + Vector2(-11, -18), at + Vector2(11, -18), Color("6d969d"), 3)
	_rounded(Rect2(at + Vector2(-19, 7), Vector2(38, 23)), Color("557b7c"), 6)
	draw_line(at + Vector2(-14, 10), at + Vector2(14, 10), GOLD, 2)

func _wall(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(5, 7), rect.size), Color("c6c0b2"))
	draw_rect(rect, Color("b9b8aa"))
	draw_line(rect.position + Vector2(2, 2), rect.position + Vector2(rect.size.x - 2, 2), Color("eee8d9"), 3)

func _furniture(kind: String, rect: Rect2) -> void:
	_rounded(Rect2(rect.position + Vector2(6, 9), rect.size), Color("c1bda9"), 12)
	match kind:
		"reception", "ctf_reception":
			_rounded(rect, Color("5c4c44"), 18)
			draw_rect(Rect2(rect.position + Vector2(12, 18), rect.size - Vector2(24, 33)), VELVET)
			for x in range(int(rect.position.x + 38), int(rect.end.x - 25), 48): draw_line(Vector2(x, rect.position.y + 22), Vector2(x, rect.end.y - 22), GOLD, 2)
			_rounded(Rect2(rect.position + Vector2(-8, -10), Vector2(rect.size.x + 16, 28)), Color("d8c7a8"), 9)
		"breakfast_table": _breakfast_table(rect)
		"buffet": _buffet(rect)
		"coffee_machine": _coffee_machine(rect)
		"bus_shelter": _bus_shelter(rect)
		"fountain":
			var center := rect.get_center()
			draw_circle(center, 170, GOLD)
			draw_circle(center, 155, Color("77999a"))
			draw_circle(center, 135, Color("b0d2cc"))
			draw_arc(center, 108, 0, TAU, 64, Color("e1e9d7"), 3, true)
			draw_arc(center, 76, 0, TAU, 48, Color("d6e4d5"), 3, true)
			draw_circle(center, 36, Color("e0d8bc"))
			draw_circle(center, 16, GOLD)
		"stairs_up", "stairs_down": _spiral(rect, kind == "stairs_up")
		"planter": _plant(rect)
		"column":
			draw_circle(rect.get_center(), rect.size.x * 0.5, GOLD)
			draw_circle(rect.get_center(), rect.size.x * 0.43, Color("e5dfcf"))
			draw_arc(rect.get_center(), rect.size.x * 0.31, PI, TAU, 24, Color("faf5e9"), 6, true)
		"sofa", "armchair": _seat(rect, kind == "sofa")
		"coffee":
			_rounded(rect, GOLD, 23)
			_rounded(rect.grow(-7), Color("d9d3be"), 19)
			draw_circle(rect.get_center(), 19, Color("f1e9d3"))
			draw_circle(rect.get_center(), 12, Color("b7a27b"))
		"server": _server(rect)
		"repair": _repair_desk(rect)
		"storage":
			_rounded(rect, Color("9c8b70"), 7)
			draw_line(rect.get_center() - Vector2(0, rect.size.y * .4), rect.get_center() + Vector2(0, rect.size.y * .4), Color("c9bda2"), 3)
			draw_circle(rect.get_center() + Vector2(-9, 5), 3, GOLD)
			draw_circle(rect.get_center() + Vector2(9, 5), 3, GOLD)
		"bed": _bed(rect)
		"nightstand":
			_rounded(rect, Color("a18b6a"), 5)
			draw_circle(rect.get_center(), 19, Color("e8d7ae"))
			draw_circle(rect.get_center(), 8, GOLD)
		"luggage":
			_rounded(rect, Color("9b876d"), 6)
			for x in range(int(rect.position.x + 20), int(rect.end.x - 15), 32): draw_line(Vector2(x, rect.position.y + 6), Vector2(x, rect.end.y - 6), GOLD, 6)
		"desk":
			_rounded(rect, Color("ac9575"), 8)
			_rounded(Rect2(rect.position + Vector2(25, 18), Vector2(100, 65)), Color("eee6d3"), 3)
			draw_circle(rect.end - Vector2(45, 46), 17, GOLD)

func _spiral(rect: Rect2, ascending: bool) -> void:
	var center := rect.get_center() - Vector2(0, 24)
	var radius := minf(rect.size.x * .47, rect.size.y * .36)
	_rounded(rect, Color("e0d5bc"), 35)
	# Both ends face the lower landing. The curving treads turn around a solid
	# central well rather than suggesting a straight through-floor corridor.
	draw_arc(center, radius, PI * .15, PI * 2.85, 64, Color("a5916f"), 24, true)
	for index in range(19):
		var angle := PI * .25 + float(index) / 18.0 * PI * 1.5
		var direction := Vector2.from_angle(angle)
		draw_line(center + direction * radius * .38, center + direction * radius, Color("f4eddb"), 4, true)
	draw_circle(center, radius * .31, VELVET)
	draw_arc(center, radius * .4, 0, TAU, 32, GOLD, 4, true)
	draw_rect(Rect2(center + Vector2(-radius * .5, radius * .65), Vector2(radius, radius * .45)), Color("d3c7ac"))
	var arrow_at := Vector2(rect.get_center().x, rect.end.y - 22)
	var flip := -1.0 if ascending else 1.0
	draw_polyline(PackedVector2Array([arrow_at + Vector2(-13, -flip * 6), arrow_at + Vector2(0, flip * 7), arrow_at + Vector2(13, -flip * 6)]), INK, 4, true)

func _seat(rect: Rect2, long_seat: bool) -> void:
	_rounded(rect, VELVET, 22)
	_rounded(Rect2(rect.position + Vector2(17, 22), rect.size - Vector2(34, 35)), Color("55777a"), 13)
	if long_seat:
		for index in range(1, 4):
			var x := rect.position.x + rect.size.x * index / 4.0
			draw_line(Vector2(x, rect.position.y + 29), Vector2(x, rect.end.y - 15), VELVET, 3)
	for x in [rect.position.x + 5, rect.end.x - 22]: _rounded(Rect2(x, rect.position.y + 10, 17, rect.size.y - 20), Color("294b52"), 8)

func _plant(rect: Rect2) -> void:
	var center := rect.get_center()
	_rounded(Rect2(center - Vector2(24, 6), Vector2(48, 42)), Color("aa8b63"), 7)
	for offset in [Vector2(-17, -12), Vector2(18, -17), Vector2(0, -34)]: draw_circle(center + offset, rect.size.x * .25, Color("78947a"))
	draw_circle(center - Vector2(6, 24), rect.size.x * .2, Color("91a787"))

func _server(rect: Rect2) -> void:
	_rounded(rect, Color("455e62"), 9)
	for y in range(int(rect.position.y + 18), int(rect.end.y - 20), 48):
		draw_rect(Rect2(rect.position.x + 15, y, rect.size.x - 30, 35), Color("697f7d"))
		draw_circle(Vector2(rect.end.x - 27, y + 17), 4, Color("96bc9a") if bool(state.get("repaired", false)) else Color("d59b6d"))

func _repair_desk(rect: Rect2) -> void:
	_rounded(rect, Color("a08d6d"), 10)
	_rounded(Rect2(rect.position + Vector2(49, -35), Vector2(122, 84)), INK, 7)
	_rounded(Rect2(rect.position + Vector2(57, -27), Vector2(106, 66)), Color("a9c5ba"), 3)
	_text("EN LIGNE" if bool(state.get("repaired", false)) else "ERREUR", rect.position + Vector2(110, 12), 14, INK, true)
	draw_rect(Rect2(rect.position + Vector2(45, 68), Vector2(135, 24)), Color("dbddcb"))
	for x in range(50, 177, 13): draw_line(rect.position + Vector2(x, 73), rect.position + Vector2(x, 86), Color("a8b4a7"), 2)

func _bed(rect: Rect2) -> void:
	_rounded(rect.grow(10), Color("a18a65"), 18)
	_rounded(rect, Color("f8f4e9"), 14)
	_rounded(Rect2(rect.position + Vector2(8, 72), rect.size - Vector2(16, 80)), Color("91aaa3"), 9)
	for x in [rect.position.x + 20, rect.position.x + 141]: _rounded(Rect2(x, rect.position.y + 15, 99, 58), Color("fffdf5"), 12)
	draw_line(rect.position + Vector2(12, 87), Vector2(rect.end.x - 12, rect.position.y + 87), Color("d6dfcf"), 4)
	_rounded(Rect2(rect.position.x + 8, rect.end.y - 53, rect.size.x - 16, 39), VELVET, 5)

func _suitcase(at: Vector2) -> void:
	_rounded(Rect2(at - Vector2(48, 20), Vector2(96, 62)), Color("4a565b"), 8)
	for x in [-24, 24]: draw_line(at + Vector2(x, -15), at + Vector2(x, 36), GOLD, 4)
	draw_rect(Rect2(at + Vector2(-16, -29), Vector2(32, 10)), GOLD, false, 4)

func _seated_guest(at: Vector2) -> void:
	# The guest remains visibly seated between the repeated rest choices.
	_rounded(Rect2(at + Vector2(-20, 20), Vector2(40, 10)), Color("78918c"), 5)
	draw_line(at + Vector2(-7, 12), at + Vector2(-11, 29), Color("405563"), 8)
	draw_line(at + Vector2(7, 12), at + Vector2(11, 29), Color("405563"), 8)
	_rounded(Rect2(at + Vector2(-14, -12), Vector2(28, 30)), Color("557d95"), 7)
	draw_circle(at + Vector2(0, -22), 12, Color("c9ac8c"))
	draw_arc(at + Vector2(0, -24), 11, PI, TAU, 16, Color("60584b"), 6, true)
	draw_line(at + Vector2(-14, -2), at + Vector2(-10, 15), Color("c9ac8c"), 6)
	draw_line(at + Vector2(14, -2), at + Vector2(10, 15), Color("c9ac8c"), 6)

func _person(at: Vector2, _guest: bool) -> void:
	draw_circle(at + Vector2(0, -17), 13, Color("d0b28d"))
	_rounded(Rect2(at + Vector2(-15, -5), Vector2(30, 22)), INK, 6)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-5, -5), at + Vector2(5, -5), at + Vector2(0, 8)]), IVORY)
	draw_circle(at + Vector2(0, 5), 3, GOLD)

func _chandelier(at: Vector2) -> void:
	draw_circle(at + Vector2(5, 9), 100, Color("dfd6c1"))
	draw_arc(at, 83, 0, TAU, 64, GOLD, 6, true)
	for index in range(10):
		var ray := Vector2.from_angle(TAU * index / 10.0)
		draw_line(at + ray * 30, at + ray * 83, GOLD, 3, true)
		draw_circle(at + ray * 83, 12, Color("faf2d0"))
	draw_circle(at, 31, Color("e9d3a4"))
	draw_circle(at, 14, Color("fff7d7"))

func _window(rect: Rect2) -> void:
	_rounded(rect.grow(8), Color("c3ad82"), 6)
	draw_rect(rect, Color("b3d0d0"))
	for index in range(1, 4):
		var x := rect.position.x + rect.size.x * index / 4.0
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color("eee8d8"), 5)
	draw_line(rect.position + Vector2(0, rect.size.y * .5), rect.end - Vector2(0, rect.size.y * .5), Color("eee8d8"), 5)

func _door(at: Vector2, label: String) -> void:
	_rounded(Rect2(at - Vector2(90, 13), Vector2(180, 26)), VELVET, 4)
	draw_line(at - Vector2(0, 12), at + Vector2(0, 12), GOLD, 3)
	_text(label, at - Vector2(0, 29), 17, INK, true)

func _rug(rect: Rect2, color: Color) -> void:
	_rounded(rect, color, 14)
	var box := StyleBoxFlat.new()
	box.bg_color = Color.TRANSPARENT
	box.border_color = GOLD
	box.set_border_width_all(3)
	box.set_corner_radius_all(10)
	draw_style_box(box, rect.grow(-12))

func _rounded(rect: Rect2, color: Color, radius: int) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	draw_style_box(box, rect)

func _text(value: String, at: Vector2, font_size: int, color := INK, centered := false) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x if centered else 0.0
	draw_string(font, at - Vector2(width * .5, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
