extends Node2D
## A compact, entirely original 2D room. All dimensions are in world pixels.
## Collision and interaction data are built alongside the matching decoration.

signal interaction_requested(id: String)
signal target_changed(id: String, label: String)

const Art=preload('res://scripts/game/room_art.gd')
const PlayerScript = preload("res://scripts/game/player.gd")
const InteractableScript = preload("res://scripts/game/interactable.gd")
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
	"exit": Vector2(500, 350)
}
const DOOR_RECT := Rect2(619, 276, 20, 112)

var player: CharacterBody2D
var door_body: StaticBody2D
var door_shape: CollisionShape2D
var camera: Camera2D
var target_id := ""
var lighting_restored := false
var door_open := false
var computer_repaired := false
var chapter_id := 1
var room_id := "room_01"
var elevator_unlocked := false
var network_restored := false
var addressing_restored := false
var security_restored := false
var python_restored := false
var html_restored := false
var markdown_restored := false
var _targets: Array[Node2D] = []
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
	door_body = null
	door_shape = null
	chapter_id = chapter
	room_id = "room_0%d" % chapter
	_room_root = Node2D.new()
	_room_root.name = ["ChapterOneRoom", "ChapterTwoRoom", "ChapterThreeRoom"][chapter - 1]
	add_child(_room_root)
	_props=Node2D.new()
	_props.name='RoomObjects'
	_props.y_sort_enabled=true
	_room_root.add_child(_props)
	# Perimeter and office partition. The doorway is a real, separate body.
	_add_obstacle(Rect2(24, 30, 952, 20), "NorthWall")
	_add_obstacle(Rect2(24, 476, 952, 20), "SouthWall")
	_add_obstacle(Rect2(24, 50, 20, 426), "WestWall")
	_add_obstacle(Rect2(956, 50, 20, 426), "EastWall")
	if chapter == 1:
		_build_workshop()
	elif chapter == 2:
		_build_network_room()
	else:
		_build_code_room()
	player = PlayerScript.new()
	player.name = "Player"
	player.position = _chapter_checkpoints().entrance
	_props.add_child(player)
	player.controls_enabled = _controls_enabled
	_restored_once = false
	_was_repaired = false
	target_changed.emit("", "")

func _build_workshop() -> void:
	_add_obstacle(Rect2(619, 50, 20, 226), "OfficeWallNorth")
	_add_obstacle(Rect2(619, 388, 20, 88), "OfficeWallSouth")
	door_body = _add_obstacle(DOOR_RECT, "OfficeDoor", false)
	door_shape = door_body.get_child(0)
	_closed_door=_sprite(door_body,'door_closed',Rect2(616,276,28,120))
	_open_door=_sprite(door_body,'door_open',Rect2(639,272,120,28))
	for prop in Art.PROPS:
		var body=_add_obstacle(prop[1],prop[0],false)
		var visual=_sprite(body,prop[2],prop[3])
		if prop[0]=='ElectricalCabinet': _cabinet_sprite=visual
		if prop[0]=='ComputerDesk':
			_monitor_sprite=_sprite(body,'monitor_off',Rect2(781,127,85,61))
			_sprite(body,'tower',Rect2(879,145,36,68))
	_reader_sprite=_sprite(_room_root,'reader_off',Rect2(568,289,30,49))
	_light_sprite=_sprite(_room_root,'light',Rect2(274,61,172,28))
	_note=_sprite(_room_root,'note',Rect2(447,194,70,48))
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

func _chapter_for_room(id: String) -> int:
	match id:
		"room_02": return 2
		"room_03": return 3
		_: return 1

func _chapter_checkpoints() -> Dictionary:
	match chapter_id:
		2: return CHAPTER_TWO_CHECKPOINTS
		3: return CHAPTER_THREE_CHECKPOINTS
		_: return CHECKPOINTS

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
	if is_instance_valid(_elevator_sprite):
		_elevator_sprite.texture = Art.TEXTURES.elevator_ready if elevator_unlocked else Art.TEXTURES.elevator_locked
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
	var target := InteractableScript.new()
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
	var fit := maxf(MINIMUM_CAMERA_ZOOM, minf(available.x / WORLD_SIZE.x, available.y / WORLD_SIZE.y))
	camera.zoom = Vector2(fit, fit)
	_update_camera_position()

func _update_camera_position() -> void:
	if not is_inside_tree() or not is_instance_valid(camera) or not is_instance_valid(player):
		return
	var half_visible: Vector2 = get_viewport_rect().size / camera.zoom * 0.5
	var center := WORLD_SIZE * 0.5
	if half_visible.x < WORLD_SIZE.x * 0.5:
		center.x = clampf(player.position.x, half_visible.x, WORLD_SIZE.x - half_visible.x)
	if half_visible.y < WORLD_SIZE.y * 0.5:
		center.y = clampf(player.position.y, half_visible.y, WORLD_SIZE.y - half_visible.y)
	# No permanent background animation or camera smoothing is needed.
	camera.position = center

func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled
	if is_instance_valid(player):
		player.controls_enabled = enabled
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
	player.velocity = Vector2.ZERO
	_update_camera_position()
	_update_target()

func restore_progress(progress: Dictionary) -> void:
	_pending_progress = progress.duplicate(true)
	if not is_instance_valid(player):
		return
	var desired_chapter := _chapter_for_room(str(progress.get("room_id", "room_01")))
	if chapter_id != desired_chapter:
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
	_refresh_art()
	_refresh_target_availability()
	if not _restored_once:
		restore_checkpoint()
		_restored_once = true
	_sync_appearance()
	_fit_camera()
	queue_redraw()
	_update_target()

func _is_target_available(target: Node2D) -> bool:
	# Mission equipment remains part of the room after repair, but its marker
	# and interaction stop. The elevator is travel, never a completed mission.
	return target.interaction_id == "elevator" or not _pending_progress.get("completed_missions", []).has(target.interaction_id)

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

func _can_reach(target: Node2D, margin := 0.0) -> bool:
	if not _is_target_available(target):
		return false
	if player.global_position.distance_to(target.global_position) > target.interaction_radius + margin:
		return false
	# In particular, an unopened door prevents interacting with the computer
	# through the partition. Other furniture also blocks the line of sight.
	var query := PhysicsRayQueryParameters2D.create(player.global_position, target.global_position, 1, [player.get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _target_score(target: Node2D) -> float:
	var toward := target.global_position - player.global_position
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

func _draw_code_label(language: String, completed: bool, at: Vector2, color: Color) -> void:
	var label := language + (" · VALIDÉ" if completed else "")
	var font := ThemeDB.fallback_font
	var font_size := 13 if _large_text else 12
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, at - Vector2(width * 0.5, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#4f765f") if completed else color)
