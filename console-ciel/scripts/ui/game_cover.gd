extends Control
## Original local illustrations that fit the available cover rectangle.
const Materials = preload("res://scripts/game/render_materials.gd")
const RoomArt = preload('res://scripts/game/room_art.gd')
var item: Dictionary = {}

func _init() -> void:
	custom_minimum_size = Vector2(0, 104)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

func _ready() -> void:
	resized.connect(queue_redraw)

func configure(value: Dictionary) -> void:
	item = value.duplicate(true)
	queue_redraw()

func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	var accent = Color(item.get('color', '#527FA3'))
	var box = StyleBoxFlat.new()
	box.bg_color = accent.darkened(0.58)
	box.set_corner_radius_all(18)
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	if item.get('educational', false) or item.get('type', '') == 'educational':
		box.bg_color = Color('#D5E1DF')
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		RoomArt.draw_preview(self, Rect2(Vector2(8, 8), size - Vector2(16, 16)))
		return
	var factor = minf(size.x / 320.0, size.y / 180.0)
	var origin = (size - Vector2(320, 180) * factor) / 2.0
	draw_set_transform(origin, 0, Vector2(factor, factor))
	# Product photography language: a matte shell, rubber grips, recessed
	# controls and a soft contact shadow replace the angular icon silhouette.
	Materials.ellipse(self, Rect2(82, 125, 161, 19), Color(0, 0, 0, .30))
	var body := _contour([Vector2(96, 62), Vector2(120, 51), Vector2(200, 51), Vector2(224, 62), Vector2(243, 116), Vector2(234, 134), Vector2(215, 133), Vector2(185, 110), Vector2(135, 110), Vector2(105, 133), Vector2(86, 134), Vector2(77, 116)])
	var lower := PackedVector2Array()
	for point in body: lower.append(point + Vector2(0, 5))
	draw_colored_polygon(lower, accent.darkened(.23))
	draw_colored_polygon(body, accent.lightened(.12))
	var top_edge := body.duplicate()
	top_edge.append(body[0])
	draw_polyline(top_edge, Color(accent.lightened(.69), .56), 1.5, true)
	draw_colored_polygon(_contour([Vector2(89, 96), Vector2(112, 103), Vector2(124, 112), Vector2(103, 129), Vector2(88, 129), Vector2(82, 116)]), accent.darkened(.18))
	draw_colored_polygon(_contour([Vector2(231, 96), Vector2(208, 103), Vector2(196, 112), Vector2(217, 129), Vector2(232, 129), Vector2(238, 116)]), accent.darkened(.18))
	# Fine grip grooves follow the handles rather than a square background grid.
	for index in range(4):
		draw_line(Vector2(88 + index * 4, 111), Vector2(94 + index * 4, 122), Color(accent.lightened(.4), .28), 1, true)
		draw_line(Vector2(232 - index * 4, 111), Vector2(226 - index * 4, 122), Color(accent.lightened(.4), .28), 1, true)
	Materials.rounded(self, Rect2(132, 60, 56, 27), accent.darkened(.19), 5, Color(accent.lightened(.55), .4), 1)
	for x in range(138, 184, 4):
		draw_circle(Vector2(x, 67), .65, Color(accent.lightened(.65), .5))
	var dark := Color("1b2b38")
	for at in [Vector2(139, 96), Vector2(180, 96)]:
		draw_circle(at + Vector2(0, 2), 13, accent.darkened(.4))
		draw_circle(at, 11, dark)
		draw_arc(at, 8, 0, TAU, 24, Color("617582"), 1.5, true)
		draw_arc(at, 7, -2.8, -.5, 16, Color("92a5ab"), 1, true)
	draw_circle(Vector2(108, 80), 16, accent.darkened(.25))
	Materials.rounded(self, Rect2(103, 65, 10, 30), dark, 2)
	Materials.rounded(self, Rect2(93, 75, 30, 10), dark, 2)
	draw_line(Vector2(97, 77), Vector2(119, 77), Color("6a818b"), 1, true)
	var outline := accent.lightened(.78)
	for at in [Vector2(211, 66), Vector2(224, 80), Vector2(211, 94), Vector2(198, 80)]:
		draw_circle(at + Vector2(0, 1), 6.8, accent.darkened(.4))
		draw_circle(at, 5.5, dark)
		draw_arc(at, 3.5, -2.6, -.4, 12, outline, 1, true)
	var number = str(item.get('id', '')).get_slice('_', 2)
	var variation = clampi(int(number) - 1, 0, 3)
	for dot in range(variation + 1):
		draw_circle(Vector2(150 + dot * 7, 91), 1.5, outline)
	draw_set_transform(Vector2.ZERO)

func _contour(anchors: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	# Closed Catmull-Rom contour keeps the handles and shell smoothly joined.
	for index in range(anchors.size()):
		var a: Vector2 = anchors[posmod(index - 1, anchors.size())]
		var b: Vector2 = anchors[index]
		var c: Vector2 = anchors[(index + 1) % anchors.size()]
		var d: Vector2 = anchors[(index + 2) % anchors.size()]
		for step in range(8):
			var t := step / 8.0
			points.append(.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t * t + (-a + 3 * b - 3 * c + d) * t * t * t))
	return points
