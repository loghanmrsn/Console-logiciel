extends "res://scripts/game/hotel_visual.gd"
## Original 2D reconstruction inspired by the supplied photograph, not a floor survey.
const School = preload("res://scripts/game/school_layout.gd")
const LOGO = preload("res://assets/lycee/logo_louise_michel.jpg")
const SCHOOL_STONE := Color("e6e1d5")
const ROSE := Color("bda3a0")
const METAL := Color("6e858a")
const DARK := Color("283c49")

func _draw() -> void:
	if not furniture_only.is_empty():
		draw_set_transform(-furniture_anchor)
		_prop_art(str(furniture_only.kind), furniture_only.rect)
		return
	draw_rect(Rect2(0,0,2000,1400), Color("8b9695") if zone == "school_stop" else Color("dce3e5"))
	if zone in ["school_hall", "school_passage", "school_workshop"]: _atelier_area()
	elif zone == "school_stop": _exterior()
	else: _cyber()
	for wall in School.walls(zone):
		if zone == "school_stop" and wall.size.y == 330: continue
		draw_rect(Rect2(wall.position+Vector2(4,6),wall.size),Color("657b7c"))
		draw_rect(wall,Color("b6c4c0"))
		draw_line(wall.position,wall.position+Vector2(wall.size.x,0),Color("e7ece5"),3)

func _exterior() -> void:
	# Low, horizontal school frontage: pale concrete, rose fascia and glazed vestibule.
	for y in range(440,1300,80): draw_line(Vector2(80,y),Vector2(1920,y),Color("929b98"),1)
	draw_rect(Rect2(110,430,1780,24),Color("647878"))
	draw_rect(Rect2(100,100,1800,310),SCHOOL_STONE)
	draw_rect(Rect2(100,90,1800,48),ROSE)
	draw_rect(Rect2(100,90,1800,8),Color("e7dfcf"))
	for x in range(160,1870,180):
		draw_rect(Rect2(x,182,128,154),Color("627a80"))
		draw_rect(Rect2(x+7,190,114,135),Color("bdd2d0"))
		draw_rect(Rect2(x+7,190,114,55),Color("dddcd2"))
		for y in range(193,241,6): draw_line(Vector2(x+8,y),Vector2(x+120,y),Color("c5c8bf"),1)
		draw_line(Vector2(x+64,246),Vector2(x+64,325),Color("e4e7df"),3)
		draw_rect(Rect2(x+133,145,13,250),Color("c3bfb0"))
	# Glass entry projects ahead of the window ribbon.
	draw_rect(Rect2(840,145,320,280),METAL)
	for x in [850, 955, 1060]:
		draw_rect(Rect2(x,160,94,249),Color("acc8c8"))
		draw_line(Vector2(x+8,190),Vector2(x+78,230),Color("cfe0db"),5)
		draw_line(Vector2(x+46,160),Vector2(x+46,409),Color("e0e3d9"),4)
	draw_rect(Rect2(828,137,344,16),Color("dedfd3"))
	draw_line(Vector2(997,320),Vector2(997,346),DARK,4)
	_text("LYCÉE LOUISE MICHEL",Vector2(1000,117),22,DARK,true)
	_text("RUFFEC · ENTRÉE",Vector2(1000,470),19,DARK,true)
	# Quiet landscaping and route to a clearly identified bus stop.
	draw_rect(Rect2(880,500,240,740),Color("c9c7b8"))
	for y in range(520,1210,60): draw_line(Vector2(880,y),Vector2(1120,y),Color("b6b7ab"),1)
	_text("2 · LYCÉE LOUISE MICHEL",Vector2(1560,1175),20,DARK,true)
	_text("BUS · RETOUR EN VILLE",Vector2(1560,1210),16,DARK,true)

