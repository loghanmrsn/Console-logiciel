extends VBoxContainer
signal close_requested
var viewport: SubViewport
var actor: CharacterBody3D
var wall_bodies: Array[StaticBody3D]=[]
func _ready() -> void:
	name="character_walk_panel"
	var title=Label.new();title.text="Marcher avec mon personnage en 3D";title.add_theme_font_size_override("font_size",26);add_child(title)
	var hint=Label.new();hint.text="Flèches / ZQSD / joystick : marcher · Maj : courir. Essayez le passage entre les deux murs.";hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(hint)
	var display=SubViewportContainer.new();display.stretch=true;display.custom_minimum_size=Vector2(500,310);display.size_flags_horizontal=Control.SIZE_EXPAND_FILL;add_child(display)
	viewport=SubViewport.new();viewport.size=Vector2i(960,420);viewport.own_world_3d=true;viewport.handle_input_locally=false;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;display.add_child(viewport)
	var environment=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("e5ebee");environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("dce5ed");environment.environment.ambient_light_energy=.7;viewport.add_child(environment)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-55,-30,0);light.light_energy=1.1;viewport.add_child(light)
	_box(Vector3(0,-.1,0),Vector3(8,.2,7),Color("c3c9cc"))
	_box(Vector3(-2,1,-1.2),Vector3(2.9,2,.18),Color("f6f7f3"))
	_box(Vector3(2,1,-1.2),Vector3(2.9,2,.18),Color("f6f7f3"))
	_box(Vector3(0,2.1,-1.2),Vector3(1.1,.2,.22),Color("96acb6"))
	for at in [Vector3(-3.9,.6,0),Vector3(3.9,.6,0)]:_box(at,Vector3(.2,1.2,7),Color("aebfc6"))
	for z in [-3.4,3.4]:_box(Vector3(0,.6,z),Vector3(8,1.2,.2),Color("aebfc6"))
	actor=preload("res://scripts/character/character_player_3d.gd").new();actor.name="CharacterPlayer3D";actor.position=Vector3(0,.02,1.3);viewport.add_child(actor)
	var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=7.8;camera.position=Vector3(3.6,4.5,6.2);viewport.add_child(camera);camera.look_at(Vector3(0,.65,0));camera.current=true
	var back=preload("res://scripts/ui/translucent_button.gd").new();back.name="character_walk_back";back.text="Retour au dressing";back.pressed.connect(func():close_requested.emit());add_child(back)
func _box(at: Vector3,size_: Vector3,color: Color) -> void:
	var body=StaticBody3D.new();body.position=at;viewport.add_child(body);wall_bodies.append(body)
	var collision=CollisionShape3D.new();var box=BoxShape3D.new();box.size=size_;collision.shape=box;body.add_child(collision)
	var mesh=MeshInstance3D.new();var shape=BoxMesh.new();shape.size=size_;mesh.mesh=shape;var material=StandardMaterial3D.new();material.albedo_color=color;material.roughness=.85;mesh.material_override=material;body.add_child(mesh)
