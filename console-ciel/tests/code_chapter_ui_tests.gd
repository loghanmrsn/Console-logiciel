extends SceneTree
## Native keyboard/controller events exercise the chapter-three menus and room.
## Saves and settings are isolated; physical controllers and a Pi GPU are not used.
## Optional images: CIEL_CAPTURE_DIR=/tmp/captures -- --screenshots

const FIRST := ["lighting", "lock", "computer"]
const SECOND := ["network", "addressing", "security"]
const THIRD := ["python", "html", "markdown"]
const ANSWERS := {"python": "print", "html": "h1", "markdown": "hash"}
const PREVIEWS := {
	"python": "print(\"Bonjour CIEL\")",
	"html": "<h1>Bonjour CIEL</h1>",
	"markdown": "# Bonjour CIEL"
}

var checks := 0
var failures: Array[String] = []
var app
var saves
var profiles
var settings
var state
var investigation
var router
var controllers
var test_root := ""
var profile_id := ""
var captures := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	Input.use_accumulated_input = true
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	settings = root.get_node("SettingsService")
	state = root.get_node("AppState")
	investigation = root.get_node("InvestigationService")
	router = root.get_node("SceneRouter")
	controllers = root.get_node("ControllerService")
	controllers.debug_set_devices([0])
	test_root = "user://tests/code_chapter_ui_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	print("CODE_CHAPTER_UI_DATA : ", ProjectSettings.globalize_path(test_root))
	var values: Dictionary = settings.committed.duplicate(true)
	values.reduce_motion = true
	_check(settings.apply_settings(values).ok, "Réglages de test isolés")
	var created: Dictionary = profiles.create_profile("Code CIEL")
	_check(created.ok, "Profil de test créé")
	if not created.ok:
		await _finish()
		return
	profile_id = str(created.data.id)
	_check(profiles.start_game().ok, "Enquête de test démarrée")
	for id in FIRST:
		_complete_service(id)
	_check(investigation.enter_chapter(2).ok, "Préparation du chapitre réseau")
	for id in ["network", "addressing"]:
		_complete_service(id)
	root.size = Vector2i(1280, 720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(35)
	app._show_screen("home")
	await _frames(7)
	await _capture("home_three_chapters")
	await _activate("continue_game")
	_check(app.screen == "game" and is_instance_valid(app.demo), "Continuer ouvre le monde sauvegardé")
	if not is_instance_valid(app.demo):
		await _finish()
		return
	await _test_locked_floor()
	_complete_service("security")
	await _frames(5)
	await _travel(3, true)
	await _test_room_and_walking()
	await _check_tracker(0)
	await _capture("chapter_3_arrival")
	for id in THIRD:
		await _solve_code(id)
		if not state.profile.progress.completed_missions.has(id):
			await _finish()
			return
		if id != "markdown":
			await _test_resume(id)
	_check(app.demo.overlay_kind == "conclusion", "Le troisième exercice ouvre le bilan code")
	_check(state.profile.wallet.points == 450 and state.profile.progress.run_reward_points == 450 and state.profile.rewarded_missions.size() == 9, "Les neuf réussites ont donné exactement 450 points")
	_check(saves.read_profile(profile_id).data == state.profile, "Le bilan correspond à la sauvegarde entière")
	await _check_modal_layout("bilan du code")
	await _capture("chapter_3_conclusion")
	await _activate("conclusion_stay")
	await _check_tracker(3)
	await _test_compact_hud()
	await _test_round_trips()
	await _test_resume("elevator")
	await _finish()


func _test_locked_floor() -> void:
	var before: Dictionary = state.profile.duplicate(true)
	await _approach("elevator")
	await _key(KEY_SPACE)
	var code := _find("elevator_up") as Button
	_check(app.demo.overlay_kind == "elevator" and code != null and code.disabled, "La destination code est visible mais verrouillée avant la fin du réseau")
	_check(_find("elevator_down") != null and not (_find("elevator_down") as Button).disabled, "Le retour à un étage déjà débloqué reste disponible")
	_check(state.profile == before and saves.read_profile(profile_id).data == before, "Consulter les destinations n’altère pas le profil")
	await _capture("elevator_locked")
	await _key(KEY_ESCAPE)


func _travel(chapter: int, with_failure: bool = false) -> void:
	if absi(chapter - app.demo.world.chapter_id) > 1:
		while app.demo.world.chapter_id != chapter:
			var step: int = app.demo.world.chapter_id + (1 if chapter > app.demo.world.chapter_id else -1)
			await _travel(step, with_failure)
		return
	var before: Dictionary = state.profile.duplicate(true)
	await _approach("elevator")
	await _key(KEY_SPACE)
	var button := "elevator_up" if chapter > app.demo.world.chapter_id else "elevator_down"
	_check(app.demo.overlay_kind == "elevator", "L’ascenseur propose monter, descendre et le menu")
	if with_failure:
		await _capture("elevator_unlocked")
	if with_failure:
		saves.simulate_write_failure = true
		await _activate(button)
		saves.simulate_write_failure = false
		_check(app.demo.overlay_kind == "dialog" and state.profile == before and saves.read_profile(profile_id).data == before and app.demo.world.chapter_id != chapter, "Échec de trajet : monde, sauvegarde et portefeuille restent à l’étage précédent")
		await _activate("dialog_continue")
		_check(app.demo.overlay_kind == "elevator", "La destination peut être réessayée après l’échec")
	await _activate(button, true)
	await _physics_frames(4)
	await _frames(6)
	_check(app.demo.world.chapter_id == chapter and investigation.current_chapter() == chapter and state.profile.progress.room_id == "room_0%d" % chapter, "Monde, service et document changent d’étage ensemble")
	_check(app.demo.overlay_kind.is_empty() and state.profile.progress.checkpoint_id == "elevator", "Arrivée sans dialogue, près de l’ascenseur")
	_check(state.profile.wallet == before.wallet and state.profile.rewarded_missions == before.rewarded_missions, "Aucun gain lors du trajet")


func _test_room_and_walking() -> void:
	var world = app.demo.world
	_check(world.room_id == "room_03" and world.chapter_id == 3, "La salle code a son identifiant propre")
	_check(world.get_interactable("network") == null and world.get_interactable("lighting") == null, "Les interactions des anciens étages ne restent pas superposées")
	for name in ["PythonDesk", "HtmlDesk", "MarkdownDesk", "CodeStorage", "CodeResources", "CodePlant", "Elevator"]:
		var prop := world._props.get_node_or_null(name) as StaticBody2D
		_check(prop != null and prop.collision_layer == 1, "Meuble avec collision physique : " + name)
		if prop != null:
			var shapes := 0
			var sprites := 0
			for child in prop.get_children():
				if child is CollisionShape2D and child.shape != null:
					shapes += 1
				if child is Sprite2D and child.texture != null:
					sprites += 1
			_check(shapes > 0 and sprites > 0, "Visuel et collision appartiennent au même meuble : " + name)
	# Walk the clear aisle from the elevator to all three desks. No position
	# teleport occurs between these waypoints; the real CharacterBody2D moves.
	world.player.position = world.CHAPTER_THREE_CHECKPOINTS.elevator
	await _physics_frames(3)
	await _walk_axis(KEY_UP, 111)
	await _walk_axis(KEY_RIGHT, 62)
	_check(world.player.position.distance_to(world.CHAPTER_THREE_CHECKPOINTS.python) < 9 and world.target_id == "python", "Le joueur rejoint Python à pied depuis l’ascenseur")
	await _walk_axis(KEY_RIGHT, 280)
	_check(world.player.position.distance_to(world.CHAPTER_THREE_CHECKPOINTS.html) < 13 and world.target_id == "html", "Le couloir mène physiquement au poste HTML")
	await _walk_axis(KEY_RIGHT, 280)
	_check(world.player.position.distance_to(world.CHAPTER_THREE_CHECKPOINTS.markdown) < 18 and world.target_id == "markdown", "Le tableau Markdown est accessible à pied sans obstacle invisible")
	for id in THIRD:
		await _approach(id)
		_check(_point_clear(world.player.position), "Checkpoint hors de tout meuble ou mur : " + id)
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "dialog" and not state.profile.progress.completed_missions.has("markdown"), "Le dernier poste explique son prérequis au lieu de sauter Python et HTML")
	await _key(KEY_ESCAPE)


