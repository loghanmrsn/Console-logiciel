extends "res://tests/character_ui_tests.gd"

func _run() -> void:
	await process_frame
	saves=root.get_node("SaveService");profiles=root.get_node("ProfileService");state=root.get_node("AppState");settings=root.get_node("SettingsService");router=root.get_node("SceneRouter");controllers=root.get_node("ControllerService")
	controllers.debug_set_devices([0])
	test_root="user://tests/compact_%s"%Time.get_ticks_usec();saves.root_path=test_root;settings.storage_root=test_root
	captures="--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	root.size=Vector2i(1280,900)
	app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await _frames(25)
	_check(profiles.use_dev_profile().ok,"Profil de test isolé")
	var service=root.get_node("CharacterService")
	var legacy=Catalog.defaults()
	for field in ["model","fur","accessory","accessory_color"]:legacy.appearance.erase(field)
	var old=legacy.duplicate(true)
	_check(Catalog.valid(legacy),"Ancien format sans nouveau champ accepté")
	var restored=Catalog.record({"character":legacy})
	_check(restored.appearance.model=="classic" and restored.appearance.accessory=="none" and legacy==old,"Ancienne silhouette conservée sans modifier la source")
	var invalid=Catalog.defaults();invalid.appearance.model="unknown"
	_check(not Catalog.valid(invalid),"Modèle inconnu refusé")
	invalid=Catalog.defaults();invalid.appearance.fur="unknown"
	_check(not Catalog.valid(invalid),"Pelage inconnu refusé")
	invalid=Catalog.defaults();invalid.appearance.scale=2
	_check(not Catalog.valid(invalid),"Aucune taille libre dans le profil")
	app._show_screen("character");await _frames(8)
	var panel=_find("character_configurator")
	_check(panel.draft.model=="human","Nouveau personnage humain compact par défaut")
	panel.view.focus_face(false);panel.view.heading=.2;panel.view.refresh()
	await _capture("humain_compact")
	if captures:
		panel.view.heading=0;panel.view.refresh();await _frames(5);await RenderingServer.frame_post_draw
		var front=panel.view.viewport.get_texture().get_image().get_data()
		panel.view.turn(PI);await _frames(5);await RenderingServer.frame_post_draw
		var back=panel.view.viewport.get_texture().get_image().get_data()
		panel.view.turn(-PI);await _frames(5);await RenderingServer.frame_post_draw
		var restored_front=panel.view.viewport.get_texture().get_image().get_data()
		_check(front!=back,"La rotation change réellement le rendu de l’aperçu")
		_check(front==restored_front,"Retour de face identique, sans image interpolée figée")
	await _option("character_model",1)
	_check(panel.draft.model=="rabbit" and panel.view.model._model_id=="rabbit","Choix du lapin réellement visible")
	await _activate("character_rabbit",true)
	_check(panel.draft==Catalog.rabbit_appearance() and panel._missing().is_empty(),"Tenue du lapin blanc à écharpe entièrement gratuite")
	await _option("character_fur",1)
	_check(panel.draft.fur=="sand","Pelage personnalisable")
	await _option("character_fur",0)
	await _option("character_category",7)
	await _option("character_accessory",1)
	_check(panel.draft.accessory=="scarf" and panel._missing().is_empty(),"Écharpe gratuite sans achat requis")
	panel.view.focus_face(false);await _capture("lapin_echarpe")
	var before=state.profile.duplicate(true)
	saves.simulate_write_failure=true;await _activate("character_save")
	_check(state.profile==before,"Échec disque : profil et solde conservés")
	saves.simulate_write_failure=false;await _activate("character_save",true)
	_check(state.profile.character.appearance.model=="rabbit" and saves.read_profile(before.id).data==state.profile,"Lapin et cosmétiques persistés")
	var points=state.profile.wallet.points
	await _option("character_accessory",2)
	_check(panel.apply.disabled and panel.buy.visible,"Sac essayé avant achat")
	await _activate("character_buy",true);await _activate("character_save",true)
	_check(state.profile.wallet.points==points-45 and state.profile.character.appearance.accessory=="backpack","Sac acheté une fois avec les points du jeu")
	panel.view.heading=PI-.35;panel.view.refresh();await _capture("lapin_sac_a_dos")
	for model_id in Catalog.MODELS:
		var a=Catalog.defaults().appearance;a.model=model_id
		panel.view.configure(a)
		var model=panel.view.model
		_check(model.skeleton.get_bone_count()==13,"Treize os : "+model_id)
		_check(model.visible_triangles()<40000,"Budget visible : "+model_id)
		var stable=true
		for i in range(240):
			model.pose(true,i*.025)
			stable=stable and _upright(model)
		_check(stable,"Marche verticale stable : "+model_id)
		for item in Catalog.ITEMS:
			if item.slot!="accessory" or item.id=="none":continue
			a.accessory=item.id;model.configure(a)
			var found=false
			for mesh in model.meshes:
				if str(mesh.name)=="accessory_"+item.id:found=mesh.visible
			_check(found,"Accessoire adapté : "+model_id+" / "+item.id)
	panel.draft=service.current().appearance;panel._page()
	await _option("character_model",0)
	await _option("character_accessory",3)
	panel.view.focus_face(true);panel.view.heading=.1;panel.view.refresh();await _capture("humain_lunettes")
	root.size=Vector2i(800,480);await _frames(8)
	panel.model_selector.grab_focus();await _frames(5)
	_check(app.scroll.get_global_rect().grow(1).encloses(panel.model_selector.get_global_rect()),"Choix du personnage accessible sur écran 800 × 480")
	await _capture("dressing_compact_800")
	app._show_screen("shop");await _frames(8);await _activate("shop_dressing",true)
	await _option("wardrobe_category",6)
	var shop=_find("wardrobe_shop")
	_check(shop.grid.get_child_count()==3,"Trois accessoires proposés en boutique")
	await _activate("wardrobe_card_accessory_backpack",true)
	_check(shop.equip.disabled and shop.price.text=="45 points","Achat conservé entre dressing et boutique")
	await _capture("boutique_accessoires")
	app._show_screen("campus3d");await _frames(12)
	var campus=_find("campus_3d_panel")
	if campus!=null:
		_check(campus.world.actor.model._model_id=="rabbit","Apparence du lapin reprise dans le quartier 3D")
		var shape=campus.world.actor.collider.shape
		_check(is_equal_approx(shape.height,1.70) and is_equal_approx(shape.radius,.23),"Collisions fixes pour les deux nouvelles silhouettes")
		await _capture("lapin_dans_le_quartier")
	else:_check(false,"Quartier 3D accessible")
	await _finish()
