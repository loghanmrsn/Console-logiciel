extends Control
## Hotel objectives and native modal interactions. Saved story state belongs to
## HotelService; this component only owns presentation and the seated clock.
const HOTEL_ZONES := ["building_02", "hotel_it", "hotel_stairs_1", "hotel_floor_2", "hotel_room_206", "hotel_breakfast", "ctf_bus_stop", "ctf_lobby"]
const CtfPanel = preload("res://scripts/ui/ctf_challenge_panel.gd")
const CtfCatalog = preload("res://scripts/game/ctf_catalog.gd")
const CoffeeWiringPanel = preload("res://scripts/ui/coffee_wiring_panel.gd")
const DiagnosticPanel = preload("res://scripts/ui/hotel_diagnostic_panel.gd")
const WAIT_SECONDS := 10.0


var game: Control
var objective_panel: PanelContainer
var objective_text: Label
var objective_title: Label
var objectives_expanded := true
var wait_remaining_seconds := WAIT_SECONDS
var _wait_label: Label
var _clock_msec := 0
var _profile_id := ""
var _room_id := ""
var _diagnosis := ""
var _repair := ""
var _feedback := ""
var _observation := ""
var _last_wait_second := -1
var _night_remaining := 0.0
var _night_duration := 1.2
var _action_busy := false
var _objective_fit_scheduled := false
var _ground_arrival_scheduled := false
var _last_morning_stage := -1
var _coffee_selection := ""
var _coffee_feedback := ""
var coffee_panel: Control
var _coffee_status: Label

func configure(host: Control) -> void:
	game = host

func _ready() -> void:
	name = "hotel_story_ui"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	objective_panel = PanelContainer.new()
	objective_panel.name = "hotel_objectives"
	objective_panel.theme_type_variation = "HUDPanel"
	objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(objective_panel)
	objective_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_panel.add_child(column)
	objective_title = Label.new()
	objective_title.name = "hotel_objective_title"
	objective_title.text = "HÔTEL CIEL · SÉJOUR"
	objective_title.add_theme_font_size_override("font_size", 13)
	objective_title.clip_text = true
	objective_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	objective_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(objective_title)
	objective_text = Label.new()
	objective_text.name = "hotel_objective_text"
	objective_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(objective_text)
	# Autowrap first measures against its previous width. Refit when the
	# containers settle that measurement, including the first visible frame.
	objective_text.minimum_size_changed.connect(_schedule_objective_fit)
	objective_title.minimum_size_changed.connect(_schedule_objective_fit)
	resized.connect(_schedule_objective_fit)
	theme_changed.connect(_schedule_objective_fit)
	refresh()

func is_hotel_zone() -> bool:
	if AppState.profile.is_empty():
		return false
	var room := str(AppState.profile.get("progress", {}).get("room_id", ""))
	return room in HOTEL_ZONES or (room == "courtyard" and int(HotelService.state().get("morning_stage", 0)) > 0)

func is_sitting() -> bool:
	return is_hotel_zone() and str(HotelService.state().get("bed_state", "standing")) == "sitting"

func can_move() -> bool:
	return not is_sitting()

