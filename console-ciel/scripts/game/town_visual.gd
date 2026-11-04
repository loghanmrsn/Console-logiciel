extends Node2D
## Detailed, original 2D town scenery; solid bases are owned by TownLayout.
const Storefront = preload("res://scripts/game/storefront_art.gd")
const SchoolFacade = preload("res://scripts/game/school_facade_art.gd")
const Town = preload("res://scripts/game/town_layout.gd")
const Art = preload("res://scripts/game/exterior_painter.gd")
const Details = preload("res://scripts/game/town_details.gd")
var furniture_only: Dictionary = {}
var use_baked_art := true
var furniture_anchor := Vector2.ZERO
var water_time := 0.0
func _ready() -> void:
	if furniture_only.is_empty(): add_child(preload("res://scripts/game/town_streets.gd").new())
	if not furniture_only.is_empty() and furniture_only.kind == "signal":
		var light := preload("res://scripts/game/road_traffic.gd").PedestrianSignal.new()
		light.position = furniture_only.rect.get_center()-furniture_anchor
		light.add_to_group("town_signals")
		add_child(light)
	set_process(not furniture_only.is_empty() and furniture_only.kind == "fountain")
func _process(delta: float) -> void:
	if not is_visible_in_tree() or SettingsService.current.reduce_motion: return
	water_time += delta
	queue_redraw()
func _draw() -> void:
	if not furniture_only.is_empty():
		draw_set_transform(-furniture_anchor)
		if use_baked_art and preload("res://scripts/game/baked_art.gd").draw_town(self,furniture_only): return
		_prop(furniture_only)
		return
	# The paving and garden silhouettes remain within their existing grounds.
	Art.rounded(self,Town.SCHOOL_GROUNDS,Color("c6c7b7"),22)
	Art.rounded(self,Town.SCHOOL_GROUNDS.grow(-14),Color("969f90"),18)
	var forecourt := Rect2(6790,900,2020,310)
	Art.rounded(self,forecourt,Color("c9c9bb"),12)
	for row in range(5):
		var y := 920 + row * 60
		draw_line(Vector2(6800,y),Vector2(8800,y),Color("b9bcae"),1,true)
		for x in range(6820 + (row % 2) * 60,8800,120): draw_line(Vector2(x,y),Vector2(x,y+58),Color("c1c3b5"),1,true)
	Art.rounded(self,Rect2(7270,900,180,345),Color("e1d8c4"),5)
	Art.rounded(self,Town.FORMER_SCHOOL,Color("b6c6a8"),28)
	Art.rounded(self,Town.PARK,Color("afc59d"),28)
	for i in range(23):
		var at := Town.PARK.position + Vector2(55 + (i * 173) % 1330,55 + (i * 127) % 740)
		Art.ellipse(self,at,Vector2(45 + i % 27,18 + i % 13),Color("b8cca5") if i % 2 else Color("a6be96"))
	Art.rounded(self,Rect2(2840,1660,180,850),Color("c3c4a9"),22)
	Art.rounded(self,Rect2(2210,2000,1450,140),Color("c3c4a9"),20)
	Art.rounded(self,Rect2(2850,1660,160,850),Color("ded7c0"),20)
	Art.rounded(self,Rect2(2210,2010,1450,120),Color("ded7c0"),18)
	for y in range(1680,2490,76): draw_line(Vector2(2858,y),Vector2(3002,y),Color("d0cbb5"),1,true)
	for x in range(2240,3640,76): draw_line(Vector2(x,2018),Vector2(x,2122),Color("d0cbb5"),1,true)
	_text("PARC DES TILLEULS",Vector2(2940,1630),27)
	_text("CENTRE · RITZ / CONSOLE CIEL ←",Vector2(2630,1260),24)
