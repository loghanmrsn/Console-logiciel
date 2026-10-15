class_name DemoGame
extends Control
## Enquête intégrée au menu existant. Les réponses et récompenses restent dans les services.
const GlassButton = preload('res://scripts/ui/translucent_button.gd')
const WorldScene = preload('res://scenes/investigation_world.tscn')
const Challenge = preload('res://scripts/game/challenge_panel.gd')
const MissionTracker = preload('res://scripts/game/mission_tracker.gd')

signal menu_requested
signal settings_requested
signal help_requested
signal notification_requested(message: String)

var paused: bool = false:
	set(value):
		paused = value
		_sync_controls()
var world: Node2D
var challenge: VBoxContainer
var overlay_kind := ''
var modal_content: VBoxContainer
var _layout: VBoxContainer
var _room: SubViewportContainer
var _viewport: SubViewport
var _hint: Label
var _objectives: VBoxContainer
var _objective_panel: PanelContainer
var _objective_toggle: Button
var _objectives_expanded=true
var mission_tracker: Control
var _target_label: Label
var _interact_button: Button
var _target_panel: PanelContainer
var _layer: CanvasLayer
var _overlay: Control
var _modal_scroll: ScrollContainer
var _modal_panel: PanelContainer
var _modal_layout_serial=0
var _disabled_controls: Array = []
var _original_focus: Control
var _modal_serial := 0
var _busy := false
var _restored := false
var _last_profile_id := ''
var _pending_focus_key := ''
var _controller_waiting := false
var _controller_message := ''
var _controller_saved_kind := ''
var _controller_saved_nodes: Array[Node] = []
var _controller_saved_focus: Control
var _controller_saved_focus_key := ''
var _controller_saved_scroll := 0
var _controller_deferred_conclusion := false
var _missions_held := false

class RoomViewport extends SubViewportContainer:
	func _draw() -> void:
		if has_focus(): draw_style_box(get_theme_stylebox('focus','Button'),Rect2(Vector2.ZERO,size))

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	AppState.objectives_changed.connect(_progress_changed)
	visibility_changed.connect(_visibility_changed)
	SettingsService.settings_changed.connect(_settings_changed)
	resized.connect(_resize_viewport)
	refresh()
	call_deferred('_focus_room')

