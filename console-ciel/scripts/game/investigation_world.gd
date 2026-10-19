extends Node2D
## A compact, entirely original 2D room. All dimensions are in world pixels.
## Collision and interaction data are built alongside the matching decoration.

signal interaction_requested(id: String)
signal target_changed(id: String, label: String)

const Art=preload('res://scripts/game/room_art.gd')
const PlayerScript = preload("res://scripts/game/player.gd")
const InteractableScript = preload("res://scripts/game/interactable.gd")
const MazeLayout = preload("res://scripts/game/maze_layout.gd")
const MazeVisual = preload("res://scripts/game/maze_visual.gd")
const CampusLayout = preload("res://scripts/game/campus_layout.gd")
const CampusVisual = preload("res://scripts/game/campus_visual.gd")
const HotelLayout = preload("res://scripts/game/hotel_layout.gd")
const HotelVisual = preload("res://scripts/game/hotel_visual.gd")
const RoadTraffic = preload("res://scripts/game/road_traffic.gd")
const NpcCatalog = preload("res://scripts/game/npc_catalog.gd")
const NpcVisual = preload("res://scripts/game/npc_visual.gd")
const NpcMarker = preload("res://scripts/game/npc_speech_marker.gd")
signal traffic_notice(message: String)
const WORLD_SIZE := Vector2(1000, 520)
const MINIMUM_CAMERA_ZOOM := 0.70
const CHECKPOINTS := {
	"entrance": Vector2(150, 432),
	"lighting": Vector2(120, 230),
	"lock": Vector2(554, 340),
	"computer": Vector2(824, 270),
	"elevator": Vector2(835, 407),
	"exit": Vector2(790, 355)
}
const CHAPTER_TWO_CHECKPOINTS := {
	"entrance": Vector2(158, 405),
	"elevator": Vector2(158, 405),
	"network": Vector2(292, 224),
	"addressing": Vector2(532, 336),
	"security": Vector2(803, 248),
	"exit": Vector2(532, 381)
}
const CHAPTER_THREE_CHECKPOINTS := {
	"entrance": Vector2(158, 405),
	"elevator": Vector2(158, 405),
	"python": Vector2(220, 294),
	"html": Vector2(500, 294),
	"markdown": Vector2(780, 294),
	"exit": Vector2(500, 350), "books": Vector2(532, 375)
}
const CHAPTER_FOUR_CHECKPOINTS := {
	"entrance": Vector2(158, 405), "elevator": Vector2(158, 405),
	"firewall": Vector2(220, 294), "ip_conflict": Vector2(500, 294),
	"subnet_mask": Vector2(780, 294), "exit": Vector2(500, 350)
}
const DOOR_RECT := Rect2(619, 276, 20, 112)

var player: CharacterBody2D
var door_body: StaticBody2D
var door_shape: CollisionShape2D
var _open_door_body: StaticBody2D
var _open_door_shape: CollisionShape2D
var camera: Camera2D
var target_id := ""
var lighting_restored := false
var door_open := false
var computer_repaired := false
var chapter_id := 1
var room_id := "room_01"
var campus_zone := ""
var campus_visual: Node2D
var hotel_visual: Node2D
var _hotel_props: Array[Node2D] = []
var traffic: Node2D
var _bed_pose := "standing"
var maze_active := false
var maze_visual: Node2D
var elevator_unlocked := false
var network_restored := false
var addressing_restored := false
var security_restored := false
var python_restored := false
var html_restored := false
var markdown_restored := false
var _targets: Array[Node2D] = []
var _characters: Dictionary = {}
var _target: Node2D
var _controls_enabled := true
var _restored_once := false
var _pending_progress: Dictionary = {}
var _obstacle_rects: Array[Rect2] = []
var _accent := Color("527fa3")
var _floor_lit := Color("e8eef1")
var _large_text := false
var _props: Node2D
var _cabinet_sprite: Sprite2D
var _monitor_sprite: Sprite2D
var _reader_sprite: Sprite2D
var _light_sprite: Sprite2D
var _closed_door: Sprite2D
var _open_door: Sprite2D
var _note: Sprite2D
var _was_repaired := false
var _repair_tween: Tween
var _room_root: Node2D
var _elevator_sprite: Sprite2D
var _network_sprite: Sprite2D
var _addressing_sprite: Sprite2D
var _security_sprite: Sprite2D
var _python_sprite: Sprite2D
var _html_sprite: Sprite2D
var _markdown_sprite: Sprite2D
var _lab_screens: Dictionary = {}

func _ready() -> void:
	camera = Camera2D.new()
	camera.name = "RoomCamera"
	camera.position = WORLD_SIZE * 0.5
	camera.position_smoothing_enabled = false
	camera.enabled = true
	add_child(camera)
	_build_room(_chapter_for_room(str(_pending_progress.get("room_id", "room_01"))))
	get_viewport().size_changed.connect(_fit_camera)
	var settings := get_node_or_null("/root/SettingsService")
	if settings != null:
		settings.settings_changed.connect(_appearance_changed)
	var app := get_node_or_null("/root/AppState")
	if app != null:
		app.equipment_changed.connect(_appearance_changed)
	_sync_appearance()
	_fit_camera()
	if not _pending_progress.is_empty():
		restore_progress(_pending_progress)
	queue_redraw()

