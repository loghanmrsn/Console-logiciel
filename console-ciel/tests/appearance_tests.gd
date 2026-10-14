extends SceneTree
## Preferences remain local; tests never edit real profiles or project files.
const Palette = preload("res://scripts/ui/appearance_palette.gd")
const Themes = preload("res://scripts/ui/theme_factory.gd")
var checks := 0
var failures: Array[String] = []
var settings
var saves
var test_root := ""

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	settings = root.get_node("SettingsService")
	saves = root.get_node("SaveService")
	test_root = "user://tests/appearance_%s_%s" % [Time.get_ticks_usec(), OS.get_process_id()]
	saves.root_path = test_root
	settings.storage_root = test_root
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_root))
	_test_previous_settings()
	_test_preview_persistence()
	_test_validation()
	_test_palettes()
	settings.force_write_failure = false
	_remove_tree(test_root)
	print("APPARENCE : %d assertions, %d échec(s)." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _test_previous_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "schema_version", 1)
	for key in settings.defaults:
		if key not in settings.OPTIONAL_KEYS:
			config.set_value("settings", key, settings.defaults[key])
	config.set_value("settings", "music", 21)
	var path: String = test_root.path_join("settings.cfg")
	_check(config.save(path) == OK, "Ancien settings.cfg schema 1 créé dans le dossier de test")
	var text := FileAccess.get_file_as_string(path)
	_check(settings.load_settings().ok, "Réglages 0.4.2 lus sans les nouvelles clés")
	_check(settings.current.music == 21 and settings.current.appearance_style == "profile" and settings.current.background_color == "" and settings.current.button_color == "" and settings.current.home_layout == "split", "Migration en mémoire conserve l’audio et utilise les valeurs compatibles")
	_check(FileAccess.get_file_as_string(path) == text, "Charger un ancien fichier ne réécrit pas le fichier sur disque")
	for required in ["master", "fullscreen", "deadzone"]:
		var malformed := ConfigFile.new()
		malformed.parse(text)
		malformed.erase_section_key("settings", required)
		var temporary: String = test_root.path_join("missing_" + required + ".cfg")
		_check(malformed.save(temporary) == OK and not settings._read(temporary).ok, "Ancienne clé obligatoire manquante refusée : " + required)

func _test_preview_persistence() -> void:
	var original: Dictionary = settings.committed.duplicate(true)
	var path: String = test_root.path_join("settings.cfg")
	var original_text := FileAccess.get_file_as_string(path)
	var candidate := original.duplicate(true)
	candidate.appearance_style = "nuit"
	candidate.background_color = "#193451"
	candidate.button_color = "#ffd700"
	candidate.home_layout = "carousel"
	_check(settings.preview(candidate).ok, "Aperçu du style sombre, fond et boutons personnalisés et carrousel")
	_check(settings.current.appearance_style == "nuit" and settings.current.button_color == "#FFD700" and settings.current.home_layout == "carousel", "Aperçu appliqué avec normalisation RGB")
	_check(settings.committed == original and FileAccess.get_file_as_string(path) == original_text, "Aperçu sans achat, sans écriture et sans modifier les réglages validés")
	settings.cancel_preview()
	_check(settings.current == original and settings.committed == original, "Annuler restaure également couleurs, style et disposition")
	_check(settings.apply_settings(candidate).ok, "Nouveaux réglages sauvegardés atomiquement")
	var saved: Dictionary = settings.committed.duplicate(true)
	var saved_text := FileAccess.get_file_as_string(path)
	_check(settings.preview(original).ok and settings.load_settings().ok, "Relecture indépendante après un autre aperçu")
	_check(settings.current == saved and settings.committed == saved and settings.current.music == 21, "Style, couleurs, disposition et ancien volume persistants")
	settings.force_write_failure = true
	_check(not settings.apply_settings(original).ok, "Échec d’écriture simulé signalé")
	settings.force_write_failure = false
	_check(settings.committed == saved and FileAccess.get_file_as_string(path) == saved_text, "Échec sans perdre les réglages validés ni leur fichier")
	settings.cancel_preview()
	_check(settings.current == saved, "Annuler après une erreur restaure aussi l’apparence validée")
	_check(settings.apply_settings(settings.defaults).ok, "Rétablissement volontaire des valeurs par défaut")
	_check(settings.current == settings.defaults and settings.committed == settings.defaults, "Réinitialisation retire les surcharges et restaure la disposition partagée")

