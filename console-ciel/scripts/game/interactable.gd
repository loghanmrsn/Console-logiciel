extends Node2D
## Generic spatial target. Puzzle rules live in the investigation service.
@export var interaction_id := ""
@export var label := ""
@export var interaction_radius := 92.0
var accent := Color("527fa3")
var highlighted := false:
	set(value):
		if highlighted != value:
			highlighted = value
			_highlight_changed()
			queue_redraw()

@export var marker_offset := Vector2(0,-45)
var dialogue_marker := false

func _highlight_changed() -> void:
	pass

func _draw() -> void:
	if not highlighted: return
	draw_set_transform(marker_offset)
	draw_circle(Vector2.ZERO,9,Color(1,1,1,.96))
	draw_arc(Vector2.ZERO,9,0,TAU,32,accent,2,true)
	draw_line(Vector2(-3,0),Vector2(3,0),accent,2,true)
	draw_line(Vector2(0,-3),Vector2(0,3),accent,2,true)
	draw_set_transform(Vector2.ZERO)
