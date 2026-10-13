extends Control
## Catalog illustration uses the item's real palette / avatar / frame.
const Avatar=preload('res://scripts/ui/avatar_icon.gd')
var item: Dictionary
func configure(value: Dictionary) -> void:
 item=value
 custom_minimum_size=Vector2(0,92)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 if item.type!='theme':
  var icon=Avatar.new()
  icon.color=Color(item.get('color','#527FA3'))
  icon.variant={'H':0,'O':2,'F':1,'R':2}.get(item.get('symbol','H'),0)
  if item.type=='frame':icon.frame=item.id;icon.frame_spec=item
  icon.custom_minimum_size=Vector2(72,72)
  add_child(icon)
  resized.connect(func():icon.position=(size-Vector2(72,72))/2;icon.size=Vector2(72,72))
 resized.connect(queue_redraw)
func _draw() -> void:
 if item.is_empty():return
 var accent=Color(item.get('accent',item.get('color','#527FA3')))
 var background=Color(item.get('secondary','#E6EDF2'))
 var box=StyleBoxFlat.new();box.bg_color=background;box.set_corner_radius_all(16)
 draw_style_box(box,Rect2(Vector2.ZERO,size))
 if item.type=='theme':
  box.bg_color=Color(item.get('background','#F3F5F7'))
  draw_style_box(box,Rect2(Vector2(size.x*.18,12),Vector2(size.x*.64,68)))
  box.bg_color=accent.lightened(.84);box.set_corner_radius_all(8)
  draw_style_box(box,Rect2(Vector2(size.x*.22,22),Vector2(size.x*.36,27)))
  box.bg_color=accent
  draw_style_box(box,Rect2(Vector2(size.x*.22,57),Vector2(size.x*.22,11)))
  draw_circle(Vector2(size.x*.68,36),10,accent)
