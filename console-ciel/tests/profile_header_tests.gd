extends SceneTree
## Native header placement and real player updates with isolated local data.
const LocalAvatars := preload("res://scripts/services/local_avatar_library.gd")
const DESTINATIONS := ["home", "shop", "settings", "profiles", "game"]
const LABELS := ["Accueil", "Boutique", "Paramètres", "Profil"]

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
var test_root := ""
var image_path := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	settings = root.get_node("SettingsService")
	state = root.get_node("AppState")
	shop = root.get_node("ShopService")
	investigation = root.get_node("InvestigationService")
	router = root.get_node("SceneRouter")
	root.get_node("ControllerService").debug_set_devices([0])
	if DisplayServer.get_name() != "headless":
		Input.use_accumulated_input = false
	test_root = "user://tests/profile_header_%s_%s" % [Time.get_ticks_usec(), OS.get_process_id()]
	saves.root_path = test_root.path_join("saves")
	settings.storage_root = test_root.path_join("settings")
	image_path = test_root.path_join("images")
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(image_path)) == OK, "Only an isolated image directory is created")
	var image := Image.create(180, 110, false, Image.FORMAT_RGB8)
	image.fill(Color("#648897"))
	_check(image.save_png(image_path.path_join("portrait.png")) == OK, "The local portrait fixture is written")
	LocalAvatars.directories_override = [image_path]
	LocalAvatars.refresh()
	state.clear_profile()
	root.size = Vector2i(1280, 720)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await _frames(35)
	_check(not app.header_player.visible, "An empty session does not show stale player information")
	var created: Dictionary = profiles.create_profile("WWWWWWWWWWWWWWWW", "avatar_default", "portrait.png")
	_check(created.ok, "A maximum-width name and a real local photo are saved")
	if created.ok:
		_check(profiles.start_game().ok, "The saved investigation is available for game header checks")
		await _test_updates(created.data.id)
		await _test_geometry()
		await _test_navigation()
	await _finish()


