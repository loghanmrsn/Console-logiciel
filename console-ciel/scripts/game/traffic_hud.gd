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
	_detail.text = "Rouge : pénalité de 200 points\nChoc : retour sur le trottoir"
	_detail.add_theme_font_size_override("font_size", 13)
	column.add_child(_detail)

func _process(_delta: float) -> void:
	if not is_instance_valid(world) or not is_instance_valid(world.traffic):
		hide()
		return
	visible = world.traffic.enabled and world.is_visible_in_tree()
	var green: bool = world.traffic.phase == world.traffic.Phase.GREEN
	var seconds := maxi(0, ceili(world.traffic.remaining))
	var message := ("✓ VERT · Traversez" if green else "● ROUGE · Attendez") + (" · %ds" % seconds if seconds > 0 else "")
	if _status.text != message:
		_status.text = message
		reset_size()
