extends SceneTree
const Details = preload("res://scripts/game/town_details.gd")
const Town = preload("res://scripts/game/town_layout.gd")
const Cache = preload("res://scripts/game/baked_art.gd")
var checks := 0
var failures := 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("TOWN_DETAIL_FAIL : "+message)
func _run() -> void:
	var manifest := Details.manifest()
	check(manifest.get("version")==1 and manifest.get("sprites",{}).size()==34,"Catalogue complet des modèles de ville")
	check(manifest.get("eu_star_count")==12 and manifest.get("fr_stripe_order")==["blue","white","red"],"Drapeaux français et européen")
	check(manifest.get("catalog_sha256")==FileAccess.get_sha256("res://data/town_forecourts.json"),"Catalogue lié aux placements livrés")
	var baked: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Cache.DIRECTORY+"manifest.json"))
	check(baked.get("town_render_manifest_sha256")==FileAccess.get_sha256(Details.DIRECTORY+"manifest.json"),"Catalogue précalculé lié aux rendus")
	check(baked.get("forecourt_catalog_sha256")==FileAccess.get_sha256("res://data/town_forecourts.json"),"Placements précalculés à jour")
	var owners: Dictionary = {}
	var decorations := Town.forecourt_specs()
	check(decorations.size()==41,"41 décors devant les 40 bâtiments")
	for spec in decorations:
		owners[spec.forecourt_owner]=true
		check(not Details.record(spec.kind,spec.rect.size).is_empty(),"Chaque décor possède un vrai rendu Blender : "+spec.kind)
		for road in Town.roads(): check(not road.intersects(spec.rect),"Décor hors chaussée : "+spec.kind)
		for facade in Town.buildings(): check(not facade.rect.intersects(spec.rect),"Décor hors façade : "+spec.kind)
		for other in Town.props():
			if other!=spec: check(not other.rect.intersects(spec.rect),"Emprise distincte : "+spec.kind+" / "+other.kind)
	check(owners.size()==40 and owners.has("academy") and owners.has("ritz"),"Les deux bâtiments d’origine sont également décorés")
	for index in range(38): check(owners.has(str(index)),"Domaine représenté : "+Town.NAMES[index])
	for key in manifest.sprites:
		var entry: Dictionary=manifest.sprites[key]
		var path := Details.DIRECTORY+str(entry.file)
		var texture: Texture2D=load(path)
		check(texture!=null,"Texture importée : "+key)
		if texture==null: continue
		check(texture.get_width()==int(entry.rect[2]*entry.scale) and texture.get_height()==int(entry.rect[3]*entry.scale),"Ancrage et dimensions : "+key)
		check(texture.get_width()<=1024 and texture.get_height()<=1024,"Texture bornée : "+key)
		check(entry.get("lossless_roundtrip_verified",false) and entry.get("alpha")=="straight","Pixels sans perte et alpha droit : "+key)
		var pixels := texture.get_image()
		var clear := true
		for x in range(pixels.get_width()):
			if pixels.get_pixel(x,0).a>.02 or pixels.get_pixel(x,pixels.get_height()-1).a>.02: clear=false
		for y in range(pixels.get_height()):
			if pixels.get_pixel(0,y).a>.02 or pixels.get_pixel(pixels.get_width()-1,y).a>.02: clear=false
		check(clear,"Aucun bord coupé : "+key)
		if FileAccess.file_exists(path): check(FileAccess.get_sha256(path)==entry.sha256,"Source intacte : "+key)
	for spec in Town.props():
		var record := Details.record(spec.kind,spec.rect.size)
		if record.is_empty(): continue
		var id := Cache.key(spec.kind,spec.rect)
		if spec.kind=="fountain": check(not baked.sprites.has(id),"Fontaine dessinée en temps réel pour l’eau")
		else:
			var entry: Dictionary=baked.sprites.get(id,{})
			check(entry.get("sha256")==record.sha256,"Rendu réellement utilisé : "+spec.kind)
			check(is_equal_approx(entry.rect[0],spec.rect.position.x+record.rect[0]) and is_equal_approx(entry.rect[1],spec.rect.position.y+record.rect[1]),"Ancrage mondial conservé : "+spec.kind)
	var generators := {"res://tools/render_town_details.py":"generator_sha256","res://tools/town_prop_models.py":"models_sha256","res://tools/render_school_assets.py":"rig_sha256","res://tools/pack_school_renders.gd":"packing_generator_sha256"}
	for path in generators:
		var key: String=generators[path]
		if FileAccess.file_exists(path): check(FileAccess.get_sha256(path)==manifest.get(key),"Générateur conservé : "+path)
	print("TOWN_DETAILS_ASSETS : %d assertions, %d échec(s)." % [checks,failures])
	quit(0 if failures==0 else 1)
