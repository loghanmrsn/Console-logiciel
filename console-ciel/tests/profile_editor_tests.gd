extends SceneTree
## Local photos and the mobile keyboard, through the actual profile UI.
## All images, saves and settings remain in user://tests/; no personal file is read.
## godot --headless --path . --script res://tests/profile_editor_tests.gd
## Optional real captures: godot --path . --script res://tests/profile_editor_tests.gd -- --screenshots

const LocalLibrary = preload("res://scripts/services/local_avatar_library.gd")
const Avatar = preload("res://scripts/ui/avatar_icon.gd")
const PHOTO := "mon_portrait.png"
const SECOND_PHOTO := "nouveau_portrait.png"

var checks := 0
var failures: Array[String] = []
var test_root := ""
var image_root := ""
var app
var saves
var profiles
var state
var settings
var router
var controllers
var captures := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	if DisplayServer.get_name() != "headless":
		Input.use_accumulated_input = false
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	state = root.get_node("AppState")
	settings = root.get_node("SettingsService")
	router = root.get_node("SceneRouter")
	controllers = root.get_node("ControllerService")
	controllers.debug_set_devices([0])
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	test_root = "user://tests/profile_editor_%s" % Time.get_ticks_usec()
	image_root = test_root.path_join("images_profil")
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	LocalLibrary.directories_override = [image_root]
	LocalLibrary.refresh()
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(image_root)) == OK, "Dossier des images de test créé")
	_test_library()
	_test_profile_contracts()
	root.size = Vector2i(1280, 720)
	await _launch()
	await _test_create_with_keyboard()
	if state.profile.is_empty() or app.screen != "home":
		await _finish()
		return
	await _test_editor_choices()
	await _test_restart_and_missing_photo()
	await _test_small_editor()
	await _finish()


func _test_library() -> void:
	_check(LocalLibrary.folder_path() == image_root and LocalLibrary.list_images().is_empty(), "Bibliothèque vide et isolée avant dépôt d’images")
	_make_png(PHOTO, Color("#3D7E9E"), Vector2i(320, 80))
	var image := Image.create(44, 56, false, Image.FORMAT_RGB8)
	image.fill(Color("#A26386"))
	_check(image.save_jpg(image_root.path_join("portrait.jpg")) == OK, "Photo JPEG réelle déposée")
	_check(image.save_webp(image_root.path_join("portrait.webp")) == OK, "Photo WebP réelle déposée")
	_write_text(image_root.path_join("corrompue.png"), "Ce fichier n’est pas une image.")
	_write_text(image_root.path_join("instructions.txt"), "Fichier ordinaire à ignorer.")
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(image_root.path_join("sous_dossier"))) == OK, "Sous-dossier de test créé")
	_check(image.save_png(image_root.path_join("sous_dossier/ignore.png")) == OK, "Image imbriquée réelle déposée")
	LocalLibrary.refresh()
	var entries: Array[Dictionary] = LocalLibrary.list_images()
	var names: Array[String] = []
	for entry in entries:
		names.append(entry.filename)
		_check(entry.texture is Texture2D and entry.texture.get_width() > 0, "Miniature réellement décodée : " + entry.filename)
	_check(entries.size() == 3 and PHOTO in names and "portrait.jpg" in names and "portrait.webp" in names, "PNG, JPEG et WebP détectés sans import Godot")
	_check("corrompue.png" not in names and "ignore.png" not in names and "instructions.txt" not in names, "Image corrompue, fichier ordinaire et sous-dossier ignorés")
	var texture := LocalLibrary.texture_for(PHOTO)
	_check(texture != null and texture.get_width() == 256 and texture.get_height() == 64, "Une grande photo devient une miniature avec les proportions conservées")
	_check(not FileAccess.file_exists(image_root.path_join(PHOTO + ".import")), "Les photos personnelles n’exigent aucun fichier .import")
	for filename in [PHOTO, "École été.PNG", "photo-2.jpeg", "profil.webp"]:
		_check(LocalLibrary.is_safe_filename(filename), "Nom d’image locale accepté : " + filename)
	for filename in ["", "../photo.png", "/tmp/photo.png", "C:\\photo.png", "sous/photo.png", "sous\\photo.png", ".photo.png", "photo.png ", "photo.svg", "CON.png", "aux.jpg", "lpt1.webp", "a\n.png"]:
		_check(not LocalLibrary.is_safe_filename(filename), "Référence extérieure ou nom invalide refusé : " + JSON.stringify(filename))
	_check(not LocalLibrary.is_safe_filename(42), "Un nom d’image non textuel est refusé")
	_check(LocalLibrary.texture_for("../photo.png") == null and LocalLibrary.texture_for("inconnue.png") == null, "Une référence absente ou extérieure ne charge aucune texture")


