extends RefCounted
## Static furniture volumes, with the existing solid bases kept as anchors.
const M = preload("res://scripts/game/render_materials.gd")
const INK := Color("344e59")

static func table(c: CanvasItem, r: Rect2, wood: Color = Color("c6b08c")) -> void:
	M.shadow(c,r,12,.18)
	M.rounded(c,r,wood.darkened(.26),10)
	M.rounded(c,Rect2(r.position,r.size-Vector2(0,12)),wood,10)
	for index in range(5):
		var y := r.position.y+12+index*(r.size.y-32)/5
		c.draw_polyline(PackedVector2Array([Vector2(r.position.x+12,y),Vector2(r.get_center().x-8,y+2),Vector2(r.end.x-12,y-1)]),Color(wood.darkened(.17),.35),1,true)
	c.draw_line(r.position+Vector2(12,3),Vector2(r.end.x-12,r.position.y+3),wood.lightened(.32),2,true)
	for x in [r.position.x+12,r.end.x-19]: M.rounded(c,Rect2(x,r.end.y-11,7,10),INK,2)

static func screen(c: CanvasItem, r: Rect2, tint: Color = Color("94b9b7")) -> void:
	M.shadow(c,r,7,.15,Vector2(3,5))
	M.rounded(c,r,INK,8)
	var glass := r.grow(-6)
	M.rounded(c,glass,tint,4)
	c.draw_colored_polygon(PackedVector2Array([glass.position+Vector2(3,3),glass.position+Vector2(glass.size.x*.52,3),Vector2(glass.position.x+3,glass.end.y-4)]),Color("cce0da"))
	for index in range(3):
		var y := glass.position.y+10+index*11
		c.draw_line(Vector2(glass.get_center().x,y),Vector2(glass.end.x-10-index*7,y),Color("608f90"),3,true)
	var foot := Vector2(r.get_center().x,r.end.y)
	M.rounded(c,Rect2(foot-Vector2(6,0),Vector2(12,16)),Color("748e91"),2)
	M.rounded(c,Rect2(foot+Vector2(-29,13),Vector2(58,7)),Color("a8bab5"),4)
	c.draw_circle(r.end-Vector2(8,3),1.5,Color("abd5af"))

static func keyboard(c: CanvasItem, r: Rect2) -> void:
	M.rounded(c,r,Color("a6b6b2"),4)
	M.rounded(c,Rect2(r.position,r.size-Vector2(0,3)),Color("edf0e5"),4)
	for row in range(3):
		for col in range(11):
			var at := r.position+Vector2(5+col*(r.size.x-11)/11,4+row*(r.size.y-9)/3)
			M.rounded(c,Rect2(at,Vector2((r.size.x-25)/12,2)),Color("9baba7"),1)

