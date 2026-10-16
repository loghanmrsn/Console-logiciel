extends Control
## Hotel objectives and native modal interactions. Saved story state belongs to
## HotelService; this component only owns presentation and the seated clock.
const HOTEL_ZONES := ["building_02", "hotel_it", "hotel_stairs_1", "hotel_floor_2", "hotel_room_206"]
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
var _last_wait_second := -1
var _night_remaining := 0.0
var _night_duration := 1.2
var _action_busy := false
var _objective_fit_scheduled := false

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
	return not AppState.profile.is_empty() and str(AppState.profile.get("progress", {}).get("room_id", "")) in HOTEL_ZONES

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
	objective_title.text = "HÔTEL CIEL · " + ({"hotel_stairs_1": "PALIER 1", "hotel_floor_2": "ÉTAGE 2", "hotel_room_206": "CHAMBRE 206"}.get(current_room, "RÉCEPTION"))
	if not state.get("reserved", false):
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
		objective_text.text = "Une nouvelle journée commence. La suite du séjour arrivera plus tard."
	else:
		objective_text.text = "Vos affaires sont posées. Installez-vous sur le lit."
	objective_text.visible = objectives_expanded
	_fit_objectives()
	_schedule_objective_fit()
	sync_visibility()

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
	if not id.begins_with("hotel_"):
		return false
	match id:
		"hotel_reception": _show_reception()
		"hotel_repair": _show_repair()
		"hotel_luggage": _show_luggage()
		"hotel_bed": _show_bed()
		"hotel_it_door": _show_travel("hotel_it", "Local informatique", "Le local technique est juste à côté du hall.")
		"hotel_it_return": _show_travel("building_02", "Revenir à la réception", "Retrouvez le hall et les escaliers.")
		"hotel_stairs_up":
			var first := str(AppState.profile.progress.room_id) == "building_02"
			_show_travel("hotel_stairs_1" if first else "hotel_floor_2", "Monter l’escalier", "Le premier étage est fermé au public : seul son palier d’escalier est accessible." if first else "Le deuxième étage dessert votre chambre 206.")
		"hotel_stairs_down":
			var second := str(AppState.profile.progress.room_id) == "hotel_floor_2"
			_show_travel("hotel_stairs_1" if second else "building_02", "Descendre l’escalier", "Rejoignez le palier inférieur par l’escalier voisin.")
		"hotel_room206": _show_travel("hotel_room_206", "Chambre 206", "Votre chambre vous attend. Vous pourrez y déposer vos affaires.")
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
	if HotelService.state().get("repaired", false):
		game._label(game.modal_content, "Le service de réservation fonctionne à nouveau. Montez les escaliers vers le deuxième étage, puis rejoignez la chambre 206.")
		game._button(game.modal_content, "Revenir au local", game._close_overlay, "hotel_repair_close")
		game._wire_modal()
		return
	game._label(game.modal_content, "Examinez les quatre indices, puis choisissez le diagnostic et une réparation adaptée. Les choix erronés vous permettent de réessayer.")
	var observed: Array = HotelService.state().get("repair_observations", [])
	for id in HotelService.REPAIR_OBSERVATIONS:
		var key := str(id)
		game._button(game.modal_content, ("✓ " if key in observed else "○ ") + str(HotelService.REPAIR_OBSERVATIONS[key].title), func(): _observe_repair(key), "hotel_observe_" + key)
		if key in observed:
			game._label(game.modal_content, str(HotelService.REPAIR_OBSERVATIONS[key].text), 16)
	game._label(game.modal_content, "Quel diagnostic explique les indices ?", 21)
	for option in [["storage_full", "Le disque est saturé par les journaux"], ["network_link", "Le câble réseau est débranché"], ["power_supply", "Le serveur manque d’alimentation"]]:
		var value := str(option[0])
		game._button(game.modal_content, ("✓ " if _diagnosis == value else "○ ") + str(option[1]), func():
			_diagnosis = value
			game._pending_focus_key = "hotel_diagnosis_" + value
			_show_repair(), "hotel_diagnosis_" + value)
	game._label(game.modal_content, "Quelle intervention faut-il effectuer ?", 21)
	for option in [["archive_logs_restart", "Archiver les journaux puis relancer le service"], ["reboot_only", "Redémarrer sans libérer d’espace"], ["disable_firewall", "Désactiver le pare-feu"]]:
		var value := str(option[0])
		game._button(game.modal_content, ("✓ " if _repair == value else "○ ") + str(option[1]), func():
			_repair = value
			game._pending_focus_key = "hotel_fix_" + value
			_show_repair(), "hotel_fix_" + value)
	if not _feedback.is_empty():
		var feedback: Label = game._label(game.modal_content, _feedback)
		feedback.name = "hotel_repair_feedback"
	var submit: Button = game._button(game.modal_content, "Vérifier et réparer", _submit_repair, "hotel_repair_submit")
	submit.disabled = _diagnosis.is_empty() or _repair.is_empty()
	game._button(game.modal_content, "Revenir au local", game._close_overlay, "hotel_repair_close")
	game._wire_modal()

func _observe_repair(id: String) -> void:
	var result: Dictionary = HotelService.observe_repair(id)
	if not result.ok:
		_show_error("Observation non enregistrée", result, _show_repair)
		return
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
	_action_busy = true
	var result: Dictionary = HotelService.travel(destination)
	_action_busy = false
	if not result.ok:
		_show_error("Passage indisponible", result, func(): _show_travel(destination, title, description))
		return
	game.world.restore_progress(AppState.profile.progress)
	game.world.restore_checkpoint()
	game._close_overlay()
	if destination == "hotel_floor_2":
		game.notification_requested.emit("Étage 2 · Rendez-vous chambre 206")

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
		game._label(game.modal_content, "Vous avez passé une nuit paisible. La suite du séjour sera ajoutée plus tard.")
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
		game._label(game.modal_content, "Vous avez passé la nuit à l’hôtel. Le service informatique fonctionne et votre séjour peut continuer. Les prochaines aventures seront ajoutées plus tard.")
		game._button(game.modal_content, "Continuer", game._close_overlay, "hotel_morning_continue")
		game._button(game.modal_content, "Retour au menu", game._return_to_menu, "hotel_morning_menu")
		game._wire_modal()

func _show_error(title: String, result: Dictionary, retry: Callable) -> void:
	game._open_overlay("hotel_error")
	game._label(game.modal_content, title, 26)
	game._label(game.modal_content, str(result.get("error", "L’action n’a pas pu être enregistrée.")) + "\nL’état précédent est conservé.")
	game._button(game.modal_content, "Réessayer", retry, "hotel_retry")
	game._button(game.modal_content, "Continuer", game._close_overlay, "hotel_error_close")
	game._wire_modal()