func _test_profile_contracts() -> void:
	_check(profiles.refresh().ok and profiles.profiles.is_empty(), "Profils de test isolés des données personnelles")
	var plain: Dictionary = profiles.create_profile("ancien profil")
	_check(plain.ok and not plain.data.has("avatar_image"), "Un profil classique conserve le schéma 1 sans nouveau champ obligatoire")
	if not plain.ok:
		return
	_check(saves.validate_profile(plain.data).ok, "Les anciens profils sans photo restent valides")
	var invalid: Dictionary = plain.data.duplicate(true)
	invalid.avatar_image = "../photo.png"
	_check(not saves.validate_profile(invalid).ok, "La sauvegarde refuse une photo hors du dossier local")
	invalid.avatar_image = 12
	_check(not saves.validate_profile(invalid).ok, "La sauvegarde refuse un champ photo non textuel")
	invalid.avatar_image = "image_retiree.png"
	_check(saves.validate_profile(invalid).ok, "Une photo retirée ne rend jamais le profil illisible")
	for filename in ["../photo.png", "inconnue.png", "corrompue.png"]:
		_check(not profiles.create_profile("refusé", "avatar_default", filename).ok, "Créer un profil nécessite une vraie photo locale : " + filename)
	var photographed: Dictionary = profiles.create_profile("profil photo", "avatar_default", PHOTO)
	_check(photographed.ok and photographed.data.avatar_image == PHOTO, "Le service crée un profil avec une photo locale")
	if not photographed.ok:
		return
	var snapshot: Dictionary = state.profile.duplicate(true)
	_check(snapshot.owned_items == plain.data.owned_items and snapshot.wallet.points == 0, "La photo personnelle ne change ni inventaire, ni points")
	_check(saves.read_profile(snapshot.id).data.avatar_image == PHOTO, "Seul le nom du fichier local est enregistré dans le profil")
	_check(not profiles.update_profile("échec", "avatar_default", "../photo.png").ok, "Une modification ne peut pas injecter un chemin extérieur")
	_check(not profiles.update_profile("échec", "avatar_default", "inconnue.png").ok, "Une nouvelle image inexistante est refusée")
	saves.simulate_write_failure = true
	_check(not profiles.update_profile("échec", "avatar_default", "portrait.jpg").ok, "Échec d’écriture d’une nouvelle photo signalé")
	saves.simulate_write_failure = false
	_check(state.profile == snapshot and saves.read_profile(snapshot.id).data == snapshot, "Une erreur de sauvegarde conserve pseudo et photo en mémoire et sur disque")


