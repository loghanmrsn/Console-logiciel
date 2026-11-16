extends "res://tests/school_ui_tests.gd"
## Native regression for the reception and the legacy workshop corridor.
func _run() -> void:
	await process_frame
	saves=root.get_node("SaveService");profiles=root.get_node("ProfileService");state=root.get_node("AppState")
	settings=root.get_node("SettingsService");router=root.get_node("SceneRouter");controllers=root.get_node("ControllerService")
	controllers.debug_set_devices([0]);test_root="user://tests/atelier_exit_%s" % Time.get_ticks_usec()
	saves.root_path=test_root;settings.storage_root=test_root
	captures="--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	root.size=Vector2i(1280,720)
	_check(profiles.use_dev_profile().ok,"Profil de lycée isolé")
	var document=state.profile.duplicate(true)
	document.progress.school_guided=true
	document.progress.room_id="school_reception";document.progress.checkpoint_id="school_reception_entry"
	_check(saves.write_profile(document).ok,"Accueil préparé")
	state.commit_profile(saves.read_profile(document.id).data)
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await _frames(25)
	app._show_screen("game");await _frames(8)
	if app.demo.campus_map.expanded:app.demo.campus_map.toggle_map()
	app.demo.world.player.position=Vector2(620,550);app.demo.world.player.reset_physics_interpolation()
	await _frames(30);await _capture("accueil_sans_texte_challenge")
	var hotel=root.get_node("HotelService")
	_check(hotel.escort_to_workshops().ok,"Accès au couloir")
	app.demo.world.restore_progress(state.profile.progress);app.demo.world.restore_checkpoint();await _frames(8)
	await _approach("school_reception_return");await _frames(30)
	_check(app.demo.world.player.position.x<250,"La sortie se trouve à l’extrémité gauche")
	_check(app.demo.world.target_id=="school_reception_return","Sortie interactive devant le modèle de porte")
	await _capture("porte_sortie_ateliers_challenge")
	await _key(KEY_SPACE);await _frames(4)
	_check(_find("hotel_travel_go")!=null,"Dialogue de sortie au clavier")
	await _activate("hotel_travel_go",true)
	_check(state.profile.progress.room_id=="school_reception" and app.demo.world.room_id=="school_reception","Sortie à la manette vers l’accueil")
	_check(saves.read_profile(state.profile.id).data==state.profile,"Retour enregistré et rechargeable")
	await _finish()
