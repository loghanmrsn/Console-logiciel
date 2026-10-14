extends SceneTree
## Images et profils locaux : toutes les écritures restent dans user://tests/.
## Run: godot --headless --path . --script res://tests/local_avatar_tests.gd

const Library := preload("res://scripts/services/local_avatar_library.gd")

var checks := 0
var failures: Array[String] = []
var test_root := ""
var images_path := ""
var saves
var profiles
var state
var shop


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	state = root.get_node("AppState")
	shop = root.get_node("ShopService")
	test_root = "user://tests/local_avatars_%s_%s" % [Time.get_ticks_usec(), OS.get_process_id()]
	images_path = test_root.path_join("images")
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(images_path)) == OK, "Créer uniquement le dossier d'images temporaire")
	Library.directories_override = [images_path]
	Library.refresh()
	saves.root_path = test_root.path_join("saves")
	state.clear_profile()
	_check(shop.load_catalog().ok, "Catalogue livré chargé sans modification")
	_test_filenames()
	_test_scan()
	_test_profiles()
	_test_removed_image()
	_test_missing_folder()
	saves.simulate_write_failure = false
	state.clear_profile()
	Library.directories_override = []
	Library.refresh()
	_remove_tree(test_root)
	print("AVATARS LOCAUX : %d assertions, %d échec(s)." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _test_filenames() -> void:
	for filename in ["photo.png", "été 2026.JPEG", "Mon_avatar.WEBP", "simple.jpg"]:
		_check(Library.is_safe_filename(filename), "Nom local sûr accepté : " + filename)
	for filename in [null, 42, [], {}, "", ".hidden.png", "../photo.png", "sub/photo.png", "sub\\photo.png", "https://site/photo.png", "file:///tmp/photo.png", "/tmp/photo.png", "C:\\photo.png", "../..", "photo.svg", "photo.gif", "photo.png ", " photo.png", "photo.png\n", "a?b.png", "a*b.jpg", "CON.png", "CON.photo.png", "lpt9.JPEG", "bad\u0001.png", "x".repeat(252) + ".png"]:
		_check(not Library.is_safe_filename(filename), "Nom/type interdit refusé : " + JSON.stringify(filename))
	_check(Library.folder_path() == images_path, "Le test utilise un seul dossier explicitement isolé")
	_check(Library.texture_for("../photo.png") == null, "Aucun chargement par traversée de chemin")


func _test_scan() -> void:
	var image := Image.create(512, 300, false, Image.FORMAT_RGB8)
	image.fill(Color(0.2, 0.6, 0.9))
	_check(image.save_png(images_path.path_join("bleu.png")) == OK, "Fixture PNG créée localement")
	_check(image.save_jpg(images_path.path_join("Photo.JPG")) == OK, "Fixture JPG majuscule créée localement")
	_check(image.save_jpg(images_path.path_join("Portrait.jpeg")) == OK, "Fixture JPEG créée localement")
	_check(image.save_webp(images_path.path_join("profil.WEBP")) == OK, "Fixture WebP créée localement")
	_write_raw(images_path.path_join("invalide.png"), "Ce texte n'est pas une image.")
	_write_raw(images_path.path_join("unsupported.svg"), "<svg></svg>")
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(images_path.path_join("nested"))) == OK, "Sous-dossier de test préparé")
	_check(image.save_png(images_path.path_join("nested/cache.png")) == OK, "Image imbriquée de test créée")
	var enormous := image.save_png_to_buffer()
	# Dimensions PNG falsifiées à 65536 : refus avant tout décodage/allocation.
	enormous[16] = 0
	enormous[17] = 1
	enormous[18] = 0
	enormous[19] = 0
	_write_bytes(images_path.path_join("trop_grande.png"), enormous)
	var oversized := PackedByteArray()
	oversized.resize(Library.MAX_FILE_BYTES + 1)
	_write_bytes(images_path.path_join("trop_lourde.png"), oversized)
	var filenames: Array[String] = []
	for entry in Library.list_images():
		filenames.append(entry.filename)
		_check(entry.name is String and entry.texture is Texture2D, "Entrée prête pour l'aperçu : " + entry.filename)
		_check(entry.texture.get_width() <= Library.THUMBNAIL_EDGE and entry.texture.get_height() <= Library.THUMBNAIL_EDGE, "Vignette bornée : " + entry.filename)
	_check(filenames.size() == 4, "Seules les quatre images directes valides sont proposées")
	for filename in ["bleu.png", "Photo.JPG", "Portrait.jpeg", "profil.WEBP"]:
		_check(filename in filenames and Library.texture_for(filename) != null, "Format réellement décodé : " + filename)
	for filename in ["invalide.png", "trop_grande.png", "trop_lourde.png", "unsupported.svg", "nested/cache.png"]:
		_check(Library.texture_for(filename) == null, "Fichier invalide, démesuré ou imbriqué ignoré : " + filename)
	var first := Library.texture_for("bleu.png")
	_check(first == Library.texture_for("bleu.png"), "Les aperçus identiques réutilisent la vignette en cache")
	Library.refresh()
	_check(Library.texture_for("bleu.png") != null and Library.texture_for("bleu.png") != first, "Actualiser relit l'image au lieu d'utiliser l'ancien cache")
	var absolute_source := ProjectSettings.globalize_path(images_path.path_join("bleu.png"))
	var absolute_link := ProjectSettings.globalize_path(images_path.path_join("lien.png"))
	var directory := DirAccess.open(images_path)
	if directory.create_link(absolute_source, absolute_link) == OK:
		_check(Library.texture_for("lien.png") == null, "Une image liée symboliquement n'est jamais chargée")
		_check(not _contains_filename(Library.list_images(), "lien.png"), "Le lien symbolique est absent du sélecteur")
	else:
		print("  Liens symboliques indisponibles sur cette plateforme : contrôle de lien non exécuté.")


