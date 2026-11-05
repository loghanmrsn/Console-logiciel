extends "res://tests/town_ui_tests.gd"
func _capture(id: String) -> void:
	if id.begins_with("civic_"): await super._capture(id)
func _finish() -> void:
	if not is_instance_valid(app): await super._finish();return
	app.demo._close_overlay()
	var doc: Dictionary=state.profile.duplicate(true)
	doc.progress.room_id="courtyard"
	doc.progress.checkpoint_id="from_first"
	state.commit_profile(saves.write_profile(doc).data)
	app._show_screen("game")
	await _frames(12)
	for spec in Town.forecourt_specs():
		_check(not _point_clear(spec.rect.get_center()),"Pied du décor solide : "+spec.kind)
	for building in Town.buildings():
		var door: Vector2=preload("res://scripts/game/school_facade_art.gd").entrance(building.rect) if building.school else Vector2(building.rect.get_center().x,building.rect.end.y)
		for x in [-34,0,34]:
			var ray := PhysicsRayQueryParameters2D.create(door+Vector2(x,15),door+Vector2(x,160),1)
			_check(app.demo.world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(),"Parvis dégagé : "+building.title)
	if app.demo.campus_map.expanded: app.demo.campus_map.toggle_map()
	app.demo.hotel_story.objective_panel.visible=false
	for view in [{"at":Vector2(2405,1135),"name":"poste"},{"at":Vector2(4505,1135),"name":"fleuriste"},{"at":Vector2(685,2435),"name":"cycles"},{"at":Vector2(2895,665),"name":"marche"},{"at":Vector2(3385,3855),"name":"musique"},{"at":Vector2(2930,2250),"name":"fontaine"}]:
		app.demo.world.player.position=view.at
		app.demo.world.player.reset_physics_interpolation()
		await _frames(10)
		await _capture("civic_"+view.name+"_challenge")
	var fountain: Node
	for node in app.demo.world.find_children("*","Node2D",true,false):
		if node.get_script()==load("res://scripts/game/town_visual.gd") and node.furniture_only.get("kind")=="fountain": fountain=node
	_check(fountain!=null,"Fontaine avec animation indépendante")
	if fountain!=null:
		var values: Dictionary=settings.committed.duplicate(true)
		values.reduce_motion=false
		_check(settings.apply_settings(values).ok,"Animations activées")
		var before: float=fountain.water_time
		var first := await _water_pixels()
		await _frames(10)
		_check(fountain.water_time>before,"L’eau avance pendant le jeu")
		if captures:
			var second := await _water_pixels()
			_check(first.get_data()!=second.get_data(),"Les pixels de l’eau changent réellement à l’écran")
			await _record_water()
		values.reduce_motion=true
		_check(settings.apply_settings(values).ok,"Animations réduites activées")
		before=fountain.water_time
		first=await _water_pixels()
		await _frames(10)
		_check(fountain.water_time==before,"Animations réduites respectées")
		if captures: _check(first.get_data()==(await _water_pixels()).get_data(),"Le rendu de l’eau reste fixe avec les animations réduites")
		values.reduce_motion=false
		settings.apply_settings(values)
		app.demo.request_pause()
		await _frames(3)
		before=fountain.water_time
		first=await _water_pixels()
		await _frames(10)
		_check(fountain.water_time==before,"La pause immobilise l’eau")
		if captures: _check(first.get_data()==(await _water_pixels()).get_data(),"Le rendu de l’eau reste fixe en pause")
		app.demo._close_overlay()
	await super._finish()

func _water_pixels() -> Image:
	if not captures: return null
	await RenderingServer.frame_post_draw
	var transform: Transform2D=app.demo.world.get_canvas_transform()
	var upper: Vector2=transform*(Town.FOUNTAIN-Vector2(112,175))
	var lower: Vector2=transform*(Town.FOUNTAIN+Vector2(112,102))
	var image: Image=app.demo._viewport.get_texture().get_image()
	var area := Rect2i(Vector2i(upper),Vector2i(lower-upper))
	_check(Rect2i(Vector2i.ZERO,image.get_size()).encloses(area),"La fontaine est entièrement visible")
	return image.get_region(area)

func _record_water() -> void:
	var directory := OS.get_environment("CIEL_WATER_FRAMES_DIR")
	if directory.is_empty(): return
	_check(DirAccess.make_dir_recursive_absolute(directory)==OK,"Dossier isolé des images d’eau")
	for index in range(20):
		var pixels := await _water_pixels()
		_check(pixels.save_png(directory.path_join("water_%02d.png" % index))==OK,"Image réelle de l’eau enregistrée")
		await create_timer(.1).timeout
