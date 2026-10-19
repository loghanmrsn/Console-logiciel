extends SceneTree
## Inspect real PhysicsServer shapes and navigate a radius-10 player, across
## every floor and hotel zone. No user profile or gameplay reward is modified.
const World = "res://scenes/investigation_world.tscn"
const Hotel = preload("res://scripts/game/hotel_layout.gd")
var checks := 0
var failures: Array[String] = []
var segments := 0
var bodies := 0
var scene
var query: PhysicsShapeQueryParameters2D

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("COLLISION_FAIL : ", message)

func _run() -> void:
	await process_frame
	query = PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.2
	query.shape = circle
	query.collision_mask = 1
	var zones: Array = ["room_01", "room_02", "room_03", "room_04", "room_05", "maze_05", "courtyard"] + Hotel.ZONES
	for zone in zones:
		scene = load(World).instantiate()
		root.add_child(scene)
		scene.restore_progress({"room_id": zone, "checkpoint_id": "entrance", "completed_missions": ["lighting", "lock", "computer"], "hotel": {"reserved": true, "repaired": true, "luggage_placed": true, "bed_state": "standing", "morning_stage": 5}})
		scene.set_controls_enabled(false)
		await physics_frame
		await physics_frame
		_check(scene.player.get_parent().y_sort_enabled, zone + " : le personnage est trié avec les objets")
		if Hotel.is_zone(zone):
			_check(scene._hotel_props.size() == Hotel.furniture_specs(zone).size(), zone + " : chaque modèle possède un objet physique trié")
			for visual in scene._hotel_props:
				_check(visual.get_parent() is StaticBody2D and visual.get_parent().get_parent() == scene._props, zone + " : collision et modèle ont le même parent")
		_audit_shapes(scene._room_root)
		_check_routes(zone)
		scene.free()
		await physics_frame
	print("WORLD_COLLISION : %d assertions, %d échec(s). %d objets physiques, %d segments vérifiés." % [checks, failures.size(), bodies, segments])
	quit(0 if failures.is_empty() else 1)

func _clear(at: Vector2) -> bool:
	query.transform = Transform2D(0, at)
	return scene.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _audit_shapes(node: Node) -> void:
	if node is StaticBody2D and node.collision_layer == 1:
		for child in node.get_children():
			if child is CollisionShape2D and not child.disabled:
				bodies += 1
				_check(child.shape != null and not _clear(child.global_position), str(node.name) + " : objet solide réellement actif")
	for child in node.get_children(): _audit_shapes(child)

func _check_routes(zone: String) -> void:
	var checkpoints: Dictionary = scene._chapter_checkpoints()
	var step := 32.0
	var extent: Vector2 = scene.world_extent()
	var width := ceili(extent.x / step)
	var height := ceili(extent.y / step)
	var points: Array[Vector2] = []
	for key in checkpoints:
		points.append(checkpoints[key])
		_check(_clear(checkpoints[key]), zone + " : reprise sans chevauchement " + str(key))
	for target in scene._targets:
		points.append(target.position)
		_check(_clear(target.position), zone + " : approche libre " + target.interaction_id)
	var clear: Dictionary = {}
	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			if _clear((Vector2(cell) + Vector2(.5, .5)) * step): clear[cell] = true
	var origin: Vector2i = Vector2i(checkpoints.entrance / step)
	if not clear.has(origin):
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if clear.has(origin + offset):
				origin += offset
				break
	var visited := {origin: true}
	var queue: Array[Vector2i] = [origin]
	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			if not clear.has(next) or visited.has(next): continue
			var from := (Vector2(cell) + Vector2(.5, .5)) * step
			segments += 1
			if not scene.player.test_move(Transform2D(0, from), Vector2(offset) * step):
				visited[next] = true
				queue.append(next)
	for point in points:
		var reached := false
		var target_cell := Vector2i(point / step)
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var cell := target_cell + Vector2i(dx, dy)
				if not visited.has(cell): continue
				var from := (Vector2(cell) + Vector2(.5, .5)) * step
				if not scene.player.test_move(Transform2D(0, from), point - from): reached = true
		_check(reached, zone + " : parcours physique jusqu’à " + str(point))
