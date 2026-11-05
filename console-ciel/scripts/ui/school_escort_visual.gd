extends Control
## Two readable shots: stair flight, then a bright school corridor.
const M = preload("res://scripts/game/render_materials.gd")
const Npc = preload("res://scripts/game/npc_visual.gd")
var player_frames: SpriteFrames
var elapsed := 0.0
var stage: Node2D
var guide: Node2D
var player: AnimatedSprite2D
func _ready() -> void:
	clip_contents=true
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	stage=Node2D.new()
	add_child(stage)
	guide=Npc.new()
	guide.name="Surveillante"
	guide.configure(preload("res://scripts/game/npc_catalog.gd").find("npc_school_supervisor"))
	guide.scale=Vector2.ONE*1.15
	stage.add_child(guide)
	player=AnimatedSprite2D.new()
	player.name="Joueur"
	player.sprite_frames=player_frames
	player.animation="right"
	player.scale=Vector2.ONE*(66.0/player_frames.get_frame_texture("right",0).get_width())
	stage.add_child(player)
	resized.connect(_fit)
	_fit()
func _fit() -> void:
	if stage==null: return
	stage.scale=Vector2.ONE*minf(size.x/900.0,size.y/280.0)
	stage.position=(size-Vector2(900,280)*stage.scale)*.5
	queue_redraw()
func stair_y(x: float) -> float:
	return 244-clampf(floorf((x-250)/32),0,11)*13
func set_elapsed(value: float) -> void:
	elapsed=value
	if stage==null: return
	var stairs := elapsed<1.3
	var t := clampf((elapsed if stairs else elapsed-1.3)/1.3,0,1)
	var x := lerpf(190,650,t)
	var gx := x+78
	var bob := absf(sin(elapsed*20))*2
	guide.position=Vector2(gx,stair_y(gx) if stairs else 238)-Vector2(0,bob)
	guide.walk_cycle=elapsed*20
	guide.queue_redraw()
	player.position=Vector2(x,(stair_y(x) if stairs else 238)-35-bob)
	player.frame=int(elapsed*10)%4
	queue_redraw()
func _draw() -> void:
	if stage==null: return
	draw_rect(Rect2(Vector2.ZERO,size),Color("e5eaeb"))
	draw_set_transform(stage.position,0,stage.scale)
	draw_rect(Rect2(0,0,900,280),Color("f5f6f4"))
	draw_rect(Rect2(0,222,900,58),Color("cbd2d3"))
	for x in range(0,900,75): draw_line(Vector2(x,224),Vector2(x+35,280),Color("b9c4c7"),1,true)
	if elapsed<1.3:
		for i in range(12):
			var x := 250+i*32
			var y := 244-i*13
			draw_rect(Rect2(x,y,32,280-y),Color("aebbbf"))
			draw_rect(Rect2(x,y,32,5),Color("e7eded"))
			draw_line(Vector2(x,y+8),Vector2(x+32,y+8),Color("82969e"),2,true)
		for x in [260,388,516,612]: draw_line(Vector2(x,stair_y(x)-4),Vector2(x,stair_y(x)-58),Color("657e8a"),4,true)
		draw_line(Vector2(250,185),Vector2(645,28),Color("91a7b0"),6,true)
		draw_rect(Rect2(634,101,266,179),Color("aebbbf"))
		draw_rect(Rect2(634,101,266,5),Color("edf0ee"))
		_text("ESCALIER · ATELIERS",Vector2(55,44))
	else:
		for x in [80,320,560,800]:
			M.rounded(self,Rect2(x,45,100,173),Color("778f9b"),4)
			draw_rect(Rect2(x+7,52,86,159),Color("b7c9d0"))
			draw_rect(Rect2(x+16,64,67,50),Color("e1edef"))
			draw_line(Vector2(x+78,136),Vector2(x+87,136),Color("f8f8eb"),3,true)
		draw_line(Vector2(0,218),Vector2(900,218),Color("8e9fa5"),5,true)
		_text("COULOIR DES ATELIERS →",Vector2(285,29))
	draw_set_transform(Vector2.ZERO)
func _text(value: String, at: Vector2) -> void:
	draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("3d5563"))
