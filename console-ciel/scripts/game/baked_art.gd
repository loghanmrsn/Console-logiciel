extends RefCounted
## Generated static sprites. Procedural authoring remains the fallback/source.
const DIRECTORY := "res://assets/art/baked/"
static var _manifest: Dictionary = {}
static var _loaded := false
static var _textures: Dictionary = {}
static var _material: CanvasItemMaterial

static func key(kind: String, rect: Rect2, variant: String = "") -> String:
	return (kind+"|"+str(rect)+"|"+variant).sha256_text().left(20)

static func draw_town(canvas: CanvasItem, spec: Dictionary) -> bool:
	return _draw(canvas,key(str(spec.kind),spec.rect,str(spec.get("index",""))))

static func draw_school(canvas: CanvasItem, kind: String, rect: Rect2) -> bool:
	var local := Rect2(Vector2.ZERO,rect.size)
	return _draw(canvas,key("school_"+kind,local),rect.position)

static func draw_garden(canvas: CanvasItem, rect: Rect2) -> bool:
	return _draw(canvas,key("campus_garden",Rect2(Vector2.ZERO,rect.size)),rect.position)

static func _draw(canvas: CanvasItem, id: String, offset: Vector2 = Vector2.ZERO) -> bool:
	if not _loaded:
		_loaded=true
		if FileAccess.file_exists(DIRECTORY+"manifest.json"):
			var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY+"manifest.json"))
			if value is Dictionary: _manifest=value.get("sprites",{})
	if not _manifest.has(id): return false
	var record: Dictionary=_manifest[id]
	if not _textures.has(id):
		var texture: Texture2D=load(DIRECTORY+str(record.file))
		if texture==null: return false
		_textures[id]=texture
	if _material==null:
		_material=CanvasItemMaterial.new()
		_material.blend_mode=CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	if canvas.material != _material: canvas.material=_material
	if canvas.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS:
		canvas.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var box: Array=record.rect
	canvas.draw_texture_rect(_textures[id],Rect2(offset+Vector2(box[0],box[1]),Vector2(box[2],box[3])),false)
	return true