func _test_create_with_keyboard() -> void:
	app._open_editor("")
	await _frames(6)
	_check(app.screen == "editor" and root.gui_get_focus_owner() == _find("key_A"), "Créer un profil focalise la première touche du clavier mobile")
	var editor := _find("profile_name") as LineEdit
	_check(editor != null and _find("profile_avatar_preview") != null, "Pseudo et grand aperçu du profil présents")
	if editor == null:
		return
	_check(_find("key_A").text == "a" and not _find("key_1").is_visible_in_tree(), "Page des lettres minuscules par défaut")
	_check(_find("open_profile_images") != null and _find("refresh_profile_images") != null, "Ouvrir le dossier local et Actualiser sont disponibles")
	_check(_find("avatar_avatar_default") != null and _find(_image_key(PHOTO)) == null, "Un nouveau profil propose d’abord les avatars illustrés")
	await _activate("profile_tab_images", true)
	_check(_find(_image_key(PHOTO)) != null, "Mes images ouvre la galerie des portraits locaux")
	await _activate(_image_key(PHOTO), true)
	var preview = _find("profile_avatar_preview")
	_check(preview.local_image == PHOTO and preview.image_texture != null, "Choisir une image locale actualise immédiatement le grand aperçu")
	_check(app.scroll.get_global_rect().encloses(_find("key_Valider").get_global_rect()) and app.scroll.get_global_rect().encloses(_find("key_123").get_global_rect()), "Toutes les rangées du clavier sont visibles à 1280×720 sans défilement")
	await _capture("profile_photo_selection_1280x720")
	await _activate("key_A", true)
	_check(editor.text == "a", "La saisie manette remplace le pseudo proposé")
	await _activate("key_Shift", true)
	_check(_find("key_B").text == "B", "La flèche Majuscule change les lettres affichées")
	await _activate("key_B")
	_check(editor.text == "aB" and _find("key_B").text == "b", "Une seule lettre est mise en majuscule, puis les minuscules reviennent")
	await _activate("key_123", true)
	_check(_find("key_123").text == "ABC" and not _find("key_A").is_visible_in_tree(), "123 affiche les chiffres et symboles avec une touche ABC")
	await _move_focus(KEY_UP)
	_check(_find("profile_keyboard").is_ancestor_of(root.gui_get_focus_owner()) and root.gui_get_focus_owner().is_visible_in_tree(), "Une flèche atteint une touche visible après le changement de page")
	_check(editor.text == "aB", "Changer de page et déplacer le focus ne saisit aucun caractère")
	await _capture("profile_keyboard_123_1280x720")
	await _activate("key_1", true)
	var at_key := _button_with_text(app, "@")
	_check(at_key != null, "Le clavier des chiffres contient le symbole @")
	if at_key != null:
		await _activate(String(at_key.name))
	await _activate("key_Symbols", true)
	_check(not _find("key_1").is_visible_in_tree() and _find("key_Numbers").is_visible_in_tree(), "#+= affiche une seconde page de caractères spéciaux")
	await _move_focus(KEY_RIGHT, true)
	_check(_find("profile_keyboard").is_ancestor_of(root.gui_get_focus_owner()) and root.gui_get_focus_owner().is_visible_in_tree(), "La croix manette navigue dans la page des symboles")
	var hash_key := _button_with_text(app, "#")
	_check(hash_key != null, "La page des symboles contient le caractère #")
	if hash_key != null:
		await _activate(String(hash_key.name), true)
	_check(editor.text == "aB1@#", "Un symbole de la seconde page est réellement inséré")
	await _activate("key_Effacer")
	await _activate("key_Numbers")
	_check(_find("key_1").is_visible_in_tree(), "La touche 123 de la page des symboles revient aux chiffres")
	await _activate("key_123")
	await _activate("key_Espace")
	await _activate("key_B")
	_check(editor.text == "aB1@ b", "Le clavier saisit casse mixte, chiffres, symbole et espace")
	await _activate("key_Effacer", true)
	_check(editor.text == "aB1@ ", "Effacer retire exactement le dernier caractère")
	await _activate("key_B")
	await _activate("key_Valider", true)
	_check(app.screen == "home" and state.profile.display_name == "aB1@ b" and state.profile.get("avatar_image", "") == PHOTO, "Valider crée le pseudo mixte et sa photo locale")
	if state.profile.is_empty() or app.screen != "home":
		return
	_check(app.navigation.profile_avatar.local_image == PHOTO and app.navigation.profile_avatar.image_texture != null, "La barre de navigation affiche la photo du profil actif")
	await _capture("home_local_profile_1280x720")
	app._show_screen("profiles")
	await _frames(6)
	var selector := _find("select_" + state.profile.id)
	_check(selector != null, "Le nouveau profil apparaît dans la liste")
	if selector != null:
		var icon := _avatar_in(selector.get_parent().get_parent())
		_check(icon != null and icon.local_image == PHOTO and icon.image_texture != null, "La carte du profil affiche également la photo locale")
		var card = selector.get_parent().get_parent().get_parent()
		for label in card.find_children("*", "Label", true, false):
			if "Récent" in label.text:
				_check(label.size.y < 40 and label.size.x > 50, "Le badge Récent reste sur une ligne dans une carte de profil")
	await _capture("profiles_local_photo_1280x720")
	app._show_screen("home")
	await _frames(4)


