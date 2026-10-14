extends SceneTree
## Real rooms, physics, native input and saved educational rewards.
## All profiles/settings live below a unique user://tests folder.
## Optional native viewport images: CIEL_CAPTURE_DIR=/tmp/captures -- --screenshots

const Appearance := preload("res://scripts/ui/appearance_palette.gd")
const FIRST := ["lighting", "lock", "computer"]
const SECOND := ["network", "addressing", "security"]
const OBSERVATIONS := {
	"lock": ["badge", "power", "command", "link"],
	"computer": ["pc", "display", "no_signal"],
	"network": ["switch", "link", "cable"],
	"addressing": ["workstation", "gateway", "allocation"],
	"security": ["wifi", "compatibility", "passphrase"]
}
const ANSWERS := {
	"network": ["cable_unplugged", "reconnect_rj45"],
	"addressing": ["wrong_subnet", "align_subnet"],
	"security": ["open_wifi", "enable_encryption"]
}

var checks := 0
var failures: Array[String] = []
var app
var saves
var profiles
var settings
var state
var investigation
var shop
var router
var controllers
var test_root := ""
var first_id := ""
var other_id := ""
var captures := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	# Use the engine's event queue in both backends. A press must reach a full
	# process/physics cycle before release; otherwise synthetic just_pressed
	# events can expire before DemoGame._process on the graphical backend.
	Input.use_accumulated_input = true
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	settings = root.get_node("SettingsService")
	state = root.get_node("AppState")
	investigation = root.get_node("InvestigationService")
	shop = root.get_node("ShopService")
	router = root.get_node("SceneRouter")
	controllers = root.get_node("ControllerService")
	controllers.debug_set_devices([0])
	test_root = "user://tests/chapter_ui_%s" % Time.get_ticks_usec()
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	print("CHAPTER_UI_DATA : ", ProjectSettings.globalize_path(test_root))
	root.size = Vector2i(1280, 720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(35)
	var created: Dictionary = profiles.create_profile("Voyage CIEL")
	_check(created.ok, "Profil isolé créé pour le parcours éducatif")
	if not created.ok:
		await _finish()
		return
	first_id = str(created.data.id)
	app._show_screen("home")
	await _frames(6)
	await _activate("new_game")
	_check(app.screen == "game" and is_instance_valid(app.demo), "L’accueil ouvre une nouvelle enquête native")
	if not is_instance_valid(app.demo):
		await _finish()
		return
	_check(investigation.chapter_missions(1).size() == 3 and investigation.chapter_missions(2).size() == 3, "Six missions éducatives réparties dans deux chapitres")
	await _check_tracker(1, 0)
	await _test_tracker_input()
	await _test_elevator_blocked(0)
	await _solve_first("lighting")
	if not state.profile.progress.completed_missions.has("lighting"):
		await _finish()
		return
	await _test_elevator_blocked(1)
	await _solve_first("lock")
	await _test_elevator_blocked(2)
	await _solve_first("computer")
	_check(app.demo.overlay_kind == "conclusion", "Le troisième défi ouvre un bilan sans changer automatiquement d’étage")
	_check(state.profile.progress.room_id == "room_01" and state.profile.wallet.points == 150, "Le chapitre 1 rapporte 150 points et conserve sa salle")
	await _activate("conclusion_stay")
	await _check_tracker(1, 3)
	await _test_elevator_path()
	await _capture("chapter_1_elevator_unlocked")
	await _travel(2, true)
	await _check_tracker(2, 0)
	await _test_second_room()
	await _capture("chapter_2_arrival_missions")
	await _solve_second("network", true)
	await _test_checkpoint_restart("network")
	await _solve_second("addressing", true)
	await _test_checkpoint_restart("addressing")
	await _solve_second("security", true)
	_check(state.profile.wallet.points == 300 and state.profile.rewarded_missions.size() == 6, "Six réussites donnent 300 points avec six identifiants de récompense uniques")
	_check(state.profile.progress.run_reward_points == 300 and state.profile.progress.completed_missions.size() == 6, "Les gains de partie comprennent les deux chapitres")
	_check(saves.read_profile(first_id).data == state.profile, "Le parcours complet et les points sont enregistrés ensemble")
	if app.demo.overlay_kind == "conclusion":
		await _activate("conclusion_stay")
	await _check_tracker(2, 3)
	await _capture("chapter_2_completed_missions")
	await _test_compact_layouts()
	await _test_shop_and_isolation()
	await _test_replay()
	await _finish()


func _check_tracker(chapter: int, completed: int) -> void:
	var tracker := _find("mission_tracker")
	_check(tracker != null and tracker.is_visible_in_tree(), "Tableau de missions visible dans la salle du chapitre %d" % chapter)
	var chapter_label := _find("mission_chapter") as Label
	_check(chapter_label != null and chapter_label.text.contains(str(chapter)), "Le panneau annonce le chapitre réellement chargé")
	var progress := _find("mission_progress") as ProgressBar
	_check(progress != null and progress.max_value == 3 and progress.value == completed, "Le compteur du chapitre %d affiche %d/3, sans compter l’autre étage" % [chapter, completed])
	for mission_id in FIRST if chapter == 1 else SECOND:
		_check(_find("mission_name_" + mission_id) != null and _find("mission_status_" + mission_id) != null, "Une ligne et un état pour la mission locale " + mission_id)
	for mission_id in SECOND if chapter == 1 else FIRST:
		_check(_find("mission_name_" + mission_id) == null, "Le panneau ne mêle pas les missions de l’autre étage : " + mission_id)
	var board := _find("mission_board") as Control
	if board != null:
		var bounds := board.get_global_rect()
		_check(bounds.position.x > root.size.x * 0.5 and bounds.end.x <= root.size.x + 1, "Le tableau est placé à droite de l’écran")


func _test_tracker_input() -> void:
	_check(InputMap.has_action("game_missions"), "Action dédiée au panneau de missions")
	var tracker := _find("mission_tracker")
	if tracker == null:
		return
	var original: bool = tracker.is_expanded()
	var room := _find("game_room") as Control
	room.grab_focus()
	var position: Vector2 = app.demo.world.get_player_position()
	await _key(KEY_T)
	_check(tracker.is_expanded() != original and not app.demo.paused and app.demo.overlay_kind.is_empty(), "T replie le panneau sans suspendre l’enquête")
	_check(root.gui_get_focus_owner() == room, "Le raccourci du tableau conserve le focus de déplacement")
	await _hold(KEY_RIGHT, 8)
	_check(app.demo.world.get_player_position() != position, "Le personnage continue à marcher lorsque le tableau est replié")
	await _joy(JOY_BUTTON_Y)
	_check(tracker.is_expanded() == original, "La touche du haut Y / Triangle déplie le même tableau")
	await _joy(JOY_BUTTON_Y, 1)
	_check(tracker.is_expanded() == original, "Une manette secondaire ne bascule pas le tableau de la manette active")
	var joy_event := InputEventJoypadButton.new()
	joy_event.device = 0
	joy_event.button_index = JOY_BUTTON_Y
	joy_event.pressed = true
	Input.parse_input_event(joy_event)
	await _frames(2)
	var joy_held: bool = tracker.is_expanded()
	Input.parse_input_event(joy_event.duplicate())
	await _frames(2)
	_check(tracker.is_expanded() == joy_held, "Un bouton de manette maintenu ne rebascule pas le tableau")
	joy_event.pressed = false
	Input.parse_input_event(joy_event)
	await _frames(2)
	await _joy(JOY_BUTTON_Y)
	_check(tracker.is_expanded() == original, "Une nouvelle pression de la face haute fonctionne après relâchement")
	var event := InputEventKey.new()
	event.keycode = KEY_T
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(2)
	var held_value: bool = tracker.is_expanded()
	event = event.duplicate()
	event.echo = true
	for repeat in range(4):
		Input.parse_input_event(event)
		await process_frame
	_check(tracker.is_expanded() == held_value, "La répétition clavier ne fait pas clignoter le tableau")
	event.echo = false
	Input.parse_input_event(event)
	await _frames(2)
	_check(tracker.is_expanded() == held_value, "Un second événement pressé sans relâchement ne rebascule pas le tableau")
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(2)
	await _key(KEY_T)
	_check(tracker.is_expanded() == original, "Un nouvel appui après relâchement rebascule une seule fois")
	await _key(KEY_P)
	var focus_before: Control = root.gui_get_focus_owner()
	var pause_value: bool = tracker.is_expanded()
	await _key(KEY_T)
	await _joy(JOY_BUTTON_Y)
	_check(app.demo.paused and tracker.is_expanded() == pause_value and root.gui_get_focus_owner() == focus_before, "T et la face haute laissent le tableau et le focus inchangés pendant la pause")
	await _key(KEY_ESCAPE)
	root.close_requested.emit()
	await _frames(5)
	_check(is_instance_valid(app.modal), "Une confirmation globale existe pour vérifier l’isolation des raccourcis")
	await _key(KEY_T)
	await _joy(JOY_BUTTON_Y)
	_check(is_instance_valid(app.modal) and tracker.is_expanded() == pause_value, "La confirmation globale possède les commandes du panneau")
	if is_instance_valid(app.modal):
		_check(app.modal.is_ancestor_of(root.gui_get_focus_owner()), "Les touches du tableau ne volent pas le focus de la confirmation")
		await _key(KEY_ESCAPE)
	if app.demo.overlay_kind == "pause":
		await _key(KEY_ESCAPE)
	app.demo.world.player.position = app.demo.world.CHECKPOINTS.entrance
	await _physics_frames(3)


func _test_elevator_blocked(completed: int) -> void:
	var before: Dictionary = state.profile.duplicate(true)
	_check(not investigation.can_use_elevator(), "Ascenseur métier verrouillé après %d mission(s)" % completed)
	await _approach("elevator")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "dialog" and _find("elevator_travel") == null, "L’ascenseur explique le verrouillage sans proposer de changement d’étage : %d/3" % completed)
	_check(state.profile == before and saves.read_profile(first_id).data == before, "Examiner l’ascenseur bloqué ne modifie ni la salle ni les points")
	var tracker := _find("mission_tracker")
	var expanded: bool = tracker.is_expanded() if tracker != null else false
	await _key(KEY_T)
	await _joy(JOY_BUTTON_Y)
	_check(tracker != null and tracker.is_expanded() == expanded and app.demo.overlay_kind == "dialog", "Le dialogue d’ascenseur n’est pas traversé par les raccourcis du panneau")
	await _key(KEY_ESCAPE)


