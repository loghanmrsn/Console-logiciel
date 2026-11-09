extends "res://tests/profile_editor_tests.gd"
const Catalog=preload("res://scripts/services/character_catalog.gd")
func _initialize() -> void:
	Engine.max_fps=60
	super._initialize()
func _run() -> void:
	await process_frame
	saves=root.get_node("SaveService");profiles=root.get_node("ProfileService");state=root.get_node("AppState");settings=root.get_node("SettingsService");router=root.get_node("SceneRouter");controllers=root.get_node("ControllerService")
	controllers.debug_set_devices([0])
	test_root="user://tests/character_ui_%s"%Time.get_ticks_usec();saves.root_path=test_root;settings.storage_root=test_root
	captures="--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	root.size=Vector2i(1280,720)
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app)
	await _frames(35)
	_check(profiles.use_dev_profile().ok,"Profil isolé")
	app._show_screen("home");await _frames(12)
	await _activate("home_character",true)
	await _frames(12)
	var panel=_find("character_configurator")
	_check(app.screen=="character" and panel!=null,"Configurateur accessible par manette")
	_check(panel.view.model.figure!=null and panel.view.model.meshes.size()>=30,"Véritable scène 3D modulaire chargée")
	_check(panel.view.model.animation!=null and panel.view.model.animation.get_animation_list().size()>=2,"Squelette avec repos et marche")
	_check(panel.view.model.skeleton!=null and panel.view.model.skeleton.find_bone("spine")>=0,"Squelette 3D réel avec colonne animable")
	_check(_find("character_gait")==null,"La démarche bancale n'est plus proposée")
	_check(panel.view.model.visible_triangles()<25000,"Budget du personnage visible inférieur à 25 000 triangles")
	var updates=panel.view.rendered_updates
	await _frames(20)
	_check(panel.view.rendered_updates==updates,"Aperçu immobile sans rendu 3D continuel")
	await _capture("configurateur_visage")
	await _activate("character_rotate_right")
	_check(panel.view.heading!=0,"Rotation native du modèle")
	await _option("character_category",2)
	await _option("character_top",1)
	_check(panel.draft.top=="sweater" and _find("character_save").disabled,"Essayage payant sans équipement prématuré")
	var old=state.profile.duplicate(true)
	saves.simulate_write_failure=true
	await _activate("character_buy")
	_check(state.profile==old,"Échec disque : achat non débité")
	saves.simulate_write_failure=false
	await _activate("character_buy",true)
	_check("top/sweater" in state.profile.character.owned and state.profile.wallet.points==old.wallet.points-55,"Achat en points depuis le dressing")
	await _activate("character_save",true)
	_check(state.profile.character.appearance.top=="sweater","Apparence équipée et enregistrée")
	await _capture("pull_ample_3d")
	var shape_before=panel.view.model.figure.transform
	var spine=panel.view.model.skeleton.find_bone("spine")
	var a_pose=panel.draft.duplicate()
	a_pose.gait="natural";panel.view.model.configure(a_pose);panel.view.model.pose(true,.22)
	var natural=panel.view.model.skeleton.get_bone_pose_rotation(spine)
	a_pose.gait="loose";panel.view.model.configure(a_pose);panel.view.model.pose(true,.22)
	_check(panel.view.model.skeleton.get_bone_pose_rotation(spine).is_equal_approx(natural),"Ancienne démarche : marche naturelle sans torsion du buste")
	_check(panel.view.model.figure.transform==shape_before,"Marche naturelle sans déplacement du corps de collision")
	panel.view.configure(panel.draft)
	# Inspect every mesh variant, independent of ownership, as a showroom preview.
	var a=panel.draft.duplicate()
	for entry in Catalog.ITEMS:
		a[entry.slot]=entry.id
		if entry.slot!="hair":a[entry.slot+"_color"]=Catalog.allowed_colors(entry.slot,entry.id)[0]
		panel.view.configure(a)
		var name_=entry.slot+"_"+entry.id
		if entry.id!="none":
			var found=false
			for mesh in panel.view.model.meshes:
				if str(mesh.name)==name_:found=mesh.visible
			_check(found,"Modèle réellement visible : "+name_)
		_check(panel.view.model.visible_triangles()<25000,"Budget visible respecté : "+name_)
	var worst=Catalog.defaults().appearance
	for slot in Catalog.CATEGORIES+["eyes","smile"]:
		var maximum=-1
		for mesh in panel.view.model.meshes:
			if str(mesh.name).begins_with(slot+"_"):
				var triangles=0
				for s in mesh.mesh.get_surface_count():triangles+=mesh.mesh.surface_get_array_index_len(s)/3
				if triangles>maximum:maximum=triangles;worst[slot]=str(mesh.name).trim_prefix(slot+"_")
		if slot in Catalog.CATEGORIES and slot!="hair":worst[slot+"_color"]=Catalog.allowed_colors(slot,worst[slot])[0]
	panel.view.configure(worst)
	_check(panel.view.model.visible_triangles()<25000,"Combinaison la plus détaillée : budget global sous 25 000 triangles")
	a=Catalog.defaults().appearance;a.hair="fringe_curly";a.hair_color="blonde";a.top="hoodie";a.top_color="cream";a.trousers="baggy";a.trousers_color="blue";a.headwear="cap_flat";a.headwear_color="red";a.shoes="boots";a.shoes_color="brown"
	panel.draft=a.duplicate();panel._page();panel.view.heading=.55;panel.view.refresh()
	await _capture("dressing_casquette_baggy")
	if captures:
		var directory=OS.get_environment("CIEL_CAPTURE_DIR").path_join("walk_frames")
		DirAccess.make_dir_recursive_absolute(directory)
		for frame in range(16):
			panel.view.walking=true;panel.view.phase=frame/16.0;panel.view.refresh()
			await RenderingServer.frame_post_draw
			panel.view.viewport.get_texture().get_image().save_png(directory.path_join("walk_%02d.png"%frame))
		panel.view.walking=false;panel.view.refresh()
	a.headwear="straw";a.headwear_color="cream";a.hair="ponytails_long";a.trousers="balloon";a.trousers_color="green";panel.draft=a.duplicate();panel._page()
	await _capture("chapeau_paille_pantalon_ballon")
	root.size=Vector2i(800,480);await _frames(12)
	await _option("character_category",4)
	await _option("character_headwear",1)
	await _capture("dressing_compact")
	await _activate("character_reset",true)
	_check(panel.draft==panel.saved,"Annuler restaure les essais sans retirer les achats")
	await _activate("character_walk",true)
	await _frames(8)
	_check(app.screen=="character_walk","Test jouable en vraie 3D")
	var room=_find("character_walk_panel")
	var actor=room.actor
	var shape=actor.collider.shape
	_check(shape is CapsuleShape3D and is_equal_approx(shape.height,1.70) and is_equal_approx(shape.radius,.23),"Capsule 3D de dimensions fixes")
	actor.position=Vector3(1.4,.02,1)
	await create_timer(.25).timeout
	Input.action_press("game_up")
	for i in range(90):await physics_frame
	Input.action_release("game_up")
	_check(actor.position.z>-.96,"Le mur arrête le personnage 3D")
	actor.position=Vector3(0,.02,1)
	Input.action_press("game_up")
	for i in range(110):await physics_frame
	Input.action_release("game_up")
	_check(actor.position.z< -1.5,"Passage de porte franchissable avec le gabarit fixe")
	_check(_upright(actor.model),"Marche dans la vraie scène 3D : corps vertical")
	actor.model.configure(a)
	_check(actor.collider.shape==shape and is_equal_approx(shape.height,1.70) and is_equal_approx(shape.radius,.23),"Vêtements et chapeau ne changent jamais la capsule")
	await _capture("test_personnage_collision_3d")
	await _activate("character_walk_back",true)
	await _frames(8)
	await _activate("character_back")
	app._show_screen("game");await _frames(15)
	var world=app.demo.world
	app.demo._close_overlay()
	var progress=state.profile.progress.duplicate(true)
	progress.room_id="courtyard";progress.checkpoint_id="from_first"
	world.restore_progress(progress)
	world.set_controls_enabled(true)
	var radius=world.player.get_child(0).shape.radius
	_check(radius==10.0,"Collision des pieds conservée à dix unités")
	_check(world.player.avatar3d!=null and not world.player.sprite.visible,"Personnage 3D réellement utilisé dans le jeu")
	world.player.position=Vector2(2100,1580);world.player.reset_physics_interpolation()
	var before=world.player.position
	await create_timer(.25).timeout
	Input.action_press("game_walk_right" if world.player.reserve_map_arrow else "game_right")
	for i in range(20):await physics_frame
	Input.action_release("game_walk_right" if world.player.reserve_map_arrow else "game_right")
	await _frames(4)
	_check(world.player.position.x>before.x and world.player.avatar3d.model.animation!=null,"Marche du personnage dans le vrai jeu")
	await _capture("personnage_3d_en_jeu")
	# Exercise raw keyboard and virtual stick events, including diagonals and stops.
	var keyboard=InputEventKey.new();keyboard.keycode=KEY_Z;keyboard.pressed=true
	Input.parse_input_event(keyboard)
	for i in range(20):await physics_frame
	_check(world.player.avatar3d.walking and _upright(world.player.avatar3d.model),"Clavier : marche debout vers le haut")
	await _capture("marche_clavier_de_dos")
	keyboard.pressed=false;Input.parse_input_event(keyboard)
	for i in range(3):await physics_frame
	_check(world.player.velocity.is_zero_approx() and not world.player.avatar3d.walking and _upright(world.player.avatar3d.model),"Clavier relâché : arrêt debout sans glissement")
	for direction in [Vector2.RIGHT,Vector2(1,1).normalized(),Vector2.DOWN,Vector2.LEFT]:
		for axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]:
			var stick=InputEventJoypadMotion.new();stick.device=0;stick.axis=axis;stick.axis_value=direction.x if axis==JOY_AXIS_LEFT_X else direction.y
			Input.parse_input_event(stick)
		for i in range(18):await physics_frame
		_check(world.player.avatar3d.walking and _upright(world.player.avatar3d.model),"Stick simulé : corps vertical dans la direction "+str(direction))
		await _capture("marche_stick_%d"%int((direction.angle()+PI)*100))
	for axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]:
		var stick=InputEventJoypadMotion.new();stick.device=0;stick.axis=axis;stick.axis_value=0
		Input.parse_input_event(stick)
	for i in range(3):await physics_frame
	_check(world.player.velocity.is_zero_approx() and not world.player.avatar3d.walking and _upright(world.player.avatar3d.model),"Stick relâché : retour debout sans rotation résiduelle")
	app.demo.request_pause();await _frames(6)
	updates=world.player.avatar3d.rendered_updates
	await _frames(20)
	_check(world.player.avatar3d.rendered_updates==updates,"Pause sans animation 3D cachée")
	await _finish()
