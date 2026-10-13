extends SceneTree
## Real final art states and small-screen polish; isolated fixtures only.
var app
var checks=0
var captures=[]
func _initialize():run.call_deferred()
func frames(n=8):
 for i in range(n):await process_frame
func capture(name):
 await frames();await RenderingServer.frame_post_draw
 var im=root.get_texture().get_image()
 assert(im!=null and not im.is_empty())
 assert(im.save_png('res://docs/screenshots/refonte/apres/'+name+'.png')==OK)
 captures.append(name);checks+=1
func run():
 assert(DisplayServer.get_name()!='headless')
 var saves=root.get_node('SaveService');var settings=root.get_node('SettingsService');var profiles=root.get_node('ProfileService');var investigation=root.get_node('InvestigationService');var state=root.get_node('AppState');var shop=root.get_node('ShopService')
 saves.root_path='user://tests/art_states_'+str(Time.get_ticks_usec());settings.storage_root=saves.root_path
 app=load('res://scenes/main.tscn').instantiate();root.add_child(app);await frames(30)
 var p=profiles.create_profile('Loghan');assert(p.ok and profiles.select_profile(p.data.id).ok)
 for dimensions in [Vector2i(800,480),Vector2i(1024,600),Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=dimensions;await frames()
  for large in [false,true]:
   var values=settings.defaults.duplicate(true);values.large_text=large;values.reduce_motion=true;values.reduce_transparency=large;assert(settings.preview(values).ok)
   app._show_screen('home');await capture('menu_%dx%d_%s'%[dimensions.x,dimensions.y,'grand_opaque' if large else 'normal'])
   app.draft_settings=values.duplicate(true);app.settings_origin='home';app.settings_category=0;app._show_screen('settings');await capture('parametres_%dx%d_%s'%[dimensions.x,dimensions.y,'grand_opaque' if large else 'normal'])
 root.size=Vector2i(1280,720);settings.cancel_preview();assert(profiles.start_game().ok)
 app._show_screen('game');await frames();app.demo.world.player.position=app.demo.world.CHECKPOINTS.lighting;await capture('atelier_avant_eclairage_1280x720')
 assert(investigation.begin_mission('lighting').ok);assert(investigation.submit_lighting(['source_switch','switch_lamp','lamp_return']).ok);await capture('atelier_apres_eclairage_1280x720')
 assert(investigation.begin_mission('lock').ok)
 for id in ['badge','power','command','link']:assert(investigation.observe('lock',id).ok)
 assert(investigation.submit_lock('control_link','reconnect_control').ok)
 app.demo.world.player.position=Vector2(760,300);await capture('atelier_porte_ouverte_1280x720')
 assert(investigation.begin_mission('computer').ok)
 for id in ['pc','display','no_signal']:assert(investigation.observe('computer',id).ok)
 for id in ['power','video']:assert(investigation.check_computer(id).ok)
 assert(investigation.submit_computer(['power','video'],'video_disconnected','reconnect_video').ok)
 await capture('ordinateur_repare_1280x720')
 app._show_screen('shop');await frames();app.content.find_child('product_avatar_default',true,false).grab_focus();await capture('boutique_focus_1280x720')
 assert(shop.purchase('avatar_orbit').ok and shop.equip('avatar_orbit').ok)
 app.shop_inventory=true;app._show_screen('shop');await frames();app.content.find_child('product_avatar_orbit',true,false).grab_focus();await capture('inventaire_apres_achat_1280x720')
 assert(state.profile.wallet.points==130 and profiles.save_active().ok);checks+=1
 var report={'captures':captures,'checks':checks,'failures':0,'display':DisplayServer.get_name(),'renderer':RenderingServer.get_video_adapter_name()}
 var file=FileAccess.open('res://tests/refonte_results/states.json',FileAccess.WRITE);file.store_string(JSON.stringify(report,'\t'));file.close();file=null
 root.remove_child(app);app.queue_free()
 for player in [settings._music_player,settings._effect_player]:
  if is_instance_valid(player):player.stop();player.stream=null
 await frames(3)
 print('REFONTE_STATES : %d captures réelles, %d contrôles.'%[captures.size(),checks]);quit()