func _build() -> void:
	_layout = VBoxContainer.new()
	_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout.add_theme_constant_override('separation', 8)
	_layout.minimum_size_changed.connect(_fit_minimum)
	add_child(_layout)
	_room = RoomViewport.new()
	_room.name = 'game_room'
	_room.focus_mode = Control.FOCUS_ALL
	_room.mouse_filter = Control.MOUSE_FILTER_STOP
	_room.stretch = true
	_room.custom_minimum_size = Vector2(240, 170)
	_room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_room.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_room.focus_entered.connect(_room.queue_redraw)
	_room.focus_exited.connect(_room.queue_redraw)
	_room.gui_input.connect(func(event):
		if event.is_action('ui_up') or event.is_action('ui_down') or event.is_action('ui_left') or event.is_action('ui_right'):
			_room.accept_event()
		if event is InputEventMouseButton and event.pressed: _room.grab_focus())
	_layout.add_child(_room)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1000, 520)
	_viewport.handle_input_locally = false
	_viewport.gui_disable_input = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_room.add_child(_viewport)
	world = WorldScene.instantiate()
	_viewport.add_child(world)
	world.interaction_requested.connect(_interaction_requested)
	world.target_changed.connect(func(_id, label):
		_target_label.text=label.replace(' fictif','')
		_interact_button.disabled = label.is_empty()
		_target_panel.visible = not label.is_empty())
	# HUD uses native-size controls above the room; it is not scaled with the camera.
	var hud=MarginContainer.new()
	hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ['left','right','top','bottom']: hud.add_theme_constant_override('margin_'+side,12)
	add_child(hud)
	var hud_column=VBoxContainer.new()
	hud_column.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud.add_child(hud_column)
	var top=HBoxContainer.new()
	top.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud_column.add_child(top)
	var pause_button=_button(top,'Pause · P',request_pause,'game_pause')
	pause_button.custom_minimum_size=Vector2(136,44)
	pause_button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	pause_button.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	var flexible=Control.new()
	flexible.mouse_filter=Control.MOUSE_FILTER_IGNORE
	flexible.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(flexible)
	mission_tracker = MissionTracker.new()
	mission_tracker.panel_expanded = true
	mission_tracker.configure(InvestigationService)
	add_child(mission_tracker)
	mission_tracker.expanded_changed.connect(func(expanded: bool): _objectives_expanded = expanded)
	# Retained aliases keep the pause menu and keyboard tests on the same board.
	_objective_panel = mission_tracker.panel
	_objective_toggle = mission_tracker.toggle_button
	_objectives = mission_tracker.mission_list
	_hint = mission_tracker.next_step_label
	var space=Control.new()
	space.mouse_filter=Control.MOUSE_FILTER_IGNORE
	space.size_flags_vertical=Control.SIZE_EXPAND_FILL
	hud_column.add_child(space)
	var bottom=CenterContainer.new()
	bottom.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud_column.add_child(bottom)
	var target_panel=PanelContainer.new()
	_target_panel=target_panel
	target_panel.name='game_target_panel'
	target_panel.theme_type_variation='HUDPanel'
	target_panel.custom_minimum_size.x=320
	bottom.add_child(target_panel)
	var target_column=VBoxContainer.new()
	target_column.add_theme_constant_override('separation',2)
	target_panel.add_child(target_column)
	_target_label=_label(target_column,'Approchez un équipement')
	_target_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_target_label.add_theme_font_size_override('font_size',18)
	_interact_button=_button(target_column,'Interagir · Espace / face bas',_interact,'game_interact')
	_interact_button.add_theme_font_size_override('font_size',16)
	_interact_button.custom_minimum_size.y=36
	_interact_button.disabled=true
	_interact_button.focus_mode=Control.FOCUS_NONE
	target_panel.hide()
	_layer = CanvasLayer.new()
	_layer.layer = 80
	add_child(_layer)
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(_overlay)
	var shade := ColorRect.new()
	shade.color = Color(.15, .20, .25, .40)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ['left', 'right', 'top', 'bottom']: margin.add_theme_constant_override('margin_' + side, 18)
	_overlay.add_child(margin)
	var center=CenterContainer.new()
	margin.add_child(center)
	var panel := PanelContainer.new()
	_modal_panel=panel
	center.add_child(panel)
	_modal_scroll = ScrollContainer.new()
	_modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_modal_scroll.follow_focus = false
	panel.add_child(_modal_scroll)
	modal_content = VBoxContainer.new()
	modal_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_content.add_theme_constant_override('separation', 12)
	_modal_scroll.add_child(modal_content)
	_overlay.hide()
	_resize_viewport.call_deferred()

func refresh() -> void:
	if world == null: return
	_sync_overlay_theme()
	if not AppState.profile.is_empty():
		var changed: bool = _last_profile_id != str(AppState.profile.id)
		_last_profile_id = str(AppState.profile.id)
		world.restore_progress(AppState.profile.progress)
		_update_objectives()
		if not _restored or changed:
			_restored = true
			world.restore_checkpoint()
			var chapter_missions: Array = InvestigationService.chapter_missions()
			var final_mission := str(chapter_missions.back().id) if not chapter_missions.is_empty() else ''
			if not final_mission.is_empty() and final_mission in AppState.profile.progress.completed_missions:
				_show_conclusion.call_deferred()
	_sync_controls()
	if _controller_waiting:
		_show_controller_pause()
	if not overlay_kind.is_empty():
		_overlay.show()
		_pending_focus_key = SceneRouter.focus_key('game')
		_wire_modal.call_deferred()
	else: _focus_room.call_deferred()

func _progress_changed(progress: Dictionary) -> void:
	if not is_inside_tree() or world == null: return
	_sync_overlay_theme()
	world.restore_progress(progress)
	_update_objectives()

func _current_mission() -> String:
	for mission in InvestigationService.chapter_missions():
		if InvestigationService.mission_state(mission.id) in ['available','in_progress']:return mission.id
	return ''

func _toggle_objectives() -> void:
	if mission_tracker == null: return
	# Pause owns the input lock, but its explicit action can change the board.
	mission_tracker.set_input_enabled(true)
	mission_tracker.toggle_panel()
	_sync_controls()

func _update_objectives() -> void:
	if mission_tracker != null:
		mission_tracker.refresh()
		_hint = mission_tracker.next_step_label

func _resize_viewport() -> void:
	if not is_inside_tree(): return
	if _room!=null:
		_room.custom_minimum_size.y=120 if get_viewport_rect().size.y<600 else 170
	# SubViewportContainer.stretch suit la zone disponible automatiquement.
	# Son signal size_changed permet à la Camera2D d'ajuster la pièce.
	if is_instance_valid(world) and world.is_inside_tree(): world._fit_camera()
	_fit_minimum()
	if not overlay_kind.is_empty(): _fit_modal.call_deferred()

