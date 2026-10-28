extends Node2D
## Original layered 2D characters. Only short focus gestures animate; feet stay fixed.
var character: Dictionary = {}
var _attention := 0.0:
	set(value):
		_attention = value
		queue_redraw()
var _attentive := false
var _look := Vector2.ZERO
var _target_look := Vector2.ZERO
var _gesture: Tween

func configure(spec: Dictionary) -> void:
	character = spec.duplicate(true)
	queue_redraw()

func _draw() -> void:
	draw_character(self, character, _attention, _look)

func set_attention(value: bool) -> void:
	if _attentive == value: return
	_attentive = value
	if is_instance_valid(_gesture): _gesture.kill()
	var settings := get_node_or_null("/root/SettingsService") if is_inside_tree() else null
	if not is_inside_tree() or (settings != null and settings.current.get("reduce_motion", false)):
		_attention = 1.0 if value else 0.0
		return
	_gesture = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_gesture.tween_property(self, "_attention", 1.0 if value else 0.0, .16)

func look_toward(direction: Vector2) -> void:
	_target_look = direction.normalized()
	var settings := get_node_or_null("/root/SettingsService")
	if settings != null and settings.current.get("reduce_motion", false):
		_look = _target_look
		set_process(false)
		queue_redraw()
	else:
		set_process(_look.distance_squared_to(_target_look) > .0001)

func _process(delta: float) -> void:
	_look = _look.lerp(_target_look, 1.0 - exp(-16.0 * delta))
	if _look.distance_squared_to(_target_look) < .0001:
		_look = _target_look
		set_process(false)
	queue_redraw()

func _ready() -> void:
	set_process(false)

func _exit_tree() -> void:
	if is_instance_valid(_gesture): _gesture.kill()

static func _rounded(canvas: CanvasItem, rect: Rect2, color: Color, radius := 4.0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(radius))
	canvas.draw_style_box(style, rect)

static func _ellipse(canvas: CanvasItem, at: Vector2, radius: Vector2, color: Color) -> void:
	canvas.draw_set_transform(at, 0, radius)
	canvas.draw_circle(Vector2.ZERO, 1, color)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_character(canvas: CanvasItem, spec: Dictionary, attention := 0.0, look := Vector2.ZERO) -> void:
	var coat := Color(str(spec.get("coat", "749b90")))
	var skin := Color(str(spec.get("skin", "dfbca0")))
	var hair := Color(str(spec.get("hair", "665248")))
	var accessory := str(spec.get("accessory", "badge"))
	var hairstyle := str(spec.get("hairstyle", "short"))
	var ink := Color("405656")
	_ellipse(canvas, Vector2(0, -3), Vector2(18, 5), Color(.19, .29, .28, .09))
	_ellipse(canvas, Vector2(0, -3), Vector2(12, 3), Color(.19, .29, .28, .13))
	# Back hair, trousers and shoes sit below the jacket, never below the feet.
	if hairstyle == "bob": _rounded(canvas, Rect2(-15, -59, 30, 27), hair.darkened(.12), 11)
	if hairstyle == "bun": canvas.draw_circle(Vector2(10, -62), 7, hair.darkened(.1))
	for x in [-11, 2]:
		_rounded(canvas, Rect2(x, -21, 9, 18), Color("51676b"))
		canvas.draw_line(Vector2(x + 2, -15), Vector2(x + 2, -6), Color("698082"), 1, true)
		_rounded(canvas, Rect2(x - 1, -6, 11, 6), Color("344d52"), 3)
		canvas.draw_line(Vector2(x + 1, -3), Vector2(x + 7, -3), Color("61797c"), 1, true)
	_rounded(canvas, Rect2(-15, -38, 30, 26), coat.darkened(.24), 8)
	_rounded(canvas, Rect2(-13, -37, 26, 23), coat, 7)
	_rounded(canvas, Rect2(-11, -35, 9, 3), coat.lightened(.18), 2)
	canvas.draw_line(Vector2(-11, -16), Vector2(11, -16), coat.darkened(.18), 1, true)
	# The near hand rises a few pixels in greeting; the collider stays still.
	for side in [-1, 1]:
		var raise := attention * 3 if side == 1 else 0.0
		_rounded(canvas, Rect2(12 if side == 1 else -19, -33 - raise, 7, 15), coat.darkened(.06), 4)
		_rounded(canvas, Rect2(12 if side == 1 else -19, -23 - raise, 7, 8), skin.darkened(.08), 3)
		_rounded(canvas, Rect2(13 if side == 1 else -18, -22 - raise, 5, 5), skin.lightened(.06), 3)
	_rounded(canvas, Rect2(-5, -42, 10, 9), skin.darkened(.12), 3)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-8, -36), Vector2(-1, -31), Vector2(0, -36)]), Color("e5e4d7"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(8, -36), Vector2(1, -31), Vector2(0, -36)]), Color("f3eee1"))
	canvas.draw_line(Vector2(0, -31), Vector2(0, -16), coat.darkened(.18), 1, true)
	match accessory:
		"apron":
			_rounded(canvas, Rect2(-9, -31, 18, 19), Color("ede5d4"), 3)
			canvas.draw_line(Vector2(-7, -35), Vector2(-6, -28), Color("f6efdf"), 2, true)
			canvas.draw_line(Vector2(7, -35), Vector2(6, -28), Color("f6efdf"), 2, true)
			_rounded(canvas, Rect2(-5, -23, 10, 6), Color("d5c7a9"), 2)
			canvas.draw_line(Vector2(-4, -22), Vector2(4, -22), Color("f7f0e0"), 1, true)
		"tie":
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(0, -34), Vector2(-3, -25), Vector2(0, -21), Vector2(3, -25)]), Color("e8d7ac"))
			canvas.draw_line(Vector2(-10, -32), Vector2(-5, -25), coat.lightened(.25), 1, true)
			canvas.draw_line(Vector2(10, -32), Vector2(5, -25), coat.lightened(.25), 1, true)
			_rounded(canvas, Rect2(5, -27, 6, 3), Color("d9c793"), 1)
		"vest":
			for x in [-9, 7]: _rounded(canvas, Rect2(x, -34, 3, 19), Color("f1edcf"), 1)
			canvas.draw_line(Vector2(-12, -23), Vector2(12, -23), Color("f1edcf"), 3, true)
			_rounded(canvas, Rect2(-5, -29, 4, 4), coat.darkened(.28), 1)
		_:
			canvas.draw_line(Vector2(-2, -33), Vector2(6, -25), coat.darkened(.34), 1.4, true)
			_rounded(canvas, Rect2(4, -28, 7, 9), Color("ece7d5"), 1)
			canvas.draw_circle(Vector2(7.5, -25), 1.2, coat.darkened(.2))
			canvas.draw_line(Vector2(6, -22), Vector2(10, -22), Color("a5b0a1"), 1, true)
	for y in [-26, -20]: canvas.draw_circle(Vector2(-1, y), .8, coat.lightened(.38))
	# Face: ears, softly shaded cheeks, brows and a small smile.
	canvas.draw_circle(Vector2(-13, -48), 3, skin.darkened(.08))
	canvas.draw_circle(Vector2(13, -48), 3, skin.darkened(.08))
	_ellipse(canvas, Vector2(0, -48), Vector2(14, 15), skin.darkened(.12))
	_ellipse(canvas, Vector2(0, -49), Vector2(13, 14), skin)
	_ellipse(canvas, Vector2(-3, -51), Vector2(9, 10), skin.lightened(.06))
	for x in [-8, 8]: _ellipse(canvas, Vector2(x, -44), Vector2(3, 1.8), skin.lerp(Color("c98779"), .25))
	var eye_shift := look * Vector2(1.1, .7)
	for x in [-5, 5]:
		canvas.draw_line(Vector2(x - 2, -51), Vector2(x + 2, -51.5), hair.lightened(.05), 1.2, true)
		canvas.draw_circle(Vector2(x, -48) + eye_shift, 1.6, ink)
		canvas.draw_circle(Vector2(x - .4, -48.5) + eye_shift, .45, Color("fff4df"))
	canvas.draw_line(Vector2(0, -47), Vector2(1, -44.5), skin.darkened(.15), 1.1, true)
	canvas.draw_arc(Vector2(0, -43), 4, .35, PI - .35, 12, skin.darkened(.3), 1.2, true)
	_draw_hair(canvas, hairstyle, hair, coat)
	if accessory == "glasses":
		for x in [-6, 6]:
			canvas.draw_arc(Vector2(x, -48), 4.5, 0, TAU, 20, ink, 1.1, true)
			canvas.draw_line(Vector2(x - 2, -50), Vector2(x, -51), Color("d4e7df"), 1, true)
		canvas.draw_line(Vector2(-1.5, -48), Vector2(1.5, -48), ink, 1, true)
		canvas.draw_arc(Vector2(0, -39), 7, 0, PI, 14, hair, 2, true)

