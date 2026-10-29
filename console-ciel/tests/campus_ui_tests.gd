extends "res://tests/code_chapter_ui_tests.gd"
const Campus = preload("res://scripts/game/campus_layout.gd")
const Hotel = preload("res://scripts/game/hotel_layout.gd")
const FOURTH := ["firewall","ip_conflict","subnet_mask"]

func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	settings = root.get_node("SettingsService")
	state = root.get_node("AppState")
	investigation = root.get_node("InvestigationService")
	router = root.get_node("SceneRouter")
	controllers = root.get_node("ControllerService")
	controllers.debug_set_devices([0,1])
	test_root = "user://tests/campus_ui_%s_%s" % [OS.get_process_id(),Time.get_ticks_usec()]
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var values: Dictionary = settings.committed.duplicate(true)
	values.reduce_motion = true
	_check(settings.apply_settings(values).ok,"Réglages isolés")
	var made: Dictionary = profiles.create_profile("Explorateur CIEL")
	if not made.ok:
		_check(false,"Profil créé")
		await _finish()
		return
	profile_id = str(made.data.id)
	_check(profiles.start_game().ok,"Enquête démarrée")
	for chapter in [1,2,3,4]:
		if chapter > 1: _check(investigation.enter_chapter(chapter).ok,"Préparation étage")
		for id in [FIRST,SECOND,THIRD,FOURTH][chapter-1]:
			if chapter == 3: _check(investigation.submit_code(id,ANSWERS[id]).ok,"Code préparé")
			else: _complete_service(id)
	_check(investigation.enter_chapter(5).ok and investigation.enter_maze().ok,"Préparation labyrinthe")
	_check(investigation.terminal_login("admin","admin").ok and investigation.terminal_command("sudo","admin").ok,"Mystère réussi")
	_check(investigation.leave_maze().ok,"Retour palier")
	root.size = Vector2i(1280,720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(35)
	app._show_screen("home")
	await _activate("continue_game")
	if app.demo.overlay_kind == "conclusion": await _activate("conclusion_stay")
	await _capture("retour_palier_challenge")
	for chapter in [4,3,2,1]: await _travel(chapter)
	_check(app.demo.world.room_id == "room_01","Retour au premier niveau par les quatre descentes")
	await _walk_axis(KEY_UP,67)
	await _walk_axis(KEY_LEFT,280)
	await _walk_axis(KEY_DOWN,104)
	await _walk_axis(KEY_LEFT,405)
	_check(app.demo.world.target_id == "building_exit","La porte de sortie est accessible à pied depuis l’ascenseur")
	await _capture("premier_niveau_sortie_challenge")
	await _use_door("courtyard",true)
	_check(not app.demo.mission_tracker.visible and not app.demo.campus_map.visible,"Cour sans faux tableau de missions ni carte intérieure")
	await _capture("cour_immeuble_face_challenge")
	await _walk_axis(KEY_UP,550)
	_check(app.demo.world.target_id == "courtyard_second","Traversée réelle de la cour jusqu’à la porte d’en face")
	await _capture("facade_hotel_ciel_challenge")
	await _use_door("building_02",true)
	_check(app.demo.world.world_extent() == Campus.BUILDING_SIZE and app.demo.world.world_extent().x > 6*1000,"Le bâtiment est beaucoup plus grand que la première pièce")
	_check(app.demo.campus_map.visible and app.demo.campus_map.expanded,"Carte visible en haut à gauche à l’arrivée")
	_check(not app.demo.mission_tracker.visible and investigation.chapter_missions().is_empty(),"Aucune mission future inventée")
	await _capture("grand_batiment_entree_challenge")
	await _test_map_input()
	await _test_floor_plan()
	# The hotel replaces the provisional empty rooms. Walk around its fountain
	# and reception rather than walking through the new solid furniture.
	await _walk_axis(KEY_Q,500)
	await _walk_axis(KEY_UP,1850)
	_check(app.demo.world.player.position.y < 2200 and app.demo.world.camera.position.y < 2700,"La caméra suit la marche jusqu’au grand atrium")
	await _capture("grand_atrium_challenge")
	await _walk_axis(KEY_UP,450)
	await _walk_axis(KEY_Q,1840)
	_check(app.demo.world.player.position.distance_to(Vector2(860,1700)) < 60,"Le salon éloigné est accessible à pied par les galeries de l’hôtel")
	await _capture("salle_aile_ouest_challenge")
	await _test_compact_map()
	# Camera corners are a separate boundary check, after the full walked route.
	for point in [Vector2(100,100),Vector2(6300,4100),Vector2(3200,2100)]:
		app.demo.world.player.position = point
		await _physics_frames(3)
		var half: Vector2 = app.demo.world.get_viewport_rect().size/app.demo.world.camera.zoom*.5
		var camera_at: Vector2 = app.demo.world.camera.position
		_check(camera_at.x >= half.x-.01 and camera_at.y >= half.y-.01 and camera_at.x <= 6400-half.x+.01 and camera_at.y <= 4200-half.y+.01,"Caméra bornée au plan du grand bâtiment")
	await _resume_new_area()
	await _use_door("courtyard")
	_check(state.profile.progress.checkpoint_id == "from_second","Sortie par la porte du nouveau bâtiment")
	await _walk_axis(KEY_DOWN,550)
	_check(app.demo.world.target_id == "courtyard_first","Le premier immeuble reste accessible à pied")
	await _use_door("room_01")
	_check(state.profile.wallet.points == 650 and state.profile.rewarded_missions.size() == 13,"Exploration et allers-retours sans points supplémentaires")
	_check(app.demo.world.player.position.distance_to(Vector2(150,419)) < 15,"Retour dans la première pièce par la porte")
	await _finish()

func _approach(id: String) -> void:
	if app.demo.world.chapter_id == 5:
		app.demo.world.player.position = Vector2(158,405)
		await _physics_frames(3)
		return
	await super._approach(id)

func _use_door(destination: String, failure := false) -> void:
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "zone_door","La porte demande explicitement le passage")
	var before: Dictionary = state.profile.duplicate(true)
	var room: String = app.demo.world.room_id
	if failure:
		saves.simulate_write_failure = true
		await _activate("zone_go")
		saves.simulate_write_failure = false
		_check(app.demo.overlay_kind == "dialog" and state.profile == before and app.demo.world.room_id == room,"Échec de porte sans changer de monde ni de sauvegarde")
		await _activate("dialog_continue")
	await _activate("zone_go",true)
	await _physics_frames(5)
	_check(state.profile.progress.room_id == destination and app.demo.world.room_id == destination and app.demo.overlay_kind.is_empty(),"Porte enregistrée avant changement de monde : " + destination)

