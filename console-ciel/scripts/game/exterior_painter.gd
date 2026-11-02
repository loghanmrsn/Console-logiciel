extends RefCounted
## Small, deterministic vector materials. Canvas draw lists stay cached by Godot.
const Materials = preload("res://scripts/game/render_materials.gd")

static func rounded(c: Node2D, r: Rect2, color: Color, radius: int = 4) -> void:
	Materials.rounded(c, r, color, radius)

static func ellipse(c: Node2D, center: Vector2, radius: Vector2, color: Color, points: int = 24) -> void:
	var shape := PackedVector2Array()
	for i in range(points):
		var angle := TAU * float(i) / float(points)
		shape.append(center + Vector2(cos(angle), sin(angle)) * radius)
	c.draw_colored_polygon(shape, color)

static func contact(c: Node2D, r: Rect2, strength: float = 1.0) -> void:
	Materials.shadow(c, r, 5, .20 * strength, Vector2(3, 5))

static func plaster(c: Node2D, r: Rect2, base: Color, seed: int = 0) -> void:
	# Large tonal planes suggest limewash; sparse marks avoid visual noise.
	c.draw_rect(r, base)
	c.draw_rect(Rect2(r.position, Vector2(r.size.x * .18, r.size.y)), base.darkened(.035))
	c.draw_rect(Rect2(r.position + Vector2(r.size.x * .18, 0), Vector2(r.size.x * .42, r.size.y)), base.lightened(.025))
	for i in range(18):
		var x := fposmod(float(i * 79 + seed * 31), maxf(1, r.size.x - 18)) + 8
		var y := fposmod(float(i * 47 + seed * 17), maxf(1, r.size.y - 12)) + 6
		c.draw_line(r.position + Vector2(x, y), r.position + Vector2(minf(x + 8 + i % 11, r.size.x - 4), y), Color(base.darkened(.13), .15), 1, true)

static func masonry(c: Node2D, r: Rect2, color: Color, course: float = 22.0, block: float = 64.0) -> void:
	for row in range(1, int(r.size.y / course)):
		var y := r.position.y + float(row) * course
		c.draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), color, 1, true)
		var shift := block * .5 if row % 2 == 0 else 0.0
		for col in range(1, int(r.size.x / block)):
			var x := r.position.x + float(col) * block - shift
			c.draw_line(Vector2(x, y - course + 2), Vector2(x, y - 2), color, 1, true)

static func tree(c: Node2D, r: Rect2, seed: int = 0) -> void:
	var center := r.get_center()
	var radius := r.size.x * .50
	ellipse(c, center + Vector2(8, 9), Vector2(radius * 1.12, radius * .58), Color(.17, .26, .20, .08))
	ellipse(c, center + Vector2(4, 6), Vector2(radius * .86, radius * .43), Color(.17, .26, .20, .12))
	c.draw_line(center + Vector2(0, 5), center - Vector2(3, radius * .96), Color("74694f"), maxf(4, radius * .16), true)
	c.draw_line(center - Vector2(2, radius * .45), center + Vector2(radius * .36, -radius * 1.08), Color("8d7b59"), maxf(2, radius * .08), true)
	var crown := center - Vector2(0, radius * .95)
	var greens: Array[Color] = [Color("617f61"), Color("78946a"), Color("8da475"), Color("a1b486")]
	for layer in range(3):
		for i in range(7):
			var angle := float(i) * TAU / 7.0 + float(seed % 5) * .24
			var reach := radius * (.52 - float(layer) * .13)
			var at := crown + Vector2(cos(angle) * reach, sin(angle) * reach * .76) - Vector2(float(layer) * 4, float(layer) * 5)
			ellipse(c, at, Vector2(radius * (.62 - float(layer) * .09), radius * (.49 - float(layer) * .05)), greens[layer + int(i % 3 == 0)])
	for i in range(5):
		var at := crown + Vector2(float(i % 3 - 1) * radius * .40, float(i / 3) * radius * .38 - radius * .37)
		c.draw_arc(at, radius * .17, PI * 1.1, TAU * .91, 8, Color("b4c395"), 1.4, true)

static func garden(c: Node2D, rect: Rect2) -> void:
	rounded(c,rect.grow(-5),Color("b6c3a6"),12)
	flowers(c,Rect2(rect.position+Vector2(12,rect.size.y-32),Vector2(rect.size.x-24,25)),3)
	for offset in [rect.size.x*.27,rect.size.x*.73]:
		tree(c,Rect2(rect.position+Vector2(offset-27,35),Vector2(54,60)),int(offset))

static func flowers(c: Node2D, r: Rect2, seed: int = 0) -> void:
	var count := maxi(4, int(r.size.x / 19))
	for i in range(count):
		var x := r.position.x + 8 + fposmod(float(i * 37 + seed * 11), maxf(1, r.size.x - 16))
		var y := r.position.y + r.size.y * .45 + fposmod(float(i * 13), maxf(1, r.size.y * .45))
		var at := Vector2(x, y)
		var height := 8.0 + float(i % 5) * 2.0
		c.draw_line(at, at - Vector2(2, height), Color("658461"), 1.5, true)
		ellipse(c, at - Vector2(3, height * .4), Vector2(4, 2), Color("839965"), 8)
		var petal := Color("d7c0cd") if (i + seed) % 3 else Color("f0e7cf")
		for offset in [Vector2(-2, -1), Vector2(2, -1), Vector2(0, -4)]:
			c.draw_circle(at - Vector2(2, height) + offset, 2.2, petal)
		c.draw_circle(at - Vector2(2, height + 1), 1.1, Color("d7b987"))
