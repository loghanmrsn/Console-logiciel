extends "res://tests/npc_ui_tests.gd"
## Exercise the real approach rays, scrolling, gestures and interrupted fades.

func _initialize() -> void:
	# Real-time fades need the same frame cadence in headless and native runs.
	Engine.max_fps = 60
	super._initialize()

func _conversation(id: String, fragment: String, controller: bool) -> void:
	await _test_approach_sides(id)
	await super._conversation(id, fragment, controller)
	if id == "npc_workshop": await _test_fluid_controls()

func _test_approach_sides(id: String) -> void:
	var spec := People.find(id)
	var world = app.demo.world
	var target = world.get_interactable(id)
	for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		var at: Vector2 = spec.at + direction * 36
		world.player.position = at
		world.player.facing = -direction
		await _physics_frames(3)
		_check(_clear_player(at), "Une approche latérale garde les pieds libres : " + id + str(direction))
		_check(world._can_reach(target) and world.target_id == id, "Le PNJ peut être abordé depuis ce côté : " + id + str(direction))
	_check(world._characters[id]._look.x < 0, "Le regard accompagne le joueur placé à gauche : " + id)
	# Excluding the NPC's own feet must never make a wall transparent to talk.
	world.player.position = spec.at + Vector2(0, 56)
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(44, 6)
	shape.shape = box
	wall.position = spec.at + Vector2(0, 26)
	wall.add_child(shape)
	world._room_root.add_child(wall)
	await _physics_frames(3)
	_check(not world._can_reach(target), "Un obstacle intermédiaire empêche toujours la discussion : " + id)
	wall.free()
	await _physics_frames(3)
	_check(world._can_reach(target), "L’approche redevient disponible après retrait de l’obstacle")

