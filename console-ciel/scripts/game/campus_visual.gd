extends Node2D
## Original vector scenery for the courtyard and the hotel bus stop.
const Layout = preload("res://scripts/game/campus_layout.gd")
const Road = preload("res://scripts/game/road_layout.gd")
var zone := "courtyard"
var furniture_only: Dictionary = {}
var furniture_anchor := Vector2.ZERO

func _draw() -> void:
	if not furniture_only.is_empty():
		draw_set_transform(-furniture_anchor)
		if furniture_only.kind == "bus": _bus_stop()
		elif furniture_only.kind == "bench": _bench(furniture_only.rect)
		return
	var size := Layout.extent(zone)
	draw_rect(Rect2(Vector2.ZERO,size),Color("edf0e8") if zone == "courtyard" else Color("e9efed"))
	if zone == "courtyard": _courtyard()
	else: _building()
	for wall in Layout.walls(zone):
		if zone == "courtyard" and wall in Road.furniture(): continue
		draw_rect(Rect2(wall.position+Vector2(4,7),wall.size),Color("bbc7c2"))
		draw_rect(wall,Color("91a59e"))
		draw_line(wall.position+Vector2(2,2),wall.position+Vector2(wall.size.x-2,2),Color("cedbd4"),3)
	if zone == "courtyard":
		_facades()
		_gardens()
		_street_furniture()
	else:
		for i in Layout.rooms().size():
			var room: Rect2 = Layout.rooms()[i]
			_text("SALLE %02d · À AMÉNAGER" % (i+1),room.position+Vector2(80,60),24)
			var door := room.position+Vector2(488,room.size.y-20)
			draw_rect(Rect2(door,Vector2(144,20)),Color("c8ac79"))
		_door(Vector2(3200,4100),"SORTIE · COUR",false)

func _courtyard() -> void:
	for x in range(64,1740,80): draw_line(Vector2(x,64),Vector2(x,1236),Color("dfe5dc"),1)
	for y in range(64,1240,80): draw_line(Vector2(64,y),Vector2(1736,y),Color("dfe5dc"),1)
	draw_rect(Rect2(700,330,400,760),Color("d5dcd6"))
	draw_rect(Rect2(765,350,270,720),Color("e8e4d6"))
	for y in [465,940]:
		var at := Vector2(900,y)
		draw_polyline(PackedVector2Array([at+Vector2(-18,15),at,at+Vector2(18,15)]),Color("75988d"),5,true)
	_text("L’HÔTEL CIEL · EN FACE",Vector2(900,460),27,true)
	draw_rect(Road.ROAD, Color("525f65"))
	draw_rect(Rect2(64, 568, 1672, 12), Color("b9b9ad"))
	draw_rect(Rect2(64, 820, 1672, 12), Color("b9b9ad"))
	for x in range(90, 1710, 90):
		if x < 740 or x > 1040: draw_rect(Rect2(x, 698, 48, 4), Color("d7d6c6"))
	for y in range(588, 813, 32): draw_rect(Rect2(805, y, 190, 18), Color("f4f0dd"))
	for x in [770, 1025]: draw_rect(Rect2(x, 592, 5, 216), Color("eee9d4"))
	_text("PASSAGE PIÉTON", Vector2(900, 548), 17, true)

func _facades() -> void:
	# Architectural details remain inside the existing solid building footprints.
	# The porch is overhead decoration: the approach to the door stays clear.
	_hotel_facade()
	_academy_facade()
	_door(Vector2(900,330),"ENTRER",true)
	_door(Vector2(900,1090),"RETOUR",false)