func refresh() -> void:
	if not is_instance_valid(game) or objective_text == null:
		return
	var current_profile := str(AppState.profile.get("id", ""))
	var current_room := str(AppState.profile.get("progress", {}).get("room_id", ""))
	if _profile_id != current_profile or (not current_room in HOTEL_ZONES and _room_id in HOTEL_ZONES):
		_reset_context()
	if current_room == "hotel_floor_2" and _room_id != current_room:
		objectives_expanded = true
	_profile_id = current_profile
	_room_id = current_room
	var state: Dictionary = HotelService.state()
	objective_title.text = "HÔTEL CIEL · " + ({"hotel_stairs_1": "PALIER 1", "hotel_floor_2": "ÉTAGE 2", "hotel_room_206": "CHAMBRE 206", "hotel_breakfast": "PETIT DÉJEUNER", "courtyard": "ARRÊT DE BUS"}.get(current_room, "RÉCEPTION"))
	if current_room in ["ctf_bus_stop", "ctf_lobby"]:
		objective_title.text = "SUDO HACK · " + ("ARRIVÉE" if current_room == "ctf_bus_stop" else "ACCUEIL")
	var morning_stage := int(state.get("morning_stage", 0))
	if morning_stage > 0 and morning_stage != _last_morning_stage:
		objectives_expanded = true
	_last_morning_stage = morning_stage
	if morning_stage > 0:
		objective_text.text = _morning_objective(morning_stage, current_room)
	elif not state.get("reserved", false):
		objective_text.text = "Réservez votre chambre à la réception."
	elif not state.get("repaired", false):
		objective_text.text = "Panne informatique · Rejoignez le local technique à côté de la réception."
	elif current_room == "hotel_stairs_1":
		objective_text.text = "Continuez par l’escalier montant vers l’étage 2. Le premier étage reste fermé."
	elif not state.get("luggage_placed", false) and current_room in ["building_02", "hotel_it"]:
		objective_text.text = "Prenez les escaliers vers l’étage 2, puis rejoignez la chambre 206."
	elif not state.get("luggage_placed", false):
		objective_text.text = "Rendez-vous chambre 206" + (" · Déposez vos affaires." if current_room == "hotel_room_206" else ".")
	elif state.get("bed_state", "standing") == "sitting":
		objective_text.text = "Installé sur le lit · Prenez le temps de vous reposer."
	elif state.get("bed_state", "standing") == "rested":
		objective_text.text = "Rejoignez le rez-de-chaussée par les escaliers · 50 points."
	else:
		objective_text.text = "Vos affaires sont posées. Installez-vous sur le lit."
	objective_text.visible = objectives_expanded
	_fit_objectives()
	_schedule_objective_fit()
	sync_visibility()
	if current_room == "building_02" and morning_stage == 1 and not _ground_arrival_scheduled:
		_ground_arrival_scheduled = true
		_ensure_ground_arrival.call_deferred()

func _morning_objective(stage: int, room: String) -> String:
	match stage:
		1: return "Descendez au rez-de-chaussée par les escaliers · " + _reward_text("hotel_ground_floor") + "."
		2: return "Prenez la porte du petit déjeuner dans le hall, puis installez-vous à une table."
		3: return "Votre café manque ! Réparez la machine en reliant les trois fils de même couleur."
		4: return "La machine fonctionne. Prenez votre café."
		5: return "Retournez chambre 206 à l’étage 2 pour récupérer votre sac et votre ordinateur · " + _reward_text("hotel_backpack") + "."
		6: return "Sortez de l’hôtel, puis rejoignez l’arrêt de bus pour le CTF Sudo Hack." if room != "courtyard" else "Prenez le bus vers le CTF Sudo Hack."
		7: return "Vous êtes arrivé. Entrez dans le bâtiment du CTF Sudo Hack."
		8, 9:
			if room in ["ctf_lobby", "ctf_bus_stop"]:
				var done: int = CtfService.state().completed.size()
				return "Sudo Hack · 5 / 5 · Sortez puis prenez le bus de retour vers la ville." if done == 5 else "Sudo Hack · %d / 5 · Rejoignez le poste %d : %s." % [done, done + 1, str(CtfCatalog.CHALLENGES[CtfCatalog.IDS[done]].skill)]
			return "Sudo Hack terminé · Vous êtes de retour en ville. L'hôtel et les bâtiments restent accessibles."
	return ""

func _reward_text(id: String) -> String:
	return "récompense déjà obtenue (+0 point)" if id in AppState.profile.get("rewarded_missions", []) else "50 points"

func _ensure_ground_arrival() -> void:
	_ground_arrival_scheduled = false
	if not is_inside_tree() or str(AppState.profile.get("progress", {}).get("room_id", "")) != "building_02" or int(HotelService.state().get("morning_stage", 0)) != 1:
		return
	var result: Dictionary = HotelService.arrive_ground_floor()
	if not result.ok:
		_show_error("Arrivée non enregistrée", result, _ensure_ground_arrival)
		return
	if game.overlay_kind == "hotel_error":
		game._close_overlay()
	_notify_reward(result, "Rez-de-chaussée rejoint")

func toggle_objectives() -> void:
	objectives_expanded = not objectives_expanded
	refresh()

func sync_visibility() -> void:
	if objective_panel == null or not is_instance_valid(game):
		return
	objective_panel.visible = is_hotel_zone() and game.is_visible_in_tree() and not game.paused and game.overlay_kind.is_empty()

func _schedule_objective_fit() -> void:
	if _objective_fit_scheduled:
		return
	_objective_fit_scheduled = true
	_apply_objective_fit.call_deferred()

func _apply_objective_fit() -> void:
	_objective_fit_scheduled = false
	_fit_objectives()

