extends Node3D
## Small playable 3D district. Existing profile and wardrobe remain the source of truth.
signal location_changed(title: String)
signal prompt_changed(text: String)
signal interaction_requested(id: String)
signal escort_finished
const Actor = preload("res://scripts/character/character_player_3d.gd")
const Model = preload("res://scripts/character/character_model.gd")
const Catalog = preload("res://scripts/services/character_catalog.gd")
const SCENES = {
	"square": preload("res://assets/campus3d/square.glb"),
	"reception": preload("res://assets/campus3d/reception.glb"),
	"workshop": preload("res://assets/campus3d/workshop.glb")}
const TITLES = {"square":"Parvis · quartier du lycée", "reception":"Lycée · accueil", "workshop":"Lycée · atelier CIEL"}
const PROMPTS = {"school":"Entrer à l’accueil", "post":"Consulter la boîte aux lettres", "flowers":"Découvrir les plantations", "books":"Ouvrir la boîte à livres", "fountain":"Examiner la fontaine", "exit":"Sortir", "supervisor":"Parler à la surveillante", "stairs":"Rejoindre les ateliers", "computer":"Examiner le poste informatique", "rack":"Vérifier la baie réseau"}
var zone := "square"
var actor: CharacterBody3D
var scenery: Node3D
var camera_pivot: Node3D
var arm: SpringArm3D
var camera: Camera3D
var supervisor: Node3D
var manifest: Dictionary
var nearest := ""
var locked := false
var escorting := false
var escort_time := 0.0
var escort_started_msec := 0
var last_escort_seconds := 0.0
var npc_time := 0.0
var water: ShaderMaterial
var streams: MeshInstance3D
var water_running := true
var _targets: Dictionary = {}

func _ready() -> void:
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campus3d/manifest.json"))
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("b9cbd1")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("dbe4e8")
	environment.environment.ambient_light_energy = .30
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("fff0d8")
	sun.light_energy = .65
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 30
	add_child(sun)
	actor = Actor.new()
	actor.name = "CampusPlayer"
	actor.smooth_turning = true
	actor.animate_rest = true
	add_child(actor)
	actor.model.enable_world_shadows()
	camera_pivot = Node3D.new()
	camera_pivot.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(camera_pivot)
	arm = SpringArm3D.new()
	arm.rotation.x = deg_to_rad(-23)
	arm.spring_length = 5.2
	arm.margin = .15
	arm.collision_mask = 1
	var probe := SphereShape3D.new()
	probe.radius = .17
	arm.shape = probe
	arm.add_excluded_object(actor.get_rid())
	camera_pivot.add_child(arm)
	camera = Camera3D.new()
	camera.near = .08
	camera.far = 90
	camera.fov = 62
	camera.current = true
	arm.add_child(camera)
	load_zone("square")

func _vector(values: Array) -> Vector3:
	return Vector3(values[0], values[1], values[2])

func load_zone(id: String) -> void:
	if id not in SCENES: return
	if scenery != null:
		remove_child(scenery)
		scenery.queue_free()
	zone = id
	supervisor = null
	water = null
	streams = null
	scenery = SCENES[id].instantiate()
	add_child(scenery)
	for mesh in scenery.find_children("*", "MeshInstance3D", true, false):
		if str(mesh.name) in ["wood", "oak", "white", "stone", "paving", "brick"]:
			var surface := ShaderMaterial.new()
			surface.shader = preload("res://scripts/campus3d/architecture.gdshader")
			var original: Material = mesh.mesh.surface_get_material(0)
			if original is StandardMaterial3D: surface.set_shader_parameter("base_color", original.albedo_color)
			surface.set_shader_parameter("wood", str(mesh.name) in ["wood", "oak"])
			mesh.material_override = surface
	var data: Dictionary = manifest.zones[id]
	for proxy in data.collisions:
		var body := StaticBody3D.new()
		body.position = _vector(proxy.position)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = _vector(proxy.size)
		collision.shape = shape
		body.add_child(collision)
		scenery.add_child(body)
	for sign_ in data.labels:
		var label := Label3D.new()
		label.text = sign_.text
		label.position = _vector(sign_.position)
		label.pixel_size = float(sign_.size)
		label.font_size = 40
		label.modulate = Color("243b45")
		label.outline_size = 0
		scenery.add_child(label)
	_targets.clear()
	for key in data.anchors:
		if key != "spawn": _targets[key] = _vector(data.anchors[key])
	if id == "reception":
		supervisor = Model.new()
		var appearance: Dictionary = Catalog.defaults().appearance
		appearance.merge({"hair":"long", "hair_color":"blonde", "skin":"light", "top":"sweater", "top_color":"cream", "trousers_color":"black"}, true)
		supervisor.configure(appearance)
		supervisor.position = _targets.supervisor
		supervisor.scale = Vector3.ONE * .94
		scenery.add_child(supervisor)
		supervisor.enable_world_shadows()
		var body := StaticBody3D.new()
		body.name = "SupervisorCollision"
		body.position = supervisor.position + Vector3(0, .8, 0)
		var collision := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.height = 1.6; capsule.radius = .23
		collision.shape = capsule; body.add_child(collision); scenery.add_child(body)
		var label := Label3D.new()
		label.text = "Surveillante"
		label.font_size = 32; label.pixel_size = .004
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = supervisor.position + Vector3(0, 1.95, 0)
		scenery.add_child(label)
	if id == "square":
		water = ShaderMaterial.new()
		water.shader = preload("res://scripts/campus3d/water.gdshader")
		water.set_shader_parameter("flowing", water_running and not SettingsService.current.reduce_motion)
		for mesh in scenery.find_children("*", "MeshInstance3D", true, false):
			if mesh.name in ["water", "stream"]:
				mesh.material_override = water
			if mesh.name == "stream":
				streams = mesh
				streams.visible = water_running
	teleport(_vector(data.anchors.spawn))
	nearest = ""
	prompt_changed.emit("")
	location_changed.emit(TITLES[id])

