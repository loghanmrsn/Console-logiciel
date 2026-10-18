extends RefCounted
## Shared courtyard geometry and interactions for the hotel and bus route.
const BUILDING_SIZE := Vector2(6400, 4200)
const COURTYARD_SIZE := Vector2(1800, 1300)
const ROOM_SIZE := Vector2(1120, 660)
const ROOM_X := [300, 1540, 3620, 4860]
const ROOM_Y := [300, 1080, 2460, 3240]
const COLORS := [Color("d5e3df"), Color("dce2eb"), Color("e6dfd0"), Color("dedbeb")]

static func extent(zone: String) -> Vector2:
	return BUILDING_SIZE if zone == "building_02" else COURTYARD_SIZE

static func checkpoints(zone: String) -> Dictionary:
	if zone == "building_02":
		return {"entrance": Vector2(3200, 4000), "new_entrance": Vector2(3200, 4000)}
	return {"entrance": Vector2(900, 980), "from_first": Vector2(900, 980), "from_second": Vector2(900, 430)}

static func rooms() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for y in ROOM_Y:
		for x in ROOM_X: result.append(Rect2(Vector2(x, y), ROOM_SIZE))
	return result

static func walls(zone: String) -> Array[Rect2]:
	var size := extent(zone)
	var result: Array[Rect2] = [Rect2(40,40,size.x-80,24), Rect2(40,size.y-64,size.x-80,24), Rect2(40,64,24,size.y-128), Rect2(size.x-64,64,24,size.y-128)]
	if zone == "courtyard":
		result.append_array([Rect2(100,80,1600,250), Rect2(100,1090,1600,160), Rect2(190,450,330,400), Rect2(1280,450,330,400)])
	else:
		for room in rooms():
			# Every room opens onto a continuous network of broad galleries.
			result.append_array([Rect2(room.position,Vector2(room.size.x,20)), Rect2(room.position,Vector2(20,room.size.y)), Rect2(room.end-Vector2(20,room.size.y),Vector2(20,room.size.y)), Rect2(room.position+Vector2(0,room.size.y-20),Vector2(488,20)), Rect2(room.position+Vector2(632,room.size.y-20),Vector2(488,20))])
	return result

static func furniture() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for room in rooms():
		result.append(Rect2(room.position+Vector2(100,100),Vector2(200,70)))
		result.append(Rect2(room.position+Vector2(900,100),Vector2(70,70)))
	return result

static func interactions(zone: String) -> Array[Dictionary]:
	if zone != "courtyard": return []
	return [
		{"id": "courtyard_first", "label": "Porte · premier bâtiment", "at": Vector2(900, 1060), "radius": 100.0},
		{"id": "courtyard_second", "label": "Porte · hôtel CIEL", "at": Vector2(900, 370), "radius": 100.0},
		{"id": "campus_bus", "label": "Arrêt de bus · rejoindre sudo hack", "at": Vector2(1140, 900), "radius": 90.0}]