func _clear_player(at: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.1
	query.shape = circle
	query.transform = Transform2D(0, at)
	query.collision_mask = 1
	return app.demo.world.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _test_fluid_controls() -> void:
	var before: Dictionary = state.profile.duplicate(true)
	var original: Dictionary = settings.committed.duplicate(true)
	var animated: Dictionary = original.duplicate(true)
	animated.reduce_motion = false
	_check(settings.apply_settings(animated).ok, "Animations autorisées pour vérifier les vraies transitions")
	app.demo.world.player.position = Vector2(80, 430)
	await _physics_frames(4)
	await _approach_person("npc_workshop")
	await _frames(16)
	var marker = app.demo.world.get_interactable("npc_workshop")
	var visual = app.demo.world._characters.npc_workshop
	_check(marker._focus > .99 and visual._attention > .99, "Le nom et le geste d’accueil atteignent leur état final")
	await _capture("npc_attention_challenge")
	await _key(KEY_SPACE)
	var panel = _find("npc_dialogue_panel")
	_check(panel != null and app.demo.paused, "L’ouverture animée bloque immédiatement les mouvements")
	await _frames(14)
	_check(is_equal_approx(panel.modulate.a, 1), "La discussion est entièrement visible après son court fondu")
	var close_button := _find("npc_close") as Button
	var glyph_width := close_button.get_theme_font("font").get_string_size(close_button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, close_button.get_theme_font_size("font_size")).x
	_check(close_button.size.x >= glyph_width + close_button.get_theme_stylebox("normal").get_minimum_size().x, "Le bouton de fermeture laisse assez de place au symbole ×")
	var portrait_rect: Rect2 = _find("npc_portrait").get_global_rect()
	var actions_rect: Rect2 = _find("npc_next").get_global_rect()
	await _key(KEY_SPACE)
	_check(panel.page_index == 1, "Espace avance d’une page sans déplacer le focus vers un autre écran")
	_check(_find("npc_portrait").get_global_rect().is_equal_approx(portrait_rect) and _find("npc_next").get_global_rect().is_equal_approx(actions_rect), "La pagination garde le portrait et les actions à la même place")
	var echo := InputEventKey.new()
	echo.keycode = KEY_SPACE
	echo.pressed = true
	echo.echo = true
	Input.parse_input_event(echo)
	await _frames(4)
	_check(app.demo.overlay_kind == "npc" and panel.page_index == 1, "La répétition automatique de la touche ne saute pas le dialogue")
	echo = echo.duplicate()
	echo.echo = false
	echo.pressed = false
	Input.parse_input_event(echo)
	await _frames(2)
	await _capture("npc_dialogue_fluide_challenge")
	await _key(KEY_ESCAPE)
	_check(app.demo.overlay_kind.is_empty() and not app.demo.paused, "Échap ferme rapidement la fenêtre animée")
	await _key(KEY_SPACE)
	await _frames(14)
	await _key(KEY_SPACE)
	# Keep Space down after asking to close, across the return to gameplay.
	var held := InputEventKey.new()
	held.keycode = KEY_SPACE
	held.pressed = true
	Input.parse_input_event(held)
	await _frames(20)
	_check(app.demo.overlay_kind.is_empty(), "Maintenir Espace après la dernière page ne rouvre pas la conversation")
	held = held.duplicate()
	held.pressed = false
	Input.parse_input_event(held)
	await _frames(5)
	await _test_interrupted_close()
	_check(settings.apply_settings(original).ok, "Réduction des animations restaurée après le contrôle")
	await _key(KEY_SPACE)
	panel = _find("npc_dialogue_panel")
	_check(panel != null and is_equal_approx(panel.modulate.a, 1), "Avec animations réduites, le dialogue est immédiatement opaque")
	await _activate("npc_close", true)
	_check(app.demo.overlay_kind.is_empty(), "Le nouveau bouton de fermeture reste accessible à la manette")
	_check(state.profile == before and saves.read_profile(profile_id).data == before, "Les transitions et leurs interruptions ne modifient aucune donnée du profil")
	# The inherited crossing scenario expects device 0 to be active initially.
	controllers.debug_set_devices([0])
	controllers.debug_set_devices([0, 1])

func _test_interrupted_close() -> void:
	await _approach_person("npc_workshop")
	await _key(KEY_SPACE)
	await _frames(14)
	var panel := _find("npc_dialogue_panel")
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	_check(app.demo._npc_closing, "La fermeture possède une courte phase de transition")
	controllers.debug_connection_changed(0, false)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(12)
	_check(app.demo.overlay_kind == "controller_pause", "Une fermeture interrompue ne supprime pas l’alerte de manette")
	controllers.debug_connection_changed(0, true)
	await _frames(4)
	await _activate("controller_resume")
	_check(app.demo.overlay_kind == "npc" and _find("npc_dialogue_panel") == panel, "La reprise conserve la même discussion après interruption du fondu")
	_check(not app.demo._npc_closing and is_equal_approx(panel.modulate.a, 1) and not (_find("npc_next") as Button).disabled, "La discussion restaurée retrouve son opacité et ses boutons")
	await _activate("npc_close")
	_check(app.demo.overlay_kind.is_empty(), "Une nouvelle fermeture fonctionne après l’interruption")

func _compact_conversation() -> void:
	await super._compact_conversation()
	var original: Dictionary = settings.committed.duplicate(true)
	var compact: Dictionary = original.duplicate(true)
	compact.large_text = true
	compact.appearance_style = "nuit"
	_check(settings.apply_settings(compact).ok, "Lecture compacte avec le vrai grand texte")
	root.size = Vector2i(800, 480)
	await _frames(12)
	await _approach_person("npc_workshop")
	await _key(KEY_SPACE)
	await _activate("npc_next", true)
	await _frames(6)
	var reader := _find("npc_text_scroll") as ScrollContainer
	var portrait_rect := _find("npc_portrait").get_global_rect()
	var actions_rect := _find("npc_next").get_global_rect()
	_check(app.demo._modal_scroll.scroll_vertical == 0, "Sur petit écran, le cadre entier n’a plus besoin de défiler")
	_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(portrait_rect) and Rect2(Vector2.ZERO, Vector2(root.size)).encloses(actions_rect), "Portrait et actions restent visibles ensemble en 800 × 480 grand texte")
	reader.grab_focus()
	await _frames(4)
	await _key(KEY_DOWN)
	_check(reader.scroll_vertical > 0, "La flèche du clavier fait défiler le texte sélectionné")
	await _joy(JOY_BUTTON_DPAD_DOWN)
	_check(reader.scroll_vertical > 0, "Clavier et croix de manette font défiler le texte long")
	_check(_find("npc_portrait").get_global_rect().is_equal_approx(portrait_rect) and _find("npc_next").get_global_rect().is_equal_approx(actions_rect), "Lire le bas du texte conserve le portrait et les boutons fixes")
	await _capture("npc_lecture_compacte_challenge")
	await _activate("npc_close", true)
	root.size = Vector2i(1280, 720)
	_check(settings.apply_settings(original).ok, "Dimensions et préférences restaurées après la lecture compacte")
	await _frames(10)