static func _draw_hair(canvas: CanvasItem, style: String, hair: Color, coat: Color) -> void:
	match style:
		"curls":
			for center in [Vector2(-10, -59), Vector2(-4, -62), Vector2(3, -62), Vector2(10, -59)]:
				canvas.draw_circle(center, 5, hair)
				canvas.draw_arc(center, 3, PI, TAU, 10, hair.lightened(.18), 1, true)
		"bob":
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-14, -48), Vector2(-14, -58), Vector2(-6, -64), Vector2(7, -64), Vector2(14, -57), Vector2(14, -44), Vector2(10, -45), Vector2(8, -56), Vector2(-1, -53), Vector2(-10, -52), Vector2(-11, -45)]), hair)
			canvas.draw_line(Vector2(-8, -59), Vector2(2, -61), hair.lightened(.2), 1.3, true)
		"bun":
			canvas.draw_arc(Vector2(0, -51), 13, PI, TAU, 24, hair, 7, true)
			canvas.draw_line(Vector2(-10, -55), Vector2(7, -60), hair.lightened(.2), 1.4, true)
			canvas.draw_arc(Vector2(10, -62), 5, -.6, 1.5, 14, hair.lightened(.2), 1, true)
		"cap":
			_rounded(canvas, Rect2(-14, -63, 28, 12), coat.darkened(.25), 6)
			_rounded(canvas, Rect2(-16, -54, 29, 4), coat.darkened(.4), 2)
			_rounded(canvas, Rect2(-3, -60, 6, 5), Color("e6ddb5"), 2)
		_:
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-14, -49), Vector2(-13, -58), Vector2(-6, -64), Vector2(7, -63), Vector2(14, -56), Vector2(13, -49), Vector2(5, -55), Vector2(-3, -53), Vector2(-10, -52)]), hair)
			canvas.draw_line(Vector2(-7, -59), Vector2(4, -60), hair.lightened(.2), 1.2, true)
			if style == "side_part": canvas.draw_line(Vector2(6, -61), Vector2(3, -56), hair.darkened(.25), 1.5, true)
