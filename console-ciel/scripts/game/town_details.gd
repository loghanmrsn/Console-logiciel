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
	preload("res://scripts/game/fountain_water.gd").draw(canvas,rect,time)