func _test_validation() -> void:
	var original: Dictionary = settings.current.duplicate(true)
	for key in ["background_color", "button_color"]:
		for invalid in [null, 12, false, [], {}, "#fff", "ffffff", "#12345678", "#12GG56", "#12345", " #123456", "#123456\n", "red", "rgba(1,2,3,4)"]:
			var values := original.duplicate(true)
			values[key] = invalid
			_check(not settings.preview(values).ok and settings.current == original, "Couleur mal formée ou mauvais type refusé sans effet : " + key + " " + JSON.stringify(invalid))
		for accepted in ["", "#000000", "#ffffff", "#AB12cd"]:
			var values := original.duplicate(true)
			values[key] = accepted
			_check(settings.preview(values).ok, "Couleur exacte acceptée : " + key + " " + accepted)
		settings.cancel_preview()
	for setting_pair in [["appearance_style", "inconnu"], ["appearance_style", 1], ["appearance_style", null], ["home_layout", "inconnu"], ["home_layout", false], ["home_layout", null]]:
		var values := original.duplicate(true)
		values[setting_pair[0]] = setting_pair[1]
		_check(not settings.preview(values).ok and settings.current == original, "Style/disposition invalide refusé : " + JSON.stringify(setting_pair))

func _test_palettes() -> void:
	var profile_palette := {"background": "#FAF4E1", "accent": "#9A7835", "secondary": "#F0E3C3"}
	var resolved := Palette.resolve({}, profile_palette)
	_check(resolved.background == "#FAF4E1" and resolved.accent == "#9A7835", "L’option par défaut respecte le thème équipé du profil")
	var seen: Array[String] = []
	for entry in Palette.presets():
		_check(entry.id not in seen and not entry.name.is_empty(), "Style nommé sans identifiant en double : " + entry.id)
		seen.append(entry.id)
		var values := {"appearance_style": entry.id}
		_test_contrast(values, profile_palette, "Style " + entry.id)
		if entry.id != "profile":
			_check(Palette.resolve(values, profile_palette).background == entry.background, "Style gratuit indépendant du thème équipé : " + entry.id)
	for background in ["#000000", "#FFFFFF", "#808080", "#FF0000", "#0000FF", "#FFFF00"]:
		for button in ["#000000", "#FFFFFF", "#808080", "#FF0000", "#0000FF", "#FFFF00"]:
			_test_contrast({"appearance_style": "nuit", "background_color": background, "button_color": button}, {}, "Couleurs " + background + " / " + button)
	var opaque := Themes.build({"appearance_style": "nuit", "reduce_transparency": true}, {})
	_check(opaque.get_stylebox("panel", "NavigationPanel").bg_color.a == 1.0 and opaque.get_stylebox("panel", "PanelContainer").bg_color.a == 1.0, "Réduction de transparence conservée pour un style sombre")
	_check(Themes.build({"large_text": true}, {}).default_font_size == 22, "Grand texte conservé avec les nouvelles apparences")

func _test_contrast(values: Dictionary, profile_palette: Dictionary, context: String) -> void:
	var palette := Palette.resolve(values, profile_palette)
	for key in ["background", "accent", "secondary", "foreground", "muted", "panel", "button", "button_text"]:
		_check(palette[key] is String and Color.html_is_valid(palette[key]) and palette[key].length() == 7, context + " couleur RGB valide : " + key)
	for surface in ["background", "panel", "secondary"]:
		_check(Palette.contrast_ratio(Color(palette.foreground), Color(palette[surface])) >= 4.5, context + " texte lisible sur " + surface)
	for surface in ["background", "panel"]:
		_check(Palette.contrast_ratio(Color(palette.muted), Color(palette[surface])) >= 4.5, context + " texte secondaire lisible sur " + surface)
	_check(Palette.contrast_ratio(Color(palette.button_text), Color(palette.button)) >= 4.5, context + " texte de bouton lisible")
	var theme := Themes.build(values, profile_palette)
	_check(theme.get_color("background", "Appearance") == Color(palette.background), context + " couleurs exposées au reste de l’interface")
	for type in ["Button", "OptionButton", "CheckButton", "CheckBox", "PrimaryButton"]:
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var fill: Color = theme.get_stylebox(state, type).bg_color
			var font: Color = theme.get_color("font_color" if state == "normal" else "font_" + state + "_color", type)
			_check(Palette.contrast_ratio(font, fill) >= 4.5, context + " bouton lisible : " + type + " / " + state)
	_check(Palette.contrast_ratio(theme.get_color("font_color", "LineEdit"), theme.get_stylebox("normal", "LineEdit").bg_color) >= 4.5, context + " saisie lisible")
	_check(Palette.contrast_ratio(theme.get_color("font_hover_color", "PopupMenu"), theme.get_stylebox("hover", "PopupMenu").bg_color) >= 4.5, context + " menu déroulant lisible")
	_check(theme.get_stylebox("focus", "HSlider").border_width_left == 3, context + " focus des curseurs conservé")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("ÉCHEC : ", message)

func _remove_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var filename := dir.get_next()
	while not filename.is_empty():
		var child := path.path_join(filename)
		if dir.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child))
		filename = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
