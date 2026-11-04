extends "res://tests/school_ateliers_ui_tests.gd"
## Same playable route in source, prior pack and delivered pack; no user saves.
var samples: Array[Dictionary] = []
var baseline := "--baseline" in OS.get_cmdline_user_args()
func _inspect(room: String) -> void:
	await super._inspect(room)
	if not baseline:
		var sprite: AnimatedSprite2D=app.demo.world.player.sprite
		var width := sprite.sprite_frames.get_frame_texture("down",0).get_width()
		_check(is_equal_approx(sprite.scale.x,.78*64.0/width*2.4),"Échelle du personnage adaptée au mobilier : "+room)
		_check(app.demo.world.player.get_child(0).shape.radius==10.0,"Pieds et collisions conservés : "+room)
	if captures: await _sample(room)
func _capture(id: String) -> void:
	# Collapse the existing HUD controls so the architectural evidence is visible.
	if is_instance_valid(app) and is_instance_valid(app.demo):
		if app.demo.campus_map.expanded: app.demo.campus_map.toggle_map()
		if app.demo.hotel_story.objectives_expanded: app.demo.hotel_story.toggle_objectives()
	await super._capture(id)
func _sample(zone: String) -> void:
	await _frames(30)
	var intervals: Array[float] = []
	for index in range(90):
		var start := Time.get_ticks_usec()
		await process_frame
		intervals.append(float(Time.get_ticks_usec()-start)/1000.0)
	intervals.sort()
	samples.append({"zone":zone,"samples":90,"viewport":str(root.size),"median_ms":intervals[45],"p95_ms":intervals[85],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
func _finish() -> void:
	if is_instance_valid(app) and captures:
		root.size=Vector2i(1280,720)
		app.demo._close_overlay()
		for zone in ["school_network_lab","school_stop","courtyard"]:
			var doc: Dictionary=state.profile.duplicate(true)
			doc.progress.room_id=zone
			doc.progress.checkpoint_id={"school_network_lab":"city_lab_entry","school_stop":"school_arrival","courtyard":"from_first"}[zone]
			var saved: Dictionary=saves.write_profile(doc)
			_check(saved.ok,"Point de vue de contrôle : "+zone)
			if not saved.ok: continue
			state.commit_profile(saved.data)
			app._show_screen("game")
			await _frames(12)
			app.demo._close_overlay()
			app.demo.world.player.position={"school_network_lab":Vector2(1220,780),"school_stop":Vector2(1000,610),"courtyard":Vector2(7850,1010)}[zone]
			app.demo.world.player.reset_physics_interpolation()
			if zone=="school_stop": app.demo.world.camera.zoom=Vector2(.58,.58)
			await _frames(10)
			await _capture(zone+"_realisme_challenge")
			await _sample(zone)
			if zone=="school_stop" and not baseline:
				var sprite: AnimatedSprite2D=app.demo.world.player.sprite
				_check(is_equal_approx(sprite.position.y,-23),"Échelle extérieure restaurée")
		var file := FileAccess.open(OS.get_environment("CIEL_CAPTURE_DIR").path_join("render_samples.json"),FileAccess.WRITE)
		_check(file!=null,"Mesures du rendu conservées")
		if file!=null: file.store_string(JSON.stringify(samples,"\t"));file.close()
	await super._finish()