func _solve_code(id: String) -> void:
	var original: Dictionary = settings.committed.duplicate(true)
	var values: Dictionary = original.duplicate(true)
	values.large_text = id != "python"
	values.appearance_style = "nuit" if id == "html" else "brume"
	values.reduce_motion = true
	_check(settings.apply_settings(values).ok, "Lecture adaptée pour le défi " + id)
	root.size = Vector2i(1280, 720) if id == "python" else Vector2i(800, 480)
	await _frames(9)
	await _approach(id)
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "challenge", "Le poste ouvre l’exercice " + id)
	var editor := _find(id + "_answer") as LineEdit
	var keyboard = app.demo.challenge.code_keyboard
	var preview := _find(id + "_code_preview") as Label
	var submit := _find(id + "_validate") as Button
	_check(editor != null and preview != null and submit != null and keyboard != null and keyboard.is_visible_in_tree(), "Champ de saisie, clavier visible, aperçu et validation natifs : " + id)
	if editor == null or preview == null or submit == null:
		return
	_check(editor.text.is_empty() and submit.disabled and preview.text == investigation.mission(id).code.template, "Sans texte, aperçu incomplet et validation désactivée : " + id)
	_check(preview.get_class() == "Label", "Le code est un texte littéral, sans interprétation HTML ou Markdown : " + id)
	await _check_modal_layout(id + " sans réponse")
	var before: Dictionary = state.profile.duplicate(true)
	var tracker := _find("mission_tracker")
	var expanded: bool = tracker.is_expanded()
	await _key(KEY_T)
	await _joy(JOY_BUTTON_Y)
	_check(tracker.is_expanded() == expanded and app.demo.overlay_kind == "challenge", "Les raccourcis de missions restent suspendus pendant le choix code")
	editor.grab_focus()
	await _frames(3)
	await _joy(JOY_BUTTON_DPAD_DOWN)
	var expected_first := "[" if id == "markdown" else "a"
	_check(root.gui_get_focus_owner() is Button and root.gui_get_focus_owner().text == expected_first, "La croix bas rejoint le clavier depuis le champ : " + id)
	await _joy(JOY_BUTTON_DPAD_RIGHT)
	_check(root.gui_get_focus_owner() is Button and root.gui_get_focus_owner().text == ("]" if id == "markdown" else "z"), "La croix droite suit la rangée du clavier : " + id)
	await _joy(JOY_BUTTON_DPAD_UP)
	_check(root.gui_get_focus_owner() == editor, "La croix haut revient au champ de réponse : " + id)
	await _physical_text(editor, "p t e")
	_check(editor.text == "p t e" and app.demo.overlay_kind == "challenge" and tracker.is_expanded() == expanded, "P, T et espace sont saisis sans pause ni changement des missions : " + id + "/" + editor.text + "/" + app.demo.overlay_kind + "/" + str(tracker.is_expanded()) + "/" + str(expanded))
	var wrong: String = {"python": "input", "html": "p", "markdown": "*"}[id]
	await _choose(id + "_answer", wrong)
	await _activate(id + "_validate")
	_check(app.demo.overlay_kind == "challenge" and state.profile == before and not app.demo.challenge.feedback_label.text.is_empty(), "La mauvaise réponse explique l’erreur sans modifier la sauvegarde : " + id)
	await _check_modal_layout(id + " erreur")
	await _choose(id + "_answer", ANSWERS[id], id != "python")
	_check(preview.text == PREVIEWS[id], "Aperçu exact conservant les guillemets, balises ou dièse : " + id)
	_check(not submit.disabled, "Une réponse saisie autorise la validation : " + id)
	if id == "python":
		var draft := editor.text
		var original_modal: Vector2 = app.demo._modal_panel.size
		controllers.debug_connection_changed(0, false)
		await _frames(7)
		_check(app.demo.overlay_kind == "controller_pause", "Débrancher la manette suspend la saisie du code")
		controllers.debug_connection_changed(0, true)
		await _frames(4)
		await _activate("controller_resume")
		_check(app.demo.overlay_kind == "challenge" and editor.text == draft and keyboard.is_visible_in_tree(), "La reprise explicite restaure le clavier et le texte saisi")
		_check(app.demo._modal_panel.size.x >= original_modal.x - 1 and app.demo._modal_scroll.get_global_rect().grow(1).encloses(keyboard.get_global_rect()), "La reprise restaure la largeur du panneau et affiche toutes les touches du clavier")

	await _capture("chapter_3_" + id + "_challenge")
	saves.simulate_write_failure = true
	await _activate(id + "_validate")
	saves.simulate_write_failure = false
	_check(app.demo.overlay_kind == "challenge" and state.profile == before and saves.read_profile(profile_id).data == before, "Échec de sauvegarde : exercice encore ouvert sans réussite ni points : " + id)
	await _physical_text(editor, PREVIEWS[id])
	_check(editor.text == PREVIEWS[id] and preview.text == PREVIEWS[id], "La ligne complète se saisit aussi au clavier physique : " + id)
	await _activate(id + "_validate", true)
	_check(state.profile.progress.completed_missions.has(id) and state.profile.wallet.points == before.wallet.points + 50, "Le bouton natif valide une vraie solution et 50 points : " + id)
	_check(state.profile.progress.checkpoint_id == id and saves.read_profile(profile_id).data == state.profile, "La réussite enregistre son checkpoint : " + id)
	var world = app.demo.world
	var target: Node2D = world.get_interactable(id)
	_check(target != null and not target.visible and not target.highlighted and world.target_id.is_empty(), "Marqueur et cible de mission disparaissent pendant le succès : " + id)
	var prompt := _find("game_target_panel")
	_check(prompt != null and not prompt.visible and not world._can_reach(target, 1000), "Ni prompt fantôme ni interaction d’une mission terminée : " + id)
	_check(bool(world.get(id + "_restored")), "Le décor conserve la réussite visuelle : " + id)
	await _activate("dialog_continue")
	await _frames(5)
	_check(settings.apply_settings(original).ok, "Réglages restaurés après " + id)
	root.size = Vector2i(1280, 720)
	await _frames(8)


