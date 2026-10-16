extends PanelContainer
## Native HUD, separate from the following camera. Geometry matches collisions.
const Layout = preload("res://scripts/game/campus_layout.gd")
var expanded := true
var toggle_button: Button
var legend: Label
var canvas: Control
var world: Node2D
var _last_position := Vector2.INF

class FloorPlan extends Control:
	const Plan = preload("res://scripts/game/campus_layout.gd")
	var player_at := Vector2.ZERO
	func _draw() -> void:
		var scale_factor := minf((size.x-12)/Plan.BUILDING_SIZE.x,(size.y-12)/Plan.BUILDING_SIZE.y)
		var origin := (size-Plan.BUILDING_SIZE*scale_factor)*.5
		draw_rect(Rect2(origin,Plan.BUILDING_SIZE*scale_factor),Color("d3dfd9"))
		for i in Plan.rooms().size():
			var room: Rect2 = Plan.rooms()[i]
			draw_rect(Rect2(origin+room.position*scale_factor,room.size*scale_factor),Plan.COLORS[i%4])
		for wall in Plan.walls("building_02"):
			draw_rect(Rect2(origin+wall.position*scale_factor,Vector2(maxf(1,wall.size.x*scale_factor),maxf(1,wall.size.y*scale_factor))),Color("617a73"))
		var door := origin+Vector2(3200,4100)*scale_factor
		draw_rect(Rect2(door-Vector2(5,3),Vector2(10,6)),Color("ba873e"))
		var point := origin+player_at.clamp(Vector2.ZERO,Plan.BUILDING_SIZE)*scale_factor
		draw_circle(point,5,Color("ffffff"))
		draw_circle(point,3,Color("235f83"))

func _ready() -> void:
	name = "campus_map"
	theme_type_variation = "HUDPanel"
	mouse_filter = Control.MOUSE_FILTER_STOP
	position = Vector2(12,64)
	custom_minimum_size.x = 228
	var column := VBoxContainer.new()
	add_child(column)
	toggle_button = Button.new()
	toggle_button.name = "campus_map_toggle"
	toggle_button.focus_mode = Control.FOCUS_NONE
	toggle_button.add_theme_font_size_override("font_size",16)
	toggle_button.custom_minimum_size.y = 34
	toggle_button.pressed.connect(toggle_map)
	column.add_child(toggle_button)
	canvas = FloorPlan.new()
	canvas.name = "campus_floor_plan"
	canvas.custom_minimum_size = Vector2(208,138)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(canvas)
	legend = Label.new()
	legend.name = "campus_map_legend"
	legend.text = "● Vous   ▪ Sortie vers la cour"
	legend.add_theme_font_size_override("font_size",12)
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(legend)
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
	size = Vector2(228,0)

func _process(_delta: float) -> void:
	if not is_visible_in_tree() or not expanded or not is_instance_valid(world): return
	var point: Vector2 = world.get_player_position()
	if point != _last_position:
		_last_position = point
		canvas.player_at = point
		canvas.queue_redraw()
