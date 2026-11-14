extends SceneTree
## Regressions for accumulated poses: a walk must depend on time, never history.
const Model=preload("res://scripts/character/character_model.gd")
const Catalog=preload("res://scripts/services/character_catalog.gd")
var checks:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("CHARACTER_MOVEMENT_FAIL : ",message)
func snapshot(model: Node3D) -> Array[Transform3D]:
	var result: Array[Transform3D]=[]
	for i in model.skeleton.get_bone_count():result.append(model.skeleton.get_bone_pose(i))
	return result
func matches(model: Node3D,expected: Array[Transform3D]) -> bool:
	for i in expected.size():
		if not model.skeleton.get_bone_pose(i).is_equal_approx(expected[i]):return false
	return true
func upright(model: Node3D) -> bool:
	var hips=model.skeleton.get_bone_global_pose(model.skeleton.find_bone("hips"))
	var head=model.skeleton.get_bone_global_pose(model.skeleton.find_bone("head"))
	return (model.basis*hips.basis.y).normalized().dot(Vector3.UP)>.99 and head.origin.y>hips.origin.y+(.5 if model._model_id=="classic" else .25)
func run() -> void:
	await process_frame
	var model=Model.new();root.add_child(model)
	var reference=Model.new();root.add_child(reference)
	check(Catalog.defaults().appearance.gait=="natural","Nouveaux personnages : marche naturelle")
	model.pose(false,0)
	var idle=snapshot(model)
	for gait in Catalog.GAITS:
		var appearance=Catalog.defaults().appearance;appearance.gait=gait;model.configure(appearance)
		model.pose(true,.22)
		var sample=snapshot(model)
		for frame in range(1200):model.pose(true,.22)
		check(matches(model,sample) and upright(model),"Même instant répété 1 200 fois sans accumulation : "+gait)
		var stable=true
		var independent=true
		for frame in range(3600):
			var seconds=frame/60.0
			model.rotation.y=(frame%8)*PI/4
			model.pose(true,seconds)
			stable=stable and upright(model)
			if frame%173==0:
				reference.pose(true,seconds)
				independent=independent and matches(model,snapshot(reference))
			if frame%97==0:
				model.pose(false,seconds)
				independent=independent and matches(model,idle)
		check(stable,"60 secondes de marche, huit directions : tête au-dessus du bassin et corps vertical : "+gait)
		check(independent,"Marche et arrêts indépendants des poses précédentes : "+gait)
		check(model.scale.is_equal_approx(Vector3.ONE) and model.position.is_zero_approx(),"Aucune inclinaison ni translation de la racine : "+gait)
		model.pose(false,0)
		check(matches(model,idle),"Relâcher restaure exactement le repos : "+gait)
		model.sit()
		var seated=snapshot(model)
		for frame in range(120):model.sit()
		check(matches(model,seated),"S'asseoir plusieurs fois ne cumule ni rotation ni descente : "+gait)
		model.pose(false,0)
		check(matches(model,idle) and upright(model),"Se relever restaure tous les os : "+gait)
		model.sit();model.pose(true,.22)
		check(matches(model,sample) and upright(model),"Marcher après une pose assise restaure le cycle : "+gait)
	model.pose(true,.1)
	var thigh=model.skeleton.find_bone("thigh_-1")
	if thigh<0:thigh=model.skeleton.find_bone("thigh__1")
	var first=model.skeleton.get_bone_pose_rotation(thigh)
	model.pose(true,.6)
	check(first.angle_to(model.skeleton.get_bone_pose_rotation(thigh))>.2,"Les jambes alternent réellement ; la marche n'est pas figée")
	model.free();reference.free()
	print("CHARACTER_MOVEMENT : %d assertions, %d échec(s)."%[checks,failures])
	quit(0 if failures==0 else 1)