func _test_resume(checkpoint: String) -> void:
	var saved: Dictionary = state.profile.duplicate(true)
	var previous = weakref(app.demo.world)
	await _key(KEY_P)
	await _activate("pause_menu")
	await _frames(6)
	_check(app.screen == "home" and previous.get_ref() == null, "Le menu libère le monde avant une reprise réelle")
	await _activate("continue_game")
	await _frames(8)
	await _physics_frames(3)
	_check(state.profile == saved and app.demo.world.chapter_id == 3 and saved.progress.checkpoint_id == checkpoint, "Continuer recharge le chapitre code au checkpoint " + checkpoint)
	_check(app.demo.world.player.position.is_equal_approx(app.demo.world.CHAPTER_THREE_CHECKPOINTS[checkpoint]), "Le personnage reprend devant le bon poste : " + checkpoint)
	if app.demo.overlay_kind == "conclusion":
		await _activate("conclusion_stay")
	if checkpoint != "elevator":
		var target: Node2D = app.demo.world.get_interactable(checkpoint)
		_check(not target.visible and not target.highlighted and app.demo.world.target_id != checkpoint, "La reprise n’affiche pas le marqueur déjà terminé : " + checkpoint)
	await _check_tracker(3 if checkpoint == "elevator" else THIRD.find(checkpoint) + 1)