func _fit_minimum() -> void:
	if not is_inside_tree() or _layout == null: return
	var available := 170.0
	var ancestor: Node = get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			available = maxf(available, ancestor.size.y)
			break
		ancestor = ancestor.get_parent()
	custom_minimum_size.y = maxf(available,_layout.get_combined_minimum_size().y)

func _settings_changed(_value: Dictionary) -> void:
	if is_inside_tree():
		_sync_overlay_theme()
		_update_objectives()
		_target_label.add_theme_font_size_override('font_size',22 if SettingsService.current.get('large_text',false) else 18)
		_resize_viewport.call_deferred()
		if not overlay_kind.is_empty(): _fit_modal.call_deferred(); _wire_modal.call_deferred()

func _visibility_changed() -> void:
	if _overlay != null:
		_overlay.visible = is_visible_in_tree() and not overlay_kind.is_empty()
	if not is_visible_in_tree():
		_missions_held = false
		_release_focus_modes()
	elif not overlay_kind.is_empty() and _disabled_controls.is_empty():
		_disable_focus(get_tree().root)
	_sync_controls()
	if _controller_waiting and is_visible_in_tree(): _show_controller_pause.call_deferred()

func _exit_tree() -> void:
	_release_focus_modes()

func _notification(what: int) -> void:
	# Un changement d'écran retire ce jeu de l'arbre sans le détruire. Les
	# choix du défi restent alors conservés. Seule sa destruction finale doit
	# libérer les enfants temporairement détachés du panneau de suspension.
	if what == NOTIFICATION_PREDELETE:
		_discard_controller_context()

func _release_focus_modes() -> void:
	for entry in _disabled_controls:
		if is_instance_valid(entry[0]): entry[0].focus_mode = entry[1]
	_disabled_controls.clear()

func _sync_controls() -> void:
	var enabled := is_visible_in_tree() and not paused and overlay_kind.is_empty()
	if not enabled: _missions_held = false
	if is_instance_valid(world): world.set_controls_enabled(enabled)
	if is_instance_valid(mission_tracker):
		mission_tracker.visible = enabled
		mission_tracker.set_input_enabled(enabled)

func _sync_overlay_theme() -> void:
	if _overlay == null: return
	var ancestor: Node = self
	while ancestor != null:
		if ancestor is Control and ancestor.theme != null:
			_overlay.theme = ancestor.theme
			return
		ancestor = ancestor.get_parent()

func _process(_delta: float) -> void:
	if not is_visible_in_tree() or paused or not overlay_kind.is_empty() or not SceneRouter.gameplay_allowed(): return
	if Input.is_action_just_pressed('game_interact'): _interact()

func _input(event: InputEvent) -> void:
	if not ControllerService.accepts_event(event): return
	if event.is_action_released('game_missions'):
		_missions_held = false
		return
	# La confirmation globale possède la navigation, y compris Start/P.
	if get_tree().get_first_node_in_group('blocking_confirmation')!=null: return
	if not is_visible_in_tree() or event.is_echo(): return
	# Les lettres P/T et l’espace appartiennent au texte saisi dans un défi,
	# même pendant le verrou de transition ; Échap garde son rôle de retour.
	var typing: Control = get_viewport().gui_get_focus_owner()
	if event is InputEventKey and typing is LineEdit and modal_content.is_ancestor_of(typing) and not event.is_action("ui_cancel"):
		return
	if event.is_action_pressed('game_missions'):
		if not paused and overlay_kind.is_empty() and SceneRouter.gameplay_allowed():
			if not _missions_held:
				_missions_held = true
				_toggle_objectives()
			get_viewport().set_input_as_handled()
		return
	if not overlay_kind.is_empty() and not SceneRouter.gameplay_allowed():
		if event.is_action('ui_accept') or event.is_action('game_interact') or event.is_action('ui_cancel') or event.is_action('pause'):
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed('pause'):
		get_viewport().set_input_as_handled()
		if overlay_kind == 'pause': resume()
		elif overlay_kind.is_empty(): request_pause()
	elif event.is_action_pressed('ui_cancel') and not overlay_kind.is_empty():
		get_viewport().set_input_as_handled()
		handle_back()

