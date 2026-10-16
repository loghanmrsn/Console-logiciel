extends Node2D
## Original vector scenery: quiet courtyards, a large atrium and sixteen rooms.
const Layout = preload("res://scripts/game/campus_layout.gd")
var zone := "courtyard"

func _draw() -> void:
	var size := Layout.extent(zone)
	draw_rect(Rect2(Vector2.ZERO,size),Color("edf0e8") if zone == "courtyard" else Color("e9efed"))
	if zone == "courtyard": _courtyard()
	else: _building()
	for wall in Layout.walls(zone):
		draw_rect(Rect2(wall.position+Vector2(4,7),wall.size),Color("bbc7c2"))
		draw_rect(wall,Color("91a59e"))
		draw_line(wall.position+Vector2(2,2),wall.position+Vector2(wall.size.x-2,2),Color("cedbd4"),3)
	if zone == "courtyard":
		_facades()
		_gardens()
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
	for y in [510,680,850]:
		var at := Vector2(900,y)
		draw_polyline(PackedVector2Array([at+Vector2(-18,15),at,at+Vector2(18,15)]),Color("75988d"),5,true)
	_text("L’IMMEUBLE D’EN FACE",Vector2(900,460),27,true)

func _facades() -> void:
	for rect in [Rect2(100,80,1600,250),Rect2(100,1090,1600,160)]:
		draw_rect(rect,Color("c6d4d4"))
		for x in range(180,1640,180):
			if abs(x-900)>140:
				draw_rect(Rect2(x,rect.position.y+45,96,70),Color("718d93"))
				draw_rect(Rect2(x+6,rect.position.y+51,84,58),Color("b7d4d8"))
	_text("BÂTIMENT B · NOUVELLE EXPLORATION",Vector2(900,220),26,true)
	_text("BÂTIMENT A · CONSOLE CIEL",Vector2(900,1210),24,true)
	_door(Vector2(900,330),"ENTRER",true)
	_door(Vector2(900,1090),"RETOUR",false)

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
	for x in [190,1280]:
		draw_rect(Rect2(x+8,458,314,384),Color("bfd0b4"))
		for y in [530,660,790]:
			var at := Vector2(x+165,y)
			draw_circle(at+Vector2(7,10),48,Color("a0b59a"))
			draw_circle(at,46,Color("7e9d82"))
			draw_arc(at,30,PI,TAU,16,Color("a9bf9f"),3,true)
