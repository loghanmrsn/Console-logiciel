extends RefCounted
## One geometry source for solid furniture, scenery, interactions and the map.
const Facade = preload("res://scripts/game/school_facade_art.gd")
const Ateliers = preload("res://scripts/game/school_ateliers.gd")
const EXTERIOR := Rect2(100,90,1800,330)
static func extent(zone: String) -> Vector2:
	if zone in Ateliers.IDS: return Ateliers.extent(zone)
	if zone == "school_network_lab": return Vector2(2200,1600)
	return Vector2(1000,1800) if zone == "school_hall" else (Vector2(3000,700) if zone == "school_passage" else Vector2(2000,1400))
static func title(zone: String) -> String:
	if zone in Ateliers.IDS: return Ateliers.TITLES[zone]
	if zone == "school_network_lab": return "City CIEL · laboratoire IPv4 / IPv6"
	if zone in ["school_hall", "school_passage", "school_workshop"]: return {"school_hall":"Lycée · couloir et porte sécurisée", "school_passage":"Lycée · liaison vers les ateliers", "school_workshop":"City CIEL · atelier informatique et électronique"}[zone]
	return "Louise Michel · " + ("parvis et arrêt" if zone == "school_stop" else "salle cyber")
static func checkpoints(zone: String) -> Dictionary:
	if zone in Ateliers.NEW_IDS: return {"entrance":Ateliers.entry(zone),zone+"_entry":Ateliers.entry(zone)}
	if zone == "school_hall": return {"entrance": Vector2(500,1550), "school_hall_entry": Vector2(500,1550)}
	if zone == "school_passage": return {"entrance": Vector2(250,350), "school_passage_entry": Vector2(250,350), "school_passage_tne":Vector2(2150,260), "school_passage_meeting":Vector2(900,440), "school_passage_fed":Vector2(2700,260)}
	if zone == "school_workshop": return {"entrance": Ateliers.entry(zone), "school_workshop_entry": Ateliers.entry(zone), "city_workshop_return":Vector2(150,730)}
	if zone == "school_network_lab": return {"entrance":Vector2(1000,1370), "city_lab_entry":Vector2(1000,1370)}
	return {"entrance": Vector2(1000, 1040), "school_arrival": Vector2(1000, 1040), "school_door": Facade.entrance(EXTERIOR,80)} if zone == "school_stop" else {"entrance": Vector2(1000, 1210), "school_entry": Vector2(1000, 1210)}
static func walls(zone: String) -> Array[Rect2]:
	var size := extent(zone)
	var result: Array[Rect2] = [Rect2(40,40,size.x-80,24),Rect2(40,size.y-64,size.x-80,24),Rect2(40,64,24,size.y-128),Rect2(size.x-64,64,24,size.y-128)]
	if zone == "school_workshop":
		# A recessed, solid-backed doorway on the left; no walk into the void.
		result.remove_at(2)
		result.append_array([Rect2(40,64,24,556),Rect2(40,820,24,size.y-884),Rect2(16,620,24,200)])
	if zone == "school_network_lab":
		result.remove_at(1)
		result.append_array([Rect2(40,1536,860,24),Rect2(1100,1536,1060,24),Rect2(900,1576,200,24),Rect2(1460,160,28,330),Rect2(1460,1040,28,260)])
	result.append_array(Ateliers.walls(zone))
	if zone == "school_stop": result.append(EXTERIOR)
	return result