func _cyber() -> void:
	for x in range(80,1920,120): draw_line(Vector2(x,64),Vector2(x,1336),Color("cbd4d6"),1)
	for y in range(80,1330,120): draw_line(Vector2(64,y),Vector2(1936,y),Color("cbd4d6"),1)
	for x in [180,580,980,1380]:
		draw_rect(Rect2(x,72,280,16),Color("b2ccd0"))
		draw_line(Vector2(x,90),Vector2(x+260,90),Color("f6f7e8"),5)
	_text("SALLE CYBER · LOUISE MICHEL",Vector2(1000,105),24,DARK,true)
	_text("POSTES PÉDAGOGIQUES",Vector2(770,1030),21,DARK,true)
	_text("RÉSEAU ISOLÉ",Vector2(1630,355),18,DARK,true)
	draw_rect(Rect2(860,1300,280,18),METAL)
	_text("SORTIE · PARVIS / BUS",Vector2(1000,1285),19,DARK,true)
	# Cable paths run along the wall and between rows, outside the walking lanes.
	draw_polyline(PackedVector2Array([Vector2(1810,260),Vector2(1810,930),Vector2(170,930)]),Color("9aabad"),8,true)
	for y in [365,695]: draw_line(Vector2(170,y),Vector2(1810,y),Color("8ca4a7"),3)

func _prop_art(kind: String, rect: Rect2) -> void:
	draw_style_box(_shadow_style(), Rect2(rect.position+Vector2(5,9),rect.size))
	match kind:
		"printer3d", "laptop_bench", "electronics":
			draw_rect(rect,Color("bba98a"))
			var at := rect.position + Vector2(40,-90)
			if kind == "printer3d":
				draw_rect(Rect2(at,Vector2(200,190)),DARK)
				draw_rect(Rect2(at+Vector2(14,14),Vector2(172,140)),Color("8ba9ac"))
				draw_rect(Rect2(at+Vector2(40,130),Vector2(120,10)),METAL)
				draw_line(at+Vector2(100,16),at+Vector2(100,90),DARK,10)
				draw_rect(Rect2(at+Vector2(75,98),Vector2(50,32)),Color("dba77a"))
				draw_circle(at+Vector2(232,48),33,DARK)
				draw_circle(at+Vector2(232,48),19,Color("dba77a"))
			elif kind == "laptop_bench":
				for x in [0,220]:
					var a := at+Vector2(x,25)
					draw_rect(Rect2(a,Vector2(170,95)),DARK)
					draw_rect(Rect2(a+Vector2(8,8),Vector2(154,76)),Color("92b5b9"))
					draw_rect(Rect2(a+Vector2(-8,98),Vector2(186,48)),METAL)
					for y in [108,120,132]: draw_line(a+Vector2(6,y),a+Vector2(162,y),DARK,2)
			else:
				draw_rect(Rect2(at+Vector2(10,50),Vector2(120,85)),Color("557e69"))
				for x in range(30,120,20): draw_circle(at+Vector2(x,80),5,Color("e5c48e"))
				draw_rect(Rect2(at+Vector2(190,35),Vector2(95,95)),DARK)
				draw_rect(Rect2(at+Vector2(201,46),Vector2(73,48)),Color("a1cbb5"))
		"cyber_desk":
			draw_rect(rect,Color("bdac8e"))
			for offset in [26,54,86]: draw_line(rect.position+Vector2(10,offset),rect.position+Vector2(rect.size.x-10,offset),Color("b4a385"),1)
			draw_rect(Rect2(rect.position,Vector2(rect.size.x,7)),Color("e1d4b8"))
			var a := rect.position
			draw_rect(Rect2(a+Vector2(82,-58),Vector2(156,87)),DARK)
			draw_rect(Rect2(a+Vector2(89,-51),Vector2(142,70)),Color("8eafb6"))
			for y in [0,14,28]: draw_line(a+Vector2(103,-38+y),a+Vector2(170+y,-38+y),Color("d0e8dd"),3)
			draw_rect(Rect2(a+Vector2(153,29),Vector2(14,17)),METAL)
			draw_rect(Rect2(a+Vector2(125,43),Vector2(70,8)),DARK)
			draw_rect(Rect2(a+Vector2(82,66),Vector2(140,24)),Color("e7e9df"))
			for x in range(90,216,12): draw_line(a+Vector2(x,70),a+Vector2(x,85),METAL,1)
			for y in [73,79]: draw_line(a+Vector2(85,y),a+Vector2(219,y),METAL,1)
			draw_circle(a+Vector2(252,78),10,Color("e4e7e2"))
			draw_rect(Rect2(a+Vector2(280,20),Vector2(25,70)),DARK)
			draw_circle(a+Vector2(293,31),3,Color("8dd0aa"))
		"chair":
			draw_rect(rect,Color("47616b"))
			draw_line(rect.position+Vector2(0,8),rect.position+Vector2(rect.size.x,8),Color("9bb3b6"),5)
			draw_line(rect.get_center(),rect.get_center()+Vector2(0,25),DARK,5)
		"rack":
			draw_rect(rect,DARK)
			for y in range(int(rect.position.y)+12,int(rect.end.y)-10,26):
				draw_rect(Rect2(rect.position.x+8,y,104,20),METAL)
				for x in range(int(rect.position.x)+17,int(rect.end.x)-12,14): draw_circle(Vector2(x,y+8),2,Color("a5dab4"))
		"whiteboard":
			draw_rect(Rect2(rect.position-Vector2(0,55),Vector2(rect.size.x,85)),METAL)
			draw_rect(Rect2(rect.position+Vector2(6,-49),Vector2(rect.size.x-12,73)),Color("f0f3e8"))
			_text("CYBERSÉCURITÉ · OBSERVER / COMPRENDRE / TESTER",rect.get_center()+Vector2(0,-22),15,DARK,true)
		"sign":
			draw_rect(Rect2(rect.position-Vector2(8,125),Vector2(196,170)),METAL)
			draw_rect(Rect2(rect.position-Vector2(3,120),Vector2(186,160)),Color.WHITE)
			draw_texture_rect(LOGO,Rect2(rect.position+Vector2(52,-116),Vector2(69,104)),false)
			_text("LOUISE MICHEL",rect.get_center()+Vector2(0,-5),14,DARK,true)
			_text("RUFFEC",rect.get_center()+Vector2(0,14),12,DARK,true)
		"garden":
			draw_rect(rect,Color("b6b7a8"))
			draw_rect(rect.grow(-10),Color("778b6b"))
			for i in range(15):
				var at := rect.position+Vector2(25+(i*53)%220,22+(i*37)%110)
				draw_circle(at,14,Color("8c9c78"))
				draw_circle(at+Vector2(3,-7),3,Color("ded4e0"))
		"shelter":
			draw_rect(rect,Color("adc4bf"))
			for x in [rect.position.x+10,rect.end.x-10]: draw_line(Vector2(x,rect.position.y),Vector2(x,rect.end.y),DARK,6)
			draw_rect(Rect2(rect.position-Vector2(10,10),Vector2(rect.size.x+20,18)),DARK)
			draw_rect(Rect2(rect.position+Vector2(25,80),Vector2(270,17)),Color("aa9477"))

