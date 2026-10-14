extends SceneTree
## Achats de jeux : points pédagogiques réels, transactions et rechargement.
## Toutes les écritures utilisent un dossier distinct sous user://tests/.
## Run: godot --headless --path . --script res://tests/game_purchase_tests.gd

const Library := preload("res://scripts/services/game_library.gd")

var checks := 0
var failures: Array[String] = []
var test_root := ""
var saves
var profiles
var shop
var state
var investigation
var original_catalog: Array = []
var alice_id := ""
var bob_id := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	shop = root.get_node("ShopService")
	state = root.get_node("AppState")
	investigation = root.get_node("InvestigationService")
	test_root = "user://tests/game_purchase_%s_%s" % [Time.get_ticks_usec(), OS.get_process_id()]
	saves.root_path = test_root
	state.clear_profile()
	if _succeeds(shop.load_catalog(), "Charger le catalogue livré avec ses emplacements de jeux"):
		original_catalog = shop.catalog.duplicate(true)
		_test_library()
		_test_catalog_validation()
		_test_transactions()
	saves.simulate_write_failure = false
	shop.catalog = original_catalog.duplicate(true)
	saves.invalidate_definitions()
	state.clear_profile()
	_remove_tree(test_root)
	print("ACHATS DE JEUX : %d assertions, %d échec(s)." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _test_library() -> void:
	var definitions := Library.definitions(shop.catalog)
	_check(definitions.size() == 5, "Une enquête gratuite et quatre jeux de test, sans jeux ajoutés arbitrairement")
	_check(definitions[0].id == Library.EDUCATIONAL_ID and definitions[0].price == 0, "L'enquête reste gratuite et indépendante de la boutique")
	_check(shop.item(Library.EDUCATIONAL_ID).is_empty(), "L'enquête gratuite n'est pas un article vendable")
	_check(Library.owned_games({}, shop.catalog).is_empty(), "Sans profil, aucun jeu acheté")
	_check(not Library.can_play({}, Library.EDUCATIONAL_ID, shop.catalog), "Un profil est nécessaire pour lancer une enquête")
	var total := 0
	for number in range(1, 5):
		var id := "game_test_%d" % number
		var game := Library.entry(shop.catalog, id)
		_check(not game.is_empty() and game.get("name") == "Test %d" % number, "Jeu de test livré : " + id)
		_check(game.get("placeholder") == true and game.get("scene") == "res://scenes/games/test_game.tscn", "Emplacement clairement identifié, sans gameplay fictif : " + id)
		_check(Library.is_valid_game_scene(game.get("scene")), "Scène locale de jeu réellement livrée : " + id)
		total += int(game.get("price", 0))
		game["name"] = "Copie modifiée"
		_check(Library.entry(shop.catalog, id).name == "Test %d" % number, "Les résultats de bibliothèque sont copiés : " + id)
	_check(total == 140, "Les quatre emplacements coûtent 140 points, sous les 150 points de l'enquête")
	_check(Library.entry(shop.catalog, "inconnu").is_empty(), "Jeu inconnu sans entrée ni scène")
	var malformed: Array = [null, 42, {}, {"id": "game_bad", "type": "game", "scene": "user://bad.tscn"}]
	_check(Library.definitions(malformed).size() == 1, "Une bibliothèque mal formée ne propose que l'enquête gratuite")
	var duplicate: Array = shop.catalog.duplicate(true)
	duplicate.append(shop.item("game_test_1"))
	duplicate.append(Library.EDUCATIONAL_GAME.duplicate(true))
	_check(Library.definitions(duplicate).size() == definitions.size(), "La bibliothèque ne duplique ni les jeux ni l'enquête")
	for invalid in [null, 1, [], {}, "", "user://test.tscn", "https://example.com/test.tscn", "file:///tmp/test.tscn", "/tmp/test.tscn", "C:\\test.tscn", Library.GAMES_DIRECTORY + "../main.tscn", Library.GAMES_DIRECTORY + "/test_game.tscn", Library.GAMES_DIRECTORY + "./test_game.tscn", Library.GAMES_DIRECTORY + "sub/../../main.tscn", Library.GAMES_DIRECTORY + "test_game.gd", "res://scenes/main.tscn", Library.GAMES_DIRECTORY + "absent.tscn", Library.GAMES_DIRECTORY + "test_game.tscn\n", Library.GAMES_DIRECTORY + "%2e%2e/main.tscn"]:
		_check(not Library.is_valid_game_scene(invalid), "Chemin de jeu externe, absent ou invalide refusé : " + JSON.stringify(invalid))


func _test_catalog_validation() -> void:
	var parsed: Dictionary = saves._resource_json("res://data/shop_catalog.json")
	if not _succeeds(parsed, "Lire les données du catalogue pour la validation isolée"):
		return
	var document: Dictionary = parsed.data
	_check(saves.validate_catalog(document).ok, "Le catalogue enrichi est accepté sans changement de schéma")
	var index := -1
	for position in range(document.items.size()):
		if document.items[position].id == "game_test_1":
			index = position
			break
	_check(index >= 0, "L'entrée game_test_1 existe dans le catalogue livré")
	if index < 0:
		return
	for invalid in [null, [], 42, "https://example.com/test.tscn", Library.GAMES_DIRECTORY + "../main.tscn", Library.GAMES_DIRECTORY + "absent.tscn", "res://scenes/main.tscn"]:
		var bad: Dictionary = document.duplicate(true)
		bad.items[index].scene = invalid
		_check(not saves.validate_catalog(bad).ok, "Un jeu invendable est rejeté par le catalogue : " + JSON.stringify(invalid))
	for invalid in [null, 0, "true", [], {}]:
		var bad: Dictionary = document.duplicate(true)
		bad.items[index].placeholder = invalid
		_check(not saves.validate_catalog(bad).ok, "Le marqueur de jeu en préparation doit être booléen")
	for invalid in [-1, 1, 19, 20.5, "20", true, 101]:
		var bad: Dictionary = document.duplicate(true)
		bad.items[index].price = invalid
		_check(not saves.validate_catalog(bad).ok, "Prix de jeu invalide refusé dans le catalogue : " + JSON.stringify(invalid))
	var normal_game: Dictionary = document.duplicate(true)
	normal_game.items[index].erase("placeholder")
	_check(saves.validate_catalog(normal_game).ok, "Le schéma accueille aussi un futur vrai jeu sans marqueur placeholder")
	var reserved: Dictionary = document.duplicate(true)
	reserved.items[index].id = Library.EDUCATIONAL_ID
	_check(not saves.validate_catalog(reserved).ok, "Une entrée vendable ne peut pas remplacer l'enquête gratuite")


func _test_transactions() -> void:
	var alice: Dictionary = profiles.create_profile("Alice jeux")
	if not _succeeds(alice, "Créer Alice sans points dans les données de test"):
		return
	alice_id = alice.data.id
	var bob: Dictionary = profiles.create_profile("Bob jeux")
	if not _succeeds(bob, "Créer Bob sans points dans les données de test"):
		return
	bob_id = bob.data.id
	var before: Dictionary = state.profile.duplicate(true)
	var disk_before := _profile_text(bob_id)
	_check(Library.can_play(before, Library.EDUCATIONAL_ID, shop.catalog), "L'enquête est disponible gratuitement avec un profil")
	for number in range(1, 5):
		var id := "game_test_%d" % number
		_check(not shop.purchase(id).ok, "Achat directement refusé par le service avec zéro point : " + id)
		_check(not Library.can_play(state.profile, id, shop.catalog), "Un jeu non acheté reste inaccessible : " + id)
	_check(state.profile == before and _profile_text(bob_id) == disk_before, "Quatre achats sans points conservent mémoire et fichier intégralement")
	_check(not shop.purchase("game_inconnu").ok, "Identifiant de jeu inconnu refusé")
	_check(not shop.purchase(Library.EDUCATIONAL_ID).ok, "Aucun achat ni débit possible pour l'enquête gratuite")
	_check(not shop.equip("game_test_1").ok and state.profile == before, "Un jeu non possédé ne peut pas être équipé")
	if not _succeeds(profiles.select_profile(alice_id), "Sélectionner Alice pour gagner des points pédagogiques"):
		return
	if not _succeeds(profiles.start_game(), "Commencer la vraie enquête éducative"):
		return
	if not _succeeds(investigation.begin_mission("lighting"), "Ouvrir le vrai défi d'éclairage"):
		return
	var earned: Dictionary = investigation.submit_lighting(["source_switch", "switch_lamp", "lamp_return"])
	if not _succeeds(earned, "Résoudre le vrai défi pour financer un achat"):
		return
	_check(state.profile.wallet.points == 50 and earned.data.reward == 50, "L'achat utilise exactement les 50 points de la mission, sans crédit de test")
	before = state.profile.duplicate(true)
	disk_before = _profile_text(alice_id)
	var committed: Array = []
	var on_commit := func(profile: Dictionary) -> void: committed.append(profile.duplicate(true))
	state.profile_changed.connect(on_commit)
	saves.simulate_write_failure = true
	_check(not shop.purchase("game_test_4").ok, "Échec de sauvegarde d'un achat de jeu signalé")
	saves.simulate_write_failure = false
	_check(state.profile == before and _profile_text(alice_id) == disk_before, "Échec d'achat : aucun débit ni propriété partiels en mémoire ou sur disque")
	_check(committed.is_empty(), "Aucun signal de profil validé n'est émis avant l'écriture réussie")
	var bought: Dictionary = shop.purchase("game_test_4")
	if not _succeeds(bought, "Acheter Test 4 avec les points réellement gagnés"):
		state.profile_changed.disconnect(on_commit)
		return
	_check(state.profile.wallet.points == 0 and "game_test_4" in state.profile.owned_items, "Le prix est débité exactement une fois et le jeu rejoint l'inventaire")
	_check(state.profile.equipped == before.equipped and state.profile.rewarded_missions == before.rewarded_missions and state.profile.progress == before.progress, "L'achat conserve équipements, progression et récompenses")
	_check(committed.size() == 1 and committed[0] == state.profile, "La propriété est publiée une seule fois après l'écriture réussie")
	_check(saves.read_profile(alice_id).data == state.profile, "Points et achat sont conservés dans le profil sur disque")
	before = state.profile.duplicate(true)
	disk_before = _profile_text(alice_id)
	_check(not shop.purchase("game_test_4").ok, "Double achat refusé même avec zéro point restant")
	_check(state.profile == before and _profile_text(alice_id) == disk_before and committed.size() == 1, "Double achat sans nouveau débit, sans réécriture ni signal")
	_check(not shop.purchase("game_test_1").ok and state.profile == before, "Un second jeu payant reste refusé après épuisement du solde")
	_check(not shop.equip("game_test_4").ok and state.profile == before, "Un jeu acheté se lance et ne remplace aucun équipement")
	_check(Library.can_play(state.profile, "game_test_4", shop.catalog), "Le jeu acheté est autorisé au lancement")
	_check(Library.owned_games(state.profile, shop.catalog).size() == 1 and Library.owned_games(state.profile, shop.catalog)[0].id == "game_test_4", "La liste de jeux achetés exclut cosmétiques et enquête gratuite")
	_test_placeholder()
	var invalid: Dictionary = state.profile.duplicate(true)
	invalid.equipped["game"] = "game_test_4"
	_check(not saves.validate_profile(invalid).ok, "Un document ne peut pas enregistrer un jeu comme équipement")
	invalid = state.profile.duplicate(true)
	invalid.owned_items.append("game_test_4")
	_check(not saves.validate_profile(invalid).ok, "Un jeu dupliqué dans l'inventaire reste invalide")
	state.profile_changed.disconnect(on_commit)
	state.clear_profile()
	if _succeeds(profiles.select_profile(alice_id), "Recharger le profil après avoir effacé l'état mémoire"):
		_check(state.profile == before and Library.can_play(state.profile, "game_test_4", shop.catalog), "Propriété et solde survivent à la resélection depuis le disque")
		_succeeds(profiles.reset_progress(), "Réinitialiser uniquement l'enquête après un achat de jeu")
		_check(state.profile.owned_items == before.owned_items and state.profile.wallet == before.wallet and state.profile.rewarded_missions == before.rewarded_missions, "La remise à zéro pédagogique conserve jeux, points et récompenses déjà attribuées")
	_succeeds(profiles.select_profile(bob_id), "Resélectionner Bob pour vérifier l'isolation entre profils")
	_check(state.profile.wallet.points == 0 and Library.owned_games(state.profile, shop.catalog).is_empty() and not Library.can_play(state.profile, "game_test_4", shop.catalog), "Les achats d'Alice ne débloquent aucun jeu pour Bob")
	_test_free_game_and_invalid_scene()


func _test_placeholder() -> void:
	var before: Dictionary = state.profile.duplicate(true)
	var disk_before := _profile_text(alice_id)
	var definition := Library.entry(shop.catalog, "game_test_4")
	var packed := ResourceLoader.load(definition.scene, "PackedScene") as PackedScene
	if not _check_fixture(packed != null, "L'emplacement acheté est une vraie scène chargeable"):
		return
	var placeholder := packed.instantiate() as Control
	if not _check_fixture(placeholder != null and placeholder.has_method("configure"), "La scène accepte la définition du jeu acheté"):
		if placeholder != null:
			placeholder.free()
		return
	placeholder.call("configure", definition)
	root.add_child(placeholder)
	var title := placeholder.find_child("test_game_title", true, false) as Label
	var status := placeholder.find_child("test_game_status", true, false) as Label
	var back := placeholder.find_child("test_game_back", true, false) as Button
	_check(title != null and title.text == "Test 4", "Le titre correspond au jeu acheté, même avec une scène partagée")
	_check(status != null and "Jeu en préparation" in status.text, "Le lancement annonce clairement qu'il s'agit d'un emplacement")
	var returns: Array = []
	placeholder.connect("menu_requested", func(): returns.append(true))
	if _check_fixture(back != null, "L'emplacement garde un bouton de retour vers la bibliothèque"):
		back.pressed.emit()
		_check(returns.size() == 1, "Le retour au menu est demandé une seule fois")
	_check(state.profile == before and _profile_text(alice_id) == disk_before, "Lancer et quitter un emplacement ne gagne aucun point et ne modifie aucune progression")
	root.remove_child(placeholder)
	placeholder.free()


func _test_free_game_and_invalid_scene() -> void:
	# Prix gratuit uniquement dans une copie de catalogue de test : aucune ressource
	# de production n'est modifiée et la scène reste celle réellement livrée.
	var local_catalog: Array = original_catalog.duplicate(true)
	for game in local_catalog:
		if game.id == "game_test_1":
			game.price = 0
	shop.catalog = local_catalog
	var free: Dictionary = shop.purchase("game_test_1")
	if _succeeds(free, "Une entrée gratuite explicitement définie reste achetable avec zéro point"):
		var before: Dictionary = state.profile.duplicate(true)
		var disk_before := _profile_text(bob_id)
		_check(before.wallet.points == 0 and "game_test_1" in before.owned_items, "Un achat gratuit ne crée ni ne débite aucun point")
		_check(not shop.purchase("game_test_1").ok and state.profile == before and _profile_text(bob_id) == disk_before, "Un jeu gratuit ne peut pas être ajouté deux fois")
	shop.catalog = original_catalog.duplicate(true)
	for invalid in ["user://outside.tscn", Library.GAMES_DIRECTORY + "../main.tscn", Library.GAMES_DIRECTORY + "absent.tscn"]:
		var fake: Dictionary = shop.item("game_test_2")
		fake.scene = invalid
		fake.price = 0
		shop.catalog = [fake]
		var before: Dictionary = state.profile.duplicate(true)
		var disk_before := _profile_text(bob_id)
		_check(not shop.purchase("game_test_2").ok, "Le service bloque une scène invendable même si le prix est zéro : " + invalid)
		_check(state.profile == before and _profile_text(bob_id) == disk_before, "Scène invalide refusée sans mutation du profil")
		shop.catalog = original_catalog.duplicate(true)


func _profile_text(id: String) -> String:
	return FileAccess.get_file_as_string(saves._path("profiles/%s.json" % id))


func _succeeds(result: Dictionary, description: String) -> bool:
	var success := bool(result.get("ok", false))
	_check(success, description + (" : " + str(result.get("error", "")) if not success else ""))
	return success


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)


func _check_fixture(condition: bool, description: String) -> bool:
	_check(condition, description)
	return condition


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
