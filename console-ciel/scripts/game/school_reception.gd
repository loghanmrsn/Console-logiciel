extends RefCounted
## Ground-floor reception, with the same white plaster and Blender furniture.
const SIZE := Vector2(1600,1100)
const Surface = preload("res://scripts/game/school_surfaces.gd")
const M = preload("res://scripts/game/render_materials.gd")
static func furniture() -> Array[Dictionary]:
	var result: Array[Dictionary]=[
		{"kind":"cyber_desk","rect":Rect2(290,350,320,110)},
		{"kind":"bookcase","rect":Rect2(1070,270,280,90)},
		{"kind":"reception_stairs","rect":Rect2(1120,560,320,250)},
		{"kind":"garden_planter","rect":Rect2(170,230,110,36)},
		{"kind":"garden_planter","rect":Rect2(1320,950,110,36)}]
	for x in [250,370,490]: result.append({"kind":"chair","rect":Rect2(x,740,70,40)})
	return result
static func label(c: CanvasItem, text: String, at: Vector2, size: int=22) -> void:
	var font := ThemeDB.fallback_font
	c.draw_string(font,at-Vector2(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("3e5665"))
static func draw(c: Node2D) -> void:
	Surface.floor_material(c,SIZE)
	M.rounded(c,Rect2(690,670,240,370),Color("b7c7cc"),12)
	for x in [220,650,1080]:
		M.rounded(c,Rect2(x,70,270,35),Color("8da3ad"),4)
		M.rounded(c,Rect2(x+6,74,258,23),Color("d9e9ec"),2)
		for dx in [90,180]: c.draw_line(Vector2(x+dx,74),Vector2(x+dx,99),Color.WHITE,5,true)
		c.draw_colored_polygon(PackedVector2Array([Vector2(x+5,115),Vector2(x+258,115),Vector2(x+350,310),Vector2(x+75,310)]),Color(1,1,1,.16))
	M.rounded(c,Rect2(440,135,720,70),Color("f5f7f7"),8)
	label(c,"LYCÉE LOUISE MICHEL · ACCUEIL",Vector2(800,180),28)
	label(c,"VIE SCOLAIRE",Vector2(470,295),23)
	label(c,"ESPACE D’ATTENTE",Vector2(400,855),19)
	label(c,"ATELIERS · À L’ÉTAGE",Vector2(1280,500),20)
	label(c,"La surveillante vous accompagne",Vector2(1280,530),16)
	M.rounded(c,Rect2(690,1014,220,20),Color("7b959e"),3)
	label(c,"SORTIE · PARVIS / BUS",Vector2(800,1000),20)
static func stairs(c: CanvasItem, rect: Rect2) -> void:
	Surface.contact(c,rect)
	for i in range(10):
		var y := rect.end.y-25*(i+1)
		M.rounded(c,Rect2(rect.position.x,y,rect.size.x,24),Color("c3c9c9"),2)
		c.draw_rect(Rect2(rect.position.x+7,y,rect.size.x-14,5),Color("eef1ef"))
		c.draw_line(Vector2(rect.position.x+8,y+20),Vector2(rect.end.x-8,y+20),Color("7b898c"),2,true)
	for x in [rect.position.x+12,rect.end.x-12]:
		for y in [rect.position.y+20,rect.end.y-15]: c.draw_line(Vector2(x,y),Vector2(x,y-65),Color("748c95"),5,true)
		c.draw_line(Vector2(x,rect.position.y-45),Vector2(x,rect.end.y-80),Color("b7c9cf"),7,true)
