extends SceneTree
## Native input smoke tests. Uses isolated user data and no physical controller.
## godot --headless --path . --script res://tests/ui_smoke.gd
## Real viewport captures: godot --path . --script res://tests/ui_smoke.gd -- --screenshots

var checks := 0
var failures: Array[String] = []
var test_root := ""
var app
var saves
var profiles
var shop
var rewards
var settings
var state
var router
var investigation
var controllers
var captures := false
var layout_reports: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	# Synthetic press/release pairs must be delivered immediately, not merged
	# into a later frame by the graphical backend's accumulated input queue.
	if DisplayServer.get_name()!='headless': Input.use_accumulated_input=false
	for service_name in ["SaveService", "ProfileService", "ShopService", "RewardService", "SettingsService", "AppState", "SceneRouter", "InvestigationService", "ControllerService"]:
		_check(root.has_node(service_name), "Autoload disponible : " + service_name)
	if not failures.is_empty():
		await _finish()
		return
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	shop = root.get_node("ShopService")
	rewards = root.get_node("RewardService")
	settings = root.get_node("SettingsService")
	state = root.get_node("AppState")
	router = root.get_node("SceneRouter")
	investigation = root.get_node("InvestigationService")
	controllers = root.get_node("ControllerService")
	# Explicit development fixture: no USB controller is claimed to be attached.
	controllers.debug_set_devices([0])
	test_root = "user://tests/ui_%s_%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	print("UI : données isolées ", ProjectSettings.globalize_path(test_root))
	captures = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	print("UI : affichage ", DisplayServer.get_name(), "; captures réelles ", captures)
	saves.root_path = test_root
	settings.storage_root = test_root
	state.clear_profile()
	root.size = Vector2i(1280, 720)
	var packed = load("res://scenes/main.tscn")
	if packed == null:
		_check(false, "Scène principale chargeable")
		await _finish()
		return
	app = packed.instantiate()
	root.add_child(app)
	for frame in range(40):
		await process_frame
		if app.screen != "boot":
			break
	await _frames(5)
	_check(app.screen == "editor", "Premier lancement ouvre la création de profil")
	await _capture("profile_editor_1280x720")
	var name_edit = _find(app, "profile_name")
	var first_key = _find(app, "key_A")
	_check(name_edit != null and first_key != null, "Pseudo et clavier virtuel présents")
	if name_edit == null or first_key == null:
		await _finish()
		return
	_check(root.gui_get_focus_owner() == first_key, "Le premier focus est une touche du clavier virtuel")
	_check(first_key.text == "a" and (_find(app, "key_1") == null or not _find(app, "key_1").is_visible_in_tree()), "Le clavier commence en minuscules, sans chiffres dans la page de lettres")
	await _joy(JOY_BUTTON_A)
	_check(name_edit.text == "a", "Première validation manette simulée remplace le pseudo proposé par une minuscule")
	await _activate("key_Shift", true)
	_check(_find(app, "key_B").text == "B", "La flèche Majuscule affiche les lettres en capitales")
	await _activate("key_B", true)
	_check(name_edit.text == "aB" and _find(app, "key_B").text == "b", "Majuscule ponctuelle : la lettre suivante revient en minuscule")
	await _activate("key_B")
	await _activate("key_123", true)
	_check(_find(app, "key_123").text == "ABC" and not _find(app, "key_A").is_visible_in_tree(), "123 ouvre les chiffres et propose le retour ABC")
	await _activate("key_1", true)
	var symbol = _button_with_text(app, "@")
	_check(symbol != null, "La page 123 propose des caractères spéciaux")
	if symbol != null:
		symbol.grab_focus()
		await _press(KEY_ENTER)
	_check(name_edit.text == "aBb1@", "Chiffre et symbole du clavier virtuel insérés")
	await _activate("key_123")
	_check(_find(app, "key_A").text == "a" and _find(app, "key_123").text == "123", "ABC restitue la page des minuscules")
	await _activate("key_Espace")
	await _activate("key_B")
	_check(name_edit.text == "aBb1@ b", "Espace et minuscule du clavier virtuel fonctionnent")
	await _activate("key_Effacer")
	_check(name_edit.text == "aBb1@ ", "Effacer retire le caractère précédent")
	name_edit.grab_focus()
	await _press(KEY_Q)
	await _press(KEY_E)
	_check(app.screen == "editor", "Les lettres Q/E pendant la saisie ne changent pas d'écran")
	_find(app, "key_Valider").grab_focus()
	await _press(KEY_ENTER)
	await _frames(3)
	_check(app.screen == "home" and not state.profile.is_empty(), "Création de profil via clavier virtuel ouvre l'accueil")
	if state.profile.is_empty() or app.screen != "home":
		await _finish()
		return
	_check(_find(app, "continue_game").disabled, "Continuer indisponible sans progression")
	_check(root.gui_get_focus_owner() == _find(app, "new_game"), "Focus initial de l'accueil sur Commencer")
	_check(saves.read_profile(state.profile.id).ok and state.profile.wallet.points == 0, "Profil créé par UI enregistré sans crédit debug")
	await _capture("home_1280x720")
	_find(app, "home_shop").grab_focus()
	await _press(KEY_ENTER)
	_check(app.screen == "shop", "Boutique accessible au clavier")
	await _capture("shop_1280x720")
	await _joy(JOY_BUTTON_B)
	_check(app.screen == "home", "Face droite simulée retourne à l'accueil")
	_check(root.gui_get_focus_owner() == _find(app, "home_shop") and router.focus_key("home") == "home_shop", "SceneRouter mémorise et restitue le bouton Boutique")
	_find(app, "home_settings").grab_focus()
	await _press(KEY_ENTER)
	_check(app.screen == "settings", "L'aide reste accessible depuis Paramètres")
	for _category in range(6):
		await _press(KEY_E)
	_check(app.settings_category == 6, "À propos accessible au clavier")
	_find(app, "settings_help").grab_focus()
	await _press(KEY_ENTER)
	_check(app.screen == "help", "L’aide conserve son écran accessible depuis les paramètres")
	await _capture("help_1280x720")
	await _press(KEY_ESCAPE)
	_check(app.screen == "settings", "Retour de l'aide vers les paramètres")
	for _category in range(6):
		await _press(KEY_Q)
	await _press(KEY_ESCAPE)
	_check(app.screen == "home", "Retour des paramètres vers l'accueil après l'aide")
	var rest_focus: Control = root.gui_get_focus_owner()
	await _joy_axis(JOY_AXIS_LEFT_Y, 0.05)
	_check(root.gui_get_focus_owner() == rest_focus, "Axe simulé au repos sous la zone morte : aucun défilement")
	await _joy_axis(JOY_AXIS_LEFT_Y, 0.9)
	_check(root.gui_get_focus_owner() != rest_focus, "Axe simulé au-dessus du seuil : navigation UI")
	await _joy_axis(JOY_AXIS_LEFT_Y, 0.0)
	await _test_slider()
	await _test_modal()
	await _test_pause()
	await _test_shop_purchase()
	await _test_profile_isolation()
	await _test_diagnostics()
	await _test_close_cancel()
	if not "--quick" in OS.get_cmdline_user_args():
		await _test_layouts()
	await _finish()