func _hotel_facade() -> void:
	# Limestone wings, slate mansard roof, central portico and brass fittings.
	draw_rect(Rect2(100,80,1600,250), Color("d8d1bc"))
	for x in [100, 1420]:
		draw_rect(Rect2(x,80,280,250), Color("c7c3ad"))
		draw_rect(Rect2(x+12,90,256,220), Color("e4dcc6"))
	for y in [174, 257, 318]:
		draw_rect(Rect2(108,y,1584,7), Color("b6ad94"))
		draw_line(Vector2(108,y),Vector2(1692,y),Color("f1e8d4"),3,true)
	for x in range(140, 1680, 110):
		if x > 730 and x < 1030: continue
		_facade_window(Vector2(x,184), Vector2(58,61), true)
		_facade_window(Vector2(x,269), Vector2(58,40), false)
	# A sloping roof with dormers gives the silhouette depth without moving walls.
	draw_colored_polygon(PackedVector2Array([Vector2(100,164),Vector2(130,80),Vector2(1670,80),Vector2(1700,164)]),Color("647e7c"))
	for y in [103,125,147]: draw_line(Vector2(130,y),Vector2(1670,y),Color("839994"),2,true)
	for x in [190,410,630,1110,1330,1550]:
		draw_colored_polygon(PackedVector2Array([Vector2(x-8,142),Vector2(x+30,102),Vector2(x+68,142)]),Color("e4dcc6"))
		_facade_window(Vector2(x+8,125),Vector2(44,33),false)
	draw_rect(Rect2(735,165,330,165),Color("eee3ca"))
	_text("HÔTEL CIEL",Vector2(900,205),29,true)
	_text("★ ★ ★ ★ ★",Vector2(900,232),20,true)
	# Recessed glazed entrance and four stone columns.
	draw_rect(Rect2(814,251,172,79),Color("526f70"))
	for x in [822,904]: _facade_window(Vector2(x,259),Vector2(74,67),false)
	for x in [754,790,994,1030]:
		draw_rect(Rect2(x,248,16,77),Color("c5b894"))
		draw_rect(Rect2(x+3,249,5,72),Color("f4ebd6"))
		draw_rect(Rect2(x-4,319,24,9),Color("b2a17e"))
	draw_colored_polygon(PackedVector2Array([Vector2(738,250),Vector2(760,234),Vector2(1040,234),Vector2(1062,250)]),Color("668681"))
	draw_line(Vector2(738,250),Vector2(1062,250),Color("c7ad70"),5,true)
	for x in [724,1076]:
		draw_rect(Rect2(x-5,276,10,27),Color("9b8254"))
		draw_circle(Vector2(x,280),8,Color("f1dc9f"))

func _facade_window(at: Vector2, size: Vector2, balcony: bool) -> void:
	draw_rect(Rect2(at-Vector2(4,4),size+Vector2(8,8)),Color("eee5cd"))
	draw_rect(Rect2(at,size),Color("587b80"))
	draw_rect(Rect2(at+Vector2(4,4),size-Vector2(8,8)),Color("b2ced0"))
	draw_colored_polygon(PackedVector2Array([at+Vector2(5,5),at+Vector2(size.x-5,5),at+Vector2(5,size.y-5)]),Color("d4e3df"))
	draw_line(at+Vector2(size.x/2,0),at+Vector2(size.x/2,size.y),Color("eee2c6"),3,true)
	draw_line(at+Vector2(0,size.y*.45),at+Vector2(size.x,size.y*.45),Color("eee2c6"),3,true)
	if balcony:
		var y := at.y+size.y-15
		draw_rect(Rect2(at.x-8,y+16,size.x+16,5),Color("afa486"))
		draw_line(Vector2(at.x-6,y),Vector2(at.x+size.x+6,y),Color("627874"),3,true)
		for x in range(-4,int(size.x)+7,9): draw_line(Vector2(at.x+x,y),Vector2(at.x+x,y+16),Color("627874"),2,true)

func _academy_facade() -> void:
	# The original school remains distinct from the five-star hotel opposite.
	draw_rect(Rect2(100,1090,1600,160),Color("c5d4d0"))
	for x in range(125,1660,130):
		if abs(x-900)<150: continue
		_facade_window(Vector2(x,1120),Vector2(86,64),false)
	for y in [1096,1203,1236]: draw_rect(Rect2(108,y,1584,6),Color("8fa9a2"))
	draw_rect(Rect2(746,1090,308,153),Color("e2e5d9"))
	_text("BÂTIMENT A",Vector2(900,1178),24,true)
	_text("CONSOLE CIEL",Vector2(900,1210),20,true)

