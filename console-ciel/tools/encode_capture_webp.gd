extends SceneTree
## Archive real viewport captures losslessly; keep original PNGs as evidence.
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var source := ""
	var destination := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--source="): source=arg.trim_prefix("--source=")
		if arg.begins_with("--destination="): destination=arg.trim_prefix("--destination=")
	if source.is_empty() or destination.is_empty() or source==destination: push_error("Distinct source and destination directories are required");quit(1);return
	DirAccess.make_dir_recursive_absolute(destination)
	var records: Array[Dictionary] = []
	for filename in DirAccess.get_files_at(source):
		if not filename.ends_with(".png"): continue
		var original := Image.load_from_file(source.path_join(filename))
		original.convert(Image.FORMAT_RGBA8)
		var output := destination.path_join(filename.get_basename()+".webp")
		if original.save_webp(output,false)!=OK: push_error("Capture encoding failed");quit(1);return
		var decoded := Image.load_from_file(output)
		decoded.convert(Image.FORMAT_RGBA8)
		if decoded.get_size()!=original.get_size() or decoded.get_data()!=original.get_data(): push_error("Capture pixels differ");quit(1);return
		records.append({"source":filename,"source_sha256":FileAccess.get_sha256(source.path_join(filename)),"file":output.get_file(),"sha256":FileAccess.get_sha256(output),"width":original.get_width(),"height":original.get_height(),"lossless_roundtrip_verified":true})
	var file := FileAccess.open(destination.path_join("encoding.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"\t"));file.close()
	print("CAPTURE_ENCODING : ",records.size()," exact pixel comparisons, 0 failure(s).")
	quit()
