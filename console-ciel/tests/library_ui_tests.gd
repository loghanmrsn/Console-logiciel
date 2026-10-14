extends SceneTree
## Exercises the real library, purchases, appearance previews and credits.
## Real affordability uses educational rewards; a separate saved UI fixture
## supplies the remaining cards for the four-owned-game layout checks.
## Optional real viewport captures: -- --screenshots

const Library := preload("res://scripts/services/game_library.gd")
const Palette := preload("res://scripts/ui/appearance_palette.gd")
const GAMES := ["game_test_1", "game_test_2", "game_test_3", "game_test_4"]
const PRICES := [200, 200, 200, 200]

var checks := 0
var failures: Array[String] = []
var app
var saves
var profiles
var settings
var state
var shop
var investigation
var router
var controllers
var captures := false
var first_id := ""
var test_root := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	if DisplayServer.get_name() != "headless":
		Input.use_accumulated_input = false
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	settings = root.get_node("SettingsService")
	state = root.get_node("AppState")
	shop = root.get_node("ShopService")
	investigation = root.get_node("InvestigationService")
	router = root.get_node("SceneRouter")
	controllers = root.get_node("ControllerService")
	controllers.debug_set_devices([0])
	test_root = "user://tests/library_ui_%s" % Time.get_ticks_usec()
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	root.size = Vector2i(1280, 720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(35)
	var created: Dictionary = profiles.create_profile("Bibliothèque")
	_check(created.ok, "Profil neuf créé dans le dossier de test")
	if not created.ok:
		await _finish()
		return
	first_id = created.data.id
	app._show_screen("home")
	await _frames(8)
	await _test_no_points()
	await _test_purchases()
	await _test_profiles_and_restart()
	await _test_layouts()
	await _test_appearance_and_credits()
	await _finish()


func _test_no_points() -> void:
	_check(state.profile.wallet.points == 0, "Un profil neuf ne reçoit aucun point de test")
	var definitions: Array[Dictionary] = Library.definitions(shop.catalog)
	_check(definitions.size() == 5 and definitions[0].id == Library.EDUCATIONAL_ID, "Une enquête gratuite et quatre emplacements de futurs jeux")
	for index in range(GAMES.size()):
		var item: Dictionary = shop.item(GAMES[index])
		_check(item.get("name") == "Test %d" % (index + 1) and item.get("price") == PRICES[index] and item.get("placeholder") == true, "Catalogue explicite et prix du futur Test %d" % (index + 1))
		_check(not Library.can_play(state.profile, GAMES[index], shop.catalog), "Un futur jeu non acheté reste verrouillé : " + GAMES[index])
		var saved: Dictionary = state.profile.duplicate(true)
		_check(not shop.purchase(GAMES[index]).ok and state.profile == saved and saves.read_profile(first_id).data == saved, "Aucun achat sans points, ni débit, ni écriture : " + GAMES[index])
		var button := _find("buy_" + GAMES[index]) as Button
		_check(button != null and button.is_visible_in_tree(), "La case verrouillée explique son achat : " + GAMES[index])
		_check(_find("play_" + GAMES[index]) == null or (_find("play_" + GAMES[index]) as BaseButton).disabled, "La bibliothèque ne propose pas un lancement utilisable sans achat : " + GAMES[index])
	var before: Dictionary = state.profile.duplicate(true)
	app._launch_library_game(GAMES[0])
	await _frames(5)
	_check(app.screen != "arcade", "Le lancement direct d’un jeu non possédé est refusé")
	_check(state.profile == before and saves.read_profile(first_id).data == before, "Le refus de lancement conserve le profil")
	if is_instance_valid(app.modal):
		await _key(KEY_ESCAPE)
	app._show_screen("shop")
	await _frames(8)
	var filter := _find("shop_filter") as OptionButton
	_check(filter != null and filter.item_count == 5 and filter.get_item_text(4) == "Jeux", "La catégorie Jeux complète les catégories cosmétiques existantes")
	if filter != null:
		await _choose("shop_filter", 4)
		for id in GAMES:
			_check(_find("product_" + id) != null, "Jeu affiché dans la catégorie dédiée : " + id)
		_check(_find("product_avatar_orbit") == null, "Le filtre Jeux masque les cosmétiques")
		_check_shop_badges()
		await _capture("shop_games_without_points")
		if await _activate("product_" + GAMES[0]):
			if is_instance_valid(app.modal):
				await _activate("modal_confirm")
			await _frames(5)
			_check(state.profile == before and saves.read_profile(first_id).data == before, "L’achat depuis la vraie boutique refuse également le solde nul")
	if is_instance_valid(app.modal):
		await _key(KEY_ESCAPE)
	app._show_screen("home")
	await _frames(5)


func _check_shop_badges() -> void:
	for id in GAMES:
		var status := _find("product_status_" + id) as Label
		_check(status != null and status.size.y < 40 and status.size.x > 30, "Le prix ou badge acheté reste sur une ligne : " + id)


func _earn_points() -> void:
	_check(profiles.start_game().ok, "Enquête réelle commencée pour gagner les points")
	_check(investigation.begin_mission("lighting").ok and investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"]).ok, "Mission éclairage validée par son circuit complet")
	_check(investigation.begin_mission("lock").ok, "Mission serrure déverrouillée")
	for observation in ["badge", "power", "command", "link"]:
		_check(investigation.observe("lock", observation).ok, "Observation réelle de serrure : " + observation)
	_check(investigation.submit_lock("control_link", "reconnect_control").ok, "Liaison de commande réellement corrigée")
	_check(investigation.begin_mission("computer").ok, "Diagnostic ordinateur déverrouillé")
	for observation in ["pc", "display", "no_signal"]:
		_check(investigation.observe("computer", observation).ok, "Observation réelle de l’ordinateur : " + observation)
	for verification in ["power", "video"]:
		_check(investigation.check_computer(verification).ok, "Vérification réelle : " + verification)
	_check(investigation.submit_computer(["power", "video"], "video_disconnected", "reconnect_video").ok, "Branchement vidéo réparé")
	_check(state.profile.wallet.points == 150 and state.profile.rewarded_missions.size() == 3, "Les trois récompenses éducatives fournissent exactement 150 points")


func _test_purchases() -> void:
	await _earn_points()
	var chapter_one: Dictionary = state.profile.duplicate(true)
	_check(not shop.purchase(GAMES[0]).ok and state.profile == chapter_one and saves.read_profile(first_id).data == chapter_one, "Les 150 points du premier chapitre ne suffisent pas à acheter un jeu à 200 points")
	_check(investigation.enter_chapter(2).ok and investigation.begin_mission("network").ok, "Le vrai chapitre 2 permet de gagner les 50 points manquants")
	var network: Dictionary = investigation.mission("network")
	for observation in network.observations:
		_check(investigation.observe("network", observation.id).ok, "Observation réseau réelle : " + observation.id)
	_check(investigation.submit_diagnostic("network", network.solution.diagnosis, network.solution.repair).ok, "Le diagnostic réseau atteint exactement 200 points gagnés")
	_check(state.profile.wallet.points == 200 and state.profile.rewarded_missions.size() == 4, "Trois missions au rez-de-chaussée et le réseau financent un seul jeu")
	app.shop_filter = 4
	app._show_screen("shop")
	await _frames(8)
	for index in range(GAMES.size()):
		if index == 1:
			# This saved fixture exists only in this test's isolated storage. It
			# exercises all four purchased cards without creating fake rewards
			# in the product or pretending the six missions can fund 800 points.
			var fixture: Dictionary = state.profile.duplicate(true)
			fixture.wallet.points = 600
			var written: Dictionary = saves.write_profile(fixture)
			_check(written.ok, "Fixture UI isolée : 600 points pour vérifier les trois dernières cartes achetées")
			if written.ok:
				state.commit_profile(written.data)
			await _frames(5)
		var id: String = GAMES[index]
		var before: Dictionary = state.profile.duplicate(true)
		if not await _activate("product_" + id, index % 2 == 1):
			continue
		_check(is_instance_valid(app.modal), "Acheter demande une confirmation explicite : " + id)
		_check(state.profile == before, "Ouvrir la confirmation ne débite aucun point : " + id)
		if not is_instance_valid(app.modal):
			continue
		await _activate("modal_confirm", index % 2 == 0)
		await _frames(5)
		_check(state.profile.wallet.points == before.wallet.points - PRICES[index] and id in state.profile.owned_items, "Achat réel avec débit exact : " + id)
		if index == 0:
			_check(state.profile.wallet.points == 0 and state.profile.rewarded_missions.size() == 4, "Le premier achat dépense uniquement les 200 points réellement gagnés")
		_check(saves.read_profile(first_id).data == state.profile, "Solde et possession sauvegardés ensemble : " + id)
		var after: Dictionary = state.profile.duplicate(true)
		_check(not shop.purchase(id).ok and state.profile == after, "Un second achat n’effectue aucun second débit : " + id)
	_check(state.profile.wallet.points == 0 and Library.owned_games(state.profile, shop.catalog).size() == 4, "Les quatre achats coûtent 800 points, financés par 200 gains réels et 600 points de fixture UI isolée")
	_check_shop_badges()
	await _capture("shop_games_after_purchase")
	app._show_screen("home")
	await _frames(8)
	_check(app.header_points.is_visible_in_tree() and app.header_points.text == "0 pts", "Le profil en haut à gauche affiche le solde réel après les achats")
	_check(not app.navigation.profile_points_label.is_visible_in_tree(), "Le solde ne surcharge plus la barre des quatre onglets")
	for id in GAMES:
		_check(_find("play_" + id) != null and _find("buy_" + id) == null, "Chaque achat remplace le bouton d’achat par un lancement : " + id)
		if await _activate("play_" + id, id == GAMES[1]):
			_check(app.screen == "arcade" and not app.navigation.visible, "La case ouvre l’emplacement local du futur jeu avec la barre masquée : " + id)
			_check(_contains_text(app.content, "préparation") or _contains_text(app.content, "pas encore"), "L’écran précise que le vrai jeu reste à venir : " + id)
			await _key(KEY_ESCAPE)
			_check(app.screen == "home", "Retour clavier de l’emplacement vers la bibliothèque : " + id)
			_check(root.gui_get_focus_owner() == _find("play_" + id), "Le retour retrouve la case du jeu sélectionné : " + id)


func _test_profiles_and_restart() -> void:
	var bought: Dictionary = state.profile.duplicate(true)
	var other: Dictionary = profiles.create_profile("Autre console")
	_check(other.ok and state.profile.wallet.points == 0 and Library.owned_games(state.profile, shop.catalog).is_empty(), "Un autre profil ne partage ni les points ni les jeux achetés")
	app._show_screen("home")
	await _frames(6)
	for id in GAMES:
		_check(_find("buy_" + id) != null and not Library.can_play(state.profile, id, shop.catalog), "Le second profil garde le jeu verrouillé : " + id)
	_check(profiles.select_profile(first_id).ok and state.profile == bought, "La sélection relit le premier profil avec tous ses achats")
	root.remove_child(app)
	app.queue_free()
	await _frames(4)
	state.clear_profile()
	_check(profiles.select_profile(first_id).ok and state.profile == bought, "Les achats sont repris depuis le disque après destruction de l’interface")
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(35)
	app._show_screen("home")
	await _frames(8)
	for id in GAMES:
		_check(_find("play_" + id) != null, "L’interface recréée propose le jeu conservé : " + id)
	app._show_screen("profiles")
	await _frames(6)
	_check(_find("select_" + first_id) != null and _find("edit_" + first_id) != null, "Les nouvelles cartes de profil conservent sélection et personnalisation")
	var games_stat := _find("profile_games_" + first_id) as Label
	_check(games_stat != null and games_stat.text.begins_with("4"), "La carte du profil compte ses quatre jeux réellement possédés")
	_check(state.profile == bought and saves.read_profile(first_id).data == bought, "La consultation des profils ne modifie pas les possessions")
	await _capture("profiles_purchased_library")


func _test_layouts() -> void:
	var original: Dictionary = settings.committed.duplicate(true)
	var before: Dictionary = state.profile.duplicate(true)
	for resolution in [Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(800, 480)]:
		root.size = resolution
		await _frames(5)
		for large in [false, true]:
			var values: Dictionary = original.duplicate(true)
			values.large_text = large
			values.reduce_motion = true
			values.reduce_transparency = large
			values.home_layout = "split"
			_check(settings.apply_settings(values).ok, "Disposition partagée réellement appliquée : %s grand=%s" % [resolution, large])
			app._show_screen("home")
			await _frames(10)
			var education := _find("home_education_cover") as Control
			var library := _find("home_game_library") as Control
			var split := _find("home_split") as Control
			_check(education != null and library != null and split != null, "Une couverture compacte et une bibliothèque distincte dans la disposition partagée")
			if education != null and library != null:
				_check(education.size.y < resolution.y * 0.5, "La couverture éducative occupe moins de la moitié de la hauteur : %s grand=%s" % [resolution, large])
				if education.get_global_rect().position.x < library.get_global_rect().position.x:
					_check(education.get_global_rect().end.x <= library.get_global_rect().position.x + 1, "Enquête à gauche et quatre cases à droite sans recouvrement")
			for id in GAMES:
				var cover := _find("library_cover_" + id) as Control
				_check(cover != null and cover.size.x > 0 and cover.size.y > 0, "Couverture réelle du jeu acheté : " + id)
			await _check_focused_layout("split", resolution, large)
			await _capture("home_split_%dx%d_%s" % [resolution.x, resolution.y, "large" if large else "normal"])
			values.home_layout = "carousel"
			_check(settings.apply_settings(values).ok, "Disposition défilante réellement appliquée")
			app._show_screen("home")
			await _frames(10)
			var carousel := _find("home_carousel") as ScrollContainer
			_check(carousel != null and carousel.follow_focus, "Le carrousel accompagne le focus clavier et manette")
			var first_cover := _find("home_education_cover") as Control
			for id in GAMES:
				var cover := _find("library_cover_" + id) as Control
				_check(first_cover != null and cover != null and cover.size.is_equal_approx(first_cover.size), "Enquête et futur jeu ont des couvertures de même taille : " + id)
			if carousel != null:
				_find("home_next").grab_focus()
				await _frames(8)
				# The previous screen can remember a card far along the row.
				# Start at the first cover to exercise a complete native round trip.
				carousel.scroll_horizontal = 0
				await _frames(3)
				var start: int = carousel.scroll_horizontal
				await _activate("home_next", true)
				await _frames(8)
				_check(carousel.scroll_horizontal > start, "Suivant fait réellement défiler la bibliothèque")
				var maximum := carousel.get_h_scroll_bar().max_value - carousel.get_h_scroll_bar().page
				_check(carousel.scroll_horizontal <= maximum + 1, "Le défilement reste borné aux couvertures disponibles")
				await _activate("home_previous")
				await _frames(8)
				_check(carousel.scroll_horizontal == start, "Précédent revient à la couverture de départ")
			await _check_focused_layout("carousel", resolution, large)
			await _capture("home_carousel_%dx%d_%s" % [resolution.x, resolution.y, "large" if large else "normal"])
	_check(state.profile == before and saves.read_profile(first_id).data == before, "Tester les deux dispositions ne modifie ni les points ni les jeux")
	_check(settings.apply_settings(original).ok, "Réglages de disposition restaurés")
	root.size = Vector2i(1280, 720)


func _test_appearance_and_credits() -> void:
	app._show_screen("home")
	await _frames(6)
	await _activate("home_settings")
	await _choose("settings_categories", 4)
	var committed: Dictionary = settings.committed.duplicate(true)
	var saved: String = FileAccess.get_file_as_string(settings._path())
	var profile_before: Dictionary = state.profile.duplicate(true)
	for style in Palette.presets():
		_check(_find("appearance_" + style.id) != null, "Style accessible dans les paramètres : " + style.name)
	await _activate("appearance_nuit", true)
	_check(app.draft_settings.appearance_style == "nuit" and settings.current.appearance_style == "nuit", "Choisir Nuit prévisualise le fond sombre dans l’interface réelle")
	_check(settings.committed == committed and FileAccess.get_file_as_string(settings._path()) == saved, "Une prévisualisation d’apparence n’enregistre pas le fichier")
	var colors: Dictionary = app._palette()
	_check(Palette.contrast_ratio(Color(colors.foreground), Color(colors.background)) >= 4.5 and Palette.contrast_ratio(Color(colors.button_text), Color(colors.button)) >= 4.5, "Textes lisibles sur le fond et les boutons de Nuit")
	var displayed_label := _first_label(app.content)
	_check(displayed_label != null and Palette.contrast_ratio(displayed_label.get_theme_color("font_color"), Color(colors.background)) >= 4.5, "Le thème réellement appliqué affiche un titre lisible sur le fond Nuit")
	var background := _find("setting_background_color") as OptionButton
	var button := _find("setting_button_color") as OptionButton
	_check(background != null and button != null, "Couleur du fond et couleur des boutons sont des choix séparés")
	if background != null and button != null:
		await _choose("setting_background_color", 1)
		await _choose("setting_button_color", 2)
		_check(not app.draft_settings.background_color.is_empty() and not app.draft_settings.button_color.is_empty(), "Les deux couleurs sont prévisualisées indépendamment")
		colors = app._palette()
		_check(Palette.contrast_ratio(Color(colors.foreground), Color(colors.background)) >= 4.5 and Palette.contrast_ratio(Color(colors.button_text), Color(colors.button)) >= 4.5, "Les couleurs personnalisées conservent un texte lisible")
	await _choose("settings_categories", 1)
	var layout := _find("setting_home_layout") as OptionButton
	_check(layout != null, "Le choix de disposition figure dans Affichage")
	if layout != null:
		await _choose("setting_home_layout", 1)
		_check(settings.current.home_layout == "carousel" and app.draft_settings.home_layout == "carousel", "La disposition est également un aperçu tant qu’Appliquer n’est pas validé")
	var picker := _find("settings_categories") as OptionButton
	_check(picker != null and picker.get_item_text(picker.item_count - 1) == "Crédits", "Crédits est la dernière catégorie des paramètres")
	if picker != null:
		await _choose("settings_categories", picker.item_count - 1)
		_check(_contains_text(app.content, "Godot") and _contains_text(app.content, "licence"), "Les crédits mentionnent le moteur et les licences à la fin des paramètres")
		_check(settings.current.appearance_style == "nuit" and settings.committed == committed, "Consulter les crédits conserve l’aperçu sans le sauvegarder")
		await _capture("settings_credits_nuit")
	await _key(KEY_ESCAPE)
	_check(app.screen == "home" and settings.current == committed and settings.committed == committed, "Annuler restaure le style, les couleurs et la disposition précédents")
	_check(FileAccess.get_file_as_string(settings._path()) == saved and state.profile == profile_before, "Annuler ne touche ni au fichier des réglages ni à l’inventaire du profil")
	await _activate("home_settings")
	await _choose("settings_categories", 4)
	await _activate("appearance_aurore")
	await _capture("settings_appearance_aurore")
	await _choose("settings_categories", 1)
	await _choose("setting_home_layout", 1)
	await _activate("settings_apply")
	_check(app.screen == "home" and settings.committed.appearance_style == "aurore" and settings.committed.home_layout == "carousel", "Appliquer sauvegarde réellement style et disposition")
	_check(settings.load_settings().ok and settings.current.appearance_style == "aurore" and settings.current.home_layout == "carousel", "Les nouveaux réglages sont relus depuis le fichier de sauvegarde")
	_check(state.profile == profile_before and saves.read_profile(first_id).data == profile_before, "Personnaliser l’apparence ne dépense aucun point et ne remplace aucun équipement")
	_check(settings.apply_settings(committed).ok, "Réglages initiaux restaurés après la recette")


func _check_focused_layout(mode: String, resolution: Vector2i, large: bool) -> void:
	for control in app._focusables(app.content):
		control.grab_focus()
		await _frames(6)
		var bounds: Rect2 = app.scroll.get_global_rect()
		var rect: Rect2 = control.get_global_rect()
		_check(rect.position.x >= bounds.position.x - 1 and rect.end.x <= bounds.end.x + 1 and rect.position.y >= bounds.position.y - 1 and rect.end.y <= bounds.end.y + 1, "Commande entièrement visible au focus : %s/%s %s grand=%s" % [mode, control.name, resolution, large])
		if control is Button:
			var style: StyleBox = control.get_theme_stylebox("normal")
			var width: float = control.get_theme_font("font").get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, control.get_theme_font_size("font_size")).x
			_check(width <= rect.size.x - style.get_content_margin(SIDE_LEFT) - style.get_content_margin(SIDE_RIGHT) + 2, "Libellé de commande entier : " + String(control.name))


func _find(id: String) -> Node:
	return app.find_child(id, true, false)


func _contains_text(node: Node, text: String) -> bool:
	if node is Label and node.text.to_lower().contains(text.to_lower()):
		return true
	for child in node.get_children():
		if _contains_text(child, text):
			return true
	return false


func _first_label(node: Node) -> Label:
	if node is Label and node.is_visible_in_tree():
		return node
	for child in node.get_children():
		var found := _first_label(child)
		if found != null:
			return found
	return null


func _activate(id: String, joy: bool = false) -> bool:
	var button := _find(id) as BaseButton
	_check(button != null and button.is_visible_in_tree() and not button.disabled, "Commande native disponible : " + id)
	if button == null or not button.is_visible_in_tree() or button.disabled:
		return false
	button.grab_focus()
	await _frames(5)
	if joy:
		await _joy(JOY_BUTTON_A)
	else:
		await _key(KEY_ENTER)
	return true


func _choose(id: String, index: int) -> void:
	var option := _find(id) as OptionButton
	_check(option != null and index >= 0 and index < option.item_count, "Choix natif présent : %s[%d]" % [id, index])
	if option == null or index < 0 or index >= option.item_count:
		return
	option.grab_focus()
	await _frames(5)
	await _key(KEY_ENTER)
	var popup := option.get_popup()
	_check(popup.visible, "Liste déroulante réellement ouverte : " + id)
	for attempt in range(option.item_count + 2):
		if not popup.visible or popup.get_focused_item() == index:
			break
		await _key(KEY_DOWN)
	if popup.visible:
		await _key(KEY_ENTER)
	await _frames(5)
	var rebuilt := _find(id) as OptionButton
	_check(rebuilt != null and rebuilt.selected == index, "Choix validé au clavier : %s[%d]" % [id, index])


func _key(code: Key) -> void:
	if not router.gameplay_allowed():
		await create_timer(0.23).timeout
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(5)


func _joy(code: JoyButton) -> void:
	if not router.gameplay_allowed():
		await create_timer(0.23).timeout
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(5)


func _frames(count: int = 5) -> void:
	for index in range(count):
		await process_frame


func _capture(name: String) -> void:
	if not captures:
		return
	app.scroll.scroll_vertical = 0
	await _frames(4)
	await RenderingServer.frame_post_draw
	var folder := "res://docs/screenshots/bibliotheque_0.5.0"
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK, "Dossier des captures réelles")
	var path := folder.path_join(name + ".png")
	_check(root.get_texture().get_image().save_png(path) == OK, "Capture du rendu réel : " + name)


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("LIBRARY_UI_FAIL : " + message)


func _finish() -> void:
	# Finish pending resize and focus coroutines while the UI is still in-tree.
	await _frames(4)
	if is_instance_valid(app):
		root.remove_child(app)
		app.queue_free()
	await _frames(4)
	controllers.debug_clear_devices()
	for player in [settings._music_player, settings._effect_player]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	# Dummy audio can mix more slowly than the graphical frame loop.
	await create_timer(.15).timeout
	await _frames(4)
	print("LIBRARY_UI : %d assertions, %d échec(s)." % [checks, failures.size()])
	call_deferred("quit", 0 if failures.is_empty() else 1)