func _test_slider() -> void:
	_find(app, "home_settings").grab_focus()
	await _press(KEY_ENTER)
	_check(app.screen == "settings", "Entrée ouvre les paramètres")
	if app.screen != "settings":
		return
	await _capture("settings_audio_1280x720")
	var slider = _find(app, "setting_master")
	_check(slider != null, "Slider du volume général présent")
	if slider == null:
		return
	slider.grab_focus()
	var initial: float = slider.value
	await _press(KEY_LEFT)
	_check(slider.value < initial, "Gauche modifie le HSlider focalisé")
	var changed: float = slider.value
	await _press(KEY_DOWN)
	_check(root.gui_get_focus_owner() == _find(app, "setting_music") and slider.value == changed, "Bas passe au slider Musique sans modifier le volume")
	await _press(KEY_UP)
	_check(root.gui_get_focus_owner() == slider, "Haut revient au volume général")
	var category_picker: OptionButton = _find(app, "settings_categories")
	category_picker.grab_focus()
	await _joy(JOY_BUTTON_A)
	var category_popup: PopupMenu = category_picker.get_popup()
	_check(category_popup.visible, "Face basse simulée ouvre la liste native des catégories")
	if category_popup.visible:
		var previous_item := category_popup.get_focused_item()
		await _joy(JOY_BUTTON_DPAD_DOWN)
		_check(category_popup.get_focused_item() != previous_item and category_popup.get_focused_item() >= 0, "Croix simulée navigue dans le popup de catégories")
		await _joy(JOY_BUTTON_B)
		_check(not category_popup.visible and app.screen == "settings", "Face droite ferme uniquement le popup des catégories")
	await _press(KEY_E)
	_check(app.settings_category == 1, "E change de catégorie hors saisie")
	await _joy(JOY_BUTTON_RIGHT_SHOULDER)
	_check(app.settings_category == 2, "RB simulé sélectionne Accessibilité")
	var before: Dictionary = settings.committed.duplicate(true)
	_find(app, "setting_reduce_transparency").grab_focus()
	await _press(KEY_ENTER)
	_check(settings.current.reduce_transparency != before.reduce_transparency, "Réduire la transparence produit un aperçu réel")
	await _press(KEY_ESCAPE)
	_check(app.screen == "home", "Échap annule les paramètres et revient à l'accueil")
	_check(settings.current == settings.committed, "Annulation UI restaure les aperçus")
	_check(root.gui_get_focus_owner() == _find(app, "home_settings"), "Retour des paramètres restaure le bouton d'origine")
	_find(app, "home_settings").grab_focus()
	await _press(KEY_ENTER)
	_find(app, "setting_reduce_motion").grab_focus()
	await _press(KEY_ENTER)
	_find(app, "settings_apply").grab_focus()
	await _press(KEY_ENTER)
	_check(app.screen == "home" and settings.committed.reduce_motion, "Appliquer valide réellement la réduction des animations")
	_check(FileAccess.file_exists(test_root.path_join("settings.cfg")), "Appliquer écrit les réglages dans le dossier temporaire")


func _test_modal() -> void:
	await _activate("home_settings")
	var opener = _find(app, "quit")
	opener.grab_focus()
	await _press(KEY_ENTER,0)
	_check(is_instance_valid(app.modal), "Quitter ouvre une confirmation")
	if not is_instance_valid(app.modal):
		return
	var modal = app.modal
	_check(opener.focus_mode == Control.FOCUS_NONE, "Modale désactive le focus derrière elle")
	await _burst(KEY_ENTER, 8)
	_check(is_instance_valid(app.modal) and app.modal == modal, "Validations rapides : une seule confirmation, aucun appui ne traverse son ouverture")
	if not is_instance_valid(modal): return
	for key_code in [KEY_RIGHT, KEY_DOWN, KEY_LEFT, KEY_UP, KEY_TAB]:
		await _press(key_code)
		_check(modal.is_ancestor_of(root.gui_get_focus_owner()), "Navigation capturée par la modale : " + OS.get_keycode_string(key_code))
	await _press(KEY_ESCAPE)
	await _frames(2)
	_check(not is_instance_valid(app.modal) and root.gui_get_focus_owner() == opener, "Échap ferme la modale et restitue le focus d'origine")
	await _press(KEY_ESCAPE)


