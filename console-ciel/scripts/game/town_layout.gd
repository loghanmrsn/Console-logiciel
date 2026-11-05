extends RefCounted
## Compact town centre: 38 new facades + the two original playable buildings.
const Road = preload("res://scripts/game/road_layout.gd")
const SchoolFacade = preload("res://scripts/game/school_facade_art.gd")
const SIZE := Vector2(9200,4800)
const SCHOOL := Rect2(7100,520,1560,380)
const SCHOOL_GROUNDS := Rect2(6750,340,2100,890)
const FORMER_SCHOOL := Rect2(4790,820,410,270)
const PARK := Rect2(2210,1660,1450,850)
const FOUNTAIN := Vector2(2930,2070)
const NAMES := ["Boulangerie", "Épicerie du centre", "Pharmacie", "La Poste", "Café des amis", "Sudo Hack", "Mairie", "Médiathèque", "Bibliothèque", "Fleuriste", "Louise Michel", "Résidence des Tilleuls", "Maison de santé", "Opticien", "Cycles & Réparations", "Bar du marché", "Cinéma Le Parc", "Restaurant de la place", "Résidence des Arts", "Atelier du quartier", "Maison des associations", "Hôtel des Voyageurs", "Résidence Bellevue", "Résidence du Canal", "Garage", "Maison de quartier", "Résidence des Écoles", "Épicerie bio", "Laverie", "Café du parc", "Résidence du Square", "Maison de la musique", "Résidence des Jardins", "Papeterie", "Restaurant du Marché", "Résidence des Platanes", "Banque", "Boucherie"]
static func buildings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for origin in [Vector2(2200,350),Vector2(4300,350)]:
		for row in range(2):
			for col in range(3): add_building(result,Rect2(origin+Vector2(col*490,row*470),Vector2(410,270)))
	for row in range(2):
		for col in range(2): add_building(result,Rect2(400+col*770,1700+row*430,570,260))
	for row in range(2):
		for col in range(3): add_building(result,Rect2(4300+col*490,1700+row*470,410,270))
	for row in range(2):
		for col in range(2): add_building(result,Rect2(400+col*770,3100+row*440,570,270))
	for origin_x in [2200,4300]:
		for row in range(2):
			for col in range(3): add_building(result,Rect2(origin_x+col*490,3100+row*440,410,270))
	return result
static func add_building(result: Array[Dictionary], rect: Rect2) -> void:
	var index := result.size()
	var school: bool = NAMES[index]=="Louise Michel"
	result.append({"kind":"building","rect":SCHOOL if school else rect,"title":NAMES[index],"index":index,"floors":1 if school else 2+index%3,"school":school})
static func roads() -> Array[Rect2]:
	# The original street joins the full width of the first avenue. Its old
	# crossing/penalty region stays owned by RoadLayout, independently of paint.
	# All segment ends overlap another street, including the outer boulevard.
	return [
		Rect2(1800,80,270,4530), Rect2(3900,80,220,4530),
		Rect2(64,1300,9016,220), Rect2(64,2650,9016,220), Rect2(64,3950,6056,220),
		Rect2(Road.ROAD.position,Vector2(2070-Road.ROAD.position.x,Road.ROAD.size.y)),
		Rect2(64,580,220,4030), Rect2(5900,80,220,4530),
		Rect2(1800,80,4320,180), Rect2(64,4390,6056,220),
		Rect2(8860,1300,220,1570)]
static func intersections() -> Array[Rect2]:
	var result: Array[Rect2] = []
	var streets := roads()
	for index in range(streets.size()):
		for other in range(index+1,streets.size()):
			if streets[index].intersects(streets[other]): result.append(streets[index].intersection(streets[other]))
	return result
static func crosswalks() -> Array[Rect2]:
	return [Road.CROSSING,Rect2(1800,496,270,52),Rect2(1800,850,270,52),Rect2(2720,1300,110,220),Rect2(2720,2650,110,220),Rect2(4300,2650,110,220)]
