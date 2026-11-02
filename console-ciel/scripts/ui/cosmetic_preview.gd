extends Control
## Catalog illustration uses the item's real palette / avatar / frame.
const Avatar = preload('res://scripts/ui/avatar_icon.gd')
const Materials = preload('res://scripts/game/render_materials.gd')
var item: Dictionary

func configure(value: Dictionary) -> void:
	item = value
	custom_minimum_size = Vector2(0, 92)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if item.type != 'theme':
		var icon := Avatar.new()
		icon.color = Color(item.get('color', '#527FA3'))
		icon.variant = {'H':0, 'O':2, 'F':1, 'R':2}.get(item.get('symbol', 'H'), 0)
		if item.type == 'frame':
			icon.frame = item.id
			icon.frame_spec = item
		icon.custom_minimum_size = Vector2(72, 72)
		add_child(icon)
		resized.connect(func(): icon.position = (size - Vector2(72, 72)) / 2; icon.size = Vector2(72, 72))
	resized.connect(queue_redraw)

func _draw() -> void:
	if item.is_empty(): return
	var accent := Color(item.get('accent', item.get('color', '#527FA3')))
	var background := Color(item.get('secondary', '#E6EDF2'))
	Materials.rounded(self, Rect2(Vector2.ZERO, size), background, 12)
	if item.type == 'theme':
		var rect := Rect2(Vector2(size.x * .16, 8), Vector2(size.x * .68, size.y - 16))
		Materials.shadow(self, rect, 7, .12, Vector2(0, 3))
		Materials.rounded(self, rect, Color(item.get('background', '#F3F5F7')), 7, accent.darkened(.15), 1)
		var top := rect.position + Vector2(8, 9)
		Materials.rounded(self, Rect2(top, Vector2(rect.size.x * .57, rect.size.y * .49)), background, 4)
		Materials.rounded(self, Rect2(top + Vector2(5, 5), Vector2(rect.size.x * .24, 3)), accent, 1)
		for y in [13, 19]:
			draw_line(top + Vector2(5, y), top + Vector2(rect.size.x * .43, y), accent.lightened(.35), 2, true)
		draw_circle(top + Vector2(rect.size.x * .76, 13), 10, accent)
		var nav := Rect2(rect.position + Vector2(8, rect.size.y - 19), Vector2(rect.size.x - 16, 12))
		Materials.rounded(self, nav, background, 5)
		Materials.rounded(self, Rect2(nav.position + Vector2(3, 2), Vector2(nav.size.x * .25, 8)), accent, 3)
		for fraction in [.43, .66, .85]:
			draw_circle(nav.position + Vector2(nav.size.x * fraction, 6), 2, accent)
	else:
		Materials.ellipse(self, Rect2(Vector2(size.x * .5 - 31, size.y - 15), Vector2(62, 8)), Color(accent.darkened(.3), .16))
		draw_arc(size * .5, 38, -PI * .8, PI * .1, 36, Color(accent, .18), 1, true)
