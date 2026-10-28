extends Node2D
## Slow traffic plus a crossing state machine. Movement and clocks stop with
## gameplay. A red entry is penalized only after reaching the opposite kerb.
signal notice(message: String)
const Layout = preload("res://scripts/game/road_layout.gd")
const GREEN_SECONDS := 10.0
const RED_SECONDS := 10.0
const CLEAR_SECONDS := 4.0
enum Phase { GREEN, RED, CLEARING }
var phase := Phase.GREEN
var remaining := GREEN_SECONDS
var enabled := true
var player: CharacterBody2D
var cars: Array[Dictionary] = []
var attempt_side := 0
var entered_red := false
var crossing_id := ""
var last_safe_side := 1
var _previous := Vector2.INF
var _hit_cooldown := 0.0
var _drawn_phase := -1
var _signals: Array[Node2D] = []

class Car extends Area2D:
	var color := Color("4e8297")
	var direction := 1
	func _ready() -> void:
		collision_layer = 4
		collision_mask = 2
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(104, 54)
		shape.shape = box
		shape.position.y = -27
		add_child(shape)
	func _draw() -> void:
		draw_set_transform(Vector2(0, -27))
		var shadow := StyleBoxFlat.new()
		shadow.bg_color = Color(0.06, .09, .12, .23)
		shadow.set_corner_radius_all(13)
		draw_style_box(shadow, Rect2(-50, -20, 108, 56))
		for x in [-33, 26]:
			for y in [-30, 22]: draw_rect(Rect2(x, y, 15, 8), Color("263339"))
		var shell := StyleBoxFlat.new()
		shell.bg_color = color
		shell.border_color = color.darkened(.3)
		shell.set_border_width_all(2)
		shell.set_corner_radius_all(12)
		draw_style_box(shell, Rect2(-52, -27, 104, 54))
		draw_rect(Rect2(-19, -22, 42, 44), color.lightened(.12))
		for x in [-30, 22]:
			draw_rect(Rect2(x, -20, 10, 40), Color("284d60"))
			draw_line(Vector2(x + 2, -16), Vector2(x + 7, 9), Color("89bac6"), 2, true)
		draw_line(Vector2(-43, -21), Vector2(40, -21), color.lightened(.4), 2, true)
		for y in [-18, 11]:
			draw_rect(Rect2(45 * direction - 3, y, 6, 7), Color("fff0bc"))
			draw_rect(Rect2(-47 * direction - 3, y, 6, 7), Color("d36657"))

func _ready() -> void:
	name = "RoadTraffic"
	y_sort_enabled = true
	process_physics_priority = 1
	for at in [Vector2(1070, 569), Vector2(738, 930)]:
		var light := PedestrianSignal.new()
		light.position = at
		add_child(light)
		_signals.append(light)
	for spec in [[260.0, 645.0, 1, "517d9b"], [620.0, 645.0, 1, "b18358"], [1180.0, 755.0, -1, "6e927c"], [1620.0, 755.0, -1, "a15e63"]]:
		var car := Car.new()
		car.color = Color(spec[3])
		car.direction = int(spec[2])
		car.position = Vector2(spec[0], spec[1] + 27)
		add_child(car)
		car.body_entered.connect(_body_entered)
		cars.append({"x": float(spec[0]), "y": float(spec[1]), "direction": int(spec[2]), "body": car})

func reset_for_spawn(at: Vector2) -> void:
	attempt_side = 0
	entered_red = false
	crossing_id = ""
	_previous = at
	var side := Layout.side(at)
	if side != 0: last_safe_side = side
	_hit_cooldown = .4

func _physics_process(delta: float) -> void:
	if not enabled or not is_visible_in_tree() or not is_instance_valid(player): return
	if not SceneRouter.gameplay_allowed(): return
	advance(delta, player.position)

func advance(delta: float, point: Vector2) -> void:
	if delta <= 0: return
	if not _previous.is_finite(): reset_for_spawn(point)
	# Explicit room/checkpoint restores are discontinuities, never a walking
	# crossing or a swept collision through the whole map.
	if point.distance_to(_previous) > maxf(64, 300 * delta):
		reset_for_spawn(point)
		return
	_hit_cooldown = maxf(0, _hit_cooldown - delta)
	_track_entry(point)
	var steps := maxi(1, ceili(delta / .04))
	var from := _previous
	for step in range(steps):
		var to := _previous.lerp(point, float(step + 1) / steps)
		if _advance_cars(delta / steps, from, to):
			_respawn_after_hit()
			return
		from = to
	remaining -= delta
	if remaining <= 0:
		if phase == Phase.GREEN:
			# Let a pedestrian who started on green finish before releasing cars.
			if attempt_side == 0 or entered_red:
				phase = Phase.RED
				remaining = RED_SECONDS
		elif phase == Phase.RED:
			phase = Phase.CLEARING
			remaining = CLEAR_SECONDS
		elif _crosswalk_clear():
			phase = Phase.GREEN
			remaining = GREEN_SECONDS
	_track_finish(point)
	_previous = player.position if is_instance_valid(player) else point
	if phase != _drawn_phase:
		_drawn_phase = phase
		for light in _signals:
			light.green = phase == Phase.GREEN
			light.queue_redraw()

