extends RefCounted
## Original low school frontage inspired by the user's Ruffec photograph.
const Garden = preload("res://scripts/game/exterior_painter.gd")
const LOGO = preload("res://assets/lycee/logo_louise_michel.jpg")
const STONE := Color("e8e0cf")
const ROSE := Color("c8aaa7")
const FRAME := Color("e9e9df")
const METAL := Color("6c8082")
const GLASS := Color("8da9ab")
const INK := Color("3e575f")

static func entrance(frame: Rect2, clearance: float = 65) -> Vector2:
	return frame.position+Vector2(frame.size.x/6,frame.size.y+clearance)

static func draw_facade(c: Node2D, f: Rect2) -> void:
	if preload("res://scripts/game/school_realism.gd").manifest().get("sprites",{}).has("lycee_facade"):
		preload("res://scripts/game/school_surfaces.gd").contact(c,Rect2(f.position+Vector2(0,f.size.y-12),Vector2(f.size.x,30)))
		preload("res://scripts/game/school_realism.gd").facade(c,f)
		# Keep the licensed school logo on its own small wall plaque.
		c.draw_texture_rect(LOGO,_region(f,Rect2(22,42,30,46)),false)
		return
	_box(c,f,Rect2(6,12,1800,310),Color(0.18,.23,.22,.18))
	_box(c,f,Rect2(0,0,560,310),ROSE)
	_box(c,f,Rect2(540,45,1260,265),STONE)
	for i in range(10):
		var x := 585.0+i*117
		_line(c,f,Vector2(x,89),Vector2(x-11,296),Color("d5ccbb"),1)
	_box(c,f,Rect2(540,45,1260,31),ROSE)
	_box(c,f,Rect2(0,-8,560,21),Color("d4d1c0"))
	_box(c,f,Rect2(540,30,1260,18),Color("d4d1c0"))
	for x in range(548,1790,12): _line(c,f,Vector2(x,32),Vector2(x,46),Color("b5b6a8"),1)
	_box(c,f,Rect2(670,-24,67,55),Color("c5c1ad"))
	_box(c,f,Rect2(662,-28,83,8),METAL)
	_box(c,f,Rect2(0,298,1800,12),Color("b2afa0"))
	# Curtain-wall glazing and the main entrance on the pink left wing.
	for x in [40,390]:
		_box(c,f,Rect2(x,96,170,204),METAL)
		_box(c,f,Rect2(x+7,103,156,188),GLASS)
		_line(c,f,Vector2(x+85,103),Vector2(x+85,291),FRAME,5)
		_line(c,f,Vector2(x+7,155),Vector2(x+163,155),FRAME,5)
		_line(c,f,Vector2(x+12,111),Vector2(x+69,142),Color("d2dfd9"),3)
	_box(c,f,Rect2(220,95,160,215),METAL)
	_box(c,f,Rect2(228,104,144,195),Color("adc5c5"))
	_box(c,f,Rect2(234,157,62,142),Color("45616a"))
	_box(c,f,Rect2(306,157,59,142),Color("b1ccca"))
	for x in [226,300,373]: _line(c,f,Vector2(x,102),Vector2(x,310),FRAME,5)
	_line(c,f,Vector2(226,153),Vector2(374,153),FRAME,5)
	for x in [290,311]: _line(c,f,Vector2(x,220),Vector2(x,244),METAL,4)
	_box(c,f,Rect2(214,83,173,13),FRAME)
	_box(c,f,Rect2(215,310,175,17),Color("c2bba8"))
	_line(c,f,Vector2(216,311),Vector2(390,311),Color("f1ead8"),3)
	# Pale shutters, concrete pilasters and the secondary glazed door.
	for x in [610,815,1230,1435,1640]:
		_box(c,f,Rect2(x-10,107,157,179),Color("c8c3b4"))
		_box(c,f,Rect2(x-3,113,143,168),FRAME)
		_box(c,f,Rect2(x+5,121,127,151),GLASS)
		_box(c,f,Rect2(x+5,121,127,98),Color("e0e0d7"))
		for y in range(127,217,7): _line(c,f,Vector2(x+7,y),Vector2(x+130,y),Color("c9ccc4"),1)
		_line(c,f,Vector2(x+68,220),Vector2(x+68,273),FRAME,3)
		_box(c,f,Rect2(x-27,87,12,209),Color("c8c1b0"))
		_box(c,f,Rect2(x-26,87,4,209),Color("f4eddb"))
	_box(c,f,Rect2(1020,104,155,206),FRAME)
	for x in [1028,1104]:
		_box(c,f,Rect2(x,112,64,188),GLASS)
		_line(c,f,Vector2(x+7,161),Vector2(x+55,197),Color("d2dfd9"),3)
		_line(c,f,Vector2(x+31,112),Vector2(x+31,299),FRAME,3)
	_box(c,f,Rect2(1045,80,104,16),METAL)
	_text(c,f,"ATELIERS",Vector2(1097,92),10,FRAME)
	# Drainpipe and clock are architectural details visible in the reference.
	_line(c,f,Vector2(564,66),Vector2(564,297),METAL,5)
	var clock := _at(f,Vector2(518,64))
	c.draw_circle(clock,13*f.size.y/310,METAL)
	c.draw_circle(clock,10*f.size.y/310,Color("f1eddb"))
	_line(c,f,Vector2(518,64),Vector2(518,55),INK,2)
	_line(c,f,Vector2(518,64),Vector2(525,64),INK,2)
	_box(c,f,Rect2(35,25,47,52),Color.WHITE)
	c.draw_texture_rect(LOGO,_region(f,Rect2(43,28,30,46)),false)
	_text(c,f,"LYCÉE LOUISE MICHEL",Vector2(288,60),24,INK)