func _fit_objectives() -> void:
	if not is_inside_tree() or objective_panel == null or size.x <= 0 or size.y <= 0:
		return
	var compact := get_viewport_rect().size.x < 1000 or get_viewport_rect().size.y < 600
	var width := minf(242.0 if compact else 310.0, maxf(150.0, size.x - 24))
	var font_size := (16 if compact else 18) + (2 if SettingsService.current.get("large_text", false) else 0)
	if objective_text.get_theme_font_size("font_size") != font_size:
		objective_text.add_theme_font_size_override("font_size", font_size)
	if objective_panel.custom_minimum_size.x != width:
		objective_panel.custom_minimum_size.x = width
	objective_panel.offset_left = -width - 12
	objective_panel.offset_right = -12
	objective_panel.offset_top = 12
	# Use the game control's available height, rather than the whole window.
	# Short objectives remain fully visible; exceptionally small areas clip at
	# a whole line instead of growing a column over the room.
	var padding := objective_panel.get_theme_stylebox("panel").get_minimum_size().y
	var line_height := objective_text.get_theme_font("font").get_height(font_size) + objective_text.get_theme_constant("line_spacing")
	var available_text_height := size.y - 24 - padding - objective_title.get_combined_minimum_size().y - 5
	var maximum_lines := maxi(1, floori(available_text_height / maxf(1, line_height)))
	if objective_text.max_lines_visible != maximum_lines:
		objective_text.max_lines_visible = maximum_lines
	# A previous minimum may have been measured at width zero. Reset both
	# dimensions again after that minimum changes so the panel can shrink.
	objective_panel.size = Vector2(width, 0)

func _reset_context() -> void:
	wait_remaining_seconds = WAIT_SECONDS
	_wait_label = null
	_last_wait_second = -1
	_clock_msec = 0
	_night_remaining = 0.0
	_diagnosis = ""
	_repair = ""
	_feedback = ""
	_observation = ""
	_last_morning_stage = -1
	_coffee_selection = ""
	_coffee_feedback = ""
	coffee_panel = null
	_coffee_status = null
	objectives_expanded = true
	if is_instance_valid(game) and is_instance_valid(game._room):
		game._room.modulate = Color.WHITE

func suspend_clock() -> void:
	# Settings detach the game from the tree. Their elapsed time never counts.
	_clock_msec = 0

func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	var elapsed := 0.0 if _clock_msec == 0 else float(now - _clock_msec) / 1000.0
	_clock_msec = now
	if not is_instance_valid(game) or not game.is_visible_in_tree() or game._controller_waiting:
		return
	if get_tree().get_first_node_in_group("blocking_confirmation") != null or not SceneRouter.gameplay_allowed():
		return
	if game.overlay_kind == "hotel_bed_waiting" and is_sitting():
		_tick_wait(elapsed)
	elif game.overlay_kind == "hotel_night" and _night_remaining > 0:
		_tick_night(elapsed)

func _tick_wait(elapsed_seconds: float) -> void:
	# Called with monotonic real time by _process. Public remaining time also
	# makes paused-clock behavior inspectable without a second hidden timer.
	if not is_instance_valid(game) or game.overlay_kind != "hotel_bed_waiting" or not is_sitting():
		return
	wait_remaining_seconds = maxf(0.0, wait_remaining_seconds - maxf(0.0, elapsed_seconds))
	_update_wait_label()
	if wait_remaining_seconds <= 0.0:
		_show_bed_choices()

func restore_seated_overlay() -> void:
	if not is_inside_tree() or not is_instance_valid(game) or not game.is_visible_in_tree() or not game.overlay_kind.is_empty() or game._controller_waiting:
		return
	if is_sitting():
		if wait_remaining_seconds > 0:
			_show_waiting()
		else:
			_show_bed_choices()

func can_pause_bed() -> bool:
	return is_sitting() and game.overlay_kind in ["hotel_bed_waiting", "hotel_bed_choices"]

