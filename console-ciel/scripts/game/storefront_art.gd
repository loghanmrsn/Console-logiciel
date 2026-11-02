extends RefCounted
## Original wall-mounted business signs and terrace objects; no new textures.
static func is_food(title: String) -> bool:
	var value := title.to_lower()
	return "café" in value or "restaurant" in value or "bar " in value
static func sign_rect(building: Rect2) -> Rect2:
	return Rect2(building.position+Vector2(22,building.size.y-154),Vector2(building.size.x-44,62))
static func sign(canvas: Node2D, spec: Dictionary) -> void:
	var rect := sign_rect(spec.rect)
	var title: String = spec.title
	var postal := title == "La Poste"
	var food := is_food(title)
	var face := Color("e6c75d") if postal else (Color("365c55") if food else Color("e8e0ca"))
	var ink := Color("284b66") if postal else (Color("fbf5e2") if food else Color("34525c"))
	canvas.draw_style_box(panel(Color(0.12,.18,.20,.22),5),Rect2(rect.position+Vector2(4,6),rect.size))
	canvas.draw_style_box(panel(Color("776a51"),5),rect.grow(4))
	canvas.draw_style_box(panel(face,3),rect)
	var icon_center := rect.position+Vector2(41,31)
	if postal:
		envelope(canvas,icon_center,Vector2(60,38),ink)
	elif food:
		cup(canvas,icon_center,15,ink,face)
	elif "Pharmacie" in title:
		canvas.draw_rect(Rect2(icon_center-Vector2(5,19),Vector2(10,38)),Color("4a8771"))
		canvas.draw_rect(Rect2(icon_center-Vector2(19,5),Vector2(38,10)),Color("4a8771"))
	else:
		canvas.draw_rect(Rect2(icon_center-Vector2(18,15),Vector2(36,30)),ink)
		canvas.draw_line(icon_center+Vector2(-13,-8),icon_center+Vector2(13,-8),face,3)
		canvas.draw_line(icon_center+Vector2(-13,0),icon_center+Vector2(13,0),face,3)
	var font := ThemeDB.fallback_font
	var text := title.to_upper()
	var font_size := 28
	while font_size>15 and font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>rect.size.x-100: font_size-=1
	var center := rect.position+Vector2(85+(rect.size.x-95)*.5,40)
	canvas.draw_string(font,center-Vector2(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x*.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,ink)
	for offset in [Vector2(7,7),Vector2(rect.size.x-7,7),Vector2(7,rect.size.y-7),rect.size-Vector2(7,7)]: canvas.draw_circle(rect.position+offset,2,Color("a89669"))
static func envelope(canvas: Node2D, center: Vector2, size: Vector2, color: Color) -> void:
	var rect := Rect2(center-size*.5,size)
	canvas.draw_style_box(panel(color,3),rect)
	var paper := Color("fff6d5")
	canvas.draw_polyline(PackedVector2Array([rect.position+Vector2(4,5),center+Vector2(0,5),Vector2(rect.end.x-4,rect.position.y+5)]),paper,3,true)
	canvas.draw_line(Vector2(rect.position.x+4,rect.end.y-4),center+Vector2(-8,0),paper,2,true)
	canvas.draw_line(rect.end-Vector2(4,4),center+Vector2(8,0),paper,2,true)
static func cup(canvas: Node2D, at: Vector2, radius: float, porcelain: Color, coffee: Color) -> void:
	canvas.draw_circle(at+Vector2(1,3),radius+4,porcelain.darkened(.13))
	canvas.draw_arc(at+Vector2(radius+1,0),radius*.45,-PI*.6,PI*.6,14,porcelain,3,true)
	canvas.draw_circle(at,radius,porcelain)
	canvas.draw_circle(at,radius*.65,coffee)
	canvas.draw_arc(at,radius*.76,PI,TAU,18,Color("f1ead8"),1.5,true)
static func furniture(canvas: Node2D, spec: Dictionary) -> void:
	var rect: Rect2 = spec.rect
	var at := rect.get_center()
	match str(spec.kind):
		"cafe_table":
			canvas.draw_circle(at+Vector2(4,7),32,Color(0.15,.20,.20,.20))
			canvas.draw_circle(at,32,Color("806a4f"))
			canvas.draw_circle(at-Vector2(0,3),29,Color("ceb78f"))
			canvas.draw_line(at+Vector2(-23,7),at+Vector2(24,7),Color("b39c76"),1)
			canvas.draw_rect(Rect2(at+Vector2(-5,-20),Vector2(15,13)),Color("f5efdc"))
			cup(canvas,at+Vector2(-12,-6),7,Color("fff9e8"),Color("674632"))
			cup(canvas,at+Vector2(13,11),7,Color("fff9e8"),Color("674632"))
		"cafe_chair":
			canvas.draw_style_box(panel(Color("57766b"),4),rect)
			canvas.draw_line(rect.position+Vector2(0,5),Vector2(rect.end.x,rect.position.y+5),Color("a9ba9b"),4)
			for x in [rect.position.x+3,rect.end.x-3]: canvas.draw_line(Vector2(x,rect.end.y-2),Vector2(x,rect.end.y+5),Color("4b5c55"),2)
		"menu_board":
			canvas.draw_line(at+Vector2(-20,10),at+Vector2(-12,-42),Color("a68961"),5)
			canvas.draw_line(at+Vector2(20,10),at+Vector2(12,-42),Color("a68961"),5)
			canvas.draw_style_box(panel(Color("927750"),3),Rect2(at-Vector2(23,42),Vector2(46,48)))
			canvas.draw_style_box(panel(Color("34554e"),1),Rect2(at-Vector2(19,38),Vector2(38,40)))
			canvas.draw_string(ThemeDB.fallback_font,at+Vector2(-15,-22),"MENU",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("f4efdc"))
			for y in [-13,-6]: canvas.draw_line(at+Vector2(-12,y),at+Vector2(12,y),Color("e0e5cf"),1.5)
static func panel(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(radius)
	return style
