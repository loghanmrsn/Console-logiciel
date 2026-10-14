extends Control
const LocalLibrary = preload('res://scripts/services/local_avatar_library.gd')

var color = Color('#527FA3')
var variant = 0
var frame = 'frame_default'
var frame_spec: Dictionary={}
var local_image: String = ''
var image_texture: Texture2D

func _init() -> void:
	custom_minimum_size = Vector2(62, 62)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_local_image(filename: String) -> void:
	local_image = filename
	image_texture = LocalLibrary.texture_for(filename) if not filename.is_empty() else null
	queue_redraw()

func _draw() -> void:
	var center = size / 2
	var r = minf(size.x, size.y) * .36
	draw_circle(center, r, color.lightened(.85))
	if image_texture != null:
		_draw_portrait(center, r)
	elif variant % 3 == 0:
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

func _draw_portrait(center: Vector2, radius: float) -> void:
	# Circular texture geometry also works with the Compatibility renderer.
	# UVs crop wide or tall photos around their centre, without stretching faces.
	var texture_size = image_texture.get_size()
	if texture_size.x <= 0 or texture_size.y <= 0:
		return
	var crop = Vector2.ONE
	if texture_size.x > texture_size.y:
		crop.x = texture_size.y / texture_size.x
	else:
		crop.y = texture_size.x / texture_size.y
	var points = PackedVector2Array()
	var uv = PackedVector2Array()
	for index in range(96):
		var direction = Vector2.from_angle(TAU * index / 96.0)
		points.append(center + direction * radius)
		uv.append(Vector2(.5, .5) + direction * crop * .5)
	draw_polygon(points, PackedColorArray([Color.WHITE]), uv, image_texture)

func _pill(c: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color=c
	s.set_corner_radius_all(8)
	return s
