extends Node2D
## Paint the connected street network in passes so pavement cannot cut asphalt.
const Town = preload("res://scripts/game/town_layout.gd")
const Road = preload("res://scripts/game/road_layout.gd")
const ASPHALT := Color("546269")
const PAVEMENT := Color("c9c6b7")
const PAINT := Color("eee9d4")

func _draw() -> void:
	var streets := Town.roads()
	# Every pavement base is behind every road, including the roundabouts.
	for street in streets: draw_rect(street.grow(34),PAVEMENT)
	for center in Town.roundabouts(): draw_circle(center,179,PAVEMENT)
	for street in streets: draw_rect(street,ASPHALT)
	for center in Town.roundabouts(): draw_circle(center,145,ASPHALT)
	var junctions := Town.intersections()
	for street in streets:
		var horizontal := street.size.x>street.size.y
		var length := street.size.x if horizontal else street.size.y
		for offset in range(20,int(length)-45,100):
			var at := street.position+Vector2(offset,street.size.y*.5-2) if horizontal else street.position+Vector2(street.size.x*.5-2,offset)
			var dash := Rect2(at,Vector2(45,4) if horizontal else Vector2(4,45))
			if _marking_clear(dash,junctions): draw_rect(dash,Color("dedcc6"))
	for center in Town.roundabouts(): draw_arc(center,100,0,TAU,64,PAINT,3,true)
	for crossing in Town.crosswalks():
		if crossing.size.x>crossing.size.y:
			for x in range(int(crossing.position.x)+8,int(crossing.end.x)-18,32): draw_rect(Rect2(x,crossing.position.y,18,crossing.size.y),PAINT)
		else:
			for y in range(int(crossing.position.y)+8,int(crossing.end.y)-18,32): draw_rect(Rect2(crossing.position.x+5,y,crossing.size.x-10,18),PAINT)
	for x in [770,1025]: draw_rect(Rect2(x,592,5,216),PAINT)
	# Render barriers above the street base; their shared solid footprints and
	# the original pedestrian opening are unchanged.
	for rect in Road.barriers():
		draw_rect(rect,Color("637d7c"))
		draw_line(rect.position+Vector2(0,3),Vector2(rect.end.x,rect.position.y+3),Color("cfdbd3"),3)
		for x in range(int(rect.position.x+15),int(rect.end.x),42): draw_rect(Rect2(x,rect.position.y-7,6,27),Color("526d6c"))
	var font := ThemeDB.fallback_font
	var label := "PASSAGE PIÉTON"
	draw_string(font,Vector2(900-font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x*.5,548),label,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("52756e"))

func _marking_clear(dash: Rect2, junctions: Array[Rect2]) -> bool:
	for junction in junctions:
		if dash.intersects(junction.grow(18)): return false
	for crossing in Town.crosswalks():
		if dash.intersects(crossing.grow(25)): return false
	for center in Town.roundabouts():
		if dash.get_center().distance_to(center)<180: return false
	return true
