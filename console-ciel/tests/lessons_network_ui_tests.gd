extends "res://tests/code_chapter_ui_tests.gd"
const FOURTH := ["firewall", "ip_conflict", "subnet_mask"]

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
	test_root = "user://tests/lessons_network_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var values: Dictionary = settings.committed.duplicate(true)
	values.reduce_motion = true
	_check(settings.apply_settings(values).ok, "Réglages isolés")
	var created: Dictionary = profiles.create_profile("Livres réseau")
	if not created.ok:
		_check(false, "Création du profil")
		await _finish()
		return
	profile_id = str(created.data.id)
	_check(profiles.start_game().ok, "Enquête isolée")
	for chapter in [1, 2, 3]:
		if chapter > 1: _check(investigation.enter_chapter(chapter).ok, "Préparation étage")
		for id in [FIRST, SECOND, THIRD][chapter - 1]:
			if chapter == 3: _check(investigation.submit_code(id, ANSWERS[id]).ok, "Préparation du code")
			else: _complete_service(id)
	root.size = Vector2i(1280,720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(35)
	app._show_screen("home")
	await _activate("continue_game")
	await _frames(8)
	if app.demo.overlay_kind == "conclusion": await _activate("conclusion_stay")
	await _test_books()
	await _approach("elevator")
	await _key(KEY_SPACE)
	_check(_find("elevator_down") != null and _find("elevator_up") != null and _find("elevator_menu") != null, "Les trois actions de l’ascenseur sont affichées")
	await _capture("ascenseur_challenge")
	await _key(KEY_ESCAPE)
	await _travel(4, true)
	await _test_lab_walk()
	for id in FOURTH:
		await _solve_lab(id)
	_check(app.demo.overlay_kind == "conclusion" and state.profile.wallet.points == 600, "Le laboratoire ouvre le bilan des douze réussites")
	await _capture("bilan_reseau_challenge")
	await _activate("conclusion_stay")
	await _approach("elevator")
	await _key(KEY_SPACE)
	_check(not (_find("elevator_up") as Button).disabled and not (_find("elevator_down") as Button).disabled, "Chapitre 4 terminé : montée au chapitre 5 et descente disponibles")
	await _key(KEY_ESCAPE)
	await _travel(3)
	await _test_books(true)
	await _travel(4)
	await _approach("elevator")
	await _key(KEY_SPACE)
	await _activate("elevator_menu", true)
	_check(app.screen == "home" and saves.read_profile(profile_id).data == state.profile, "Le troisième bouton retourne au menu en sauvegardant")
	await _activate("continue_game")
	await _frames(8)
	_check(app.demo.world.chapter_id == 4, "Continuer reprend le chapitre 4")
	await _finish()

func _test_books(compact: bool = false) -> void:
	var before: Dictionary = state.profile.duplicate(true)
	if compact:
		root.size = Vector2i(800,480)
		var values: Dictionary = settings.committed.duplicate(true)
		values.large_text = true
		values.appearance_style = "nuit"
		_check(settings.apply_settings(values).ok, "Petit écran, thème nuit et texte agrandi")
		await _frames(8)
	await _approach("books")
	_check(app.demo.world.get_interactable("books").visible, "Les ressources restent accessibles après les missions")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "library" and not app.demo.world._controls_enabled, "Les livres suspendent le déplacement")
	await _capture("bibliotheque_compacte_challenge" if compact else "bibliotheque_challenge")
	for id in THIRD:
		await _activate("book_" + id, true)
		var library = app.demo.lesson_library
		_check(library.reader.visible and library.page_index == 0 and library.spread.amount == 1.0, "Livre ouvert, première leçon visible : " + id)
		await _activate("lesson_next")
		await _activate("lesson_next", true)
		_check(library.page_index == 2 and library.example.text == PREVIEWS[id], "Le livre donne l’exemple exact du défi : " + id)
		await _check_modal_layout("leçon " + id)
		if not compact: await _capture("livre_" + id + "_challenge")
		if id == "html":
			var retained = library
			app.demo.controller_lost("Déconnexion de test")
			await _frames(8)
			_check(app.demo.overlay_kind == "controller_pause", "Lecture suspendue après déconnexion")
			await _activate("controller_resume")
			_check(app.demo.overlay_kind == "library" and app.demo.lesson_library == retained and retained.page_index == 2, "La même leçon est conservée à la reprise")
		await _key(KEY_ESCAPE)
		_check(library.selection.visible and library.selected_book == -1, "Échap ferme le livre et revient au choix")
	# Exercise animated opening separately from the reduced-motion path.
	var values: Dictionary = settings.committed.duplicate(true)
	values.reduce_motion = false
	_check(settings.apply_settings(values).ok, "Animations activées pour vérifier leur progression")
	await _frames(6)
	var card := _find("book_python")
	card.grab_focus()
	await create_timer(.2).timeout
	_check(card.scale.x > 1.0, "La sélection anime la couverture")
	app.demo.lesson_library.open_book(0)
	_check(app.demo.lesson_library.spread.amount < 1.0, "Le livre démarre fermé")
	await create_timer(.38).timeout
	_check(is_equal_approx(app.demo.lesson_library.spread.amount,1.0), "L’animation déploie les pages")
	await _key(KEY_ESCAPE)
	await _activate("library_close")
	_check(app.demo.overlay_kind.is_empty() and app.demo.world._controls_enabled, "Retour dans la pièce avec contrôles rétablis")
	_check(state.profile == before and saves.read_profile(profile_id).data == before, "Lire, changer de livre et fermer ne modifie aucune sauvegarde ni aucun point")
	values.reduce_motion = true
	_check(settings.apply_settings(values).ok, "Animations réduites rétablies")