func _building() -> void:
	# A 6,400 × 4,200 world, over fifty times the first room's area.
	draw_rect(Rect2(2780,64,840,4072),Color("d1dfdd"))
	draw_rect(Rect2(64,1820,6272,620),Color("d1dfdd"))
	for y in range(120,4140,120):
		draw_line(Vector2(64,y),Vector2(6336,y),Color("dbe4df"),1)
	for x in range(120,6340,120):
		draw_line(Vector2(x,64),Vector2(x,4136),Color("dbe4df"),1)
	var all_rooms := Layout.rooms()
	for i in all_rooms.size(): draw_rect(all_rooms[i],Layout.COLORS[i%4])
	for rect in Layout.furniture():
		draw_rect(Rect2(rect.position+Vector2(4,8),rect.size),Color("b8c7bf"))
		draw_rect(rect,Color("adbea8"))
	_text("GRAND ATRIUM",Vector2(3200,2080),36,true)
	_text("Les prochaines missions seront ajoutées plus tard.",Vector2(3200,2140),23,true)
	_text("ENTRÉE · BÂTIMENT B",Vector2(3200,3890),28,true)
	for x in [2940,3460]:
		for y in [360,1540,2670,3650]:
			draw_circle(Vector2(x,y)+Vector2(4,7),44,Color("b6c6ba"))
			draw_circle(Vector2(x,y),40,Color("81a08c"))
	for point in [Vector2(3200,900),Vector2(3200,3150),Vector2(1100,2130),Vector2(5300,2130)]:
		draw_arc(point,50,0,TAU,40,Color("a7bdb7"),3,true)

func _door(at: Vector2, label: String, top: bool) -> void:
	draw_rect(Rect2(at-Vector2(74,12),Vector2(148,24)),Color("527c7b"))
	draw_line(at+Vector2(0,-10),at+Vector2(0,10),Color("dbe9df"),3)
	draw_rect(Rect2(at+Vector2(-78,14 if top else -25),Vector2(156,10)),Color("cbb385"))
	_text(label,at+Vector2(0,54 if top else -40),18,true)

func _text(text: String, at: Vector2, font_size: int, centered := false) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x if centered else 0.0
	draw_string(font,at-Vector2(width*.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("52756e"))

func _gardens() -> void:
	for rect in Road.gardens():
		draw_rect(rect.grow(-6), Color("bfd0b4"))
		for offset in [90, 240]:
			var at := rect.position + Vector2(offset, 55)
			draw_circle(at + Vector2(5, 8), 39, Color("9caf98"))
			draw_circle(at, 36, Color("6e927a"))
			draw_arc(at, 26, PI, TAU, 20, Color("b6cf9e"), 4, true)

func _street_furniture() -> void:
	for rect in Road.barriers():
		draw_rect(rect, Color("637d7c"))
		draw_line(rect.position + Vector2(0, 3), Vector2(rect.end.x, rect.position.y + 3), Color("cfdbd3"), 3)
		for x in range(int(rect.position.x + 15), int(rect.end.x), 42): draw_rect(Rect2(x, rect.position.y - 7, 6, 27), Color("526d6c"))

func _bench(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(4, 8), rect.size), Color("bec3b8"))
	draw_rect(rect, Color("9e8161"))
	for y in [7, 17, 27]: draw_line(rect.position + Vector2(4, y), Vector2(rect.end.x - 4, rect.position.y + y), Color("c6ae87"), 4)

func _bus_stop() -> void:
	# Kept in the broad east walkway, clear of both garden collision rectangles.
	var at := Vector2(1180, 840)
	draw_rect(Rect2(at + Vector2(-7, -62), Vector2(14, 126)), Color("607d7b"))
	draw_circle(at - Vector2(0, 72), 32, Color("e6d5aa"))
	draw_circle(at - Vector2(0, 72), 26, Color("4d787d"))
	var font := ThemeDB.fallback_font
	draw_string(font, at + Vector2(-23, -65), "BUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("f5eed9"))
	draw_rect(Rect2(at + Vector2(-45, -23), Vector2(90, 52)), Color("f5efdf"))
	_text("sudo hack", at + Vector2(0, -2), 14, true)
	_text("CTF", at + Vector2(0, 20), 13, true)
	_text("ARRÊT DE BUS", Vector2(1150, 1024), 18, true)
