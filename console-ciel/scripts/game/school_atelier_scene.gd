extends RefCounted
## Bright white plaster, quiet blue circulation, light through high windows.
const A = preload("res://scripts/game/school_ateliers.gd")
const M = preload("res://scripts/game/render_materials.gd")
const Surface = preload("res://scripts/game/school_surfaces.gd")
const Ink := Color("405562")
static func label(c: CanvasItem, text: String, at: Vector2, size: int=20) -> void:
	var font := ThemeDB.fallback_font
	c.draw_string(font,at-Vector2(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Ink)
static func draw_floor(c: Node2D, zone: String) -> void:
	var size := A.extent(zone)
	var industrial := zone in ["school_workshop","school_tne","school_fed"]
	Surface.floor_material(c,size)
	if industrial:
		var lane_x := 780.0 if zone=="school_workshop" else 800.0
		M.rounded(c,Rect2(lane_x,230,140,size.y-440),Color("87a4b3"),10)
		M.rounded(c,Rect2(140,size.y-300,size.x-280,140),Color("87a4b3"),10)
		for x in range(int(lane_x)+8,int(lane_x)+125,24): c.draw_line(Vector2(x,size.y-290),Vector2(x,size.y-170),Color("e9edec"),12,true)
		for y in range(300,int(size.y)-410,280):
			c.draw_polyline(PackedVector2Array([Vector2(lane_x+50,y+20),Vector2(lane_x+70,y),Vector2(lane_x+90,y+20)]),Color("dbe9ee"),4,true)
	# Broad windows, mullions and restrained sunlight. Roof is cut away for play.
	for x in range(170,int(size.x)-250,400):
		M.rounded(c,Rect2(x,65,270,36),Color("859da9"),3)
		M.rounded(c,Rect2(x+5,68,260,23),Color("c2dae5"),2)
		for dx in [88,174]: c.draw_line(Vector2(x+dx,68),Vector2(x+dx,94),Color("f7f9f9"),5,true)
		c.draw_line(Vector2(x,101),Vector2(x+270,101),Color("f9faf9"),6,true)
		c.draw_texture_rect(Surface.light(),Rect2(x+30,110,430,340),false)
	for target in A.targets(zone):
		c.draw_circle(target.at,9,Color("688da4"))
		c.draw_arc(target.at,8,0,TAU,20,Color("f8fafb"),2,true)
		c.draw_circle(target.at,2,Color("f8fafb"))
	var at := A.entry(zone)
	if zone=="school_cyber": at=Vector2(1000,1200)
	label(c,"ACCUEIL / SORTIE" if zone=="school_cyber" else "COULOIR DES ATELIERS",Vector2(at.x,size.y-90),18)
static func door(c: Node2D, at: Vector2, title: String, top: bool) -> void:
	var face := Rect2(at-Vector2(85,42),Vector2(170,67))
	M.rounded(c,face,Color("677f8e"),4)
	M.rounded(c,face.grow(-7),Color("eff2f3"),2)
	M.rounded(c,Rect2(at+Vector2(-68,-29),Vector2(132,32)),Color("9cb7c6"),2)
	c.draw_line(at+Vector2(-68,13),at+Vector2(68,13),Color("f8fafb"),4,true)
	c.draw_circle(at+Vector2(56,7),3,Ink)
	if not title.is_empty(): label(c,title,at+Vector2(0,66 if top else -65),18)