func _build_room(chapter: int) -> void:
	if is_instance_valid(_room_root):
		remove_child(_room_root)
		_room_root.queue_free()
	_targets.clear()
	_characters.clear()
	_lab_screens.clear()
	_target = null
	target_id = ""
	_obstacle_rects.clear()
	_closed_door = null
	_open_door = null
	_cabinet_sprite = null
	_monitor_sprite = null
	_reader_sprite = null
	_light_sprite = null
	_note = null
	_network_sprite = null
	_addressing_sprite = null
	_security_sprite = null
	_python_sprite = null
	_html_sprite = null
	_markdown_sprite = null
	_elevator_sprite = null
	hotel_visual = null
	traffic = null
	_hotel_props.clear()
	_bed_pose = "standing"
	door_body = null
	door_shape = null
	_open_door_body = null
	_open_door_shape = null
	chapter_id = chapter
	maze_active = chapter == 5 and str(_pending_progress.get("room_id", "")) == "maze_05"
	campus_zone = str(_pending_progress.get("room_id", "")) if chapter == 0 else ""
	room_id = campus_zone if chapter == 0 else ("maze_05" if maze_active else "room_0%d" % chapter)
	_room_root = Node2D.new()
	_room_root.name = "CampusZone" if chapter == 0 else ["ChapterOneRoom", "ChapterTwoRoom", "ChapterThreeRoom", "ChapterFourRoom", "ChapterFiveRoom"][chapter - 1]
	add_child(_room_root)
	_props=Node2D.new()
	_props.name='RoomObjects'
	_props.y_sort_enabled=true
	_room_root.add_child(_props)
	if chapter == 0:
		if HotelLayout.is_zone(campus_zone): _build_hotel()
		else: _build_campus()
	elif maze_active:
		_build_maze()
	else:
		# Perimeter and office partition. The doorway is a real, separate body.
		_add_obstacle(Rect2(24, 30, 952, 20), "NorthWall")
		_add_obstacle(Rect2(24, 476, 952, 20), "SouthWall")
		_add_obstacle(Rect2(24, 50, 20, 426), "WestWall")
		_add_obstacle(Rect2(956, 50, 20, 426), "EastWall")
		if chapter == 1:
			_build_workshop()
		elif chapter == 2:
			_build_network_room()
		elif chapter == 3:
			_build_code_room()
		elif chapter == 4:
			_build_lab_room()
		else:
			_build_fifth_hub()
	_build_characters()
	player = PlayerScript.new()
	player.name = "Player"
	player.position = _chapter_checkpoints().entrance
	_props.add_child(player)
	player.reserve_map_arrow = HotelLayout.is_zone(campus_zone)
	if is_instance_valid(traffic):
		traffic.player = player
		traffic.reset_for_spawn(player.position)
	player.controls_enabled = _controls_enabled
	_restored_once = false
	_was_repaired = false
	target_changed.emit("", "")

func _build_characters() -> void:
	for spec in NpcCatalog.for_zone(room_id):
		# A small foot collider leaves room to pass. Art shares the body's depth.
		var footprint := Rect2(spec.at - Vector2(12, 16), Vector2(24, 16))
		var body := _add_obstacle(footprint, str(spec.id), false)
		var visual := NpcVisual.new()
		visual.name = "CharacterArt"
		visual.configure(spec)
		visual.scale = Vector2(.78, .78)
		body.add_child(visual)
		_characters[str(spec.id)] = visual
		_add_target(str(spec.id), "Parler à %s · %s" % [spec.name, spec.role], spec.approach, 68)
		var target := get_interactable(str(spec.id))
		target.dialogue_marker = true
		target.speaker_name = str(spec.name)
		target.marker_offset = spec.at - spec.approach + Vector2(14, -62)

func _build_workshop() -> void:
	_add_obstacle(Rect2(619, 50, 20, 226), "OfficeWallNorth")
	_add_obstacle(Rect2(619, 388, 20, 88), "OfficeWallSouth")
	door_body = _add_obstacle(DOOR_RECT, "OfficeDoor", false)
	door_shape = door_body.get_child(0)
	_closed_door=_sprite(door_body,'door_closed',Rect2(616,276,28,120))
	_open_door_body = _add_obstacle(Rect2(639, 272, 120, 28), "OfficeDoorOpenLeaf", false)
	_open_door_shape = _open_door_body.get_child(0)
	_open_door=_sprite(_open_door_body,'door_open',Rect2(639,272,120,28))
	for prop in Art.PROPS:
		var body=_add_obstacle(prop[1],prop[0],false)
		var visual=_sprite(body,prop[2],prop[3])
		if prop[0]=='ElectricalCabinet': _cabinet_sprite=visual
		if prop[0]=='ComputerDesk':
			_monitor_sprite=_sprite(body,'monitor_off',Rect2(781,127,85,61))
			_sprite(body,'tower',Rect2(879,145,36,68))
	var control_body := _add_obstacle(Rect2(574, 308, 18, 20), "DoorControl", false)
	_reader_sprite=_sprite(control_body,'reader_off',Rect2(568,289,30,49))
	_light_sprite=_sprite(_room_root,'light',Rect2(274,61,172,28))
	_note=_sprite(_room_root,'note',Rect2(447,194,70,48))
	_add_target("building_exit", "Porte de sortie · cour", Vector2(150, 444), 65)
	_add_target("lighting", "Tableau électrique fictif", Vector2(120, 192), 104)
	_add_target("lock", "Commande de la porte", Vector2(582, 340), 104)
	_add_target("computer", "Ordinateur du bureau", Vector2(825, 247), 104)
	var elevator_body := _add_obstacle(Rect2(843, 435, 104, 35), "Elevator", false)
	_elevator_sprite = _sprite(elevator_body, 'elevator_locked', Rect2(835, 389, 112, 87))
	_elevator_sprite.name = "ElevatorArt"
	_add_target("elevator", "Ascenseur · accès à l’étage", Vector2(875, 400), 92)