func _interact() -> void:
	if paused or _busy or not overlay_kind.is_empty() or not SceneRouter.gameplay_allowed(): return
	world.interact_nearest()

func _interaction_requested(id: String) -> void:
	if _busy or paused or not overlay_kind.is_empty(): return
	if id == 'elevator':
		_show_elevator()
		return
	var state: String = InvestigationService.mission_state(id)
	if state == 'locked':
		var blocked := {'lock': 'Rétablissez d’abord l’éclairage pour lire les observations de la serrure.', 'computer': 'Débloquez la porte du bureau pour accéder à l’ordinateur.', 'network': 'Terminez le rez-de-chaussée puis prenez l’ascenseur.', 'addressing': 'Rétablissez la liaison Ethernet avant de vérifier l’adresse du poste.', 'security': 'Corrigez l’adresse IP du poste avant de protéger la connexion Wi-Fi.', 'python': 'Terminez les trois missions de la salle réseau, puis prenez l’ascenseur vers l’atelier du code.', 'html': 'Complétez d’abord la mission Python pour découvrir les balises HTML.', 'markdown': 'Complétez d’abord le titre HTML pour découvrir son équivalent en Markdown.'}
		_show_dialog('Un préalable manque', str(blocked.get(id, 'Terminez la mission précédente.')), _close_overlay)
		return
	if state == 'completed':
		if id in ['computer', 'security', 'markdown']: _show_conclusion()
		else:
			var definition: Dictionary = InvestigationService.mission(id)
			_show_dialog('Équipement rétabli', str(definition.get('success_explanation', 'Cette mission est terminée et sa récompense a déjà été enregistrée.')), _close_overlay)
		return
	_busy = true
	var result: Dictionary = InvestigationService.begin_mission(id)
	_busy = false
	if not result.ok:
		_show_dialog('Sauvegarde impossible', result.error + '\nL’état précédent est conservé. Fermez puis examinez de nouveau cet équipement pour réessayer.', _close_overlay)
		return
	_open_overlay('challenge')
	challenge = Challenge.new()
	modal_content.add_child(challenge)
	challenge.configure(id)
	challenge.close_requested.connect(_close_overlay)
	challenge.notification_requested.connect(func(message): notification_requested.emit(message))
	challenge.navigation_changed.connect(_wire_modal)
	challenge.mission_completed.connect(_mission_completed)
	_wire_modal()

func _mission_completed(result: Dictionary) -> void:
	var data: Dictionary = result.get('data', {})
	var reward: int = int(data.get('reward', 0))
	var explanation: String = str(data.get('explanation', 'L’équipement est rétabli.'))
	var clue_text: String = str(data.get('clue', {}).get('text', ''))
	if not clue_text.is_empty(): explanation += '\n\n' + clue_text
	var reward_text := '%d points nouvellement gagnés.' % reward if reward > 0 else 'Déjà récompensée : aucun point ajouté pour cette mission rejouée.'
	var next: Callable = _show_conclusion if data.get('mission_id') in ['computer', 'security', 'markdown'] else _close_overlay
	_show_dialog('✓ Mission terminée', explanation + '\n\n' + reward_text + '\nProgression et récompense sauvegardées.', next)

func _show_elevator() -> void:
	if not InvestigationService.can_use_elevator():
		_show_dialog('Ascenseur verrouillé', 'L’accès à l’étage sera disponible après les trois missions du rez-de-chaussée : éclairage, porte et ordinateur. Consultez le panneau Missions avec T ou le bouton du haut de la manette.', _close_overlay)
		return
	var chapter := InvestigationService.current_chapter()
	var historical_destination := 1 if chapter == 2 else 2
	_open_overlay('elevator')
	_label(modal_content, 'Ascenseur · CIEL', 26)
	_label(modal_content, 'Choisissez votre destination. Les missions terminées et vos points sont conservés.')
	var destinations := {
		1: 'Rez-de-chaussée · Chapitre 1 · Le bureau',
		2: 'Étage 1 · Chapitre 2 · La salle réseau',
		3: 'Étage 2 · Chapitre 3 · L’atelier du code'
	}
	for destination in [1, 2, 3]:
		var key := 'elevator_travel' if destination == historical_destination else 'elevator_chapter_%d' % destination
		var accessible: bool = InvestigationService.can_enter_chapter(destination)
		var caption := str(destinations[destination])
		if destination == chapter:
			caption += ' · Vous êtes ici'
		elif not accessible:
			caption += ' · Verrouillé'
		var travel := _button(modal_content, caption, func(): _travel_to_chapter(destination), key)
		travel.disabled = destination == chapter or not accessible
		if destination == 3 and accessible and chapter != 3:
			travel.theme_type_variation = 'PrimaryButton'
	if not InvestigationService.can_enter_chapter(3):
		_label(modal_content, 'Pour ouvrir l’atelier du code, terminez les trois missions du chapitre 2 : réseau, adresse IPv4 et Wi-Fi.')
	_button(modal_content, 'Rester dans la pièce', _close_overlay, 'elevator_cancel')
	_wire_modal()

