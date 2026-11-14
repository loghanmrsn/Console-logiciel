extends RefCounted
## Shared, tiny surface maps; each character owns only its color parameters.
const ShaderSource=preload("res://scripts/character/surface_material.gdshader")
const MAPS={
	"skin":preload("res://assets/character3d/materials/skin.png"),
	"cotton":preload("res://assets/character3d/materials/cotton.png"),
	"knit":preload("res://assets/character3d/materials/knit.png"),
	"denim":preload("res://assets/character3d/materials/denim.png"),
	"leather":preload("res://assets/character3d/materials/leather.png"),
	"felt":preload("res://assets/character3d/materials/felt.png"),
	"straw":preload("res://assets/character3d/materials/straw.png"),
	"hair":preload("res://assets/character3d/materials/hair.png")}
static func kind(surface: String,a: Dictionary) -> String:
	match surface:
		"skin","lips","fur":return "skin"
		"hair":return "hair"
		"top":return "knit" if a.top in ["sweater","cardigan","madison"] else "cotton"
		"trousers":return "denim" if a.trousers=="baggy" else "cotton"
		"socks":return "knit"
		"hat":return {"cap_denim":"denim","straw":"straw","fedora":"felt"}.get(a.headwear,"cotton")
		"shoes":return "cotton" if a.shoes in ["canvas","runner"] else ("felt" if a.shoes=="boots" else "leather")
	return "cotton"
static func configure(material: ShaderMaterial,surface: String,color: Color,a: Dictionary) -> void:
	var style=kind(surface,a)
	material.shader=ShaderSource
	material.set_shader_parameter("tint",color)
	material.set_shader_parameter("detail_map",MAPS[style])
	material.set_shader_parameter("skin_coverage",surface in ["skin","fur"])
	material.set_shader_parameter("compact_body",a.get("model","classic")!="classic")
	material.set_shader_parameter("evening_dress",a.top=="madison")
	material.set_shader_parameter("short_sleeves",a.top=="tee")
	material.set_shader_parameter("capped",surface=="hair" and a.headwear!="none")
	var settings={"skin":[90.0,.00009,.64,.13,.23],"cotton":[24.0,.00035,.86,.34,.18],"knit":[13.0,.0008,.88,.38,.16],"denim":[22.0,.0004,.82,.38,.22],"leather":[32.0,.0002,.48,.20,.36],"felt":[36.0,.00025,.93,.22,.12],"straw":[12.0,.0004,.85,.38,.20],"hair":[16.0,.00015,.54,.30,.40]}[style]
	for i in range(5):material.set_shader_parameter(["tile_scale","relief","roughness_base","variation","shine"][i],settings[i])
