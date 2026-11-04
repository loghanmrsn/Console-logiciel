extends "res://tests/ctf_ui_tests.gd"
func _run() -> void:
	await process_frame
	saves=root.get_node("SaveService")
	profiles=root.get_node("ProfileService")
	settings=root.get_node("SettingsService")
	state=root.get_node("AppState")
	router=root.get_node("SceneRouter")
	controllers=root.get_node("ControllerService")
	controllers.debug_set_devices([0])
	test_root="user://tests/pseudo_ui_%s" % Time.get_ticks_usec()
	saves.root_path=test_root
	settings.storage_root=test_root
	state.clear_profile()
	captures="--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(30)
	app._open_editor("")
	await _frames(6)
	await _physical_text(app.name_edit,"Ad.min42")
	await _activate("key_Valider",true)
	_check(app.screen=="editor" and state.profile.is_empty() and is_instance_valid(app.modal),"Création refusée depuis le clavier manette")
	_check(_contains_message(app.modal,"Ce pseudo n’est pas autorisé"),"Message clair de refus")
	await _capture("pseudo_interdit_challenge")
	await _key(KEY_ESCAPE)
	await _physical_text(app.name_edit,"Constance")
	await _activate("key_Valider")
	_check(app.screen=="home" and state.profile.display_name=="Constance","Correction du pseudo puis création")
	profile_id=state.profile.id
	app._open_editor(profile_id)
	await _frames(6)
	await _physical_text(app.name_edit,"f.d.p")
	await _activate("key_Valider")
	_check(app.screen=="editor" and state.profile.display_name=="Constance" and saves.read_profile(profile_id).data.display_name=="Constance","Renommage refusé sans remplacer le pseudo")
	_check(_contains_message(app.modal,"Ce pseudo n’est pas autorisé"),"Refus expliqué pendant la personnalisation")
	await _key(KEY_ESCAPE)
	await _physical_text(app.name_edit,"Loghan")
	await _activate("key_Valider",true)
	_check(app.screen=="home" and state.profile.display_name=="Loghan","Renommage corrigé avec la manette")
	await _finish()
func _contains_message(node: Node, message: String) -> bool:
	if node==null: return false
	if node is Label and message in node.text: return true
	for child in node.get_children():
		if _contains_message(child,message): return true
	return false