func _travel_to_chapter(destination: int) -> void:
	if _busy or overlay_kind != 'elevator': return
	_busy = true
	var result: Dictionary = InvestigationService.enter_chapter(destination)
	_busy = false
	if not result.ok:
		_show_dialog('Déplacement non enregistré', result.error + '\nVous restez dans la pièce actuelle. Votre progression est conservée.', _show_elevator)
		return
	# The service has committed the checkpoint before the new room is displayed.
	world.restore_progress(AppState.profile.progress)
	world.restore_checkpoint()
	_close_overlay()
	if not SettingsService.current.get('reduce_motion', false):
		_room.modulate = Color(.76, .83, .80)
		var arrival := create_tween()
		arrival.tween_property(_room, 'modulate', Color.WHITE, .24)
	var arrivals := {1: 'Chapitre 1 · Retour au bureau.', 2: 'Chapitre 2 · Bienvenue dans la salle réseau.', 3: 'Chapitre 3 · Bienvenue dans l’atelier du code.'}
	notification_requested.emit(str(arrivals.get(destination, 'Bienvenue dans la pièce.')))

func request_pause() -> void:
	if not is_visible_in_tree() or not overlay_kind.is_empty(): return
	_open_overlay('pause')
	_label(modal_content, 'Pause', 26)
	_label(modal_content, 'Les déplacements et interactions sont suspendus.')
	var resume_button=_button(modal_content, 'Reprendre', resume, 'pause_resume')
	resume_button.theme_type_variation='PrimaryButton'
	_button(modal_content, 'Masquer les objectifs' if _objectives_expanded else 'Afficher les objectifs', func():
		_toggle_objectives()
		resume(), 'pause_objectives')
	if InvestigationService.conclusion().ok:
		_button(modal_content, 'Bilan du chapitre', _show_conclusion, 'pause_conclusion')
	_button(modal_content, 'Paramètres', func(): settings_requested.emit(), 'pause_settings')
	_button(modal_content, 'Aide aux commandes', func(): help_requested.emit(), 'pause_help')
	_button(modal_content, 'Retour au menu', _return_to_menu, 'pause_menu')
	_wire_modal()

func resume() -> void:
	if overlay_kind == 'pause': _close_overlay()

func controller_lost(message: String) -> void:
	_controller_message = message if not message.is_empty() else 'La manette active a été déconnectée. Le clavier reste utilisable. Reprenez explicitement lorsque vous êtes prêt.'
	_controller_waiting = true
	paused = true
	# Paramètres et Aide conservent ce jeu hors de l'arbre : son interface
	# sera suspendue à son retour, sans supprimer le défi ou la pause.
	if is_inside_tree() and is_visible_in_tree(): _show_controller_pause()

func _show_controller_pause() -> void:
	if not _controller_waiting or not is_inside_tree() or not is_visible_in_tree() or modal_content == null: return
	if overlay_kind == 'controller_pause':
		_update_controller_message()
		return
	_modal_serial += 1
	_controller_saved_kind = overlay_kind
	_controller_saved_scroll = _modal_scroll.scroll_vertical
	_controller_saved_focus_key = SceneRouter.focus_key('game')
	var owner: Control = get_viewport().gui_get_focus_owner()
	if is_instance_valid(owner) and modal_content.is_ancestor_of(owner):
		_controller_saved_focus = owner
		_controller_saved_focus_key = String(owner.name)
	else:
		_controller_saved_focus = null
	if overlay_kind.is_empty(): _original_focus = owner
	if _disabled_controls.is_empty(): _disable_focus(get_tree().root)
	# Détacher plutôt que reconstruire préserve les réponses cochées, les
	# observations ouvertes et le même objet challenge.
	for child in modal_content.get_children():
		modal_content.remove_child(child)
		_controller_saved_nodes.append(child)
	overlay_kind = 'controller_pause'
	paused = true
	_overlay.show()
	_modal_scroll.scroll_vertical = 0
	_label(modal_content, 'Manette déconnectée · Jeu suspendu', 26)
	var explanation := _label(modal_content, _controller_message)
	explanation.name = 'controller_message'
	_label(modal_content, 'Le clavier reste disponible. Une reconnexion ne reprend pas automatiquement la partie. Vos choix sont conservés.')
	_button(modal_content, 'Reprendre explicitement', _resume_controller, 'controller_resume')
	_button(modal_content, 'Retour au menu', _return_to_menu, 'controller_menu')
	_pending_focus_key = 'controller_resume'
	SceneRouter.lock_until_release()
	_wire_modal()