func _test_pause() -> void:
	_find(app, "new_game").grab_focus()
	await _press(KEY_ENTER)
	await _frames(5)
	_check(app.screen == "game" and state.profile.progress.started, "Commencer ouvre réellement l'enquête")
	if app.screen != "game" or not is_instance_valid(app.demo):
		return
	_check(state.profile.wallet.points == 0 and state.profile.progress.completed_missions.is_empty(), "Appui menu → jeu ne valide aucune mission")
	await _capture("investigation_1280x720")
	await create_timer(0.22).timeout
	await _press(KEY_P)
	_check(app.demo.paused, "P suspend l'enquête")
	var before: Vector2 = app.demo.world.get_player_position()
	await _hold(KEY_RIGHT, 6)
	_check(app.demo.world.get_player_position() == before, "Les contrôles ne déplacent pas le joueur pendant la pause")
	if await _activate("pause_settings"):
		_check(app.screen == "settings", "Paramètres de la pause ouverts")
		controllers.debug_connection_changed(0, false)
		await _frames(4)
		_check(app.screen == "settings", "Déconnexion depuis les paramètres : l'écran reste exploitable au clavier")
		controllers.debug_connection_changed(0, true)
		await _press(KEY_ESCAPE)
		await _frames(5)
		_check(app.demo.overlay_kind == "controller_pause", "Retour au jeu après perte depuis les paramètres : suspension explicite")
		await _activate("controller_resume")
		_check(app.screen == "game" and app.demo.paused, "Annuler retourne à l'enquête toujours en pause")
		_check(_find(app, "pause_settings") == root.gui_get_focus_owner(), "Retour paramètres → enquête restitue le bouton Paramètres")
	if await _activate("pause_help"):
		_check(app.screen == "help", "Aide disponible pendant la pause")
		await _activate("help_controls")
		_check(app.screen == "controls", "Le test des commandes est accessible depuis l'aide de pause")
		await _press(KEY_ESCAPE)
		_check(app.screen == "help", "Retour du test des commandes revient à l'aide")
		await _press(KEY_ESCAPE)
		await _frames(5)
		_check(app.screen == "game" and app.demo.paused, "Retour de l'aide restitue la pause après le test des commandes")
		_check(_find(app, "pause_help") == root.gui_get_focus_owner(), "Retour de l'aide restitue le bouton Aide de la pause")
	await _press(KEY_ESCAPE)
	_check(not app.demo.paused, "Échap reprend l'enquête")
	await _test_controller_loss()
	await _test_controller_loss_in_quit_modal()
	await create_timer(0.22).timeout
	_check(app.demo.world.target_id == "building_exit", "À l’entrée, seule la porte de sortie est proche ; aucun équipement de mission")
	await _test_collisions(false)
	await _approach("lock")
	await _press(KEY_SPACE)
	_check(app.demo.overlay_kind == "dialog" and not state.profile.progress.completed_missions.has("lock"), "Mission verrouillée : indice lisible, aucune validation")
	before = app.demo.world.get_player_position()
	await _hold(KEY_LEFT, 6)
	_check(app.demo.world.get_player_position() == before, "Déplacement suspendu pendant un dialogue")
	await _press(KEY_ESCAPE)
	await create_timer(0.22).timeout
	await _hold(KEY_LEFT, 6)
	_check(app.demo.world.get_player_position() != before, "Les déplacements reprennent après fermeture du dialogue")
	await _solve_lighting(true)
	await _return_and_continue("lighting")
	await _solve_lock(true)
	await _test_collisions(true)
	await _return_and_continue("lock")
	await _solve_computer(true)
	_check(app.demo.overlay_kind == "conclusion", "Troisième réussite ouvre le bilan de l'enquête")
	_check(state.profile.wallet.points == 150 and state.profile.progress.run_reward_points == 150, "Conclusion distingue 150 points nouveaux du solde")
	await _activate("conclusion_menu")
	await _frames(4)
	_check(app.screen == "home" and not _find(app, "continue_game").disabled, "Retour de la conclusion ouvre l'accueil et permet la reprise")
	_check(app.header_points.text.contains("150"), "Le compteur de l'accueil reçoit les récompenses réelles")
	# Reprise after the third mission, then replay through a real confirmation.
	await _activate("continue_game")
	await _frames(5)
	_check(app.demo.world.computer_repaired and app.demo.world.door_open and app.demo.world.lighting_restored, "Reprise après les trois missions restaure toute la pièce")
	if app.demo.overlay_kind != "conclusion":
		await _press(KEY_P)
		await _activate("pause_conclusion")
	_check(app.demo.overlay_kind == "conclusion", "Le bilan du chapitre terminé se retrouve depuis la pause sans réactiver un équipement terminé")
	if _find(app, "conclusion_replay") != null:
		await _activate("conclusion_replay")
		_check(state.profile.progress.completed_missions.size() == 3, "Rejouer ne réinitialise rien avant la confirmation")
		await _activate("replay_confirm")
		await _frames(5)
		_check(state.profile.progress.completed_missions.size() == 3 and state.profile.progress.run_reward_points == 150 and state.profile.wallet.points == 150, "Rejouer conserve toutes les validations et les points")
		_check(app.demo.challenge.mission_id == "computer", "Seule la dernière mission est rouverte")
		await _press(KEY_ESCAPE)
		await _press(KEY_P)
		await _activate("pause_conclusion")
		await _activate("conclusion_menu")
	elif app.screen == "game":
		await _press(KEY_P)
		await _activate("pause_menu")


func _approach(mission_id: String) -> void:
	_check(is_instance_valid(app.demo) and is_instance_valid(app.demo.world), "Monde jouable présent pour " + mission_id)
	if not is_instance_valid(app.demo):
		return
	# Position setup does not bypass collision tests or any business validation.
	app.demo.world.player.position = app.demo.world.CHECKPOINTS[mission_id]
	await _physics_frames(3)
	await _frames(3)
	_check(app.demo.world.target_id == mission_id, "Cible proche cohérente : " + mission_id)


func _test_controller_loss() -> void:
	var game = app.demo
	var before: Vector2 = game.world.get_player_position()
	controllers.debug_connection_changed(1, true)
	await _frames(4)
	_check(controllers.active_device == 0, "Une deuxième manette ne remplace pas la manette active")
	await _joy_from_device(JOY_BUTTON_DPAD_RIGHT, 1)
	await _physics_frames(4)
	_check(game.world.get_player_position() == before, "Les commandes d'une manette secondaire ne déplacent pas le joueur")
	controllers.debug_connection_changed(1, false)
	await _frames(4)
	_check(not game.paused, "Débrancher une manette secondaire ne suspend pas le jeu")
	controllers.debug_connection_changed(0, false)
	await _frames(5)
	_check(game.paused and not game.overlay_kind.is_empty(), "Déconnexion de la manette active : pause explicite avec interface accessible")
	await _hold(KEY_RIGHT, 6)
	_check(game.world.get_player_position() == before, "Déconnexion : le personnage reste immobile derrière la pause")
	controllers.debug_connection_changed(0, true)
	await _frames(5)
	_check(game.paused, "Reconnexion : aucune reprise automatique du joueur")
	await _press(KEY_ESCAPE)
	_check(game.paused and game.overlay_kind == "controller_pause", "Échap ne reprend pas automatiquement après perte de manette")
	await _activate("controller_resume")
	_check(not game.paused, "Le clavier permet une reprise explicite après reconnexion")
	await _hold(KEY_RIGHT, 6)
	_check(game.world.get_player_position() != before, "La reprise restitue les déplacements clavier")
	game.world.player.position = game.world.CHECKPOINTS.entrance
	await _physics_frames(3)