func _check_tracker(completed: int) -> void:
	var tracker := _find("mission_tracker")
	var progress := _find("mission_progress") as ProgressBar
	var label := _find("mission_chapter") as Label
	_check(tracker != null and tracker.is_visible_in_tree() and label != null and label.text.contains("3"), "Le panneau annonce le chapitre code")
	_check(progress != null and progress.max_value == 3 and progress.value == completed, "Le compteur local affiche %d/3" % completed)
	for id in THIRD:
		_check(_find("mission_name_" + id) != null and _find("mission_status_" + id) != null, "Mission code et état présents dans le panneau : " + id)
	for id in FIRST + SECOND:
		_check(_find("mission_name_" + id) == null, "Le panneau code exclut la mission d’un ancien étage : " + id)
	var expanded: bool = tracker.is_expanded()
	await _key(KEY_T)
	_check(tracker.is_expanded() != expanded, "T replie ou déplie les trois missions code")
	await _joy(JOY_BUTTON_Y)
	_check(tracker.is_expanded() == expanded, "La face haute de la manette commande le même panneau")


func _test_compact_hud() -> void:
	var original: Dictionary = settings.committed.duplicate(true)
	for resolution in [Vector2i(1280, 720), Vector2i(800, 480)]:
		for large in [false, true]:
			var values: Dictionary = original.duplicate(true)
			values.large_text = large
			values.reduce_motion = true
			_check(settings.apply_settings(values).ok, "Réglages compacts du tableau code")
			root.size = resolution
			await _frames(10)
			for id in ["mission_board", "game_objectives", "mission_chapter", "mission_progress", "game_pause"]:
				var control := _find(id)
				_check(control != null and control.is_visible_in_tree() and Rect2(Vector2.ZERO, Vector2(root.size)).grow(1).encloses(control.get_global_rect()), "HUD dans l’écran %s, grand texte=%s : %s" % [resolution, large, id])
			await _approach("elevator")
			await _key(KEY_SPACE)
			await _check_modal_layout("ascenseur " + str(resolution) + " " + str(large))
			await _key(KEY_ESCAPE)
			if resolution == Vector2i(800, 480) and large:
				await _capture("chapter_3_800x480_large")
	_check(settings.apply_settings(original).ok, "Réglages initiaux restaurés")
	root.size = Vector2i(1280, 720)
	await _frames(8)


