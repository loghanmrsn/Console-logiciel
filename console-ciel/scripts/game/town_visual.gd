extends Node2D
## Detailed, original 2D town scenery; solid bases are owned by TownLayout.
const Town = preload("res://scripts/game/town_layout.gd")
var furniture_only: Dictionary = {}
var furniture_anchor := Vector2.ZERO
var water_time := 0.0
func _ready() -> void:
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
		_prop(furniture_only)
		return
	for road in Town.roads():
		draw_rect(road.grow(34),Color("c9c6b7"))
		draw_rect(road,Color("546269"))
		if road.size.x > road.size.y:
			for x in range(int(road.position.x)+20,int(road.end.x)-20,100): draw_line(Vector2(x,road.get_center().y),Vector2(x+45,road.get_center().y),Color("dedcc6"),3)
		else:
			for y in range(int(road.position.y)+20,int(road.end.y)-20,100): draw_line(Vector2(road.get_center().x,y),Vector2(road.get_center().x,y+45),Color("dedcc6"),3)
	for point in Town.roundabouts():
		draw_circle(point,145,Color("546269"))
		draw_arc(point,100,0,TAU,64,Color("d5d7c6"),3,true)
	# Mark pedestrian crossings at the park approaches.
	for at in [Vector2(2720,1300),Vector2(2720,2650),Vector2(4300,2650)]:
		for y in range(0,200,28): draw_rect(Rect2(at+Vector2(0,y),Vector2(110,12)),Color("ede9d4"))
	draw_rect(Town.PARK,Color("afc59d"))
	draw_rect(Rect2(2840,1660,180,850),Color("d9d4bf"))
	draw_rect(Rect2(2210,2000,1450,140),Color("d9d4bf"))
	_text("PARC DES TILLEULS",Vector2(2940,1630),27)
	_text("CENTRE · RITZ / CONSOLE CIEL ←",Vector2(2630,1260),24)
	for b in Town.buildings():
		var rect: Rect2 = b.rect
		draw_rect(Rect2(rect.position+Vector2(0,rect.size.y),Vector2(rect.size.x,36)),Color("c5c4b4"))
func _prop(spec: Dictionary) -> void:
	var rect: Rect2 = spec.rect
	var at := rect.position
	draw_rect(Rect2(at+Vector2(8,10),rect.size),Color(0.13,.20,.22,.16))
	match str(spec.kind):
		"building": _building(spec)
		"tree", "island":
			var center := rect.get_center()
			draw_circle(center,rect.size.x*.5,Color("b4bc9e"))
			draw_circle(center-Vector2(0,30),rect.size.x*.42,Color("698b70"))
			draw_circle(center-Vector2(12,42),rect.size.x*.3,Color("87a07b"))
		"fountain":
			var center := rect.get_center()
			draw_circle(center,95,Color("aaa990"))
			draw_circle(center-Vector2(0,8),88,Color("dce0d2"))
			draw_circle(center-Vector2(0,10),74,Color("81b8c1"))
			for index in range(3):
				var offset := Vector2((index-1)*32,-12)
				draw_arc(center+offset,24+4*sin(water_time*2+index),0,TAU,32,Color("c3e0de"),2,true)
				draw_line(center+offset,center+offset-Vector2(0,65+5*sin(water_time*3)),Color("d5eeec"),5,true)
		"shelter":
			draw_rect(Rect2(at-Vector2(6,90),Vector2(rect.size.x+12,112)),Color("bad0ce"))
			for x in [at.x,rect.end.x]: draw_line(Vector2(x,at.y-90),Vector2(x,rect.end.y),Color("405e66"),7)
			draw_rect(Rect2(at-Vector2(15,103),Vector2(rect.size.x+30,18)),Color("355962"))
			_text("BUS · CENTRE",rect.get_center()-Vector2(0,120),18)
			_text("1 · SUDO HACK / 2 · LYCÉE",rect.get_center()-Vector2(0,65),11)
			_text("1 € = 10 POINTS",rect.get_center()-Vector2(0,44),12)
		"bench":
			draw_rect(rect,Color("ad9872"))
			for y in [8,20,32]: draw_line(at+Vector2(4,y),Vector2(rect.end.x-4,at.y+y),Color("d4c4a1"),2)
		"lamp":
			draw_line(rect.get_center(),rect.get_center()-Vector2(0,130),Color("5b7476"),7)
			draw_circle(rect.get_center()-Vector2(0,130),14,Color("eddfac"))
func _building(spec: Dictionary) -> void:
	var rect: Rect2 = spec.rect
	var index := int(spec.index)
	var palettes := [Color("d7c9ae"),Color("c9d1c3"),Color("d7bdb2"),Color("c0ced0"),Color("d3cdbc")]
	var base: Color = palettes[index%palettes.size()]
	draw_rect(rect,base)
	draw_rect(Rect2(rect.position,Vector2(18,rect.size.y)),base.darkened(.15))
	var roof := Rect2(rect.position+Vector2(0,-34),Vector2(rect.size.x,75))
	draw_colored_polygon(PackedVector2Array([roof.position,roof.position+Vector2(28,-30),roof.position+Vector2(roof.size.x-28,-30),roof.position+Vector2(roof.size.x,0),roof.end,roof.position+Vector2(0,roof.size.y)]),Color("637c7b") if index%2 == 0 else Color("a37b69"))
	for x in range(int(rect.position.x)+35,int(rect.end.x)-30,85):
		for y in range(int(rect.position.y)+65,int(rect.end.y)-70,65):
			draw_rect(Rect2(x-4,y-4,51,48),Color("ece8d6"))
			draw_rect(Rect2(x,y,43,40),Color("6f949e"))
			draw_line(Vector2(x+21,y),Vector2(x+21,y+40),Color("d4e1d7"),2)
			if index%3==0: draw_line(Vector2(x-7,y+36),Vector2(x+50,y+36),Color("536e70"),4)
	var door := Vector2(rect.get_center().x,rect.end.y-52)
	draw_rect(Rect2(door-Vector2(26,0),Vector2(52,52)),Color("466b73"))
	draw_line(door+Vector2(0,4),door+Vector2(0,48),Color("bad6d1"),3)
	if index < 22 or index > 26:
		var awning := Rect2(rect.position+Vector2(18,rect.size.y-85),Vector2(rect.size.x-36,24))
		draw_rect(awning,Color("577f76") if index%2 == 0 else Color("ab7163"))
		for x in range(int(awning.position.x)+5,int(awning.end.x)-5,32): draw_rect(Rect2(x,awning.position.y,13,24),Color("e6dcca"))
	_text(str(spec.title),Vector2(rect.get_center().x,rect.end.y-95),19)
func _text(value: String, at: Vector2, size: int) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font,at-Vector2(font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("344f58"))