func _test_diagnostics() -> void:
	if not OS.is_debug_build():
		return
	var origin: String = app.screen
	await _press(KEY_F3)
	_check(app.screen == "diagnostics", "F3 ouvre le diagnostic de développement")
	if app.screen != "diagnostics":
		return
	var back := _find(app, "diagnostics_back")
	_check(back != null, "Le diagnostic possède un retour accessible au clavier")
	var version := _find(app, "diagnostics_version") as Label
	_check(version != null and version.text.contains(Engine.get_version_info().string), "Le diagnostic affiche la version réelle du moteur")
	_check(_find(app, "diagnostics_controller") != null and _find(app, "diagnostics_error") != null, "Diagnostic : état du contrôleur et dernière erreur disponibles")
	await _press(KEY_ESCAPE)
	_check(app.screen == origin, "Retour du diagnostic restitue son écran parent")


func _test_controller_loss_in_quit_modal() -> void:
	root.close_requested.emit()
	await _frames(5)
	_check(is_instance_valid(app.modal), "La fermeture depuis l'enquête ouvre une confirmation globale")
	var overlay_before: String = app.demo.overlay_kind
	await _press(KEY_P)
	_check(is_instance_valid(app.modal) and app.demo.paused and app.demo.overlay_kind == overlay_before, "P ne reprend ni ne remplace le jeu derrière une confirmation globale")
	controllers.debug_connection_changed(0, false)
	await _frames(5)
	var owner: Control = root.gui_get_focus_owner()
	_check(is_instance_valid(app.modal) and owner != null and app.modal.is_ancestor_of(owner), "La perte de manette conserve le focus dans la confirmation globale")
	controllers.debug_connection_changed(0, true)
	await _press(KEY_ESCAPE)
	await _frames(5)
	_check(not is_instance_valid(app.modal) and app.demo.overlay_kind == "controller_pause" and app.demo.paused, "Annuler la fermeture après déconnexion affiche la suspension explicite")
	await _activate("controller_resume")
	_check(not app.demo.paused, "La reprise explicite reste possible après annulation de fermeture")


func _test_close_cancel() -> void:
	await _activate("home_settings")
	var before: Dictionary = settings.committed.duplicate(true)
	for step in range(7):
		if app.settings_category == 2:
			break
		await _press(KEY_E)
	await _activate("setting_reduce_transparency")
	var draft_before: Dictionary = app.draft_settings.duplicate(true)
	_check(settings.current != before, "La fermeture est testée avec un aperçu de paramètre réellement modifié")
	root.close_requested.emit()
	await _frames(5)
	_check(is_instance_valid(app.modal), "La fermeture de fenêtre avec paramètres ouverts demande une décision")
	_check(_find(app, "quit_keep") != null and _find(app, "quit_apply") != null and _find(app, "quit_discard") != null, "Fermer un brouillon propose conserver la session, appliquer ou abandonner")
	await _activate("quit_keep")
	_check(app.screen == "settings" and app.draft_settings == draft_before, "Annuler la fermeture conserve l'écran et le brouillon de paramètres")
	await _press(KEY_ESCAPE)
	_check(app.screen == "home" and settings.current == before, "Retour des paramètres restaure leur état enregistré après annulation de fermeture")
	saves.simulate_write_failure = true
	root.close_requested.emit()
	await _frames(5)
	_check(is_instance_valid(app.modal), "La fermeture avec profil actif reste confirmée")
	if is_instance_valid(app.modal):
		await _activate("modal_confirm")
		await _frames(6)
		_check(is_instance_valid(app) and app.screen == "home", "Échec de sauvegarde à la fermeture : l'application reste dans la session")
		_check(is_instance_valid(app.modal), "L'erreur de fermeture exige une action et ne disparaît pas en notification temporaire")
	saves.simulate_write_failure = false
	if is_instance_valid(app.modal):
		await _press(KEY_ESCAPE)
	await _frames(3)


func _solve_lighting(with_errors: bool) -> void:
	await _approach("lighting")
	await _joy(JOY_BUTTON_A)
	await _frames(4)
	_check(app.demo.overlay_kind == "challenge" and _find(app, "light_validate") != null, "Interaction ouvre le défi d'éclairage")
	_check(not state.profile.progress.completed_missions.has("lighting"), "L'appui d'ouverture ne valide pas le défi")
	var first_connection := _find(app, "light_connection_source_switch") as CheckButton
	_check(first_connection != null and not first_connection.button_pressed, "Le bouton de validation qui ouvre le défi ne coche pas sa première réponse")
	if _find(app, "light_validate") == null:
		return
	if with_errors:
		await _test_controller_loss_in_challenge()
	await _check_modal_navigation()
	if with_errors:
		await _activate("light_validate")
		_check(not state.profile.progress.completed_missions.has("lighting") and state.profile.wallet.points == 0, "Circuit incomplet refusé avec feedback, sans récompense")
		_check(not app.demo.challenge.feedback_label.text.is_empty(), "Une mauvaise configuration reçoit une explication")
	for connection in ["source_switch", "switch_lamp", "lamp_return"]:
		await _activate("light_connection_" + connection)
	if with_errors:
		saves.simulate_write_failure = true
		var old_profile: Dictionary = state.profile.duplicate(true)
		await _activate("light_validate")
		_check(state.profile == old_profile and app.demo.overlay_kind == "challenge", "Erreur d'écriture UI : mission et portefeuille inchangés, défi conservé")
		saves.simulate_write_failure = false
	await _activate("light_validate",false,0)
	await _burst(KEY_ENTER, 4)
	await _frames(4)
	_check(state.profile.progress.completed_missions.has("lighting") and app.demo.world.lighting_restored, "Boucle fermée réellement vérifiée : lumière restaurée et sauvegardée")
	await _activate("dialog_continue")
	await create_timer(0.22).timeout


func _test_controller_loss_in_challenge() -> void:
	var original_challenge = app.demo.challenge
	await _activate("light_connection_source_switch")
	var before: Vector2 = app.demo.world.get_player_position()
	controllers.debug_connection_changed(0, false)
	await _frames(5)
	_check(app.demo.overlay_kind == "controller_pause" and app.demo.paused, "Déconnexion pendant un défi : suspension explicite")
	_check(is_instance_valid(original_challenge), "La suspension conserve l'instance du défi et ses choix")
	await _hold(KEY_RIGHT, 6)
	_check(app.demo.world.get_player_position() == before, "Aucun déplacement derrière la suspension du défi")
	controllers.debug_connection_changed(0, true)
	await _frames(5)
	_check(app.demo.overlay_kind == "controller_pause", "La reconnexion ne ferme pas la suspension du défi")
	await _activate("controller_resume")
	_check(app.demo.overlay_kind == "challenge" and app.demo.challenge == original_challenge and app.demo.paused, "La reprise explicite restitue le même défi en bloquant l'exploration")
	var first := _find(app, "light_connection_source_switch") as CheckButton
	_check(first != null and first.button_pressed, "La liaison sélectionnée avant déconnexion reste cochée")
	await _activate("light_connection_source_switch")


