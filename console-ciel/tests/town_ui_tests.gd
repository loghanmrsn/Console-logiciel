extends "res://tests/school_ui_tests.gd"
const Town = preload("res://scripts/game/town_layout.gd")
const Campus = preload("res://scripts/game/campus_layout.gd")
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
	test_root="user://tests/town_%s" % Time.get_ticks_usec()
	saves.root_path=test_root
	settings.storage_root=test_root
	state.clear_profile()
	captures="--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	_check(profiles.use_dev_profile().ok,"Profil isolé")
	profile_id=state.profile.id
	var doc: Dictionary=state.profile.duplicate(true)
	doc.progress.room_id="courtyard"
	doc.progress.checkpoint_id="from_first"
	doc.wallet.points=100
	state.commit_profile(saves.write_profile(doc).data)
	app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(25)
	app._show_screen("home")
	await _frames(4)
	await _activate("continue_game")
	_check(Town.buildings().size()==38,"40 bâtiments avec les deux lieux d’origine")
	_check(app.demo.world.world_extent()==Town.SIZE,"Grande ville chargée")
	_check(app.demo.campus_map.visible,"Carte de la ville visible")
	await _verify_streets()
	for building in Town.buildings():
		_check(not _point_clear(building.rect.get_center()),"Façade solide : "+building.title)
		for road in Town.roads(): _check(not building.rect.intersects(road),"Bâtiment hors chaussée")
	_check(not _point_clear(Town.FOUNTAIN),"Bassin de fontaine solide")

	var terrace_count := 0
	for prop in Town.props():
		if prop.kind in ["cafe_table","cafe_chair","menu_board"]:
			_check(not _point_clear(prop.rect.get_center()),"Mobilier de terrasse solide : "+prop.kind)
			if prop.kind=="cafe_table": terrace_count+=1
	_check(terrace_count==10,"Deux tables devant chacun des cinq cafés, bar et restaurants")
	for building in Town.buildings():
		if not preload("res://scripts/game/storefront_art.gd").is_food(building.title): continue
		var door := Vector2(building.rect.get_center().x,building.rect.end.y)
		for side in [-18,0,18]:
			var ray := PhysicsRayQueryParameters2D.create(door+Vector2(side,20),door+Vector2(side,150),1)
			_check(app.demo.world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(),"Accès à la porte préservé : "+building.title)

	var ambient=app.demo.world.town_ambient
	_check(ambient.people.size()==12,"Douze passants sans interaction")
	var start: Vector2=ambient.people[0].body.position
	await _physics_frames(20)
	_check(ambient.people[0].body.position!=start,"Passants en mouvement")
	for person in ambient.people: _check(_point_clear(person.body.position),"Trottoir libre pour les passants")
	for route in Town.pedestrian_routes():
		for index in range(route.size()):
			var ray := PhysicsRayQueryParameters2D.create(route[index],route[(index+1)%route.size()],1)
			_check(app.demo.world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(),"Parcours des passants sans obstacle")
	app.demo.request_pause()
	await _frames(4)
	start=ambient.people[0].body.position
	await _physics_frames(15)
	_check(ambient.people[0].body.position==start,"La pause immobilise les passants")
	app.demo._close_overlay()
	await _key(KEY_RIGHT)
	for spec in [{"at":Vector2(1690,990),"image":"ville_raccord_centre_challenge"},{"at":Vector2(380,1050),"image":"ville_boucle_ouest_challenge"},{"at":Vector2(2180,380),"image":"ville_boucle_nord_challenge"},{"at":Vector2(6210,380),"image":"ville_boucle_nord_est_challenge"},{"at":Vector2(6210,4670),"image":"ville_boucle_sud_est_challenge"},{"at":Vector2(380,4670),"image":"ville_boucle_sud_ouest_challenge"},{"at":Vector2(4150,1670),"image":"ville_intersection_nord_challenge"},{"at":Vector2(4170,4330),"image":"ville_intersection_sud_challenge"},{"at":Vector2(2730,1240),"image":"ville_commerces_challenge"},{"at":Vector2(2920,2290),"image":"ville_parc_fontaine_challenge"},{"at":Vector2(4150,2920),"image":"ville_rond_point_challenge"}]:
		app.demo.world.player.position=spec.at
		app.demo.world.player.reset_physics_interpolation()
		await _physics_frames(4)
		await _frames(5)
		await _capture(spec.image)
	if captures:
		var zoom: Vector2=app.demo.world.camera.zoom
		app.demo.world.camera.zoom=Vector2(.105,.105)
		app.demo.world._update_camera_position()
		await _frames(8)
		await _capture("ville_vue_ensemble_challenge")
		app.demo.world.camera.zoom=zoom
		app.demo.world._update_camera_position()
	await _approach("campus_bus")
	await _key(KEY_SPACE)
	_check(_find("hotel_bus_board")!=null and _find("school_bus_board")!=null,"Choix des destinations")
	await _capture("ville_arret_billet_challenge")
	var before: Dictionary=state.profile.duplicate(true)
	saves.simulate_write_failure=true
	await _activate("school_bus_board")
	_check(app.demo.overlay_kind=="hotel_error" and state.profile==before,"Pas de débit quand l’écriture échoue")
	saves.simulate_write_failure=false
	app.demo.hotel_story._show_bus()
	await _activate("school_bus_board")
	_check(app.demo.overlay_kind=="bus_ride" and state.profile.wallet.points==90,"Montée : billet débité une fois")
	var ride=app.demo.modal_content.get_node("bus_ride_panel")
	_check(ride.elapsed>0,"L’animation avance pendant le rendu")
	ride.set_process(false)
	ride.elapsed=1.5
	ride.advance(0)
	await _capture("bus_paiement_challenge")
	ride.elapsed=2.5
	ride.advance(0)
	_check("En attente de destination" in str(_find("bus_ride_status").text),"Attente assise avec message")
	await _capture("bus_attente_assise_challenge")
	root.size=Vector2i(800,480)
	await _frames(8)
	await _capture("bus_attente_compact_challenge")
	_check(_find("bus_ride_finish").is_visible_in_tree(),"Sortie de l’animation disponible en 800 × 480")
	var skip_rect: Rect2=_find("bus_ride_finish").get_global_rect()
	_check(Rect2(Vector2.ZERO,root.size).encloses(skip_rect),"Bouton du bus entièrement dans la petite fenêtre")
	_check(ride.cabin.size.y==210,"Intérieur adapté à une fenêtre compacte")
	root.size=Vector2i(1280,720)
	await _frames(5)
	ride.elapsed=5.1
	ride.advance(0)
	await _capture("bus_descente_challenge")
	await _activate("bus_ride_finish")
	_check(app.demo.overlay_kind.is_empty() and app.demo.world.room_id=="school_stop","Descente au bon arrêt")
	_check(profiles.select_profile(profile_id).ok and state.profile.wallet.points==90,"Rechargement après billet sans nouveau débit")
	await _approach("school_bus")
	await _key(KEY_SPACE)
	await _activate("ctf_bus_return")
	await _key(KEY_ESCAPE)
	_check(state.profile.wallet.points==80 and state.profile.bus_travel.rides==2,"Échap termine le trajet payé ; deux billets au total")
	_check(state.profile.progress.room_id=="courtyard","Retour près des bâtiments d’origine")
	await _approach("town_walk_ctf")
	await _key(KEY_SPACE)
	await _activate("town_walk_go")
	_check(state.profile.progress.room_id=="ctf_bus_stop" and state.profile.wallet.points==80,"Accès à pied gratuit depuis la façade")
	await _finish()