func handle_target(id: String) -> bool:
	if id.trim_prefix("ctf_") in CtfCatalog.IDS:
		_show_ctf(id.trim_prefix("ctf_"))
		return true
	if not id.begins_with("hotel_") and id not in ["campus_bus", "ctf_enter", "ctf_leave", "ctf_return_bus"]:
		return false
	match id:
		"hotel_reception": _show_reception()
		"hotel_repair": _show_repair()
		"hotel_luggage": _show_luggage()
		"hotel_bed": _show_bed()
		"hotel_breakfast_door": _show_travel("hotel_breakfast", "Salle du petit déjeuner", "Le buffet et les tables se trouvent derrière cette porte.")
		"hotel_breakfast_return": _show_travel("building_02", "Revenir dans le hall", "Retrouvez les escaliers et la sortie de l’hôtel.")
		"hotel_breakfast_table": _show_breakfast()
		"hotel_coffee_machine":
			_coffee_selection = ""
			_coffee_feedback = ""
			_show_coffee()
		"hotel_backpack": _show_backpack()
		"campus_bus": _show_bus()
		"ctf_enter": _show_travel("ctf_lobby", "CTF Sudo Hack", "Entrez avec votre sac et votre ordinateur. Cinq postes vous attendent. Consultez leurs indices puis saisissez vos réponses.")
		"ctf_return_bus": _show_return_bus()
		"ctf_leave": _show_travel("ctf_bus_stop", "Sortir du bâtiment", "Retrouvez l’arrêt de bus devant le bâtiment Sudo Hack.")
		"hotel_it_door": _show_travel("hotel_it", "Local informatique", "Le local technique est juste à côté du hall.")
		"hotel_it_return": _show_travel("building_02", "Revenir à la réception", "Retrouvez le hall et les escaliers.")
		"hotel_stairs_up":
			var first := str(AppState.profile.progress.room_id) == "building_02"
			_show_travel("hotel_stairs_1" if first else "hotel_floor_2", "Monter l’escalier", "Le premier étage est fermé au public : seul son palier d’escalier est accessible." if first else "Le deuxième étage dessert votre chambre 206.")
		"hotel_stairs_down":
			var second := str(AppState.profile.progress.room_id) == "hotel_floor_2"
			_show_travel("hotel_stairs_1" if second else "building_02", "Descendre l’escalier", "Rejoignez le palier inférieur par l’escalier voisin.")
		"hotel_room206": _show_travel("hotel_room_206", "Chambre 206", "Votre sac et votre ordinateur vous attendent dans la chambre." if int(HotelService.state().get("morning_stage", 0)) == 5 else "Retrouvez votre chambre 206.")
		"hotel_room206_exit": _show_travel("hotel_floor_2", "Quitter la chambre", "Retrouvez le couloir du deuxième étage.")
		_: return false
	return true

func _show_reception() -> void:
	game._open_overlay("hotel_reception")
	game._label(game.modal_content, "Bienvenue à l’Hôtel CIEL", 28)
	if HotelService.state().get("reserved", false):
		game._label(game.modal_content, "Votre chambre 206 est réservée. " + ("Les escaliers donnent accès au deuxième étage." if HotelService.state().get("repaired", false) else "Le système de réservation vient de tomber en panne. Le local informatique est à côté de la réception."))
		game._button(game.modal_content, "Continuer", game._close_overlay, "hotel_reception_close")
	else:
		game._label(game.modal_content, "La réception vous propose la chambre 206 au deuxième étage. La réservation fait partie de l’histoire et ne coûte aucun point.")
		game._button(game.modal_content, "Réserver la chambre 206", _reserve_room, "hotel_reserve")
		game._button(game.modal_content, "Revenir dans le hall", game._close_overlay, "hotel_reception_close")
	game._wire_modal()

func _reserve_room() -> void:
	if _action_busy: return
	_action_busy = true
	var result: Dictionary = HotelService.reserve_room()
	_action_busy = false
	if not result.ok:
		_show_error("Réservation non enregistrée", result, _show_reception)
		return
	game._show_dialog("Chambre 206 réservée · Panne informatique", "Votre réservation est enregistrée. Soudain, l’écran de la réception se fige : le service informatique de l’hôtel ne répond plus. Rejoignez le local technique voisin pour diagnostiquer et réparer la panne.", game._close_overlay)

func _show_repair() -> void:
	game._open_overlay("hotel_repair")
	game._label(game.modal_content, "Local informatique · Diagnostic", 27)
	var panel := DiagnosticPanel.new()
	panel.configure(HotelService.state(), _diagnosis, _repair, _feedback, _observation)
	panel.observation_requested.connect(_observe_repair)
	panel.diagnosis_selected.connect(func(value: String):
		_diagnosis = value
		game._pending_focus_key = "hotel_diagnosis_" + value
		_show_repair())
	panel.repair_selected.connect(func(value: String):
		_repair = value
		game._pending_focus_key = "hotel_fix_" + value
		_show_repair())
	panel.submit_requested.connect(_submit_repair)
	panel.close_requested.connect(game._close_overlay)
	game.modal_content.add_child(panel)
	game._wire_modal()

