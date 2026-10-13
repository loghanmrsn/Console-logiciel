extends SceneTree
## Four resolutions, directed bottom navigation and visual-only persistence contract.
var app
var checks=0
var failures=0
var profiles
var state
var settings
var saves
var router
func _initialize(): run.call_deferred()
func frames(n=5):
 for i in range(n):await process_frame
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr('REFONTE_FAIL : '+message)
func key(code):
 if not router.gameplay_allowed():await create_timer(.23).timeout
 var e=InputEventKey.new();e.keycode=code;e.pressed=true;Input.parse_input_event(e)
 await process_frame
 e=e.duplicate();e.pressed=false;Input.parse_input_event(e);await frames(5)
func run():
 await process_frame
 saves=root.get_node('SaveService');profiles=root.get_node('ProfileService');state=root.get_node('AppState');settings=root.get_node('SettingsService');router=root.get_node('SceneRouter')
 saves.root_path='user://tests/refonte_'+str(Time.get_ticks_usec());settings.storage_root=saves.root_path
 app=load('res://scenes/main.tscn').instantiate();root.add_child(app);await frames(25)
 var profile=profiles.create_profile('WWWWWWWWWWWWWWWW');check(profile.ok,'Profil isolé');check(profiles.select_profile(profile.data.id).ok,'Sélection')
 var before=state.profile.duplicate(true)
 var nav_id=app.navigation.get_instance_id()
 for resolution in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(1024,600),Vector2i(800,480)]:
  root.size=resolution;await frames()
  for large in [false,true]:
   var values=settings.defaults.duplicate(true);values.large_text=large;values.reduce_motion=true;values.reduce_transparency=large;settings.preview(values)
   for destination in ['home','shop','profiles','settings','help']:
    app.draft_settings=values.duplicate(true);app.settings_origin='home';app.parent_screen='home'
    app._show_screen(destination);await frames(8)
    var nav=app.navigation
    check(Rect2(Vector2.ZERO,Vector2(resolution)).encloses(app.header_profile.get_global_rect()),'Pseudo de 16 caractères visible')
    check(nav.get_instance_id()==nav_id,'Navigation persistante '+destination)
    check(nav.visible and nav.selected==destination,'Onglet actif '+destination)
    check(app.scroll.get_global_rect().end.y<=nav.get_global_rect().position.y+.5,'Aucun recouvrement du contenu '+str(resolution))
    for tab in nav.buttons:
     check(Rect2(Vector2.ZERO,Vector2(resolution)).encloses(tab.get_global_rect()),'Onglet accessible '+str(tab.name))
     var label=tab.get_child(0).get_child(1)
     check(label.get_theme_font('font').get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size('font_size')).x<=label.size.x,'Libellé lisible '+label.text)
     var top=tab.get_node_or_null(tab.focus_neighbor_top)
     var down=tab.get_node_or_null(tab.focus_neighbor_bottom)
     check(top!=null and down!=null and app.content.is_ancestor_of(top) and app.content.is_ancestor_of(down),'Contenu accessible depuis chaque onglet')
   app._show_screen('home');await frames(6)
   var shop_tab=app.navigation.buttons[1]
   shop_tab.grab_focus();await frames()
   check(app.navigation.selected=='home','Le focus ne change pas la destination active')
   check(app.navigation.buttons[0].get_theme_stylebox('normal').border_width_bottom==3 and shop_tab.get_theme_stylebox('focus').border_width_top==3,'Sélection et focus ont des formes distinctes')
   await key(KEY_UP)
   check(app.content.is_ancestor_of(root.gui_get_focus_owner()),'Flèche haut rejoint le contenu')
 check(state.profile==before and saves.read_profile(before.id).data==before,'Refonte sans modification des données du joueur')
 settings.cancel_preview();root.size=Vector2i(1280,720)
 app._show_screen('home');await frames()
 app.navigation.buttons[1].grab_focus();await key(KEY_ENTER)
 check(app.screen=='shop','Validation réelle de la barre')
 await key(KEY_ESCAPE);check(app.screen=='home' and root.gui_get_focus_owner()==app.navigation.buttons[1],'Retour restitue le focus')
 check(profiles.start_game().ok,'Partie')
 app._show_screen('game');await frames()
 check(not app.navigation.visible,'Barre masquée en jeu')
 var player=app.demo.world.player
 check(player.sprite.sprite_frames.get_animation_names().size()==4,'Quatre directions animées')
 check(player.get_child(0).shape.radius==10 and app.demo.world._props.y_sort_enabled,'Collision des pieds et profondeur')
 app.demo.request_pause();await frames()
 var objectives=app.demo.modal_content.find_child('pause_objectives',true,false)
 objectives.grab_focus();await key(KEY_ENTER)
 check(app.demo._objectives_expanded and not app.demo.paused,'Objectifs accessibles depuis la pause sans souris')
 app.demo.request_pause();app.settings_origin='game';app.draft_settings=settings.committed.duplicate(true);app._show_screen('settings');await frames()
 check(not app.navigation.visible and not app.demo.world._controls_enabled,'Paramètres de pause sans navigation hors jeu')
 app._cancel_settings();await frames();check(app.demo.paused and app.demo.overlay_kind=='pause','Retour au contexte de pause')
 app.demo.resume();root.remove_child(app);app.queue_free();await frames(3)
 print('REFONTE_NAVIGATION : %d assertions, %d échec(s).'%[checks,failures]);quit(0 if failures==0 else 1)