func _test_editor_choices() -> void:
	var profile_id: String = state.profile.id
	var before: Dictionary = state.profile.duplicate(true)
	app._open_editor(profile_id)
	await _frames(6)
	_check(not app.header_avatar.visible and not app.header_profile.visible and not app.header_points.visible, "L’éditeur réserve les informations du joueur au grand aperçu")
	_check(app.header_avatar.local_image == PHOTO and app.header_avatar.image_texture != null, "La photo du joueur actif reste configurée pour les autres écrans")
	_check(_find("profile_avatar_preview").local_image == PHOTO, "Modifier le profil retrouve sa photo sélectionnée")
	_check(_find(_image_key(PHOTO)) != null and _find("avatar_avatar_default") == null, "Un profil avec une photo ouvre directement Mes images")
	var editor := _find("profile_name") as LineEdit
	editor.text = "brouillon"
	editor.caret_column = editor.text.length()
	_make_png(SECOND_PHOTO, Color("#E8A267"), Vector2i(64, 96))
	_check(_find(_image_key(SECOND_PHOTO)) == null, "Une image déposée après ouverture attend l’actualisation")
	await _activate("refresh_profile_images")
	_check(_find(_image_key(SECOND_PHOTO)) != null and _find("profile_name").text == "brouillon", "Actualiser trouve la nouvelle image et conserve le pseudo saisi")
	await _activate(_image_key(SECOND_PHOTO))
	_check(_find("profile_avatar_preview").local_image == SECOND_PHOTO and _find("profile_avatar_preview").image_texture != null, "La nouvelle photo a un aperçu immédiat")
	await _activate("key_Annuler")
	_check(state.profile == before and saves.read_profile(profile_id).data == before, "Annuler une photo et un pseudo garde les données enregistrées")
	app._open_editor(profile_id)
	await _frames(6)
	await _activate("clear_profile_image")
	_check(_find("profile_avatar_preview").local_image.is_empty() and _find("profile_avatar_preview").image_texture == null, "Retirer la photo réaffiche l’avatar illustré")
	await _activate("profile_tab_avatars")
	await _activate("avatar_avatar_default")
	await _activate("key_Valider")
	_check(not state.profile.has("avatar_image") and not saves.read_profile(profile_id).data.has("avatar_image"), "Retirer la photo puis Valider efface la référence locale")
	app._open_editor(profile_id)
	await _frames(6)
	await _activate("profile_tab_images")
	await _activate(_image_key(PHOTO))
	await _activate("key_Valider")
	_check(state.profile.get("avatar_image", "") == PHOTO and saves.read_profile(profile_id).data.get("avatar_image", "") == PHOTO, "Une modification sauvegarde à nouveau la photo choisie")
	_check(profiles.start_game().ok, "Une enquête de test démarre avec la photo personnelle")
	app._show_screen("game")
	await _frames(6)
	_check(app.header_avatar.visible and app.header_avatar.local_image == PHOTO and app.header_avatar.image_texture != null, "L’en-tête affiche la photo personnelle pendant l’enquête")
	app.demo.request_pause()
	await _frames(6)
	_check(app.header_avatar.visible and app.header_avatar.image_texture != null, "La photo reste présente pendant la pause")
	app._show_screen("home")
	await _frames(6)


