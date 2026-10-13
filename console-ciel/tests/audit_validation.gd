extends SceneTree
## Every existing field receives null/bool/array/object in a disposable copy.
var checks=0
var failures=0
var saves
var fixture=''
func _initialize(): call_deferred('_run')
func paths(value: Variant,prefix: Array=[]) -> Array:
	var result=[prefix]
	if value is Dictionary:
		for key in value: result.append_array(paths(value[key],prefix+[key]))
	elif value is Array:
		for index in range(value.size()): result.append_array(paths(value[index],prefix+[index]))
	return result
func probe(kind: String,source: Dictionary,method: String):
	for path in paths(source):
		for poison in [null,false,[],{}]:
			var copy: Variant=source.duplicate(true)
			if path.is_empty(): copy=poison
			else:
				var parent=copy
				for index in range(path.size()-1): parent=parent[path[index]]
				parent[path[-1]]=poison
			var answer: Dictionary=saves.call(method,copy)
			checks+=1
			if not answer.has('ok') or not answer.get('ok') is bool or not answer.get('error') is String:
				failures+=1
				print('AUDIT_VALIDATION_FAIL ',kind,' ',path,' poison=',poison)
func _run():
	await process_frame
	saves=root.get_node('SaveService')
	fixture='user://tests/audit_validation_'+str(Time.get_ticks_usec())
	saves.root_path=fixture
	root.get_node('ShopService').load_catalog()
	root.get_node('RewardService').load_rules()
	var created=root.get_node('ProfileService').create_profile('Validation')
	probe('catalog',JSON.parse_string(FileAccess.get_file_as_string('res://data/shop_catalog.json')),'validate_catalog')
	probe('rules',JSON.parse_string(FileAccess.get_file_as_string('res://data/game_rules.json')),'validate_rules')
	probe('profile',created.data,'validate_profile')
	root.get_node('AppState').clear_profile()
	var base=ProjectSettings.globalize_path(fixture)
	var dir=DirAccess.open(base.path_join('profiles'))
	for name in dir.get_files(): DirAccess.remove_absolute(base.path_join('profiles').path_join(name))
	DirAccess.remove_absolute(base.path_join('profiles'))
	DirAccess.remove_absolute(base.path_join('session.json'))
	DirAccess.remove_absolute(base)
	print('AUDIT_VALIDATION : %d assertions, %d échec(s).'%[checks,failures])
	quit(0 if failures==0 else 1)
