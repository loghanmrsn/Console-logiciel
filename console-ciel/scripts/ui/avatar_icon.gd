extends Control
var color = Color('#527FA3')
var variant = 0
var frame = 'frame_default'
var frame_spec: Dictionary={}
func _init() -> void:
	custom_minimum_size = Vector2(62, 62)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var center = size / 2
	var r = minf(size.x, size.y) * .36
	draw_circle(center, r, color.lightened(.85))
	if variant % 3 == 0:
		draw_circle(center + Vector2(0, -r*.24), r*.26, color)
		draw_style_box(_pill(color), Rect2(center + Vector2(-r*.49,r*.13), Vector2(r*.98,r*.47)))
	elif variant % 3 == 1:
		var points = PackedVector2Array([center+Vector2(0,-r*.60),center+Vector2(r*.52,0),center+Vector2(0,r*.60),center+Vector2(-r*.52,0)])
		draw_colored_polygon(points, color)
	else:
		draw_arc(center, r*.52, -PI*.82, PI*.82, 40, color, r*.27, true)
		draw_circle(center+Vector2(r*.42,-r*.35),r*.16,color.lightened(.2))
	var outline=Color(frame_spec.get('color','#A6B7C4'))
	var width=minf(float(frame_spec.get('width',2))*size.x/62.0,r*.20)
	var kind=frame_spec.get('style','double' if 'double' in frame else 'simple')
	draw_arc(center,r+(r*.05 if kind=='round' else 0),0,TAU,64,outline,maxf(1,width),true)
	if kind=='double':
		draw_arc(center,r+r*.14,0,TAU,64,outline,maxf(1,width*.45),true)
func _pill(c: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color=c
	s.set_corner_radius_all(8)
	return s