func _build_network_room() -> void:
	# The rack, the addressing station and Wi-Fi area share an open walkway.
	# The short privacy divider leaves a wide passage towards the wireless area.
	_add_obstacle(Rect2(691, 50, 9, 178), "WirelessDivider")
	for prop in Art.NETWORK_PROPS:
		var body := _add_obstacle(prop[1], prop[0], false)
		var visual := _sprite(body, prop[2], prop[3])
		if prop[0] == "NetworkRack": _network_sprite = visual
		if prop[0] == "AddressingDesk":
			_addressing_sprite = _sprite(body, 'network_terminal', Rect2(485, 215, 85, 61))
			_sprite(body, 'tower', Rect2(574, 228, 36, 68))
		if prop[0] == "WirelessStation": _security_sprite = visual
	var elevator_body := _add_obstacle(Rect2(88, 435, 112, 35), "Elevator", false)
	_elevator_sprite = _sprite(elevator_body, 'elevator_ready', Rect2(84, 389, 120, 87))
	_elevator_sprite.name = "ElevatorArt"
	_add_target("elevator", "Ascenseur · choix des étages", Vector2(158, 400), 92)
	_add_target("network", "Baie réseau · liaison Ethernet", Vector2(292, 221), 100)
	_add_target("addressing", "Poste réseau · adresse IP", Vector2(532, 332), 100)
	_add_target("security", "Borne Wi-Fi · sécurisation", Vector2(803, 244), 100)

func _build_code_room() -> void:
	# Three separate stations share a clear central aisle. The low resources
	# corner leaves a continuous route from the elevator to every terminal.
	for prop in Art.CODE_PROPS:
		var body := _add_obstacle(prop[1], prop[0], false)
		_sprite(body, prop[2], prop[3])
		match prop[0]:
			"PythonDesk": _python_sprite = _sprite(body, "code_python", Rect2(156, 104, 126, 89))
			"HtmlDesk": _html_sprite = _sprite(body, "code_html", Rect2(436, 104, 126, 89))
			"MarkdownDesk": _markdown_sprite = _sprite(body, "code_markdown", Rect2(716, 104, 126, 89))
	var elevator_body := _add_obstacle(Rect2(88, 435, 112, 35), "Elevator", false)
	_elevator_sprite = _sprite(elevator_body, "elevator_ready", Rect2(84, 389, 120, 87))
	_elevator_sprite.name = "ElevatorArt"
	_add_target("elevator", "Ascenseur · choix des étages", Vector2(158, 400), 92)
	_add_target("python", "Poste Python · afficher un message", Vector2(220, 260), 100)
	_add_target("html", "Poste HTML · une première balise", Vector2(500, 260), 100)
	_add_target("markdown", "Poste Markdown · créer un titre", Vector2(780, 260), 100)
	_add_target("books", "Coin ressources · lire les trois livres", Vector2(532, 394), 82)

class LabGlyph extends Node2D:
	var kind := 0
	func _draw() -> void:
		var ink := Color("5c837d")
		draw_rect(Rect2(-44, -21, 88, 40), Color("d1dfd8"))
		if kind == 0:
			var shield := PackedVector2Array([Vector2(-13,-14),Vector2(13,-14),Vector2(13,3),Vector2(0,15),Vector2(-13,3)])
			draw_colored_polygon(shield, ink)
			draw_line(Vector2(-6,0),Vector2(-1,6),Color("edf1df"),3,true)
			draw_line(Vector2(-1,6),Vector2(7,-5),Color("edf1df"),3,true)
		else:
			draw_string(ThemeDB.fallback_font,Vector2(-30,4),"IPv4" if kind == 1 else "/26",HORIZONTAL_ALIGNMENT_LEFT,-1,19,ink)