func _test_profiles() -> void:
	var created: Dictionary = profiles.create_profile("Alice locale", "avatar_default", "bleu.png")
	if not _succeeds(created, "Créer un profil avec image personnelle"):
		return
	var first_id: String = created.data.id
	var initial: Dictionary = created.data.duplicate(true)
	_check(initial.get("avatar_image") == "bleu.png", "Seul le nom simple de l'image est enregistré")
	_check(initial.schema_version == 1 and initial.equipped.avatar == "avatar_default", "Schéma et avatar de repli du catalogue restent inchangés")
	_check(initial.wallet.points == 0 and initial.owned_items == saves.DEFAULT_ITEMS, "Une image personnelle ne coûte rien et n'ajoute aucun article")
	_check(saves.read_profile(first_id).data == initial, "Image personnelle et profil survivent à une lecture disque")
	var legacy: Dictionary = initial.duplicate(true)
	legacy.erase("avatar_image")
	_check(saves.validate_profile(legacy).ok, "Ancien document sans champ avatar_image accepté")
	var empty: Dictionary = initial.duplicate(true)
	empty.avatar_image = ""
	_check(saves.validate_profile(empty).ok, "Champ facultatif vide accepté")
	var missing: Dictionary = initial.duplicate(true)
	missing.avatar_image = "absente.png"
	_check(saves.validate_profile(missing).ok, "Image absente ne rend pas la sauvegarde invalide")
	for value in [42, null, [], "../bleu.png", "https://site/photo.png", "photo.gif"]:
		var invalid: Dictionary = initial.duplicate(true)
		invalid.avatar_image = value
		_check(not saves.validate_profile(invalid).ok, "Référence d'image invalide refusée dans le document : " + JSON.stringify(value))
	_check(not profiles.create_profile("Refus absent", "avatar_default", "absente.png").ok, "Création avec une nouvelle image absente refusée")
	_check(not profiles.create_profile("Refus chemin", "avatar_default", "../bleu.png").ok, "Création avec un chemin arbitraire refusée")
	var second: Dictionary = profiles.create_profile("Bob local", "avatar_default", "Photo.JPG")
	if not _succeeds(second, "Créer un deuxième profil avec une autre image"):
		return
	var second_id: String = second.data.id
	_check(second_id != first_id and second.data.avatar_image == "Photo.JPG", "Chaque profil garde son image propre")
	_succeeds(profiles.select_profile(first_id), "Resélectionner le premier profil")
	_check(state.profile.avatar_image == "bleu.png", "La sélection restaure l'image du bon profil")
	var before: Dictionary = state.profile.duplicate(true)
	var disk_before := FileAccess.get_file_as_string(saves._path("profiles/%s.json" % first_id))
	_check(not profiles.update_profile("Alice", "avatar_default", "absente.png").ok and state.profile == before, "Nouvelle image absente refusée sans modifier le profil")
	saves.simulate_write_failure = true
	_check(not profiles.update_profile("Alice renommée", "avatar_default", "Photo.JPG").ok, "Échec d'écriture du changement d'image signalé")
	saves.simulate_write_failure = false
	_check(state.profile == before and FileAccess.get_file_as_string(saves._path("profiles/%s.json" % first_id)) == disk_before, "Échec conserve image, pseudo, points et fichier précédents")
	_succeeds(profiles.update_profile("alice minuscule", "avatar_default", "Portrait.jpeg"), "Changer d'image et enregistrer un pseudo en minuscules")
	_check(state.profile.avatar_image == "Portrait.jpeg" and state.profile.wallet == initial.wallet and state.profile.owned_items == initial.owned_items, "Changement d'image conserve argent et inventaire")
	_check(saves.read_profile(second_id).data == second.data, "Modifier Alice ne modifie aucun champ de Bob")
	_succeeds(shop.equip("theme_brume"), "Rééquiper un thème sans changer l'image")
	_succeeds(shop.equip("frame_default"), "Rééquiper un cadre sans changer l'image")
	_check(state.profile.get("avatar_image") == "Portrait.jpeg", "Thème et cadre conservent la photo personnelle")
	var before_purchase: Dictionary = state.profile.duplicate(true)
	_check(not shop.purchase("theme_sable").ok and state.profile == before_purchase, "Un achat sans points reste refusé même avec une photo personnelle")
	# Équipements possédés de fixture uniquement : aucun achat ni crédit de production.
	var equipment_fixture: Dictionary = state.profile.duplicate(true)
	equipment_fixture.owned_items.append("theme_sable")
	equipment_fixture.owned_items.append("frame_round")
	var fixture_saved: Dictionary = saves.write_profile(equipment_fixture)
	if _succeeds(fixture_saved, "Préparer deux équipements possédés dans le profil de test isolé"):
		state.commit_profile(fixture_saved.data)
		_succeeds(shop.equip("theme_sable"), "Changer réellement de thème avec une photo personnelle")
		_succeeds(shop.equip("frame_round"), "Changer réellement de cadre avec une photo personnelle")
		_check(state.profile.avatar_image == "Portrait.jpeg" and state.profile.wallet == initial.wallet and state.profile.owned_items == equipment_fixture.owned_items, "Équiper thème/cadre conserve image, points et inventaire")
		var equipped_before: Dictionary = state.profile.duplicate(true)
		saves.simulate_write_failure = true
		_check(not shop.equip("avatar_default").ok, "Échec de sauvegarde du retour à l'avatar du catalogue signalé")
		saves.simulate_write_failure = false
		_check(state.profile == equipped_before and saves.read_profile(first_id).data == equipped_before, "Retour à l'avatar échoué conserve la photo et le document précédent")
	_succeeds(shop.equip("avatar_default"), "Rééquiper le même avatar du catalogue")
	_check(not state.profile.has("avatar_image") and state.profile.equipped.avatar == "avatar_default", "Avatar du catalogue retire l'image même si le repli était déjà équipé")
	_succeeds(profiles.update_profile("Alice", "avatar_default", "bleu.png"), "Restaurer une image locale après l'avatar du catalogue")
	_succeeds(profiles.update_profile("Alice API", "avatar_default"), "L'ancienne API sans troisième argument reste utilisable")
	_check(not state.profile.has("avatar_image"), "Choisir un avatar normal par l'ancienne API retire l'image")
	_succeeds(profiles.update_profile("Alice", "avatar_default", "bleu.png"), "Préparer la disparition d'image sans autre modification")


