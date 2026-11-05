extends SceneTree
## Repeatable CPU microbenchmarks: real profile handlers and target selection.
## Run with isolated XDG folders; timings describe this host, not target hardware.
func _initialize() -> void:
	Engine.max_fps=0
	_run.call_deferred()
func frames(n: int) -> void:
	for i in range(n): await process_frame
func median(values: Array) -> float:
	values.sort()
	return values[values.size()/2]
func _run() -> void:
	await process_frame
	var saves=root.get_node("SaveService")
	saves.root_path="user://tests/benchmark_%s"%Time.get_ticks_usec()
	root.get_node("SettingsService").storage_root=saves.root_path
	var app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await frames(25)
	var created=root.get_node("ProfileService").use_dev_profile()
	assert(created.ok)
	app._show_screen("home")
	await frames(12)
	var transaction_samples=[]
	for batch in range(7):
		var start=Time.get_ticks_usec()
		for i in range(40): app._profile_updated(root.get_node("AppState").profile)
		transaction_samples.append((Time.get_ticks_usec()-start)/40.0)
	app._show_screen("game")
	await frames(15)
	var world=app.demo.world
	world.restore_progress({"room_id":"courtyard","checkpoint_id":"from_first","completed_missions":["lighting","lock","computer"]})
	world.player.position=Vector2(900,980)
	await frames(8)
	var target_samples=[]
	for batch in range(7):
		var start=Time.get_ticks_usec()
		for i in range(500): world._update_target()
		target_samples.append((Time.get_ticks_usec()-start)/500.0)
	var report={"version":ProjectSettings.get_setting("application/config/version"),"profile_handler_median_us":median(transaction_samples),"target_selection_median_us":median(target_samples),"profile_samples_us":transaction_samples,"target_samples_us":target_samples,"host":"Linux x86_64; CPU microbenchmarks; no hardware FPS claim","renderer":DisplayServer.get_name(),"world_targets":world._targets.size(),"same_profile_repeats_per_batch":40,"target_repeats_per_batch":500}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			var f=FileAccess.open(arg.trim_prefix("--output="),FileAccess.WRITE)
			f.store_string(JSON.stringify(report,"\t"))
	print("INTERACTION_BENCHMARK ",JSON.stringify(report))
	app.free()
	quit()