func _test_restart_and_missing_photo() -> void:
	var profile_id: String = state.profile.id
	var snapshot: Dictionary = state.profile.duplicate(true)
	root.remove_child(app)
	app.queue_free()
	app = null
	await _frames(4)
	state.clear_profile()
	profiles.profiles.clear()
	await _launch()
	_check(app.screen == "profiles" and app.last_profile_id == profile_id and state.profile.is_empty(), "Relancer la scène propose le dernier profil sans conserver l’état mémoire")
	await _activate("select_" + profile_id, true)
	_check(app.screen == "home" and state.profile.id == profile_id and state.profile == snapshot, "La sélection recharge le profil complet depuis le disque")
	_check(app.navigation.profile_avatar.local_image == PHOTO and app.navigation.profile_avatar.image_texture != null, "La photo locale réapparaît après rechargement de la sauvegarde")
	_check(DirAccess.remove_absolute(ProjectSettings.globalize_path(image_root.path_join(PHOTO))) == OK, "La fixture photo est retirée du disque")
	LocalLibrary.refresh()
	_check(LocalLibrary.texture_for(PHOTO) == null, "Une photo disparue n’est plus fournie par le cache")
	app._show_screen("home")
	await _frames(6)
	_check(app.navigation.profile_avatar.image_texture == null and app.navigation.profile_avatar.color == Color("#527FA3"), "Une photo retirée laisse un avatar illustré visible dans la barre")
	_check(saves.read_profile(profile_id).ok and saves.read_profile(profile_id).data.avatar_image == PHOTO, "Le retrait du fichier ne corrompt ni ne supprime la sauvegarde")
	app._open_editor(profile_id)
	await _frames(6)
	_check(_find("profile_avatar_preview").image_texture == null and _find(_image_key(PHOTO)) == null, "L’éditeur affiche le repli et retire la photo inexistante du choix")
	var editor := _find("profile_name") as LineEdit
	editor.text = "photo absente"
	await _activate("key_Valider")
	_check(app.screen == "home" and state.profile.display_name == "photo absente" and state.profile.get("avatar_image", "") == PHOTO, "Renommer reste possible quand la photo sélectionnée manque")
	_make_png(PHOTO, Color("#3D7E9E"), Vector2i(320, 80))
	LocalLibrary.refresh()
	app._show_screen("home")
	await _frames(6)
	_check(app.navigation.profile_avatar.image_texture != null, "Remettre la photo à son nom rétablit le portrait du profil")


func _test_small_editor() -> void:
	var profile_id: String = state.profile.id
	for large in [false, true]:
		root.size = Vector2i(800, 480)
		var values: Dictionary = settings.committed.duplicate(true)
		values.large_text = large
		values.reduce_transparency = large
		values.reduce_motion = true
		_check(settings.apply_settings(values).ok, "Mode de lecture appliqué pour l’éditeur 800×480, grand=" + str(large))
		app._open_editor(profile_id)
		await _frames(8)
		_check(_find("delete_profile") != null, "La suppression reste distincte des commandes du clavier")
		await _focused_controls_fit("lettres", large)
		await _activate("key_123")
		await _focused_controls_fit("chiffres", large)
		await _activate("key_Symbols", true)
		await _focused_controls_fit("symboles", large)
		await _activate("key_123", true)
		await _activate("key_A", true)
		_check(_find("profile_name").text == "a", "Le clavier manette reste exploitable en 800×480, grand=" + str(large))
		_find("key_Valider").grab_focus()
		await _frames(6)
		_check(app.scroll.scroll_vertical > 0, "Le focus sur Valider fait défiler le clavier dans le petit écran")
		await _capture("profile_editor_800x480_" + ("large" if large else "normal"))
		await _activate("key_Annuler")
	root.size = Vector2i(1280, 720)


func _focused_controls_fit(page: String, large: bool) -> void:
	var controls: Array = app._focusables(app.content)
	_check(not controls.is_empty(), "L’éditeur possède des contrôles accessibles : " + page)
	for control in controls:
		control.grab_focus()
		await _frames(6)
		var rect: Rect2 = control.get_global_rect()
		var visible: Rect2 = app.scroll.get_global_rect()
		var fits := rect.position.x >= visible.position.x - 1 and rect.position.y >= visible.position.y - 1 and rect.end.x <= visible.end.x + 1 and rect.end.y <= visible.end.y + 1
		_check(fits, "Contrôle focalisé entièrement visible : %s / %s / grand=%s" % [page, control.name, large])
		if control is Button and control.text.length() > 0:
			var font: Font = control.get_theme_font("font")
			var style: StyleBox = control.get_theme_stylebox("normal")
			var text_width := font.get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, control.get_theme_font_size("font_size")).x
			var available := rect.size.x - style.get_content_margin(SIDE_LEFT) - style.get_content_margin(SIDE_RIGHT)
			_check(text_width <= available + 2, "Texte du bouton lisible : %s / %s / grand=%s" % [page, control.name, large])