func _solve_first(id: String) -> void:
	await _approach(id)
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "challenge", "Un équipement ouvre le défi pédagogique : " + id)
	if app.demo.overlay_kind != "challenge":
		return
	if id == "lighting":
		for connection in ["source_switch", "switch_lamp", "lamp_return"]:
			await _activate("light_connection_" + connection)
		await _activate("light_validate")
	elif id == "lock":
		for observation in OBSERVATIONS[id]:
			await _activate("observation_" + observation)
		await _choose("lock_diagnosis", "control_link")
		await _choose("lock_repair", "reconnect_control")
		await _activate("lock_validate")
	else:
		for observation in OBSERVATIONS[id]:
			await _activate("observation_" + observation)
		for verification in ["power", "video"]:
			await _activate("computer_check_" + verification)
		await _choose("computer_cause", "video_disconnected")
		await _choose("computer_correction", "reconnect_video")
		await _activate("computer_validate")
	_check(state.profile.progress.completed_missions.has(id), "Le défi natif valide sa mission : " + id)
	await _activate("dialog_continue")
	await _frames(4)


func _test_elevator_path() -> void:
	var world = app.demo.world
	var elevator = world.get_interactable("elevator")
	_check(elevator != null and elevator.position.x > 640 and elevator.position.y > 360, "L’ascenseur est en bas de la seconde pièce, dans le bureau")
	_check(investigation.can_use_elevator(), "Les trois missions débloquent l’ascenseur")
	world.player.position = Vector2(835, 335)
	await _physics_frames(3)
	await _hold(KEY_DOWN, 25)
	_check(world.get_player_position().y > 395 and world.target_id == "elevator", "Le joueur atteint l’ascenseur en marchant dans le bureau, sans obstacle invisible")
	_check(_point_clear(world.get_player_position()), "Le point d’interaction de l’ascenseur n’est pas situé dans une collision")


