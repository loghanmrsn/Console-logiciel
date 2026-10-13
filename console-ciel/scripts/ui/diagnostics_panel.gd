extends VBoxContainer
## Development diagnostics only; Main decides whether this screen is available.
## Runtime values are sampled at 4 Hz. No host temperature/battery is inferred.
const SAMPLE_INTERVAL := 0.25
var _labels: Dictionary = {}
var _elapsed := 0.0

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 14)
	for key in ["version", "resolution", "renderer", "fps", "profile", "controller", "deadzone", "error"]:
		var label := Label.new()
		label.name = "diagnostics_" + key
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(label)
		_labels[key] = label
	_refresh()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < SAMPLE_INTERVAL:
		return
	_elapsed = 0.0
	_refresh()

func _refresh() -> void:
	if _labels.is_empty():
		return
	var application := str(ProjectSettings.get_setting("application/config/version", "version non renseignée"))
	var engine := Engine.get_version_info()
	_update_text("version", "Console CIEL %s · Godot %s" % [application, engine.get("string", "version indisponible")])
	var viewport_size := get_viewport().get_visible_rect().size
	var display := DisplayServer.get_name()
	_update_text("resolution", "Zone de l'application : %d × %d · affichage : %s" % [roundi(viewport_size.x), roundi(viewport_size.y), display])
	if display == "headless":
		_update_text("renderer", "Rendu graphique non disponible (headless). Méthode configurée : %s." % ProjectSettings.get_setting("rendering/renderer/rendering_method", "non renseignée"))
	else:
		# These methods are present in the bundled Godot 4.6.3 class reference.
		_update_text("renderer", "Moteur de rendu actuel : %s · pilote : %s" % [RenderingServer.get_current_rendering_method(), RenderingServer.get_current_rendering_driver_name()])
	var fps := Engine.get_frames_per_second()
	_update_text("fps", "Boucle moteur : %.1f images/s · aucun rendu graphique mesuré en headless." % fps if display == "headless" else "Images par seconde mesurées par Godot : %.1f" % fps)
	var state := get_node_or_null("/root/AppState")
	var profile_id: String = "aucun profil sélectionné"
	if state != null and not state.profile.is_empty():
		profile_id = str(state.profile.get("id", "identifiant absent"))
	_update_text("profile", "Identifiant interne du profil actif : " + profile_id)
	var controllers := get_node_or_null("/root/ControllerService")
	if controllers == null:
		_update_text("controller", "Contrôleur : service indisponible. Le clavier reste accessible.")
	else:
		var devices: Array = controllers.connected_devices()
		var names: Array[String] = []
		for device in devices:
			names.append("#%d %s" % [device, controllers.controller_name(device)])
		_update_text("controller", "Manette active : %s%s\nPériphériques : %s\nLe retrait met l'enquête en pause ; la reconnexion exige Reprendre." % [controllers.controller_name(), " (#%d)" % controllers.active_device if controllers.active_device >= 0 else "", "aucun" if names.is_empty() else "; ".join(names)])
	var deadzone := InputMap.action_get_deadzone("game_left") if InputMap.has_action("game_left") else 0.0
	_update_text("deadzone", "Zone morte effective des déplacements : %.2f · événements bruts dans Test des commandes." % deadzone if InputMap.has_action("game_left") else "Zone morte : action de déplacement non configurée.")
	var saves := get_node_or_null("/root/SaveService")
	if saves == null:
		_update_text("error", "Dernière erreur de sauvegarde : service indisponible.")
	elif saves.last_error.is_empty():
		_update_text("error", "Dernière erreur de sauvegarde : aucune enregistrée pendant cette exécution.")
	else:
		_update_text("error", "Dernière erreur de sauvegarde enregistrée : %s\n%s\nHistorique : ce message reste visible après une nouvelle tentative." % [saves.last_error_at, saves.last_error])

func _update_text(key: String, value: String) -> void:
	var label: Label = _labels[key]
	if label.text != value:
		label.text = value
