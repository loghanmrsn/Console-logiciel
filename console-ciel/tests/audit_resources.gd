extends SceneTree
const Mapping=preload('res://scripts/input_setup.gd')
var checks=0
var failures=0
func _initialize(): call_deferred('_run')
func check(ok: bool,message: String):
	checks+=1
	if not ok: failures+=1;print('AUDIT_RESOURCES_FAIL '+message)
func load_scripts(path: String):
	var dir=DirAccess.open(path)
	for name in dir.get_files():
		if name.ends_with('.gd'):
			var script=load(path.path_join(name)) as GDScript
			check(script!=null and script.can_instantiate(),'Compilation contexte projet '+path.path_join(name))
			if FileAccess.file_exists(path.path_join(name)+'.uid'):
				var uid=ResourceUID.text_to_id(FileAccess.get_file_as_string(path.path_join(name)+'.uid').strip_edges())
				check(uid==ResourceLoader.get_resource_uid(path.path_join(name)),'UID résolu '+path.path_join(name))
	for name in dir.get_directories(): load_scripts(path.path_join(name))
func _run():
	await process_frame
	for folder in ['res://scripts','res://tests','res://tools']: load_scripts(folder)
	check(Mapping.configure().ok,'Input Map configurée')
	for action in Mapping.JOY_ACTIONS+['ui_focus_next','ui_focus_prev','debug_diagnostics']:
		check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(),'Action '+action)
	for bus in ['Master','Music','Effects']: check(AudioServer.get_bus_index(bus)>=0,'Bus '+bus)
	for scene in ['main','startup','demo_game','investigation_world']:
		var resource=load('res://scenes/'+scene+'.tscn') as PackedScene
		check(resource!=null,'Scene '+scene)
		if resource!=null:
			var node=resource.instantiate()
			check(node!=null,'Instanciation '+scene)
			if scene=='startup': check(node.get_node_or_null('Status')!=null,'Chemin $Status')
			node.free()
	for path in ['res://default_bus_layout.tres','res://themes/console_theme.tres']:
		check(load(path)!=null,'Ressource '+path)
	for key in ProjectSettings.get_property_list():
		if not str(key.name).begins_with('autoload/'): continue
		var name=str(key.name).trim_prefix('autoload/')
		var configured=str(ProjectSettings.get_setting(key.name)).trim_prefix('*')
		check(root.has_node(name),'Autoload '+name)
		if root.has_node(name): check(root.get_node(name).get_script().resource_path==configured,'Script autoload '+name)
	var presets=ConfigFile.new()
	check(presets.load('res://export_presets.cfg')==OK,'Config export')
	for index in range(3):
		check(presets.get_value('preset.%d.options'%index,'binary_format/embed_pck',false)==true,'Pack intégré preset '+str(index))
	check(presets.get_value('preset.1.options','binary_format/architecture','')=='arm64','ARM64')
	check(ProjectSettings.get_setting('run/main_scene',ProjectSettings.get_setting('application/run/main_scene',''))=='res://scenes/main.tscn','Scène principale')
	print('AUDIT_RESOURCES : %d assertions, %d échec(s).'%[checks,failures])
	quit(0 if failures==0 else 1)