func _prop(spec: Dictionary) -> void:
	var rect: Rect2 = spec.rect
	var at := rect.position
	if spec.kind not in ["tree","island","signal","lamp"]: Art.contact(self,rect,.8)
	if Details.draw(self,spec):
		if spec.kind=="fountain": Details.fountain_water(self,rect,water_time)
		return
	match str(spec.kind):
		"building": _building(spec)
		"cafe_table", "cafe_chair", "menu_board": Storefront.furniture(self,spec)
		"campus_planter", "campus_bench", "campus_sign", "campus_arrow": SchoolFacade.prop(self,spec)
		"tree": Art.tree(self,rect,int(at.x/100))
		"island":
			var center := rect.get_center()
			draw_circle(center,rect.size.x*.5,Color("c8c6b0"))
			draw_circle(center-Vector2(0,2),rect.size.x*.5-5,Color("aab68c"))
			Art.flowers(self,rect.grow(-15),int(at.x))
			Art.tree(self,Rect2(center-Vector2(22,25),Vector2(44,44)),2)
		"shelter":
			Art.rounded(self,Rect2(at-Vector2(6,90),Vector2(rect.size.x+12,112)),Color("a6c0bf"),4)
			draw_colored_polygon(PackedVector2Array([at+Vector2(6,-82),at+Vector2(60,-82),at+Vector2(15,14),at+Vector2(6,14)]),Color("c9dbd4"))
			draw_line(at+Vector2(73,-88),at+Vector2(73,18),Color("6b8c8c"),3,true)
			draw_rect(Rect2(at+Vector2(17,-7),Vector2(rect.size.x-34,14)),Color("9e8968"))
			for x in [at.x,rect.end.x]: draw_line(Vector2(x,at.y-90),Vector2(x,rect.end.y),Color("405e66"),7)
			Art.rounded(self,Rect2(at-Vector2(15,103),Vector2(rect.size.x+30,18)),Color("355962"),6)
			draw_line(at+Vector2(-10,-102),at+Vector2(rect.size.x+10,-102),Color("8caaa6"),2,true)
			_text("BUS · CENTRE",rect.get_center()-Vector2(0,120),18)
			_text("1 · SUDO HACK / 2 · LYCÉE",rect.get_center()-Vector2(0,65),11)
			_text("1 € = 10 POINTS",rect.get_center()-Vector2(0,44),12)
		"bench":
			for x in [at.x+14,rect.end.x-14]: Art.rounded(self,Rect2(x,at.y+4,8,rect.size.y+2),Color("526e65"),2)
			for y in [3,15,27]:
				Art.rounded(self,Rect2(at+Vector2(0,y),Vector2(rect.size.x,9)),Color("ab8f68"),3)
				draw_line(at+Vector2(5,y+2),Vector2(rect.end.x-5,at.y+y+2),Color("cbb18a"),1.5,true)
				for x in [at.x+17,rect.end.x-11]: draw_circle(Vector2(x,at.y+y+5),1.5,Color("70644f"))
		"lamp":
			Art.ellipse(self,rect.get_center()+Vector2(3,5),Vector2(16,7),Color(.14,.20,.20,.16))
			draw_line(rect.get_center(),rect.get_center()-Vector2(0,130),Color("5b7476"),7)
			draw_line(rect.get_center()-Vector2(1,2),rect.get_center()-Vector2(1,125),Color("93a49a"),2,true)
			Art.rounded(self,Rect2(rect.get_center()-Vector2(13,145),Vector2(26,26)),Color("eddfac"),8)
			draw_arc(rect.get_center()-Vector2(0,132),16,PI,TAU,16,Color("49635f"),4,true)
