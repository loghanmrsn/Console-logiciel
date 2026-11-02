extends PanelContainer
## A native HUD stays readable while the camera follows the crossing.
var world: Node2D
var _status: Label
var _detail: Label

func _ready() -> void:
	name = "traffic_hud"
	theme_type_variation = "HUDPanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(12, 64)
	custom_minimum_size.x = 245
	var column := VBoxContainer.new()
	add_child(column)
	_status = Label.new()
	_status.name = "pedestrian_signal"
	_status.add_theme_font_size_override("font_size", 18)
	column.add_child(_status)
	_detail = Label.new()
	_detail.text = "Centre : rouge = 200 points\nChoc : retour sur le trottoir"
	_detail.add_theme_font_size_override("font_size", 13)
	column.add_child(_detail)

func _process(_delta: float) -> void:
	if not is_instance_valid(world) or not is_instance_valid(world.traffic):
		hide()
		return
	var compact := get_viewport_rect().size.x<1000
	custom_minimum_size.x=210 if compact else 245
	var font_size := 15 if compact else 18
	if _status.get_theme_font_size("font_size") != font_size: _status.add_theme_font_size_override("font_size",font_size)
	if get_parent() is Control: position=Vector2(maxf(12,(get_parent().size.x-custom_minimum_size.x)*.5),12)
	visible = world.traffic.enabled and world.is_visible_in_tree() and world.get_player_position().distance_to(Vector2(900,700)) < 650
	var green: bool = world.traffic.phase == world.traffic.Phase.GREEN
	var seconds := maxi(0, ceili(world.traffic.remaining))
	var message := ("✓ VERT · Traversez" if green else "● ROUGE · Attendez") + (" · %ds" % seconds if seconds > 0 else "")
	if _status.text != message:
		_status.text = message
		reset_size()
