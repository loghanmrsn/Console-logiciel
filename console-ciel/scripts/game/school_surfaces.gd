extends RefCounted
## Small retained material textures: no full-screen noise shader or light pass.
static var _concrete: NoiseTexture2D
static var _plaster: GradientTexture2D
static var _light: GradientTexture2D
static var _contact: GradientTexture2D
static func concrete() -> NoiseTexture2D:
	if _concrete==null:
		_concrete=NoiseTexture2D.new()
		_concrete.width=256
		_concrete.height=256
		_concrete.seamless=true
		_concrete.generate_mipmaps=true
		var noise := FastNoiseLite.new()
		noise.seed=47028
		noise.frequency=.18
		noise.fractal_octaves=3
		_concrete.noise=noise
		var ramp := Gradient.new()
		ramp.colors=PackedColorArray([Color("cdd0cf"),Color("d8dad7")])
		_concrete.color_ramp=ramp
	return _concrete
static func plaster() -> GradientTexture2D:
	if _plaster==null:
		_plaster=GradientTexture2D.new()
		_plaster.width=8
		_plaster.height=128
		_plaster.fill_from=Vector2(.5,0)
		_plaster.fill_to=Vector2(.5,1)
		var ramp := Gradient.new()
		ramp.colors=PackedColorArray([Color("fbfbf9"),Color("d9dedd")])
		_plaster.gradient=ramp
	return _plaster
static func light() -> GradientTexture2D:
	if _light==null:
		_light=GradientTexture2D.new()
		_light.width=128
		_light.height=64
		_light.fill=GradientTexture2D.FILL_RADIAL
		_light.fill_from=Vector2(.5,.5)
		_light.fill_to=Vector2(1,.5)
		var ramp := Gradient.new()
		ramp.colors=PackedColorArray([Color(1,.96,.85,.2),Color(1,.96,.85,0)])
		_light.gradient=ramp
	return _light
static func floor_material(c: CanvasItem, size: Vector2) -> void:
	if c.texture_filter!=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS: c.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	c.draw_rect(Rect2(Vector2.ZERO,size),Color("d1d5d4"))
	c.draw_texture_rect(concrete(),Rect2(64,64,size.x-128,size.y-128),true)
	# Expansion joints in large concrete bays, rather than a heavy tiled grid.
	for y in range(400,int(size.y)-80,480): c.draw_line(Vector2(64,y),Vector2(size.x-64,y),Color(.4,.45,.46,.13),1,true)
	for x in range(600,int(size.x)-80,640): c.draw_line(Vector2(x,64),Vector2(x,size.y-64),Color(.4,.45,.46,.13),1,true)
	for layer in range(12):
		var alpha := .016*(1.0-float(layer)/12)
		c.draw_rect(Rect2(64+layer*3,64+layer*3,size.x-128-layer*6,size.y-128-layer*6),Color(.16,.2,.22,alpha),false,3)
static func wall_face(c: CanvasItem, footprint: Rect2, rise: float) -> void:
	for layer in range(5,0,-1):
		c.draw_rect(Rect2(footprint.position+Vector2(layer*3,layer*4),footprint.size+Vector2(6,4)),Color(.14,.18,.20,.025))
	var face := Rect2(footprint.position-Vector2(0,rise),footprint.size+Vector2(0,rise))
	c.draw_texture_rect(plaster(),face,false)
	if footprint.size.y>footprint.size.x:
		c.draw_rect(Rect2(face.position-Vector2(9,0),Vector2(9,face.size.y)),Color("bbc4c7"))
	c.draw_rect(Rect2(face.position,Vector2(face.size.x,6)),Color("ffffff"))
	c.draw_rect(Rect2(footprint.position+Vector2(0,footprint.size.y-7),Vector2(footprint.size.x,7)),Color("929b9f"))
	c.draw_line(footprint.position+Vector2(0,footprint.size.y-7),footprint.end-Vector2(0,7),Color("b6bec0"),1,true)

static func contact(c: CanvasItem, footprint: Rect2) -> void:
	if _contact==null:
		_contact=GradientTexture2D.new()
		_contact.width=128
		_contact.height=64
		_contact.fill=GradientTexture2D.FILL_RADIAL
		_contact.fill_from=Vector2(.5,.5)
		_contact.fill_to=Vector2(1,.5)
		var ramp := Gradient.new()
		ramp.offsets=PackedFloat32Array([0,.55,1])
		ramp.colors=PackedColorArray([Color(.08,.12,.15,.22),Color(.08,.12,.15,.13),Color(.08,.12,.15,0)])
		_contact.gradient=ramp
	c.draw_texture_rect(_contact,Rect2(footprint.position+Vector2(-14,-5),footprint.size+Vector2(40,30)),false)
