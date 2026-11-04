extends RefCounted
## Original civic props. Water stays animated over the pre-rendered stone basin.
const DIRECTORY := "res://assets/art/town_details/"
static var _manifest: Dictionary = {}
static var _textures: Dictionary = {}
static func manifest() -> Dictionary:
	if _manifest.is_empty():
		var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY+"manifest.json"))
		if parsed is Dictionary: _manifest=parsed
	return _manifest
static func record(kind: String, size: Vector2) -> Dictionary:
	return manifest().get("sprites",{}).get("%s_%dx%d" % [kind,int(size.x),int(size.y)],{})
static func draw(canvas: CanvasItem, spec: Dictionary) -> bool:
	var entry := record(spec.kind,spec.rect.size)
	if entry.is_empty(): return false
	var filename := str(entry.file)
	if not _textures.has(filename): _textures[filename]=load(DIRECTORY+filename)
	if _textures[filename]==null: return false
	if canvas.texture_filter!=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS: canvas.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var box: Array=entry.rect
	canvas.draw_texture_rect(_textures[filename],Rect2(spec.rect.position+Vector2(box[0],box[1]),Vector2(box[2],box[3])),false)
	return true
static func fountain_water(canvas: CanvasItem, rect: Rect2, time: float) -> void:
	var origin := rect.position+Vector2(95,27)
	for index in range(3):
		var landing := rect.position+Vector2(95+(index-1)*43,102 if index==1 else 79)
		var crest := (origin+landing)*.5-Vector2(0,45+2*sin(time*1.6+index))
		var line := PackedVector2Array()
		for step in range(25):
			var t := step/24.0
			line.append((1-t)*(1-t)*origin+2*(1-t)*t*crest+t*t*landing)
		canvas.draw_polyline(line,Color(.40,.72,.80,.60),3,true)
		canvas.draw_polyline(line,Color(.84,.97,1,.72),1,true)
		for ring in range(2):
			var phase := fposmod(time*.55+index*.29+ring*.5,1.0)
			var ripple := PackedVector2Array()
			for step in range(33):
				var a := TAU*step/32.0
				ripple.append(landing+Vector2(cos(a),sin(a)*.55)*(3+phase*11))
			canvas.draw_polyline(ripple,Color(.82,.95,1,(1-phase)*.45),1,true)
