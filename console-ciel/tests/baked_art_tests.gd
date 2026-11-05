extends SceneTree
## Generated-art contract: every static prop is available in exported packs too.
const Cache = preload("res://scripts/game/baked_art.gd")
const Town = preload("res://scripts/game/town_layout.gd")
const School = preload("res://scripts/game/school_layout.gd")
var checks := 0
var failures := 0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(Cache.DIRECTORY+"manifest.json"))
	check(manifest is Dictionary and manifest.get("version")==1,"Manifest livré et versionné")
	if not manifest is Dictionary: quit(1);return
	var records: Dictionary=manifest.get("sprites",{})
	var expected: Dictionary={}
	for spec in Town.solid_specs():
		var id := Cache.key(str(spec.kind),spec.rect,str(spec.get("index","")))
		if spec.kind in ["fountain","signal"]:
			check(not records.has(id),"Animation conservée en temps réel : "+str(spec.kind))
		else: expected[id]=true
	for zone in ["school_reception","school_stop","school_cyber","school_workshop","school_network_lab","school_tne","school_meeting","school_fed"]:
		for spec in School.furniture_specs(zone): expected[Cache.key("school_"+str(spec.kind),Rect2(Vector2.ZERO,spec.rect.size))]=true
	for rect in preload("res://scripts/game/road_layout.gd").gardens():
		expected[Cache.key("campus_garden",Rect2(Vector2.ZERO,rect.size))]=true
	check(records.size()==expected.size(),"Inventaire complet sans sprite orphelin")
	var bytes := 0.0
	var measured: Dictionary={}
	for id in expected:
		check(records.has(id),"Sprite attendu : "+id)
		if not records.has(id): continue
		var entry: Dictionary=records[id]
		var texture: Texture2D=load(Cache.DIRECTORY+str(entry.file))
		check(texture!=null,"Texture importée dans le pack : "+id)
		if texture==null: continue
		check(texture.get_width()>0 and texture.get_height()>0 and texture.get_width()<=4096 and texture.get_height()<=4096,"Dimensions bornées : "+id)
		var box: Array=entry.rect
		check(box.size()==4 and box[2]>0 and box[3]>0 and is_equal_approx(float(texture.get_width()),float(box[2])*float(entry.scale)) and is_equal_approx(float(texture.get_height()),float(box[3])*float(entry.scale)),"Origine et taille après détourage : "+id)
		if not measured.has(entry.file):
			measured[entry.file]=true
			bytes+=texture.get_width()*texture.get_height()*4.0*4.0/3.0
	check(bytes<64*1024*1024,"Budget de 64 Mio RGBA avec mipmaps")
	if FileAccess.file_exists("res://assets/lycee/logo_louise_michel.jpg"):
		check(FileAccess.get_sha256("res://assets/lycee/logo_louise_michel.jpg")==manifest.get("school_logo_sha256",""),"Logo source inchangé")
	if FileAccess.file_exists("res://tools/bake_static_art.gd"):
		check(FileAccess.get_file_as_string("res://tools/bake_static_art.gd").sha256_text()==manifest.get("generator_sha256",""),"Version du générateur conservée")
	for name in manifest.get("generator_inputs",{}):
		var path := "res://scripts/game/"+str(name)+".gd"
		if FileAccess.file_exists(path):
			check(FileAccess.get_file_as_string(path).sha256_text()==manifest.generator_inputs[name],"Précalcul à jour : "+str(name))
	print("BAKED_ART : %d assertions, %d échec(s)." % [checks,failures])
	quit(0 if failures==0 else 1)
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("ÉCHEC : "+message)