func _test_updates(first_id: String) -> void:
	app._show_screen("home")
	await _frames()
	_check_identity("initial local portrait")
	_check(app.header_avatar.local_image == "portrait.png" and app.header_avatar.image_texture is Texture2D, "The header really decodes the selected local portrait")
	_check(investigation.begin_mission("lighting").ok and investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"]).ok, "A real educational mission earns points")
	await _frames()
	_check(state.profile.wallet.points == 50 and app.header_points.text == "50 pts", "An earned reward immediately updates the top-left balance")
	_check(shop.purchase("avatar_orbit").ok, "A cosmetic purchase uses earned points")
	await _frames()
	_check(state.profile.wallet.points == 30 and app.header_points.text == "30 pts", "A successful purchase immediately updates the header balance")
	var before: Dictionary = state.profile.duplicate(true)
	_check(not shop.purchase("game_test_1").ok, "The actual higher-priced game is refused when funds are insufficient")
	await _frames()
	_check(state.profile == before and app.header_points.text == "30 pts", "A refused purchase keeps the visible balance and saved profile")
	_check(shop.equip("avatar_orbit").ok and shop.purchase("frame_round").ok and shop.equip("frame_round").ok, "Purchased avatar and frame are really equipped")
	await _frames()
	_check_identity("after equipment")
	_check(app.header_avatar.local_image.is_empty() and app.header_avatar.image_texture == null, "Choosing an equipped catalog avatar replaces the former photo in the header")
	var equipped: Dictionary = state.profile.duplicate(true)
	var second: Dictionary = profiles.create_profile("Autre joueur")
	_check(second.ok, "A second isolated profile is created")
	await _frames()
	_check_identity("second player")
	_check(app.header_profile.text == "Autre joueur" and app.header_points.text == "0 pts", "Switching to another player replaces both identity and wallet")
	_check(profiles.select_profile(first_id).ok and state.profile == equipped, "Selecting the first saved player restores its actual equipment and wallet")
	await _frames()
	_check_identity("saved player selected again")
	_check(profiles.update_profile("WWWWWWWWWWWWWWWW", "avatar_orbit", "portrait.png").ok, "The saved profile selects its local portrait again")
	await _frames()
	_check(app.header_avatar.image_texture is Texture2D and app.header_avatar.local_image == "portrait.png", "Editing the local photo immediately updates the header")
	var large_wallet: Dictionary = state.profile.duplicate(true)
	large_wallet.wallet.points = saves.MAX_POINTS
	var saved: Dictionary = saves.write_profile(large_wallet)
	_check(saved.ok, "Only the isolated geometry fixture receives the maximum supported balance")
	if saved.ok:
		state.commit_profile(saved.data)
	await _frames()
	_check_identity("maximum supported balance")
	_check(app.header_points.text == "2147483647 pts", "The header preserves the complete supported balance")


func _test_geometry() -> void:
	var saved_profile: Dictionary = state.profile.duplicate(true)
	for resolution in [Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(800, 480)]:
		root.size = resolution
		await _frames()
		for large in [false, true]:
			for style in ["nuit", "sable"]:
				var values: Dictionary = settings.defaults.duplicate(true)
				values.large_text = large
				values.reduce_motion = true
				values.appearance_style = style
				_check(settings.preview(values).ok, "Preview the actual theme at %s large=%s %s" % [resolution, large, style])
				for destination in DESTINATIONS:
					app.draft_settings = values.duplicate(true)
					app.settings_origin = "home"
					app._show_screen(destination)
					await _frames(8)
					_check_geometry(resolution, "%s large=%s %s %s" % [resolution, large, style, destination])
				app._open_editor(state.profile.id)
				await _frames(8)
				_check_geometry(resolution, "%s large=%s %s editor" % [resolution, large, style])
	_check(state.profile == saved_profile and saves.read_profile(saved_profile.id).data == saved_profile, "Layout and theme checks preserve the real saved player")
	settings.cancel_preview()


func _check_geometry(resolution: Vector2i, context: String) -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(resolution))
	var player: Rect2 = app.header_player.get_global_rect()
	var header: Rect2 = app.header_player.get_parent().get_global_rect()
	var brand: Rect2 = app.header_brand.get_global_rect()
	_check_identity(context)
	_check(bounds.encloses(header) and header.encloses(player), "The complete header and identity fit inside the viewport: " + context)
	_check(absf(player.position.x - header.position.x) <= .5 and player.position.y < resolution.y * .15, "The actual player group starts at the top-left of the shell: " + context)
	_check(player.encloses(app.header_avatar.get_global_rect()) and player.encloses(app.header_profile.get_global_rect()) and player.encloses(app.header_points.get_global_rect()), "Avatar, nickname and points stay inside the identity: " + context)
	_check(app.header_avatar.get_global_rect().end.x <= app.header_profile.get_global_rect().position.x + .5, "The avatar sits before the identity column without overlap: " + context)
	_check(app.header_profile.get_global_rect().end.y <= app.header_points.get_global_rect().position.y + .5, "The points sit below the nickname without overlap: " + context)
	_check(player.end.x <= brand.position.x + .5 and bounds.encloses(brand), "The brand remains to the right without covering player information: " + context)
	_check(app.scroll.get_global_rect().position.y >= header.end.y - .5, "The game or menu begins below the header: " + context)
	_check_text(app.header_profile, true, "Long nickname: " + context)
	_check_text(app.header_points, false, "Maximum wallet: " + context)
	_check_text(app.header_brand, false, "Brand: " + context)
	_check(app.header_profile.get_theme_color("font_color") == Color(app.background_palette.foreground), "Nickname inherits the selected theme foreground: " + context)
	if app.header_back.visible:
		_check(bounds.encloses(app.header_back.get_global_rect()) and brand.end.x <= app.header_back.get_global_rect().position.x + .5, "The return button remains accessible beside the brand: " + context)
	if app.navigation.visible:
		var nav = app.navigation
		_check(not nav.profile_name_label.is_visible_in_tree() and not nav.profile_points_label.is_visible_in_tree(), "The bottom navigation has no duplicate nickname or balance: " + context)
		for index in range(nav.buttons.size()):
			var button_rect: Rect2 = nav.buttons[index].get_global_rect()
			_check(absf(button_rect.size.x - nav.buttons[0].size.x) <= 1.0, "All four tabs have the same width: " + LABELS[index] + " " + context)
			var label: Label = nav.destination_labels[index]
			_check(label.text == LABELS[index] and label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and button_rect.encloses(label.get_global_rect()), "Every destination uses its own centered label: " + context)
			_check_text(label, false, LABELS[index] + ": " + context)
	else:
		_check(app.screen in ["game", "editor"], "Gameplay and editing keep their independent navigation mode: " + context)


