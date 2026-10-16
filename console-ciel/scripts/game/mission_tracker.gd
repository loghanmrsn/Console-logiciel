extends Control
## Native overlay: the board stays readable while the room follows its camera.
## DemoGame owns keyboard/controller input and hides it behind modal screens.
signal expanded_changed(expanded: bool)

const SHORT_NAMES := {
	"lighting": "Rétablir l’éclairage",
	"lock": "Débloquer la porte",
	"computer": "Diagnostiquer le poste",
	"network": "Rétablir le réseau",
	"addressing": "Corriger l’adresse IPv4",
	"security": "Protéger le Wi-Fi",
	"python": "Afficher un message en Python",
	"html": "Écrire un titre HTML",
	"markdown": "Créer un titre Markdown", "firewall": "Configurer le pare-feu", "ip_conflict": "Résoudre un conflit IPv4", "subnet_mask": "Choisir le masque réseau", "maze": "???"
}
const NEXT_STEPS := {
	"lighting": "Examinez le tableau électrique.",
	"lock": "Examinez la commande de la porte.",
	"computer": "Examinez le poste dans le bureau.",
	"network": "Examinez le commutateur réseau.",
	"addressing": "Vérifiez l’adresse du poste.",
	"security": "Examinez le point d’accès Wi-Fi.",
	"python": "Examinez le poste Python.",
	"html": "Examinez le poste HTML.",
	"markdown": "Examinez le tableau Markdown.", "firewall": "Examinez le poste pare-feu.", "ip_conflict": "Comparez les adresses IP.", "subnet_mask": "Consultez le plan du réseau.", "maze": "???"
}
const COMPACT_NAMES := {"lighting": "Éclairage", "lock": "Porte", "computer": "Ordinateur", "network": "Réseau", "addressing": "Adresse IPv4", "security": "Wi-Fi", "python": "Python", "html": "HTML", "markdown": "Markdown", "firewall": "Pare-feu", "ip_conflict": "Conflit IPv4", "subnet_mask": "Masque /26", "maze": "???"}
const COMPACT_NEXT_STEPS := {
	"lighting": "Examinez le tableau électrique.",
	"lock": "Examinez la porte.",
	"computer": "Examinez l’ordinateur.",
	"network": "Examinez le commutateur.",
	"addressing": "Vérifiez l’adresse du poste.",
	"security": "Examinez le point Wi-Fi.",
	"python": "Examinez le poste Python.",
	"html": "Examinez le poste HTML.",
	"markdown": "Examinez le tableau Markdown.", "firewall": "Examinez le poste pare-feu.", "ip_conflict": "Comparez les adresses IP.", "subnet_mask": "Consultez le plan du réseau.", "maze": "???"
}

var panel_expanded := true
var panel: PanelContainer
var toggle_button: Button
var chapter_label: Label
var progress_bar: ProgressBar
var mission_list: VBoxContainer
var next_step_label: Label
var _body: ScrollContainer
var _column: VBoxContainer
var _service: Node
var _input_enabled := true
var _compact := false
var _fit_scheduled := false


func _ready() -> void:
	name = "mission_tracker"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	resized.connect(_resized)
	theme_changed.connect(_appearance_changed)
	refresh()
	_fit.call_deferred()


func configure(service: Node) -> void:
	_service = service
	if panel != null:
		refresh()


func _build() -> void:
	panel = PanelContainer.new()
	panel.name = "mission_board"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.theme_type_variation = "HUDPanel"
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_column = VBoxContainer.new()
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_theme_constant_override("separation", 4)
	panel.add_child(_column)
	chapter_label = _label(_column, "", "mission_chapter", true)
	chapter_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	chapter_label.clip_text = true
	chapter_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	toggle_button = Button.new()
	toggle_button.name = "game_objectives"
	toggle_button.focus_mode = Control.FOCUS_NONE
	toggle_button.tooltip_text = "Déployer ou replier les missions · T / bouton du haut (Triangle, Y ou X)"
	toggle_button.custom_minimum_size.y = 34
	toggle_button.pressed.connect(toggle_panel)
	_column.add_child(toggle_button)
	progress_bar = ProgressBar.new()
	progress_bar.name = "mission_progress"
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size.y = 5
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(progress_bar)
	_body = ScrollContainer.new()
	_body.name = "mission_list_scroll"
	_body.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_body.follow_focus = false
	_body.focus_mode = Control.FOCUS_NONE
	_body.mouse_filter = Control.MOUSE_FILTER_PASS
	_column.add_child(_body)
	mission_list = VBoxContainer.new()
	mission_list.name = "mission_list"
	mission_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_list.add_theme_constant_override("separation", 9)
	_body.add_child(mission_list)
	mission_list.minimum_size_changed.connect(_schedule_fit)
	next_step_label = _label(mission_list, "", "mission_next_step", true)
	_appearance_changed()


