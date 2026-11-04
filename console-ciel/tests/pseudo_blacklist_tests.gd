extends SceneTree
const Policy = preload("res://scripts/services/pseudo_policy.gd")
var checks := 0
var failures := 0
var sandbox := ""
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("PSEUDO_FAIL : "+message)
func _run() -> void:
	await process_frame
	var saves=root.get_node("SaveService")
	var profiles=root.get_node("ProfileService")
	var state=root.get_node("AppState")
	sandbox="user://tests/pseudo_blacklist_%s" % Time.get_ticks_usec()
	saves.root_path=sandbox
	state.clear_profile()
	Policy.rules_path_override=""
	for name in ["ADMIN","ad.min","Modérateur","Admin42","42Admin","root42","nazi42","admin_42","Super Admin","f.d.p","connaRd42","Ａｄｍｉｎ","ad\u200bmin"]:
		check(not Policy.validate_new_name(name).ok,"Terme interdit reconnu : "+name)
	for name in ["Loghan","Constance","Mathieu","Dev","Zoë","Alex42","Machiniste","Shiho","Élodie","中文"]:
		check(Policy.validate_new_name(name).ok,"Nom ordinaire conservé : "+name)
	check(profiles.create_profile("Constance").ok,"Création normale")
	var before: Dictionary=state.profile.duplicate(true)
	var session: Dictionary=saves.read_session()
	check(not profiles.create_profile("Admin").ok and state.profile==before,"Création interdite sans mutation du profil")
	check(saves.list_profiles().data.size()==1 and saves.read_session()==session,"Aucun profil ni sélection supplémentaire")
	check(not profiles.update_profile("FDP42","avatar_default").ok and state.profile==before,"Renommage interdit atomique")
	check(saves.read_profile(before.id).data==before,"Sauvegarde inchangée après refus")
	# Existing documents retain structural validity even if a naming rule changes.
	var old: Dictionary=before.duplicate(true)
	old.display_name="Admin"
	check(saves.write_profile(old).ok,"Ancien profil encore valide")
	state.clear_profile()
	check(profiles.select_profile(old.id).ok and state.profile.display_name=="Admin","Ancien profil sélectionnable")
	check(profiles.update_profile("Admin","avatar_default").ok,"Avatar modifiable sans imposer un nouveau pseudo")
	check(profiles.update_profile("Loghan","avatar_default").ok,"Ancien pseudo renommable")
	before=state.profile.duplicate(true)
	saves.simulate_write_failure=true
	check(not profiles.update_profile("Louise","avatar_default").ok and state.profile==before,"Erreur disque sans renommage partiel")
	saves.simulate_write_failure=false
	var custom := sandbox.path_join("pseudo_blacklist.json")
	var file := FileAccess.open(custom,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"blocked_names":["Roi Bleu"],"blocked_terms":["terme"]}));file.close()
	Policy.rules_path_override=custom
	check(not Policy.validate_new_name("roi_bleu").ok,"Nom personnalisé normalisé")
	check(not Policy.validate_new_name("Terme22").ok and Policy.validate_new_name("Monterme").ok,"Mot entier, sans blocage de sous-chaîne")
	check(Policy.validate_new_name("Admin").ok,"La liste locale modifiée est prise en compte sans redémarrage")
	file=FileAccess.open(custom,FileAccess.WRITE);file.store_string("invalid json");file.close()
	check(not profiles.create_profile("Joueur").ok and state.profile==before,"Configuration cassée signalée sans écriture")
	file=FileAccess.open(custom,FileAccess.WRITE);file.store_string(JSON.stringify({"version":1,"blocked_names":[23],"blocked_terms":[]}));file.close()
	check(not Policy.validate_new_name("Joueur").ok,"Entrées mal formées refusées")
	Policy.rules_path_override=""
	check(profiles.use_dev_profile().ok and profiles.is_super_admin(),"Profil Dev interne préservé")
	state.clear_profile()
	_remove(sandbox)
	print("PSEUDO_BLACKLIST : %d assertions, %d échec(s)." % [checks,failures])
	quit(0 if failures==0 else 1)
func _remove(path: String) -> void:
	if not path.begins_with(sandbox): return
	var directory := DirAccess.open(path)
	if directory==null: return
	for filename in directory.get_files(): directory.remove(filename)
	for child in directory.get_directories(): _remove(path.path_join(child))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
