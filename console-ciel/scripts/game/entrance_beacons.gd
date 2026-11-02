extends Node2D
## Persistent small entrance dots, independent of the interaction highlight.
var points := PackedVector2Array()
var _zoom := -1.0
var _radius := 9.0

func _ready() -> void:
	name="EntranceBeacons"
	z_index=6

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	var zoom := camera.zoom.x if camera!=null else 1.0
	if is_equal_approx(zoom,_zoom): return
	_zoom=zoom
	_radius=6.0/maxf(zoom,.05)
	queue_redraw()

func _draw() -> void:
	for point in points:
		draw_circle(point,_radius*1.6,Color(.25,.49,.65,.16))
		draw_circle(point,_radius,Color("fffdf4"))
		draw_circle(point,_radius*.67,Color("477fa5"))
		draw_circle(point,_radius*.23,Color("fffdf4"))
