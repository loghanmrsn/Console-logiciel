extends "res://tests/code_chapter_ui_tests.gd"
const Layout = preload("res://scripts/game/maze_layout.gd")
const FOURTH := ["firewall","ip_conflict","subnet_mask"]

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
	test_root = "user://tests/maze_ui_%s_%s" % [OS.get_process_id(),Time.get_ticks_usec()]
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var values: Dictionary = settings.committed.duplicate(true)
	values.reduce_motion = true
	_check(settings.apply_settings(values).ok,"Réglages isolés")
	var made: Dictionary = profiles.create_profile("Labyrinthe CIEL")
	if not made.ok:
		_check(false,"Profil créé")
		await _finish()
		return
	profile_id = str(made.data.id)
	_check(profiles.start_game().ok,"Enquête démarrée")
	for chapter in [1,2,3,4]:
		if chapter > 1: _check(investigation.enter_chapter(chapter).ok,"Préparation d’étage")
		for id in [FIRST,SECOND,THIRD,FOURTH][chapter-1]:
			if chapter == 3: _check(investigation.submit_code(id,ANSWERS[id]).ok,"Ancien code validé")
			else: _complete_service(id)
	root.size = Vector2i(1280,720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(35)
	app._show_screen("home")
	await _activate("continue_game")
	await _frames(8)
	if app.demo.overlay_kind == "conclusion": await _activate("conclusion_stay")
	await _travel(5,true)
	_check(app.demo.world.room_id == "room_05" and not app.demo.world.maze_active,"Ascenseur arrive au palier du chapitre 5")
	await _check_mystery_board()
	await _capture("chapitre_5_palier_challenge")
	await _walk_axis(KEY_UP,110)
	await _walk_axis(KEY_RIGHT,342)
	_check(app.demo.world.target_id == "laptop","Le portable est accessible à pied depuis l’ascenseur")
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "laptop" and _find("maze_go") != null,"Le portable propose Y aller")
	await _capture("portable_challenge")
	var before: Dictionary = state.profile.duplicate(true)
	saves.simulate_write_failure = true
	await _activate("maze_go")
	saves.simulate_write_failure = false
	_check(app.demo.overlay_kind == "dialog" and state.profile == before and app.demo.world.room_id == "room_05","Entrée échouée : le palier et le profil restent intacts")
	await _activate("dialog_continue")
	await _activate("maze_go",true)
	await _physics_frames(5)
	_check(app.demo.world.maze_active and state.profile.progress.room_id == "maze_05","Y aller téléporte dans le labyrinthe sauvegardé")
	await _check_mystery_board()
	await _capture("entree_labyrinthe_challenge")
	await _test_physics_and_layout()
	await _walk_to_center()
	await _key(KEY_SPACE)
	_check(app.demo.overlay_kind == "terminal" and app.demo.terminal_panel.phase == "user","Le terminal central demande un identifiant")
	await _test_terminal()
	_check(app.demo.overlay_kind == "conclusion" and state.profile.wallet.points == 650,"Le seul défi finit après obtention des droits, à 650 points cumulés")
	await _capture("bilan_mystere_challenge")
	await _activate("conclusion_stay")
	_check(not app.demo.world.get_interactable("maze_terminal").visible and app.demo.world.target_id != "maze_terminal","Le marqueur du terminal disparaît après la réussite")
	await _test_resume("maze")
	_check(app.demo.world.maze_active,"Continuer reprend aussi une réussite dans le labyrinthe")
	# The full path above is walked; this final proximity setup tests the exit UI.
	app.demo.world.player.position = Layout.at(Layout.START)
	await _physics_frames(4)
	await _key(KEY_SPACE)
	await _activate("maze_leave",true)
	_check(state.profile.progress.room_id == "room_05" and not app.demo.world.maze_active,"Le portail retrouve le palier et l’ascenseur")
	await _travel(4)
	await _travel(5)
	_check(state.profile.wallet.points == 650,"Aucun gain pendant les retours d’étages")
	await _finish()

func _check_mystery_board() -> void:
	var board = app.demo.mission_tracker
	_check(board.toggle_button.text.contains("0 / 1"),"Le tableau ne contient qu’un objectif")
	_check(_find("mission_name_maze").text.ends_with("???"),"L’objectif est affiché uniquement par des points d’interrogation")
	_check(not board.next_step_label.visible,"Aucun indice de but dans le panneau de missions")

