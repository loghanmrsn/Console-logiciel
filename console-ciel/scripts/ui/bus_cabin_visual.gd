extends Control
## Perspective cutaway of the bus: fixed design coordinates, scaled to the panel.
const GUEST = preload("res://assets/art/character/down_0.svg")
const WALK = preload("res://assets/art/character/down_1.svg")
const BACK = preload("res://assets/art/character/up_0.svg")
var phase := 0
var amount := 0.0
var scenery := 0.0
var destination := ""
var _styles: Dictionary = {}
const DARK := Color("263c46")
const METAL := Color("8fa5a7")
const RAIL := Color("dbc46f")
func _ready() -> void:
	resized.connect(queue_redraw)
func _draw() -> void:
	if size.x<1 or size.y<1: return
	draw_set_transform(Vector2.ZERO,0,Vector2(size.x/960.0,size.y/340.0))
	draw_style_box(_style(Color("b4c2c2"),12),Rect2(0,0,960,340))
	_poly([Vector2(20,0),Vector2(940,0),Vector2(750,97),Vector2(210,97)],Color("e2e7df"))
	_poly([Vector2(0,0),Vector2(220,81),Vector2(286,193),Vector2(0,340)],Color("acbebd"))
	_poly([Vector2(960,0),Vector2(740,81),Vector2(674,193),Vector2(960,340)],Color("a0b4b5"))
	_poly([Vector2(0,340),Vector2(286,150),Vector2(674,150),Vector2(960,340)],Color("8d9694"))
	_poly([Vector2(388,340),Vector2(457,151),Vector2(503,151),Vector2(572,340)],Color("626f71"))
	for y in [180,215,258,315]: draw_line(Vector2(380,y),Vector2(580,y),Color("788486"),1)
	# Ceiling lights, ventilation and an overhead destination display.
	for side in [-1,1]:
		_poly([Vector2(480+side*80,18),Vector2(480+side*110,18),Vector2(480+side*72,85),Vector2(480+side*57,85)],Color("f7f3d7"))
	for y in range(23,68,8): draw_line(Vector2(456,y),Vector2(504,y),Color("b6c4bf"),2)
	draw_style_box(_style(DARK,4),Rect2(342,75,276,26))
	_text(destination.to_upper(),Vector2(480,94),13,Color("e4c578"))
	# Front windscreen and cockpit, separated from the passenger area.
	_poly([Vector2(270,100),Vector2(690,100),Vector2(652,151),Vector2(308,151)],Color("83aeb9"))
	for x in [315,360,570,615]: draw_rect(Rect2(x,112,26,31),Color("74978e"))
	_poly([Vector2(425,150),Vector2(469,111),Vector2(493,111),Vector2(535,150)],Color("57717a"))
	draw_line(Vector2(481,117),Vector2(481,145),Color("e1dcc3"),2)
	draw_polyline(PackedVector2Array([Vector2(270,100),Vector2(308,151),Vector2(652,151),Vector2(690,100)]),DARK,6,true)
	_windows(false)
	_windows(true)
	# Driver seat and dashboard with steering wheel and instruments.
	draw_style_box(_style(Color("3f5c68"),6),Rect2(302,138,110,57))
	draw_texture_rect(BACK,Rect2(326,116,35,41),false,Color("cad8dc"))
	_poly([Vector2(304,142),Vector2(421,143),Vector2(442,179),Vector2(289,176)],DARK)
	draw_arc(Vector2(371,161),17,0,TAU,32,Color("172f3a"),5,true)
	draw_line(Vector2(356,161),Vector2(386,161),METAL,3)
	draw_line(Vector2(371,161),Vector2(371,175),METAL,3)
	draw_rect(Rect2(304,151,30,12),Color("9fc3b0"))
	for x in [400,410,420]: draw_circle(Vector2(x,159),2,Color("caad6b"))
	# Glazed entry/exit door and visible step edges.
	_poly([Vector2(744,122),Vector2(862,172),Vector2(919,323),Vector2(807,281)],Color("567783"))
	_poly([Vector2(755,138),Vector2(800,158),Vector2(848,285),Vector2(814,271)],Color("9dc3c6"))
	_poly([Vector2(812,163),Vector2(851,180),Vector2(898,306),Vector2(861,290)],Color("a7cccd"))
	draw_line(Vector2(805,154),Vector2(859,294),DARK,5)
	for step in [0,1,2]: draw_line(Vector2(800+step*12,290+step*14),Vector2(882+step*10,317+step*7),RAIL,4,true)
	# Perspective rows. The selected seat is in the middle right row.
	for row in [{"left":365.0,"y":187.0,"w":62.0,"h":52.0},{"left":300.0,"y":245.0,"w":91.0,"h":76.0},{"left":196.0,"y":316.0,"w":124.0,"h":100.0}]:
		for side in [0,1]:
			var at := Vector2(row.left if side==0 else 960-row.left,row.y)
			_seat_back(at,row.w,row.h)
			if not (side==1 and row.y==245.0): _seat_front(at,row.w)
	# Quiet passengers face towards the driver, without dialogue.
	draw_texture_rect(BACK,Rect2(348,130,31,36),false,Color("d2c3b9"))
	draw_texture_rect(BACK,Rect2(169,219,43,50),false,Color("b7c5b4"))
	_seat_front(Vector2(365,187),62)
	_seat_front(Vector2(196,316),124)
	# Ticket reader, handrails and stop request buttons.
	draw_line(Vector2(743,169),Vector2(743,228),METAL,7)
	draw_style_box(_style(DARK,4),Rect2(720,139,47,45))
	draw_rect(Rect2(727,146,33,14),Color("abd1a1") if phase==1 else Color("719b9c"))
	_text("1 €",Vector2(743,157),11,DARK)
	draw_arc(Vector2(743,171),8,-PI*.7,PI*.7,16,Color("d6e4dc"),2,true)
	for side in [-1,1]:
		draw_line(Vector2(480+side*315,326),Vector2(480+side*176,126),RAIL,5,true)
		draw_line(Vector2(480+side*176,126),Vector2(480+side*167,84),RAIL,5,true)
	for at in [Vector2(155,290),Vector2(803,285)]:
		draw_circle(at,8,Color("af6358"))
		draw_circle(at,3,Color("ece6d3"))
	var seat := Vector2(660,245)
	var reader := Vector2(707,205)
	var exit := Vector2(871,315)
	var guest := seat
	if phase==0: guest=exit.lerp(reader,amount)
	if phase==1: guest=reader.lerp(seat,clampf((amount-.65)/.35,0,1))
	if phase==3: guest=seat.lerp(exit,amount)
	var walking := phase in [0,3] or phase==1 and amount>.65
	var texture: Texture2D=WALK if walking and int(amount*12)%2==1 else GUEST
	draw_texture_rect(texture,Rect2(guest-Vector2(25,72),Vector2(50,58)),false)
	if phase==2 or phase==1 and amount>.96:
		_seat_front(seat,91)
		for x in [-10,10]:
			draw_line(seat+Vector2(x,-10),seat+Vector2(x+4,5),Color("3a5666"),5)
			draw_circle(seat+Vector2(x+7,7),4,DARK)
	elif phase==1 and amount<.65:
		var card := (reader-Vector2(0,37)).lerp(Vector2(741,167),clampf(amount/.5,0,1))
		draw_style_box(_style(Color("c6d6b9"),2),Rect2(card,Vector2(21,12)))
		draw_rect(Rect2(card+Vector2(3,3),Vector2(6,5)),Color("d7ba6b"))
	# A thin foreground sill finishes the cutaway instead of a floating flat floor.
	draw_line(Vector2(0,337),Vector2(960,337),DARK,6)