static func prop(c: CanvasItem, kind: String, r: Rect2) -> void:
	match kind:
		"cyber_desk":
			table(c,r)
			screen(c,Rect2(r.position+Vector2(82,-58),Vector2(156,87)))
			keyboard(c,Rect2(r.position+Vector2(82,66),Vector2(140,24)))
			M.ellipse(c,Rect2(r.position+Vector2(242,65),Vector2(19,27)),Color("e5eade"))
			M.rounded(c,Rect2(r.position+Vector2(280,20),Vector2(25,70)),INK,5)
			for y in range(45,77,6): c.draw_line(r.position+Vector2(285,y),r.position+Vector2(300,y),Color("617a80"),1,true)
			c.draw_circle(r.position+Vector2(293,31),3,Color("a1cbb1"))
		"laptop_bench", "electronics", "printer3d":
			table(c,r)
			var at := r.position+Vector2(40,-90)
			if kind=="laptop_bench":
				for x in [0,220]:
					var a := at+Vector2(x,25)
					screen(c,Rect2(a,Vector2(170,95)),Color("9dbac3"))
					M.rounded(c,Rect2(a+Vector2(-8,98),Vector2(186,48)),Color("98acae"),6)
					keyboard(c,Rect2(a+Vector2(0,102),Vector2(170,23)))
					M.rounded(c,Rect2(a+Vector2(57,130),Vector2(57,12)),Color("b6c6bf"),3)
			elif kind=="electronics":
				M.rounded(c,Rect2(at+Vector2(10,50),Vector2(120,85)),Color("52765e"),7)
				for x in [30,65,100]:
					M.rounded(c,Rect2(at+Vector2(x,65),Vector2(15,26)),INK,2)
					for y in [66,75,84]: c.draw_line(at+Vector2(x-4,y),at+Vector2(x+20,y),Color("d9c99f"),1,true)
				screen(c,Rect2(at+Vector2(190,35),Vector2(105,89)),Color("8eb69d"))
				var wave := PackedVector2Array()
				for i in range(38): wave.append(at+Vector2(198+i*2,78+sin(i*.4)*12))
				c.draw_polyline(wave,Color("e3e9b5"),2,true)
				c.draw_arc(at+Vector2(160,127),42,PI*.7,TAU,26,Color("a77e5b"),3,true)
			else:
				M.rounded(c,Rect2(at,Vector2(200,190)),INK,9)
				M.rounded(c,Rect2(at+Vector2(14,15),Vector2(172,139)),Color("abc4bf"),4)
				c.draw_colored_polygon(PackedVector2Array([at+Vector2(26,29),at+Vector2(166,29),at+Vector2(146,116),at+Vector2(45,116)]),Color("cee0d5"))
				for x in [30,165]: c.draw_line(at+Vector2(x,25),at+Vector2(x,145),Color("7f999c"),7,true)
				c.draw_line(at+Vector2(28,50),at+Vector2(173,50),Color("718e95"),8,true)
				M.rounded(c,Rect2(at+Vector2(85,50),Vector2(30,36)),INK,4)
				M.rounded(c,Rect2(at+Vector2(40,130),Vector2(120,10)),Color("799b9f"),3)
				c.draw_colored_polygon(PackedVector2Array([at+Vector2(78,128),at+Vector2(83,104),at+Vector2(117,104),at+Vector2(125,128)]),Color("d4a477"))
				c.draw_circle(at+Vector2(232,48),33,INK)
				c.draw_circle(at+Vector2(232,48),24,Color("c9976b"))
				for radius in [11,17,23]: c.draw_arc(at+Vector2(232,48),radius,0,TAU,24,Color("e0bd8e"),1,true)
				M.rounded(c,Rect2(at+Vector2(128,164),Vector2(49,16)),Color("a5c3b3"),3)
		"chair":
			var center := r.get_center()
			c.draw_line(center,center+Vector2(0,24),INK,5,true)
			for direction in [-1,1]: c.draw_line(center+Vector2(0,22),center+Vector2(direction*23,29),INK,3,true)
			M.rounded(c,r,Color("385762"),10)
			M.rounded(c,r.grow(-5),Color("6f9399"),8)
			c.draw_arc(center-Vector2(0,5),r.size.x*.38,PI*1.08,PI*1.92,24,Color("a6bec0"),2,true)
		"rack":
			M.shadow(c,r,8,.15)
			M.rounded(c,r,INK,8)
			M.rounded(c,r.grow(-7),Color("59777d"),4)
			for y in range(int(r.position.y)+12,int(r.end.y)-16,27):
				M.rounded(c,Rect2(r.position.x+12,y,r.size.x-24,20),Color("8c9e99"),3)
				for x in range(int(r.position.x)+18,int(r.end.x)-20,7): c.draw_line(Vector2(x,y+5),Vector2(x,y+15),INK,1,true)
				c.draw_circle(Vector2(r.end.x-18,y+8),2,Color("b2d298"))

static func plant(c: CanvasItem, r: Rect2) -> void:
	var center := r.get_center()
	M.ellipse(c,Rect2(center+Vector2(-25,15),Vector2(54,20)),Color(.15,.22,.18,.12))
	M.rounded(c,Rect2(center-Vector2(22,1),Vector2(44,35)),Color("a78b68"),8)
	M.ellipse(c,Rect2(center-Vector2(23,10),Vector2(46,17)),Color("c4ad87"))
	for index in range(11):
		var angle := -PI*.90+index*PI*.08
		var length := r.size.x*(.30+(index%3)*.09)
		var end := center+Vector2(cos(angle)*length,sin(angle)*length-12)
		var perp := (end-center).orthogonal().normalized()*7
		var leaf := PackedVector2Array([center,center.lerp(end,.45)+perp,end,center.lerp(end,.55)-perp*.7])
		c.draw_colored_polygon(leaf,Color("6b886a") if index%2 else Color("8da37a"))
		c.draw_line(center,end,Color("a6b78a"),1,true)
