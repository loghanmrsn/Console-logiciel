extends SceneTree
## Actual Godot viewport captures with disposable profile data and a real display.
var app
var failures=0
var captures:Array=[]
var saves
var profiles
var settings
var state
var investigation
var shop
const OUTPUT='res://docs/screenshots/navigation_0.4.1'

func _initialize():run.call_deferred()

func frames(count=8):
	for _index in range(count):await process_frame

func check(ok:bool,message:String):
	if not ok:
		failures+=1
		printerr('GLASS_VISUAL_FAIL : '+message)

func capture(name:String):
	await frames(12)
	await RenderingServer.frame_post_draw
	var picture=root.get_texture().get_image()
	check(picture!=null and not picture.is_empty(),'Viewport rendered '+name)
	if picture==null or picture.is_empty():return
	var path=OUTPUT.path_join(name+'.png')
	check(picture.save_png(path)==OK,'Capture saved '+name)
	captures.append({'file':path,'size':str(root.size),'screen':app.screen})

func show_screen(destination:String):
	if destination=='settings':
		app.settings_origin='home'
		app.draft_settings=settings.current.duplicate(true)
	app._show_screen(destination)
	await frames()

func run():
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	saves=root.get_node('SaveService');profiles=root.get_node('ProfileService')
	settings=root.get_node('SettingsService');state=root.get_node('AppState')
	investigation=root.get_node('InvestigationService');shop=root.get_node('ShopService')
	saves.root_path='user://tests/glass_visual_'+str(Time.get_ticks_usec())
	settings.storage_root=saves.root_path
	app=load('res://scenes/main.tscn').instantiate()
	root.add_child(app)
	await frames(30)
	var profile=profiles.create_profile('Loghan')
	check(profile.ok,'Isolated profile created')
	check(profiles.select_profile(profile.data.id).ok,'Profile selected')
	check(profiles.start_game().ok,'Enquiry started')
	check(investigation.begin_mission('lighting').ok,'Lighting started')
	check(investigation.submit_lighting(['source_switch','switch_lamp','lamp_return']).ok,'Real lighting reward')
	for dimensions in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(1024,600),Vector2i(800,480)]:
		root.size=dimensions
		for accessible in [false,true]:
			var values=settings.defaults.duplicate(true)
			values.large_text=accessible;values.reduce_transparency=accessible;values.reduce_motion=true
			settings.preview(values)
			await show_screen('home')
			await capture('accueil_%dx%d_%s'%[dimensions.x,dimensions.y,'grand_opaque' if accessible else 'normal'])
	root.size=Vector2i(1280,720)
	settings.cancel_preview()
	for destination in ['shop','settings','profiles']:
		await show_screen(destination)
		await capture(destination+'_1280x720')
	await show_screen('home')
	app.navigation.buttons[1].grab_focus()
	await capture('focus_boutique_1280x720')
	check(shop.purchase('avatar_orbit').ok,'Purchase with real points')
	check(shop.equip('avatar_orbit').ok,'Equipped avatar in navigation')
	await show_screen('home')
	await capture('avatar_equipe_1280x720')
	check(state.profile.wallet.points==30,'Wallet updated after purchase')
	var before=state.profile.duplicate(true)
	check(profiles.update_profile('WWWWWWWWWWWWWWWW','avatar_orbit').ok,'Maximum width name')
	root.size=Vector2i(800,480)
	var large=settings.defaults.duplicate(true)
	large.large_text=true;large.reduce_transparency=true;large.reduce_motion=true
	settings.preview(large)
	await show_screen('home')
	await capture('pseudo_long_800x480_grand_opaque')
	check(state.profile.wallet.points==before.wallet.points,'Visual capture preserves points')
	var report={'display':DisplayServer.get_name(),'renderer':RenderingServer.get_video_adapter_name(),
		'failures':failures,'captures':captures,'physical_controller_tested':false,
		'isolated_data':saves.root_path}
	var file=FileAccess.open(OUTPUT.path_join('captures.json'),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,'\t'));file.close()
	root.remove_child(app);app.queue_free()
	for player in [settings._music_player,settings._effect_player]:
		if is_instance_valid(player):player.stop();player.stream=null
	await frames(4)
	print('GLASS_VISUAL : %d captures, %d échec(s).'%[captures.size(),failures])
	quit(0 if failures==0 else 1)
