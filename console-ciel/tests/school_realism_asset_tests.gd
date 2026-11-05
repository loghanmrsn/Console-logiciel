extends SceneTree
const Models = preload("res://scripts/game/school_realism.gd")
const School = preload("res://scripts/game/school_layout.gd")
const Cache = preload("res://scripts/game/baked_art.gd")
var checks := 0
var failures := 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("REALISM_FAIL : "+message)
func _run() -> void:
	var manifest := Models.manifest()
	check(manifest.get("version")==1,"Catalogue des rendus livré")
	var records: Dictionary=manifest.get("sprites",{})
	check(records.size()==24,"23 empreintes de mobilier et façade")
	var live: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Cache.DIRECTORY+"manifest.json"))
	check(live.get("school_render_manifest_sha256","")==FileAccess.get_sha256(Models.DIRECTORY+"manifest.json"),"Cache lié au catalogue exact des modèles")
	for name in records:
		var entry: Dictionary=records[name]
		var path := Models.DIRECTORY+str(entry.file)
		var texture: Texture2D=load(path)
		check(texture!=null,"Rendu importé : "+name)
		if texture==null: continue
		check(texture.get_width()==int(entry.rect[2]) and texture.get_height()==int(entry.rect[3]),"Pixels alignés sur les coordonnées : "+name)
		check(entry.get("lossless_roundtrip_verified",false),"Compression sans perte : "+name)
		var pixels := texture.get_image()
		var clear_border := true
		for x in range(0,pixels.get_width(),8):
			if pixels.get_pixel(x,0).a>.02 or pixels.get_pixel(x,pixels.get_height()-1).a>.02: clear_border=false
		for y in range(0,pixels.get_height(),8):
			if pixels.get_pixel(0,y).a>.02 or pixels.get_pixel(pixels.get_width()-1,y).a>.02: clear_border=false
		check(clear_border,"Contour transparent sans ombre rectangulaire coupée : "+name)
		check(entry.get("alpha")=="straight","Alpha du moteur 3D déclaré : "+name)
		check(texture.get_width()<=2048 and texture.get_height()<=1024,"Texture bornée : "+name)
		if FileAccess.file_exists(path): check(FileAccess.get_sha256(path)==entry.sha256,"Rendu source intact : "+name)
	for zone in School.Ateliers.IDS+["school_network_lab"]:
		for spec in School.furniture_specs(zone):
			if spec.kind in ["sign"]: continue
			var rendered := Models.record(spec.kind,spec.rect.size)
			check(not rendered.is_empty(),"Mobilier reconstruit : "+zone+"/"+spec.kind)
			if rendered.is_empty(): continue
			var id := Cache.key("school_"+str(spec.kind),Rect2(Vector2.ZERO,spec.rect.size))
			check(live.sprites[id].get("alpha")=="straight" and live.sprites[id].get("sha256")==rendered.sha256,"Le jeu utilise réellement ce rendu : "+id)
	var texture_paths: Dictionary = {}
	for entry in live.sprites.values(): texture_paths[(Cache.DIRECTORY+str(entry.file)).simplify_path()]=true
	texture_paths[Models.DIRECTORY+"lycee_facade.webp"]=true
	texture_paths["res://assets/art/town_details/fountain_190x190.webp"]=true
	var bytes := 256.0*256*4*4/3
	for path in texture_paths:
		var texture: Texture2D=load(path)
		bytes+=texture.get_width()*texture.get_height()*4.0*4.0/3.0
	check(bytes<=64*1024*1024,"Décors et matières du lycée dans le budget de 64 Mio RGBA avec mipmaps")
	var generator := "res://tools/render_school_assets.py"
	if FileAccess.file_exists(generator): check(FileAccess.get_sha256(generator)==manifest.get("generator_sha256",""),"Source de génération conservée")
	var packer := "res://tools/pack_school_renders.gd"
	if FileAccess.file_exists(packer): check(FileAccess.get_sha256(packer)==manifest.get("packing_generator_sha256",""),"Source de compression conservée")
	print("SCHOOL_REALISM_ASSETS : %d assertions, %d échec(s)." % [checks,failures])
	quit(0 if failures==0 else 1)