var _soft_shadow: StyleBoxFlat
func _shadow_style() -> StyleBoxFlat:
	if _soft_shadow == null:
		_soft_shadow = StyleBoxFlat.new()
		_soft_shadow.bg_color = Color(0.15,0.22,0.24,0.12)
		_soft_shadow.set_corner_radius_all(6)
		_soft_shadow.shadow_color = Color(0.15,0.22,0.24,0.10)
		_soft_shadow.shadow_size = 6
	return _soft_shadow

func _atelier_area() -> void:
	var size := School.extent(zone)
	draw_rect(Rect2(Vector2.ZERO,size),Color("dce3e5"))
	for x in range(80,int(size.x)-80,120): draw_line(Vector2(x,64),Vector2(x,size.y-64),Color("cbd4d6"),1)
	for y in range(80,int(size.y)-60,120): draw_line(Vector2(64,y),Vector2(size.x-64,y),Color("cbd4d6"),1)
	_text(School.title(zone).to_upper(),Vector2(size.x/2,110),22,DARK,true)
	for target in School.interactions(zone):
		if target.id in ["school_secure","school_workshop","school_cyber_return","school_hall_return","school_passage_return"]:
			draw_rect(Rect2(target.at-Vector2(72,50),Vector2(144,14)),METAL)
			_text(target.label,target.at+Vector2(0,-65),16,DARK,true)
	if zone == "school_passage":
		_text("ATELIER ← · 10 m",Vector2(1400,250),22,DARK,true)
		for x in range(450,2600,300): draw_line(Vector2(x,340),Vector2(x+80,340),Color("90a6a6"),4)