func _check_identity(context: String) -> void:
	_check(app.header_player.name == "header_player" and app.header_avatar.name == "header_avatar" and app.header_profile.name == "header_profile" and app.header_points.name == "header_points" and app.header_brand.name == "header_brand", "Header controls retain stable identifiers: " + context)
	_check(app.header_player.is_visible_in_tree() and app.header_avatar.is_visible_in_tree() and app.header_profile.is_visible_in_tree() and app.header_points.is_visible_in_tree(), "The active player is visible in the top header: " + context)
	_check(app.header_profile.text == state.profile.display_name and app.header_profile.tooltip_text == state.profile.display_name, "The real nickname and its complete tooltip are updated: " + context)
	_check(app.header_points.text == "%d pts" % state.profile.wallet.points, "The actual wallet is updated: " + context)
	var avatar: Dictionary = shop.item(state.profile.equipped.avatar)
	_check(app.header_avatar.color == Color(avatar.color) and app.header_avatar.frame == state.profile.equipped.frame and app.header_avatar.frame_spec == shop.item(state.profile.equipped.frame), "The actual equipped avatar and frame are updated: " + context)


func _check_text(label: Label, allow_ellipsis: bool, message: String) -> void:
	var width: float = label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
	var full_tooltip := allow_ellipsis and label.clip_text and label.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS and label.tooltip_text == label.text
	_check(label.is_visible_in_tree() and (width <= label.size.x + .5 or full_tooltip), "Text fits, or the complete nickname remains accessible: " + message)


func _test_navigation() -> void:
	root.size = Vector2i(1280, 720)
	app._show_screen("home")
	await _frames(8)
	app.navigation.buttons[1].grab_focus()
	await _key(KEY_ENTER)
	_check(app.screen == "shop", "The existing Boutique tab still activates with the keyboard")
	await _key(KEY_ESCAPE)
	_check(app.screen == "home" and root.gui_get_focus_owner() == app.navigation.buttons[1], "Returning still restores the selected tab focus")
	app.navigation.buttons[0].grab_focus()
	await _key(KEY_LEFT)
	_check(root.gui_get_focus_owner() == app.navigation.buttons[3], "The four destinations still loop with the keyboard")
	var event := InputEventJoypadButton.new()
	if not router.gameplay_allowed():
		await create_timer(.23).timeout
	event.device = 0
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	await _frames()
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(8)
	_check(app.screen == "profiles", "The top-left identity keeps controller activation of Profil working")
	state.clear_profile()
	await _frames()
	_check(not app.header_player.visible and app.header_profile.text.is_empty() and app.header_points.text.is_empty(), "Clearing the active profile removes former personal data from the header")


func _key(code: Key) -> void:
	if not router.gameplay_allowed():
		await create_timer(.23).timeout
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(6)


func _frames(count: int = 5) -> void:
	for _index in range(count):
		await process_frame


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("PROFILE_HEADER_FAIL: " + message)


func _finish() -> void:
	saves.simulate_write_failure = false
	settings.cancel_preview()
	state.clear_profile()
	settings.stop_music()
	if is_instance_valid(settings._effect_player):
		settings._effect_player.stop()
	if is_instance_valid(app):
		root.remove_child(app)
		app.queue_free()
	await _frames(5)
	LocalAvatars.directories_override = []
	LocalAvatars.refresh()
	_remove_tree(test_root)
	print("PROFILE_HEADER : %d assertions, %d échec(s)." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _remove_tree(path: String) -> void:
	if not path.begins_with("user://tests/profile_header_"):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for filename in directory.get_files():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path.path_join(filename)))
	for folder in directory.get_directories():
		_remove_tree(path.path_join(folder))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