func _test_removed_image() -> void:
	if state.profile.is_empty():
		return
	var id: String = state.profile.id
	var inventory: Array = state.profile.owned_items.duplicate()
	var wallet: Dictionary = state.profile.wallet.duplicate()
	_check(DirAccess.remove_absolute(ProjectSettings.globalize_path(images_path.path_join("bleu.png"))) == OK, "Supprimer uniquement la fixture d'image temporaire")
	_check(Library.texture_for("bleu.png") == null, "Une image supprimée abandonne aussi sa vignette mise en cache")
	_check(saves.read_profile(id).ok and saves.read_profile(id).data.avatar_image == "bleu.png", "Le profil reste chargeable et conserve sa référence après suppression d'image")
	_succeeds(profiles.update_profile("Alice sans image", "avatar_default", "bleu.png"), "Renommer conserve une référence existante dont l'image a disparu")
	_check(state.profile.equipped.avatar == "avatar_default" and state.profile.wallet == wallet and state.profile.owned_items == inventory, "Le repli existant, les points et l'inventaire restent disponibles")
	state.clear_profile()
	_succeeds(profiles.select_profile(id), "Réouvrir le profil après disparition d'image")
	_check(state.profile.get("avatar_image") == "bleu.png" and Library.texture_for(state.profile.avatar_image) == null, "Le chargement conserve les données et permet le repli visuel")
	_succeeds(profiles.update_profile("Alice restaurée", "avatar_default", "profil.WEBP"), "Une autre image valide peut remplacer celle qui manque")
	_write_raw(images_path.path_join("profil.WEBP"), "Image remplacée par un contenu invalide.")
	Library.refresh()
	_check(Library.texture_for("profil.WEBP") == null and saves.read_profile(id).ok, "Une image devenue invalide disparaît de l'aperçu sans invalider le profil")
	_succeeds(profiles.update_profile("Alice valide", "avatar_default", "profil.WEBP"), "Image devenue invalide : renommage toujours possible")