func _update_controller_message() -> void:
	var explanation := modal_content.get_node_or_null('controller_message') as Label
	if explanation != null: explanation.text = _controller_message

func _resume_controller() -> void:
	if overlay_kind != 'controller_pause' or not _controller_waiting: return
	_modal_serial += 1
	for child in modal_content.get_children():
		modal_content.remove_child(child)
		child.queue_free()
	var previous_kind := _controller_saved_kind
	var previous_scroll := _controller_saved_scroll
	var previous_focus_key := _controller_saved_focus_key
	var previous_focus := _controller_saved_focus
	for child in _controller_saved_nodes:
		if is_instance_valid(child): modal_content.add_child(child)
	_controller_saved_nodes.clear()
	_controller_saved_focus = null
	_controller_saved_focus_key = ''
	_controller_saved_kind = ''
	_controller_waiting = false
	_controller_message = ''
	overlay_kind = previous_kind
	if overlay_kind.is_empty():
		_close_overlay()
	else:
		paused = true
		_overlay.show()
		_modal_scroll.scroll_vertical = previous_scroll
		_pending_focus_key = previous_focus_key
		if is_instance_valid(previous_focus) and previous_focus.is_inside_tree() and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
		SceneRouter.lock_until_release()
		_fit_modal.call_deferred()
		_wire_modal()
	if _controller_deferred_conclusion:
		_controller_deferred_conclusion = false
		_show_conclusion()

func _discard_controller_context() -> void:
	for child in _controller_saved_nodes:
		if is_instance_valid(child): child.free()
	_controller_saved_nodes.clear()
	_controller_saved_focus = null
	_controller_saved_focus_key = ''
	_controller_saved_kind = ''
	_controller_waiting = false
	_controller_deferred_conclusion = false

func handle_back() -> void:
	match overlay_kind:
		'controller_pause': return
		'': request_pause()
		'confirm': _show_conclusion()
		'challenge', 'pause', 'elevator': _close_overlay()
		'dialog': _close_overlay()
		'conclusion': _return_to_menu()

func _return_to_menu() -> void:
	var saved: Dictionary = ProfileService.save_active()
	if not saved.ok:
		if overlay_kind == 'controller_pause':
			_controller_message = saved.error + '\nLa sauvegarde a échoué. L’état précédent et vos choix sont conservés. Réessayez « Retour au menu » ou reprenez explicitement la partie.'
			_update_controller_message()
			return
		_open_overlay('dialog')
		_label(modal_content, 'Sauvegarde impossible', 26)
		_label(modal_content, saved.error + '\nLa progression déjà enregistrée reste intacte. Réessayez ou reprenez la partie.')
		_button(modal_content, 'Réessayer le retour au menu', _return_to_menu, 'save_retry')
		_button(modal_content, 'Reprendre', _close_overlay, 'save_stay')
		_wire_modal()
		return
	if _controller_waiting: _discard_controller_context()
	_close_overlay()
	menu_requested.emit()

