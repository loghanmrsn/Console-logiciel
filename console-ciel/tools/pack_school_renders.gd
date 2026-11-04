extends SceneTree
## Lossless encoding only. Original Cycles renders are kept outside the project.
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var source := ""
	var directory := "res://assets/art/school_realism/"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--source="): source=arg.trim_prefix("--source=")
		if arg.begins_with("--destination="): directory=arg.trim_prefix("--destination=").trim_suffix("/")+"/"
	if source.is_empty(): push_error("Pass --source=/absolute/raw-render-directory");quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source.path_join("manifest.json")))
	for id in manifest.sprites:
		var entry: Dictionary=manifest.sprites[id]
		var path := source.path_join(str(entry.file))
		var original := Image.load_from_file(path)
		if original==null or original.is_empty(): push_error("Missing render: "+path);quit(1);return
		original.convert(Image.FORMAT_RGBA8)
		var filename := str(id)+".webp"
		if original.save_webp(directory+filename,false)!=OK: push_error("Encoding failed: "+filename);quit(1);return
		var decoded := Image.load_from_file(ProjectSettings.globalize_path(directory+filename))
		decoded.convert(Image.FORMAT_RGBA8)
		if decoded.get_size()!=original.get_size(): push_error("Size changed: "+filename);quit(1);return
		var a := original.get_data()
		var b := decoded.get_data()
		for offset in range(0,a.size(),4):
			# Transparent RGB is irrelevant; all alpha and visible RGB must be exact.
			if a[offset+3]!=b[offset+3] or (a[offset+3]>0 and (a[offset]!=b[offset] or a[offset+1]!=b[offset+1] or a[offset+2]!=b[offset+2])):
				push_error("Lossless round trip failed: "+filename);quit(1);return
		entry.source_png_sha256=FileAccess.get_sha256(path)
		entry.file=filename
		entry.sha256=FileAccess.get_sha256(directory+filename)
		entry.lossless_roundtrip_verified=true
	manifest.packing_generator_sha256=FileAccess.get_sha256("res://tools/pack_school_renders.gd")
	var file := FileAccess.open(directory+"manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t"));file.close()
	print("RENDER_PACK : ",manifest.sprites.size()," lossless round trips, 0 failure(s).")
	quit()
