extends RefCounted
## Compact town centre: 38 new facades + the two original playable buildings.
const SIZE := Vector2(6000,4600)
const PARK := Rect2(2210,1660,1450,850)
const FOUNTAIN := Vector2(2930,2070)
const NAMES := ["Boulangerie", "Épicerie du centre", "Pharmacie", "La Poste", "Café des amis", "Sudo Hack", "Mairie", "Médiathèque", "Librairie", "Fleuriste", "Louise Michel", "Résidence des Tilleuls", "Maison de santé", "Opticien", "Cycles & Réparations", "Salon du marché", "Cinéma Le Parc", "Restaurant de la place", "Résidence des Arts", "Atelier du quartier", "Maison des associations", "Hôtel des Voyageurs", "Résidence Bellevue", "Résidence du Canal", "Garage", "Maison de quartier", "Résidence des Écoles", "Épicerie bio", "Laverie", "Café du parc", "Résidence du Square", "Maison de la musique", "Résidence des Jardins", "Papeterie", "Restaurant du Marché", "Résidence des Platanes", "Banque", "Boucherie"]
static func buildings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for origin in [Vector2(2200,180),Vector2(4300,180)]:
		for row in range(2):
			for col in range(3): add_building(result,Rect2(origin+Vector2(col*490,row*520),Vector2(410,270)))
	for row in range(2):
		for col in range(2): add_building(result,Rect2(200+col*770,1700+row*430,570,260))
	for row in range(2):
		for col in range(3): add_building(result,Rect2(4300+col*490,1700+row*470,410,270))
	for row in range(2):
		for col in range(2): add_building(result,Rect2(200+col*770,3100+row*440,570,270))
	for origin_x in [2200,4300]:
		for row in range(2):
			for col in range(3): add_building(result,Rect2(origin_x+col*490,3100+row*440,410,270))
	return result
static func add_building(result: Array[Dictionary], rect: Rect2) -> void:
	var index := result.size()
	result.append({"kind":"building","rect":rect,"title":NAMES[index],"index":index,"floors":2+index%3})
static func roads() -> Array[Rect2]:
	return [Rect2(1800,64,270,4420),Rect2(3900,64,220,4420),Rect2(100,1300,5800,220),Rect2(100,2650,5800,220),Rect2(100,3950,5800,220)]
static func roundabouts() -> Array[Vector2]: return [Vector2(1935,1410),Vector2(4010,2760)]
static func props() -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"kind":"fountain","rect":Rect2(FOUNTAIN-Vector2(95,95),Vector2(190,190))},{"kind":"shelter","rect":Rect2(1080,850,170,22)}]
	for point in roundabouts(): result.append({"kind":"island","rect":Rect2(point-Vector2(65,65),Vector2(130,130))})
	for at in [Vector2(2380,1790),Vector2(3380,1790),Vector2(2380,2310),Vector2(3380,2310)]: result.append({"kind":"tree","rect":Rect2(at,Vector2(60,60))})
	for at in [Vector2(2520,1870),Vector2(3160,2270)]: result.append({"kind":"bench","rect":Rect2(at,Vector2(180,45))})
	for x in [2150,3800,4230,5810]:
		for y in [1180,2510,3810]: result.append({"kind":"lamp","rect":Rect2(x,y,18,18)})
	for point in [Vector2(2860,1270),Vector2(2860,2890),Vector2(4440,2620)]: result.append({"kind":"signal","rect":Rect2(point,Vector2(20,20))})
	return result
static func solid_specs() -> Array[Dictionary]:
	var result: Array[Dictionary] = buildings()
	result.append_array(props())
	return result
static func interactions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for b in buildings():
		if b.title not in ["Sudo Hack","Louise Michel"]: continue
		result.append({"id":"town_walk_ctf" if b.title == "Sudo Hack" else "town_walk_school", "label":b.title+" · accès à pied", "at":b.rect.get_center()+Vector2(0,b.rect.size.y*.5+65),"radius":95.0})
	return result
static func pedestrian_routes() -> Array[PackedVector2Array]:
	return [PackedVector2Array([Vector2(2170,1580),Vector2(3750,1580),Vector2(3750,2550),Vector2(2170,2550)]),PackedVector2Array([Vector2(2130,110),Vector2(3750,110),Vector2(3750,1160),Vector2(2130,1160)]),PackedVector2Array([Vector2(4200,1600),Vector2(5800,1600),Vector2(5800,2540),Vector2(4200,2540)])]
static func car_route() -> PackedVector2Array:
	return PackedVector2Array([Vector2(2220,1360),Vector2(3850,1360),Vector2(3950,1500),Vector2(3950,2600),Vector2(3810,2705),Vector2(2210,2705),Vector2(1950,2590),Vector2(1950,1560)])
static func on_road(at: Vector2) -> bool:
	for road in roads():
		if road.grow(15).has_point(at): return true
	return false