func _build_lab_room() -> void:
	var ids := ["firewall", "ip_conflict", "subnet_mask"]
	for index in range(3):
		var x := 220.0 + index * 280.0
		var desk := _add_obstacle(Rect2(x - 86, 141, 172, 80), "LabDesk%d" % index, false)
		_sprite(desk, "desk", Rect2(x - 100, 117, 200, 122))
		_lab_screens[ids[index]] = _sprite(desk, "network_terminal", Rect2(x - 64, 104, 126, 89))
		var glyph := LabGlyph.new()
		glyph.kind = index
		glyph.position = Vector2(x, 138) - desk.position
		desk.add_child(glyph)
		_add_target(ids[index], ["Pare-feu · autoriser HTTPS", "Adresses IP · résoudre un conflit", "Masque réseau · découvrir /26"][index], Vector2(x, 260), 100)
	var storage := _add_obstacle(Rect2(760,403,114,45), "LabStorage", false)
	_sprite(storage, "cabinet", Rect2(751,384,132,79))
	var rack := _add_obstacle(Rect2(500,411,64,52), "LabResources", false)
	_sprite(rack, "network_rack", Rect2(490,380,84,94))
	var elevator_body := _add_obstacle(Rect2(88,435,112,35), "Elevator", false)
	_elevator_sprite = _sprite(elevator_body, "elevator_ready", Rect2(84,389,120,87))
	_add_target("elevator", "Ascenseur · choix des étages", Vector2(158,400),92)

func _chapter_for_room(id: String) -> int:
	if HotelLayout.is_zone(id): return 0
	match id:
		"courtyard", "building_02": return 0
		"room_02": return 2
		"room_03": return 3
		"room_04": return 4
		"room_05", "maze_05": return 5
		_: return 1

func _chapter_checkpoints() -> Dictionary:
	match chapter_id:
		0: return HotelLayout.checkpoints(campus_zone) if HotelLayout.is_zone(campus_zone) else CampusLayout.checkpoints(campus_zone)
		2: return CHAPTER_TWO_CHECKPOINTS
		3: return CHAPTER_THREE_CHECKPOINTS
		4: return CHAPTER_FOUR_CHECKPOINTS
		5: return MazeLayout.checkpoints() if maze_active else {"entrance": Vector2(158,405), "elevator": Vector2(158,405), "laptop": Vector2(500,295)}
		_: return CHECKPOINTS.merged({"building_exit": Vector2(150, 419)})

func _add_obstacle(rect: Rect2, node_name: String, wall := true) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = rect.get_center() if wall else Vector2(rect.get_center().x,rect.end.y)
	body.collision_layer = 1
	body.collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	if not wall: collision.position.y=-rect.size.y/2
	body.add_child(collision)
	if wall: _room_root.add_child(body)
	else: _props.add_child(body)
	if wall:
		_obstacle_rects.append(rect)
	return body

func _sprite(host: Node2D,asset: String,rect: Rect2) -> Sprite2D:
	var visual=Sprite2D.new()
	visual.name=asset.capitalize().replace('_','')+'Art'
	visual.texture=Art.TEXTURES[asset]
	visual.centered=false
	visual.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	visual.position=rect.position-host.position if host!=self else rect.position
	visual.scale=rect.size/visual.texture.get_size()
	host.add_child(visual)
	return visual

func _refresh_art() -> void:
	if is_instance_valid(hotel_visual):
		hotel_visual.state = _pending_progress.get("hotel", {}).duplicate(true)
		for visual in _hotel_props:
			visual.state = hotel_visual.state
			visual.queue_redraw()
		set_bed_pose(str(hotel_visual.state.get("bed_state", "standing")))
		hotel_visual.queue_redraw()
		return
	if is_instance_valid(_elevator_sprite):
		_elevator_sprite.texture = Art.TEXTURES.elevator_ready if elevator_unlocked else Art.TEXTURES.elevator_locked
	if chapter_id == 5:
		if is_instance_valid(maze_visual): maze_visual.completed = _pending_progress.get("completed_missions", []).has("maze")
		return
	if chapter_id == 4:
		_props.modulate = Color.WHITE
		for id in _lab_screens:
			_lab_screens[id].modulate = Color("b9d9bc") if _pending_progress.get("completed_missions", []).has(id) else Color.WHITE
		return
	if chapter_id == 3:
		_props.modulate = Color.WHITE
		if is_instance_valid(_python_sprite): _python_sprite.modulate = Color("b9d9bc") if python_restored else Color.WHITE
		if is_instance_valid(_html_sprite): _html_sprite.modulate = Color("b9d9bc") if html_restored else Color.WHITE
		if is_instance_valid(_markdown_sprite): _markdown_sprite.modulate = Color("b9d9bc") if markdown_restored else Color.WHITE
		return
	if chapter_id == 2:
		_props.modulate = Color.WHITE
		if is_instance_valid(_network_sprite): _network_sprite.modulate = Color("b9d9bc") if network_restored else Color.WHITE
		if is_instance_valid(_addressing_sprite): _addressing_sprite.modulate = Color("b9d9bc") if addressing_restored else Color.WHITE
		if is_instance_valid(_security_sprite): _security_sprite.modulate = Color("b9d9bc") if security_restored else Color.WHITE
		return
	if not is_instance_valid(_closed_door): return
	_closed_door.visible=not door_open
	_open_door.visible=door_open
	_cabinet_sprite.texture=Art.TEXTURES.electrical_on if lighting_restored else Art.TEXTURES.electrical_off
	_monitor_sprite.texture=Art.TEXTURES.monitor_on if computer_repaired else Art.TEXTURES.monitor_off
	_reader_sprite.texture=Art.TEXTURES.reader_on if door_open else Art.TEXTURES.reader_off
	_note.visible=lighting_restored
	_light_sprite.modulate=Color.WHITE if lighting_restored else Color(.67,.77,.83)
	_props.modulate=Color.WHITE if lighting_restored else Color(.88,.91,.94)
	# A brief, soft emphasis, triggered only by an actual state transition.
	if computer_repaired and not _was_repaired and not SettingsService.current.get('reduce_motion',false):
		if _repair_tween!=null and _repair_tween.is_valid(): _repair_tween.kill()
		_monitor_sprite.modulate=Color('#C6E0C5')
		_repair_tween=create_tween()
		_repair_tween.tween_property(_monitor_sprite,'modulate',Color.WHITE,.20)
	_was_repaired=computer_repaired