static func prop(c: Node2D, spec: Dictionary) -> void:
	var r: Rect2=spec.rect
	match str(spec.kind):
		"campus_planter":
			c.draw_rect(Rect2(r.position+Vector2(4,6),r.size),Color(0.18,.23,.20,.16))
			c.draw_rect(r,Color("b6b7aa"))
			c.draw_rect(r.grow(-8),Color("809572"))
			Garden.flowers(c,r.grow(-12),int(r.position.x))
		"campus_bench":
			c.draw_rect(r,Color("6b8976"))
			for y in [7,18,29]: c.draw_line(r.position+Vector2(4,y),Vector2(r.end.x-4,r.position.y+y),Color("a5b49a"),3)
		"campus_sign":
			for x in [r.position.x+16,r.end.x-16]: c.draw_line(Vector2(x,r.end.y),Vector2(x,r.position.y-140),METAL,6)
			c.draw_rect(Rect2(r.position-Vector2(5,152),Vector2(r.size.x+10,161)),METAL)
			c.draw_rect(Rect2(r.position-Vector2(0,147),Vector2(r.size.x,151)),Color.WHITE)
			c.draw_texture_rect(LOGO,Rect2(r.position+Vector2(48,-141),Vector2(50,76)),false)
			var font := ThemeDB.fallback_font
			for line in [{"text":"LOUISE MICHEL","y":-38,"font_size":14},{"text":"LYCÉE · RUFFEC","y":-16,"font_size":12}]:
				c.draw_string(font,Vector2(r.get_center().x-font.get_string_size(line.text,HORIZONTAL_ALIGNMENT_LEFT,-1,line.font_size).x*.5,r.position.y+line.y),line.text,HORIZONTAL_ALIGNMENT_LEFT,-1,line.font_size,INK)
		"campus_arrow":
			c.draw_line(r.get_center(),r.get_center()-Vector2(0,70),METAL,5)
			var board := Rect2(r.get_center()-Vector2(87,100),Vector2(174,40))
			c.draw_rect(board,Color("e6dfca"))
			c.draw_string(ThemeDB.fallback_font,board.position+Vector2(13,26),"CAMPUS LYCÉE →",HORIZONTAL_ALIGNMENT_LEFT,-1,17,INK)

static func _at(f: Rect2, p: Vector2) -> Vector2: return f.position+p*f.size/Vector2(1800,310)
static func _region(f: Rect2, r: Rect2) -> Rect2: return Rect2(_at(f,r.position),r.size*f.size/Vector2(1800,310))
static func _box(c: Node2D, f: Rect2, r: Rect2, color: Color) -> void: c.draw_rect(_region(f,r),color)
static func _line(c: Node2D, f: Rect2, a: Vector2, b: Vector2, color: Color, width: float) -> void: c.draw_line(_at(f,a),_at(f,b),color,width*f.size.x/1800,true)
static func _text(c: Node2D, f: Rect2, value: String, p: Vector2, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var font_size := maxi(10,int(size*f.size.x/1800))
	c.draw_string(font,_at(f,p)-Vector2(font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x*.5,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