func _track_entry(point: Vector2) -> void:
	var side := Layout.side(point)
	if attempt_side == 0:
		if side != 0:
			last_safe_side = side
		elif Layout.ROAD.has_point(point):
			attempt_side = last_safe_side
			entered_red = phase != Phase.GREEN
			crossing_id = Crypto.new().generate_random_bytes(16).hex_encode()

func _track_finish(point: Vector2) -> void:
	if attempt_side == 0: return
	var side := Layout.side(point)
	if side == 0: return
	if side != attempt_side and entered_red:
		var result := PenaltyService.record_crossing(crossing_id)
		if not result.ok:
			_move_to_start(attempt_side)
			notice.emit("Passage non enregistré : sauvegarde indisponible. Réessayez la traversée.")
			return
		notice.emit("Traversée au rouge · pénalité de 200 points" + (" · dette : %d points" % result.data.debt if int(result.data.debt) > 0 else ""))
	last_safe_side = side
	attempt_side = 0
	entered_red = false
	crossing_id = ""

func _advance_cars(delta: float, from: Vector2, to: Vector2) -> bool:
	var previous_x: Array[float] = []
	for car in cars: previous_x.append(float(car.x))
	for index in range(cars.size()):
		var car := cars[index]
		var old_x := previous_x[index]
		var distance := Layout.SPEED * delta
		for other in range(cars.size()):
			if index == other or cars[other].direction != car.direction: continue
			var gap := fposmod((previous_x[other] - old_x) * car.direction, Layout.LOOP_END - Layout.LOOP_START)
			distance = minf(distance, maxf(0, gap - 155))
		var next_x: float = old_x + distance * car.direction
		if phase != Phase.RED:
			if car.direction > 0 and old_x <= Layout.STOP_EAST: next_x = minf(next_x, Layout.STOP_EAST)
			if car.direction < 0 and old_x >= Layout.STOP_WEST: next_x = maxf(next_x, Layout.STOP_WEST)
		var wrapped := next_x > Layout.LOOP_END or next_x < Layout.LOOP_START
		if wrapped: next_x = Layout.LOOP_START if car.direction > 0 else Layout.LOOP_END
		car.x = next_x
		car.body.position = Vector2(next_x, car.y + 27)
		if wrapped: car.body.reset_physics_interpolation()
		if not wrapped and _hit_cooldown <= 0 and _swept_hit(from - Vector2(old_x, car.y), to - Vector2(next_x, car.y)):
			return true
	return false

func _swept_hit(from: Vector2, to: Vector2) -> bool:
	var box := Rect2(-Layout.CAR_SIZE * .5, Layout.CAR_SIZE).grow(10)
	if box.has_point(from) or box.has_point(to): return true
	var corners := [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]
	for index in range(4):
		if Geometry2D.segment_intersects_segment(from, to, corners[index], corners[(index + 1) % 4]) != null: return true
	return false

func _crosswalk_clear() -> bool:
	for car in cars:
		if Layout.CROSSING.grow(14).intersects(Rect2(Vector2(car.x, car.y) - Layout.CAR_SIZE * .5, Layout.CAR_SIZE)): return false
	return true

func _body_entered(body: Node2D) -> void:
	if enabled and is_visible_in_tree() and SceneRouter.gameplay_allowed() and body == player and _hit_cooldown <= 0: _respawn_after_hit()

func _respawn_after_hit() -> void:
	_move_to_start(attempt_side if attempt_side != 0 else last_safe_side)
	_hit_cooldown = 1.0
	notice.emit("Voiture touchée · retour au départ de la traversée. Vos missions sont conservées.")

func _move_to_start(side: int) -> void:
	var at := Layout.start_for(side)
	if is_instance_valid(player):
		player.position = at
		player.velocity = Vector2.ZERO
		player.reset_physics_interpolation()
	reset_for_spawn(at)

class PedestrianSignal extends Node2D:
	var green := true
	func _draw() -> void:
		var at := Vector2(0, -55)
		draw_rect(Rect2(at - Vector2(6, 0), Vector2(12, 55)), Color("4d5e61"))
		var box := StyleBoxFlat.new()
		box.bg_color = Color("25383d")
		box.set_corner_radius_all(8)
		draw_style_box(box, Rect2(at - Vector2(21, 47), Vector2(42, 61)))
		draw_circle(at - Vector2(0, 29), 10, Color("dc655e") if not green else Color("58443f"))
		draw_circle(at - Vector2(0, 3), 10, Color("8bd0a1") if green else Color("354e46"))
		if green:
			draw_line(at + Vector2(-5, -3), at + Vector2(0, 2), Color("203c30"), 2)
			draw_line(at + Vector2(0, 2), at + Vector2(6, -6), Color("203c30"), 2)