func _travel(chapter: int, with_errors: bool = false) -> void:
	var before: Dictionary = state.profile.duplicate(true)
	await _approach("elevator")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "elevator" and _find("elevator_travel") != null, "Un ascenseur débloqué propose le déplacement vers le chapitre %d" % chapter)
	_check(state.profile == before, "L’ouverture de l’ascenseur attend une confirmation avant de déplacer le joueur")
	if with_errors:
		saves.simulate_write_failure = true
		await _activate("elevator_travel")
		saves.simulate_write_failure = false
		_check(state.profile == before and saves.read_profile(first_id).data == before and app.demo.world.chapter_id != chapter and app.demo.overlay_kind == "dialog", "Un échec de sauvegarde d’ascenseur conserve le monde et la progression précédents")
		await _activate("dialog_continue")
		_check(app.demo.overlay_kind == "elevator", "Le dialogue d’échec permet de réessayer le déplacement")
	await _activate("elevator_travel", true)
	await _physics_frames(4)
	await _frames(5)
	_check(state.profile.progress.room_id == "room_0%d" % chapter and investigation.current_chapter() == chapter and app.demo.world.chapter_id == chapter, "La salle affichée, le service et la sauvegarde changent de chapitre ensemble")
	_check(state.profile.progress.checkpoint_id == "elevator" and app.demo.overlay_kind.is_empty(), "L’arrivée à l’étage conserve le checkpoint ascenseur sans dialogue ouvert")
	_check(state.profile.wallet == before.wallet and state.profile.rewarded_missions == before.rewarded_missions, "L’ascenseur n’attribue aucun gain supplémentaire")
	_check(saves.read_profile(first_id).data == state.profile, "Le déplacement d’étage est persisté")


