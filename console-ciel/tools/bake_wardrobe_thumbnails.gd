extends SceneTree
## Actual 3D catalogue pictures, rendered once; shop cards never run 30 viewports.
const Catalog=preload("res://scripts/services/character_catalog.gd")
const View=preload("res://scripts/character/character_view.gd")
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var directory="res://assets/character3d/shop/"
	DirAccess.make_dir_recursive_absolute(directory)
	var records={}
	for item in Catalog.ITEMS:
		if item.id=="none":continue
		var a=Catalog.defaults().appearance
		a[item.slot]=item.id
		var color={"top":"cream","trousers":"blue","shoes":"white","headwear":"black","socks":"white"}.get(item.slot,"")
		if item.id in ["boots","loafers"]:color="brown"
		if item.id=="cap_denim":color="denim"
		if item.id=="straw":color="cream"
		if item.slot!="hair":a[item.slot+"_color"]=color if color in Catalog.allowed_colors(item.slot,item.id) else Catalog.allowed_colors(item.slot,item.id)[0]
		var view=View.new();view.appearance=a;view.size=Vector2(256,256);root.add_child(view)
		view.viewport.size=Vector2i(256,256)
		var framing={"hair":[1.56,.48],"top":[1.11,.73],"trousers":[.53,1.04],"headwear":[1.65,.40],"socks":[.15,.34],"shoes":[.10,.40]}[item.slot]
		if item.id=="madison":framing=[1.0,1.1]
		view.camera.size=framing[1];view.camera.position=Vector3(0,framing[0]+.18,3);view.camera.look_at(Vector3(0,framing[0],0))
		view.heading=.35 if item.slot!="hair" else .15
		for mesh in view.model.meshes:
			mesh.visible=String(mesh.name)==item.slot+"_"+item.id or (item.slot=="hair" and String(mesh.name) in ["body","eyes_almond","smile_soft"])
		view.refresh()
		await process_frame;await RenderingServer.frame_post_draw
		var im=view.viewport.get_texture().get_image()
		var file=item.slot+"_"+item.id+".webp"
		if im==null or im.is_empty() or im.save_webp(directory+file,false)!=OK:push_error("Thumbnail failed: "+file);quit(1);return
		records[Catalog.key(item.slot,item.id)]={"file":file,"sha256":FileAccess.get_sha256(directory+file),"size":[256,256],"appearance":a}
		root.remove_child(view);view.free()
		print("WARDROBE_THUMBNAIL ",file)
	var result={"version":1,"license":"CC0-1.0 original rendered artwork","engine":Engine.get_version_info().string,"model_sha256":FileAccess.get_sha256("res://assets/character3d/character.glb"),"materials_sha256":FileAccess.get_sha256("res://assets/character3d/materials/manifest.json"),"material_factory_sha256":FileAccess.get_sha256("res://scripts/character/character_materials.gd"),"shader_sha256":FileAccess.get_sha256("res://scripts/character/surface_material.gdshader"),"generator_sha256":FileAccess.get_sha256("res://tools/bake_wardrobe_thumbnails.gd"),"items":records,"source":"Actual offscreen Godot Compatibility render; no external imagery or brand"}
	var f=FileAccess.open(directory+"manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"\t"));f.close()
	print("WARDROBE_BAKE : ",records.size()," images, 0 échec(s).")
	quit()