func refresh() -> void:
	if panel == null:
		return
	_compact = get_viewport_rect().size.y <= 600
	mission_list.add_theme_constant_override("separation", 3 if _compact else 9)
	var chapter := 1
	var definitions: Array = []
	if is_instance_valid(_service):
		if _service.has_method("current_chapter"):
			chapter = int(_service.current_chapter())
		if _service.has_method("chapter_missions"):
			definitions = _service.chapter_missions(chapter)
	chapter_label.text = "CHAPITRE %d · %s" % [chapter, "REZ-DE-CHAUSSÉE" if chapter == 1 else "ÉTAGE %d" % (chapter - 1)]
	for child in mission_list.get_children():
		mission_list.remove_child(child)
		child.queue_free()
	var completed := 0
	var next_id := ""
	var first_locked := ""
	for definition in definitions:
		var id := str(definition.get("id", ""))
		var state := str(_service.mission_state(id))
		if state == "completed":
			completed += 1
		elif state in ["available", "in_progress"] and next_id.is_empty():
			next_id = id
		elif first_locked.is_empty():
			first_locked = id
		var row: BoxContainer = HBoxContainer.new() if _compact else VBoxContainer.new()
		row.name = "mission_row_" + id
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 5 if _compact else 0)
		mission_list.add_child(row)
		var names: Dictionary = COMPACT_NAMES if _compact else SHORT_NAMES
		var title := _label(row, "%s  %s" % ["✓" if state == "completed" else "○", str(names.get(id, definition.get("name", id)))], "mission_name_" + id)
		title.tooltip_text = str(definition.get("name", id))
		var status := {"locked": "À débloquer", "available": "Disponible", "in_progress": "En cours", "completed": "Terminée"}.get(state, "À débloquer")
		var status_label := _label(row, ("" if _compact else "     ") + str(status), "mission_status_" + id, true)
		if _compact:
			title.autowrap_mode = TextServer.AUTOWRAP_OFF
			title.clip_text = true
			title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
			status_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	toggle_button.text = "Missions · %d / %d  %s" % [completed, definitions.size(), "▴" if panel_expanded else "▾"]
	progress_bar.max_value = maxi(definitions.size(), 1)
	progress_bar.value = completed
	var hints: Dictionary = COMPACT_NEXT_STEPS if _compact else NEXT_STEPS
	var next_text := str(hints.get(next_id, ""))
	if definitions.size() > 0 and completed == definitions.size():
		if chapter == 1:
			next_text = ("Porte de sortie · en bas à gauche" if _exit_unlocked() else ("Prenez l’ascenseur en bas du bureau." if not _compact else "Ascenseur · en bas du bureau"))
		elif chapter == 2:
			next_text = "Prenez l’ascenseur vers le chapitre 3 : l’atelier du code." if not _compact else "Chapitre 3 · ascenseur"
		elif chapter == 3:
			next_text = "Livres au coin ressources · Chapitre 4 par l’ascenseur"
		elif chapter == 4:
			next_text = "Chapitre 5 · ascenseur"
		else:
			next_text = "Revenez au palier, puis descendez jusqu’au premier niveau. Porte de sortie en bas à gauche." if not _compact else "Descendez au premier niveau · porte de sortie"
	elif next_text.is_empty():
		next_text = "Terminez la mission précédente." if not first_locked.is_empty() else "Commencez l’enquête depuis l’accueil."
	if _exit_unlocked() and chapter in [2,3,4]: next_text = "Descendez au premier niveau · porte de sortie"
	next_step_label = _label(mission_list, next_text, "mission_next_step", true)
	next_step_label.visible = chapter != 5 or completed == definitions.size()
	_body.visible = panel_expanded
	_appearance_changed()
	_fit.call_deferred()


