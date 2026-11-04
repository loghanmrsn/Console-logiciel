extends RefCounted
## Original Blender render records; straight alpha, common floor anchors.
const DIRECTORY := "res://assets/art/school_realism/"
static var _manifest: Dictionary = {}
static var _loaded := false
static var _textures: Dictionary = {}
static func manifest() -> Dictionary:
	if not _loaded:
		_loaded=true
		if FileAccess.file_exists(DIRECTORY+"manifest.json"):
			var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY+"manifest.json"))
			if value is Dictionary: _manifest=value
	return _manifest
static func record(kind: String, size: Vector2) -> Dictionary:
	return manifest().get("sprites",{}).get("%s_%dx%d" % [kind,int(size.x),int(size.y)],{})
static func facade(canvas: CanvasItem, frame: Rect2) -> bool:
	var entry: Dictionary=manifest().get("sprites",{}).get("lycee_facade",{})
	if entry.is_empty(): return false
	if not _textures.has("facade"): _textures.facade=load(DIRECTORY+str(entry.file))
	if _textures.facade==null: return false
	var box: Array=entry.rect
	var factor := frame.size/Vector2(1800,330)
	canvas.draw_texture_rect(_textures.facade,Rect2(frame.position+Vector2(box[0],box[1])*factor,Vector2(box[2],box[3])*factor),false)
	return true