func _building(spec: Dictionary) -> void:
	var rect: Rect2 = spec.rect
	if spec.get("school",false):
		SchoolFacade.draw_facade(self,rect)
		return
	var index := int(spec.index)
	var palettes: Array[Color] = [Color("dfd0b2"),Color("cbd4c2"),Color("d8bcb0"),Color("c3d0ce"),Color("ddd4bb"),Color("cebfac")]
	var base: Color = palettes[index%palettes.size()]
	Art.plaster(self,rect,base,index)
	if index % 5 == 2: Art.masonry(self,rect,Color(base.darkened(.18),.24),18,49)
	draw_rect(Rect2(rect.position+Vector2(0,9),Vector2(13,rect.size.y-9)),base.darkened(.12))
	draw_rect(Rect2(rect.end-Vector2(11,rect.size.y-9),Vector2(11,rect.size.y-9)),base.darkened(.10))
	for y in range(int(rect.position.y)+38,int(rect.end.y)-9,29):
		for x in [rect.position.x+3,rect.end.x-14]:
			draw_rect(Rect2(x,y,11,22),base.lightened(.12))
	Art.rounded(self,Rect2(rect.position+Vector2(3,rect.size.y-13),Vector2(rect.size.x-6,13)),Color("b1a68b"),2)
	_roof(rect,index)
	# A projecting string course and eave shadow separate the facade planes.
	draw_rect(Rect2(rect.position+Vector2(11,46),Vector2(rect.size.x-22,7)),Color(.21,.29,.28,.14))
	draw_line(rect.position+Vector2(10,52),rect.position+Vector2(rect.size.x-10,52),base.lightened(.20),3,true)
	for x in range(int(rect.position.x)+35,int(rect.end.x)-30,85):
		for y in range(int(rect.position.y)+65,int(rect.end.y)-70,65):
			if Rect2(x,y,43,40).intersects(Storefront.sign_rect(rect).grow(4)): continue
			_window(Rect2(x,y,43,40),index)
	var door := Vector2(rect.get_center().x,rect.end.y-52)
	Art.rounded(self,Rect2(door-Vector2(32,4),Vector2(64,56)),base.darkened(.24),3)
	draw_rect(Rect2(door-Vector2(26,0),Vector2(52,52)),Color("46666c"))
	draw_rect(Rect2(door+Vector2(-21,4),Vector2(18,41)),Color("92afb0"))
	draw_rect(Rect2(door+Vector2(4,4),Vector2(18,41)),Color("77999d"))
	draw_line(door+Vector2(0,2),door+Vector2(0,50),Color("cdd9cc"),3,true)
	for x in [-6,6]: draw_line(door+Vector2(x,25),door+Vector2(x,35),Color("d2b67c"),2,true)
	draw_line(door+Vector2(-30,53),door+Vector2(30,53),Color("e9ddc2"),3,true)
	if index < 22 or index > 26:
		var awning := Rect2(rect.position+Vector2(18,rect.size.y-85),Vector2(rect.size.x-36,24))
		_awning(awning,index)
	# Rainwater pipe is narrow and separate from the shop door and sign.
	draw_line(rect.position+Vector2(rect.size.x-20,47),rect.end-Vector2(20,17),base.darkened(.25),3,true)
	draw_line(rect.position+Vector2(rect.size.x-21,48),rect.end-Vector2(21,17),base.lightened(.15),1,true)
	Storefront.sign(self,spec)

func _roof(r: Rect2, index: int) -> void:
	var at := r.position
	var width := r.size.x
	var slate := Color("617878") if index % 2 == 0 else Color("9c7665")
	var profile := index % 4
	var shape := PackedVector2Array()
	if profile == 0:
		shape = PackedVector2Array([at+Vector2(0,27),at+Vector2(32,-44),at+Vector2(width-42,-44),at+Vector2(width,27)])
	elif profile == 1:
		shape = PackedVector2Array([at+Vector2(0,28),at+Vector2(0,-7),at+Vector2(width*.5,-69),at+Vector2(width,-7),at+Vector2(width,28)])
	elif profile == 2:
		shape = PackedVector2Array([at+Vector2(0,34),at+Vector2(15,-5),at+Vector2(48,-41),at+Vector2(width-48,-41),at+Vector2(width-15,-5),at+Vector2(width,34)])
	else:
		shape = PackedVector2Array([at+Vector2(0,28),at+Vector2(29,-32),at+Vector2(width*.63,-32),at+Vector2(width*.68,-52),at+Vector2(width-28,-52),at+Vector2(width,28)])
	draw_colored_polygon(shape,slate)
	for row in range(4):
		var y := -17.0 + row * 13.0
		var inset := 48.0 if row < 2 else 20.0
		draw_line(at+Vector2(inset,y),at+Vector2(width-inset,y),slate.lightened(.11),1,true)
		for x in range(int(inset)+13+(row%2)*17,int(width-inset)-10,35): draw_line(at+Vector2(x,y+2),at+Vector2(x-3,y+11),slate.darkened(.12),1,true)
	if profile in [0,2]:
		for x in [width*.24,width*.72]:
			var dormer := at+Vector2(x,4)
			draw_colored_polygon(PackedVector2Array([dormer+Vector2(-21,-1),dormer+Vector2(0,-24),dormer+Vector2(21,-1)]),Color("e2d5bb"))
			draw_rect(Rect2(dormer+Vector2(-17,-1),Vector2(34,27)),Color("d3c8ae"))
			draw_rect(Rect2(dormer+Vector2(-12,2),Vector2(24,20)),Color("88a7aa"))
			draw_line(dormer+Vector2(0,2),dormer+Vector2(0,22),Color("eee5cf"),2,true)
	if index % 3 == 0:
		draw_rect(Rect2(at+Vector2(width*.80,-58),Vector2(21,30)),Color("b3a38e"))
		draw_rect(Rect2(at+Vector2(width*.80-3,-61),Vector2(27,6)),Color("d8cbb4"))
	draw_line(at+Vector2(0,29),at+Vector2(width,29),slate.darkened(.24),5,true)
	draw_line(at+Vector2(0,27),at+Vector2(width,27),slate.lightened(.25),2,true)

