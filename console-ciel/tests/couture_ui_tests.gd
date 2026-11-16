extends "res://tests/character_ui_tests.gd"
## Regression: retired outfit stays readable in old saves but cannot be offered again.
func _run() -> void:
 await process_frame
 saves=root.get_node("SaveService");profiles=root.get_node("ProfileService");state=root.get_node("AppState");settings=root.get_node("SettingsService");router=root.get_node("SceneRouter");controllers=root.get_node("ControllerService")
 controllers.debug_set_devices([0]);test_root="user://tests/retired_outfit_%s"%Time.get_ticks_usec();saves.root_path=test_root;settings.storage_root=test_root
 captures="--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
 root.size=Vector2i(1280,720)
 app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await _frames(30)
 _check(profiles.use_dev_profile().ok,"Profil isolé")
 var legacy=state.profile.duplicate(true)
 legacy.character=Catalog.defaults();legacy.character.owned=["top/madison"]
 legacy.character.appearance.top="madison";legacy.character.appearance.top_color="taupe"
 _check(saves.write_profile(legacy).ok,"Ancienne tenue et achat toujours lisibles")
 state.commit_profile(saves.read_profile(legacy.id).data)
 var before=state.profile.duplicate(true)
 var service=root.get_node("CharacterService")
 _check(service.current().appearance.top=="tee" and service.current().appearance.top_color=="white","Ancienne tenue remplacée par un haut simple")
 _check(state.profile==before and saves.read_profile(legacy.id).data==before,"Lecture sans réécriture ni perte du profil")
 _check(not service.purchase("top","madison").ok and not service.apply(legacy.character.appearance).ok,"Achat et nouvel équipement de la tenue retirée refusés")
 app._show_screen("character");await _frames(10)
 var panel=_find("character_configurator")
 _check(_find("character_madison")==null,"Présélection Madison supprimée")
 panel.page=2;panel._page();await _frames(5)
 var selector=_find("character_top")
 for i in selector.item_count:_check(selector.get_item_metadata(i)!="madison","Tenue absente des options")
 _check(panel.draft.top=="tee","Aperçu de l’ancien profil sans la tenue retirée")
 saves.simulate_write_failure=true
 var appearance=service.current().appearance
 _check(not service.apply(appearance).ok and state.profile==before,"Échec disque conserve l’ancien profil")
 saves.simulate_write_failure=false
 _check(service.apply(appearance).ok,"Nouvelle apparence enregistrée")
 _check(state.profile.character.owned==before.character.owned and state.profile.wallet==before.wallet,"Historique des achats et solde conservés")
 _check(saves.read_profile(legacy.id).data==state.profile,"Apparence relue après enregistrement")
 app._show_screen("shop");await _frames(8);await _activate("shop_dressing",true)
 _check(_find("wardrobe_card_top_madison")==null,"Tenue retirée absente de la boutique")
 var shop=_find("wardrobe_shop")
 _check(shop.grid.get_child_count()==4,"Quatre hauts courants proposés")
 await _capture("boutique_sans_madison")
 root.size=Vector2i(800,480);await _frames(8)
 var rotate=_find("wardrobe_rotate_left")
 rotate.grab_focus();await _frames(8)
 _check(app.scroll.get_global_rect().grow(1).encloses(rotate.get_global_rect()),"Action accessible sur petit écran")
 await _finish()
