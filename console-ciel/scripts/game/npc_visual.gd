extends Node2D
## Original, still 2D characters. Their solid feet and y-sort belong to the world.
var character: Dictionary = {}

func configure(spec: Dictionary) -> void:
	character = spec.duplicate(true)
	queue_redraw()

func _draw() -> void:
	draw_character(self, character)

static func _rounded(canvas: CanvasItem, rect: Rect2, color: Color, radius := 4.0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(radius))
	canvas.draw_style_box(style, rect)

static func draw_character(canvas: CanvasItem, spec: Dictionary) -> void:
	var coat := Color(str(spec.get("coat", "749b90")))
	var skin := Color(str(spec.get("skin", "dfbca0")))
	var hair := Color(str(spec.get("hair", "665248")))
	var accessory := str(spec.get("accessory", "badge"))
	canvas.draw_set_transform(Vector2(0, -3), 0, Vector2(1, .32))
	canvas.draw_circle(Vector2.ZERO, 17, Color(.19, .29, .28, .18))
	canvas.draw_set_transform(Vector2.ZERO)
	_rounded(canvas, Rect2(-11, -19, 9, 17), Color("52676b"))
	_rounded(canvas, Rect2(2, -19, 9, 17), Color("52676b"))
	_rounded(canvas, Rect2(-12, -5, 11, 5), Color("344d52"), 3)
	_rounded(canvas, Rect2(1, -5, 11, 5), Color("344d52"), 3)
	_rounded(canvas, Rect2(-15, -38, 30, 25), coat.darkened(.17), 8)
	_rounded(canvas, Rect2(-13, -37, 26, 23), coat, 7)
	_rounded(canvas, Rect2(-19, -34, 7, 19), skin, 4)
	_rounded(canvas, Rect2(12, -34, 7, 19), skin, 4)
	canvas.draw_line(Vector2(0, -34), Vector2(0, -16), coat.lightened(.35), 2, true)
	match accessory:
		"apron":
			_rounded(canvas, Rect2(-9, -32, 18, 19), Color("ece3cf"), 3)
			canvas.draw_line(Vector2(-6, -23), Vector2(6, -23), Color("c3b492"), 1, true)
		"tie":
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(0, -34), Vector2(-3, -24), Vector2(0, -20), Vector2(3, -24)]), Color("e8d7ac"))
		"vest":
			for x in [-9, 7]: _rounded(canvas, Rect2(x, -34, 3, 19), Color("ece8cd"), 1)
			canvas.draw_line(Vector2(-12, -23), Vector2(12, -23), Color("ece8cd"), 3, true)
		_:
			_rounded(canvas, Rect2(4, -29, 6, 7), Color("e9e4d2"), 1)
			canvas.draw_line(Vector2(5, -26), Vector2(9, -26), coat.darkened(.3), 1, true)
	canvas.draw_circle(Vector2(0, -46), 14, skin.darkened(.06))
	canvas.draw_circle(Vector2(0, -47), 13, skin)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-14, -48), Vector2(-13, -56), Vector2(-7, -61), Vector2(6, -62), Vector2(13, -57), Vector2(14, -48), Vector2(7, -52), Vector2(-2, -51), Vector2(-9, -48)]), hair)
	canvas.draw_circle(Vector2(-5, -45), 1.3, Color("36494b"))
	canvas.draw_circle(Vector2(5, -45), 1.3, Color("36494b"))
	canvas.draw_line(Vector2(-3, -39), Vector2(3, -39), skin.darkened(.2), 1.3, true)
	if accessory == "glasses":
		for x in [-6, 6]: canvas.draw_arc(Vector2(x, -45), 4, 0, TAU, 16, Color("596c68"), 1, true)
		canvas.draw_line(Vector2(-2, -45), Vector2(2, -45), Color("596c68"), 1, true)