func _solve_lock(with_errors: bool) -> void:
	await _approach("lock")
	await _press(KEY_SPACE)
	await _frames(4)
	_check(_find(app, "lock_validate") != null, "La lumière débloque le défi de la serrure")
	if _find(app, "lock_validate") == null:
		return
	if with_errors:
		_check(_find(app, "lock_diagnosis").disabled and _find(app, "lock_validate").disabled and not state.profile.progress.completed_missions.has("lock"), "Diagnostic indisponible avant consultation des observations")
	for observation in ["badge", "power", "command", "link"]:
		await _activate("observation_" + observation)
	if with_errors:
		await _choose_option("lock_diagnosis", "power_fault")
		await _choose_option("lock_repair", "replace_power")
		await _activate("lock_validate")
		_check(not state.profile.progress.completed_missions.has("lock") and not app.demo.world.door_open, "Mauvaise hypothèse d'alimentation refusée, porte encore fermée")
	await _choose_option("lock_diagnosis", "control_link")
	await _choose_option("lock_repair", "reconnect_control")
	await _activate("lock_validate")
	await _frames(4)
	_check(state.profile.progress.completed_missions.has("lock") and app.demo.world.door_open, "Bonne liaison de commande réparée : porte ouverte et mission enregistrée")
	await _activate("dialog_continue")
	await create_timer(0.22).timeout


func _solve_computer(with_errors: bool) -> void:
	await _approach("computer")
	await _press(KEY_SPACE)
	await _frames(4)
	_check(_find(app, "computer_validate") != null, "L'ouverture du bureau rend le diagnostic ordinateur jouable")
	if _find(app, "computer_validate") == null:
		return
	for observation in ["pc", "display", "no_signal"]:
		await _activate("observation_" + observation)
	if with_errors:
		_check(_find(app, "computer_cause").disabled and _find(app, "computer_validate").disabled and not state.profile.progress.completed_missions.has("computer"), "Cause indisponible avant vérifications")
	for check_id in ["power", "video"]:
		await _activate("computer_check_" + check_id)
	if with_errors:
		await _choose_option("computer_cause", "network_fault")
		await _choose_option("computer_correction", "reset_network")
		await _activate("computer_validate")
		_check(not state.profile.progress.completed_missions.has("computer") and not app.demo.world.computer_repaired, "Hypothèse réseau incorrecte refusée avec explication")
	await _choose_option("computer_cause", "video_disconnected")
	await _choose_option("computer_correction", "reconnect_video")
	await _activate("computer_validate")
	await _frames(4)
	_check(state.profile.progress.completed_missions.has("computer") and app.demo.world.computer_repaired, "Correction vidéo virtuelle : ordinateur réparé et mission enregistrée")
	await _activate("dialog_continue")
	await _frames(4)


func _return_and_continue(checkpoint: String) -> void:
	await _press(KEY_P)
	await _activate("pause_menu")
	await _frames(4)
	_check(app.screen == "home" and not _find(app, "continue_game").disabled, "Retour au menu après " + checkpoint + " conserve la reprise")
	await _activate("continue_game")
	await _frames(5)
	_check(app.screen == "game" and state.profile.progress.checkpoint_id == checkpoint, "Continuer charge le checkpoint " + checkpoint)
	_check(app.demo.world.lighting_restored and app.demo.world.door_open == (checkpoint == "lock"), "État physique restauré au checkpoint " + checkpoint)
	await create_timer(0.22).timeout


func _test_collisions(open_door: bool) -> void:
	var world = app.demo.world
	world.player.position = Vector2(575, 340)
	await _physics_frames(3)
	await _hold(KEY_RIGHT, 36)
	var final_position: Vector2 = world.get_player_position()
	_check(final_position.x > 640 if open_door else final_position.x < 619, "La porte est franchissable" if open_door else "La porte fermée bloque réellement le CharacterBody2D")
	if not open_door:
		world.player.position = Vector2(90, 430)
		await _physics_frames(3)
		await _hold(KEY_LEFT, 36)
		_check(world.get_player_position().x - world.player.get_child(0).shape.radius >= 44-.2, "Le personnage ne traverse pas le mur ouest")
		world.player.position = Vector2(323, 400)
		await _physics_frames(3)
		await _hold(KEY_UP, 36)
		_check(world.get_player_position().y - world.player.get_child(0).shape.radius >= 352-.2, "Le personnage ne traverse pas le mobilier")
	world.player.position = world.CHECKPOINTS.entrance if not open_door else world.CHECKPOINTS.lock
	await _physics_frames(3)


func _activate(wanted: String, with_joy: bool = false, settle_frames: int = 3) -> bool:
	var button := _find(app, wanted) as BaseButton
	_check(button != null and button.is_visible_in_tree() and not button.disabled, "Action native disponible : " + wanted)
	if button == null or button.disabled:
		return false
	button.grab_focus()
	await _frames(5)
	if with_joy:
		await _joy(JOY_BUTTON_A)
	else:
		await _press(KEY_ENTER,0 if settle_frames==0 else 2)
	await _frames(settle_frames)
	return true


func _choose_option(wanted: String, metadata: String) -> void:
	var option := _find(app, wanted) as OptionButton
	_check(option != null, "Choix navigable présent : " + wanted)
	if option == null:
		return
	var target := -1
	for index in range(option.item_count):
		if str(option.get_item_metadata(index)) == metadata:
			target = index
	_check(target >= 0, "Option de diagnostic disponible : " + metadata)
	if target < 0:
		return
	option.grab_focus()
	await _frames(5)
	await _press(KEY_ENTER)
	var popup := option.get_popup()
	_check(popup.visible, "Popup natif ouvert : " + wanted)
	for attempt in range(option.item_count + 2):
		if not popup.visible or popup.get_focused_item() == target:
			break
		await _press(KEY_DOWN)
	if popup.visible:
		await _press(KEY_ENTER)
	await _frames(3)
	_check(option.selected == target, "Choix validé au clavier : " + metadata)


func _check_modal_navigation() -> void:
	for key_code in [KEY_DOWN, KEY_UP, KEY_TAB, KEY_RIGHT, KEY_LEFT]:
		await _press(key_code)
		var owner: Control = root.gui_get_focus_owner()
		_check(owner != null and app.demo.modal_content.is_ancestor_of(owner), "Le défi capture la navigation native : " + OS.get_keycode_string(key_code))


