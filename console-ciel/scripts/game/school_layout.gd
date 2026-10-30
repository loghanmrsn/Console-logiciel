extends RefCounted
## One geometry source for solid furniture, scenery, interactions and the map.
static func extent(_zone: String) -> Vector2: return Vector2(2000, 1400)
static func title(zone: String) -> String: return "Louise Michel · " + ("parvis et arrêt" if zone == "school_stop" else "salle cyber")
static func checkpoints(zone: String) -> Dictionary:
	return {"entrance": Vector2(1000, 1040), "school_arrival": Vector2(1000, 1040), "school_door": Vector2(1000, 490)} if zone == "school_stop" else {"entrance": Vector2(1000, 1210), "school_entry": Vector2(1000, 1210)}
static func walls(zone: String) -> Array[Rect2]:
	var result: Array[Rect2] = [Rect2(40,40,1920,24),Rect2(40,1336,1920,24),Rect2(40,64,24,1272),Rect2(1936,64,24,1272)]
	if zone == "school_stop": result.append(Rect2(100, 90, 1800, 330))
	return result
static func furniture_specs(zone: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if zone == "school_stop":
		for x in [260, 1450]: result.append({"kind":"garden", "rect":Rect2(x,600,270,160)})
		result.append({"kind":"shelter", "rect":Rect2(1390,930,320,120)})
		result.append({"kind":"sign", "rect":Rect2(660,430,180,45)})
	else:
		for y in [360, 690]:
			for x in [250, 760, 1270]:
				result.append({"kind":"cyber_desk", "rect":Rect2(x,y,320,110)})
		for x in [1490, 1670]: result.append({"kind":"rack", "rect":Rect2(x,100,120,165)})
		result.append({"kind":"whiteboard", "rect":Rect2(580,120,520,30)})
		result.append({"kind":"sign", "rect":Rect2(180,120,180,45)})
	for spec in result.duplicate():
		if spec.kind == "cyber_desk": result.append({"kind":"chair", "rect":Rect2(spec.rect.position+Vector2(30,145),Vector2(70,40))})
	return result
static func interactions(zone: String) -> Array[Dictionary]:
	if zone == "school_stop": return [target("school_enter","Entrée · salle cyber",Vector2(1000,475)), target("school_bus","Bus · retour en ville",Vector2(1550,1110))]
	var result: Array[Dictionary] = [target("school_exit","Porte · parvis et bus",Vector2(1000,1270)),target("school_network","Baie réseau · découvrir",Vector2(1630,320)),target("school_course","Tableau · espace de cours",Vector2(850,220))]
	for y in [360,690]:
		for x in [250,760,1270]: result.append(target("school_pc_%d_%d" % [x,y],"Ordinateur · poste cyber",Vector2(x+160,y+180)))
	return result
static func target(id: String, label: String, at: Vector2) -> Dictionary: return {"id":id,"label":label,"at":at,"radius":95.0}
static func rooms(_zone: String) -> Array[Rect2]: return [Rect2(80,80,1840,1240)]