func _test_second_room() -> void:
	var world = app.demo.world
	_check(world.room_id == "room_02" and world.chapter_id == 2, "Le monde reconstruit la salle du chapitre 2")
	_check(world.get_interactable("lighting") == null and world.get_interactable("computer") == null, "Les cibles du rez-de-chaussée sont remplacées à l’étage")
	for prop in ["NetworkRack", "AddressingDesk", "WirelessStation", "Elevator"]:
		var body := world._props.get_node_or_null(prop) as StaticBody2D
		_check(body != null and body.collision_layer == 1, "Le meuble dessiné possède une collision réelle : " + prop)
		if body != null:
			var shape_count := 0
			var visual_count := 0
			for child in body.get_children():
				if child is CollisionShape2D and child.shape != null:
					shape_count += 1
				if child is Sprite2D and child.texture != null and child.scale.x > 0 and child.scale.y > 0:
					visual_count += 1
			_check(shape_count > 0 and visual_count > 0, "Visuel et collision sont associés au même objet d’étage : " + prop)
	for id in SECOND:
		var target = world.get_interactable(id)
		_check(target != null, "L’équipement du chapitre 2 possède une cible réelle : " + id)
		await _approach(id)
		_check(_point_clear(world.get_player_position()), "Checkpoint de mission utilisable hors du mobilier : " + id)
	_check(investigation.mission_state("network") == "available" and investigation.mission_state("addressing") == "locked" and investigation.mission_state("security") == "locked", "Le second chapitre conserve des missions à prérequis")
	var before: Dictionary = state.profile.duplicate(true)
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "dialog" and state.profile == before, "La sécurité ne peut être résolue avant les missions réseau")
	await _key(KEY_ESCAPE)
	world.player.position = Vector2(70, 430)
	await _physics_frames(3)
	await _hold(KEY_LEFT, 18)
	_check(world.get_player_position().x >= 54 - .3, "Les murs du nouvel étage bloquent réellement le personnage")
	await _approach("elevator")