func _add_target(id: String, label_text: String, at: Vector2, radius: float) -> void:
	var target := NpcMarker.new() if id.begins_with("npc_") else InteractableScript.new()
	target.name = id.capitalize() + "Interaction"
	target.interaction_id = id
	target.label = label_text
	target.interaction_radius = radius
	target.position = at
	target.z_index = 7
	_room_root.add_child(target)
	_targets.append(target)

func _fit_camera() -> void:
	if camera == null or not is_inside_tree():
		return
	var available := get_viewport_rect().size
	# On compact screens, retain an 18 px character instead of shrinking the
	# complete room into a short strip. The cropped axes follow the player.
	var fit := .92 if maze_active or chapter_id == 0 else maxf(MINIMUM_CAMERA_ZOOM, minf(available.x / WORLD_SIZE.x, available.y / WORLD_SIZE.y))
	camera.zoom = Vector2(fit, fit)
	_update_camera_position()

func _update_camera_position() -> void:
	if not is_inside_tree() or not is_instance_valid(camera) or not is_instance_valid(player):
		return
	var half_visible: Vector2 = get_viewport_rect().size / camera.zoom * 0.5
	var extent := world_extent()
	var center := extent * .5
	if half_visible.x < extent.x * .5:
		center.x = clampf(player.position.x, half_visible.x, extent.x - half_visible.x)
	if half_visible.y < extent.y * .5:
		center.y = clampf(player.position.y, half_visible.y, extent.y - half_visible.y)
	# No permanent background animation or camera smoothing is needed.
	camera.position = center

func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled
	if is_instance_valid(traffic): traffic.enabled = enabled
	if is_instance_valid(player):
		player.controls_enabled = enabled and not _hotel_seated()
		if not enabled:
			player.velocity = Vector2.ZERO

func get_player_position() -> Vector2:
	return player.position if is_instance_valid(player) else _chapter_checkpoints().entrance

func get_interactable(id: String) -> Node2D:
	for target in _targets:
		if target.interaction_id == id:
			return target
	return null

func restore_checkpoint() -> void:
	if not is_instance_valid(player):
		return
	var checkpoint := str(_pending_progress.get("checkpoint_id", "entrance"))
	if chapter_id == 1 and checkpoint in ["computer", "exit", "elevator"] and not door_open:
		checkpoint = "entrance"
	var checkpoints := _chapter_checkpoints()
	player.position = checkpoints.get(checkpoint, checkpoints.entrance)
	if room_id == "hotel_room_206" and str(_pending_progress.get("hotel", {}).get("bed_state", "standing")) == "sitting":
		player.position = HotelLayout.BED_SEAT
	player.velocity = Vector2.ZERO
	if is_instance_valid(traffic): traffic.reset_for_spawn(player.position)
	_update_camera_position()
	_update_target()

func restore_progress(progress: Dictionary) -> void:
	_pending_progress = progress.duplicate(true)
	if not is_instance_valid(player):
		return
	var desired_chapter := _chapter_for_room(str(progress.get("room_id", "room_01")))
	if room_id != str(progress.get("room_id", "room_01")):
		_build_room(desired_chapter)
	var completed: Array = progress.get("completed_missions", [])
	lighting_restored = completed.has("lighting")
	door_open = completed.has("lock")
	computer_repaired = completed.has("computer")
	elevator_unlocked = lighting_restored and door_open and computer_repaired
	network_restored = completed.has("network")
	addressing_restored = completed.has("addressing")
	security_restored = completed.has("security")
	python_restored = completed.has("python")
	html_restored = completed.has("html")
	markdown_restored = completed.has("markdown")
	if is_instance_valid(door_body):
		door_body.collision_layer = 0 if door_open else 1
		door_shape.set_deferred("disabled", door_open)
		_open_door_body.collision_layer = 1 if door_open else 0
		_open_door_shape.set_deferred("disabled", not door_open)
	_refresh_art()
	_refresh_target_availability()
	if not _restored_once:
		restore_checkpoint()
		_restored_once = true
	if is_instance_valid(hotel_visual):
		set_bed_pose(str(_pending_progress.get("hotel", {}).get("bed_state", "standing")))
	_sync_appearance()
	_fit_camera()
	queue_redraw()
	_update_target()

