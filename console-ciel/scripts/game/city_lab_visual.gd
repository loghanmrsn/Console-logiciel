extends "res://scripts/game/school_visual.gd"
## Furnished teaching room: shared footprints keep artwork and physics aligned.
func _draw() -> void:
	if not furniture_only.is_empty():
		draw_set_transform(-furniture_anchor)
		if use_baked_art and preload("res://scripts/game/baked_art.gd").draw_school(self,str(furniture_only.kind),furniture_only.rect): return
		_prop_art(str(furniture_only.kind),furniture_only.rect)
		return
	preload("res://scripts/game/school_surfaces.gd").floor_material(self,Vector2(2200,1600))
	# A distinct but quiet equipment bay, with glazed partition frames.
	draw_rect(Rect2(1500,100,620,1200),Color("cdd9d8"))
	for y in [180,350,1100,1230]:
		draw_rect(Rect2(1454,y,36,62),Color("7f9a9d"))
		draw_rect(Rect2(1460,y+6,24,50),Color("b5ced0"))
	for x in [250,800,1570]:
		draw_rect(Rect2(x,100,350,18),Color("a4b8b5"))
		draw_rect(Rect2(x+8,103,334,9),Color("f7f4da"))
	_text("CITY CIEL · LABORATOIRE RÉSEAU",Vector2(1000,135),24,DARK,true)
	_text("IPv4 /24   ·   IPv6 /64   ·   ROUTAGE",Vector2(850,380),18,DARK,true)
	_text("PC-01 · IPv4",Vector2(420,790),18,DARK,true)
	_text("PC-02 · IPv6",Vector2(1000,790),18,DARK,true)
	_text("R1 + SW1",Vector2(1770,1010),18,DARK,true)
	_text("SORTIE · CITY CIEL",Vector2(1000,1420),18,DARK,true)
	# Wall-mounted cable tray, with separate labelled connections to the rack.
	draw_polyline(PackedVector2Array([Vector2(2100,430),Vector2(2100,1340),Vector2(160,1340)]),Color("819e9d"),8,true)
	preload("res://scripts/game/school_architecture.gd").draw_room(self,zone)
	# High windows and reveal shadows give the cutaway room a built volume.
	for x in [220,650,1080,1670]:
		draw_rect(Rect2(x,-7,240,58),Color("718c91"))
		draw_rect(Rect2(x+8,0,224,43),Color("b0ced0"))
		draw_line(Vector2(x+120,0),Vector2(x+120,43),Color("e9eadd"),5)
		draw_line(Vector2(x+20,6),Vector2(x+80,33),Color("d7e6df"),3)
		draw_rect(Rect2(x-5,49,250,9),Color("93a8a1"))
func _prop_art(kind: String, rect: Rect2) -> void:
	if kind != "network_console":
		super._prop_art(kind,rect)
		return
	draw_style_box(_shadow_style(),Rect2(rect.position+Vector2(6,10),rect.size))
	Workshop.table(self,rect,Color("b9a98a"))
	var at := rect.position+Vector2(20,22)
	# Router, console, ventilation and link lights.
	preload("res://scripts/game/render_materials.gd").rounded(self,Rect2(at,Vector2(175,100)),Color("e0e5df"),9)
	draw_rect(Rect2(at+Vector2(12,14),Vector2(148,32)),Color("466776"))
	for x in [20,55,90,125]: draw_circle(at+Vector2(x,70),3,Color("82b995"))
	at += Vector2(205,0)
	preload("res://scripts/game/render_materials.gd").rounded(self,Rect2(at,Vector2(170,100)),Color("3d535d"),8)
	for row in [20,50]:
		for x in range(14,153,23):
			draw_rect(Rect2(at+Vector2(x,row),Vector2(16,18)),Color("b3c5be"))
			draw_circle(at+Vector2(x+8,row-4),2,Color("a7ce83"))
	draw_polyline(PackedVector2Array([rect.position+Vector2(170,112),rect.position+Vector2(195,145),rect.position+Vector2(240,112)]),Color("6f9dc1"),4,true)