static func roundabouts() -> Array[Vector2]: return [Vector2(1935,1410),Vector2(4010,2760)]
static func props() -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"kind":"fountain","rect":Rect2(FOUNTAIN-Vector2(95,95),Vector2(190,190))},{"kind":"shelter","rect":Rect2(1080,850,170,22)}]
	result.append_array(forecourt_specs())
	for at in [Vector2(5060,685),Vector2(5550,685)]: result.append({"kind":"bench","rect":Rect2(at,Vector2(100,45))})
	for point in roundabouts(): result.append({"kind":"island","rect":Rect2(point-Vector2(65,65),Vector2(130,130))})
	for at in [Vector2(2380,1790),Vector2(3380,1790),Vector2(2380,2310),Vector2(3380,2310)]: result.append({"kind":"tree","rect":Rect2(at,Vector2(60,60))})
	for at in [Vector2(2520,1870),Vector2(3160,2270)]: result.append({"kind":"bench","rect":Rect2(at,Vector2(180,45))})
	for x in [2150,3800,4230,5810]:
		for y in [1180,2510,3810]: result.append({"kind":"lamp","rect":Rect2(x,y,18,18)})
	for point in [Vector2(2860,1270),Vector2(2860,2890),Vector2(4440,2620)]: result.append({"kind":"signal","rect":Rect2(point,Vector2(20,20))})
	result.append_array([
		{"kind":"campus_planter","rect":Rect2(6830,1030,320,110)},
		{"kind":"campus_planter","rect":Rect2(7620,1060,420,100)},
		{"kind":"campus_planter","rect":Rect2(8280,1030,420,110)},
		{"kind":"campus_bench","rect":Rect2(6920,965,180,36)},
		{"kind":"campus_bench","rect":Rect2(8020,980,180,36)},
		{"kind":"campus_sign","rect":Rect2(7780,970,145,35)},
		{"kind":"tree","rect":Rect2(4860,920,60,60)},
		{"kind":"bench","rect":Rect2(4940,1020,180,45)},
		{"kind":"campus_arrow","rect":Rect2(5170,1040,22,20)}])
	# Terraces stay beside the central doorway, with a clear route to the road.
	for building in buildings():
		if not preload("res://scripts/game/storefront_art.gd").is_food(building.title): continue
		var rect: Rect2=building.rect
		for x in [rect.position.x+70,rect.end.x-70]:
			var center := Vector2(x,rect.end.y+(76 if x==rect.position.x+70 else 68))
			result.append({"kind":"cafe_table","rect":Rect2(center-Vector2(32,32),Vector2(64,64))})
			for y in ([40] if x==rect.position.x+70 else [-40,40]): result.append({"kind":"cafe_chair","rect":Rect2(center+Vector2(-11,y-10),Vector2(22,20))})
		result.append({"kind":"menu_board","rect":Rect2(rect.get_center().x+45,rect.end.y+46,42,22)})
	return result
static var _forecourt_catalog: Dictionary = {}
static func forecourt_specs() -> Array[Dictionary]:
	if _forecourt_catalog.is_empty():
		_forecourt_catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/town_forecourts.json"))
	var facades := buildings()
	var result: Array[Dictionary] = []
	for entry in _forecourt_catalog.decorations:
		var at: Vector2
		if entry.has("at"): at=Vector2(entry.at[0],entry.at[1])
		else:
			var facade: Rect2=facades[int(entry.building)].rect
			at=Vector2(facade.position.x+entry.offset[0],facade.end.y+entry.offset[1])
		var owner := str(int(entry.building)) if entry.building is float else str(entry.building)
		result.append({"kind":entry.kind,"rect":Rect2(at,Vector2(entry.size[0],entry.size[1])),"forecourt_owner":owner})
	return result
static func solid_specs() -> Array[Dictionary]:
	var result: Array[Dictionary] = buildings()
	result.append_array(props())
	return result
static func interactions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for b in buildings():
		if b.title not in ["Sudo Hack","Louise Michel"]: continue
		var at: Vector2=SchoolFacade.entrance(b.rect) if b.school else b.rect.get_center()+Vector2(0,b.rect.size.y*.5+65)
		result.append({"id":"town_walk_ctf" if b.title == "Sudo Hack" else "town_walk_school", "label":b.title+" · accès à pied", "at":at,"radius":95.0})
	return result
static func pedestrian_routes() -> Array[PackedVector2Array]:
	return [PackedVector2Array([Vector2(2170,1580),Vector2(3750,1580),Vector2(3750,2550),Vector2(2170,2550)]),PackedVector2Array([Vector2(2130,680),Vector2(3750,680),Vector2(3750,1235),Vector2(2130,1235)]),PackedVector2Array([Vector2(4200,1600),Vector2(5800,1600),Vector2(5800,2540),Vector2(4200,2540)])]
static func car_route() -> PackedVector2Array:
	return PackedVector2Array([Vector2(2220,1360),Vector2(3850,1360),Vector2(3950,1500),Vector2(3950,2600),Vector2(3810,2705),Vector2(2210,2705),Vector2(1950,2590),Vector2(1950,1560)])
static func on_road(at: Vector2) -> bool:
	for road in roads():
		if road.grow(15).has_point(at): return true
	return false
