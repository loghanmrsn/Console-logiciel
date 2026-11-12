extends Control
## An actual 3D camera. Idle views render once; only a walking player redraws.
const Model=preload("res://scripts/character/character_model.gd")
const Catalog=preload("res://scripts/services/character_catalog.gd")
var viewport: SubViewport
var model: Node3D
var picture: TextureRect
var camera: Camera3D
var close_up:=false
var appearance: Dictionary={}
var preview_mode:=true
var walking:=false
var seated:=false
var heading:=0.0
var phase:=0.0
var rendered_updates:=0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP if preview_mode else Control.MOUSE_FILTER_IGNORE
	clip_contents=true
	viewport=SubViewport.new()
	viewport.name="Character3DViewport"
	viewport.size=Vector2i(384,512) if preview_mode else Vector2i(128,192)
	viewport.transparent_bg=true
	viewport.own_world_3d=true
	viewport.handle_input_locally=false
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	viewport.positional_shadow_atlas_size=0
	add_child(viewport)
	var environment=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_CLEAR_COLOR
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("dce5ed")
	environment.environment.ambient_light_energy=.45
	viewport.add_child(environment)
	for spec in [[Vector3(-.35,-.7,0),1.15,Color("fff2df")],[Vector3(-.25,.8,0),.40,Color("dceaff")]]:
		var light=DirectionalLight3D.new()
		light.rotation=spec[0]
		light.light_energy=spec[1]
		light.light_color=spec[2]
		light.shadow_enabled=false
		viewport.add_child(light)
	model=Model.new()
	model.configure(appearance if not appearance.is_empty() else Catalog.defaults().appearance)
	viewport.add_child(model)
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=2.05
	camera.position=Vector3(0,1.15,4)
	viewport.add_child(camera)
	camera.look_at(Vector3(0,.86,0))
	camera.current=true
	picture=TextureRect.new()
	picture.texture=viewport.get_texture()
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visibility_changed.connect(_visibility_changed)
	refresh()
	set_process(false)
func configure(a: Dictionary) -> void:
	if appearance==a and model!=null: return
	appearance=a.duplicate()
	if model!=null: model.configure(a);refresh()
func refresh() -> void:
	if viewport==null: return
	model.rotation.y=heading
	model.pose(walking,phase)
	if seated:model.sit()
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	rendered_updates+=1
func set_motion(active: bool,direction: Vector2=Vector2.DOWN) -> void:
	var angle=atan2(direction.x,direction.y)
	var changed=walking!=active or not is_equal_approx(angle,heading)
	walking=active
	heading=angle
	set_process(walking and is_visible_in_tree())
	if changed: refresh()
func _process(delta: float) -> void:
	phase+=minf(delta,.05)
	refresh()
func turn(radians_: float) -> void:
	heading=wrapf(heading+radians_,-PI,PI)
	refresh()
func focus_face(enabled: bool) -> void:
	close_up=enabled
	if camera==null:return
	camera.size=.65 if enabled else 1.90
	camera.position=Vector3(0,1.55 if enabled else 1.15,4)
	camera.look_at(Vector3(0,1.49 if enabled else .86,0))
	refresh()
func _gui_input(event: InputEvent) -> void:
	if preview_mode and event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_LEFT:
		turn(event.relative.x*.012)
		accept_event()
func _visibility_changed() -> void:
	if viewport==null: return
	set_process(walking and is_visible_in_tree())
	if not is_visible_in_tree(): viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	else: refresh()