func _windows(right: bool) -> void:
	var top_a := Vector2(16,27)
	var top_b := Vector2(222,95)
	var bottom_a := Vector2(16,153)
	var bottom_b := Vector2(247,157)
	for index in range(4):
		var t0 := index/4.0+.015
		var t1 := (index+1)/4.0-.015
		var a := top_a.lerp(top_b,t0)
		var b := top_a.lerp(top_b,t1)
		var c := bottom_a.lerp(bottom_b,t1)
		var d := bottom_a.lerp(bottom_b,t0)
		if right:
			a.x=960-a.x; b.x=960-b.x; c.x=960-c.x; d.x=960-d.x
		_poly([a,b,c,d],Color("8db5bd"))
		var offset := fposmod(scenery*.18+index*.21,.55)
		var u := a.lerp(b,offset)
		var v := a.lerp(b,offset+.25)
		var w := d.lerp(c,offset+.25)
		var z := d.lerp(c,offset)
		_poly([u.lerp(z,.45),v.lerp(w,.45),w,z],Color("70918c"))
		draw_line(a.lerp(d,.18),b.lerp(c,.65),Color("d4e5df"),2,true)
		draw_polyline(PackedVector2Array([a,b,c,d,a]),Color("556f76"),5,true)
func _seat_back(at: Vector2, width: float, height: float) -> void:
	draw_rect(Rect2(at+Vector2(-width*.15,-3),Vector2(width*.3,20)),Color("445a62"))
	draw_style_box(_style(Color("273f4f"),7),Rect2(at-Vector2(width*.5,height),Vector2(width,height*.86)))
	draw_style_box(_style(Color("4b7485"),5),Rect2(at-Vector2(width*.5-6,height-6),Vector2(width-12,height*.65)))
	for stripe in range(3):
		var y := at.y-height+16+stripe*(height*.15)
		draw_line(Vector2(at.x-width*.35,y),Vector2(at.x+width*.35,y),Color("648c98"),1,true)
	draw_line(at+Vector2(-width*.55,-23),at+Vector2(width*.55,-23),METAL,3,true)
func _seat_front(at: Vector2, width: float) -> void:
	_poly([at+Vector2(-width*.48,-18),at+Vector2(width*.48,-18),at+Vector2(width*.6,-3),at+Vector2(-width*.5,1)],Color("5e8593"))
	draw_line(at+Vector2(-width*.5,1),at+Vector2(width*.6,-3),Color("2c4656"),4,true)
func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points),color)
func _style(color: Color, radius: int) -> StyleBoxFlat:
	var key := color.to_html()+str(radius)
	if _styles.has(key): return _styles[key]
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(radius)
	_styles[key]=style
	return style
func _text(value: String, at: Vector2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font,at-Vector2(font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x*.5,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