func _hold(code: Key, physics_count: int) -> void:
	if not router.gameplay_allowed():
		await create_timer(0.22).timeout
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await _physics_frames(physics_count)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _physics_frames(2)


func _burst(code: Key, count: int) -> void:
	for index in range(count):
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = true
		Input.parse_input_event(event)
		event = event.duplicate()
		event.pressed = false
		Input.parse_input_event(event)
	await _frames(2)


func _physics_frames(count: int) -> void:
	for index in range(count):
		await physics_frame


func _test_shop_purchase() -> void:
	var opener := _find(app, "home_shop")
	_check(app.screen == "home" and opener != null, "Boutique accessible après les trois missions")
	if opener == null or app.screen != "home":
		return
	opener.grab_focus()
	await _press(KEY_ENTER)
	_check(app.screen == "shop", "Validation native ouvre la boutique avec les points gagnés")
	var product_id := "avatar_orbit"
	var product := _find(app, "product_" + product_id) as Button
	_check(product != null and product.text.begins_with("Acheter"), "Avatar Orbite proposé à l’achat")
	if product == null:
		return
	var price: int = shop.item(product_id).price
	var before_points: int = state.profile.wallet.points
	product.grab_focus()
	await _frames(4)
	await _joy(JOY_BUTTON_A)
	_check(is_instance_valid(app.modal), "Validation manette simulée demande confirmation de l’achat")
	var purchase_modal = app.modal
	await _burst(KEY_ENTER, 8)
	_check(is_instance_valid(app.modal) and app.modal == purchase_modal, "Achats rapides : une seule modale avant validation explicite")
	_check(state.profile.wallet.points == before_points and not state.profile.owned_items.has(product_id), "Aucun débit avant confirmation de l’achat")
	if not is_instance_valid(app.modal):
		return
	await _joy(JOY_BUTTON_DPAD_RIGHT)
	_check(root.gui_get_focus_owner() == _find(app, "modal_confirm"), "La croix sélectionne Acheter dans la confirmation")
	await _joy(JOY_BUTTON_A)
	await _burst(KEY_ENTER, 8)
	await _frames(4)
	_check(app.screen == "shop" and not is_instance_valid(app.modal), "La confirmation d’achat revient au catalogue")
	_check(state.profile.wallet.points == before_points - price and state.profile.owned_items.has(product_id), "Achat UI réussi : débit exact et article possédé")
	_check(state.profile.equipped.avatar == "avatar_default", "Une rafale de validation après l'achat n'équipe pas automatiquement l'objet")
	var purchased: Dictionary = saves.read_profile(state.profile.id)
	_check(purchased.ok and purchased.data.wallet.points == before_points - price and purchased.data.owned_items.has(product_id), "L’achat et le solde sont enregistrés ensemble sur disque")
	product = _find(app, "product_" + product_id) as Button
	_check(product != null and product.text.begins_with("Équiper"), "L’article acheté présente l’action Équiper")
	if product != null:
		product.grab_focus()
		await _frames(4)
		await _press(KEY_ENTER)
		_check(state.profile.equipped.avatar == product_id, "Équiper applique réellement l’avatar acheté")
		var equipped: Dictionary = saves.read_profile(state.profile.id)
		_check(equipped.ok and equipped.data.equipped.avatar == product_id, "L’avatar équipé reste enregistré dans le profil")
		var equipped_button := _find(app, "product_" + product_id) as Button
		_check(equipped_button != null and equipped_button.text.contains("Équipé"), "Le catalogue affiche l’état Équipé après sauvegarde")
	await _joy(JOY_BUTTON_B)
	_check(app.screen == "home" and root.gui_get_focus_owner() == _find(app, "home_shop"), "Retour de la boutique restaure le focus d’origine")


func _test_profile_isolation() -> void:
	if app.screen != "home":
		return
	var first_id: String = state.profile.id
	var first_snapshot: Dictionary = state.profile.duplicate(true)
	await _activate("home_profiles")
	await _activate("add_profile")
	await _frames(3)
	await _activate("key_B")
	await _activate("key_Valider")
	await _frames(4)
	_check(app.screen == "home" and state.profile.id != first_id, "Deuxième profil créé depuis l'interface")
	if state.profile.is_empty() or state.profile.id == first_id:
		return
	var second_id: String = state.profile.id
	_check(state.profile.wallet.points == 0 and not state.profile.owned_items.has("avatar_orbit") and state.profile.progress.completed_missions.is_empty(), "Nouveau joueur indépendant : aucun point, achat ou objectif du premier")
	await _activate("new_game")
	await _frames(4)
	await _approach("lighting")
	await _press(KEY_SPACE)
	await _frames(3)
	_check(_find(app, "light_validate") != null, "Le deuxième profil commence avec un vrai défi non résolu")
	await _press(KEY_ESCAPE)
	await _press(KEY_P)
	await _activate("pause_menu")
	await _activate("home_profiles")
	await _activate("select_" + first_id)
	_check(state.profile.id == first_id and state.profile.wallet.points == first_snapshot.wallet.points and state.profile.owned_items == first_snapshot.owned_items and state.profile.progress.completed_missions == first_snapshot.progress.completed_missions, "Changer de joueur restaure le portefeuille, l'inventaire et les trois missions du premier")
	_check(saves.read_profile(second_id).data.wallet.points == 0, "Changer de joueur n'accorde aucun point au deuxième profil")


