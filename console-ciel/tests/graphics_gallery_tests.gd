extends "res://tests/school_ui_tests.gd"
## Matched rendered scenes and a bounded host-cost sample, with isolated saves.
class CharacterSheet extends Control:
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO,size),Color("e9eee8"))
		draw_string(ThemeDB.fallback_font,Vector2(100,50),"PERSONNAGE · DIRECTIONS ET POSES",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("344e59"))
		var directions := ["down","left","right","up"]
		for row in range(4):
			draw_string(ThemeDB.fallback_font,Vector2(100,130+row*130),directions[row],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("344e59"))
			for pose in range(3):
				var at := Vector2(250+pose*220,72+row*130)
				var texture: Texture2D=load("res://assets/art/character/%s_%d.svg" % [directions[row],pose])
				draw_line(at+Vector2(-12,94),at+Vector2(110,94),Color("b6c7bd"),1,true)
				draw_texture_rect(texture,Rect2(at,Vector2(96,108)),false)

var render_samples: Array[Dictionary] = []

func _run() -> void:
	await process_frame
	saves=root.get_node("SaveService")
	profiles=root.get_node("ProfileService")
	settings=root.get_node("SettingsService")
	state=root.get_node("AppState")
	investigation=root.get_node("InvestigationService")
	router=root.get_node("SceneRouter")
	controllers=root.get_node("ControllerService")
	controllers.debug_set_devices([0])
	test_root="user://tests/graphics_%s" % Time.get_ticks_usec()
	saves.root_path=test_root
	settings.storage_root=test_root
	state.clear_profile()
	captures="--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	_check(profiles.use_dev_profile().ok,"Profil de galerie isolé")
	var original: Dictionary=state.profile.duplicate(true)
	app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(30)
	for view in ["home","shop","profiles","settings"]:
		app._show_screen(view)
		await _frames(8)
		_check(app.screen==view,"Écran de console disponible : "+view)
		await _capture("console_"+view+"_challenge")
	var zones := ["room_01","room_02","room_03","room_04","room_05","maze_05","building_02","hotel_it","hotel_room_206","hotel_breakfast","ctf_lobby","school_workshop","school_network_lab","courtyard"]
	for zone in zones:
		var doc: Dictionary=original.duplicate(true)
		doc.progress.room_id=zone
		if zone=="ctf_lobby": doc.progress.hotel.morning_stage=8
		if zone in ["school_workshop","school_network_lab"]: doc.progress.school_wires=saves.COFFEE_WIRES.duplicate()
		doc.progress.active_mission=""
		var checkpoint := "entrance" if zone=="room_01" else ("maze_entry" if zone=="maze_05" else "elevator")
		if zone in saves.HOTEL_ROOMS:
			for key in saves.HOTEL_CHECKPOINTS:
				if saves.HOTEL_CHECKPOINTS[key]==zone: checkpoint=key; break
		if zone=="courtyard": checkpoint="from_first"
		doc.progress.checkpoint_id=checkpoint
		var saved: Dictionary=saves.write_profile(doc)
		_check(saved.ok,"Fixture graphique valide : "+zone+str(saved.get("error","")))
		if not saved.ok: continue
		state.commit_profile(saved.data)
		app._show_screen("game")
		await _frames(12)
		app.demo._close_overlay()
		await _frames(4)
		_check(app.demo.overlay_kind.is_empty(),"Vue dégagée pour la comparaison : "+zone)
		_check(app.demo.world.room_id==zone,"Scène graphique chargée : "+zone)
		if zone=="courtyard":
			app.demo.world.player.position=Vector2(2730,1240)
			app.demo.world.player.reset_physics_interpolation()
		if zone=="building_02":
			app.demo.world.player.position=Vector2(3200,3650)
			app.demo.world.player.reset_physics_interpolation()
		if zone=="school_network_lab":
			app.demo.world.player.position=Vector2(1220,780)
			app.demo.world.player.reset_physics_interpolation()
		if zone=="school_workshop":
			app.demo.world.player.position=Vector2(820,600)
			app.demo.world.player.reset_physics_interpolation()
		if zone=="hotel_room_206":
			app.demo.world.player.position=Vector2(600,600)
			app.demo.world.player.reset_physics_interpolation()
		await _frames(6)
		await _capture("jeu_"+zone+"_challenge")
		if captures and zone in ["room_01","building_02","school_network_lab","courtyard"]: await _sample_render(zone)
	if captures:
		var sheet := CharacterSheet.new()
		sheet.size=Vector2(root.size)
		sheet.z_index=100
		root.add_child(sheet)
		await _frames(4)
		await _capture("personnage_directions_challenge")
		sheet.queue_free()
		await _frames(4)
	app._show_screen("home")
	var preferences: Dictionary=settings.committed.duplicate(true)
	preferences.appearance_style="nuit"
	preferences.large_text=true
	preferences.reduce_transparency=true
	_check(settings.apply_settings(preferences).ok,"Interface sombre et grand texte")
	root.size=Vector2i(800,480)
	await _frames(12)
	await _capture("console_compact_nuit_challenge")
	if captures:
		var folder := OS.get_environment("CIEL_CAPTURE_DIR")
		var file := FileAccess.open(folder.path_join("host_render_samples.json"),FileAccess.WRITE)
		_check(file!=null,"Rapport de coût du rendu ouvert")
		if file!=null: file.store_string(JSON.stringify(render_samples,"\t")); file.close()
	await _finish()

func _sample_render(zone: String) -> void:
	await _frames(30)
	var durations: Array[float] = []
	for index in range(90):
		var start := Time.get_ticks_usec()
		await process_frame
		durations.append(float(Time.get_ticks_usec()-start)/1000)
	durations.sort()
	render_samples.append({"zone":zone,"viewport":str(root.size),"samples":durations.size(),"frame_interval_median_ms":durations[45],"frame_interval_p95_ms":durations[85],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"hardware":"Linux x86_64 X11 llvmpipe; not Raspberry Pi"})
