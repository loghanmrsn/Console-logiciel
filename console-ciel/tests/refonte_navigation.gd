extends SceneTree
## Four resolutions, glass navigation, real player updates and isolated persistence.
const DESTINATIONS = ['home', 'shop', 'settings', 'profiles']
const LABELS = ['Accueil', 'Boutique', 'Paramètres', 'Profil']
var app
var checks = 0
var failures = 0
var profiles
var state
var settings
var saves
var router
var shop
var investigation

func _initialize(): run.call_deferred()

func frames(n = 5):
	for i in range(n): await process_frame

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr('REFONTE_FAIL : ' + message)

func key(code):
	if not router.gameplay_allowed(): await create_timer(.23).timeout
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames(5)

func check_player(message: String):
	var nav = app.navigation
	var avatar = shop.item(state.profile.equipped.avatar)
	check(nav.profile_name_label.text == state.profile.display_name, 'Pseudo réel dans la barre ' + message)
	check(nav.profile_points_label.text == '%d pts' % state.profile.wallet.points, 'Solde réel dans la barre ' + message)
	check(nav.profile_avatar.visible and nav.profile_avatar.color == Color(avatar.color) and nav.profile_avatar.variant == {'H': 0, 'O': 2, 'F': 1, 'R': 2}.get(avatar.symbol, 0), 'Avatar équipé dans la barre ' + message)
	check(nav.profile_avatar.frame == state.profile.equipped.frame and nav.profile_avatar.frame_spec == shop.item(state.profile.equipped.frame), 'Cadre équipé dans la barre ' + message)

func check_readable(label: Label, bounds: Rect2, message: String, allow_ellipsis = false):
	check(label.is_visible_in_tree() and bounds.encloses(label.get_global_rect()), 'Information visible ' + message)
	var width = label.get_theme_font('font').get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size('font_size')).x
	var complete_name = allow_ellipsis and label.clip_text and label.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS and label.tooltip_text == label.text
	check(width <= label.size.x + .5 or complete_name, 'Libellé lisible ou pseudo complet accessible ' + message)

func check_selection_and_focus():
	var selected_style = app.navigation.buttons[0].get_theme_stylebox('normal')
	var idle_style = app.navigation.buttons[1].get_theme_stylebox('normal')
	var focus_style = app.navigation.buttons[1].get_theme_stylebox('focus')
	check(selected_style is StyleBoxFlat and selected_style.bg_color != idle_style.bg_color and selected_style.corner_radius_top_left > 0 and selected_style.corner_radius_bottom_right > 0, 'Destination sélectionnée représentée par une capsule')
	check(focus_style is StyleBoxFlat and focus_style.border_color.a > 0 and focus_style.border_width_top > 0 and focus_style.border_width_bottom > 0 and focus_style != selected_style, 'Contour de focus distinct de la capsule sélectionnée')

func check_draft_navigation():
	check(settings.apply_settings(settings.committed).ok, 'Réglages de référence enregistrés dans le dossier isolé')
	var committed = settings.committed.duplicate(true)
	var settings_file = FileAccess.get_file_as_string(settings._path())
	app._show_screen('home')
	await frames()
	app.navigation.buttons[2].grab_focus()
	await key(KEY_ENTER)
	check(app.screen == 'settings' and app.navigation.selected == 'settings', 'Paramètres ouverts par la troisième destination')
	app.settings_category = 2
	app._show_screen('settings')
	await frames()
	app.content.find_child('setting_reduce_transparency', true, false).grab_focus()
	await key(KEY_ENTER)
	check(app.draft_settings.reduce_transparency != committed.reduce_transparency and settings.current.reduce_transparency == app.draft_settings.reduce_transparency, 'Transparence prévisualisée sans application')
	app.navigation.buttons[1].grab_focus()
	await key(KEY_ENTER)
	check(is_instance_valid(app.modal) and app.screen == 'settings', 'Changement de destination confirme le brouillon')
	check(app.modal.is_ancestor_of(root.gui_get_focus_owner()) and app.navigation.buttons[1].focus_mode == Control.FOCUS_NONE, 'Le dialogue possède le focus et bloque la barre')
	check(settings.committed == committed and FileAccess.get_file_as_string(settings._path()) == settings_file, 'La confirmation n’enregistre pas les aperçus')
	await key(KEY_ESCAPE)
	check(not is_instance_valid(app.modal) and app.screen == 'settings' and settings.current.reduce_transparency != committed.reduce_transparency, 'Annuler le dialogue conserve le brouillon et la destination')
	app.navigation.buttons[1].grab_focus()
	await key(KEY_ENTER)
	check(is_instance_valid(app.modal), 'Nouvelle tentative avec le brouillon ouvre la confirmation')
	app.modal.find_child('modal_confirm', true, false).grab_focus()
	await key(KEY_ENTER)
	check(app.screen == 'shop' and app.navigation.selected == 'shop', 'Confirmer rejoint la destination demandée')
	check(settings.current == committed and settings.committed == committed and FileAccess.get_file_as_string(settings._path()) == settings_file, 'Le départ annule les aperçus sans les sauvegarder')

