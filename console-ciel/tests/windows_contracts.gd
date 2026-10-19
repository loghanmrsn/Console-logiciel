extends SceneTree
## Windows configuration checks on the host; no native Windows runtime claim.
var checks=0
var failures=0
func _initialize():call_deferred('_run')
func check(ok: bool,message: String):
	checks+=1
	if not ok:failures+=1;print('WINDOWS_FAIL '+message)
func _run():
	await process_frame
	check(Engine.get_version_info().string=='4.6.3-stable (official)','Version exacte Godot')
	check(ProjectSettings.get_setting('application/run/main_scene')=='res://scenes/main.tscn','Scene principale')
	check(ProjectSettings.get_setting('application/config/version')=='0.14.0','Version du logiciel')
	check(ProjectSettings.get_setting('display/window/size/window_width_override')==1280 and ProjectSettings.get_setting('display/window/size/window_height_override')==720,'Fenêtre initiale 1280x720')
	check(ProjectSettings.get_setting('display/window/size/resizable')==true and ProjectSettings.get_setting('display/window/size/mode')==0,'Fenêtre redimensionnable par défaut')
	check(ProjectSettings.get_setting('rendering/renderer/rendering_method')=='gl_compatibility','Compatibility')
	check(ProjectSettings.get_setting('application/config/use_custom_user_dir')==true and ProjectSettings.get_setting('application/config/custom_user_dir_name')=='console-ciel','Configuration du dossier utilisateur')
	var platform=root.get_node('PlatformService')
	check(platform.user_data_directory()==OS.get_user_data_dir(),'Chemin affiché réellement donné par Godot')
	check(platform.application_log_directory()==OS.get_user_data_dir().path_join('logs'),'Chemin des journaux')
	check(not platform.can_shutdown and not platform.request_shutdown().ok,'Arrêt système indisponible')
	var settings=root.get_node('SettingsService')
	check(settings.defaults.fullscreen==false,'Premier lancement en fenêtre')
	var presets=ConfigFile.new();check(presets.load('res://export_presets.cfg')==OK,'Presets lisibles')
	check(presets.get_value('preset.2','name')=='Windows Desktop x86_64' and presets.get_value('preset.2','platform')=='Windows Desktop','Cible Windows dédiée')
	check(presets.get_value('preset.2.options','binary_format/architecture')=='x86_64','Architecture Windows x86_64')
	check(presets.get_value('preset.2.options','application/file_version')=='0.14.0' and presets.get_value('preset.2.options','application/product_version')=='0.14.0','Métadonnées Windows 0.14.0')
	check(presets.get_value('preset.2','export_path')=='builds/windows-x86_64/Console_CIEL.exe','Destination Windows')
	check(presets.get_value('preset.2.options','binary_format/embed_pck')==true and presets.get_value('preset.2.options','codesign/enable')==false,'Pack intégré et pas de signature annoncée')
	check(presets.get_value('preset.1','name')=='Linux ARM64 Raspberry Pi' and presets.get_value('preset.1.options','binary_format/architecture')=='arm64','Cible Pi préservée')
	print('WINDOWS_CONTRACTS : %d assertions, %d échec(s).'%[checks,failures])
	quit(0 if failures==0 else 1)
