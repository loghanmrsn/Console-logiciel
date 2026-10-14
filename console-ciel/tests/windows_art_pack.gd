extends SceneTree
## Exported art + compiled UI executed by Linux Godot, not native Windows.
var checks=0
var failures=0
var app
func _initialize():run.call_deferred()
func frames(n=8):
 for i in range(n):await process_frame
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr('WINDOWS_ART_FAIL : '+message)
func resources(folder: String) -> Array:
 var result=[];var directory=DirAccess.open(folder)
 if directory==null:return result
 for child in directory.get_files():
  if child.ends_with('.svg'):result.append(folder.path_join(child))
  elif child.ends_with('.svg.import'):result.append(folder.path_join(child.trim_suffix('.import')))
  elif child.ends_with('.svg.remap'):result.append(folder.path_join(child.trim_suffix('.remap')))
 for child in directory.get_directories():result.append_array(resources(folder.path_join(child)))
 return result
func run():
 await process_frame
 check(ProjectSettings.get_setting('application/config/version')=='0.5.0','Version embarquée')
 var all=resources('res://assets/art');check(all.size()==36,'36 SVG dans le pack')
 for path in all:
  var asset=ResourceLoader.load(path)
  check(asset is Texture2D and asset.get_width()>0 and asset.get_height()>0,'Image embarquée '+path)
 var saves=root.get_node('SaveService');var settings=root.get_node('SettingsService');var profiles=root.get_node('ProfileService');var state=root.get_node('AppState');var investigation=root.get_node('InvestigationService');var shop=root.get_node('ShopService')
 saves.root_path='user://tests/art_pack_'+str(Time.get_ticks_usec());settings.storage_root=saves.root_path
 app=load('res://scenes/main.tscn').instantiate();root.add_child(app);await frames(30)
 check(app.screen=='editor','Pack démarre sans profil')
 check(app.find_child('profile_avatar_preview',true,false)!=null,'Aperçu du profil embarqué')
 check(app.find_child('key_A',true,false).text=='a' and app.find_child('key_Shift',true,false)!=null and app.find_child('key_123',true,false).text=='123','Clavier mobile compilé : minuscules, majuscule et chiffres')
 check(app.find_child('open_profile_images',true,false)!=null and app.find_child('refresh_profile_images',true,false)!=null,'Dossier des images locales accessible depuis le pack')
 var p=profiles.create_profile('Export graphique');check(p.ok and profiles.select_profile(p.data.id).ok,'Profil isolé du pack')
 app._show_screen('home');await frames();check(app.navigation.visible and app.navigation.buttons.size()==4,'Accueil compilé et quatre destinations')
 check(ResourceLoader.load('res://scenes/games/test_game.tscn') is PackedScene,'Écran local des futurs jeux embarqué')
 for id in ['game_test_1','game_test_2','game_test_3','game_test_4']:
  check(shop.item(id).get('placeholder')==true and app.find_child('buy_'+id,true,false)!=null,'Futur jeu clairement verrouillé dans le pack '+id)
 var empty_profile=state.profile.duplicate(true)
 check(not shop.purchase('game_test_1').ok and state.profile==empty_profile,'Achat sans points refusé par le service compilé')
 var destinations=['home','shop','settings','profiles'];var labels=['Accueil','Boutique','Paramètres','Profil']
 check(app.navigation.destination_labels.size()==4,'Quatre libellés compilés')
 for i in range(destinations.size()):
  check(String(app.navigation.buttons[i].name)=='home_'+destinations[i] and app.navigation.destination_labels[i].text==labels[i],'Ordre compilé '+labels[i])
 check(app.navigation.profile_name_label.text==state.profile.display_name and app.navigation.profile_points_label.text=='0 pts' and app.navigation.profile_avatar.visible,'Vrai profil intégré à la barre du pack')
 check(profiles.start_game().ok,'Partie du pack');app._show_screen('game');await frames()
 check(not app.navigation.visible and app.demo.world.player.sprite!=null,'Jeu avec personnage et barre masquée')
 check(app.demo.world.player.sprite.sprite_frames.get_animation_names().size()==4,'Animations des quatre directions')
 check(app.demo.world._light_sprite.modulate!=Color.WHITE,'Luminaire éteint au début')
 app.demo.request_pause();await frames();check(app.demo._modal_panel.size.x<=660 and app.demo.paused,'Pause centrée et commandes suspendues')
 app.demo.resume();await frames()
 check(investigation.begin_mission('lighting').ok and investigation.submit_lighting(['source_switch','switch_lamp','lamp_return']).ok,'Mission inchangée')
 await frames();check(app.demo.world.lighting_restored and state.profile.wallet.points==50,'État visuel et récompense du pack')
 check(app.navigation.profile_points_label.text=='50 pts','La récompense met à jour la barre du pack')
 check(app.demo.world._light_sprite.modulate==Color.WHITE,'Luminaire allumé après validation')
 app._show_screen('shop');await frames();check(app.screen=='shop' and app.navigation.selected=='shop','Boutique compilée avec aperçu')
 check(app.find_child('shop_filter',true,false).item_count==5,'Catégorie Jeux embarquée à côté des cosmétiques')
 check(shop.purchase('game_test_1').ok and state.profile.wallet.points==30,'Achat de jeu avec les vrais points éducatifs du pack')
 check(saves.read_profile(p.data.id).data==state.profile,'Points et jeu achetés enregistrés ensemble par les scripts compilés')
 app._show_screen('home');await frames()
 check(app.find_child('play_game_test_1',true,false)!=null,'Jeu acheté accessible depuis la bibliothèque compilée')
 app._launch_library_game('game_test_1');await frames()
 check(app.screen=='arcade','La scène du futur jeu se charge depuis le pack')
 app._back();await frames();check(app.screen=='home','Retour de l’emplacement vers la bibliothèque')
 var values=settings.committed.duplicate(true);values.appearance_style='nuit';values.home_layout='carousel'
 check(settings.preview(values).ok,'Apparence Nuit et disposition défilante compilées')
 app._show_screen('home');await frames();check(app.find_child('home_carousel',true,false) is ScrollContainer,'Bibliothèque défilante disponible dans le pack')
 app.settings_origin='home';app.draft_settings=values.duplicate(true);app.settings_category=4;app._show_screen('settings');await frames()
 check(app.find_child('appearance_nuit',true,false)!=null and app.find_child('setting_background_color',true,false)!=null and app.find_child('setting_button_color',true,false)!=null,'Styles et couleurs accessibles dans les paramètres compilés')
 var categories=app.find_child('settings_categories',true,false)
 check(categories.item_count==8 and categories.get_item_text(7)=='Crédits','Crédits termine les paramètres du pack')
 root.remove_child(app);app.queue_free();await frames(3)
 print('WINDOWS_ART_PACK : %d assertions, %d échec(s).'%[checks,failures]);quit(0 if failures==0 else 1)
