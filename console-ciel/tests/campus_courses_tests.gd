extends "res://tests/profile_editor_tests.gd"
const Course=preload("res://scripts/campus3d/course_catalog.gd")

func _initialize() -> void:
	Engine.max_fps=60
	super._initialize()

func _run() -> void:
	await process_frame
	saves=root.get_node("SaveService");profiles=root.get_node("ProfileService");state=root.get_node("AppState")
	settings=root.get_node("SettingsService");router=root.get_node("SceneRouter");controllers=root.get_node("ControllerService")
	controllers.debug_set_devices([0]);test_root="user://tests/campus_courses_%s" % Time.get_ticks_usec()
	saves.root_path=test_root;settings.storage_root=test_root
	captures="--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	root.size=Vector2i(1280,720)
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await _frames(25)
	_check(profiles.use_dev_profile().ok,"Profil isolé")
	var original=state.profile.duplicate(true)
	_check(Course.current(state.profile).completed.is_empty() and not state.profile.progress.has("campus3d"),"Ancien profil sans ajout à la simple lecture")
	_check(not Course.answer(state,saves,"cyber_incident",0).ok and state.profile==original,"Impossible de sauter les étapes")
	for value in [null,{}, {"version":2,"completed":[]},{"version":true,"completed":[]},{"version":1,"completed":["net_address"]},{"version":1,"completed":["net_cable","net_cable"]}]:
		var corrupt=original.duplicate(true);corrupt.progress.campus3d=value
		_check(not saves.validate_profile(corrupt).ok,"Progression malformée refusée")
	app._show_screen("campus3d");await _frames(15)
	var panel=_find("campus_3d_panel");var world=panel.world
	world.load_zone("corridor");await _frames(8)
	_check(world.scenery.find_children("*", "MeshInstance3D",true,false).size()>12,"Portes et couloir réellement chargés en 3D")
	await _capture("couloir_ateliers_3d")
	world.teleport(Vector3(-8.1,.05,0));await create_timer(.25).timeout
	_check(world.nearest=="exit","Sortie du couloir atteignable tout à gauche")
	Input.action_press("game_left")
	for i in range(60):await physics_frame
	Input.action_release("game_left")
	_check(world.actor.position.x> -9.85,"La porte fermée empêche de tomber hors du couloir")
	world.teleport(Vector3(-8.1,.05,0));await create_timer(.25).timeout
	await _capture("porte_antipanique_3d")
	world.interact();await _frames(3);await _activate("campus_choice_0",true)
	_check(world.zone=="reception","La porte de gauche ramène à l’accueil")
	panel._travel("corridor");await _frames(5)
	for room in ["network","cyber"]:
		world.teleport(world._targets["to_"+room]+Vector3(0,.05,.7));await create_timer(.25).timeout
		_check(world.nearest=="to_"+room,"Porte accessible : "+room)
		world.interact();await _frames(3);await _activate("campus_choice_0",true)
		_check(world.zone==room,"Transition vers la salle : "+room)
		await _capture("salle_"+room+"_3d")
		for id in Course.IDS:
			if Course.LESSONS[id].zone!=room:continue
			world.teleport(world._targets[id]+Vector3(0,.05,.35));await create_timer(.25).timeout
			_check(world.nearest==id,"Station accessible sans traverser le mobilier : "+id)
			var before=state.profile.duplicate(true)
			world.interact();await _frames(3)
			if id=="net_address":
				root.size=Vector2i(800,480);await _frames(8)
				_check(panel.get_global_rect().grow(1).encloses(panel.dialog.get_global_rect()),"Dialogue contenu dans la zone visible sur 800 × 480")
				var back=_find("campus_choice_3")
				back.grab_focus();await _frames(8)
				_check(panel.dialog_scroll.get_global_rect().grow(1).encloses(back.get_global_rect()),"Dernier choix accessible par défilement sur petit écran")
				_find("campus_choice_0").grab_focus();await _frames(8)
				await _capture("exercice_reseau_compact")
			await _activate("campus_choice_%d" % ((Course.LESSONS[id].answer+1)%3))
			_check(state.profile==before,"Mauvaise réponse sans progression : "+id)
			await _activate("campus_choice_0",true)
			if id=="net_cable":
				var save_before=saves.read_profile(original.id).data
				saves.simulate_write_failure=true
				await _activate("campus_choice_%d" % Course.LESSONS[id].answer)
				_check(state.profile==before and saves.read_profile(original.id).data==save_before,"Échec disque ne valide pas l’exercice")
				saves.simulate_write_failure=false
				await _activate("campus_choice_0")
			await _activate("campus_choice_%d" % Course.LESSONS[id].answer,true)
			_check(id in Course.current(state.profile).completed,"Exercice validé par le contrôleur : "+id)
			_check(saves.read_profile(original.id).data==state.profile,"Progression persistée : "+id)
			await _activate("campus_choice_0")
			root.size=Vector2i(1280,720);await _frames(4)
		world.teleport(Vector3(0,.05,5.0));await create_timer(.25).timeout
		world.interact();await _frames(3);await _activate("campus_choice_0",true)
		_check(world.zone=="corridor","Sortie vers le couloir : "+room)
		_check(world.actor.position.distance_to(world._targets["to_"+room])<1.5,"Retour près de la bonne porte")
	_check(Course.current(state.profile).completed==Course.IDS,"Les six étapes sont terminées")
	var finished=state.profile.duplicate(true)
	_check(Course.answer(state,saves,"net_cable",1).ok and state.profile==finished,"Révision sans duplication de progression")
	_check(state.profile.wallet==original.wallet and state.profile.rewarded_missions==original.rewarded_missions,"Solde et missions de l’enquête conservés")
	_check(profiles.create_profile("Parcours séparé").ok and Course.current(state.profile).completed.is_empty(),"Progression isolée par profil")
	_check(profiles.select_profile(original.id).ok and Course.current(state.profile).completed==Course.IDS,"Progression restaurée après rechargement du profil")
	await _finish()

func _capture(filename: String) -> void:
	if not captures:return
	await _frames(4);await RenderingServer.frame_post_draw
	var folder=OS.get_environment("CIEL_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(folder)
	var rendered=root.get_texture().get_image()
	_check(rendered!=null and not rendered.is_empty(),"Image native : "+filename)
	rendered.save_png(folder.path_join(filename+".png"))
