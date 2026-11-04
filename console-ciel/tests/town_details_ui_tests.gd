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
	for spec in Town.props():
		if spec.kind in ["flag_fr","flag_eu","book_box","media_kiosk"]:
			_check(not _point_clear(spec.rect.get_center()),"Pied du décor solide : "+spec.kind)
	for building in Town.buildings():
		if building.title not in ["Mairie","Bibliothèque","Médiathèque"]: continue
		var door := Vector2(building.rect.get_center().x,building.rect.end.y)
		for x in [-45,0,45]:
			var ray := PhysicsRayQueryParameters2D.create(door+Vector2(x,15),door+Vector2(x,160),1)
			_check(app.demo.world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(),"Parvis dégagé : "+building.title)
	if app.demo.campus_map.expanded: app.demo.campus_map.toggle_map()
	app.demo.hotel_story.objective_panel.visible=false
	for view in [{"at":Vector2(4505,730),"name":"mairie"},{"at":Vector2(4995,730),"name":"mediatheque"},{"at":Vector2(5485,730),"name":"bibliotheque"},{"at":Vector2(2930,2250),"name":"fontaine"}]:
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
		await _frames(10)
		_check(fountain.water_time>before,"L’eau avance pendant le jeu")
		values.reduce_motion=true
		_check(settings.apply_settings(values).ok,"Animations réduites activées")
		before=fountain.water_time
		await _frames(10)
		_check(fountain.water_time==before,"Animations réduites respectées")
		values.reduce_motion=false
		settings.apply_settings(values)
		app.demo.request_pause()
		await _frames(3)
		before=fountain.water_time
		await _frames(10)
		_check(fountain.water_time==before,"La pause immobilise l’eau")
		app.demo._close_overlay()
	await super._finish()
