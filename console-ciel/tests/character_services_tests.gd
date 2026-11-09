extends SceneTree
const Catalog=preload("res://scripts/services/character_catalog.gd")
var checks:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("CHARACTER_FAIL : ",message)
func run() -> void:
	await process_frame
	var saves=root.get_node("SaveService");var state=root.get_node("AppState");var profiles=root.get_node("ProfileService");var service=root.get_node("CharacterService")
	saves.root_path="user://tests/character_%s"%Time.get_ticks_usec()
	check(root.get_node("ShopService").load_catalog().ok,"Catalogue existant")
	check(root.get_node("RewardService").load_rules().ok,"Règles existantes")
	check(profiles.create_profile("Personnage test").ok,"Profil existant compatible")
	var old=state.profile.duplicate(true)
	check(not old.has("character") and Catalog.valid(service.current()),"Ancien profil sans migration forcée")
	check(not service.purchase("top","sweater").ok and state.profile==old,"Solde insuffisant : aucun débit")
	check(service.apply(Catalog.defaults().appearance).ok,"Tenue gratuite utilisable sans points")
	var original=state.profile.duplicate(true)
	var invalid=service.current();invalid.rig="other"
	check(not Catalog.valid(invalid),"Gabarit arbitraire rejeté")
	invalid=service.current();invalid.height=2.5
	check(not Catalog.valid(invalid),"Taille variable rejetée")
	invalid=service.current();invalid.appearance.top="sweater"
	check(not service.apply(invalid.appearance).ok,"Achat requis pour équiper")
	invalid=state.profile.duplicate(true);invalid.character.appearance.top="sweater"
	check(not saves.validate_profile(invalid).ok,"Sauvegarde falsifiée sans achat rejetée")
	check(profiles.use_dev_profile().ok,"Profil Dev isolé avec points réellement gagnés")
	var funded=state.profile.duplicate(true)
	funded.wallet.points=5000
	state.commit_profile(saves.write_profile(funded).data)
	var points=int(state.profile.wallet.points)
	var rewards=state.profile.rewarded_missions.duplicate()
	var progress=state.profile.progress.duplicate(true)
	var spent:=0
	for item in Catalog.ITEMS:
		var before=state.profile.duplicate(true)
		if item.price>0:
			saves.simulate_write_failure=true
			check(not service.purchase(item.slot,item.id).ok and state.profile==before,"Échec disque atomique : "+item.name)
			saves.simulate_write_failure=false
			check(service.purchase(item.slot,item.id).ok,"Achat enregistré : "+item.name)
			spent+=item.price
			check(not service.purchase(item.slot,item.id).ok,"Aucun double débit : "+item.name)
		else:check(not service.purchase(item.slot,item.id).ok,"Gratuit déjà disponible : "+item.name)
		var a=service.current().appearance
		a[item.slot]=item.id
		if item.slot!="hair":a[item.slot+"_color"]=Catalog.allowed_colors(item.slot,item.id)[0]
		check(service.apply(a).ok,"Équipement valide : "+item.name)
		check(saves.read_profile(state.profile.id).data==state.profile,"Reprise persistante : "+item.name)
	check(int(state.profile.wallet.points)==points-spent,"Débits exacts en points virtuels")
	check(state.profile.rewarded_missions==rewards and state.profile.progress==progress,"Achat et apparence ne modifient aucune mission")
	var a=service.current().appearance
	a.trousers="regular";a.trousers_color="pink"
	check(not service.apply(a).ok,"Coloris gratuits limités à noir, bleu et blanc")
	a=service.current().appearance;a.socks_color="red"
	check(not service.apply(a).ok,"Chaussettes uniquement noires ou blanches")
	var before=state.profile.duplicate(true)
	a=service.current().appearance;a.eye_color="blue"
	saves.simulate_write_failure=true
	check(not service.apply(a).ok and state.profile==before and saves.read_profile(before.id).data==before,"Erreur disque : apparence, solde et inventaire inchangés")
	saves.simulate_write_failure=false
	var legacy=state.profile.duplicate(true)
	legacy.character.appearance.gait="loose"
	check(saves.validate_profile(legacy).ok,"Ancienne démarche toujours acceptée dans les sauvegardes")
	state.commit_profile(saves.write_profile(legacy).data)
	var persisted=state.profile.duplicate(true)
	var normalized=service.current()
	check(normalized.appearance.gait=="natural","Ancien personnage repris avec une marche naturelle")
	var expected=persisted.character.duplicate(true);expected.appearance.gait="natural"
	check(normalized==expected,"Tenue, couleurs et achats conservés pendant la reprise")
	check(state.profile==persisted and saves.read_profile(persisted.id).data==persisted,"Lire l'ancienne démarche ne réécrit pas le profil ni le disque")
	check(profiles.select_profile(original.id).ok and state.profile.wallet.points==0,"Isolation des achats entre profils")
	check(service.current().owned.is_empty(),"Un autre profil ne reçoit pas les achats")
	print("CHARACTER_SERVICES : %d assertions, %d échec(s)."%[checks,failures])
	quit(0 if failures==0 else 1)
