extends Control
signal close_requested
const World = preload("res://scripts/campus3d/campus_world.gd")
const ActionButton = preload("res://scripts/ui/translucent_button.gd")
const Inputs = preload("res://scripts/input_setup.gd")
var world: Node3D
var viewport: SubViewport
var place: Label
var prompt: Label
var dialog: PanelContainer
var veil: ColorRect
var overlay: Control
var link_checked := false
var display_checked := false

func _ready() -> void:
	name = "campus_3d_panel"
	focus_mode = Control.FOCUS_ALL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true
	var display := TextureRect.new()
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_SCALE
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(display)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.handle_input_locally = false
	viewport.positional_shadow_atlas_size = 0
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	display.texture = viewport.get_texture()
	display.resized.connect(func():
		var factor := minf(1.0, 960.0 / maxf(display.size.x, 1.0))
		viewport.size = Vector2i(maxi(1, int(display.size.x * factor)), maxi(1, int(display.size.y * factor))))
	world = World.new()
	world.location_changed.connect(_location_changed)
	world.prompt_changed.connect(_prompt_changed)
	world.interaction_requested.connect(_interact)
	world.escort_finished.connect(func(): grab_focus())
	# HUD labels exist before the world emits its initial location.
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var header := PanelContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 12; header.offset_right = -12; header.offset_top = 10
	overlay.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	header.add_child(row)
	place = Label.new()
	place.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	place.add_theme_font_size_override("font_size", 18)
	place.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(place)
	var pause := ActionButton.new()
	pause.name = "campus_pause"; pause.text = "Pause"
	pause.custom_minimum_size = Vector2(90, 40)
	pause.size_flags_horizontal = Control.SIZE_SHRINK_END
	pause.pressed.connect(handle_back)
	row.add_child(pause)
	var strip := PanelContainer.new()
	strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	strip.offset_left = 12; strip.offset_right = -12; strip.offset_top = -68; strip.offset_bottom = -10
	overlay.add_child(strip)
	prompt = Label.new()
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 16)
	strip.add_child(prompt)
	viewport.add_child(world)
	get_viewport().size_changed.connect(_fit)
	visibility_changed.connect(_visibility_changed)
	_fit()

func _fit() -> void:
	custom_minimum_size.y = maxf(260, get_viewport_rect().size.y - 145)
	if is_instance_valid(dialog): _size_dialog()

func _visibility_changed() -> void:
	if viewport == null: return
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED
	world.process_mode = Node.PROCESS_MODE_INHERIT if is_visible_in_tree() else Node.PROCESS_MODE_DISABLED

func _location_changed(title: String) -> void:
	place.text = title

func _prompt_changed(text: String) -> void:
	prompt.text = (text + " · " + Inputs.label_for("game_interact")) if not text.is_empty() else "Flèches / ZQSD / joystick : marcher · Approchez-vous des portes et des objets."

func _gui_input(event: InputEvent) -> void:
	if is_instance_valid(dialog): return
	# Keep movement keys from navigating to shell buttons while exploring.
	for action in ["ui_up", "ui_down", "ui_left", "ui_right"]:
		if event.is_action(action): accept_event(); return
	if handle_event(event): accept_event()

func handle_event(event: InputEvent) -> bool:
	if not ControllerService.accepts_event(event) or event.is_echo(): return false
	if not SceneRouter.gameplay_allowed(): return false
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		handle_back()
		return true
	if not is_instance_valid(dialog) and event.is_action_pressed("game_interact"):
		world.interact()
		return true
	return false

func handle_back() -> void:
	if world.escorting: return
	if is_instance_valid(dialog):
		_close_dialog()
		return
	_show_dialog("Pause", "L’exploration est en pause.", [
		{"text":"Continuer", "action":_close_dialog},
		{"text":"Retour à l’accueil de la console", "action":func(): close_requested.emit()}])

func _close_dialog() -> void:
	if is_instance_valid(veil):
		remove_child(veil); veil.queue_free()
	veil = null; dialog = null
	world.process_mode = Node.PROCESS_MODE_INHERIT
	world.set_locked(false)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	SceneRouter.lock_until_release()
	grab_focus()

