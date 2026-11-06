extends Node3D
## One real skinned GLB; outfit meshes and materials are shared within this rig.
const Surfaces=preload("res://scripts/character/character_materials.gd")
const Catalog=preload("res://scripts/services/character_catalog.gd")
const Body=preload("res://assets/character3d/character.glb")
var figure: Node3D
var animation: AnimationPlayer
var skeleton: Skeleton3D
var meshes: Array[MeshInstance3D]=[]
var _materials={}
var _appearance={}
func _ready() -> void:
	figure=Body.instantiate()
	add_child(figure)
	animation=figure.find_child("AnimationPlayer",true,false)
	for node in figure.find_children("*","Skeleton3D",true,false): skeleton=node;break
	if animation!=null: animation.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for node in figure.find_children("*","MeshInstance3D",true,false): meshes.append(node)
	configure(_appearance if not _appearance.is_empty() else Catalog.defaults().appearance)
func configure(a: Dictionary) -> void:
	_appearance=a.duplicate()
	if figure==null: return
	var selected=["body","eyes_"+a.eyes,"smile_"+a.smile]
	for slot in Catalog.CATEGORIES: selected.append(slot+"_"+a[slot])
	var colors={"skin":Catalog.SKIN[a.skin],"hair":Catalog.HAIR_COLORS[a.hair_color],"eyes":Catalog.EYE_COLORS[a.eye_color],"lips":Catalog.LIPS[a.lips]}
	for slot in ["top","trousers","headwear","socks","shoes"]: colors["hat" if slot=="headwear" else slot]=Catalog.COLORS[a[slot+"_color"]]
	for mesh in meshes:
		mesh.visible=String(mesh.name) in selected
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if not mesh.visible: continue
		for surface in mesh.mesh.get_surface_count():
			var original=mesh.mesh.surface_get_material(surface)
			if original==null: continue
			var name_=str(original.resource_name)
			if name_ not in colors: continue
			if not _materials.has(name_):
				_materials[name_]=original.duplicate() if name_=="eyes" else ShaderMaterial.new()
			if name_=="eyes":
				_materials[name_].albedo_color=Color(str(colors[name_]))
				_materials[name_].roughness=.26
				_materials[name_].metallic_specular=.45
			else:Surfaces.configure(_materials[name_],name_,Color(str(colors[name_])),a)
			mesh.set_surface_override_material(surface,_materials[name_])
	pose(false,0)
func pose(walking: bool, seconds: float) -> void:
	if animation==null: return
	var selected=""
	for id in animation.get_animation_list():
		if ("walk" if walking else "idle") in id: selected=id;break
	if selected.is_empty(): return
	if animation.current_animation!=selected: animation.play(selected)
	animation.seek(fmod(seconds,animation.get_animation(selected).length) if walking else 0,true)
	animation.advance(0)
	if walking and _appearance.get("gait","loose")=="loose" and skeleton!=null:
		var t=seconds*TAU
		# Secondary movement is entirely visual: the fixed collision body keeps
		# its upright shape and follows the exact input direction.
		_sway("hips",Vector3(.035*sin(t*2),.05*sin(t),.065*sin(t)))
		_sway("spine",Vector3(.09,.10*sin(t+.5),.12*sin(t+.25)))
		_sway("head",Vector3(-.045,.04*sin(t-.4),-.085*sin(t+.1)))
		for side in [-1,1]:
			_sway("arm_"+str(side),Vector3(.11*sin(t+side*.8),side*.10,side*(.10+.055*sin(t+.7))))
			_sway("forearm_"+str(side),Vector3(-.14+.06*sin(t+side),0,side*.04))
func _sway(name_: String,angles: Vector3) -> void:
	var index=skeleton.find_bone(name_)
	if index<0: index=skeleton.find_bone(name_.replace("-1","_1"))
	if index>=0:skeleton.set_bone_pose_rotation(index,skeleton.get_bone_pose_rotation(index)*Quaternion.from_euler(angles))
func sit() -> void:
	if skeleton==null:return
	for side in [-1,1]:
		_sway("thigh_"+str(side),Vector3(-1.25,0,0))
		_sway("shin_"+str(side),Vector3(1.15,0,0))
	var hips=skeleton.find_bone("hips")
	if hips>=0:skeleton.set_bone_pose_position(hips,skeleton.get_bone_pose_position(hips)+Vector3(0,-.27,0))
func visible_triangles() -> int:
	var total=0
	for mesh in meshes:
		if mesh.visible:
			for s in mesh.mesh.get_surface_count(): total+=mesh.mesh.surface_get_array_index_len(s)/3
	return total