func _observe_repair(id: String) -> void:
	var result: Dictionary = HotelService.observe_repair(id)
	if not result.ok:
		_show_error("Observation non enregistrée", result, _show_repair)
		return
	_observation = id
	game._pending_focus_key = "hotel_observe_" + id
	_show_repair()

func _submit_repair() -> void:
	if _action_busy: return
	_action_busy = true
	var result: Dictionary = HotelService.submit_repair(_diagnosis, _repair)
	_action_busy = false
	if not result.ok:
		_feedback = str(result.get("error", "Vérifiez les observations avant de réessayer."))
		game._pending_focus_key = "hotel_repair_submit"
		_show_repair()
		return
	_feedback = ""
	game._show_dialog("Service informatique rétabli", "Les anciens journaux sont archivés et le service peut à nouveau écrire sur le disque. La réception confirme votre réservation. Prenez les escaliers : seul le palier du premier étage est accessible, puis continuez jusqu’au deuxième étage et à la chambre 206.", game._close_overlay)

func _show_travel(destination: String, title: String, description: String) -> void:
	game._open_overlay("hotel_travel")
	game._label(game.modal_content, title, 27)
	game._label(game.modal_content, description)
	game._button(game.modal_content, "Y aller", func(): _travel(destination, title, description), "hotel_travel_go")
	game._button(game.modal_content, "Rester ici", game._close_overlay, "hotel_travel_stay")
	game._wire_modal()

func _travel(destination: String, title: String, description: String) -> void:
	if _action_busy: return
	var ground_arrival := destination == "building_02" and int(HotelService.state().get("morning_stage", 0)) == 1
	_action_busy = true
	var result: Dictionary = HotelService.travel(destination)
	_action_busy = false
	if not result.ok:
		_show_error("Passage indisponible", result, func(): _show_travel(destination, title, description))
		return
	game.world.restore_progress(AppState.profile.progress)
	game.world.restore_checkpoint()
	game._close_overlay()
	if ground_arrival:
		_notify_reward(result, "Rez-de-chaussée rejoint")
	if destination == "hotel_floor_2":
		game.notification_requested.emit("Étage 2 · Récupérez votre sac chambre 206" if int(HotelService.state().get("morning_stage", 0)) == 5 else "Étage 2 · Rendez-vous chambre 206")

func _show_luggage() -> void:
	game._open_overlay("hotel_luggage")
	game._label(game.modal_content, "Chambre 206 · Vos affaires", 27)
	if HotelService.state().get("luggage_placed", false):
		game._label(game.modal_content, "Vos affaires sont déjà posées. Le lit vous attend.")
	else:
		game._label(game.modal_content, "Posez votre valise et installez-vous dans votre chambre.")
		game._button(game.modal_content, "Déposer mes affaires", _place_luggage, "hotel_luggage_place")
	game._button(game.modal_content, "Continuer", game._close_overlay, "hotel_luggage_close")
	game._wire_modal()

func _place_luggage() -> void:
	var result: Dictionary = HotelService.place_luggage()
	if not result.ok:
		_show_error("Affaires non enregistrées", result, _show_luggage)
		return
	game._close_overlay()
	game.notification_requested.emit("Vos affaires sont posées. Vous pouvez vous installer sur le lit.")

func _show_bed() -> void:
	if is_sitting():
		restore_seated_overlay()
		return
	game._open_overlay("hotel_bed")
	game._label(game.modal_content, "Chambre 206 · Le lit", 27)
	var state: Dictionary = HotelService.state()
	if not state.get("luggage_placed", false):
		game._label(game.modal_content, "Déposez d’abord vos affaires sur le porte-bagages.")
		game._button(game.modal_content, "Continuer", game._close_overlay, "hotel_bed_close")
	elif state.get("bed_state", "standing") == "rested":
		game._label(game.modal_content, "Vous avez passé une nuit paisible. " + _morning_objective(int(state.get("morning_stage", 1)), str(AppState.profile.progress.room_id)))
		game._button(game.modal_content, "Continuer", game._close_overlay, "hotel_bed_close")
	else:
		game._label(game.modal_content, "Vous pouvez dormir tout de suite ou simplement vous poser. Une fois installé, vous resterez sur le lit jusqu’à choisir de dormir.")
		game._button(game.modal_content, "Dormir", _sleep, "hotel_bed_sleep")
		game._button(game.modal_content, "Se poser sur le lit", _sit, "hotel_bed_sit")
	game._wire_modal()

