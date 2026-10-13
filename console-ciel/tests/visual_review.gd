extends SceneTree
## Real viewport captures only. Run with X11 and isolated XDG directories.
var app
var failures := 0
var captures: Array = []
var SaveService
var SettingsService
var AppState
var ProfileService
var InvestigationService
var ShopService
func _initialize(): call_deferred('_run')
func check(ok: bool, message: String):
	if not ok: failures+=1; printerr('VISUAL_FAIL : '+message)
func frames(count: int):
	for i in range(count): await process_frame
func capture(name: String):
	await frames(8)
	await RenderingServer.frame_post_draw
	var picture = root.get_texture().get_image()
	check(picture!=null and not picture.is_empty(),'Rendu réel '+name)
	if picture==null or picture.is_empty(): return
	var path='res://docs/screenshots/finition/'+name+'.png'
	check(picture.save_png(path)==OK,'Écriture '+name)
	captures.append({'file':path,'width':picture.get_width(),'height':picture.get_height()})
func screen(name: String):
	app._show_screen(name)
	await frames(12)
func _run():
	await process_frame
	SaveService=root.get_node('SaveService')
	SettingsService=root.get_node('SettingsService')
	AppState=root.get_node('AppState')
	ProfileService=root.get_node('ProfileService')
	InvestigationService=root.get_node('InvestigationService')
	ShopService=root.get_node('ShopService')
	if DisplayServer.get_name()=='headless':
		printerr('VISUAL_FAIL : affichage réel requis');quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path('res://docs/screenshots/finition'))
	SaveService.root_path='user://tests/visual_review'
	SettingsService.storage_root=SaveService.root_path
	AppState.clear_profile()
	root.size=Vector2i(1280,720)
	app=load('res://scenes/main.tscn').instantiate()
	root.add_child(app)
	await frames(2)
	await RenderingServer.frame_post_draw
	var boot=root.get_texture().get_image()
	check(boot.save_png('res://docs/screenshots/finition/demarrage.png')==OK,'Démarrage réellement rendu')
	boot=null
	await frames(30)
	check(app.screen=='editor','Premier lancement')
	await capture('creation_1280x720')
	var first=ProfileService.create_profile('Démo Loghan')
	var second=ProfileService.create_profile('Démo Camille')
	check(first.ok and second.ok,'Deux profils isolés')
	if not first.ok or not second.ok: quit(1);return
	check(ProfileService.select_profile(first.data.id).ok,'Profil actif')
	for dimensions in [Vector2i(1280,720),Vector2i(1024,600),Vector2i(800,480)]:
		root.size=dimensions
		await frames(10)
		for large in [false,true]:
			var values=SettingsService.defaults.duplicate(true)
			values.large_text=large
			values.reduce_transparency=large
			values.reduce_motion=true
			check(SettingsService.preview(values).ok,'Accessibilité')
			var suffix='%dx%d_%s'%[dimensions.x,dimensions.y,'grand_opaque' if large else 'normal']
			await screen('home');await capture('menu_'+suffix)
			await screen('profiles');await capture('profils_'+suffix)
			app.settings_category=0
			app.draft_settings=values.duplicate(true)
			await screen('settings');await capture('parametres_'+suffix)
			await screen('shop');await capture('boutique_'+suffix)
			app.shop_inventory=true
			await screen('shop');await capture('inventaire_'+suffix)
			app.shop_inventory=false
			check(ProfileService.start_game().ok,'Enquête initialisée')
			await screen('game');await capture('enquete_'+suffix)
			app.demo.request_pause();await capture('pause_'+suffix)
			app.demo.resume();await frames(12)
			app.demo._interaction_requested('lock');await capture('dialogue_'+suffix)
			app.demo._close_overlay();await frames(12)
			app.demo._interaction_requested('lighting');await capture('defi_'+suffix)
			app.demo._close_overlay();await frames(12)
	root.size=Vector2i(1280,720)
	SettingsService.cancel_preview()
	check(InvestigationService.begin_mission('lighting').ok,'Éclairage')
	check(InvestigationService.submit_lighting(['source_switch','switch_lamp','lamp_return']).ok,'Circuit validé')
	check(InvestigationService.begin_mission('lock').ok,'Serrure')
	for observation in ['badge','power','command','link']: check(InvestigationService.observe('lock',observation).ok,'Observation serrure')
	check(InvestigationService.submit_lock('control_link','reconnect_control').ok,'Serrure validée')
	check(InvestigationService.begin_mission('computer').ok,'Ordinateur')
	for observation in ['pc','display','no_signal']: check(InvestigationService.observe('computer',observation).ok,'Observation ordinateur')
	for observation in ['power','video']: check(InvestigationService.check_computer(observation).ok,'Vérification ordinateur')
	check(InvestigationService.submit_computer(['power','video'],'video_disconnected','reconnect_video').ok,'Ordinateur validé')
	for dimensions in [Vector2i(1280,720),Vector2i(1024,600),Vector2i(800,480)]:
		root.size=dimensions
		for large in [false,true]:
			var values=SettingsService.defaults.duplicate(true)
			values.large_text=large;values.reduce_transparency=large;values.reduce_motion=true
			SettingsService.preview(values)
			await screen('game')
			app.demo._show_conclusion()
			await capture('conclusion_%dx%d_%s'%[dimensions.x,dimensions.y,'grand_opaque' if large else 'normal'])
			app.demo._close_overlay()
	root.size=Vector2i(1280,720)
	SettingsService.cancel_preview()
	app.demo._close_overlay();await screen('home')
	check(ShopService.purchase('avatar_orbit').ok,'Achat avec récompense réelle')
	check(ShopService.equip('avatar_orbit').ok,'Équipement')
	check(ProfileService.save_active().ok,'Sauvegarde')
	check(ProfileService.select_profile(second.data.id).ok and AppState.profile.wallet.points==0,'Profils indépendants')
	check(ProfileService.select_profile(first.data.id).ok and AppState.profile.wallet.points==130 and AppState.profile.equipped.avatar=='avatar_orbit','Reprise conservée')
	await screen('home')
	SaveService.simulate_write_failure=true
	var failed=ProfileService.save_active()
	check(not failed.ok,'Échec de sauvegarde simulé et signalé')
	SaveService.simulate_write_failure=false
	app._result(failed,'',func(): app._result(ProfileService.save_active(),'✓ Sauvegarde enregistrée'))
	await capture('confirmation_1280x720')
	var report={'display':DisplayServer.get_name(),'renderer':RenderingServer.get_video_adapter_name(),'failures':failures,'captures':captures,'physical_controller_tested':false,'isolated_data':SaveService.root_path}
	var file=FileAccess.open('res://tests/visual_results/captures.json',FileAccess.WRITE)
	file.store_string(JSON.stringify(report,'\t'))
	file.close()
	file=null
	print('VISUAL_REVIEW : %d captures, %d échec(s).'%[captures.size(),failures])
	root.remove_child(app)
	app.queue_free()
	for player in [SettingsService._music_player,SettingsService._effect_player]:
		if is_instance_valid(player): player.stop();player.stream=null
	await frames(3)
	quit(0 if failures==0 else 1)