func _show_conclusion() -> void:
	if not is_inside_tree(): return
	if _controller_waiting:
		_controller_deferred_conclusion = true
		return
	var result: Dictionary = InvestigationService.conclusion()
	if not result.ok:
		_show_dialog('Enquête en cours',result.error,_close_overlay)
		return
	_open_overlay('conclusion')
	var chapter := InvestigationService.current_chapter()
	var room_names := {1: 'Bureau fictif', 2: 'Salle réseau', 3: 'Atelier du code'}
	var titles := {1: 'Le message retrouvé', 2: 'Un réseau rétabli et protégé', 3: 'Vos premières lignes de code'}
	_label(modal_content, 'Chapitre %d terminé · %s' % [chapter, str(room_names.get(chapter, 'CIEL'))], 22)
	_label(modal_content, str(titles.get(chapter, 'Enquête terminée')), 28)
	_label(modal_content, str(result.data.message))
	_label(modal_content, 'Bilan de l’enquête', 24)
	var recaps := {
		1: '✓ Éclairage : un circuit doit former une boucle fermée.\n✓ Serrure : une alimentation correcte ne garantit pas la transmission de la commande.\n✓ Ordinateur : observer et vérifier permet de distinguer une panne du poste d’une liaison vidéo débranchée.',
		2: '✓ Ethernet : un lien réseau nécessite une liaison physique correctement connectée.\n✓ IPv4 : le poste et sa passerelle doivent partager un réseau cohérent.\n✓ Wi-Fi : utilisez un chiffrement adapté pour protéger l’accès au réseau.',
		3: '✓ Python : print("Bonjour CIEL") affiche un message.\n✓ HTML : <h1>Bonjour CIEL</h1> définit un titre principal avec une balise ouvrante et une balise fermante.\n✓ Markdown : # Bonjour CIEL crée un titre ; un espace suit le symbole #.'
	}
	_label(modal_content, str(recaps.get(chapter, 'Les missions de cet étage sont terminées.')))
	var progress: Dictionary = AppState.profile.get('progress', {})
	_label(modal_content, '%d points nouvellement gagnés pendant cette partie.\nSolde total du profil : %d points.' % [int(progress.get('run_reward_points', 0)), int(AppState.profile.get('wallet', {}).get('points', 0))], 22)
	_label(modal_content, 'Simulations pédagogiques fictives. Aucune intervention sur le matériel ou le système hôte.')
	var next_steps := {
		1: 'L’ascenseur en bas du bureau est maintenant déverrouillé. Revenez dans la pièce pour monter au chapitre 2.',
		2: 'Le chapitre 3 est maintenant accessible. Revenez dans la pièce, puis prenez l’ascenseur vers l’atelier du code : Python, HTML et Markdown vous attendent.',
		3: 'Bravo ! Les trois chapitres sont terminés. Vous pouvez rester dans l’atelier du code ou reprendre l’ascenseur pour revisiter les autres étages.'
	}
	_label(modal_content, str(next_steps.get(chapter, 'Revenez dans la pièce pour continuer.')))
	var stay := _button(modal_content, 'Revenir dans la pièce', _close_overlay, 'conclusion_stay')
	stay.theme_type_variation = 'PrimaryButton'
	_button(modal_content, 'Retour au menu', _return_to_menu, 'conclusion_menu')
	_button(modal_content, 'Rejouer', _confirm_replay, 'conclusion_replay')
	_wire_modal()

func _confirm_replay() -> void:
	_open_overlay('confirm')
	_label(modal_content, 'Rejouer l’enquête ?', 26)
	_label(modal_content, 'Les objectifs et indices de cette partie seront remis à zéro. Vos achats, votre solde et les récompenses déjà attribuées restent conservés : aucune mission déjà récompensée ne rapportera de nouveaux points.')
	_button(modal_content, 'Annuler', _show_conclusion, 'replay_cancel')
	_button(modal_content, 'Rejouer', _replay, 'replay_confirm')
	_wire_modal()

func _replay() -> void:
	var result: Dictionary = ProfileService.start_game()
	if not result.ok:
		_show_dialog('Sauvegarde impossible', result.error, _show_conclusion)
		return
	world.restore_progress(AppState.profile.progress)
	world.restore_checkpoint()
	_close_overlay()

func _show_dialog(title: String, text: String, accepted: Callable) -> void:
	_open_overlay('dialog')
	_label(modal_content, title, 26)
	_label(modal_content, text)
	_button(modal_content, 'Continuer', accepted, 'dialog_continue')
	_wire_modal()

func _open_overlay(kind: String) -> void:
	if overlay_kind.is_empty():
		_original_focus = get_viewport().gui_get_focus_owner()
		_disable_focus(get_tree().root)
	for child in modal_content.get_children():
		modal_content.remove_child(child)
		child.queue_free()
	challenge = null
	overlay_kind = kind
	paused = true
	_overlay.show()
	_modal_scroll.scroll_vertical = 0
	_fit_modal.call_deferred()
	SceneRouter.lock_until_release()

