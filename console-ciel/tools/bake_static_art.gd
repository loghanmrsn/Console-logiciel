extends SceneTree
## Run under the Compatibility renderer. Only authored, state-free props bake.
const Town = preload("res://scripts/game/town_layout.gd")
const School = preload("res://scripts/game/school_layout.gd")
const Realism = preload("res://scripts/game/school_realism.gd")
const Details = preload("res://scripts/game/town_details.gd")
const Cache = preload("res://scripts/game/baked_art.gd")
var records: Dictionary = {}

class GardenDrawing extends Node2D:
	var rect: Rect2
	var anchor: Vector2
	func _draw() -> void:
		draw_set_transform(-anchor)
		preload("res://scripts/game/exterior_painter.gd").garden(self,rect)

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(Cache.DIRECTORY))
	for spec in Town.solid_specs():
		if spec.kind in ["fountain","signal"]: continue
		var r: Rect2=spec.rect
		var id := Cache.key(str(spec.kind),r,str(spec.get("index","")))
		var rendered := Details.record(str(spec.kind),r.size)
		if not rendered.is_empty():
			var entry: Dictionary=rendered.duplicate(true)
			entry.file="../town_details/"+str(entry.file)
			entry.rect[0]+=r.position.x
			entry.rect[1]+=r.position.y
			records[id]=entry
			continue
		var box := Rect2(r.position-Vector2(32,185),r.size+Vector2(64,245))
		var node=load("res://scripts/game/town_visual.gd").new()
		node.furniture_only=spec
		node.furniture_anchor=box.position
		node.use_baked_art=false
		await _bake(node,box,id,.85)
	for zone in ["school_stop","school_cyber","school_workshop","school_network_lab","school_tne","school_meeting","school_fed"]:
		for spec in School.furniture_specs(zone):
			var r := Rect2(Vector2.ZERO,spec.rect.size)
			var id := Cache.key("school_"+str(spec.kind),r)
			if records.has(id): continue
			var rendered := Realism.record(str(spec.kind),r.size)
			if not rendered.is_empty():
				var entry: Dictionary=rendered.duplicate(true)
				entry.file="../school_realism/"+str(entry.file)
				records[id]=entry
				continue
			var box := Rect2(Vector2(-40,-165),r.size+Vector2(80,215))
			var node=load("res://scripts/game/city_lab_visual.gd").new() if zone=="school_network_lab" else load("res://scripts/game/school_visual.gd").new()
			node.zone=zone
			node.furniture_only={"kind":spec.kind,"rect":r}
			node.furniture_anchor=box.position
			node.use_baked_art=false
			await _bake(node,box,id,1.0)
	for rect in preload("res://scripts/game/road_layout.gd").gardens():
		var local := Rect2(Vector2.ZERO,rect.size)
		var id := Cache.key("campus_garden",local)
		if records.has(id): continue
		var box := Rect2(Vector2(-40,-100),rect.size+Vector2(80,140))
		var node := GardenDrawing.new()
		node.rect=local
		node.anchor=box.position
		await _bake(node,box,id,1.0)
	var source_hashes: Dictionary={}
	for path in ["fountain_water","town_details","town_visual","town_layout","school_facade_art","school_visual","city_lab_visual","workshop_art","exterior_painter","render_materials","school_layout","school_ateliers","school_atelier_art","school_atelier_scene","school_realism","school_surfaces","campus_visual","road_layout","storefront_art"]:
		source_hashes[path]=FileAccess.get_file_as_string("res://scripts/game/"+path+".gd").sha256_text()
	var file := FileAccess.open(Cache.DIRECTORY+"manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"forecourt_catalog_sha256":FileAccess.get_sha256("res://data/town_forecourts.json"),"town_render_manifest_sha256":FileAccess.get_sha256(Details.DIRECTORY+"manifest.json"),"school_render_manifest_sha256":FileAccess.get_sha256(Realism.DIRECTORY+"manifest.json"),"generator_inputs":source_hashes,"generator_sha256":FileAccess.get_file_as_string("res://tools/bake_static_art.gd").sha256_text(),"school_logo_sha256":FileAccess.get_sha256("res://assets/lycee/logo_louise_michel.jpg"),"sprites":records},"\t"));file.close()
	print("BAKE_STATIC : ",records.size()," sprites, 0 échec(s).")
	quit()

func _bake(node: Node2D, box: Rect2, id: String, scale_factor: float) -> void:
	var view := SubViewport.new()
	view.size=Vector2i(ceil(box.size.x*scale_factor),ceil(box.size.y*scale_factor))
	view.transparent_bg=true
	view.render_target_update_mode=SubViewport.UPDATE_ONCE
	node.scale=Vector2.ONE*scale_factor
	view.add_child(node)
	root.add_child(view)
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var picture := view.get_texture().get_image()
	# Trim transparent margins; preserve the world-space origin after cropping.
	var used := picture.get_used_rect()
	if used.has_area():
		picture=picture.get_region(used)
		box=Rect2(box.position+Vector2(used.position)/scale_factor,Vector2(used.size)/scale_factor)
	var filename := id+".png"
	var error := picture.save_png(Cache.DIRECTORY+filename)
	if error!=OK: push_error("Baking failed: "+filename);quit(1);return
	records[id]={"file":filename,"rect":[box.position.x,box.position.y,box.size.x,box.size.y],"scale":scale_factor}
	view.queue_free()
	await process_frame
