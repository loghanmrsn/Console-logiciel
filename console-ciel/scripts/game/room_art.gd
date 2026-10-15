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
	'elevator_locked':preload('res://assets/art/world/elevator_locked.svg'),
	'elevator_ready':preload('res://assets/art/world/elevator_ready.svg'),
	'network_floor':preload('res://assets/art/world/network_floor.svg'),
	'network_walls':preload('res://assets/art/world/network_walls.svg'),
	'network_rack':preload('res://assets/art/world/network_rack.svg'),
	'network_terminal':preload('res://assets/art/world/network_terminal.svg'),
	'wifi_station':preload('res://assets/art/world/wifi_station.svg'),
	'code_floor':preload('res://assets/art/world/code_floor.svg'),
	'code_walls':preload('res://assets/art/world/code_walls.svg'),
	'code_python':preload('res://assets/art/world/code_python.svg'),
	'code_html':preload('res://assets/art/world/code_html.svg'),
	'code_markdown':preload('res://assets/art/world/code_markdown.svg'),
}
const PROPS=[
 ['ElectricalCabinet',Rect2(76,102,90,60),'electrical_off',Rect2(66,83,110,90)],
 ['LowBench',Rect2(250,298,146,54),'workbench',Rect2(239,284,168,88)],
 ['Storage',Rect2(444,106,64,64),'shelf',Rect2(434,94,84,96)],
 ['ComputerDesk',Rect2(755,142,172,80),'desk',Rect2(741,118,200,122)],
 ['OfficeCabinet',Rect2(683,415,114,45),'cabinet',Rect2(674,396,132,79)],
 ['OfficeChair',Rect2(880,251,44,42),'chair',Rect2(872,234,60,74)],
 ['OfficePlant',Rect2(679,113,26,20),'plant',Rect2(667,85,50,55)]
]
const NETWORK_PROPS=[
 ['NetworkRack',Rect2(247,112,88,90),'network_rack',Rect2(233,83,116,131)],
 ['AddressingDesk',Rect2(445,231,170,77),'desk',Rect2(431,207,198,117)],
 ['WirelessStation',Rect2(762,149,86,59),'wifi_station',Rect2(745,106,120,115)],
 ['NetworkStorage',Rect2(735,394,118,62),'cabinet',Rect2(727,373,134,95)],
 ['NetworkPlant',Rect2(882,130,28,26),'plant',Rect2(870,101,54,62)],
 ['NetworkChair',Rect2(635,249,44,42),'chair',Rect2(627,232,60,74)]
]
const CODE_PROPS=[
 ['PythonDesk',Rect2(134,141,172,80),'desk',Rect2(120,117,200,122)],
 ['HtmlDesk',Rect2(414,141,172,80),'desk',Rect2(400,117,200,122)],
 ['MarkdownDesk',Rect2(694,141,172,80),'desk',Rect2(680,117,200,122)],
 ['CodeStorage',Rect2(760,403,114,45),'cabinet',Rect2(751,384,132,79)],
 ['CodeResources',Rect2(500,411,64,52),'shelf',Rect2(490,397,84,77)],
 ['CodePlant',Rect2(888,118,26,20),'plant',Rect2(876,90,50,55)]
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
 canvas.draw_texture_rect(TEXTURES.elevator_locked,Rect2(835,389,112,87),false)
 canvas.draw_texture(TEXTURES.door_closed,Vector2(616,276))
 canvas.draw_texture_rect(PREVIEW_CHARACTER,Rect2(276,374,52,58),false)
 canvas.draw_set_transform(Vector2.ZERO)
