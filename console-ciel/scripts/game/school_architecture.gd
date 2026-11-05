extends RefCounted
## Solid cutaway walls with depth, plaster faces, skirting and framed doorways.
const Plan = preload("res://scripts/game/school_layout.gd")
static func draw_room(canvas: Node2D, zone: String) -> void:
	for wall in Plan.walls(zone):
		if zone == "school_stop" and wall.size.y == 330: continue
		var rise := 62.0 if wall.size.x > wall.size.y else 34.0
		if wall.position.y > Plan.extent(zone).y-100: rise = 22.0
		preload("res://scripts/game/school_surfaces.gd").wall_face(canvas,wall,rise)
	var scene = preload("res://scripts/game/school_atelier_scene.gd")
	if zone in Plan.Ateliers.IDS:
		scene.door(canvas,Vector2(Plan.Ateliers.entry(zone).x,Plan.extent(zone).y-65),"",false)
	if zone == "school_passage":
		for item in [[1400,64,"1 · BAC PRO CIEL"],[2150,64,"2 · 2TNE"],[2700,64,"5 · BTS FED"],[900,636,"3 · RÉUNION"],[1750,636,"4 · CIEL INFORMATIQUE"],[430,636,"ACCUEIL"]]:
			scene.door(canvas,Vector2(item[0],item[1]),item[2],item[1]==64)
	if zone == "school_workshop":
		left_door(canvas, Vector2(52,720))
		label(canvas,"SALLE RÉSEAU",Vector2(218,603),20)
		label(canvas,"CITY CIEL",Vector2(218,630),17)
	if zone == "school_network_lab":
		# South wall has an actual threshold and an open leaf, not a line on a plan.
		canvas.draw_rect(Rect2(900,1495,200,81),Color("809a98"))
		canvas.draw_rect(Rect2(912,1507,176,62),Color("ddd7bf"))
		canvas.draw_line(Vector2(913,1508),Vector2(960,1448),Color("697e7e"),14,true)
		canvas.draw_line(Vector2(1086,1508),Vector2(1086,1570),Color("ecedde"),6,true)
static func left_door(canvas: Node2D, at: Vector2) -> void:
	canvas.draw_rect(Rect2(at-Vector2(30,100),Vector2(50,200)),Color("6c8383"))
	canvas.draw_rect(Rect2(at-Vector2(17,88),Vector2(30,176)),Color("b9cdc6"))
	canvas.draw_line(at+Vector2(7,-85),at+Vector2(70,-48),Color("8f9c83"),14,true)
	canvas.draw_circle(at+Vector2(61,-48),3,Color("ddc799"))
static func label(canvas: Node2D, text: String, at: Vector2, size: int) -> void:
	var font := ThemeDB.fallback_font
	canvas.draw_string(font,at-Vector2(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("344e59"))
