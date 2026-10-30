extends VBoxContainer
## Presentation only: HotelService keeps every observation and repair decision.
const ActionButton = preload("res://scripts/ui/translucent_button.gd")
const SUMMARIES := {
	"power": "Serveur et onduleur alimentés",
	"network": "Liaison avec la réception active",
	"storage": "Disque plein · journaux à archiver",
	"service": "Réservations arrêtées · écriture impossible"
}
signal observation_requested(id: String)
signal diagnosis_selected(id: String)
signal repair_selected(id: String)
signal submit_requested
signal close_requested

var hotel_state: Dictionary = {}
var diagnosis := ""
var repair := ""
var feedback := ""
var selected_observation := ""
var _observations: GridContainer

func configure(saved: Dictionary, selected_diagnosis: String, selected_repair: String, message: String, observation := "") -> void:
	hotel_state = saved.duplicate(true)
	diagnosis = selected_diagnosis
	repair = selected_repair
	feedback = message
	selected_observation = observation

func _ready() -> void:
	name = "hotel_diagnostic_panel"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	_build_overview()
	if bool(hotel_state.get("repaired", false)):
		_label(self, "✓ Les journaux ont été archivés et le service fonctionne à nouveau. La réception confirme votre chambre 206. Prenez les escaliers vers le deuxième étage.")
		_button(self, "Revenir au local", "hotel_repair_close", func(): close_requested.emit())
		return
	_label(self, "01 · Examiner les équipements", 22)
	_label(self, "Consultez les quatre indices. Les informations examinées restent enregistrées dans votre profil.", 16)
	_observations = GridContainer.new()
	_observations.add_theme_constant_override("h_separation", 10)
	_observations.add_theme_constant_override("v_separation", 10)
	add_child(_observations)
	var observed: Array = hotel_state.get("repair_observations", [])
	for id in HotelService.REPAIR_OBSERVATIONS:
		var key := str(id)
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_observations.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 7)
		card.add_child(column)
		var examined := key in observed
		_button(column, ("✓ " if examined else "○ ") + str(HotelService.REPAIR_OBSERVATIONS[key].title), "hotel_observe_" + key, func(): observation_requested.emit(key))
		_label(column, str(SUMMARIES[key]) if examined else "À examiner", 15)
	if not observed.is_empty():
		var detail_id := selected_observation if selected_observation in observed else str(observed.back())
		var detail := _label(self, str(HotelService.REPAIR_OBSERVATIONS[detail_id].text), 17)
		detail.name = "hotel_observation_detail"
	_label(self, "02 · Poser le diagnostic", 22)
	for option in [["storage_full", "Le disque est saturé par les journaux"], ["network_link", "Le câble réseau est débranché"], ["power_supply", "Le serveur manque d’alimentation"]]:
		var value := str(option[0])
		_choice(str(option[1]), "hotel_diagnosis_" + value, diagnosis == value, func(): diagnosis_selected.emit(value))
	_label(self, "03 · Choisir l’intervention", 22)
	for option in [["archive_logs_restart", "Archiver les journaux puis relancer le service"], ["reboot_only", "Redémarrer sans libérer d’espace"], ["disable_firewall", "Désactiver le pare-feu"]]:
		var value := str(option[0])
		_choice(str(option[1]), "hotel_fix_" + value, repair == value, func(): repair_selected.emit(value))
	if not feedback.is_empty():
		var message := _label(self, feedback, 17)
		message.name = "hotel_repair_feedback"
	var submit := _button(self, "Vérifier et réparer", "hotel_repair_submit", func(): submit_requested.emit())
	submit.theme_type_variation = "PrimaryButton"
	submit.disabled = diagnosis.is_empty() or repair.is_empty()
	_button(self, "Revenir au local", "hotel_repair_close", func(): close_requested.emit())
	resized.connect(_layout_cards)
	_layout_cards()

func _build_overview() -> void:
	var banner := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color("345a61")
	box.border_color = Color("b4945d")
	box.set_border_width_all(1)
	box.set_corner_radius_all(17)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: box.set_content_margin(side, 16)
	banner.add_theme_stylebox_override("panel", box)
	add_child(banner)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	banner.add_child(row)
	var artwork := ServerIllustration.new()
	artwork.repaired = bool(hotel_state.get("repaired", false))
	row.add_child(artwork)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override("separation", 6)
	row.add_child(text)
	for entry in [["HÔTEL RITZ · MAINTENANCE", 13], ["Réservations rétablies" if artwork.repaired else "Serveur de réservation", 24], ["Service en ligne" if artwork.repaired else "%d / 4 indices examinés" % hotel_state.get("repair_observations", []).size(), 17]]:
		var label := _label(text, entry[0], entry[1])
		label.add_theme_color_override("font_color", Color("fff8e7"))
	var progress := ProgressBar.new()
	progress.name = "hotel_observation_progress"
	progress.max_value = 4
	progress.value = hotel_state.get("repair_observations", []).size()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 7
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(progress)

func _layout_cards() -> void:
	if is_instance_valid(_observations): _observations.columns = 2 if size.x >= 620 else 1

func _label(host: Node, value: String, font_size := 17) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size + (2 if SettingsService.current.get("large_text", false) else 0))
	host.add_child(label)
	return label

func _button(host: Node, title: String, key: String, action: Callable) -> Button:
	var button := ActionButton.new()
	button.name = key
	button.text = title
	button.tooltip_text = title
	button.pressed.connect(action)
	host.add_child(button)
	return button

func _choice(title: String, key: String, selected: bool, action: Callable) -> void:
	var button := _button(self, ("✓ " if selected else "○ ") + title, key, action)
	if selected: button.theme_type_variation = "PrimaryButton"

class ServerIllustration extends Control:
	var repaired := false
	func _ready() -> void:
		custom_minimum_size = Vector2(126, 116)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var origin := Vector2((size.x - 126) * .5, (size.y - 116) * .5)
		draw_set_transform(origin)
		var cabinet := StyleBoxFlat.new()
		cabinet.bg_color = Color("253f48")
		cabinet.border_color = Color("bca779")
		cabinet.set_border_width_all(2)
		cabinet.set_corner_radius_all(8)
		draw_style_box(cabinet, Rect2(4, 4, 76, 106))
		for index in range(4):
			var y := 17 + index * 20
			draw_rect(Rect2(13, y, 58, 15), Color("647e7c"))
			for x in range(20, 48, 5): draw_line(Vector2(x, y + 4), Vector2(x, y + 11), Color("345a61"), 2)
			draw_circle(Vector2(61, y + 7), 3, Color("9abda2") if repaired or index < 2 else Color("d2ac74"))
		var cable := PackedVector2Array([Vector2(80, 94), Vector2(107, 94), Vector2(107, 62)])
		draw_polyline(cable, Color("bda475"), 4, true)
		draw_style_box(cabinet, Rect2(87, 30, 37, 34))
		draw_rect(Rect2(93, 36, 25, 19), Color("afcbbb") if repaired else Color("dcc294"))
		draw_line(Vector2(99, 43), Vector2(113, 43), Color("345a61"), 3)
		draw_line(Vector2(105, 64), Vector2(105, 71), Color("dac8a0"), 4)