func _sit() -> void:
	var result: Dictionary = HotelService.sit_on_bed()
	if not result.ok:
		_show_error("Repos non enregistré", result, _show_bed)
		return
	wait_remaining_seconds = WAIT_SECONDS
	_show_waiting()

func _show_waiting() -> void:
	game._open_overlay("hotel_bed_waiting")
	game._label(game.modal_content, "Installé sur le lit", 27)
	game._label(game.modal_content, "Vous vous posez tranquillement. Un nouveau choix vous sera proposé dans quelques secondes.")
	_wait_label = game._label(game.modal_content, "", 21)
	_wait_label.name = "hotel_bed_countdown"
	_last_wait_second = -1
	_update_wait_label()
	game._label(game.modal_content, "P / Start : pause · Échap / face droit : pause", 16)
	_clock_msec = Time.get_ticks_msec()
	game._wire_modal()

func _update_wait_label() -> void:
	var second := ceili(wait_remaining_seconds)
	if second == _last_wait_second or not is_instance_valid(_wait_label): return
	_last_wait_second = second
	_wait_label.text = "Prochain choix dans %d s" % second

func _show_bed_choices() -> void:
	game._open_overlay("hotel_bed_choices")
	game._label(game.modal_content, "Toujours installé sur le lit", 27)
	game._label(game.modal_content, "Souhaitez-vous dormir ou continuer à vous reposer ?")
	game._button(game.modal_content, "Dormir", _sleep, "hotel_bed_sleep")
	game._button(game.modal_content, "Continuer à attendre", _wait_again, "hotel_bed_wait")
	game._wire_modal()

func _wait_again() -> void:
	if not is_sitting(): return
	wait_remaining_seconds = WAIT_SECONDS
	_show_waiting()

func _sleep() -> void:
	if _action_busy: return
	_action_busy = true
	var result: Dictionary = HotelService.sleep_in_bed()
	_action_busy = false
	if not result.ok:
		_show_error("Nuit non enregistrée", result, _show_bed_choices if is_sitting() else _show_bed)
		return
	game._open_overlay("hotel_night")
	game._label(game.modal_content, "La nuit passe…", 29)
	game._label(game.modal_content, "La chambre s’apaise. Vous vous endormez jusqu’au matin.")
	_night_duration = 0.12 if SettingsService.current.get("reduce_motion", false) else 1.2
	_night_remaining = _night_duration
	_clock_msec = Time.get_ticks_msec()

func _tick_night(elapsed_seconds: float) -> void:
	_night_remaining = maxf(0, _night_remaining - maxf(0, elapsed_seconds))
	if not SettingsService.current.get("reduce_motion", false):
		var light := absf(2.0 * (_night_remaining / _night_duration) - 1.0)
		game._room.modulate = Color(light, light, light)
	if _night_remaining <= 0:
		game._room.modulate = Color.WHITE
		game._open_overlay("hotel_morning")
		game._label(game.modal_content, "Au matin · Chambre 206", 28)
		game._label(game.modal_content, "Une nouvelle journée commence. " + _morning_objective(1, "hotel_room_206") + " Le petit déjeuner vous attend.")
		game._button(game.modal_content, "Continuer", game._close_overlay, "hotel_morning_continue")
		game._button(game.modal_content, "Retour au menu", game._return_to_menu, "hotel_morning_menu")
		game._wire_modal()

func _show_breakfast() -> void:
	game._open_overlay("hotel_breakfast")
	game._label(game.modal_content, "Petit déjeuner · Votre table", 27)
	if int(HotelService.state().get("morning_stage", 0)) == 2:
		game._label(game.modal_content, "Le buffet est prêt. Installez-vous un instant à cette table.")
		game._button(game.modal_content, "M’asseoir à la table", _sit_for_breakfast, "hotel_breakfast_sit")
	else:
		game._label(game.modal_content, _morning_objective(int(HotelService.state().get("morning_stage", 0)), "hotel_breakfast"))
	game._button(game.modal_content, "Continuer", game._close_overlay, "hotel_breakfast_close")
	game._wire_modal()

func _sit_for_breakfast() -> void:
	var result: Dictionary = HotelService.sit_for_breakfast()
	if not result.ok:
		_show_error("Petit déjeuner non enregistré", result, _show_breakfast)
		return
	game._show_dialog("Il manque votre café…", "À peine assis, vous réalisez que vous avez oublié votre café. La machine ne démarre plus : le panneau de connexion est débranché. Levez-vous et rejoignez la machine pour relier ses trois fils.", game._close_overlay)