func choose_settings_category(category: int, message: String):
	for i in range(posmod(category - app.settings_category, 7)):
		var focus_target = app.navigation.buttons[2] if app.navigation.visible else app.header_back
		focus_target.grab_focus()
		await key(KEY_E)
	check(app.settings_category == category, 'Catégorie choisie au clavier ' + message)

func open_settings_subpage(destination: String):
	await choose_settings_category(3 if destination == 'controls' else 6, destination)
	app.content.find_child('test_controls' if destination == 'controls' else 'settings_help', true, false).grab_focus()
	await key(KEY_ENTER)
	if destination == 'help_controls':
		app.content.find_child('help_controls', true, false).grab_focus()
		await key(KEY_ENTER)

func check_settings_subpages():
	var committed = settings.committed.duplicate(true)
	var settings_file = FileAccess.get_file_as_string(settings._path())
	var profile_before = state.profile.duplicate(true)
	for destination in ['controls', 'help', 'help_controls']:
		var origin = 'home' if destination == 'controls' else 'shop'
		var target_screen = 'help' if destination == 'help' else 'controls'
		app._show_screen(origin)
		await frames()
		app.navigation.buttons[2].grab_focus()
		await key(KEY_ENTER)
		check(app.screen == 'settings' and app.settings_origin == origin, 'Origine des réglages conservée ' + destination)
		await choose_settings_category(2, 'brouillon ' + destination)
		app.content.find_child('setting_reduce_transparency', true, false).grab_focus()
		await key(KEY_ENTER)
		var draft = app.draft_settings.duplicate(true)
		var preview = settings.current.duplicate(true)
		check(preview != committed and draft.reduce_transparency == preview.reduce_transparency, 'Brouillon réel créé avant la sous-page ' + destination)
		await open_settings_subpage(destination)
		check(app.screen == target_screen and app.navigation.visible and app.navigation.selected == 'settings', 'Sous-page des réglages ouverte au clavier ' + destination)
		app.navigation.buttons[2].grab_focus()
		await key(KEY_ENTER)
		check(app.screen == 'settings' and not is_instance_valid(app.modal), 'Onglet Paramètres revient directement aux réglages ' + destination)
		check(app.settings_origin == origin and app.draft_settings == draft and settings.current == preview, 'Retour par la barre conserve origine et brouillon ' + destination)
		await open_settings_subpage(destination)
		check(app.screen == target_screen, 'Sous-page rouverte avec les mêmes aperçus ' + destination)
		app.navigation.buttons[1].grab_focus()
		await key(KEY_ENTER)
		check(is_instance_valid(app.modal) and app.screen == target_screen, 'Quitter la sous-page demande l’abandon du brouillon ' + destination)
		check(settings.committed == committed and FileAccess.get_file_as_string(settings._path()) == settings_file, 'La confirmation de sous-page n’applique rien ' + destination)
		await key(KEY_ESCAPE)
		check(not is_instance_valid(app.modal) and app.screen == target_screen and app.navigation.selected == 'settings', 'Refuser l’abandon garde la sous-page ' + destination)
		check(app.settings_origin == origin and app.draft_settings == draft and settings.current == preview, 'Refuser l’abandon conserve le brouillon ' + destination)
		app.navigation.buttons[1].grab_focus()
		await key(KEY_ENTER)
		check(is_instance_valid(app.modal), 'Nouvelle tentative confirme encore le brouillon ' + destination)
		app.modal.find_child('modal_confirm', true, false).grab_focus()
		await key(KEY_ENTER)
		check(app.screen == 'shop' and app.navigation.selected == 'shop', 'Accepter l’abandon rejoint Boutique ' + destination)
		check(settings.current == committed and settings.committed == committed and FileAccess.get_file_as_string(settings._path()) == settings_file, 'Accepter l’abandon restaure les réglages sans modifier leur fichier ' + destination)
		check(state.profile == profile_before and saves.read_profile(profile_before.id).data == profile_before, 'Sous-pages et confirmations préservent les données du joueur ' + destination)

