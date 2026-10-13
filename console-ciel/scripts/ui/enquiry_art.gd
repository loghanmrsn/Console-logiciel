extends Control
const RoomArt=preload('res://scripts/game/room_art.gd')
func _init() -> void:
 custom_minimum_size=Vector2(0,240)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
func _ready() -> void:
 resized.connect(queue_redraw)
func _draw() -> void:
 var panel=StyleBoxFlat.new()
 panel.bg_color=Color('#D5E1DF');panel.set_corner_radius_all(24)
 draw_style_box(panel,Rect2(Vector2.ZERO,size))
 RoomArt.draw_preview(self,Rect2(Vector2(4,6),size-Vector2(8,12)))