func _show_dialog(title: String, body: String, choices: Array) -> void:
	if is_instance_valid(dialog): _close_dialog()
	world.set_locked(true)
	world.process_mode = Node.PROCESS_MODE_DISABLED
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	veil = ColorRect.new()
	veil.color = Color(0.025, .04, .05, .55)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.add_child(center)
	dialog = PanelContainer.new()
	dialog.name = "campus_dialog"
	center.add_child(dialog)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	dialog.add_child(box)
	var heading := Label.new()
	heading.text = title; heading.add_theme_font_size_override("font_size", 22)
	box.add_child(heading)
	var text := Label.new()
	text.text = body
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text)
	var buttons: Array[Button] = []
	for index in choices.size():
		var button := ActionButton.new()
		button.name = "campus_choice_%d" % index
		button.text = choices[index].text
		button.custom_minimum_size.y = 42
		button.pressed.connect(choices[index].action)
		box.add_child(button)
		buttons.append(button)
	for i in buttons.size():
		buttons[i].focus_neighbor_top = buttons[(i-1+buttons.size())%buttons.size()].get_path()
		buttons[i].focus_neighbor_bottom = buttons[(i+1)%buttons.size()].get_path()
		buttons[i].focus_neighbor_left = buttons[i].get_path()
		buttons[i].focus_neighbor_right = buttons[i].get_path()
		buttons[i].focus_next = buttons[(i+1)%buttons.size()].get_path()
		buttons[i].focus_previous = buttons[(i-1+buttons.size())%buttons.size()].get_path()
	_size_dialog()
	buttons[0].grab_focus()

func _size_dialog() -> void:
	dialog.custom_minimum_size.x = minf(540, maxf(220, size.x-32))

func _travel(zone: String) -> void:
	_close_dialog()
	world.load_zone(zone)
	SceneRouter.lock_until_release()

func _escort() -> void:
	_close_dialog()
	world.begin_escort()

func _interact(id: String) -> void:
	match id:
		"school":
			_show_dialog("Lycée Louise Michel", "Entrez à l’accueil. La surveillante peut vous accompagner à l’atelier CIEL.", [{"text":"Entrer", "action":func(): _travel("reception")}, {"text":"Rester sur le parvis", "action":_close_dialog}])
		"exit":
			_show_dialog("Sortir", "Où souhaitez-vous aller ?", [{"text":"Retour au parvis" if world.zone=="reception" else "Retour à l’accueil du lycée", "action":func(): _travel("square" if world.zone=="reception" else "reception")}, {"text":"Rester ici", "action":_close_dialog}])
		"supervisor", "stairs":
			_show_dialog("Surveillante", "Bonjour ! Je peux vous accompagner dans le couloir des ateliers.", [{"text":"M’accompagner aux ateliers", "action":_escort}, {"text":"Non merci", "action":_close_dialog}])
		"rack":
			_show_dialog("Baie réseau", "Pour relier un ordinateur au commutateur, quel câble utilisez-vous ?", [{"text":"Un câble Ethernet RJ45", "action":func(): link_checked=true; _message("Liaison réseau", "Exact. Le câble RJ45 relie le poste au commutateur. Les voyants permettent ensuite de vérifier la liaison.")}, {"text":"Un câble HDMI", "action":func(): _message("À vérifier", "HDMI transporte l’image et le son. Pour le réseau local, cherchez un câble Ethernet RJ45.")}, {"text":"Fermer", "action":_close_dialog}])
		"computer":
			_show_dialog("Poste informatique", "L’écran reste noir. Que vérifiez-vous en premier ?", [{"text":"L’alimentation et le câble vidéo", "action":func(): display_checked=true; _message("Diagnostic", "Bonne méthode : vérifiez l’alimentation, le branchement vidéo puis la source sélectionnée sur l’écran avant de remplacer du matériel.")}, {"text":"Remplacer immédiatement le PC", "action":func(): _message("Diagnostic", "Commencez par les branchements : un câble déconnecté peut suffire à expliquer un écran noir.")}, {"text":"Fermer", "action":_close_dialog}])
		"fountain":
			_show_dialog("Fontaine du parvis", "Une pompe fait circuler l’eau du bassin jusqu’à la vasque supérieure.", [{"text":"Arrêter la pompe" if world.water_running else "Remettre la pompe en marche", "action":func(): world.toggle_water(); _close_dialog()}, {"text":"Fermer", "action":_close_dialog}])
		"books": _message("Boîte à livres", "Réseaux : une adresse IP identifie une interface sur le réseau. Un commutateur relie les équipements du réseau local. Rendez-vous à l’atelier pour vérifier une liaison.")
		"post": _message("La Poste", "Une adresse postale indique une destination. Sur un réseau informatique, les adresses IP permettent aussi d’acheminer des données vers leur destination.")
		"flowers": _message("Le fleuriste", "Les jardinières associent feuillages et fleurs. L’arrosage se règle selon la saison ; un capteur d’humidité peut aider à éviter le gaspillage d’eau.")

func _message(title: String, text: String) -> void:
	_show_dialog(title, text, [{"text":"Reprendre l’exploration", "action":_close_dialog}])