func _test_map_input() -> void:
	var panel = app.demo.campus_map
	var before: Vector2 = app.demo.world.player.position
	await _hold(KEY_RIGHT,25)
	_check(not panel.expanded and app.demo.world.player.position.distance_to(before) < 1,"Flèche droite maintenue : une seule fermeture, sans déplacement")
	await _key(KEY_RIGHT)
	_check(panel.expanded,"Nouvel appui : carte réaffichée")
	await _capture("carte_deployee_challenge")
	await _hold(KEY_D,16)
	_check(app.demo.world.player.position.x > before.x+35,"D permet de marcher à droite")
	await _hold(KEY_Q,16)
	var event := InputEventJoypadMotion.new()
	event.device = 1
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = 1
	before = app.demo.world.player.position
	Input.parse_input_event(event)
	await _physics_frames(10)
	event = event.duplicate(); event.axis_value = 0
	Input.parse_input_event(event)
	_check(app.demo.world.player.position.distance_to(before)<1,"La manette inactive ne pilote pas l’alias D/joystick")
	event = event.duplicate(); event.device = 0; event.axis_value = 1
	Input.parse_input_event(event)
	await _physics_frames(10)
	event = event.duplicate(); event.axis_value = 0
	Input.parse_input_event(event)
	await _physics_frames(2)
	_check(app.demo.world.player.position.x>before.x+20 and panel.expanded,"Le joystick actif marche vers la droite sans replier la carte")
	await _hold(KEY_Q,10)
	before = app.demo.world.player.position
	await _joy(JOY_BUTTON_DPAD_RIGHT)
	_check(app.demo.world.player.position.x > before.x and panel.expanded,"La croix droite marche sans changer la carte")
	await _joy(JOY_BUTTON_DPAD_LEFT)
	await _key(KEY_P)
	_check(not panel.visible,"Carte masquée derrière le menu pause")
	await _key(KEY_RIGHT)
	_check(panel.expanded,"La navigation de pause ne replie pas la carte")
	await _capture("pause_exploration_challenge")
	await _key(KEY_ESCAPE)
	await _frames(8)
	_check(panel.visible and panel.expanded,"Reprise avec le même état de carte")
	panel.toggle_button.pressed.emit()
	_check(not panel.expanded,"Le bouton tactile/souris replie aussi la carte")
	await _capture("carte_repliee_challenge")
	panel.toggle_button.pressed.emit()