static func furniture_specs(zone: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if zone in Ateliers.NEW_IDS: return Ateliers.furniture(zone)
	if zone in ["school_hall", "school_passage"]: return result
	if zone == "school_network_lab":
		for x in [260,840]:
			for y in [500,930]:
				result.append({"kind":"cyber_desk", "rect":Rect2(x,y,320,110)})
				result.append({"kind":"chair", "rect":Rect2(x+30,y+150,70,40)})
		result.append_array([{"kind":"network_console", "rect":Rect2(1560,650,420,160)}, {"kind":"rack", "rect":Rect2(1780,230,120,165)}, {"kind":"rack", "rect":Rect2(1970,230,120,165)}, {"kind":"whiteboard", "rect":Rect2(550,200,600,30)}])
		return result
	if zone == "school_workshop":
		result = [{"kind":"printer3d", "rect":Rect2(250,300,420,150)}, {"kind":"laptop_bench", "rect":Rect2(950,300,480,150)}, {"kind":"electronics", "rect":Rect2(250,750,420,150)}, {"kind":"cyber_desk", "rect":Rect2(1000,750,320,110)}, {"kind":"rack", "rect":Rect2(1630,220,120,165)}]
		result.append_array(Ateliers.extras(zone))
		return result
	if zone == "school_stop":
		for x in [610, 1450]: result.append({"kind":"garden", "rect":Rect2(x,600,270,160)})
		result.append({"kind":"shelter", "rect":Rect2(1390,930,320,120)})
		result.append({"kind":"sign", "rect":Rect2(660,430,180,45)})
	else:
		for y in [360, 690]:
			for x in [250, 760, 1270]:
				result.append({"kind":"cyber_desk", "rect":Rect2(x,y,320,110)})
		for x in [1490, 1670]: result.append({"kind":"rack", "rect":Rect2(x,100,120,165)})
		result.append({"kind":"whiteboard", "rect":Rect2(580,120,520,30)})
		result.append({"kind":"sign", "rect":Rect2(180,120,180,45)})
	result.append_array(Ateliers.extras(zone))
	for spec in result.duplicate():
		if spec.kind == "cyber_desk": result.append({"kind":"chair", "rect":Rect2(spec.rect.position+Vector2(30,145),Vector2(70,40))})
	return result
static func interactions(zone: String) -> Array[Dictionary]:
	if zone in Ateliers.NEW_IDS: return Ateliers.targets(zone)
	if zone == "school_network_lab": return [target("school_city_return","Porte · revenir à City CIEL",Vector2(1000,1460)),target("school_city_lesson","Tableau de cours · IPv4, IPv6 et routage",Vector2(850,330)),target("school_city_ipv4","PC-01 · configuration IPv4",Vector2(420,740)),target("school_city_ipv6","PC-02 · configuration IPv6",Vector2(1000,740)),target("school_city_routing","Routeur et switch · relier les réseaux",Vector2(1770,940))]
	if zone == "school_hall": return [target("school_cyber_return", "Retour · salle cyber",Vector2(500,1640)),target("school_secure","Porte à droite · câblage",Vector2(850,700))]
	if zone == "school_passage": return [target("school_hall_return","Retour · porte sécurisée",Vector2(180,350)),target("school_workshop","Atelier 1 · CIEL",Vector2(1400,150)),target("school_tne","Atelier 2 · 2TNE",Vector2(2150,150)),target("school_meeting","Atelier 3 · réunion",Vector2(900,550)),target("school_fed","Atelier 5 · BTS FED",Vector2(2700,150))]
	if zone == "school_workshop":
		var items: Array[Dictionary] = [target("school_city_door","Porte à gauche · salle réseau City CIEL",Vector2(150,730)),target("school_passage_return","Sortie · couloir",Ateliers.entry(zone)+Vector2(0,70)),target("school_3d","Imprimante 3D · plan de travail",Vector2(460,540)),target("school_laptops","Ordinateurs portables",Vector2(1190,540)),target("school_electronics","Électronique · instruments",Vector2(460,990)),target("school_desktop","Ordinateur fixe et écran",Vector2(1160,950))]
		items.append_array(Ateliers.targets(zone))
		return items
	if zone == "school_stop": return [target("school_enter","Entrée · salle cyber",Facade.entrance(EXTERIOR)), target("school_bus","Bus · retour en ville",Vector2(1550,1110))]
	var result: Array[Dictionary] = [target("school_hall","Porte · couloir du lycée",Vector2(1800,1100)),target("school_exit","Porte · parvis et bus",Vector2(1000,1270)),target("school_network","Baie réseau · découvrir",Vector2(1630,320)),target("school_course","Tableau · espace de cours",Vector2(850,220))]
	for y in [360,690]:
		for x in [250,760,1270]: result.append(target("school_pc_%d_%d" % [x,y],"Ordinateur · poste cyber",Vector2(x+160,y+180)))
	result.append_array(Ateliers.targets(zone))
	return result
static func target(id: String, label: String, at: Vector2) -> Dictionary: return {"id":id,"label":label,"at":at,"radius":95.0}
static func rooms(zone: String) -> Array[Rect2]: return [Rect2(Vector2(80,80),extent(zone)-Vector2(160,160))]
