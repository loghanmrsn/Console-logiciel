extends RefCounted
## Original SVG palette, shared by the real room and its home preview.
const PREVIEW_CHARACTER=preload('res://assets/art/character/down_0.svg')
const TEXTURES={
	'cabinet':preload('res://assets/art/world/cabinet.svg'),
	'chair':preload('res://assets/art/world/chair.svg'),
	'desk':preload('res://assets/art/world/desk.svg'),
	'door_closed':preload('res://assets/art/world/door_closed.svg'),
	'door_open':preload('res://assets/art/world/door_open.svg'),
	'electrical_off':preload('res://assets/art/world/electrical_off.svg'),
	'electrical_on':preload('res://assets/art/world/electrical_on.svg'),
	'floor':preload('res://assets/art/world/floor.svg'),
	'light':preload('res://assets/art/world/light.svg'),
	'monitor_off':preload('res://assets/art/world/monitor_off.svg'),
	'monitor_on':preload('res://assets/art/world/monitor_on.svg'),
	'note':preload('res://assets/art/world/note.svg'),
	'plant':preload('res://assets/art/world/plant.svg'),
	'reader_off':preload('res://assets/art/world/reader_off.svg'),
	'reader_on':preload('res://assets/art/world/reader_on.svg'),
	'shelf':preload('res://assets/art/world/shelf.svg'),
	'tower':preload('res://assets/art/world/tower.svg'),
	'walls':preload('res://assets/art/world/walls.svg'),
	'workbench':preload('res://assets/art/world/workbench.svg'),
}
const PROPS=[
 ['ElectricalCabinet',Rect2(76,102,90,60),'electrical_off',Rect2(66,83,110,90)],
 ['LowBench',Rect2(250,298,146,54),'workbench',Rect2(239,284,168,88)],
 ['Storage',Rect2(444,106,64,64),'shelf',Rect2(434,94,84,96)],
 ['ComputerDesk',Rect2(755,142,172,80),'desk',Rect2(741,118,200,122)],
 ['OfficeCabinet',Rect2(700,408,114,52),'cabinet',Rect2(691,389,132,86)],
 ['OfficeChair',Rect2(880,251,44,42),'chair',Rect2(872,234,60,74)],
 ['OfficePlant',Rect2(679,113,26,20),'plant',Rect2(667,85,50,55)]
]
const EXTRAS=[
 ['light',Rect2(274,61,172,28)],
 ['monitor_off',Rect2(781,127,85,61)],
 ['tower',Rect2(879,145,36,68)],
 ['reader_off',Rect2(568,289,30,49)]
]
static func draw_preview(canvas: CanvasItem,rect: Rect2) -> void:
 var factor=minf(rect.size.x/1000.0,rect.size.y/520.0)
 var origin=rect.position+(rect.size-Vector2(1000,520)*factor)/2
 canvas.draw_set_transform(origin,0,Vector2(factor,factor))
 canvas.draw_texture(TEXTURES.floor,Vector2.ZERO)
 canvas.draw_texture(TEXTURES.walls,Vector2.ZERO)
 for prop in PROPS:canvas.draw_texture_rect(TEXTURES[prop[2]],prop[3],false)
 for extra in EXTRAS:canvas.draw_texture_rect(TEXTURES[extra[0]],extra[1],false)
 canvas.draw_texture(TEXTURES.door_closed,Vector2(616,276))
 canvas.draw_texture_rect(PREVIEW_CHARACTER,Rect2(276,374,52,58),false)
 canvas.draw_set_transform(Vector2.ZERO)