func _upright(model: Node3D) -> bool:
	var hips=model.skeleton.get_bone_global_pose(model.skeleton.find_bone("hips"))
	var head=model.skeleton.get_bone_global_pose(model.skeleton.find_bone("head"))
	return (model.basis*hips.basis.y).normalized().dot(Vector3.UP)>.99 and head.origin.y>hips.origin.y+.5
func _option(id: String,index: int) -> void:
	var option=_find(id) as OptionButton
	_check(option!=null,"Sélecteur natif : "+id)
	if option==null:return
	await _activate(id)
	var difference=index-option.selected
	for i in range(absi(difference)):await _press(KEY_DOWN if difference>0 else KEY_UP)
	await _press(KEY_ENTER)
	await _frames(4)
	option=_find(id) as OptionButton
	_check(option.selected==index,"Choix au clavier : "+id)
func _press(code: Key) -> void:
	var event=InputEventKey.new();event.keycode=code;event.pressed=true;Input.parse_input_event(event)
	await _frames(2)
	event=event.duplicate();event.pressed=false;Input.parse_input_event(event)
	await _frames(2)
func _capture(id: String) -> void:
	if not captures:return
	await _frames(4)
	await RenderingServer.frame_post_draw
	var folder=OS.get_environment("CIEL_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(folder)
	var im=root.get_texture().get_image()
	_check(im!=null and not im.is_empty() and im.save_png(folder.path_join(id+".png"))==OK,"Capture réelle : "+id)