func _window(r: Rect2, index: int) -> void:
	Art.rounded(self,r.grow(5),Color("e9dfc9"),3)
	draw_rect(r,Color("4b6871"))
	draw_rect(r.grow(-3),Color("91b0b4"))
	draw_colored_polygon(PackedVector2Array([r.position+Vector2(3,3),r.position+Vector2(r.size.x-3,3),r.position+Vector2(3,r.size.y-6)]),Color("c1d5cd"))
	draw_line(r.position+Vector2(r.size.x*.5,1),Vector2(r.get_center().x,r.end.y-1),Color("e6e3ce"),2,true)
	draw_line(r.position+Vector2(1,15),r.position+Vector2(r.size.x-1,15),Color("d6d9c5"),2,true)
	Art.rounded(self,Rect2(r.position+Vector2(-7,r.size.y+2),Vector2(r.size.x+14,5)),Color("b1a68a"),1)
	if index % 3 == 0:
		draw_line(r.position+Vector2(-6,31),Vector2(r.end.x+6,r.position.y+31),Color("536b65"),3,true)
		for x in range(-4,int(r.size.x)+5,8): draw_line(r.position+Vector2(x,31),r.position+Vector2(x,42),Color("536b65"),1.5,true)
	elif index % 3 == 1:
		for side in [-1,1]:
			var x := r.position.x-14 if side == -1 else r.end.x+5
			draw_rect(Rect2(x,r.position.y,8,r.size.y),Color("80927a"))
			for y in range(5,int(r.size.y)-2,6): draw_line(Vector2(x+1,r.position.y+y),Vector2(x+7,r.position.y+y),Color("a3b09a"),1,true)

func _awning(r: Rect2, index: int) -> void:
	var cloth := Color("577f76") if index%2 == 0 else Color("ab7163")
	Art.rounded(self,Rect2(r.position+Vector2(2,6),r.size+Vector2(0,5)),Color(.17,.24,.22,.14),3)
	draw_colored_polygon(PackedVector2Array([r.position+Vector2(5,-3),r.position+Vector2(r.size.x-5,-3),r.end,r.position+Vector2(0,r.size.y)]),cloth)
	for x in range(int(r.position.x)+5,int(r.end.x)-15,32):
		draw_rect(Rect2(x,r.position.y,13,r.size.y),Color("e8deca"))
	for x in range(int(r.position.x)+8,int(r.end.x)-8,16):
		draw_circle(Vector2(x,r.end.y),8,Color("e8deca") if int((x-r.position.x)/16)%2==0 else cloth)
	draw_line(r.position,r.position+Vector2(r.size.x,0),cloth.lightened(.24),2,true)
func _text(value: String, at: Vector2, size: int) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font,at-Vector2(font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("344f58"))