func _fit_modal() -> void:
	if not is_inside_tree() or overlay_kind.is_empty():return
	_modal_layout_serial+=1
	var token=_modal_layout_serial
	var extent=get_viewport_rect().size
	_modal_panel.custom_minimum_size.x=minf(extent.x-36,900 if overlay_kind=='challenge' else 660)
	await get_tree().process_frame
	if not is_inside_tree():return
	await get_tree().process_frame
	if not is_inside_tree() or overlay_kind.is_empty() or token!=_modal_layout_serial:return
	_modal_panel.custom_minimum_size.y=minf(extent.y-36,modal_content.get_combined_minimum_size().y+32)


func _disable_focus(node: Node) -> void:
	# Disable underlying header/buttons too, while leaving the modal's own tree alone.
	if node == _layer: return
	if node is Control and node.focus_mode != Control.FOCUS_NONE:
		_disabled_controls.append([node, node.focus_mode])
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children(): _disable_focus(child)

func _close_overlay() -> void:
	_modal_serial += 1
	for child in modal_content.get_children():
		modal_content.remove_child(child)
		child.queue_free()
	challenge = null
	_overlay.hide()
	overlay_kind = ''
	_release_focus_modes()
	paused = false
	SceneRouter.lock_until_release()
	call_deferred('_restore_original_focus')

func _restore_original_focus() -> void:
	if not is_inside_tree() or not is_visible_in_tree() or not overlay_kind.is_empty(): return
	if is_instance_valid(_original_focus) and _original_focus.is_inside_tree() and _original_focus.is_visible_in_tree(): _original_focus.grab_focus()
	else: _focus_room()

func _focus_room() -> void:
	if is_inside_tree() and is_visible_in_tree() and overlay_kind.is_empty(): _room.grab_focus()

func _wire_modal() -> void:
	if not is_inside_tree() or overlay_kind.is_empty(): return
	_modal_serial += 1
	var serial := _modal_serial
	await get_tree().process_frame
	if not is_inside_tree(): return
	await get_tree().process_frame
	if not is_inside_tree() or serial != _modal_serial or overlay_kind.is_empty() or not is_visible_in_tree(): return
	var targets: Array[Control] = []
	_collect_focus(modal_content, targets)
	for index in range(targets.size()):
		var control: Control = targets[index]
		var previous: Control = targets[posmod(index - 1, targets.size())]
		var next: Control = targets[(index + 1) % targets.size()]
		control.focus_previous = control.get_path_to(previous)
		control.focus_next = control.get_path_to(next)
		control.focus_neighbor_top = control.get_path_to(previous)
		control.focus_neighbor_bottom = control.get_path_to(next)
		control.focus_neighbor_left = control.get_path_to(previous)
		control.focus_neighbor_right = control.get_path_to(next)
		if not control.focus_entered.is_connected(_ensure_modal_focus): control.focus_entered.connect(_ensure_modal_focus)
	if is_instance_valid(challenge) and is_instance_valid(challenge.code_keyboard):
		challenge.code_keyboard.wire_navigation()
	var owner: Control = get_viewport().gui_get_focus_owner()
	if not targets.is_empty() and (not is_instance_valid(owner) or not modal_content.is_ancestor_of(owner) or owner.focus_mode != Control.FOCUS_ALL):
		var target: Control = targets[0]
		for candidate in targets:
			if not _pending_focus_key.is_empty() and candidate.name == _pending_focus_key: target = candidate
		target.grab_focus()
	_pending_focus_key = ''
	_ensure_modal_focus()

func _collect_focus(node: Node, result: Array[Control]) -> void:
	if node is Control and node.is_visible_in_tree() and node.focus_mode == Control.FOCUS_ALL and not (node is BaseButton and node.disabled): result.append(node)
	for child in node.get_children(): _collect_focus(child, result)

func _ensure_modal_focus() -> void:
	if not is_inside_tree() or overlay_kind.is_empty(): return
	await get_tree().process_frame
	if not is_inside_tree(): return
	await get_tree().process_frame
	if not is_inside_tree() or overlay_kind.is_empty(): return
	var owner: Control = get_viewport().gui_get_focus_owner()
	if is_instance_valid(owner) and modal_content.is_ancestor_of(owner): _modal_scroll.ensure_control_visible(owner)

func _label(host: Node, text: String, font_size: int = 0) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if font_size > 0: label.add_theme_font_size_override('font_size', font_size + (2 if SettingsService.current.get('large_text', false) else 0))
	host.add_child(label)
	return label

func _button(host: Node, text: String, action: Callable, key: String) -> Button:
	var button := GlassButton.new()
	button.name = key
	button.text = text
	button.pressed.connect(action)
	host.add_child(button)
	return button
