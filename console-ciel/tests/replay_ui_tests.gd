extends "res://tests/code_chapter_ui_tests.gd"

func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	settings = root.get_node("SettingsService")
	state = root.get_node("AppState")
	investigation = root.get_node("InvestigationService")
	router = root.get_node("SceneRouter")
	controllers = root.get_node("ControllerService")
	controllers.debug_set_devices([0])
	test_root = "user://tests/replay_%s" % Time.get_ticks_usec()
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var made: Dictionary = profiles.create_profile("Rejeu sûr")
	_check(made.ok and profiles.start_game().ok, "Profil normal isolé")
	profile_id = str(made.data.id)
	for chapter in range(1, 6):
		if chapter > 1: _check(investigation.enter_chapter(chapter).ok, "Préparer étage")
		for definition in investigation.chapter_missions(chapter):
			var id: String = definition.id
			if chapter == 3: _check(investigation.submit_code(id, definition.solution.answer).ok, "Code validé")
			elif chapter == 5:
				_check(investigation.enter_maze().ok and investigation.terminal_login("admin", "admin").ok and investigation.terminal_command("sudo", "admin").ok, "Labyrinthe validé")
			else: _complete_service(id)
	root.size = Vector2i(800, 480)
	var values: Dictionary = settings.committed.duplicate(true)
	values.large_text = true
	values.reduce_motion = true
	_check(settings.apply_settings(values).ok, "Petit écran et texte agrandi")
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(25)
	app._show_screen("home")
	await _frames(4)
	await _activate("continue_game")
	for chapter in range(1, 5):
		_check(investigation.enter_chapter(chapter).ok, "Revisiter étage terminé")
		app.demo.world.restore_progress(state.profile.progress)
		app.demo.world.restore_checkpoint()
		for definition in investigation.chapter_missions(chapter):
			var id: String = definition.id
			var before: Dictionary = state.profile.duplicate(true)
			app.demo._last_completed_mission = id
			app.demo._show_conclusion()
			await _frames(4)
			await _activate("conclusion_replay", true)
			_check(root.gui_get_focus_owner().name == "replay_cancel", "Annuler reçoit le focus par défaut")
			if id == "computer":
				await _check_modal_layout("confirmation sans reset")
				await _capture("rejeu_confirmation_challenge")
			await _activate("replay_cancel")
			_check(state.profile == before, "Annuler est sans effet")
			await _activate("conclusion_replay")
			saves.simulate_write_failure = true
			await _activate("replay_confirm", true)
			_check(app.demo.overlay_kind == "challenge" and app.demo.challenge.mission_id == id, "Seul le défi demandé est ouvert : " + id)
			var panel = app.demo.challenge
			if chapter == 3:
				await _choose(id + "_answer", definition.solution.answer, true)
				await _activate(id + "_validate", true)
			elif id == "lighting":
				for connection in definition.solution.connections: panel.connection_buttons[connection].set_pressed(true)
				await _activate("light_validate")
			else:
				var first: OptionButton = panel.cause_selector if id == "computer" else panel.diagnosis_selector
				var second: OptionButton = panel.correction_selector if id == "computer" else panel.repair_selector
				_select_answer(first, definition.solution.cause if id == "computer" else definition.solution.diagnosis)
				_select_answer(second, definition.solution.correction if id == "computer" else definition.solution.repair)
				panel.refresh()
				await _activate(str(panel.submit_button.name), true)
			saves.simulate_write_failure = false
			_check(app.demo.overlay_kind == "dialog", "Réponse revalidée sans écriture : " + id)
			_check(state.profile == before and saves.read_profile(profile_id).data == before, "Profil et disque exactement conservés : " + id)
			await _activate("dialog_continue")
			app.demo._close_overlay()
	# A fresh game view has no transient last-mission ID: its chapter fallback is safe.
	app.demo._last_completed_mission = ""
	_check(app.demo._replay_target() == "subnet_mask", "Bilan rechargé : dernière mission du chapitre, sans reset")
	_check(investigation.enter_chapter(5).ok and investigation.enter_maze().ok, "Retour au terminal")
	app.demo.world.restore_progress(state.profile.progress)
	app.demo.world.restore_checkpoint()
	var before: Dictionary = state.profile.duplicate(true)
	app.demo._show_conclusion()
	await _activate("conclusion_replay")
	await _activate("replay_confirm", true)
	_check(app.demo.terminal_panel.phase == "user" and app.demo.terminal_panel.code_keyboard.visible, "Rejeu du terminal avec identifiant et clavier")
	for answer in ["admin", "admin", "sudo -i", "admin"]:
		await _physical_text(app.demo.terminal_panel.editor, answer)
		await _activate("terminal_validate", true)
	_check(app.demo.overlay_kind == "dialog" and state.profile == before and saves.read_profile(profile_id).data == before, "Terminal rejoué sans perdre de validation ni augmenter les points")
	await _capture("rejeu_reussi_challenge")
	await _activate("dialog_continue")
	await _activate("maze_success_stay")
	await _key(KEY_P)
	await _activate("pause_menu")
	await _activate("continue_game")
	_check(state.profile == before and state.profile.progress.completed_missions.size() == 13, "Les treize validations survivent au retour au menu et à la reprise")
	await _finish()

func _select_answer(selector: OptionButton, answer: String) -> void:
	for index in range(selector.item_count):
		if str(selector.get_item_metadata(index)) == answer:
			selector.select(index)
			selector.item_selected.emit(index)
			return
	_check(false, "Réponse disponible : " + answer)