func toggle_panel() -> void:
	if not _input_enabled:
		return
	panel_expanded = not panel_expanded
	refresh()
	expanded_changed.emit(panel_expanded)


func is_expanded() -> bool:
	return panel_expanded


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if toggle_button != null:
		toggle_button.disabled = not enabled


func _label(host: Node, text: String, key: String, secondary: bool = false) -> Label:
	var label := Label.new()
	label.name = key
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if secondary:
		label.theme_type_variation = "SecondaryLabel"
	host.add_child(label)
	return label


func _appearance_changed() -> void:
	if panel == null:
		return
	var large := _large_text()
	chapter_label.add_theme_font_size_override("font_size", 14 if large else 12)
	toggle_button.add_theme_font_size_override("font_size", 18 if large else 16)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var button_box: StyleBoxFlat = get_theme_stylebox(state, "Button").duplicate() as StyleBoxFlat
		if button_box != null:
			button_box.content_margin_top = 5
			button_box.content_margin_bottom = 5
			toggle_button.add_theme_stylebox_override(state, button_box)
	for row in mission_list.get_children():
		if row is BoxContainer:
			for child in row.get_children():
				if child is Label:
					child.add_theme_font_size_override("font_size", (18 if large else 16) if str(child.name).begins_with("mission_name_") else (16 if large else 14))
		elif row is Label:
			row.add_theme_font_size_override("font_size", 16 if large else 14)
	# Preserve the active theme's palette and transparency accessibility setting.
	var box: StyleBoxFlat = get_theme_stylebox("panel", "HUDPanel").duplicate() as StyleBoxFlat
	if box != null:
		box.bg_color.a = 1.0 if _reduced_transparency() else 0.94
		box.content_margin_left = 11
		box.content_margin_right = 11
		box.content_margin_top = 8
		box.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", box)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(get_theme_color("font_color", "Label"), 0.14)
	background.set_corner_radius_all(3)
	progress_bar.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = get_theme_color("accent", "Appearance") if has_theme_color("accent", "Appearance") else get_theme_color("font_color", "Label")
	fill.set_corner_radius_all(3)
	progress_bar.add_theme_stylebox_override("fill", fill)
	_fit.call_deferred()


func _resized() -> void:
	if panel != null and _compact != (get_viewport_rect().size.y <= 600):
		refresh()
	else:
		_fit()


func _schedule_fit() -> void:
	# Word wrapping first computes its minimum at the preceding width. Fit
	# again after native containers give the replacement mission rows a width.
	if _fit_scheduled:
		return
	_fit_scheduled = true
	_apply_scheduled_fit.call_deferred()


func _apply_scheduled_fit() -> void:
	_fit_scheduled = false
	_fit()


func _large_text() -> bool:
	return get_theme_font_size("font_size", "Label") >= 22


func _reduced_transparency() -> bool:
	var settings := get_node_or_null("/root/SettingsService")
	return settings != null and bool(settings.current.get("reduce_transparency", false))


func _fit() -> void:
	if not is_inside_tree() or panel == null or size.x <= 0 or size.y <= 0:
		return
	var compact := get_viewport_rect().size.y <= 600
	var preferred_width := (280.0 if _large_text() else 240.0) if compact else (310.0 if _large_text() else 284.0)
	var width := minf(preferred_width, maxf(size.x - 24, 150))
	panel.custom_minimum_size.x = width
	panel.offset_left = -width - 12
	panel.offset_right = -12
	panel.offset_top = 12
	var maximum_height := 200.0 if compact else (340.0 if _large_text() else 300.0)
	var available_height := minf(maximum_height, maxf(0, size.y - 24))
	var fixed_height := panel.get_theme_stylebox("panel").get_minimum_size().y + chapter_label.get_combined_minimum_size().y + toggle_button.get_combined_minimum_size().y + progress_bar.get_combined_minimum_size().y + _column.get_theme_constant("separation") * 3
	_body.custom_minimum_size.y = minf(mission_list.get_combined_minimum_size().y, maxf(0, available_height - fixed_height)) if panel_expanded else 0
	panel.size = Vector2(width, 0)

func _exit_unlocked() -> bool:
	var app := get_node_or_null("/root/AppState")
	return app != null and not app.profile.is_empty() and "maze" in app.profile.progress.completed_missions