func _solve_second(id: String, with_errors: bool) -> void:
	var original_settings: Dictionary = settings.committed.duplicate(true)
	var original_size := root.size
	if with_errors and id in ["addressing", "security"]:
		var values: Dictionary = original_settings.duplicate(true)
		values.large_text = id == "addressing"
		values.reduce_motion = true
		if id == "addressing":
			values.appearance_style = "nuit"
		_check(settings.apply_settings(values).ok, "Lecture du nouveau défi sur un écran réduit : " + id)
		root.size = Vector2i(800, 480) if id == "addressing" else Vector2i(1024, 600)
		await _frames(8)
	var before: Dictionary = state.profile.duplicate(true)
	await _approach(id)
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "challenge" and _find(id + "_validate") != null, "Le défi d’étage présente ses commandes natives : " + id)
	if _find(id + "_validate") == null:
		return
	var diagnosis := _find(id + "_diagnosis") as OptionButton
	_check(diagnosis != null and diagnosis.disabled, "Le diagnostic exige d’observer l’équipement avant de choisir : " + id)
	var tracker := _find("mission_tracker")
	var expanded: bool = tracker.is_expanded() if tracker != null else false
	var focus_before: Control = root.gui_get_focus_owner()
	await _key(KEY_T)
	await _joy(JOY_BUTTON_Y)
	_check(tracker != null and tracker.is_expanded() == expanded and app.demo.overlay_kind == "challenge" and root.gui_get_focus_owner() == focus_before, "Le tableau ne détourne pas les commandes du défi " + id)
	for observation in OBSERVATIONS[id]:
		await _activate("observation_" + observation)
	_check(state.profile.progress.observations[id].size() == 3, "Les trois observations du nouveau défi sont sauvegardées : " + id)
	if with_errors:
		await _check_modal_layout(id + "_" + str(root.size))
		_check_feedback(false, id)
	if with_errors:
		var wrong := _other_choice(id + "_diagnosis", ANSWERS[id][0])
		await _choose(id + "_diagnosis", wrong)
		await _choose(id + "_repair", ANSWERS[id][1])
		await _activate(id + "_validate")
		_check(not state.profile.progress.completed_missions.has(id) and state.profile.wallet == before.wallet and app.demo.overlay_kind == "challenge", "Un mauvais diagnostic explique l’erreur sans points ni mission terminée : " + id)
		_check(not app.demo.challenge.feedback_label.text.is_empty(), "La mauvaise hypothèse reçoit une explication pédagogique : " + id)
		_check_feedback(true, id)
		await _capture("chapter_2_" + id + "_challenge")
	await _choose(id + "_diagnosis", ANSWERS[id][0])
	await _choose(id + "_repair", ANSWERS[id][1])
	if with_errors:
		var prepared: Dictionary = state.profile.duplicate(true)
		saves.simulate_write_failure = true
		await _activate(id + "_validate")
		saves.simulate_write_failure = false
		_check(state.profile == prepared and saves.read_profile(first_id).data == prepared and app.demo.overlay_kind == "challenge", "Échec d’écriture : défi, progression et portefeuille conservés ensemble : " + id)
	await _activate(id + "_validate", true)
	_check(state.profile.progress.completed_missions.has(id), "Observations et solution valident réellement la nouvelle mission : " + id)
	var expected_reward := 0 if id in before.rewarded_missions else 50
	_check(state.profile.wallet.points == before.wallet.points + expected_reward, "Le nouveau défi attribue exactement sa récompense unique : " + id)
	_check(saves.read_profile(first_id).data == state.profile, "La récompense d’étage est persistée avec sa mission : " + id)
	await _activate("dialog_continue")
	await _frames(4)
	if root.size != original_size:
		_check(settings.apply_settings(original_settings).ok, "Lecture restaurée après le défi natif " + id)
		root.size = original_size
		await _frames(8)


func _check_feedback(is_error: bool, id: String) -> void:
	var feedback := app.demo.challenge.feedback_label as Label
	_check(feedback.is_visible_in_tree() and feedback.text.begins_with("! " if is_error else "ℹ "), "Le retour pédagogique visible distingue information et erreur sans dépendre de sa couleur : " + id)
	var panel := app.demo._modal_panel.get_theme_stylebox("panel") as StyleBoxFlat
	_check(panel != null, "Le fond réel du défi est disponible pour mesurer son contraste")
	if panel != null:
		var ratio := Appearance.contrast_ratio(feedback.get_theme_color("font_color"), panel.bg_color)
		_check(ratio >= 4.5, "Retour pédagogique lisible (contraste %.2f), thème %s : %s" % [ratio, settings.current.appearance_style, id])


func _test_checkpoint_restart(id: String) -> void:
	var saved: Dictionary = state.profile.duplicate(true)
	var previous_world = weakref(app.demo.world)
	await _key(KEY_P)
	await _activate("pause_menu")
	await _frames(5)
	_check(app.screen == "home" and not (_find("continue_game") as Button).disabled, "Retour au menu après le défi d’étage " + id)
	_check(previous_world.get_ref() == null, "Le menu détruit le monde précédent : la reprise doit relire sa sauvegarde")
	await _activate("continue_game")
	await _frames(7)
	await _physics_frames(3)
	_check(state.profile == saved and app.demo.world.chapter_id == 2 and state.profile.progress.checkpoint_id == id, "Continuer restaure la salle du deuxième chapitre et son checkpoint : " + id)
	_check(app.demo.world.get_player_position().is_equal_approx(app.demo.world.CHAPTER_TWO_CHECKPOINTS[id]), "Le personnage reprend au bon équipement d’étage : " + id)
	await _check_tracker(2, 1 if id == "network" else 2)