func _test_lab_walk() -> void:
	var world = app.demo.world
	_check(world.chapter_id == 4 and world.room_id == "room_04" and world.get_interactable("books") == null, "Salle du laboratoire distincte, sans anciennes cibles")
	world.player.position = world.CHAPTER_FOUR_CHECKPOINTS.elevator
	await _physics_frames(3)
	await _walk_axis(KEY_UP,111)
	await _walk_axis(KEY_RIGHT,62)
	_check(world.target_id == "firewall", "Le pare-feu est accessible à pied depuis l’ascenseur")
	await _walk_axis(KEY_RIGHT,280)
	_check(world.target_id == "ip_conflict", "Le poste IPv4 est accessible par le couloir")
	await _walk_axis(KEY_RIGHT,280)
	_check(world.target_id == "subnet_mask", "Le masque est accessible sans collision invisible")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "dialog", "Le dernier défi reste verrouillé avant les deux premiers")
	await _key(KEY_ESCAPE)
	await _capture("laboratoire_challenge")

func _solve_lab(id: String) -> void:
	await _approach(id)
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "challenge" and app.demo.challenge.mission_id == id, "Défi du bon poste ouvert : " + id)
	var definition: Dictionary = investigation.mission(id)
	_check(app.demo.challenge.diagnosis_selector.disabled and app.demo.challenge.repair_selector.disabled and app.demo.challenge.submit_button.disabled, "Choix bloqués avant les observations : " + id)
	for observation in definition.observations: await _activate("observation_" + str(observation.id))
	await _select_option(id + "_diagnosis", str(definition.solution.diagnosis))
	await _select_option(id + "_repair", str(definition.solution.repair))
	await _check_modal_layout(id)
	await _capture(id + "_challenge")
	await _activate(id + "_validate", true)
	_check(app.demo.overlay_kind == "dialog" and state.profile.progress.completed_missions.has(id), "Réussite validée et sauvegardée : " + id)
	_check(not app.demo.world.get_interactable(id).visible and app.demo.world.target_id != id, "Repère retiré après réussite : " + id)
	await _activate("dialog_continue")
func _select_option(id: String, metadata: String) -> void:
	var option := _find(id) as OptionButton
	_check(option != null and not option.disabled, "Choix natif accessible : " + id)
	if option == null or option.disabled:
		return
	var target := -1
	for index in range(option.item_count):
		if str(option.get_item_metadata(index)) == metadata:
			target = index
	_check(target >= 0, "Solution proposée par la liste native : " + metadata)
	if target < 0:
		return
	option.grab_focus()
	await _frames(5)
	await _key(KEY_ENTER)
	var popup := option.get_popup()
	_check(popup.visible, "Liste native réellement ouverte : " + id)
	for attempt in range(option.item_count + 2):
		if not popup.visible or popup.get_focused_item() == target:
			break
		await _key(KEY_DOWN)
	if popup.visible:
		await _key(KEY_ENTER)
	await _frames(4)
	_check(option.selected == target, "Choix validé avec les touches de navigation : " + id)