func _test_missing_folder() -> void:
	Library.directories_override = [test_root.path_join("dossier_absent")]
	Library.refresh()
	_check(Library.list_images().is_empty() and Library.texture_for("Photo.JPG") == null, "Dossier absent : liste vide, aucun échec de profil")
	if not state.profile.is_empty():
		_check(saves.read_profile(state.profile.id).ok, "Le stockage des profils reste indépendant du dossier d'images")
	var directory := DirAccess.open(test_root)
	var link := ProjectSettings.globalize_path(test_root.path_join("dossier_lie"))
	if directory.create_link(ProjectSettings.globalize_path(images_path), link) == OK:
		Library.directories_override = [link]
		Library.refresh()
		_check(Library.list_images().is_empty() and Library.texture_for("Photo.JPG") == null, "Le dossier d'images lui-même ne peut pas être un lien symbolique")
	Library.directories_override = [images_path]


func _contains_filename(images: Array[Dictionary], filename: String) -> bool:
	for entry in images:
		if entry.filename == filename:
			return true
	return false


func _succeeds(result: Dictionary, description: String) -> bool:
	var success := bool(result.get("ok", false))
	_check(success, description + (" : " + str(result.get("error", "")) if not success else ""))
	return success


func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("  OK  ", description)
	else:
		failures.append(description)
		printerr("  ÉCHEC  ", description)


func _write_raw(path: String, contents: String) -> void:
	_write_bytes(path, contents.to_utf8_buffer())


func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "Écriture du fichier de test : " + path)
		return
	file.store_buffer(bytes)
	file.flush()
	_check(file.get_error() == OK, "Fichier temporaire écrit : " + path.get_file())
	file.close()


func _remove_tree(path: String) -> void:
	if test_root.is_empty() or not (path == test_root or path.begins_with(test_root + "/")):
		_check(false, "Nettoyage interdit hors du dossier temporaire")
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for filename in directory.get_files():
		directory.remove(filename)
	for child in directory.get_directories():
		if directory.is_link(child):
			directory.remove(child)
		else:
			_remove_tree(path.path_join(child))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
