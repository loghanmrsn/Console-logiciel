extends "res://tests/morning_ui_tests.gd"
const CtfCatalog = preload("res://scripts/game/ctf_catalog.gd")

func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	settings = root.get_node("SettingsService")
	state = root.get_node("AppState")
	investigation = root.get_node("InvestigationService")
	router = root.get_node("SceneRouter")
	controllers = root.get_node("ControllerService")
	hotel = root.get_node("HotelService")
	controllers.debug_set_devices([0, 1])
	test_root = "user://tests/ctf_ui_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var values: Dictionary = settings.committed.duplicate(true)
	values.reduce_motion = true
	_check(settings.apply_settings(values).ok, "Réglages isolés")
	var made: Dictionary = profiles.create_profile("CTF interface")
	_check(made.ok, "Profil de joueur créé")
	profile_id = str(made.data.id)
	var preset: Dictionary = load("res://scripts/services/dev_profile.gd").build().data
	preset.id = profile_id
	preset.display_name = "CTF interface"
	preset.erase("role")
	preset.progress.erase("ctf")
	preset.rewarded_missions = saves.MISSION_IDS + saves.HOTEL_REWARD_IDS
	preset.wallet.points = 750
	preset.progress.hotel.morning_stage = 8
	preset.progress.room_id = "ctf_lobby"
	preset.progress.checkpoint_id = "ctf_entry"
	_check(saves.write_profile(preset).ok, "Ancien joueur arrivé au CTF préparé par le validateur réel")
	state.clear_profile()
	_check(profiles.select_profile(profile_id).ok, "Ancienne sauvegarde sélectionnée")
	root.size = Vector2i(1280, 720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(35)
	app._show_screen("home")
	await _activate("continue_game")
	await _frames(8)
	_check(_objective_contains("0 / 5"), "Le tableau indique le premier poste et la progression")
	await _check_layout_connectivity("ctf_lobby")
	await _capture("ctf_hall_challenge")
	await _target("ctf_flag")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "dialog", "Le dernier poste explique son verrouillage")
	await _dismiss_dialog()
	await _travel_target("ctf_leave", "ctf_bus_stop")
	await _target("ctf_return_bus")
	await _key(KEY_SPACE)
	await _capture("ctf_retour_anticipe_challenge")
	await _failed_action("ctf_bus_return", "ctf_bus", "Retour anticipé")
	await _activate("ctf_bus_return", true)
	_check(app.demo.world.room_id == "courtyard" and state.profile.wallet.points == 750, "Retour en ville à zéro épreuve, sans perte de points")
	await _resume_area("courtyard", "Reprise du retour anticipé")
	_check(hotel.board_bus().ok, "Reprendre le bus vers le CTF")
	app.demo.world.restore_progress(state.profile.progress)
	app.demo.world.restore_checkpoint()
	await _travel_target("ctf_enter", "ctf_lobby")
	for index in range(5):
		var id: String = CtfCatalog.IDS[index]
		await _target("ctf_" + id)
		await _key(KEY_SPACE)
		var panel = _find("ctf_challenge_panel")
		_check(panel != null and app.demo.overlay_kind == "ctf_challenge", "Le poste ouvre ses indices et son clavier : " + id)
		if panel == null:
			await _finish()
			return
		_check(panel.code_keyboard.visible and _find("key_123") != null and _find("key_Shift") != null, "Minuscules, majuscules et symboles disponibles : " + id)
		await _physical_text(panel.editor, "incorrect")
		await _activate("key_Valider", true)
		_check(app.demo.overlay_kind == "ctf_challenge" and state.profile.wallet.points == 750 + 50 * index, "Erreur corrigible sans récompense : " + id)
		if id == "base64":
			await _virtual_answer(panel, "CIEL_2026")
		elif id == "flag":
			await _virtual_answer(panel, "SUDO{CIEL_2026}")
		else:
			await _physical_text(panel.editor, str(CtfCatalog.CHALLENGES[id].answer))
		if id == "permissions":
			root.size = Vector2i(800, 480)
			var compact := values.duplicate(true)
			compact.large_text = true
			_check(settings.apply_settings(compact).ok, "Grand texte compact")
			await _frames(12)
			await _check_modal_layout("Permissions avec clavier en 800 × 480")
			await _capture("ctf_compact_challenge")
			root.size = Vector2i(1280, 720)
			_check(settings.apply_settings(values).ok, "Taille normale restaurée")
			await _frames(10)
		await _capture("ctf_" + id + "_challenge")
		await _activate("key_Valider", index % 2 == 0)
		_check(app.demo.overlay_kind == "dialog" and state.profile.wallet.points == 800 + 50 * index, "Validation au clavier/manette et récompense : " + id)
		await _dismiss_dialog()
		_check(_objective_contains(str(index + 1) + " / 5"), "Tableau mis à jour : " + id)
		await _resume_area("ctf_lobby", "Reprise conserve le poste validé")
	await _target("ctf_base64")
	await _key(KEY_SPACE)
	_check(_find("ctf_done_close") != null and _find("ctf_answer") == null, "Les indices terminés se relisent sans nouvelle saisie")
	await _activate("ctf_done_close")
	await _travel_target("ctf_leave", "ctf_bus_stop")
	await _target("ctf_return_bus")
	await _key(KEY_SPACE)
	await _capture("ctf_bus_retour_challenge")
	await _failed_action("ctf_bus_return", "ctf_bus", "Bus de retour")
	await _activate("ctf_bus_return", true)
	_check(app.demo.world.room_id == "courtyard" and state.profile.progress.hotel.morning_stage == 9 and state.profile.wallet.points == 1000, "Le bus ramène réellement en ville sans changer les points")
	await _capture("ctf_retour_ville_challenge")
	await _resume_area("courtyard", "La reprise conserve le retour près de l'hôtel")
	_check(saves.read_profile(profile_id).data == state.profile, "Dernier document cohérent")
	await _finish()

func _virtual_answer(panel: Control, value: String) -> void:
	var keyboard = panel.code_keyboard
	panel.editor.grab_focus()
	panel.editor.select_all()
	await _frames(3)
	for character in value:
		if character.to_lower() in "azertyuiopqsdfghjklmwxcvbn":
			if keyboard.input_mode != "letters": await _activate("key_123", true)
			if character == character.to_upper() and keyboard.shift_state == 0: await _activate("key_Shift", true)
		var key: BaseButton = _character_key(keyboard, character)
		for attempt in range(3):
			if key != null: break
			await _activate("key_123" if keyboard.input_mode == "letters" else ("key_Symbols" if keyboard.input_mode == "numbers" else "key_Numbers"), true)
			key = _character_key(keyboard, character)
		_check(key != null, "Le clavier propose le caractère : " + character)
		if key == null: return
		await _activate(str(key.name), true)
	_check(panel.editor.text == value, "Le clavier virtuel compose exactement la réponse : " + value)
