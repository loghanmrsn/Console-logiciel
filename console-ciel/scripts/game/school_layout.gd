extends RefCounted
## One geometry source for solid furniture, scenery, interactions and the map.
static func extent(zone: String) -> Vector2: return Vector2(1000,1800) if zone == "school_hall" else (Vector2(3000,700) if zone == "school_passage" else Vector2(2000,1400))
static func title(zone: String) -> String:
	if zone in ["school_hall", "school_passage", "school_workshop"]: return {"school_hall":"Lycée · couloir et porte sécurisée", "school_passage":"Lycée · liaison vers les ateliers", "school_workshop":"Atelier · cyber, informatique et électronique"}[zone]
	return "Louise Michel · " + ("parvis et arrêt" if zone == "school_stop" else "salle cyber")
static func checkpoints(zone: String) -> Dictionary:
	if zone == "school_hall": return {"entrance": Vector2(500,1550), "school_hall_entry": Vector2(500,1550)}
	if zone == "school_passage": return {"entrance": Vector2(250,350), "school_passage_entry": Vector2(250,350)}
	if zone == "school_workshop": return {"entrance": Vector2(1000,1200), "school_workshop_entry": Vector2(1000,1200)}
	return {"entrance": Vector2(1000, 1040), "school_arrival": Vector2(1000, 1040), "school_door": Vector2(1000, 490)} if zone == "school_stop" else {"entrance": Vector2(1000, 1210), "school_entry": Vector2(1000, 1210)}
static func walls(zone: String) -> Array[Rect2]:
	var size := extent(zone)
	var result: Array[Rect2] = [Rect2(40,40,size.x-80,24),Rect2(40,size.y-64,size.x-80,24),Rect2(40,64,24,size.y-128),Rect2(size.x-64,64,24,size.y-128)]
	if zone == "school_stop": result.append(Rect2(100, 90, 1800, 330))
	return result
static func furniture_specs(zone: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if zone in ["school_hall", "school_passage"]: return result
	if zone == "school_workshop":
		return [{"kind":"printer3d", "rect":Rect2(250,300,420,150)}, {"kind":"laptop_bench", "rect":Rect2(950,300,480,150)}, {"kind":"electronics", "rect":Rect2(250,750,420,150)}, {"kind":"cyber_desk", "rect":Rect2(1000,750,320,110)}, {"kind":"rack", "rect":Rect2(1630,220,120,165)}]
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
	if zone == "school_hall": return [target("school_cyber_return", "Retour · salle cyber",Vector2(500,1640)),target("school_secure","Porte à droite · câblage",Vector2(850,700))]
	if zone == "school_passage": return [target("school_hall_return","Retour · porte sécurisée",Vector2(180,350)),target("school_workshop","Porte à gauche · atelier",Vector2(1400,150))]
	if zone == "school_workshop": return [target("school_passage_return","Sortie · couloir",Vector2(1000,1250)),target("school_3d","Imprimante 3D · plan de travail",Vector2(460,540)),target("school_laptops","Ordinateurs portables",Vector2(1190,540)),target("school_electronics","Électronique · instruments",Vector2(460,990)),target("school_desktop","Ordinateur fixe et écran",Vector2(1160,950))]
	if zone == "school_stop": return [target("school_enter","Entrée · salle cyber",Vector2(1000,475)), target("school_bus","Bus · retour en ville",Vector2(1550,1110))]
	var result: Array[Dictionary] = [target("school_hall","Porte · couloir du lycée",Vector2(1800,1100)),target("school_exit","Porte · parvis et bus",Vector2(1000,1270)),target("school_network","Baie réseau · découvrir",Vector2(1630,320)),target("school_course","Tableau · espace de cours",Vector2(850,220))]
	for y in [360,690]:
		for x in [250,760,1270]: result.append(target("school_pc_%d_%d" % [x,y],"Ordinateur · poste cyber",Vector2(x+160,y+180)))
	return result
static func target(id: String, label: String, at: Vector2) -> Dictionary: return {"id":id,"label":label,"at":at,"radius":95.0}
static func rooms(zone: String) -> Array[Rect2]: return [Rect2(Vector2(80,80),extent(zone)-Vector2(160,160))]