func _test_floor_plan() -> void:
	_check(Hotel.rooms("building_02").size() >= 6,"Le grand hall, l’atrium, les salons, le local et les escaliers ont des espaces distincts")
	# Flood-fill the actual physics graph: rays stop links across thin walls.
	var reachable := {}
	var pending: Array[Vector2i] = [Vector2i(31,39)]
	reachable[pending[0]] = true
	var cursor := 0
	while cursor < pending.size():
		var cell := pending[cursor]
		cursor += 1
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = cell+offset
			if reachable.has(next) or next.x<1 or next.x>62 or next.y<1 or next.y>40: continue
			var at := Vector2(next)*100+Vector2(50,50)
			if not _point_clear(at): continue
			var ray := PhysicsRayQueryParameters2D.create(Vector2(cell)*100+Vector2(50,50),at,1)
			if not app.demo.world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
			reachable[next] = true
			pending.append(next)
	for room in Hotel.rooms("building_02"):
		var connected := false
		for cell in reachable:
			if room.has_point(Vector2(cell)*100+Vector2(50,50)):
				connected = true
				break
		_check(connected,"Le plan physique relie les espaces de l’hôtel à son entrée : " + str(room))
	for target in Hotel.interactions("building_02"):
		var connected := false
		for cell in reachable:
			if (Vector2(cell)*100+Vector2(50,50)).distance_to(target.at) < target.radius:
				connected = true
				break
		_check(connected,"Les passages et la réception restent accessibles : " + str(target.id))
	_check(reachable.size()>1800,"Le grand bâtiment possède un vaste espace réellement connecté")

func _test_compact_map() -> void:
	root.size = Vector2i(800,480)
	var values: Dictionary = settings.committed.duplicate(true)
	values.large_text = true
	values.reduce_transparency = true
	_check(settings.apply_settings(values).ok,"Grand texte et opacité au format compact")
	await _frames(15)
	var map_rect: Rect2 = app.demo.campus_map.get_global_rect()
	_check(map_rect.position.x>=0 and map_rect.position.y>=0 and map_rect.end.x<=800 and map_rect.end.y<=480,"Carte lisible et dans l’écran 800 × 480")
	_check(app.demo.campus_map.canvas.size.x>=200,"Plan conservé à une taille utile")
	await _capture("carte_compacte_challenge")
	values.large_text = false
	_check(settings.apply_settings(values).ok,"Taille habituelle restaurée")
	root.size = Vector2i(1280,720)
	await _frames(12)

func _resume_new_area() -> void:
	await _key(KEY_P)
	await _activate("pause_menu")
	await _frames(10)
	_check(app.screen == "home","Retour au menu")
	_check("Hôtel" in app._investigation_progress_text() and not "chapitre 0" in app._investigation_progress_text().to_lower(),"L’accueil indique l’hôtel, sans faux chapitre zéro")
	await _activate("continue_game")
	await _frames(10)
	_check(app.demo.world.room_id == "building_02" and app.demo.overlay_kind.is_empty(),"Continuer reprend le nouveau bâtiment sans bilan du chapitre 5")
	_check(app.demo.world.player.position.distance_to(Vector2(3200,4000))<10,"Reprise sûre au seuil d’entrée du bâtiment")
	await _capture("reprise_nouveau_batiment_challenge")