func _is_target_available(target: Node2D) -> bool:
	# Mission equipment remains part of the room after repair, but its marker
	# and interaction stop. The elevator is travel, never a completed mission.
	if target.interaction_id == "maze_terminal": return not _pending_progress.get("completed_missions", []).has("maze")
	if target.interaction_id == "hotel_luggage": return not bool(_pending_progress.get("hotel", {}).get("luggage_placed", false))
	if target.interaction_id == "hotel_repair": return not bool(_pending_progress.get("hotel", {}).get("repaired", false))
	var morning_stage := int(_pending_progress.get("hotel", {}).get("morning_stage", 0))
	match target.interaction_id:
		"hotel_breakfast_table": return morning_stage == 2
		"hotel_coffee_machine": return morning_stage in [3, 4]
		"hotel_backpack": return morning_stage == 5
		"campus_bus": return morning_stage >= 6

	return target.interaction_id in ["elevator", "books"] or not _pending_progress.get("completed_missions", []).has(target.interaction_id)

func _refresh_target_availability() -> void:
	for target in _targets:
		var available := _is_target_available(target)
		target.visible = available
		if not available:
			target.highlighted = false
	# A challenge can finish while movement is suspended by its dialog. Clear
	# the latched target immediately, without waiting for a physics frame.
	if is_instance_valid(_target) and not _is_target_available(_target):
		_target = null
		target_id = ""
		target_changed.emit("", "")

func _appearance_changed(_value: Dictionary) -> void:
	_sync_appearance()

func _sync_appearance() -> void:
	# Main temporarily detaches the retained game while showing settings. The
	# autoload signals still reach it, but absolute node paths require a tree.
	# restore_progress() refreshes appearance when the game is attached again.
	if not is_inside_tree():
		return
	var settings := get_node_or_null("/root/SettingsService")
	if settings != null:
		_large_text = bool(settings.current.get("large_text", false))
	var app := get_node_or_null("/root/AppState")
	var shop := get_node_or_null("/root/ShopService")
	if app != null and shop != null:
		var equipment: Dictionary = app.profile.get("equipped", {})
		var theme_item: Dictionary = shop.item(str(equipment.get("theme", "theme_brume")))
		_accent = Color(theme_item.get("accent", "#527fa3"))
		_floor_lit = Color(theme_item.get("secondary", "#e8eef1"))
		if is_instance_valid(player):
			var avatar: Dictionary = shop.item(str(equipment.get("avatar", "avatar_default")))
			player.accent = Color(avatar.get("color", "#527fa3"))
			player.queue_redraw()
	for target in _targets:
		target.accent = _accent
		target.queue_redraw()
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if is_visible_in_tree() and is_instance_valid(player):
		_update_camera_position()
		if _controls_enabled:
			_update_target()
		if _characters.has(target_id):
			var visual: Node2D = _characters[target_id]
			visual.look_toward(player.global_position - visual.global_position)

func _interaction_position(target: Node2D) -> Vector2:
	if _characters.has(target.interaction_id):
		return _characters[target.interaction_id].global_position - Vector2(0, 8)
	return target.global_position

func _can_reach(target: Node2D, margin := 0.0) -> bool:
	if not _is_target_available(target):
		return false
	var at := _interaction_position(target)
	if player.global_position.distance_to(at) > target.interaction_radius + margin:
		return false
	# In particular, an unopened door prevents interacting with the computer
	# through the partition. Other furniture also blocks the line of sight.
	var excluded: Array[RID] = [player.get_rid()]
	if _characters.has(target.interaction_id):
		excluded.append(_characters[target.interaction_id].get_parent().get_rid())
	var query := PhysicsRayQueryParameters2D.create(player.global_position, at, 1, excluded)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _target_score(target: Node2D) -> float:
	var toward := _interaction_position(target) - player.global_position
	var direction_cost: float = (1.0 - player.facing.dot(toward.normalized())) * 12.0
	return toward.length() + direction_cost

func _update_target() -> void:
	if not is_inside_tree() or not is_instance_valid(player):
		return
	var chosen: Node2D = null
	var best_score := INF
	for candidate in _targets:
		if not _can_reach(candidate):
			continue
		var score := _target_score(candidate)
		if score < best_score:
			chosen = candidate
			best_score = score
	# Keep the current object while it remains close, unless a clearly better
	# object is approached. This hysteresis prevents rapid focus oscillation.
	if is_instance_valid(_target) and _can_reach(_target, 12.0):
		if chosen == null or _target_score(_target) <= best_score + 18.0:
			chosen = _target
	if chosen == _target:
		return
	if is_instance_valid(_target):
		_target.highlighted = false
	_target = chosen
	target_id = "" if chosen == null else chosen.interaction_id
	if chosen != null:
		chosen.highlighted = true
	for id in _characters:
		_characters[id].set_attention(id == target_id)
	target_changed.emit(target_id, "" if chosen == null else chosen.label)

func interact_nearest() -> void:
	if not is_inside_tree():
		return
	var router := get_node_or_null("/root/SceneRouter")
	if not _controls_enabled or not is_visible_in_tree() or (router != null and not router.gameplay_allowed()):
		return
	_update_target()
	if is_instance_valid(_target) and _can_reach(_target, 12.0):
		interaction_requested.emit(_target.interaction_id)