func check_pause_settings_subpages():
	var committed = settings.committed.duplicate(true)
	var settings_file = FileAccess.get_file_as_string(settings._path())
	await choose_settings_category(2, 'brouillon depuis la pause')
	app.content.find_child('setting_reduce_transparency', true, false).grab_focus()
	await key(KEY_ENTER)
	var draft = app.draft_settings.duplicate(true)
	var preview = settings.current.duplicate(true)
	check(preview != committed, 'La pause possède un aperçu temporaire')
	for destination in ['controls', 'help', 'help_controls']:
		await open_settings_subpage(destination)
		check(app.screen == ('help' if destination == 'help' else 'controls'), 'Sous-page de pause ouverte au clavier ' + destination)
		check(not app.navigation.visible and not app.demo.world._controls_enabled, 'La barre reste masquée et le jeu suspendu dans la sous-page de pause ' + destination)
		check(app.header_profile.visible and app.header_points.visible and app.header_avatar.visible, 'Informations du joueur disponibles sans barre dans la sous-page de pause ' + destination)
		check(app.demo.paused and app.demo.overlay_kind == 'pause', 'Le contexte de pause est conservé dans la sous-page ' + destination)
		await key(KEY_ESCAPE)
		if destination == 'help_controls': await key(KEY_ESCAPE)
		check(app.screen == 'settings' and app.settings_origin == 'game' and app.draft_settings == draft and settings.current == preview, 'Retour des sous-pages conserve la pause et son brouillon ' + destination)
		check(settings.committed == committed and FileAccess.get_file_as_string(settings._path()) == settings_file, 'Les sous-pages de pause ne sauvegardent pas les aperçus ' + destination)

func check_rewards_and_equipment(profile_id: String):
	check(profiles.start_game().ok, 'Partie isolée pour les récompenses')
	app._show_screen('home')
	await frames()
	check(investigation.begin_mission('lighting').ok and investigation.submit_lighting(['source_switch', 'switch_lamp', 'lamp_return']).ok, 'Récompense obtenue par une vraie mission')
	await frames()
	check(state.profile.wallet.points == 50 and app.navigation.profile_points_label.text == '50 pts', 'Les points gagnés actualisent la barre persistante')
	check(app.home_labels.progress.text.begins_with('1 / 3'), 'La progression réelle actualise l’accueil')
	check(shop.purchase('avatar_orbit').ok, 'Achat d’avatar avec les points gagnés')
	await frames()
	check(state.profile.wallet.points == 30 and app.navigation.profile_points_label.text == '30 pts', 'L’achat actualise le solde dans la barre')
	check(shop.equip('avatar_orbit').ok and shop.purchase('frame_round').ok and shop.equip('frame_round').ok, 'Avatar et cadre achetés puis équipés')
	await frames()
	check_player('après achats')
	check(profiles.save_active().ok, 'Progression et achats enregistrés')
	var saved = saves.read_profile(profile_id)
	check(saved.ok and saved.data == state.profile, 'La sauvegarde conserve progression, points, achats et équipements')
	var other = profiles.create_profile('Autre joueur')
	check(other.ok and state.profile.wallet.points == 0, 'Second profil indépendant')
	await frames()
	check_player('second joueur')
	check(profiles.select_profile(profile_id).ok and state.profile == saved.data, 'Reprise du vrai profil avec sa progression et ses achats')
	await frames()
	check_player('après reprise')

