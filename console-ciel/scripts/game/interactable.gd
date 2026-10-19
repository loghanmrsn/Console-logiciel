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
			queue_redraw()

@export var marker_offset := Vector2(0,-45)
var dialogue_marker := false

func _draw() -> void:
	if not highlighted: return
	draw_set_transform(marker_offset)
	if dialogue_marker:
		var bubble := StyleBoxFlat.new()
		bubble.bg_color = Color(1, 1, 1, .97)
		bubble.border_color = accent
		bubble.set_border_width_all(2)
		bubble.set_corner_radius_all(6)
		draw_style_box(bubble, Rect2(-13, -10, 26, 20))
		draw_colored_polygon(PackedVector2Array([Vector2(-6, 8), Vector2(-6, 15), Vector2(1, 9)]), accent)
		for x in [-6, 0, 6]: draw_circle(Vector2(x, 0), 1.5, accent)
		draw_set_transform(Vector2.ZERO)
		return
	draw_circle(Vector2.ZERO,9,Color(1,1,1,.96))
	draw_arc(Vector2.ZERO,9,0,TAU,32,accent,2,true)
	draw_line(Vector2(-3,0),Vector2(3,0),accent,2,true)
	draw_line(Vector2(0,-3),Vector2(0,3),accent,2,true)
	draw_set_transform(Vector2.ZERO)