func _draw() -> void:
	if chapter_id == 0: return
	if chapter_id == 5:
		if maze_active: return
		draw_texture(Art.TEXTURES.code_floor, Vector2.ZERO, Color("e8e1d3"))
		draw_texture(Art.TEXTURES.code_walls, Vector2.ZERO)
		draw_string(ThemeDB.fallback_font, Vector2(66,73), "CHAPITRE 5 · LE PALIER", HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("5a736b"))
		draw_string(ThemeDB.fallback_font, Vector2(426,326), "UN PORTABLE VOUS ATTEND", HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("71817c"))
		return
	if chapter_id == 4:
		draw_texture(Art.TEXTURES.code_floor, Vector2.ZERO, Color("c7dce4"))
		draw_texture(Art.TEXTURES.code_walls, Vector2.ZERO)
		draw_string(ThemeDB.fallback_font,Vector2(66,73),"CHAPITRE 4 · LABORATOIRE RÉSEAU",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("5a736b"))
		var ids := ["firewall", "ip_conflict", "subnet_mask"]
		for index in range(3):
			_draw_code_label(["PARE-FEU", "ADRESSES IP", "MASQUE /26"][index], _pending_progress.get("completed_missions", []).has(ids[index]), Vector2(220 + index * 280,249), Color("5b7d90"))
		return
	if chapter_id == 3:
		draw_texture(Art.TEXTURES.code_floor, Vector2.ZERO)
		draw_texture(Art.TEXTURES.code_walls, Vector2.ZERO)
		draw_string(ThemeDB.fallback_font, Vector2(66, 73), "CHAPITRE 3 · ATELIER CODE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#5A736B"))
		_draw_code_label("PYTHON", python_restored, Vector2(220, 249), Color("#60889e"))
		_draw_code_label("HTML", html_restored, Vector2(500, 249), Color("#a4875f"))
		_draw_code_label("MARKDOWN", markdown_restored, Vector2(780, 249), Color("#8f7ca2"))
		draw_string(ThemeDB.fallback_font, Vector2(448, 381), "COIN RESSOURCES", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#5A736B"))
		return
	if chapter_id == 2:
		draw_texture(Art.TEXTURES.network_floor, Vector2.ZERO)
		draw_texture(Art.TEXTURES.network_walls, Vector2.ZERO)
		draw_string(ThemeDB.fallback_font, Vector2(66,73), 'ÉTAGE 1 · RÉSEAU CIEL', HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color('#5A736B'))
		draw_string(ThemeDB.fallback_font, Vector2(737,73), 'ESPACE WI-FI', HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color('#5A736B'))
		return
	var ambient=Color.WHITE if lighting_restored else Color(.83,.88,.90)
	draw_texture(Art.TEXTURES.floor,Vector2.ZERO,ambient)
	draw_texture(Art.TEXTURES.walls,Vector2.ZERO,ambient)
	# Small diegetic signage is decorative; interaction text belongs to the HUD.
	draw_string(ThemeDB.fallback_font,Vector2(66,73),'ATELIER · CIEL',HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color('#5A736B'))
	draw_string(ThemeDB.fallback_font,Vector2(676,73),'BUREAU',HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color('#5A736B'))
	# The visible threshold aligns with the exit interaction; the perimeter
	# remains solid until the player explicitly uses the door.
	draw_rect(Rect2(96,460,108,26),Color("6c8b83"))
	draw_rect(Rect2(103,465,94,16),Color("c8dfd4"))
	draw_line(Vector2(150,465),Vector2(150,481),Color("6c8b83"),3)
	draw_string(ThemeDB.fallback_font,Vector2(117,456),"SORTIE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("52756e"))

func _draw_code_label(language: String, completed: bool, at: Vector2, color: Color) -> void:
	var label := language + (" · VALIDÉ" if completed else "")
	var font := ThemeDB.fallback_font
	var font_size := 13 if _large_text else 12
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, at - Vector2(width * 0.5, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#4f765f") if completed else color)

class LaptopArt extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(-43,-28,86,52),Color("526c70"))
		draw_rect(Rect2(-37,-22,74,39),Color("b8d2ca"))
		draw_string(ThemeDB.fallback_font,Vector2(-13,3),">_",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("527775"))
		draw_colored_polygon(PackedVector2Array([Vector2(-43,24),Vector2(43,24),Vector2(53,40),Vector2(-53,40)]),Color("8ba3a3"))
		draw_rect(Rect2(-11,29,22,6),Color("cfddd5"))

func _build_fifth_hub() -> void:
	var desk := _add_obstacle(Rect2(430,202,140,63), "PortableDesk", false)
	_sprite(desk, "desk", Rect2(414,177,172,112))
	var laptop := LaptopArt.new()
	laptop.position = Vector2(500,199) - desk.position
	desk.add_child(laptop)
	_add_target("laptop", "Ordinateur portable", Vector2(500,278),98)
	var elevator_body := _add_obstacle(Rect2(88,435,112,35),"Elevator",false)
	_elevator_sprite = _sprite(elevator_body,"elevator_ready",Rect2(84,389,120,87))
	_add_target("elevator","Ascenseur · choix des étages",Vector2(158,400),92)
	var storage := _add_obstacle(Rect2(760,403,114,45),"HallStorage",false)
	_sprite(storage,"cabinet",Rect2(751,384,132,79))

func _build_maze() -> void:
	maze_visual = MazeVisual.new()
	_room_root.add_child(maze_visual)
	_room_root.move_child(maze_visual,0)
	# Une collision par segment horizontal, alignée sur les murs visibles.
	for y in range(MazeLayout.GRID.size()):
		var x := 0
		while x < MazeLayout.GRID[y].length():
			if MazeLayout.GRID[y][x] != "#":
				x += 1
				continue
			var first := x
			while x < MazeLayout.GRID[y].length() and MazeLayout.GRID[y][x] == "#": x += 1
			_add_obstacle(Rect2(first * MazeLayout.TILE,y * MazeLayout.TILE,(x-first) * MazeLayout.TILE,MazeLayout.TILE),"MazeWall_%d_%d" % [y,first])
	var center: Vector2 = MazeLayout.at(MazeLayout.CENTER)
	var body := _add_obstacle(Rect2(center + Vector2(-34,-43),Vector2(68,18)),"CentralTerminal",false)
	_sprite(body,"network_terminal",Rect2(center + Vector2(-38,-66),Vector2(76,54)))
	_add_target("maze_terminal","Terminal du serveur",center + Vector2(0,15),72)
	_add_target("maze_return","Retour au palier",MazeLayout.at(MazeLayout.START),64)
	for index in range(MazeLayout.NOTES.size()):
		_add_target("maze_note_%d" % index,"Lire l’inscription murale",MazeLayout.at(MazeLayout.NOTES[index].cell),65)

func world_extent() -> Vector2:
	if chapter_id == 0:
		return HotelLayout.extent(campus_zone) if HotelLayout.is_zone(campus_zone) else CampusLayout.extent(campus_zone)
	return MazeLayout.extent() if maze_active else WORLD_SIZE

func _build_hotel() -> void:
	hotel_visual = HotelVisual.new()
	hotel_visual.name = "HotelScenery"
	hotel_visual.zone = campus_zone
	_room_root.add_child(hotel_visual)
	_room_root.move_child(hotel_visual, 0)
	var index := 0
	for rect in HotelLayout.walls(campus_zone):
		_add_obstacle(rect, "HotelWall%d" % index)
		index += 1
	for spec in HotelLayout.furniture_specs(campus_zone):
		var rect: Rect2 = HotelLayout.footprint(spec)
		var body := _add_obstacle(rect, "HotelFurniture%d" % index, false)
		if spec.kind in ["fountain", "column"]:
			var circle := CircleShape2D.new()
			circle.radius = rect.size.x * .5
			body.get_child(0).shape = circle
			body.get_child(0).position = Vector2(0, -rect.size.y * .5)
		var visual := HotelVisual.new()
		visual.zone = campus_zone
		visual.furniture_only = spec
		visual.furniture_anchor = body.position
		body.add_child(visual)
		_hotel_props.append(visual)
		index += 1
	for spec in HotelLayout.interactions(campus_zone):
		_add_target(str(spec.id), str(spec.label), spec.at, float(spec.radius))

func _hotel_seated() -> bool:
	return room_id == "hotel_room_206" and _bed_pose == "sitting"

func set_bed_pose(pose: String) -> void:
	if not is_instance_valid(player): return
	var was_seated := _hotel_seated()
	_bed_pose = pose if room_id == "hotel_room_206" else "standing"
	if _hotel_seated():
		player.position = HotelLayout.BED_SEAT
		player.velocity = Vector2.ZERO
	elif was_seated:
		player.position = HotelLayout.checkpoints("hotel_room_206").room206_bed
	if is_instance_valid(player.sprite): player.sprite.visible = not _hotel_seated()
	player.controls_enabled = _controls_enabled and not _hotel_seated()
	if is_instance_valid(hotel_visual):
		hotel_visual.bed_pose = _bed_pose
		hotel_visual.queue_redraw()
		for visual in _hotel_props:
			visual.bed_pose = _bed_pose
			visual.queue_redraw()
	_update_camera_position()

func _build_campus() -> void:
	campus_visual = CampusVisual.new()
	campus_visual.zone = campus_zone
	_room_root.add_child(campus_visual)
	_room_root.move_child(campus_visual, 0)
	var index := 0
	for rect in CampusLayout.walls(campus_zone):
		var street_prop := campus_zone == "courtyard" and rect in RoadTraffic.Layout.furniture()
		var body := _add_obstacle(rect,"CampusWall%d" % index, not street_prop)
		if street_prop:
			for spec in RoadTraffic.Layout.furniture_specs():
				if spec.rect != rect or spec.kind == "signal": continue
				var visual := CampusVisual.new()
				visual.furniture_only = spec
				visual.furniture_anchor = body.position
				body.add_child(visual)
		index += 1
	if campus_zone == "building_02":
		for rect in CampusLayout.furniture():
			_add_obstacle(rect,"CampusFurniture%d" % index)
			index += 1
		_add_target("campus_leave","Porte · retour dans la cour",Vector2(3200,4050),100)
	else:
		traffic = RoadTraffic.new()
		_props.add_child(traffic)
		traffic.notice.connect(func(message: String): traffic_notice.emit(message))
		for spec in CampusLayout.interactions(campus_zone):
			_add_target(str(spec.id), str(spec.label), spec.at, float(spec.radius))
