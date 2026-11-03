extends RefCounted
## Cutaway equipment: raised faces, rounded housings, legs and soft shadows.
const M = preload("res://scripts/game/render_materials.gd")
const W = preload("res://scripts/game/workshop_art.gd")
const INK := Color("354956")
const BLUE := Color("688da4")
const KINDS := ["meeting_board","training_panel","regulation_panel","tools_bench","parts_cabinet","meeting_table","bookcase","hydraulic_bench","mezzanine","steel_column","stool","measurement_bench"]
static func line(c: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float=3) -> void:
	c.draw_line(a,b,color,width,true)
static func gauge(c: CanvasItem, at: Vector2, radius: float=15) -> void:
	c.draw_circle(at,radius,INK)
	c.draw_circle(at,radius-3,Color("f5f7f7"))
	c.draw_arc(at,radius-6,PI*.8,TAU*1.1,18,BLUE,1,true)
	line(c,at,at+Vector2(5,-7),INK,2)
static func prop(c: CanvasItem, kind: String, r: Rect2) -> void:
	var p := r.position
	var w := r.size.x
	M.shadow(c,r,9,.19)
	match kind:
		"meeting_board":
			M.rounded(c,Rect2(p-Vector2(0,65),Vector2(w,95)),Color("8599a5"),6)
			M.rounded(c,Rect2(p+Vector2(6,-59),Vector2(w-12,81)),Color("fafbf9"),4)
			for i in range(3):
				var at := p+Vector2(45+i*190,-37)
				M.rounded(c,Rect2(at,Vector2(135,36)),Color("e7eff3"),3,BLUE,2)
				for dy in [12,24]: line(c,at+Vector2(12,dy),at+Vector2(118,dy),BLUE,2)
				if i<2: line(c,at+Vector2(143,18),at+Vector2(178,18),BLUE,2)
			line(c,p+Vector2(20,25),p+Vector2(w-20,25),Color("b8c6cd"),7)
		"training_panel", "regulation_panel":
			# The footprint is the stand; its vertical teaching face rises above it.
			var face := Rect2(p-Vector2(0,145),Vector2(w,r.size.y+100))
			M.rounded(c,face,INK,7)
			M.rounded(c,face.grow(-9),Color("e7ecee"),4)
			for x in [12.0,w-22]:
				M.rounded(c,Rect2(p+Vector2(x,-145),Vector2(10,r.size.y+145)),BLUE,3)
				M.rounded(c,Rect2(p+Vector2(x-8,r.size.y-15),Vector2(34,12)),INK,4)
			for y in [-110,-32]:
				line(c,p+Vector2(35,y),p+Vector2(w-35,y),Color("aab9c1"),9)
				for i in range(5):
					var a := p+Vector2(46+i*64,y-17)
					M.rounded(c,Rect2(a,Vector2(42,34)),Color("f8f8f5"),3,Color("98a7ae"),1)
					M.rounded(c,Rect2(a+Vector2(13,9),Vector2(16,12)),INK,2)
					line(c,a+Vector2(10,34),a+Vector2(10,45),BLUE,2)
			for i in range(4):
				var a := p+Vector2(65+i*80,-70)
				c.draw_polyline(PackedVector2Array([a,a+Vector2(0,17),a+Vector2(25,17),a+Vector2(25,38)]),BLUE if i%2==0 else Color("ad8174"),3,true)
			if kind=="regulation_panel":
				for i in range(3): gauge(c,p+Vector2(75+i*120,35),18)
			else:
				for i in range(3):
					M.rounded(c,Rect2(p+Vector2(52+i*118,18),Vector2(75,25)),Color("b2bdc4"),4)
					for dx in [16,36,56]: c.draw_circle(p+Vector2(52+i*118+dx,30),4,INK)
		"tools_bench", "meeting_table":
			W.table(c,r,Color("d3c0a2"))
			if kind=="tools_bench":
				M.rounded(c,Rect2(p+Vector2(30,15),Vector2(130,80)),Color("7d959b"),6)
				for i in range(3):
					var a := p+Vector2(48+i*35,35)
					line(c,a,a+Vector2(0,36),Color("d5dfe2"),5)
					M.rounded(c,Rect2(a+Vector2(-5,25),Vector2(10,30)),Color("a46e5c"),4)
				M.rounded(c,Rect2(p+Vector2(w-130,18),Vector2(90,90)),INK,9)
				M.rounded(c,Rect2(p+Vector2(w-119,29),Vector2(68,24)),Color("bcd0c7"),3)
				gauge(c,p+Vector2(w-85,77),20)
				c.draw_arc(p+Vector2(w-160,88),35,-1,3.8,24,Color("ad8174"),3,true)
			else:
				M.rounded(c,Rect2(p+Vector2(28,25),Vector2(84,60)),Color("f9f9f5"),3)
				for y in [40,51,62]: line(c,p+Vector2(40,y),p+Vector2(96,y),Color("adbec8"),2)
				line(c,p+Vector2(124,30),p+Vector2(145,70),BLUE,4)
				M.rounded(c,Rect2(p+Vector2(w-88,33),Vector2(62,75)),BLUE,4)
		"parts_cabinet", "bookcase":
			var face := Rect2(p-Vector2(0,80),r.size+Vector2(0,80))
			M.rounded(c,face,Color("637984"),6)
			M.rounded(c,Rect2(face.position,Vector2(w,16)),Color("ced6da"),4)
			for row in range(3):
				for col in range(4):
					var a := face.position+Vector2(10+col*(w-16)/4,25+row*(face.size.y-28)/3)
					var box := Rect2(a,Vector2((w-28)/4,(face.size.y-42)/3))
					M.rounded(c,box,Color("bfcbd0") if kind=="parts_cabinet" else Color("334c5b"),3)
					if kind=="parts_cabinet":
						M.rounded(c,Rect2(a+Vector2(8,7),Vector2(box.size.x-16,8)),Color("edf0ee"),2)
						line(c,box.get_center()+Vector2(-10,5),box.get_center()+Vector2(10,5),INK,3)
					else:
						for i in range(3): M.rounded(c,Rect2(a+Vector2(6+i*13,4),Vector2(10,box.size.y-8)),[Color("d4b69d"),BLUE,Color("e5e8e8")][i],1)
		"hydraulic_bench":
			M.rounded(c,r,Color("99aeb8"),12)
			M.rounded(c,r.grow(-9),Color("d9e0e1"),8)
			var tank := Rect2(p+Vector2(35,-115),Vector2(100,230))
			M.rounded(c,tank,Color("91a6b0"),40)
			M.rounded(c,Rect2(tank.position+Vector2(12,7),Vector2(62,210)),Color("d4dde0"),30)
			line(c,tank.position+Vector2(28,25),tank.position+Vector2(28,185),Color("edf2f2"),5)
			M.ellipse(c,Rect2(tank.position+Vector2(3,2),Vector2(94,30)),Color("edf1f0"))
			var a := p+Vector2(135,-45)
			c.draw_polyline(PackedVector2Array([a,a+Vector2(90,0),a+Vector2(90,135),a+Vector2(195,135),a+Vector2(195,-20)]),INK,12,true)
			c.draw_polyline(PackedVector2Array([a,a+Vector2(90,0),a+Vector2(90,135),a+Vector2(195,135),a+Vector2(195,-20)]),Color("b79b80"),7,true)
			for x in [220,330]: gauge(c,p+Vector2(x,-55),22)
			M.rounded(c,Rect2(p+Vector2(195,40),Vector2(58,52)),Color("a47061"),14)
			c.draw_circle(p+Vector2(224,66),15,INK)
			c.draw_circle(p+Vector2(224,66),8,Color("bccad1"))
			for x in [330,365]:
				line(c,p+Vector2(x,-10),p+Vector2(x,100),Color("c2ccd1"),13)
				line(c,p+Vector2(x-10,22),p+Vector2(x+10,22),BLUE,5)
		"measurement_bench":
			W.table(c,r)
			W.screen(c,Rect2(p+Vector2(20,-55),Vector2(110,70)),Color("a9c1c7"))
			gauge(c,p+Vector2(165,35),21)
			M.rounded(c,Rect2(p+Vector2(30,58),Vector2(95,25)),Color("6e8f88"),3)
		"mezzanine":
			M.rounded(c,Rect2(p-Vector2(0,70),r.size+Vector2(0,70)),Color("526773"),4)
			M.rounded(c,Rect2(p-Vector2(0,76),Vector2(w,65)),Color("cad3d8"),3)
			for x in range(16,int(w),50): line(c,p+Vector2(x,-130),p+Vector2(x,-4),BLUE,5)
			for y in [-130,-96,-8]: line(c,p+Vector2(4,y),p+Vector2(w-4,y),BLUE,7)
			for x in [16.0,w-30]: M.rounded(c,Rect2(p+Vector2(x,0),Vector2(14,r.size.y)),Color("8b6660"),3)
		"steel_column":
			M.rounded(c,r,Color("778793"),3)
			M.rounded(c,Rect2(p+Vector2(12,-140),Vector2(24,r.size.y+130)),Color("9d756c"),3)
			line(c,p+Vector2(15,-135),p+Vector2(15,28),Color("c5a498"),3)
		"stool":
			for dx in [-12,12]: line(c,r.get_center()+Vector2(dx,0),r.get_center()+Vector2(dx*1.4,24),INK,3)
			M.ellipse(c,r,Color("b9a88e"))
			M.ellipse(c,r.grow(-5),Color("deceb4"))