func _setup_layout_progress(mission_id: String) -> void:
	_check(profiles.start_game().ok, "Nouvelle partie isolée pour la géométrie " + mission_id)
	if mission_id in ["lock", "computer", "conclusion"]:
		_check(investigation.begin_mission("lighting").ok and investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"]).ok, "Prérequis d'éclairage validé par le service pour la géométrie")
	if mission_id in ["computer", "conclusion"]:
		investigation.begin_mission("lock")
		for id in ["badge", "power", "command", "link"]:
			investigation.observe("lock", id)
		_check(investigation.submit_lock("control_link", "reconnect_control").ok, "Prérequis de serrure validé par le service pour la géométrie")
	if mission_id == "conclusion":
		investigation.begin_mission("computer")
		for id in ["pc", "display", "no_signal"]:
			investigation.observe("computer", id)
		for id in ["video", "power"]:
			investigation.check_computer(id)
		_check(investigation.submit_computer(["video", "power"], "video_disconnected", "reconnect_video").ok, "Diagnostic ordinateur validé par le service pour la géométrie")
	if is_instance_valid(app.demo):
		app.demo.queue_free()
		app.demo = null
	app._show_screen("game")
	await _frames(6)


func _test_game_layouts(window_size: Vector2i, large_text: bool) -> void:
	await _setup_layout_progress("lighting")
	await _check_focused_layout("game", window_size, large_text)
	await _capture("investigation_%dx%d_%s" % [window_size.x, window_size.y, "large_opaque" if large_text else "normal"])
	await _press(KEY_P)
	await _check_overlay_layout("pause", window_size, large_text)
	await _press(KEY_ESCAPE)
	await _approach("lock")
	await _press(KEY_SPACE)
	await _check_overlay_layout("locked_hint", window_size, large_text)
	await _press(KEY_ESCAPE)
	for mission_id in ["lighting", "lock", "computer"]:
		await _setup_layout_progress(mission_id)
		await _approach(mission_id)
		await _press(KEY_SPACE)
		await _frames(4)
		if mission_id == "lock":
			for id in ["badge", "power", "command", "link"]:
				await _activate("observation_" + id)
			await _choose_option("lock_diagnosis", "control_link")
			await _choose_option("lock_repair", "reconnect_control")
		elif mission_id == "computer":
			for id in ["pc", "display", "no_signal"]:
				await _activate("observation_" + id)
			for id in ["video", "power"]:
				await _activate("computer_check_" + id)
			await _choose_option("computer_cause", "video_disconnected")
			await _choose_option("computer_correction", "reconnect_video")
		if mission_id == "lighting":
			controllers.debug_connection_changed(0, false)
			await _frames(5)
			await _check_overlay_layout("controller_pause", window_size, large_text)
			controllers.debug_connection_changed(0, true)
			await _activate("controller_resume")
		await _check_overlay_layout("challenge/" + mission_id, window_size, large_text)
		await _capture("challenge_%s_%dx%d_%s" % [mission_id, window_size.x, window_size.y, "large_opaque" if large_text else "normal"])
		await _press(KEY_ESCAPE)
	await _setup_layout_progress("conclusion")
	await _check_overlay_layout("conclusion", window_size, large_text)
	await _activate("conclusion_replay")
	await _check_overlay_layout("replay_confirmation", window_size, large_text)
	await _capture("conclusion_replay_%dx%d_%s" % [window_size.x, window_size.y, "large_opaque" if large_text else "normal"])
	await _activate("replay_cancel")
	await _activate("conclusion_menu")


func _check_overlay_layout(screen_name: String, window_size: Vector2i, large_text: bool) -> void:
	await _frames(5)
	var focusables: Array = app._focusables(app.demo.modal_content)
	_check(not focusables.is_empty(), "Focus modal disponible : %s / %s / grand=%s" % [screen_name, window_size, large_text])
	for control in focusables:
		control.grab_focus()
		await _frames(5)
		var rect: Rect2 = control.get_global_rect()
		var visible_rect: Rect2 = app.demo._modal_scroll.get_global_rect()
		var visible: bool = rect.position.x >= visible_rect.position.x - 1 and rect.end.x <= visible_rect.end.x + 1 and rect.position.y >= visible_rect.position.y - 1 and rect.end.y <= visible_rect.end.y + 1
		var description := "%s/%s %s grand=%s" % [screen_name, control.name, window_size, large_text]
		if control is Button:
			_check(control.get_theme_font_size("font_size") == (22 if large_text else 18), "Taille de police réellement appliquée : " + description)
		_check(visible, "Contrôle modal focalisé visible : " + description)
		if not visible:
			layout_reports.append(description + " rect=" + str(rect) + " viewport=" + str(visible_rect))
		_check_button_text(control, description, rect)


func _check_button_text(control: Control, description: String, rect: Rect2) -> void:
	if not control is Button:
		return
	var font: Font = control.get_theme_font("font")
	var font_size: int = control.get_theme_font_size("font_size")
	var text_width := font.get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var style: StyleBox = control.get_theme_stylebox("normal")
	var available_width: float = rect.size.x - style.get_content_margin(SIDE_LEFT) - style.get_content_margin(SIDE_RIGHT)
	if control is CheckButton:
		available_width -= control.get_theme_icon("checked").get_width() + control.get_theme_constant("h_separation")
	elif control is OptionButton:
		available_width -= control.get_theme_icon("arrow").get_width() + control.get_theme_constant("arrow_margin")
	if text_width > available_width + 2:
		layout_reports.append(description + " texte « " + control.text + " » : " + str(text_width) + " > " + str(available_width))


func _test_layouts() -> void:
	# Scrolling is expected; a focused control must fit the visible scroll viewport.
	var original_settings: Dictionary = settings.committed.duplicate(true)
	for window_size in [Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(800, 480)]:
		root.size = window_size
		await _frames(5)
		for large_text in [false, true]:
			var preview: Dictionary = settings.committed.duplicate(true)
			preview.large_text = large_text
			preview.reduce_transparency = large_text
			preview.reduce_motion = true
			# These are genuinely applied modes, rather than a pending settings
			# draft that would correctly change the meaning of Quitter.
			_check(settings.apply_settings(preview).ok, "Mode de géométrie enregistré dans le dossier de test")
			var screens: Array[String] = ["home", "profiles", "shop", "help", "controls"]
			if OS.is_debug_build():
				screens.append("diagnostics")
			for screen in screens:
				app._show_screen(screen)
				await _frames(5)
				await _check_focused_layout(screen, window_size, large_text)
				if screen == "home" or window_size.x == 800:
					await _capture("%s_%dx%d_%s" % [screen, window_size.x, window_size.y, "large_opaque" if large_text else "normal"])
			app._show_screen("home")
			await _frames(5)
			await _activate("home_settings")
			await _activate("quit")
			await _check_confirmation_layout("quit", window_size, large_text)
			await _press(KEY_ESCAPE)
			await _activate("home_shop")
			await _activate("product_theme_sable")
			await _check_confirmation_layout("purchase", window_size, large_text)
			await _press(KEY_ESCAPE)
			await _press(KEY_ESCAPE)
			for category in range(8):
				app.settings_category = category
				app.settings_origin = "home"
				app.draft_settings = preview.duplicate(true)
				app._show_screen("settings")
				await _frames(5)
				await _check_focused_layout("settings/" + str(category), window_size, large_text)
				if window_size.x == 800 and category in [0, 2, 3]:
					await _capture("settings_%s_800x480_%s" % [category, "large_opaque" if large_text else "normal"])
			app.settings_category = 2
			app.draft_settings = preview.duplicate(true)
			app._show_screen("settings")
			await _frames(5)
			await _activate("setting_reduce_transparency")
			root.close_requested.emit()
			await _frames(5)
			await _check_confirmation_layout("dirty_quit", window_size, large_text)
			await _activate("quit_keep")
			settings.preview(preview)
			app._open_editor(state.profile.id)
			await _frames(5)
			await _check_focused_layout("editor", window_size, large_text)
			if window_size.x == 800:
				await _capture("profile_editor_800x480_" + ("large_opaque" if large_text else "normal"))
			await _test_game_layouts(window_size, large_text)
			app._show_screen("home")
	for detail in layout_reports:
		printerr("DÉTAIL LAYOUT : ", detail)
	_check(layout_reports.is_empty(), "Aucun contrôle hors largeur ni texte essentiel de bouton tronqué aux trois résolutions et deux modes")
	_check(settings.apply_settings(original_settings).ok, "Réglages de la recette restaurés après la matrice")
	root.size = Vector2i(1280, 720)


func _check_confirmation_layout(screen_name: String, window_size: Vector2i, large_text: bool) -> void:
	_check(is_instance_valid(app.modal), "Confirmation présente pour la géométrie : " + screen_name)
	if not is_instance_valid(app.modal):
		return
	for control in app._focusables(app.modal):
		control.grab_focus()
		await _frames(5)
		var rect: Rect2 = control.get_global_rect()
		var visible_rect := Rect2(Vector2.ZERO, Vector2(window_size))
		var visible := visible_rect.encloses(rect)
		var label := "confirmation/%s/%s %s grand=%s" % [screen_name, control.name, window_size, large_text]
		_check(visible, "Bouton de confirmation focalisé visible : " + label)
		if not visible:
			layout_reports.append(label + " rect=" + str(rect) + " viewport=" + str(visible_rect))
		_check_button_text(control, label, rect)


func _check_focused_layout(screen: String, window_size: Vector2i, large_text: bool) -> void:
	var focusables: Array = app._focusables(app.content)
	_check(not focusables.is_empty(), "Focus initial disponible : %s / %s / grand=%s" % [screen, window_size, large_text])
	for control in focusables:
		control.grab_focus()
		await _frames(5)
		var rect: Rect2 = control.get_global_rect()
		var visible_rect: Rect2 = app.scroll.get_global_rect()
		var horizontally_visible: bool = rect.position.x >= visible_rect.position.x - 1 and rect.end.x <= visible_rect.end.x + 1
		var vertically_visible: bool = rect.position.y >= visible_rect.position.y - 1 and rect.end.y <= visible_rect.end.y + 1
		var label := "%s/%s %s grand=%s" % [screen, control.name, window_size, large_text]
		_check(horizontally_visible and vertically_visible, "Contrôle focalisé visible : " + label)
		if not horizontally_visible or not vertically_visible:
			layout_reports.append(label + " rect=" + str(rect) + " visible=" + str(visible_rect) + " scroll_y=" + str(app.scroll.scroll_vertical) + " focused=" + str(root.gui_get_focus_owner() == control))
		if control is Button:
			var font: Font = control.get_theme_font("font")
			var font_size: int = control.get_theme_font_size("font_size")
			var text_width := font.get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var style: StyleBox = control.get_theme_stylebox("normal")
			var available_width: float = rect.size.x - style.get_content_margin(SIDE_LEFT) - style.get_content_margin(SIDE_RIGHT)
			if control is CheckButton:
				available_width -= control.get_theme_icon("checked").get_width() + control.get_theme_constant("h_separation")
			elif control is OptionButton:
				available_width -= control.get_theme_icon("arrow").get_width() + control.get_theme_constant("arrow_margin")
			if text_width > available_width + 2:
				layout_reports.append(label + " texte « " + control.text + " » : " + str(text_width) + " > " + str(available_width))
	# Capture the start of the actual screen, keeping a first control in view.
	if not focusables.is_empty():
		focusables[0].grab_focus()
		app.scroll.scroll_vertical = 0
		await _frames(3)


func _find(node: Node, wanted: String) -> Control:
	if node is Control and String(node.name) == wanted:
		return node
	for child in node.get_children():
		var found := _find(child, wanted)
		if found != null:
			return found
	return null


func _button_with_text(node: Node, wanted: String) -> Button:
	if node is Button and node.text == wanted:
		return node
	for child in node.get_children():
		var found := _button_with_text(child, wanted)
		if found != null:
			return found
	return null


func _press(code: Key, settle_frames: int = 2) -> void:
	if not router.gameplay_allowed():
		await create_timer(0.22).timeout
	var event := InputEventKey.new()
	event.keycode = code
	event.unicode = int(code) if int(code) >= 32 and int(code) <= 126 else 0
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	# Deliver the release through the native GUI queue before inspecting callbacks.
	await _frames(maxi(1,settle_frames))


func _joy(button_index: JoyButton) -> void:
	await _joy_from_device(button_index, 0)


func _joy_from_device(button_index: JoyButton, device_id: int) -> void:
	if not router.gameplay_allowed():
		await create_timer(0.22).timeout
	var event := InputEventJoypadButton.new()
	event.device = device_id
	event.button_index = button_index
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(3)


func _joy_axis(axis_index: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis_index
	event.axis_value = value
	Input.parse_input_event(event)
	await _frames(3)


func _capture(file_name: String) -> void:
	if not captures:
		return
	await _frames(3)
	await RenderingServer.frame_post_draw
	var rendered: Image = root.get_texture().get_image()
	if rendered == null or rendered.is_empty():
		_check(false, "Texture réellement rendue pour " + file_name)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots"))
	var result := rendered.save_png("res://docs/screenshots/" + file_name + ".png")
	_check(result == OK, "Capture réelle enregistrée : " + file_name)


func _frames(count: int) -> void:
	for index in range(count):
		await process_frame


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		printerr("ÉCHEC UI : ", description)


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
	if is_instance_valid(app):
		root.remove_child(app)
		app.queue_free()
	await process_frame
	if controllers != null:
		controllers.debug_clear_devices()
	_remove_tree(test_root)
	print("UI : %s assertions, %s échec(s)." % [checks, failures.size()])
	print("Manette physique non testée : événements InputEventJoypadButton injectés uniquement.")
	print("Contrôleur USB HID fabriqué et performances Raspberry Pi : mesures à réaliser sur le vrai matériel.")
	# Release Dummy audio playback before shutting down the graphical fixture.
	for player in [settings._music_player,settings._effect_player] if settings!=null else []:
		if is_instance_valid(player):player.stop();player.stream=null
	await _frames(5)
	quit(0 if failures.is_empty() else 1)