func _test_compact_layouts() -> void:
	var original: Dictionary = settings.committed.duplicate(true)
	for resolution in [Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(800, 480)]:
		for large in [false, true]:
			var values: Dictionary = original.duplicate(true)
			values.large_text = large
			values.reduce_motion = true
			_check(settings.apply_settings(values).ok, "Mode de lecture enregistré pour vérifier l’interface de jeu")
			root.size = resolution
			await _frames(10)
			var tracker := _find("mission_tracker")
			if tracker != null and not tracker.is_expanded():
				await _key(KEY_T)
			for id in ["mission_board", "game_objectives", "mission_chapter", "mission_progress", "game_pause", "game_interact"]:
				var control := _find(id) as Control
				_check(control != null and control.is_visible_in_tree() and Rect2(Vector2.ZERO, Vector2(root.size)).grow(1).encloses(control.get_global_rect()), "HUD dans l’écran %s, grands textes=%s : %s" % [resolution, large, id])
			await _key(KEY_T)
			_check(tracker != null and not tracker.is_expanded(), "Le panneau se replie dans chaque résolution et mode de lecture")
			var board := _find("mission_board") as Control
			_check(board != null and Rect2(Vector2.ZERO, Vector2(root.size)).grow(1).encloses(board.get_global_rect()), "Le bouton du tableau replié reste visible")
			if not large:
				await _key(KEY_T)
			await _capture("chapter_2_%dx%d_%s" % [resolution.x, resolution.y, "large_folded" if large else "normal_expanded"])
			await _approach("elevator")
			await _key(KEY_SPACE)
			await _check_modal_layout("elevator_" + str(resolution) + "_" + str(large))
			await _key(KEY_ESCAPE)
			await _key(KEY_P)
			await _check_modal_layout("pause_" + str(resolution) + "_" + str(large))
			await _key(KEY_ESCAPE)
	_check(settings.apply_settings(original).ok, "Réglages restaurés après vérification du petit écran")
	root.size = Vector2i(1280, 720)
	await _frames(8)


func _test_shop_and_isolation() -> void:
	await _key(KEY_P)
	await _activate("pause_menu")
	await _activate("home_shop")
	var before: Dictionary = state.profile.duplicate(true)
	await _activate("product_game_test_1")
	await _activate("modal_confirm")
	_check(state.profile.wallet.points == before.wallet.points - 20 and "game_test_1" in state.profile.owned_items, "Les points du chapitre 2 servent à un achat natif dans la boutique")
	_check(state.profile.progress == before.progress and saves.read_profile(first_id).data == state.profile, "La boutique conserve la progression des deux étages")
	await _key(KEY_ESCAPE)
	var completed: Dictionary = state.profile.duplicate(true)
	var other: Dictionary = profiles.create_profile("Autre étage")
	_check(other.ok, "Second profil créé pour vérifier l’isolation des chapitres")
	if not other.ok:
		return
	other_id = str(other.data.id)
	_check(state.profile.progress.room_id == "room_01" and state.profile.progress.completed_missions.is_empty() and state.profile.wallet.points == 0, "Un autre profil commence au rez-de-chaussée sans progression ni points hérités")
	_check(not investigation.can_use_elevator() and not investigation.enter_chapter(2).ok, "Le second profil ne récupère pas l’ascenseur déverrouillé")
	_check(saves.read_profile(first_id).data == completed, "Changer de profil ne modifie pas l’enquête terminée du premier")
	_check(profiles.select_profile(first_id).ok and state.profile == completed, "Le premier profil retrouve sa salle, ses six missions et son achat")
	app._show_screen("home")
	await _frames(5)
	await _activate("continue_game")
	await _frames(5)
	_check(app.demo.world.chapter_id == 2, "La reprise du premier profil rouvre le chapitre 2 après changement de joueur")
	if app.demo.overlay_kind == "conclusion":
		await _activate("conclusion_stay")
	await _travel(1)
	await _check_tracker(1, 3)
	await _travel(2)
	await _check_tracker(2, 3)
	_check(state.profile.wallet.points == completed.wallet.points and state.profile.rewarded_missions == completed.rewarded_missions, "Aller-retour entre les étages terminés ne produit aucun doublon de récompense")