func _show_coffee() -> void:
	game._open_overlay("hotel_coffee")
	game._label(game.modal_content, "Machine à café · Panneau de connexion", 27)
	var state: Dictionary = HotelService.state()
	var stage := int(state.get("morning_stage", 0))
	if stage < 3:
		game._label(game.modal_content, "Installez-vous d’abord à la table du petit déjeuner.")
	elif stage == 3:
		game._label(game.modal_content, "Vue rapprochée · Reliez une borne A, B ou C à une borne 1, 2 ou 3 de même couleur. Appuyez à nouveau sur une borne sélectionnée pour retirer sa sélection.", 17)
		coffee_panel = CoffeeWiringPanel.new()
		game.modal_content.add_child(coffee_panel)
		coffee_panel.terminal_pressed.connect(_select_coffee_terminal)
		_coffee_status = game._label(game.modal_content, "", 17)
		_coffee_status.name = "hotel_coffee_feedback"
		_refresh_coffee_panel()
	elif stage == 4:
		game._label(game.modal_content, "✓ Les trois fils sont reliés : la machine fonctionne à nouveau. Vous pouvez préparer votre café.")
		coffee_panel = CoffeeWiringPanel.new()
		game.modal_content.add_child(coffee_panel)
		coffee_panel.refresh(state.get("coffee_connections", {}), "")
		game._button(game.modal_content, "Prendre mon café", _take_coffee, "hotel_coffee_take")
	else:
		game._label(game.modal_content, "Vous avez pris votre café. Votre sac et votre ordinateur vous attendent dans la chambre 206.")
	game._button(game.modal_content, "Revenir dans la salle", game._close_overlay, "hotel_coffee_close")
	game._wire_modal()

func _select_coffee_terminal(id: String) -> void:
	if _action_busy or int(HotelService.state().get("morning_stage", 0)) != 3:
		return
	var connections: Dictionary = HotelService.state().get("coffee_connections", {})
	if connections.has(id) or id in connections.values():
		return
	if _coffee_selection == id:
		_coffee_selection = ""
		_coffee_feedback = "Sélection retirée. Choisissez une borne."
	elif _coffee_selection.is_empty() or ((_coffee_selection in ["A", "B", "C"]) == (id in ["A", "B", "C"])):
		_coffee_selection = id
		_coffee_feedback = "%s sélectionnée · Choisissez la même couleur en face." % id
	else:
		var top := _coffee_selection if _coffee_selection in ["A", "B", "C"] else id
		var bottom := id if id in ["1", "2", "3"] else _coffee_selection
		_action_busy = true
		var result: Dictionary = HotelService.connect_coffee_wire(top, bottom)
		_action_busy = false
		if not result.ok:
			# An incorrect pair and an unavailable save both preserve the last
			# validated connections and the currently highlighted first wire.
			_coffee_feedback = str(result.get("error", "Ces fils ne peuvent pas être reliés. Réessayez."))
		else:
			_coffee_selection = ""
			_coffee_feedback = "✓ Bornes %s et %s reliées." % [top, bottom]
			if int(HotelService.state().get("morning_stage", 0)) == 4:
				game._pending_focus_key = "hotel_coffee_take"
				_show_coffee()
				return
	_refresh_coffee_panel()
	game._wire_modal()

func _refresh_coffee_panel() -> void:
	if not is_instance_valid(coffee_panel):
		return
	var connections: Dictionary = HotelService.state().get("coffee_connections", {})
	coffee_panel.refresh(connections, _coffee_selection)
	if is_instance_valid(_coffee_status):
		_coffee_status.text = "%d / 3 connexions · " % connections.size() + (_coffee_feedback if not _coffee_feedback.is_empty() else "Choisissez une borne : son fil s’illuminera.")

func _take_coffee() -> void:
	var result: Dictionary = HotelService.take_coffee()
	if not result.ok:
		_show_error("Café non enregistré", result, _show_coffee)
		return
	game._show_dialog("Votre café est prêt", "Vous prenez votre café. Il est temps de préparer le CTF Sudo Hack : remontez dans la chambre 206 pour récupérer le sac à dos contenant votre ordinateur.", game._close_overlay)

