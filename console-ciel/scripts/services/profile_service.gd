extends Node

const LocalAvatarLibrary := preload("res://scripts/services/local_avatar_library.gd")

signal profiles_changed(profiles: Array)
var profiles: Array = []
var issues: Array = []
var last_profile_id: String = ""

func refresh() -> Dictionary:
	var result := SaveService.list_profiles()
	if not result.ok:
		return result
	profiles = result.data.duplicate(true)
	issues = result.get("issues", []).duplicate(true)
	var session := SaveService.read_session()
	last_profile_id = session.data if session.ok else ""
	if not session.ok:
		issues.append({"id": "", "path": "session.json", "error": session.error, "has_backup": SaveService.session_backup_available()})
	profiles_changed.emit(profiles.duplicate(true))
	var response := SaveService._ok(profiles.duplicate(true))
	response["issues"] = issues.duplicate(true)
	return response

func _new_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()

func _empty_progress() -> Dictionary:
	return SaveService.empty_investigation_progress()

func create_profile(display_name: String, avatar_id: String = "avatar_default", avatar_image: String = "") -> Dictionary:
	var name := SaveService.validate_display_name(display_name)
	if not name.ok:
		return name
	var avatar := ShopService.item(avatar_id)
	if avatar.is_empty() or avatar.type != "avatar" or int(avatar.price) != 0:
		return SaveService._fail("Choisissez un avatar gratuit pour créer le profil.")
	if not avatar_image.is_empty() and (not LocalAvatarLibrary.is_safe_filename(avatar_image) or LocalAvatarLibrary.texture_for(avatar_image) == null):
		return SaveService._fail("Choisissez une image locale valide dans le dossier images_profil.")
	var id := _new_id()
	while FileAccess.file_exists(SaveService._path("profiles/%s.json" % id)):
		id = _new_id()
	var document := {
		"schema_version": SaveService.SCHEMA_VERSION, "id": id, "display_name": name.data,
		"wallet": {"points": 0}, "owned_items": SaveService.DEFAULT_ITEMS.duplicate(),
		"equipped": {"avatar": avatar_id, "theme": "theme_brume", "frame": "frame_default"},
		"rewarded_missions": [], "progress": _empty_progress()
	}
	if avatar_id not in document.owned_items:
		document.owned_items.append(avatar_id)
	if not avatar_image.is_empty():
		document["avatar_image"] = avatar_image
	var saved := SaveService.write_profile(document)
	if not saved.ok:
		return saved
	# La création reste présente si la session n'a pu être enregistrée ; elle n'est pas effacée.
	var session := SaveService.write_session(id)
	refresh()
	if not session.ok:
		return SaveService._fail("Le profil a été créé, mais sa sélection n'a pas été enregistrée : " + session.error, saved.data)
	AppState.set_profile(saved.data)
	last_profile_id = id
	return SaveService._ok(saved.data)

func select_profile(id: String) -> Dictionary:
	var current := save_active()
	if not current.ok:
		return current
	var loaded := SaveService.read_profile(id)
	if not loaded.ok:
		return loaded
	# Migration explicite à la sélection : l'ancien document reste dans .bak.
	# La notice reste disponible jusqu'à son acquittement par l'interface.
	if loaded.get("migration_required", false):
		var migrated := SaveService.write_profile(loaded.data)
		if not migrated.ok:
			return SaveService._fail("Impossible d'enregistrer la migration du prototype : " + migrated.error)
		loaded.data = migrated.data
	var session := SaveService.write_session(id)
	if not session.ok:
		return session
	AppState.set_profile(loaded.data)
	last_profile_id = id
	return loaded

func update_profile(display_name: String, avatar_id: String, avatar_image: String = "") -> Dictionary:
	if AppState.profile.is_empty():
		return SaveService._fail("Aucun profil actif.")
	var name := SaveService.validate_display_name(display_name)
	if not name.ok:
		return name
	var avatar := ShopService.item(avatar_id)
	if avatar.is_empty() or avatar.type != "avatar" or avatar_id not in AppState.profile.owned_items:
		return SaveService._fail("Cet avatar n'est pas possédé.")
	if not avatar_image.is_empty():
		if not LocalAvatarLibrary.is_safe_filename(avatar_image):
			return SaveService._fail("Le nom de l'image de profil locale est invalide.")
		# Un renommage garde une référence existante même si l'image a été retirée.
		# Une nouvelle sélection doit en revanche pouvoir être réellement décodée.
		if avatar_image != AppState.profile.get("avatar_image", "") and LocalAvatarLibrary.texture_for(avatar_image) == null:
			return SaveService._fail("Choisissez une image locale valide dans le dossier images_profil.")
	var document: Dictionary = AppState.profile.duplicate(true)
	document.display_name = name.data
	document.equipped.avatar = avatar_id
	if avatar_image.is_empty():
		document.erase("avatar_image")
	else:
		document["avatar_image"] = avatar_image
	var saved := SaveService.write_profile(document)
	if not saved.ok:
		return saved
	AppState.commit_profile(saved.data)
	refresh()
	return saved

func delete_profile(id: String) -> Dictionary:
	var old_session := SaveService.read_session()
	if not old_session.ok:
		return old_session
	var deleting_active: bool = not AppState.profile.is_empty() and AppState.profile.id == id
	if old_session.data == id:
		var session := SaveService.write_session("")
		if not session.ok:
			return session
	var deleted := SaveService.delete_profile(id)
	if not deleted.ok:
		if old_session.data == id:
			SaveService.write_session(id)
		return deleted
	if deleting_active:
		AppState.clear_profile()
	refresh()
	return SaveService._ok()

func start_game() -> Dictionary:
	if AppState.profile.is_empty():
		return SaveService._fail("Aucun profil actif.")
	var document: Dictionary = AppState.profile.duplicate(true)
	document.progress = _empty_progress()
	document.progress.started = true
	var saved := SaveService.write_profile(document)
	if not saved.ok:
		return saved
	AppState.commit_profile(saved.data)
	return saved

func reset_progress() -> Dictionary:
	if AppState.profile.is_empty():
		return SaveService._fail("Aucun profil actif.")
	var document: Dictionary = AppState.profile.duplicate(true)
	document.progress = _empty_progress()
	var saved := SaveService.write_profile(document)
	if not saved.ok:
		return saved
	AppState.commit_profile(saved.data)
	return saved

func save_active() -> Dictionary:
	if AppState.profile.is_empty():
		return SaveService._ok()
	return SaveService.write_profile(AppState.profile)

func recover(id: String) -> Dictionary:
	var recovered := SaveService.recover_profile(id)
	if recovered.ok:
		refresh()
		if not AppState.profile.is_empty() and AppState.profile.id == id:
			AppState.commit_profile(recovered.data)
	return recovered

func quarantine(id: String) -> Dictionary:
	var result := SaveService.quarantine_profile(id)
	if result.ok:
		if not AppState.profile.is_empty() and AppState.profile.id == id:
			AppState.clear_profile()
		refresh()
	return result