func _test_physics_and_layout() -> void:
	var world = app.demo.world
	_check(Layout.GRID.size() == 23 and Layout.GRID[0].length() == 31,"Grand labyrinthe fixe de 31 par 23 cases")
	var reachable: Dictionary = _route_map(Layout.START)
	var floors := 0
	for y in range(Layout.GRID.size()):
		for x in range(Layout.GRID[y].length()):
			var cell := Vector2i(x,y)
			var floor: bool = Layout.is_floor(cell)
			_check(_point_clear(Layout.at(cell)) == floor,"Collision conforme au dessin : " + str(cell))
			if floor:
				floors += 1
				_check(reachable.has(cell),"Aucun couloir isolé : " + str(cell))
	_check(floors > 300 and Layout.NOTES.size() == 8,"Nombreux couloirs et huit inscriptions mêlées")
	var start: Vector2 = world.player.position
	await _hold(KEY_LEFT,35)
	_check(world.player.position.x > Layout.TILE + 8 and world.player.position.distance_to(start) < 40,"Le personnage ne traverse pas le mur à gauche de l’entrée")
	world.player.position = Layout.at(Layout.START)
	await _physics_frames(3)
	var camera_before: Vector2 = world.camera.position
	# Plaques can be read at close range; no mission evidence or points awarded.
	var before: Dictionary = state.profile.duplicate(true)
	for index in range(Layout.NOTES.size()):
		var note: Dictionary = Layout.NOTES[index]
		world.player.position = Layout.at(note.cell)
		await _physics_frames(3)
		_check(world.target_id == "maze_note_%d" % index,"Inscription accessible au bon embranchement")
		await _key(KEY_SPACE)
		_check(app.demo.overlay_kind == "dialog","L’inscription s’ouvre pour la lire")
		if index in [0,1,2]: await _capture("inscription_%d_challenge" % index)
		await _key(KEY_ESCAPE)
	_check(state.profile == before and state.profile.wallet.points == 600,"Lire les murs ne valide ni sous-mission ni récompense")
	_check(world.camera.position.distance_to(camera_before) > 100 and world.camera.zoom.x >= .9,"La caméra suit le joueur et garde le labyrinthe à explorer")
	world.player.position = Layout.at(Layout.START)
	await _physics_frames(3)

func _route_map(start: Vector2i, avoid_center: bool = false) -> Dictionary:
	var parents := {start:start}
	var queue: Array[Vector2i] = [start]
	var cursor := 0
	while cursor < queue.size():
		var at: Vector2i = queue[cursor]
		cursor += 1
		for direction in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var next: Vector2i = at + direction
			if avoid_center and next == Layout.CENTER: continue
			if Layout.is_floor(next) and not parents.has(next):
				parents[next] = at
				queue.append(next)
	return parents

func _walk_to_center() -> void:
	var goal: Vector2i = Layout.CENTER + Vector2i.DOWN
	var parents: Dictionary = _route_map(Layout.START,true)
	_check(parents.has(goal),"Parcours jusqu’au côté accessible du terminal")
	if not parents.has(goal): return
	var route: Array[Vector2i] = [goal]
	while route.back() != Layout.START: route.append(parents[route.back()])
	route.reverse()
	_check(route.size() > 90,"Le terminal est au centre après un vrai parcours avec détours")
	for cell in route.slice(1):
		await _walk_point(Layout.at(cell))
		_check(app.demo.world.player.position.distance_to(Layout.at(cell)) < 10,"Déplacement réel dans le couloir : " + str(cell))
	await _walk_point(Layout.checkpoints().maze_terminal)
	_check(app.demo.world.target_id == "maze_terminal","Le parcours physique rejoint le terminal central")
	await _capture("terminal_central_challenge")

func _walk_point(target: Vector2) -> void:
	var delta: Vector2 = target - app.demo.world.player.position
	if absf(delta.x) > 4:
		await _walk_axis(KEY_RIGHT if delta.x > 0 else KEY_LEFT,absf(delta.x))
	delta = target - app.demo.world.player.position
	if absf(delta.y) > 4:
		await _walk_axis(KEY_DOWN if delta.y > 0 else KEY_UP,absf(delta.y))

