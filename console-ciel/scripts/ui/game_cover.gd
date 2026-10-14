extends Control
## Original local illustrations that fit the available cover rectangle.
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
	draw_circle(Vector2(252, 27), 42, Color(accent.lightened(0.25), 0.12))
	draw_circle(Vector2(43, 146), 48, Color(accent.lightened(0.38), 0.10))
	var grid_color = Color(accent.lightened(0.6), 0.08)
	for x in range(40, 321, 40):
		draw_line(Vector2(x, 0), Vector2(x, 180), grid_color, 1)
	for y in range(30, 181, 30):
		draw_line(Vector2(0, y), Vector2(320, y), grid_color, 1)
	var outline = accent.lightened(0.78)
	var body = PackedVector2Array([Vector2(100, 60), Vector2(126, 49), Vector2(194, 49), Vector2(220, 60), Vector2(239, 115), Vector2(228, 131), Vector2(209, 129), Vector2(186, 110), Vector2(134, 110), Vector2(111, 129), Vector2(92, 131), Vector2(81, 115)])
	draw_colored_polygon(body, accent.lightened(0.06))
	draw_polyline(PackedVector2Array([Vector2(100, 60), Vector2(126, 49), Vector2(194, 49), Vector2(220, 60), Vector2(239, 115), Vector2(228, 131), Vector2(209, 129), Vector2(186, 110), Vector2(134, 110), Vector2(111, 129), Vector2(92, 131), Vector2(81, 115), Vector2(100, 60)]), outline, 2, true)
	draw_line(Vector2(111, 78), Vector2(111, 98), outline, 5, true)
	draw_line(Vector2(101, 88), Vector2(121, 88), outline, 5, true)
	draw_circle(Vector2(202, 78), 5, outline)
	draw_circle(Vector2(215, 91), 5, accent.lightened(0.35))
	var number = str(item.get('id', '')).get_slice('_', 2)
	var variation = clampi(int(number) - 1, 0, 3)
	for dot in range(variation + 1):
		draw_circle(Vector2(150 + dot * 7, 89), 2, outline)
	draw_set_transform(Vector2.ZERO)