func _test_round_trips() -> void:
	var saved: Dictionary = state.profile.duplicate(true)
	for chapter in [1, 2, 3]:
		await _travel(chapter)
		_check(state.profile.progress.completed_missions == saved.progress.completed_missions and state.profile.wallet == saved.wallet and state.profile.rewarded_missions == saved.rewarded_missions, "Les retours libres conservent toutes les réussites et les points")
	for id in THIRD:
		_check(not app.demo.world.get_interactable(id).visible, "Après les retours, le marqueur terminé reste masqué : " + id)


func _complete_service(id: String) -> void:
	_check(investigation.begin_mission(id).ok, "Préparer mission antérieure : " + id)
	var definition: Dictionary = investigation.mission(id)
	for observation in definition.observations:
		_check(investigation.observe(id, observation.id).ok, "Préparer observation : " + observation.id)
	var result: Dictionary
	match id:
		"lighting": result = investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"])
		"lock": result = investigation.submit_lock("control_link", "reconnect_control")
		"computer":
			for check_id in ["power", "video"]:
				_check(investigation.check_computer(check_id).ok, "Préparer vérification ordinateur")
			result = investigation.submit_computer(["power", "video"], "video_disconnected", "reconnect_video")
		_: result = investigation.submit_diagnostic(id, definition.solution.diagnosis, definition.solution.repair)
	_check(result.ok, "Solution antérieure réellement validée : " + id)


func _approach(id: String) -> void:
	var world = app.demo.world
	var points: Dictionary = world.CHAPTER_FOUR_CHECKPOINTS if world.chapter_id == 4 else (world.CHAPTER_THREE_CHECKPOINTS if world.chapter_id == 3 else (world.CHAPTER_TWO_CHECKPOINTS if world.chapter_id == 2 else world.CHECKPOINTS))
	_check(points.has(id), "Checkpoint de proximité pour " + id)
	if not points.has(id):
		return
	world.player.position = points[id]
	await _physics_frames(3)
	await _frames(3)
	_check(world.target_id == id, "La physique sélectionne la cible proche : " + id)


func _point_clear(at: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = at
	query.collision_mask = 1
	return app.demo.world.get_world_2d().direct_space_state.intersect_point(query).is_empty()


func _walk_axis(code: Key, distance: float) -> void:
	# Observe the real distance instead of assuming instant constant velocity.
	# An early physical obstacle still ends the walk and is checked by callers.
	if not router.gameplay_allowed(): await create_timer(.23).timeout
	var player = app.demo.world.player
	var start: Vector2 = player.position
	var previous := start
	var stalled := 0
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	var maximum_steps := ceili(distance * 60.0 / player.SPEED) + 40
	for step in range(maximum_steps):
		await physics_frame
		var current: Vector2 = player.position
		if current.distance_to(start) >= distance - 1.5: break
		stalled = stalled + 1 if current.distance_to(previous) < .01 else 0
		if stalled >= 8: break
		previous = current
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _physics_frames(2)


func _choose(id: String, metadata: String, joy: bool = false) -> void:
	var editor := _find(id) as LineEdit
	_check(editor != null and editor.editable, "Saisie native disponible : " + id)
	if editor == null or not editor.editable:
		return
	var keyboard = app.demo.challenge.code_keyboard
	var value := "#" if metadata == "hash" else metadata
	editor.grab_focus()
	editor.select_all()
	await _frames(3)
	for character in value:
		if character.to_lower() in "azertyuiopqsdfghjklmwxcvbn":
			if keyboard.input_mode != "letters": await _activate("key_123", joy)
			if character == character.to_upper() and keyboard.shift_state == 0: await _activate("key_Shift", joy)
			elif character == character.to_lower() and keyboard.shift_state > 0: await _activate("key_Shift", joy)
		var key: BaseButton = _character_key(keyboard, character)
		for attempt in range(3):
			if key != null: break
			await _activate("key_123" if keyboard.input_mode == "letters" else ("key_Symbols" if keyboard.input_mode == "numbers" else "key_Numbers"), joy)
			key = _character_key(keyboard, character)
		_check(key != null, "Caractère proposé par le clavier à l’écran : " + character)
		if key == null: return
		await _activate(str(key.name), joy)
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).grow(1).encloses(editor.get_global_rect()), "La réponse reste visible pendant la saisie virtuelle : " + id)
	_check(editor.text == value, "Réponse réellement tapée à l’écran : " + id)


