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
var _sample_rotations: Array[Quaternion]=[]
var _sample_positions: Array[Vector3]=[]
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
	# AnimationMixer can omit constant tracks. Always discard the preceding
	# procedural/seated pose before sampling, even at the exact same timestamp.
	if skeleton!=null:skeleton.reset_bone_poses()
	if animation.current_animation!=selected: animation.play(selected)
	animation.seek(fmod(seconds,animation.get_animation(selected).length) if walking else 0,true)
	animation.advance(0)
	_sample_rotations.clear();_sample_positions.clear()
	if skeleton!=null:
		for i in skeleton.get_bone_count():
			_sample_rotations.append(skeleton.get_bone_pose_rotation(i))
			_sample_positions.append(skeleton.get_bone_pose_position(i))
func _sway(name_: String,angles: Vector3) -> void:
	var index=skeleton.find_bone(name_)
	if index<0: index=skeleton.find_bone(name_.replace("-1","_1"))
	if index>=0 and index<_sample_rotations.size():skeleton.set_bone_pose_rotation(index,_sample_rotations[index]*Quaternion.from_euler(angles))
func sit() -> void:
	if skeleton==null:return
	for side in [-1,1]:
		_sway("thigh_"+str(side),Vector3(-1.25,0,0))
		_sway("shin_"+str(side),Vector3(1.15,0,0))
	var hips=skeleton.find_bone("hips")
	if hips>=0 and hips<_sample_positions.size():skeleton.set_bone_pose_position(hips,_sample_positions[hips]+Vector3(0,-.27,0))
func visible_triangles() -> int:
	var total=0
	for mesh in meshes:
		if mesh.visible:
			for s in mesh.mesh.get_surface_count(): total+=mesh.mesh.surface_get_array_index_len(s)/3
	return total
