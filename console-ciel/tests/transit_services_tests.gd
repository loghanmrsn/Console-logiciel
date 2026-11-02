extends "res://tests/appearance_tests.gd"
func _run() -> void:
	await process_frame
	settings=root.get_node("SettingsService")
	saves=root.get_node("SaveService")
	var state=root.get_node("AppState")
	var profiles=root.get_node("ProfileService")
	var transit=root.get_node("TransitService")
	test_root="user://tests/transit_%s" % Time.get_ticks_usec()
	saves.root_path=test_root
	settings.storage_root=test_root
	state.clear_profile()
	_check(not transit.travel("school_stop").ok,"Pas de trajet sans profil")
	_check(profiles.use_dev_profile().ok,"Profil isolé")
	var id: String=state.profile.id
	var doc: Dictionary=state.profile.duplicate(true)
	doc.progress.room_id="courtyard"
	doc.progress.checkpoint_id="from_first"
	doc.wallet.points=30
	state.commit_profile(saves.write_profile(doc).data)
	var before: Dictionary=state.profile.duplicate(true)
	_check(not transit.travel("unknown").ok and state.profile==before,"Arrêt inconnu sans effet")
	saves.simulate_write_failure=true
	_check(not transit.travel("school_stop").ok and state.profile==before,"Échec atomique : ni débit ni trajet")
	saves.simulate_write_failure=false
	_check(transit.travel("school_stop").ok,"Billet aller enregistré")
	_check(state.profile.wallet.points==20 and state.profile.bus_travel.rides==1 and state.profile.bus_travel.spent_points==10,"1 euro vaut exactement 10 points")
	_check(state.profile.progress.completed_missions==before.progress.completed_missions and state.profile.rewarded_missions==before.rewarded_missions,"Missions et reçus conservés")
	before=state.profile.duplicate(true)
	_check(not transit.travel("school_stop").ok and state.profile==before,"Double soumission impossible depuis l’arrivée")
	_check(saves.read_profile(id).data==state.profile,"Disque et mémoire identiques")
	state.clear_profile()
	_check(profiles.select_profile(id).ok and state.profile.progress.room_id=="school_stop" and state.profile.wallet.points==20,"Reprise à l’arrivée : pas de nouveau billet")
	_check(transit.travel("courtyard").ok and state.profile.wallet.points==10 and state.profile.bus_travel.rides==2,"Retour payant une seule fois")
	doc=state.profile.duplicate(true)
	doc.wallet.points=0
	state.commit_profile(saves.write_profile(doc).data)
	before=state.profile.duplicate(true)
	_check(not transit.travel("ctf_bus_stop").ok and state.profile==before,"Solde insuffisant sans mutation")
	_check(transit.travel("ctf_bus_stop",true).ok and state.profile.wallet.points==0 and state.profile.bus_travel.rides==2,"Accès à pied sans dette ni blocage")
	_check(transit.travel("courtyard",true).ok,"Retour à pied gratuit")
	for bad in [{"version":1,"rides":1,"spent_points":1,"last_stop":"courtyard"},{"version":1,"rides":-1,"spent_points":-10,"last_stop":"courtyard"},{"version":1,"rides":1,"spent_points":10,"last_stop":"invalid"}]:
		doc=state.profile.duplicate(true)
		doc.bus_travel=bad
		_check(not saves.validate_profile(doc).ok,"Historique de billets invalide refusé")
	state.clear_profile()
	_remove_tree(test_root)
	print("TRANSIT : %d assertions, %d échec(s)." % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
