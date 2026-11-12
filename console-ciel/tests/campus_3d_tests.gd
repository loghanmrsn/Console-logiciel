extends "res://tests/profile_editor_tests.gd"

func _initialize() -> void:
	Engine.max_fps = 60
	super._initialize()

func _run() -> void:
	await process_frame
	saves=root.get_node("SaveService");profiles=root.get_node("ProfileService");state=root.get_node("AppState")
	settings=root.get_node("SettingsService");router=root.get_node("SceneRouter");controllers=root.get_node("ControllerService")
	controllers.debug_set_devices([0])
	test_root="user://tests/campus3d_%s" % Time.get_ticks_usec()
	saves.root_path=test_root;settings.storage_root=test_root
	captures="--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	root.size=Vector2i(1280,720)
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app)
	await _frames(30)
	_check(profiles.use_dev_profile().ok,"Profil de test isolé")
	var before: Dictionary=state.profile.duplicate(true)
	app._show_screen("home");await _frames(8)
	await _activate("home_campus_3d",true)
	await _frames(20)
	var panel=_find("campus_3d_panel")
	_check(panel!=null and app.screen=="campus3d","Parcours 3D accessible depuis le menu à la manette")
	if panel==null:await _finish();return
	var world=panel.world
	_check(world.camera.current and world.actor.model.skeleton!=null,"Caméra et avatar articulé 3D actifs")
	_check(world.actor.model._appearance==root.get_node("CharacterService").current().appearance,"Apparence réellement reprise depuis le profil")
	_check(is_equal_approx(world.actor.collider.shape.height,1.70) and is_equal_approx(world.actor.collider.shape.radius,.23),"Gabarit constant")
	_check(world.water!=null,"Eau animée du bassin chargée")
	for id in world.manifest.zones:
		_check(int(world.manifest.zones[id].triangles)<100000,"Budget géométrique du décor : "+id)
	await _capture("parvis_3d")
	var origin: Vector3=world.actor.position
	var key=InputEventKey.new();key.keycode=KEY_Z;key.pressed=true;Input.parse_input_event(key)
	for i in range(35):await physics_frame
	key.pressed=false;Input.parse_input_event(key)
	_check(world.actor.position.z<origin.z-.8,"Déplacement au clavier vers le lycée")
	await _frames(5)
	_check(absf(world.actor.rotation.x)<.001 and absf(world.actor.model.rotation.z)<.001,"Le corps reste droit pendant la marche")
	world.teleport(Vector3(6,.05,-3.4))
	Input.action_press("game_up")
	for i in range(70):await physics_frame
	Input.action_release("game_up")
	_check(world.actor.position.z> -4.80,"La façade empêche de traverser le bâtiment")
	world.teleport(Vector3(0,.05,-2.9));await create_timer(.25).timeout
	world.interact();await _frames(4)
	_check(is_instance_valid(panel.dialog),"Entrée du lycée interactive à portée")
	await _activate("campus_choice_0",true);await _frames(10)
	_check(world.zone=="reception","La porte mène à l’accueil")
	world.teleport(Vector3(-2,.05,1.0));await create_timer(.25).timeout
	await _capture("accueil_surveillante_3d")
	world.interact();await _frames(3)
	_check(is_instance_valid(panel.dialog) and _find("campus_choice_1")!=null,"Surveillante : accompagner ou refuser")
	var stopped: Vector3=world.actor.position
	Input.action_press("game_right");await create_timer(.25).timeout;Input.action_release("game_right")
	_check(world.actor.position.is_equal_approx(stopped),"Conversation : déplacements suspendus")
	await _capture("dialogue_surveillante_3d")
	await _activate("campus_choice_1");await _frames(5)
	_check(world.zone=="reception" and not world.locked,"Refuser conserve la position et rend le contrôle")
	await create_timer(.25).timeout;world.interact();await _frames(3)
	# Observe the real button press immediately; frame-count UI helpers can take
	# longer than the whole trip under a slow software renderer.
	var escort_button=_find("campus_choice_0")
	escort_button.grab_focus()
	await create_timer(.25).timeout
	var confirm=InputEventJoypadButton.new();confirm.device=0;confirm.button_index=JOY_BUTTON_A;confirm.pressed=true
	Input.parse_input_event(confirm)
	await process_frame
	confirm.pressed=false;Input.parse_input_event(confirm)
	await process_frame
	_check(world.escorting and world.actor.position.y>=.0,"Les deux personnages empruntent l’escalier")
	var frame_clock={"previous":Time.get_ticks_msec(),"gap":0.0}
	var measure_frame=func():
		var now=Time.get_ticks_msec()
		frame_clock.gap=maxf(frame_clock.gap,(now-frame_clock.previous)/1000.0)
		frame_clock.previous=now
	process_frame.connect(measure_frame)
	await _capture("escalier_droit_3d")
	await create_timer(2.9).timeout
	process_frame.disconnect(measure_frame)
	_check(world.zone=="workshop" and not world.locked and not world.escorting,"Arrivée dans l’atelier et contrôle restauré")
	_check(world.last_escort_seconds>=2.7 and world.last_escort_seconds<2.8+frame_clock.gap,"Trajet animé de 2,7 secondes, terminé à la première image disponible")
	print("ESCORT_TIMING seconds=%.3f longest_frame=%.3f" % [world.last_escort_seconds,frame_clock.gap])
	await _capture("atelier_ciel_3d")
	world.teleport(Vector3(-3,.05,2.0));await create_timer(.25).timeout
	world.interact();await _frames(3);await _activate("campus_choice_0")
	_check(panel.display_checked,"Diagnostic du poste informatique interactif")
	await _activate("campus_choice_0")
	world.teleport(Vector3(5.8,.05,-2.2));await create_timer(.25).timeout
	world.interact();await _frames(3);await _activate("campus_choice_1")
	_check(not panel.link_checked,"Une réponse erronée ne valide pas la liaison")
	await _activate("campus_choice_0");await create_timer(.25).timeout
	world.interact();await _frames(3);await _activate("campus_choice_0")
	_check(panel.link_checked,"Bonne réponse réseau validée")
	await _activate("campus_choice_0")
	world.teleport(Vector3(0,.05,5.5));await create_timer(.25).timeout
	world.interact();await _frames(3);await _activate("campus_choice_0")
	_check(world.zone=="reception","Retour à l’accueil depuis l’atelier")
	settings.current.reduce_motion=true
	panel._escort();await _frames(4)
	_check(world.zone=="workshop" and not world.escorting,"Réduction des animations : trajet immédiat")
	settings.current.reduce_motion=false
	panel.handle_back();await _frames(4)
	_check(is_instance_valid(panel.dialog) and world.process_mode==Node.PROCESS_MODE_DISABLED,"Pause complète du parcours")
	root.size=Vector2i(800,480);await _frames(10)
	_check(root.get_visible_rect().encloses(panel.dialog.get_global_rect()),"Dialogue visible sur écran 800 × 480")
	await _capture("pause_compacte_3d")
	await _activate("campus_choice_0",true)
	world.load_zone("square");world.teleport(Vector3(0,.05,14.2));await create_timer(.25).timeout
	world.interact();await _frames(3);await _activate("campus_choice_0",true)
	_check(not world.water_running and world.water.get_shader_parameter("flowing")==false,"Pompe de fontaine commandable")
	_check(world.streams!=null and not world.streams.visible,"Les jets disparaissent lorsque la pompe est arrêtée")
	root.size=Vector2i(1280,720);await _frames(10)
	world.toggle_water();await _capture("fontaine_3d")
	# Real stick events, not a direct call to the movement implementation.
	world.teleport(Vector3(4,.05,12));await create_timer(.25).timeout
	origin=world.actor.position
	var stick=InputEventJoypadMotion.new();stick.device=0;stick.axis=JOY_AXIS_LEFT_X;stick.axis_value=.8;Input.parse_input_event(stick)
	for i in range(25):await physics_frame
	stick.axis_value=0;Input.parse_input_event(stick)
	_check(world.actor.position.x>origin.x+.4,"Joystick simulé : déplacement réel en 3D")
	await _frames(5)
	_check(Vector2(world.actor.velocity.x,world.actor.velocity.z).length()<.01,"Arrêt sans glissement après relâchement")
	_check(state.profile==before,"Exploration et exercices sans corruption du profil ni débit")
	panel.handle_back();await _frames(4);await _activate("campus_choice_1",true)
	_check(app.screen=="home","Retour au menu par la manette")
	await _finish()

func _capture(filename: String) -> void:
	if not captures:return
	await _frames(4)
	await RenderingServer.frame_post_draw
	var folder=OS.get_environment("CIEL_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(folder)
	var rendered=root.get_texture().get_image()
	_check(rendered!=null and not rendered.is_empty(),"Image native : "+filename)
	rendered.save_png(folder.path_join(filename+".png"))