func _character_key(keyboard: Node, character: String) -> BaseButton:
	for node in keyboard.find_children("*", "BaseButton", true, false):
		if node.is_visible_in_tree() and node.text == character: return node
	return null


func _physical_text(editor: LineEdit, value: String) -> void:
	editor.grab_focus()
	editor.select_all()
	await _frames(3)
	for character in value:
		var event := InputEventKey.new()
		event.keycode = character.to_upper().unicode_at(0)
		event.unicode = character.unicode_at(0)
		event.pressed = true
		Input.parse_input_event(event)
		await _frames(1)
		event = event.duplicate()
		event.pressed = false
		Input.parse_input_event(event)
		await _frames(1)
	await _frames(4)


func _activate(id: String, joy: bool = false) -> bool:
	var control := _find(id) as BaseButton
	_check(control != null and control.is_visible_in_tree() and not control.disabled, "Commande native utilisable : " + id)
	if control == null or control.disabled or not control.is_visible_in_tree():
		return false
	control.grab_focus()
	await _frames(5)
	if joy:
		await _joy(JOY_BUTTON_A)
	else:
		await _key(KEY_ENTER)
	await _frames(3)
	return true


func _check_modal_layout(context: String) -> void:
	_check(not app.demo.overlay_kind.is_empty(), "Dialogue disponible pour vérifier la géométrie : " + context)
	for control in app._focusables(app.demo.modal_content):
		control.grab_focus()
		await _frames(5)
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).grow(1).encloses(control.get_global_rect()), "Commande focalisée visible : " + context + "/" + str(control.name))


func _find(id: String, node: Node = null) -> Control:
	if node == null:
		node = app
	if node is Control and str(node.name) == id:
		return node
	for child in node.get_children():
		var found := _find(id, child)
		if found != null:
			return found
	return null


func _key(code: Key) -> void:
	if not router.gameplay_allowed():
		await create_timer(.23).timeout
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(2)
	await physics_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(4)


func _joy(code: JoyButton) -> void:
	if not router.gameplay_allowed():
		await create_timer(.23).timeout
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = code
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(2)
	await physics_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(4)


func _hold(code: Key, count: int) -> void:
	if not router.gameplay_allowed():
		await create_timer(.23).timeout
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await _physics_frames(count)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _physics_frames(2)


func _frames(count: int) -> void:
	for index in range(count):
		await process_frame


func _physics_frames(count: int) -> void:
	for index in range(count):
		await physics_frame


func _capture(id: String) -> void:
	if not captures or not id.ends_with("_challenge"):
		return
	await _frames(4)
	await RenderingServer.frame_post_draw
	var directory := OS.get_environment("CIEL_CAPTURE_DIR")
	_check(not directory.is_empty(), "Dossier de capture explicitement fourni")
	if directory.is_empty():
		return
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) == OK, "Dossier des captures créé")
	var image := root.get_texture().get_image()
	_check(image != null and not image.is_empty(), "Rendu natif disponible : " + id)
	if image != null and not image.is_empty():
		_check(image.save_png(directory.path_join(id + ".png")) == OK, "Capture native enregistrée : " + id)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("CODE_CHAPTER_UI_FAIL : " + label)


func _remove_tree(path: String) -> void:
	if test_root.is_empty() or not path.begins_with(test_root):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for filename in directory.get_files():
		directory.remove(filename)
	for child in directory.get_directories():
		_remove_tree(path.path_join(child))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _finish() -> void:
	saves.simulate_write_failure = false
	await _frames(4)
	if is_instance_valid(app):
		root.remove_child(app)
		app.queue_free()
	await _frames(5)
	controllers.debug_clear_devices()
	for player in [settings._music_player, settings._effect_player]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	state.clear_profile()
	_remove_tree(test_root)
	await create_timer(.15).timeout
	await _frames(4)
	print("CODE_CHAPTER_UI : %d assertions, %d échec(s)." % [checks, failures.size()])
	print("Manette simulée par événements natifs ; matériel physique non testé.")
	quit.call_deferred(0 if failures.is_empty() else 1)
