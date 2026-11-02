extends RefCounted
## Small cached drawing primitives for the console's soft material palette.
static var _boxes: Dictionary = {}

static func rounded(canvas: CanvasItem, rect: Rect2, color: Color, radius: float = 8, border: Color = Color.TRANSPARENT, border_width: int = 0) -> void:
	var corner := maxi(0,roundi(radius))
	var key := color.to_html()+":"+str(corner)+":"+border.to_html()+":"+str(border_width)
	if not _boxes.has(key):
		if _boxes.size()>=512: _boxes.clear()
		var box := StyleBoxFlat.new()
		box.bg_color=color
		box.set_corner_radius_all(corner)
		box.border_color=border
		box.set_border_width_all(border_width)
		box.anti_aliasing=true
		_boxes[key]=box
	canvas.draw_style_box(_boxes[key],rect)

static func shadow(canvas: CanvasItem, rect: Rect2, radius: float = 10, strength: float = .14, offset: Vector2 = Vector2(3,6)) -> void:
	# Three retained layers soften the edge without a viewport blur or shader.
	for layer in [3,2,1]:
		var spread := float(layer)*2
		rounded(canvas,Rect2(rect.position+offset,rect.size).grow(spread),Color(.10,.15,.18,strength/float(layer+3)),radius+spread)

static func ellipse(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	var points := PackedVector2Array()
	var center := rect.get_center()
	for index in range(40):
		var angle := TAU*float(index)/40
		points.append(center+Vector2(cos(angle),sin(angle))*rect.size*.5)
	canvas.draw_colored_polygon(points,color)
