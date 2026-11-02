extends Node2D
## Decorative, non-interactive pedestrians; moving cars keep slow, fixed routes.
const Layout = preload("res://scripts/game/town_layout.gd")
const Road = preload("res://scripts/game/road_traffic.gd")
var enabled := true
var player: CharacterBody2D
var traffic: Node2D
var people: Array[Dictionary] = []
var cars: Array[Dictionary] = []
var _safe := Vector2(2100,1580)
var _cooldown := 1.0
var _light_phase := -1
var _frames: SpriteFrames
func _ready() -> void:
	y_sort_enabled = true
	_frames = SpriteFrames.new()
	_frames.remove_animation("default")
	for facing in ["up","down","left","right"]:
		_frames.add_animation(facing)
		_frames.set_animation_speed(facing,7)
		for pose in [0,1,0,2]: _frames.add_frame(facing,load("res://assets/art/character/%s_%d.svg" % [facing,pose]))
	var routes := Layout.pedestrian_routes()
	for index in range(12):
		var route: PackedVector2Array = routes[index%routes.size()]
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = _frames
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.scale = Vector2.ONE*.32
		sprite.modulate = [Color("e2d2c4"),Color("b6cbd9"),Color("c6d4b6"),Color("d5bdd0")][index%4]
		sprite.position = route[index%4]
		sprite.play("right")
		add_child(sprite)
		people.append({"body":sprite,"route":route,"target":(index%4+1)%4,"speed":48.0+index%4*8})
	var path := Layout.car_route()
	for index in range(3):
		var car := Road.Car.new()
		car.color = [Color("658d9f"),Color("b09068"),Color("8e6c7d")][index]
		car.position = path[index*2]
		car.body_entered.connect(_hit)
		add_child(car)
		cars.append({"body":car,"target":index*2+1})
func _physics_process(delta: float) -> void:
	if not enabled or not is_visible_in_tree() or not SceneRouter.gameplay_allowed():
		for p in people: p.body.pause()
		return
	if is_instance_valid(traffic) and int(traffic.phase) != _light_phase:
		_light_phase = int(traffic.phase)
		for light in get_tree().get_nodes_in_group("town_signals"):
			light.green = _light_phase == Road.Phase.GREEN
			light.queue_redraw()
	for p in people:
		var body: AnimatedSprite2D = p.body
		var at: Vector2 = p.route[p.target]
		var toward := at-body.position
		body.position = body.position.move_toward(at,p.speed*delta)
		var facing := ("right" if toward.x>0 else "left") if absf(toward.x)>absf(toward.y) else ("down" if toward.y>0 else "up")
		if SettingsService.current.reduce_motion:
			body.stop()
		else: body.play(facing)
		if body.position.distance_to(at)<1: p.target=(p.target+1)%p.route.size()
	_cooldown=maxf(0,_cooldown-delta)
	if is_instance_valid(player) and not Layout.on_road(player.position): _safe=player.position
	var route := Layout.car_route()
	for car in cars:
		var body: Area2D = car.body
		var target: Vector2 = route[car.target]
		var direction := target-body.position
		# Yield to nearby walkers rather than cutting through a crossing.
		var yield_to_player := is_instance_valid(player) and player.position.distance_to(body.position)<180 and Layout.on_road(player.position)
		if not yield_to_player:
			var next := body.position.move_toward(target,70*delta)
			if is_instance_valid(traffic) and traffic.phase != Road.Phase.RED:
				if absf(body.position.y-1360)<4 and body.position.x<=2640: next.x=minf(next.x,2640)
				if absf(body.position.y-2705)<4 and body.position.x>=2880: next.x=maxf(next.x,2880)
			body.position=next
		body.rotation=direction.angle()
		if body.position.distance_to(target)<1: car.target=(car.target+1)%route.size()
func _hit(body: Node2D) -> void:
	if not enabled or body != player or _cooldown>0 or not SceneRouter.gameplay_allowed(): return
	player.position=_safe
	player.velocity=Vector2.ZERO
	player.reset_physics_interpolation()
	_cooldown=1
	if is_instance_valid(traffic): traffic.reset_for_spawn(_safe)
