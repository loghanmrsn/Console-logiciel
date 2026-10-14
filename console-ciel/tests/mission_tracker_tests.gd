extends SceneTree
## Component geometry, chapter scoping and explicit virtual controller events.
## No saves or physical controller measurements are used by this suite.
const Tracker := preload("res://scripts/game/mission_tracker.gd")
const Mapping := preload("res://scripts/input_setup.gd")
const Themes := preload("res://scripts/ui/theme_factory.gd")

class TrackerService extends Node:
	var chapter := 1
	var states := {"lighting": "available", "lock": "locked", "computer": "locked", "network": "available", "addressing": "locked", "security": "locked"}
	func current_chapter() -> int:
		return chapter
	func chapter_missions(_chapter: int = 0) -> Array:
		var result: Array = []
		for id in (["lighting", "lock", "computer"] if chapter == 1 else ["network", "addressing", "security"]):
			result.append({"id": id, "name": id})
		return result
	func mission_state(id: String) -> String:
		return states[id]

var checks := 0
var failures: Array[String] = []
var stage: Control
var tracker: Control
var service: TrackerService


func _initialize() -> void:
	_run.call_deferred()


func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		push_error(label)


func _frames(count: int = 5) -> void:
	for _index in range(count):
		await process_frame


func _run() -> void:
	await process_frame
	await _test_mapping()
	root.size = Vector2i(1280, 720)
	stage = Control.new()
	root.add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.theme = Themes.build({"appearance_style": "brume"}, {})
	service = TrackerService.new()
	stage.add_child(service)
	tracker = Tracker.new()
	tracker.configure(service)
	stage.add_child(tracker)
	await _frames(8)
	_check(tracker.panel_expanded and tracker.is_expanded(), "Le tableau initial présente les missions")
	_check(tracker.toggle_button.focus_mode == Control.FOCUS_NONE and tracker.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Le panneau ne prend pas le focus des déplacements")
	_check(tracker.chapter_label.text.contains("CHAPITRE 1") and tracker.chapter_label.text.contains("REZ-DE-CHAUSSÉE"), "Le tableau situe le rez-de-chaussée")
	_check(tracker.progress_bar.max_value == 3 and tracker.progress_bar.value == 0, "Le compteur porte sur les trois missions du chapitre")
	for id in ["lighting", "lock", "computer"]:
		_check(tracker.find_child("mission_name_" + id, true, false) != null and tracker.find_child("mission_status_" + id, true, false) != null, "Nom et état de la mission affichés : " + id)
	_check(tracker.find_child("mission_name_network", true, false) == null, "Le tableau du rez-de-chaussée ne mélange pas les missions de l’étage")
	_check(tracker.next_step_label.text.contains("tableau électrique"), "L’indice indique le premier équipement")
	service.states.lighting = "completed"
	service.states.lock = "available"
	tracker.refresh()
	await _frames()
	_check(tracker.progress_bar.value == 1 and tracker.toggle_button.text.contains("1 / 3"), "La réussite actualise le compteur")
	_check(tracker.find_child("mission_status_lighting", true, false).text.contains("Terminée"), "Le statut de réussite reste visible")
	_check(tracker.next_step_label.text.contains("commande de la porte"), "L’indice suit la prochaine mission")
	for id in ["lock", "computer"]:
		service.states[id] = "completed"
	tracker.refresh()
	await _frames()
	_check(tracker.progress_bar.value == 3 and tracker.next_step_label.text.contains("ascenseur"), "Après trois missions, le tableau guide vers l’ascenseur")
	service.chapter = 2
	tracker.refresh()
	await _frames()
	_check(tracker.chapter_label.text.contains("CHAPITRE 2") and tracker.chapter_label.text.contains("ÉTAGE 1"), "L’ascension change le chapitre affiché")
	_check(tracker.progress_bar.value == 0 and tracker.progress_bar.max_value == 3, "Les réussites du premier chapitre ne remplissent pas le compteur du deuxième")
	for id in ["network", "addressing", "security"]:
		_check(tracker.find_child("mission_name_" + id, true, false) != null, "Mission de l’étage affichée : " + id)
	_check(tracker.find_child("mission_name_lighting", true, false) == null, "Les anciennes lignes sont remplacées par celles du chapitre actuel")
	_check(tracker.next_step_label.text.contains("commutateur"), "L’étage propose un nouvel équipement à observer")
	var focus_anchor := Button.new()
	focus_anchor.text = "Focus du jeu"
	stage.add_child(focus_anchor)
	focus_anchor.grab_focus()
	var height_open: float = tracker.panel.size.y
	tracker.toggle_button.pressed.emit()
	await _frames()
	_check(not tracker.panel_expanded and not tracker._body.visible and tracker.panel.size.y < height_open, "Le bouton replie réellement le panneau")
	_check(root.gui_get_focus_owner() == focus_anchor, "Replier conserve le focus qui pilote le jeu")
	tracker.set_input_enabled(false)
	tracker.toggle_panel()
	await _frames()
	_check(not tracker.panel_expanded and tracker.toggle_button.disabled, "Un écran bloquant interdit de modifier le panneau")
	tracker.set_input_enabled(true)
	tracker.toggle_panel()
	await _frames()
	_check(tracker.panel_expanded and not tracker.toggle_button.disabled, "La reprise restitue le bouton et le tableau")
	for viewport_size in [Vector2i(1280, 720), Vector2i(800, 480)]:
		root.size = viewport_size
		for large in [false, true]:
			for style in ["brume", "nuit"]:
				stage.theme = Themes.build({"appearance_style": style, "large_text": large}, {})
				tracker.refresh()
				await _frames(8)
				var rect: Rect2 = tracker.panel.get_global_rect()
				_check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= viewport_size.x and rect.end.y <= viewport_size.y, "Tableau contenu dans %s, grand texte %s, %s" % [viewport_size, large, style])
				_check(rect.position.x > viewport_size.x * 0.5, "Le tableau reste à droite : %s, grand texte %s, %s" % [viewport_size, large, style])
				if viewport_size.y <= 600:
					_check(rect.size.y <= 200.1 and rect.size.x <= 280.1, "Le tableau reste compact sur petit écran, grand texte %s, %s" % [large, style])
					var content_rect: Rect2 = tracker._body.get_global_rect()
					for id in ["network", "addressing", "security"]:
						var name_label := tracker.find_child("mission_name_" + id, true, false) as Label
						_check(content_rect.encloses(name_label.get_global_rect()), "Les trois missions restent visibles sans défilement à la manette : %s, grand texte %s, %s" % [id, large, style])
					_check(content_rect.encloses(tracker.next_step_label.get_global_rect()), "L’indice reste visible sans souris, grand texte %s, %s" % [large, style])
					await _test_compact_mission_states(large, style)
				else:
					_check(rect.size.y <= (340.1 if large else 300.1), "Le tableau développé reste petit sur écran 720, grand texte %s, %s" % [large, style])
					_check(tracker._body.size.y <= tracker.mission_list.get_combined_minimum_size().y + 1, "La hauteur suit la liste après calcul des retours à la ligne, grand texte %s, %s" % [large, style])
					await _test_desktop_refresh(large, style)
				_check(tracker.toggle_button.size.y >= tracker.toggle_button.get_combined_minimum_size().y, "Le bouton garde sa hauteur native en grand texte %s, %s" % [large, style])
	for id in ["network", "addressing", "security"]:
		service.states[id] = "completed"
	tracker.refresh()
	await _frames()
	_check(tracker.progress_bar.value == 3 and tracker.next_step_label.text.contains("terminées") and not tracker.next_step_label.text.contains("ascenseur"), "Le bilan du deuxième chapitre ne propose pas un étage inexistant")
	root.remove_child(stage)
	stage.queue_free()
	await _frames()
	print("MISSION_TRACKER : %d assertions, %d échec(s). Géométrie native et périphériques virtuels ; matériel non testé." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _test_compact_mission_states(large: bool, style: String) -> void:
	for chapter in [1, 2]:
		service.chapter = chapter
		var ids: Array = ["lighting", "lock", "computer"] if chapter == 1 else ["network", "addressing", "security"]
		for done_count in range(4):
			for index in range(ids.size()):
				service.states[ids[index]] = "completed" if index < done_count else ("available" if index == done_count else "locked")
			tracker.refresh()
			await _frames()
			var content_rect: Rect2 = tracker._body.get_global_rect()
			var last_status := tracker.find_child("mission_status_" + ids[-1], true, false) as Label
			_check(content_rect.encloses(last_status.get_global_rect()), "Les trois statuts restent lisibles au chapitre %d, %d missions finies, grand texte %s, %s" % [chapter, done_count, large, style])
			_check(content_rect.encloses(tracker.next_step_label.get_global_rect()), "Chaque indice ou bilan reste visible au chapitre %d, %d missions finies, grand texte %s, %s" % [chapter, done_count, large, style])


func _test_desktop_refresh(large: bool, style: String) -> void:
	service.chapter = 1
	for id in ["lighting", "lock", "computer"]:
		service.states[id] = "completed"
	# Repeated updates exercise replacing all wrapped controls, as missions do.
	for _repeat in range(3):
		tracker.refresh()
		await _frames(8)
	_check(tracker.panel.size.y <= (340.1 if large else 300.1), "La fin du chapitre n’étend pas le tableau sur le bureau, grand texte %s, %s" % [large, style])
	_check(tracker._body.size.y <= tracker.mission_list.get_combined_minimum_size().y + 1, "Un remplacement des missions ne conserve pas une ancienne hauteur excessive, grand texte %s, %s" % [large, style])
	service.chapter = 2
	service.states.network = "available"
	service.states.addressing = "locked"
	service.states.security = "locked"
	tracker.refresh()
	await _frames()


func _test_mapping() -> void:
	var result: Dictionary = Mapping.configure()
	_check(result.ok, "Le mapping central du projet reste valide")
	_check("game_missions" in Mapping.JOY_ACTIONS and InputMap.has_action("game_missions"), "Les missions utilisent une action centrale filtrée par périphérique")
	var key := InputEventKey.new()
	key.keycode = KEY_T
	key.pressed = true
	_check(key.is_action_pressed("game_missions"), "La touche T actionne les missions")
	for action in ["game_interact", "pause", "ui_accept", "ui_cancel", "game_left", "game_right", "game_up", "game_down"]:
		_check(not key.is_action_pressed(action), "T ne déclenche pas une autre commande : " + action)
	var mapping: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Mapping.MAPPING_PATH))
	_check(mapping.actions.game_missions.button == JOY_BUTTON_Y and JOY_BUTTON_Y == 3, "La convention Godot du bouton du haut est explicitement index 3")
	var legacy := mapping.duplicate(true)
	legacy.actions.erase("game_missions")
	var old_result: Dictionary = Mapping.validate_mapping(legacy)
	_check(old_result.ok and old_result.data.game_missions.is_empty(), "Un ancien mapping HID conserve ses commandes sans inventer d’indice pour le nouveau raccourci")
	for action in legacy.actions:
		_check(old_result.data[action] == Mapping.validate_mapping(mapping).data[action], "Le mapping ancien garde son indice mesuré : " + action)
	var invalid := mapping.duplicate(true)
	invalid.actions.game_missions = {}
	_check(not Mapping.validate_mapping(invalid).ok, "Une nouvelle action déclarée vide reste invalide")
	invalid = mapping.duplicate(true)
	invalid.actions.game_missions.button = 3.5
	_check(not Mapping.validate_mapping(invalid).ok, "Un indice fractionnaire est rejeté pour le panneau")
	invalid = mapping.duplicate(true)
	invalid.actions.erase("game_interact")
	_check(not Mapping.validate_mapping(invalid).ok, "Les anciennes commandes obligatoires restent validées strictement")
	var controllers := root.get_node("ControllerService")
	controllers.debug_set_devices([7])
	for active in [false, true]:
		var event := InputEventJoypadButton.new()
		event.device = 7 if active else 8
		event.button_index = JOY_BUTTON_Y
		event.pressed = true
		Input.parse_input_event(event)
		await _frames(2)
		_check(Input.is_action_pressed("game_missions") == active, "Bouton du haut accepté uniquement pour le périphérique virtuel actif : " + str(active))
		event.pressed = false
		Input.parse_input_event(event)
		await _frames(2)
	controllers.debug_clear_devices()
	_check(not Input.is_action_pressed("game_missions"), "Le changement de périphérique libère l’action des missions")