func _verify_streets() -> void:
	var streets := Town.roads()
	var visited: Array[int] = [0]
	var pending: Array[int] = [0]
	while not pending.is_empty():
		var index := pending.pop_back() as int
		for other in range(streets.size()):
			if other not in visited and streets[index].intersects(streets[other]):
				visited.append(other)
				pending.append(other)
	_check(visited.size()==streets.size(),"Toutes les rues appartiennent au même réseau connecté")
	for index in range(streets.size()):
		var street := streets[index]
		var horizontal := street.size.x>street.size.y
		for tip in [street.get_center()-Vector2(street.size.x*.5-1,0),street.get_center()+Vector2(street.size.x*.5-1,0)] if horizontal else [street.get_center()-Vector2(0,street.size.y*.5-1),street.get_center()+Vector2(0,street.size.y*.5-1)]:
			var joined := false
			for other in range(streets.size()):
				if other!=index and streets[other].has_point(tip): joined=true
			_check(joined,"Chaque extrémité rejoint une autre rue : "+str(tip))
	for lane in [[Vector2(174,620),Vector2(174,4570)],[Vector2(6010,120),Vector2(6010,4570)],[Vector2(1840,170),Vector2(6080,170)],[Vector2(104,4500),Vector2(6080,4500)]]:
		var ray := PhysicsRayQueryParameters2D.create(lane[0],lane[1],1)
		_check(app.demo.world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(),"Boulevard sans bâtiment, jardin ou barrière sur la chaussée")
	for x in range(1650,2071,10): _check(Town.on_road(Vector2(x,700)),"Rue continue entre le centre et l’avenue")
	for y in [625,700,790]:
		var ray := PhysicsRayQueryParameters2D.create(Vector2(1690,y),Vector2(2130,y),1)
		_check(app.demo.world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(),"Raccord sans obstacle caché")
	for crossing in Town.crosswalks():
		_check(Town.on_road(crossing.position+Vector2.ONE) and Town.on_road(crossing.end-Vector2.ONE),"Passage piéton posé sur la chaussée")
	if not captures: return
	# Render the street layer alone to detect pavement seams in the actual
	# framebuffer, independently of the layout graph and moving vehicles.
	var view := SubViewport.new()
	view.size=Vector2i(Town.SIZE*.2)
	view.render_target_update_mode=SubViewport.UPDATE_ONCE
	var paint := preload("res://scripts/game/town_streets.gd").new()
	paint.scale=Vector2(.2,.2)
	view.add_child(paint)
	root.add_child(view)
	await _frames(5)
	var image := view.get_texture().get_image()
	_check(image!=null and not image.is_empty(),"Rendu des routes disponible")
	if image!=null and not image.is_empty():
		var samples: Array[Vector2] = [Vector2(1768,705),Vector2(1820,700)]
		for junction in Town.intersections():
			var center := junction.get_center()
			for point in [Vector2(center.x-35,junction.position.y-20),Vector2(center.x-35,junction.end.y+20),Vector2(junction.position.x-20,center.y-35),Vector2(junction.end.x+20,center.y-35)]:
				if Town.on_road(point): samples.append(point)
		for point in samples:
			var color := image.get_pixelv(Vector2i(point*.2))
			_check(Vector3(color.r,color.g,color.b).distance_to(Vector3(84.0/255,98.0/255,105.0/255))<.025,"Asphalte sans trou ni trottoir au raccord : "+str(point))
	view.queue_free()

func _approach(id: String) -> void:
	var specs: Array=Campus.interactions("courtyard") if app.demo.world.room_id=="courtyard" else preload("res://scripts/game/hotel_layout.gd").interactions(app.demo.world.room_id)
	for spec in specs:
		if spec.id!=id: continue
		app.demo.world.player.position=spec.at
		app.demo.world.player.reset_physics_interpolation()
		await _physics_frames(4)
		await _frames(4)
		_check(app.demo.world.target_id==id,"Cible accessible : "+id)
		return
	_check(false,"Cible absente : "+id)