func run():
	await process_frame
	saves = root.get_node('SaveService')
	profiles = root.get_node('ProfileService')
	state = root.get_node('AppState')
	settings = root.get_node('SettingsService')
	router = root.get_node('SceneRouter')
	shop = root.get_node('ShopService')
	investigation = root.get_node('InvestigationService')
	saves.root_path = 'user://tests/refonte_' + str(Time.get_ticks_usec())
	settings.storage_root = saves.root_path
	app = load('res://scenes/main.tscn').instantiate()
	root.add_child(app)
	await frames(25)
	var profile = profiles.create_profile('WWWWWWWWWWWWWWWW')
	check(profile.ok, 'Profil isolé')
	check(profiles.select_profile(profile.data.id).ok, 'Sélection')
	var before = state.profile.duplicate(true)
	var nav_id = app.navigation.get_instance_id()
	check(app.navigation.buttons.size() == 4 and app.navigation.destination_labels.size() == 4, 'Quatre destinations persistantes')
	for index in range(DESTINATIONS.size()):
		check(String(app.navigation.buttons[index].name) == 'home_' + DESTINATIONS[index] and app.navigation.destination_labels[index].text == LABELS[index], 'Ordre demandé : ' + LABELS[index])
	for resolution in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(800, 480)]:
		root.size = resolution
		await frames()
		for large in [false, true]:
			var values = settings.defaults.duplicate(true)
			values.large_text = large
			values.reduce_motion = true
			values.reduce_transparency = large
			check(settings.preview(values).ok, 'Mode de lecture ' + str(resolution) + ' grand=' + str(large))
			for destination in ['home', 'shop', 'settings', 'profiles', 'help', 'controls']:
				app.draft_settings = values.duplicate(true)
				app.settings_origin = 'home'
				app.parent_screen = 'settings'
				app.controls_origin = 'settings'
				app._show_screen(destination)
				await frames(8)
				var nav = app.navigation
				var bounds = Rect2(Vector2.ZERO, Vector2(resolution))
				var selected = 'settings' if destination in ['help', 'controls'] else destination
				check(nav.get_instance_id() == nav_id, 'Navigation persistante ' + destination)
				check(nav.visible and nav.selected == selected, 'Onglet actif ' + destination)
				check(not app.header_profile.visible and not app.header_points.visible and not app.header_avatar.visible, 'Informations du joueur déplacées dans la barre ' + destination)
				check(app.scroll.get_global_rect().end.y <= nav.get_global_rect().position.y + .5, 'Aucun recouvrement du contenu ' + str(resolution))
				check(bounds.encloses(nav.panel.get_global_rect()), 'Barre entière visible ' + str(resolution))
				check_player(destination)
				check_readable(nav.profile_name_label, bounds, 'pseudo de 16 caractères ' + str(resolution), true)
				check_readable(nav.profile_points_label, bounds, 'points ' + str(resolution))
				check(nav.buttons[3].get_global_rect().encloses(nav.profile_avatar.get_global_rect()), 'Avatar contenu dans Profil ' + str(resolution))
				var panel_style = nav.panel.get_theme_stylebox('panel')
				check(panel_style is StyleBoxFlat and (is_equal_approx(panel_style.bg_color.a, 1.0) if large else panel_style.bg_color.a > 0 and panel_style.bg_color.a < 1), 'Réduire la transparence rend la barre opaque ' + str(large))
				for index in range(nav.buttons.size()):
					var tab = nav.buttons[index]
					check(bounds.encloses(tab.get_global_rect()), 'Onglet accessible ' + str(tab.name))
					check_readable(nav.destination_labels[index], bounds, LABELS[index])
					var top = tab.get_node_or_null(tab.focus_neighbor_top)
					var down = tab.get_node_or_null(tab.focus_neighbor_bottom)
					check(top != null and down != null and app.content.is_ancestor_of(top) and app.content.is_ancestor_of(down), 'Contenu accessible depuis chaque onglet')
					if index > 0:
						check(nav.buttons[index - 1].get_global_rect().end.x <= tab.get_global_rect().position.x + .5, 'Destinations sans recouvrement ' + LABELS[index])
			app._show_screen('home')
			await frames(6)
			app.navigation.buttons[1].grab_focus()
			await frames()
			check(app.navigation.selected == 'home', 'Le focus ne change pas la destination active')
			check_selection_and_focus()
			await key(KEY_RIGHT)
			check(root.gui_get_focus_owner() == app.navigation.buttons[2], 'Flèche droite : Boutique vers Paramètres')
			await key(KEY_RIGHT)
			check(root.gui_get_focus_owner() == app.navigation.buttons[3], 'Flèche droite : Paramètres vers Profil')
			await key(KEY_RIGHT)
			check(root.gui_get_focus_owner() == app.navigation.buttons[0], 'La navigation boucle de Profil vers Accueil')
			await key(KEY_LEFT)
			check(root.gui_get_focus_owner() == app.navigation.buttons[3], 'Flèche gauche : Accueil vers Profil')
			await key(KEY_UP)
			check(app.content.is_ancestor_of(root.gui_get_focus_owner()), 'Flèche haut rejoint le contenu')
	check(state.profile == before and saves.read_profile(before.id).data == before, 'La matrice visuelle ne modifie pas les données du joueur')
	settings.cancel_preview()
	root.size = Vector2i(1280, 720)
	app._show_screen('home')
	await frames()
	app.navigation.buttons[1].grab_focus()
	await key(KEY_ENTER)
	check(app.screen == 'shop', 'Validation réelle de la barre')
	await key(KEY_ESCAPE)
	check(app.screen == 'home' and root.gui_get_focus_owner() == app.navigation.buttons[1], 'Retour restitue le focus')
	await check_draft_navigation()
	await check_settings_subpages()
	await check_rewards_and_equipment(profile.data.id)
	check(app.navigation.get_instance_id() == nav_id, 'La même barre survit aux réglages, achats et changements de joueur')
	app._show_screen('game')
	await frames()
	check(not app.navigation.visible, 'Barre masquée en jeu')
	check(app.header_profile.visible and app.header_points.visible and app.header_avatar.visible, 'Informations du joueur conservées en jeu')
	var player = app.demo.world.player
	check(player.sprite.sprite_frames.get_animation_names().size() == 4, 'Quatre directions animées')
	check(player.get_child(0).shape.radius == 10 and app.demo.world._props.y_sort_enabled, 'Collision des pieds et profondeur')
	app.demo.request_pause()
	await frames()
	var objectives = app.demo.modal_content.find_child('pause_objectives', true, false)
	objectives.grab_focus()
	await key(KEY_ENTER)
	check(app.demo._objectives_expanded and not app.demo.paused, 'Objectifs accessibles depuis la pause sans souris')
	app.demo.request_pause()
	app.settings_origin = 'game'
	app.draft_settings = settings.committed.duplicate(true)
	app._show_screen('settings')
	await frames()
	check(not app.navigation.visible and not app.demo.world._controls_enabled, 'Paramètres de pause sans navigation hors jeu')
	await check_pause_settings_subpages()
	app._cancel_settings()
	await frames()
	check(app.demo.paused and app.demo.overlay_kind == 'pause', 'Retour au contexte de pause')
	app.demo.resume()
	root.remove_child(app)
	app.queue_free()
	await frames(3)
	print('REFONTE_NAVIGATION : %d assertions, %d échec(s).' % [checks, failures])
	quit(0 if failures == 0 else 1)