func _test_replay() -> void:
	var points: int = state.profile.wallet.points
	await _key(KEY_P)
	await _activate("pause_menu")
	await _activate("new_game")
	_check(is_instance_valid(app.modal) and state.profile.progress.completed_missions.size() == 6, "Recommencer demande confirmation et conserve encore les six missions")
	await _activate("modal_confirm")
	await _frames(6)
	_check(app.demo.world.chapter_id == 1 and state.profile.progress.completed_missions.is_empty() and not investigation.can_use_elevator(), "Le rejeu revient au rez-de-chaussée avec l’ascenseur verrouillé")
	_check(state.profile.wallet.points == points and state.profile.rewarded_missions.size() == 6 and "game_test_1" in state.profile.owned_items, "Recommencer conserve solde, achats et les six récompenses déjà gagnées")
	for id in FIRST:
		await _solve_first(id)
	if app.demo.overlay_kind == "conclusion":
		await _activate("conclusion_stay")
	await _travel(2)
	for id in SECOND:
		await _solve_second(id, false)
	_check(state.profile.wallet.points == points and state.profile.progress.run_reward_points == 0 and state.profile.rewarded_missions.size() == 6, "Rejouer les six défis n’accorde aucun second gain")
	_check(state.profile.progress.completed_missions.size() == 6 and saves.read_profile(first_id).data == state.profile, "Le rejeu complet des deux chapitres conserve une sauvegarde cohérente")


func _point_clear(at: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = at
	query.collision_mask = 1
	return app.demo.world.get_world_2d().direct_space_state.intersect_point(query).is_empty()


func _approach(id: String) -> void:
	var world = app.demo.world
	var points: Dictionary = world.CHAPTER_TWO_CHECKPOINTS if world.chapter_id == 2 else world.CHECKPOINTS
	_check(points.has(id), "Point d’approche défini pour " + id)
	if not points.has(id):
		return
	# The fixture only positions the player; all interactions use real physics
	# line of sight, targets and native input. Separate tests walk the elevator path.
	world.player.position = points[id]
	await _physics_frames(3)
	await _frames(3)
	_check(world.target_id == id, "La cible physique proche correspond à " + id)


func _other_choice(id: String, correct: String) -> String:
	var option := _find(id) as OptionButton
	if option != null:
		for index in range(1, option.item_count):
			var metadata := str(option.get_item_metadata(index))
			if metadata != correct:
				return metadata
	return ""


func _choose(id: String, metadata: String) -> void:
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
	_check(not app.demo.overlay_kind.is_empty(), "Dialogue disponible pour contrôler sa géométrie : " + context)
	for control in app._focusables(app.demo.modal_content):
		control.grab_focus()
		await _frames(5)
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).grow(1).encloses(control.get_global_rect()), "Commande focalisée visible dans le petit écran : %s/%s" % [context, control.name])


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


func _joy(code: JoyButton, device: int = 0) -> void:
	if not router.gameplay_allowed():
		await create_timer(.23).timeout
	var event := InputEventJoypadButton.new()
	event.device = device
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
	if not captures:
		return
	await _frames(4)
	await RenderingServer.frame_post_draw
	var directory := OS.get_environment("CIEL_CAPTURE_DIR")
	if directory.is_empty():
		directory = "res://docs/screenshots/chapitre_2_0.6.0"
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) == OK, "Dossier des captures de chapitre créé")
	var image := root.get_texture().get_image()
	_check(image != null and not image.is_empty(), "Le moteur a réellement rendu la salle : " + id)
	if image != null and not image.is_empty():
		_check(image.save_png(directory.path_join(id + ".png")) == OK, "Capture native enregistrée : " + id)


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("CHAPTER_UI_FAIL : " + message)


func _remove_tree(path: String) -> void:
	if test_root.is_empty() or not path.begins_with(test_root):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for child in directory.get_files():
		directory.remove(child)
	for child in directory.get_directories():
		_remove_tree(path.path_join(child))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _finish() -> void:
	await _frames(4)
	if is_instance_valid(app):
		root.remove_child(app)
		app.queue_free()
	await _frames(4)
	controllers.debug_clear_devices()
	for player in [settings._music_player, settings._effect_player]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_remove_tree(test_root)
	await create_timer(.15).timeout
	await _frames(4)
	print("CHAPTER_UI : %d assertions, %d échec(s)." % [checks, failures.size()])
	print("Manette simulée par événements natifs ; matériel physique non testé.")
	call_deferred("quit", 0 if failures.is_empty() else 1)