func _launch() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	app = packed.instantiate()
	root.add_child(app)
	for frame in range(40):
		await process_frame
		if app.screen != "boot":
			break
	await _frames(6)


func _make_png(filename: String, color: Color, dimensions: Vector2i) -> void:
	var image := Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	image.fill_rect(Rect2i(0, 0, dimensions.x / 3, dimensions.y), color.lightened(.3))
	_check(image.save_png(image_root.path_join(filename)) == OK, "Photo PNG réelle déposée : " + filename)


func _write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "Fichier de test ouvert : " + path.get_file())
	if file != null:
		file.store_string(content)
		file.close()


func _image_key(filename: String) -> String:
	return "image_" + filename.sha256_text().substr(0, 12)


func _find(wanted: String) -> Control:
	return app.find_child(wanted, true, false) as Control


func _avatar_in(node: Node) -> Control:
	if node.get_script() == Avatar:
		return node as Control
	for child in node.get_children():
		var found := _avatar_in(child)
		if found != null:
			return found
	return null


func _button_with_text(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var found := _button_with_text(child, text)
		if found != null:
			return found
	return null


func _activate(wanted: String, with_joy := false) -> bool:
	var button := _find(wanted) as BaseButton
	_check(button != null and button.is_visible_in_tree() and not button.disabled, "Action native accessible : " + wanted)
	if button == null or button.disabled:
		return false
	button.grab_focus()
	await _frames(6)
	if not router.gameplay_allowed():
		await create_timer(.23).timeout
	var event: InputEvent
	if with_joy:
		var joy := InputEventJoypadButton.new()
		joy.device = 0
		joy.button_index = JOY_BUTTON_A
		joy.pressed = true
		event = joy
	else:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.pressed = true
		event = key
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.set("pressed", false)
	Input.parse_input_event(event)
	await _frames(6)
	return true


func _move_focus(code: Key, with_joy := false) -> void:
	var event: InputEvent
	if with_joy:
		var joy := InputEventJoypadButton.new()
		joy.device = 0
		joy.button_index = JOY_BUTTON_DPAD_RIGHT if code == KEY_RIGHT else JOY_BUTTON_DPAD_UP
		joy.pressed = true
		event = joy
	else:
		var key := InputEventKey.new()
		key.keycode = code
		key.pressed = true
		event = key
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.set("pressed", false)
	Input.parse_input_event(event)
	await _frames(6)


func _capture(filename: String) -> void:
	if not captures:
		return
	await _frames(3)
	await RenderingServer.frame_post_draw
	var rendered: Image = root.get_texture().get_image()
	_check(rendered != null and not rendered.is_empty(), "Image réellement rendue : " + filename)
	if rendered == null or rendered.is_empty():
		return
	var folder := "res://docs/screenshots/profils_0.4.2"
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK, "Dossier des captures réel créé")
	_check(rendered.save_png(folder.path_join(filename + ".png")) == OK, "Capture réelle enregistrée : " + filename)


func _frames(count: int) -> void:
	for frame in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("PROFILE_EDITOR_FAIL : ", message)


func _remove_tree(path: String) -> void:
	if test_root.is_empty() or not path.begins_with(test_root):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for child in directory.get_files():
		directory.remove(child)
	for child in directory.get_directories():
		_remove_tree(path.path_join(child))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _finish() -> void:
	# Let the final resize and focus coroutines finish while the scene still
	# belongs to the tree, before releasing the native UI.
	await _frames(4)
	if is_instance_valid(app):
		root.remove_child(app)
		app.queue_free()
	await _frames(4)
	controllers.debug_clear_devices()
	LocalLibrary.directories_override = []
	LocalLibrary.refresh()
	_remove_tree(test_root)
	for player in [settings._music_player, settings._effect_player]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	# Frame counts alone can finish faster than a Dummy audio mix interval.
	# Give the audio server time to release its stopped playback resources.
	await create_timer(.15).timeout
	await _frames(4)
	print("PROFILE_EDITOR_TESTS : %d assertions, %d échec(s)." % [checks, failures.size()])
	print("Événements clavier et manette simulés ; manette physique et exécutable Windows natif à tester sur matériel réel.")
	quit(0 if failures.is_empty() else 1)
