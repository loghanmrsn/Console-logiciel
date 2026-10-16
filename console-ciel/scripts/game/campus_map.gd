extends PanelContainer
## Native HUD, separate from the following camera. Geometry matches collisions.
const Layout = preload("res://scripts/game/campus_layout.gd")
const HotelLayout = preload("res://scripts/game/hotel_layout.gd")
var expanded := true
var toggle_button: Button
var legend: Label
var area_label: Label
var canvas: Control
var world: Node2D
var _last_position := Vector2.INF
var _last_zone := ""
var _column: VBoxContainer
var _fit_scheduled := false

class FloorPlan extends Control:
	const Plan = preload("res://scripts/game/campus_layout.gd")
	const HotelPlan = preload("res://scripts/game/hotel_layout.gd")
	var player_at := Vector2.ZERO
	var zone := "building_02"
	func _draw() -> void:
		var extent: Vector2 = HotelPlan.extent(zone) if HotelPlan.is_zone(zone) else Plan.extent(zone)
		var rooms: Array[Rect2] = HotelPlan.rooms(zone) if HotelPlan.is_zone(zone) else Plan.rooms()
		var walls: Array[Rect2] = HotelPlan.walls(zone) if HotelPlan.is_zone(zone) else Plan.walls(zone)
		var scale_factor := minf((size.x-12)/extent.x,(size.y-12)/extent.y)
		var origin := (size-extent*scale_factor)*.5
		draw_rect(Rect2(origin,extent*scale_factor),Color("eee6d3"))
		for i in rooms.size():
			var room: Rect2 = rooms[i]
			draw_rect(Rect2(origin+room.position*scale_factor,room.size*scale_factor),Plan.COLORS[i%4])
		for wall in walls:
			draw_rect(Rect2(origin+wall.position*scale_factor,Vector2(maxf(1,wall.size.x*scale_factor),maxf(1,wall.size.y*scale_factor))),Color("617a73"))
		if HotelPlan.is_zone(zone):
			for rect in HotelPlan.furniture(zone):
				draw_rect(Rect2(origin+rect.position*scale_factor,rect.size*scale_factor),Color("b5b49c"))
			for spec in HotelPlan.interactions(zone):
				var marker: Vector2 = origin+spec.at*scale_factor
				if str(spec.id).begins_with("hotel_stairs"):
					var up := str(spec.id).ends_with("up")
					var flip := -1.0 if up else 1.0
					draw_colored_polygon(PackedVector2Array([marker+Vector2(-4,-flip*3),marker+Vector2(4,-flip*3),marker+Vector2(0,flip*4)]),Color("6d718e"))
				else:
					draw_rect(Rect2(marker-Vector2(3,2),Vector2(6,4)),Color("ba873e"))
		var point := origin+player_at.clamp(Vector2.ZERO,extent)*scale_factor
		draw_circle(point,5,Color("ffffff"))
		draw_circle(point,3,Color("235f83"))

func _ready() -> void:
	name = "campus_map"
	theme_type_variation = "HUDPanel"
	mouse_filter = Control.MOUSE_FILTER_STOP
	position = Vector2(12,64)
	custom_minimum_size.x = 228
	var column := VBoxContainer.new()
	_column = column
	add_child(column)
	toggle_button = Button.new()
	toggle_button.name = "campus_map_toggle"
	toggle_button.focus_mode = Control.FOCUS_NONE
	toggle_button.add_theme_font_size_override("font_size",16)
	toggle_button.custom_minimum_size.y = 34
	toggle_button.pressed.connect(toggle_map)
	column.add_child(toggle_button)
	area_label = Label.new()
	area_label.name = "campus_map_area"
	area_label.add_theme_font_size_override("font_size",13)
	area_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	area_label.clip_text = true
	area_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	area_label.custom_minimum_size.x = 208
	area_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(area_label)
	canvas = FloorPlan.new()
	canvas.name = "campus_floor_plan"
	canvas.custom_minimum_size = Vector2(208,138)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(canvas)
	legend = Label.new()
	legend.name = "campus_map_legend"
	legend.text = "● Vous   ▪ Porte / accueil\n▲ / ▼ Escaliers"
	legend.add_theme_font_size_override("font_size",12)
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(legend)
	column.minimum_size_changed.connect(_schedule_fit)
	theme_changed.connect(_schedule_fit)
	if get_parent() is Control: get_parent().resized.connect(_schedule_fit)
	_refresh()

func toggle_map() -> void:
	if not visible: return
	expanded = not expanded
	_refresh()

func _refresh() -> void:
	if canvas == null: return
	toggle_button.text = "Carte · →  " + ("▴" if expanded else "▾")
	canvas.visible = expanded
	legend.visible = expanded
	area_label.visible = expanded
	_schedule_fit()

func _process(_delta: float) -> void:
	if not is_visible_in_tree() or not is_instance_valid(world): return
	var zone := str(world.room_id)
	if zone != _last_zone:
		_last_zone = zone
		canvas.zone = zone
		area_label.text = HotelLayout.title(zone) if HotelLayout.is_zone(zone) else "Cour · entre les deux bâtiments"
		canvas.queue_redraw()
	if not expanded: return
	var point: Vector2 = world.get_player_position()
	if point != _last_position:
		_last_position = point
		canvas.player_at = point
		canvas.queue_redraw()

## Fit the map inside the actual game area, which can be shorter than the
## window when a compact header, footer or notification is present.
func _schedule_fit() -> void:
	if _fit_scheduled: return
	_fit_scheduled = true
	_fit_to_game.call_deferred()

func _fit_to_game() -> void:
	_fit_scheduled = false
	if not is_inside_tree() or canvas == null or not get_parent() is Control:
		return
	var available := maxf(48, get_parent().size.y - position.y - 12)
	area_label.visible = expanded and available >= 150
	legend.visible = expanded and available >= 200
	var fixed := get_theme_stylebox("panel").get_minimum_size().y + toggle_button.get_combined_minimum_size().y
	var children := 1
	for label in [area_label, legend]:
		if label.visible:
			fixed += label.get_combined_minimum_size().y
			children += 1
	if expanded:
		fixed += _column.get_theme_constant("separation") * children
		canvas.custom_minimum_size.y = maxf(16, minf(138, available - fixed - 2))
	else:
		fixed += _column.get_theme_constant("separation") * (children - 1)
	# Reset the rectangle after native wrapping/minimum sizes settle. A stale
	# taller minimum otherwise leaves the map clipped by its scroll ancestor.
	size = Vector2(228, 0)