func _test_terminal() -> void:
	var terminal = app.demo.terminal_panel
	_check(terminal.code_keyboard.is_visible_in_tree() and not terminal.editor.secret,"Le clavier virtuel apparaît pour l’identifiant")
	await _virtual_text("admin")
	await _activate("terminal_validate",true)
	_check(terminal.phase == "password" and terminal.editor.secret,"La saisie du mot de passe est masquée")
	await _capture("connexion_challenge")
	await _virtual_text("faux")
	await _activate("terminal_validate")
	_check(terminal.phase == "password" and not investigation.terminal_connected(),"Mauvais mot de passe sans connexion")
	await _virtual_text("admin")
	saves.simulate_write_failure = true
	await _activate("terminal_validate")
	saves.simulate_write_failure = false
	_check(not investigation.terminal_connected() and terminal.phase == "password","Échec de sauvegarde de la session sans privilège")
	await _virtual_text("admin")
	await _activate("terminal_validate",true)
	_check(terminal.phase == "command" and investigation.terminal_connected() and not terminal.editor.secret,"Connexion ouvre uniquement une session utilisateur")
	await _physical_text(terminal.editor,"dir")
	await _activate("terminal_validate")
	_check(terminal.output.text.contains("Windows") and state.profile.wallet.points == 600,"Une piste Windows n’accorde aucun droit")
	await _physical_text(terminal.editor,"print test")
	await _activate("terminal_validate")
	_check(app.demo.overlay_kind == "terminal","P, T et Espace appartiennent à la saisie, sans fermer le terminal")
	await _key(KEY_ESCAPE)
	await _test_resume("maze_terminal")
	_check(investigation.terminal_connected() and app.demo.world.maze_active,"Reprise avec la session conservée au terminal")
	await _key(KEY_SPACE)
	terminal = app.demo.terminal_panel
	_check(terminal.phase == "command","Réouverture du terminal connecté")
	root.size = Vector2i(800,480)
	var values: Dictionary = settings.committed.duplicate(true)
	values.large_text = true
	_check(settings.apply_settings(values).ok,"Terminal sur petit écran avec texte agrandi")
	await _frames(8)
	await _virtual_text("sudo -i")
	await _activate("terminal_validate",true)
	_check(terminal.phase == "elevation" and terminal.editor.secret,"sudo demande une authentification avant de donner les droits")
	await _check_modal_layout("terminal 800x480")
	await _capture("elevation_challenge")
	await _virtual_text("ad")
	app.demo.controller_lost("Déconnexion de test")
	await _frames(8)
	_check(app.demo.overlay_kind == "controller_pause","Déconnexion : la console est suspendue")
	await _activate("controller_resume")
	_check(app.demo.terminal_panel == terminal and terminal.phase == "elevation" and terminal.editor.text == "ad","La même authentification reste conservée après reprise")
	await _virtual_text("admin")
	saves.simulate_write_failure = true
	await _activate("terminal_validate")
	saves.simulate_write_failure = false
	_check(terminal.phase == "elevation" and state.profile.wallet.points == 600,"Élévation échouée à l’écriture sans gain")
	await _virtual_text("admin")
	await _activate("terminal_validate",true)
	_check(app.demo.overlay_kind == "dialog" and state.profile.progress.completed_missions.has("maze"),"Authentification complète valide l’unique mission")
	await _activate("dialog_continue")

func _virtual_text(value: String) -> void:
	var terminal = app.demo.terminal_panel
	var keyboard = terminal.code_keyboard
	terminal.editor.text = ""
	terminal.editor.caret_column = 0
	for character in value:
		if character == " ":
			await _activate("key_Espace",true)
			continue
		if character in "azertyuiopqsdfghjklmwxcvbn" and keyboard.input_mode != "letters": await _activate("key_123",true)
		var key: BaseButton = _character_key(keyboard,character)
		if key == null:
			await _activate("key_123",true)
			key = _character_key(keyboard,character)
		_check(key != null,"Touche virtuelle disponible : " + character)
		if key == null: return
		await _activate(str(key.name),true)
	_check(terminal.editor.text == value,"Texte réellement composé au clavier virtuel")

func _test_resume(checkpoint: String) -> void:
	var saved: Dictionary = state.profile.duplicate(true)
	var previous = weakref(app.demo.world)
	await _key(KEY_P)
	await _activate("pause_menu")
	await _frames(6)
	_check(app.screen == "home" and previous.get_ref() == null,"Reprise après libération réelle du monde")
	await _activate("continue_game")
	await _frames(8)
	await _physics_frames(3)
	_check(state.profile == saved and app.demo.world.chapter_id == 5 and saved.progress.checkpoint_id == checkpoint,"Le profil retrouve le chapitre 5 et son point de reprise")
	_check(app.demo.world.player.position.is_equal_approx(Layout.checkpoints()[checkpoint]),"Le personnage reprend au terminal enregistré")
	if app.demo.overlay_kind == "conclusion": await _activate("conclusion_stay")

func _approach(id: String) -> void:
	if app.demo.world.chapter_id != 5:
		await super._approach(id)
		return
	var points: Dictionary = app.demo.world._chapter_checkpoints()
	if not points.has(id):
		_check(false,"Checkpoint du palier : " + id)
		return
	app.demo.world.player.position = points[id]
	await _physics_frames(3)
	await _frames(3)
	_check(app.demo.world.target_id == id,"Cible du palier approchée : " + id)