func teleport(at: Vector3) -> void:
	actor.position = at
	actor.velocity = Vector3.ZERO
	actor.reset_physics_interpolation()
	camera_pivot.position = at + Vector3(0, 1.0, 0)
	camera_pivot.reset_physics_interpolation()

func set_locked(value: bool) -> void:
	locked = value
	actor.controls_enabled = not locked
	actor.motion_enabled = not escorting

func _physics_process(_delta: float) -> void:
	if actor == null or locked or escorting: return
	var candidate := ""
	var distance := 2.0
	for id in _targets:
		var target: Vector3 = _targets[id]
		var current := Vector2(actor.position.x-target.x, actor.position.z-target.z).length()
		if current >= distance: continue
		var query := PhysicsRayQueryParameters3D.create(actor.position + Vector3(0, 1.4, 0), target + Vector3(0, 1.4, 0), 1)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and not (id == "supervisor" and hit.collider.name == "SupervisorCollision"): continue
		distance = current; candidate = id
	if candidate != nearest:
		nearest = candidate
		prompt_changed.emit(PROMPTS.get(nearest, ""))

func interact() -> void:
	if locked or escorting or nearest.is_empty() or not SceneRouter.gameplay_allowed(): return
	interaction_requested.emit(nearest)

func begin_escort() -> void:
	if zone != "reception" or escorting: return
	if SettingsService.current.reduce_motion:
		load_zone("workshop")
		set_locked(false)
		escort_finished.emit()
		return
	escorting = true
	escort_time = 0.0
	escort_started_msec = Time.get_ticks_msec()
	set_locked(true)
	# Both actors follow the same straight staircase. No physics/tween property conflict.
	teleport(Vector3(3, .02, .9))
	supervisor.position = Vector3(3, .02, .35)
	actor.model.rotation.y = PI
	supervisor.rotation.y = PI
	actor.reset_physics_interpolation()
	supervisor.reset_physics_interpolation()
	prompt_changed.emit("La surveillante vous accompagne aux ateliers…")

func _process(delta: float) -> void:
	if actor == null: return
	if escorting:
		escort_time = (Time.get_ticks_msec() - escort_started_msec) / 1000.0
		var t := minf(escort_time / 2.7, 1.0)
		var z := lerpf(.6, -4.0, t)
		actor.position = Vector3(3, clampf((-z-1.0)*.6, 0, 1.8)+.02, z)
		supervisor.position = Vector3(3, clampf((-z-.45)*.6, 0, 1.8)+.02, z-.55)
		actor.model.pose(true, escort_time)
		supervisor.pose(true, escort_time)
		if t >= 1.0:
			last_escort_seconds = escort_time
			escorting = false
			load_zone("workshop")
			set_locked(false)
			SceneRouter.lock_until_release()
			escort_finished.emit()
	elif supervisor != null and not locked and not SettingsService.current.reduce_motion:
		npc_time += delta
		supervisor.pose(false, 0)
		supervisor.breathe(npc_time)
		var offset := actor.position - supervisor.position
		if offset.length_squared() < 16:
			supervisor.rotation.y = lerp_angle(supervisor.rotation.y, atan2(offset.x, offset.z), 1-exp(-3*delta))
	var target: Vector3 = actor.position if escorting else actor.get_global_transform_interpolated().origin
	camera_pivot.position = camera_pivot.position.lerp(target+Vector3(0,1,0), 1-exp(-10*delta))

func toggle_water() -> void:
	water_running = not water_running
	if water != null: water.set_shader_parameter("flowing", water_running and not SettingsService.current.reduce_motion)
	if streams != null: streams.visible = water_running