func _show_backpack() -> void:
	game._open_overlay("hotel_backpack")
	game._label(game.modal_content, "Chambre 206 · Votre sac à dos", 27)
	var stage := int(HotelService.state().get("morning_stage", 0))
	if stage == 5:
		game._label(game.modal_content, "Votre ordinateur est dans votre sac. Prenez-le pour participer au CTF Sudo Hack · " + _reward_text("hotel_backpack") + ".")
		game._button(game.modal_content, "Récupérer mon sac et mon ordinateur", _collect_backpack, "hotel_backpack_take")
	elif stage < 5:
		game._label(game.modal_content, "Votre sac est en sécurité. " + _morning_objective(stage, "hotel_room_206"))
	else:
		game._label(game.modal_content, "Vous avez déjà votre sac et votre ordinateur. Rejoignez l’arrêt de bus devant l’hôtel.")
	game._button(game.modal_content, "Continuer", game._close_overlay, "hotel_backpack_close")
	game._wire_modal()

func _collect_backpack() -> void:
	var result: Dictionary = HotelService.collect_backpack()
	if not result.ok:
		_show_error("Sac non enregistré", result, _show_backpack)
		return
	game._close_overlay()
	_notify_reward(result, "Sac et ordinateur récupérés")

func _show_bus() -> void:
	game._open_overlay("hotel_bus")
	game._label(game.modal_content, "Arrêt de bus · Sudo Hack", 27)
	game._label(game.modal_content, "Le bus vous dépose devant le bâtiment du CTF Sudo Hack. Votre sac et votre ordinateur doivent être avec vous.")
	game._button(game.modal_content, "Prendre le bus", _board_bus, "hotel_bus_board")
	game._button(game.modal_content, "Rester ici", game._close_overlay, "hotel_bus_close")
	game._wire_modal()

func _board_bus() -> void:
	var result: Dictionary = HotelService.board_bus()
	if not result.ok:
		_show_error("Trajet non enregistré", result, _show_bus)
		return
	game.world.restore_progress(AppState.profile.progress)
	game.world.restore_checkpoint()
	game._close_overlay()
	game.notification_requested.emit("Sudo Hack · Entrez dans le bâtiment du CTF")

func _notify_reward(result: Dictionary, message: String) -> void:
	var reward := int(result.get("reward", 0))
	game.notification_requested.emit(PenaltyService.reward_message(message, result) + (" (récompense déjà obtenue)" if reward == 0 else ""))

func _show_error(title: String, result: Dictionary, retry: Callable) -> void:
	game._open_overlay("hotel_error")
	game._label(game.modal_content, title, 26)
	game._label(game.modal_content, str(result.get("error", "L’action n’a pas pu être enregistrée.")) + "\nL’état précédent est conservé.")
	game._button(game.modal_content, "Réessayer", retry, "hotel_retry")
	game._button(game.modal_content, "Continuer", game._close_overlay, "hotel_error_close")
	game._wire_modal()

func _show_ctf(id: String) -> void:
	if CtfService.mission_state(id) == "locked":
		game._show_dialog("Poste verrouillé", "Terminez le poste précédent. Le panneau de missions indique celui à rejoindre.", game._close_overlay)
		return
	game._open_overlay("ctf_challenge")
	var panel := CtfPanel.new()
	panel.mission_id = id
	game.modal_content.add_child(panel)
	panel.close_requested.connect(game._close_overlay)
	panel.navigation_changed.connect(func(): game._fit_modal.call_deferred(); game._wire_modal.call_deferred())
	panel.mission_completed.connect(func(result: Dictionary):
		game.notification_requested.emit(PenaltyService.reward_message("Épreuve Sudo Hack validée", result))
		game._show_dialog("Épreuve validée", str(CtfCatalog.CHALLENGES[id].explanation), game._close_overlay))
	game._wire_modal()

func _show_return_bus() -> void:
	game._open_overlay("ctf_bus")
	game._label(game.modal_content, "Arrêt de bus · retour en ville", 26)
	game._label(game.modal_content, "Le bus vous ramène sur le trottoir près de l'hôtel CIEL." if CtfService.completed() else "Le trajet de retour sera disponible après les cinq épreuves Sudo Hack.")
	if CtfService.completed():
		game._button(game.modal_content, "Revenir en ville", _return_bus, "ctf_bus_return")
	game._button(game.modal_content, "Rester ici", game._close_overlay, "ctf_bus_close")
	game._wire_modal()

func _return_bus() -> void:
	var result: Dictionary = HotelService.return_bus()
	if not result.ok:
		_show_error("Retour non enregistré", result, _show_return_bus)
		return
	game.world.restore_progress(AppState.profile.progress)
	game.world.restore_checkpoint()
	game._close_overlay()
	game.notification_requested.emit("Retour en ville · Hôtel CIEL")
