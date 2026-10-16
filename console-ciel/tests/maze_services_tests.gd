extends "res://tests/code_chapter_services_tests.gd"
const FOURTH := ["firewall", "ip_conflict", "subnet_mask"]

func _run() -> void:
	await process_frame
	saves = root.get_node("SaveService")
	profiles = root.get_node("ProfileService")
	shop = root.get_node("ShopService")
	rewards = root.get_node("RewardService")
	investigation = root.get_node("InvestigationService")
	state = root.get_node("AppState")
	test_root = "user://tests/maze_services_%s_%s" % [OS.get_process_id(),Time.get_ticks_usec()]
	saves.root_path = test_root
	state.clear_profile()
	if not _ok(shop.load_catalog(),"Catalogue") or not _ok(rewards.load_rules(),"Règles"):
		_finish()
		return
	var made: Dictionary = profiles.create_profile("Mystère")
	if not _ok(made,"Profil isolé"):
		_finish()
		return
	profile_id = str(made.data.id)
	_ok(profiles.start_game(),"Début de partie")
	var before: Dictionary = state.profile.duplicate(true)
	_check(not investigation.enter_chapter(5).ok and not investigation.enter_maze().ok, "Pas de raccourci avant les chapitres précédents")
	_check(not investigation.terminal_login("admin","admin").ok and not investigation.terminal_command("sudo","admin").ok, "Terminal inaccessible hors du labyrinthe")
	_check(state.profile == before,"Aucun effet après les accès anticipés")
	for chapter in [1,2,3,4]:
		if chapter > 1: _ok(investigation.enter_chapter(chapter),"Étage précédent")
		for id in [FIRST,SECOND,THIRD,FOURTH][chapter-1]:
			_check(not investigation.can_enter_chapter(5),"Les douze réussites restent nécessaires : " + id)
			_complete(id)
	_check(rewards.missions.size() == 13 and investigation.chapter_missions(5).size() == 1,"Treize missions, une seule au chapitre 5")
	var definition: Dictionary = investigation.mission("maze")
	_check(definition.name == "???" and definition.title == "???" and definition.description == "???","L’objectif n’est pas révélé dans ses textes")
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/game_rules.json"))
	for field in ["name","title","description","prerequisites","solution","reward","room_id"]:
		var bad: Dictionary = rules.duplicate(true)
		match field:
			"prerequisites": bad.missions[12][field] = ["markdown"]
			"solution": bad.missions[12][field] = {"user":"root","password":"admin"}
			"reward": bad.missions[12][field] = 0
			_: bad.missions[12][field] = "invalide"
		_check(not saves.validate_rules(bad).ok,"Définition du mystère altérée refusée : " + field)
	_test_legacy_twelve()
	_ok(investigation.enter_chapter(5),"Ascenseur au palier")
	_check(state.profile.progress.room_id == "room_05" and not investigation.terminal_connected(),"Arrivée au palier, sans session")
	before = state.profile.duplicate(true)
	saves.simulate_write_failure = true
	_check(not investigation.enter_maze().ok,"Échec d’entrée signalé")
	saves.simulate_write_failure = false
	_check(state.profile == before and saves.read_profile(profile_id).data == before,"Une téléportation échouée ne modifie rien")
	_ok(investigation.enter_maze(),"Entrée depuis le portable")
	_check(state.profile.progress.room_id == "maze_05" and state.profile.progress.checkpoint_id == "maze_entry","Le labyrinthe et son entrée sont sauvegardés")
	_ok(investigation.begin_mission("maze"),"Mission mystère démarrée")
	before = state.profile.duplicate(true)
	for pair in [["root","admin"],["admin","ADMIN"],[" admin","admin"],["admin",""]]:
		_check(not investigation.terminal_login(pair[0],pair[1]).ok,"Mauvais identifiants refusés")
	_check(not investigation.observe("maze","login").ok,"Une observation générique ne fabrique pas une connexion")
	_check(not investigation.terminal_command("sudo","admin").ok and not investigation._finish_validated("maze",{"command":"sudo","password":"admin"}).ok,"L’élévation nécessite d’abord une connexion")
	_check(state.profile == before and saves.read_profile(profile_id).data == before,"Les erreurs de connexion sont sans effet")
	saves.simulate_write_failure = true
	_check(not investigation.terminal_login("admin","admin").ok,"Échec d’enregistrement de la connexion remonté")
	saves.simulate_write_failure = false
	_check(state.profile == before and not investigation.terminal_connected(),"Échec de connexion sans authentification partielle")
	_ok(investigation.terminal_login("admin","admin"),"Connexion correcte")
	_check(investigation.terminal_connected() and state.profile.wallet.points == 600 and not state.profile.progress.completed_missions.has("maze"),"Connexion seule : aucun droit complet ni récompense")
	_reload(profile_id)
	_check(investigation.terminal_connected() and state.profile.progress.checkpoint_id == "maze_terminal","La session et le terminal sont repris")
	for command in ["whoami","ls","pwd","id","help","dir","cls","ipconfig","runas","clear"]:
		before = state.profile.duplicate(true)
		var reply: Dictionary = investigation.terminal_command(command)
		_check(reply.ok and reply.data.has("output") and state.profile == before,"Commande de consultation sans élévation : " + command)
	for command in ["sudo rm -rf /","sudo && whoami","powershell","sudo\nwhoami","sudo -i; id","whoami".repeat(20),""]:
		_check(not investigation.terminal_command(command,"admin").ok,"Texte hors des commandes simulées refusé")
	for command in ["sudo","sudo -i","sudo -s","su -","s-","su    -"]:
		var request: Dictionary = investigation.terminal_command(command)
		_check(request.ok and request.data.needs_password,"L’élévation demande une nouvelle authentification : " + command)
		_check(not investigation.terminal_command(command,"faux").ok,"Mauvais mot de passe d’élévation refusé")
	before = state.profile.duplicate(true)
	_check(not rewards.complete_mission("maze").ok and not rewards._complete_validated_mission("maze","invented").ok,"Pas de récompense directe")
	saves.simulate_write_failure = true
	_check(not investigation.terminal_command("sudo -i","admin").ok,"Échec d’enregistrement des droits signalé")
	saves.simulate_write_failure = false
	_check(state.profile == before and saves.read_profile(profile_id).data == before,"Droits et récompense restent atomiques en cas d’échec")
	var success: Dictionary = investigation.terminal_command("sudo -i","admin")
	_check(success.ok and success.data.reward == 50,"Élévation valide : mission et 50 points")
	_check(state.profile.wallet.points == 650 and state.profile.rewarded_missions.size() == 13 and investigation.conclusion(5).ok,"Cinq chapitres, treize réussites et bilan final à 650")
	_check(saves.read_profile(profile_id).data == state.profile,"Réussite entière persistée")
	_check(investigation.terminal_command("whoami").data.output.begins_with("root") and investigation.terminal_command("id").data.output.contains("uid=0"),"La session obtenue possède bien les droits root simulés")
	var again: Dictionary = investigation.terminal_command("su -","admin")
	_check(again.ok and again.data.reward == 0,"Une autre commande d’élévation ne redonne pas de points")
	_ok(investigation.leave_maze(),"Retour au palier")
	_check(state.profile.progress.room_id == "room_05" and state.profile.progress.active_mission.is_empty(),"Retour au palier enregistré")
	_ok(investigation.enter_chapter(4),"Descente")
	_check(not investigation.terminal_command("sudo","admin").ok,"Ancienne session inutilisable depuis un autre étage")
	_ok(investigation.enter_chapter(5),"Retour au palier")
	_ok(investigation.enter_maze(),"Revisite")
	var saved: Dictionary = state.profile.duplicate(true)
	var other: Dictionary = profiles.create_profile("Autre")
	_check(other.ok and not investigation.terminal_connected() and not investigation.can_enter_chapter(5),"Profils et sessions restent isolés")
	_reload(profile_id)
	_check(state.profile == saved,"Le profil initial retrouve ses acquis")
	_ok(profiles.start_game(),"Rejeu")
	_check(not investigation.terminal_connected() and state.profile.progress.observations.size() == 13,"Le rejeu efface la session de cette partie")
	for chapter in [1,2,3,4]:
		if chapter > 1: _ok(investigation.enter_chapter(chapter),"Trajet de rejeu")
		for id in [FIRST,SECOND,THIRD,FOURTH][chapter-1]: _complete(id,0)
	_ok(investigation.enter_chapter(5),"Rejeu au chapitre 5")
	_ok(investigation.enter_maze(),"Rejeu dans le labyrinthe")
	_ok(investigation.terminal_login("admin","admin"),"Reconnexion")
	var replay: Dictionary = investigation.terminal_command("su -","admin")
	_check(replay.ok and replay.data.reward == 0 and state.profile.wallet.points == 650 and state.profile.progress.run_reward_points == 0,"La mission rejouée ne rapporte aucun gain supplémentaire")
	_finish()

func _test_legacy_twelve() -> void:
	var modern: Dictionary = state.profile.duplicate(true)
	var legacy: Dictionary = modern.duplicate(true)
	legacy.progress.observations.erase("maze")
	var raw := JSON.stringify(legacy,"\t")
	_check(_write_raw(_path(profile_id),raw),"Ancien document 0.8.0 préparé")
	state.clear_profile()
	var read: Dictionary = saves.read_profile(profile_id)
	_check(read.ok and read.migration_required and read.data == modern and _disk(profile_id) == raw,"Lecture d’un profil à douze observations sans perte ni écriture")
	saves.simulate_write_failure = true
	_check(not profiles.select_profile(profile_id).ok and _disk(profile_id) == raw,"Migration échouée sans toucher l’original")
	saves.simulate_write_failure = false
	_ok(profiles.select_profile(profile_id),"Migration à treize observations")
	_check(state.profile == modern and FileAccess.get_file_as_string(_path(profile_id)+".bak") == raw,"Original conservé dans .bak, acquis identiques")
	_check(not saves.read_profile(profile_id).migration_required,"Migration unique")
